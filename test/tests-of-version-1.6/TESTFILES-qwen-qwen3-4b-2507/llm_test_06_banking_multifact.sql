-- ============================================================================
-- TEST 6: BANKING - MULTI-FACT + WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Banking/Finance
-- Complexity: 🔴 Advanced
-- Focus: Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP
-- Test Coverage: Multi-Fact Schema, Advanced Analytics, Financial Calculations
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

SELECT 
    f1.account_key,
    SUM(f1.amount) AS total_transaction_value,
    f2.closing_balance AS current_account_balance
FROM 
    FACT_Transaction f1
JOIN 
    FACT_Account_Balance f2 
    ON f1.account_key = f2.account_key 
    AND f1.time_key = f2.time_key
GROUP BY 
    f1.account_key, f2.closing_balance;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten

SELECT 
    c.customer_key,
    c.customer_name,
    SUM(t.amount) AS total_transaction_amount,
    AVG(ab.closing_balance) AS average_account_balance
FROM 
    DIM_Customer c
    JOIN FACT_Transaction t ON c.customer_key = t.customer_key
    JOIN FACT_Account_Balance ab ON c.customer_key = ab.customer_key
GROUP BY 
    c.customer_key, c.customer_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)

-- ❌ FAILED (Score: 30/100):
--    FEHLT: Window Function für Running Balance!
--    Diese Query zeigt nur closing_balance, keinen RUNNING Total!
--    SOLLTE: SUM(daily_change) OVER (PARTITION BY account_key ORDER BY time_key)

SELECT 
    ab.time_key,
    ab.account_key,
    ab.customer_key,
    ab.closing_balance AS running_balance
FROM 
    FACT_Account_Balance ab
ORDER BY 
    ab.time_key, 
    ab.account_key;

-- KORREKTE LÖSUNG:
-- SELECT 
--     ab.time_key,
--     ab.account_key,
--     ab.closing_balance,
--     SUM(ab.daily_change) OVER (
--         PARTITION BY ab.account_key 
--         ORDER BY ab.time_key
--     ) AS running_balance
-- FROM FACT_Account_Balance ab
-- ORDER BY ab.account_key, ab.time_key;


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)

-- ❌ SYNTAX-FEHLER (Score: 10/100):
--    WINDOW Syntax KOMPLETT FALSCH!
--    WINDOW Klausel kann KEINE Subquery enthalten!
--    Model verwechselt WINDOW mit CTE oder Subquery!
--    SOLLTE: AVG() OVER (PARTITION BY customer_key) verwenden

SELECT 
    t.transaction_id,
    t.customer_key,
    t.transaction_type,
    t.amount,
    t.transaction_status
FROM 
    FACT_Transaction t
WINDOW 
    avg_amount AS (
        SELECT 
            customer_key,
            AVG(amount) AS avg_amount
        FROM 
            FACT_Transaction
        GROUP BY 
            customer_key
    )
WHERE 
    t.amount > 3 * (SELECT avg_amount FROM avg_amount WHERE avg_amount.customer_key = t.customer_key);

-- KORREKTE LÖSUNG:
-- WITH customer_avg AS (
--     SELECT 
--         transaction_id,
--         customer_key,
--         transaction_type,
--         amount,
--         transaction_status,
--         AVG(amount) OVER (PARTITION BY customer_key) AS avg_customer_amount
--     FROM FACT_Transaction
-- )
-- SELECT *
-- FROM customer_avg
-- WHERE amount > 3 * avg_customer_amount;


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)

SELECT 
    c.customer_segment,
    c.customer_name,
    DENSE_RANK() OVER (PARTITION BY c.customer_segment ORDER BY SUM(f.amount) DESC) AS total_transaction_rank
FROM 
    DIM_Customer c
JOIN 
    FACT_Transaction f ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_segment, c.customer_name;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)

-- ❌ FAILED (Score: 25/100):
--    FEHLT: Window Function mit ROWS BETWEEN!
--    Diese Query berechnet nur AVG() über 7-Tage-Zeitraum, nicht gleitend!
--    WHERE filter schränkt nur Zeitraum ein, macht aber keinen Moving Average!
--    SOLLTE: ROWS BETWEEN 6 PRECEDING AND CURRENT ROW

SELECT 
    a.account_key,
    AVG(fab.daily_change) AS average_daily_change_7_days
FROM 
    FACT_Account_Balance fab
JOIN 
    DIM_Account a ON fab.account_key = a.account_key
