-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

-- ✅ PERFEKT (Score: 100/100)
--    Alle 5 Dimensions korrekt verknüpft!
--    Gruppierung korrekt, Aggregation korrekt!

SELECT 
    c.customer_name,
    p.product_name,
    ch.channel_name,
    e.employee_name,
    SUM(f.revenue) AS total_revenue
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
JOIN DIM_Employee e ON f.employee_key = e.employee_key
GROUP BY 
    c.customer_name,
    p.product_name,
    ch.channel_name,
    e.employee_name;


-- Aufgabe 2: Berechne die Profitabilität (profit / revenue * 100) pro Produktkategorie mit allen relevanten Dimensionsattributen

-- ❌ LOGIKFEHLER (Score: 40/100)
--    FEHLER: Verwendet AVG statt SUM!
--    Profit Margin sollte SUM(profit) / SUM(revenue) sein, nicht AVG(profit) / AVG(revenue)!
--    Außerdem: "total_profit" als Alias für AVG ist irreführend!

SELECT 
    p.category,
    p.subcategory,
    p.brand,
    p.product_name,
    AVG(f.profit) AS total_profit,
    AVG(f.revenue) AS total_revenue,
    AVG(f.profit) * 100.0 / AVG(f.revenue) AS profit_margin_percent
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory, p.brand, p.product_name;

-- KORREKTE LÖSUNG:
-- SELECT 
--     p.category,
--     p.subcategory,
--     p.brand,
--     p.product_name,
--     SUM(f.profit) AS total_profit,
--     SUM(f.revenue) AS total_revenue,
--     SUM(f.profit) * 100.0 / NULLIF(SUM(f.revenue), 0) AS profit_margin_percent
-- FROM FACT_Sales f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- GROUP BY p.category, p.subcategory, p.brand, p.product_name;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)

-- ✅ PERFEKT (Score: 100/100)
--    CTE korrekt verwendet!
--    DENSE_RANK mit PARTITION BY perfekt!
--    WHERE Filter auf Ranking korrekt!

WITH RankedProducts AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.revenue) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.revenue) DESC) AS revenue_rank
    FROM DIM_Product p
    JOIN FACT_Sales f ON p.product_key = f.product_key
    GROUP BY p.product_name, p.category
)
SELECT product_name, category, total_revenue
FROM RankedProducts
WHERE revenue_rank <= 5;


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)

-- ✅ PERFEKT (Score: 100/100)
--    Nested SUM korrekt verwendet!
--    SUM(SUM(...)) OVER mit PARTITION BY perfekt!
--    Komplexe Window Function gemeistert!

SELECT 
    c.customer_id,
    c.customer_name,
    c.region,
    SUM(f.revenue) AS total_revenue,
    SUM(f.revenue) * 100.0 / SUM(SUM(f.revenue)) OVER (PARTITION BY c.region) AS percent_of_total_region
FROM 
    DIM_Customer c
JOIN 
    FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_id, c.customer_name, c.region;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    ZU KOMPLEX: LAG + Moving Average + Trendberechnung

-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    ZU KOMPLEX: Running Total + LAG kombiniert

-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    MERGE + ETL: ZU KOMPLEX für 4B Model!

-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    MERGE: KANN DAS MODEL NICHT!

-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)

-- ❌ FAILED (Score: 40/100)
--    FEHLT: GROUPING() Funktion! Die Aufgabe verlangt explizit GROUPING!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    Die Aufgabe verlangt EXPLIZIT "ROLLUP mit GROUPING Funktion"!

SELECT 
    c.region,
    c.country,
    c.segment,
    ch.channel_name,
    SUM(f.revenue) AS total_revenue,
    SUM(f.profit) AS total_profit
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
GROUP BY 
    c.region, 
    c.country, 
    c.segment, 
    ch.channel_name
WITH ROLLUP;

-- KORREKTE LÖSUNG:
-- SELECT 
--     c.region,
--     c.country,
--     c.segment,
--     ch.channel_name,
--     SUM(f.revenue) AS total_revenue,
--     SUM(f.profit) AS total_profit,
--     GROUPING(c.region) AS is_region_subtotal,
--     GROUPING(c.country) AS is_country_subtotal,
--     GROUPING(c.segment) AS is_segment_subtotal,
--     GROUPING(ch.channel_name) AS is_channel_subtotal
-- FROM FACT_Sales f
-- JOIN DIM_Customer c ON f.customer_key = c.customer_key
-- JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
-- GROUP BY ROLLUP(c.region, c.country, c.segment, ch.channel_name);


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)

-- ❌ FAILED (Score: 30/100)
--    FEHLER: SELECT Reihenfolge falsch! Aggregation vor Gruppierung!
--    FALSCHE SYNTAX: "WITH ROLLUP" ist MySQL, nicht PostgreSQL!
--    Sollte: SELECT fiscal_year, fiscal_quarter, month_name, SUM(...)

SELECT 
    SUM(FACT_Sales.revenue) AS total_revenue,
    DIM_Time.fiscal_year,
    DIM_Time.fiscal_quarter,
    DIM_Time.month_name
FROM FACT_Sales
JOIN DIM_Time ON FACT_Sales.time_key = DIM_Time.time_key
GROUP BY 
    DIM_Time.fiscal_year, 
    DIM_Time.fiscal_quarter, 
    DIM_Time.month_name
WITH ROLLUP;

