-- ============================================================================
-- TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA + ADVANCED WINDOW + ROLLUP
-- ============================================================================
-- Domain: E-Commerce / Online Retail
-- Complexity: 🔴 Advanced
-- Focus: Snowflake Schema, Komplexe JOINs, Window Functions, ROLLUP
-- Test Coverage: Denormalized Dimensions, Deep Hierarchies, Web Analytics
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

-- ============================================================================
-- SCHEMA: E-Commerce Snowflake Schema
-- ============================================================================

-- Core Dimension: Customer (mit Snowflake-Normalisierung)
CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) UNIQUE,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city_key INT,  -- Snowflake: verweist auf DIM_City
    registration_date DATE,
    customer_tier VARCHAR(20)  -- 'Bronze', 'Silver', 'Gold', 'Platinum'
);

CREATE TABLE DIM_City (
    city_key SERIAL PRIMARY KEY,
    city_name VARCHAR(100),
    region_key INT  -- Snowflake: verweist auf DIM_Region
);

CREATE TABLE DIM_Region (
    region_key SERIAL PRIMARY KEY,
    region_name VARCHAR(100),
    country_key INT  -- Snowflake: verweist auf DIM_Country
);

CREATE TABLE DIM_Country (
    country_key SERIAL PRIMARY KEY,
    country_name VARCHAR(100),
    continent VARCHAR(50)
);

-- Core Dimension: Product (mit Snowflake-Normalisierung)
CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_id VARCHAR(50) UNIQUE,
    product_name VARCHAR(200),
    brand VARCHAR(100),
    subcategory_key INT,  -- Snowflake: verweist auf DIM_Subcategory
    unit_price DECIMAL(10,2),
    weight_kg DECIMAL(8,2)
);

CREATE TABLE DIM_Subcategory (
    subcategory_key SERIAL PRIMARY KEY,
    subcategory_name VARCHAR(100),
    category_key INT  -- Snowflake: verweist auf DIM_Category
);

CREATE TABLE DIM_Category (
    category_key SERIAL PRIMARY KEY,
    category_name VARCHAR(100),
    department_key INT  -- Snowflake: verweist auf DIM_Department
);

CREATE TABLE DIM_Department (
    department_key SERIAL PRIMARY KEY,
    department_name VARCHAR(100)
);

-- Time Dimension
CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_of_week INT,
    is_weekend BOOLEAN
);

-- Fact Table: Online Sales
CREATE TABLE FACT_Online_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    product_key INT REFERENCES DIM_Product(product_key),
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    shipping_cost DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    payment_method VARCHAR(50),
    order_status VARCHAR(20)  -- 'Completed', 'Cancelled', 'Returned'
);

-- ============================================================================
-- TEST TASKS - SNOWFLAKE JOIN NAVIGATION
-- ============================================================================

-- Aufgabe 1: Zeige alle Verkäufe mit vollständigem geografischen Pfad (Customer -> City -> Region -> Country -> Continent)
-- ❌ FEHLER: Unvollständige JOINs! city.continent existiert nicht (ist in country table). reg fehlt JOIN.

SELECT s.sale_id, c.customer_name, city.city_name, reg.region_name, city.continent 
FROM FACT_Online_Sales s 
JOIN DIM_Customer c ON s.customer_key = c.customer_key 
JOIN DIM_City city ON c.city_key = city.city_key 
JOIN DIM_Region reg ON city.region_key = reg.region_key;

-- KORREKTUR:
-- SELECT 
--     s.sale_id, 
--     c.customer_name, 
--     city.city_name, 
--     reg.region_name, 
--     country.country_name,
--     country.continent
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key 
-- JOIN DIM_City city ON c.city_key = city.city_key 
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key;


-- Aufgabe 2: Navigiere durch die Produkthierarchie (Product -> Subcategory -> Category -> Department) und berechne den Gesamtumsatz pro Department
-- ⚠️ TEILWEISE: JOINs sind korrekt, ABER total_sales ohne Aggregat (sollte SUM sein). Fehlt GROUP BY!

SELECT d.department_name, total_sales 
FROM FACT_Online_Sales s 
JOIN DIM_Product p ON s.product_key = p.product_key 
JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key 
JOIN DIM_Category c ON sc.category_key = c.category_key 
JOIN DIM_Department d ON c.department_key = d.department_key;

-- KORREKTUR:
-- SELECT 
--     d.department_name, 
--     SUM(s.total_amount) AS total_sales
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Product p ON s.product_key = p.product_key 
-- JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key 
-- JOIN DIM_Category c ON sc.category_key = c.category_key 
-- JOIN DIM_Department d ON c.department_key = d.department_key
-- GROUP BY d.department_name;


