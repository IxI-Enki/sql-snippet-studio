-- ============================================================================
-- TEST 3: SALES ANALYTICS - WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Verkaufsanalyse
-- Complexity: 🟡 Intermediate
-- Focus: Rankings, ROLLUP für hierarchische Aggregationen
-- Test Coverage: Window Functions (RANK, DENSE_RANK, ROW_NUMBER), ROLLUP, LAG
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: DENSE_RANK() ORDER BY ist ASCENDING (ASC) statt DESCENDING (DESC)!
-- Bewertung: RANK und ROW_NUMBER korrekt, aber DENSE_RANK falsch sortiert

SELECT s.salesperson_key, s.salesperson_name, SUM(f.revenue) AS total_revenue, RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS revenue_rank, DENSE_RANK() OVER (ORDER BY SUM(f.revenue)) AS dense_revenue_rank, ROW_NUMBER() OVER (ORDER BY SUM(f.revenue) DESC) AS row_number FROM FACT_Sales f JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key GROUP BY s.salesperson_key, s.salesperson_name ORDER BY total_revenue DESC NULLS LAST;

-- ✅ KORRIGIERT: Alle Rankings mit DESC
-- SELECT 
--     s.salesperson_key,
--     s.salesperson_name,
--     SUM(f.revenue) AS total_revenue,
--     RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS revenue_rank,
--     DENSE_RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS dense_revenue_rank,
--     ROW_NUMBER() OVER (ORDER BY SUM(f.revenue) DESC) AS row_number
-- FROM FACT_Sales f
-- JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
-- GROUP BY s.salesperson_key, s.salesperson_name
-- ORDER BY total_revenue DESC;


-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)
-- Status: ❌ FALSCH
-- Problem 1: Berechnet CUMULATIVE REVENUE statt TOP 3 PRO KATEGORIE!
-- Problem 2: LIMIT 3 zeigt nur 3 insgesamt, nicht 3 PRO Kategorie!
-- Problem 3: Sollte ROW_NUMBER() verwenden um Top 3 pro Kategorie zu filtern!
-- Bewertung: Komplett falsche Logik für "Top N pro Gruppe"

