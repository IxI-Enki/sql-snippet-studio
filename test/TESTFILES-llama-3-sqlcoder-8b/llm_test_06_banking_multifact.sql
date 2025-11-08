-- ============================================================================
-- TEST 6: BANKING - MULTI-FACT + WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Banking/Finance
-- Complexity: 🔴 Advanced
-- Focus: Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP
-- Test Coverage: Multi-Fact Schema, Advanced Analytics, Financial Calculations
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: JOIN ohne time_key erzeugt Duplikate! Jede Transaction wird mit ALLEN Balances gejoint!
-- Bewertung: Aggregation korrekt, aber Duplikate durch falsche JOIN-Bedingung

SELECT f.account_key, SUM(f.amount) AS total_amount, ab.closing_balance FROM FACT_Transaction f JOIN FACT_Account_Balance ab ON f.account_key = ab.account_key GROUP BY f.account_key, ab.closing_balance ORDER BY f.account_key NULLS LAST;

-- ✅ KORRIGIERT: Nur aktuellster Balance pro Konto
-- WITH latest_balance AS (
--     SELECT 
--         account_key,
--         closing_balance,
--         ROW_NUMBER() OVER (PARTITION BY account_key ORDER BY time_key DESC) AS rn
--     FROM FACT_Account_Balance
-- )
-- SELECT 
--     f.account_key,
--     SUM(f.amount) AS total_transaction_amount,
--     lb.closing_balance AS current_balance
-- FROM FACT_Transaction f
-- LEFT JOIN latest_balance lb ON f.account_key = lb.account_key AND lb.rn = 1
-- GROUP BY f.account_key, lb.closing_balance
-- ORDER BY f.account_key;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Duplikate durch Multi-Fact JOIN ohne Aggregation davor!
-- Bewertung: Konzept richtig, aber braucht separate Aggregationen

SELECT c.customer_key, SUM(ft.amount) AS total_transaction_amount, AVG(ab.closing_balance) AS average_account_balance FROM DIM_Customer c JOIN FACT_Transaction ft ON c.customer_key = ft.customer_key JOIN FACT_Account_Balance ab ON c.customer_key = ab.customer_key GROUP BY c.customer_key;

-- ✅ KORRIGIERT: Separate Aggregationen für Multi-Fact
-- WITH customer_transactions AS (
--     SELECT 
--         customer_key,
--         SUM(amount) AS total_transaction_amount
--     FROM FACT_Transaction
--     GROUP BY customer_key
-- ),
-- customer_balances AS (
--     SELECT 
--         customer_key,
--         AVG(closing_balance) AS average_account_balance
--     FROM FACT_Account_Balance
--     GROUP BY customer_key
-- )
-- SELECT 
--     c.customer_key,
--     c.customer_name,
--     ct.total_transaction_amount,
--     cb.average_account_balance
-- FROM DIM_Customer c
-- LEFT JOIN customer_transactions ct ON c.customer_key = ct.customer_key
-- LEFT JOIN customer_balances cb ON c.customer_key = cb.customer_key;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)
-- Status: ❌ FALSCH
-- Problem: SUM(closing_balance) macht keinen Sinn! Sollte einfach closing_balance sein (ist schon Balance!)
-- Bewertung: Versteht "Running Balance" falsch - summiert Balances statt sie anzuzeigen

SELECT a.account_key, a.account_number, SUM(b.closing_balance) OVER (PARTITION BY a.account_key ORDER BY b.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS running_balance FROM DIM_Account a JOIN FACT_Account_Balance b ON a.account_key = b.account_key;

-- ✅ KORRIGIERT: Closing Balance IST schon der running balance
-- SELECT 
--     a.account_key,
--     a.account_number,
--     t.full_date,
--     b.closing_balance AS running_balance,
--     b.daily_change
-- FROM DIM_Account a
-- JOIN FACT_Account_Balance b ON a.account_key = b.account_key
-- JOIN DIM_Time t ON b.time_key = t.time_key
-- ORDER BY a.account_key, t.full_date;


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)
-- Status: ❌ FALSCH
-- Problem: Window Function in WHERE Clause ist UNGÜLTIG! Braucht CTE oder HAVING!
-- Bewertung: Syntaktisch falsch

