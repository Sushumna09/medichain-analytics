-- ============================================================================
-- FILE  : 14_interview_questions.sql
-- PURPOSE: 30 SQL interview problems drawn from company style-guides.
--          Each problem has:  * Company style / difficulty
--                             * The problem statement
--                             * A solution query
--
-- SECTIONS:
--   A. Fundamentals (Q1-Q6)
--   B. Joins & Aggregation (Q7-Q13)
--   C. Subqueries & CTEs (Q14-Q19)
--   D. Window Functions (Q20-Q25)
--   E. Consulting / Business style — ZS, Deloitte, Accenture (Q26-Q30)
-- ============================================================================

-- ============================================================================
-- SECTION A — FUNDAMENTALS
-- ============================================================================

-- Q1 [Easy | TCS/Infosys style]
-- Q: Find all patients from Bengaluru who registered in 2024.
SELECT patient_id, name, registration_date
FROM patients
WHERE city = 'Bengaluru'
  AND YEAR(registration_date) = 2024;

-- Q2 [Easy]
-- Q: How many doctors work in each hospital?
SELECT h.name, COUNT(*) AS doctors
FROM staff s JOIN hospitals h ON h.hospital_id = s.hospital_id
WHERE s.role='Doctor'
GROUP BY h.hospital_id, h.name;

-- Q3 [Easy]
-- Q: List the top 5 most-prescribed medicines by total quantity.
SELECT m.name, SUM(rx.quantity) AS total_qty
FROM prescriptions rx JOIN medicines m ON m.medicine_id = rx.medicine_id
GROUP BY m.medicine_id, m.name
ORDER BY total_qty DESC
LIMIT 5;

-- Q4 [Easy]
-- Q: Find rooms that are ICU AND currently occupied.
SELECT room_id, hospital_id, room_number, daily_charge
FROM rooms
WHERE room_type = 'ICU' AND status = 'Occupied';

-- Q5 [Easy]
-- Q: What percentage of patients are chronic patients?
SELECT
    ROUND(100.0 * SUM(has_chronic_condition) / COUNT(*), 2) AS chronic_pct
FROM patients;

-- Q6 [Easy]
-- Q: Show patient count per blood group, most common first.
SELECT blood_group, COUNT(*) AS cnt
FROM patients
GROUP BY blood_group
ORDER BY cnt DESC;

-- ============================================================================
-- SECTION B — JOINS & AGGREGATION
-- ============================================================================

-- Q7 [Medium | Amazon/Flipkart style]
-- Q: For each hospital, list top-earning doctor by total consultation-fee revenue.
WITH doc_rev AS (
    SELECT s.hospital_id, s.staff_id, s.name,
           SUM(a.consultation_fee) AS rev
    FROM appointments a JOIN staff s ON s.staff_id = a.doctor_id
    WHERE a.status='Attended'
    GROUP BY s.hospital_id, s.staff_id, s.name
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY hospital_id ORDER BY rev DESC) AS r
    FROM doc_rev
)
SELECT h.name AS hospital, ranked.name AS top_doctor, rev
FROM ranked JOIN hospitals h ON h.hospital_id = ranked.hospital_id
WHERE r = 1;

-- Q8 [Medium]
-- Q: Number of unique patients seen by each doctor.
SELECT s.name AS doctor, COUNT(DISTINCT a.patient_id) AS unique_patients
FROM appointments a JOIN staff s ON s.staff_id = a.doctor_id
GROUP BY s.staff_id, s.name
ORDER BY unique_patients DESC;

-- Q9 [Medium]
-- Q: Which hospitals have never had a claim rejected?
SELECT h.hospital_id, h.name
FROM hospitals h
WHERE h.hospital_id NOT IN (
    SELECT DISTINCT ap.hospital_id
    FROM claims c
    JOIN bills b ON b.bill_id = c.bill_id
    JOIN appointments ap ON ap.appointment_id = b.appointment_id
    WHERE c.status='Rejected'
);

