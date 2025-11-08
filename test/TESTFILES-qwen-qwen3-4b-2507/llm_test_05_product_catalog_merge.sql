-- ============================================================================
-- TEST 5: PRODUCT CATALOG - SQL MERGE (UPSERT) & ETL
-- ============================================================================
-- Domain: Produktkatalog (E-Commerce)
-- Complexity: 🟢 Beginner (MERGE focus)
-- Focus: MERGE Statement für ETL-Prozess, UPSERT Operations
-- Test Coverage: MERGE (INSERT, UPDATE, DELETE), ETL Patterns
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement generieren!

-- KORREKTE LÖSUNG (PostgreSQL mit ON CONFLICT):
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id) DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP;

-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement generieren!

-- KORREKTE LÖSUNG:
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id) DO UPDATE SET
--     price = EXCLUDED.price,
--     last_updated = CURRENT_TIMESTAMP
-- WHERE Products.price != EXCLUDED.price;
-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)

-- ⚠️ FRAGMENT (Score: 20/100):
--    Nur ein FRAGMENT des MERGE Statements!
--    Fehlt: MERGE INTO ... USING ... Anfang
--    Das gezeigte Fragment ist syntaktisch unvollständig

Updates AS source
ON target.product_id = source.product_id
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

-- KORREKTE LÖSUNG (Oracle/SQL Server Syntax):
-- MERGE INTO Products target
-- USING STG_Product_Updates source
-- ON target.product_id = source.product_id
-- WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- PostgreSQL Alternative (kein MERGE, separate DELETE):
-- DELETE FROM Products
-- WHERE product_id NOT IN (SELECT product_id FROM STG_Product_Updates);


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement generieren!

-- KORREKTE LÖSUNG:
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id) DO UPDATE SET
--     price = EXCLUDED.price,
--     last_updated = CURRENT_TIMESTAMP
-- WHERE ABS(Products.price - EXCLUDED.price) / NULLIF(Products.price, 0) > 0.10;
-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement generieren!

-- KORREKTE LÖSUNG:
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id) DO UPDATE SET
--     price = EXCLUDED.price,
--     stock_quantity = Products.stock_quantity + EXCLUDED.stock_quantity,
--     last_updated = CURRENT_TIMESTAMP;
-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)

-- ❌ FAILED (Score: 0/100):
--    Model konnte KEIN MERGE Statement mit Logging generieren!

-- KORREKTE LÖSUNG (mit Trigger):
-- CREATE OR REPLACE FUNCTION log_product_changes()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     IF TG_OP = 'UPDATE' THEN
--         INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
--         VALUES (NEW.product_id, 'UPDATE', OLD.price, NEW.price, OLD.stock_quantity, NEW.stock_quantity);
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen

-- ⚠️ TEILWEISE KORREKT (Score: 60/100):
--    UPDATE + INSERT Statements getrennt (kein MERGE, aber funktional)
--    PROBLEM: CASE WHEN macht nichts! stock_quantity = stock_quantity
--    PROBLEM: INSERT loggt GLEICHE Werte (old_stock = new_stock)
--    Die Logik ist falsch - es wird nichts geändert!

UPDATE Products 
SET stock_quantity = CASE 
    WHEN stock_quantity < 10 THEN stock_quantity 
    ELSE stock_quantity 
END, 
last_updated = CURRENT_TIMESTAMP 
WHERE stock_quantity < 10;

INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock) 
SELECT 
    p.product_id, 
    'UPDATE', 
    p.stock_quantity AS old_stock, 
    p.stock_quantity AS new_stock 
FROM Products p 
WHERE p.stock_quantity < 10;

-- KORREKTE LÖSUNG:
-- WITH updates AS (
--     UPDATE Products 
--     SET stock_quantity = 10, last_updated = CURRENT_TIMESTAMP 
--     WHERE stock_quantity < 10
--     RETURNING product_id, stock_quantity AS old_stock, 10 AS new_stock
-- )
-- INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock)
-- SELECT product_id, 'UPDATE', old_stock, new_stock
-- FROM updates;


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen
	
-- ❌ FAILED (Score: 0/100):
--    Model konnte KEINEN mehrstufigen ETL Prozess generieren!

-- KORREKTE LÖSUNG:
-- -- Step 1: Load Suppliers
-- INSERT INTO Suppliers (supplier_id, supplier_name, country, contact_email)
-- SELECT DISTINCT supplier_id, 'Unknown Supplier', 'Unknown', 'unknown@example.com'
-- FROM STG_Product_Updates
-- WHERE supplier_id NOT IN (SELECT supplier_id FROM Suppliers);
--
-- -- Step 2: Load Products with MERGE
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id) DO UPDATE SET
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     last_updated = CURRENT_TIMESTAMP;
--
-- -- Step 3: Log changes (would need trigger or CTE with RETURNING)

-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 10/100 ⭐
-- SUCCESS RATE: 0% (0/8 tasks korrekt, 1 teilweise)
-- 
-- AUFGABE BREAKDOWN:
--   ❌ Aufgabe 1:   0/100 - MERGE NICHT generiert!
--   ❌ Aufgabe 2:   0/100 - MERGE NICHT generiert!
--   ⚠️ Aufgabe 3:  20/100 - Nur Fragment (unvollständig)
--   ❌ Aufgabe 4:   0/100 - MERGE NICHT generiert!
--   ❌ Aufgabe 5:   0/100 - MERGE NICHT generiert!
--   ❌ Aufgabe 6:   0/100 - MERGE mit Logging NICHT generiert!
--   ⚠️ Aufgabe 7:  60/100 - UPDATE + INSERT (kein MERGE, aber Logikfehler)
--   ❌ Aufgabe 8:   0/100 - Mehrstufiger ETL NICHT generiert!
--
-- STÄRKEN:
--   Keine erkennbaren Stärken bei MERGE Statements!
--
-- SCHWÄCHEN:
--   - MERGE Statement KOMPLETT UNBEKANNT!
--   - Auch PostgreSQL ON CONFLICT nicht generiert
--   - Nur Fragmente oder gar nichts
--   - Selbst einfachste MERGE Varianten scheitern
--
-- KRITISCHE FEHLER:
--   ⚠️ Model kennt MERGE Syntax NICHT!
--   ⚠️ Auch Alternative Syntax (ON CONFLICT) nicht bekannt!
--   ⚠️ Bei Aufgabe 7: Logikfehler (nichts wird geändert)
--   ⚠️ 4B Model ist zu klein für ETL Operations!
--
-- EMPFEHLUNG: ❌ ABSOLUT UNGEEIGNET für MERGE/ETL Operations!
--              Dieses Model kann KEINE MERGE Statements generieren!
--              Für Production: Mindestens 7B+ Model erforderlich!
-- ============================================================================
