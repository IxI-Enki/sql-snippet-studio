-- ============================================================================
-- TEST 3: SALES ANALYTICS - WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Verkaufsanalyse
-- Complexity: 🟡 Intermediate
-- Focus: Rankings, ROLLUP für hierarchische Aggregationen
-- Test Coverage: Window Functions (RANK, DENSE_RANK, ROW_NUMBER), ROLLUP, LAG
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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

SELECT salesperson_key, salesperson_name, SUM(revenue) AS total_revenue,
       RANK() OVER (ORDER BY SUM(revenue) DESC) as rank,
       DENSE_RANK() OVER (ORDER BY SUM(revenue) DESC) as dense_rank,
       ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC) as row_number
FROM FACT_Sales fs
JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
GROUP BY salesperson_key, salesperson_name
ORDER BY total_revenue DESC;


-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)
-- ❌ FEHLER: Fehlt ROW_NUMBER() und WHERE <= 3! Query zeigt ALLE Produkte, nicht Top 3!

SELECT category, subcategory, product_name, SUM(revenue) OVER(PARTITION BY category ORDER BY SUM(revenue) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Top_3_Revenue FROM FACT_Sales JOIN DIM_Product ON FACT_Sales.product_key = DIM_Product.product_key GROUP BY category, subcategory, product_name ORDER BY category;

-- KORREKTUR: Top 3 mit ROW_NUMBER
-- WITH RankedProducts AS (
--     SELECT 
--         p.category, 
--         p.product_name, 
--         SUM(fs.revenue) AS total_revenue,
--         ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(fs.revenue) DESC) as rn
--     FROM FACT_Sales fs
--     JOIN DIM_Product p ON fs.product_key = p.product_key
--     GROUP BY p.category, p.product_name
-- )
-- SELECT category, product_name, total_revenue
-- FROM RankedProducts
-- WHERE rn <= 3
-- ORDER BY category, rn;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)
-- ❌ FEHLER: SUM(revenue) OVER muss SUM direkt auf revenue anwenden, nicht auf aggregiertes SUM! Außerdem fehlt time_key in SELECT.

SELECT salesperson_key, salesperson_name, SUM(revenue) OVER (PARTITION BY salesperson_key ORDER BY time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue
FROM FACT_Sales
JOIN DIM_Salesperson ON FACT_Sales.salesperson_key = DIM_Salesperson.salesperson_key
GROUP BY salesperson_key, salesperson_name;

-- KORREKTUR:
-- SELECT 
--     sp.salesperson_key,
--     sp.salesperson_name,
--     t.month,
--     SUM(fs.revenue) OVER (PARTITION BY sp.salesperson_key ORDER BY t.year, t.month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue
-- FROM FACT_Sales fs
-- JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
-- JOIN DIM_Time t ON fs.time_key = t.time_key
-- ORDER BY sp.salesperson_key, t.year, t.month;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)
-- ⚠️ TEILWEISE: LAG ist richtig, ABER berechnet Differenz für JEDE Transaktion, nicht aggregiert pro Monat!

SELECT s.salesperson_name, t.month_name, f.revenue - LAG(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.time_key) AS revenue_change
FROM DIM_Salesperson s
JOIN FACT_Sales f ON s.salesperson_key = f.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key;

-- BESSERE LÖSUNG: Aggregiere erst pro Monat, dann LAG
-- WITH MonthlyRevenue AS (
--     SELECT 
--         sp.salesperson_key,
--         sp.salesperson_name,
--         t.year,
--         t.month,
--         t.month_name,
--         SUM(fs.revenue) AS monthly_revenue
--     FROM FACT_Sales fs
--     JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
--     JOIN DIM_Time t ON fs.time_key = t.time_key
--     GROUP BY sp.salesperson_key, sp.salesperson_name, t.year, t.month, t.month_name
-- )
-- SELECT 
--     salesperson_name,
--     year,
--     month_name,
--     monthly_revenue,
--     monthly_revenue - LAG(monthly_revenue) OVER (PARTITION BY salesperson_key ORDER BY year, month) AS revenue_change
-- FROM MonthlyRevenue
-- ORDER BY salesperson_key, year, month;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)
-- ❌ FEHLER: WHERE vor Window Function (falsch!), ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING (vorwärts statt rückwärts!), GROUP BY mit Window Function problematisch

SELECT salesperson_key, AVG(revenue) OVER (PARTITION BY salesperson_key ORDER BY time_key ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING) AS average_revenue_last_3_months FROM FACT_Sales WHERE time_key >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3 months') GROUP BY salesperson_key;

