-- ============================================================================
-- FILE  : 12_fraud_detection.sql
-- MODULE: FRAUD & ANOMALY DETECTION  (UNIQUE MODULE)
-- WHY   : Real hospitals and insurers lose crores every year to billing fraud
--         and over-prescription. These queries find hidden anomalies in the
--         data without any ML — just pure SQL statistics + business rules.
--
-- WHAT THIS FINDS (planted in 02_seed_data.sql):
--   FRAUD-1: A cardiologist over-prescribing meds vs peers
--   FRAUD-2: Two bills pointing to the same admission (double billing)
--   FRAUD-3: "Ghost" bill with no linked appointment/admission
--   FRAUD-4: Same bill claimed against two different insurance policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ANOMALY 1: Doctors prescribing FAR MORE than peers of same specialization.
--            Uses a statistical rule: > 2x the specialization average.
-- ----------------------------------------------------------------------------
WITH doc_qty AS (
    SELECT
        s.staff_id,
        s.name          AS doctor,
        s.specialization,
        SUM(rx.quantity) AS total_units_prescribed,
        COUNT(*)         AS rx_events
    FROM prescriptions rx
    JOIN staff s ON s.staff_id = rx.doctor_id
    WHERE s.role='Doctor'
    GROUP BY s.staff_id, s.name, s.specialization
),
spec_avg AS (
    SELECT specialization, AVG(total_units_prescribed) AS spec_avg_units
    FROM doc_qty
    GROUP BY specialization
)
SELECT
    dq.doctor,
    dq.specialization,
    dq.total_units_prescribed,
    ROUND(sa.spec_avg_units, 0)                          AS peer_avg_units,
    ROUND(dq.total_units_prescribed / sa.spec_avg_units, 2) AS times_over_avg,
    'OVER-PRESCRIBER — investigate'                       AS flag
FROM doc_qty dq
JOIN spec_avg sa ON sa.specialization = dq.specialization
WHERE dq.total_units_prescribed > 2 * sa.spec_avg_units
ORDER BY times_over_avg DESC;

-- ----------------------------------------------------------------------------
-- ANOMALY 2: DUPLICATE BILLING — same admission billed twice.
-- ----------------------------------------------------------------------------
SELECT
    admission_id,
    COUNT(*)                AS bill_count,
    GROUP_CONCAT(bill_id)   AS duplicate_bill_ids,
    SUM(total_amount)       AS combined_amount,
    'DUPLICATE ADMISSION BILL' AS flag
FROM bills
WHERE admission_id IS NOT NULL
GROUP BY admission_id
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------------------------
-- ANOMALY 3: GHOST BILLS — bill exists but has no linked appointment or admission.
-- ----------------------------------------------------------------------------
SELECT
    bill_id, patient_id, bill_date, total_amount, status,
    'GHOST BILL — no service linked' AS flag
FROM bills
WHERE appointment_id IS NULL
  AND admission_id   IS NULL;

-- ----------------------------------------------------------------------------
-- ANOMALY 4: SAME BILL CLAIMED MULTIPLE TIMES (against different policies).
-- ----------------------------------------------------------------------------
SELECT
    bill_id,
    COUNT(*)                     AS claim_count,
    GROUP_CONCAT(claim_id)       AS claim_ids,
    GROUP_CONCAT(DISTINCT policy_id) AS policies_used,
    'DUPLICATE CLAIM SUBMISSION' AS flag
FROM claims
GROUP BY bill_id
HAVING COUNT(*) > 1;

-- ----------------------------------------------------------------------------
-- ANOMALY 5: PRESCRIPTIONS with NO valid link (neither appt nor admission).
-- ----------------------------------------------------------------------------
SELECT prescription_id, doctor_id, medicine_id, quantity, prescribed_date,
       'ORPHAN PRESCRIPTION' AS flag
FROM prescriptions
WHERE appointment_id IS NULL AND admission_id IS NULL;

-- ----------------------------------------------------------------------------
-- ANOMALY 6: IMPOSSIBLE STAY LENGTHS — discharge before admit, or > 60 days.
-- ----------------------------------------------------------------------------
SELECT
    admission_id, patient_id, admit_date, discharge_date,
    DATEDIFF(discharge_date, admit_date) AS los_days,
    CASE
        WHEN discharge_date < admit_date               THEN 'NEGATIVE STAY'
        WHEN DATEDIFF(discharge_date, admit_date) > 60 THEN 'UNUSUALLY LONG STAY'
    END AS flag
