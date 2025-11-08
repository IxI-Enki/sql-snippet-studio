-- ============================================================================
-- TEST 2: LOGISTICS - ADVANCED STAR-SCHEMA + MERGE + ETL
-- ============================================================================
-- Domain: Logistik (Lager, Lieferungen, Transportrouten)
-- Complexity: 🟡 Intermediate
-- Focus: Mehrere Dimensionen, Hierarchien, MERGE für Delta-Loading
-- Test Coverage: Advanced Star-Schema, MERGE, ETL, ROLLUP-ready Hierarchies
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
-- Bewertung: Perfekt! Alle relevanten Spalten, 3-fache JOINs korrekt

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! AVG + GROUP BY + ORDER BY korrekt

SELECT 
    ds.supplier_name,
    AVG(fd.delivery_days) AS avg_delivery_time_days
FROM FACT_Delivery fd
JOIN DIM_Supplier ds ON fd.supplier_key = ds.supplier_key
GROUP BY ds.supplier_name
ORDER BY avg_delivery_time_days;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Simple WHERE mit Boolean

SELECT * FROM FACT_Delivery WHERE on_time = FALSE;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! COUNT + GROUP BY korrekt

SELECT w.region, COUNT(f.delivery_id) AS delivery_count
FROM FACT_Delivery f
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
GROUP BY w.region;


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Fehlt "MERGE INTO FACT_Delivery fd USING (" am Anfang!
-- Bewertung: Logik + JOINs korrekt, aber Syntax unvollständig

-- 🚫 FEHLERHAFT (Oracle/SQL Server Syntax, fehlt MERGE Prefix):
SELECT 
        sd.delivery_id,
        dt.time_key,
        dw.warehouse_key,
        dp.product_key,
        ds.supplier_key,
        sd.quantity_delivered,
        sd.quantity_ordered,
        sd.delivery_days,
        sd.on_time,
        sd.cost
    FROM STG_Delivery sd
    JOIN DIM_Time dt ON dt.full_date = sd.delivery_date
    JOIN DIM_Warehouse dw ON dw.warehouse_code = sd.warehouse_code
    JOIN DIM_Product dp ON dp.sku = sd.product_sku
    JOIN DIM_Supplier ds ON ds.supplier_code = sd.supplier_code
) src ON (fd.delivery_id = src.delivery_id)
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
        src.delivery_id,
        src.time_key,
        src.warehouse_key,
        src.product_key,
        src.supplier_key,
        src.quantity_delivered,
        src.quantity_ordered,
        src.delivery_days,
        src.on_time,
        src.cost
    );

-- ✅ KORRIGIERT (PostgreSQL ON CONFLICT):
-- INSERT INTO FACT_Delivery (delivery_id, time_key, warehouse_key, product_key, supplier_key, quantity_delivered, quantity_ordered, delivery_days, on_time, cost)
-- SELECT 
--     sd.delivery_id,
--     dt.time_key,
--     dw.warehouse_key,
--     dp.product_key,
--     ds.supplier_key,
--     sd.quantity_delivered,
--     sd.quantity_ordered,
--     sd.delivery_days,
--     sd.on_time,
--     sd.cost
-- FROM STG_Delivery sd
-- JOIN DIM_Time dt ON dt.full_date = sd.delivery_date
-- JOIN DIM_Warehouse dw ON dw.warehouse_code = sd.warehouse_code
-- JOIN DIM_Product dp ON dp.sku = sd.product_sku
-- JOIN DIM_Supplier ds ON ds.supplier_code = sd.supplier_code
-- ON CONFLICT (delivery_id) DO NOTHING;

-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Aggregation + GROUP BY + ORDER BY korrekt

SELECT 
    w.warehouse_name,
    p.category,
    SUM(f.quantity_delivered) AS stock_level
FROM FACT_Delivery f
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY w.warehouse_name, p.category
ORDER BY w.warehouse_name, p.category;


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! CASE WHEN + Berechnung + LIMIT korrekt

SELECT 
    s.supplier_name,
    COUNT(*) AS total_deliveries,
    SUM(CASE WHEN f.on_time = TRUE THEN 1 ELSE 0 END) AS on_time_deliveries,
    ROUND(SUM(CASE WHEN f.on_time = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS punctuality_rate
FROM FACT_Delivery f
JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key
GROUP BY s.supplier_key, s.supplier_name
ORDER BY punctuality_rate DESC
LIMIT 3;


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROLLUP Syntax korrekt

SELECT 
    w.region,
    w.country,
    SUM(f.cost) AS total_cost
FROM FACT_Delivery f
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
GROUP BY ROLLUP(w.region, w.country);


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 80-95 (MERGE Statement kann komplex sein)
-- Parser Challenge: Medium (MERGE Syntax, Subqueries)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: MERGE Statement muss korrekt sein (WHEN MATCHED, WHEN NOT MATCHED)
-- ============================================================================
