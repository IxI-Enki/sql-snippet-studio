-- ============================================================================
-- TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA + WINDOW + ROLLUP
-- ============================================================================
-- Domain: E-Commerce (Online-Shop)
-- Complexity: 🔴 Advanced
-- Focus: Snowflake-Schema mit Hierarchien, Window Functions, ROLLUP
-- Test Coverage: Normalized Dimensions, Deep Hierarchies, Complex Analytics
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

-- ============================================================================
-- SCHEMA: E-Commerce Snowflake Schema (Normalized Dimensions)
-- ============================================================================

-- PRODUCT HIERARCHY (Snowflake: Department → Category → Product)
CREATE TABLE DIM_Department (
    department_key SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    department_code VARCHAR(20) UNIQUE
);

CREATE TABLE DIM_Category (
    category_key SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    category_code VARCHAR(20) UNIQUE,
    department_key INT REFERENCES DIM_Department(department_key)
);

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    sku VARCHAR(50) UNIQUE,
    category_key INT REFERENCES DIM_Category(category_key),
    price DECIMAL(10,2),
    weight_kg DECIMAL(8,3),
    rating DECIMAL(3,2)
);

-- LOCATION HIERARCHY (Snowflake: Country → Region → City → Customer)
CREATE TABLE DIM_Country (
    country_key SERIAL PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(3) UNIQUE,
    continent VARCHAR(50)
);

CREATE TABLE DIM_Region (
    region_key SERIAL PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    country_key INT REFERENCES DIM_Country(country_key)
);

CREATE TABLE DIM_City (
    city_key SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL,
    region_key INT REFERENCES DIM_Region(region_key),
    postal_code VARCHAR(20)
);

CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    city_key INT REFERENCES DIM_City(city_key),
    registration_date DATE,
    loyalty_tier VARCHAR(20)  -- 'Bronze', 'Silver', 'Gold', 'Platinum'
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

-- FACT TABLE
CREATE TABLE FACT_Order (
    order_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    product_key INT REFERENCES DIM_Product(product_key),
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    shipping_cost DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    order_status VARCHAR(20)  -- 'Completed', 'Cancelled', 'Returned'
);

-- ============================================================================
-- TEST TASKS - SNOWFLAKE SCHEMA QUERIES (DEEP HIERARCHIES)
-- ============================================================================

-- Aufgabe 1: Zeige alle Bestellungen mit vollständiger Produkthierarchie (Product → Category → Department)

-- ✅ PERFEKT (Score: 100/100)
--    Alle 3 Hierarchie-Ebenen korrekt verknüpft!

SELECT 
    f.order_id,
    p.product_name,
    c.category_name,
    d.department_name
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
JOIN DIM_Department d ON c.department_key = d.department_key;

-- Aufgabe 2: Zeige alle Bestellungen mit vollständiger Standorthierarchie (Customer → City → Region → Country)

-- ✅ PERFEKT (Score: 100/100)
--    Alle 4 Hierarchie-Ebenen korrekt verknüpft!

SELECT 
    f.order_id,
    c.customer_name,
    ci.city_name,
    reg.region_name,
    co.country_name
FROM FACT_Order f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_City ci ON c.city_key = ci.city_key
JOIN DIM_Region reg ON ci.region_key = reg.region_key
JOIN DIM_Country co ON reg.country_key = co.country_key;


-- Aufgabe 3: Berechne den Umsatz pro Department → Category → Product (3 Ebenen Hierarchie)

-- ✅ PERFEKT (Score: 100/100)
--    Hierarchie-JOINs korrekt, Gruppierung korrekt, Berechnung korrekt!

SELECT 
    d.department_name,
    cat.category_name,
    p.product_name,
    SUM(f.quantity * f.unit_price) AS total_revenue
