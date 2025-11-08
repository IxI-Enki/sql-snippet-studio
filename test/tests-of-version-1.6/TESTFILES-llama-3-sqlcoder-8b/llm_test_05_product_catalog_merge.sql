-- ============================================================================
-- TEST 5: PRODUCT CATALOG - SQL MERGE (UPSERT) & ETL
-- ============================================================================
-- Domain: Produktkatalog (E-Commerce)
-- Complexity: 🟢 Beginner (MERGE focus)
-- Focus: MERGE Statement für ETL-Prozess, UPSERT Operations
-- Test Coverage: MERGE (INSERT, UPDATE, DELETE), ETL Patterns
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ❌ FALSCH (KEIN VOLLSTÄNDIGER MERGE!)
-- Problem 1: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!
-- Problem 2: CURRENT_TIMESTAMP() ist eine Funktion, PostgreSQL: CURRENT_TIMESTAMP (ohne Klammern)!
-- Bewertung: MERGE Struktur erkennbar, aber unvollständig - fehlt MERGE INTO Prefix

Updates AS s ON p.product_id = s.product_id WHEN MATCHED THEN UPDATE SET p.product_name = s.product_name, p.sku = s.sku, p.category = s.category, p.price = s.price, p.stock_quantity = s.stock_quantity, p.supplier_id = s.supplier_id, p.last_updated = CURRENT_TIMESTAMP() WHEN NOT MATCHED THEN INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id) VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);

-- ✅ KORRIGIERT: Vollständiger MERGE Statement (PostgreSQL ON CONFLICT Syntax)
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT 
--     product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP;


-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat
-- Status: ❌ FALSCH (KEIN MERGE!)
-- Problem: Das ist nur ein SELECT, KEIN MERGE Statement!
-- Bewertung: Komplett falsch - zeigt nur JOINs, keine MERGE Operation

SELECT p.product_id, s.supplier_id FROM Products p JOIN Suppliers s ON p.supplier_id = s.supplier_id;

-- ✅ KORRIGIERT: MERGE mit Preis-Änderungs-Bedingung
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT 
--     product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP
-- WHERE Products.price != EXCLUDED.price;


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)
-- Status: ❌ FALSCH (KEIN VOLLSTÄNDIGER MERGE + FALSCHE SYNTAX!)
-- Problem 1: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!
-- Problem 2: "BY TARGET/SOURCE" ist SQL Server Syntax, nicht PostgreSQL!
-- Problem 3: PostgreSQL unterstützt DELETE in MERGE nicht! Braucht separaten DELETE Statement!
-- Bewertung: Unvollständig + falsche Datenbank-Syntax

Updates AS s ON p.product_id = s.product_id WHEN NOT MATCHED BY TARGET THEN INSERT (product_name, sku, category, price, stock_quantity, supplier_id) VALUES (s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id) WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- ✅ KORRIGIERT: DELETE von Produkten die nicht mehr in Staging sind
-- DELETE FROM Products
-- WHERE product_id NOT IN (
--     SELECT product_id 
--     FROM STG_Product_Updates
-- );


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde
-- Status: ❌ FALSCH (KEIN ECHTER MERGE!)
-- Problem: "previous_query" existiert nicht! Kann nicht auf vorige Query referenzieren!
-- Bewertung: Logik-Idee erkennbar, aber syntaktisch unmöglich

SELECT p.product_id FROM Products p JOIN STG_Product_Updates sp ON p.product_id = sp.product_id WHERE (p.price - sp.price) / NULLIF(p.price, 0) * 100 > 10; MERGE INTO Products p USING (SELECT product_id FROM previous_query) AS t ON p.product_id = t.product_id SET p.price = STG_Product_Updates.price;

-- ✅ KORRIGIERT: MERGE mit 10% Preisänderungs-Bedingung
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT 
--     product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP
-- WHERE ABS(Products.price - EXCLUDED.price) / NULLIF(Products.price, 0) * 100 > 10;


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt
-- Status: ❌ FALSCH (KEIN MERGE!)
-- Problem: Nur SELECT mit FULL JOIN, KEIN MERGE Statement!
-- Bewertung: Komplett falsch - keine MERGE Operation

SELECT p.product_id, s.supplier_id, COALESCE(p.price, s.price) AS price, SUM(p.stock_quantity) AS total_stock FROM Products p FULL JOIN Suppliers s ON p.supplier_id = s.supplier_id GROUP BY p.product_id, s.supplier_id ORDER BY p.product_id NULLS LAST;

