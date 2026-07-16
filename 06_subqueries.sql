-- ============================================================================
-- FILE  : 06_subqueries.sql
-- TOPIC : Scalar subqueries, IN, NOT IN, EXISTS, NOT EXISTS,
--         correlated subqueries, subqueries in FROM (derived tables)
-- LEVEL : Intermediate  (Round 2 interview stuff)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Scalar subquery — patients older than the AVERAGE patient age.
-- ----------------------------------------------------------------------------
SELECT patient_id, name, dob,
       TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age
FROM patients
WHERE TIMESTAMPDIFF(YEAR, dob, CURDATE()) >
      (SELECT AVG(TIMESTAMPDIFF(YEAR, dob, CURDATE())) FROM patients);

-- ----------------------------------------------------------------------------
-- Q2. IN subquery — doctors who have EVER admitted a patient in Mumbai branch.
-- ----------------------------------------------------------------------------
SELECT staff_id, name, specialization
FROM staff
WHERE staff_id IN (
    SELECT attending_doctor_id
    FROM admissions
    WHERE hospital_id = (SELECT hospital_id FROM hospitals WHERE city = 'Mumbai')
);

-- ----------------------------------------------------------------------------
-- Q3. NOT IN — patients who have NEVER been admitted (only outpatient).
--      Careful: NOT IN with a NULL breaks. Use NOT EXISTS to be safe (see Q5).
-- ----------------------------------------------------------------------------
SELECT patient_id, name
FROM patients
WHERE patient_id NOT IN (
    SELECT DISTINCT patient_id FROM admissions
);

-- ----------------------------------------------------------------------------
-- Q4. EXISTS — hospitals that have at least one currently-admitted patient.
-- ----------------------------------------------------------------------------
SELECT h.hospital_id, h.name
FROM hospitals h
WHERE EXISTS (
    SELECT 1
    FROM admissions a
    WHERE a.hospital_id = h.hospital_id
      AND a.discharge_date IS NULL
);

-- ----------------------------------------------------------------------------
-- Q5. NOT EXISTS (safer than NOT IN) — patients with no insurance policy.
-- ----------------------------------------------------------------------------
SELECT p.patient_id, p.name
FROM patients p
WHERE NOT EXISTS (
    SELECT 1
    FROM patient_insurance_policies pol
    WHERE pol.patient_id = p.patient_id
);

-- ----------------------------------------------------------------------------
-- Q6. Correlated subquery — for each doctor, count how many prescriptions
--      they have written. (Correlated because the inner query references
--      the outer table's staff_id.)
-- ----------------------------------------------------------------------------
SELECT
    s.staff_id,
    s.name,
    (SELECT COUNT(*)
       FROM prescriptions rx
       WHERE rx.doctor_id = s.staff_id)   AS rx_count
FROM staff s
WHERE s.role = 'Doctor'
ORDER BY rx_count DESC;

-- ----------------------------------------------------------------------------
-- Q7. Correlated + comparison — find doctors who earn MORE than the average
--      salary of their OWN department.
-- ----------------------------------------------------------------------------
SELECT s.staff_id, s.name, s.salary, s.department_id
FROM staff s
WHERE s.salary > (
    SELECT AVG(s2.salary)
    FROM staff s2
    WHERE s2.department_id = s.department_id
);

-- ----------------------------------------------------------------------------
-- Q8. Subquery in FROM (derived table) — top-3 revenue hospitals.
-- ----------------------------------------------------------------------------
SELECT *
FROM (
    SELECT h.name AS hospital, SUM(b.total_amount) AS revenue
    FROM bills b
    JOIN patients p ON p.patient_id = b.patient_id
    LEFT JOIN admissions a  ON a.admission_id  = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status = 'Paid'
    GROUP BY h.hospital_id, h.name
) t
ORDER BY revenue DESC
LIMIT 3;

-- ----------------------------------------------------------------------------
-- Q9. Subquery in SELECT — every hospital with 3 KPIs side-by-side.
-- ----------------------------------------------------------------------------
SELECT
    h.hospital_id,
    h.name,
    (SELECT COUNT(*) FROM staff s
        WHERE s.hospital_id = h.hospital_id AND s.role = 'Doctor')  AS doctors,
    (SELECT COUNT(*) FROM admissions a
        WHERE a.hospital_id = h.hospital_id)                        AS admissions,
    (SELECT COUNT(*) FROM appointments ap
        WHERE ap.hospital_id = h.hospital_id)                       AS appointments
FROM hospitals h;

-- ----------------------------------------------------------------------------
-- Q10. Nested subquery — find the medicine that has been prescribed the most.
-- ----------------------------------------------------------------------------
SELECT medicine_id, name
FROM medicines
WHERE medicine_id = (
    SELECT medicine_id
    FROM prescriptions
    GROUP BY medicine_id
    ORDER BY SUM(quantity) DESC
    LIMIT 1
);

-- ----------------------------------------------------------------------------
-- Q11. Second-highest salary in the whole chain (classic interview Q).
-- ----------------------------------------------------------------------------
SELECT MAX(salary) AS second_highest_salary
FROM staff
WHERE salary < (SELECT MAX(salary) FROM staff);

-- ----------------------------------------------------------------------------
-- Q12. ANY / ALL — doctors whose salary is greater than ALL nurses' salaries.
-- ----------------------------------------------------------------------------
SELECT staff_id, name, salary
FROM staff
WHERE role = 'Doctor'
  AND salary > ALL (SELECT salary FROM staff WHERE role = 'Nurse');
