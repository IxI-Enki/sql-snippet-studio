-- ============================================================================
-- EXAMPLE: Product catalog - MERGE (UPSERT) and ETL
-- ============================================================================
-- Domain: E-commerce product master data
-- Level: Beginner (MERGE focus)
-- Focus: MERGE insert/update/delete patterns for ETL
-- Validated with model: qwen3-coder-30b-a3b-instruct
-- ============================================================================
-- ============================================================================
-- SCHEMA: Product Master Data & Staging
-- ============================================================================

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    supplier_id INT,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    contact_email VARCHAR(100)
);

-- ============================================================================
-- STAGING TABLES FOR ETL
-- ============================================================================

CREATE TABLE STG_Product_Updates (
    product_id INT,
    product_name VARCHAR(100),
    sku VARCHAR(50),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT,
    supplier_id INT,
    import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Product_Change_Log (
    log_id SERIAL PRIMARY KEY,
    product_id INT,
    change_type VARCHAR(20),  -- 'INSERT', 'UPDATE', 'DELETE'
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    old_stock INT,
    new_stock INT,
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 1: Erstelle einen MERGE Statement der neue Produkte aus STG_Product_Updates in Products einfügt (INSERT) und existierende Produkte aktualisiert (UPDATE)


-- Task 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat

MERGE INTO Products p
USING (SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET 
    p.product_name = s.product_name,
    p.sku = s.sku,
    p.category = s.category,
    p.price = s.price,
    p.stock_quantity = s.stock_quantity,
    p.supplier_id = s.supplier_id,
    p.last_updated = CURRENT_TIMESTAMP
WHERE p.price <> s.price;


-- Task 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)
DELETE FROM Products WHERE product_id NOT IN (SELECT product_id FROM STG_Product_Updates);

-- Task 3 (repeat run)
MERGE INTO Products p
USING (SELECT product_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN NOT MATCHED BY SOURCE THEN DELETE;



-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde


-- Task 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)


-- Task 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen


