-- ============================================================================
-- TEST 4: TIME SERIES ANALYSIS - LAG/LEAD & MOVING AVERAGES
-- ============================================================================
-- Domain: Zeitreihenanalyse (Sales Trends, Stock Analysis)
-- Complexity: 🟡 Intermediate
-- Focus: LAG, LEAD, Running Totals, Moving Averages
-- Test Coverage: Navigation Functions, Aggregate Window Functions, Frames
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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
-- ✅ KORREKT

SELECT 
    p.product_name,
    t.full_date,
    fs.daily_revenue,
    LAG(fs.daily_revenue, 1, 0) OVER (PARTITION BY p.product_key ORDER BY t.full_date) AS previous_day_revenue
FROM FACT_Daily_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
JOIN DIM_Product p ON fs.product_key = p.product_key
ORDER BY p.product_key, t.full_date;


-- Aufgabe 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt
-- ✅ KORREKT (Korrekte LAG-Nutzung, aber ineffizient da LAG 3x wiederholt wird - könnte CTE nutzen)

SELECT 
    p.product_name,
    t.full_date,
    fs.daily_revenue,
    LAG(fs.daily_revenue, 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date) AS prev_day_revenue,
    CASE 
        WHEN LAG(fs.daily_revenue, 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date) IS NOT NULL 
        THEN ((fs.daily_revenue - LAG(fs.daily_revenue, 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) / LAG(fs.daily_revenue, 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) * 100 
        ELSE NULL 
    END AS revenue_change_percent
FROM FACT_Daily_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
JOIN DIM_Product p ON fs.product_key = p.product_key
ORDER BY p.product_key, t.full_date;


-- Aufgabe 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12
-- ❌ FEHLER: LAG(SUM(fs.daily_revenue), 12) mit GROUP BY ist inkonsistent!
-- ORDER BY t.time_key ist falsch - sollte ORDER BY t.year, t.month sein!

SELECT 
    t.month_name,
    t.year,
    SUM(fs.daily_revenue) AS current_month_revenue,
    LAG(SUM(fs.daily_revenue), 12) OVER (ORDER BY t.time_key) AS same_month_last_year_revenue
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales fs ON t.time_key = fs.time_key
GROUP BY 
    t.month_name, t.year
ORDER BY 
    t.year, t.month_name;

-- KORREKTUR:
-- WITH MonthlySales AS (
--     SELECT 
--         t.year,
--         t.month,
--         t.month_name,
--         SUM(fs.daily_revenue) AS current_month_revenue
--     FROM DIM_Time t
--     JOIN FACT_Daily_Sales fs ON t.time_key = fs.time_key
--     GROUP BY t.year, t.month, t.month_name
-- )
-- SELECT 
--     month_name,
--     year,
--     current_month_revenue,
--     LAG(current_month_revenue, 12) OVER (ORDER BY year, month) AS same_month_last_year_revenue
-- FROM MonthlySales
-- ORDER BY year, month;


-- Aufgabe 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)
-- ❌ FEHLER: LAG/LEAD Offset ist 1, nicht 7! Sollte LAG(f.daily_revenue, 7) sein!

SELECT 
    t.full_date,
    f.daily_revenue,
    LAG(f.daily_revenue, 1, 0) OVER (ORDER BY t.full_date) AS revenue_7_days_ago,
    LEAD(f.daily_revenue, 1, 0) OVER (ORDER BY t.full_date) AS revenue_7_days_ahead
FROM 
    FACT_Daily_Sales f
JOIN 
    DIM_Time t ON f.time_key = t.time_key
ORDER BY 
    t.full_date;

-- KORREKTUR:
-- SELECT 
--     t.full_date,
--     f.daily_revenue,
--     LAG(f.daily_revenue, 7, 0) OVER (ORDER BY t.full_date) AS revenue_7_days_ago,
--     LEAD(f.daily_revenue, 7, 0) OVER (ORDER BY t.full_date) AS revenue_7_days_ahead
-- FROM 
--     FACT_Daily_Sales f
-- JOIN 
--     DIM_Time t ON f.time_key = t.time_key
-- ORDER BY 
--     t.full_date;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS
-- ============================================================================

-- Aufgabe 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024
-- ⚠️ TEILWEISE: Korrekte Window Function, ABER fehlt explizites "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW"!

SELECT 
    p.product_name,
    t.full_date,
    SUM(fs.daily_revenue) OVER (PARTITION BY fs.product_key ORDER BY t.full_date) AS cumulative_revenue
FROM 
    FACT_Daily_Sales fs
JOIN 
    DIM_Time t ON fs.time_key = t.time_key
JOIN 
    DIM_Product p ON fs.product_key = p.product_key
WHERE 
    t.full_date BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY 
    p.product_name, t.full_date;

-- BESSERE LÖSUNG (explizites Frame):
-- SELECT 
--     p.product_name,
--     t.full_date,
--     fs.daily_revenue,
--     SUM(fs.daily_revenue) OVER (
--         PARTITION BY fs.product_key 
--         ORDER BY t.full_date 
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS cumulative_revenue
-- FROM FACT_Daily_Sales fs
-- JOIN DIM_Time t ON fs.time_key = t.time_key
-- JOIN DIM_Product p ON fs.product_key = p.product_key
-- WHERE t.full_date BETWEEN '2024-01-01' AND '2024-12-31'
-- ORDER BY p.product_name, t.full_date;


-- Aufgabe 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals
-- ❌ FEHLER: GROUP BY mit Window Function ist inkonsistent! 
-- SUM(fs.daily_revenue) aggregiert, aber OVER verwendet t.full_date das nicht in GROUP BY ist!

SELECT 
    t.month_name,
    t.quarter,
    SUM(fs.daily_revenue) OVER (PARTITION BY t.quarter ORDER BY t.full_date) AS running_total_revenue
FROM 
    FACT_Daily_Sales fs
JOIN 
    DIM_Time t ON fs.time_key = t.time_key
GROUP BY 
    t.month_name, t.quarter, t.full_date
ORDER BY 
    t.quarter, t.full_date;

-- KORREKTUR:
-- WITH MonthlySales AS (
--     SELECT 
--         t.quarter,
--         t.month,
--         t.month_name,
--         SUM(fs.daily_revenue) AS monthly_revenue
--     FROM FACT_Daily_Sales fs
--     JOIN DIM_Time t ON fs.time_key = t.time_key
--     GROUP BY t.quarter, t.month, t.month_name
-- )
-- SELECT 
--     month_name,
--     quarter,
--     monthly_revenue,
--     SUM(monthly_revenue) OVER (
--         PARTITION BY quarter 
--         ORDER BY month 
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS running_total_revenue
-- FROM MonthlySales
-- ORDER BY quarter, month;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt
-- ❌ FEHLER: ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING ist FORWARD-looking (Zukunft)!
-- Moving Average sollte BACKWARD sein: ROWS BETWEEN 6 PRECEDING AND CURRENT ROW!

SELECT 
    p.product_name,
    t.full_date,
    AVG(fs.daily_revenue) OVER (
        PARTITION BY fs.product_key 
        ORDER BY t.full_date 
        ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING
    ) AS seven_day_moving_avg_revenue
FROM FACT_Daily_Sales fs
JOIN DIM_Time t ON fs.time_key = t.time_key
JOIN DIM_Product p ON fs.product_key = p.product_key
ORDER BY p.product_name, t.full_date;

-- KORREKTUR:
-- SELECT 
--     p.product_name,
--     t.full_date,
--     fs.daily_revenue,
--     AVG(fs.daily_revenue) OVER (
--         PARTITION BY fs.product_key 
--         ORDER BY t.full_date 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS seven_day_moving_avg_revenue
-- FROM FACT_Daily_Sales fs
-- JOIN DIM_Time t ON fs.time_key = t.time_key
-- JOIN DIM_Product p ON fs.product_key = p.product_key
-- ORDER BY p.product_name, t.full_date;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)
-- ❌ FEHLER: RANGE BETWEEN INTERVAL funktioniert nur mit DATE types!
-- ORDER BY t.time_key (INT) mit INTERVAL ist ungültig!

SELECT 
    t.full_date,
    AVG(fs.daily_revenue) OVER (
        ORDER BY t.time_key 
        RANGE BETWEEN INTERVAL '15 days' PRECEDING 
        AND INTERVAL '15 days' FOLLOWING
    ) AS moving_average_revenue
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales fs ON t.time_key = fs.time_key
WHERE 
    t.full_date >= (CURRENT_DATE - INTERVAL '30 days')
ORDER BY 
    t.full_date;

-- KORREKTUR (ORDER BY muss DATE sein):
-- SELECT 
--     t.full_date,
--     AVG(fs.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         RANGE BETWEEN INTERVAL '15 days' PRECEDING 
--         AND INTERVAL '15 days' FOLLOWING
--     ) AS moving_average_revenue
-- FROM 
--     DIM_Time t
-- JOIN 
--     FACT_Daily_Sales fs ON t.time_key = fs.time_key
-- WHERE 
--     t.full_date >= (CURRENT_DATE - INTERVAL '30 days')
-- ORDER BY 
--     t.full_date;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)
-- ❌ FEHLER: Unnötiger JOIN FACT_Daily_Sales f2! Query ist viel zu komplex!
-- Außerdem: AVG(f2.daily_revenue) statt AVG(f1.daily_revenue) ist falsch!

SELECT 
    f1.time_key,
    f1.product_key,
    f1.daily_revenue,
    AVG(f2.daily_revenue) OVER (
        PARTITION BY f1.product_key 
        ORDER BY f1.time_key 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_days,
    f1.daily_revenue - AVG(f2.daily_revenue) OVER (
        PARTITION BY f1.product_key 
        ORDER BY f1.time_key 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS deviation_from_moving_avg
FROM FACT_Daily_Sales f1
JOIN FACT_Daily_Sales f2 ON f1.product_key = f2.product_key
WHERE f1.time_key >= (SELECT time_key FROM DIM_Time WHERE full_date = CURRENT_DATE - INTERVAL '7 days')
ORDER BY f1.time_key;

-- KORREKTUR (ohne JOIN f2):
-- SELECT 
--     time_key,
--     product_key,
--     daily_revenue,
--     AVG(daily_revenue) OVER (
--         PARTITION BY product_key 
--         ORDER BY time_key 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS moving_avg_7_days,
--     daily_revenue - AVG(daily_revenue) OVER (
--         PARTITION BY product_key 
--         ORDER BY time_key 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS deviation_from_moving_avg
-- FROM FACT_Daily_Sales
-- WHERE time_key >= (SELECT time_key FROM DIM_Time WHERE full_date >= CURRENT_DATE - INTERVAL '7 days' LIMIT 1)
-- ORDER BY time_key;


-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt
-- ⚠️ TEILWEISE: Funktioniert, aber ineffizient (Subquery wird 2x ausgeführt)! Sollte CTE nutzen!

SELECT t.full_date, f.daily_revenue, 
       (SELECT AVG(daily_revenue) 
        FROM FACT_Daily_Sales fs2 
        JOIN DIM_Time t2 ON fs2.time_key = t2.time_key 
        WHERE t2.full_date BETWEEN t.full_date - INTERVAL '6 days' AND t.full_date
       ) AS moving_avg
FROM FACT_Daily_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE f.daily_revenue > (SELECT AVG(daily_revenue) 
                         FROM FACT_Daily_Sales fs2 
                         JOIN DIM_Time t2 ON fs2.time_key = t2.time_key 
                         WHERE t2.full_date BETWEEN t.full_date - INTERVAL '6 days' AND t.full_date) * 1.2;

-- BESSERE LÖSUNG mit Window Function:
-- WITH MovingAvg AS (
--     SELECT 
--         t.full_date,
--         f.daily_revenue,
--         AVG(f.daily_revenue) OVER (
--             ORDER BY t.full_date 
--             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--         ) AS moving_avg_7_days
--     FROM FACT_Daily_Sales f
--     JOIN DIM_Time t ON f.time_key = t.time_key
-- )
-- SELECT full_date, daily_revenue, moving_avg_7_days
-- FROM MovingAvg
-- WHERE daily_revenue > moving_avg_7_days * 1.2;


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage
-- ✅ KORREKT

SELECT 
    t.full_date,
    AVG(f.daily_orders) OVER (
        ORDER BY t.full_date 
        ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
    ) AS moving_avg_orders
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales f ON t.time_key = f.time_key
ORDER BY 
    t.full_date;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt
-- ❌ FEHLER: GROUP BY t.full_date aggregiert pro Tag, zeigt aber nicht "letzte 30 Tage"!
-- Das zeigt Min/Max/Avg nur für DIESEN Tag, nicht für die letzten 30 Tage!

SELECT 
    t.full_date,
    MIN(fs.daily_revenue) AS min_revenue,
    MAX(fs.daily_revenue) AS max_revenue,
    AVG(fs.daily_revenue) AS avg_revenue
FROM 
    DIM_Time t
JOIN 
    FACT_Daily_Sales fs ON t.time_key = fs.time_key
WHERE 
    t.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    t.full_date
ORDER BY 
    t.full_date;

-- KORREKTUR (mit Window Functions):
-- SELECT 
--     t.full_date,
--     MIN(fs.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS min_revenue_30_days,
--     MAX(fs.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS max_revenue_30_days,
--     AVG(fs.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS avg_revenue_30_days
-- FROM 
--     DIM_Time t
-- JOIN 
--     FACT_Daily_Sales fs ON t.time_key = fs.time_key
-- WHERE 
--     t.full_date >= CURRENT_DATE - INTERVAL '30 days'
-- ORDER BY 
--     t.full_date;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 41.7/100
-- SUCCESS RATE: 4/12 (33.3%)

-- BREAKDOWN:
-- ✅ Korrekt:  3 (Tasks 1, 2, 11)
-- ⚠️ Teilweise: 2 (Tasks 5, 10)
-- ❌ Fehler:   7 (Tasks 3, 4, 6, 7, 8, 9, 12)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + LAG mit einfachem Offset korrekt (Tasks 1, 2)
-- + Moving Average mit ROWS BETWEEN korrekt (Task 11)

-- WEAKNESSES:
-- - LAG/LEAD Offset falsch (Task 4: nutzt 1 statt 7)
-- - ROWS BETWEEN Richtung falsch (Task 7: FOLLOWING statt PRECEDING)
-- - RANGE BETWEEN mit INT statt DATE (Task 8)
-- - Unnötige JOINs (Task 9)
-- - GROUP BY ohne Window Function Konsistenz (Tasks 3, 6)
-- - Falsche Logik bei Aggregationen (Task 12)

-- CRITICAL ERRORS:
-- - Task 4: LAG(revenue, 1) statt LAG(revenue, 7) - Offset komplett falsch!
-- - Task 7: ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING ist forward-looking, nicht backward!
-- - Task 8: RANGE BETWEEN INTERVAL mit ORDER BY t.time_key (INT) ist ungültig!
-- - Task 12: GROUP BY zeigt nur aktuellen Tag, nicht "letzte 30 Tage"!

-- RECOMMENDATION:
-- ⚠️ SCHWACH für Time Series!
-- Score ist schlechter als qwen2.5-vl-7b (58.3% → 41.7%)
-- LAG/LEAD Offsets, Window Frames und komplexe Aggregationen sind Schwachpunkte

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
