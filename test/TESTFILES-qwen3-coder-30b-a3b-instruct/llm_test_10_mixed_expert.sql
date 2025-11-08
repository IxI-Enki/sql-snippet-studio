-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴 EXPERT
-- Focus: Star-Schema + Window Functions + MERGE + ROLLUP + CTEs + Subqueries
-- Test Coverage: COMPLETE - All Topics Combined in Real-World Scenarios
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
    p.product_code,
    p.product_name,
    p.brand,
    SUM(f.profit) AS total_profit,
    SUM(f.revenue) AS total_revenue,
    (SUM(f.profit) / NULLIF(SUM(f.revenue), 0) * 100) AS profitability_percent
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY p.category, p.product_code, p.product_name, p.brand
ORDER BY total_profit DESC;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)

WITH RankedProducts AS (
    SELECT 
        p.product_name,
        p.category,
        SUM(s.revenue) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.category ORDER BY SUM(s.revenue) DESC) AS rank_in_category
    FROM FACT_Sales s
    JOIN DIM_Product p ON s.product_key = p.product_key
    GROUP BY p.product_name, p.category
)
SELECT 
    product_name,
    category,
    total_revenue
FROM RankedProducts
WHERE rank_in_category <= 5
ORDER BY category, rank_in_category;


-- Aufgabe 4: Berechne für jeden Kunden seinen Anteil am Gesamtumsatz seiner Region (Percent of Total mit Window Functions)

SELECT 
    c.customer_key,
    c.customer_name,
    c.region,
    SUM(f.revenue) AS customer_revenue,
    SUM(SUM(f.revenue)) OVER (PARTITION BY c.region) AS total_region_revenue,
    (SUM(f.revenue) * 100.0 / SUM(SUM(f.revenue)) OVER (PARTITION BY c.region)) AS percent_of_total
FROM 
    FACT_Sales f
JOIN 
    DIM_Customer c ON f.customer_key = c.customer_key
GROUP BY 
    c.customer_key, c.customer_name, c.region;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)

SELECT 
    p.product_code,
    p.product_name,
    t.full_date,
    f.revenue,
    LAG(f.revenue) OVER (
        PARTITION BY p.product_key 
        ORDER BY t.full_date
    ) AS prev_revenue,
    (f.revenue - LAG(f.revenue) OVER (
        PARTITION BY p.product_key 
        ORDER BY t.full_date
    )) / LAG(f.revenue) OVER (
        PARTITION BY p.product_key 
        ORDER BY t.full_date
    ) * 100 AS revenue_change_percent
FROM FACT_Sales f
JOIN DIM_Product p ON f.product_key = p.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= CURRENT_DATE - INTERVAL '3 months'
AND LAG(f.revenue) OVER (
    PARTITION BY p.product_key 
    ORDER BY t.full_date
) IS NOT NULL
AND (f.revenue - LAG(f.revenue) OVER (
    PARTITION BY p.product_key 
    ORDER BY t.full_date
)) / LAG(f.revenue) OVER (
    PARTITION BY p.product_key 
    ORDER BY t.full_date
) * 100 < -20;


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)

SELECT 
    e.employee_key,
    e.employee_name,
    t.full_date,
    SUM(fs.revenue) OVER (
        PARTITION BY e.employee_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_revenue,
    LAG(SUM(fs.revenue) OVER (
        PARTITION BY e.employee_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ), 1) OVER (
        PARTITION BY e.employee_key 
        ORDER BY t.full_date
    ) AS previous_month_revenue
FROM FACT_Sales fs
JOIN DIM_Employee e ON fs.employee_key = e.employee_key
JOIN DIM_Time t ON fs.time_key = t.time_key
GROUP BY e.employee_key, e.employee_name, t.full_date
ORDER BY e.employee_key, t.full_date;


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert
!!!TIMEOUT !!!

-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)

