-- ============================================================================
-- TEST 10: MIXED SCENARIO - ALL TOPICS COMBINED (EXPERT LEVEL)
-- ============================================================================
-- Domain: Multi-Domain (Kombination aller Themen)
-- Complexity: 🔴🔴🔴 EXPERT
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
-- ✅ KORREKT (Perfekte Star-Schema Query mit allen 4 Dimension-JOINs!)

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
-- ❌ FEHLER: r.region ist nicht definiert! Variable r existiert nicht (sollte c.region sein)!

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

-- KORREKTUR:
-- SELECT 
--     p.category,
--     c.segment,
--     c.region,
--     c.country,
--     SUM(f.profit) AS total_profit,
--     COUNT(*) AS product_count,
--     AVG(f.revenue) AS average_revenue,
--     AVG(f.profit / f.revenue * 100) AS profit_margin
-- FROM 
--     DIM_Product p
-- JOIN 
--     FACT_Sales f ON p.product_key = f.product_key
-- JOIN 
--     DIM_Customer c ON f.customer_key = c.customer_key
-- GROUP BY 
--     p.category, c.segment, c.region, c.country;


-- ============================================================================
-- TEST TASKS - WINDOW FUNCTIONS (ADVANCED)
-- ============================================================================

-- Aufgabe 3: Ranke Produkte nach Umsatz innerhalb jeder Kategorie und zeige nur die Top 5 pro Kategorie (verwende DENSE_RANK mit CTE)
-- ✅ KORREKT (Perfekte CTE + DENSE_RANK + WHERE Filter!)

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
-- ❌ FEHLER: Nutzt SUM() OVER als Window Function, aber dann GROUP BY - das ist widersprüchlich! Percent_of_total Formel ist falsch!

SELECT c.customer_id, c.customer_name, SUM(f.net_revenue) OVER (PARTITION BY c.region) AS total_region_revenue,
       SUM(f.net_revenue) OVER () * 100 / COUNT(*) OVER () AS percent_of_total
FROM DIM_Customer c
JOIN FACT_Sales f ON c.customer_key = f.customer_key
GROUP BY c.customer_id, c.customer_name, c.region;
;

-- KORREKTUR:
-- WITH CustomerRevenue AS (
--     SELECT 
--         c.customer_id, 
--         c.customer_name, 
--         c.region,
--         SUM(f.net_revenue) AS customer_revenue
--     FROM DIM_Customer c
--     JOIN FACT_Sales f ON c.customer_key = f.customer_key
--     GROUP BY c.customer_id, c.customer_name, c.region
-- )
-- SELECT 
--     customer_id, 
--     customer_name, 
--     region,
--     customer_revenue,
--     SUM(customer_revenue) OVER (PARTITION BY region) AS total_region_revenue,
--     ROUND(100.0 * customer_revenue / SUM(customer_revenue) OVER (PARTITION BY region), 2) AS percent_of_region
-- FROM CustomerRevenue;


-- Aufgabe 5: Identifiziere Produkte deren Umsatz in den letzten 3 Monaten um mehr als 20 Prozent gesunken ist (verwende LAG und Moving Average)
-- ⚠️ TEILWEISE: WHERE mit LAG in nicht-CTE ist problematisch. Logik ist korrekt, aber sollte CTE nutzen!

SELECT p.product_code FROM DIM_Product p JOIN FACT_Sales fs ON p.product_key = fs.product_key WHERE fs.time_key IN (SELECT time_key FROM DIM_Time WHERE full_date >= CURRENT_DATE - INTERVAL '3 MONTH') AND fs.revenue < LAG(fs.revenue, 1) OVER (PARTITION BY p.product_code ORDER BY fs.time_key) * 0.8;

-- BESSERE LÖSUNG:
-- WITH MonthlySales AS (
--     SELECT 
--         p.product_code,
--         t.month,
--         SUM(fs.revenue) AS monthly_revenue,
--         LAG(SUM(fs.revenue)) OVER (PARTITION BY p.product_code ORDER BY t.month) AS prev_month_revenue
--     FROM DIM_Product p 
--     JOIN FACT_Sales fs ON p.product_key = fs.product_key
--     JOIN DIM_Time t ON fs.time_key = t.time_key
--     WHERE t.full_date >= CURRENT_DATE - INTERVAL '3 months'
--     GROUP BY p.product_code, t.month
-- )
-- SELECT DISTINCT product_code
-- FROM MonthlySales
-- WHERE prev_month_revenue IS NOT NULL 
--   AND monthly_revenue < prev_month_revenue * 0.8;


