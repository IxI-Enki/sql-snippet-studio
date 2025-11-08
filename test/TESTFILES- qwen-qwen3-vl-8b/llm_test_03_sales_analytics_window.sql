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

SELECT category, product_name, revenue,
       ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
FROM FACT_Sales fs
JOIN DIM_Product dp ON fs.product_key = dp.product_key
ORDER BY category, revenue DESC
LIMIT 3;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)

SELECT 
    s.salesperson_name,
    t.month_name,
    f.revenue,
    SUM(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.month_key) AS running_total
FROM FACT_Sales f
JOIN DIM_Salesperson s ON f.salesperson_key = s.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.salesperson_key, t.month_key;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)

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


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)

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


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)

SELECT 
    t.region,
    t.department,
    sp.salesperson_name,
    SUM(f.revenue) AS total_revenue
FROM FACT_Sales f
JOIN DIM_Salesperson sp ON f.salesperson_key = sp.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY ROLLUP (t.region, t.department, sp.salesperson_name);


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)

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
