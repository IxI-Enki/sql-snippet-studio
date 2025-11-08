-- ============================================================================
-- TEST 6: BANKING - MULTI-FACT + WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Banking/Finance
-- Complexity: 🔴 Advanced
-- Focus: Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP
-- Test Coverage: Multi-Fact Schema, Advanced Analytics, Financial Calculations
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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
-- ⚠️ TEILWEISE: JOIN korrekt, aber fb.closing_balance im GROUP BY ist problematisch!
-- Problem: Mehrere closing_balance Werte pro Konto (täglich), sollte MAX(time_key) nehmen für "aktuellen" Stand

SELECT 
    a.account_number,
    SUM(t.amount) AS total_transaction_amount,
    fb.closing_balance AS current_balance
FROM 
    FACT_Transaction t
JOIN 
    DIM_Account a ON t.account_key = a.account_key
JOIN 
    FACT_Account_Balance fb ON t.account_key = fb.account_key
GROUP BY 
    a.account_number, fb.closing_balance;

-- BESSERE LÖSUNG:
-- WITH LatestBalance AS (
--     SELECT 
--         account_key,
--         closing_balance,
--         ROW_NUMBER() OVER (PARTITION BY account_key ORDER BY time_key DESC) AS rn
--     FROM FACT_Account_Balance
-- )
-- SELECT 
--     a.account_number,
--     SUM(t.amount) AS total_transaction_amount,
--     lb.closing_balance AS current_balance
-- FROM FACT_Transaction t
-- JOIN DIM_Account a ON t.account_key = a.account_key
-- JOIN LatestBalance lb ON t.account_key = lb.account_key AND lb.rn = 1
-- GROUP BY a.account_number, lb.closing_balance;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten
-- ✅ KORREKT

SELECT 
    c.customer_key,
    c.customer_name,
    SUM(t.amount) AS total_transaction_amount,
    AVG(ab.closing_balance) AS average_account_balance
FROM DIM_Customer c
JOIN FACT_Transaction t ON c.customer_key = t.customer_key
JOIN FACT_Account_Balance ab ON c.customer_key = ab.customer_key
GROUP BY c.customer_key, c.customer_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)
-- ❌ FEHLER: SUM(fb.closing_balance) ist FALSCH!
-- Problem: closing_balance ist bereits der Kontostand, nicht die Änderung!
-- Sollte SUM(fb.daily_change) sein ODER nur closing_balance ohne SUM!

SELECT 
    fb.time_key,
    fb.account_key,
    fb.customer_key,
    fb.opening_balance,
    fb.closing_balance,
    SUM(fb.closing_balance) OVER (PARTITION BY fb.account_key ORDER BY fb.time_key) AS running_balance
FROM FACT_Account_Balance fb
ORDER BY fb.account_key, fb.time_key;

-- KORREKTUR:
-- SELECT 
--     fb.time_key,
--     fb.account_key,
--     fb.customer_key,
--     fb.opening_balance,
--     fb.closing_balance,
--     SUM(fb.daily_change) OVER (PARTITION BY fb.account_key ORDER BY fb.time_key 
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
-- FROM FACT_Account_Balance fb
-- ORDER BY fb.account_key, fb.time_key;
-- ODER einfach nur fb.closing_balance selbst, da das schon der Running Balance ist!


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)
-- ✅ KORREKT (ineffizient aber funktioniert - Subquery wird für jede Row ausgeführt)

SELECT t.transaction_id, t.customer_key, t.amount, AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_customer_amount
FROM FACT_Transaction t
WHERE t.amount > (SELECT AVG(amount) * 3 FROM FACT_Transaction WHERE customer_key = t.customer_key);

