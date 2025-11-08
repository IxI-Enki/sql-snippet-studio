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

SELECT 
    product_name,
    full_date,
    daily_revenue,
    LAG(daily_revenue) OVER (PARTITION BY product_key ORDER BY full_date) AS previous_day_revenue
FROM 
    FACT_Daily_Sales fs
JOIN 
    DIM_Product dp ON fs.product_key = dp.product_key
JOIN 
    DIM_Time dt ON fs.time_key = dt.time_key;


-- Aufgabe 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt

SELECT 
    p.product_name,
    t.full_date,
    (fs.daily_revenue - LAG(fs.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) * 100.0 / NULLIF(LAG(fs.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date), 0) AS revenue_change_percentage
FROM DIM_Product p
JOIN FACT_Daily_Sales fs ON p.product_key = fs.product_key
JOIN DIM_Time t ON fs.time_key = t.time_key
ORDER BY p.product_key, t.full_date;


-- Aufgabe 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12

SELECT 
    t.month_name,
    SUM(fs.daily_revenue) AS current_month_revenue,
    LAG(SUM(fs.daily_revenue), 12) OVER (ORDER BY t.month_name) AS previous_year_same_month_revenue
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales fs ON t.time_key = fs.time_key
GROUP BY 
    t.month_name
ORDER BY 
    t.month_name;


-- Aufgabe 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)

SELECT 
    daily_revenue,
    LAG(daily_revenue, 7) OVER (ORDER BY time_key) AS revenue_7_days_ago,
    LEAD(daily_revenue, 7) OVER (ORDER BY time_key) AS revenue_7_days_ahead
FROM FACT_Daily_Sales;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS
-- ============================================================================

-- Aufgabe 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024

SELECT 
    p.product_name,
    t.full_date,
    SUM(fs.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date ROWS UNBOUNDED PRECEDING) AS running_total_revenue
FROM FACT_Daily_Sales fs
JOIN DIM_Product p ON fs.product_key = p.product_key
JOIN DIM_Time t ON fs.time_key = t.time_key
WHERE t.year = 2024
ORDER BY p.product_key, t.full_date;


-- Aufgabe 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals

SELECT 
    t.month_name,
    t.quarter,
    SUM(f.daily_revenue) AS monthly_revenue,
    SUM(SUM(f.daily_revenue)) OVER (PARTITION BY t.quarter ORDER BY t.month_name) AS running_total_revenue
FROM DIM_Time t
JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
GROUP BY t.month_name, t.quarter
ORDER BY t.quarter, t.month_name;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt

SELECT 
    p.product_name,
    AVG(s.daily_revenue) AS seven_day_moving_average_revenue
FROM 
    DIM_Product p
JOIN 
    FACT_Daily_Sales s ON p.product_key = s.product_key
GROUP BY 
    p.product_name
ORDER BY 
    p.product_name;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)

SELECT 
    t.full_date,
    AVG(s.daily_revenue) AS moving_average_revenue
FROM 
    DIM_Time t
    JOIN FACT_Daily_Sales s ON t.time_key = s.time_key
WHERE 
    t.full_date BETWEEN DATEADD(day, -15, t.full_date) AND DATEADD(day, 15, t.full_date)
GROUP BY 
    t.full_date
ORDER BY 
    t.full_date;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)

SELECT 
    t.time_key,
    f.daily_revenue - AVG(f2.daily_revenue) OVER (
        ORDER BY t.time_key ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
    ) AS revenue_difference
FROM 
    FACT_Daily_Sales f
JOIN 
    DIM_Time t ON f.time_key = t.time_key;


-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt

SELECT 
    t.full_date,
    SUM(f.daily_revenue) AS total_revenue,
    AVG(SUM(f.daily_revenue)) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS seven_day_moving_average
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key
GROUP BY 
    t.full_date
HAVING 
    SUM(f.daily_revenue) > 1.2 * AVG(SUM(f.daily_revenue)) OVER (ORDER BY t.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW);


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage

SELECT 
    t.full_date,
    AVG(f.daily_orders) AS moving_average_orders
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key
WHERE 
    t.full_date >= CURRENT_DATE - INTERVAL '14 days'
GROUP BY 
    t.full_date
ORDER BY 
    t.full_date;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt

SELECT 
    t.full_date,
    MIN(f.daily_revenue) AS min_revenue,
    MAX(f.daily_revenue) AS max_revenue,
    AVG(f.daily_revenue) AS avg_revenue
FROM DIM_Time t
JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
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
