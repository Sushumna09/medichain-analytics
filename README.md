# MediChain Analytics

An SQL analytics project for a fictional multi-branch hospital chain.
The project models the complete revenue cycle of a hospital — from
patient registration and appointments, through admissions and
prescriptions, all the way to billing, insurance claims, and payments —
and exposes it through analytical SQL queries.

Written in **MySQL 8.0** using only standard SQL (portable to
PostgreSQL and SQLite with minor tweaks).

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Workflow](#workflow)
- [Modules](#modules)
- [Example Queries](#example-queries)
- [Portability](#portability)
- [License](#license)

---

## Overview

MediChain Analytics simulates the day-to-day operations of a hospital
chain with **5 branches** across India (Hyderabad, Bengaluru, Mumbai,
Delhi, Chennai). It ships with:

- A **normalized 13-table schema** covering patients, staff, rooms,
  departments, appointments, admissions, prescriptions, medicines,
  insurance policies, bills, claims, and payments.
- **~500 rows of seed data** spread across 2024 – 2025, including
  intentionally seeded fraud patterns and readmission events.
- **~60 analytical queries** organized as themed script files.
- Two dedicated modules that go beyond standard reporting: **Fraud &
  Anomaly Detection** and **Patient Readmission Risk Scoring**.

The goal is to serve as an end-to-end example of a real analytical
workload — schema design, ETL-like data loading, KPI reporting,
anomaly detection, and simple rule-based modeling — all expressed
in SQL.

---

## Features

- Multi-branch hospital chain modeling with per-branch KPIs
- Full insurance workflow: policy → claim → adjudication → payment
- Self-referential staff hierarchy for org-chart queries
- Handles currently-admitted patients via `NULL` discharge dates
- 30-day readmission detection using window functions
- Statistical anomaly detection (over-prescribers, duplicate bills,
  ghost bills, duplicate claims, overlapping admissions)
- Rule-based patient risk scoring implemented entirely in SQL

---

## Tech Stack

| Component | Version |
|---|---|
| Database | MySQL 8.0+ |
| SQL features used | CTEs, recursive CTEs, window functions, `CASE`, date/time functions |
| Tools needed | Any MySQL client (`mysql` CLI, MySQL Workbench, DBeaver, TablePlus) |

No application code, no ORM — the project is 100% SQL.

---

## Database Schema

```
                    hospitals (chain branches)
                        │
        ┌───────────────┼────────────────┐
        ▼               ▼                ▼
   departments       staff              rooms
        │               │                │
        └───────┬───────┘                │
                ▼                        ▼
            appointments             admissions
                │                        │
                ▼                        ▼
           prescriptions ─► medicines    │
                │                        │
                └──────────►  bills  ◄───┘
                                │
                                ▼
                            claims ──► insurance_companies
                                │              ▲
                                ▼              │
                            payments   patient_insurance_policies
                                                ▲
                                                │
                                            patients
```

### Table summary

| Table | Purpose |
|---|---|
| `hospitals` | Master list of chain branches |
| `departments` | Departments per hospital (Cardiology, Neurology, …) |
| `staff` | Doctors, nurses, admin; self-references `manager_id` |
| `rooms` | Inpatient rooms with type and daily charge |
| `patients` | Patient demographics and chronic-condition flag |
| `insurance_companies` | Master list of insurers |
| `patient_insurance_policies` | Which patient has which policy |
| `appointments` | Outpatient visits with status `Attended` / `No-Show` / `Cancelled` |
| `admissions` | Inpatient stays; `discharge_date` is `NULL` while admitted |
| `medicines` | Medicine catalog |
| `prescriptions` | Linked to either an appointment or an admission |
| `bills` | Bill header per appointment / admission |
| `claims` | Insurance claim per bill, with approval workflow |
| `payments` | Payments against bills (cash, card, UPI, insurance) |

Full DDL, foreign keys, and indexes are defined in `01_schema.sql`.

---

## Project Structure

```
medichain-analytics/
├── 01_schema.sql                      # Table definitions, PK/FK, indexes
├── 02_seed_data.sql                   # ~500 rows of realistic sample data
├── 03_basics.sql                      # SELECT / WHERE / ORDER BY / DISTINCT / LIMIT
├── 04_joins.sql                       # INNER / LEFT / RIGHT / SELF / CROSS joins
├── 05_aggregations.sql                # GROUP BY, HAVING, aggregate functions
├── 06_subqueries.sql                  # Scalar, correlated, EXISTS, ANY / ALL
├── 07_ctes.sql                        # WITH clauses, chained CTEs, RECURSIVE CTEs
├── 08_window_functions.sql            # RANK, LAG, LEAD, running totals, moving avg
├── 09_case_and_dates.sql              # CASE WHEN, date math, YoY / MoM
├── 10_pivot_reporting.sql             # Pivot / Unpivot patterns using CASE
├── 11_kpi_dashboard.sql               # 15 hospital operations KPIs
├── 12_fraud_detection.sql             # Anomaly detection queries
├── 13_readmission_risk_scoring.sql    # Rule-based patient risk score in SQL
├── 14_interview_questions.sql         # 30 SQL problems with solutions
└── README.md
```

---

## Getting Started

### Prerequisites

- MySQL 8.0 or newer installed and running
- A user with permission to create a database

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Sushumna09/medichain-analytics.git
   cd medichain-analytics
   ```

2. Connect to MySQL and create the database:

   ```bash
   mysql -u root -p
   ```

   ```sql
   CREATE DATABASE medichain;
   USE medichain;
   ```

3. Load the schema and data:

   ```sql
   SOURCE 01_schema.sql;
   SOURCE 02_seed_data.sql;
   ```

4. Verify the load:

   ```sql
   SELECT COUNT(*) FROM patients;      -- expect 40
   SELECT COUNT(*) FROM admissions;    -- expect 35
   ```

### Running a query file

```sql
SOURCE 08_window_functions.sql;
```

Or from the shell:

```bash
mysql -u root -p medichain < 11_kpi_dashboard.sql
```

---

## Workflow

The data flows through the schema in the following order:

1. **Registration** — a patient record is created in `patients`.
2. **Insurance (optional)** — a `patient_insurance_policy` row links the
   patient to an insurer.
3. **Outpatient visit** — an `appointment` is created and (if attended)
   may generate `prescriptions` and a `bill`.
4. **Inpatient stay** — an `admission` is created, a room is assigned,
   the attending doctor may write `prescriptions`, and on discharge a
   `bill` is generated.
5. **Billing** — every `bill` records a total amount.
6. **Insurance claim** — if the patient has a policy, a `claim` is
   filed against the bill and adjudicated (`Approved` / `Rejected` /
   `Pending`).
7. **Payment** — one or more `payments` are made against the bill,
   possibly via multiple methods (insurance + cash top-up, for example).

The analytical query files traverse these entities to produce KPIs,
detect anomalies, and score patient risk.

---

## Modules

The 14 SQL files are organized into three logical groups.

### Foundations — `01` through `10`

Progressively cover core SQL: schema design, seed data, and every major
query construct (joins, aggregation, subqueries, CTEs, window
functions, CASE, date functions, pivot patterns).

### Business KPIs — `11_kpi_dashboard.sql`

Fifteen queries that compute the operational KPIs a hospital chain
would put on an executive dashboard:

- Revenue per hospital, per bed, per department
- Bed occupancy rate
- Average length of stay
- 30-day readmission rate
- No-show rate
- Claim rejection rate
- Doctor productivity
- Repeat-patient rate
- New-patient acquisition trend

### Advanced Modules — `12` and `13`

- **`12_fraud_detection.sql`** — ten queries that flag data anomalies:
  over-prescribing doctors (using per-specialization averages),
  duplicate admission bills, ghost bills with no linked service,
  duplicate claim submissions, impossible stay lengths, over-approved
  claims, doctor-shopping patients, and overlapping admissions.

- **`13_readmission_risk_scoring.sql`** — a pure-SQL rule-based scoring
  model that assigns each patient a `risk_score` between `0` and `100`
  based on age, chronic conditions, prior admissions, average length
  of stay, ICU history, and recency of last visit. Patients are then
  bucketed into `HIGH`, `MEDIUM`, or `LOW` risk tiers with a suggested
  follow-up action.

### Practice — `14_interview_questions.sql`

Thirty SQL problems with worked solutions, grouped by difficulty and
topic. Useful for revision.

---

## Example Queries

**Revenue per bed, per hospital:**

```sql
SELECT
    h.name,
    h.total_beds,
    ROUND(SUM(b.total_amount) / h.total_beds, 0) AS revenue_per_bed
FROM bills b
JOIN admissions a ON a.admission_id = b.admission_id
JOIN hospitals  h ON h.hospital_id  = a.hospital_id
WHERE b.status = 'Paid'
GROUP BY h.hospital_id, h.name, h.total_beds
ORDER BY revenue_per_bed DESC;
```

**30-day readmission flag using `LAG`:**

```sql
SELECT
    patient_id,
    admission_id,
    admit_date,
    LAG(discharge_date) OVER (
        PARTITION BY patient_id ORDER BY admit_date
    ) AS prev_discharge,
    CASE
        WHEN DATEDIFF(
                admit_date,
                LAG(discharge_date) OVER (
                    PARTITION BY patient_id ORDER BY admit_date)
            ) <= 30
        THEN 'READMISSION'
        ELSE 'FIRST/NEW'
    END AS flag
FROM admissions;
```

**Over-prescribing doctors (Fraud Anomaly 1):**

```sql
WITH doc_qty AS (
    SELECT s.staff_id, s.name, s.specialization,
           SUM(rx.quantity) AS units
    FROM prescriptions rx
    JOIN staff s ON s.staff_id = rx.doctor_id
    WHERE s.role = 'Doctor'
    GROUP BY s.staff_id, s.name, s.specialization
),
spec_avg AS (
    SELECT specialization, AVG(units) AS avg_units
    FROM doc_qty
    GROUP BY specialization
)
SELECT dq.name, dq.specialization, dq.units, sa.avg_units
FROM doc_qty dq
JOIN spec_avg sa ON sa.specialization = dq.specialization
WHERE dq.units > 2 * sa.avg_units;
```

---

## Portability

The queries target MySQL 8.0 but are ~95% portable. Adjustments needed
for other engines:

| Feature | MySQL | PostgreSQL | SQLite |
|---|---|---|---|
| Auto-increment PK | `AUTO_INCREMENT` | `SERIAL` / `GENERATED` | `AUTOINCREMENT` |
| Format a date | `DATE_FORMAT(d, '%Y-%m')` | `TO_CHAR(d, 'YYYY-MM')` | `strftime('%Y-%m', d)` |
| Date arithmetic | `DATE_SUB(d, INTERVAL 1 MONTH)` | `d - INTERVAL '1 month'` | `date(d, '-1 month')` |
| Boolean shortcut inside `SUM` | `SUM(status='X')` | `SUM(CASE WHEN status='X' THEN 1 ELSE 0 END)` | same as Postgres |

All CTEs, recursive CTEs, and window functions used are standard
SQL:2003+ and work in all three engines.

---

## License

Released under the MIT License. See `LICENSE` if present, otherwise
free to use for learning and demonstration purposes.