-- Q10 [Medium]
-- Q: For each department, avg salary AND # of doctors.
SELECT
    h.name AS hospital, d.name AS department,
    COUNT(*) AS doctors,
    ROUND(AVG(s.salary),0) AS avg_salary
FROM staff s
JOIN departments d ON d.department_id = s.department_id
JOIN hospitals h  ON h.hospital_id = s.hospital_id
WHERE s.role='Doctor'
GROUP BY h.hospital_id, d.department_id;

-- Q11 [Medium]
-- Q: Find hospitals whose total revenue is above the chain-wide average.
WITH rev AS (
    SELECT h.hospital_id, h.name, SUM(b.total_amount) AS r
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status='Paid'
    GROUP BY h.hospital_id, h.name
)
SELECT * FROM rev
WHERE r > (SELECT AVG(r) FROM rev);

-- Q12 [Medium]
-- Q: Insurance companies that cover more than 3 patients.
SELECT ic.name, COUNT(DISTINCT p.patient_id) AS patients
FROM insurance_companies ic
JOIN patient_insurance_policies p ON p.insurer_id = ic.insurer_id
GROUP BY ic.insurer_id, ic.name
HAVING COUNT(DISTINCT p.patient_id) > 3;

-- Q13 [Medium]
-- Q: Find the doctor with highest no-show rate (min 3 appointments).
SELECT s.name,
       COUNT(*) AS total,
       SUM(a.status='No-Show') AS no_shows,
       ROUND(100.0*SUM(a.status='No-Show')/COUNT(*),2) AS no_show_pct
FROM appointments a
JOIN staff s ON s.staff_id = a.doctor_id
GROUP BY s.staff_id, s.name
HAVING COUNT(*) >= 3
ORDER BY no_show_pct DESC
LIMIT 1;

-- ============================================================================
-- SECTION C — SUBQUERIES & CTEs
-- ============================================================================

-- Q14 [Medium | Classic interview]
-- Q: Nth highest salary among doctors (here N=3).
SELECT DISTINCT salary
FROM (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rk
    FROM staff WHERE role='Doctor'
) t
WHERE rk = 3;

-- Q15 [Medium]
-- Q: Patients who have been admitted more than once.
SELECT patient_id, COUNT(*) AS admits
FROM admissions
GROUP BY patient_id
HAVING COUNT(*) > 1;

-- Q16 [Medium]
-- Q: For each medicine, show what % of total prescription volume it accounts for.
WITH med_qty AS (
    SELECT medicine_id, SUM(quantity) AS qty
    FROM prescriptions
    GROUP BY medicine_id
)
SELECT m.name, mq.qty,
       ROUND(100.0 * mq.qty / (SELECT SUM(qty) FROM med_qty), 2) AS pct_share
FROM med_qty mq JOIN medicines m ON m.medicine_id = mq.medicine_id
ORDER BY pct_share DESC;

-- Q17 [Hard]
-- Q: List patients whose most recent bill was UNPAID.
WITH latest AS (
    SELECT patient_id, MAX(bill_date) AS last_bill
    FROM bills GROUP BY patient_id
)
SELECT p.patient_id, p.name, b.bill_id, b.total_amount, b.status
FROM latest l
JOIN bills b ON b.patient_id = l.patient_id AND b.bill_date = l.last_bill
JOIN patients p ON p.patient_id = l.patient_id
WHERE b.status <> 'Paid';

-- Q18 [Hard | ZS style]
-- Q: Doctors whose salary is above the average of their hospital.
SELECT s.staff_id, s.name, s.salary, s.hospital_id
FROM staff s
WHERE s.role='Doctor'
  AND s.salary > (
      SELECT AVG(s2.salary)
      FROM staff s2
      WHERE s2.hospital_id = s.hospital_id AND s2.role='Doctor'
  );

