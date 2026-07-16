-- ============================================================================
-- FILE  : 13_readmission_risk_scoring.sql
-- MODULE: PATIENT READMISSION RISK SCORING  (UNIQUE MODULE)
-- WHY   : A real hospital tries to predict which patients are at HIGH risk
--         of being re-admitted within 30 days — so nurses can call them,
--         schedule follow-ups, and prevent it (which saves money & lives).
--
-- APPROACH:
--   Build a 0-100 RISK SCORE for every patient using additive rules —
--   effectively a mini "rule-based model" implemented in pure SQL:
--
--   +25 if age > 60
--   +20 if has_chronic_condition = 1
--   +15 for every prior admission (max +45)
--   +20 if average length of stay > 7 days
--   +10 if a prior admission was in the ICU
--   +10 if the patient's most recent discharge was < 90 days ago
--
--   Then rank patients by risk score. This is genuine analytics — the same
--   pattern real healthcare risk-scoring models start with.
-- ============================================================================

WITH patient_age AS (
    SELECT patient_id,
           TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age,
           has_chronic_condition
    FROM patients
),
prior_stays AS (
    SELECT
        patient_id,
        COUNT(*)                                    AS admission_count,
        AVG(DATEDIFF(COALESCE(discharge_date,CURDATE()), admit_date)) AS avg_los,
        MAX(CASE WHEN r.room_type = 'ICU' THEN 1 ELSE 0 END)          AS ever_icu,
        DATEDIFF(CURDATE(), MAX(COALESCE(discharge_date, admit_date))) AS days_since_last_visit
    FROM admissions a
    LEFT JOIN rooms r ON r.room_id = a.room_id
    GROUP BY patient_id
),
scored AS (
    SELECT
        p.patient_id,
        pa.age,
        pa.has_chronic_condition,
        COALESCE(ps.admission_count, 0)  AS prior_admits,
        COALESCE(ROUND(ps.avg_los,1), 0) AS avg_los,
        COALESCE(ps.ever_icu, 0)         AS ever_icu,
        COALESCE(ps.days_since_last_visit, 999) AS days_since_last,

        (CASE WHEN pa.age > 60 THEN 25 ELSE 0 END)                     AS pts_age,
        (CASE WHEN pa.has_chronic_condition = 1 THEN 20 ELSE 0 END)    AS pts_chronic,
        LEAST(COALESCE(ps.admission_count,0)*15, 45)                   AS pts_admits,
        (CASE WHEN COALESCE(ps.avg_los,0) > 7 THEN 20 ELSE 0 END)      AS pts_los,
        (CASE WHEN COALESCE(ps.ever_icu,0) = 1 THEN 10 ELSE 0 END)     AS pts_icu,
        (CASE WHEN COALESCE(ps.days_since_last_visit,999) < 90 THEN 10 ELSE 0 END) AS pts_recent
    FROM patients p
    JOIN patient_age  pa ON pa.patient_id = p.patient_id
    LEFT JOIN prior_stays ps ON ps.patient_id = p.patient_id
)
SELECT
    s.patient_id,
    pt.name,
    s.age,
    s.has_chronic_condition,
    s.prior_admits,
    s.avg_los,
    s.ever_icu,
    s.days_since_last,
    (s.pts_age + s.pts_chronic + s.pts_admits + s.pts_los + s.pts_icu + s.pts_recent) AS risk_score,
    CASE
        WHEN (s.pts_age + s.pts_chronic + s.pts_admits + s.pts_los + s.pts_icu + s.pts_recent) >= 70
             THEN 'HIGH'
        WHEN (s.pts_age + s.pts_chronic + s.pts_admits + s.pts_los + s.pts_icu + s.pts_recent) >= 40
             THEN 'MEDIUM'
        ELSE 'LOW'
    END AS risk_tier,
    -- suggested action for the care team
    CASE
        WHEN (s.pts_age + s.pts_chronic + s.pts_admits + s.pts_los + s.pts_icu + s.pts_recent) >= 70
             THEN 'Schedule follow-up call within 7 days; assign case manager'
        WHEN (s.pts_age + s.pts_chronic + s.pts_admits + s.pts_los + s.pts_icu + s.pts_recent) >= 40
             THEN 'Book preventive check-up within 30 days'
        ELSE 'Standard reminder in 90 days'
    END AS suggested_action
FROM scored s
JOIN patients pt ON pt.patient_id = s.patient_id
ORDER BY risk_score DESC, s.age DESC;

-- ----------------------------------------------------------------------------
-- BONUS: RISK TIER SUMMARY  (for dashboard).
-- ----------------------------------------------------------------------------
WITH tiered AS (
    -- (Re-use above logic in a compact form)
    SELECT
        p.patient_id,
        (CASE WHEN TIMESTAMPDIFF(YEAR,p.dob,CURDATE()) > 60 THEN 25 ELSE 0 END)
      + (CASE WHEN p.has_chronic_condition = 1 THEN 20 ELSE 0 END)
      + LEAST(COALESCE(a_stats.cnt,0)*15, 45)
      + (CASE WHEN COALESCE(a_stats.avg_los,0) > 7 THEN 20 ELSE 0 END)
      + (CASE WHEN COALESCE(a_stats.icu_flag,0) = 1 THEN 10 ELSE 0 END)
      + (CASE WHEN COALESCE(a_stats.days_since,999) < 90 THEN 10 ELSE 0 END) AS score
    FROM patients p
    LEFT JOIN (
        SELECT
            a.patient_id,
            COUNT(*) AS cnt,
            AVG(DATEDIFF(COALESCE(a.discharge_date,CURDATE()), a.admit_date)) AS avg_los,
            MAX(CASE WHEN r.room_type='ICU' THEN 1 ELSE 0 END) AS icu_flag,
            DATEDIFF(CURDATE(), MAX(COALESCE(a.discharge_date,a.admit_date))) AS days_since
        FROM admissions a
        LEFT JOIN rooms r ON r.room_id = a.room_id
        GROUP BY a.patient_id
    ) a_stats ON a_stats.patient_id = p.patient_id
)
SELECT
    CASE WHEN score >= 70 THEN 'HIGH'
         WHEN score >= 40 THEN 'MEDIUM'
         ELSE 'LOW' END AS risk_tier,
    COUNT(*) AS patients
FROM tiered
GROUP BY risk_tier
ORDER BY FIELD(risk_tier, 'HIGH','MEDIUM','LOW');
