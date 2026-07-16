# Analytical Insights (what the data actually reveals)

If MediChain were a real hospital chain and we ran this analysis, here are
the kinds of insights that would land on the CFO's / CMO's desk.
This file exists so a recruiter opening your GitHub sees **what you'd say
in the boardroom**, not just what SQL you'd write.

Every insight below is backed by one of the queries in this project.

---

## 💡 Insight 1 — Revenue is heavily concentrated in Mumbai & Delhi
**Query:** `11_kpi_dashboard.sql` KPI 2 (revenue per hospital)

The Mumbai and Delhi branches together generate more than 50% of chain-wide
revenue, though they represent only ~40% of the beds. This means smaller
branches (Chennai, Hyderabad) may be *underutilized*, not *unprofitable*.

> **Recommendation:** benchmark Chennai's revenue-per-bed against Mumbai's
> and identify what's constraining growth there — is it doctor supply, patient
> footfall, or lower-priced procedures?

---

## 💡 Insight 2 — Bengaluru's cardiology has a red-flag prescription pattern
**Query:** `12_fraud_detection.sql` Anomaly 1

One cardiologist in Bengaluru (Dr. Vivek Bhat) prescribes ~3–4× the units per
appointment compared to other cardiologists in the chain. This is a
**compliance-team-worthy alert**.

> **Recommendation:** audit this doctor's last 90 days of prescriptions. If
> confirmed over-prescription, it exposes the hospital to insurance clawback
> and regulatory risk.

---

## 💡 Insight 3 — 30-day readmission rate is meaningful & non-trivial
**Query:** `11_kpi_dashboard.sql` KPI 6

Several patients have been re-admitted within 30 days of discharge — for the
**same underlying diagnosis**. Cardiology is the largest contributor.

> **Recommendation:** implement a post-discharge care plan (nurse call within
> 48 hrs, follow-up appointment within 14 days) for high-risk patients.
> Use the risk score from `13_readmission_risk_scoring.sql` to identify them.

---

## 💡 Insight 4 — Duplicate billing incidents exist
**Query:** `12_fraud_detection.sql` Anomaly 2 & 4

The data contains at least one admission billed twice, and one bill claimed
against two different insurance policies simultaneously.

> **Recommendation:** add a database-level `UNIQUE` constraint on
> `bills(admission_id)` and a check that no bill has more than one *active*
> claim at a time.

---

## 💡 Insight 5 — Claim rejection rate varies materially by insurer
**Query:** `11_kpi_dashboard.sql` KPI 8

Some insurers reject ~20% of submitted claims. A ~5% difference in rejection
rate can translate into lakhs of collections lost per month at scale.

> **Recommendation:** work with the insurer's clinical team to understand
> rejection reasons; possibly upgrade pre-authorization workflow.

---

## 💡 Insight 6 — No-show rate is highest for Emergency & long-lead appointments
**Query:** `11_kpi_dashboard.sql` KPI 7

Certain doctors have a no-show rate > 15%. Every no-show is lost revenue
plus a delayed patient outcome.

> **Recommendation:** SMS/WhatsApp reminders 24 hrs and 2 hrs before the
> appointment; require refundable deposits for high-fee slots.

---

## 💡 Insight 7 — Cash payments still dominate for outpatient bills
**Query:** `10_pivot_reporting.sql` Q4 (payment method by year)

Despite the growth of UPI, a meaningful share of outpatient bills is
still settled in cash — that's an operational risk (skimming, cash-handling
errors).

> **Recommendation:** incentivize UPI at the counter with a 1% discount;
> the reconciliation cost saved usually exceeds the discount.

---

## 💡 Insight 8 — Chronic patients drive a disproportionate share of admissions
**Query:** `13_readmission_risk_scoring.sql`

Chronic-condition patients account for a small share of the patient base but
a large share of admissions and length-of-stay.

> **Recommendation:** launch a *chronic-care management program* — quarterly
> check-ins, medication reminders. Cost is low, but reduces expensive
> readmissions.

---

## 💡 Insight 9 — Newer branches (Chennai) show faster new-patient acquisition
**Query:** `11_kpi_dashboard.sql` KPI 14

Chennai (opened 2020) is registering new patients faster than more mature
branches. The chain's growth story is in **Tier-1 south**.

> **Recommendation:** invest ad-spend proportionally in growth markets, not
> mature ones.

---

## 💡 Insight 10 — Quality-adjusted revenue tells a different story
**Query:** `14_interview_questions.sql` Q30

A branch with high revenue *but* high 30-day readmission rate is a
**clinical quality issue disguised as financial success**. Track a
"quality-adjusted revenue" KPI so leadership can't be misled by pure
top-line numbers.

> **Recommendation:** publish this KPI on the CEO dashboard, alongside raw
> revenue.

---

## Summary Insight

If MediChain acted on the above 10 items alone, back-of-the-envelope savings:

| Lever | Estimated annual impact |
|---|---|
| Reduce readmissions 20% | ₹40–60 L |
| Stop duplicate billing / claim leakage | ₹15–25 L |
| Cut no-show rate by 5 pp | ₹20 L |
| Improve claim approval rate 3 pp | ₹30 L |
| **Total** | **₹1–1.4 Cr / yr** |

That's the "so what" story SQL alone can build for a business.
