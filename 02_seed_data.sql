-- ============================================================================
-- FILE  : 02_seed_data.sql
-- PURPOSE: Insert realistic seed data covering ~2 years (2024-2025) across
--          5 hospital branches. Data intentionally contains a few HIDDEN
--          FRAUD / ANOMALY PATTERNS so that queries in 12_fraud_detection.sql
--          have something to find. See end of file for the "fraud spec".
--
-- USAGE:  USE medichain;  SOURCE 02_seed_data.sql;
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. HOSPITALS  (5 branches)
-- ----------------------------------------------------------------------------
INSERT INTO hospitals (name, city, state, opening_date, total_beds) VALUES
('MediChain Hyderabad',  'Hyderabad', 'Telangana',      '2018-04-01', 250),
('MediChain Bengaluru',  'Bengaluru', 'Karnataka',      '2019-06-15', 300),
('MediChain Mumbai',     'Mumbai',    'Maharashtra',    '2015-01-20', 400),
('MediChain Delhi',      'Delhi',     'Delhi',          '2016-09-10', 350),
('MediChain Chennai',    'Chennai',   'Tamil Nadu',     '2020-02-01', 200);

-- ----------------------------------------------------------------------------
-- 2. DEPARTMENTS  (6 depts per hospital)
-- ----------------------------------------------------------------------------
INSERT INTO departments (hospital_id, name) VALUES
(1,'Cardiology'),(1,'Neurology'),(1,'Orthopedics'),(1,'Pediatrics'),(1,'General Medicine'),(1,'Emergency'),
(2,'Cardiology'),(2,'Neurology'),(2,'Orthopedics'),(2,'Pediatrics'),(2,'General Medicine'),(2,'Emergency'),
(3,'Cardiology'),(3,'Neurology'),(3,'Orthopedics'),(3,'Pediatrics'),(3,'General Medicine'),(3,'Emergency'),
(4,'Cardiology'),(4,'Neurology'),(4,'Orthopedics'),(4,'Pediatrics'),(4,'General Medicine'),(4,'Emergency'),
(5,'Cardiology'),(5,'Neurology'),(5,'Orthopedics'),(5,'Pediatrics'),(5,'General Medicine'),(5,'Emergency');

-- ----------------------------------------------------------------------------
-- 3. STAFF  (managers first so self-FK resolves; ~40 rows total)
-- ----------------------------------------------------------------------------
-- Chief Medical Officers (top of hierarchy) — one per hospital
INSERT INTO staff (hospital_id, department_id, name, role, specialization, hire_date, salary, manager_id) VALUES
(1, NULL, 'Dr. Anil Rao',      'Admin', 'CMO', '2018-05-01', 350000, NULL),  -- id 1
(2, NULL, 'Dr. Sunita Nair',   'Admin', 'CMO', '2019-07-01', 340000, NULL),  -- id 2
(3, NULL, 'Dr. Ramesh Iyer',   'Admin', 'CMO', '2015-03-01', 380000, NULL),  -- id 3
(4, NULL, 'Dr. Kavita Menon',  'Admin', 'CMO', '2016-10-01', 360000, NULL),  -- id 4
(5, NULL, 'Dr. Vikram Reddy',  'Admin', 'CMO', '2020-03-01', 330000, NULL);  -- id 5

-- Department heads (report to CMO of their hospital)
INSERT INTO staff (hospital_id, department_id, name, role, specialization, hire_date, salary, manager_id) VALUES
-- Hyderabad heads
(1, 1, 'Dr. Prakash Verma',  'Doctor', 'Cardiologist',    '2018-06-01', 220000, 1),   -- 6
(1, 2, 'Dr. Meena Gupta',    'Doctor', 'Neurologist',     '2018-06-01', 210000, 1),   -- 7
(1, 3, 'Dr. Sanjay Deshmukh','Doctor', 'Orthopedic',      '2018-07-01', 200000, 1),   -- 8
-- Bengaluru heads
(2, 7,  'Dr. Rohit Shetty',  'Doctor', 'Cardiologist',    '2019-08-01', 215000, 2),   -- 9
(2, 8,  'Dr. Latha Krishnan','Doctor', 'Neurologist',     '2019-09-01', 205000, 2),   -- 10
-- Mumbai heads
(3, 13, 'Dr. Aditya Khanna', 'Doctor', 'Cardiologist',    '2015-04-01', 240000, 3),   -- 11
(3, 14, 'Dr. Nisha Bhatt',   'Doctor', 'Neurologist',     '2015-05-01', 235000, 3),   -- 12
-- Delhi heads
(4, 19, 'Dr. Arjun Malhotra','Doctor', 'Cardiologist',    '2016-11-01', 225000, 4),   -- 13
(4, 22, 'Dr. Preeti Sharma', 'Doctor', 'Pediatrician',    '2016-12-01', 195000, 4),   -- 14
-- Chennai heads
(5, 25, 'Dr. Karthik Raman', 'Doctor', 'Cardiologist',    '2020-04-01', 200000, 5);   -- 15

