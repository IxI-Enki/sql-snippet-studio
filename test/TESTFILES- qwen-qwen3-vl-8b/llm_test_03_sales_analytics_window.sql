-- ============================================================================
-- TEST 3: SALES ANALYTICS - WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Verkaufsanalyse
-- Complexity: 🟡 Intermediate
-- Focus: Rankings, ROLLUP für hierarchische Aggregationen
-- Test Coverage: Window Functions (RANK, DENSE_RANK, ROW_NUMBER), ROLLUP, LAG
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

-- ============================================================================
-- SCHEMA: Sales Performance Data Warehouse
-- ============================================================================

CREATE TABLE DIM_Salesperson (
    salesperson_key SERIAL PRIMARY KEY,
    salesperson_name VARCHAR(100) NOT NULL,
    employee_id VARCHAR(20) UNIQUE,
    department VARCHAR(50),
    region VARCHAR(50),
    hire_date DATE
);

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20)
);

CREATE TABLE FACT_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    salesperson_key INT REFERENCES DIM_Salesperson(salesperson_key),
    product_key INT REFERENCES DIM_Product(product_key),
    quantity INT,
    revenue DECIMAL(12,2),
    commission DECIMAL(10,2)
);

-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS
-- ============================================================================

-- Aufgabe 1: Ranking der Verkäufer nach Gesamtumsatz (verwende RANK, DENSE_RANK und ROW_NUMBER)
-- ✅ KORREKT


SELECT 
    sp.salesperson_name,
    SUM(fs.revenue) AS total_revenue,
    RANK() OVER (ORDER BY SUM(fs.revenue) DESC) AS rank_by_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(fs.revenue) DESC) AS dense_rank_by_revenue,
    ROW_NUMBER() OVER (ORDER BY SUM(fs.revenue) DESC) AS row_number_by_revenue
FROM FACT_Sales fs
JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
GROUP BY sp.salesperson_key, sp.salesperson_name
ORDER BY total_revenue DESC;

-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)
-- ❌ FEHLER: Fehlt CTE/Subquery für WHERE rn <= 3! 
-- Außerdem: revenue ohne SUM - zeigt jeden Sale einzeln statt aggregiert!
-- LIMIT 3 ist falsch - zeigt nur insgesamt 3 Rows, nicht 3 pro Kategorie!

SELECT category, product_name, revenue,
       ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
FROM FACT_Sales fs
JOIN DIM_Product dp ON fs.product_key = dp.product_key
ORDER BY category, revenue DESC
LIMIT 3;

-- KORREKTUR:
-- WITH RankedProducts AS (
--     SELECT 
--         dp.category, 
--         dp.product_name, 
--         SUM(fs.revenue) AS total_revenue,
--         ROW_NUMBER() OVER (PARTITION BY dp.category ORDER BY SUM(fs.revenue) DESC) AS rn
--     FROM FACT_Sales fs
--     JOIN DIM_Product dp ON fs.product_key = dp.product_key
--     GROUP BY dp.category, dp.product_name
-- )
-- SELECT category, product_name, total_revenue, rn
-- FROM RankedProducts
-- WHERE rn <= 3
-- ORDER BY category, rn;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)
-- ❌ FEHLER: t.month_key existiert nicht im Schema! Nur t.month!
-- Außerdem: f.revenue ohne SUM aggregiert nicht pro Monat!

SELECT 
    s.salesperson_name,
    t.month_name,
    f.revenue,
    SUM(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.month_key) AS running_total
FROM FACT_Sales f
JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.salesperson_key, t.month_key;

-- KORREKTUR:
-- WITH MonthlySales AS (
--     SELECT 
--         s.salesperson_key,
--         s.salesperson_name,
--         t.month,
--         t.month_name,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY s.salesperson_key, s.salesperson_name, t.month, t.month_name
-- )
-- SELECT 
--     salesperson_name,
--     month_name,
--     monthly_revenue,
--     SUM(monthly_revenue) OVER (PARTITION BY salesperson_key ORDER BY month) AS running_total
-- FROM MonthlySales
-- ORDER BY salesperson_key, month;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)
-- ⚠️ TEILWEISE: f.revenue ohne SUM - zeigt jeden einzelnen Sale statt Monatsumsatz!

SELECT 
    t.month_name,
    s.salesperson_name,
    f.revenue,
    LAG(f.revenue, 1) OVER (PARTITION BY s.salesperson_key ORDER BY t.time_key) AS prev_month_revenue
FROM 
    FACT_Sales f
JOIN 
    DIM_Time t ON f.time_key = t.time_key
JOIN 
    DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
ORDER BY 
    s.salesperson_key, t.month_name;

-- BESSERE LÖSUNG:
-- WITH MonthlySales AS (
--     SELECT 
--         s.salesperson_key,
--         s.salesperson_name,
--         t.month,
--         t.month_name,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     GROUP BY s.salesperson_key, s.salesperson_name, t.month, t.month_name
-- )
-- SELECT 
--     month_name,
--     salesperson_name,
--     monthly_revenue,
--     LAG(monthly_revenue, 1) OVER (PARTITION BY salesperson_key ORDER BY month) AS prev_month_revenue
-- FROM MonthlySales
-- ORDER BY salesperson_key, month;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)
-- ❌ FEHLER: WHERE t.month >= EXTRACT(MONTH FROM CURRENT_DATE) - 2 ist falsch!
-- Das filtert nur Monate >= (aktueller_monat - 2), nicht "letzte 3 Monate"!

