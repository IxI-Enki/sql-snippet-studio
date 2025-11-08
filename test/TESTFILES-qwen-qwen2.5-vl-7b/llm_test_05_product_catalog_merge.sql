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
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_Updates up ON..."!

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

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates up 
-- ON p.product_id = up.product_id 
-- WHEN MATCHED THEN 
--     UPDATE SET 
--         product_name = up.product_name,
--         sku = up.sku,
--         category = up.category,
--         price = up.price,
--         stock_quantity = up.stock_quantity,
--         supplier_id = up.supplier_id
-- WHEN NOT MATCHED THEN 
--     INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id) 
--     VALUES (up.product_id, up.product_name, up.sku, up.category, up.price, up.stock_quantity, up.supplier_id);


-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat
-- ❌ FEHLER: Fehlt "MERGE INTO"! Außerdem "UPDATE SET p.product_name" ist falsch (kein Prefix!)

Updates u ON (p.product_id = u.product_id AND p.price != u.price)
WHEN MATCHED THEN UPDATE SET 
    p.product_name = u.product_name,
    p.sku = u.sku,
    p.category = u.category,
    p.price = u.price,
    p.stock_quantity = u.stock_quantity,
    p.supplier_id = u.supplier_id
WHERE u.import_timestamp > p.last_updated;

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates u 
-- ON p.product_id = u.product_id
-- WHEN MATCHED AND p.price != u.price THEN 
--     UPDATE SET 
--         product_name = u.product_name,
--         sku = u.sku,
--         category = u.category,
--         price = u.price,
--         stock_quantity = u.stock_quantity,
--         supplier_id = u.supplier_id,
--         last_updated = CURRENT_TIMESTAMP;


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)
-- ❌ FEHLER: Fehlt "MERGE INTO"!

Updates up ON p.product_id = up.product_id
WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates up 
-- ON p.product_id = up.product_id
-- WHEN NOT MATCHED BY SOURCE THEN DELETE;


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde
-- ❌ FEHLER: Fehlt "MERGE INTO"! WHERE nach WHEN MATCHED ist falsch platziert!

Updates u ON (p.product_id = u.product_id AND p.last_updated < u.import_timestamp)
WHEN MATCHED THEN UPDATE SET p.price = u.price, p.stock_quantity = u.stock_quantity, p.supplier_id = u.supplier_id, p.category = u.category
WHERE ((u.price - p.price) / p.price * 100 > 10 OR (u.stock_quantity - p.stock_quantity) > 5)
RETURNING product_name;

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates u 
-- ON p.product_id = u.product_id
-- WHEN MATCHED AND ABS((u.price - p.price) / p.price * 100) > 10 THEN 
--     UPDATE SET 
--         price = u.price,
--         stock_quantity = u.stock_quantity,
--         supplier_id = u.supplier_id,
--         category = u.category,
--         last_updated = CURRENT_TIMESTAMP;


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt
-- ❌ FEHLER: Fehlt "MERGE INTO"! Extra Semikolon nach VALUES.

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

-- KORREKTUR: Entferne extra Semikolon und füge MERGE INTO hinzu
-- MERGE INTO Products p
-- USING STG_Product_Updates pu 
-- ON p.product_id = pu.product_id
-- WHEN MATCHED THEN
--     UPDATE SET 
--         product_name = pu.product_name,
--         sku = pu.sku,
--         category = pu.category,
--         price = pu.price,
--         stock_quantity = p.stock_quantity + pu.stock_quantity,
--         supplier_id = pu.supplier_id,
--         last_updated = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
--     INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
--     VALUES (pu.product_id, pu.product_name, pu.sku, pu.category, pu.price, pu.stock_quantity, pu.supplier_id);


-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)
-- ❌ FEHLER: Fehlt "MERGE INTO"! Logik komplett falsch! UPDATE SET auf falscher Tabelle!

Updates AS source 
ON target.product_id = source.product_id 
WHEN MATCHED THEN 
  UPDATE SET old_price = source.price, new_price = target.new_price, old_stock = target.old_stock, new_stock = source.stock_quantity
WHEN NOT MATCHED THEN 
  INSERT (product_id, change_type, old_price, new_price, old_stock, new_stock) VALUES (source.product_id, 'INSERT', NULL, source.price, NULL, source.stock_quantity)
OUTPUT INSERTED.*;

-- KORREKTUR: PostgreSQL unterstützt keine OUTPUT-Klausel! Nutze RETURNING oder separate Trigger/Log-Inserts.
-- MERGE INTO Products p
-- USING STG_Product_Updates u 
-- ON p.product_id = u.product_id
-- WHEN MATCHED THEN
--     UPDATE SET 
--         product_name = u.product_name,
--         price = u.price,
--         stock_quantity = u.stock_quantity,
--         last_updated = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
--     INSERT (product_id, product_name, price, stock_quantity)
--     VALUES (u.product_id, u.product_name, u.price, u.stock_quantity);
-- 
-- -- Dann separate Log-Inserts (in Trigger oder nachfolgendem Statement)
-- INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
-- SELECT p.product_id, 'UPDATE', p.price, u.price, p.stock_quantity, u.stock_quantity
-- FROM Products p
-- JOIN STG_Product_Updates u ON p.product_id = u.product_id
-- WHERE p.price != u.price OR p.stock_quantity != u.stock_quantity;


-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen
-- ⚠️ TEILWEISE: Nutzt UPDATE + INSERT statt MERGE (akzeptabel). ABER: Parameter-Syntax (:product_id) ist nicht PostgreSQL!

UPDATE Products SET stock_quantity = CASE WHEN stock_quantity < 10 THEN 10 ELSE stock_quantity END WHERE stock_quantity < 10;
INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock) VALUES (:product_id, 'UPDATE', :old_stock, :new_stock);

-- KORREKTUR: PostgreSQL-Syntax ohne Parameter
-- WITH updated_products AS (
--     UPDATE Products 
--     SET stock_quantity = 10
--     WHERE stock_quantity < 10
--     RETURNING product_id, 10 AS new_stock, stock_quantity AS old_stock
-- )
-- INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock, change_timestamp)
-- SELECT product_id, 'UPDATE', old_stock, new_stock, CURRENT_TIMESTAMP
-- FROM updated_products;


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen
-- ⚠️ TEILWEISE: MERGE ist korrekt! Aber: STG_Suppliers existiert nicht im Schema! Log-Insert ist problematisch.

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

-- HINWEIS: Task 8 hat ein korrektes MERGE Statement! Aber STG_Suppliers existiert nicht, und Log-Insert ist unvollständig.


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 12.5/100
-- SUCCESS RATE: 1/8 (12.5%)

-- BREAKDOWN:
-- ✅ Korrekt:  1 (Task 8 - MERGE korrekt, Rest problematisch)
-- ⚠️ Teilweise: 1 (Task 7 - UPDATE/INSERT statt MERGE)
-- ❌ Fehler:   6 (Tasks 1-6 - alle fehlen "MERGE INTO")
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Task 8 zeigt korrektes MERGE Statement! (einziges in allen Tasks)
-- + WHEN MATCHED/NOT MATCHED Konzept verstanden
-- + UPDATE SET und INSERT VALUES Syntax meist korrekt

-- WEAKNESSES:
-- - 6 von 8 MERGE Statements fehlt "MERGE INTO ... USING" Kopfzeile!
-- - Beginnen direkt mit "Updates" statt "MERGE INTO Products USING STG_Product_Updates"
-- - UPDATE SET p.column Prefix falsch (sollte nur column sein)
-- - WHERE Klausel nach WHEN MATCHED falsch platziert
-- - Parameter-Syntax (:variable) statt PostgreSQL

-- CRITICAL ERRORS:
-- - Tasks 1-6: ALLE MERGE Statements unvollständig!
-- - Das Model generiert Fragmente, nicht vollständige MERGE Statements!
-- - Nur Task 8 hat vollständiges "MERGE INTO ... USING ... ON ... WHEN"

-- RECOMMENDATION:
-- ❌ KRITISCH SCHWACH für MERGE!
-- Das 7B Model kann MERGE Statements nicht korrekt generieren (nur 1/8 vollständig).
-- Systematisches Problem: Kopfzeile "MERGE INTO ... USING" fehlt konsequent!

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