-- Regular doctors (report to dept heads)
INSERT INTO staff (hospital_id, department_id, name, role, specialization, hire_date, salary, manager_id) VALUES
(1, 1, 'Dr. Neha Kulkarni',  'Doctor', 'Cardiologist', '2020-01-15', 150000, 6),      -- 16
(1, 4, 'Dr. Rajesh Patil',   'Doctor', 'Pediatrician', '2019-08-01', 140000, 1),      -- 17
(1, 6, 'Dr. Sneha Joshi',    'Doctor', 'Emergency',    '2021-03-01', 130000, 1),      -- 18
(2, 7, 'Dr. Vivek Bhat',     'Doctor', 'Cardiologist', '2021-05-15', 145000, 9),      -- 19  (⚠ FRAUD-1: over-prescriber)
(2, 8, 'Dr. Anjali Menon',   'Doctor', 'Neurologist',  '2020-09-10', 155000, 10),     -- 20
(2,12, 'Dr. Suresh Rao',     'Doctor', 'Emergency',    '2022-01-15', 125000, 2),      -- 21
(3,13, 'Dr. Kunal Kapoor',   'Doctor', 'Cardiologist', '2018-07-01', 175000, 11),     -- 22
(3,15, 'Dr. Sonal Bhargava', 'Doctor', 'Orthopedic',   '2019-04-01', 165000, 3),      -- 23
(3,18, 'Dr. Farhan Sheikh',  'Doctor', 'Emergency',    '2020-11-15', 145000, 3),      -- 24
(4,19, 'Dr. Ishaan Kohli',   'Doctor', 'Cardiologist', '2019-01-01', 170000, 13),     -- 25
(4,20, 'Dr. Pallavi Sinha',  'Doctor', 'Neurologist',  '2020-06-01', 160000, 4),      -- 26
(4,22, 'Dr. Ankit Chopra',   'Doctor', 'Pediatrician', '2021-08-01', 135000, 14),     -- 27
(5,25, 'Dr. Divya Nair',     'Doctor', 'Cardiologist', '2020-05-01', 150000, 15),     -- 28
(5,27, 'Dr. Manoj Pillai',   'Doctor', 'Orthopedic',   '2021-02-01', 145000, 5),      -- 29
(5,29, 'Dr. Rekha Iyer',     'Doctor', 'General',      '2022-07-01', 120000, 5);      -- 30

-- Nurses & other staff
INSERT INTO staff (hospital_id, department_id, name, role, specialization, hire_date, salary, manager_id) VALUES
(1, 1, 'Nurse Priya S.',    'Nurse', NULL, '2019-01-10', 45000, 6),       -- 31
(1, 6, 'Nurse Amit K.',     'Nurse', NULL, '2020-05-15', 42000, 18),      -- 32
(2, 7, 'Nurse Rekha D.',    'Nurse', NULL, '2020-03-01', 44000, 9),       -- 33
(3,13, 'Nurse Kavya M.',    'Nurse', NULL, '2018-10-01', 48000, 11),      -- 34
(4,19, 'Nurse Deepak V.',   'Nurse', NULL, '2019-06-01', 46000, 13),      -- 35
(5,25, 'Nurse Anita R.',    'Nurse', NULL, '2021-01-15', 40000, 15),      -- 36
(1, NULL,'Ravi Chowdhury',  'Admin', NULL, '2018-04-15', 60000, 1),       -- 37
(2, NULL,'Shweta Kaul',     'Admin', NULL, '2019-06-20', 58000, 2),       -- 38
(3, NULL,'Manish Trivedi',  'Admin', NULL, '2015-02-01', 70000, 3),       -- 39
(4, NULL,'Priyanka Das',    'Admin', NULL, '2016-10-15', 65000, 4);       -- 40

-- ----------------------------------------------------------------------------
-- 4. ROOMS  (~8 per hospital = 40 rows)
-- ----------------------------------------------------------------------------
INSERT INTO rooms (hospital_id, room_number, room_type, daily_charge, status) VALUES
(1,'101','General',2000,'Available'),(1,'102','General',2000,'Occupied'),(1,'103','Semi-Private',3500,'Available'),
(1,'201','Private',6000,'Occupied'),(1,'202','Private',6000,'Available'),(1,'301','ICU',12000,'Occupied'),
(1,'302','ICU',12000,'Available'),(1,'401','Deluxe',15000,'Available'),
(2,'101','General',2200,'Occupied'),(2,'102','General',2200,'Available'),(2,'201','Semi-Private',3800,'Occupied'),
(2,'202','Private',6500,'Available'),(2,'301','ICU',13000,'Occupied'),(2,'302','ICU',13000,'Occupied'),
(2,'303','ICU',13000,'Available'),(2,'401','Deluxe',16000,'Available'),
(3,'101','General',2500,'Occupied'),(3,'102','General',2500,'Occupied'),(3,'201','Semi-Private',4000,'Available'),
(3,'202','Private',7500,'Occupied'),(3,'301','ICU',14000,'Occupied'),(3,'302','ICU',14000,'Available'),
(3,'303','ICU',14000,'Occupied'),(3,'401','Deluxe',18000,'Occupied'),
(4,'101','General',2300,'Available'),(4,'102','General',2300,'Occupied'),(4,'201','Semi-Private',3900,'Occupied'),
(4,'202','Private',7000,'Available'),(4,'301','ICU',13500,'Occupied'),(4,'302','ICU',13500,'Available'),
(4,'303','ICU',13500,'Occupied'),(4,'401','Deluxe',17000,'Available'),
(5,'101','General',1900,'Available'),(5,'102','General',1900,'Occupied'),(5,'201','Semi-Private',3200,'Available'),
(5,'202','Private',5500,'Available'),(5,'301','ICU',11000,'Occupied'),(5,'302','ICU',11000,'Available'),
(5,'303','ICU',11000,'Available'),(5,'401','Deluxe',14000,'Available');

