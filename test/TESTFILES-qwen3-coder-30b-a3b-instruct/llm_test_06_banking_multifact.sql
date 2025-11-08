-- ============================================================================
-- TEST 6: BANKING - MULTI-FACT + WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Banking/Finance
-- Complexity: 🔴 Advanced
-- Focus: Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP
-- Test Coverage: Multi-Fact Schema, Advanced Analytics, Financial Calculations
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
    f.account_key,
    SUM(f.amount) AS total_transaction_amount,
    MAX(b.closing_balance) AS current_balance
FROM FACT_Transaction f
JOIN FACT_Account_Balance b ON f.account_key = b.account_key
GROUP BY f.account_key;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten

SELECT 
    c.customer_key,
    SUM(t.amount) AS total_transaction_amount,
    AVG(ab.closing_balance) AS average_account_balance
FROM DIM_Customer c
JOIN FACT_Transaction t ON c.customer_key = t.customer_key
JOIN FACT_Account_Balance ab ON c.customer_key = ab.customer_key
GROUP BY c.customer_key;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)

SELECT 
    ab.account_key,
    ab.time_key,
    ab.closing_balance,
    SUM(ab.daily_change) OVER (
        PARTITION BY ab.account_key 
        ORDER BY ab.time_key 
        ROWS UNBOUNDED PRECEDING
    ) AS running_balance
FROM FACT_Account_Balance ab
ORDER BY ab.account_key, ab.time_key;


-- Aufgabe 4: Identifiziere Transaktionen die mehr als das Dreifache des durchschnittlichen Transaktionsbetrags des Kunden betragen (verwende Window Functions)

SELECT 
    t.transaction_id,
    t.customer_key,
    t.amount,
    AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_transaction_amount
FROM 
    FACT_Transaction t
WHERE 
    t.amount > 3 * AVG(t.amount) OVER (PARTITION BY t.customer_key);


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)

SELECT 
    c.customer_key,
    c.customer_name,
    c.customer_segment,
    SUM(t.amount) AS total_transaction_volume,
    DENSE_RANK() OVER (PARTITION BY c.customer_segment ORDER BY SUM(t.amount) DESC) AS customer_rank_by_segment
FROM 
    DIM_Customer c
JOIN 
    FACT_Transaction t ON c.customer_key = t.customer_key
GROUP BY 
    c.customer_key, c.customer_name, c.customer_segment;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)

SELECT 
    account_key,
    AVG(daily_change) OVER (
        PARTITION BY account_key 
        ORDER BY time_key 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS avg_daily_change_7day
FROM FACT_Account_Balance
WHERE time_key IN (
    SELECT time_key 
    FROM DIM_Time 
    WHERE full_date >= CURRENT_DATE - INTERVAL '7 days'
)
ORDER BY account_key;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten

SELECT 
    c.customer_key,
    c.customer_name,
    t.full_date,
    COUNT(f.transaction_id) AS transaction_count
FROM FACT_Transaction f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE f.amount > 10000
GROUP BY c.customer_key, c.customer_name, t.full_date
HAVING COUNT(f.transaction_id) > 3;


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt

SELECT 
    a.account_key,
    t.full_date,
    SUM(f.amount) AS weekly_transaction_sum
FROM FACT_Transaction f
JOIN DIM_Account a ON f.account_key = a.account_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY a.account_key, t.full_date
HAVING SUM(f.amount) > (
    SELECT AVG(weekly_sum) * 10
    FROM (
        SELECT 
            account_key,
            DATE_TRUNC('week', full_date) AS week_start,
            SUM(amount) AS weekly_sum
        FROM FACT_Transaction f2
        JOIN DIM_Time t2 ON f2.time_key = t2.time_key
        GROUP BY account_key, DATE_TRUNC('week', full_date)
    ) weekly_averages
)
ORDER BY weekly_transaction_sum DESC;


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden

SELECT 
    t.transaction_id,
    t.amount,
    AVG(t.amount) OVER (PARTITION BY t.customer_key) AS avg_transaction_amount_per_customer
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
GROUP BY ROLLUP(c.customer_segment, a.account_type, t.transaction_type)
ORDER BY c.customer_segment, a.account_type, t.transaction_type;


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)

SELECT 
    t.year,
    t.quarter,
    t.month,
    SUM(f.amount) AS total_fees
FROM FACT_Transaction f
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY ROLLUP(t.year, t.quarter, t.month)
ORDER BY t.year, t.quarter, t.month;


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT 
    COALESCE(ac.account_category, 'Grand Total') AS account_category,
    COALESCE(ac.account_type, 'All Types') AS account_type,
    AVG(fab.closing_balance) AS avg_closing_balance
FROM FACT_Account_Balance fab
JOIN DIM_Account ac ON fab.account_key = ac.account_key
GROUP BY ROLLUP(ac.account_category, ac.account_type)
ORDER BY GROUPING(ac.account_category), GROUPING(ac.account_type);


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