FROM DIM_Department d
JOIN DIM_Category cat ON d.department_key = cat.department_key
JOIN DIM_Product p ON cat.category_key = p.category_key
JOIN FACT_Order f ON p.product_key = f.product_key
GROUP BY d.department_name, cat.category_name, p.product_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (MULTI-LEVEL HIERARCHIES)
-- ============================================================================

-- Aufgabe 4: Berechne den Umsatz mit hierarchischen Subtotals nach Department, Category und Product (verwende ROLLUP)

-- ✅ PERFEKT (Score: 100/100)
--    ROLLUP mit korrekter PostgreSQL Syntax!
--    Hierarchie in richtiger Reihenfolge!

SELECT 
    d.department_name,
    cat.category_name,
    p.product_name,
    SUM(f.quantity * f.unit_price) AS total_revenue
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category cat ON p.category_key = cat.category_key
JOIN DIM_Department d ON cat.department_key = d.department_key
GROUP BY ROLLUP (d.department_name, cat.category_name, p.product_name);


-- Aufgabe 5: Berechne den Umsatz mit hierarchischen Subtotals nach Country, Region und City (verwende ROLLUP mit GROUPING Funktion)

-- ❌ FAILED (Score: 40/100)
--    FEHLT: GROUPING() Funktion! Die Aufgabe verlangt explizit GROUPING!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!

SELECT 
    c.country_name,
    r.region_name,
    ci.city_name,
    SUM(f.total_amount) AS total_revenue
FROM FACT_Order f
JOIN DIM_Customer cust ON f.customer_key = cust.customer_key
JOIN DIM_City ci ON cust.city_key = ci.city_key
JOIN DIM_Region r ON ci.region_key = r.region_key
JOIN DIM_Country c ON r.country_key = c.country_key
GROUP BY c.country_name, r.region_name, ci.city_name WITH ROLLUP;

-- KORREKTE LÖSUNG:
-- SELECT 
--     c.country_name,
--     r.region_name,
--     ci.city_name,
--     SUM(f.total_amount) AS total_revenue,
--     GROUPING(c.country_name) AS is_country_subtotal,
--     GROUPING(r.region_name) AS is_region_subtotal,
--     GROUPING(ci.city_name) AS is_city_subtotal
-- FROM FACT_Order f
-- JOIN DIM_Customer cust ON f.customer_key = cust.customer_key
-- JOIN DIM_City ci ON cust.city_key = ci.city_key
-- JOIN DIM_Region r ON ci.region_key = r.region_key
-- JOIN DIM_Country c ON r.country_key = c.country_key
-- GROUP BY ROLLUP(c.country_name, r.region_name, ci.city_name);


-- Aufgabe 6: Erstelle einen Bericht mit Subtotals nach Kontinent, Land und Region (ROLLUP über geografische Hierarchie)

-- ❌ SYNTAX-FEHLER (Score: 10/100)
--    FEHLER: "c.continent" aber keine JOIN zu DIM_Country AS c!
--    FEHLER: JOIN zu DIM_Time macht keinen Sinn (t.time_key = f.time_key zweimal)!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL!

SELECT 
    c.continent,
    co.country_name,
    r.region_name,
    COUNT(f.order_id) AS order_count
FROM DIM_Country co
JOIN DIM_Region r ON co.country_key = r.country_key
JOIN DIM_Time t ON t.time_key = f.time_key
JOIN FACT_Order f ON f.time_key = t.time_key
GROUP BY c.continent, co.country_name, r.region_name WITH ROLLUP;

-- KORREKTE LÖSUNG:
-- SELECT 
--     co.continent,
--     co.country_name,
--     r.region_name,
--     COUNT(f.order_id) AS order_count
-- FROM FACT_Order f
-- JOIN DIM_Customer cust ON f.customer_key = cust.customer_key
-- JOIN DIM_City ci ON cust.city_key = ci.city_key
-- JOIN DIM_Region r ON ci.region_key = r.region_key
-- JOIN DIM_Country co ON r.country_key = co.country_key
-- GROUP BY ROLLUP(co.continent, co.country_name, r.region_name);


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS
-- ============================================================================