-- ----------------------------------------------------------------------------
-- 5. PATIENTS  (~40 patients)
-- ----------------------------------------------------------------------------
INSERT INTO patients (name, dob, gender, city, blood_group, registration_date, has_chronic_condition) VALUES
('Aarav Sharma',      '1985-04-12','M','Hyderabad','B+','2024-01-05',1),
('Diya Patel',        '1990-08-23','F','Hyderabad','O+','2024-01-15',0),
('Kabir Singh',       '1978-02-14','M','Bengaluru','A+','2024-02-10',1),
('Mira Nair',         '1995-11-30','F','Bengaluru','AB+','2024-02-20',0),
('Raghav Iyer',       '1965-07-01','M','Mumbai','O-','2023-11-01',1),
('Isha Bhatia',       '1988-05-19','F','Mumbai','B+','2024-03-05',0),
('Arjun Rao',         '1972-12-25','M','Delhi','A-','2024-01-22',1),
('Naina Chopra',      '1993-09-08','F','Delhi','O+','2024-04-01',0),
('Vikas Reddy',       '1980-06-17','M','Chennai','B-','2024-02-14',1),
('Priya Menon',       '1998-03-11','F','Chennai','A+','2024-05-10',0),
('Rohan Desai',       '1970-10-20','M','Hyderabad','O+','2023-12-15',1),
('Aditi Ghosh',       '1992-07-04','F','Bengaluru','B+','2024-06-01',0),
('Karan Malhotra',    '1960-01-30','M','Delhi','A+','2023-10-10',1),
('Sneha Verma',       '1987-11-15','F','Mumbai','O-','2024-07-20',0),
('Manav Kapoor',      '1975-04-25','M','Chennai','AB-','2024-03-15',1),
('Tanya Bhat',        '1996-08-19','F','Bengaluru','B-','2024-08-01',0),
('Sameer Jain',       '1982-02-28','M','Hyderabad','A+','2024-04-12',0),
('Neelam Reddy',      '1968-06-11','F','Chennai','O+','2023-09-05',1),
('Yash Agarwal',      '1991-12-03','M','Delhi','B+','2024-05-25',0),
('Anushka Sen',       '1985-05-17','F','Mumbai','A-','2024-06-15',1),
('Rahul Bose',        '1979-09-22','M','Bengaluru','O+','2024-07-05',1),
('Meera Krishnan',    '1994-02-08','F','Chennai','AB+','2024-08-14',0),
('Nikhil Joshi',      '1988-11-30','M','Hyderabad','B-','2024-09-01',0),
('Pooja Sharma',      '1971-07-14','F','Delhi','A+','2023-08-20',1),
('Amit Trivedi',      '1983-03-27','M','Mumbai','O+','2024-10-05',0),
('Kritika Mehta',     '1990-10-19','F','Bengaluru','B+','2024-11-01',0),
('Deepak Kulkarni',   '1966-05-08','M','Hyderabad','A-','2023-07-15',1),
('Ritika Roy',        '1997-01-22','F','Chennai','O-','2024-12-10',0),
('Siddharth Mishra',  '1974-09-15','M','Delhi','B+','2024-02-28',1),
('Ananya Pillai',     '1993-06-30','F','Bengaluru','AB+','2024-11-20',0),
('Varun Rao',         '1986-08-05','M','Mumbai','A+','2025-01-05',0),
('Simran Kaur',       '1981-04-16','F','Delhi','O+','2025-01-15',1),
('Tarun Ghosh',       '1970-11-11','M','Hyderabad','B-','2024-01-25',1),
('Zara Sheikh',       '1995-05-25','F','Mumbai','A-','2025-02-01',0),
('Aryan Menon',       '1989-02-19','M','Chennai','O+','2025-02-15',0),
('Nandini Iyer',      '1976-07-08','F','Bengaluru','B+','2024-03-10',1),
('Aakash Verma',      '1984-12-14','M','Delhi','AB+','2025-03-05',0),
('Lavanya Rao',       '1998-09-27','F','Hyderabad','O-','2025-03-20',0),
('Kunal Bhatt',       '1972-06-21','M','Mumbai','A+','2024-04-18',1),
('Riya Kapoor',       '1992-10-08','F','Bengaluru','B+','2025-04-01',0);