-- ✅ KORRIGIERT: MERGE mit Lagerbestand-Addition
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT 
--     product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = CASE 
--         WHEN Products.price != EXCLUDED.price THEN EXCLUDED.price
--         ELSE Products.price
--     END,
--     stock_quantity = Products.stock_quantity + EXCLUDED.stock_quantity,  -- ADDITION statt Ersatz!
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP;


-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)
-- Status: ❌ FALSCH (SEHR KOMPLEX, MULTIPLE ERRORS!)
-- Problem 1: pr.price undefined (pr ist nicht definiert!)
-- Problem 2: MERGE INTO Product_Change_Log macht keinen Sinn - sollte in Products mergen!
-- Problem 3: OUTPUT Klausel ist SQL Server, nicht PostgreSQL!
-- Problem 4: Logik komplett verworren
-- Bewertung: Grundidee erkennbar, aber Implementierung nicht funktional

SELECT p.product_id, s.supplier_id, pr.price AS old_price, st.stock_quantity AS new_stock FROM Products p JOIN STG_Product_Updates st ON p.product_id = st.product_id AND p.sku = st.sku AND p.category = st.category AND p.supplier_id = st.supplier_id LEFT JOIN Product_Change_Log pc ON p.product_id = pc.product_id AND pc.change_type = 'UPDATE' WHERE st.import_timestamp > pc.change_timestamp OR pc.change_type IS NULL; MERGE INTO Product_Change_Log AS t USING (SELECT p.product_id, s.supplier_id, pr.price AS new_price, st.stock_quantity FROM Products p JOIN STG_Product_Updates st ON p.product_id = st.product_id AND p.sku = st.sku AND p.category = st.category AND p.supplier_id = st.supplier_id) AS s ON t.product_id = s.product_id AND t.change_type = 'UPDATE' WHEN MATCHED THEN UPDATE SET t.new_price = s.new_price, t.new_stock = s.stock_quantity, t.change_timestamp = CURRENT_TIMESTAMP() WHEN NOT MATCHED THEN INSERT (product_id, change_type, old_price, new_price, old_stock, new_stock) VALUES (s.product_id, 'INSERT', NULL, s.new_price, NULL, s.stock_quantity);

-- ✅ KORRIGIERT: MERGE mit Change Logging (2-Step Process)
-- -- Step 1: MERGE mit Log-Vorbereitung
-- WITH changes AS (
--     SELECT 
--         p.product_id,
--         p.price AS old_price,
--         p.stock_quantity AS old_stock,
--         s.price AS new_price,
--         s.stock_quantity AS new_stock,
--         CASE 
--             WHEN p.product_id IS NULL THEN 'INSERT'
--             WHEN p.price != s.price OR p.stock_quantity != s.stock_quantity THEN 'UPDATE'
--             ELSE NULL
--         END AS change_type
--     FROM STG_Product_Updates s
--     LEFT JOIN Products p ON s.product_id = p.product_id
--     WHERE p.product_id IS NULL OR p.price != s.price OR p.stock_quantity != s.stock_quantity
-- )
-- INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
-- SELECT product_id, change_type, old_price, new_price, old_stock, new_stock
-- FROM changes
-- WHERE change_type IS NOT NULL;
-- 
-- -- Step 2: Actual MERGE
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP;


-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen
-- Status: ❌ FALSCH (MULTIPLE SYNTAX ERRORS!)
-- Problem 1: UPDATE Products p SET p.price - falsche Syntax! Sollte UPDATE Products SET price sein!
-- Problem 2: Berechnungen in old_price falsch (p.price - 0.05 * p.price statt p.price / 1.05)!
-- Problem 3: new_stock = old_stock + 5 macht keinen Sinn (wo kommt +5 her?)!
-- Problem 4: UPDATE Change_Log am Ende macht keinen Sinn!
-- Bewertung: Logik komplett verworren, multiple Syntax-Fehler

SELECT p.product_id FROM Products p WHERE p.stock_quantity < 10; UPDATE Products p SET p.price = p.price * 1.05, p.last_updated = CURRENT_TIMESTAMP() WHERE p.product_id IN (SELECT product_id FROM Products WHERE stock_quantity < 10); INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock) SELECT p.product_id, 'UPDATE', p.price - (p.price * 0.05), p.price, p.stock_quantity, p.stock_quantity + 5 FROM Products p WHERE p.product_id IN (SELECT product_id FROM Products WHERE stock_quantity < 10); UPDATE Product_Change_Log SET change_type = 'UPDATE' WHERE change_type = 'INSERT'; SELECT pc.log_id, pr.product_name, pc.change_type, pc.old_price, pc.new_price, pc.old_stock, pc.new_stock FROM Product_Change_Log pc JOIN Products pr ON pc.product_id = pr.product_id ORDER BY log_id DESC;