-- BESSERE LÖSUNG (ohne correlated subquery):
-- WITH CustomerAvg AS (
--     SELECT 
--         customer_key,
--         AVG(amount) AS avg_amount
--     FROM FACT_Transaction
--     GROUP BY customer_key
-- )
-- SELECT 
--     t.transaction_id, 
--     t.customer_key, 
--     t.amount, 
--     ca.avg_amount AS avg_customer_amount
-- FROM FACT_Transaction t
-- JOIN CustomerAvg ca ON t.customer_key = ca.customer_key
-- WHERE t.amount > ca.avg_amount * 3;


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)
-- ✅ KORREKT

SELECT 
    c.customer_name, 
    c.customer_segment, 
    SUM(t.amount) AS total_transaction_volume,
    DENSE_RANK() OVER (PARTITION BY c.customer_segment ORDER BY SUM(t.amount) DESC) AS rank_by_segment
FROM 
    DIM_Customer c
JOIN 
    FACT_Transaction t ON c.customer_key = t.customer_key
GROUP BY 
    c.customer_key, c.customer_name, c.customer_segment
ORDER BY 
    c.customer_segment, rank_by_segment;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)
-- ❌ FEHLER: Das ist KEIN Moving Average!
-- Problem: Nutzt GROUP BY + AVG statt Window Function mit ROWS BETWEEN!
-- Das berechnet nur den Durchschnitt der letzten 7 Tage, nicht einen gleitenden Durchschnitt

SELECT 
    a.account_key,
    a.account_number,
    AVG(fdb.daily_change) AS avg_daily_change
FROM 
    DIM_Account a
JOIN 
    FACT_Account_Balance fdb ON a.account_key = fdb.account_key
JOIN 
    DIM_Time t ON fdb.time_key = t.time_key
WHERE 
    t.full_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 
    a.account_key, a.account_number
ORDER BY 
    avg_daily_change DESC;

-- KORREKTUR (echtes 7-Day Moving Average):
-- SELECT 
--     a.account_number,
--     t.full_date,
--     fdb.daily_change,
--     AVG(fdb.daily_change) OVER (
--         PARTITION BY a.account_key 
--         ORDER BY t.full_date 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS moving_avg_7_days
-- FROM DIM_Account a
-- JOIN FACT_Account_Balance fdb ON a.account_key = fdb.account_key
-- JOIN DIM_Time t ON fdb.time_key = t.time_key
-- ORDER BY a.account_number, t.full_date;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten
-- ✅ KORREKT

SELECT c.customer_name, t.full_date, COUNT(*) AS transaction_count
FROM FACT_Transaction ft
JOIN DIM_Customer c ON ft.customer_key = c.customer_key
JOIN DIM_Time t ON ft.time_key = t.time_key
WHERE ft.amount > 10000
GROUP BY c.customer_key, c.customer_name, t.full_date
HAVING COUNT(*) > 3;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt
-- ⚠️ TEILWEISE: Logik korrekt, ABER WHERE ti.week = 1 ist zu spezifisch!
-- Problem: Filtert nur Woche 1, nicht die aktuelle Woche oder alle Wochen!

SELECT a.account_key, a.account_number, SUM(t.amount) AS weekly_transaction_sum
FROM FACT_Transaction t
JOIN DIM_Account a ON t.account_key = a.account_key
JOIN DIM_Time ti ON t.time_key = ti.time_key
WHERE ti.week = 1
GROUP BY a.account_key, a.account_number
HAVING SUM(t.amount) > (SELECT AVG(weekly_sum) * 10
                         FROM (SELECT a2.account_key, SUM(t2.amount) AS weekly_sum
                               FROM FACT_Transaction t2
                               JOIN DIM_Account a2 ON t2.account_key = a2.account_key
                               JOIN DIM_Time ti2 ON t2.time_key = ti2.time_key
                               WHERE ti2.week = 1
                               GROUP BY a2.account_key) AS avg_weekly);

-- BESSERE LÖSUNG (alle Wochen prüfen):
-- WITH WeeklyTransactions AS (
--     SELECT 
--         a.account_key,
--         a.account_number,
--         ti.week,
--         ti.year,
--         SUM(t.amount) AS weekly_sum
--     FROM FACT_Transaction t
--     JOIN DIM_Account a ON t.account_key = a.account_key
--     JOIN DIM_Time ti ON t.time_key = ti.time_key
--     GROUP BY a.account_key, a.account_number, ti.week, ti.year
-- ),
-- WeeklyAverage AS (
--     SELECT AVG(weekly_sum) AS avg_weekly_sum
--     FROM WeeklyTransactions
-- )
-- SELECT account_key, account_number, week, year, weekly_sum
-- FROM WeeklyTransactions, WeeklyAverage
-- WHERE weekly_sum > avg_weekly_sum * 10
-- ORDER BY weekly_sum DESC;


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden
-- ✅ KORREKT

SELECT t.transaction_id, t.customer_key, t.amount, AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_transaction_amount
FROM FACT_Transaction t
WHERE t.is_suspicious = TRUE;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)
-- ✅ KORREKT