-- ----------------------------------------------------------------------------
-- 6. INSURANCE COMPANIES
-- ----------------------------------------------------------------------------
INSERT INTO insurance_companies (name, rating) VALUES
('Star Health',       4.2),
('HDFC Ergo',         4.5),
('ICICI Lombard',     4.3),
('Bajaj Allianz',     4.1),
('Max Bupa',          4.0);

-- ----------------------------------------------------------------------------
-- 7. PATIENT INSURANCE POLICIES  (not every patient has insurance)
-- ----------------------------------------------------------------------------
INSERT INTO patient_insurance_policies (patient_id, insurer_id, policy_number, coverage_limit, start_date, end_date) VALUES
(1, 1,'SH-2024-0001',500000,'2024-01-01','2025-12-31'),
(3, 2,'HD-2024-0102',700000,'2024-02-01','2026-01-31'),
(5, 1,'SH-2023-0555',1000000,'2023-11-01','2025-10-31'),
(7, 3,'IC-2024-0033',600000,'2024-01-15','2025-12-14'),
(9, 4,'BA-2024-0088',400000,'2024-02-14','2025-12-13'),
(11,2,'HD-2023-0999',800000,'2023-12-01','2025-11-30'),
(13,5,'MB-2023-0111',1200000,'2023-10-10','2026-10-09'),
(15,1,'SH-2024-0244',500000,'2024-03-15','2026-03-14'),
(18,3,'IC-2023-0500',900000,'2023-09-05','2025-09-04'),
(20,2,'HD-2024-0311',700000,'2024-06-15','2026-06-14'),
(24,4,'BA-2023-0722',500000,'2023-08-20','2025-08-19'),
(27,5,'MB-2023-0803',600000,'2023-07-15','2025-07-14'),
(29,1,'SH-2024-0450',500000,'2024-02-28','2026-02-27'),
(32,2,'HD-2025-0011',800000,'2025-01-15','2027-01-14'),
(33,3,'IC-2024-0777',600000,'2024-01-25','2026-01-24'),
(36,4,'BA-2024-0899',400000,'2024-03-10','2026-03-09'),
(39,5,'MB-2024-0921',600000,'2024-04-18','2026-04-17');

-- ----------------------------------------------------------------------------
-- 8. MEDICINES
-- ----------------------------------------------------------------------------
INSERT INTO medicines (name, category, unit_price, stock_quantity) VALUES
('Amoxicillin 500mg',    'Antibiotic',        45.00,  500),
('Azithromycin 250mg',   'Antibiotic',        75.00,  300),
('Paracetamol 500mg',    'Analgesic',         15.00, 1200),
('Ibuprofen 400mg',      'Analgesic',         25.00,  800),
('Metformin 500mg',      'Antidiabetic',      35.00,  600),
('Insulin Glargine',     'Antidiabetic',     850.00,  100),
('Atenolol 50mg',        'Antihypertensive',  55.00,  400),
('Amlodipine 5mg',       'Antihypertensive',  40.00,  500),
('Atorvastatin 20mg',    'Statin',            65.00,  350),
('Omeprazole 20mg',      'Antacid',           30.00,  700),
('Cetirizine 10mg',      'Antihistamine',     18.00,  900),
('Salbutamol Inhaler',   'Bronchodilator',   220.00,  150);

