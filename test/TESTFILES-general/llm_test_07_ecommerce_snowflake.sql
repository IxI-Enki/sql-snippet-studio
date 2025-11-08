-- ============================================================================
-- TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA + WINDOW + ROLLUP
-- ============================================================================
-- Domain: E-Commerce (Online-Shop)
-- Complexity: 🔴 Advanced
-- Focus: Snowflake-Schema mit Hierarchien, Window Functions, ROLLUP
-- Test Coverage: Normalized Dimensions, Deep Hierarchies, Complex Analytics
-- ============================================================================

-- Dieser Test wurde mit dem Modell [MODEL_NAME] getestet.

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


-- Aufgabe 2: Zeige alle Bestellungen mit vollständiger Standorthierarchie (Customer → City → Region → Country)


-- Aufgabe 3: Berechne den Umsatz pro Department → Category → Product (3 Ebenen Hierarchie)


-- ============================================================================
-- TEST TASKS - ROLLUP (MULTI-LEVEL HIERARCHIES)
-- ============================================================================

-- Aufgabe 4: Berechne den Umsatz mit hierarchischen Subtotals nach Department, Category und Product (verwende ROLLUP)


-- Aufgabe 5: Berechne den Umsatz mit hierarchischen Subtotals nach Country, Region und City (verwende ROLLUP mit GROUPING Funktion)


-- Aufgabe 6: Erstelle einen Bericht mit Subtotals nach Kontinent, Land und Region (ROLLUP über geografische Hierarchie)


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS
-- ============================================================================

-- Aufgabe 7: Ranke Produkte nach Umsatz innerhalb jeder Kategorie (DENSE_RANK mit PARTITION BY category)


-- Aufgabe 8: Berechne den durchschnittlichen Bestellwert pro Kunde mit Vergleich zum Durchschnitt seiner Loyalty Tier (Window Functions)


-- Aufgabe 9: Identifiziere die Top 3 Produkte pro Department nach Verkaufsmenge (Window Functions mit PARTITION BY)


-- ============================================================================
-- TEST TASKS - CONVERSION RATE ANALYSIS
-- ============================================================================

-- Aufgabe 10: Berechne die Conversion Rate pro Produktkategorie (abgeschlossene Bestellungen / Gesamtbestellungen)


-- Aufgabe 11: Berechne die Return Rate pro Department (zurückgegebene Bestellungen / abgeschlossene Bestellungen)


-- ============================================================================
-- TEST TASKS - CUSTOMER SEGMENTATION
-- ============================================================================

-- Aufgabe 12: Segmentiere Kunden in Quartile basierend auf ihrem Gesamtumsatz (verwende NTILE Window Function)


-- Aufgabe 13: Finde alle Kunden die im obersten Quartil ihres Landes liegen (NTILE mit PARTITION BY country)


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
