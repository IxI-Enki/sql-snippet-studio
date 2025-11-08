-- ============================================================================
-- TEST 1: RETAIL SALES - BASIC STAR-SCHEMA
-- ============================================================================
-- Domain: Einzelhandel (Verkauf von Produkten)
-- Complexity: 🟢 Beginner
-- Focus: Grundlegende Star-Schema Struktur, einfache Joins
-- Test Coverage: Star-Schema Basics, Simple Aggregations, JOINs
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Alle relevanten Spalten, saubere JOINs

SELECT 
    fs.sale_id,
    dp.product_name,
    dc.customer_name,
    fs.quantity,
    fs.unit_price,
    fs.total_amount
FROM FACT_Sales fs
JOIN DIM_Product dp ON fs.product_key = dp.product_key
JOIN DIM_Customer dc ON fs.customer_key = dc.customer_key;



-- Aufgabe 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! GROUP BY mit customer_key + name korrekt

SELECT 
    c.customer_name,
    SUM(s.total_amount) AS total_revenue
FROM FACT_Sales s
JOIN DIM_Customer c ON s.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY total_revenue DESC;


-- Aufgabe 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! WHERE + GROUP BY + ORDER BY korrekt

SELECT 
    t.month_name,
    SUM(f.total_amount) AS total_revenue
FROM FACT_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.year = 2024
GROUP BY t.month_name, t.month
ORDER BY t.month;


-- Aufgabe 4: Finde die Top 5 meistverkauften Produkte nach Menge
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! GROUP BY + ORDER BY + LIMIT korrekt

SELECT p.product_name, SUM(f.quantity) AS total_quantity
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY p.product_key, p.product_name
ORDER BY total_quantity DESC
LIMIT 5;


-- Aufgabe 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! AVG + GROUP BY korrekt

SELECT 
    p.category,
    AVG(s.total_amount) AS avg_order_value
FROM FACT_Sales s
JOIN DIM_Product p ON s.product_key = p.product_key
GROUP BY p.category;


-- Aufgabe 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! GROUP BY + HAVING korrekt

SELECT c.customer_name, SUM(f.total_amount) AS total_revenue 
FROM FACT_Sales f 
JOIN DIM_Customer c ON f.customer_key = c.customer_key 
GROUP BY c.customer_key, c.customer_name 
HAVING SUM(f.total_amount) > 1000;


-- Aufgabe 7: Berechne den Umsatz pro Land (verwende DIM_Customer)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Simple Aggregation

SELECT c.country, SUM(s.total_amount) AS total_revenue 
FROM FACT_Sales s 
JOIN DIM_Customer c ON s.customer_key = c.customer_key 
GROUP BY c.country;


-- Aufgabe 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Simple WHERE Clause

SELECT * FROM FACT_Sales WHERE discount_percent > 10;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 90-100 (Basic queries, straightforward JOINs)
-- Parser Challenge: Low (straightforward responses expected)
-- Model Compatibility: ALL (beginner-friendly)
-- ============================================================================
