-- ============================================================================
-- TEST 2: LOGISTICS - ADVANCED STAR-SCHEMA + MERGE + ETL
-- ============================================================================
-- Domain: Logistik (Lager, Lieferungen, Transportrouten)
-- Complexity: 🟡 Intermediate
-- Focus: Mehrere Dimensionen, Hierarchien, MERGE für Delta-Loading
-- Test Coverage: Advanced Star-Schema, MERGE, ETL, ROLLUP-ready Hierarchies
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Alle relevanten Spalten, korrekte JOINs

SELECT f.delivery_id, d.warehouse_code, p.product_name, s.supplier_name, f.quantity_delivered, f.quantity_ordered, f.delivery_days, f.on_time, f.cost FROM FACT_Delivery f JOIN DIM_Warehouse d ON f.warehouse_key = d.warehouse_key JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key;


-- Aufgabe 2: Berechne die durchschnittliche Lieferzeit in Tagen pro Lieferant
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Zeigt nur supplier_key - sollte auch supplier_name für Lesbarkeit zeigen
-- Bewertung: Technisch korrekt, aber unvollständig

SELECT s.supplier_key, AVG(f.delivery_days) AS average_delivery_days FROM FACT_Delivery f JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key GROUP BY s.supplier_key ORDER BY s.supplier_key NULLS LAST;

-- ✅ KORRIGIERT: Mit Lieferantenname für bessere Lesbarkeit
-- SELECT 
--     s.supplier_key,
--     s.supplier_name,
--     AVG(f.delivery_days) AS average_delivery_days
-- FROM FACT_Delivery f
-- JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key
-- GROUP BY s.supplier_key, s.supplier_name
-- ORDER BY average_delivery_days;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Einfacher WHERE Filter auf BOOLEAN

SELECT * FROM FACT_Delivery WHERE on_time = FALSE;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)
-- Status: ❌ FALSCH
-- Problem: Gruppiert nach warehouse_key statt nach REGION! Aufgabe verlangt "pro Region"!
-- Bewertung: Falsche Gruppierung - zeigt Lager statt Regionen

SELECT d.warehouse_key, COUNT(f.delivery_id) AS delivery_count FROM FACT_Delivery f JOIN DIM_Warehouse d ON f.warehouse_key = d.warehouse_key GROUP BY d.warehouse_key ORDER BY d.warehouse_key NULLS LAST;

-- ✅ KORRIGIERT: Gruppierung nach Region (wie in Aufgabe gefordert)
-- SELECT 
--     d.region,
--     COUNT(f.delivery_id) AS delivery_count
-- FROM FACT_Delivery f
-- JOIN DIM_Warehouse d ON f.warehouse_key = d.warehouse_key
-- GROUP BY d.region
-- ORDER BY delivery_count DESC;


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)
-- Status: ❌ FALSCH (KEIN MERGE!)
-- Problem: Das ist nur ein SELECT Statement, KEIN MERGE! MERGE benötigt INSERT INTO ... ON CONFLICT!
-- Bewertung: Komplett falsch - keine MERGE Operation, nur Daten-Mapping

SELECT d.delivery_id, dw.warehouse_key, dp.product_key, ds.supplier_key, d.quantity_delivered, d.quantity_ordered, d.delivery_days, d.on_time, d.cost FROM STG_Delivery d JOIN DIM_Warehouse dw ON d.warehouse_code = dw.warehouse_code JOIN DIM_Product dp ON d.product_sku = dp.sku JOIN DIM_Supplier ds ON d.supplier_code = ds.supplier_code;

-- ✅ KORRIGIERT: Echter MERGE Statement (PostgreSQL ON CONFLICT Syntax)
-- INSERT INTO FACT_Delivery (
--     delivery_id, time_key, warehouse_key, product_key, supplier_key,
--     quantity_delivered, quantity_ordered, delivery_days, on_time, cost
-- )
-- SELECT 
--     s.delivery_id,
--     t.time_key,
--     w.warehouse_key,
--     p.product_key,
--     sup.supplier_key,
--     s.quantity_delivered,
--     s.quantity_ordered,
--     s.delivery_days,
--     s.on_time,
--     s.cost
-- FROM STG_Delivery s
-- JOIN DIM_Warehouse w ON s.warehouse_code = w.warehouse_code
-- JOIN DIM_Product p ON s.product_sku = p.sku
-- JOIN DIM_Supplier sup ON s.supplier_code = sup.supplier_code
-- JOIN DIM_Time t ON s.delivery_date = t.full_date
-- ON CONFLICT (delivery_id) 
-- DO UPDATE SET
--     quantity_delivered = EXCLUDED.quantity_delivered,
--     quantity_ordered = EXCLUDED.quantity_ordered,
--     delivery_days = EXCLUDED.delivery_days,
--     on_time = EXCLUDED.on_time,
--     cost = EXCLUDED.cost;


-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Zeigt nur warehouse_key - sollte auch warehouse_name/code zeigen
-- Bewertung: Technisch korrekt, aber unvollständig für Lesbarkeit

SELECT dw.warehouse_key, dp.category, SUM(fd.quantity_delivered) AS total_quantity FROM FACT_Delivery fd JOIN DIM_Warehouse dw ON fd.warehouse_key = dw.warehouse_key JOIN DIM_Product dp ON fd.product_key = dp.product_key GROUP BY dw.warehouse_key, dp.category;

-- ✅ KORRIGIERT: Mit Lager-Details
-- SELECT 
--     dw.warehouse_name,
--     dw.region,
--     dp.category,
--     SUM(fd.quantity_delivered) AS total_quantity
-- FROM FACT_Delivery fd
-- JOIN DIM_Warehouse dw ON fd.warehouse_key = dw.warehouse_key
-- JOIN DIM_Product dp ON fd.product_key = dp.product_key
-- GROUP BY dw.warehouse_name, dw.region, dp.category
-- ORDER BY dw.warehouse_name, dp.category;


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! BOOLEAN to FLOAT Cast + AVG + TOP 3 korrekt

SELECT s.supplier_name, AVG(f.on_time::FLOAT) AS punctuality_rate FROM DIM_Supplier s JOIN FACT_Delivery f ON s.supplier_key = f.supplier_key GROUP BY s.supplier_name ORDER BY punctuality_rate DESC NULLS LAST LIMIT 3;


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)
-- Status: ❌ FALSCH
-- Problem: Gruppiert nach warehouse_key/code statt nach REGION und LAND!
-- Bewertung: Falsche Gruppierungsebene - ignoriert hierarchische Struktur

SELECT d.warehouse_key, d.warehouse_code, SUM(f.cost) AS total_cost FROM FACT_Delivery f JOIN DIM_Warehouse d ON f.warehouse_key = d.warehouse_key GROUP BY d.warehouse_key, d.warehouse_code;

-- ✅ KORRIGIERT: Hierarchische Aggregation nach Region und Land
-- SELECT 
--     d.region,
--     d.country,
--     SUM(f.cost) AS total_cost
-- FROM FACT_Delivery f
-- JOIN DIM_Warehouse d ON f.warehouse_key = d.warehouse_key
-- GROUP BY d.region, d.country
-- ORDER BY d.region, d.country;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 80-95 (MERGE Statement kann komplex sein)
-- Parser Challenge: Medium (MERGE Syntax, Subqueries)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: MERGE Statement muss korrekt sein (WHEN MATCHED, WHEN NOT MATCHED)
-- ============================================================================