-- ✅ KORRIGIERT: Low-Stock Update mit Logging
-- -- Step 1: Log alte Werte
-- INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
-- SELECT 
--     product_id,
--     'UPDATE',
--     price AS old_price,
--     price * 1.05 AS new_price,
--     stock_quantity AS old_stock,
--     stock_quantity AS new_stock
-- FROM Products
-- WHERE stock_quantity < 10;
-- 
-- -- Step 2: Update Preise
-- UPDATE Products
-- SET 
--     price = price * 1.05,
--     last_updated = CURRENT_TIMESTAMP
-- WHERE stock_quantity < 10;


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen
-- Status: ❌ FALSCH (KOMPLETT VERWORREN!)
-- Problem 1: Erste 2 SELECTs machen nichts, nur Abfragen!
-- Problem 2: MERGE INTO new_suppliers (CTE) ist ungültig - CTEs sind read-only!
-- Problem 3: ns.supplier_id = np.product_id macht keinen Sinn (supplier_id != product_id)!
-- Problem 4: MERGE INTO updated_products (CTE) wieder ungültig!
-- Problem 5: Letzter CTE ist nur SELECT, kein MERGE oder INSERT!
-- Bewertung: Grundidee von 3-Step ETL erkennbar, aber Implementierung komplett falsch

SELECT s.supplier_id, s.supplier_name FROM Suppliers s; SELECT p.product_id, p.product_name FROM Products p; WITH new_suppliers AS (SELECT s.supplier_id, s.supplier_name FROM STG_Product_Updates s), new_products AS (SELECT p.product_id, p.product_name FROM Products p) MERGE INTO new_suppliers AS ns USING new_products AS np ON ns.supplier_id = np.product_id WHEN NOT MATCHED THEN INSERT (supplier_id, supplier_name) VALUES (ns.supplier_id, ns.supplier_name); WITH updated_products AS (SELECT p.product_id, p.product_name, s.supplier_id FROM Products p JOIN Suppliers s ON p.supplier_id = s.supplier_id), new_product_updates AS (SELECT p.product_id, p.product_name, s.supplier_id FROM STG_Product_Updates p JOIN Suppliers s ON p.supplier_id = s.supplier_id) MERGE INTO updated_products AS up USING new_product_updates AS nup ON up.product_id = nup.product_id WHEN MATCHED THEN UPDATE SET up.product_name = nup.product_name, up.supplier_id = nup.supplier_id; WITH change_log AS (SELECT pc.log_id, pc.product_id, pc.change_type, pc.old_price, pc.new_price, pc.old_stock, pc.new_stock FROM Product_Change_Log pc) SELECT cl.log_id, cl.product_id, cl.change_type, cl.old_price, cl.new_price, cl.old_stock, cl.new_stock FROM change_log cl;

-- ✅ KORRIGIERT: Mehrstufiger ETL Prozess
-- -- STEP 1: Lade neue Suppliers aus Staging
-- INSERT INTO Suppliers (supplier_id, supplier_name, country, contact_email)
-- SELECT DISTINCT 
--     supplier_id,
--     NULL AS supplier_name,  -- Nicht in STG_Product_Updates
--     NULL AS country,
--     NULL AS contact_email
-- FROM STG_Product_Updates
-- WHERE supplier_id NOT IN (SELECT supplier_id FROM Suppliers)
-- ON CONFLICT (supplier_id) DO NOTHING;
-- 
-- -- STEP 2: Log Changes (BEFORE merge)
-- INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
-- SELECT 
--     s.product_id,
--     CASE WHEN p.product_id IS NULL THEN 'INSERT' ELSE 'UPDATE' END AS change_type,
--     p.price AS old_price,
--     s.price AS new_price,
--     p.stock_quantity AS old_stock,
--     s.stock_quantity AS new_stock
-- FROM STG_Product_Updates s
-- LEFT JOIN Products p ON s.product_id = p.product_id
-- WHERE p.product_id IS NULL 
--    OR p.price != s.price 
--    OR p.stock_quantity != s.stock_quantity;
-- 
-- -- STEP 3: MERGE Products
-- INSERT INTO Products (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
-- SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
-- FROM STG_Product_Updates
-- ON CONFLICT (product_id)
-- DO UPDATE SET
--     product_name = EXCLUDED.product_name,
--     sku = EXCLUDED.sku,
--     category = EXCLUDED.category,
--     price = EXCLUDED.price,
--     stock_quantity = EXCLUDED.stock_quantity,
--     supplier_id = EXCLUDED.supplier_id,
--     last_updated = CURRENT_TIMESTAMP;


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
