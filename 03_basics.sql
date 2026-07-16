-- ============================================================================
-- FILE  : 03_basics.sql
-- TOPIC : SELECT, WHERE, ORDER BY, LIMIT, DISTINCT, LIKE, IN, BETWEEN, IS NULL
-- LEVEL : Beginner  (warm-up screening round questions)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Show all hospitals in the chain.
-- ----------------------------------------------------------------------------
SELECT * FROM hospitals;

-- ----------------------------------------------------------------------------
-- Q2. List only patient names & cities (projection).
-- ----------------------------------------------------------------------------
SELECT name, city FROM patients;

-- ----------------------------------------------------------------------------
-- Q3. Find all female patients.
-- ----------------------------------------------------------------------------
SELECT patient_id, name, city
FROM patients
WHERE gender = 'F';

-- ----------------------------------------------------------------------------
-- Q4. Find all patients from Mumbai OR Delhi.
-- ----------------------------------------------------------------------------
SELECT name, city
FROM patients
WHERE city IN ('Mumbai', 'Delhi');

-- ----------------------------------------------------------------------------
-- Q5. Find patients whose name starts with 'A'.
-- ----------------------------------------------------------------------------
SELECT patient_id, name
FROM patients
WHERE name LIKE 'A%';

-- ----------------------------------------------------------------------------
-- Q6. Find doctors earning between 150000 and 200000.
-- ----------------------------------------------------------------------------
SELECT staff_id, name, role, salary
FROM staff
WHERE role = 'Doctor'
  AND salary BETWEEN 150000 AND 200000;

-- ----------------------------------------------------------------------------
-- Q7. Sort patients by registration date (newest first) and show top 10.
-- ----------------------------------------------------------------------------
SELECT patient_id, name, registration_date
FROM patients
ORDER BY registration_date DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- Q8. List the DISTINCT cities patients have come from.
-- ----------------------------------------------------------------------------
SELECT DISTINCT city
FROM patients
ORDER BY city;

-- ----------------------------------------------------------------------------
-- Q9. Find all admissions that are currently ongoing (discharge_date is NULL).
-- ----------------------------------------------------------------------------
SELECT admission_id, patient_id, admit_date, diagnosis
FROM admissions
WHERE discharge_date IS NULL;

-- ----------------------------------------------------------------------------
-- Q10. Find no-show or cancelled appointments.
-- ----------------------------------------------------------------------------
SELECT appointment_id, patient_id, doctor_id, appointment_date, status
FROM appointments
WHERE status <> 'Attended';

-- ----------------------------------------------------------------------------
-- Q11. Show medicines that cost more than Rs. 100 per unit, cheapest first.
-- ----------------------------------------------------------------------------
SELECT name, category, unit_price
FROM medicines
WHERE unit_price > 100
ORDER BY unit_price ASC;

-- ----------------------------------------------------------------------------
-- Q12. Rename columns with aliases for a cleaner report output.
-- ----------------------------------------------------------------------------
SELECT
    hospital_id  AS branch_id,
    name         AS branch_name,
    city         AS location,
    total_beds   AS bed_capacity
FROM hospitals
ORDER BY total_beds DESC;

-- ----------------------------------------------------------------------------
-- Q13. Patients aged over 50 as of 2025-01-01
--      (basic date arithmetic without joins yet).
-- ----------------------------------------------------------------------------
SELECT patient_id, name, dob,
       TIMESTAMPDIFF(YEAR, dob, '2025-01-01') AS age_years
FROM patients
WHERE TIMESTAMPDIFF(YEAR, dob, '2025-01-01') > 50
ORDER BY age_years DESC;

-- ----------------------------------------------------------------------------
-- Q14. Return the 3 most expensive rooms.
-- ----------------------------------------------------------------------------
SELECT room_id, room_type, daily_charge
FROM rooms
ORDER BY daily_charge DESC
LIMIT 3;

-- ----------------------------------------------------------------------------
-- Q15. Count how many patients we have.
-- ----------------------------------------------------------------------------
SELECT COUNT(*) AS total_patients FROM patients;
