-- ============================================================================
-- TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA + WINDOW + ROLLUP
-- ============================================================================
-- Domain: E-Commerce (Online-Shop)
-- Complexity: 🔴 Advanced
-- Focus: Snowflake-Schema mit Hierarchien, Window Functions, ROLLUP
-- Test Coverage: Normalized Dimensions, Deep Hierarchies, Complex Analytics
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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

SELECT f.*, d.department_name, c.category_name 
FROM FACT_Order f 
JOIN DIM_Product p ON f.product_key = p.product_key 
JOIN DIM_Category c ON p.category_key = c.category_key 
JOIN DIM_Department d ON c.department_key = d.department_key;


-- Aufgabe 2: Zeige alle Bestellungen mit vollständiger Standorthierarchie (Customer → City → Region → Country)

SELECT c.customer_name, d.city_name, r.region_name, co.country_name 
FROM DIM_Customer c 
JOIN DIM_City d ON c.city_key = d.city_key 
JOIN DIM_Region r ON d.region_key = r.region_key 
JOIN DIM_Country co ON r.country_key = co.country_key;


-- Aufgabe 3: Berechne den Umsatz pro Department → Category → Product (3 Ebenen Hierarchie)

SELECT d.department_name, c.category_name, p.product_name, SUM(f.total_amount) AS total_sales
FROM DIM_Department d
JOIN DIM_Category c ON d.department_key = c.department_key
JOIN DIM_Product p ON c.category_key = p.category_key
JOIN FACT_Order fo ON p.product_key = fo.product_key
GROUP BY d.department_name, c.category_name, p.product_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (MULTI-LEVEL HIERARCHIES)
-- ============================================================================

-- Aufgabe 4: Berechne den Umsatz mit hierarchischen Subtotals nach Department, Category und Product (verwende ROLLUP)

SELECT department_name, category_name, product_name, SUM(total_amount) AS total_sales
FROM DIM_Department d JOIN DIM_Category c ON d.department_key = c.department_key
JOIN DIM_Product p ON c.category_key = p.category_key
JOIN FACT_Order fo ON p.product_key = fo.product_key
GROUP BY ROLLUP(department_name, category_name, product_name);


-- Aufgabe 5: Berechne den Umsatz mit hierarchischen Subtotals nach Country, Region und City (verwende ROLLUP mit GROUPING Funktion)

SELECT 
    c.country_name,
    r.region_name,
    ci.city_name,
    SUM(f.total_amount) AS total_umsatz
FROM 
    DIM_Country c
JOIN 
    DIM_Region r ON c.country_key = r.country_key
JOIN 
    DIM_City ci ON r.region_key = ci.region_key
JOIN 
    FACT_Order fo ON ci.city_key = fo.customer_key
GROUP BY 
    ROLLUP(c.country_name, r.region_name, ci.city_name)
ORDER BY 
    total_umsatz DESC;


-- Aufgabe 6: Erstelle einen Bericht mit Subtotals nach Kontinent, Land und Region (ROLLUP über geografische Hierarchie)

SELECT 
    c.continent,
    co.country_name AS country_name,
    r.region_name AS region_name,
    SUM(f.total_amount) AS total_revenue
FROM 
    DIM_Country co
JOIN 
    DIM_Region r ON co.country_key = r.country_key
JOIN 
    FACT_Order f ON r.region_key = f.customer_key
GROUP BY 
    ROLLUP(c.continent, co.country_name, r.region_name)
ORDER BY 
    continent, country_name, region_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS
-- ============================================================================

-- Aufgabe 7: Ranke Produkte nach Umsatz innerhalb jeder Kategorie (DENSE_RANK mit PARTITION BY category)

SELECT category_key, product_name, SUM(unit_price * quantity) AS total_sales, DENSE_RANK() OVER(PARTITION BY category_key ORDER BY SUM(unit_price * quantity)) AS rank_within_category
FROM FACT_Order
JOIN DIM_Product ON FACT_Order.product_key = DIM_Product.product_key
GROUP BY category_key, product_name
ORDER BY category_key, rank_within_category;


