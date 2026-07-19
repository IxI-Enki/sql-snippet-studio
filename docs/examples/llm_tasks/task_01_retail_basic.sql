-- ============================================================================
-- EXAMPLE: Retail sales - basic star schema
-- ============================================================================
-- Domain: Retail product sales
-- Level: Beginner
-- Focus: Star-schema structure, simple joins and aggregations
-- Validated with model: qwen3-coder-30b-a3b-instruct
-- ============================================================================
-- ============================================================================
-- SCHEMA: Retail Sales Data Warehouse
-- ============================================================================

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    brand VARCHAR(50),
    unit_price DECIMAL(10,2)
);

CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    registration_date DATE
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    day_of_week INT,
    day_name VARCHAR(20)
);

CREATE TABLE FACT_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    product_key INT REFERENCES DIM_Product(product_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    quantity INT,
    unit_price DECIMAL(10,2),
    discount_percent DECIMAL(5,2),
    total_amount DECIMAL(12,2)
);

-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 1: Zeige alle Verkäufe mit Produktnamen und Kundennamen

SELECT p.product_name, c.customer_name 
FROM FACT_Sales s 
JOIN DIM_Product p ON s.product_key = p.product_key 
JOIN DIM_Customer c ON s.customer_key = c.customer_key;



-- Task 2: Berechne den Gesamtumsatz pro Kunde (sortiert nach Umsatz absteigend)


-- Task 3: Berechne den Gesamtumsatz pro Monat im Jahr 2024


-- Task 4: Finde die Top 5 meistverkauften Produkte nach Menge


-- Task 5: Berechne den durchschnittlichen Bestellwert pro Produktkategorie


-- Task 6: Zeige alle Kunden die mehr als 1000 Euro Umsatz generiert haben


-- Task 7: Berechne den Umsatz pro Land (verwende DIM_Customer)


-- Task 8: Finde alle Verkäufe mit einem Rabatt von mehr als 10 Prozent


