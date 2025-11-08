-- ============================================================================
-- TEST 6: BANKING - MULTI-FACT + WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Banking/Finance
-- Complexity: 🔴 Advanced
-- Focus: Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP
-- Test Coverage: Multi-Fact Schema, Advanced Analytics, Financial Calculations
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

-- ============================================================================
-- SCHEMA: Banking Data Warehouse (Multi-Fact)
-- ============================================================================

CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_number VARCHAR(20) UNIQUE,
    date_of_birth DATE,
    customer_segment VARCHAR(50),  -- 'Premium', 'Standard', 'Basic'
    registration_date DATE,
    risk_category VARCHAR(20)      -- 'Low', 'Medium', 'High'
);

CREATE TABLE DIM_Account (
    account_key SERIAL PRIMARY KEY,
    account_number VARCHAR(30) UNIQUE NOT NULL,
    account_type VARCHAR(50),          -- 'Checking', 'Savings', 'Investment', 'Credit'
    account_category VARCHAR(50),      -- 'Personal', 'Business', 'Joint'
    currency VARCHAR(3),
    opening_date DATE,
    interest_rate DECIMAL(5,4)
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_name VARCHAR(20),
    is_business_day BOOLEAN
);

-- FACT TABLE 1: Transactions (High Granularity)
CREATE TABLE FACT_Transaction (
    transaction_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    account_key INT REFERENCES DIM_Account(account_key),
    transaction_type VARCHAR(50),      -- 'Deposit', 'Withdrawal', 'Transfer', 'Payment'
    amount DECIMAL(15,2),
    fee DECIMAL(10,2),
    transaction_status VARCHAR(20),    -- 'Completed', 'Pending', 'Failed'
    is_suspicious BOOLEAN
);

-- FACT TABLE 2: Daily Account Balance (Daily Snapshot)
CREATE TABLE FACT_Account_Balance (
    balance_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    account_key INT REFERENCES DIM_Account(account_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    opening_balance DECIMAL(15,2),
    closing_balance DECIMAL(15,2),
    daily_change DECIMAL(15,2),
    minimum_balance DECIMAL(15,2),
    maximum_balance DECIMAL(15,2)
);

-- ============================================================================
-- TEST TASKS - MULTI-FACT QUERIES
-- ============================================================================

-- Aufgabe 1: Kombiniere beide Fact-Tabellen um den Gesamtumsatz pro Konto mit dem aktuellen Kontostand zu vergleichen
-- ❌ FEHLER: fb.closing_balance muss in GROUP BY oder als Aggregat! Außerdem fehlt GROUP BY fb.closing_balance.

SELECT f1.account_key, SUM(f1.amount) AS total_transaction_amount, fb.closing_balance 
FROM FACT_Transaction f1 
JOIN FACT_Account_Balance fb ON f1.account_key = fb.account_key AND f1.time_key = fb.time_key 
GROUP BY f1.account_key;

-- KORREKTUR: MAX(fb.closing_balance) oder GROUP BY hinzufügen
-- SELECT f1.account_key, SUM(f1.amount) AS total_transaction_amount, MAX(fb.closing_balance) AS latest_closing_balance
-- FROM FACT_Transaction f1 
-- JOIN FACT_Account_Balance fb ON f1.account_key = fb.account_key AND f1.time_key = fb.time_key 
-- GROUP BY f1.account_key
-- ORDER BY f1.account_key;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten
-- ❌ FEHLER: Column "transaction_amount" existiert nicht in FACT_Transaction! Korrekt ist "amount".

SELECT c.customer_name,
       SUM(f.transaction_amount) AS total_transaction_sum,
       AVG(fb.closing_balance) AS average_account_balance
FROM DIM_Customer c
JOIN FACT_Transaction f ON c.customer_key = f.customer_key
JOIN FACT_Account_Balance fb ON c.customer_key = fb.customer_key AND f.time_key = fb.time_key
GROUP BY c.customer_name;

-- KORREKTUR:
-- SELECT c.customer_name,
--        SUM(f.amount) AS total_transaction_sum,
--        AVG(fb.closing_balance) AS average_account_balance
-- FROM DIM_Customer c
-- JOIN FACT_Transaction f ON c.customer_key = f.customer_key
-- JOIN FACT_Account_Balance fb ON c.customer_key = fb.customer_key AND f.time_key = fb.time_key
-- GROUP BY c.customer_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)
-- ✅ KORREKT (Perfektes Running Total!)

