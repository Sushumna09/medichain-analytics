-- ============================================================================
-- FILE  : 08_window_functions.sql
-- TOPIC : ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, running totals,
--         moving averages, PARTITION BY, ORDER BY within window
-- LEVEL : Advanced   (ZS, Amazon, Meta love this topic)
-- WHY   : Windows solve "top-N per group" and time-series comparisons cleanly.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. ROW_NUMBER — number every appointment per doctor in chronological order.
-- ----------------------------------------------------------------------------
SELECT
    doctor_id,
    appointment_id,
    appointment_date,
    ROW_NUMBER() OVER (PARTITION BY doctor_id ORDER BY appointment_date) AS visit_num
FROM appointments;

-- ----------------------------------------------------------------------------
-- Q2. RANK vs DENSE_RANK vs ROW_NUMBER on doctor salaries.
-- ----------------------------------------------------------------------------
SELECT
    name, salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK()       OVER (ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS d_rnk
FROM staff
WHERE role = 'Doctor';

-- ----------------------------------------------------------------------------
-- Q3. TOP-N PER GROUP — top 3 highest-paid doctor per hospital.
--      One of the MOST asked interview questions.
-- ----------------------------------------------------------------------------
WITH ranked AS (
    SELECT
        s.staff_id, s.name, s.salary, h.name AS hospital,
        RANK() OVER (PARTITION BY h.hospital_id ORDER BY s.salary DESC) AS rnk
    FROM staff s
    JOIN hospitals h ON h.hospital_id = s.hospital_id
    WHERE s.role = 'Doctor'
)
SELECT hospital, name, salary, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY hospital, rnk;

-- ----------------------------------------------------------------------------
-- Q4. LAG — for each patient, show days since their PREVIOUS appointment.
--      Great for "gap analysis" / follow-up compliance.
-- ----------------------------------------------------------------------------
SELECT
    patient_id,
    appointment_id,
    appointment_date,
    LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date) AS prev_visit,
    DATEDIFF(
        appointment_date,
        LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date)
    ) AS days_since_prev
FROM appointments;

-- ----------------------------------------------------------------------------
-- Q5. LEAD — predict NEXT admission date for each patient.
-- ----------------------------------------------------------------------------
SELECT
    patient_id,
    admission_id,
    admit_date,
    LEAD(admit_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS next_admit
FROM admissions;

-- ----------------------------------------------------------------------------
-- Q6. RUNNING TOTAL — cumulative revenue over time (chain-wide).
-- ----------------------------------------------------------------------------
WITH daily_revenue AS (
    SELECT bill_date, SUM(total_amount) AS daily_total
    FROM bills
    WHERE status = 'Paid'
    GROUP BY bill_date
)
SELECT
    bill_date,
    daily_total,
    SUM(daily_total) OVER (ORDER BY bill_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM daily_revenue
ORDER BY bill_date;

-- ----------------------------------------------------------------------------
-- Q7. MOVING AVERAGE — 7-day rolling average of daily revenue.
-- ----------------------------------------------------------------------------
WITH daily_revenue AS (
    SELECT bill_date, SUM(total_amount) AS daily_total
    FROM bills
    WHERE status = 'Paid'
    GROUP BY bill_date
)
SELECT
    bill_date,
    daily_total,
    ROUND(
        AVG(daily_total) OVER (ORDER BY bill_date
                               ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
    0) AS rolling_7d_avg
FROM daily_revenue
ORDER BY bill_date;

-- ----------------------------------------------------------------------------
-- Q8. NTILE — bucket patients into 4 quartiles by total spend.
-- ----------------------------------------------------------------------------
WITH patient_spend AS (
    SELECT patient_id, SUM(total_amount) AS spend
    FROM bills WHERE status = 'Paid'
    GROUP BY patient_id
)
SELECT
    patient_id, spend,
    NTILE(4) OVER (ORDER BY spend DESC) AS spend_quartile
FROM patient_spend;

-- ----------------------------------------------------------------------------
-- Q9. FIRST_VALUE / LAST_VALUE — first and last admission diagnosis per patient.
-- ----------------------------------------------------------------------------
SELECT DISTINCT
    patient_id,
    FIRST_VALUE(diagnosis) OVER (
        PARTITION BY patient_id ORDER BY admit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_dx,
    LAST_VALUE(diagnosis) OVER (
        PARTITION BY patient_id ORDER BY admit_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_dx,
    COUNT(*) OVER (PARTITION BY patient_id) AS total_admissions
FROM admissions;

-- ----------------------------------------------------------------------------
-- Q10. PERCENT_RANK — where does each doctor fall in the salary distribution?
-- ----------------------------------------------------------------------------
SELECT
    name, salary,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary) * 100, 1) AS salary_percentile
FROM staff
WHERE role = 'Doctor';

-- ----------------------------------------------------------------------------
-- Q11. Compare each doctor's revenue to average of their hospital.
--      Very ZS-style: "how does X compare to peers?"
-- ----------------------------------------------------------------------------
WITH doctor_rev AS (
    SELECT
        s.staff_id, s.name AS doctor, s.hospital_id,
        SUM(b.total_amount) AS revenue
    FROM bills b
    JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN staff s ON s.staff_id = ap.doctor_id
    WHERE b.status = 'Paid'
    GROUP BY s.staff_id, s.name, s.hospital_id
)
SELECT
    doctor,
    hospital_id,
    revenue,
    ROUND(AVG(revenue) OVER (PARTITION BY hospital_id), 0) AS hospital_avg,
    ROUND(revenue - AVG(revenue) OVER (PARTITION BY hospital_id), 0) AS delta_vs_avg
FROM doctor_rev
ORDER BY hospital_id, delta_vs_avg DESC;

-- ----------------------------------------------------------------------------
-- Q12. Month-over-month admission growth using LAG.
-- ----------------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_FORMAT(admit_date, '%Y-%m') AS ym,
           COUNT(*) AS admissions
    FROM admissions
    GROUP BY DATE_FORMAT(admit_date, '%Y-%m')
)
SELECT
    ym,
    admissions,
    LAG(admissions) OVER (ORDER BY ym) AS prev_month,
    ROUND(
        (admissions - LAG(admissions) OVER (ORDER BY ym)) * 100.0
        / NULLIF(LAG(admissions) OVER (ORDER BY ym), 0),
    2) AS mom_growth_pct
FROM monthly
ORDER BY ym;
