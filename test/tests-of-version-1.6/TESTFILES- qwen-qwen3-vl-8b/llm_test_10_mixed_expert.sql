-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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
GROUP BY c.customer_name, p.product_name, ch.channel_name, e.employee_name;


-- Aufgabe 2: Berechne die Profitabilität (profit / revenue * 100) pro Produktkategorie mit allen relevanten Dimensionsattributen

SELECT 
    p.category,
    p.product_name,
    SUM(f.profit) AS total_profit,
    SUM(f.revenue) AS total_revenue,
    (SUM(f.profit) / SUM(f.revenue) * 100) AS profitability_percent,
    c.channel_name,
    cu.customer_name,
    t.month_name,
    t.year
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Channel c ON f.channel_key = c.channel_key
JOIN DIM_Customer cu ON f.customer_key = cu.customer_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY p.category, p.product_name, c.channel_name, cu.customer_name, t.month_name, t.year;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)

WITH RankedProducts AS (
    SELECT 
        p.product_key,
        p.product_name,
        p.category,
        SUM(f.revenue) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(f.revenue) DESC) AS rank
    FROM FACT_Sales f
    JOIN DIM_Product p ON f.product_key = p.product_key
    GROUP BY p.product_key, p.product_name, p.category
)
SELECT 
    product_name,
    category,
    total_revenue
FROM RankedProducts
WHERE rank <= 5
ORDER BY category, rank;


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)

SELECT 
    c.customer_name,
    c.region,
    SUM(f.revenue) AS customer_revenue,
    SUM(SUM(f.revenue)) OVER (PARTITION BY c.region) AS region_total_revenue,
    (SUM(f.revenue) / SUM(SUM(f.revenue)) OVER (PARTITION BY c.region)) * 100 AS percent_of_region_total
FROM 
    DIM_Customer c
JOIN 
    FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key, c.customer_name, c.region
ORDER BY 
    c.region, percent_of_region_total DESC;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)

SELECT 
    p.product_key,
    p.product_name,
    SUM(f.revenue) AS current_month_revenue,
    LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.product_key ORDER BY t.time_key) AS prev_month_revenue,
    (SUM(f.revenue) - LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.product_key ORDER BY t.time_key)) / LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.product_key ORDER BY t.time_key) * 100 AS revenue_change_percent
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY p.product_key, p.product_name
HAVING (SUM(f.revenue) - LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.product_key ORDER BY t.time_key)) / LAG(SUM(f.revenue), 1) OVER (PARTITION BY p.product_key ORDER BY t.time_key) * 100 < -20
ORDER BY revenue_change_percent ASC;


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)

SELECT 
    e.employee_name,
    t.full_date,
    f.revenue,
    SUM(f.revenue) OVER (PARTITION BY e.employee_key ORDER BY t.full_date) AS running_total,
    LAG(SUM(f.revenue), 1) OVER (PARTITION BY e.employee_key ORDER BY t.full_date) AS prev_month_total
FROM FACT_Sales f
JOIN DIM_Time t ON f.time_key = t.time_key
JOIN DIM_Employee e ON f.employee_key = e.employee_key
WHERE t.full_date >= '2023-01-01'
GROUP BY e.employee_key, e.employee_name, t.full_date, f.revenue
ORDER BY e.employee_key, t.full_date;


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert

SELECT 
        s.sale_date,
        s.customer_id,
        s.product_code,
        s.channel_name,
        s.employee_id,
        s.quantity,
        s.revenue,
        s.cost,
        s.discount,
        t.time_key,
        c.customer_key,
        p.product_key,
        ch.channel_key,
        e.employee_key
    FROM STG_Sales_Updates s
    JOIN DIM_Time t ON t.full_date = s.sale_date
    JOIN DIM_Customer c ON c.customer_id = s.customer_id
    JOIN DIM_Product p ON p.product_code = s.product_code
    JOIN DIM_Channel ch ON ch.channel_name = s.channel_name
    JOIN DIM_Employee e ON e.employee_id = s.employee_id
) AS source
ON target.sale_id = source.sale_id
WHEN MATCHED THEN
    UPDATE SET
        time_key = source.time_key,
        customer_key = source.customer_key,
        product_key = source.product_key,
        channel_key = source.channel_key,
        employee_key = source.employee_key,
        quantity = source.quantity,
        revenue = source.revenue,
        cost = source.cost,
        discount = source.discount
WHEN NOT MATCHED THEN
    INSERT (
        time_key,
        customer_key,
        product_key,
        channel_key,
        employee_key,
        quantity,
        revenue,
        cost,
        discount,
        net_revenue,
        profit
    )
    VALUES (
        source.time_key,
        source.customer_key,
        source.product_key,
        source.channel_key,
        source.employee_key,
        source.quantity,
        source.revenue,
        source.cost,
        source.discount,
        source.revenue - source.cost - source.discount,
        source.revenue - source.cost - source.discount - source.cost
    );

INSERT INTO ETL_Log (table_name, rows_inserted, rows_updated, rows_deleted, status)
SELECT 
    'FACT_Sales',
    COUNT(CASE WHEN source.sale_id IS NULL THEN 1 END) AS rows_inserted,
    COUNT(CASE WHEN target.sale_id IS NOT NULL THEN 1 END) AS rows_updated,
    0 AS rows_deleted,
    'SUCCESS'
FROM (
    SELECT 
        s.sale_date,
        s.customer_id,
        s.product_code,
        s.channel_name,
        s.employee_id,
        s.quantity,
        s.revenue,
        s.cost,
        s.discount,
        t.time_key,
        c.customer_key,
        p.product_key,
        ch.channel_key,
        e.employee_key
    FROM STG_Sales_Updates s
    JOIN DIM_Time t ON t.full_date = s.sale_date
    JOIN DIM_Customer c ON c.customer_id = s.customer_id
    JOIN DIM_Product p ON p.product_code = s.product_code
    JOIN DIM_Channel ch ON ch.channel_name = s.channel_name
    JOIN DIM_Employee e ON e.employee_id = s.employee_id
) AS source
FULL OUTER JOIN FACT_Sales target ON target.sale_id = source.sale_id;


-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)

SELECT product_key, product_code
    FROM DIM_Product
    EXCEPT
    SELECT DISTINCT fp.product_key
    FROM FACT_Sales fs
    JOIN DIM_Product fp ON fs.product_key = fp.product_key
    WHERE fs.sale_date >= CURRENT_DATE - INTERVAL '6 months'
) AS source
ON target.product_key = source.product_key
WHEN MATCHED THEN
UPDATE SET is_active = FALSE;


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)

SELECT 
    r.region,
    r.country,
    c.segment,
    ch.channel_name,
    SUM(f.revenue) AS total_revenue,
    SUM(f.profit) AS total_profit
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
JOIN DIM_Time t ON f.time_key = t.time_key
JOIN DIM_Employee e ON f.employee_key = e.employee_key
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
JOIN DIM_Time t ON f.time_key = t.time_key
JOIN DIM_Employee e ON f.employee_key = e.employee_key
GROUP BY ROLLUP (r.region, r.country, c.segment, ch.channel_name);


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)

SELECT 
    dt.fiscal_year,
    dt.fiscal_quarter,
    dt.month_name,
    SUM(fs.quantity) AS total_quantity
FROM FACT_Sales fs
JOIN DIM_Time dt ON fs.time_key = dt.time_key
GROUP BY ROLLUP (dt.fiscal_year, dt.fiscal_quarter, dt.month_name);


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend

WITH MonthlyRevenue AS (
    SELECT 
        p.product_key,
        p.product_name,
        t.month,
        SUM(f.revenue) AS monthly_revenue
    FROM FACT_Sales f
    JOIN DIM_Product p ON f.product_key = p.product_key
    JOIN DIM_Time t ON f.time_key = t.time_key
    GROUP BY p.product_key, p.product_name, t.month
),
RevenueTrend AS (
    SELECT 
        product_key,
        product_name,
        month,
        monthly_revenue,
        LAG(monthly_revenue, 1) OVER (PARTITION BY product_key ORDER BY month) AS prev_month_revenue,
        (monthly_revenue - LAG(monthly_revenue, 1) OVER (PARTITION BY product_key ORDER BY month)) AS revenue_change
    FROM MonthlyRevenue
),
ProfitableProducts AS (
    SELECT 
        product_key,
        product_name,
        SUM(profit) AS total_profit
    FROM FACT_Sales
    JOIN DIM_Product p ON FACT_Sales.product_key = p.product_key
    GROUP BY product_key, product_name
)
SELECT 
    p.product_name,
    p.total_profit,
    rt.month,
    rt.monthly_revenue,
    rt.revenue_change
FROM ProfitableProducts p
JOIN RevenueTrend rt ON p.product_key = rt.product_key
WHERE rt.revenue_change > 0
ORDER BY p.total_profit DESC;


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)

SELECT e.employee_name, c.customer_name, c.lifetime_value, SUM(f.quantity) AS total_quantity_sold
FROM DIM_Employee e
JOIN FACT_Sales f ON e.employee_key = f.employee_key
JOIN DIM_Customer c ON f.customer_key = c.customer_key
WHERE c.lifetime_value > (SELECT AVG(lifetime_value) FROM DIM_Customer)
AND f.quantity > (SELECT AVG(quantity) FROM FACT_Sales)
GROUP BY e.employee_key, c.customer_key, e.employee_name, c.customer_name, c.lifetime_value
ORDER BY total_quantity_sold DESC;


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist

SELECT 
    p.product_name,
    p.product_code,
    i.reorder_point,
    i.quantity_on_hand,
    AVG(s.quantity) AS avg_daily_sales_last_30_days
FROM 
    FACT_Inventory i
JOIN 
    DIM_Product p ON i.product_key = p.product_key
JOIN 
    DIM_Time t ON i.time_key = t.time_key
JOIN 
    FACT_Sales s ON s.product_key = p.product_key
WHERE 
    i.quantity_on_hand < i.reorder_point
    AND t.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY 
    p.product_name, p.product_code, i.reorder_point, i.quantity_on_hand
HAVING 
    AVG(s.quantity) > 0
ORDER BY 
    avg_daily_sales_last_30_days DESC;


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)

SELECT p.product_name, SUM(s.quantity) AS total_quantity_sold, SUM(s.revenue) AS total_revenue, SUM(i.quantity_on_hand) AS total_inventory
FROM FACT_Sales s
JOIN FACT_Inventory i ON s.product_key = i.product_key
JOIN DIM_Product p ON s.product_key = p.product_key
GROUP BY p.product_name
HAVING SUM(s.quantity) > 0 AND SUM(i.quantity_on_hand) < 100
ORDER BY total_revenue DESC;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)

SELECT 
    p.product_key,
    p.product_name,
    SUM(f.quantity) AS total_sales_quantity,
    SUM(f.quantity) / SUM(i.quantity_on_hand) AS sales_to_stock_ratio
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN FACT_Inventory i ON f.product_key = i.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= '2020-01-01' -- Beispiel-Datum, anpassbar
GROUP BY p.product_key, p.product_name
HAVING SUM(f.quantity) / SUM(i.quantity_on_hand) > 0.8;


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management

SELECT 
    p.category,
    c.region,
    SUM(s.revenue) AS total_revenue,
    SUM(s.profit) AS total_profit,
    AVG(p.margin_percent) AS avg_margin_percent,
    COUNT(*) AS sale_count,
    LAG(SUM(s.revenue)) OVER (PARTITION BY p.category ORDER BY c.region) AS prev_region_revenue,
    SUM(s.revenue) * 100.0 / SUM(SUM(s.revenue)) OVER () AS market_share,
    ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(s.revenue) DESC) AS rank_by_revenue
FROM FACT_Sales s
JOIN DIM_Product p ON s.product_key = p.product_key
JOIN DIM_Customer c ON s.customer_key = c.customer_key
GROUP BY ROLLUP (p.category, c.region)
ORDER BY p.category, c.region;


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)

SELECT 
    c.customer_key,
    c.customer_name,
    SUM(f.profit) AS total_profit,
    COUNT(f.sale_id) AS purchase_count,
    MAX(f.time_key) AS last_purchase_time,
    MIN(f.time_key) AS first_purchase_time,
    AVG(f.revenue) AS avg_revenue_per_sale
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY total_profit DESC;

SELECT 
    c.customer_key,
    c.customer_name,
    NTILE(4) OVER (ORDER BY SUM(f.profit) DESC) AS profitability_segment,
    COUNT(f.sale_id) AS frequency,
    SUM(f.revenue) AS monetary_value,
    MAX(f.time_key) AS recency
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.customer_name
ORDER BY SUM(f.profit) DESC;

SELECT 
    c.customer_name,
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS co_purchase_count
FROM FACT_Sales f1
JOIN FACT_Sales f2 ON f1.customer_key = f2.customer_key
JOIN DIM_Product p1 ON f1.product_key = p1.product_key
JOIN DIM_Product p2 ON f2.product_key = p2.product_key
WHERE f1.time_key < f2.time_key
  AND p1.product_key <> p2.product_key
GROUP BY c.customer_name, p1.product_name, p2.product_name
ORDER BY co_purchase_count DESC
LIMIT 100;


-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category

SELECT 
    c.channel_name,
    p.category,
    SUM(f.profit) AS total_profit,
    SUM(f.revenue) AS total_revenue,
    SUM(f.cost) AS total_cost,
    SUM(f.quantity) AS total_quantity,
    AVG(f.profit / f.revenue) AS avg_profit_margin,
    COUNT(*) AS sale_count,
    MIN(f.time_key) AS earliest_sale,
    MAX(f.time_key) AS latest_sale
FROM FACT_Sales f
JOIN DIM_Channel c ON f.channel_key = c.channel_key
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY ROLLUP((c.channel_name, p.category))
ORDER BY 
    CASE WHEN GROUPING(c.channel_name) = 1 THEN 0 ELSE 1 END,
    CASE WHEN GROUPING(p.category) = 1 THEN 0 ELSE 1 END,
    c.channel_name,
    p.category;


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
