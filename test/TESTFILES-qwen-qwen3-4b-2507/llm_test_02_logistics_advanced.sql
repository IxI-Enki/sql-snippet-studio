-- ============================================================================
-- TEST 2: LOGISTICS - ADVANCED STAR-SCHEMA + MERGE + ETL
-- ============================================================================
-- Domain: Logistik (Lager, Lieferungen, Transportrouten)
-- Complexity: 🟡 Intermediate
-- Focus: Mehrere Dimensionen, Hierarchien, MERGE für Delta-Loading
-- Test Coverage: Advanced Star-Schema, MERGE, ETL, ROLLUP-ready Hierarchies
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

SELECT 
    f.delivery_id,
    w.warehouse_name,
    p.product_name,
    s.supplier_name,
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

-- ❌ FEHLER (Score: 40/100):
--    FEHLT: GROUP BY s.supplier_name
--    FEHLT: s.supplier_name im SELECT
--    Diese Query zeigt nur den GESAMTDURCHSCHNITT, nicht PRO Lieferant!

SELECT 
    AVG(d.delivery_days) AS average_delivery_days
FROM 
    FACT_Delivery d
JOIN 
    DIM_Supplier s ON d.supplier_key = s.supplier_key;

-- KORREKTE LÖSUNG:
-- SELECT 
--     s.supplier_name,
--     AVG(d.delivery_days) AS average_delivery_days
-- FROM 
--     FACT_Delivery d
-- JOIN 
--     DIM_Supplier s ON d.supplier_key = s.supplier_key
-- GROUP BY 
--     s.supplier_name;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)

SELECT * FROM FACT_Delivery WHERE on_time = false;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)

SELECT COUNT(f.delivery_id) AS delivery_count, dw.region 
FROM FACT_Delivery f 
JOIN DIM_Warehouse dw ON f.warehouse_key = dw.warehouse_key 
GROUP BY dw.region;


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement generieren!
--    Dies ist eine der komplexesten SQL-Operationen.

-- KORREKTE LÖSUNG (PostgreSQL):
-- INSERT INTO FACT_Delivery (
--     time_key, warehouse_key, product_key, supplier_key,
--     quantity_delivered, quantity_ordered, delivery_days, on_time, cost
-- )
-- SELECT 
--     (SELECT time_key FROM DIM_Time WHERE full_date = stg.delivery_date),
--     (SELECT warehouse_key FROM DIM_Warehouse WHERE warehouse_code = stg.warehouse_code),
--     (SELECT product_key FROM DIM_Product WHERE sku = stg.product_sku),
--     (SELECT supplier_key FROM DIM_Supplier WHERE supplier_code = stg.supplier_code),
--     stg.quantity_delivered, stg.quantity_ordered, stg.delivery_days, stg.on_time, stg.cost
-- FROM STG_Delivery stg
-- ON CONFLICT (delivery_id) DO UPDATE SET
--     quantity_delivered = EXCLUDED.quantity_delivered,
--     quantity_ordered = EXCLUDED.quantity_ordered,
--     delivery_days = EXCLUDED.delivery_days,
--     on_time = EXCLUDED.on_time,
--     cost = EXCLUDED.cost;

-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie

SELECT 
    w.warehouse_name,
    p.category AS product_category,
    SUM(f.quantity_delivered) AS total_quantity_delivered
FROM FACT_Delivery f
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY w.warehouse_name, p.category;


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate

SELECT 
    s.supplier_name,
    AVG(CASE WHEN d.on_time THEN 1 ELSE 0 END) AS on_time_rate
FROM 
    FACT_Delivery d
JOIN 
    DIM_Supplier s ON d.supplier_key = s.supplier_key
GROUP BY 
    s.supplier_name
ORDER BY 
    on_time_rate DESC
LIMIT 3;


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)

SELECT 
    w.region, 
    w.country, 
    SUM(f.cost) AS total_cost 
FROM FACT_Delivery f 
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key 
GROUP BY w.region, w.country 
ORDER BY w.region, w.country;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 80/100 ⭐⭐⭐⭐
-- SUCCESS RATE: 75% (6/8 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1: 100/100 - Perfekt
--   ❌ Aufgabe 2:  40/100 - Fehlt GROUP BY (zeigt nur Gesamtdurchschnitt)
--   ✅ Aufgabe 3: 100/100 - Perfekt
--   ✅ Aufgabe 4: 100/100 - Perfekt
--   ❌ Aufgabe 5:   0/100 - MERGE Statement NICHT generiert!
--   ✅ Aufgabe 6: 100/100 - Perfekt
--   ✅ Aufgabe 7: 100/100 - Perfekt (CASE WHEN für Rate)
--   ✅ Aufgabe 8: 100/100 - Perfekt
--
-- STÄRKEN:
--   + Multi-Table JOINs korrekt
--   + CASE WHEN für Berechnungen korrekt
--   + GROUP BY mit mehreren Spalten korrekt
--   + Hierarchien (Region/Country) verstanden
--
-- SCHWÄCHEN:
--   - GROUP BY vergessen bei Aggregation PRO X
--   - MERGE Statement zu komplex für dieses Model
--
-- EMPFEHLUNG: ⚠️ BEDINGT geeignet für Advanced Queries (MERGE nicht nutzbar)
-- ============================================================================