SELECT 
    t.time_key,
    d.account_key,
    c.customer_key,
    SUM(f.closing_balance) OVER (
        PARTITION BY d.account_key, c.customer_key
        ORDER BY t.time_key
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_balance
FROM 
    DIM_Time t
JOIN 
    FACT_Account_Balance f ON t.time_key = f.time_key
JOIN 
    DIM_Customer c ON f.customer_key = c.customer_key
JOIN 
    DIM_Account d ON f.account_key = d.account_key;


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)
-- ⚠️ TEILWEISE: Nutzt Subquery statt Window Function (funktioniert, aber nicht optimal laut Aufgabe).

SELECT t.transaction_id, c.customer_name, t.amount 
FROM FACT_Transaction t 
JOIN DIM_Customer c ON t.customer_key = c.customer_key 
WHERE t.amount > 3 * (
    SELECT AVG(amount) 
    FROM FACT_Transaction 
    WHERE customer_key = t.customer_key
);

-- BESSERE LÖSUNG mit Window Function:
-- WITH CustomerAvg AS (
--     SELECT 
--         transaction_id,
--         customer_key,
--         amount,
--         AVG(amount) OVER (PARTITION BY customer_key) AS avg_amount
--     FROM FACT_Transaction
-- )
-- SELECT t.transaction_id, c.customer_name, ca.amount, ca.avg_amount
-- FROM CustomerAvg ca
-- JOIN DIM_Customer c ON ca.customer_key = c.customer_key
-- WHERE ca.amount > 3 * ca.avg_amount;


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)
-- ✅ KORREKT

SELECT customer_key, customer_segment, SUM(amount) AS total_transaction_volume,
       DENSE_RANK() OVER(PARTITION BY customer_segment ORDER BY SUM(amount)) as rank_within_segment
FROM FACT_Transaction ft
JOIN DIM_Customer dc ON ft.customer_key = dc.customer_key
GROUP BY customer_key, customer_segment
ORDER BY customer_segment, rank_within_segment;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)
-- ❌ FEHLER: WHERE filtert vor Aggregation - sollte Window Function sein! Außerdem: DATE_TRUNC ist unnötig komplex.

SELECT account_key, AVG(daily_change) AS avg_daily_change 
FROM FACT_Account_Balance 
WHERE time_key >= DATE_TRUNC('day', CURRENT_DATE - INTERVAL '7 days') 
GROUP BY account_key;