-- Aufgabe 7: Ranke Produkte nach Umsatz innerhalb jeder Kategorie (DENSE_RANK mit PARTITION BY category)

-- ⚠️ TEILWEISE KORREKT (Score: 80/100)
--    PROBLEM: GROUP BY fehlt c.category_key!
--    DENSE_RANK() braucht c.category_key in GROUP BY für PARTITION BY!
--    Funktioniert aber in vielen DBs trotzdem (implizite Gruppierung)

SELECT 
    p.product_name,
    c.category_name,
    SUM(f.quantity * f.unit_price) AS total_revenue,
    DENSE_RANK() OVER (PARTITION BY c.category_key ORDER BY SUM(f.quantity * f.unit_price) DESC) AS revenue_rank
FROM 
    FACT_Order f
JOIN 
    DIM_Product p ON f.product_key = p.product_key
JOIN 
    DIM_Category c ON p.category_key = c.category_key
GROUP BY 
    p.product_name, c.category_name
ORDER BY 
    c.category_key, revenue_rank;

-- KORREKTE LÖSUNG:
-- SELECT 
--     p.product_name,
--     c.category_name,
--     SUM(f.quantity * f.unit_price) AS total_revenue,
--     DENSE_RANK() OVER (PARTITION BY c.category_key ORDER BY SUM(f.quantity * f.unit_price) DESC) AS revenue_rank
-- FROM FACT_Order f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- JOIN DIM_Category c ON p.category_key = c.category_key
-- GROUP BY p.product_key, p.product_name, c.category_key, c.category_name
-- ORDER BY c.category_key, revenue_rank;


-- Aufgabe 8: Berechne den durchschnittlichen Bestellwert pro Kunde mit Vergleich zum Durchschnitt seiner Loyalty Tier (Window Functions)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!

-- KORREKTE LÖSUNG:
-- SELECT 
--     c.customer_name,
--     c.loyalty_tier,
--     AVG(f.total_amount) AS avg_order_value,
--     AVG(AVG(f.total_amount)) OVER (PARTITION BY c.loyalty_tier) AS tier_avg_order_value,
--     AVG(f.total_amount) - AVG(AVG(f.total_amount)) OVER (PARTITION BY c.loyalty_tier) AS difference_from_tier_avg
-- FROM DIM_Customer c
-- JOIN FACT_Order f ON c.customer_key = f.customer_key
-- GROUP BY c.customer_key, c.customer_name, c.loyalty_tier;

-- Aufgabe 9: Identifiziere die Top 3 Produkte pro Department nach Verkaufsmenge (Window Functions mit PARTITION BY)

-- ❌ FAILED (Score: 20/100)
--    FEHLT: Window Function mit PARTITION BY!
--    LIMIT 3 zeigt nur TOP 3 INSGESAMT, nicht PRO Department!
--    SOLLTE: ROW_NUMBER() OVER (PARTITION BY department ...) verwenden

SELECT 
    p.product_name,
    d.department_name,
    SUM(f.quantity) AS total_quantity
FROM 
    FACT_Order f
JOIN 
    DIM_Product p ON f.product_key = p.product_key
JOIN 
    DIM_Category c ON p.category_key = c.category_key
JOIN 
    DIM_Department d ON c.department_key = d.department_key
GROUP BY 
    p.product_name, d.department_name
ORDER BY 
    d.department_name, total_quantity DESC
LIMIT 3;

-- KORREKTE LÖSUNG:
-- WITH ranked_products AS (
--     SELECT 
--         p.product_name,
--         d.department_name,
--         SUM(f.quantity) AS total_quantity,
--         ROW_NUMBER() OVER (PARTITION BY d.department_key ORDER BY SUM(f.quantity) DESC) AS rank
--     FROM FACT_Order f
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     JOIN DIM_Category c ON p.category_key = c.category_key
--     JOIN DIM_Department d ON c.department_key = d.department_key
--     GROUP BY p.product_key, p.product_name, d.department_key, d.department_name
-- )
-- SELECT product_name, department_name, total_quantity
-- FROM ranked_products
-- WHERE rank <= 3;


