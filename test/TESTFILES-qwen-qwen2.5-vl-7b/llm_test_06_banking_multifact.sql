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

SELECT f1.account_key, SUM(f1.amount) AS total_transaction_amount, fb.closing_balance 
FROM FACT_Transaction f1 
JOIN FACT_Account_Balance fb ON f1.account_key = fb.account_key AND f1.time_key = fb.time_key 
GROUP BY f1.account_key;


-- Aufgabe 2: Berechne für jeden Kunden die Summe aller Transaktionen und den durchschnittlichen Kontostand über alle seine Konten

SELECT c.customer_name,
       SUM(f.transaction_amount) AS total_transaction_sum,
       AVG(fb.closing_balance) AS average_account_balance
FROM DIM_Customer c
JOIN FACT_Transaction f ON c.customer_key = f.customer_key
JOIN FACT_Account_Balance fb ON c.customer_key = fb.customer_key AND f.time_key = fb.time_key
GROUP BY c.customer_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (FINANCIAL ANALYTICS)
-- ============================================================================

-- Aufgabe 3: Berechne den laufenden Kontostand für jedes Konto über die Zeit (Running Balance mit Window Functions)

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

SELECT t.transaction_id, c.customer_name, t.amount 
FROM FACT_Transaction t 
JOIN DIM_Customer c ON t.customer_key = c.customer_key 
WHERE t.amount > 3 * (
    SELECT AVG(amount) 
    FROM FACT_Transaction 
    WHERE customer_key = t.customer_key
);


-- Aufgabe 5: Ranke Kunden nach ihrem Gesamttransaktionsvolumen innerhalb ihres Kundensegments (DENSE_RANK mit PARTITION BY segment)

SELECT customer_key, customer_segment, SUM(amount) AS total_transaction_volume,
       DENSE_RANK() OVER(PARTITION BY customer_segment ORDER BY SUM(amount)) as rank_within_segment
FROM FACT_Transaction ft
JOIN DIM_Customer dc ON ft.customer_key = dc.customer_key
GROUP BY customer_key, customer_segment
ORDER BY customer_segment, rank_within_segment;


-- Aufgabe 6: Berechne die durchschnittliche Kontostandsänderung der letzten 7 Tage für jedes Konto (7-Day Moving Average)

SELECT account_key, AVG(daily_change) AS avg_daily_change 
FROM FACT_Account_Balance 
WHERE time_key >= DATE_TRUNC('day', CURRENT_DATE - INTERVAL '7 days') 
GROUP BY account_key;


-- ============================================================================
-- TEST TASKS - SUSPICIOUS ACTIVITY DETECTION
-- ============================================================================

-- Aufgabe 7: Finde alle Kunden die mehr als 3 Transaktionen über 10000 Euro an einem Tag hatten

SELECT c.customer_name 
FROM DIM_Customer c 
JOIN FACT_Transaction t ON c.customer_key = t.customer_key 
WHERE t.transaction_amount > 10000 AND t.transaction_date IN (
    SELECT transaction_date 
    FROM FACT_Transaction 
    GROUP BY transaction_date 
    HAVING COUNT(*) > 3
);


-- Aufgabe 8: Identifiziere Konten bei denen die Summe der Transaktionen in einer Woche mehr als das Zehnfache des durchschnittlichen Wochenumsatzes beträgt

SELECT DISTINCT account_key 
FROM FACT_Transaction 
WHERE transaction_id IN (
    SELECT transaction_id 
    FROM FACT_Transaction 
    GROUP BY account_key, week(time_key) 
    HAVING SUM(amount) > 10 * AVG(SUM(amount)) OVER (PARTITION BY account_key)
);


-- Aufgabe 9: Zeige alle Transaktionen die als verdächtig markiert wurden zusammen mit dem durchschnittlichen Transaktionsbetrag des Kunden

SELECT t.transaction_id, c.customer_name, AVG(f.amount) AS average_transaction_amount 
FROM FACT_Transaction t 
JOIN DIM_Customer c ON t.customer_key = c.customer_key 
WHERE t.is_suspicious = TRUE 
GROUP BY t.transaction_id, c.customer_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 10: Berechne das Transaktionsvolumen mit hierarchischen Subtotals nach Kundensegment, Kontotyp und Transaktionstyp (verwende ROLLUP)

SELECT customer_segment, account_type, transaction_type, SUM(amount) AS total_amount 
FROM FACT_Transaction 
GROUP BY ROLLUP(customer_segment, account_type, transaction_type);;


-- Aufgabe 11: Erstelle einen Bericht der die Gesamtgebühren (fees) nach Jahr, Quartal und Monat mit Subtotals zeigt (ROLLUP)

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


-- Aufgabe 12: Berechne den durchschnittlichen Kontostand nach Kontokategorie und Kontotyp mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT account_category, account_type, AVG(closing_balance) AS average_balance FROM FACT_Account_Balance GROUP BY ROLLUP(account_category, account_type);


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
