-- ============================================================================
-- TEST 1: RETAIL SALES - BASIC STAR-SCHEMA
-- ============================================================================
-- Domain: Einzelhandel (Verkauf von Produkten)
-- Complexity: 🟢 Beginner
-- Focus: Grundlegende Star-Schema Struktur, einfache Joins
-- Test Coverage: Star-Schema Basics, Simple Aggregations, JOINs
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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

SELECT f.sale_id, p.product_name, c.customer_name
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Customer c ON f.customer_key = c.customer_key;



-- Aufgabe 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)
-- ✅ KORREKT

SELECT c.customer_name, SUM(fs.total_amount) AS total_revenue
FROM FACT_Sales fs
JOIN DIM_Customer c ON fs.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY total_revenue DESC;


-- Aufgabe 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024
-- ❌ FEHLER: ORDER BY t.month ist problematisch - month ist INT, aber month_name ist im SELECT!

SELECT 
    t.month_name,
    SUM(fs.total_amount) AS total_revenue
FROM 
    FACT_Sales fs
JOIN 
    DIM_Time t ON fs.time_key = t.time_key
WHERE 
    t.year = 2024
GROUP BY 
    t.month_name
ORDER BY 
    t.month;

-- KORREKTUR: ORDER BY sollte t.month sein (ist ja auch im Schema), ABER month_name fehlt in GROUP BY für Sortierung!
-- Bessere Lösung:
-- SELECT 
--     t.month_name,
--     SUM(fs.total_amount) AS total_revenue
-- FROM 
--     FACT_Sales fs
-- JOIN 
--     DIM_Time t ON fs.time_key = t.time_key
-- WHERE 
--     t.year = 2024
-- GROUP BY 
--     t.month, t.month_name
-- ORDER BY 
--     t.month;


-- Aufgabe 4: Finde die Top 5 meistverkauften Produkte nach Menge
-- ✅ KORREKT

SELECT p.product_name, SUM(fs.quantity) AS total_quantity
FROM FACT_Sales fs
JOIN DIM_Product p ON fs.product_key = p.product_key
GROUP BY p.product_key, p.product_name
ORDER BY total_quantity DESC
LIMIT 5;


-- Aufgabe 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie
-- ✅ KORREKT

SELECT p.category, AVG(fs.total_amount) AS average_order_value
FROM FACT_Sales fs
JOIN DIM_Product p ON fs.product_key = p.product_key
GROUP BY p.category;


-- Aufgabe 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben
-- ✅ KORREKT

SELECT c.customer_name, SUM(fs.total_amount) AS total_sales
FROM DIM_Customer c
JOIN FACT_Sales fs ON c.customer_key = fs.customer_key
GROUP BY c.customer_key, c.customer_name
HAVING SUM(fs.total_amount) > 1000;


-- Aufgabe 7: Berechne den Umsatz pro Land (verwende DIM_Customer)
-- ✅ KORREKT

SELECT c.country, SUM(fs.total_amount) AS total_revenue
FROM FACT_Sales fs
JOIN DIM_Customer c ON fs.customer_key = c.customer_key
GROUP BY c.country;


-- Aufgabe 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent
-- ✅ KORREKT

SELECT * FROM FACT_Sales WHERE discount_percent > 10;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 93.8/100
-- SUCCESS RATE: 7/8 (87.5%)

-- BREAKDOWN:
-- ✅ Korrekt:  7 (Tasks 1, 2, 4, 5, 6, 7, 8)
-- ⚠️ Teilweise: 0
-- ❌ Fehler:   1 (Task 3)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Alle Basic JOINs perfekt
-- + GROUP BY und HAVING korrekt
-- + Aggregationen (SUM, AVG) korrekt
-- + WHERE Filter korrekt
-- + ORDER BY meist korrekt

-- WEAKNESSES:
-- - Task 3: ORDER BY t.month ohne t.month im GROUP BY (kann zu Sortier-Problemen führen)

-- CRITICAL ERRORS:
-- - Task 3: Minor Issue - Sollte t.month auch im GROUP BY haben für korrekte Sortierung

-- RECOMMENDATION:
-- ✅ SEHR GUT für Basic SQL!
-- Score ist identisch mit qwen2.5-vl-7b (93.8%)
-- Model zeigt solide Basic SQL Kenntnisse

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 90-100 (Basic queries, straightforward JOINs)
-- Parser Challenge: Low (straightforward responses expected)
-- Model Compatibility: ALL (beginner-friendly)
-- ============================================================================
