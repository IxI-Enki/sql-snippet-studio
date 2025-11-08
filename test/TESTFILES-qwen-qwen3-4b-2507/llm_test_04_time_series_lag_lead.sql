-- ============================================================================
-- TEST 4: TIME SERIES ANALYSIS - LAG/LEAD & MOVING AVERAGES
-- ============================================================================
-- Domain: Zeitreihenanalyse (Sales Trends, Stock Analysis)
-- Complexity: 🟡 Intermediate
-- Focus: LAG, LEAD, Running Totals, Moving Averages
-- Test Coverage: Navigation Functions, Aggregate Window Functions, Frames
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

-- ❌ FEHLER (Score: 50/100):
--    PROBLEM: ORDER BY month_name (alphabetisch!) statt year, month
--    LAG(12) macht keinen Sinn mit alphabetischer Sortierung!
--    "April 2023" → LAG(12) → "April 2022" funktioniert nicht!
--    SOLLTE: ORDER BY year, month für chronologische Reihenfolge

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

-- KORREKTE LÖSUNG:
-- SELECT 
--     t.year,
--     t.month,
--     t.month_name,
--     SUM(fs.daily_revenue) AS current_month_revenue,
--     LAG(SUM(fs.daily_revenue), 12) OVER (ORDER BY t.year, t.month) AS previous_year_same_month_revenue
-- FROM DIM_Time t
-- JOIN FACT_Daily_Sales fs ON t.time_key = fs.time_key
-- GROUP BY t.year, t.month, t.month_name
-- ORDER BY t.year, t.month;


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

-- ⚠️ TEILWEISE KORREKT (Score: 70/100):
--    PROBLEM: ORDER BY month_name (alphabetisch!) statt month (numerisch)
--    In Q1: "April" kommt vor "Februar" vor "Januar" vor "März" - FALSCH!
--    Running Total wird in falscher Reihenfolge berechnet!
--    SOLLTE: ORDER BY t.month (numerisch)

SELECT 
    t.month_name,
    t.quarter,
    SUM(f.daily_revenue) AS monthly_revenue,
    SUM(SUM(f.daily_revenue)) OVER (PARTITION BY t.quarter ORDER BY t.month_name) AS running_total_revenue
FROM DIM_Time t
JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
GROUP BY t.month_name, t.quarter
ORDER BY t.quarter, t.month_name;

-- KORREKTE LÖSUNG:
-- SELECT 
--     t.quarter,
--     t.month,
--     t.month_name,
--     SUM(f.daily_revenue) AS monthly_revenue,
--     SUM(SUM(f.daily_revenue)) OVER (PARTITION BY t.quarter ORDER BY t.month) AS running_total_revenue
-- FROM DIM_Time t
-- JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
-- GROUP BY t.quarter, t.month, t.month_name
-- ORDER BY t.quarter, t.month;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt

-- ❌ FAILED (Score: 20/100):
--    FEHLT: Window Function mit ROWS BETWEEN!
--    Diese Query berechnet nur den GLOBALEN Durchschnitt PRO Produkt!
--    Das ist KEIN Moving Average, nur AVG() über alle Tage!
--    SOLLTE: AVG() OVER (... ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)

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

-- KORREKTE LÖSUNG:
-- SELECT 
--     p.product_name,
--     t.full_date,
--     s.daily_revenue,
--     AVG(s.daily_revenue) OVER (
--         PARTITION BY p.product_key 
--         ORDER BY t.full_date 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS seven_day_moving_average
-- FROM DIM_Product p
-- JOIN FACT_Daily_Sales s ON p.product_key = s.product_key
-- JOIN DIM_Time t ON s.time_key = t.time_key
-- ORDER BY p.product_name, t.full_date;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)

-- ❌ FAILED (Score: 10/100):
--    SYNTAX-FEHLER: DATEADD ist SQL Server Syntax, nicht PostgreSQL!
--    LOGIKFEHLER: WHERE mit DATEADD(day, -15, t.full_date) macht keinen Sinn!
--    FEHLT: Window Function mit ROWS BETWEEN!
--    PostgreSQL: INTERVAL '15 days' statt DATEADD
--    SOLLTE: ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING

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

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     t.full_date,
--     AVG(s.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
--     ) AS centered_moving_average_30_days
-- FROM DIM_Time t
-- JOIN FACT_Daily_Sales s ON t.time_key = s.time_key
-- ORDER BY t.full_date;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEINE Query generieren!

-- KORREKTE LÖSUNG:
-- WITH moving_avg AS (
--     SELECT 
--         t.full_date,
--         p.product_key,
--         s.daily_revenue,
--         AVG(s.daily_revenue) OVER (
--             PARTITION BY p.product_key 
--             ORDER BY t.full_date 
--             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--         ) AS seven_day_moving_avg
--     FROM FACT_Daily_Sales s
--     JOIN DIM_Time t ON s.time_key = t.time_key
--     JOIN DIM_Product p ON s.product_key = p.product_key
-- )
-- SELECT 
--     full_date,
--     product_key,
--     daily_revenue,
--     seven_day_moving_avg,
--     daily_revenue - seven_day_moving_avg AS deviation_from_average
-- FROM moving_avg
-- ORDER BY product_key, full_date;

