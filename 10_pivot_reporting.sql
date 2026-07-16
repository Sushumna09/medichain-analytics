-- ============================================================================
-- FILE  : 10_pivot_reporting.sql
-- TOPIC : Pivot / Unpivot patterns using CASE + GROUP BY
--         (MySQL has no native PIVOT operator like SQL Server does)
-- LEVEL : Intermediate → Advanced
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. PIVOT — appointment status counts per hospital, one column per status.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    SUM(CASE WHEN a.status = 'Attended'  THEN 1 ELSE 0 END) AS attended,
    SUM(CASE WHEN a.status = 'No-Show'   THEN 1 ELSE 0 END) AS no_show,
    SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    COUNT(*)                                                 AS total
FROM appointments a
JOIN hospitals h ON h.hospital_id = a.hospital_id
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- Q2. PIVOT — monthly revenue matrix per hospital (rows = hospital, cols = month).
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    SUM(CASE WHEN MONTH(b.bill_date)=1  THEN b.total_amount ELSE 0 END) AS jan,
    SUM(CASE WHEN MONTH(b.bill_date)=2  THEN b.total_amount ELSE 0 END) AS feb,
    SUM(CASE WHEN MONTH(b.bill_date)=3  THEN b.total_amount ELSE 0 END) AS mar,
    SUM(CASE WHEN MONTH(b.bill_date)=4  THEN b.total_amount ELSE 0 END) AS apr,
    SUM(CASE WHEN MONTH(b.bill_date)=5  THEN b.total_amount ELSE 0 END) AS may,
    SUM(CASE WHEN MONTH(b.bill_date)=6  THEN b.total_amount ELSE 0 END) AS jun,
    SUM(CASE WHEN MONTH(b.bill_date)=7  THEN b.total_amount ELSE 0 END) AS jul,
    SUM(CASE WHEN MONTH(b.bill_date)=8  THEN b.total_amount ELSE 0 END) AS aug,
    SUM(CASE WHEN MONTH(b.bill_date)=9  THEN b.total_amount ELSE 0 END) AS sep,
    SUM(CASE WHEN MONTH(b.bill_date)=10 THEN b.total_amount ELSE 0 END) AS oct,
    SUM(CASE WHEN MONTH(b.bill_date)=11 THEN b.total_amount ELSE 0 END) AS nov,
    SUM(CASE WHEN MONTH(b.bill_date)=12 THEN b.total_amount ELSE 0 END) AS `dec`
FROM bills b
LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
WHERE YEAR(b.bill_date) = 2024
  AND b.status = 'Paid'
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- Q3. PIVOT — gender-wise patient count per city.
-- ----------------------------------------------------------------------------
SELECT
    city,
    SUM(gender='M') AS male,
    SUM(gender='F') AS female,
    SUM(gender='O') AS other,
    COUNT(*)        AS total
FROM patients
GROUP BY city
ORDER BY total DESC;

-- ----------------------------------------------------------------------------
-- Q4. PIVOT — payment method share per year.
-- ----------------------------------------------------------------------------
SELECT
    YEAR(payment_date) AS yr,
    SUM(CASE WHEN payment_method='Cash'      THEN amount ELSE 0 END) AS cash,
    SUM(CASE WHEN payment_method='Card'      THEN amount ELSE 0 END) AS card,
    SUM(CASE WHEN payment_method='UPI'       THEN amount ELSE 0 END) AS upi,
    SUM(CASE WHEN payment_method='Insurance' THEN amount ELSE 0 END) AS insurance,
    SUM(amount)                                                       AS total
FROM payments
GROUP BY YEAR(payment_date)
ORDER BY yr;

-- ----------------------------------------------------------------------------
-- Q5. UNPIVOT (via UNION ALL) — turn a wide row into a long form.
--      Take the monthly revenue matrix (Q2) and un-pivot to (hospital, month, revenue).
-- ----------------------------------------------------------------------------
SELECT hospital, 'Jan' AS month, jan AS revenue FROM (
    SELECT
        h.name AS hospital,
        SUM(CASE WHEN MONTH(b.bill_date)=1 THEN b.total_amount ELSE 0 END) AS jan,
        SUM(CASE WHEN MONTH(b.bill_date)=2 THEN b.total_amount ELSE 0 END) AS feb
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE YEAR(b.bill_date)=2024 AND b.status='Paid'
    GROUP BY h.hospital_id, h.name
) t
UNION ALL
SELECT hospital, 'Feb', feb FROM (
    SELECT
        h.name AS hospital,
        SUM(CASE WHEN MONTH(b.bill_date)=1 THEN b.total_amount ELSE 0 END) AS jan,
        SUM(CASE WHEN MONTH(b.bill_date)=2 THEN b.total_amount ELSE 0 END) AS feb
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE YEAR(b.bill_date)=2024 AND b.status='Paid'
    GROUP BY h.hospital_id, h.name
) t;

-- ----------------------------------------------------------------------------
-- Q6. PIVOT — diagnosis vs discharge_status matrix.
-- ----------------------------------------------------------------------------
SELECT
    diagnosis,
    SUM(discharge_status='Recovered')   AS recovered,
    SUM(discharge_status='Transferred') AS transferred,
    SUM(discharge_status='DAMA')        AS dama,
    SUM(discharge_status='Deceased')    AS deceased
FROM admissions
WHERE discharge_status IS NOT NULL
GROUP BY diagnosis
ORDER BY diagnosis;