-- KORREKTUR mit Window Function:
-- SELECT 
--     account_key,
--     time_key,
--     daily_change,
--     AVG(daily_change) OVER (
--         PARTITION BY account_key 
--         ORDER BY time_key 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS avg_daily_change_7_days
-- FROM FACT_Account_Balance
-- ORDER BY account_key, time_key;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten
-- ❌ FEHLER: Column "transaction_amount" und "transaction_date" existieren nicht!

SELECT c.customer_name 
FROM DIM_Customer c 
JOIN FACT_Transaction t ON c.customer_key = t.customer_key 
WHERE t.transaction_amount > 10000 AND t.transaction_date IN (
    SELECT transaction_date 
    FROM FACT_Transaction 
    GROUP BY transaction_date 
    HAVING COUNT(*) > 3
);

-- KORREKTUR:
-- WITH DailyTransactions AS (
--     SELECT 
--         customer_key,
--         time_key,
--         COUNT(*) AS transaction_count
--     FROM FACT_Transaction
--     WHERE amount > 10000
--     GROUP BY customer_key, time_key
--     HAVING COUNT(*) > 3
-- )
-- SELECT DISTINCT c.customer_name
-- FROM DailyTransactions dt
-- JOIN DIM_Customer c ON dt.customer_key = c.customer_key;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt
-- ❌ FEHLER: Multiple Probleme: week() ist MySQL-Funktion, nested aggregate AVG(SUM()) ist ungültig!

SELECT DISTINCT account_key 
FROM FACT_Transaction 
WHERE transaction_id IN (
    SELECT transaction_id 
    FROM FACT_Transaction 
    GROUP BY account_key, week(time_key) 
    HAVING SUM(amount) > 10 * AVG(SUM(amount)) OVER (PARTITION BY account_key)
);

-- KORREKTUR:
-- WITH WeeklyTotals AS (
--     SELECT 
--         account_key,
--         DATE_TRUNC('week', t.full_date) AS week_start,
--         SUM(ft.amount) AS weekly_total
--     FROM FACT_Transaction ft
--     JOIN DIM_Time t ON ft.time_key = t.time_key
--     GROUP BY account_key, DATE_TRUNC('week', t.full_date)
-- ),
-- WeeklyAvg AS (
--     SELECT 
--         account_key,
--         AVG(weekly_total) AS avg_weekly_total
--     FROM WeeklyTotals
--     GROUP BY account_key
-- )
-- SELECT DISTINCT wt.account_key
-- FROM WeeklyTotals wt
-- JOIN WeeklyAvg wa ON wt.account_key = wa.account_key
-- WHERE wt.weekly_total > 10 * wa.avg_weekly_total;


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden
-- ⚠️ TEILWEISE: GROUP BY mit transaction_id ist problematisch (jede Transaction unique), AVG sollte über alle Customer-Transactions gehen.

SELECT t.transaction_id, c.customer_name, AVG(f.amount) AS average_transaction_amount 
FROM FACT_Transaction t 
JOIN DIM_Customer c ON t.customer_key = c.customer_key 
WHERE t.is_suspicious = TRUE 
GROUP BY t.transaction_id, c.customer_name;

-- BESSERE LÖSUNG:
-- WITH CustomerAvg AS (
--     SELECT 
--         customer_key,
--         AVG(amount) AS avg_amount
--     FROM FACT_Transaction
--     GROUP BY customer_key
-- )
-- SELECT 
--     t.transaction_id, 
--     c.customer_name, 
--     t.amount,
--     ca.avg_amount AS customer_avg_amount
-- FROM FACT_Transaction t
-- JOIN DIM_Customer c ON t.customer_key = c.customer_key
-- JOIN CustomerAvg ca ON t.customer_key = ca.customer_key
-- WHERE t.is_suspicious = TRUE;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)
-- ❌ FEHLER: customer_segment, account_type, transaction_type sind NICHT in FACT_Transaction! Fehlen JOINs!

SELECT customer_segment, account_type, transaction_type, SUM(amount) AS total_amount 
FROM FACT_Transaction 
GROUP BY ROLLUP(customer_segment, account_type, transaction_type);;

-- KORREKTUR:
-- SELECT 
--     c.customer_segment, 
--     a.account_type, 
--     t.transaction_type, 
--     SUM(t.amount) AS total_amount 
-- FROM FACT_Transaction t
-- JOIN DIM_Customer c ON t.customer_key = c.customer_key
-- JOIN DIM_Account a ON t.account_key = a.account_key
-- GROUP BY ROLLUP(c.customer_segment, a.account_type, t.transaction_type)
-- ORDER BY c.customer_segment, a.account_type, t.transaction_type;


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)
-- ❌ FEHLER: year(), quarter(), month() sind MySQL-Funktionen! PostgreSQL nutzt DIM_Time Spalten oder EXTRACT().