-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt

-- ❌ SYNTAX-FEHLER (Score: 40/100):
--    FEHLER: HAVING kann NICHT mit Window Functions verwendet werden!
--    PostgreSQL erlaubt keine Window Functions in HAVING Klausel!
--    SOLLTE: Subquery oder CTE verwenden, dann WHERE auf das Ergebnis

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

-- KORREKTE LÖSUNG:
-- WITH daily_avg AS (
--     SELECT 
--         t.full_date,
--         SUM(f.daily_revenue) AS total_revenue,
--         AVG(SUM(f.daily_revenue)) OVER (
--             ORDER BY t.full_date 
--             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--         ) AS seven_day_moving_avg
--     FROM DIM_Time t
--     JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
--     GROUP BY t.full_date
-- )
-- SELECT *
-- FROM daily_avg
-- WHERE total_revenue > 1.2 * seven_day_moving_avg;


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage

-- ❌ FAILED (Score: 25/100):
--    FEHLT: Window Function mit ROWS BETWEEN!
--    Diese Query berechnet nur AVG() PRO TAG, nicht gleitend!
--    WHERE filter schränkt nur Zeitraum ein, macht aber keinen Moving Average!
--    SOLLTE: ROWS BETWEEN 13 PRECEDING AND CURRENT ROW

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

-- KORREKTE LÖSUNG:
-- SELECT 
--     t.full_date,
--     f.daily_orders,
--     AVG(f.daily_orders) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
--     ) AS moving_average_14_days
-- FROM DIM_Time t
-- JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
-- ORDER BY t.full_date;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt

-- ❌ FAILED (Score: 25/100):
--    FEHLT: Window Functions mit ROWS BETWEEN!
--    Diese Query zeigt MIN/MAX/AVG PRO TAG, nicht über 30 Tage!
--    WHERE filter schränkt nur Zeitraum ein, berechnet aber keine gleitenden Werte!
--    SOLLTE: MIN/MAX/AVG OVER (...ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)

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

-- KORREKTE LÖSUNG:
-- SELECT 
--     t.full_date,
--     f.daily_revenue,
--     MIN(f.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS min_revenue_30_days,
--     MAX(f.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS max_revenue_30_days,
--     AVG(f.daily_revenue) OVER (
--         ORDER BY t.full_date 
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS avg_revenue_30_days
-- FROM DIM_Time t
-- JOIN FACT_Daily_Sales f ON t.time_key = f.time_key
-- ORDER BY t.full_date;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 46.7/100 ⭐⭐
-- SUCCESS RATE: 33.3% (4/12 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1:  100/100 - Perfekt (LAG mit PARTITION BY)
--   ✅ Aufgabe 2:  100/100 - Perfekt (Prozentberechnung mit LAG)
--   ⚠️ Aufgabe 3:   50/100 - LAG über month_name (alphabetisch)
--   ✅ Aufgabe 4:  100/100 - Perfekt (LAG + LEAD mit Offset)
--   ✅ Aufgabe 5:  100/100 - Perfekt (Running Total mit ROWS UNBOUNDED PRECEDING)
--   ⚠️ Aufgabe 6:   70/100 - Running Total über month_name (alphabetisch)
--   ❌ Aufgabe 7:   20/100 - Kein ROWS BETWEEN (nur AVG)
--   ❌ Aufgabe 8:   10/100 - SQL Server Syntax + Logikfehler
--   ❌ Aufgabe 9:    0/100 - NICHT generiert!
--   ❌ Aufgabe 10:  40/100 - HAVING mit Window Functions (Syntax-Fehler)
--   ❌ Aufgabe 11:  25/100 - Kein ROWS BETWEEN (nur WHERE filter)
--   ❌ Aufgabe 12:  25/100 - Kein ROWS BETWEEN (nur GROUP BY)
--
-- STÄRKEN:
--   + LAG/LEAD mit PARTITION BY perfekt verstanden
--   + Running Totals mit ROWS UNBOUNDED PRECEDING korrekt
--   + Offset-Parameter bei LAG/LEAD korrekt
--
-- SCHWÄCHEN:
--   - ROWS BETWEEN X PRECEDING AND CURRENT ROW: NICHT VERSTANDEN!
--   - Sortierung wieder über month_name (alphabetisch) statt numerisch
--   - Verwechselt SQL Server (DATEADD) und PostgreSQL Syntax
--   - HAVING mit Window Functions (PostgreSQL erlaubt das nicht!)
--   - Moving Averages werden als einfache AVG() interpretiert
--
-- KRITISCHE FEHLER:
--   ⚠️ ROWS BETWEEN für Moving Averages: KOMPLETT FEHLT!
--   ⚠️ Model versteht Konzept "Moving Average" nicht!
--   ⚠️ Verwendet immer WHERE filter statt Window Frames!
--   ⚠️ SQL Server vs PostgreSQL Syntax-Verwechslungen
--
-- EMPFEHLUNG: ❌ NICHT geeignet für Moving Averages & Window Frames!
--              Nur für einfache LAG/LEAD und Running Totals verwendbar!
-- ============================================================================
