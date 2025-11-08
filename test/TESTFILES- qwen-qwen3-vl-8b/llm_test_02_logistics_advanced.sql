-- ============================================================================
-- TEST 2: LOGISTICS - ADVANCED STAR-SCHEMA + MERGE + ETL
-- ============================================================================
-- Domain: Logistik (Lager, Lieferungen, Transportrouten)
-- Complexity: 🟡 Intermediate
-- Focus: Mehrere Dimensionen, Hierarchien, MERGE für Delta-Loading
-- Test Coverage: Advanced Star-Schema, MERGE, ETL, ROLLUP-ready Hierarchies
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

-- ============================================================================
-- SCHEMA: Logistics & Warehouse Data Warehouse
-- ============================================================================

CREATE TABLE DIM_Warehouse (
    warehouse_key SERIAL PRIMARY KEY,
    warehouse_name VARCHAR(100) NOT NULL,
    warehouse_code VARCHAR(20) UNIQUE,
    region VARCHAR(50),      -- Hierarchy Level 1
    country VARCHAR(50),     -- Hierarchy Level 2
    capacity INT,
    manager_name VARCHAR(100)
);

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    category VARCHAR(50),    -- Hierarchy Level 1
    subcategory VARCHAR(50), -- Hierarchy Level 2
    weight_kg DECIMAL(10,2),
    volume_m3 DECIMAL(10,3)
);

CREATE TABLE DIM_Supplier (
    supplier_key SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_code VARCHAR(20) UNIQUE,
    country VARCHAR(50),
    rating DECIMAL(3,2),
    contract_start_date DATE
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_name VARCHAR(20)
);

CREATE TABLE FACT_Delivery (
    delivery_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    warehouse_key INT REFERENCES DIM_Warehouse(warehouse_key),
    product_key INT REFERENCES DIM_Product(product_key),
    supplier_key INT REFERENCES DIM_Supplier(supplier_key),
    quantity_delivered INT,
    quantity_ordered INT,
    delivery_days INT,          -- Measure: How long did delivery take?
    on_time BOOLEAN,             -- Measure: Was delivery on time?
    cost DECIMAL(12,2)           -- Measure: Cost of delivery
);

-- ============================================================================
-- STAGING TABLE FOR ETL (MERGE)
-- ============================================================================

CREATE TABLE STG_Delivery (
    delivery_id INT,
    delivery_date DATE,
    warehouse_code VARCHAR(20),
    product_sku VARCHAR(50),
    supplier_code VARCHAR(20),
    quantity_delivered INT,
    quantity_ordered INT,
    delivery_days INT,
    on_time BOOLEAN,
    cost DECIMAL(12,2)
);

-- ============================================================================
-- TEST TASKS
-- ============================================================================

-- Aufgabe 1: Zeige alle Lieferungen mit Lager-, Produkt- und Lieferantendetails
-- ✅ KORREKT

SELECT 
    f.delivery_id,
    w.warehouse_name,
    w.warehouse_code,
    p.product_name,
    p.sku,
    s.supplier_name,
    s.supplier_code,
    f.quantity_delivered,
    f.quantity_ordered,
    f.delivery_days,
    f.on_time,
    f.cost
FROM FACT_Delivery f
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key;


-- Aufgabe 2: Berechne die durchschnittliche Lieferzeit in Tagen pro Lieferant
-- ✅ KORREKT

SELECT s.supplier_name, AVG(fd.delivery_days) AS avg_delivery_days
FROM DIM_Supplier s
JOIN FACT_Delivery fd ON s.supplier_key = fd.supplier_key
GROUP BY s.supplier_key, s.supplier_name;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)
-- ✅ KORREKT

SELECT * FROM FACT_Delivery WHERE on_time = false;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)
-- ✅ KORREKT

SELECT w.region, COUNT(f.delivery_id) AS delivery_count 
FROM FACT_Delivery f 
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key 
GROUP BY w.region;


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)
-- ❌ FEHLER: KOMPLETT ZERBROCHEN!
-- 1. Fehlt "MERGE INTO FACT_Delivery f USING (" am Anfang!
-- 2. Die SELECT Clause steht alleine ohne MERGE Kontext!
-- 3. ") s" ist da, aber ohne vorheriges "USING ("!