SELECT ft.transaction_id FROM FACT_Transaction ft JOIN DIM_Customer dc ON ft.customer_key = dc.customer_key WHERE ft.amount > 3 * AVG(ft.amount) OVER (PARTITION BY dc.customer_key);

-- ✅ KORRIGIERT: Mit CTE für Window Function
-- WITH customer_avg AS (
--     SELECT 
--         transaction_id,
--         customer_key,
--         amount,
--         AVG(amount) OVER (PARTITION BY customer_key) AS avg_customer_amount
--     FROM FACT_Transaction
-- )
-- SELECT 
--     ca.transaction_id,
--     ca.customer_key,
--     ca.amount,
--     ca.avg_customer_amount
-- FROM customer_avg ca
-- WHERE ca.amount > 3 * ca.avg_customer_amount;


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)
-- Status: ❌ FALSCH
-- Problem: DENSE_RANK fehlt komplett! Nur GROUP BY + ORDER BY, kein Ranking!
-- Bewertung: Aufgabe nicht verstanden

SELECT c.customer_key, c.customer_segment, SUM(ft.amount) AS total_transaction_amount FROM FACT_Transaction ft JOIN DIM_Customer c ON ft.customer_key = c.customer_key GROUP BY c.customer_segment, c.customer_key ORDER BY total_transaction_amount DESC NULLS LAST;

-- ✅ KORRIGIERT: Mit DENSE_RANK
-- SELECT 
--     c.customer_key,
--     c.customer_name,
--     c.customer_segment,
--     SUM(ft.amount) AS total_transaction_amount,
--     DENSE_RANK() OVER (
--         PARTITION BY c.customer_segment 
--         ORDER BY SUM(ft.amount) DESC
--     ) AS segment_rank
-- FROM FACT_Transaction ft
-- JOIN DIM_Customer c ON ft.customer_key = c.customer_key
-- GROUP BY c.customer_key, c.customer_name, c.customer_segment
-- ORDER BY c.customer_segment, segment_rank;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)
-- Status: ❌ FALSCH
-- Problem 1: EXTRACT(time_key FROM ...) ist ungültige Syntax!
-- Problem 2: Keine Window Function! Sollte ROWS BETWEEN 6 PRECEDING verwenden!
-- Bewertung: Komplett falsch

SELECT ab.account_key, AVG(ab.daily_change) AS average_daily_change FROM FACT_Account_Balance ab WHERE ab.time_key >= EXTRACT(time_key FROM CURRENT_DATE - INTERVAL '1 week') GROUP BY ab.account_key ORDER BY ab.account_key NULLS LAST;

-- ✅ KORRIGIERT: 7-Day Moving Average mit Window Function
-- SELECT 
--     ab.account_key,
--     t.full_date,
--     ab.daily_change,
--     AVG(ab.daily_change) OVER (
--         PARTITION BY ab.account_key 
--         ORDER BY t.full_date
--         ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
--     ) AS seven_day_moving_avg
-- FROM FACT_Account_Balance ab
-- JOIN DIM_Time t ON ab.time_key = t.time_key
-- ORDER BY ab.account_key, t.full_date;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Gruppiert nicht nach TAG! Aufgabe verlangt "an einem Tag", aber query gruppiert nur nach Kunde!
-- Bewertung: Funktioniert, aber falsche Gruppierung

SELECT c.customer_name FROM FACT_Transaction ft JOIN DIM_Customer c ON ft.customer_key = c.customer_key WHERE ft.amount > 10000 GROUP BY c.customer_name HAVING COUNT(ft.transaction_id) > 3;

