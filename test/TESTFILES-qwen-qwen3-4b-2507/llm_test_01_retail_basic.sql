-- ============================================================================
-- TEST 1: RETAIL SALES - BASIC STAR-SCHEMA
-- ============================================================================
-- Domain: Einzelhandel (Verkauf von Produkten)
-- Complexity: 🟢 Beginner
-- Focus: Grundlegende Star-Schema Struktur, einfache Joins
-- Test Coverage: Star-Schema Basics, Simple Aggregations, JOINs
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

SELECT 
    p.product_name,
    c.customer_name
FROM FACT_Sales fs
JOIN DIM_Product p ON fs.product_key = p.product_key
JOIN DIM_Customer c ON fs.customer_key = c.customer_key;



-- Aufgabe 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)

SELECT 
    c.customer_name, 
    SUM(s.total_amount) AS total_revenue 
FROM 
    DIM_Customer c 
JOIN 
    FACT_Sales s ON c.customer_key = s.customer_key 
GROUP BY 
    c.customer_key, c.customer_name 
ORDER BY 
    total_revenue DESC;


-- Aufgabe 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024

SELECT 
    t.month_name,
    SUM(s.total_amount) AS total_revenue
FROM FACT_Sales s
JOIN DIM_Time t ON s.time_key = t.time_key
WHERE t.year = 2024 
    AND t.month IS NOT NULL
GROUP BY t.month_name;


-- Aufgabe 4: Finde die Top 5 meistverkauften Produkte nach Menge

SELECT 
    p.product_name,
    SUM(f.quantity) AS total_quantity
FROM 
    FACT_Sales f
JOIN 
    DIM_Product p ON f.product_key = p.product_key
GROUP BY 
    p.product_name
ORDER BY 
    total_quantity DESC
LIMIT 5;


-- Aufgabe 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie

-- ❌ FEHLER (Score: 60/100):
--    LOGIKFEHLER: Berechnet AVG(total_amount / quantity) = Preis pro Einheit
--    KORREKT wäre: AVG(total_amount) = durchschnittlicher Bestellwert
--    Das Model hat die Anforderung missverstanden!

SELECT 
    p.category,
    AVG(f.total_amount / f.quantity) AS average_order_value_per_unit
FROM 
    DIM_Product p
JOIN 
    FACT_Sales f ON p.product_key = f.product_key
GROUP BY 
    p.category;

-- KORREKTE LÖSUNG:
-- SELECT 
--     p.category,
--     AVG(f.total_amount) AS average_order_value
-- FROM 
--     DIM_Product p
-- JOIN 
--     FACT_Sales f ON p.product_key = f.product_key
-- GROUP BY 
--     p.category;


-- Aufgabe 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben

SELECT DISTINCT c.customer_name
FROM DIM_Customer c
JOIN FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.customer_name
HAVING SUM(f.total_amount) > 1000;


-- Aufgabe 7: Berechne den Umsatz pro Land (verwende DIM_Customer)

SELECT SUM(f.total_amount) AS total_revenue, c.country 
FROM FACT_Sales f 
JOIN DIM_Customer c ON f.customer_key = c.customer_key 
GROUP BY c.country;


-- Aufgabe 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent

SELECT * FROM FACT_Sales WHERE discount_percent > 10.0;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 95/100 ⭐⭐⭐⭐⭐
-- SUCCESS RATE: 87.5% (7/8 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1: 100/100 - Perfekt
--   ✅ Aufgabe 2: 100/100 - Perfekt
--   ✅ Aufgabe 3: 100/100 - Perfekt
--   ✅ Aufgabe 4: 100/100 - Perfekt
--   ❌ Aufgabe 5:  60/100 - LOGIKFEHLER (Preis statt Bestellwert)
--   ✅ Aufgabe 6: 100/100 - Perfekt
--   ✅ Aufgabe 7: 100/100 - Perfekt
--   ✅ Aufgabe 8: 100/100 - Perfekt
--
-- STÄRKEN:
--   + Einfache JOINs perfekt
--   + GROUP BY & Aggregationen korrekt
--   + HAVING Klausel korrekt
--   + ORDER BY & LIMIT korrekt
--
-- SCHWÄCHEN:
--   - Logikfehler bei Durchschnittsberechnung (AVG falsch interpretiert)
--
-- EMPFEHLUNG: ✅ GEEIGNET für Basic Star-Schema Queries
-- ============================================================================