-- Aufgabe 6: Berechne den kumulativen Umsatz pro Mitarbeiter über das Jahr mit Vergleich zum Vormonat (Running Total + LAG)
-- ❌ FEHLER: LAG(SUM(...)) ist ungültig! LAG funktioniert nicht mit aggregierten Window Functions! Braucht CTE!

SELECT e.employee_name, SUM(f.revenue) OVER (PARTITION BY e.employee_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) - 
LAG(SUM(f.revenue), 1, 0) OVER (PARTITION BY e.employee_key ORDER BY f.time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
FROM DIM_Employee e
JOIN FACT_Sales f ON e.employee_key = f.employee_key
GROUP BY e.employee_name, f.time_key;

-- KORREKTUR mit CTE:
-- WITH MonthlySales AS (
--     SELECT 
--         e.employee_name,
--         e.employee_key,
--         t.month,
--         SUM(f.revenue) AS monthly_revenue
--     FROM DIM_Employee e
--     JOIN FACT_Sales f ON e.employee_key = f.employee_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY e.employee_name, e.employee_key, t.month
-- ),
-- RunningTotal AS (
--     SELECT 
--         employee_name,
--         month,
--         monthly_revenue,
--         SUM(monthly_revenue) OVER (PARTITION BY employee_key ORDER BY month ROWS UNBOUNDED PRECEDING) AS cumulative_revenue,
--         LAG(SUM(monthly_revenue) OVER (PARTITION BY employee_key ORDER BY month ROWS UNBOUNDED PRECEDING)) OVER (PARTITION BY employee_key ORDER BY month) AS prev_month_cumulative
--     FROM MonthlySales
-- )
-- SELECT 
--     employee_name, 
--     month, 
--     cumulative_revenue, 
--     cumulative_revenue - COALESCE(prev_month_cumulative, 0) AS month_over_month_change
-- FROM RunningTotal;


-- ============================================================================
-- TEST TASKS - MERGE & ETL
-- ============================================================================

-- Aufgabe 7: Erstelle einen kompletten ETL-Prozess mit MERGE der neue Sales aus STG_Sales_Updates lädt, dabei die Dimension-Keys auflöst, und alle Änderungen in ETL_Log protokolliert
-- ❌ FEHLER: KOMPLETT ZERBROCHEN!
-- 1. SELECT ohne MERGE INTO!
-- 2. Unvollständige CTE (fehlt WITH keyword)!
-- 3. ON fs.sale_id = stg.sale_date ist Type-Mismatch (ID vs DATE)!
-- 4. INSERT VALUES Spalten sind falsch (nutzt business keys statt surrogate keys)!
-- 5. net_revenue und profit existieren NICHT in STG_Sales_Updates!
-- 6. ETL_Log Subquery ist falsch (sale_id IN sale_date ist Type-Mismatch)!
-- 7. COMMIT ohne Transaction (nicht notwendig in normalem Script)!

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

-- KORREKTUR (PostgreSQL 15+):
-- -- Step 1: MERGE Statement
-- WITH StagingWithKeys AS (
--     SELECT 
--         s.sale_date,
--         (SELECT time_key FROM DIM_Time WHERE full_date = s.sale_date) AS time_key,
--         c.customer_key,
--         p.product_key,
--         ch.channel_key,
--         e.employee_key,
--         s.quantity,
--         s.revenue,
--         s.cost,
--         s.discount,
--         s.revenue - s.discount AS net_revenue,
--         (s.revenue - s.discount) - s.cost AS profit
--     FROM STG_Sales_Updates s
--     JOIN DIM_Customer c ON s.customer_id = c.customer_id
--     JOIN DIM_Product p ON s.product_code = p.product_code
--     JOIN DIM_Channel ch ON s.channel_name = ch.channel_name
--     JOIN DIM_Employee e ON s.employee_id = e.employee_id
-- )
-- MERGE INTO FACT_Sales fs
-- USING StagingWithKeys stg
-- ON fs.time_key = stg.time_key 
--    AND fs.customer_key = stg.customer_key 
--    AND fs.product_key = stg.product_key
-- WHEN MATCHED THEN 
--     UPDATE SET 
--         quantity = fs.quantity + stg.quantity,
--         revenue = fs.revenue + stg.revenue,
--         cost = fs.cost + stg.cost,
--         discount = fs.discount + stg.discount,
--         net_revenue = fs.net_revenue + stg.net_revenue,
--         profit = fs.profit + stg.profit
-- WHEN NOT MATCHED THEN 
--     INSERT (time_key, customer_key, product_key, channel_key, employee_key, quantity, revenue, cost, discount, net_revenue, profit)
--     VALUES (stg.time_key, stg.customer_key, stg.product_key, stg.channel_key, stg.employee_key, stg.quantity, stg.revenue, stg.cost, stg.discount, stg.net_revenue, stg.profit);
-- 
-- -- Step 2: Log Results
-- INSERT INTO ETL_Log (table_name, rows_inserted, rows_updated, status)
-- VALUES ('FACT_Sales', (SELECT COUNT(*) FROM STG_Sales_Updates), 0, 'SUCCESS');


-- Aufgabe 8: Implementiere einen MERGE Statement der Produkte deaktiviert die in den letzten 6 Monaten keine Verkäufe hatten (UPDATE ein is_active Flag)
-- ❌ FEHLER: KOMPLETT ZERBROCHEN!
-- 1. Unvollständige Query (fehlt MERGE INTO und ON Clause Start)!
-- 2. full_date ist in FACT_Sales nicht vorhanden (muss JOIN DIM_Time)!
-- 3. is_active Column existiert NICHT in DIM_Product Schema!
-- 4. Logik ist invertiert (WHEN NOT MATCHED sollte inactive setzen)!

SELECT product_code FROM FACT_Sales WHERE full_date >= CURRENT_DATE - INTERVAL '6 MONTH'
) s ON p.product_code = s.product_code 
WHEN NOT MATCHED THEN UPDATE SET is_active = FALSE;