-- ----------------------------------------------------------------------------
-- 9. APPOINTMENTS  (~60 rows spanning 2024-2025)
-- ----------------------------------------------------------------------------
INSERT INTO appointments (patient_id, doctor_id, hospital_id, appointment_date, status, consultation_fee) VALUES
(1, 6, 1,'2024-01-10 10:00','Attended',800),
(2,17, 1,'2024-01-20 11:00','Attended',600),
(3, 9, 2,'2024-02-15 09:30','Attended',900),
(4,19, 2,'2024-02-25 10:00','Attended',700),
(5,11, 3,'2024-03-05 14:00','Attended',1200),
(6,22, 3,'2024-03-15 15:00','No-Show',1000),
(7,13, 4,'2024-01-25 11:30','Attended',1000),
(8,27, 4,'2024-04-05 10:00','Attended',700),
(9,15, 5,'2024-02-18 09:00','Attended',800),
(10,28,5,'2024-05-15 10:30','Attended',700),
(11,16,1,'2024-01-15 16:00','Attended',700),
(12,20,2,'2024-06-10 11:00','Cancelled',0),
(13,25,4,'2024-01-30 09:30','Attended',900),
(14,12,3,'2024-07-25 14:00','Attended',1100),
(15,28,5,'2024-03-20 15:30','Attended',700),
(16,10,2,'2024-08-05 10:00','Attended',950),
(17, 6,1,'2024-04-15 12:00','Attended',800),
(18,15,5,'2024-09-10 09:00','Attended',800),
(19,25,4,'2024-05-28 10:00','No-Show',900),
(20,24,3,'2024-06-18 13:00','Attended',600),
(21,19,2,'2024-07-10 15:00','Attended',900),      -- FRAUD-1 doctor
(22,29,5,'2024-08-14 11:00','Attended',700),
(23,17,1,'2024-09-05 14:00','Attended',600),
(24,13,4,'2024-08-25 10:00','Attended',1000),
(25,22,3,'2024-10-10 11:30','Attended',1000),
(26,10,2,'2024-11-05 09:00','Attended',900),
(27, 8,1,'2024-07-20 10:30','Attended',900),
(28,15,5,'2024-12-15 11:00','Attended',800),
(29,26,4,'2024-03-01 09:30','Attended',950),
(30,19,2,'2024-11-25 10:00','Attended',900),      -- FRAUD-1 doctor
(31,23,3,'2025-01-15 14:00','Attended',900),
(32,25,4,'2025-01-20 10:30','Attended',900),
(33,18,1,'2024-02-10 16:00','Attended',700),
(34,24,3,'2025-02-05 10:00','Attended',600),
(35,28,5,'2025-02-25 11:00','Attended',700),
(36,19,2,'2024-04-08 09:00','Attended',900),      -- FRAUD-1 doctor
(37,25,4,'2025-03-10 10:00','Attended',900),
(38,16,1,'2025-03-25 11:30','Attended',700),
(39,22,3,'2024-05-01 13:00','Attended',1000),
(40,20,2,'2025-04-05 15:00','Attended',900),
(1, 6,1,'2024-06-15 10:00','Attended',800),      -- returning patient
(3, 9,2,'2024-08-20 09:30','Attended',900),
(5,11,3,'2024-09-10 14:00','Attended',1200),
(7,13,4,'2024-07-15 11:30','Attended',1000),
(11,16,1,'2024-09-01 16:00','Attended',700),
(15,28,5,'2024-11-10 15:30','Attended',700),
(17, 6,1,'2024-10-20 12:00','Attended',800),
(21,19,2,'2024-10-25 15:00','Attended',900),      -- FRAUD-1 doctor
(24,13,4,'2024-12-15 10:00','Attended',1000),
(29,26,4,'2024-09-25 09:30','Attended',950),
(11,16,1,'2025-01-10 16:00','Attended',700),
(30,19,2,'2025-02-14 10:00','Attended',900),      -- FRAUD-1 doctor
(4,19,2,'2025-03-01 10:00','Attended',700),       -- FRAUD-1 doctor
(2,17,1,'2025-04-15 11:00','Attended',600),
(9,15,5,'2025-03-18 09:00','Attended',800),
(13,25,4,'2025-04-30 09:30','Attended',900),
(18,15,5,'2025-05-10 09:00','Attended',800),
(21,19,2,'2025-05-25 15:00','Attended',900),      -- FRAUD-1 doctor
(27, 8,1,'2025-06-20 10:30','Attended',900),
(33,18,1,'2025-06-10 16:00','Attended',700),
(36,19,2,'2025-06-08 09:00','No-Show',900);       -- FRAUD-1 doctor

-- ----------------------------------------------------------------------------
-- 10. ADMISSIONS  (~35 rows, some still admitted i.e. NULL discharge)
-- ----------------------------------------------------------------------------
INSERT INTO admissions (patient_id, hospital_id, room_id, attending_doctor_id, admit_date, discharge_date, diagnosis, discharge_status) VALUES
(1, 1, 6, 6, '2024-02-10','2024-02-15','Acute MI','Recovered'),
(3, 2,13, 9, '2024-03-05','2024-03-12','Stroke','Recovered'),
(5, 3,21,11, '2024-04-01','2024-04-20','Heart Failure','Recovered'),
(7, 4,29,13, '2024-02-05','2024-02-10','Coronary Artery Disease','Recovered'),
(9, 5,37,15, '2024-03-15','2024-03-22','Arrhythmia','Recovered'),
(11,1, 4, 6, '2024-04-10','2024-04-25','Post-MI care','Recovered'),
(13,4,29,13, '2024-02-20','2024-03-05','Heart Failure','Recovered'),
(15,5,37,15, '2024-05-10','2024-05-18','Chest Pain','Recovered'),
(18,5,37,28, '2024-06-01','2024-06-15','Arrhythmia','Recovered'),
(20,3,21,12, '2024-07-05','2024-07-14','Seizure','Recovered'),
(1, 1, 6, 6, '2024-02-28','2024-03-04','Chest pain (readmission)','Recovered'),  -- ⚠ readmission <30d
(11,1, 4, 6, '2024-05-05','2024-05-10','Cardiac follow-up (readmission)','Recovered'), -- ⚠ readmission <30d
(24,4,29,25, '2024-08-01','2024-08-08','Angina','Recovered'),
(27,1, 8, 8, '2024-09-05','2024-09-15','Hip fracture','Recovered'),
(29,4,30,26, '2024-04-01','2024-04-12','Migraine + Seizure','Recovered'),
(13,4,29,13, '2024-03-15','2024-03-22','Chest pain (readmission)','Recovered'),  -- ⚠ readmission <30d
(5, 3,21,11, '2024-05-15','2024-06-05','Heart Failure (readmission)','Recovered'), -- ⚠ readmission <30d... wait, 25d
(7, 4,29,13, '2024-03-01','2024-03-10','Post-op CABG','Recovered'),
(2, 1, 2,17, '2024-06-10','2024-06-14','Pneumonia','Recovered'),
(4, 2, 9,19, '2024-08-20','2024-08-30','Chest pain','Recovered'),
(33,1, 8, 8, '2024-07-01','2024-07-15','Fractured femur','Recovered'),
(38,1, 4,16, '2025-02-05','2025-02-12','Angina','Recovered'),
(24,4,29,25, '2024-11-10','2024-11-18','Cardiac follow-up','Recovered'),
(19,2, 9,19, '2024-06-15','2024-06-25','Chest pain','Recovered'),
(21,2,15,19, '2024-08-01','2024-08-10','Post-op recovery','Recovered'),
(30,2,15,19, '2024-12-05','2024-12-15','Angina','Recovered'),
(36,2, 9,19, '2024-06-01','2024-06-08','Chest pain','Recovered'),
(9, 5,37,28, '2024-10-05','2024-10-14','Post-op cardiac','Recovered'),
(18,5,37,28, '2024-12-01','2024-12-20','Heart failure','Transferred'),
(15,5,37,15, '2025-01-10','2025-01-18','Chest pain','Recovered'),
-- Currently admitted (discharge_date NULL)
(32,4,30,25, '2025-06-15', NULL,'Angina','NULL'),
(35,5,38,28, '2025-06-20', NULL,'Cardiac observation','NULL'),
(40,2,15,19, '2025-06-25', NULL,'Chest pain','NULL'),
(1, 1, 6, 6, '2025-06-28', NULL,'Post-MI follow-up','NULL'),
(11,1, 4, 6, '2025-07-01', NULL,'Cardiac observation','NULL');