FROM admissions
WHERE discharge_date IS NOT NULL
  AND (discharge_date < admit_date
    OR DATEDIFF(discharge_date, admit_date) > 60);

-- ----------------------------------------------------------------------------
-- ANOMALY 7: CLAIM APPROVED for MORE than the bill amount (over-payment leak).
-- ----------------------------------------------------------------------------
SELECT
    c.claim_id, c.bill_id, b.total_amount, c.approved_amount,
    (c.approved_amount - b.total_amount) AS over_payment,
    'CLAIM > BILL — refund likely'       AS flag
FROM claims c
JOIN bills  b ON b.bill_id = c.bill_id
WHERE c.status = 'Approved'
  AND c.approved_amount > b.total_amount;

-- ----------------------------------------------------------------------------
-- ANOMALY 8: PATIENTS with too many visits in a short window (potential fraud).
--            > 5 appointments in any 30-day window.
-- ----------------------------------------------------------------------------
WITH patient_visits AS (
    SELECT
        patient_id,
        appointment_date,
        COUNT(*) OVER (
            PARTITION BY patient_id
            ORDER BY appointment_date
            RANGE BETWEEN INTERVAL 30 DAY PRECEDING AND CURRENT ROW
        ) AS visits_last_30d
    FROM appointments
)
SELECT DISTINCT
    p.patient_id, p.name, pv.visits_last_30d,
    'EXCESSIVE VISITS — potential doctor-shopping' AS flag
FROM patient_visits pv
JOIN patients p ON p.patient_id = pv.patient_id
WHERE pv.visits_last_30d > 5;

-- ----------------------------------------------------------------------------
-- ANOMALY 9: SAME PATIENT admitted to TWO hospitals on OVERLAPPING dates
--            (impossible — indicates data entry / fraud issue).
-- ----------------------------------------------------------------------------
SELECT
    a1.patient_id,
    a1.admission_id AS admit_1, a1.hospital_id AS hosp_1, a1.admit_date AS start_1, a1.discharge_date AS end_1,
    a2.admission_id AS admit_2, a2.hospital_id AS hosp_2, a2.admit_date AS start_2, a2.discharge_date AS end_2,
    'OVERLAPPING ADMISSIONS' AS flag
FROM admissions a1
JOIN admissions a2
     ON a1.patient_id  = a2.patient_id
    AND a1.admission_id < a2.admission_id
    AND a1.hospital_id  <> a2.hospital_id
    AND a1.admit_date <= COALESCE(a2.discharge_date, CURDATE())
    AND a2.admit_date <= COALESCE(a1.discharge_date, CURDATE());

-- ----------------------------------------------------------------------------
-- ANOMALY 10: HIGH-VALUE CLAIMS with fast approval (< 1 day) — audit trigger.
-- ----------------------------------------------------------------------------
SELECT
    c.claim_id, c.bill_id, c.claim_amount,
    DATEDIFF(c.claim_date, b.bill_date) AS days_to_claim,
    'HIGH-VALUE FAST CLAIM — audit' AS flag
FROM claims c
JOIN bills b ON b.bill_id = c.bill_id
WHERE c.status = 'Approved'
  AND c.claim_amount > 100000
  AND DATEDIFF(c.claim_date, b.bill_date) <= 1;

-- ----------------------------------------------------------------------------
-- SUMMARY DASHBOARD — one row per fraud category.
-- ----------------------------------------------------------------------------
SELECT 'Duplicate admission bills' AS category,
       COUNT(*) AS incidents
FROM (SELECT admission_id FROM bills
      WHERE admission_id IS NOT NULL
      GROUP BY admission_id HAVING COUNT(*)>1) x
UNION ALL
SELECT 'Ghost bills', COUNT(*)
FROM bills WHERE appointment_id IS NULL AND admission_id IS NULL
UNION ALL
SELECT 'Duplicate claims', COUNT(*)
FROM (SELECT bill_id FROM claims GROUP BY bill_id HAVING COUNT(*)>1) y
UNION ALL
SELECT 'Orphan prescriptions', COUNT(*)
FROM prescriptions WHERE appointment_id IS NULL AND admission_id IS NULL;