-- Aufgabe 3: Finde die Top 3 Länder nach Gesamtumsatz (Snowflake Navigation durch 4 Tabellen)
-- ❌ FEHLER: city.country_name existiert nicht (ist in DIM_Country)! Fehlt JOIN zu DIM_Country.

SELECT city.country_name, SUM(s.total_amount) AS total_sales 
FROM FACT_Online_Sales s 
JOIN DIM_Customer c ON s.customer_key = c.customer_key 
JOIN DIM_City city ON c.city_key = city.city_key 
GROUP BY city.country_name 
ORDER BY total_sales DESC 
LIMIT 3;

-- KORREKTUR:
-- SELECT 
--     country.country_name, 
--     SUM(s.total_amount) AS total_sales 
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key 
-- JOIN DIM_City city ON c.city_key = city.city_key 
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key
-- GROUP BY country.country_name 
-- ORDER BY total_sales DESC 
-- LIMIT 3;


-- Aufgabe 4: Berechne den Umsatz pro Kontinent und Kundenrang (Customer Tier) - Kombination beider Snowflake-Hierarchien
-- ❌ FEHLER: city.continent existiert nicht (ist in DIM_Country)! Fehlt JOIN zu DIM_Country.

SELECT city.continent, c.customer_tier, SUM(s.total_amount) AS total_sales 
FROM FACT_Online_Sales s 
JOIN DIM_Customer c ON s.customer_key = c.customer_key 
JOIN DIM_City city ON c.city_key = city.city_key 
GROUP BY city.continent, c.customer_tier;

-- KORREKTUR:
-- SELECT 
--     country.continent, 
--     c.customer_tier, 
--     SUM(s.total_amount) AS total_sales 
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key 
-- JOIN DIM_City city ON c.city_key = city.city_key 
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key
-- GROUP BY country.continent, c.customer_tier;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (E-COMMERCE ANALYTICS)
-- ============================================================================

-- Aufgabe 5: Ranke Produkte nach Verkaufsmenge innerhalb ihrer Kategorie (RANK mit Snowflake Navigation)
-- ✅ KORREKT (Perfekte Snowflake Navigation + Window Function!)

SELECT p.product_name, sc.subcategory_name, c.category_name, SUM(s.quantity) AS total_quantity,
       RANK() OVER (PARTITION BY c.category_name ORDER BY SUM(s.quantity) DESC) AS rank_in_category
FROM FACT_Online_Sales s
JOIN DIM_Product p ON s.product_key = p.product_key
JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key
JOIN DIM_Category c ON sc.category_key = c.category_key
GROUP BY p.product_name, sc.subcategory_name, c.category_name
ORDER BY c.category_name, rank_in_category;


-- Aufgabe 6: Berechne für jeden Kunden den kumulierten Umsatz über die Zeit (Running Total pro Customer)
-- ✅ KORREKT (Perfektes Running Total!)

SELECT 
    c.customer_name, 
    t.full_date, 
    SUM(s.total_amount) OVER (
        PARTITION BY c.customer_key 
        ORDER BY t.full_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales
FROM FACT_Online_Sales s
JOIN DIM_Customer c ON s.customer_key = c.customer_key
JOIN DIM_Time t ON s.time_key = t.time_key
ORDER BY c.customer_name, t.full_date;


-- Aufgabe 7: Berechne den gleitenden 30-Tage-Durchschnitt des Umsatzes pro Produkt
-- ❌ FEHLER: RANGE BETWEEN verwendet INTERVAL (für DATE types), aber t.full_date ist INT in ORDER BY! Außerdem fehlt JOINs-Reihenfolge.

SELECT p.product_name, AVG(s.total_amount) 
OVER (PARTITION BY p.product_key ORDER BY t.full_date RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW) AS moving_avg_30_days 
FROM FACT_Online_Sales s 
JOIN DIM_Product p ON s.product_key = p.product_key 
JOIN DIM_Time t ON s.time_key = t.time_key;

-- KORREKTUR (PostgreSQL):
-- SELECT 
--     p.product_name, 
--     t.full_date,
--     AVG(s.total_amount) OVER (
--         PARTITION BY p.product_key 
--         ORDER BY t.full_date 
--         RANGE BETWEEN INTERVAL '30 days' PRECEDING AND CURRENT ROW
--     ) AS moving_avg_30_days 
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Product p ON s.product_key = p.product_key 
-- JOIN DIM_Time t ON s.time_key = t.time_key
-- ORDER BY p.product_name, t.full_date;


-- Aufgabe 8: Finde für jeden Verkauf den vorherigen und nächsten Verkauf desselben Kunden (LAG und LEAD)
-- ⚠️ TEILWEISE: LEAD korrekt, LAG korrekt, ABER sale_date existiert nicht (korrekt ist t.full_date via JOIN)!

SELECT customer_key, sale_id, sale_date, 
       LAG(sale_id) OVER (PARTITION BY customer_key ORDER BY sale_date) AS previous_sale,
       LEAD(sale_id) OVER (PARTITION BY customer_key ORDER BY sale_date) AS next_sale
FROM FACT_Online_Sales
ORDER BY customer_key, sale_date;

-- KORREKTUR:
-- SELECT 
--     s.customer_key, 
--     s.sale_id, 
--     t.full_date AS sale_date, 
--     LAG(s.sale_id) OVER (PARTITION BY s.customer_key ORDER BY t.full_date) AS previous_sale,
--     LEAD(s.sale_id) OVER (PARTITION BY s.customer_key ORDER BY t.full_date) AS next_sale
-- FROM FACT_Online_Sales s
-- JOIN DIM_Time t ON s.time_key = t.time_key
-- ORDER BY s.customer_key, t.full_date;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL SALES REPORTS)
-- ============================================================================

