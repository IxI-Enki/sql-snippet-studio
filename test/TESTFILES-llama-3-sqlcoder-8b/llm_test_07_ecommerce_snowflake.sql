-- ============================================================================
-- TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA + WINDOW + ROLLUP
-- ============================================================================
-- Domain: E-Commerce (Online-Shop)
-- Complexity: 🔴 Advanced
-- Focus: Snowflake-Schema mit Hierarchien, Window Functions, ROLLUP
-- Test Coverage: Normalized Dimensions, Deep Hierarchies, Complex Analytics
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! 3-stufige Snowflake JOINs korrekt

SELECT f.order_id, p.product_key, c.category_key, d.department_key FROM FACT_Order f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Category c ON p.category_key = c.category_key JOIN DIM_Department d ON c.department_key = d.department_key;


-- Aufgabe 2: Zeige alle Bestellungen mit vollständiger Standorthierarchie (Customer → City → Region → Country)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: Zeigt keine Bestellungen! Sollte FACT_Order joinen!
-- Bewertung: Hierarchie-JOINs korrekt, aber Fact-Tabelle fehlt

SELECT c.customer_key, c.customer_name, ci.city_key, ci.city_name, ri.region_key, ri.region_name, co.country_key, co.country_name FROM DIM_Customer AS c JOIN DIM_City AS ci ON c.city_key = ci.city_key JOIN DIM_Region AS ri ON ci.region_key = ri.region_key JOIN DIM_Country AS co ON ri.country_key = co.country_key;

-- ✅ KORRIGIERT: Mit FACT_Order
-- SELECT 
--     f.order_id,
--     c.customer_name,
--     ci.city_name,
--     ri.region_name,
--     co.country_name
-- FROM FACT_Order f
-- JOIN DIM_Customer c ON f.customer_key = c.customer_key
-- JOIN DIM_City ci ON c.city_key = ci.city_key
-- JOIN DIM_Region ri ON ci.region_key = ri.region_key
-- JOIN DIM_Country co ON ri.country_key = co.country_key;


-- Aufgabe 3: Berechne den Umsatz pro Department → Category → Product (3 Ebenen Hierarchie)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! Snowflake JOINs + Aggregation korrekt

SELECT d.department_name, c.category_name, p.product_name, SUM(f.total_amount) AS total_sales FROM DIM_Department d JOIN DIM_Category c ON d.department_key = c.department_key JOIN DIM_Product p ON c.category_key = p.category_key JOIN FACT_Order f ON p.product_key = f.product_key GROUP BY d.department_name, c.category_name, p.product_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (MULTI-LEVEL HIERARCHIES)
-- ============================================================================

-- Aufgabe 4: Berechne den Umsatz mit hierarchischen Subtotals nach Department, Category und Product (verwende ROLLUP)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! ROLLUP Syntax korrekt

SELECT d.department_name, c.category_name, p.product_name, SUM(f.total_amount) AS total_revenue FROM FACT_Order f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Category c ON p.category_key = c.category_key JOIN DIM_Department d ON c.department_key = d.department_key GROUP BY ROLLUP(d.department_name, c.category_name, p.product_name);


-- Aufgabe 5: Berechne den Umsatz mit hierarchischen Subtotals nach Country, Region und City (verwende ROLLUP mit GROUPING Funktion)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: GROUPING() Funktion fehlt! Aufgabe verlangt GROUPING!
-- Bewertung: ROLLUP korrekt, GROUPING fehlt

SELECT c.country_name, r.region_name, ci.city_name, SUM(f.total_amount) AS total_sales FROM FACT_Order f JOIN DIM_Customer cu ON f.customer_key = cu.customer_key JOIN DIM_City ci ON cu.city_key = ci.city_key JOIN DIM_Region r ON ci.region_key = r.region_key JOIN DIM_Country c ON r.country_key = c.country_key GROUP BY ROLLUP(c.country_name, r.region_name, ci.city_name);

-- ✅ KORRIGIERT: Mit GROUPING()
-- SELECT 
--     c.country_name,
--     r.region_name,
--     ci.city_name,
--     SUM(f.total_amount) AS total_sales,
--     GROUPING(c.country_name) AS is_country_total,
--     GROUPING(r.region_name) AS is_region_total,
--     GROUPING(ci.city_name) AS is_city_total
-- FROM FACT_Order f
-- JOIN DIM_Customer cu ON f.customer_key = cu.customer_key
-- JOIN DIM_City ci ON cu.city_key = ci.city_key
-- JOIN DIM_Region r ON ci.region_key = r.region_key
-- JOIN DIM_Country c ON r.country_key = c.country_key
-- GROUP BY ROLLUP(c.country_name, r.region_name, ci.city_name);


-- Aufgabe 6: Erstelle einen Bericht mit Subtotals nach Kontinent, Land und Region (ROLLUP über geografische Hierarchie)
-- Status: ❌ FALSCH
-- Problem: r.region_key = f.city_key macht keinen Sinn! FACT_Order hat keine city_key!
-- Bewertung: Komplett falsche JOIN-Bedingung