-- KORREKTUR (DIM_Product müsste is_active Column haben):
-- -- Annahme: DIM_Product hat is_active BOOLEAN column
-- WITH RecentProducts AS (
--     SELECT DISTINCT p.product_code
--     FROM FACT_Sales fs
--     JOIN DIM_Product p ON fs.product_key = p.product_key
--     JOIN DIM_Time t ON fs.time_key = t.time_key
--     WHERE t.full_date >= CURRENT_DATE - INTERVAL '6 months'
-- )
-- UPDATE DIM_Product p
-- SET is_active = CASE 
--     WHEN EXISTS (SELECT 1 FROM RecentProducts rp WHERE rp.product_code = p.product_code) 
--     THEN TRUE 
--     ELSE FALSE 
-- END;


-- ============================================================================
-- TEST TASKS - ROLLUP & HIERARCHICAL ANALYSIS
-- ============================================================================

-- Aufgabe 9: Erstelle einen Management Report mit Umsatz und Profit nach Region, Land, Kundensegment und Kanal mit allen Subtotals (ROLLUP mit GROUPING Funktion)
-- ❌ FEHLER: MySQL Syntax (WITH ROLLUP) statt PostgreSQL (ROLLUP(...))! Fehlt GROUPING Funktion!

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

-- KORREKTUR:
-- SELECT 
--     dcu.region,
--     dcu.country,
--     dcu.segment,
--     dc.channel_name,
--     SUM(fs.revenue) AS total_revenue,
--     SUM(fs.profit) AS total_profit,
--     GROUPING(dcu.region) AS is_region_total,
--     GROUPING(dcu.country) AS is_country_total,
--     GROUPING(dcu.segment) AS is_segment_total,
--     GROUPING(dc.channel_name) AS is_channel_total
-- FROM 
--     FACT_Sales fs
-- JOIN 
--     DIM_Channel dc ON fs.channel_key = dc.channel_key
-- JOIN 
--     DIM_Customer dcu ON fs.customer_key = dcu.customer_key
-- GROUP BY 
--     ROLLUP(dcu.region, dcu.country, dcu.segment, dc.channel_name)
-- ORDER BY 
--     dcu.region, dcu.country, dcu.segment, dc.channel_name;


