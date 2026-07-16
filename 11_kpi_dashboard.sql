-- ============================================================================
-- FILE  : 11_kpi_dashboard.sql
-- TOPIC : 15 real-world hospital operations KPIs
-- USE   : These are the queries you'd wire up to a Tableau / Power BI dashboard
--         for hospital management. Every KPI has a business explanation.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- KPI 1. Total revenue chain-wide (all-time).
-- ----------------------------------------------------------------------------
SELECT SUM(total_amount) AS total_revenue
FROM bills WHERE status='Paid';

-- ----------------------------------------------------------------------------
-- KPI 2. Revenue per hospital (branch-level performance).
-- ----------------------------------------------------------------------------
SELECT h.name, SUM(b.total_amount) AS revenue
FROM bills b
LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
WHERE b.status='Paid'
GROUP BY h.hospital_id, h.name
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- KPI 3. Revenue per bed  (efficiency metric — high = well-utilized).
-- ----------------------------------------------------------------------------
SELECT
    h.name,
    h.total_beds,
    ROUND(SUM(b.total_amount) / h.total_beds, 0) AS revenue_per_bed
FROM bills b
JOIN admissions a ON a.admission_id = b.admission_id
JOIN hospitals h ON h.hospital_id  = a.hospital_id
WHERE b.status='Paid'
GROUP BY h.hospital_id, h.name, h.total_beds
ORDER BY revenue_per_bed DESC;

-- ----------------------------------------------------------------------------
-- KPI 4. Average Length of Stay (ALOS) per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    ROUND(AVG(DATEDIFF(a.discharge_date, a.admit_date)), 1) AS avg_los_days
FROM admissions a
JOIN hospitals h ON h.hospital_id = a.hospital_id
WHERE a.discharge_date IS NOT NULL
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- KPI 5. Bed occupancy rate (rough) — currently admitted / total beds.
-- ----------------------------------------------------------------------------
SELECT
    h.name,
    h.total_beds,
    SUM(CASE WHEN a.discharge_date IS NULL THEN 1 ELSE 0 END) AS currently_occupied,
    ROUND(100.0 * SUM(CASE WHEN a.discharge_date IS NULL THEN 1 ELSE 0 END)
                 / h.total_beds, 2)                          AS occupancy_pct
FROM hospitals h
LEFT JOIN admissions a ON a.hospital_id = h.hospital_id
GROUP BY h.hospital_id, h.name, h.total_beds;

-- ----------------------------------------------------------------------------
-- KPI 6. 30-DAY READMISSION RATE per hospital (an industry benchmark).
--      A patient re-admitted within 30 days of prior discharge = readmission.
-- ----------------------------------------------------------------------------
WITH ordered AS (
    SELECT
        a.hospital_id,
        a.patient_id,
        a.admit_date,
        LAG(a.discharge_date) OVER (PARTITION BY a.patient_id ORDER BY a.admit_date) AS prev_dc
    FROM admissions a
    WHERE a.discharge_date IS NOT NULL
),
flagged AS (
    SELECT
        hospital_id,
        CASE WHEN prev_dc IS NOT NULL AND DATEDIFF(admit_date, prev_dc) BETWEEN 0 AND 30
             THEN 1 ELSE 0 END AS is_readmit
    FROM ordered
)
SELECT
    h.name,
    COUNT(*)                                              AS total_stays,
    SUM(f.is_readmit)                                     AS readmissions,
    ROUND(100.0 * SUM(f.is_readmit) / COUNT(*), 2)        AS readmit_rate_pct
FROM flagged f
JOIN hospitals h ON h.hospital_id = f.hospital_id
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- KPI 7. No-Show Rate per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name,
    COUNT(*) AS total_appts,
    SUM(a.status='No-Show') AS no_shows,
    ROUND(100.0 * SUM(a.status='No-Show') / COUNT(*), 2) AS no_show_rate_pct
FROM appointments a
JOIN hospitals h ON h.hospital_id = a.hospital_id
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- KPI 8. Claim REJECTION rate per insurer.
-- ----------------------------------------------------------------------------
SELECT
    ic.name AS insurer,
    COUNT(*)                                             AS total_claims,
    SUM(c.status='Rejected')                             AS rejected,
    ROUND(100.0 * SUM(c.status='Rejected') / COUNT(*),2) AS rejection_rate_pct