-- Aufgabe 9: Erstelle einen hierarchischen Bericht: Continent -> Country -> Region mit Subtotals (ROLLUP über Snowflake-Hierarchie)
-- ❌ FEHLER: continent, country_name, region_name sind NICHT in FACT_Online_Sales! Fehlen JOINs durch gesamte Snowflake-Hierarchie!

SELECT continent, country_name, region_name, SUM(total_amount) AS total_sales 
FROM FACT_Online_Sales 
GROUP BY ROLLUP(continent, country_name, region_name);

-- KORREKTUR:
-- SELECT 
--     country.continent, 
--     country.country_name, 
--     reg.region_name, 
--     SUM(s.total_amount) AS total_sales 
-- FROM FACT_Online_Sales s
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key
-- JOIN DIM_City city ON c.city_key = city.city_key
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key
-- GROUP BY ROLLUP(country.continent, country.country_name, reg.region_name)
-- ORDER BY country.continent, country.country_name, reg.region_name;


-- Aufgabe 10: Zeige Umsatz nach Department -> Category -> Subcategory mit Grand Total (ROLLUP über Produkthierarchie)
-- ❌ FEHLER: department_name, category_name, subcategory_name sind NICHT in FACT_Online_Sales! Fehlen JOINs durch Produkthierarchie!

SELECT department_name, category_name, subcategory_name, SUM(total_amount) AS total_sales 
FROM FACT_Online_Sales 
GROUP BY ROLLUP(department_name, category_name, subcategory_name);

-- KORREKTUR:
-- SELECT 
--     d.department_name, 
--     cat.category_name, 
--     sc.subcategory_name, 
--     SUM(s.total_amount) AS total_sales 
-- FROM FACT_Online_Sales s
-- JOIN DIM_Product p ON s.product_key = p.product_key
-- JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key
-- JOIN DIM_Category cat ON sc.category_key = cat.category_key
-- JOIN DIM_Department d ON cat.department_key = d.department_key
-- GROUP BY ROLLUP(d.department_name, cat.category_name, sc.subcategory_name)
-- ORDER BY d.department_name, cat.category_name, sc.subcategory_name;


-- Aufgabe 11: Kombiniere beide Hierarchien: Umsatz nach Continent und Department mit ROLLUP (CROSS-Hierarchie Analyse)
-- ❌ FEHLER: continent und department_name sind NICHT in FACT_Online_Sales! Fehlen JOINs durch BEIDE Hierarchien!

SELECT continent, department_name, SUM(total_amount) AS total_sales 
FROM FACT_Online_Sales 
GROUP BY ROLLUP(continent, department_name);

-- KORREKTUR:
-- SELECT 
--     country.continent, 
--     d.department_name, 
--     SUM(s.total_amount) AS total_sales 
-- FROM FACT_Online_Sales s
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key
-- JOIN DIM_City city ON c.city_key = city.city_key
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key
-- JOIN DIM_Product p ON s.product_key = p.product_key
-- JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key
-- JOIN DIM_Category cat ON sc.category_key = cat.category_key
-- JOIN DIM_Department d ON cat.department_key = d.department_key
-- GROUP BY ROLLUP(country.continent, d.department_name)
-- ORDER BY country.continent, d.department_name;


-- ============================================================================
-- TEST TASKS - ADVANCED SNOWFLAKE QUERIES
-- ============================================================================

