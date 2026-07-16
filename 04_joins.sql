-- ============================================================================
-- FILE  : 04_joins.sql
-- TOPIC : INNER, LEFT, RIGHT, FULL (via UNION), SELF, CROSS JOIN
-- LEVEL : Beginner → Intermediate
-- WHY   : Joins are asked in EVERY SQL interview. Master these.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. INNER JOIN — show each appointment with patient name and doctor name.
-- ----------------------------------------------------------------------------
SELECT
    a.appointment_id,
    p.name        AS patient_name,
    s.name        AS doctor_name,
    a.appointment_date,
    a.status
FROM appointments a
INNER JOIN patients p ON p.patient_id  = a.patient_id
INNER JOIN staff    s ON s.staff_id    = a.doctor_id
ORDER BY a.appointment_date;

-- ----------------------------------------------------------------------------
-- Q2. INNER JOIN + filter — Cardiology admissions in Mumbai branch only.
-- ----------------------------------------------------------------------------
SELECT
    a.admission_id,
    p.name              AS patient_name,
    h.name              AS hospital,
    d.name              AS department,
    a.diagnosis,
    a.admit_date
FROM admissions a
JOIN patients    p ON p.patient_id    = a.patient_id
JOIN hospitals   h ON h.hospital_id   = a.hospital_id
JOIN staff       s ON s.staff_id      = a.attending_doctor_id
JOIN departments d ON d.department_id = s.department_id
WHERE h.city = 'Mumbai'
  AND d.name = 'Cardiology';

-- ----------------------------------------------------------------------------
-- Q3. LEFT JOIN — every patient and their appointment count (0 for those with none).
--      Note: patients who never booked will still appear (COUNT=0).
-- ----------------------------------------------------------------------------
SELECT
    p.patient_id,
    p.name,
    COUNT(a.appointment_id) AS total_appointments
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
GROUP BY p.patient_id, p.name
ORDER BY total_appointments DESC;

-- ----------------------------------------------------------------------------
-- Q4. LEFT JOIN + IS NULL — patients who have NEVER booked an appointment.
--      A classic "anti-join" pattern.
-- ----------------------------------------------------------------------------
SELECT p.patient_id, p.name, p.city
FROM patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id
WHERE a.appointment_id IS NULL;

-- ----------------------------------------------------------------------------
-- Q5. LEFT JOIN chain — patients WITHOUT any insurance policy.
-- ----------------------------------------------------------------------------
SELECT p.patient_id, p.name
FROM patients p
LEFT JOIN patient_insurance_policies pol ON pol.patient_id = p.patient_id
WHERE pol.policy_id IS NULL;

-- ----------------------------------------------------------------------------
-- Q6. RIGHT JOIN — every doctor and their appointment count.
--      (functionally same as LEFT JOIN with sides swapped)
-- ----------------------------------------------------------------------------
SELECT
    s.staff_id,
    s.name AS doctor,
    COUNT(a.appointment_id) AS total_appointments
FROM appointments a
RIGHT JOIN staff s ON s.staff_id = a.doctor_id
WHERE s.role = 'Doctor'
GROUP BY s.staff_id, s.name
ORDER BY total_appointments DESC;

-- ----------------------------------------------------------------------------
-- Q7. FULL OUTER JOIN — MySQL doesn't support FULL JOIN directly.
--      Emulate with LEFT + UNION + RIGHT.
--      Show every bill and every payment (matched where possible).
-- ----------------------------------------------------------------------------
SELECT b.bill_id, b.total_amount, pay.payment_id, pay.amount
FROM bills b
LEFT JOIN payments pay ON pay.bill_id = b.bill_id
UNION
SELECT b.bill_id, b.total_amount, pay.payment_id, pay.amount
FROM bills b
RIGHT JOIN payments pay ON pay.bill_id = b.bill_id;

-- ----------------------------------------------------------------------------
-- Q8. SELF JOIN — list every doctor with their manager's name.
--      Staff table joins to itself on manager_id.
-- ----------------------------------------------------------------------------
SELECT
    e.staff_id,
    e.name         AS employee,
    e.role,
    m.name         AS manager_name,
    m.role         AS manager_role
FROM staff e
LEFT JOIN staff m ON m.staff_id = e.manager_id
ORDER BY e.hospital_id, e.staff_id;

-- ----------------------------------------------------------------------------
-- Q9. SELF JOIN — find pairs of doctors who share the same specialization.
--      Classic "employees who earn more than colleagues" pattern reused.
-- ----------------------------------------------------------------------------
SELECT
    d1.name AS doctor_1,
    d2.name AS doctor_2,
    d1.specialization
FROM staff d1
JOIN staff d2
     ON d1.specialization = d2.specialization
    AND d1.staff_id < d2.staff_id           -- avoid duplicates & self-pairs
WHERE d1.role = 'Doctor'
ORDER BY d1.specialization;

-- ----------------------------------------------------------------------------
-- Q10. CROSS JOIN — a "matrix" of every hospital × every medicine category
--       (rarely useful alone, but shown for completeness).
-- ----------------------------------------------------------------------------
SELECT h.name AS hospital, m.category
FROM hospitals h
CROSS JOIN (SELECT DISTINCT category FROM medicines) m
ORDER BY h.name, m.category;

-- ----------------------------------------------------------------------------
-- Q11. Multi-table JOIN (5 tables!) — for each prescription show
--       patient, doctor, medicine, and hospital.
-- ----------------------------------------------------------------------------
SELECT
    rx.prescription_id,
    pat.name           AS patient,
    doc.name           AS doctor,
    med.name           AS medicine,
    med.category,
    h.name             AS hospital,
    rx.quantity,
    rx.prescribed_date
FROM prescriptions rx
JOIN staff     doc ON doc.staff_id = rx.doctor_id
JOIN medicines med ON med.medicine_id = rx.medicine_id
LEFT JOIN appointments a ON a.appointment_id = rx.appointment_id
LEFT JOIN admissions  ad ON ad.admission_id  = rx.admission_id
JOIN patients pat ON pat.patient_id = COALESCE(a.patient_id, ad.patient_id)
JOIN hospitals h  ON h.hospital_id  = COALESCE(a.hospital_id, ad.hospital_id)
ORDER BY rx.prescribed_date;

-- ----------------------------------------------------------------------------
-- Q12. LEFT JOIN — every hospital, plus number of Cardiology doctors it has.
-- ----------------------------------------------------------------------------
SELECT
    h.name AS hospital,
    COUNT(s.staff_id) AS cardiologists
FROM hospitals h
LEFT JOIN departments d ON d.hospital_id = h.hospital_id AND d.name = 'Cardiology'
LEFT JOIN staff s ON s.department_id = d.department_id AND s.role = 'Doctor'
GROUP BY h.hospital_id, h.name;

-- ----------------------------------------------------------------------------
-- Q13. Non-equi JOIN — patients whose registration_date falls WITHIN their
--       insurance policy's active window.
-- ----------------------------------------------------------------------------
SELECT
    p.name,
    p.registration_date,
    pol.policy_number,
    pol.start_date,
    pol.end_date
FROM patients p
JOIN patient_insurance_policies pol
     ON pol.patient_id = p.patient_id
    AND p.registration_date BETWEEN pol.start_date AND pol.end_date;
