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
WHEN MATCHED THEN 
    UPDATE SET product_name = s.product_name, sku = s.sku, category = s.category, price = s.price, stock_quantity = s.stock_quantity, supplier_id = s.supplier_id, last_updated = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN 
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id) 
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);
    
-- ✅ STATUS: PERFEKT!
  -- ✅ MERGE INTO Products p → korrekt!
  -- ✅ USING (SELECT ...) s → korrekt!
  -- ✅ ON (p.product_id = s.product_id) → korrekt!
  -- ✅ WHEN MATCHED THEN UPDATE SET → korrekt!
  -- ✅ WHEN NOT MATCHED THEN INSERT → korrekt!
  -- 🎯 IMPACT: v1.7.0 (0% - Parser kaputt) → v1.7.1 (100% - Parser fixed!)

------------------------------------------------------------------------------------------------------------------------

-- Aufgabe 2: Erweitere den MERGE Statement um nur Produkte zu updaten bei denen sich der Preis geändert hat

MERGE INTO products p
USING (
    SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
    FROM stg_product_updates
) s
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
    WHERE p.price <> s.price
WHEN NOT MATCHED THEN 
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);

-- ✅ STATUS: PERFEKT!
  -- ✅ MERGE INTO products p → korrekt!
  -- ✅ WHERE p.price <> s.price → Preisänderungs-Filter korrekt implementiert!
  -- ✅ UPDATE nur bei Preisänderung → Anforderung erfüllt!
  -- 💡 NOTE: Alle anderen Felder werden auch aktualisiert (nicht nur price), aber nur wenn Preis sich geändert hat!

------------------------------------------------------------------------------------------------------------------------


-- Aufgabe 3: Erstelle einen MERGE Statement der Produkte löscht die in Products existieren aber nicht in STG_Product_Updates (WHEN NOT MATCHED BY SOURCE THEN DELETE)
-- ❌ STATUS: SYNTAX FEHLER (PostgreSQL nicht kompatibel!)
-- ❌ "WHEN NOT MATCHED BY SOURCE" → SQL Server Syntax, PostgreSQL unterstützt das NICHT!
-- ✅ MERGE INTO products p → korrekt
-- ✅ USING (SELECT ...) s → korrekt
-- ❌ PostgreSQL LÖSUNG:
--    DELETE FROM products WHERE product_id NOT IN (SELECT product_id FROM stg_product_updates);
-- 💡 Oracle/SQL Server unterstützen "BY SOURCE", PostgreSQL nicht!

MERGE INTO products p
USING (SELECT product_id FROM stg_product_updates) s
ON (p.product_id = s.product_id)
WHEN NOT MATCHED BY SOURCE THEN DELETE;

-- ✅ KORRIGIERT (PostgreSQL):
-- DELETE FROM products 
-- WHERE product_id NOT IN (SELECT product_id FROM stg_product_updates);


-- ============================================================================
-- TEST TASKS - CONDITIONAL MERGE
-- ============================================================================

-- Aufgabe 4: Erstelle einen MERGE Statement der nur Produkte updatet bei denen der Preis um mehr als 10 Prozent geändert wurde
-- ✅ STATUS: PERFEKT!
-- ✅ MERGE INTO Products p → korrekt!
-- ✅ WHERE ABS(p.price - s.price) > p.price * 0.1 → 10% Preisänderung korrekt berechnet!
-- ✅ ABS() für absolute Differenz → berücksichtigt Preissteigerungen UND -senkungen!
-- 💡 EXCELLENT: Komplexe mathematische Bedingung korrekt implementiert!

MERGE INTO Products p
USING (
    SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
    FROM STG_Product_Updates
) s ON (p.product_id = s.product_id)
WHEN MATCHED THEN
    UPDATE SET 
        product_name = s.product_name,
        sku = s.sku,
        category = s.category,
        price = s.price,
        stock_quantity = s.stock_quantity,
        supplier_id = s.supplier_id,
        last_updated = CURRENT_TIMESTAMP
    WHERE ABS(p.price - s.price) > p.price * 0.1;


