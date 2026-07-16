# SQL 1-Page Cheatsheet

A quick reference for every SQL concept used in this project.

---

## 1. Logical Order of Execution (memorize this!)

```
FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
```

Written order is different — the engine reorders it as above.

---

## 2. Basic SELECT

```sql
SELECT col1, col2
FROM   table
WHERE  condition
ORDER  BY col1 DESC
LIMIT  10;
```

---

## 3. Joins

| Join | Returns |
|---|---|
| `INNER JOIN`  | rows that match in both tables |
| `LEFT  JOIN`  | all left + matched right (NULL where no match) |
| `RIGHT JOIN`  | all right + matched left |
| `FULL OUTER`  | all rows from both (MySQL: emulate with LEFT UNION RIGHT) |
| `SELF  JOIN`  | table joined to itself (e.g., staff → manager) |
| `CROSS JOIN`  | Cartesian product (every row × every row) |

```sql
SELECT p.name, a.status
FROM   patients p
LEFT JOIN appointments a ON a.patient_id = p.patient_id;
```

---

## 4. Aggregation

```sql
SELECT city, COUNT(*), AVG(age)
FROM   patients
WHERE  gender = 'F'          -- filters BEFORE aggregate
GROUP  BY city
HAVING COUNT(*) > 5;          -- filters AFTER aggregate
```

Aggregate functions: `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`.
`COUNT(*)` counts all rows, `COUNT(col)` skips NULLs, `COUNT(DISTINCT col)` de-dupes.

---

## 5. Subqueries

```sql
-- Scalar
SELECT name FROM patients WHERE age > (SELECT AVG(age) FROM patients);

-- IN
SELECT name FROM staff WHERE staff_id IN (SELECT doctor_id FROM appointments);

-- EXISTS  (usually faster & NULL-safe vs NOT IN)
SELECT * FROM hospitals h
WHERE EXISTS (SELECT 1 FROM admissions a WHERE a.hospital_id = h.hospital_id);

-- Correlated (inner refs outer)
SELECT s.name,
       (SELECT COUNT(*) FROM appointments a WHERE a.doctor_id = s.staff_id) AS n
FROM staff s;
```

---

## 6. CASE WHEN

```sql
SELECT
  CASE
    WHEN age < 18 THEN 'Child'
    WHEN age < 60 THEN 'Adult'
    ELSE 'Senior'
  END AS bucket
FROM patients;
```

Also great inside `SUM` for conditional aggregation:

```sql
SUM(CASE WHEN status='No-Show' THEN 1 ELSE 0 END) AS no_shows
```

---

## 7. CTE (WITH clause)

```sql
WITH revenue AS (
    SELECT hospital_id, SUM(total_amount) AS rev
    FROM bills GROUP BY hospital_id
)
SELECT * FROM revenue WHERE rev > 100000;
```

**Chained:**

```sql
WITH a AS (...), b AS (SELECT * FROM a ...)
SELECT * FROM b;
```

**Recursive** (staff hierarchy, date series):

```sql
WITH RECURSIVE t AS (
    SELECT ... FROM staff WHERE manager_id IS NULL   -- anchor
    UNION ALL
    SELECT ... FROM staff s JOIN t ON s.manager_id = t.staff_id
)
SELECT * FROM t;
```

---

## 8. Window Functions

Syntax: `func() OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN ...)`

| Function | Use |
|---|---|
| `ROW_NUMBER()` | unique sequence within group |
| `RANK()` | ties share rank, next skips |
| `DENSE_RANK()` | ties share rank, no gap |
| `LAG(col)` / `LEAD(col)` | previous / next row value |
| `SUM(col) OVER (...)` | running total |
| `AVG(col) OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` | 7-row moving avg |
| `NTILE(4)` | bucket rows into 4 equal groups |
| `FIRST_VALUE / LAST_VALUE` | first / last in the window |
| `PERCENT_RANK()` | percentile position |

**Top-N per group** (interview classic):

```sql
WITH r AS (
  SELECT *, RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
  FROM employees
)
SELECT * FROM r WHERE rk <= 3;
```

---

## 9. Date Functions (MySQL)

```sql
DATE_FORMAT(d, '%Y-%m')       -- '2025-06'
DATEDIFF(d1, d2)               -- days between
DATE_ADD(d, INTERVAL 30 DAY)   -- add days
DATE_SUB(d, INTERVAL 1 MONTH)  -- subtract
YEAR(d), MONTH(d), DAY(d)
QUARTER(d)                     -- 1..4
DAYNAME(d)                     -- 'Monday'
TIMESTAMPDIFF(YEAR, dob, CURDATE())  -- age
CURDATE()                      -- today's date
```

---

## 10. Pivot (via CASE, no native PIVOT in MySQL)

```sql
SELECT
  hospital,
  SUM(CASE WHEN MONTH(d)=1 THEN amount ELSE 0 END) AS jan,
  SUM(CASE WHEN MONTH(d)=2 THEN amount ELSE 0 END) AS feb
FROM bills
GROUP BY hospital;
```

---

## 11. NULL Handling

- Comparing to NULL: use `IS NULL` / `IS NOT NULL` (never `= NULL`).
- `COALESCE(x, y, z)` → first non-NULL.
- `NULLIF(a, b)` → NULL if a = b (useful to avoid divide-by-zero).
- `NOT IN (subquery)` breaks if subquery contains NULLs → prefer `NOT EXISTS`.

---

## 12. Speed Tips

- Add indexes on join columns and WHERE filters.
- Prefer `EXISTS` over `IN` for large subqueries.
- Use `EXPLAIN` to see query plan.
- Avoid `SELECT *` in production queries.
- Filter early in the pipeline (`WHERE` before `JOIN` if possible).
