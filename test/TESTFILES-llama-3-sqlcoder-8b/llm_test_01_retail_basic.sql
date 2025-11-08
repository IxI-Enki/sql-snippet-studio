-- ============================================================================
-- TEST 1: RETAIL SALES - BASIC STAR-SCHEMA
-- ============================================================================
-- Domain: Einzelhandel (Verkauf von Produkten)
-- Complexity: 🟢 Beginner
-- Focus: Grundlegende Star-Schema Struktur, einfache Joins
-- Test Coverage: Star-Schema Basics, Simple Aggregations, JOINs
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Query zeigt nur 3 Spalten statt "alle Verkäufe" - fehlt sale_id, time_key, quantity, etc.
-- Bewertung: Funktioniert, aber unvollständig für "alle Verkäufe"

SELECT f.total_amount, d.product_name, c.customer_name FROM FACT_Sales f JOIN DIM_Product d ON f.product_key = d.product_key JOIN DIM_Customer c ON f.customer_key = c.customer_key;

-- ✅ KORRIGIERT: Vollständige Verkaufsinformationen
-- SELECT 
--     f.sale_id,
--     f.time_key,
--     p.product_name,
--     c.customer_name,
--     f.quantity,
--     f.unit_price,
--     f.discount_percent,
--     f.total_amount
-- FROM FACT_Sales f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- JOIN DIM_Customer c ON f.customer_key = c.customer_key;



-- Aufgabe 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Zeigt nur customer_key - sollte auch customer_name für Lesbarkeit zeigen
-- Bewertung: Technisch korrekt, aber unvollständig

SELECT c.customer_key, SUM(f.total_amount) AS total_sales FROM FACT_Sales f JOIN DIM_Customer c ON f.customer_key = c.customer_key GROUP BY c.customer_key ORDER BY total_sales DESC;

-- ✅ KORRIGIERT: Mit Kundenname für bessere Lesbarkeit
-- SELECT 
--     c.customer_key,
--     c.customer_name,
--     SUM(f.total_amount) AS total_sales
-- FROM FACT_Sales f
-- JOIN DIM_Customer c ON f.customer_key = c.customer_key
-- GROUP BY c.customer_key, c.customer_name
-- ORDER BY total_sales DESC;


-- Aufgabe 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: ORDER BY month_name sortiert ALPHABETISCH (April, August, ...) statt CHRONOLOGISCH!
-- Bewertung: Aggregation korrekt, aber falsche Sortierung

SELECT d.month_name, SUM(f.total_amount) AS total_sales FROM FACT_Sales f JOIN DIM_Time d ON f.time_key = d.time_key WHERE d.year = 2024 GROUP BY d.month_name ORDER BY d.month_name NULLS LAST;

-- ✅ KORRIGIERT: Chronologische Sortierung nach Monatsnummer
-- SELECT 
--     d.month_name,
--     SUM(f.total_amount) AS total_sales
-- FROM FACT_Sales f
-- JOIN DIM_Time d ON f.time_key = d.time_key
-- WHERE d.year = 2024
-- GROUP BY d.month, d.month_name
-- ORDER BY d.month;


-- Aufgabe 4: Finde die Top 5 meistverkauften Produkte nach Menge
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! GROUP BY, SUM, ORDER BY, LIMIT korrekt

SELECT p.product_name, SUM(f.quantity) AS total_quantity FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key GROUP BY p.product_name ORDER BY total_quantity DESC NULLS LAST LIMIT 5;


-- Aufgabe 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! AVG, GROUP BY korrekt

SELECT p.category, AVG(f.total_amount) AS average_order_value FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key GROUP BY p.category;


-- Aufgabe 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben
-- Status: ❌ FALSCH
-- Problem 1: WHERE f.total_amount > 1000 prüft EINZELNE Verkäufe, nicht GESAMTUMSATZ pro Kunde!
-- Problem 2: Zeigt Duplikate wenn Kunde mehrere Verkäufe über 1000 hat
-- Bewertung: Falsche Interpretation der Aufgabe

SELECT c.customer_key, c.customer_name FROM DIM_Customer c JOIN FACT_Sales f ON c.customer_key = f.customer_key WHERE f.total_amount > 1000;

-- ✅ KORRIGIERT: Kunden mit GESAMTUMSATZ über 1000
-- SELECT 
--     c.customer_key,
--     c.customer_name,
--     SUM(f.total_amount) AS total_revenue
-- FROM DIM_Customer c
-- JOIN FACT_Sales f ON c.customer_key = f.customer_key
-- GROUP BY c.customer_key, c.customer_name
-- HAVING SUM(f.total_amount) > 1000;


-- Aufgabe 7: Berechne den Umsatz pro Land (verwende DIM_Customer)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! JOIN, GROUP BY, SUM, ORDER BY korrekt

SELECT c.country, SUM(f.total_amount) AS total_revenue FROM FACT_Sales f JOIN DIM_Customer c ON f.customer_key = c.customer_key GROUP BY c.country ORDER BY total_revenue DESC NULLS LAST;


-- Aufgabe 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent
-- Status: ❌ FALSCH
-- Problem: discount_percent ist DECIMAL(5,2), also ist 10% = 10.00, NICHT 0.1!
-- Bewertung: Falsches Verständnis des Datentyps (sollte > 10 sein, nicht > 0.1)

SELECT f.sale_id, f.product_key, f.customer_key, f.quantity, f.unit_price, f.discount_percent, f.total_amount FROM FACT_Sales f WHERE f.discount_percent > 0.1;

-- ✅ KORRIGIERT: Korrekte Prozent-Prüfung
-- SELECT 
--     f.sale_id,
--     f.product_key,
--     f.customer_key,
--     f.quantity,
--     f.unit_price,
--     f.discount_percent,
--     f.total_amount
-- FROM FACT_Sales f
-- WHERE f.discount_percent > 10;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 90-100 (Basic queries, straightforward JOINs)
-- Parser Challenge: Low (straightforward responses expected)
-- Model Compatibility: ALL (beginner-friendly)
-- ============================================================================
