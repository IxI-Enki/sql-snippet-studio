-- ============================================================================
-- TEST 2: LOGISTICS - ADVANCED STAR-SCHEMA + MERGE + ETL
-- ============================================================================
-- Domain: Logistik (Lager, Lieferungen, Transportrouten)
-- Complexity: 🟡 Intermediate
-- Focus: Mehrere Dimensionen, Hierarchien, MERGE für Delta-Loading
-- Test Coverage: Advanced Star-Schema, MERGE, ETL, ROLLUP-ready Hierarchies
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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

SELECT f.delivery_id, w.warehouse_name, p.product_name, s.supplier_name 
FROM FACT_Delivery f 
JOIN DIM_Warehouse w ON f.warehouse_key = w.warehouse_key 
JOIN DIM_Product p ON f.product_key = p.product_key 
JOIN DIM_Supplier s ON f.supplier_key = s.supplier_key;


-- Aufgabe 2: Berechne die durchschnittliche Lieferzeit in Tagen pro Lieferant

SELECT supplier_name, AVG(delivery_days) AS average_delivery_days FROM FACT_Delivery JOIN DIM_Supplier ON FACT_Delivery.supplier_key = DIM_Supplier.supplier_key GROUP BY supplier_name;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)

SELECT * FROM FACT_Delivery WHERE on_time = FALSE;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)

SELECT w.region, COUNT(*) AS delivery_count FROM FACT_Delivery fd JOIN DIM_Warehouse w ON fd.warehouse_key = w.warehouse_key GROUP BY w.region;


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)

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
    JOIN DIM_Time dt ON sd.delivery_date = dt.full_date
    JOIN DIM_Warehouse dw ON sd.warehouse_code = dw.warehouse_code
    JOIN DIM_Product dp ON sd.product_sku = dp.sku
    JOIN DIM_Supplier ds ON sd.supplier_code = ds.supplier_code
) stg 
ON fd.delivery_id = stg.delivery_id 
WHEN MATCHED THEN 
    UPDATE SET 
        time_key = stg.time_key,
        warehouse_key = stg.warehouse_key,
        product_key = stg.product_key,
        supplier_key = stg.supplier_key,
        quantity_delivered = stg.quantity_delivered,
        quantity_ordered = stg.quantity_ordered,
        delivery_days = stg.delivery_days,
        on_time = stg.on_time,
        cost = stg.cost
WHEN NOT MATCHED THEN 
    INSERT (delivery_id, time_key, warehouse_key, product_key, supplier_key, quantity_delivered, quantity_ordered, delivery_days, on_time, cost) VALUES (
        stg.delivery_id,
        stg.time_key,
        stg.warehouse_key,
        stg.product_key,
        stg.supplier_key,
        stg.quantity_delivered,
        stg.quantity_ordered,
        stg.delivery_days,
        stg.on_time,
        stg.cost
    );


-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie

SELECT w.warehouse_name, p.category, SUM(f.quantity_delivered) AS stock_level 
FROM DIM_Warehouse w 
JOIN FACT_Delivery f ON w.warehouse_key = f.warehouse_key 
JOIN DIM_Product p ON f.product_key = p.product_key 
GROUP BY w.warehouse_name, p.category;


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate

SELECT supplier_name, AVG(on_time) AS average_punctuality_rate 
FROM FACT_Delivery fd JOIN DIM_Supplier ds ON fd.supplier_key = ds.supplier_key 
GROUP BY supplier_name 
ORDER BY average_punctuality_rate DESC 
LIMIT 3;


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)

SELECT region, country, SUM(cost) AS total_cost FROM FACT_Delivery GROUP BY region, country;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 80-95 (MERGE Statement kann komplex sein)
-- Parser Challenge: Medium (MERGE Syntax, Subqueries)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: MERGE Statement muss korrekt sein (WHEN MATCHED, WHEN NOT MATCHED)
-- ============================================================================