SELECT 
        d.delivery_id,
        d.delivery_date,
        d.warehouse_code,
        d.product_sku,
        d.supplier_code,
        d.quantity_delivered,
        d.quantity_ordered,
        d.delivery_days,
        d.on_time,
        d.cost
    FROM STG_Delivery d
) s
ON (
    f.delivery_id = s.delivery_id
)
WHEN MATCHED THEN
    UPDATE SET
        time_key = (SELECT time_key FROM DIM_Time WHERE full_date = s.delivery_date),
        warehouse_key = (SELECT warehouse_key FROM DIM_Warehouse WHERE warehouse_code = s.warehouse_code),
        product_key = (SELECT product_key FROM DIM_Product WHERE sku = s.product_sku),
        supplier_key = (SELECT supplier_key FROM DIM_Supplier WHERE supplier_code = s.supplier_code),
        quantity_delivered = s.quantity_delivered,
        quantity_ordered = s.quantity_ordered,
        delivery_days = s.delivery_days,
        on_time = s.on_time,
        cost = s.cost
WHEN NOT MATCHED THEN
    INSERT (
        delivery_id,
        time_key,
        warehouse_key,
        product_key,
        supplier_key,
        quantity_delivered,
        quantity_ordered,
        delivery_days,
        on_time,
        cost
    )
    VALUES (
        s.delivery_id,
        (SELECT time_key FROM DIM_Time WHERE full_date = s.delivery_date),
        (SELECT warehouse_key FROM DIM_Warehouse WHERE warehouse_code = s.warehouse_code),
        (SELECT product_key FROM DIM_Product WHERE sku = s.product_sku),
        (SELECT supplier_key FROM DIM_Supplier WHERE supplier_code = s.supplier_code),
        s.quantity_delivered,
        s.quantity_ordered,
        s.delivery_days,
        s.on_time,
        s.cost
    );

-- KORREKTUR:
-- MERGE INTO FACT_Delivery f
-- USING (
--     SELECT 
--         d.delivery_id,
--         d.delivery_date,
--         d.warehouse_code,
--         d.product_sku,
--         d.supplier_code,
--         d.quantity_delivered,
--         d.quantity_ordered,
--         d.delivery_days,
--         d.on_time,
--         d.cost
--     FROM STG_Delivery d
-- ) s
-- ON (f.delivery_id = s.delivery_id)
-- WHEN MATCHED THEN
--     UPDATE SET
--         time_key = (SELECT time_key FROM DIM_Time WHERE full_date = s.delivery_date),
--         warehouse_key = (SELECT warehouse_key FROM DIM_Warehouse WHERE warehouse_code = s.warehouse_code),
--         product_key = (SELECT product_key FROM DIM_Product WHERE sku = s.product_sku),
--         supplier_key = (SELECT supplier_key FROM DIM_Supplier WHERE supplier_code = s.supplier_code),
--         quantity_delivered = s.quantity_delivered,
--         quantity_ordered = s.quantity_ordered,
--         delivery_days = s.delivery_days,
--         on_time = s.on_time,
--         cost = s.cost
-- WHEN NOT MATCHED THEN
--     INSERT (
--         delivery_id, time_key, warehouse_key, product_key, supplier_key,
--         quantity_delivered, quantity_ordered, delivery_days, on_time, cost
--     )
--     VALUES (
--         s.delivery_id,
--         (SELECT time_key FROM DIM_Time WHERE full_date = s.delivery_date),
--         (SELECT warehouse_key FROM DIM_Warehouse WHERE warehouse_code = s.warehouse_code),
--         (SELECT product_key FROM DIM_Product WHERE sku = s.product_sku),
--         (SELECT supplier_key FROM DIM_Supplier WHERE supplier_code = s.supplier_code),
--         s.quantity_delivered, s.quantity_ordered, s.delivery_days, s.on_time, s.cost
--     );


-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie
-- ✅ KORREKT

