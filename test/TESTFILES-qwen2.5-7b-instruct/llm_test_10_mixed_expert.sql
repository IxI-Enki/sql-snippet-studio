-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen2.5-7b-instruct getestet.

-- ============================================================================
-- SCHEMA: Integrated Business Intelligence Data Warehouse
-- ============================================================================

-- DIMENSIONS
CREATE TABLE DIM_Customer (
    customer_key SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(50),         -- 'Enterprise', 'SMB', 'Consumer'
    region VARCHAR(50),
    country VARCHAR(50),
    lifetime_value DECIMAL(15,2)
);

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    cost_price DECIMAL(10,2),
    list_price DECIMAL(10,2),
    margin_percent DECIMAL(5,2)
);

CREATE TABLE DIM_Channel (
    channel_key SERIAL PRIMARY KEY,
    channel_name VARCHAR(50) UNIQUE,  -- 'Online', 'Retail', 'Wholesale', 'Partner'
    channel_type VARCHAR(50),
    commission_rate DECIMAL(5,4)
);

CREATE TABLE DIM_Employee (
    employee_key SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE,
    employee_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100),
    department VARCHAR(50),
    hire_date DATE,
    salary DECIMAL(12,2)
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name VARCHAR(20),
    week INT,
    fiscal_year INT,
    fiscal_quarter INT,
    is_holiday BOOLEAN
);

-- FACT TABLES
CREATE TABLE FACT_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    customer_key INT REFERENCES DIM_Customer(customer_key),
    product_key INT REFERENCES DIM_Product(product_key),
    channel_key INT REFERENCES DIM_Channel(channel_key),
    employee_key INT REFERENCES DIM_Employee(employee_key),
    quantity INT,
    revenue DECIMAL(15,2),
    cost DECIMAL(15,2),
    discount DECIMAL(15,2),
    net_revenue DECIMAL(15,2),
    profit DECIMAL(15,2)
);

CREATE TABLE FACT_Inventory (
    inventory_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    product_key INT REFERENCES DIM_Product(product_key),
    quantity_on_hand INT,
    reorder_point INT,
    warehouse_capacity INT
);

-- ============================================================================
-- STAGING TABLES (FOR ETL/MERGE)
-- ============================================================================

CREATE TABLE STG_Sales_Updates (
    sale_date DATE,
    customer_id VARCHAR(20),
    product_code VARCHAR(50),
    channel_name VARCHAR(50),
    employee_id VARCHAR(20),
    quantity INT,
    revenue DECIMAL(15,2),
    cost DECIMAL(15,2),
    discount DECIMAL(15,2)
);

CREATE TABLE ETL_Log (
    log_id SERIAL PRIMARY KEY,
    load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    table_name VARCHAR(100),
    rows_inserted INT,
    rows_updated INT,
    rows_deleted INT,
    status VARCHAR(20),
    error_message TEXT
);

-- ============================================================================
-- TEST TASKS - STAR SCHEMA BASICS
-- ============================================================================

-- Aufgabe 1: Erstelle eine Complete Star-Schema Query die alle Dimensions mit dem Fact verbindet und den Umsatz pro Kunde, Produkt, Kanal und Mitarbeiter zeigt


-- Aufgabe 2: Berechne die Profitabilität (profit / revenue * 100) pro Produktkategorie mit allen relevanten Dimensionsattributen


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert


-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)


-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 50-70 (Extrem komplex, Real-World Scenarios)
-- Parser Challenge: MAXIMUM (Multi-Step Queries, CTEs, Subqueries, Window Functions)
-- Model Compatibility: EXPERT MODELS ONLY
-- Special Focus:
--   - Kombination aller Techniken in einer Query
--   - CTEs für lesbare, mehrstufige Analysen
--   - Korrekte Reihenfolge von Operations (CTE → Window → Filter → ROLLUP)
--   - Business Logic Interpretation
--   - Komplexe JOINs über mehrere Fact- und Dimension-Tabellen
--   - Performance-Bewusstsein (keine CROSS JOINs!)
-- ULTIMATE TEST: Wenn das Model diese Queries meistert, ist es production-ready!
-- ============================================================================