UPDATE admissions SET discharge_status = NULL WHERE discharge_status = 'NULL';

-- ----------------------------------------------------------------------------
-- 11. PRESCRIPTIONS  (~80 rows — FRAUD-1: doctor 19 over-prescribes)
-- ----------------------------------------------------------------------------
INSERT INTO prescriptions (appointment_id, admission_id, doctor_id, medicine_id, quantity, prescribed_date) VALUES
-- Regular outpatient prescriptions
(1, NULL,6, 7,30,'2024-01-10'),(1, NULL,6, 9,30,'2024-01-10'),
(2, NULL,17,3,20,'2024-01-20'),
(3, NULL,9, 7,30,'2024-02-15'),(3, NULL,9, 8,30,'2024-02-15'),
(4, NULL,19,3,60,'2024-02-25'),(4, NULL,19,4,60,'2024-02-25'),(4, NULL,19,10,60,'2024-02-25'),  -- FRAUD-1
(5, NULL,11,7,30,'2024-03-05'),(5, NULL,11,9,30,'2024-03-05'),(5, NULL,11,5,60,'2024-03-05'),
(7, NULL,13,7,30,'2024-01-25'),(7, NULL,13,9,30,'2024-01-25'),
(8, NULL,27,3,15,'2024-04-05'),
(9, NULL,15,7,30,'2024-02-18'),
(10,NULL,28,3,10,'2024-05-15'),
(11,NULL,16,7,30,'2024-01-15'),(11,NULL,16,9,30,'2024-01-15'),
(13,NULL,25,7,30,'2024-01-30'),
(14,NULL,12,3,15,'2024-07-25'),
(16,NULL,10,3,20,'2024-08-05'),
(17,NULL,6, 7,30,'2024-04-15'),
(18,NULL,15,7,30,'2024-09-10'),
(20,NULL,24,3,10,'2024-06-18'),
(21,NULL,19,3,90,'2024-07-10'),(21,NULL,19,4,90,'2024-07-10'),(21,NULL,19,10,90,'2024-07-10'),(21,NULL,19,11,90,'2024-07-10'),  -- FRAUD-1
(22,NULL,29,3,15,'2024-08-14'),
(23,NULL,17,3,15,'2024-09-05'),
(24,NULL,13,7,30,'2024-08-25'),
(25,NULL,22,7,30,'2024-10-10'),
(26,NULL,10,7,30,'2024-11-05'),
(27,NULL,8, 4,30,'2024-07-20'),
(28,NULL,15,7,30,'2024-12-15'),
(29,NULL,26,3,15,'2024-03-01'),
(30,NULL,19,3,120,'2024-11-25'),(30,NULL,19,4,120,'2024-11-25'),(30,NULL,19,10,120,'2024-11-25'), -- FRAUD-1 (large qty)
(33,NULL,18,3,10,'2024-02-10'),
(36,NULL,19,3,60,'2024-04-08'),(36,NULL,19,10,60,'2024-04-08'), -- FRAUD-1
(37,NULL,25,7,30,'2025-03-10'),
(39,NULL,22,7,30,'2024-05-01'),
(40,NULL,20,3,15,'2025-04-05'),
(41,NULL,6, 9,30,'2024-06-15'),
(48,NULL,19,3,60,'2024-10-25'),(48,NULL,19,4,60,'2024-10-25'),  -- FRAUD-1
(52,NULL,19,3,90,'2025-02-14'),(52,NULL,19,10,90,'2025-02-14'),(52,NULL,19,4,90,'2025-02-14'), -- FRAUD-1
(53,NULL,19,3,60,'2025-03-01'),(53,NULL,19,10,60,'2025-03-01'), -- FRAUD-1
(58,NULL,19,3,90,'2025-05-25'),(58,NULL,19,4,90,'2025-05-25'),(58,NULL,19,10,90,'2025-05-25'), -- FRAUD-1
-- Inpatient prescriptions (admission-linked)
(NULL, 1, 6, 7,10,'2024-02-11'),(NULL, 1, 6, 9,10,'2024-02-11'),
(NULL, 2, 9, 7,10,'2024-03-06'),
(NULL, 3,11, 7,15,'2024-04-02'),(NULL, 3,11, 5,15,'2024-04-02'),
(NULL, 4,13, 7,10,'2024-02-06'),
(NULL, 5,15, 7,10,'2024-03-16'),
(NULL, 6, 6, 7,10,'2024-04-11'),
(NULL, 7,13, 7,15,'2024-02-21'),
(NULL, 8,15, 7,10,'2024-05-11'),
(NULL,15,26, 3,15,'2024-04-02');