JOIN 
    DIM_Time t ON fab.time_key = t.time_key
WHERE 
    t.full_date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 
    a.account_key;

-- KORREKTE LÖSUNG:
-- SELECT 
--     a.account_key,
--     t.full_date,
--     fab.daily_change,
--     AVG(fab.daily_change) OVER (
--         PARTITION BY a.account_key 
--         ORDER BY t.full_date 
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS moving_avg_7_days
-- FROM FACT_Account_Balance fab
-- JOIN DIM_Account a ON fab.account_key = a.account_key
-- JOIN DIM_Time t ON fab.time_key = t.time_key
-- ORDER BY a.account_key, t.full_date;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten

-- ⚠️ TEILWEISE KORREKT (Score: 60/100):
--    FEHLT: Gruppierung nach Tag (time_key)!
--    Diese Query zählt über ALLE Tage, nicht PRO Tag!
--    SOLLTE: GROUP BY customer_key, time_key

SELECT 
    c.customer_name
FROM 
    DIM_Customer c
JOIN 
    FACT_Transaction ft ON c.customer_key = ft.customer_key
WHERE 
    ft.amount > 10000
GROUP BY 
    c.customer_key, c.customer_name
HAVING 
    COUNT(ft.transaction_id) > 3;

-- KORREKTE LÖSUNG:
-- SELECT 
--     c.customer_name,
--     t.full_date,
--     COUNT(ft.transaction_id) AS transaction_count
-- FROM DIM_Customer c
-- JOIN FACT_Transaction ft ON c.customer_key = ft.customer_key
-- JOIN DIM_Time t ON ft.time_key = t.time_key
-- WHERE ft.amount > 10000
-- GROUP BY c.customer_key, c.customer_name, t.full_date
-- HAVING COUNT(ft.transaction_id) > 3;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEINE Query generieren!

-- KORREKTE LÖSUNG:
-- WITH weekly_transactions AS (
--     SELECT 
--         account_key,
--         t.week,
--         t.year,
--         SUM(amount) AS weekly_amount
--     FROM FACT_Transaction ft
--     JOIN DIM_Time t ON ft.time_key = t.time_key
--     GROUP BY account_key, t.week, t.year
-- ),
-- account_avg AS (
--     SELECT 
--         account_key,
--         AVG(weekly_amount) AS avg_weekly_amount
--     FROM weekly_transactions
--     GROUP BY account_key
-- )
-- SELECT 
--     wt.account_key,
--     wt.week,
--     wt.year,
--     wt.weekly_amount,
--     aa.avg_weekly_amount
-- FROM weekly_transactions wt
-- JOIN account_avg aa ON wt.account_key = aa.account_key
-- WHERE wt.weekly_amount > 10 * aa.avg_weekly_amount;

-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden

SELECT 
    t.transaction_id,
    t.amount,
    c.customer_name,
    AVG(t.amount) OVER (PARTITION BY t.customer_key) AS average_transaction_amount
FROM 
    FACT_Transaction t
JOIN 
    DIM_Customer c ON t.customer_key = c.customer_key
WHERE 
    t.is_suspicious = TRUE;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)

-- ❌ SYNTAX-FEHLER (Score: 40/100):
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    PostgreSQL: GROUP BY ROLLUP(...)

SELECT 
    customer_segment,
    account_type,
    transaction_type,
    SUM(amount) AS transaction_volume
FROM 
    DIM_Customer
JOIN 
    FACT_Transaction ON DIM_Customer.customer_key = FACT_Transaction.customer_key
JOIN 
    DIM_Account ON FACT_Transaction.account_key = DIM_Account.account_key
GROUP BY 
    customer_segment, 
    account_type, 
    transaction_type WITH ROLLUP;

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     customer_segment,
--     account_type,
--     transaction_type,
--     SUM(amount) AS transaction_volume
-- FROM DIM_Customer
-- JOIN FACT_Transaction ON DIM_Customer.customer_key = FACT_Transaction.customer_key
-- JOIN DIM_Account ON FACT_Transaction.account_key = DIM_Account.account_key
-- GROUP BY ROLLUP(customer_segment, account_type, transaction_type)
-- ORDER BY customer_segment NULLS LAST, account_type NULLS LAST, transaction_type NULLS LAST;


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)

