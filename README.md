# MediChain Analytics — Hospital Chain Intelligence Platform (SQL Project)

> A pure-SQL analytics project modeling a 5-branch hospital chain with insurance
> claim workflows, fraud detection, and patient readmission risk scoring.

Built as a portfolio project for analytics / data-engineering placements
(**DAA / BTSA / Data Analyst / SQL Developer** roles).

---

## Why This Project Stands Out

Most "Hospital Management" SQL projects on GitHub are basic CRUD databases
with a few `SELECT * FROM patients` queries. This one is different:

| Standard hospital projects | MediChain Analytics |
|---|---|
| Single hospital | 5-branch **hospital chain** (Hyderabad, Bengaluru, Mumbai, Delhi, Chennai) |
| Only patients / doctors / bills | Adds **insurance companies**, **policies**, and full **claim workflow** |
| Only descriptive queries | Includes a dedicated **Fraud & Anomaly Detection module** |
| Only reports "what happened" | Includes a **Patient Readmission Risk-Scoring model** in pure SQL |
| Random queries | Each query is framed as a real question from the CFO / CMO / Compliance team |
| Ignores realistic complexity | Handles self-referential staff hierarchy, NULL discharges, multi-policy patients |

---

## The Business Scenario

You are a data analyst at **MediChain**, a hospital chain with 5 branches
across India. Leadership wants answers to questions like:

- Which branch is the most profitable? What's revenue per bed?
- What's our 30-day readmission rate? (an industry benchmark)
- Which insurance companies reject the most claims?
- Are any of our doctors over-prescribing medicines? (fraud check)
- Which patients are at HIGH risk of readmission — so we can call them proactively?
- Year-over-year and month-over-month growth by hospital / department?

All answered here with SQL alone.

---

## Data Model — 13 Tables

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

| Table | Purpose |
|---|---|
| `hospitals` | 5 chain branches |
| `departments` | 6 per hospital (Cardiology, Neurology, Ortho, Pediatrics, General, Emergency) |
| `staff` | Doctors, nurses, admin — self-references `manager_id` |
| `rooms` | Inpatient rooms with type & daily charge |
| `patients` | Demographics + chronic-condition flag |
| `insurance_companies` | 5 insurers |
| `patient_insurance_policies` | Which patient has which policy |
| `appointments` | Outpatient visits (`Attended` / `No-Show` / `Cancelled`) |
| `admissions` | Inpatient stays (with NULL discharge for currently admitted) |
| `medicines` | Drug catalog |
| `prescriptions` | Linked to an appointment OR an admission |
| `bills` → `claims` → `payments` | Full revenue cycle |

Full DDL in `01_schema.sql`.

---

## File Index

| # | File | What it teaches | Interview weight |
|---|---|---|---|
| 1 | `01_schema.sql` | Tables, PK/FK, indexes | ⭐⭐ |
| 2 | `02_seed_data.sql` | ~500 realistic rows *(with hidden fraud patterns)* | — |
| 3 | `03_basics.sql` | SELECT / WHERE / DISTINCT / ORDER BY / LIMIT | ⭐ |
| 4 | `04_joins.sql` | All join types + self-join | ⭐⭐⭐ |
| 5 | `05_aggregations.sql` | GROUP BY, HAVING, aggregates | ⭐⭐⭐ |
| 6 | `06_subqueries.sql` | Nested, correlated, EXISTS, ANY / ALL | ⭐⭐ |
| 7 | `07_ctes.sql` | WITH, chained CTEs, recursive CTEs | ⭐⭐ |
| 8 | `08_window_functions.sql` | RANK, LAG/LEAD, running totals, moving avg | ⭐⭐⭐⭐ |
| 9 | `09_case_and_dates.sql` | CASE WHEN, YoY, MoM, date math | ⭐⭐⭐ |
| 10 | `10_pivot_reporting.sql` | Pivot / Unpivot via CASE | ⭐⭐ |
| 11 | `11_kpi_dashboard.sql` | 15 real hospital KPIs | ⭐⭐⭐ |
| 12 | `12_fraud_detection.sql` | Anomaly detection (unique module) | ⭐⭐⭐ |
| 13 | `13_readmission_risk_scoring.sql` | Rule-based risk model in SQL (unique module) | ⭐⭐⭐ |
| 14 | `14_interview_questions.sql` | 30 problems from ZS, Amazon, Deloitte, Accenture, TCS, Flipkart | ⭐⭐⭐⭐⭐ |