-- ----------------------------------------------------------------------------
-- 12. BILLS
-- ----------------------------------------------------------------------------
INSERT INTO bills (patient_id, appointment_id, admission_id, bill_date, total_amount, status) VALUES
(1, 1,   NULL,'2024-01-10',   800,'Paid'),
(2, 2,   NULL,'2024-01-20',   600,'Paid'),
(3, 3,   NULL,'2024-02-15',   900,'Paid'),
(1,NULL, 1,   '2024-02-15', 45000,'Paid'),
(3,NULL, 2,   '2024-03-12', 88000,'Paid'),
(5,NULL, 3,   '2024-04-20',225000,'Paid'),
(7,NULL, 4,   '2024-02-10', 62000,'Paid'),
(9,NULL, 5,   '2024-03-22', 78000,'Paid'),
(11,NULL,6,   '2024-04-25',180000,'Paid'),
(13,NULL,7,   '2024-03-05',155000,'Paid'),
(15,NULL,8,   '2024-05-18', 85000,'Paid'),
(18,NULL,9,   '2024-06-15',160000,'Paid'),
(20,NULL,10,  '2024-07-14', 92000,'Paid'),
(1, NULL,11,  '2024-03-04', 55000,'Paid'),
(11,NULL,12,  '2024-05-10', 60000,'Paid'),
(24,NULL,13,  '2024-08-08', 75000,'Paid'),
(27,NULL,14, '2024-09-15',120000,'Paid'),
(29,NULL,15,  '2024-04-12',110000,'Paid'),
(13,NULL,16,  '2024-03-22', 68000,'Paid'),
(5, NULL,17,  '2024-06-05',230000,'Paid'),
(7, NULL,18,  '2024-03-10', 85000,'Paid'),
(2, NULL,19,  '2024-06-14', 42000,'Paid'),
(4, NULL,20,  '2024-08-30', 65000,'Pending'),
(33,NULL,21,  '2024-07-15',135000,'Paid'),
(38,NULL,22,  '2025-02-12', 58000,'Paid'),
(24,NULL,23,  '2024-11-18', 72000,'Paid'),
(19,NULL,24,  '2024-06-25', 85000,'Paid'),
(21,NULL,25,  '2024-08-10', 92000,'Paid'),
(30,NULL,26,  '2024-12-15', 88000,'Paid'),
(36,NULL,27,  '2024-06-08', 76000,'Paid'),
(9, NULL,28,  '2024-10-14', 95000,'Paid'),
(18,NULL,29, '2024-12-20',175000,'Paid'),
(15,NULL,30, '2025-01-18', 80000,'Paid'),
-- FRAUD-2: duplicate bill for same admission_id (admission 20)
(4, NULL,20,  '2024-08-31', 65000,'Pending'),
-- Some outpatient bills
(4, 4,   NULL,'2024-02-25',   700,'Paid'),
(21,21,  NULL,'2024-07-10',   900,'Paid'),
(30,30,  NULL,'2024-11-25',   900,'Paid'),
(36,36,  NULL,'2024-04-08',   900,'Paid'),
(52,NULL,NULL,'2025-02-14',   900,'Paid'),  -- FRAUD-3: bill with no appointment/admission link
(53,NULL,NULL,'2025-03-01',   700,'Pending');

