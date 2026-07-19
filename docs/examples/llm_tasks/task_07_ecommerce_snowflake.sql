-- ============================================================================
-- EXAMPLE: E-commerce - snowflake schema with analytics
-- ============================================================================
-- Domain: Online shop
-- Level: Advanced
-- Focus: Normalized dimensions, hierarchies, window functions, ROLLUP
-- Validated with model: qwen3-coder-30b-a3b-instruct
-- ============================================================================
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
-- TASKS
-- ============================================================================

-- Task 1: Zeige alle Bestellungen mit vollständiger Produkthierarchie (Product → Category → Department)


SELECT 
    f.order_id,
    p.product_name,
    c.category_name,
    d.department_name
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
JOIN DIM_Department d ON c.department_key = d.department_key;

-- Task 2: Zeige alle Bestellungen mit vollständiger Standorthierarchie (Customer → City → Region → Country)

SELECT 
    o.order_id,
    c.customer_name,
    ci.city_name,
    r.region_name,
    co.country_name
FROM FACT_Order o
JOIN DIM_Customer c ON o.customer_key = c.customer_key
JOIN DIM_City ci ON c.city_key = ci.city_key
JOIN DIM_Region r ON ci.region_key = r.region_key
JOIN DIM_Country co ON r.country_key = co.country_key;


-- Task 3: Berechne den Umsatz pro Department → Category → Product (3 Ebenen Hierarchie)

SELECT 
    d.department_name,
    c.category_name,
    p.product_name,
    SUM(f.total_amount) AS total_revenue
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
JOIN DIM_Department d ON c.department_key = d.department_key
GROUP BY d.department_name, c.category_name, p.product_name
ORDER BY d.department_name, c.category_name, p.product_name;


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 4: Berechne den Umsatz mit hierarchischen Subtotals nach Department, Category und Product (verwende ROLLUP)

SELECT 
    d.department_name,
    c.category_name,
    p.product_name,
    SUM(f.total_amount) AS total_revenue
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
JOIN DIM_Department d ON c.department_key = d.department_key
GROUP BY ROLLUP(d.department_name, c.category_name, p.product_name)
ORDER BY 
    d.department_name NULLS LAST,
    c.category_name NULLS LAST,
    p.product_name NULLS LAST;


-- Task 5: Berechne den Umsatz mit hierarchischen Subtotals nach Country, Region und City (verwende ROLLUP mit GROUPING Funktion)

SELECT 
    c.country_name,
    r.region_name,
    ci.city_name,
    SUM(o.total_amount) AS total_revenue,
    GROUPING(c.country_name) + GROUPING(r.region_name) + GROUPING(ci.city_name) AS grouping_level
FROM FACT_Order o
JOIN DIM_Customer cu ON o.customer_key = cu.customer_key
JOIN DIM_City ci ON cu.city_key = ci.city_key
JOIN DIM_Region r ON ci.region_key = r.region_key
JOIN DIM_Country c ON r.country_key = c.country_key
GROUP BY ROLLUP(c.country_name, r.region_name, ci.city_name)
ORDER BY 
    CASE WHEN GROUPING(c.country_name) = 1 THEN 1 ELSE 0 END,
    c.country_name NULLS LAST,
    r.region_name NULLS LAST,
    ci.city_name NULLS LAST;


-- Task 6: Erstelle einen Bericht mit Subtotals nach Kontinent, Land und Region (ROLLUP über geografische Hierarchie)

SELECT 
    c.continent,
    co.country_name,
    r.region_name,
    SUM(f.total_amount) AS total_sales
FROM FACT_Order f
JOIN DIM_Customer cust ON f.customer_key = cust.customer_key
JOIN DIM_City ci ON cust.city_key = ci.city_key
JOIN DIM_Region r ON ci.region_key = r.region_key
JOIN DIM_Country co ON r.country_key = co.country_key
JOIN DIM_Region reg ON ci.region_key = reg.region_key
JOIN DIM_Country cou ON reg.country_key = cou.country_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY ROLLUP(c.continent, co.country_name, r.region_name)
ORDER BY c.continent NULLS LAST, co.country_name NULLS LAST, r.region_name NULLS LAST;


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 7: Ranke Produkte nach Umsatz innerhalb jeder Kategorie (DENSE_RANK mit PARTITION BY category)