-- Aufgabe 10: Berechne die Verkaufszahlen mit hierarchischen Subtotals nach Fiscal Year, Fiscal Quarter, Month (ROLLUP)
-- ❌ FEHLER: fiscal_year, fiscal_quarter, month sind NICHT in FACT_Sales! Fehlt JOIN zu DIM_Time!

SELECT 
    fiscal_year,
    fiscal_quarter,
    month,
    SUM(revenue) AS total_revenue
FROM 
    FACT_Sales
GROUP BY 
    ROLLUP(fiscal_year, fiscal_quarter, month);

-- KORREKTUR:
-- SELECT 
--     t.fiscal_year,
--     t.fiscal_quarter,
--     t.month,
--     SUM(fs.revenue) AS total_revenue
-- FROM 
--     FACT_Sales fs
-- JOIN
--     DIM_Time t ON fs.time_key = t.time_key
-- GROUP BY 
--     ROLLUP(t.fiscal_year, t.fiscal_quarter, t.month)
-- ORDER BY 
--     t.fiscal_year, t.fiscal_quarter, t.month;


-- ============================================================================
-- TEST TASKS - COMPLEX ANALYTICS (CTEs + Subqueries)
-- ============================================================================

-- Aufgabe 11: Finde profitable Produkte deren Umsatztrend positiv ist: (1) CTE für Produkt-Umsatz pro Monat (2) CTE für Trendberechnung (LAG) (3) Hauptquery filtert profitable Produkte mit positivem Trend
-- ⚠️ TEILWEISE: CTEs sind korrekt! ABER: WHERE Subquery fehlt closing parenthesis! WHERE p.margin_percent > 0.1 sollte ) haben!

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

-- KORREKTUR (missing closing parenthesis):
-- ... (identisch, aber mit schließender Klammer nach 0.1)


-- Aufgabe 12: Identifiziere Top-Performer Mitarbeiter die überdurchschnittlich verkaufen und deren Kunden eine überdurchschnittliche Lifetime Value haben (mehrere Subqueries)
-- ⚠️ TEILWEISE: Funktioniert grundsätzlich, ABER sehr unübersichtlich und ineffizient (nested Subqueries). Außerdem: zweite Subquery ist incomplete (fehlt Alias).

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

-- KORREKTUR (bessere Lesbarkeit mit CTEs):
-- WITH EmployeeSales AS (
--     SELECT employee_key, SUM(net_revenue) AS total_sales 
--     FROM FACT_Sales 
--     GROUP BY employee_key
-- ),
-- AvgSales AS (
--     SELECT AVG(total_sales) AS avg_sales FROM EmployeeSales
-- ),
-- EmployeeCustomerValue AS (
--     SELECT 
--         fs.employee_key,
--         AVG(c.lifetime_value) AS avg_customer_ltv
--     FROM DIM_Customer c 
--     JOIN FACT_Sales fs ON c.customer_key = fs.customer_key 
--     GROUP BY fs.employee_key
-- ),
-- AvgCustomerValue AS (
--     SELECT AVG(lifetime_value) AS avg_ltv FROM DIM_Customer
-- )
-- SELECT e.employee_name
-- FROM DIM_Employee e
-- JOIN EmployeeSales es ON e.employee_key = es.employee_key
-- JOIN EmployeeCustomerValue ecv ON e.employee_key = ecv.employee_key
-- CROSS JOIN AvgSales
-- CROSS JOIN AvgCustomerValue
-- WHERE es.total_sales > AvgSales.avg_sales
--   AND ecv.avg_customer_ltv > AvgCustomerValue.avg_ltv;


-- Aufgabe 13: Erstelle einen Inventory Alert Report der Produkte zeigt die unter ihrem Reorder Point liegen und deren Sales Velocity (durchschnittliche Verkäufe pro Tag der letzten 30 Tage) hoch ist
-- ⚠️ TEILWEISE: Sales Velocity Formel ist falsch (revenue / quantity ergibt Preis, nicht Velocity)! Sonst gut!