-- ----------------------------------------------------------------------------
-- 13. CLAIMS
-- ----------------------------------------------------------------------------
INSERT INTO claims (bill_id, policy_id, claim_amount, claim_date, status, approved_amount, rejection_reason) VALUES
(4,  1, 45000,'2024-02-16','Approved', 42000, NULL),
(5,  2, 88000,'2024-03-13','Approved', 85000, NULL),
(6,  3,225000,'2024-04-21','Approved',210000, NULL),
(7,  4, 62000,'2024-02-11','Approved', 60000, NULL),
(8,  5, 78000,'2024-03-23','Rejected',   NULL,'Pre-existing condition not disclosed'),
(9,  6,180000,'2024-04-26','Approved',175000, NULL),
(10, 7,155000,'2024-03-06','Approved',150000, NULL),
(11, 8, 85000,'2024-05-19','Approved', 80000, NULL),
(12, 9,160000,'2024-06-16','Pending',    NULL, NULL),
(13,10, 92000,'2024-07-15','Approved', 88000, NULL),
(14, 1, 55000,'2024-03-05','Approved', 50000, NULL),
(15, 8, 60000,'2024-05-11','Approved', 58000, NULL),
(16,11, 75000,'2024-08-09','Approved', 70000, NULL),
(17,12,120000,'2024-09-16','Approved',115000, NULL),
(18,13,110000,'2024-04-13','Approved',105000, NULL),
(19,10, 68000,'2024-03-23','Approved', 65000, NULL),
(20, 3,230000,'2024-06-06','Rejected',    NULL,'Coverage limit exceeded'),
(21, 4, 85000,'2024-03-11','Approved', 82000, NULL),
(31, 6, 95000,'2024-10-15','Approved', 92000, NULL),
(32, 9,175000,'2024-12-21','Approved',170000, NULL),
(33,15, 80000,'2025-01-19','Approved', 78000, NULL),
-- FRAUD-4: same bill claimed twice against different policies
(4,  2, 45000,'2024-02-20','Pending',    NULL, NULL);

-- ----------------------------------------------------------------------------
-- 14. PAYMENTS
-- ----------------------------------------------------------------------------
INSERT INTO payments (bill_id, payment_date, amount, payment_method) VALUES
(1,  '2024-01-10',   800, 'UPI'),
(2,  '2024-01-20',   600, 'Cash'),
(3,  '2024-02-15',   900, 'Card'),
(4,  '2024-02-20', 42000, 'Insurance'),(4,  '2024-02-25',  3000, 'UPI'),
(5,  '2024-03-15', 85000, 'Insurance'),(5,  '2024-03-16',  3000, 'Card'),
(6,  '2024-04-25',210000, 'Insurance'),(6,  '2024-04-26', 15000, 'UPI'),
(7,  '2024-02-15', 60000, 'Insurance'),(7,  '2024-02-16',  2000, 'Cash'),
(8,  '2024-04-01', 78000, 'Cash'),
(9,  '2024-05-01',175000, 'Insurance'),(9,  '2024-05-02',  5000, 'UPI'),
(10, '2024-03-10',150000, 'Insurance'),(10, '2024-03-11',  5000, 'Card'),
(11, '2024-05-25', 80000, 'Insurance'),(11, '2024-05-26',  5000, 'UPI'),
(13, '2024-07-20', 88000, 'Insurance'),(13, '2024-07-21',  4000, 'Card'),
(14, '2024-03-10', 50000, 'Insurance'),(14, '2024-03-11',  5000, 'UPI'),
(15, '2024-05-15', 58000, 'Insurance'),(15, '2024-05-16',  2000, 'Cash'),
(16, '2024-08-15', 70000, 'Insurance'),(16, '2024-08-16',  5000, 'UPI'),
(17, '2024-09-20',115000, 'Insurance'),(17, '2024-09-21',  5000, 'Card'),
(18, '2024-04-20',105000, 'Insurance'),(18, '2024-04-21',  5000, 'UPI'),
(19, '2024-04-01', 65000, 'Insurance'),(19, '2024-04-02',  3000, 'Cash'),
(24, '2024-07-25',135000, 'Cash'),
(25, '2025-02-20', 58000, 'Card'),
(26, '2024-12-01', 72000, 'UPI'),
(27, '2024-07-05', 85000, 'Cash'),
(28, '2024-08-15', 92000, 'UPI'),
(29, '2024-12-20', 88000, 'Card'),
(30, '2024-06-15', 76000, 'Cash'),
(31, '2024-10-20', 92000, 'Insurance'),(31, '2024-10-21',  3000, 'UPI'),
(32, '2024-12-25',170000, 'Insurance'),(32, '2024-12-26',  5000, 'Card'),
(33, '2025-01-25', 78000, 'Insurance'),(33, '2025-01-26',  2000, 'UPI');

-- ============================================================================
-- HIDDEN FRAUD PATTERNS (for 12_fraud_detection.sql to discover)
-- ----------------------------------------------------------------------------
-- FRAUD-1: Doctor id=19 (Dr. Vivek Bhat, Bengaluru) prescribes ~3-4x more meds
--          per appointment than peer cardiologists. Detect via avg qty / doctor.
-- FRAUD-2: Bill_id 23 & 34 both point to the same admission_id=20 → duplicate.
-- FRAUD-3: Bill_id 39 has neither appointment_id nor admission_id → "ghost" bill.
-- FRAUD-4: Bill_id 4 has TWO claims filed against two different policies → dup claim.
-- (More can be seeded later; these 4 are enough for the detection queries.)
-- ============================================================================