SELECT 
    c.customer_segment,
    a.account_type,
    t.transaction_type,
    SUM(t.amount) AS transaction_volume
FROM FACT_Transaction t
JOIN DIM_Customer c ON t.customer_key = c.customer_key
JOIN DIM_Account a ON t.account_key = a.account_key
GROUP BY ROLLUP (c.customer_segment, a.account_type, t.transaction_type);


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)
-- ✅ KORREKT

SELECT 
    t.year,
    t.quarter,
    t.month,
    SUM(f.fee) AS total_fees
FROM 
    FACT_Transaction f
JOIN 
    DIM_Time t ON f.time_key = t.time_key
GROUP BY 
    ROLLUP (t.year, t.quarter, t.month);


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)
-- ✅ KORREKT

SELECT 
    a.account_category,
    a.account_type,
    AVG(fab.closing_balance) AS avg_balance,
    COUNT(*) AS transaction_count
FROM FACT_Account_Balance fab
JOIN DIM_Account a ON fab.account_key = a.account_key
GROUP BY ROLLUP (a.account_category, a.account_type)
ORDER BY GROUPING(a.account_category), GROUPING(a.account_type), a.account_category, a.account_type;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 66.7/100
-- SUCCESS RATE: 7/12 (58.3%)

-- BREAKDOWN:
-- ✅ Korrekt:  7 (Tasks 2, 4, 5, 7, 9, 10, 11, 12)
-- ⚠️ Teilweise: 2 (Tasks 1, 8)
-- ❌ Fehler:   2 (Tasks 3, 6)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Multi-Fact JOINs verstanden (Tasks 1, 2)
-- + DENSE_RANK mit PARTITION BY korrekt (Task 5)
-- + Suspicious Activity Detection korrekt (Tasks 7, 9)
-- + ROLLUP mit mehreren Ebenen perfekt (Tasks 10, 11, 12)
-- + GROUPING() Funktion korrekt verwendet (Task 12)

-- WEAKNESSES:
-- - Task 1: fb.closing_balance im GROUP BY ohne time_key Filterung
-- - Task 3: SUM(closing_balance) statt SUM(daily_change) - Logikfehler!
-- - Task 6: GROUP BY + AVG statt Window Function - kein Moving Average!
-- - Task 8: WHERE week = 1 zu spezifisch - sollte alle Wochen prüfen

-- CRITICAL ERRORS:
-- - Task 3: SUM(fb.closing_balance) ist logisch falsch - closing_balance IST bereits der Kontostand!
-- - Task 6: Kein echtes Moving Average - nur durchschnitt der letzten 7 Tage, nicht gleitend!

-- RECOMMENDATION:
-- ⚠️ MITTEL für Multi-Fact Queries
-- Model versteht Multi-Fact JOINs, aber Window Functions mit Finanz-Logik sind schwach
-- ROLLUP ist stark, aber Moving Averages und Running Totals sind problematisch

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
