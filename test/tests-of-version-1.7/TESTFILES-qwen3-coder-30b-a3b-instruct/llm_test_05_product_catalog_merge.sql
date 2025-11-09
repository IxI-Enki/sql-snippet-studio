-- ============================================================================
-- TEST 5: PRODUCT CATALOG - SQL MERGE (UPSERT) & ETL
-- ============================================================================
-- Domain: Produktkatalog (E-Commerce)
-- Complexity: 🟢 Beginner (MERGE focus)
-- Focus: MERGE Statement für ETL-Prozess, UPSERT Operations
-- Test Coverage: MERGE (INSERT, UPDATE, DELETE), ETL Patterns
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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

MERGE INTO Products p
USING (SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET 
    product_name = s.product_name,
    sku = s.sku,
    category = s.category,
    price = s.price,
    stock_quantity = s.stock_quantity,
    supplier_id = s.supplier_id,
    last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT 
    (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
VALUES 
    (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);


-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat

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


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)

MERGE INTO Products p
USING (SELECT product_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN NOT MATCHED THEN INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
VALUES (s.product_id, 'Unknown', 'UNKNOWN', 'Unknown', 0.00, 0, 0);

-- Aufgabe drei: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)

MERGE INTO Products p
USING (SELECT product_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN NOT MATCHED BY SOURCE THEN DELETE;



-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde

MERGE INTO Products p
USING (SELECT product_id, price, stock_quantity FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET 
    p.price = s.price,
    p.stock_quantity = s.stock_quantity,
    p.last_updated = CURRENT_TIMESTAMP
WHERE ABS(p.price - s.price) > p.price * 0.1;


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt

MERGE INTO Products p
USING (SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id FROM STG_Product_Updates) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN 
    UPDATE SET 
        product_name = s.product_name,
        sku = s.sku,
        category = s.category,
        price = CASE WHEN p.price <> s.price THEN s.price ELSE p.price END,
        stock_quantity = p.stock_quantity + s.stock_quantity,
        supplier_id = s.supplier_id,
        last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN 
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);


-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)

MERGE INTO Products p
USING STG_Product_Updates s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN
    UPDATE SET 
        product_name = s.product_name,
        sku = s.sku,
        category = s.category,
        price = s.price,
        stock_quantity = s.stock_quantity,
        supplier_id = s.supplier_id,
        last_updated = CURRENT_TIMESTAMP
    WHERE p.price <> s.price OR p.stock_quantity <> s.stock_quantity;

INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
SELECT 
    p.product_id,
    'UPDATE',
    p.price,
    s.price,
    p.stock_quantity,
    s.stock_quantity
FROM Products p
JOIN STG_Product_Updates s ON p.product_id = s.product_id
WHERE p.price <> s.price OR p.stock_quantity <> s.stock_quantity;


-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen

UPDATE Products 
SET stock_quantity = stock_quantity - 1, 
    last_updated = CURRENT_TIMESTAMP
WHERE stock_quantity < 10
RETURNING product_id, stock_quantity, last_updated;


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen

MERGE INTO suppliers s
USING (SELECT supplier_id, supplier_name, country, contact_email FROM stg_suppliers) t
ON (s.supplier_id = t.supplier_id)
WHEN MATCHED THEN UPDATE SET s.supplier_name = t.supplier_name, s.country = t.country, s.contact_email = t.contact_email
WHEN NOT MATCHED THEN INSERT (supplier_id, supplier_name, country, contact_email) VALUES (t.supplier_id, t.supplier_name, t.country, t.contact_email);

MERGE INTO products p
USING (SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id FROM stg_product_updates) t
ON (p.product_id = t.product_id)
WHEN MATCHED THEN UPDATE SET p.product_name = t.product_name, p.sku = t.sku, p.category = t.category, p.price = t.price, p.stock_quantity = t.stock_quantity, p.supplier_id = t.supplier_id
WHEN NOT MATCHED THEN INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id) VALUES (t.product_id, t.product_name, t.sku, t.category, t.price, t.stock_quantity, t.supplier_id);

INSERT INTO product_change_log (product_id, change_type, old_price, new_price, old_stock, new_stock)
SELECT p.product_id, 'UPDATE', p.price, t.price, p.stock_quantity, t.stock_quantity
FROM products p
JOIN stg_product_updates t ON p.product_id = t.product_id
WHERE p.price <> t.price OR p.stock_quantity <> t.stock_quantity;


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
