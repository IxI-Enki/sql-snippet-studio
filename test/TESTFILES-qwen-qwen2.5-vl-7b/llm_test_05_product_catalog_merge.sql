-- ============================================================================
-- TEST 5: PRODUCT CATALOG - SQL MERGE (UPSERT) & ETL
-- ============================================================================
-- Domain: Produktkatalog (E-Commerce)
-- Complexity: 🟢 Beginner (MERGE focus)
-- Focus: MERGE Statement für ETL-Prozess, UPSERT Operations
-- Test Coverage: MERGE (INSERT, UPDATE, DELETE), ETL Patterns
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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
-- TEST TASKS - BASIC MERGE
-- ============================================================================

-- Aufgabe 1: Erstelle einen MERGE Statement der neue Produkte aus STG_Product_Updates in Products einfügt (INSERT) und existierende Produkte aktualisiert (UPDATE)

Updates up ON p.product_id = up.product_id 
WHEN MATCHED THEN 
    UPDATE SET 
        product_name = up.product_name,
        sku = up.sku,
        category = up.category,
        price = up.price,
        stock_quantity = up.stock_quantity,
        supplier_id = up.supplier_id
WHEN NOT MATCHED BY TARGET THEN 
    INSERT (product_name, sku, category, price, stock_quantity, supplier_id) VALUES (up.product_name, up.sku, up.category, up.price, up.stock_quantity, up.supplier_id);


-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat

Updates u ON (p.product_id = u.product_id AND p.price != u.price)
WHEN MATCHED THEN UPDATE SET 
    p.product_name = u.product_name,
    p.sku = u.sku,
    p.category = u.category,
    p.price = u.price,
    p.stock_quantity = u.stock_quantity,
    p.supplier_id = u.supplier_id
WHERE u.import_timestamp > p.last_updated;


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)

Updates up ON p.product_id = up.product_id
WHEN NOT MATCHED BY SOURCE THEN DELETE;


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde

Updates u ON (p.product_id = u.product_id AND p.last_updated < u.import_timestamp)
WHEN MATCHED THEN UPDATE SET p.price = u.price, p.stock_quantity = u.stock_quantity, p.supplier_id = u.supplier_id, p.category = u.category
WHERE ((u.price - p.price) / p.price * 100 > 10 OR (u.stock_quantity - p.stock_quantity) > 5)
RETURNING product_name;


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt

Updates pu ON (p.product_id = pu.product_id)
WHEN MATCHED THEN
    UPDATE SET 
        product_name = pu.product_name,
        sku = pu.sku,
        category = pu.category,
        price = pu.price,
        stock_quantity = p.stock_quantity + pu.stock_quantity,
        supplier_id = pu.supplier_id,
        last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
    VALUES (pu.product_id, pu.product_name, pu.sku, pu.category, pu.price, pu.stock_quantity, pu.supplier_id);
;


-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)

Updates AS source 
ON target.product_id = source.product_id 
WHEN MATCHED THEN 
  UPDATE SET old_price = source.price, new_price = target.new_price, old_stock = target.old_stock, new_stock = source.stock_quantity
WHEN NOT MATCHED THEN 
  INSERT (product_id, change_type, old_price, new_price, old_stock, new_stock) VALUES (source.product_id, 'INSERT', NULL, source.price, NULL, source.stock_quantity)
OUTPUT INSERTED.*;


-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen

UPDATE Products SET stock_quantity = CASE WHEN stock_quantity < 10 THEN 10 ELSE stock_quantity END WHERE stock_quantity < 10;
INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock) VALUES (:product_id, 'UPDATE', :old_stock, :new_stock);


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen

INSERT INTO Suppliers (supplier_name, country, contact_email)
SELECT supplier_name, country, contact_email FROM STG_Suppliers;

MERGE INTO Products p
USING STG_Product_Updates pu ON p.product_id = pu.product_id
WHEN MATCHED THEN UPDATE SET 
    product_name = pu.product_name,
    sku = pu.sku,
    category = pu.category,
    price = pu.price,
    stock_quantity = pu.stock_quantity,
    supplier_id = pu.supplier_id,
    last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED BY TARGET THEN INSERT (product_name, sku, category, price, stock_quantity, supplier_id)
VALUES (pu.product_name, pu.sku, pu.category, pu.price, pu.stock_quantity, pu.supplier_id);

INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock, change_timestamp)
SELECT product_id, 'UPDATE', old_price, new_price, old_stock, new_stock, CURRENT_TIMESTAMP
FROM STG_Product_Updates
WHERE NOT EXISTS (
    SELECT 1 FROM Products p WHERE p.product_id = STG_Product_Updates.product_id AND p.last_updated = STG_Product_Updates.import_timestamp
);

SELECT * FROM Product_Change_Log;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 75-90 (MERGE Syntax variiert zwischen DBs)
-- Parser Challenge: Medium (MERGE hat verschiedene Dialekte)
-- Model Compatibility: ALL (aber Syntax-Varianten beachten!)
-- Special Focus:
--   - MERGE INTO target USING source ON condition
--   - WHEN MATCHED THEN UPDATE SET ...
--   - WHEN NOT MATCHED THEN INSERT ...
--   - WHEN NOT MATCHED BY SOURCE THEN DELETE
--   - PostgreSQL: ON CONFLICT statt MERGE (alternative Syntax möglich)
--   - Oracle: MERGE INTO ... USING ... ON ...
-- ============================================================================