Plus:
- `CHEATSHEET.md` — 1-page SQL syntax reference
- `BUSINESS_QUESTIONS.md` — 40+ business questions with the exact query that answers each
- `INSIGHTS.md` — narrative insights the analysis surfaces

---

## Quick Start (MySQL 8.0+)

```bash
mysql -u root -p
```

```sql
CREATE DATABASE medichain;
USE medichain;

SOURCE 01_schema.sql;
SOURCE 02_seed_data.sql;

-- Then browse any query file
SOURCE 08_window_functions.sql;
SOURCE 12_fraud_detection.sql;
SOURCE 13_readmission_risk_scoring.sql;
```

Or one-shot from your terminal:

```bash
mysql -u root -p medichain < 01_schema.sql
mysql -u root -p medichain < 02_seed_data.sql
```

### PostgreSQL / SQLite users

~95% of the queries are portable. Two syntactic differences:

- `AUTO_INCREMENT` → use `SERIAL` (Postgres) or `AUTOINCREMENT` (SQLite)
- `DATE_FORMAT()` / `DATE_SUB()` → use `TO_CHAR()` / `INTERVAL '1 month'` (Postgres) or `strftime()` (SQLite)

---

## Recommended Study Order

1. Read `01_schema.sql` — draw the ER diagram on paper.
2. Load data with `02_seed_data.sql` — spot-check a few rows.
3. Work through files **03 → 10** in order. Type them out; don't copy-paste.
4. Study `11_kpi_dashboard.sql` — these are the questions you'll answer on the job.
5. Dive into the two unique modules — `12_fraud_detection.sql` and `13_readmission_risk_scoring.sql` — these are the talking points that make interviews interesting.
6. Attempt every question in `14_interview_questions.sql` **before** looking at the solution.

---

## Resume Bullet (feel free to reuse)

> **MediChain Analytics — Hospital Chain Intelligence Platform** · MySQL
> Designed a 13-table analytical schema modeling a 5-branch hospital chain with
> insurance claim workflows. Wrote 60+ analytical SQL queries using CTEs,
> recursive queries, and window functions to compute hospital KPIs (bed
> occupancy, average length of stay, 30-day readmission %, claim rejection %,
> revenue per bed). Built two custom SQL-only modules: a **Fraud & Anomaly
> Detection engine** flagging over-billing and duplicate claims, and a
> **Patient Readmission Risk-Scoring model**. Also compiled 30 interview
> problems solved from ZS, Amazon, Deloitte, and TCS style guides.

---

## Skills Demonstrated

- **Schema design** — normalization, PK/FK, indexes, self-referencing keys
- **Joins** — inner / left / right / self / cross, multi-table
- **Aggregation** — GROUP BY, HAVING, conditional (CASE inside SUM)
- **Subqueries** — scalar, correlated, EXISTS / NOT EXISTS, derived tables
- **CTEs** — WITH, chained, RECURSIVE (hierarchy & date series)
- **Window functions** — ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, NTILE, running totals, rolling averages
- **Date functions** — YoY, MoM, cohort periods, day-of-week analysis
- **Pivot / Unpivot** — via CASE expressions
- **Business analytics** — KPIs, market share, retention, growth rates
- **Anomaly detection** — statistical outliers, duplicate detection, integrity rules
- **Rule-based scoring** — implementing a mini "model" in SQL alone

---

## About

Built by **Sushumna** as a placement-ready SQL portfolio project.
Feedback and pull requests welcome!