SELECT 
    time_key,
    year(time_key) AS year,
    quarter(time_key) AS quarter,
    month(time_key) AS month,
    SUM(fee) AS total_fee
FROM 
    FACT_Transaction
GROUP BY 
    ROLLUP (time_key, year(time_key), quarter(time_key), month(time_key))
ORDER BY 
    time_key;

-- KORREKTUR:
-- SELECT 
--     t.year, 
--     t.quarter, 
--     t.month, 
--     SUM(ft.fee) AS total_fee
-- FROM FACT_Transaction ft
-- JOIN DIM_Time t ON ft.time_key = t.time_key
-- GROUP BY ROLLUP(t.year, t.quarter, t.month)
-- ORDER BY t.year, t.quarter, t.month;


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)
-- ❌ FEHLER: account_category und account_type sind NICHT in FACT_Account_Balance! Fehlt JOIN zu DIM_Account! Außerdem fehlt GROUPING() Funktion.

SELECT account_category, account_type, AVG(closing_balance) AS average_balance FROM FACT_Account_Balance GROUP BY ROLLUP(account_category, account_type);

-- KORREKTUR:
-- SELECT 
--     a.account_category, 
--     a.account_type, 
--     AVG(fab.closing_balance) AS average_balance,
--     GROUPING(a.account_category) AS is_category_total,
--     GROUPING(a.account_type) AS is_type_total
-- FROM FACT_Account_Balance fab
-- JOIN DIM_Account a ON fab.account_key = a.account_key
-- GROUP BY ROLLUP(a.account_category, a.account_type)
-- ORDER BY a.account_category, a.account_type;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 25.0/100
-- SUCCESS RATE: 3/12 (25.0%)

-- BREAKDOWN:
-- ✅ Korrekt:  3 (Tasks 3, 5)
-- ⚠️ Teilweise: 3 (Tasks 4, 6, 9)
-- ❌ Fehler:   6 (Tasks 1, 2, 7, 8, 10, 11, 12)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Running Totals korrekt (Task 3)
-- + DENSE_RANK mit PARTITION BY verstanden (Task 5)
-- + ROLLUP Syntax grundsätzlich verstanden (Tasks 10, 12 - nur JOINs fehlen)

-- WEAKNESSES:
-- - Fehlende JOINs zu Dimension-Tabellen (Tasks 10, 11, 12)
-- - Falsche Column-Namen (transaction_amount, transaction_date)
-- - MySQL Syntax statt PostgreSQL (year(), quarter(), month())
-- - GROUP BY Fehler mit non-aggregierten Spalten (Task 1)
-- - WHERE statt Window Functions bei Moving Averages (Task 6)
-- - Nested Aggregates (ungültig in SQL)

-- CRITICAL ERRORS:
-- - Tasks 1, 2, 7: Column-Namen existieren nicht im Schema!
-- - Tasks 10, 11, 12: ALLE Dimension-Attribute ohne JOINs!
-- - Task 8: Nested AVG(SUM()) ist syntaktisch ungültig!
-- - Task 11: MySQL Funktionen statt PostgreSQL

-- RECOMMENDATION:
-- ❌ SCHWACH für Advanced Level!
-- Das 7B Model hat massive Probleme mit Multi-Fact Queries und fehlenden JOINs.
-- Nur 25% Success Rate bei Advanced Banking Queries!

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 65-80 (Sehr komplex, Multiple JOINs, Window Functions)
-- Parser Challenge: High (Multi-Fact JOINs, komplexe Window Clauses)
-- Model Compatibility: Advanced models only
-- Special Focus:
--   - Korrekte JOINs zwischen beiden Fact-Tabellen via Dimensions
--   - Window Functions mit komplexen PARTITION BY
--   - Financial Calculations (Running Balance, Risk Detection)
--   - ROLLUP mit mehreren Hierarchie-Ebenen
-- ============================================================================