SELECT w.warehouse_name, p.category, SUM(fd.quantity_delivered) AS total_quantity
FROM FACT_Delivery fd
JOIN DIM_Warehouse w ON fd.warehouse_key = w.warehouse_key
JOIN DIM_Product p ON fd.product_key = p.product_key
GROUP BY w.warehouse_name, p.category;


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate
-- ❌ FEHLER: Logik ist KOMPLETT FALSCH!
-- COUNT(*) * 100.0 / COUNT(*) ergibt IMMER 100%! Das ist keine Pünktlichkeitsrate!
-- WHERE fd.on_time = TRUE filtert NUR pünktliche Lieferungen, dann ist die Rate immer 100%!

SELECT s.supplier_name, COUNT(*) AS on_time_deliveries, COUNT(*) * 100.0 / COUNT(*) AS punctuality_rate
FROM FACT_Delivery fd
JOIN DIM_Supplier s ON fd.supplier_key = s.supplier_key
WHERE fd.on_time = TRUE
GROUP BY s.supplier_name
ORDER BY punctuality_rate DESC
LIMIT 3;

-- KORREKTUR:
-- SELECT 
--     s.supplier_name, 
--     COUNT(CASE WHEN fd.on_time = TRUE THEN 1 END) AS on_time_deliveries,
--     COUNT(*) AS total_deliveries,
--     ROUND(100.0 * COUNT(CASE WHEN fd.on_time = TRUE THEN 1 END) / COUNT(*), 2) AS punctuality_rate
-- FROM FACT_Delivery fd
-- JOIN DIM_Supplier s ON fd.supplier_key = s.supplier_key
-- GROUP BY s.supplier_name
-- ORDER BY punctuality_rate DESC
-- LIMIT 3;


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)
-- ❌ FEHLER: MySQL Syntax! "WITH ROLLUP" ist falsch für PostgreSQL!

SELECT 
    w.region,
    w.country,
    SUM(f.cost) AS total_cost
FROM 
    FACT_Delivery f
JOIN 
    DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
GROUP BY 
    w.region, w.country
WITH ROLLUP;

-- KORREKTUR (PostgreSQL):
-- SELECT 
--     w.region,
--     w.country,
--     SUM(f.cost) AS total_cost
-- FROM 
--     FACT_Delivery f
-- JOIN 
--     DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
-- GROUP BY 
--     ROLLUP(w.region, w.country)
-- ORDER BY 
--     w.region, w.country;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 62.5/100
-- SUCCESS RATE: 5/8 (62.5%)

-- BREAKDOWN:
-- ✅ Korrekt:  5 (Tasks 1, 2, 3, 4, 6)
-- ⚠️ Teilweise: 0
-- ❌ Fehler:   3 (Tasks 5, 7, 8)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Basic JOINs perfekt (Tasks 1, 2, 4, 6)
-- + Aggregationen korrekt
-- + WHERE Filter korrekt (Task 3)

-- WEAKNESSES:
-- - MERGE Statement zerbrochen (fehlt "MERGE INTO ... USING")
-- - Logik-Fehler bei Pünktlichkeitsrate (Task 7)
-- - ROLLUP Syntax falsch (MySQL statt PostgreSQL)

-- CRITICAL ERRORS:
-- - Task 5: MERGE Statement incomplete - fehlt "MERGE INTO FACT_Delivery f USING ("!
-- - Task 7: COUNT(*) / COUNT(*) = 100% ist keine Pünktlichkeitsrate!
-- - Task 8: "WITH ROLLUP" ist MySQL Syntax, nicht PostgreSQL!

-- RECOMMENDATION:
-- ⚠️ SCHWACH für Intermediate SQL!
-- Score ist deutlich schlechter als bei qwen2.5-vl-7b (75.0% → 62.5%)
-- MERGE, Logik und ROLLUP Syntax sind Schwachpunkte

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 80-95 (MERGE Statement kann komplex sein)
-- Parser Challenge: Medium (MERGE Syntax, Subqueries)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: MERGE Statement muss korrekt sein (WHEN MATCHED, WHEN NOT MATCHED)
-- ============================================================================