-- Q19 [Hard]
-- Q: Recursive: give the full "reporting chain" for staff_id 19.
WITH RECURSIVE chain AS (
    SELECT staff_id, name, manager_id, 0 AS lvl
    FROM staff WHERE staff_id = 19
    UNION ALL
    SELECT s.staff_id, s.name, s.manager_id, c.lvl+1
    FROM staff s JOIN chain c ON s.staff_id = c.manager_id
)
SELECT * FROM chain ORDER BY lvl;

-- ============================================================================
-- SECTION D — WINDOW FUNCTIONS
-- ============================================================================

-- Q20 [Hard | Amazon/Meta favorite]
-- Q: For each patient show the gap (in days) between consecutive appointments.
SELECT
    patient_id, appointment_date,
    DATEDIFF(appointment_date,
             LAG(appointment_date) OVER (PARTITION BY patient_id ORDER BY appointment_date))
        AS gap_days
FROM appointments;

-- Q21 [Hard]
-- Q: Rank rooms by daily_charge within each room_type.
SELECT room_id, room_type, daily_charge,
       DENSE_RANK() OVER (PARTITION BY room_type ORDER BY daily_charge DESC) AS price_rank
FROM rooms;

-- Q22 [Hard]
-- Q: 3-month rolling avg of monthly admissions.
WITH m AS (
    SELECT DATE_FORMAT(admit_date,'%Y-%m') AS ym, COUNT(*) AS cnt
    FROM admissions GROUP BY DATE_FORMAT(admit_date,'%Y-%m')
)
SELECT ym, cnt,
       ROUND(AVG(cnt) OVER (ORDER BY ym ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),1) AS rolling_3m_avg
FROM m ORDER BY ym;

-- Q23 [Hard]
-- Q: Cumulative revenue per hospital by month.
WITH monthly AS (
    SELECT h.hospital_id, h.name, DATE_FORMAT(b.bill_date,'%Y-%m') AS ym,
           SUM(b.total_amount) AS rev
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status='Paid'
    GROUP BY h.hospital_id, h.name, DATE_FORMAT(b.bill_date,'%Y-%m')
)
SELECT name, ym, rev,
       SUM(rev) OVER (PARTITION BY hospital_id ORDER BY ym) AS cumulative_rev
FROM monthly;

-- Q24 [Hard]
-- Q: For each patient, mark whether current admission was a 30-day readmission.
SELECT
    patient_id, admission_id, admit_date,
    LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS prev_discharge,
    CASE WHEN DATEDIFF(admit_date,
              LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admit_date)) <= 30
         THEN 'READMISSION' ELSE 'FIRST/NEW' END AS flag
FROM admissions;

-- Q25 [Hard]
-- Q: Percentile-rank of every doctor by number of prescriptions written.
WITH rx AS (
    SELECT doctor_id, COUNT(*) AS c
    FROM prescriptions GROUP BY doctor_id
)
SELECT s.name, rx.c,
       ROUND(PERCENT_RANK() OVER (ORDER BY rx.c) * 100, 1) AS percentile
FROM rx JOIN staff s ON s.staff_id = rx.doctor_id
ORDER BY percentile DESC;

-- ============================================================================
-- SECTION E — CONSULTING / BUSINESS STYLE (ZS, Deloitte, Accenture)
-- ============================================================================

-- Q26 [ZS style]
-- Q: "Which branch's Cardiology dept had the highest YoY revenue growth?"
WITH cardio_rev AS (
    SELECT
        h.hospital_id, h.name AS hospital,
        YEAR(b.bill_date) AS yr,
        SUM(b.total_amount) AS rev
    FROM bills b
    JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN staff s         ON s.staff_id = ap.doctor_id
    JOIN departments d   ON d.department_id = s.department_id AND d.name='Cardiology'
    JOIN hospitals h     ON h.hospital_id = ap.hospital_id
    WHERE b.status='Paid'
    GROUP BY h.hospital_id, h.name, YEAR(b.bill_date)
),
growth AS (
    SELECT c.hospital, c.yr, c.rev,
           LAG(c.rev) OVER (PARTITION BY c.hospital_id ORDER BY c.yr) AS prev
    FROM cardio_rev c
)
SELECT hospital, yr, rev, prev,
       ROUND((rev - prev)*100.0/NULLIF(prev,0),2) AS yoy_pct
