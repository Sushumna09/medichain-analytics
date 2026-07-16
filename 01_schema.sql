-- ============================================================================
-- FILE  : 01_schema.sql
-- PROJECT: MediChain Analytics
-- PURPOSE: Create the full 13-table schema for a multi-branch hospital chain
--          with insurance & claim workflows.
--
-- HOW TO RUN (MySQL 8.0+):
--   CREATE DATABASE IF NOT EXISTS medichain;
--   USE medichain;
--   SOURCE 01_schema.sql;
-- ============================================================================

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS patient_insurance_policies;
DROP TABLE IF EXISTS insurance_companies;
DROP TABLE IF EXISTS medicines;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS hospitals;

-- ----------------------------------------------------------------------------
-- 1. HOSPITALS  (the "chain" — 5 branches across Indian cities)
-- ----------------------------------------------------------------------------
CREATE TABLE hospitals (
    hospital_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    city            VARCHAR(50)  NOT NULL,
    state           VARCHAR(50)  NOT NULL,
    opening_date    DATE         NOT NULL,
    total_beds      INT          NOT NULL
);

-- ----------------------------------------------------------------------------
-- 2. DEPARTMENTS  (Cardiology, Neurology, ... — one row per dept per hospital)
-- ----------------------------------------------------------------------------
CREATE TABLE departments (
    department_id   INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id     INT          NOT NULL,
    name            VARCHAR(50)  NOT NULL,
    CONSTRAINT fk_dept_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

-- ----------------------------------------------------------------------------
-- 3. STAFF  (doctors, nurses, admin — self-referential manager_id)
-- ----------------------------------------------------------------------------
CREATE TABLE staff (
    staff_id        INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id     INT          NOT NULL,
    department_id   INT,                              -- NULL for admin
    name            VARCHAR(100) NOT NULL,
    role            VARCHAR(30)  NOT NULL,            -- Doctor / Nurse / Admin / Technician
    specialization  VARCHAR(50),                      -- NULL for non-doctors
    hire_date       DATE         NOT NULL,
    salary          DECIMAL(10,2) NOT NULL,
    manager_id      INT,                              -- self-ref, NULL for top of hierarchy
    CONSTRAINT fk_staff_hospital  FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id),
    CONSTRAINT fk_staff_dept      FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_staff_manager   FOREIGN KEY (manager_id) REFERENCES staff(staff_id)
);