SELECT p.product_name, i.quantity_on_hand, AVG(f.revenue / f.quantity) AS sales_velocity 
FROM DIM_Product p 
JOIN FACT_Inventory i ON p.product_key = i.product_key 
JOIN FACT_Sales f ON p.product_key = f.product_key AND f.time_key IN (SELECT time_key FROM DIM_Time WHERE full_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE) 
WHERE i.quantity_on_hand < i.reorder_point 
GROUP BY p.product_name, i.quantity_on_hand 
ORDER BY sales_velocity DESC;

-- KORREKTUR (Sales Velocity = Verkäufe pro Tag):
-- SELECT 
--     p.product_name, 
--     i.quantity_on_hand,
--     i.reorder_point,
--     SUM(f.quantity) AS total_quantity_sold,
--     SUM(f.quantity) / 30.0 AS sales_velocity_per_day
-- FROM DIM_Product p 
-- JOIN FACT_Inventory i ON p.product_key = i.product_key 
-- JOIN FACT_Sales f ON p.product_key = f.product_key 
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- WHERE t.full_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
--   AND i.quantity_on_hand < i.reorder_point 
-- GROUP BY p.product_name, i.quantity_on_hand, i.reorder_point
-- ORDER BY sales_velocity_per_day DESC;


-- ============================================================================
-- TEST TASKS - MULTI-FACT ANALYSIS
-- ============================================================================

-- Aufgabe 14: Kombiniere FACT_Sales und FACT_Inventory um Produkte zu identifizieren die hohe Verkäufe haben aber niedrigen Lagerbestand (Join über DIM_Product)
-- ⚠️ TEILWEISE: Funktioniert, ABER sollte SUM(fs.revenue) nutzen statt fs.revenue direkt! Sonst zeigt es alle Einzelverkäufe > 1000.

SELECT p.product_name FROM DIM_Product p JOIN FACT_Sales fs ON p.product_key = fs.product_key JOIN FACT_Inventory fi ON p.product_key = fi.product_key WHERE fs.revenue > 1000 AND fi.quantity_on_hand < 50;

-- BESSERE LÖSUNG:
-- SELECT DISTINCT p.product_name, SUM(fs.revenue) AS total_revenue, MIN(fi.quantity_on_hand) AS min_stock
-- FROM DIM_Product p 
-- JOIN FACT_Sales fs ON p.product_key = fs.product_key 
-- JOIN FACT_Inventory fi ON p.product_key = fi.product_key 
-- GROUP BY p.product_name
-- HAVING SUM(fs.revenue) > 1000 AND MIN(fi.quantity_on_hand) < 50;


-- Aufgabe 15: Berechne das Sales-to-Stock Ratio (Verkaufsmenge / Lagerbestand) pro Produkt und identifiziere kritische Produkte (Ratio > 0.8)
-- ❌ FEHLER: Multiple Probleme!
-- 1. SUM(s.quantity) * s.revenue ist falsch (sollte nur SUM(s.quantity) sein)!
-- 2. sale_date BETWEEN time_key AND time_key + 1 month ist Type-Mismatch (DATE vs INT)!
-- 3. HAVING sales_to_stock_ratio ist Alias (muss Formel wiederholt werden oder CTE)!

SELECT p.product_name, f.inventory_id, SUM(f.quantity_on_hand) AS total_stock, SUM(s.quantity) * s.revenue AS sales_amount,
       (SUM(s.quantity) * s.revenue) / SUM(f.quantity_on_hand) AS sales_to_stock_ratio
FROM DIM_Product p
JOIN FACT_Inventory f ON p.product_key = f.product_key
JOIN STG_Sales_Updates s ON p.product_code = s.product_code AND s.sale_date BETWEEN f.time_key AND (f.time_key + INTERVAL '1 month')
GROUP BY p.product_name, f.inventory_id
HAVING sales_to_stock_ratio > 0.8;

