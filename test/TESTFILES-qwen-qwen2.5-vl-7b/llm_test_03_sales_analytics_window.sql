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

SELECT salesperson_key, salesperson_name, SUM(revenue) AS total_sales, 
RANK() OVER (ORDER BY SUM(revenue) DESC), 
DENSE_RANK() OVER (ORDER BY SUM(revenue) DESC), 
ROW_NUMBER() OVER (ORDER BY SUM(revenue) DESC)
FROM FACT_Sales fs
JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key
GROUP BY salesperson_key, salesperson_name
ORDER BY total_sales DESC;


-- Aufgabe 2: Zeige die Top 3 Produkte pro Kategorie sortiert nach Umsatz (verwende Window Functions mit PARTITION BY)

SELECT category, subcategory, product_name, SUM(revenue) OVER(PARTITION BY category ORDER BY SUM(revenue) DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Top_3_Revenue FROM FACT_Sales JOIN DIM_Product ON FACT_Sales.product_key = DIM_Product.product_key GROUP BY category, subcategory, product_name ORDER BY Top_3_Revenue ASC LIMIT 3;


-- Aufgabe 3: Berechne den Umsatz pro Verkäufer mit laufender Summe über die Monate (Running Total mit Window Functions)

SELECT s.salesperson_name, SUM(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue
FROM DIM_Salesperson s
JOIN FACT_Sales f ON s.salesperson_key = f.salesperson_key
GROUP BY s.salesperson_name, f.time_key;


-- Aufgabe 4: Vergleiche den Umsatz jedes Monats mit dem Vormonat für jeden Verkäufer (verwende LAG)

SELECT s.salesperson_name, t.month_name, f.revenue AS current_month_revenue, 
       LAG(f.revenue) OVER (PARTITION BY s.salesperson_key ORDER BY t.time_key) AS previous_month_revenue
FROM DIM_Salesperson s
JOIN FACT_Sales f ON s.salesperson_key = f.salesperson_key
JOIN DIM_Time t ON f.time_key = t.time_key;


-- Aufgabe 5: Berechne den durchschnittlichen Umsatz der letzten 3 Monate für jeden Verkäufer (Moving Average mit Window Functions)

SELECT salesperson_key, AVG(revenue) OVER (PARTITION BY salesperson_key ORDER BY time_key ROWS BETWEEN CURRENT ROW AND 3 FOLLOWING) AS average_revenue_last_3_months
FROM FACT_Sales
JOIN DIM_Time ON FACT_Sales.time_key = DIM_Time.time_key
WHERE time_key >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3 months')
GROUP BY salesperson_key, time_key;


-- ============================================================================
-- TEST TASKS - ROLLUP
-- ============================================================================

-- Aufgabe 6: Berechne den Gesamtumsatz mit hierarchischen Subtotals nach Region, Department und Verkäufer (verwende ROLLUP)

SELECT region, department, salesperson_name, SUM(revenue) AS total_revenue 
FROM FACT_Sales fs 
JOIN DIM_Salesperson sp ON fs.salesperson_key = sp.salesperson_key 
GROUP BY ROLLUP(region, department, salesperson_name);;


-- Aufgabe 7: Berechne den Umsatz pro Jahr, Quartal und Monat mit Subtotals auf jeder Ebene (verwende ROLLUP)

SELECT 
    year(time_key) AS Jahr,
    quarter(time_key) AS Quartal,
    month(time_key) AS Monat,
    SUM(revenue) AS Umsatz
FROM 
    FACT_Sales
GROUP BY 
    ROLLUP(year(time_key), quarter(time_key), month(time_key));


-- Aufgabe 8: Zeige den Umsatz pro Produktkategorie und Subkategorie mit Grand Total (verwende ROLLUP und GROUPING Funktion)

SELECT category, subcategory, SUM(revenue) AS total_revenue FROM FACT_Sales JOIN DIM_Product ON FACT_Sales.product_key = DIM_Product.product_key GROUP BY category, subcategory WITH ROLLUP;


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
