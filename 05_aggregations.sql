-- ============================================================================
-- FILE  : 05_aggregations.sql
-- TOPIC : COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING
-- LEVEL : Beginner → Intermediate
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Simple aggregates on patients.
-- ----------------------------------------------------------------------------
SELECT
    COUNT(*)                                    AS total_patients,
    SUM(has_chronic_condition)                  AS chronic_patients,
    ROUND(AVG(TIMESTAMPDIFF(YEAR, dob, CURDATE())), 1) AS avg_age
FROM patients;

-- ----------------------------------------------------------------------------
-- Q2. Number of doctors per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    COUNT(*) AS doctor_count
FROM staff s
JOIN hospitals h ON h.hospital_id = s.hospital_id
WHERE s.role = 'Doctor'
GROUP BY h.hospital_id, h.name
ORDER BY doctor_count DESC;

-- ----------------------------------------------------------------------------
-- Q3. Appointments per status.
-- ----------------------------------------------------------------------------
SELECT status, COUNT(*) AS cnt
FROM appointments
GROUP BY status;

-- ----------------------------------------------------------------------------
-- Q4. Revenue per hospital (from paid bills only).
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    SUM(b.total_amount) AS revenue
FROM bills b
JOIN patients p   ON p.patient_id = b.patient_id
LEFT JOIN admissions a  ON a.admission_id  = b.admission_id
LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
WHERE b.status = 'Paid'
GROUP BY h.hospital_id, h.name
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- Q5. Average consultation fee per doctor.
-- ----------------------------------------------------------------------------
SELECT
    s.name AS doctor,
    ROUND(AVG(a.consultation_fee), 2) AS avg_fee,
    COUNT(*) AS total_appts
FROM appointments a
JOIN staff s ON s.staff_id = a.doctor_id
WHERE a.status = 'Attended'
GROUP BY s.staff_id, s.name
ORDER BY avg_fee DESC;

-- ----------------------------------------------------------------------------
-- Q6. HAVING — departments with more than 3 staff members.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    d.name AS department,
    COUNT(*) AS staff_count
FROM staff s
JOIN departments d ON d.department_id = s.department_id
JOIN hospitals  h ON h.hospital_id   = s.hospital_id
GROUP BY h.hospital_id, d.department_id, h.name, d.name
HAVING COUNT(*) > 3
ORDER BY staff_count DESC;

-- ----------------------------------------------------------------------------
-- Q7. HAVING vs WHERE — total prescriptions per doctor, only those > 5.
--      (WHERE filters BEFORE aggregation, HAVING filters AFTER)
-- ----------------------------------------------------------------------------
SELECT
    s.name AS doctor,
    COUNT(*) AS rx_count
FROM prescriptions rx
JOIN staff s ON s.staff_id = rx.doctor_id
WHERE s.role = 'Doctor'                -- filter BEFORE aggregation
GROUP BY s.staff_id, s.name
HAVING COUNT(*) > 5                    -- filter AFTER aggregation
ORDER BY rx_count DESC;

-- ----------------------------------------------------------------------------
-- Q8. Group by 2 columns — admissions by hospital & diagnosis.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    a.diagnosis,
    COUNT(*) AS admissions
FROM admissions a
JOIN hospitals h ON h.hospital_id = a.hospital_id
GROUP BY h.hospital_id, a.diagnosis
ORDER BY h.name, admissions DESC;

-- ----------------------------------------------------------------------------
-- Q9. Bed capacity vs actual admissions per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name,
    h.total_beds,
    COUNT(a.admission_id) AS admissions_lifetime,
    ROUND(COUNT(a.admission_id) / h.total_beds, 2) AS admissions_per_bed
FROM hospitals h
LEFT JOIN admissions a ON a.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.total_beds
ORDER BY admissions_per_bed DESC;

-- ----------------------------------------------------------------------------
-- Q10. Claim summary — approved / rejected / pending amounts by insurer.
-- ----------------------------------------------------------------------------
SELECT
    ic.name AS insurer,
    SUM(CASE WHEN c.status='Approved' THEN c.approved_amount END) AS approved_sum,
    SUM(CASE WHEN c.status='Rejected' THEN c.claim_amount    END) AS rejected_sum,
    SUM(CASE WHEN c.status='Pending'  THEN c.claim_amount    END) AS pending_sum,
    COUNT(*) AS total_claims
FROM claims c
JOIN patient_insurance_policies p ON p.policy_id  = c.policy_id
JOIN insurance_companies       ic ON ic.insurer_id = p.insurer_id
GROUP BY ic.insurer_id, ic.name
ORDER BY total_claims DESC;

-- ----------------------------------------------------------------------------
-- Q11. Average length of stay per diagnosis (for discharged patients only).
-- ----------------------------------------------------------------------------
SELECT
    diagnosis,
    ROUND(AVG(DATEDIFF(discharge_date, admit_date)), 1) AS avg_los_days,
    COUNT(*) AS cases
FROM admissions
WHERE discharge_date IS NOT NULL
GROUP BY diagnosis
ORDER BY avg_los_days DESC;

-- ----------------------------------------------------------------------------
-- Q12. Grouped payment method breakdown.
-- ----------------------------------------------------------------------------
SELECT
    payment_method,
    COUNT(*)         AS payment_count,
    SUM(amount)      AS total_collected,
    AVG(amount)      AS avg_payment
FROM payments
GROUP BY payment_method
ORDER BY total_collected DESC;
