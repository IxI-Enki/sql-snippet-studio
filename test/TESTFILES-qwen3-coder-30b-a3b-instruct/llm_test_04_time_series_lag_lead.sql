-- ============================================================================
-- TEST 4: TIME SERIES ANALYSIS - LAG/LEAD & MOVING AVERAGES
-- ============================================================================
-- Domain: Zeitreihenanalyse (Sales Trends, Stock Analysis)
-- Complexity: 🟡 Intermediate
-- Focus: LAG, LEAD, Running Totals, Moving Averages
-- Test Coverage: Navigation Functions, Aggregate Window Functions, Frames
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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

SELECT 
    p.product_name,
    t.full_date,
    f.daily_revenue AS daily_revenue,
    LAG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date) AS previous_day_revenue
FROM FACT_Daily_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY p.product_key, t.full_date;


-- Aufgabe 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt

SELECT 
    p.product_name,
    t.full_date,
    f.daily_revenue,
    LAG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date) AS previous_day_revenue,
    CASE 
        WHEN LAG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date) IS NOT NULL 
        THEN ((f.daily_revenue - LAG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) / LAG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) * 100
        ELSE NULL 
    END AS revenue_change_percentage
FROM FACT_Daily_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY p.product_key, t.full_date;


-- Aufgabe 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12

SELECT 
    t.full_date,
    t.month_name,
    t.year,
    f.daily_revenue,
    LAG(f.daily_revenue, 12) OVER (ORDER BY t.time_key) AS previous_year_monthly_revenue
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;


-- Aufgabe 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)

SELECT 
    t.full_date,
    f.daily_revenue AS current_revenue,
    LAG(f.daily_revenue) OVER (ORDER BY t.full_date) AS revenue_7_days_ago,
    LEAD(f.daily_revenue) OVER (ORDER BY t.full_date) AS revenue_7_days_ahead
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS
-- ============================================================================

-- Aufgabe 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024

SELECT 
    p.product_name,
    t.full_date,
    SUM(fs.daily_revenue) OVER (
        PARTITION BY p.product_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_revenue
FROM FACT_Daily_Sales fs
JOIN DIM_Product p ON fs.product_key = p.product_key
JOIN DIM_Time t ON fs.time_key = t.time_key
WHERE EXTRACT(YEAR FROM t.full_date) = 2024
ORDER BY p.product_key, t.full_date;


-- Aufgabe 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals

SELECT 
    t.quarter,
    t.month,
    SUM(fs.daily_revenue) OVER (
        PARTITION BY t.quarter 
        ORDER BY t.month 
        ROWS UNBOUNDED PRECEDING
    ) AS running_total_revenue
FROM FACT_Daily_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
ORDER BY t.quarter, t.month;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt

SELECT 
    p.product_name,
    t.full_date,
    AVG(f.daily_revenue) OVER (
        PARTITION BY p.product_key 
        ORDER BY t.full_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_revenue
FROM FACT_Daily_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY p.product_name, t.full_date;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)

SELECT 
    t.full_date,
    AVG(fs.daily_revenue) AS moving_average_30_days
FROM FACT_Daily_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
WHERE t.full_date BETWEEN (
    SELECT MIN(full_date) + INTERVAL '15 days'
    FROM DIM_Time
) AND (
    SELECT MAX(full_date) - INTERVAL '15 days'
    FROM DIM_Time
)
GROUP BY t.full_date
ORDER BY t.full_date;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)

SELECT 
    t.full_date,
    f.daily_revenue,
    AVG(f.daily_revenue) OVER (ORDER BY t.full_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_average_7_days,
    f.daily_revenue - AVG(f.daily_revenue) OVER (ORDER BY t.full_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS deviation_from_average
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;


-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt

SELECT 
    t.full_date,
    f.daily_revenue,
    AVG(f.daily_revenue) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7_days
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE f.daily_revenue > (AVG(f.daily_revenue) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) * 1.2)
ORDER BY t.full_date;

SELECT 
    t.full_date,

SELECT 
    t.full_date,
    AVG(f.daily_orders) OVER (ORDER BY t.full_date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS moving_average_orders
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;
    f.daily_revenue,
    AVG(f.daily_revenue) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7_days

SELECT 
    t.full_date,
    AVG(f.daily_orders) OVER (ORDER BY t.full_date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS moving_average_orders
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE f.daily_revenue > (AVG(f.daily_revenue) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) * 1.2)
ORDER BY t.full_date;


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage

SELECT 
    t.full_date,
    AVG(f.daily_orders) OVER (ORDER BY t.full_date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS moving_average_orders
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY t.full_date;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt

SELECT 
    t.full_date,
    MIN(f.daily_revenue) AS min_revenue,
    MAX(f.daily_revenue) AS max_revenue,
    AVG(f.daily_revenue) AS avg_revenue
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY t.full_date
ORDER BY t.full_date;


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