-- KORREKTUR:
-- WITH SalesVsStock AS (
--     SELECT 
--         p.product_name,
--         SUM(fs.quantity) AS total_quantity_sold,
--         AVG(fi.quantity_on_hand) AS avg_stock
--     FROM DIM_Product p
--     JOIN FACT_Sales fs ON p.product_key = fs.product_key
--     JOIN FACT_Inventory fi ON p.product_key = fi.product_key
--     GROUP BY p.product_name
-- )
-- SELECT 
--     product_name,
--     total_quantity_sold,
--     avg_stock,
--     total_quantity_sold / NULLIF(avg_stock, 0) AS sales_to_stock_ratio
-- FROM SalesVsStock
-- WHERE total_quantity_sold / NULLIF(avg_stock, 0) > 0.8
-- ORDER BY sales_to_stock_ratio DESC;


-- ============================================================================
-- TEST TASKS - REAL-WORLD SCENARIO
-- ============================================================================

-- Aufgabe 16: BUSINESS QUESTION: "Welche Produktkategorien sollten wir in welchen Regionen ausbauen?" Analysiere: (1) Umsatzwachstum pro Kategorie und Region (LAG) (2) Marktanteil pro Region (Window Functions) (3) Profitabilität (Margins) (4) Präsentiere Ergebnis mit ROLLUP für Management
-- ❌ FEHLER: WITH ROLLUP ist MySQL Syntax! Fehlen Window Functions für Marktanteil! LAG ist falsch (sollte über Zeit, nicht über Region)!

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

-- KORREKTUR (PostgreSQL + vollständige Analyse):
-- WITH CategoryRegionSales AS (
--     SELECT 
--         p.category,
--         c.region,
--         t.year,
--         t.quarter,
--         SUM(f.net_revenue) AS revenue,
--         SUM(f.profit) AS profit,
--         COUNT(DISTINCT f.sale_id) AS sales_count
--     FROM DIM_Customer c
--     JOIN FACT_Sales f ON c.customer_key = f.customer_key
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY p.category, c.region, t.year, t.quarter
-- ),
-- TrendAnalysis AS (
--     SELECT 
--         category,
--         region,
--         year,
--         quarter,
--         revenue,
--         profit,
--         LAG(revenue) OVER (PARTITION BY category, region ORDER BY year, quarter) AS prev_quarter_revenue,
--         SUM(revenue) OVER (PARTITION BY region, year, quarter) AS total_region_revenue
--     FROM CategoryRegionSales
-- )
-- SELECT 
--     category,
--     region,
--     SUM(revenue) AS total_revenue,
--     SUM(profit) AS total_profit,
--     ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (PARTITION BY region), 2) AS market_share_percent,
--     AVG((revenue - COALESCE(prev_quarter_revenue, 0)) / NULLIF(prev_quarter_revenue, 1)) AS avg_growth_rate
-- FROM TrendAnalysis
-- GROUP BY ROLLUP(region, category)
-- ORDER BY region, category;


-- Aufgabe 17: BUSINESS QUESTION: "Identifiziere unsere profitabelsten Kunden und deren Kaufmuster" Erstelle: (1) Customer Profitability Analysis (2) RFM Segmentation (Recency, Frequency, Monetary) mit NTILE (3) Product Affinity Analysis (welche Produkte kaufen profitable Kunden zusammen)
-- ❌ FEHLER: Mehrere separate Queries statt integrierte Analyse! 
-- Query 1: OK
-- Query 2 (RFM): MAX(time_key) OVER als Recency ist falsch (sollte DATEDIFF sein)! Fehlt GROUP BY!
-- Query 3 (Affinity): pa.customer_key = p2.customer_key ist falsch (sollte pa.product_key JOIN)!

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

-- KORREKTUREN:
-- (Zu umfangreich, aber alle 3 Queries haben signifikante Fehler)


-- Aufgabe 18: BUSINESS QUESTION: "Optimiere Channel Mix für maximalen Profit" Analysiere: (1) Profit pro Channel und Produkt (2) Channel Efficiency (Kosten vs Umsatz) (3) Trend Analysis (sind Channels profitabler geworden?) (4) Empfehlung basierend auf ROLLUP nach Channel, Product Category
-- ❌ FEHLER: ROLLUP(c.channel_name, p.category) in SELECT statt GROUP BY! profit_trend Logik ist zu simpel (fehlt Zeitvergleich)!

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

