-- ============================================================================
-- TEST 3: SALES ANALYTICS - WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Verkaufsanalyse
-- Complexity: 🟡 Intermediate
-- Focus: Rankings, ROLLUP für hierarchische Aggregationen
-- Test Coverage: Window Functions (RANK, DENSE_RANK, ROW_NUMBER), ROLLUP, LAG
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Alle 3 Rankings korrekt mit DESC

SELECT 
    sp.salesperson_name,
    SUM(f.revenue) AS total_revenue,
    RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS rank_revenue,
    DENSE_RANK() OVER (ORDER BY SUM(f.revenue) DESC) AS dense_rank_revenue,
    ROW_NUMBER() OVER (ORDER BY SUM(f.revenue) DESC) AS row_number_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
GROUP BY sp.salesperson_name
ORDER BY total_revenue DESC;


-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)
-- Status: ❌ FALSCH
-- Problem: WHERE rank <= 3 AUSSERHALB des Subqueries! Spalte "rank" existiert nicht im äußeren SELECT!
-- Bewertung: Richtige Idee, aber falsche Verschachtelung

SELECT 
    product_name,
    category,
    revenue,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank
FROM (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.revenue) AS revenue
    FROM FACT_Sales f
    JOIN DIM_Product p ON f.product_key = p.product_key
    GROUP BY p.product_key, p.product_name, p.category
) AS product_revenue
WHERE rank <= 3;

-- ✅ KORRIGIERT: WHERE im äußeren SELECT
-- WITH product_revenue AS (
--     SELECT 
--         p.product_name,
--         p.category,
--         SUM(f.revenue) AS revenue
--     FROM FACT_Sales f
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     GROUP BY p.product_key, p.product_name, p.category
-- )
-- SELECT 
--     product_name,
--     category,
--     revenue,
--     ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank
-- FROM product_revenue
-- QUALIFY ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) <= 3;
--
-- OR (ohne QUALIFY):
-- WITH ranked_products AS (
--     SELECT 
--         p.product_name,
--         p.category,
--         SUM(f.revenue) AS revenue,
--         ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(f.revenue) DESC) AS rank
--     FROM FACT_Sales f
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     GROUP BY p.product_key, p.product_name, p.category
-- )
-- SELECT product_name, category, revenue, rank
-- FROM ranked_products
-- WHERE rank <= 3;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! SUM(SUM(...)) OVER korrekt mit ROWS UNBOUNDED PRECEDING

SELECT 
    sp.salesperson_name,
    t.full_date,
    SUM(f.revenue) AS monthly_revenue,
    SUM(SUM(f.revenue)) OVER (
        PARTITION BY sp.salesperson_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY sp.salesperson_key, sp.salesperson_name, t.full_date
ORDER BY sp.salesperson_name, t.full_date;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! LAG mit PARTITION BY korrekt

SELECT 
    sp.salesperson_name,
    t.full_date,
    f.revenue,
    LAG(f.revenue) OVER (
        PARTITION BY sp.salesperson_key 
        ORDER BY t.full_date
    ) AS previous_month_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY sp.salesperson_key, t.full_date;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROWS BETWEEN 2 PRECEDING AND CURRENT ROW korrekt

SELECT 
    sp.salesperson_key,
    sp.salesperson_name,
    t.full_date,
    AVG(f.revenue) OVER (
        PARTITION BY sp.salesperson_key 
        ORDER BY t.full_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_average_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 months')
ORDER BY sp.salesperson_key, t.full_date;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROLLUP Syntax korrekt

SELECT 
    ds.region,
    ds.department,
    ds.salesperson_name,
    SUM(fs.revenue) AS total_revenue
FROM FACT_Sales fs
JOIN DIM_Salesperson ds ON fs.salesperson_key = ds.salesperson_key
GROUP BY ROLLUP(ds.region, ds.department, ds.salesperson_name)
ORDER BY ds.region, ds.department, ds.salesperson_name;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROLLUP über Zeit-Hierarchie korrekt

SELECT 
    t.year,
    t.quarter,
    t.month_name,
    SUM(f.revenue) AS total_revenue
FROM FACT_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY ROLLUP(t.year, t.quarter, t.month_name)
ORDER BY t.year, t.quarter, t.month_name;


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROLLUP + GROUPING() korrekt verwendet

SELECT 
    p.category,
    p.subcategory,
    SUM(f.revenue) AS total_revenue,
    GROUPING(p.category) + GROUPING(p.subcategory) AS is_grand_total
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY ROLLUP(p.category, p.subcategory)
ORDER BY 
    CASE WHEN GROUPING(p.category) = 1 THEN 1 ELSE 0 END,
    p.category,
    p.subcategory;


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
