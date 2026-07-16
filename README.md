# MediChain Analytics

An SQL analytics project modeling the operations of a fictional multi-branch
hospital chain — from patient registration and appointments, through admissions
and prescriptions, to billing, insurance claims, and payments.

Built with **MySQL 8.0**. All logic — schema, seed data, KPIs, anomaly
detection, and risk scoring — is expressed in standard SQL.
A lightweight HTML dashboard (`dashboard.html`) visualizes the results.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Dashboard](#dashboard)
- [Workflow](#workflow)
- [Modules](#modules)
- [Example Queries](#example-queries)
- [Portability](#portability)
- [License](#license)

---

## Overview

MediChain is a hospital chain with five branches across India — Hyderabad,
Bengaluru, Mumbai, Delhi, and Chennai. This repository defines its analytical
back-end: a normalized 13-table schema, roughly 500 rows of seed data spanning
2024–2025, and a suite of SQL scripts that compute operational KPIs and
surface data-quality anomalies.

The scripts are organized so that the first ten cover core SQL patterns
(joins, aggregation, subqueries, CTEs, window functions, and pivoting),
while the final three focus on business-level analytics — KPI dashboards,
fraud & anomaly detection, and rule-based patient risk scoring.

A companion **HTML dashboard** renders the key results as charts and tables
so the queries can be reviewed visually without connecting to a database.

---

## Features

- Multi-branch chain modeling with per-branch KPIs
- Full insurance workflow: policy → claim → adjudication → payment
- Self-referential staff hierarchy for org-chart traversal
- 30-day readmission detection using `LAG` on admissions
- Statistical anomaly detection — over-prescribers, duplicate bills,
  ghost bills, duplicate claims, overlapping admissions
- Rule-based patient risk scoring implemented entirely in SQL
- Static HTML dashboard (Chart.js, no build step) to visualize results

---

## Tech Stack

| Component | Version |
|---|---|
| Database | MySQL 8.0+ |
| SQL features | CTEs, recursive CTEs, window functions, `CASE`, date/time functions |
| Client tools | Any MySQL client — `mysql` CLI, MySQL Workbench, DBeaver, TablePlus |
| Dashboard | HTML + vanilla JavaScript + [Chart.js](https://www.chartjs.org/) (via CDN) |

The project contains no application code and no ORM. All analytics are in SQL;
the dashboard is a single self-contained HTML file.

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
| `patient_insurance_policies` | Association between patients and insurers |
| `appointments` | Outpatient visits, status `Attended` / `No-Show` / `Cancelled` |
| `admissions` | Inpatient stays; `discharge_date` is `NULL` while admitted |
| `medicines` | Medicine catalog |
| `prescriptions` | Linked to either an appointment or an admission |
| `bills` | Bill header per appointment or admission |
| `claims` | Insurance claim per bill, with approval workflow |
| `payments` | Payments against bills (cash, card, UPI, insurance) |

Full DDL, foreign keys, and indexes are defined in `01_schema.sql`.

---

## Project Structure

```
medichain-analytics/
├── 01_schema.sql                      # Table definitions, PK/FK, indexes
├── 02_seed_data.sql                   # ~500 rows of sample data
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
├── dashboard.html                     # Chart.js visualization of key KPIs
└── README.md
```

---

## Getting Started

### Prerequisites

- MySQL 8.0 or newer
- A user with permission to create a database

### Installation

1. Clone the repository.

   ```bash
   git clone https://github.com/Sushumna09/medichain-analytics.git
   cd medichain-analytics
   ```

2. Create the database and load the schema and data.

   ```bash
   mysql -u root -p
   ```

   ```sql
   CREATE DATABASE medichain;
   USE medichain;

   SOURCE 01_schema.sql;
   SOURCE 02_seed_data.sql;
   ```

3. Verify the load.

   ```sql
   SELECT COUNT(*) FROM patients;      -- 40
   SELECT COUNT(*) FROM admissions;    -- 35
   ```

### Running a query file

From inside the MySQL prompt:

```sql
SOURCE 08_window_functions.sql;
```

Or from the shell:

```bash
mysql -u root -p medichain < 11_kpi_dashboard.sql
```

---

## Dashboard

`dashboard.html` is a single self-contained page that visualizes the main
results computed by the SQL scripts. It uses **Chart.js** (loaded from a CDN)
and requires no build step and no live database connection — the numbers it
displays are the pre-computed outputs of the queries, embedded inline as
JavaScript data. To regenerate them, run the corresponding SQL against your
own database and update the `data` object at the bottom of the file.

### Viewing options

- **Locally.** Just open the file in a browser:

  ```bash
  open dashboard.html            # macOS
  xdg-open dashboard.html        # Linux
  start dashboard.html           # Windows
  ```

- **Live on the web via GitHub Pages.**
  1. Go to the repository → **Settings** → **Pages**.
  2. Under *Source*, select **Deploy from a branch** → branch `main` → folder `/ (root)` → **Save**.
  3. After a minute the site is live at
     `https://sushumna09.github.io/medichain-analytics/dashboard.html`.

### What the dashboard shows

- **Overview** — six KPI cards (revenue, patients, admissions, doctors,
  readmission rate, fraud alerts).
- **Revenue analytics** — revenue by hospital and revenue per bed.
- **Operations** — monthly admissions trend and top diagnoses by revenue.
- **Quality & compliance** — appointment outcomes and claim status by insurer.
- **Fraud & anomaly alerts** — a table of the incidents detected by
  `12_fraud_detection.sql`.
- **High-risk patients** — top patients by readmission risk score from
  `13_readmission_risk_scoring.sql`.

Each chart cites the SQL file and query number it was derived from.

---

## Workflow

Data flows through the schema in the following order.

1. **Registration.** A patient record is created in `patients`.
2. **Insurance (optional).** A `patient_insurance_policy` row links the patient
   to an insurer with a coverage limit and validity window.
3. **Outpatient visit.** An `appointment` is created and, if attended, may
   generate `prescriptions` and a `bill`.
4. **Inpatient stay.** An `admission` is created, a room is assigned, the
   attending doctor may write `prescriptions`, and on discharge a `bill` is
   generated.
5. **Billing.** Every `bill` records the total amount and its payment status.
6. **Insurance claim.** If the patient has an active policy, a `claim` is
   filed against the bill and adjudicated (`Approved` / `Rejected` / `Pending`).
7. **Payment.** One or more `payments` are recorded against the bill, possibly
   via multiple methods (for example insurance settlement plus a cash top-up).

The analytical scripts traverse these entities to compute KPIs, flag
anomalies, and score patient risk.

---

## Modules

The scripts are grouped as follows.

### Foundations — `01` through `10`

Cover schema design, seed data, and every major query construct: joins,
aggregation, subqueries, CTEs (including recursive), window functions, `CASE`
expressions, date/time arithmetic, and pivot patterns.

### Business KPIs — `11_kpi_dashboard.sql`

Fifteen operational KPIs that a hospital chain would typically surface on an
executive dashboard:

- Revenue per hospital, per bed, and per department
- Bed occupancy rate
- Average length of stay
- 30-day readmission rate
- No-show rate
- Claim rejection rate per insurer
- Doctor productivity leaderboard
- Repeat-patient rate
- New-patient acquisition trend

### Fraud & Anomaly Detection — `12_fraud_detection.sql`

Ten queries that flag data anomalies using a mix of statistical thresholds
and integrity checks. Findings include over-prescribing doctors (relative to
per-specialization averages), duplicate admission bills, ghost bills with no
linked service, duplicate claim submissions, impossible stay lengths, over-
approved claims, doctor-shopping patients, and overlapping admissions.

### Patient Readmission Risk Scoring — `13_readmission_risk_scoring.sql`

A rule-based scoring model implemented in SQL that assigns each patient a
`risk_score` between `0` and `100` based on age, chronic conditions, prior
admissions, average length of stay, ICU history, and recency of the last
visit. Patients are bucketed into `HIGH`, `MEDIUM`, or `LOW` risk tiers, each
with a suggested follow-up action.

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

**Over-prescribing doctors (Anomaly 1):**

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

The queries target MySQL 8.0 but are largely portable. The syntactic
adjustments needed for other engines are:

| Feature | MySQL | PostgreSQL | SQLite |
|---|---|---|---|
| Auto-increment PK | `AUTO_INCREMENT` | `SERIAL` / `GENERATED` | `AUTOINCREMENT` |
| Format a date | `DATE_FORMAT(d, '%Y-%m')` | `TO_CHAR(d, 'YYYY-MM')` | `strftime('%Y-%m', d)` |
| Date arithmetic | `DATE_SUB(d, INTERVAL 1 MONTH)` | `d - INTERVAL '1 month'` | `date(d, '-1 month')` |
| Boolean shortcut in `SUM` | `SUM(status='X')` | `SUM(CASE WHEN status='X' THEN 1 ELSE 0 END)` | same as Postgres |

All CTEs, recursive CTEs, and window functions used are standard SQL:2003+
and work across the three engines above.

---

## License

Released under the MIT License.