-- KORREKTE LÖSUNG:
-- SELECT 
--     DIM_Time.fiscal_year,
--     DIM_Time.fiscal_quarter,
--     DIM_Time.month_name,
--     SUM(FACT_Sales.revenue) AS total_revenue
-- FROM FACT_Sales
-- JOIN DIM_Time ON FACT_Sales.time_key = DIM_Time.time_key
-- GROUP BY ROLLUP(DIM_Time.fiscal_year, DIM_Time.fiscal_quarter, DIM_Time.month_name);


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    ZU KOMPLEX: Mehrere CTEs + LAG + Filter
-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    ZU KOMPLEX: Mehrere Subqueries + Durchschnittsvergleiche

-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    ZU KOMPLEX: Multi-Fact + Zeitberechnung + Moving Average
-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)

-- ⚠️ TEILWEISE KORREKT (Score: 70/100)
--    Multi-Fact JOIN korrekt!
--    ABER: "hohe Verkäufe" nicht definiert! f.quantity > 0 ist zu niedrig!
--    Sollte: Aggregation oder Schwellwert für "hohe Verkäufe"

SELECT 
    f.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    f.quantity,
    i.quantity_on_hand
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN FACT_Inventory i ON f.product_key = i.product_key AND f.time_key = i.time_key
WHERE f.quantity > 0 
    AND i.quantity_on_hand < 10;

-- BESSERE LÖSUNG:
-- SELECT 
--     p.product_key,
--     p.product_name,
--     p.category,
--     SUM(f.quantity) AS total_sales,
--     AVG(i.quantity_on_hand) AS avg_stock
-- FROM FACT_Sales f
-- JOIN DIM_Product p ON f.product_key = p.product_key
-- JOIN FACT_Inventory i ON f.product_key = i.product_key
-- GROUP BY p.product_key, p.product_name, p.category
-- HAVING SUM(f.quantity) > 100 AND AVG(i.quantity_on_hand) < 10;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    Multi-Fact Analysis: ZU KOMPLEX!

-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    BUSINESS LOGIC: VIEL ZU KOMPLEX für 4B Model!
-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    RFM SEGMENTATION: VIEL ZU KOMPLEX!
-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    CHANNEL OPTIMIZATION: VIEL ZU KOMPLEX!

-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 26.1/100 ⭐
-- SUCCESS RATE: 16.7% (3/18 tasks korrekt) **KATASTROPHE!**
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1:  100/100 - Complete Star-Schema Query perfekt
--   ❌ Aufgabe 2:   40/100 - Verwendet AVG statt SUM (Logikfehler!)
--   ✅ Aufgabe 3:  100/100 - CTE mit DENSE_RANK perfekt
--   ✅ Aufgabe 4:  100/100 - Percent of Total mit Window Functions perfekt
--   ❌ Aufgabe 5:    0/100 - NICHT generiert! (LAG + Moving Average)
--   ❌ Aufgabe 6:    0/100 - NICHT generiert! (Running Total + LAG)
--   ❌ Aufgabe 7:    0/100 - NICHT generiert! (ETL + MERGE)
--   ❌ Aufgabe 8:    0/100 - NICHT generiert! (MERGE)
--   ❌ Aufgabe 9:   40/100 - MySQL Syntax + fehlt GROUPING()
--   ❌ Aufgabe 10:  30/100 - SELECT-Reihenfolge falsch + MySQL Syntax
--   ❌ Aufgabe 11:   0/100 - NICHT generiert! (Multi-CTE + LAG)
--   ❌ Aufgabe 12:   0/100 - NICHT generiert! (Subqueries)
--   ❌ Aufgabe 13:   0/100 - NICHT generiert! (Multi-Fact + Velocity)
--   ⚠️ Aufgabe 14:  70/100 - Multi-Fact JOIN OK, aber "hohe Verkäufe" nicht definiert
--   ❌ Aufgabe 15:   0/100 - NICHT generiert! (Sales-to-Stock Ratio)
--   ❌ Aufgabe 16:   0/100 - NICHT generiert! (Business Question #1)
--   ❌ Aufgabe 17:   0/100 - NICHT generiert! (Business Question #2 - RFM)
--   ❌ Aufgabe 18:   0/100 - NICHT generiert! (Business Question #3)
--
-- STÄRKEN:
--   + Complete Star-Schema JOINs: PERFEKT
--   + CTE mit Window Functions: PERFEKT
--   + Nested SUM OVER: PERFEKT
--
-- SCHWÄCHEN:
--   - 61.1% DER AUFGABEN KONNTEN NICHT GENERIERT WERDEN!
--   - Alle MERGE Statements: FAILED
--   - Alle Business Logic Queries: FAILED
--   - Alle Multi-CTE Queries: FAILED
--   - LAG + andere Funktionen kombiniert: FAILED
--   - ROLLUP: IMMER NOCH MySQL Syntax!
--
-- KRITISCHE FEHLER:
--   ⚠️ **61.1% KEINE QUERY GENERIERT!** (11 von 18 Aufgaben!)
--   ⚠️ Model gibt bei komplexen Aufgaben komplett auf!
--   ⚠️ AVG statt SUM bei Profitabilitätsberechnung (Business-Logik falsch!)
--   ⚠️ MERGE: KANN ES NICHT!
--   ⚠️ Business Intelligence Fragen: KOMPLETT ÜBERFORDERT!
--
-- EMPFEHLUNG: ❌ **ABSOLUT UNGEEIGNET FÜR EXPERT-LEVEL QUERIES!**
--              Dieses 4B Model ist für Production BI NICHT VERWENDBAR!
--              
-- **FINALE BEWERTUNG: NICHT PRODUCTION-READY!**
-- ============================================================================