-- ----------------------------------------------------------------------------
-- 4. ROOMS  (inpatient rooms with type & daily charge)
-- ----------------------------------------------------------------------------
CREATE TABLE rooms (
    room_id         INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id     INT          NOT NULL,
    room_number     VARCHAR(10)  NOT NULL,
    room_type       VARCHAR(20)  NOT NULL,            -- General / Semi-Private / Private / ICU / Deluxe
    daily_charge    DECIMAL(8,2) NOT NULL,
    status          VARCHAR(20)  NOT NULL DEFAULT 'Available',   -- Available / Occupied / Maintenance
    CONSTRAINT fk_room_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

-- ----------------------------------------------------------------------------
-- 5. PATIENTS
-- ----------------------------------------------------------------------------
CREATE TABLE patients (
    patient_id             INT AUTO_INCREMENT PRIMARY KEY,
    name                   VARCHAR(100) NOT NULL,
    dob                    DATE         NOT NULL,
    gender                 CHAR(1)      NOT NULL,           -- M / F / O
    city                   VARCHAR(50),
    blood_group            VARCHAR(3),
    registration_date      DATE         NOT NULL,
    has_chronic_condition  TINYINT(1)   NOT NULL DEFAULT 0  -- 1 = diabetes/hypertension/etc.
);

-- ----------------------------------------------------------------------------
-- 6. INSURANCE COMPANIES
-- ----------------------------------------------------------------------------
CREATE TABLE insurance_companies (
    insurer_id      INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    rating          DECIMAL(2,1)                       -- e.g. 4.2 out of 5
);

-- ----------------------------------------------------------------------------
-- 7. PATIENT INSURANCE POLICIES  (a patient can have 0 or more policies)
-- ----------------------------------------------------------------------------
CREATE TABLE patient_insurance_policies (
    policy_id        INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT           NOT NULL,
    insurer_id       INT           NOT NULL,
    policy_number    VARCHAR(30)   NOT NULL UNIQUE,
    coverage_limit   DECIMAL(10,2) NOT NULL,
    start_date       DATE          NOT NULL,
    end_date         DATE          NOT NULL,
    CONSTRAINT fk_pol_patient FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_pol_insurer FOREIGN KEY (insurer_id) REFERENCES insurance_companies(insurer_id)
);

-- ----------------------------------------------------------------------------
-- 8. APPOINTMENTS  (outpatient visits)
-- ----------------------------------------------------------------------------
CREATE TABLE appointments (
    appointment_id     INT AUTO_INCREMENT PRIMARY KEY,
    patient_id         INT          NOT NULL,
    doctor_id          INT          NOT NULL,
    hospital_id        INT          NOT NULL,
    appointment_date   DATETIME     NOT NULL,
    status             VARCHAR(15)  NOT NULL,           -- Attended / No-Show / Cancelled
    consultation_fee   DECIMAL(8,2) NOT NULL,
    CONSTRAINT fk_appt_patient  FOREIGN KEY (patient_id)  REFERENCES patients(patient_id),
    CONSTRAINT fk_appt_doctor   FOREIGN KEY (doctor_id)   REFERENCES staff(staff_id),
    CONSTRAINT fk_appt_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

-- ----------------------------------------------------------------------------
-- 9. ADMISSIONS  (inpatient stays)
--    discharge_date is NULL while patient is still admitted (great for LEFT JOIN practice)
-- ----------------------------------------------------------------------------
CREATE TABLE admissions (
    admission_id          INT AUTO_INCREMENT PRIMARY KEY,
    patient_id            INT          NOT NULL,
    hospital_id           INT          NOT NULL,
    room_id               INT          NOT NULL,
    attending_doctor_id   INT          NOT NULL,
    admit_date            DATE         NOT NULL,
    discharge_date        DATE,                          -- NULL = still admitted
    diagnosis             VARCHAR(100) NOT NULL,
    discharge_status      VARCHAR(20),                   -- Recovered / Transferred / DAMA / Deceased / NULL
    CONSTRAINT fk_adm_patient  FOREIGN KEY (patient_id)          REFERENCES patients(patient_id),
    CONSTRAINT fk_adm_hospital FOREIGN KEY (hospital_id)         REFERENCES hospitals(hospital_id),
    CONSTRAINT fk_adm_room     FOREIGN KEY (room_id)             REFERENCES rooms(room_id),
    CONSTRAINT fk_adm_doctor   FOREIGN KEY (attending_doctor_id) REFERENCES staff(staff_id)
);

-- ----------------------------------------------------------------------------
-- 10. MEDICINES
-- ----------------------------------------------------------------------------
CREATE TABLE medicines (
    medicine_id     INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100) NOT NULL,
    category        VARCHAR(40)  NOT NULL,       -- Antibiotic / Analgesic / Antihypertensive / ...
    unit_price      DECIMAL(8,2) NOT NULL,
    stock_quantity  INT          NOT NULL
);

-- ----------------------------------------------------------------------------
-- 11. PRESCRIPTIONS  (linked to an appointment OR an admission)
-- ----------------------------------------------------------------------------
CREATE TABLE prescriptions (
    prescription_id   INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id    INT,                    -- one of these two is NOT NULL
    admission_id      INT,
    doctor_id         INT NOT NULL,
    medicine_id       INT NOT NULL,
    quantity          INT NOT NULL,
    prescribed_date   DATE NOT NULL,
    CONSTRAINT fk_rx_appt      FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    CONSTRAINT fk_rx_admission FOREIGN KEY (admission_id)   REFERENCES admissions(admission_id),
    CONSTRAINT fk_rx_doctor    FOREIGN KEY (doctor_id)      REFERENCES staff(staff_id),
    CONSTRAINT fk_rx_medicine  FOREIGN KEY (medicine_id)    REFERENCES medicines(medicine_id)
);

-- ----------------------------------------------------------------------------
-- 12. BILLS
-- ----------------------------------------------------------------------------
CREATE TABLE bills (
    bill_id          INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT          NOT NULL,
    appointment_id   INT,                          -- either appointment OR admission
    admission_id     INT,
    bill_date        DATE         NOT NULL,
    total_amount     DECIMAL(10,2) NOT NULL,
    status           VARCHAR(15)   NOT NULL,       -- Paid / Pending / Partially Paid
    CONSTRAINT fk_bill_patient   FOREIGN KEY (patient_id)     REFERENCES patients(patient_id),
    CONSTRAINT fk_bill_appt      FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    CONSTRAINT fk_bill_admission FOREIGN KEY (admission_id)   REFERENCES admissions(admission_id)
);

-- ----------------------------------------------------------------------------
-- 13. CLAIMS  (insurance claim workflow: Approved / Rejected / Pending)
-- ----------------------------------------------------------------------------
CREATE TABLE claims (
    claim_id           INT AUTO_INCREMENT PRIMARY KEY,
    bill_id            INT          NOT NULL,
    policy_id          INT          NOT NULL,
    claim_amount       DECIMAL(10,2) NOT NULL,
    claim_date         DATE         NOT NULL,
    status             VARCHAR(15)  NOT NULL,        -- Approved / Rejected / Pending
    approved_amount    DECIMAL(10,2),
    rejection_reason   VARCHAR(200),
    CONSTRAINT fk_claim_bill   FOREIGN KEY (bill_id)   REFERENCES bills(bill_id),
    CONSTRAINT fk_claim_policy FOREIGN KEY (policy_id) REFERENCES patient_insurance_policies(policy_id)
);

-- ----------------------------------------------------------------------------
-- 14. PAYMENTS
-- ----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id       INT AUTO_INCREMENT PRIMARY KEY,
    bill_id          INT           NOT NULL,
    payment_date     DATE          NOT NULL,
    amount           DECIMAL(10,2) NOT NULL,
    payment_method   VARCHAR(15)   NOT NULL,          -- Cash / Card / UPI / Insurance
    CONSTRAINT fk_pay_bill FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
);

-- ============================================================================
-- INDEXES  (speed up common analytical queries)
-- ============================================================================
CREATE INDEX idx_appt_date        ON appointments (appointment_date);
CREATE INDEX idx_appt_doctor      ON appointments (doctor_id);
CREATE INDEX idx_adm_dates        ON admissions   (admit_date, discharge_date);
CREATE INDEX idx_adm_patient      ON admissions   (patient_id);
CREATE INDEX idx_rx_doctor        ON prescriptions(doctor_id);
CREATE INDEX idx_bill_date        ON bills        (bill_date);
CREATE INDEX idx_claim_status     ON claims       (status);
CREATE INDEX idx_staff_dept       ON staff        (department_id);
