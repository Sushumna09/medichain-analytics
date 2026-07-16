-- ============================================================================
-- FILE  : 07_ctes.sql
-- TOPIC : WITH clause (CTEs), chained CTEs, RECURSIVE CTEs
-- LEVEL : Intermediate → Advanced
-- WHY   : CTEs make complex queries readable. Recursive CTEs are needed for
--         hierarchy traversal (staff manager tree) — a common interview Q.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Q1. Simple CTE — top revenue-generating hospitals.
--      Same result as subquery-in-FROM but cleaner to read.
-- ----------------------------------------------------------------------------
WITH hospital_revenue AS (
    SELECT h.hospital_id, h.name AS hospital, SUM(b.total_amount) AS revenue
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status = 'Paid'
    GROUP BY h.hospital_id, h.name
)
SELECT * FROM hospital_revenue
ORDER BY revenue DESC;

-- ----------------------------------------------------------------------------
-- Q2. Chained CTEs — patient revenue, then their revenue class (Gold/Silver/Bronze).
-- ----------------------------------------------------------------------------
WITH patient_spend AS (
    SELECT p.patient_id, p.name, SUM(b.total_amount) AS total_spend
    FROM bills b
    JOIN patients p ON p.patient_id = b.patient_id
    WHERE b.status = 'Paid'
    GROUP BY p.patient_id, p.name
),
classified AS (
    SELECT
        *,
        CASE
            WHEN total_spend >= 200000 THEN 'Gold'
            WHEN total_spend >= 100000 THEN 'Silver'
            ELSE 'Bronze'
        END AS spend_tier
    FROM patient_spend
)
SELECT spend_tier, COUNT(*) AS patients, SUM(total_spend) AS total_revenue
FROM classified
GROUP BY spend_tier
ORDER BY total_revenue DESC;

-- ----------------------------------------------------------------------------
-- Q3. CTE + JOIN — combine hospital revenue with hospital metadata.
-- ----------------------------------------------------------------------------
WITH hospital_revenue AS (
    SELECT h.hospital_id, SUM(b.total_amount) AS revenue
    FROM bills b
    LEFT JOIN admissions   a  ON a.admission_id   = b.admission_id
    LEFT JOIN appointments ap ON ap.appointment_id = b.appointment_id
    JOIN hospitals h ON h.hospital_id = COALESCE(a.hospital_id, ap.hospital_id)
    WHERE b.status = 'Paid'
    GROUP BY h.hospital_id
)
SELECT
    h.name, h.city, h.total_beds,
    r.revenue,
    ROUND(r.revenue / h.total_beds, 0) AS revenue_per_bed
FROM hospitals h
JOIN hospital_revenue r ON r.hospital_id = h.hospital_id
ORDER BY revenue_per_bed DESC;

-- ----------------------------------------------------------------------------
-- Q4. RECURSIVE CTE — the full staff-manager tree (Org Chart)
--      Start from CMOs (manager_id IS NULL) and walk downward.
-- ----------------------------------------------------------------------------
WITH RECURSIVE org_tree AS (
    -- Anchor: top of hierarchy
    SELECT
        staff_id,
        name,
        role,
        manager_id,
        0            AS level,
        CAST(name AS CHAR(500)) AS hierarchy_path
    FROM staff
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: everyone else, joined to their boss
    SELECT
        s.staff_id,
        s.name,
        s.role,
        s.manager_id,
        t.level + 1,
        CONCAT(t.hierarchy_path, ' > ', s.name)
    FROM staff s
    JOIN org_tree t ON t.staff_id = s.manager_id
)
SELECT staff_id, level, role, name, hierarchy_path
FROM org_tree
ORDER BY hierarchy_path;

-- ----------------------------------------------------------------------------
-- Q5. RECURSIVE CTE — generate a date series (last 12 months) and left-join
--     admissions to it → months with zero admissions still appear.
-- ----------------------------------------------------------------------------
WITH RECURSIVE month_series AS (
    SELECT DATE_FORMAT(CURDATE(), '%Y-%m-01') AS month_start
    UNION ALL
    SELECT DATE_SUB(month_start, INTERVAL 1 MONTH)
    FROM month_series
    WHERE month_start > DATE_SUB(CURDATE(), INTERVAL 11 MONTH)
)
SELECT
    DATE_FORMAT(m.month_start, '%Y-%m') AS month,
    COUNT(a.admission_id) AS admissions
FROM month_series m
LEFT JOIN admissions a
     ON DATE_FORMAT(a.admit_date, '%Y-%m-01') = m.month_start
GROUP BY m.month_start
ORDER BY m.month_start;

-- ----------------------------------------------------------------------------
-- Q6. CTE for readability — top-3 diagnoses per hospital.
--      (Uses window functions too; will feel natural after file 08.)
-- ----------------------------------------------------------------------------
WITH diag_counts AS (
    SELECT h.name AS hospital, a.diagnosis, COUNT(*) AS cnt
    FROM admissions a
    JOIN hospitals h ON h.hospital_id = a.hospital_id
    GROUP BY h.name, a.diagnosis
),
ranked AS (
    SELECT hospital, diagnosis, cnt,
           ROW_NUMBER() OVER (PARTITION BY hospital ORDER BY cnt DESC) AS rnk
    FROM diag_counts
)
SELECT hospital, diagnosis, cnt
FROM ranked
WHERE rnk <= 3
ORDER BY hospital, rnk;