FROM growth
WHERE prev IS NOT NULL
ORDER BY yoy_pct DESC;

-- Q27 [ZS style]
-- Q: "MARKET SHARE" — what % of chain-wide admissions is each hospital?
SELECT
    h.name,
    COUNT(*) AS admissions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM admissions a JOIN hospitals h ON h.hospital_id = a.hospital_id
GROUP BY h.hospital_id, h.name
ORDER BY share_pct DESC;

-- Q28 [Deloitte/consulting style]
-- Q: "Top-3 prescribers per department" — with tie-handling.
WITH rx AS (
    SELECT s.staff_id, s.name, s.department_id, COUNT(*) AS rx_count
    FROM prescriptions rx JOIN staff s ON s.staff_id = rx.doctor_id
    GROUP BY s.staff_id, s.name, s.department_id
),
ranked AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY department_id ORDER BY rx_count DESC) AS r
    FROM rx
)
SELECT d.name AS dept, r.name AS doctor, r.rx_count, r.r AS rank_in_dept
FROM ranked r JOIN departments d ON d.department_id = r.department_id
WHERE r.r <= 3
ORDER BY d.name, r.r;

-- Q29 [Accenture style]
-- Q: "Cohort analysis" — for patients registered in Jan-2024, how many were
--     still active (had a bill) in each subsequent month?
WITH cohort AS (
    SELECT patient_id
    FROM patients
    WHERE DATE_FORMAT(registration_date,'%Y-%m') = '2024-01'
),
activity AS (
    SELECT
        DATE_FORMAT(b.bill_date,'%Y-%m') AS ym,
        COUNT(DISTINCT b.patient_id)     AS active_patients
    FROM bills b
    WHERE b.patient_id IN (SELECT patient_id FROM cohort)
    GROUP BY DATE_FORMAT(b.bill_date,'%Y-%m')
)
SELECT ym, active_patients,
       ROUND(100.0 * active_patients / (SELECT COUNT(*) FROM cohort), 2) AS retention_pct
FROM activity ORDER BY ym;

-- Q30 [ZS style — the "so what?" question]
-- Q: "Which hospital has the WORST balance of high revenue but high 30-day
--     readmission rate?" (Business meaning: making money by treating same
--     patients again — quality issue!)
WITH readmit AS (
    WITH ordered AS (
        SELECT hospital_id, patient_id, admit_date,
               LAG(discharge_date) OVER (PARTITION BY patient_id ORDER BY admit_date) AS prev
        FROM admissions WHERE discharge_date IS NOT NULL
    )
    SELECT hospital_id,
           ROUND(100.0*SUM(CASE WHEN prev IS NOT NULL
                                 AND DATEDIFF(admit_date,prev)<=30 THEN 1 ELSE 0 END)
                     /COUNT(*),2) AS readmit_rate_pct
    FROM ordered GROUP BY hospital_id
),
rev AS (
    SELECT h.hospital_id, SUM(b.total_amount) AS revenue
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status='Paid'
    GROUP BY h.hospital_id
)
SELECT h.name, rev.revenue, readmit.readmit_rate_pct,
       ROUND(rev.revenue * readmit.readmit_rate_pct / 100, 0) AS quality_concern_score
FROM hospitals h
JOIN rev     ON rev.hospital_id     = h.hospital_id
JOIN readmit ON readmit.hospital_id = h.hospital_id
ORDER BY quality_concern_score DESC;

-- ============================================================================
-- END. Practice tip: attempt each question BEFORE looking at the solution.
-- ============================================================================
