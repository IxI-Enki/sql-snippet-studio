-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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

SELECT c.customer_name, p.product_name, ch.channel_name, e.employee_id, SUM(f.net_revenue) AS total_sales FROM FACT_Sales f JOIN DIM_Customer c ON f.customer_key = c.customer_key JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Channel ch ON f.channel_key = ch.channel_key JOIN DIM_Employee e ON f.employee_key = e.employee_key GROUP BY c.customer_name, p.product_name, ch.channel_name, e.employee_id;


-- Aufgabe 2: Berechne die Profitabilität (profit / revenue * 100) pro Produktkategorie mit allen relevanten Dimensionsattributen

SELECT p.category, c.channel_name, e.department, t.month_name, AVG(f.profit / NULLIF(f.revenue, 0) * 100) AS avg_profit_margin FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Channel c ON f.channel_key = c.channel_key JOIN DIM_Employee e ON f.employee_key = e.employee_key JOIN DIM_Time t ON f.time_key = t.time_key GROUP BY p.category, c.channel_name, e.department, t.month_name ORDER BY avg_profit_margin DESC NULLS LAST;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)

WITH product_sales AS (SELECT p.product_key, p.product_name, c.channel_name, e.employee_id, s.quantity, s.revenue, DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(s.net_revenue) DESC) AS sales_rank FROM FACT_Sales s JOIN DIM_Product p ON s.product_key = p.product_key JOIN DIM_Channel c ON s.channel_key = c.channel_key JOIN DIM_Employee e ON s.employee_key = e.employee_key GROUP BY p.product_key, p.product_name, c.channel_name, e.employee_id) SELECT ps.product_name, ps.channel_name, ps.employee_id, ps.quantity, ps.revenue FROM product_sales ps WHERE sales_rank <= 5;


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)

SELECT c.customer_key, c.customer_name, SUM(s.net_revenue) OVER (PARTITION BY c.region ORDER BY s.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) / NULLIF(SUM(s.net_revenue) OVER (PARTITION BY c.region ORDER BY s.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW), 0) AS proportion FROM FACT_Sales s JOIN DIM_Customer c ON s.customer_key = c.customer_key;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)

SELECT p.product_code, AVG(p.list_price) OVER (PARTITION BY p.product_key ORDER BY t.full_date ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_list_price_3_months_ago, (AVG(p.list_price) - LAG(AVG(p.list_price), 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) / NULLIF(LAG(AVG(p.list_price), 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date), 0) * 100 AS percentage_change FROM FACT_Sales fs JOIN DIM_Product p ON fs.product_key = p.product_key JOIN DIM_Time t ON fs.time_key = t.time_key WHERE t.full_date >= (CURRENT_DATE - INTERVAL '3 months') GROUP BY p.product_code, p.product_key, t.full_date HAVING ((AVG(p.list_price) - LAG(AVG(p.list_price), 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date)) / NULLIF(LAG(AVG(p.list_price), 1) OVER (PARTITION BY p.product_key ORDER BY t.full_date), 0) * 100) < -20;


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)

SELECT e.employee_key, e.employee_name, SUM(f.net_revenue) OVER (PARTITION BY e.employee_key ORDER BY t.full_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_sales, LAG(SUM(f.net_revenue), 1) OVER (PARTITION BY e.employee_key ORDER BY t.full_date) AS previous_month_sales FROM FACT_Sales f JOIN DIM_Employee e ON f.employee_key = e.employee_key JOIN DIM_Time t ON f.time_key = t.time_key;


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert

SELECT s.quantity, s.revenue, c.customer_name, p.product_name, e.employee_id FROM STG_Sales_Updates s JOIN DIM_Customer c ON s.customer_id = c.customer_id JOIN DIM_Product p ON s.product_code = p.product_code JOIN DIM_Employee e ON s.employee_id = e.employee_id;


-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)

SELECT p.product_key, p.product_name FROM DIM_Product p JOIN FACT_Sales fs ON p.product_key = fs.product_key WHERE fs.time_key NOT IN (SELECT t.time_key FROM DIM_Time t WHERE t.full_date > CURRENT_DATE - INTERVAL '6 months') ORDER BY p.product_name NULLS LAST;


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)

SELECT d.customer_segment, d.region, d.country, c.channel_name, SUM(f.revenue) AS total_revenue, SUM(f.profit) AS total_profit FROM FACT_Sales f JOIN DIM_Customer d ON f.customer_key = d.customer_key JOIN DIM_Channel c ON f.channel_key = c.channel_key GROUP BY ROLLUP(d.customer_segment, d.region, d.country, c.channel_name), d.customer_segment, d.region, d.country, c.channel_name ORDER BY d.customer_segment NULLS LAST, d.region NULLS LAST, d.country NULLS LAST, c.channel_name NULLS LAST;


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)

SELECT t.full_date, SUM(f.net_revenue) AS total_sales FROM FACT_Sales f JOIN DIM_Time t ON f.time_key = t.time_key GROUP BY ROLLUP(t.year, t.quarter, t.month), t.full_date ORDER BY 1 NULLS LAST;


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend

WITH product_sales AS (SELECT p.product_key, t.full_date, SUM(f.quantity) AS sales_quantity FROM DIM_Product p JOIN FACT_Sales f ON p.product_key = f.product_key JOIN DIM_Time t ON f.time_key = t.time_key GROUP BY p.product_key, t.full_date), product_trend AS (SELECT ps.product_key, ps.full_date, LAG(ps.sales_quantity) OVER (PARTITION BY ps.product_key ORDER BY ps.full_date) AS previous_sales FROM product_sales ps) SELECT pt.product_key, pt.full_date, pt.sales_quantity - pt.previous_sales AS sales_difference FROM product_trend pt WHERE pt.sales_difference > 0;


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)

SELECT e.employee_key, e.employee_id, e.employee_name, AVG(f.profit) AS average_profit FROM FACT_Sales f JOIN DIM_Employee e ON f.employee_key = e.employee_key GROUP BY e.employee_key, e.employee_id, e.employee_name HAVING AVG(f.profit) > (SELECT AVG(profit) FROM FACT_Sales);


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist

SELECT p.product_name, i.quantity_on_hand, s.revenue, (s.revenue / NULLIF(i.time_key - lag(i.time_key) OVER (PARTITION BY i.product_key ORDER BY i.time_key), 0)) AS sales_velocity FROM FACT_Inventory i JOIN STG_Sales_Updates s ON i.product_key = s.product_code AND i.time_key = s.sale_date::DATE WHERE i.quantity_on_hand <= i.reorder_point AND i.time_key BETWEEN (CURRENT_DATE - INTERVAL '30 days') AND CURRENT_DATE ORDER BY sales_velocity DESC NULLS LAST;


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)

SELECT f.product_key, p.product_name FROM FACT_Sales f JOIN FACT_Inventory i ON f.time_key = i.time_key AND f.product_key = i.product_key JOIN DIM_Product p ON f.product_key = p.product_key WHERE f.quantity > 1000 AND i.quantity_on_hand < 500;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)

SELECT p.product_name, CAST(SUM(f.quantity) AS FLOAT) / NULLIF(SUM(i.quantity_on_hand), 0) AS sales_to_stock_ratio FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN FACT_Inventory i ON f.time_key = i.time_key GROUP BY p.product_name HAVING CAST(SUM(f.quantity) AS FLOAT) / NULLIF(SUM(i.quantity_on_hand), 0) > 0.8 ORDER BY sales_to_stock_ratio DESC;


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management

SELECT p.category, d.region, SUM(f.revenue) OVER (PARTITION BY p.category, d.region ORDER BY f.time_key ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_revenue, LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.category, d.region ORDER BY f.time_key) AS previous_year_revenue, SUM(f.profit) / NULLIF(SUM(f.cost), 0) * 100 AS margin_percentage FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Channel c ON f.channel_key = c.channel_key JOIN DIM_Customer d ON f.customer_key = d.customer_key; WITH category_market_share AS (SELECT p.category, d.region, SUM(f.revenue) / NULLIF(SUM(f.cost), 0) * 100 AS market_share FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Channel c ON f.channel_key = c.channel_key JOIN DIM_Customer d ON f.customer_key = d.customer_key GROUP BY p.category, d.region) SELECT p.category, d.region, cs.market_share, SUM(cs.market_share) OVER (PARTITION BY d.region ORDER BY p.category ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_market_share FROM category_market_share cs JOIN DIM_Product p ON cs.category = p.category JOIN DIM_Customer d ON cs.region = d.region; SELECT p.category, d.region, SUM(f.profit) / NULLIF(SUM(f.cost), 0) * 100 AS margin_percentage FROM FACT_Sales f JOIN DIM_Product p ON f.product_key = p.product_key JOIN DIM_Channel c ON f.channel_key = c.channel_key JOIN DIM_Customer d ON f.customer_key = d.customer_key GROUP BY p.category, d.region ROLLUP (p.category, d.region);


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)

SELECT c.customer_name, f.profit, row_number() OVER(PARTITION BY c.customer_key ORDER BY f.profit DESC) AS profit_rank FROM FACT_Sales f JOIN DIM_Customer c ON f.customer_key = c.customer_key; WITH customer_rfm AS (SELECT d.customer_key, NTILE(4) OVER (ORDER BY d.last_order_date DESC) AS recency, COUNT(o.order_id) AS frequency, SUM(o.total_amount) AS monetary_value FROM customer_orders o JOIN customer_details d ON o.customer_id = d.customer_id GROUP BY d.customer_id) SELECT c.customer_name, rfm.recency, rfm.frequency, rfm.monetary_value, row_number() OVER(PARTITION BY rfm.recency ORDER BY rfm.frequency DESC, rfm.monetary_value DESC) AS rfm_rank FROM customer_rfm rfm JOIN DIM_Customer c ON rfm.customer_key = c.customer_key; WITH product_affinity AS (SELECT p.product_name, COUNT(*) AS co_purchases FROM FACT_Sales s JOIN DIM_Product p ON s.product_key = p.product_key GROUP BY p.product_name HAVING COUNT(DISTINCT s.product_key) > 1) SELECT pa.product_name, row_number() OVER(PARTITION BY pa.product_name ORDER BY pa.co_purchases DESC) AS product_rank FROM product_affinity pa;


-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category

SELECT c.channel_name, p.product_category, SUM(f.profit) AS total_profit FROM FACT_Sales f JOIN DIM_Channel c ON f.channel_key = c.channel_key JOIN DIM_Product p ON f.product_key = p.product_key GROUP BY c.channel_name, p.product_category ORDER BY total_profit DESC NULLS LAST;


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