SELECT 
    s.salesperson_name,
    t.month_name,
    AVG(f.revenue) OVER (
        PARTITION BY s.salesperson_key 
        ORDER BY t.time_key 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.month >= EXTRACT(MONTH FROM CURRENT_DATE) - 2
ORDER BY s.salesperson_name, t.month_name;

-- KORREKTUR (entferne WHERE oder korrigiere zu CURRENT_DATE - INTERVAL '3 months'):
-- WITH MonthlySales AS (
--     SELECT 
--         s.salesperson_key,
--         s.salesperson_name,
--         t.month,
--         t.month_name,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY s.salesperson_key, s.salesperson_name, t.month, t.month_name
-- )
-- SELECT 
--     salesperson_name,
--     month_name,
--     monthly_revenue,
--     AVG(monthly_revenue) OVER (
--         PARTITION BY salesperson_key 
--         ORDER BY month 
--         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--     ) AS moving_avg_revenue
-- FROM MonthlySales
-- ORDER BY salesperson_name, month;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)
-- ❌ FEHLER: t.region und t.department existieren NICHT in DIM_Time!
-- Sollte sp.region und sp.department sein (aus DIM_Salesperson)!

SELECT 
    t.region,
    t.department,
    sp.salesperson_name,
    SUM(f.revenue) AS total_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY ROLLUP (t.region, t.department, sp.salesperson_name);

-- KORREKTUR:
-- SELECT 
--     sp.region,
--     sp.department,
--     sp.salesperson_name,
--     SUM(f.revenue) AS total_revenue
-- FROM FACT_Sales f
-- JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
-- GROUP BY ROLLUP (sp.region, sp.department, sp.salesperson_name)
-- ORDER BY sp.region, sp.department, sp.salesperson_name;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)
-- ✅ KORREKT

SELECT 
    t.year,
    t.quarter,
    t.month,
    SUM(f.revenue) AS total_revenue
FROM 
    FACT_Sales f
JOIN 
    DIM_Time t ON f.time_key = t.time_key
GROUP BY 
    ROLLUP (t.year, t.quarter, t.month);


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)
-- ❌ FEHLER: "WITH ROLLUP" nach "GROUP BY ROLLUP(...)" ist doppelt und falsch!
-- Entweder "GROUP BY ... WITH ROLLUP" (MySQL) ODER "GROUP BY ROLLUP(...)" (PostgreSQL), nicht beides!

SELECT 
    p.category, 
    p.subcategory, 
    SUM(fs.revenue) AS total_revenue
FROM 
    FACT_Sales fs
JOIN 
    DIM_Product p ON fs.product_key = p.product_key
GROUP BY 
    ROLLUP(p.category, p.subcategory)
WITH ROLLUP;

-- KORREKTUR (PostgreSQL):
-- SELECT 
--     p.category, 
--     p.subcategory, 
--     SUM(fs.revenue) AS total_revenue,
--     GROUPING(p.category) AS is_category_total,
--     GROUPING(p.subcategory) AS is_subcategory_total
-- FROM 
--     FACT_Sales fs
-- JOIN 
--     DIM_Product p ON fs.product_key = p.product_key
-- GROUP BY 
--     ROLLUP(p.category, p.subcategory)
-- ORDER BY 
--     p.category, p.subcategory;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 31.3/100
-- SUCCESS RATE: 2/8 (25.0%)

-- BREAKDOWN:
-- ✅ Korrekt:  2 (Tasks 1, 7)
-- ⚠️ Teilweise: 1 (Task 4)
-- ❌ Fehler:   5 (Tasks 2, 3, 5, 6, 8)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + RANK, DENSE_RANK, ROW_NUMBER korrekt (Task 1)
-- + ROLLUP mit Zeit-Hierarchie korrekt (Task 7)

-- WEAKNESSES:
-- - Window Functions mit Aggregation fehlen (Tasks 2, 3, 4, 5)
-- - Falsche Column-Referenzen (t.month_key, t.region, t.department)
-- - ROLLUP Syntax gemischt (PostgreSQL + MySQL)
-- - Fehlende CTEs für komplexe Window Queries
-- - WHERE Logik falsch (Task 5)

-- CRITICAL ERRORS:
-- - Task 2: LIMIT 3 zeigt nur 3 Rows total, nicht 3 pro Kategorie! Fehlt CTE!
-- - Task 3: t.month_key existiert nicht im Schema!
-- - Task 5: WHERE t.month >= EXTRACT(MONTH FROM CURRENT_DATE) - 2 ist falsche Logik!
-- - Task 6: t.region und t.department existieren nicht!
-- - Task 8: Doppelte ROLLUP Syntax (beides gleichzeitig!)

-- RECOMMENDATION:
-- 🔴 SCHWACH für Window Functions!
-- Score ist deutlich schlechter als qwen2.5-vl-7b (50.0% → 25.0%)
-- Window Functions + Aggregation + ROLLUP sind Schwachpunkte

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 75-90 (Window Functions Syntax kann tricky sein)
-- Parser Challenge: Medium-High (Window Frame Clauses, PARTITION BY)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: 
--   - Korrekte PARTITION BY und ORDER BY Syntax
--   - ROWS BETWEEN für Window Frames
--   - ROLLUP Syntax (nicht CUBE!)
--   - GROUPING() Funktion
-- ============================================================================
