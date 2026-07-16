# Business Questions → SQL Query Map

This is the "so what?" file. Every query in this project answers a real
business question. Use this map when explaining the project in an interview —
recruiters love it when you can jump from a business need to the exact SQL
that solves it.

---

## 🏥 Operations (What's happening in our hospitals?)

| # | Business question | File / Query |
|---|---|---|
| 1 | How many patients do we currently have? | `03_basics.sql` Q15 |
| 2 | Which patients are chronic (diabetic/hypertensive)? | `05_aggregations.sql` Q1 |
| 3 | Which rooms are ICU and occupied right now? | `14_interview_questions.sql` Q4 |
| 4 | Which patients are currently admitted? | `03_basics.sql` Q9 |
| 5 | Bed occupancy rate per branch? | `11_kpi_dashboard.sql` KPI 5 |
| 6 | Average length of stay by diagnosis? | `05_aggregations.sql` Q11 |
| 7 | Length-of-stay bucket distribution? | `09_case_and_dates.sql` Q3 |
| 8 | How busy is each weekday? | `09_case_and_dates.sql` Q8 |

---

## 💰 Revenue & Finance (Where's the money?)

| # | Business question | File / Query |
|---|---|---|
| 9  | Total revenue chain-wide? | `11_kpi_dashboard.sql` KPI 1 |
| 10 | Revenue per hospital? | `11_kpi_dashboard.sql` KPI 2 |
| 11 | Revenue per BED (efficiency)? | `11_kpi_dashboard.sql` KPI 3 |
| 12 | Revenue by department? | `11_kpi_dashboard.sql` KPI 10 |
| 13 | Monthly revenue trend? | `09_case_and_dates.sql` Q6 |
| 14 | Year-over-year revenue growth? | `09_case_and_dates.sql` Q7 |
| 15 | Cumulative revenue over time? | `08_window_functions.sql` Q6 |
| 16 | Cumulative revenue per hospital by month? | `14_interview_questions.sql` Q23 |
| 17 | 7-day rolling revenue average? | `08_window_functions.sql` Q7 |
| 18 | Top 5 diagnoses by revenue? | `11_kpi_dashboard.sql` KPI 15 |
| 19 | Bills that are unpaid → escalate? | `09_case_and_dates.sql` Q4 |

---

## 👨‍⚕️ People (Doctors, staff, patients)

| # | Business question | File / Query |
|---|---|---|
| 20 | Top-3 highest-paid doctors per hospital? | `08_window_functions.sql` Q3 |
| 21 | Salary percentile of each doctor? | `08_window_functions.sql` Q10 |
| 22 | Doctor productivity leaderboard? | `11_kpi_dashboard.sql` KPI 9 |
| 23 | Full org-chart tree (staff → manager)? | `07_ctes.sql` Q4 |
| 24 | Reporting chain for a specific employee? | `14_interview_questions.sql` Q19 |
| 25 | Doctors who earn more than dept average? | `06_subqueries.sql` Q7 |
| 26 | Top-earning doctor per hospital? | `14_interview_questions.sql` Q7 |
| 27 | Repeat patients (loyalty proxy)? | `11_kpi_dashboard.sql` KPI 11 |
| 28 | Age-group distribution of patients? | `09_case_and_dates.sql` Q1 |
| 29 | Patient tenure buckets? | `09_case_and_dates.sql` Q9 |

---

## 📈 Growth & Trends

| # | Business question | File / Query |
|---|---|---|
| 30 | Monthly admissions trend? | `07_ctes.sql` Q5 |
| 31 | Month-over-month admission growth? | `08_window_functions.sql` Q12 |
| 32 | 3-month rolling avg admissions? | `14_interview_questions.sql` Q22 |
| 33 | New-patient acquisition per month? | `11_kpi_dashboard.sql` KPI 14 |
| 34 | Market share of each hospital? | `14_interview_questions.sql` Q27 |
| 35 | Cohort retention (Jan-2024 patients)? | `14_interview_questions.sql` Q29 |
| 36 | YoY growth in Cardiology per branch? | `14_interview_questions.sql` Q26 |

---

## 🛡️ Insurance & Claims

| # | Business question | File / Query |
|---|---|---|
| 37 | Claim summary by insurer? | `05_aggregations.sql` Q10 |
| 38 | Which insurer rejects the most claims? | `11_kpi_dashboard.sql` KPI 8 |
| 39 | Insurance share of total collections? | `11_kpi_dashboard.sql` KPI 13 |
| 40 | Patients without any insurance? | `04_joins.sql` Q5 |
| 41 | Insurers covering 3+ patients? | `14_interview_questions.sql` Q12 |

---

## 🕵️ Fraud & Anomaly Detection (unique module)

| # | Business question | File / Query |
|---|---|---|
| 42 | Doctors over-prescribing vs peers? | `12_fraud_detection.sql` A1 |
| 43 | Same admission billed twice? | `12_fraud_detection.sql` A2 |
| 44 | "Ghost" bills with no linked service? | `12_fraud_detection.sql` A3 |
| 45 | Same bill claimed against multiple policies? | `12_fraud_detection.sql` A4 |
| 46 | Impossibly long or negative stays? | `12_fraud_detection.sql` A6 |
| 47 | Claims approved for more than the bill? | `12_fraud_detection.sql` A7 |
| 48 | Patients "doctor-shopping" (excessive visits)? | `12_fraud_detection.sql` A8 |
| 49 | Same patient admitted to 2 hospitals simultaneously? | `12_fraud_detection.sql` A9 |

---

## 🎯 Predictive / Prescriptive (unique module)

| # | Business question | File / Query |
|---|---|---|
| 50 | Which patients are at HIGH risk of 30-day readmission? | `13_readmission_risk_scoring.sql` |
| 51 | Distribution of patients by risk tier? | `13_readmission_risk_scoring.sql` (Bonus) |
| 52 | 30-day readmission rate per hospital? | `11_kpi_dashboard.sql` KPI 6 |
| 53 | Which admission was a readmission? | `14_interview_questions.sql` Q24 |

---

## ⚠️ Quality of Care

| # | Business question | File / Query |
|---|---|---|
| 54 | No-show rate per doctor / hospital? | `11_kpi_dashboard.sql` KPI 7 & `09_case_and_dates.sql` Q2 |
| 55 | Which hospital has high revenue + high readmission (quality risk)? | `14_interview_questions.sql` Q30 |
| 56 | Diagnosis vs outcome (recovered / transferred / DAMA)? | `10_pivot_reporting.sql` Q6 |