UPDATE DIM_Product 
SET is_active = FALSE 
WHERE product_key IN (
    SELECT p.product_key 
    FROM DIM_Product p 
    LEFT JOIN FACT_Sales f ON p.product_key = f.product_key 
    WHERE f.time_key IS NULL OR f.time_key NOT IN (
        SELECT time_key 
        FROM DIM_Time 
        WHERE full_date >= CURRENT_DATE - INTERVAL '6 months'
    )
);


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)

SELECT 
    c.region,
    c.country,
    c.segment,
    ch.channel_name,
    SUM(f.revenue) AS total_revenue,
    SUM(f.profit) AS total_profit,
    GROUPING(c.region) + GROUPING(c.country) + GROUPING(c.segment) + GROUPING(ch.channel_name) AS grouping_level
FROM FACT_Sales f
JOIN DIM_Customer c ON f.customer_key = c.customer_key
JOIN DIM_Channel ch ON f.channel_key = ch.channel_key
GROUP BY ROLLUP(c.region, c.country, c.segment, ch.channel_name)
ORDER BY grouping_level, c.region, c.country, c.segment, ch.channel_name;


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)

SELECT 
    t.fiscal_year,
    t.fiscal_quarter,
    t.month_name,
    SUM(s.quantity) AS total_quantity
FROM FACT_Sales s
JOIN DIM_Time t ON s.time_key = t.time_key
GROUP BY ROLLUP(t.fiscal_year, t.fiscal_quarter, t.month_name)
ORDER BY t.fiscal_year, t.fiscal_quarter, t.month_name;


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend

WITH monthly_revenue AS (
    SELECT 
        p.product_key,
        t.month,
        SUM(s.revenue) AS total_revenue
    FROM FACT_Sales s
    JOIN DIM_Product p ON s.product_key = p.product_key
    JOIN DIM_Time t ON s.time_key = t.time_key
    GROUP BY p.product_key, t.month
),
trend_calculation AS (
    SELECT 
        product_key,
        month,
        total_revenue,
        LAG(total_revenue) OVER (PARTITION BY product_key ORDER BY month) AS prev_month_revenue
    FROM monthly_revenue
),
profitable_products AS (
    SELECT 
        p.product_key,
        p.product_name,
        SUM(s.profit) AS total_profit
    FROM FACT_Sales s
    JOIN DIM_Product p ON s.product_key = p.product_key
    GROUP BY p.product_key, p.product_name
    HAVING SUM(s.profit) > 0
)
SELECT DISTINCT pp.product_key, pp.product_name
FROM profitable_products pp
JOIN trend_calculation tc ON pp.product_key = tc.product_key
WHERE tc.prev_month_revenue IS NOT NULL 
AND tc.total_revenue > tc.prev_month_revenue;


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)

SELECT e.employee_name, COUNT(s.sale_id) AS total_sales
FROM FACT_Sales s
JOIN DIM_Employee e ON s.employee_key = e.employee_key
WHERE e.employee_key IN (
    SELECT employee_key
    FROM FACT_Sales
    GROUP BY employee_key
    HAVING SUM(revenue) > (
        SELECT AVG(total_revenue)
        FROM (
            SELECT SUM(revenue) AS total_revenue
            FROM FACT_Sales
            GROUP BY employee_key
        ) avg_revenue
    )
)
AND s.customer_key IN (
    SELECT customer_key
    FROM DIM_Customer
    WHERE lifetime_value > (
        SELECT AVG(lifetime_value)
        FROM DIM_Customer
    )
)
GROUP BY e.employee_name
ORDER BY total_sales DESC;


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist

SELECT 
    p.product_code,
    p.product_name,
    i.quantity_on_hand,
    i.reorder_point,
    AVG(f.quantity) AS sales_velocity_per_day
FROM FACT_Inventory i
JOIN DIM_Product p ON i.product_key = p.product_key
JOIN FACT_Sales f ON i.product_key = f.product_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE i.quantity_on_hand < i.reorder_point
    AND t.full_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.product_code, p.product_name, i.quantity_on_hand, i.reorder_point
HAVING AVG(f.quantity) > 0
ORDER BY sales_velocity_per_day DESC;


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)

SELECT 
    p.product_name,
    SUM(s.quantity) AS total_sales,
    MAX(i.quantity_on_hand) AS current_inventory
FROM FACT_Sales s
JOIN FACT_Inventory i ON s.product_key = i.product_key
JOIN DIM_Product p ON s.product_key = p.product_key
GROUP BY p.product_key, p.product_name
HAVING SUM(s.quantity) > 100 AND MAX(i.quantity_on_hand) < 50
ORDER BY total_sales DESC;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)

SELECT 
    p.product_code,
    p.product_name,
    COALESCE(SUM(s.quantity), 0) AS total_sales_quantity,
    COALESCE(MAX(i.quantity_on_hand), 0) AS current_stock,
    CASE 
        WHEN COALESCE(MAX(i.quantity_on_hand), 0) > 0 
        THEN CAST(SUM(s.quantity) AS DECIMAL(10,2)) / CAST(MAX(i.quantity_on_hand) AS DECIMAL(10,2))
        ELSE 0 
    END AS sales_to_stock_ratio,
    CASE 
        WHEN COALESCE(MAX(i.quantity_on_hand), 0) > 0 
        THEN CASE 
            WHEN CAST(SUM(s.quantity) AS DECIMAL(10,2)) / CAST(MAX(i.quantity_on_hand) AS DECIMAL(10,2)) > 0.8 
            THEN 'Critical' 
            ELSE 'Normal' 
        END
        ELSE 'No Stock Data'
    END AS product_status
FROM DIM_Product p
LEFT JOIN FACT_Sales s ON p.product_key = s.product_key
LEFT JOIN FACT_Inventory i ON p.product_key = i.product_key
GROUP BY p.product_code, p.product_name
ORDER BY sales_to_stock_ratio DESC;


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management

SELECT 
    p.category,
    c.region,
    SUM(s.revenue) AS total_revenue,
    LAG(SUM(s.revenue)) OVER (PARTITION BY p.category, c.region ORDER BY t.year) AS prev_year_revenue,
    ROUND((SUM(s.revenue) - LAG(SUM(s.revenue)) OVER (PARTITION BY p.category, c.region ORDER BY t.year)) 
          / NULLIF(LAG(SUM(s.revenue)) OVER (PARTITION BY p.category, c.region ORDER BY t.year), 0) * 100, 2) AS revenue_growth_pct,
    ROUND(SUM(s.revenue) * 100.0 / SUM(SUM(s.revenue)) OVER (PARTITION BY p.category), 2) AS market_share_pct,
    AVG(p.margin_percent) AS avg_margin_percent
FROM FACT_Sales s
JOIN DIM_Product p ON s.product_key = p.product_key
JOIN DIM_Customer c ON s.customer_key = c.customer_key
JOIN DIM_Time t ON s.time_key = t.time_key
GROUP BY ROLLUP(p.category, c.region)
ORDER BY p.category, c.region;


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)
!!! TIMEOUT !!!

-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category

SELECT 
    c.channel_name,
    p.category,
    SUM(f.profit) AS total_profit,
    SUM(f.revenue) AS total_revenue,
    SUM(f.cost) AS total_cost,
    CASE 
        WHEN SUM(f.revenue) > 0 THEN (SUM(f.revenue) - SUM(f.cost)) / SUM(f.revenue)
        ELSE 0
    END AS channel_efficiency,
    COUNT(*) AS transaction_count
FROM FACT_Sales f
JOIN DIM_Channel c ON f.channel_key = c.channel_key
JOIN DIM_Product p ON f.product_key = p.product_key
GROUP BY ROLLUP(c.channel_name, p.category)
ORDER BY total_profit DESC;


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
