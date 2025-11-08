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


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten

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

SELECT 
    fb.time_key,
    fb.account_key,
    fb.customer_key,
    fb.opening_balance,
    fb.closing_balance,
    SUM(fb.closing_balance) OVER (PARTITION BY fb.account_key ORDER BY fb.time_key) AS running_balance
FROM FACT_Account_Balance fb
ORDER BY fb.account_key, fb.time_key;


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)

SELECT t.transaction_id, t.customer_key, t.amount, AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_customer_amount
FROM FACT_Transaction t
WHERE t.amount > (SELECT AVG(amount) * 3 FROM FACT_Transaction WHERE customer_key = t.customer_key);


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)

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


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten

SELECT c.customer_name, t.full_date, COUNT(*) AS transaction_count
FROM FACT_Transaction ft
JOIN DIM_Customer c ON ft.customer_key = c.customer_key
JOIN DIM_Time t ON ft.time_key = t.time_key
WHERE ft.amount > 10000
GROUP BY c.customer_key, c.customer_name, t.full_date
HAVING COUNT(*) > 3;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt

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


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden

SELECT t.transaction_id, t.customer_key, t.amount, AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_transaction_amount
FROM FACT_Transaction t
WHERE t.is_suspicious = TRUE;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)

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
