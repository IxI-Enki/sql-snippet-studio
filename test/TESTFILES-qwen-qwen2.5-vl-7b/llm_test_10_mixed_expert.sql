-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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

SELECT 
    c.customer_name AS Customer_Name,
    p.product_name AS Product_Name,
    ch.channel_name AS Channel_Name,
    e.employee_name AS Employee_Name,
    SUM(f.net_revenue) AS Total_Revenue
FROM 
    DIM_Customer c
JOIN 
    FACT_Sales f ON c.customer_key = f.customer_key
JOIN 
    DIM_Product p ON f.product_key = p.product_key
JOIN 
    DIM_Channel ch ON f.channel_key = ch.channel_key
JOIN 
    DIM_Employee e ON f.employee_key = e.employee_key
GROUP BY 
    c.customer_name, p.product_name, ch.channel_name, e.employee_name;
;


-- Aufgabe 2: Berechne die Profitabilität (profit / revenue * 100) pro Produktkategorie mit allen relevanten Dimensionsattributen

SELECT 
    p.category,
    c.segment,
    r.region,
    c.country,
    SUM(f.profit) AS total_profit,
    COUNT(*) AS product_count,
    AVG(f.revenue) AS average_revenue,
    AVG(f.profit / f.revenue * 100) AS profit_margin
FROM 
    DIM_Product p
JOIN 
    FACT_Sales f ON p.product_key = f.product_key
JOIN 
    DIM_Channel ch ON f.channel_key = ch.channel_key
JOIN 
    DIM_Customer c ON f.customer_key = c.customer_key
GROUP BY 
    p.category, c.segment, r.region, c.country;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)

WITH RankedProducts AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(f.net_revenue) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.net_revenue) DESC) as rank
    FROM 
        DIM_Product p
    JOIN 
        FACT_Sales f ON p.product_key = f.product_key
    GROUP BY 
        p.product_name, p.category
)
SELECT 
    rp.product_name,
    rp.category,
    rp.total_revenue
FROM 
    RankedProducts rp
WHERE 
    rank <= 5;


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)

SELECT c.customer_id, c.customer_name, SUM(f.net_revenue) OVER (PARTITION BY c.region) AS total_region_revenue,
       SUM(f.net_revenue) OVER () * 100 / COUNT(*) OVER () AS percent_of_total
FROM DIM_Customer c
JOIN FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY c.customer_id, c.customer_name, c.region;
;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)

SELECT p.product_code FROM DIM_Product p JOIN FACT_Sales fs ON p.product_key = fs.product_key WHERE fs.time_key IN (SELECT time_key FROM DIM_Time WHERE full_date >= CURRENT_DATE - INTERVAL '3 MONTH') AND fs.revenue < LAG(fs.revenue, 1) OVER (PARTITION BY p.product_code ORDER BY fs.time_key) * 0.8;


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)

SELECT e.employee_name, SUM(f.revenue) OVER (PARTITION BY e.employee_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - 
LAG(SUM(f.revenue), 1, 0) OVER (PARTITION BY e.employee_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM DIM_Employee e
JOIN FACT_Sales f ON e.employee_key = f.employee_key
GROUP BY e.employee_name, f.time_key;


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert

SELECT s.sale_date, c.customer_id, p.product_code, ch.channel_name, e.employee_id, s.quantity, s.revenue, s.cost, s.discount, s.net_revenue, s.profit 
       FROM STG_Sales_Updates s 
       JOIN DIM_Customer c ON s.customer_id = c.customer_id 
       JOIN DIM_Product p ON s.product_code = p.product_code 
       JOIN DIM_Channel ch ON s.channel_name = ch.channel_name 
       JOIN DIM_Employee e ON s.employee_id = e.employee_id) stg
ON fs.sale_id = stg.sale_date
WHEN MATCHED THEN UPDATE SET fs.quantity = fs.quantity + stg.quantity, fs.revenue = fs.revenue + stg.revenue, fs.cost = fs.cost + stg.cost, fs.discount = fs.discount + stg.discount, fs.net_revenue = fs.net_revenue + stg.net_revenue, fs.profit = fs.profit + stg.profit
WHEN NOT MATCHED THEN INSERT (fs.time_key, fs.customer_key, fs.product_key, fs.channel_key, fs.employee_key, fs.quantity, fs.revenue, fs.cost, fs.discount, fs.net_revenue, fs.profit) 
VALUES (stg.sale_date, c.customer_id, p.product_code, ch.channel_name, e.employee_id, stg.quantity, stg.revenue, stg.cost, stg.discount, stg.net_revenue, stg.profit)
RETURNING fs.sale_id;

INSERT INTO ETL_Log (table_name, rows_inserted) 
SELECT 'FACT_Sales', COUNT(*) FROM FACT_SALES WHERE sale_id IN (SELECT sale_date FROM STG_SALES_UPDATES);

COMMIT;


-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)