-- KORREKTUR:
-- WITH ChannelPerformance AS (
--     SELECT 
--         c.channel_name,
--         p.category,
--         t.year,
--         t.quarter,
--         SUM(f.profit) AS profit,
--         SUM(f.cost) AS cost,
--         SUM(f.revenue) AS revenue
--     FROM DIM_Channel c
--     JOIN FACT_Sales f ON c.channel_key = f.channel_key
--     JOIN DIM_Product p ON f.product_key = p.product_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY c.channel_name, p.category, t.year, t.quarter
-- ),
-- TrendAnalysis AS (
--     SELECT 
--         channel_name,
--         category,
--         year,
--         quarter,
--         profit,
--         revenue,
--         cost,
--         LAG(profit) OVER (PARTITION BY channel_name, category ORDER BY year, quarter) AS prev_quarter_profit
--     FROM ChannelPerformance
-- )
-- SELECT 
--     channel_name,
--     category,
--     SUM(profit) AS total_profit,
--     ROUND(AVG(cost / NULLIF(revenue, 0)), 4) AS avg_cost_efficiency,
--     AVG((profit - COALESCE(prev_quarter_profit, 0)) / NULLIF(ABS(prev_quarter_profit), 1)) AS avg_profit_growth
-- FROM TrendAnalysis
-- GROUP BY ROLLUP(channel_name, category)
-- ORDER BY channel_name, category;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 16.7/100
-- SUCCESS RATE: 2/18 (11.1%)

-- BREAKDOWN:
-- ✅ Korrekt:  2 (Tasks 1, 3)
-- ⚠️ Teilweise: 5 (Tasks 5, 11, 12, 13, 14)
-- ❌ Fehler:   11 (Tasks 2, 4, 6, 7, 8, 9, 10, 15, 16, 17, 18)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Star-Schema JOINs korrekt (Task 1)
-- + CTEs + DENSE_RANK korrekt (Task 3)
-- + Grundverständnis von Subqueries (Task 12)

-- WEAKNESSES:
-- - MERGE Statements KOMPLETT KAPUTT (Tasks 7, 8 - 0% Success!)
-- - ROLLUP Syntax falsch (WITH ROLLUP ist MySQL, nicht PostgreSQL)
-- - Fehlende JOINs (Tasks 2, 9, 10, 18)
-- - Window Function Missverständnisse (Tasks 4, 6 - LAG über Aggregate)
-- - Business Logic Fehler (Tasks 13, 15, 16, 17, 18 - falsche Formeln)
-- - Incomplete Queries (Tasks 7, 8 - fehlen Schlüsselkomponenten)
-- - Type Mismatches (Task 15 - DATE vs INT)

-- CRITICAL ERRORS:
-- - Tasks 7, 8: MERGE Syntax komplett zerstört! (Unvollständige Statements, fehlende CTEs, Type Mismatches)
-- - Task 2: Variable r.region existiert nicht!
-- - Task 6: LAG(SUM(...)) ist syntaktisch ungültig!
-- - Task 9, 10: WITH ROLLUP (MySQL) statt ROLLUP(...) (PostgreSQL)!
-- - Task 15: Type Mismatch (DATE BETWEEN INT)!
-- - Task 16, 18: ROLLUP im SELECT statt GROUP BY!
-- - Task 17: Mehrere Logikfehler in RFM + Affinity Analysis!

-- RECOMMENDATION:
-- ❌ ABSOLUT NICHT PRODUCTION-READY!
-- Das 7B Model scheitert bei Expert-Level Tasks dramatisch:
-- - MERGE: 0% Success (beide Tasks komplett falsch)
-- - ROLLUP: 0% Success (falsche Syntax in allen 4 Tasks)
-- - Business Logic: 0% Success (alle Real-World Scenarios fehlerhaft)
-- - Complex Queries: 11.1% Success
-- 
-- Nur 11.1% Success Rate bei Expert-Aufgaben ist INAKZEPTABEL!
-- Das Model versteht grundlegende Konzepte, aber versagt bei:
-- - Multi-Step ETL Prozessen
-- - Complex Window Function Combinations
-- - Real-World Business Analysis
-- 
-- ⚠️ DRINGEND EMPFOHLEN: Größeres Model verwenden (32B+) oder Fine-Tuning!

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
