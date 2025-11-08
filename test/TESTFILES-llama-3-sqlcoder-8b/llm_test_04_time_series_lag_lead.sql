-- ============================================================================
-- TEST 4: TIME SERIES ANALYSIS - LAG/LEAD & MOVING AVERAGES
-- ============================================================================
-- Domain: Zeitreihenanalyse (Sales Trends, Stock Analysis)
-- Complexity: 🟡 Intermediate
-- Focus: LAG, LEAD, Running Totals, Moving Averages
-- Test Coverage: Navigation Functions, Aggregate Window Functions, Frames
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! LAG mit PARTITION BY + ORDER BY korrekt

SELECT f.product_key, f.time_key, f.daily_revenue, lag(f.daily_revenue) OVER (PARTITION BY f.product_key ORDER BY f.time_key) AS previous_day_revenue FROM FACT_Daily_Sales f;


-- Aufgabe 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! LAG zweimal aufgerufen + NULLIF für Division durch Null + Prozentrechnung korrekt

SELECT p.product_name, ((f.daily_revenue - lag(f.daily_revenue) OVER (PARTITION BY f.product_key ORDER BY f.time_key)) / NULLIF(lag(f.daily_revenue) OVER (PARTITION BY f.product_key ORDER BY f.time_key), 0)) * 100 AS revenue_change FROM FACT_Daily_Sales f JOIN DIM_Product p ON f.product_key = p.product_key;


-- Aufgabe 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12
-- Status: ❌ FALSCH
-- Problem: t.daily_revenue existiert nicht (t ist DIM_Time, nicht FACT_Daily_Sales)!
-- Bewertung: Falsche Tabellen-Referenz

SELECT t.full_date, t.month, lag(t.daily_revenue, 12) OVER (ORDER BY t.full_date) AS previous_year_month_sales FROM FACT_Daily_Sales t;

-- ✅ KORRIGIERT: Korrekte Tabellen-Referenz + monatliche Aggregation
-- WITH monthly_sales AS (
--     SELECT 
--         t.year,
--         t.month,
--         t.month_name,
--         SUM(f.daily_revenue) AS monthly_revenue
--     FROM FACT_Daily_Sales f
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY t.year, t.month, t.month_name
-- )
-- SELECT 
--     year,
--     month_name,
--     monthly_revenue,
--     LAG(monthly_revenue, 12) OVER (ORDER BY year, month) AS previous_year_same_month
-- FROM monthly_sales
-- ORDER BY year, month;


-- Aufgabe 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: ft.full_date existiert nicht (ft ist FACT_Daily_Sales, nicht DIM_Time)!
-- Bewertung: LAG/LEAD Syntax korrekt, aber Spalten-Referenz falsch

SELECT ft.time_key, ft.full_date, ft.daily_revenue, lag(ft.daily_revenue) OVER (ORDER BY ft.time_key) AS revenue_lag_7_days_ago, lead(ft.daily_revenue) OVER (ORDER BY ft.time_key) AS revenue_lead_7_days_ahead FROM FACT_Daily_Sales ft;

-- ✅ KORRIGIERT: Mit korrekter Tabellen-Referenz + Offset 7
-- SELECT 
--     f.time_key,
--     t.full_date,
--     f.daily_revenue,
--     LAG(f.daily_revenue, 7) OVER (ORDER BY t.full_date) AS revenue_7_days_ago,
--     LEAD(f.daily_revenue, 7) OVER (ORDER BY t.full_date) AS revenue_7_days_ahead
-- FROM FACT_Daily_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY t.full_date;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS
-- ============================================================================

-- Aufgabe 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! PARTITION BY + ORDER BY + ROWS BETWEEN korrekt