SELECT product_code FROM FACT_Sales WHERE full_date >= CURRENT_DATE - INTERVAL '6 MONTH'
) s ON p.product_code = s.product_code 
WHEN NOT MATCHED THEN UPDATE SET is_active = FALSE;


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)

SELECT 
    region,
    country,
    segment,
    channel_name,
    SUM(revenue) AS total_revenue,
    SUM(profit) AS total_profit
FROM 
    FACT_Sales fs
JOIN 
    DIM_Channel dc ON fs.channel_key = dc.channel_key
JOIN 
    DIM_Customer dcu ON fs.customer_key = dcu.customer_key
GROUP BY 
    region, country, segment, channel_name WITH ROLLUP;


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)

SELECT 
    fiscal_year,
    fiscal_quarter,
    month,
    SUM(revenue) AS total_revenue
FROM 
    FACT_Sales
GROUP BY 
    ROLLUP(fiscal_year, fiscal_quarter, month);


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend

WITH ProductSales AS (
    SELECT 
        p.product_name,
        t.month,
        SUM(f.net_revenue) AS monthly_sales
    FROM 
        DIM_Product p
    JOIN 
        FACT_Sales f ON p.product_key = f.product_key
    JOIN 
        DIM_Time t ON f.time_key = t.time_key
    GROUP BY 
        p.product_name, t.month
),
TrendCalculation AS (
    SELECT 
        ps.product_name,
        ps.month,
        ps.monthly_sales - LAG(ps.monthly_sales) OVER (PARTITION BY ps.product_name ORDER BY ps.month) AS sales_trend
    FROM 
        ProductSales ps
)
SELECT 
    tc.product_name, 
    tc.month, 
    tc.sales_trend
FROM 
    TrendCalculation tc
WHERE 
    tc.sales_trend > 0 AND tc.product_name IN (
        SELECT 
            p.product_name
        FROM 
            DIM_Product p
        WHERE 
            p.margin_percent > 0.1;
);


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)

SELECT e.employee_name FROM DIM_Employee e JOIN (
    SELECT employee_key, SUM(net_revenue) AS total_sales 
    FROM FACT_Sales fs 
    GROUP BY employee_key
) s ON e.employee_key = s.employee_key WHERE s.total_sales > (SELECT AVG(total_sales) FROM (
    SELECT SUM(net_revenue) AS total_sales 
    FROM FACT_Sales fs 
    GROUP BY employee_key
)) AND (
    SELECT AVG(lifetime_value) 
    FROM DIM_Customer c 
    JOIN FACT_Sales fs ON c.customer_key = fs.customer_key 
    WHERE fs.employee_key = e.employee_key
) > (SELECT AVG(lifetime_value) FROM DIM_Customer);


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist

SELECT p.product_name, i.quantity_on_hand, AVG(f.revenue / f.quantity) AS sales_velocity 
FROM DIM_Product p 
JOIN FACT_Inventory i ON p.product_key = i.product_key 
JOIN FACT_Sales f ON p.product_key = f.product_key AND f.time_key IN (SELECT time_key FROM DIM_Time WHERE full_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE) 
WHERE i.quantity_on_hand < i.reorder_point 
GROUP BY p.product_name, i.quantity_on_hand 
ORDER BY sales_velocity DESC;


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)