SELECT c.continent, r.region_name, SUM(f.total_amount) AS total_sales FROM DIM_Country c JOIN DIM_Region r ON c.country_key = r.country_key JOIN FACT_Order f ON r.region_key = f.city_key GROUP BY ROLLUP(c.continent, r.region_name);

-- ✅ KORRIGIERT: Korrekte JOINs über Customer
-- SELECT 
--     co.continent,
--     co.country_name,
--     r.region_name,
--     SUM(f.total_amount) AS total_sales
-- FROM FACT_Order f
-- JOIN DIM_Customer cu ON f.customer_key = cu.customer_key
-- JOIN DIM_City ci ON cu.city_key = ci.city_key
-- JOIN DIM_Region r ON ci.region_key = r.region_key
-- JOIN DIM_Country co ON r.country_key = co.country_key
-- GROUP BY ROLLUP(co.continent, co.country_name, r.region_name);


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS
-- ============================================================================

-- Aufgabe 7: Ranke Produkte nach Umsatz innerhalb jeder Kategorie (DENSE_RANK mit PARTITION BY category)
-- Status: ⚠️ TEILWEISE KORREKT
-- Problem: ORDER BY ASC statt DESC! Sollte absteigende Sortierung für Rankings sein!
-- Bewertung: Syntax korrekt, aber falsche Sortierreihenfolge

SELECT c.category_name, p.product_key, DENSE_RANK() OVER (PARTITION BY c.category_name ORDER BY SUM(f.total_amount)) AS sales_rank FROM DIM_Category c JOIN DIM_Product p ON c.category_key = p.category_key JOIN FACT_Order f ON p.product_key = f.product_key GROUP BY c.category_name, p.product_key;

-- ✅ KORRIGIERT: DESC für korrekte Rankings
-- SELECT 
--     c.category_name,
--     p.product_name,
--     SUM(f.total_amount) AS total_sales,
--     DENSE_RANK() OVER (
--         PARTITION BY c.category_name 
--         ORDER BY SUM(f.total_amount) DESC
--     ) AS sales_rank
-- FROM DIM_Category c
-- JOIN DIM_Product p ON c.category_key = p.category_key
-- JOIN FACT_Order f ON p.product_key = f.product_key
-- GROUP BY c.category_name, p.product_name;


-- Aufgabe 8: Berechne den durchschnittlichen Bestellwert pro Kunde mit Vergleich zum Durchschnitt seiner Loyalty Tier (Window Functions)
-- Status: ❌ FALSCH
-- Problem: Berechnet Running Average statt einfachen Average! ROWS BETWEEN UNBOUNDED PRECEDING ist falsch!
-- Bewertung: Versteht Aufgabe falsch

