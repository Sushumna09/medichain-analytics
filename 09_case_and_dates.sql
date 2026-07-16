-- ============================================================================
-- FILE  : 09_case_and_dates.sql
-- TOPIC : CASE WHEN, conditional aggregation, date/time functions,
--         YoY %, MoM %, age & length-of-stay bucketing
-- LEVEL : Intermediate
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Bucket patients by age group (CASE WHEN).
-- ----------------------------------------------------------------------------
SELECT
    CASE
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 18 THEN '0-17 (Pediatric)'
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 40 THEN '18-39 (Young Adult)'
        WHEN TIMESTAMPDIFF(YEAR, dob, CURDATE()) < 60 THEN '40-59 (Middle Age)'
        ELSE '60+ (Senior)'
    END AS age_group,
    COUNT(*) AS patients
FROM patients
GROUP BY age_group
ORDER BY patients DESC;

-- ----------------------------------------------------------------------------
-- Q2. Conditional aggregation — attended vs no-show count per doctor.
-- ----------------------------------------------------------------------------
SELECT
    s.name AS doctor,
    SUM(CASE WHEN a.status = 'Attended'  THEN 1 ELSE 0 END) AS attended,
    SUM(CASE WHEN a.status = 'No-Show'   THEN 1 ELSE 0 END) AS no_shows,
    SUM(CASE WHEN a.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    ROUND(100.0 * SUM(CASE WHEN a.status = 'No-Show' THEN 1 ELSE 0 END)
                / COUNT(*), 2)                               AS no_show_pct
FROM appointments a
JOIN staff s ON s.staff_id = a.doctor_id
GROUP BY s.staff_id, s.name
ORDER BY no_show_pct DESC;

-- ----------------------------------------------------------------------------
-- Q3. Length-of-stay buckets.
-- ----------------------------------------------------------------------------
SELECT
    CASE
        WHEN DATEDIFF(discharge_date, admit_date) <= 3  THEN '0-3 days'
        WHEN DATEDIFF(discharge_date, admit_date) <= 7  THEN '4-7 days'
        WHEN DATEDIFF(discharge_date, admit_date) <= 14 THEN '8-14 days'
        ELSE '15+ days'
    END AS los_bucket,
    COUNT(*) AS admissions
FROM admissions
WHERE discharge_date IS NOT NULL
GROUP BY los_bucket
ORDER BY MIN(DATEDIFF(discharge_date, admit_date));

-- ----------------------------------------------------------------------------
-- Q4. Bill status flag + basic segment.
-- ----------------------------------------------------------------------------
SELECT
    bill_id, total_amount, status,
    CASE
        WHEN status = 'Paid'          THEN 'Cleared'
        WHEN status = 'Partially Paid' THEN 'Follow-up'
        ELSE 'Unpaid — Escalate'
    END AS collection_action
FROM bills;

-- ----------------------------------------------------------------------------
-- Q5. Extract parts of a date.
-- ----------------------------------------------------------------------------
SELECT
    appointment_id,
    appointment_date,
    YEAR(appointment_date)     AS yr,
    MONTH(appointment_date)    AS mo,
    DAY(appointment_date)      AS dy,
    DAYNAME(appointment_date)  AS day_of_week,
    QUARTER(appointment_date)  AS qtr
FROM appointments;

-- ----------------------------------------------------------------------------
-- Q6. Monthly revenue trend.
-- ----------------------------------------------------------------------------
SELECT
    DATE_FORMAT(bill_date, '%Y-%m') AS ym,
    SUM(total_amount)               AS revenue
FROM bills
WHERE status = 'Paid'
GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
ORDER BY ym;

-- ----------------------------------------------------------------------------
-- Q7. YEAR-OVER-YEAR revenue growth using self-join on monthly aggregates.
--      (LAG version is in file 08 — this is the "old-school" way.)
-- ----------------------------------------------------------------------------
WITH monthly AS (
    SELECT
        YEAR(bill_date)  AS yr,
        MONTH(bill_date) AS mo,
        SUM(total_amount) AS revenue
    FROM bills
    WHERE status = 'Paid'
    GROUP BY YEAR(bill_date), MONTH(bill_date)
)
SELECT
    curr.yr, curr.mo,
    curr.revenue                                            AS this_year,
    prev.revenue                                            AS last_year,
    ROUND((curr.revenue - prev.revenue) * 100.0
          / NULLIF(prev.revenue, 0), 2)                     AS yoy_growth_pct
FROM monthly curr
LEFT JOIN monthly prev
       ON prev.mo = curr.mo
      AND prev.yr = curr.yr - 1
ORDER BY curr.yr, curr.mo;

-- ----------------------------------------------------------------------------
-- Q8. Weekday appointment demand — which days are the busiest?
-- ----------------------------------------------------------------------------
SELECT
    DAYNAME(appointment_date) AS day_of_week,
    COUNT(*)                  AS appts,
    ROUND(AVG(consultation_fee), 0) AS avg_fee
FROM appointments
GROUP BY DAYNAME(appointment_date)
ORDER BY FIELD(DAYNAME(appointment_date),
               'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- ----------------------------------------------------------------------------
-- Q9. Time-since-registration cohort: patient tenure buckets.
-- ----------------------------------------------------------------------------
SELECT
    CASE
        WHEN DATEDIFF(CURDATE(), registration_date) < 90  THEN 'New (<3mo)'
        WHEN DATEDIFF(CURDATE(), registration_date) < 365 THEN 'Regular (3-12mo)'
        ELSE 'Long-term (>1yr)'
    END AS tenure,
    COUNT(*) AS patients
FROM patients
GROUP BY tenure;

-- ----------------------------------------------------------------------------
-- Q10. CASE inside SUM — revenue split by payment method per hospital.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    SUM(CASE WHEN pay.payment_method = 'Cash'      THEN pay.amount ELSE 0 END) AS cash,
    SUM(CASE WHEN pay.payment_method = 'Card'      THEN pay.amount ELSE 0 END) AS card,
    SUM(CASE WHEN pay.payment_method = 'UPI'       THEN pay.amount ELSE 0 END) AS upi,
    SUM(CASE WHEN pay.payment_method = 'Insurance' THEN pay.amount ELSE 0 END) AS insurance
FROM payments pay
JOIN bills b ON b.bill_id = pay.bill_id
LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
GROUP BY h.hospital_id, h.name;