SELECT p.product_name FROM DIM_Product p JOIN FACT_Sales fs ON p.product_key = fs.product_key JOIN FACT_Inventory fi ON p.product_key = fi.product_key WHERE fs.revenue > 1000 AND fi.quantity_on_hand < 50;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)

SELECT p.product_name, f.inventory_id, SUM(f.quantity_on_hand) AS total_stock, SUM(s.quantity) * s.revenue AS sales_amount,
       (SUM(s.quantity) * s.revenue) / SUM(f.quantity_on_hand) AS sales_to_stock_ratio
FROM DIM_Product p
JOIN FACT_Inventory f ON p.product_key = f.product_key
JOIN STG_Sales_Updates s ON p.product_code = s.product_code AND s.sale_date BETWEEN f.time_key AND (f.time_key + INTERVAL '1 month')
GROUP BY p.product_name, f.inventory_id
HAVING sales_to_stock_ratio > 0.8;


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management

SELECT 
    p.category,
    c.region,
    SUM(f.net_revenue) AS revenue,
    COUNT(DISTINCT f.sale_id) AS sales_count,
    AVG(f.profit) AS profit_margin,
    LAG(SUM(f.net_revenue), 1, 0) OVER (PARTITION BY p.category ORDER BY c.region) AS lag_revenue
FROM 
    DIM_Customer c
JOIN 
    FACT_Sales f ON c.customer_key = f.customer_key
JOIN 
    DIM_Product p ON f.product_key = p.product_key
GROUP BY 
    p.category, c.region
WITH ROLLUP;
;


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)

SELECT customer_name, SUM(net_revenue) AS total_profit 
FROM FACT_Sales fs JOIN DIM_Customer dc ON fs.customer_key = dc.customer_key 
GROUP BY customer_name 
ORDER BY total_profit DESC;

WITH RFM AS (
  SELECT 
    customer_key,
    MAX(time_key) OVER (PARTITION BY customer_key) AS last_time_key,
    COUNT(*) OVER (PARTITION BY customer_key) AS freq,
    SUM(revenue) OVER (PARTITION BY customer_key) AS mon
  FROM FACT_Sales fs JOIN DIM_Time dt ON fs.time_key = dt.time_key
)
SELECT 
  customer_name, 
  NTILE(4) OVER (ORDER BY last_time_key DESC) AS recency,
  NTILE(4) OVER (ORDER BY freq DESC) AS frequency,
  NTILE(4) OVER (ORDER BY mon DESC) AS monetary
FROM RFM JOIN DIM_Customer dc ON RFM.customer_key = dc.customer_key;

WITH ProductAffinity AS (
  SELECT 
    customer_key, 
    product_key, 
    SUM(revenue) AS total_revenue
  FROM FACT_Sales fs JOIN DIM_Product dp ON fs.product_key = dp.product_key
  GROUP BY customer_key, product_key
)
SELECT 
  dc.customer_name,
  p1.product_name as first_product,
  p2.product_name as second_product,
  SUM(pa.total_revenue) AS total_revenue
FROM ProductAffinity pa JOIN DIM_Customer dc ON pa.customer_key = dc.customer_key
JOIN DIM_Product p1 ON pa.product_key = p1.product_key
JOIN DIM_Product p2 ON pa.customer_key = p2.customer_key AND pa.product_key != p2.product_key
GROUP BY dc.customer_name, p1.product_name, p2.product_name
ORDER BY total_revenue DESC;


-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category

SELECT 
    c.channel_name,
    p.category,
    SUM(f.profit) AS total_profit,
    AVG(f.cost / f.revenue) AS cost_efficiency,
    (SUM(f.profit) - SUM(f.cost)) > 0 AS profit_trend,
    ROLLUP(c.channel_name, p.category)
FROM 
    DIM_Channel c
JOIN 
    FACT_Sales f ON c.channel_key = f.channel_key
JOIN 
    DIM_Product p ON f.product_key = p.product_key
GROUP BY 
    ROLLUP(c.channel_name, p.category);


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