FROM claims c
JOIN patient_insurance_policies p ON p.policy_id  = c.policy_id
JOIN insurance_companies       ic ON ic.insurer_id = p.insurer_id
GROUP BY ic.insurer_id, ic.name;

-- ----------------------------------------------------------------------------
-- KPI 9. Doctor productivity — appointments + admissions per doctor.
-- ----------------------------------------------------------------------------
WITH doc_stats AS (
    SELECT s.staff_id, s.name,
           (SELECT COUNT(*) FROM appointments a WHERE a.doctor_id = s.staff_id) AS appts,
           (SELECT COUNT(*) FROM admissions ad WHERE ad.attending_doctor_id = s.staff_id) AS admits
    FROM staff s
    WHERE s.role='Doctor'
)
SELECT name, appts, admits, (appts + admits) AS total_cases
FROM doc_stats
ORDER BY total_cases DESC;

-- ----------------------------------------------------------------------------
-- KPI 10. Revenue per department per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    d.name AS department,
    SUM(b.total_amount) AS revenue
FROM bills b
JOIN appointments ap ON ap.appointment_id = b.appointment_id
JOIN staff s        ON s.staff_id = ap.doctor_id
JOIN departments d  ON d.department_id = s.department_id
JOIN hospitals h    ON h.hospital_id = ap.hospital_id
WHERE b.status='Paid'
GROUP BY h.hospital_id, d.department_id
ORDER BY hospital, revenue DESC;

-- ----------------------------------------------------------------------------
-- KPI 11. Repeat patients — patients with >1 visit (loyalty proxy).
-- ----------------------------------------------------------------------------
SELECT
    p.patient_id, p.name,
    COUNT(a.appointment_id) AS visits
FROM patients p
JOIN appointments a ON a.patient_id = p.patient_id
GROUP BY p.patient_id, p.name
HAVING COUNT(*) > 1
ORDER BY visits DESC;

-- ----------------------------------------------------------------------------
-- KPI 12. Average bill amount per admission type (long stay vs short).
-- ----------------------------------------------------------------------------
SELECT
    CASE
        WHEN DATEDIFF(a.discharge_date, a.admit_date) <= 3  THEN 'Short (0-3d)'
        WHEN DATEDIFF(a.discharge_date, a.admit_date) <= 7  THEN 'Medium (4-7d)'
        ELSE 'Long (>7d)'
    END AS stay_type,
    COUNT(*)                    AS admissions,
    ROUND(AVG(b.total_amount),0) AS avg_bill
FROM admissions a
JOIN bills b ON b.admission_id = a.admission_id
WHERE a.discharge_date IS NOT NULL
GROUP BY stay_type;

-- ----------------------------------------------------------------------------
-- KPI 13. Insurance coverage — % of paid bills settled by Insurance.
-- ----------------------------------------------------------------------------
SELECT
    ROUND(100.0 * SUM(CASE WHEN payment_method='Insurance' THEN amount ELSE 0 END)
                 / SUM(amount), 2) AS insurance_share_pct
FROM payments;

-- ----------------------------------------------------------------------------
-- KPI 14. Monthly new-patient acquisition (growth trend).
-- ----------------------------------------------------------------------------
SELECT
    DATE_FORMAT(registration_date, '%Y-%m') AS month,
    COUNT(*) AS new_patients
FROM patients
GROUP BY DATE_FORMAT(registration_date, '%Y-%m')
ORDER BY month;

-- ----------------------------------------------------------------------------
-- KPI 15. Top 5 diagnoses by revenue (where should we invest?)
-- ----------------------------------------------------------------------------
SELECT
    a.diagnosis,
    COUNT(*)               AS cases,
    SUM(b.total_amount)    AS revenue,
    ROUND(AVG(b.total_amount),0) AS avg_bill_per_case
FROM admissions a
JOIN bills b ON b.admission_id = a.admission_id
GROUP BY a.diagnosis
ORDER BY revenue DESC
LIMIT 5;