-- KORREKTUR: 3 Monate RÜCKWÄRTS (2 PRECEDING + CURRENT)
-- WITH MonthlyRevenue AS (
--     SELECT 
--         sp.salesperson_key,
--         sp.salesperson_name,
--         t.year,
--         t.month,
--         SUM(fs.revenue) AS monthly_revenue
--     FROM FACT_Sales fs
--     JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
--     JOIN DIM_Time t ON fs.time_key = t.time_key
--     GROUP BY sp.salesperson_key, sp.salesperson_name, t.year, t.month
-- )
-- SELECT 
--     salesperson_name,
--     year,
--     month,
--     monthly_revenue,
--     AVG(monthly_revenue) OVER (PARTITION BY salesperson_key ORDER BY year, month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_months
-- FROM MonthlyRevenue
-- ORDER BY salesperson_key, year, month;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)
-- ✅ KORREKT (PostgreSQL ROLLUP Syntax)

SELECT region, department, salesperson_name, SUM(revenue) AS total_revenue 
FROM FACT_Sales fs 
JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key 
GROUP BY ROLLUP(region, department, salesperson_name);;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)
-- ❌ FEHLER: Nutzt Window Functions statt GROUP BY ROLLUP! Außerdem MySQL Funktionen (year(), quarter(), month())

SELECT 
    year(time_key) AS Jahr,
    quarter(time_key) AS Quartal,
    month(time_key) AS Monat,
    SUM(revenue) OVER () AS Gesamtumsatz,
    SUM(revenue) OVER (PARTITION BY year(time_key)) AS Umsatz_Jahr,
    SUM(revenue) OVER (PARTITION BY quarter(time_key)) AS Umsatz_Quartal,
    SUM(revenue) OVER (PARTITION BY month(time_key)) AS Umsatz_Monat
FROM 
    FACT_Sales
GROUP BY 
    ROLLUP(year(time_key), quarter(time_key), month(time_key))
ORDER BY 
    Jahr, Quartal, Monat;

-- KORREKTUR: PostgreSQL ROLLUP ohne Window Functions
-- SELECT 
--     t.year,
--     t.quarter,
--     t.month,
--     SUM(fs.revenue) AS total_revenue
-- FROM FACT_Sales fs
-- JOIN DIM_Time t ON fs.time_key = t.time_key
-- GROUP BY ROLLUP(t.year, t.quarter, t.month)
-- ORDER BY t.year, t.quarter, t.month;


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)
-- ❌ FEHLER: WITH ROLLUP ist MySQL Syntax! PostgreSQL nutzt GROUP BY ROLLUP(...). Außerdem fehlt GROUPING() Funktion!

SELECT category, subcategory, SUM(revenue) AS total_revenue FROM FACT_Sales JOIN DIM_Product ON FACT_Sales.product_key = DIM_Product.product_key GROUP BY category, subcategory WITH ROLLUP;

-- KORREKTUR: PostgreSQL ROLLUP mit GROUPING()
-- SELECT 
--     p.category,
--     p.subcategory,
--     SUM(fs.revenue) AS total_revenue,
--     GROUPING(p.category) AS is_category_total,
--     GROUPING(p.subcategory) AS is_subcategory_total
-- FROM FACT_Sales fs
-- JOIN DIM_Product p ON fs.product_key = p.product_key
-- GROUP BY ROLLUP(p.category, p.subcategory)
-- ORDER BY p.category, p.subcategory;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 25.0/100
-- SUCCESS RATE: 2/8 (25.0%)

-- BREAKDOWN:
-- ✅ Korrekt:  2 (Tasks 1, 6)
-- ⚠️ Teilweise: 1 (Task 4 - LAG korrekt, aber nicht aggregiert)
-- ❌ Fehler:   5 (Tasks 2, 3, 5, 7, 8)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Task 1 perfekt (alle 3 Ranking-Funktionen korrekt!)
-- + Task 6 perfekt (PostgreSQL ROLLUP Syntax)
-- + LAG verstanden (Task 4)

-- WEAKNESSES:
-- - Window Functions falsch kombiniert mit GROUP BY
-- - Top N Filtering fehlt (ROW_NUMBER + WHERE rn <= N)
-- - ROWS BETWEEN Richtung falsch (FOLLOWING statt PRECEDING)
-- - MySQL Syntax statt PostgreSQL (WITH ROLLUP, year(), quarter(), month())
-- - GROUPING() Funktion nicht verwendet

-- CRITICAL ERRORS:
-- - Task 2: Zeigt ALLE Produkte, nicht Top 3!
-- - Task 3: Window Function auf falschem Aggregationslevel
-- - Task 5: ROWS BETWEEN vorwärts statt rückwärts
-- - Task 7: Window Functions statt ROLLUP + MySQL Funktionen
-- - Task 8: MySQL Syntax (WITH ROLLUP) + keine GROUPING()

-- RECOMMENDATION:
-- ❌ SCHWACH für Intermediate Level!
-- Das 7B Model hat erhebliche Probleme mit Window Functions und ROLLUP.
-- MySQL/PostgreSQL Syntax wird verwechselt. Nur 25% Success Rate!

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
