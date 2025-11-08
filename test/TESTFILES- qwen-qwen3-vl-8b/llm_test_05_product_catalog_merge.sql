-- ============================================================================
-- TEST 5: PRODUCT CATALOG - SQL MERGE (UPSERT) & ETL
-- ============================================================================
-- Domain: Produktkatalog (E-Commerce)
-- Complexity: 🟢 Beginner (MERGE focus)
-- Focus: MERGE Statement für ETL-Prozess, UPSERT Operations
-- Test Coverage: MERGE (INSERT, UPDATE, DELETE), ETL Patterns
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!

Updates s
ON p.product_id = s.product_id
WHEN MATCHED THEN
    UPDATE SET
        product_name = s.product_name,
        sku = s.sku,
        category = s.category,
        price = s.price,
        stock_quantity = s.stock_quantity,
        supplier_id = s.supplier_id,
        last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates s
-- ON p.product_id = s.product_id
-- WHEN MATCHED THEN
--     UPDATE SET
--         product_name = s.product_name,
--         sku = s.sku,
--         category = s.category,
--         price = s.price,
--         stock_quantity = s.stock_quantity,
--         supplier_id = s.supplier_id,
--         last_updated = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
--     INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
--     VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);


-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!

Updates s
ON p.product_id = s.product_id
WHEN MATCHED AND p.price != s.price THEN
UPDATE SET
    product_name = s.product_name,
    sku = s.sku,
    category = s.category,
    price = s.price,
    stock_quantity = s.stock_quantity,
    supplier_id = s.supplier_id,
    last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);

-- KORREKTUR: (identisch wie Task 1, plus MERGE INTO am Anfang)


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!

Updates s
ON p.product_id = s.product_id
WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates s
-- ON p.product_id = s.product_id
-- WHEN NOT MATCHED BY SOURCE THEN DELETE;


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!

Updates s
ON p.product_id = s.product_id
WHEN MATCHED AND ABS((s.price - p.price) / p.price * 100) > 10 THEN
    UPDATE SET
        product_name = s.product_name,
        sku = s.sku,
        category = s.category,
        price = s.price,
        stock_quantity = s.stock_quantity,
        supplier_id = s.supplier_id,
        last_updated = CURRENT_TIMESTAMP;

-- KORREKTUR: (plus MERGE INTO am Anfang)


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt
-- ❌ FEHLER: Fehlt "MERGE INTO Products p USING STG_Product_" am Anfang!
-- Außerdem: UPDATE SET verwendet p.product_name statt product_name (sollte ohne "p." sein)!
-- Lagerbestand wird NICHT addiert - stock_quantity fehlt im UPDATE!

Updates s
ON p.product_id = s.product_id
WHEN MATCHED THEN
    UPDATE SET
        p.product_name = s.product_name,
        p.sku = s.sku,
        p.category = s.category,
        p.price = s.price,
        p.last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);

-- KORREKTUR:
-- MERGE INTO Products p
-- USING STG_Product_Updates s
-- ON p.product_id = s.product_id
-- WHEN MATCHED THEN
--     UPDATE SET
--         product_name = s.product_name,
--         sku = s.sku,
--         category = s.category,
--         price = s.price,
--         stock_quantity = p.stock_quantity + s.stock_quantity,  -- ADDIEREN!
--         supplier_id = s.supplier_id,
--         last_updated = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
--     INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
--     VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);


-- ============================================================================
-- TEST TASKS - ETL WITH LOGGING
-- ============================================================================

-- Aufgabe 6: Erstelle einen MERGE Statement der alle Änderungen in die Product_Change_Log Tabelle loggt (verwende OUTPUT Klausel oder separate INSERT Statements)
-- ❌ FEHLER: KOMPLETT FALSCH!
-- Das ist kein MERGE Statement - es ist eine UNION ALL Query mit Subqueries!
-- Außerdem: "MERGE INTO Product_Change_Log target USING (" am Anfang ist broken!

SELECT 
        p.product_id,
        'UPDATE' AS change_type,
        p.price AS new_price,
        p.stock_quantity AS new_stock,
        p.last_updated AS change_timestamp
    FROM Products p
    INNER JOIN STG_Product_Updates s ON p.product_id = s.product_id
    WHERE p.price != s.price OR p.stock_quantity != s.stock_quantity
    UNION ALL
    SELECT 
        p.product_id,
        'INSERT' AS change_type,
        p.price AS new_price,
        p.stock_quantity AS new_stock,
        p.last_updated AS change_timestamp
    FROM Products p
    INNER JOIN STG_Product_Updates s ON p.product_id = s.product_id
    WHERE NOT EXISTS (
        SELECT 1 FROM STG_Product_Updates s2
        WHERE s2.product_id = p.product_id
        AND s2.product_name = p.product_name
        AND s2.sku = p.sku
        AND s2.category = p.category
        AND s2.price = p.price
        AND s2.stock_quantity = p.stock_quantity
        AND s2.supplier_id = p.supplier_id
    )
) AS source
ON target.product_id = source.product_id
WHEN MATCHED THEN
    UPDATE SET
        old_price = source.new_price,
        old_stock = source.new_stock,
        change_timestamp = source.change_timestamp
WHEN NOT MATCHED THEN
    INSERT (product_id, change_type, old_price, new_price, old_stock, new_stock, change_timestamp)
    VALUES (source.product_id, source.change_type, 0, source.new_price, 0, source.new_stock, source.change_timestamp);