-- ✅ KORRIGIERT: Gruppierung nach Kunde UND Tag
-- SELECT 
--     c.customer_name,
--     t.full_date,
--     COUNT(ft.transaction_id) AS transactions_over_10k
-- FROM FACT_Transaction ft
-- JOIN DIM_Customer c ON ft.customer_key = c.customer_key
-- JOIN DIM_Time t ON ft.time_key = t.time_key
-- WHERE ft.amount > 10000
-- GROUP BY c.customer_name, t.full_date
-- HAVING COUNT(ft.transaction_id) > 3;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt
-- Status: ❌ FALSCH (KOMPLETT VERWORREN!)
-- Problem 1: time_key Berechnung macht keinen Sinn (YEAR * 52 + WEEK)!
-- Problem 2: Window Function in HAVING - syntaktisch ungültig!
-- Problem 3: AVG(SUM(...)) ist ungültig!
-- Bewertung: Logik komplett falsch

SELECT a.account_number FROM FACT_Transaction ft JOIN DIM_Account a ON ft.account_key = a.account_key WHERE ft.time_key BETWEEN (EXTRACT(YEAR FROM CURRENT_DATE) - 1)::INT * 52 + EXTRACT(WEEK FROM CURRENT_DATE) AND (EXTRACT(YEAR FROM CURRENT_DATE))::INT * 52 + EXTRACT(WEEK FROM CURRENT_DATE) GROUP BY a.account_number HAVING SUM(ft.amount) > 10 * AVG(SUM(ft.amount)) OVER (PARTITION BY ft.time_key);

-- ✅ KORRIGIERT: Korrekte Wochen-Analyse mit CTE
-- WITH weekly_amounts AS (
--     SELECT 
--         a.account_key,
--         a.account_number,
--         t.year,
--         t.week,
--         SUM(ft.amount) AS weekly_amount
--     FROM FACT_Transaction ft
--     JOIN DIM_Account a ON ft.account_key = a.account_key
--     JOIN DIM_Time t ON ft.time_key = t.time_key
--     GROUP BY a.account_key, a.account_number, t.year, t.week
-- ),
-- account_avg AS (
--     SELECT 
--         account_key,
--         AVG(weekly_amount) AS avg_weekly_amount
--     FROM weekly_amounts
--     GROUP BY account_key
-- )
-- SELECT 
--     wa.account_number,
--     wa.year,
--     wa.week,
--     wa.weekly_amount,
--     aa.avg_weekly_amount
-- FROM weekly_amounts wa
-- JOIN account_avg aa ON wa.account_key = aa.account_key
-- WHERE wa.weekly_amount > 10 * aa.avg_weekly_amount;


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden
-- Status: ❌ FALSCH
-- Problem: Gruppiert nach transaction_status statt nach Kunde! Zeigt nicht "Transaktionen", sondern Aggregate!
-- Bewertung: Falsche Spalten

SELECT ft.transaction_status, AVG(ft.amount) AS average_transaction_amount FROM FACT_Transaction ft WHERE ft.is_suspicious = TRUE GROUP BY ft.transaction_status;

-- ✅ KORRIGIERT: Zeigt Transaktionen mit Kunden-Durchschnitt
-- WITH customer_avg AS (
--     SELECT 
--         customer_key,
--         AVG(amount) AS avg_customer_amount
--     FROM FACT_Transaction
--     GROUP BY customer_key
-- )
-- SELECT 
--     ft.transaction_id,
--     c.customer_name,
--     ft.amount,
--     ca.avg_customer_amount,
--     ft.transaction_status
-- FROM FACT_Transaction ft
-- JOIN DIM_Customer c ON ft.customer_key = c.customer_key
-- JOIN customer_avg ca ON ft.customer_key = ca.customer_key
-- WHERE ft.is_suspicious = TRUE;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)
-- Status: ❌ FALSCH
-- Problem 1: t.transaction_type undefined! f.transaction_type sollte es sein!
-- Problem 2: JOIN zu FACT_Account_Balance macht keinen Sinn (nicht benötigt)!
-- Bewertung: Tabellen-Referenz falsch + unnötige JOINs