SELECT c.customer_key, AVG(o.total_amount) OVER (PARTITION BY c.loyalty_tier ORDER BY o.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS avg_total_per_loyalty_tier FROM DIM_Customer c JOIN FACT_Order o ON c.customer_key = o.customer_key;

-- ✅ KORRIGIERT: Durchschnitt pro Kunde vs. Tier-Durchschnitt
-- SELECT 
--     c.customer_key,
--     c.customer_name,
--     c.loyalty_tier,
--     AVG(o.total_amount) AS customer_avg_order_value,
--     AVG(AVG(o.total_amount)) OVER (PARTITION BY c.loyalty_tier) AS tier_avg_order_value
-- FROM DIM_Customer c
-- JOIN FACT_Order o ON c.customer_key = o.customer_key
-- GROUP BY c.customer_key, c.customer_name, c.loyalty_tier;


-- Aufgabe 9: Identifiziere die Top 3 Produkte pro Department nach Verkaufsmenge (Window Functions mit PARTITION BY)
-- Status: ❌ FALSCH
-- Problem 1: JOIN ON TRUE ist CROSS JOIN - erzeugt Cartesian Product!
-- Problem 2: Berechnet Cumulative Sales statt Top 3!
-- Bewertung: Komplett falsch - versteht Aufgabe nicht

SELECT d.department_name, p.product_key, SUM(f.quantity) OVER (PARTITION BY d.department_name ORDER BY f.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_sales FROM DIM_Department d JOIN FACT_Order f ON TRUE LEFT JOIN DIM_Product p ON f.product_key = p.product_key;

-- ✅ KORRIGIERT: Top 3 pro Department mit ROW_NUMBER
-- WITH product_sales AS (
--     SELECT 
--         d.department_name,
--         p.product_name,
--         SUM(f.quantity) AS total_quantity,
--         ROW_NUMBER() OVER (
--             PARTITION BY d.department_name 
--             ORDER BY SUM(f.quantity) DESC
--         ) AS rank_in_dept
--     FROM FACT_Order f
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     JOIN DIM_Category c ON p.category_key = c.category_key
--     JOIN DIM_Department d ON c.department_key = d.department_key
--     GROUP BY d.department_name, p.product_name
-- )
-- SELECT 
--     department_name,
--     product_name,
--     total_quantity,
--     rank_in_dept
-- FROM product_sales
-- WHERE rank_in_dept <= 3
-- ORDER BY department_name, rank_in_dept;


-- ============================================================================
-- TEST TASKS - CONVERSION RATE ANALYSIS
-- ============================================================================

-- Aufgabe 10: Berechne die Conversion Rate pro Produktkategorie (abgeschlossene Bestellungen / Gesamtbestellungen)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! CASE WHEN + CAST korrekt

SELECT c.category_name, CAST(SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0) AS conversion_rate FROM FACT_Order o JOIN DIM_Product p ON o.product_key = p.product_key JOIN DIM_Category c ON p.category_key = c.category_key GROUP BY c.category_name;


-- Aufgabe 11: Berechne die Return Rate pro Department (zurückgegebene Bestellungen / abgeschlossene Bestellungen)
-- Status: ❌ FALSCH
-- Problem: d.department_key = o.customer_key macht keinen Sinn! Falsche JOIN-Bedingung!
-- Bewertung: Komplett falscher JOIN

SELECT d.department_name, CAST(SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(o.order_id), 0) AS return_rate FROM DIM_Department d JOIN FACT_Order o ON d.department_key = o.customer_key GROUP BY d.department_name;

-- ✅ KORRIGIERT: Korrekte JOINs über Product/Category
-- SELECT 
--     d.department_name,
--     CAST(SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS FLOAT) / 
--     NULLIF(SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END), 0) AS return_rate
-- FROM FACT_Order o
-- JOIN DIM_Product p ON o.product_key = p.product_key
-- JOIN DIM_Category c ON p.category_key = c.category_key
-- JOIN DIM_Department d ON c.department_key = d.department_key
-- GROUP BY d.department_name;


-- ============================================================================
-- TEST TASKS - CUSTOMER SEGMENTATION
-- ============================================================================

-- Aufgabe 12: Segmentiere Kunden in Quartile basierend auf ihrem Gesamtumsatz (verwende NTILE Window Function)
-- Status: ✅ KORREKT
-- Bewertung: Perfekt! NTILE + Aggregation korrekt (GROUP BY 1,2 ist ok)

SELECT c.customer_key, c.customer_name, ntile(4) OVER (ORDER BY SUM(f.total_amount)) AS sales_quartile FROM DIM_Customer c JOIN FACT_Order f ON c.customer_key = f.customer_key GROUP BY 1, 2;


-- Aufgabe 13: Finde alle Kunden die im obersten Quartil ihres Landes liegen (NTILE mit PARTITION BY country)
-- Status: ❌ FALSCH
-- Problem: Window Function in WHERE ist ungültig! + sortiert nach registration_date statt Umsatz!
-- Bewertung: Syntaktisch falsch + falsche Sortierung

SELECT c.customer_key, c.customer_name FROM DIM_Customer c JOIN DIM_City d ON c.city_key = d.city_key JOIN DIM_Region r ON d.region_key = r.region_key JOIN DIM_Country p ON r.country_key = p.country_key WHERE ntile(4) OVER (PARTITION BY p.country_code ORDER BY c.registration_date) = 4;

-- ✅ KORRIGIERT: Mit CTE + Sortierung nach Umsatz
-- WITH customer_sales AS (
--     SELECT 
--         c.customer_key,
--         c.customer_name,
--         co.country_name,
--         SUM(f.total_amount) AS total_sales,
--         NTILE(4) OVER (
--             PARTITION BY co.country_name 
--             ORDER BY SUM(f.total_amount) DESC
--         ) AS sales_quartile
--     FROM DIM_Customer c
--     JOIN DIM_City ci ON c.city_key = ci.city_key
--     JOIN DIM_Region r ON ci.region_key = r.region_key
--     JOIN DIM_Country co ON r.country_key = co.country_key
--     JOIN FACT_Order f ON c.customer_key = f.customer_key
--     GROUP BY c.customer_key, c.customer_name, co.country_name
-- )
-- SELECT 
--     customer_name,
--     country_name,
--     total_sales
-- FROM customer_sales
-- WHERE sales_quartile = 1;  -- Quartil 1 = Top 25%


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 60-75 (Sehr komplex, viele JOINs über Hierarchien)
-- Parser Challenge: Very High (Deep JOINs, Multi-Level ROLLUP)
-- Model Compatibility: Advanced models only
-- Special Focus:
--   - Korrekte JOINs über mehrere Hierarchie-Ebenen
--   - ROLLUP muss die richtige Reihenfolge haben
--   - GROUPING() Funktion zum Unterscheiden von echten NULLs und Subtotals
--   - Window Functions mit komplexen PARTITION BY
-- ============================================================================