-- KORREKTUR (separate INSERT Statements für Logging):
-- -- First, MERGE Products
-- MERGE INTO Products p
-- USING STG_Product_Updates s
-- ON p.product_id = s.product_id
-- WHEN MATCHED THEN
--     UPDATE SET
--         product_name = s.product_name,
--         sku = s.sku,
--         category = s.category,
--         price = s.price,
--         stock_quantity = s.stock_quantity,
--         supplier_id = s.supplier_id,
--         last_updated = CURRENT_TIMESTAMP
-- WHEN NOT MATCHED THEN
--     INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id, last_updated)
--     VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id, CURRENT_TIMESTAMP);
-- 
-- -- Then, Log UPDATEs
-- INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
-- SELECT 
--     s.product_id, 
--     'UPDATE', 
--     p.price AS old_price, 
--     s.price AS new_price, 
--     p.stock_quantity AS old_stock, 
--     s.stock_quantity AS new_stock
-- FROM STG_Product_Updates s
-- JOIN Products p ON s.product_id = p.product_id
-- WHERE p.price != s.price OR p.stock_quantity != s.stock_quantity;
-- 
-- -- Log INSERTs
-- INSERT INTO Product_Change_Log (product_id, change_type, new_price, new_stock)
-- SELECT 
--     s.product_id, 
--     'INSERT', 
--     s.price, 
--     s.stock_quantity
-- FROM STG_Product_Updates s
-- LEFT JOIN Products p ON s.product_id = p.product_id
-- WHERE p.product_id IS NULL;


-- Aufgabe 7: Aktualisiere nur Produkte deren Lagerbestand unter 10 gefallen ist und logge diese Änderungen
-- ❌ FEHLER: Das ist ein einfaches UPDATE, kein MERGE Statement!
-- Außerdem: stock_quantity + 1 ist willkürlich - Aufgabe sagt nichts von "+1"!
-- Loggt NICHTS in Product_Change_Log!

UPDATE Products SET stock_quantity = stock_quantity + 1 WHERE stock_quantity < 10;

-- KORREKTUR (mit Logging):
-- -- Update Products
-- UPDATE Products 
-- SET stock_quantity = stock_quantity + 10,  -- Beispiel: Auffüllen auf +10
--     last_updated = CURRENT_TIMESTAMP
-- WHERE stock_quantity < 10;
-- 
-- -- Log changes
-- INSERT INTO Product_Change_Log (product_id, change_type, old_stock, new_stock)
-- SELECT 
--     product_id, 
--     'UPDATE', 
--     stock_quantity - 10 AS old_stock,  -- Rückrechnung
--     stock_quantity AS new_stock
-- FROM Products
-- WHERE stock_quantity >= 10 AND stock_quantity < 20;  -- Die gerade aktualisierten


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen
-- ✅ KORREKT (Mehrstufiger ETL-Prozess mit INSERT, MERGE, und Logging!)

INSERT INTO Suppliers (supplier_id, supplier_name, country, contact_email)
SELECT supplier_id, supplier_name, country, contact_email
FROM STG_Suppliers
WHERE supplier_id NOT IN (SELECT supplier_id FROM Suppliers);

MERGE INTO Products P
USING STG_Product_Updates S
ON P.product_id = S.product_id
WHEN MATCHED THEN
    UPDATE SET
        product_name = S.product_name,
        sku = S.sku,
        category = S.category,
        price = S.price,
        stock_quantity = S.stock_quantity,
        supplier_id = S.supplier_id,
        last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN
    INSERT VALUES (
        S.product_id,
        S.product_name,
        S.sku,
        S.category,
        S.price,
        S.stock_quantity,
        S.supplier_id,
        CURRENT_TIMESTAMP
    );

INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
SELECT
    S.product_id,
    'UPDATE',
    P.price AS old_price,
    S.price AS new_price,
    P.stock_quantity AS old_stock,
    S.stock_quantity AS new_stock
FROM STG_Product_Updates S
JOIN Products P ON P.product_id = S.product_id
WHERE P.price != S.price OR P.stock_quantity != S.stock_quantity;

INSERT INTO Product_Change_Log (product_id, change_type)
SELECT
    S.product_id,
    'INSERT'
FROM STG_Product_Updates S
LEFT JOIN Products P ON P.product_id = S.product_id
WHERE P.product_id IS NULL;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-vl-8b
-- ============================================================================

-- SCORE: 12.5/100
-- SUCCESS RATE: 1/8 (12.5%)

-- BREAKDOWN:
-- ✅ Korrekt:  1 (Task 8)
-- ⚠️ Teilweise: 0
-- ❌ Fehler:   7 (Tasks 1, 2, 3, 4, 5, 6, 7)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Mehrstufiger ETL-Prozess korrekt (Task 8)
-- + MERGE Syntax verstanden (nur nicht vollständig ausgegeben)

-- WEAKNESSES:
-- - ALLE MERGE Statements fehlen "MERGE INTO ... USING" am Anfang!
-- - Task 6 komplett falsch (UNION ALL statt MERGE)
-- - Task 7 kein MERGE, kein Logging
-- - Task 5 vergisst Lagerbestand zu addieren

-- CRITICAL ERRORS:
-- - Tasks 1-5: ALLE MERGE Statements incomplete - fehlt "MERGE INTO Products p USING STG_Product_Updates"!
-- - Task 6: Komplett falsche Query (UNION ALL mit broken MERGE Syntax)!
-- - Task 7: Ist kein MERGE Statement und loggt nichts!

-- RECOMMENDATION:
-- 🔴 KATASTROPHAL für MERGE Statements!
-- Score ist DEUTLICH schlechter als qwen2.5-vl-7b (37.5% → 12.5%)!
-- Model hat massive Probleme mit MERGE Syntax - generiert immer incomplete Statements!

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