SELECT c.customer_segment, a.account_type, t.transaction_type, SUM(f.amount) AS total_transaction_amount FROM FACT_Transaction f JOIN DIM_Customer c ON f.customer_key = c.customer_key JOIN DIM_Account a ON f.account_key = a.account_key JOIN FACT_Account_Balance ab ON f.time_key = ab.time_key GROUP BY ROLLUP(c.customer_segment, a.account_type, t.transaction_type);

-- ✅ KORRIGIERT: Korrekte Spalten-Referenz
-- SELECT 
--     c.customer_segment,
--     a.account_type,
--     f.transaction_type,
--     SUM(f.amount) AS total_transaction_amount
-- FROM FACT_Transaction f
-- JOIN DIM_Customer c ON f.customer_key = c.customer_key
-- JOIN DIM_Account a ON f.account_key = a.account_key
-- GROUP BY ROLLUP(c.customer_segment, a.account_type, f.transaction_type)
-- ORDER BY 
--     c.customer_segment NULLS FIRST, 
--     a.account_type NULLS FIRST, 
--     f.transaction_type NULLS FIRST;


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)
-- Status: ❌ FALSCH
-- Problem 1: time_key::DATE ist ungültig (time_key ist INT, nicht DATE)!
-- Problem 2: Verwendet Window Function statt ROLLUP!
-- Problem 3: PARTITION BY in Aggregation macht keinen Sinn!
-- Bewertung: Komplett falsch - versteht ROLLUP nicht

SELECT DATE_TRUNC('year', ft.time_key::DATE) AS YEAR, DATE_TRUNC('quarter', ft.time_key::DATE) AS QUARTER, DATE_TRUNC('month', ft.time_key::DATE) AS MONTH, SUM(ft.fee) OVER (PARTITION BY DATE_TRUNC('year', ft.time_key::DATE), DATE_TRUNC('quarter', ft.time_key::DATE), DATE_TRUNC('month', ft.time_key::DATE)) AS total_fee FROM FACT_Transaction ft ORDER BY YEAR, QUARTER, MONTH;

-- ✅ KORRIGIERT: Mit ROLLUP und korrekter Tabellen-Referenz
-- SELECT 
--     t.year,
--     t.quarter,
--     t.month,
--     SUM(ft.fee) AS total_fees
-- FROM FACT_Transaction ft
-- JOIN DIM_Time t ON ft.time_key = t.time_key
-- GROUP BY ROLLUP(t.year, t.quarter, t.month)
-- ORDER BY 
--     t.year NULLS FIRST, 
--     t.quarter NULLS FIRST, 
--     t.month NULLS FIRST;


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: GROUPING() Funktion fehlt! Aufgabe verlangt GROUPING Funktion!
-- Bewertung: ROLLUP Syntax korrekt, aber GROUPING() fehlt

SELECT a.account_category, a.account_type, AVG(ab.closing_balance) AS average_balance FROM FACT_Account_Balance ab JOIN DIM_Account a ON ab.account_key = a.account_key GROUP BY ROLLUP(a.account_category, a.account_type);

-- ✅ KORRIGIERT: Mit GROUPING() Funktion
-- SELECT 
--     a.account_category,
--     a.account_type,
--     AVG(ab.closing_balance) AS average_balance,
--     GROUPING(a.account_category) AS is_category_total,
--     GROUPING(a.account_type) AS is_type_total
-- FROM FACT_Account_Balance ab
-- JOIN DIM_Account a ON ab.account_key = a.account_key
-- GROUP BY ROLLUP(a.account_category, a.account_type)
-- ORDER BY 
--     a.account_category NULLS FIRST, 
--     a.account_type NULLS FIRST;


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