-- Aufgabe 5: Erstelle einen MERGE Statement der neue Produkte einfügt, Preise updatet wenn sie sich geändert haben, und den Lagerbestand addiert statt ersetzt
-- ✅ STATUS: PERFEKT!
-- ✅ MERGE INTO Products p → korrekt!
-- ✅ price = CASE WHEN p.price <> s.price THEN s.price ELSE p.price END → Preis nur bei Änderung updaten!
-- ✅ stock_quantity = p.stock_quantity + s.stock_quantity → Lagerbestand ADDIERT statt ersetzt!
-- ✅ WHEN NOT MATCHED THEN INSERT → neue Produkte einfügen!
-- 🎯 EXCELLENT: Alle 3 Anforderungen korrekt implementiert!

MERGE INTO Products p
USING (
    SELECT 
        product_id,
        product_name,
        sku,
        category,
        price,
        stock_quantity,
        supplier_id
    FROM STG_Product_Updates
) s ON (p.product_id = s.product_id)
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
-- ✅ STATUS: KORREKT (PostgreSQL Workaround)!
-- ✅ MERGE INTO Products p → korrekt!
-- ✅ WHERE p.price <> s.price OR p.stock_quantity <> s.stock_quantity → nur bei Änderungen updaten!
-- ✅ Separates INSERT für Logging → PostgreSQL unterstützt OUTPUT nicht, daher separate INSERT!
-- 💡 NOTE: In SQL Server würde man OUTPUT $action, inserted.*, deleted.* verwenden
-- 💡 PostgreSQL Lösung: Separate INSERT nach MERGE (korrekt!)
-- ⚠️ LIMITATION: Logging passiert NACH MERGE, nicht während (aber akzeptabel für PostgreSQL)

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
    WHERE p.price <> s.price OR p.stock_quantity <> s.stock_quantity
WHEN NOT MATCHED THEN
    INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
    VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id);

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
-- ⚠️ STATUS: LOGIK FEHLER!
-- ❌ WHERE product_id IN (SELECT ... FROM STG_Product_Updates WHERE stock_quantity < 10)
--    → Prüft stock_quantity in STG_Product_Updates, sollte aber in Products prüfen!
-- ✅ UPDATE Products → korrekt
-- ✅ RETURNING → PostgreSQL Syntax für Logging (korrekt!)
-- ❌ stock_quantity = stock_quantity - 1 → reduziert um 1, sollte aber aus STG_Product_Updates holen!
-- ❌ KORRIGIERT:
--    WHERE product_id IN (SELECT product_id FROM Products WHERE stock_quantity < 10)
--    ODER: WHERE stock_quantity < 10 (direkt auf Products prüfen)

UPDATE Products 
SET stock_quantity = stock_quantity - 1,
    last_updated = CURRENT_TIMESTAMP
WHERE product_id IN (
    SELECT product_id 
    FROM STG_Product_Updates 
    WHERE stock_quantity < 10
)
RETURNING product_id, stock_quantity, last_updated;

-- ✅ KORRIGIERT (Logik fix):
-- UPDATE Products 
-- SET stock_quantity = s.stock_quantity,
--     last_updated = CURRENT_TIMESTAMP
-- FROM STG_Product_Updates s
-- WHERE Products.product_id = s.product_id 
--   AND Products.stock_quantity < 10
-- RETURNING Products.product_id, Products.stock_quantity, Products.last_updated;


-- ============================================================================
-- TEST TASKS - COMPLEX MERGE
-- ============================================================================

