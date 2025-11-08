-- ============================================================================
-- TEST 4: TIME SERIES ANALYSIS - LAG/LEAD & MOVING AVERAGES
-- ============================================================================
-- Domain: Zeitreihenanalyse (Sales Trends, Stock Analysis)
-- Complexity: 🟡 Intermediate
-- Focus: LAG, LEAD, Running Totals, Moving Averages
-- Test Coverage: Navigation Functions, Aggregate Window Functions, Frames
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

-- ============================================================================
-- SCHEMA: Time Series Sales Data
-- ============================================================================

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    launch_date DATE
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    fiscal_year INT,
    fiscal_quarter INT
);

CREATE TABLE FACT_Daily_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    product_key INT REFERENCES DIM_Product(product_key),
    daily_revenue DECIMAL(12,2),
    daily_quantity INT,
    daily_orders INT
);

-- ============================================================================
-- TEST TASKS - LAG & LEAD
-- ============================================================================

-- Aufgabe 1: Zeige den täglichen Umsatz pro Produkt mit dem Umsatz des Vortages (verwende LAG)

SELECT p.product_name, d.daily_revenue, 
       COALESCE(LAG(d.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY d.time_key), 0) AS previous_day_revenue
FROM DIM_Product p
JOIN FACT_Daily_Sales d ON p.product_key = d.product_key;


-- Aufgabe 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt

SELECT p.product_name,
       (f.daily_revenue - lag(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY f.time_key)) / lag(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY f.time_key) * 100 AS revenue_change_percentage
FROM DIM_Product p
JOIN FACT_Daily_Sales f ON p.product_key = f.product_key;


-- Aufgabe 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12

SELECT 
    t.month,
    t.year,
    t.month_name,
    t.daily_revenue AS current_month_sales,
    lag(t.daily_revenue, 12, 0) OVER (PARTITION BY t.product_key ORDER BY t.time_key) AS last_year_same_month_sales
FROM 
    FACT_Daily_Sales t
JOIN 
    DIM_Time d ON t.time_key = d.time_key;


-- Aufgabe 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)

SELECT 
    sale_id,
    time_key,
    product_key,
    daily_revenue,
    LAG(daily_revenue, 1) OVER (PARTITION BY product_key ORDER BY time_key) AS revenue_7_days_ago,
    LEAD(daily_revenue, 1) OVER (PARTITION BY product_key ORDER BY time_key) AS revenue_in_7_days
FROM 
    FACT_Daily_Sales;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS
-- ============================================================================

-- Aufgabe 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024

SELECT 
    p.product_name,
    t.month_name,
    SUM(f.daily_revenue) OVER (
        PARTITION BY p.product_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM 
    DIM_Product p
JOIN 
    FACT_Daily_Sales f ON p.product_key = f.product_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    EXTRACT(YEAR FROM t.full_date) = 2024;


-- Aufgabe 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals

SELECT 
    t.month,
    SUM(f.daily_revenue) OVER (PARTITION BY t.fiscal_quarter ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt

SELECT p.product_name, 
       AVG(f.daily_revenue) OVER (PARTITION BY f.product_key ORDER BY f.time_key ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING) AS seven_day_moving_average
FROM DIM_Product p
JOIN FACT_Daily_Sales f ON p.product_key = f.product_key;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)

SELECT 
    t.time_key,
    AVG(f.daily_revenue) OVER (
        ORDER BY f.time_key
        ROWS BETWEEN 14 PRECEDING AND CURRENT ROW
    ) AS moving_average
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)

SELECT 
    t.time_key,
    f.daily_revenue - AVG(f2.daily_revenue) OVER (
        ORDER BY t.time_key ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
    ) AS seven_day_difference
FROM 
    FACT_Daily_Sales f
JOIN 
    DIM_Time t ON f.time_key = t.time_key;


-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt

SELECT t.full_date FROM DIM_Time t JOIN FACT_Daily_Sales fs ON t.time_key = fs.time_key WHERE fs.daily_revenue > (SELECT AVG(fs1.daily_revenue) OVER (ORDER BY fs1.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) * 1.20 FROM FACT_DAILY_SALES fs1 WHERE fs1.time_key < t.time_key ORDER BY fs1.time_key LIMIT 1);


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage

SELECT AVG(daily_orders) OVER (ORDER BY time_key ROWS BETWEEN CURRENT ROW AND INTERVAL '13' DAY FOLLOWING) AS rolling_average FROM FACT_Daily_Sales;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt

SELECT 
    t.full_date,
    MIN(f.daily_revenue) AS min_daily_revenue,
    MAX(f.daily_revenue) AS max_daily_revenue,
    AVG(f.daily_revenue) OVER (ORDER BY f.time_key ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS avg_daily_revenue_last_30_days
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key
WHERE 
    t.full_date >= DATE_TRUNC('day', CURRENT_DATE - INTERVAL '30 days')
GROUP BY 
    t.full_date;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 70-85 (Window Frames können komplex werden)
-- Parser Challenge: High (ROWS BETWEEN, PRECEDING/FOLLOWING)
-- Model Compatibility: Advanced models preferred
-- Special Focus:
--   - LAG(column, offset) Syntax
--   - LEAD(column, offset) Syntax
--   - ROWS BETWEEN X PRECEDING AND Y FOLLOWING
--   - NULL Handling bei Rändern der Window Frames
-- ============================================================================