SELECT 
    p.product_name,
    c.category_name,
    SUM(f.total_amount) AS total_sales,
    DENSE_RANK() OVER (PARTITION BY c.category_key ORDER BY SUM(f.total_amount) DESC) AS rank
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
GROUP BY p.product_name, c.category_name, c.category_key;


-- Task 8: Berechne den durchschnittlichen Bestellwert pro Kunde mit Vergleich zum Durchschnitt seiner Loyalty Tier (Window Functions)

SELECT 
    c.customer_key,
    AVG(fo.total_amount) AS avg_order_value,
    AVG(AVG(fo.total_amount)) OVER (PARTITION BY c.loyalty_tier) AS tier_avg_order_value
FROM FACT_Order fo
JOIN DIM_Customer c ON fo.customer_key = c.customer_key
GROUP BY c.customer_key, c.loyalty_tier;


-- Task 9: Identifiziere die Top 3 Produkte pro Department nach Verkaufsmenge (Window Functions mit PARTITION BY)

WITH ranked_products AS (
    SELECT 
        d.department_name,
        p.product_name,
        SUM(f.quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY d.department_key ORDER BY SUM(f.quantity) DESC) AS rn
    FROM FACT_Order f
    JOIN DIM_Product p ON f.product_key = p.product_key
    JOIN DIM_Category c ON p.category_key = c.category_key
    JOIN DIM_Department d ON c.department_key = d.department_key
    GROUP BY d.department_key, d.department_name, p.product_name
)
SELECT 
    department_name,
    product_name,
    total_quantity
FROM ranked_products
WHERE rn <= 3;


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 10: Berechne die Conversion Rate pro Produktkategorie (abgeschlossene Bestellungen / Gesamtbestellungen)

SELECT 
    c.category_name,
    CAST(SUM(CASE WHEN f.order_status = 'Completed' THEN 1 ELSE 0 END) AS FLOAT) * 100 / COUNT(*) AS conversion_rate
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
GROUP BY c.category_name
ORDER BY conversion_rate DESC;


-- Task 11: Berechne die Return Rate pro Department (zurückgegebene Bestellungen / abgeschlossene Bestellungen)

SELECT 
    d.department_name,
    COALESCE(SUM(CASE WHEN f.order_status = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 0) AS return_rate_percentage
FROM FACT_Order f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Category c ON p.category_key = c.category_key
JOIN DIM_Department d ON c.department_key = d.department_key
WHERE f.order_status IN ('Completed', 'Returned')
GROUP BY d.department_name;


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 12: Segmentiere Kunden in Quartile basierend auf ihrem Gesamtumsatz (verwende NTILE Window Function)

WITH customer_sales AS (
    SELECT 
        c.customer_key,
        c.customer_name,
        SUM(f.total_amount) AS total_sales
    FROM DIM_Customer c
    JOIN FACT_Order f ON c.customer_key = f.customer_key
    GROUP BY c.customer_key, c.customer_name
),
ranked_customers AS (
    SELECT 
        customer_key,
        customer_name,
        total_sales,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM customer_sales
)
SELECT 
    customer_key,
    customer_name,
    total_sales,
    sales_quartile
FROM ranked_customers
ORDER BY sales_quartile, total_sales DESC;


-- Task 13: Finde alle Kunden die im obersten Quartil ihres Landes liegen (NTILE mit PARTITION BY country)

WITH customer_ranked AS (
    SELECT 
        c.customer_key,
        c.customer_name,
        co.country_name,
        NTILE(4) OVER (PARTITION BY co.country_name ORDER BY COUNT(o.order_id) DESC) AS quartile
    FROM DIM_Customer c
    JOIN DIM_City ci ON c.city_key = ci.city_key
    JOIN DIM_Region r ON ci.region_key = r.region_key
    JOIN DIM_Country co ON r.country_key = co.country_key
    LEFT JOIN FACT_Order o ON c.customer_key = o.customer_key
    GROUP BY c.customer_key, c.customer_name, co.country_name
)
SELECT 
    customer_key,
    customer_name,
    country_name
FROM customer_ranked
WHERE quartile = 1;


