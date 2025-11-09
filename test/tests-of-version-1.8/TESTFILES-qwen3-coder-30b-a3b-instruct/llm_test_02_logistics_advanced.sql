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

SELECT 
    f.warehouse_key,
    w.warehouse_name,
    f.product_key,
    p.product_name,
    f.supplier_key,
    s.supplier_name,
    f.quantity_delivered,
    f.quantity_ordered,
    f.delivery_days,
    f.on_time,
    f.cost
FROM 
    FACT_Delivery f
JOIN 
    DIM_Warehouse w ON f.warehouse_key = w.warehouse_key
JOIN 
    DIM_Product p ON f.product_key = p.product_key
JOIN 
    DIM_Supplier s ON f.supplier_key = s.supplier_key;


-- Aufgabe 2: Berechne die durchschnittliche Lieferzeit in Tagen pro Lieferant

SELECT s.supplier_name, AVG(f.delivery_days) AS average_delivery_days FROM STG_Delivery f JOIN DIM_Supplier s ON f.supplier_code = s.supplier_code GROUP BY s.supplier_name;


-- Aufgabe 3: Finde alle Lieferungen die nicht pünktlich waren (on_time = false)

SELECT * FROM FACT_Delivery WHERE on_time = FALSE;


-- Aufgabe 4: Berechne die Anzahl der Lieferungen pro Region (verwende DIM_Warehouse)


-- Aufgabe 5: Erstelle einen MERGE-Statement um neue Lieferungen aus STG_Delivery in FACT_Delivery zu laden (verwende warehouse_code, product_sku, supplier_code für die Zuordnung zu den Dimensions-Keys)


-- Aufgabe 6: Berechne den Lagerbestand pro Lager und Produktkategorie


-- Aufgabe 7: Finde die Top 3 Lieferanten mit der besten Pünktlichkeitsrate


-- Aufgabe 8: Berechne die Gesamtkosten pro Region und Land (Vorbereitung für ROLLUP)


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 80-95 (MERGE Statement kann komplex sein)
-- Parser Challenge: Medium (MERGE Syntax, Subqueries)
-- Model Compatibility: Medium-Advanced models
-- Special Focus: MERGE Statement muss korrekt sein (WHEN MATCHED, WHEN NOT MATCHED)
-- ============================================================================