SELECT p.product_key, p.product_name, SUM(f.revenue) OVER (PARTITION BY p.category ORDER BY f.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_revenue FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key ORDER BY p.category, cumulative_revenue DESC NULLS LAST LIMIT 3;

-- ✅ KORRIGIERT: Top 3 pro Kategorie mit ROW_NUMBER
-- WITH ranked_products AS (
--     SELECT 
--         p.category,
--         p.product_name,
--         SUM(f.revenue) AS total_revenue,
--         ROW_NUMBER() OVER (
--             PARTITION BY p.category 
--             ORDER BY SUM(f.revenue) DESC
--         ) AS rank_in_category
--     FROM FACT_Sales f
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     GROUP BY p.category, p.product_name
-- )
-- SELECT category, product_name, total_revenue, rank_in_category
-- FROM ranked_products
-- WHERE rank_in_category <= 3
-- ORDER BY category, rank_in_category;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: ORDER BY month_name sortiert ALPHABETISCH statt CHRONOLOGISCH!
-- Bewertung: Window Function Syntax korrekt, aber falsche Sortierung

SELECT s.salesperson_key, SUM(s.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.month_name ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS running_total FROM FACT_Sales s JOIN DIM_Time t ON s.time_key = t.time_key;

-- ✅ KORRIGIERT: Chronologische Sortierung nach Datum
-- SELECT 
--     f.salesperson_key,
--     s.salesperson_name,
--     t.full_date,
--     f.revenue,
--     SUM(f.revenue) OVER (
--         PARTITION BY f.salesperson_key 
--         ORDER BY t.full_date
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS running_total
-- FROM FACT_Sales f
-- JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY s.salesperson_name, t.full_date;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Zeigt JEDEN Tag statt aggregiert nach Monat!
-- Bewertung: LAG korrekt, aber sollte monatlich aggregieren

SELECT s.salesperson_key, t.month_name, s.revenue, lag(s.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.full_date) AS previous_month_revenue FROM FACT_Sales s JOIN DIM_Time t ON s.time_key = t.time_key;

-- ✅ KORRIGIERT: Monatlich aggregiert mit LAG
-- WITH monthly_sales AS (
--     SELECT 
--         f.salesperson_key,
--         s.salesperson_name,
--         t.year,
--         t.month,
--         t.month_name,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY f.salesperson_key, s.salesperson_name, t.year, t.month, t.month_name
-- )
-- SELECT 
--     salesperson_name,
--     year,
--     month_name,
--     monthly_revenue,
--     LAG(monthly_revenue) OVER (
--         PARTITION BY salesperson_key 
--         ORDER BY year, month
--     ) AS previous_month_revenue
-- FROM monthly_sales
-- ORDER BY salesperson_name, year, month;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)
-- Status: ❌ FALSCH
-- Problem: ROWS BETWEEN UNBOUNDED PRECEDING berechnet ALL-TIME Average, nicht 3-Monats Moving Average!
-- Bewertung: Falsche Window Frame Definition - sollte "2 PRECEDING" sein

SELECT s.salesperson_key, AVG(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.full_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS avg_revenue FROM FACT_Sales f JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key JOIN DIM_Time t ON f.time_key = t.time_key WHERE t.full_date >= (CURRENT_DATE - INTERVAL '3 months');

-- ✅ KORRIGIERT: 3-Monats Moving Average
-- WITH monthly_sales AS (
--     SELECT 
--         f.salesperson_key,
--         s.salesperson_name,
--         t.year,
--         t.month,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY f.salesperson_key, s.salesperson_name, t.year, t.month
-- )
-- SELECT 
--     salesperson_name,
--     year,
--     month,
--     monthly_revenue,
--     AVG(monthly_revenue) OVER (
--         PARTITION BY salesperson_key 
--         ORDER BY year, month
--         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--     ) AS three_month_moving_avg
-- FROM monthly_sales
-- ORDER BY salesperson_name, year, month;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)
-- Status: ❌ FALSCH
-- Problem: "WITH ROLLUP" ist MYSQL Syntax! PostgreSQL verwendet "GROUP BY ROLLUP(...)"
-- Bewertung: Falsche Syntax für PostgreSQL

SELECT d.salesperson_name, d.department, d.region, SUM(f.revenue) AS total_revenue FROM FACT_Sales f JOIN DIM_Salesperson d ON f.salesperson_key = d.salesperson_key GROUP BY d.salesperson_name, d.department, d.region WITH ROLLUP;

-- ✅ KORRIGIERT: PostgreSQL ROLLUP Syntax
-- SELECT 
--     d.region,
--     d.department,
--     d.salesperson_name,
--     SUM(f.revenue) AS total_revenue
-- FROM FACT_Sales f
-- JOIN DIM_Salesperson d ON f.salesperson_key = d.salesperson_key
-- GROUP BY ROLLUP(d.region, d.department, d.salesperson_name)
-- ORDER BY d.region NULLS FIRST, d.department NULLS FIRST, d.salesperson_name NULLS FIRST;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)
-- Status: ❌ FALSCH
-- Problem 1: f.full_date existiert nicht (f ist FACT_Sales, nicht DIM_Time)!
-- Problem 2: "WITH ROLLUP" ist MySQL Syntax, PostgreSQL: GROUP BY ROLLUP()
-- Bewertung: Falsche Tabellen-Referenz + falsche Syntax

SELECT DATE_TRUNC('year', f.full_date) AS YEAR, DATE_TRUNC('quarter', f.full_date) AS QUARTER, DATE_TRUNC('month', f.full_date) AS MONTH, SUM(f.revenue) AS total_revenue FROM FACT_Sales f GROUP BY YEAR, QUARTER, MONTH WITH ROLLUP;

-- ✅ KORRIGIERT: Korrekte Tabellen-Referenz + PostgreSQL ROLLUP Syntax
-- SELECT 
--     t.year,
--     t.quarter,
--     t.month,
--     SUM(f.revenue) AS total_revenue
-- FROM FACT_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- GROUP BY ROLLUP(t.year, t.quarter, t.month)
-- ORDER BY t.year NULLS FIRST, t.quarter NULLS FIRST, t.month NULLS FIRST;


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Redundante JOINs (DIM_Product zweimal gejoint als p und d) + fehlt GROUPING() Funktion
-- Bewertung: ROLLUP Syntax korrekt, aber Abfrage ineffizient

SELECT d.category, d.subcategory, SUM(f.revenue) AS total_revenue FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Time t ON f.time_key = t.time_key JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key JOIN DIM_Product d ON p.product_key = d.product_key GROUP BY ROLLUP(d.category, d.subcategory);

-- ✅ KORRIGIERT: Ohne redundante JOINs + mit GROUPING()
-- SELECT 
--     p.category,
--     p.subcategory,
--     SUM(f.revenue) AS total_revenue,
--     GROUPING(p.category) AS is_category_total,
--     GROUPING(p.subcategory) AS is_subcategory_total
-- FROM FACT_Sales f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- GROUP BY ROLLUP(p.category, p.subcategory)
-- ORDER BY p.category NULLS FIRST, p.subcategory NULLS FIRST;


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