-- Aufgabe 12: Finde alle Kunden die Produkte aus mindestens 3 verschiedenen Departments gekauft haben (Snowflake Navigation + HAVING)
-- ✅ KORREKT (Perfekte Snowflake Navigation + DISTINCT COUNT!)

SELECT c.customer_name, COUNT(DISTINCT d.department_key) AS dept_count
FROM FACT_Online_Sales s
JOIN DIM_Customer c ON s.customer_key = c.customer_key
JOIN DIM_Product p ON s.product_key = p.product_key
JOIN DIM_Subcategory sc ON p.subcategory_key = sc.subcategory_key
JOIN DIM_Category cat ON sc.category_key = cat.category_key
JOIN DIM_Department d ON cat.department_key = d.department_key
GROUP BY c.customer_name
HAVING COUNT(DISTINCT d.department_key) >= 3;


-- Aufgabe 13: Berechne den durchschnittlichen Bestellwert pro Land und zeige nur Länder die über dem globalen Durchschnitt liegen (Snowflake + Subquery)
-- ❌ FEHLER: city.country_name existiert nicht! Fehlt JOIN zu DIM_Country. Subquery sollte AVG über alle Sales sein.

SELECT city.country_name, AVG(s.total_amount) AS avg_order_value 
FROM FACT_Online_Sales s 
JOIN DIM_Customer c ON s.customer_key = c.customer_key 
JOIN DIM_City city ON c.city_key = city.city_key 
GROUP BY city.country_name 
HAVING AVG(s.total_amount) > (SELECT AVG(total_amount) FROM DIM_City);

-- KORREKTUR:
-- SELECT 
--     country.country_name, 
--     AVG(s.total_amount) AS avg_order_value 
-- FROM FACT_Online_Sales s 
-- JOIN DIM_Customer c ON s.customer_key = c.customer_key 
-- JOIN DIM_City city ON c.city_key = city.city_key 
-- JOIN DIM_Region reg ON city.region_key = reg.region_key
-- JOIN DIM_Country country ON reg.country_key = country.country_key
-- GROUP BY country.country_name 
-- HAVING AVG(s.total_amount) > (SELECT AVG(total_amount) FROM FACT_Online_Sales)
-- ORDER BY avg_order_value DESC;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 30.8/100
-- SUCCESS RATE: 4/13 (30.8%)

-- BREAKDOWN:
-- ✅ Korrekt:  3 (Tasks 5, 6, 12)
-- ⚠️ Teilweise: 2 (Tasks 2, 8)
-- ❌ Fehler:   8 (Tasks 1, 3, 4, 7, 9, 10, 11, 13)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Running Totals perfekt (Task 6)
-- + RANK mit PARTITION BY über Snowflake-JOINs (Task 5)
-- + Complex Snowflake Navigation verstanden (Task 12 - 4-fach JOIN!)
-- + DISTINCT COUNT korrekt angewandt (Task 12)

-- WEAKNESSES:
-- - Unvollständige Snowflake JOINs (Tasks 1, 3, 4, 7, 9, 10, 11, 13)
-- - Fehlende/Falsche Column-Referenzen (city.continent, city.country_name, sale_date)
-- - RANGE BETWEEN mit DATE-Spalten fehlerhaft (Task 7)
-- - ROLLUP ohne JOINs (Tasks 9, 10, 11)
-- - Falsche Subquery-Tabelle (Task 13: SELECT AVG FROM DIM_City statt FACT_Online_Sales)

-- CRITICAL ERRORS:
-- - 8 von 13 Tasks haben fehlende oder falsche JOINs!
-- - Snowflake-Navigation bricht häufig 1-2 Ebenen zu früh ab!
-- - ROLLUP Tasks fast alle falsch (fehlende JOINs zu Dimensions)

-- RECOMMENDATION:
-- ⚠️ SCHWACH für Snowflake Schema!
-- Das 7B Model versteht grundsätzliche Snowflake-Konzepte, aber scheitert häufig bei der vollständigen Navigation.
-- Nur 30.8% Success Rate - zu niedrig für Production!

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 65-80 (Sehr komplex, tiefe Hierarchien)
-- Parser Challenge: High (Multiple 4-5 fache JOINs)
-- Model Compatibility: Advanced models only
-- Special Focus:
--   - Vollständige Snowflake-Navigation durch 4-5 Tabellen
--   - Kombination beider Hierarchien (Geo + Product)
--   - ROLLUP über denormalisierte Hierarchien
--   - Window Functions mit Snowflake JOINs
-- ============================================================================
