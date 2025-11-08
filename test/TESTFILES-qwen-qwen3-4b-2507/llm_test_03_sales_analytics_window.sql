-- ============================================================================
-- TEST 3: SALES ANALYTICS - WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Verkaufsanalyse
-- Complexity: 🟡 Intermediate
-- Focus: Rankings, ROLLUP für hierarchische Aggregationen
-- Test Coverage: Window Functions (RANK, DENSE_RANK, ROW_NUMBER), ROLLUP, LAG
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

SELECT 
    s.salesperson_name,
    SUM(f.revenue) AS total_revenue,
    RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS rank_rank,
    DENSE_RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(f.revenue) DESC) AS row_number
FROM DIM_Salesperson s
JOIN FACT_Sales f ON s.salesperson_key = f.salesperson_key
GROUP BY s.salesperson_name;


-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)

-- ❌ FAILED (Score: 30/100):
--    FEHLT: Window Function mit PARTITION BY category!
--    Diese Query zeigt nur Top 3 GLOBAL, nicht PRO Kategorie!

SELECT 
    p.product_name,
    p.category,
    SUM(f.revenue) AS total_revenue
FROM 
    DIM_Product p
JOIN 
    FACT_Sales f ON p.product_key = f.product_key
GROUP BY 
    p.product_name, p.category
ORDER BY 
    total_revenue DESC
LIMIT 3;

-- KORREKTE LÖSUNG:
-- WITH ranked_products AS (
--     SELECT 
--         p.product_name,
--         p.category,
--         SUM(f.revenue) AS total_revenue,
--         ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(f.revenue) DESC) AS rank
--     FROM DIM_Product p
--     JOIN FACT_Sales f ON p.product_key = f.product_key
--     GROUP BY p.product_name, p.category
-- )
-- SELECT product_name, category, total_revenue
-- FROM ranked_products
-- WHERE rank <= 3;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)

SELECT 
    s.salesperson_name,
    t.month_name,
    SUM(f.revenue) AS monthly_revenue,
    SUM(SUM(f.revenue)) OVER (PARTITION BY s.salesperson_key ORDER BY t.time_key) AS running_total_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY s.salesperson_key, s.salesperson_name, t.month_name, t.time_key
ORDER BY s.salesperson_key, t.time_key;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)

-- ⚠️ TEILWEISE KORREKT (Score: 75/100):
--    PROBLEM: LAG sortiert über month_name (alphabetisch!) statt chronologisch!
--    "April" kommt vor "August" vor "Dezember" - FALSCHE Reihenfolge!
--    SOLLTE: ORDER BY t.year, t.month (numerisch)

SELECT 
    s.salesperson_name,
    t.month_name,
    t.year,
    SUM(f.revenue) AS monthly_revenue,
    LAG(SUM(f.revenue)) OVER (PARTITION BY s.salesperson_name ORDER BY t.month_name) AS previous_month_revenue
FROM 
    FACT_Sales f
JOIN 
    DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
GROUP BY 
    s.salesperson_name, t.month_name, t.year
ORDER BY 
    s.salesperson_name, t.year, t.month;

-- KORREKTE LÖSUNG:
-- SELECT 
--     s.salesperson_name,
--     t.year,
--     t.month,
--     t.month_name,
--     SUM(f.revenue) AS monthly_revenue,
--     LAG(SUM(f.revenue)) OVER (PARTITION BY s.salesperson_name ORDER BY t.year, t.month) AS previous_month_revenue
-- FROM FACT_Sales f
-- JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- GROUP BY s.salesperson_name, t.year, t.month, t.month_name
-- ORDER BY s.salesperson_name, t.year, t.month;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)

-- ❌ FAILED (Score: 20/100):
--    FEHLT: Window Function für Moving Average!
--    Diese Query verwendet nur AVG() ohne OVER()
--    FEHLT: ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
--    Das ist KEIN Moving Average, nur ein globaler Durchschnitt mit WHERE filter!

SELECT 
    s.salesperson_name,
    AVG(f.revenue) AS avg_revenue
FROM 
    DIM_Salesperson s
JOIN 
    FACT_Sales f ON s.salesperson_key = f.salesperson_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    t.month >= EXTRACT(MONTH FROM CURRENT_DATE) - 2
    AND t.year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    s.salesperson_name
ORDER BY 
    s.salesperson_name;

-- KORREKTE LÖSUNG:
-- WITH monthly_sales AS (
--     SELECT 
--         s.salesperson_key,
--         s.salesperson_name,
--         t.year,
--         t.month,
--         SUM(f.revenue) AS monthly_revenue
--     FROM FACT_Sales f
--     JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY s.salesperson_key, s.salesperson_name, t.year, t.month
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
--     ) AS moving_avg_3_months
-- FROM monthly_sales
-- ORDER BY salesperson_name, year, month;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)