-- ============================================================================
-- TEST TASKS - CONVERSION RATE ANALYSIS
-- ============================================================================

-- Aufgabe 10: Berechne die Conversion Rate pro Produktkategorie (abgeschlossene Bestellungen / Gesamtbestellungen)

-- ✅ PERFEKT (Score: 100/100)
--    FILTER Klausel korrekt verwendet (PostgreSQL Syntax)!
--    Berechnung korrekt!

SELECT 
    c.category_name,
    COUNT(f.order_id) FILTER (WHERE f.order_status = 'Completed') * 1.0 / COUNT(f.order_id) AS conversion_rate
FROM 
    DIM_Category c
    JOIN DIM_Product p ON c.category_key = p.category_key
    JOIN FACT_Order f ON p.product_key = f.product_key
GROUP BY 
    c.category_name;


-- Aufgabe 11: Berechne die Return Rate pro Department (zurückgegebene Bestellungen / abgeschlossene Bestellungen)

-- ⚠️ TEILWEISE KORREKT (Score: 70/100)
--    PROBLEM: Aufgabe sagt "zurückgegeben / abgeschlossen"
--    Aber Query zeigt "zurückgegeben / GESAMT"!
--    Nenner sollte nur "Completed" sein, nicht alle!

SELECT 
    d.department_name,
    COUNT(f.order_id) FILTER (WHERE f.order_status = 'Returned') * 1.0 / COUNT(f.order_id) AS return_rate
FROM 
    FACT_Order f
JOIN 
    DIM_Product p ON f.product_key = p.product_key
JOIN 
    DIM_Category c ON p.category_key = c.category_key
JOIN 
    DIM_Department d ON c.department_key = d.department_key
GROUP BY 
    d.department_name;

-- KORREKTE LÖSUNG:
-- SELECT 
--     d.department_name,
--     COUNT(f.order_id) FILTER (WHERE f.order_status = 'Returned') * 1.0 / 
--     NULLIF(COUNT(f.order_id) FILTER (WHERE f.order_status = 'Completed'), 0) AS return_rate
-- FROM FACT_Order f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- JOIN DIM_Category c ON p.category_key = c.category_key
-- JOIN DIM_Department d ON c.department_key = d.department_key
-- GROUP BY d.department_name;


-- ============================================================================
-- TEST TASKS - CUSTOMER SEGMENTATION
-- ============================================================================

-- Aufgabe 12: Segmentiere Kunden in Quartile basierend auf ihrem Gesamtumsatz (verwende NTILE Window Function)

-- ✅ PERFEKT (Score: 100/100)
--    NTILE(4) korrekt verwendet!
--    Gruppierung korrekt, ORDER BY korrekt!

SELECT 
    c.customer_name,
    NTILE(4) OVER (ORDER BY SUM(f.total_amount) DESC) AS quartile
FROM 
    DIM_Customer c
JOIN 
    FACT_Order f ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key, c.customer_name
ORDER BY 
    quartile, c.customer_name;


-- Aufgabe 13: Finde alle Kunden die im obersten Quartil ihres Landes liegen (NTILE mit PARTITION BY country)

-- ❌ FAILED (Score: 0/100)
--    FEHLT: NTILE Window Function komplett!
--    FEHLT: Keine Berechnung, kein Quartil!
--    FEHLER: JOIN zu DIM_Time macht keinen Sinn (customer_key = time_key?!)
--    Query zeigt nur Kundenliste, keine Quartile!

SELECT 
    c.customer_name,
    c.city_key,
    r.region_name,
    d.country_name