-- ❌ SYNTAX-FEHLER (Score: 40/100):
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    PostgreSQL: GROUP BY ROLLUP(...)

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
    t.year, t.quarter, t.month WITH ROLLUP;

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     t.year,
--     t.quarter,
--     t.month,
--     SUM(f.fee) AS total_fees
-- FROM FACT_Transaction f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- GROUP BY ROLLUP(t.year, t.quarter, t.month)
-- ORDER BY t.year NULLS LAST, t.quarter NULLS LAST, t.month NULLS LAST;


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)

-- ❌ FAILED (Score: 40/100):
--    FEHLT: GROUPING() Funktion!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    Die Aufgabe verlangt EXPLIZIT die GROUPING() Funktion!

SELECT 
    account_category,
    account_type,
    AVG(closing_balance) AS avg_balance
FROM 
    FACT_Account_Balance
JOIN 
    DIM_Account ON FACT_Account_Balance.account_key = DIM_Account.account_key
GROUP BY 
    account_category, 
    account_type 
WITH ROLLUP;

-- KORREKTE LÖSUNG (PostgreSQL):
-- SELECT 
--     account_category,
--     account_type,
--     AVG(closing_balance) AS avg_balance,
--     GROUPING(account_category) AS is_category_subtotal,
--     GROUPING(account_type) AS is_type_subtotal,
--     CASE 
--         WHEN GROUPING(account_category) = 1 THEN 'GRAND TOTAL'
--         WHEN GROUPING(account_type) = 1 THEN 'Category Subtotal'
--         ELSE 'Detail'
--     END AS aggregation_level
-- FROM FACT_Account_Balance
-- JOIN DIM_Account ON FACT_Account_Balance.account_key = DIM_Account.account_key
-- GROUP BY ROLLUP(account_category, account_type)
-- ORDER BY account_category NULLS LAST, account_type NULLS LAST;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 46.7/100 ⭐⭐
-- SUCCESS RATE: 25% (3/12 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1:  100/100 - Perfekt (Multi-Fact JOIN)
--   ✅ Aufgabe 2:  100/100 - Perfekt (Aggregation über beide Facts)
--   ❌ Aufgabe 3:   30/100 - Kein Window Function (nur closing_balance)
--   ❌ Aufgabe 4:   10/100 - WINDOW Syntax komplett falsch!
--   ✅ Aufgabe 5:  100/100 - Perfekt (DENSE_RANK mit PARTITION BY)
--   ❌ Aufgabe 6:   25/100 - Kein ROWS BETWEEN (nur WHERE filter)
--   ⚠️ Aufgabe 7:   60/100 - Fehlt time_key Gruppierung (zählt über alle Tage)
--   ❌ Aufgabe 8:    0/100 - NICHT generiert!
--   ✅ Aufgabe 9:  100/100 - Perfekt (Window Function mit PARTITION BY)
--   ❌ Aufgabe 10:  40/100 - MySQL Syntax (WITH ROLLUP)
--   ❌ Aufgabe 11:  40/100 - MySQL Syntax (WITH ROLLUP)
--   ❌ Aufgabe 12:  40/100 - Fehlt GROUPING() + MySQL Syntax
--
-- STÄRKEN:
--   + Multi-Fact JOINs korrekt verstanden
--   + Einfache Window Functions (DENSE_RANK) mit PARTITION BY korrekt
--   + Aggregationen über mehrere Fact-Tabellen korrekt
--   + PARTITION BY bei einfachen Rankings korrekt
--
-- SCHWÄCHEN:
--   - ROWS BETWEEN für Moving Averages: NICHT VERSTANDEN!
--   - Running Balance ohne SUM OVER
--   - WINDOW Klausel komplett missverstanden (versucht Subquery!)
--   - Gruppierung nach Zeit vergessen (PRO Tag)
--   - MySQL vs PostgreSQL Syntax-Verwechslungen bei ROLLUP
--
-- KRITISCHE FEHLER:
--   ⚠️ WINDOW Klausel Syntax: KOMPLETT FALSCH (Subquery statt Window Definition)!
--   ⚠️ ROWS BETWEEN: NICHT VERSTANDEN!
--   ⚠️ ROLLUP: Inkonsistent (MySQL Syntax)
--   ⚠️ GROUPING(): NICHT BEKANNT
--
-- EMPFEHLUNG: ⚠️ BEDINGT geeignet für Multi-Fact Analytics
--              Nur für einfache JOINs und Rankings verwendbar!
--              NICHT für Moving Averages, ROLLUP oder komplexe Window Functions!
-- ============================================================================