-- Aufgabe 8: Erstelle einen mehrstufigen ETL Prozess (1) Lade neue Supplier aus Staging (2) Lade neue Produkte mit MERGE (3) Logge alle Änderungen
-- ❌ STATUS: SYNTAX FEHLER (PostgreSQL Limitation)!
-- ❌ MERGE kann NICHT in CTE (WITH) verwendet werden in PostgreSQL!
-- ✅ WITH new_suppliers AS (INSERT ... RETURNING) → korrekt für PostgreSQL!
-- ❌ WITH updated_products AS (MERGE ...) → NICHT unterstützt in PostgreSQL!
-- 💡 PostgreSQL erlaubt in WITH nur: SELECT, INSERT, UPDATE, DELETE (aber NICHT MERGE!)
-- 🎯 ABER: Model generierte sehr komplexe, strukturierte Query! (Timeout 200000ms benötigt!)
-- 💡 NOTE: User musste Timeout auf 200000 setzen → Model brauchte lange zum Generieren!
-- ⚠️ KORREKTUR: MERGE außerhalb von WITH ausführen, dann separate INSERTs für Logging

!!! DAFÜR MUSSTE ICH DEN TIMEOUT ABER IN DEN SETTINGS AUF 200000 SETZEN !!! SONST TIMEOUT ERROR


WITH new_suppliers AS (
    INSERT INTO Suppliers (supplier_id, supplier_name, country, contact_email)
    SELECT DISTINCT s.supplier_id, s.supplier_name, s.country, s.contact_email
    FROM STG_Product_Updates s
    LEFT JOIN Suppliers t ON s.supplier_id = t.supplier_id
    WHERE t.supplier_id IS NULL
    RETURNING supplier_id, supplier_name, country, contact_email
),
updated_products AS (
    MERGE INTO Products p
    USING (
        SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
        FROM STG_Product_Updates
    ) s ON (p.product_id = s.product_id)
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
        INSERT (product_id, product_name, sku, category, price, stock_quantity, supplier_id)
        VALUES (s.product_id, s.product_name, s.sku, s.category, s.price, s.stock_quantity, s.supplier_id)
),
log_changes AS (
    INSERT INTO Product_Change_Log (product_id, change_type, old_price, new_price, old_stock, new_stock)
    SELECT 
        p.product_id,
        CASE WHEN t.product_id IS NULL THEN 'INSERT' ELSE 'UPDATE' END,
        t.price,
        p.price,
        t.stock_quantity,
        p.stock_quantity
    FROM Products p
    LEFT JOIN updated_products t ON p.product_id = t.product_id
    WHERE t.product_id IS NOT NULL OR (t.product_id IS NULL AND EXISTS (
        SELECT 1 FROM STG_Product_Updates s WHERE s.product_id = p.product_id
    ))
)
SELECT * FROM new_suppliers;

-- ✅ KORRIGIERT (PostgreSQL kompatibel):
-- -- Step 1: Insert new suppliers
-- WITH new_suppliers AS (
--     INSERT INTO Suppliers (supplier_id, supplier_name, country, contact_email)
--     SELECT DISTINCT s.supplier_id, s.supplier_name, s.country, s.contact_email
--     FROM STG_Product_Updates s
--     LEFT JOIN Suppliers t ON s.supplier_id = t.supplier_id
--     WHERE t.supplier_id IS NULL
--     RETURNING supplier_id
-- )
-- SELECT COUNT(*) AS new_suppliers_count FROM new_suppliers;
-- 
-- -- Step 2: MERGE products (außerhalb von CTE)
-- MERGE INTO Products p
-- USING (
--     SELECT product_id, product_name, sku, category, price, stock_quantity, supplier_id
--     FROM STG_Product_Updates
-- ) s ON (p.product_id = s.product_id)
-- WHEN MATCHED THEN UPDATE SET product_name = s.product_name, ...
-- WHEN NOT MATCHED THEN INSERT (product_id, ...) VALUES (s.product_id, ...);
-- 
-- -- Step 3: Log changes
-- INSERT INTO Product_Change_Log (product_id, change_type, ...)
-- SELECT p.product_id, 'UPDATE', ...
-- FROM Products p
-- JOIN STG_Product_Updates s ON p.product_id = s.product_id;


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