FROM DIM_Customer c
JOIN DIM_City ci ON c.city_key = ci.city_key
JOIN DIM_Region r ON ci.region_key = r.region_key
JOIN DIM_Country d ON r.country_key = d.country_key
JOIN DIM_Time t ON c.customer_key = t.time_key
ORDER BY d.country_name, t.year, t.quarter;

-- KORREKTE LÖSUNG:
-- WITH customer_quartiles AS (
--     SELECT 
--         c.customer_name,
--         co.country_name,
--         SUM(f.total_amount) AS total_revenue,
--         NTILE(4) OVER (PARTITION BY co.country_key ORDER BY SUM(f.total_amount) DESC) AS quartile
--     FROM DIM_Customer c
--     JOIN FACT_Order f ON c.customer_key = f.customer_key
--     JOIN DIM_City ci ON c.city_key = ci.city_key
--     JOIN DIM_Region r ON ci.region_key = r.region_key
--     JOIN DIM_Country co ON r.country_key = co.country_key
--     GROUP BY c.customer_key, c.customer_name, co.country_key, co.country_name
-- )
-- SELECT customer_name, country_name, total_revenue
-- FROM customer_quartiles
-- WHERE quartile = 1;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 56.2/100 ⭐⭐⭐
-- SUCCESS RATE: 38.5% (5/13 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1:  100/100 - Perfekt (Produkthierarchie JOINs)
--   ✅ Aufgabe 2:  100/100 - Perfekt (Standorthierarchie JOINs)
--   ✅ Aufgabe 3:  100/100 - Perfekt (3 Ebenen Hierarchie Aggregation)
--   ✅ Aufgabe 4:  100/100 - Perfekt (ROLLUP PostgreSQL Syntax!)
--   ❌ Aufgabe 5:   40/100 - Fehlt GROUPING() + MySQL Syntax
--   ❌ Aufgabe 6:   10/100 - Alias-Fehler + sinnloser JOIN zu DIM_Time
--   ⚠️ Aufgabe 7:   80/100 - Fehlt category_key in GROUP BY
--   ❌ Aufgabe 8:    0/100 - NICHT generiert!
--   ❌ Aufgabe 9:   20/100 - LIMIT 3 statt PARTITION BY (zeigt nur Top 3 INSGESAMT)
--   ✅ Aufgabe 10: 100/100 - Perfekt (FILTER Klausel)
--   ⚠️ Aufgabe 11:  70/100 - Falsche Berechnungslogik (Nenner falsch)
--   ✅ Aufgabe 12: 100/100 - Perfekt (NTILE)
--   ❌ Aufgabe 13:   0/100 - Fehlt NTILE komplett + sinnloser JOIN
--
-- STÄRKEN:
--   + Snowflake Schema JOINs perfekt verstanden (3-4 Ebenen)
--   + ROLLUP mit PostgreSQL Syntax korrekt (endlich!)
--   + FILTER Klausel (PostgreSQL) verstanden
--   + NTILE ohne PARTITION BY korrekt
--   + Hierarchie-Traversierung korrekt
--
-- SCHWÄCHEN:
--   - GROUPING() Funktion: NICHT VERWENDET!
--   - NTILE mit PARTITION BY: FAILED!
--   - Window Functions "PRO X": VERGESSEN (LIMIT statt PARTITION BY)
--   - Sinnlose JOINs zu nicht-benötigten Tabellen
--   - Inkonsistente ROLLUP Syntax (mal richtig, mal MySQL)
--
-- KRITISCHE FEHLER:
--   ⚠️ PARTITION BY vergessen bei "Top X PRO Y" Aufgaben
--   ⚠️ GROUPING() wird nicht verwendet, obwohl explizit verlangt
--   ⚠️ Sinnlose JOINs (customer_key = time_key?!)
--
-- EMPFEHLUNG: ⚠️ BEDINGT geeignet für Snowflake Schemas
--              Gut für: Hierarchie-JOINs, einfache Aggregationen
--              NICHT für: NTILE + PARTITION BY, GROUPING()
-- ============================================================================