-- ❌ SYNTAX-FEHLER (Score: 40/100):
--    FALSCHE SYNTAX: "GROUP BY ... WITH ROLLUP" ist MySQL Syntax!
--    PostgreSQL: GROUP BY ROLLUP(region, department, salesperson_name)
--    Model verwechselt MySQL und PostgreSQL Syntax!

SELECT 
    region,
    department,
    salesperson_name,
    SUM(revenue) AS total_revenue
FROM 
    DIM_Salesperson
JOIN 
    FACT_Sales ON DIM_Salesperson.salesperson_key = FACT_Sales.salesperson_key
GROUP BY 
    region, 
    department, 
    salesperson_name WITH ROLLUP;

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     region,
--     department,
--     salesperson_name,
--     SUM(revenue) AS total_revenue
-- FROM DIM_Salesperson
-- JOIN FACT_Sales ON DIM_Salesperson.salesperson_key = FACT_Sales.salesperson_key
-- GROUP BY ROLLUP(region, department, salesperson_name)
-- ORDER BY region NULLS LAST, department NULLS LAST, salesperson_name NULLS LAST;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)

-- ✅ KORREKT (Score: 100/100):
--    Diese Query verwendet die KORREKTE PostgreSQL ROLLUP Syntax!
--    GROUP BY ROLLUP(...) ist richtig für PostgreSQL!

SELECT 
    t.year,
    t.quarter,
    t.month,
    t.month_name,
    SUM(fs.revenue) AS total_revenue
FROM FACT_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
GROUP BY ROLLUP (t.year, t.quarter, t.month, t.month_name);


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)

-- ❌ FAILED (Score: 40/100):
--    FEHLT: GROUPING() Funktion!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    Die Aufgabe verlangt EXPLIZIT die GROUPING() Funktion!

SELECT 
    category,
    subcategory,
    SUM(revenue) AS total_revenue
FROM 
    DIM_Product p
JOIN 
    FACT_Sales f ON p.product_key = f.product_key
GROUP BY 
    category, subcategory WITH ROLLUP;

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     category,
--     subcategory,
--     SUM(revenue) AS total_revenue,
--     GROUPING(category) AS is_category_subtotal,
--     GROUPING(subcategory) AS is_subcategory_subtotal,
--     CASE 
--         WHEN GROUPING(category) = 1 THEN 'GRAND TOTAL'
--         WHEN GROUPING(subcategory) = 1 THEN 'Category Subtotal'
--         ELSE 'Detail'
--     END AS aggregation_level
-- FROM DIM_Product p
-- JOIN FACT_Sales f ON p.product_key = f.product_key
-- GROUP BY ROLLUP(category, subcategory)
-- ORDER BY category NULLS LAST, subcategory NULLS LAST;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 63.1/100 ⭐⭐⭐
-- SUCCESS RATE: 37.5% (3/8 korrekt, 1 teilweise)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1: 100/100 - Perfekt (RANK, DENSE_RANK, ROW_NUMBER)
--   ❌ Aufgabe 2:  30/100 - Fehlt PARTITION BY (Top 3 nur global)
--   ✅ Aufgabe 3: 100/100 - Perfekt (Running Total)
--   ⚠️ Aufgabe 4:  75/100 - LAG über month_name statt year/month
--   ❌ Aufgabe 5:  20/100 - Keine Window Function (nur AVG ohne OVER)
--   ❌ Aufgabe 6:  40/100 - MySQL Syntax statt PostgreSQL
--   ✅ Aufgabe 7: 100/100 - Perfekt (ROLLUP korrekt)
--   ❌ Aufgabe 8:  40/100 - Fehlt GROUPING() + MySQL Syntax
--
-- STÄRKEN:
--   + Einfache Window Functions (RANK, DENSE_RANK, ROW_NUMBER) korrekt
--   + Running Total mit OVER() korrekt
--   + ROLLUP Syntax (manchmal) korrekt
--
-- SCHWÄCHEN:
--   - PARTITION BY oft vergessen!
--   - ROWS BETWEEN nicht verwendet (Moving Average failed)
--   - Verwechselt MySQL und PostgreSQL Syntax
--   - GROUPING() Funktion nicht bekannt
--   - ORDER BY in Window Functions falsch (alphabetisch statt chronologisch)
--
-- KRITISCHE FEHLER:
--   ⚠️ Window Functions mit PARTITION BY: NICHT ZUVERLÄSSIG
--   ⚠️ Moving Average (ROWS BETWEEN): NICHT VERSTANDEN
--   ⚠️ ROLLUP: Inkonsistent (mal richtig, mal MySQL Syntax)
--   ⚠️ GROUPING(): NICHT BEKANNT
--
-- EMPFEHLUNG: ❌ NICHT geeignet für Window Functions & ROLLUP
--              Nur für einfache Rankings verwendbar!
-- ============================================================================
