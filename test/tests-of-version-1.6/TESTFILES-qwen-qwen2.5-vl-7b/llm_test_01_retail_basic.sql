-- ============================================================================
-- TEST 1: RETAIL SALES - BASIC STAR-SCHEMA
-- ============================================================================
-- Domain: Einzelhandel (Verkauf von Produkten)
-- Complexity: 🟢 Beginner
-- Focus: Grundlegende Star-Schema Struktur, einfache Joins
-- Test Coverage: Star-Schema Basics, Simple Aggregations, JOINs
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

-- ============================================================================
-- SCHEMA: Retail Sales Data Warehouse
-- ============================================================================

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    brand VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    day_of_week INT,
    day_name VARCHAR(20)
);

CREATE TABLE FACT_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    product_key INT REFERENCES DIM_Product(product_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    total_amount DECIMAL(12,2)
);

-- ============================================================================
-- TEST TASKS
-- ============================================================================

-- Aufgabe 1: Zeige alle Verkäufe mit Produktnamen und Kundennamen
-- ✅ KORREKT

SELECT p.product_name, c.customer_name 
FROM FACT_Sales fs 
JOIN DIM_Product p ON fs.product_key = p.product_key 
JOIN DIM_Customer c ON fs.customer_key = c.customer_key;


-- Aufgabe 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)
-- ✅ KORREKT

SELECT c.customer_name, SUM(f.total_amount) AS total_sales
FROM DIM_Customer c
JOIN FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY c.customer_name
ORDER BY total_sales DESC;


-- Aufgabe 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024
-- ❌ FEHLER: SQLite Syntax (strftime) statt PostgreSQL (EXTRACT/year/month Spalten)

SELECT strftime('%Y', t.full_date) AS year, strftime('%m', t.full_date) AS month, SUM(f.total_amount) AS total_sales FROM DIM_Time t JOIN FACT_Sales f ON t.time_key = f.time_key WHERE strftime('%Y', t.full_date) = '2024' GROUP BY year, month;

-- KORREKTUR: Verwende DIM_Time Spalten direkt (year, month sind bereits vorhanden!)
-- SELECT t.year, t.month, t.month_name, SUM(f.total_amount) AS total_sales 
-- FROM DIM_Time t 
-- JOIN FACT_Sales f ON t.time_key = f.time_key 
-- WHERE t.year = 2024 
-- GROUP BY t.year, t.month, t.month_name 
-- ORDER BY t.month;


-- Aufgabe 4: Finde die Top 5 meistverkauften Produkte nach Menge
-- ✅ KORREKT

SELECT product_name, SUM(quantity) AS total_quantity_sold 
FROM FACT_Sales fs JOIN DIM_Product dp ON fs.product_key = dp.product_key 
GROUP BY product_name 
ORDER BY total_quantity_sold DESC 
LIMIT 5;


-- Aufgabe 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie
-- ✅ KORREKT

SELECT AVG(total_amount) AS average_order_value_per_category, category 
FROM FACT_Sales fs 
JOIN DIM_Product dp ON fs.product_key = dp.product_key 
GROUP BY category;


-- Aufgabe 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben
-- ✅ KORREKT

SELECT c.customer_name 
FROM DIM_Customer c 
JOIN FACT_Sales fs ON c.customer_key = fs.customer_key 
GROUP BY c.customer_name 
HAVING SUM(fs.total_amount) > 1000;


-- Aufgabe 7: Berechne den Umsatz pro Land (verwende DIM_Customer)
-- ✅ KORREKT (LEFT JOIN ist sogar besser!)

SELECT c.country, SUM(f.total_amount) AS total_sales FROM DIM_Customer c LEFT JOIN FACT_Sales f ON c.customer_key = f.customer_key GROUP BY c.country;


-- Aufgabe 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent
-- ✅ KORREKT

SELECT * FROM FACT_Sales WHERE discount_percent > 10;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 87.5/100
-- SUCCESS RATE: 7/8 (87.5%)

-- BREAKDOWN:
-- ✅ Korrekt:  7 (Tasks 1, 2, 4, 5, 6, 7, 8)
-- ❌ Fehler:   1 (Task 3 - SQLite Syntax)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Perfekte JOINs (alle Tabellen korrekt verknüpft)
-- + Korrekte Aggregationen (SUM, AVG, GROUP BY, HAVING)
-- + Gute Sortierung (ORDER BY DESC)
-- + LIMIT richtig verwendet
-- + LEFT JOIN für bessere Abdeckung (Task 7)

-- WEAKNESSES:
-- - SQLite Syntax statt PostgreSQL (strftime vs. EXTRACT/DIM_Time Spalten)
-- - Nicht alle DIM_Time Spalten genutzt (year, month sind vorhanden!)

-- CRITICAL ERRORS:
-- - Task 3: strftime() ist SQLite, nicht PostgreSQL!

-- RECOMMENDATION:
-- ✅ SEHR GUT für Basic Level!
-- Das 7B Model zeigt deutlich bessere Performance als das 4B Model (87.5% vs. ???%).
-- SQLite Syntax ist der einzige Fehler - ansonsten perfekt!

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 90-100 (Basic queries, straightforward JOINs)
-- Parser Challenge: Low (straightforward responses expected)
-- Model Compatibility: ALL (beginner-friendly)
-- ============================================================================
