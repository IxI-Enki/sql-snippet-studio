-- ============================================================================
-- EXAMPLE: Time series - LAG/LEAD and moving averages
-- ============================================================================
-- Domain: Sales trends and stock analysis
-- Level: Intermediate
-- Focus: Navigation functions, running totals, moving averages
-- Validated with model: qwen3-coder-30b-a3b-instruct
-- ============================================================================
-- ============================================================================
-- SCHEMA: Time Series Sales Data
-- ============================================================================

CREATE TABLE DIM_Product (
    product_key SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    launch_date DATE
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
    fiscal_quarter INT
);

CREATE TABLE FACT_Daily_Sales (
    sale_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    product_key INT REFERENCES DIM_Product(product_key),
    daily_revenue DECIMAL(12,2),
    daily_quantity INT,
    daily_orders INT
);

-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 1: Zeige den täglichen Umsatz pro Produkt mit dem Umsatz des Vortages (verwende LAG)


-- Task 2: Berechne die prozentuale Veränderung des Umsatzes zum Vortag für jedes Produkt


-- Task 3: Vergleiche den Umsatz jedes Monats mit dem Vorjahresmonat (Same Month Last Year) verwende LAG mit Offset 12


-- Task 4: Zeige den Umsatz mit dem Umsatz von vor 7 Tagen und in 7 Tagen (verwende LAG und LEAD)


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 5: Berechne den kumulativen Umsatz (Running Total) pro Produkt über das Jahr 2024


-- Task 6: Berechne den Running Total des Umsatzes pro Monat innerhalb jedes Quartals


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 7: Berechne den 7-Tage Moving Average des Umsatzes für jedes Produkt


-- Task 8: Berechne den 30-Tage Moving Average mit Zentrierung (15 Tage vor und nach dem aktuellen Tag)


-- Task 9: Berechne die Differenz zwischen dem aktuellen Umsatz und dem 7-Tage Moving Average (Abweichung vom Durchschnitt)


-- ============================================================================
-- TASKS
-- ============================================================================

-- Task 10: Identifiziere Tage an denen der Umsatz mehr als 20 Prozent über dem 7-Tage Moving Average liegt


-- Task 11: Berechne den gleitenden Durchschnitt der Bestellanzahl über die letzten 14 Tage


-- Task 12: Erstelle eine Zeitreihe die für jeden Tag den Min, Max und Avg Umsatz der letzten 30 Tage zeigt