-- Aufgabe 8: Berechne den durchschnittlichen Bestellwert pro Kunde mit Vergleich zum Durchschnitt seiner Loyalty Tier (Window Functions)

SELECT c.customer_key, AVG(f.total_amount) AS average_order_value,
       AVG(CASE WHEN t.loyalty_tier = 'Bronze' THEN f.total_amount ELSE NULL END) OVER (PARTITION BY c.customer_key) AS bronze_average,
       AVG(CASE WHEN t.loyalty_tier = 'Silver' THEN f.total_amount ELSE NULL END) OVER (PARTITION BY c.customer_key) AS silver_average,
       AVG(CASE WHEN t.loyalty_tier = 'Gold' THEN f.total_amount ELSE NULL END) OVER (PARTITION BY c.customer_key) AS gold_average,
       AVG(CASE WHEN t.loyalty_tier = 'Platinum' THEN f.total_amount ELSE NULL END) OVER (PARTITION BY c.customer_key) AS platinum_average
FROM DIM_Customer c
JOIN FACT_Order f ON c.customer_key = f.customer_key
LEFT JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY c.customer_key, t.loyalty_tier;


-- Aufgabe 9: Identifiziere die Top 3 Produkte pro Department nach Verkaufsmenge (Window Functions mit PARTITION BY)

SELECT d.department_name, p.product_name, SUM(f.quantity) AS total_sales
FROM DIM_Department d
JOIN DIM_Category c ON d.department_key = c.department_key
JOIN DIM_Product p ON c.category_key = p.category_key
JOIN FACT_Order fo ON p.product_key = fo.product_key
GROUP BY d.department_name, p.product_name
ORDER BY SUM(f.quantity) DESC
LIMIT 3;


-- ============================================================================
-- TEST TASKS - CONVERSION RATE ANALYSIS
-- ============================================================================

-- Aufgabe 10: Berechne die Conversion Rate pro Produktkategorie (abgeschlossene Bestellungen / Gesamtbestellungen)

SELECT c.category_name, COUNT(f.order_id) AS completed_orders, SUM(f.order_id) AS total_orders, CAST(COUNT(f.order_id) AS DECIMAL(10,2)) * 100 / SUM(f.order_id) AS conversion_rate 
FROM DIM_Category c 
JOIN DIM_Product p ON c.category_key = p.category_key 
JOIN FACT_Order f ON p.product_key = f.product_key 
GROUP BY c.category_name;


-- Aufgabe 11: Berechne die Return Rate pro Department (zurückgegebene Bestellungen / abgeschlossene Bestellungen)

SELECT d.department_name, COUNT(f.order_status) AS return_rate 
FROM DIM_Department d 
JOIN FACT_Order fo ON d.department_key = fo.product_key 
WHERE fo.order_status = 'Returned' 
GROUP BY d.department_name;


-- ============================================================================
-- TEST TASKS - CUSTOMER SEGMENTATION
-- ============================================================================

-- Aufgabe 12: Segmentiere Kunden in Quartile basierend auf ihrem Gesamtumsatz (verwende NTILE Window Function)

SELECT customer_key, NTILE(4) OVER (ORDER BY total_amount DESC) AS quartile FROM FACT_Order GROUP BY customer_key;


-- Aufgabe 13: Finde alle Kunden die im obersten Quartil ihres Landes liegen (NTILE mit PARTITION BY country)

SELECT c.customer_key, c.customer_name FROM DIM_Customer c JOIN (
    SELECT country_key, NTILE(4) OVER (PARTITION BY country_key ORDER BY customer_key DESC) as quartile 
    FROM DIM_Customer
) t ON c.country_key = t.country_key WHERE t.quartile = 1;


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