SELECT p.product_key, p.product_name, SUM(fs.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY t.full_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS running_total FROM DIM_Product p JOIN FACT_Daily_Sales fs ON p.product_key = fs.product_key JOIN DIM_Time t ON fs.time_key = t.time_key WHERE EXTRACT(YEAR FROM t.full_date) = 2024;


-- Aufgabe 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals
-- Status: ❌ FALSCH
-- Problem: Keine Window Function! Nur GROUP BY, kein Running Total!
-- Bewertung: Zeigt Summe pro Monat, aber nicht RUNNING TOTAL innerhalb Quartal

SELECT t.month_name, SUM(fs.daily_revenue) AS total_revenue FROM FACT_Daily_Sales fs JOIN DIM_Time t ON fs.time_key = t.time_key GROUP BY t.month_name ORDER BY t.fiscal_quarter, t.month_name;

-- ✅ KORRIGIERT: Running Total innerhalb Quartals
-- SELECT 
--     t.fiscal_year,
--     t.fiscal_quarter,
--     t.month,
--     t.month_name,
--     SUM(fs.daily_revenue) AS monthly_revenue,
--     SUM(SUM(fs.daily_revenue)) OVER (
--         PARTITION BY t.fiscal_year, t.fiscal_quarter 
--         ORDER BY t.month
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS running_total_within_quarter
-- FROM FACT_Daily_Sales fs
-- JOIN DIM_Time t ON fs.time_key = t.time_key
-- GROUP BY t.fiscal_year, t.fiscal_quarter, t.month, t.month_name
-- ORDER BY t.fiscal_year, t.fiscal_quarter, t.month;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! 6 PRECEDING + CURRENT = 7 Tage, PARTITION BY product_key korrekt

SELECT p.product_key, AVG(f.daily_revenue) OVER (PARTITION BY p.product_key ORDER BY f.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS seven_day_moving_average FROM DIM_Product p JOIN FACT_Daily_Sales f ON p.product_key = f.product_key;


-- Aufgabe 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)
-- Status: ❌ FALSCH
-- Problem: Keine Window Function! WHERE filtert Zeitraum, aber berechnet keinen Moving Average!
-- Bewertung: Zeigt einfachen AVG, nicht MOVING Average

SELECT ft.time_key, AVG(fs.daily_revenue) AS avg_daily_revenue FROM FACT_Daily_Sales fs JOIN DIM_Time ft ON fs.time_key = ft.time_key WHERE ft.full_date BETWEEN (CURRENT_DATE - INTERVAL '30 days') AND (CURRENT_DATE + INTERVAL '30 days') GROUP BY ft.time_key ORDER BY ft.time_key NULLS LAST;

-- ✅ KORRIGIERT: Zentrierter 30-Tage Moving Average
-- SELECT 
--     f.time_key,
--     t.full_date,
--     f.daily_revenue,
--     AVG(f.daily_revenue) OVER (
--         ORDER BY f.time_key
--         ROWS BETWEEN 15 PRECEDING AND 15 FOLLOWING
--     ) AS centered_30_day_moving_avg
-- FROM FACT_Daily_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY t.full_date;


-- Aufgabe 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: ft.daily_revenue existiert nicht (ft ist FACT_Daily_Sales, aber fehlt JOIN zu DIM_Time für Sortierung)!
-- Bewertung: Logik korrekt, aber sollte nach Datum statt time_key sortieren

SELECT ft.time_key, ft.daily_revenue - AVG(ft.daily_revenue) OVER (ORDER BY ft.time_key ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS revenue_difference FROM FACT_Daily_Sales ft;

-- ✅ KORRIGIERT: Mit Datum-basierter Sortierung
-- SELECT 
--     f.time_key,
--     t.full_date,
--     f.daily_revenue,
--     AVG(f.daily_revenue) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS seven_day_moving_avg,
--     f.daily_revenue - AVG(f.daily_revenue) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS deviation_from_avg
-- FROM FACT_Daily_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY t.full_date;


-- ============================================================================
-- TEST TASKS - ADVANCED
-- ============================================================================

-- Aufgabe 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt
-- Status: ❌ FALSCH
-- Problem: Subquery mit Window Function in WHERE - syntaktisch ungültig! Window Functions in Subqueries nicht in WHERE erlaubt!
-- Bewertung: Logik-Idee korrekt, aber SQL Syntax unmöglich

SELECT ft.full_date FROM FACT_Daily_Sales fs JOIN DIM_Time ft ON fs.time_key = ft.time_key WHERE fs.daily_revenue > (SELECT AVG(fs2.daily_revenue) OVER (ORDER BY ft2.full_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)) * 1.20;

-- ✅ KORRIGIERT: Mit CTE für Moving Average
-- WITH daily_with_avg AS (
--     SELECT 
--         f.time_key,
--         t.full_date,
--         f.daily_revenue,
--         AVG(f.daily_revenue) OVER (
--             ORDER BY t.full_date
--             ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--         ) AS seven_day_moving_avg
--     FROM FACT_Daily_Sales f
--     JOIN DIM_Time t ON f.time_key = t.time_key
-- )
-- SELECT 
--     full_date,
--     daily_revenue,
--     seven_day_moving_avg,
--     ((daily_revenue - seven_day_moving_avg) / seven_day_moving_avg * 100) AS percent_above_avg
-- FROM daily_with_avg
-- WHERE daily_revenue > seven_day_moving_avg * 1.20
-- ORDER BY full_date;


-- Aufgabe 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage
-- Status: ❌ FALSCH
-- Problem: Keine Window Function! Berechnet einfachen AVG statt Moving Average + komplexe time_key Berechnung falsch!
-- Bewertung: Komplett falsche Logik

SELECT AVG(daily_quantity) AS average_daily_quantity FROM FACT_Daily_Sales WHERE time_key BETWEEN (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM TO_DATE('2022-01-01', 'YYYY-MM-DD'))) * 365 + 1 AND (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM TO_DATE('2022-01-01', 'YYYY-MM-DD'))) * 365 + 14;

-- ✅ KORRIGIERT: 14-Tage Moving Average für Bestellanzahl
-- SELECT 
--     f.time_key,
--     t.full_date,
--     f.daily_orders,
--     AVG(f.daily_orders) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
--     ) AS fourteen_day_moving_avg_orders
-- FROM FACT_Daily_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY t.full_date;


-- Aufgabe 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt
-- Status: ❌ FALSCH
-- Problem: Keine Window Functions! WHERE filtert Zeitraum, berechnet aber nicht "letzten 30 Tage" PRO Tag!
-- Bewertung: Zeigt Aggregat über Zeitraum, nicht Rolling Window

SELECT t.full_date, MIN(f.daily_revenue) AS min_daily_revenue, MAX(f.daily_revenue) AS max_daily_revenue, AVG(f.daily_revenue) AS avg_daily_revenue FROM FACT_Daily_Sales f JOIN DIM_Time t ON f.time_key = t.time_key WHERE t.full_date >= CURRENT_DATE - INTERVAL '30 days' GROUP BY t.full_date ORDER BY t.full_date NULLS LAST;

-- ✅ KORRIGIERT: Rolling 30-Tage Statistiken mit Window Functions
-- SELECT 
--     f.time_key,
--     t.full_date,
--     f.daily_revenue,
--     MIN(f.daily_revenue) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS min_last_30_days,
--     MAX(f.daily_revenue) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS max_last_30_days,
--     AVG(f.daily_revenue) OVER (
--         ORDER BY t.full_date
--         ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
--     ) AS avg_last_30_days
-- FROM FACT_Daily_Sales f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- ORDER BY t.full_date;


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
