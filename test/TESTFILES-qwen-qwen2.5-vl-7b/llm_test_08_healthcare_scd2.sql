-- ============================================================================
-- TEST 8: HEALTHCARE - SCD TYPE 2 + TEMPORAL QUERIES + MERGE
-- ============================================================================
-- Domain: Healthcare / Medical Records
-- Complexity: 🔴🔴 Expert Level
-- Focus: Slowly Changing Dimensions Type 2, Temporal Queries, MERGE Operations
-- Test Coverage: Historical Data Tracking, Point-in-Time Analysis, Versioning
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

-- ============================================================================
-- SCHEMA: Healthcare SCD Type 2
-- ============================================================================

-- SCD Type 2: Patient Dimension (tracks historical changes)
CREATE TABLE DIM_Patient_SCD2 (
    patient_dim_key SERIAL PRIMARY KEY,
    patient_id VARCHAR(50),              -- Business Key (nicht unique!)
    patient_name VARCHAR(100),
    date_of_birth DATE,
    address VARCHAR(200),
    insurance_type VARCHAR(50),
    chronic_conditions TEXT,
    -- SCD Type 2 Metadata
    valid_from DATE NOT NULL,
    valid_to DATE,                       -- NULL = current version
    is_current BOOLEAN DEFAULT TRUE,
    version_number INT
);

-- SCD Type 2: Doctor Dimension (tracks specialty and department changes)
CREATE TABLE DIM_Doctor_SCD2 (
    doctor_dim_key SERIAL PRIMARY KEY,
    doctor_id VARCHAR(50),               -- Business Key
    doctor_name VARCHAR(100),
    specialty VARCHAR(100),
    department VARCHAR(100),
    certification_level VARCHAR(50),
    -- SCD Type 2 Metadata
    valid_from DATE NOT NULL,
    valid_to DATE,
    is_current BOOLEAN DEFAULT TRUE,
    version_number INT
);

-- Regular Dimensions
CREATE TABLE DIM_Hospital (
    hospital_key SERIAL PRIMARY KEY,
    hospital_name VARCHAR(200),
    hospital_type VARCHAR(50),
    city VARCHAR(100),
    bed_capacity INT
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_of_week INT
);

-- Fact Table: Hospital Visits (references SCD2 via valid_from/valid_to matching)
CREATE TABLE FACT_Hospital_Visit (
    visit_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    patient_dim_key INT REFERENCES DIM_Patient_SCD2(patient_dim_key),
    doctor_dim_key INT REFERENCES DIM_Doctor_SCD2(doctor_dim_key),
    hospital_key INT REFERENCES DIM_Hospital(hospital_key),
    diagnosis_code VARCHAR(20),
    treatment_type VARCHAR(100),
    visit_duration_hours DECIMAL(5,2),
    total_cost DECIMAL(10,2),
    is_emergency BOOLEAN
);

-- ============================================================================
-- TEST TASKS - SCD TYPE 2 QUERIES
-- ============================================================================

-- Aufgabe 1: Zeige alle aktuellen Patienten (is_current = TRUE) mit ihrer Versionshistorie
-- ⚠️ TEILWEISE: WHERE is_current = TRUE filtert NUR aktuelle Versionen! Die Aufgabe will aber Versionshistorie auch zeigen.

SELECT patient_id, patient_name, address, insurance_type, version_number, valid_from, valid_to 
FROM DIM_Patient_SCD2 
WHERE is_current = TRUE 
ORDER BY patient_id, version_number;

-- BESSERE INTERPRETATION:
-- SELECT patient_id, patient_name, address, insurance_type, version_number, valid_from, valid_to, is_current
-- FROM DIM_Patient_SCD2 
-- ORDER BY patient_id, version_number;
-- ODER wenn NUR aktuelle mit ihrer Historie gemeint ist:
-- WITH CurrentPatients AS (
--     SELECT DISTINCT patient_id FROM DIM_Patient_SCD2 WHERE is_current = TRUE
-- )
-- SELECT p.*
-- FROM DIM_Patient_SCD2 p
-- JOIN CurrentPatients cp ON p.patient_id = cp.patient_id
-- ORDER BY p.patient_id, p.version_number;


-- Aufgabe 2: Finde alle Patienten die ihre Versicherung gewechselt haben (mindestens 2 Versionen mit unterschiedlicher insurance_type)
-- ❌ FEHLER: WHERE filtert nur is_current = TRUE, aber benötigt ALLE Versionen! COUNT(*) >= 2 ist zu einfach (braucht DISTINCT insurance_type)!

SELECT patient_id, COUNT(*) AS version_count 
FROM DIM_Patient_SCD2 
WHERE is_current = TRUE 
GROUP BY patient_id 
HAVING COUNT(*) >= 2;

-- KORREKTUR:
-- SELECT patient_id, COUNT(DISTINCT insurance_type) AS insurance_changes
-- FROM DIM_Patient_SCD2 
-- GROUP BY patient_id 
-- HAVING COUNT(DISTINCT insurance_type) >= 2
-- ORDER BY insurance_changes DESC;


-- Aufgabe 3: Point-in-Time Query: Zeige die Patientendaten so wie sie am 2023-06-15 gültig waren (Temporal Query)
-- ✅ KORREKT (Perfekte Point-in-Time Query!)

SELECT patient_id, patient_name, address, insurance_type, chronic_conditions 
FROM DIM_Patient_SCD2 
WHERE '2023-06-15' BETWEEN valid_from AND COALESCE(valid_to, '9999-12-31') 
ORDER BY patient_id;


-- Aufgabe 4: Zeige für jeden Arzt alle Spezialitätswechsel (alle Versionen mit Specialty Änderungen)
-- ⚠️ TEILWEISE: Zeigt alle Versionen, aber ohne Vergleich ob specialty sich tatsächlich geändert hat! LAG könnte besser sein.

SELECT doctor_id, doctor_name, specialty, valid_from, valid_to, version_number 
FROM DIM_Doctor_SCD2 
ORDER BY doctor_id, version_number;

-- BESSERE LÖSUNG mit LAG:
-- WITH SpecialtyChanges AS (
--     SELECT 
--         doctor_id, 
--         doctor_name, 
--         specialty,
--         LAG(specialty) OVER (PARTITION BY doctor_id ORDER BY version_number) AS previous_specialty,
--         valid_from, 
--         valid_to, 
--         version_number 
--     FROM DIM_Doctor_SCD2
-- )
-- SELECT * 
-- FROM SpecialtyChanges
-- WHERE previous_specialty IS NOT NULL AND specialty <> previous_specialty
-- ORDER BY doctor_id, version_number;


-- Aufgabe 5: Finde alle Krankenhaus-Besuche und zeige die zum Zeitpunkt des Besuchs gültigen Patientendaten (SCD JOIN mit FACT)
-- ❌ FEHLER: JOIN-Bedingung ist NUR patient_dim_key! Fehlt Temporal Join (visit_date BETWEEN valid_from AND valid_to)!

SELECT v.visit_id, t.full_date, p.patient_name, p.insurance_type, p.address, v.diagnosis_code 
FROM FACT_Hospital_Visit v 
JOIN DIM_Patient_SCD2 p ON v.patient_dim_key = p.patient_dim_key 
JOIN DIM_Time t ON v.time_key = t.time_key 
ORDER BY t.full_date;

-- KORREKTUR (wenn Fact patient_dim_key nicht SCD-aware ist):
-- SELECT 
--     v.visit_id, 
--     t.full_date, 
--     p.patient_name, 
--     p.insurance_type, 
--     p.address, 
--     v.diagnosis_code 
-- FROM FACT_Hospital_Visit v 
-- JOIN DIM_Time t ON v.time_key = t.time_key 
-- JOIN DIM_Patient_SCD2 p ON v.patient_dim_key = p.patient_dim_key 
--     AND t.full_date BETWEEN p.valid_from AND COALESCE(p.valid_to, '9999-12-31')
-- ORDER BY t.full_date;


-- ============================================================================
-- TEST TASKS - TEMPORAL ANALYSIS
-- ============================================================================

-- Aufgabe 6: Berechne wie viele Tage jede Patientenversion gültig war
-- ✅ KORREKT (Perfekte Duration Calculation!)

SELECT 
    patient_id, 
    patient_name, 
    version_number,
    valid_from,
    valid_to,
    COALESCE(valid_to, CURRENT_DATE) - valid_from AS days_valid
FROM DIM_Patient_SCD2 
ORDER BY patient_id, version_number;


-- Aufgabe 7: Finde alle Ärzte die innerhalb der letzten 2 Jahre ihre Abteilung gewechselt haben
-- ⚠️ TEILWEISE: Zeigt nur is_current = TRUE (fehlt alte Versionen)! valid_from > CURRENT_DATE - 2 Jahre prüft nur START, nicht ob Wechsel in 2 Jahren.

SELECT doctor_id, doctor_name, department, valid_from, valid_to 
FROM DIM_Doctor_SCD2 
WHERE is_current = TRUE AND valid_from > CURRENT_DATE - INTERVAL '2 years' 
ORDER BY doctor_id, valid_from;

-- BESSERE LÖSUNG:
-- WITH DepartmentChanges AS (
--     SELECT 
--         doctor_id, 
--         doctor_name, 
--         department,
--         LAG(department) OVER (PARTITION BY doctor_id ORDER BY version_number) AS previous_department,
--         valid_from, 
--         valid_to, 
--         version_number 
--     FROM DIM_Doctor_SCD2
-- )
-- SELECT * 
-- FROM DepartmentChanges
-- WHERE previous_department IS NOT NULL 
--   AND department <> previous_department
--   AND valid_from > CURRENT_DATE - INTERVAL '2 years'
-- ORDER BY doctor_id, valid_from;


-- Aufgabe 8: Historische Analyse: Zeige die Verteilung der Versicherungstypen für 2020, 2021, 2022, 2023 (Point-in-Time für jedes Jahr)
-- ❌ FEHLER: Nutzt nur is_current = TRUE! Zeigt nur aktuelle Daten, nicht historische Point-in-Time für jedes Jahr!

SELECT 
    EXTRACT(YEAR FROM valid_from) AS year, 
    insurance_type, 
    COUNT(*) AS patient_count 
FROM DIM_Patient_SCD2 
WHERE is_current = TRUE 
GROUP BY year, insurance_type 
ORDER BY year, insurance_type;

-- KORREKTUR mit Point-in-Time für mehrere Jahre:
-- WITH YearDates AS (
--     SELECT generate_series AS year_date 
--     FROM generate_series('2020-12-31'::date, '2023-12-31'::date, '1 year'::interval)
-- )
-- SELECT 
--     EXTRACT(YEAR FROM yd.year_date) AS year,
--     p.insurance_type, 
--     COUNT(*) AS patient_count 
-- FROM YearDates yd
-- CROSS JOIN DIM_Patient_SCD2 p
-- WHERE yd.year_date BETWEEN p.valid_from AND COALESCE(p.valid_to, '9999-12-31')
-- GROUP BY year, p.insurance_type 
-- ORDER BY year, p.insurance_type;


-- ============================================================================
-- TEST TASKS - MERGE STATEMENTS (SCD2 MAINTENANCE)
-- ============================================================================

-- Aufgabe 9: MERGE Statement: Aktualisiere Patient-Daten und erstelle neue Version bei Änderungen (SCD2 Update Pattern)
-- Staging-Tabelle für neue/geänderte Daten:
CREATE TABLE STG_Patient (
    patient_id VARCHAR(50),
    patient_name VARCHAR(100),
    date_of_birth DATE,
    address VARCHAR(200),
    insurance_type VARCHAR(50),
    chronic_conditions TEXT,
    load_date DATE
);

-- ❌ FEHLER: MERGE Statement ist KOMPLETT FALSCH!
-- 1. WHEN MATCHED THEN INSERT ist ungültig (sollte UPDATE sein)!
-- 2. INSERT syntax mit (column) VALUES () ist fehlerhaft (fehlt column list + VALUES keyword)!
-- 3. SCD2 Logik fehlt komplett (alte Version schließen mit valid_to, neue Version mit version_number)!

MERGE INTO DIM_Patient_SCD2 AS target 
USING STG_Patient AS source 
ON target.patient_id = source.patient_id 
WHEN MATCHED THEN 
  INSERT (patient_name, address, insurance_type, valid_from) 
  VALUES (source.patient_name, source.address, source.insurance_type, source.load_date) 
WHEN NOT MATCHED THEN 
  INSERT (patient_id, patient_name, date_of_birth, address, insurance_type, chronic_conditions, valid_from, is_current, version_number) 
  VALUES (source.patient_id, source.patient_name, source.date_of_birth, source.address, source.insurance_type, source.chronic_conditions, source.load_date, TRUE, 1);

-- KORREKTUR (PostgreSQL unterstützt MERGE ab v15, sonst CTE mit INSERT/UPDATE):
-- -- Step 1: Close old versions (set valid_to and is_current = FALSE)
-- UPDATE DIM_Patient_SCD2 AS target
-- SET 
--     valid_to = source.load_date - INTERVAL '1 day',
--     is_current = FALSE
-- FROM STG_Patient AS source
-- WHERE 
--     target.patient_id = source.patient_id 
--     AND target.is_current = TRUE
--     AND (
--         target.patient_name <> source.patient_name OR
--         target.address <> source.address OR
--         target.insurance_type <> source.insurance_type OR
--         target.chronic_conditions <> source.chronic_conditions
--     );
-- 
-- -- Step 2: Insert new versions
-- INSERT INTO DIM_Patient_SCD2 (
--     patient_id, patient_name, date_of_birth, address, insurance_type, chronic_conditions, 
--     valid_from, valid_to, is_current, version_number
-- )
-- SELECT 
--     s.patient_id, 
--     s.patient_name, 
--     s.date_of_birth, 
--     s.address, 
--     s.insurance_type, 
--     s.chronic_conditions, 
--     s.load_date AS valid_from,
--     NULL AS valid_to,
--     TRUE AS is_current,
--     COALESCE(MAX(d.version_number), 0) + 1 AS version_number
-- FROM STG_Patient s
-- LEFT JOIN DIM_Patient_SCD2 d ON s.patient_id = d.patient_id
-- GROUP BY s.patient_id, s.patient_name, s.date_of_birth, s.address, s.insurance_type, s.chronic_conditions, s.load_date;


-- Aufgabe 10: MERGE Statement für Doctor Dimension: Erstelle neue Version nur wenn sich Specialty oder Department geändert haben
-- ❌ FEHLER: KOMPLETT FALSCH!
-- 1. WHEN MATCHED ... INSERT ist ungültig!
-- 2. INSERT Syntax fehlerhaft!
-- 3. WHERE Bedingung im WHEN MATCHED ist ungültig (gehört in ON oder subquery)!
-- 4. SCD2 Logik fehlt (alte Version schließen)!

CREATE TABLE STG_Doctor (
    doctor_id VARCHAR(50),
    doctor_name VARCHAR(100),
    specialty VARCHAR(100),
    department VARCHAR(100),
    certification_level VARCHAR(50),
    load_date DATE
);

MERGE INTO DIM_Doctor_SCD2 AS target 
USING STG_Doctor AS source 
ON target.doctor_id = source.doctor_id 
WHEN MATCHED AND (target.specialty <> source.specialty OR target.department <> source.department) THEN 
  INSERT (doctor_name, specialty, department, valid_from) 
  VALUES (source.doctor_name, source.specialty, source.department, source.load_date) 
WHEN NOT MATCHED THEN 
  INSERT (doctor_id, doctor_name, specialty, department, certification_level, valid_from, is_current, version_number) 
  VALUES (source.doctor_id, source.doctor_name, source.specialty, source.department, source.certification_level, source.load_date, TRUE, 1);

-- KORREKTUR (ähnlich wie Aufgabe 9):
-- -- Step 1: Close old versions if specialty or department changed
-- UPDATE DIM_Doctor_SCD2 AS target
-- SET 
--     valid_to = source.load_date - INTERVAL '1 day',
--     is_current = FALSE
-- FROM STG_Doctor AS source
-- WHERE 
--     target.doctor_id = source.doctor_id 
--     AND target.is_current = TRUE
--     AND (
--         target.specialty <> source.specialty OR
--         target.department <> source.department
--     );
-- 
-- -- Step 2: Insert new versions (only if changed)
-- INSERT INTO DIM_Doctor_SCD2 (
--     doctor_id, doctor_name, specialty, department, certification_level, 
--     valid_from, valid_to, is_current, version_number
-- )
-- SELECT 
--     s.doctor_id, 
--     s.doctor_name, 
--     s.specialty, 
--     s.department, 
--     s.certification_level, 
--     s.load_date AS valid_from,
--     NULL AS valid_to,
--     TRUE AS is_current,
--     COALESCE(MAX(d.version_number), 0) + 1 AS version_number
-- FROM STG_Doctor s
-- LEFT JOIN DIM_Doctor_SCD2 d ON s.doctor_id = d.doctor_id
-- WHERE EXISTS (
--     SELECT 1 FROM DIM_Doctor_SCD2 old
--     WHERE old.doctor_id = s.doctor_id AND old.is_current = TRUE
--     AND (old.specialty <> s.specialty OR old.department <> s.department)
-- ) OR NOT EXISTS (
--     SELECT 1 FROM DIM_Doctor_SCD2 WHERE doctor_id = s.doctor_id
-- )
-- GROUP BY s.doctor_id, s.doctor_name, s.specialty, s.department, s.certification_level, s.load_date;


-- ============================================================================
-- TEST TASKS - ADVANCED SCD2 ANALYSIS
-- ============================================================================

-- Aufgabe 11: Berechne die durchschnittliche "Lebensdauer" einer Patientenversion (Average Days per Version)
-- ⚠️ TEILWEISE: Zeigt AVG pro patient_id, aber Aufgabe will globalen AVG über ALLE Versionen! Außerdem: WHERE is_current = FALSE filtert aktuelle Versionen aus!

SELECT patient_id, AVG(COALESCE(valid_to, CURRENT_DATE) - valid_from) AS avg_days_per_version 
FROM DIM_Patient_SCD2 
WHERE is_current = FALSE 
GROUP BY patient_id;

-- KORREKTUR (globaler AVG):
-- SELECT AVG(COALESCE(valid_to, CURRENT_DATE) - valid_from) AS avg_days_per_version 
-- FROM DIM_Patient_SCD2 
-- WHERE valid_to IS NOT NULL;  -- nur geschlossene Versionen


-- Aufgabe 12: Finde Patienten die mehr als 5 Adresswechsel hatten (mindestens 6 Versionen mit unterschiedlichen Adressen)
-- ❌ FEHLER: COUNT(*) >= 6 ist nicht gleich "unterschiedliche Adressen"! Braucht COUNT(DISTINCT address)!

SELECT patient_id, COUNT(*) AS address_changes 
FROM DIM_Patient_SCD2 
GROUP BY patient_id 
HAVING COUNT(*) >= 6;

-- KORREKTUR:
-- SELECT patient_id, COUNT(DISTINCT address) AS unique_addresses
-- FROM DIM_Patient_SCD2 
-- GROUP BY patient_id 
-- HAVING COUNT(DISTINCT address) >= 6
-- ORDER BY unique_addresses DESC;


-- Aufgabe 13: Erstelle einen Bericht der zeigt wie viele Ärzte in jedem Jahr ihre Spezialität gewechselt haben (Temporal Aggregation)
-- ❌ FEHLER: EXTRACT(YEAR FROM valid_from) zeigt nur START-Jahr, nicht WECHSEL-Jahr! Braucht LAG/LEAD oder Vergleich mit vorheriger Version!

SELECT EXTRACT(YEAR FROM valid_from) AS year, COUNT(*) AS specialty_changes 
FROM DIM_Doctor_SCD2 
WHERE version_number > 1 
GROUP BY year 
ORDER BY year;

-- KORREKTUR:
-- WITH SpecialtyChanges AS (
--     SELECT 
--         doctor_id,
--         specialty,
--         LAG(specialty) OVER (PARTITION BY doctor_id ORDER BY version_number) AS previous_specialty,
--         EXTRACT(YEAR FROM valid_from) AS change_year,
--         version_number
--     FROM DIM_Doctor_SCD2
-- )
-- SELECT 
--     change_year AS year, 
--     COUNT(*) AS specialty_changes 
-- FROM SpecialtyChanges
-- WHERE previous_specialty IS NOT NULL AND specialty <> previous_specialty
-- GROUP BY change_year 
-- ORDER BY change_year;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 23.1/100
-- SUCCESS RATE: 2/13 (15.4%)

-- BREAKDOWN:
-- ✅ Korrekt:  2 (Tasks 3, 6)
-- ⚠️ Teilweise: 4 (Tasks 1, 4, 7, 11)
-- ❌ Fehler:   7 (Tasks 2, 5, 8, 9, 10, 12, 13)
-- 🚫 Failed:   0

-- STRENGTHS:
-- + Point-in-Time Queries korrekt (Task 3)
-- + Duration Calculation korrekt (Task 6)
-- + Versteht SCD2 Grundkonzepte (valid_from, valid_to, is_current)

-- WEAKNESSES:
-- - MERGE Statements KOMPLETT FALSCH (Tasks 9, 10)
-- - SCD2 Join Logic fehlerhaft (Task 5 - fehlt Temporal Join)
-- - Falsche Interpretation von "Version History" (Tasks 1, 2, 7, 11, 12, 13)
-- - COUNT(*) statt COUNT(DISTINCT) bei Änderungserkennung
-- - Temporal Aggregation ohne LAG/LEAD (Task 13)
-- - WHERE is_current = TRUE filtert historische Daten aus (Tasks 2, 7, 8)

-- CRITICAL ERRORS:
-- - Tasks 9, 10: MERGE Syntax komplett ungültig! (WHEN MATCHED THEN INSERT ist unmöglich!)
-- - Task 5: Temporal Join fehlt (kritisch für SCD2 Fact-Joins!)
-- - Task 8: Historische Point-in-Time Analyse zeigt nur aktuelle Daten!
-- - Task 12: COUNT(*) statt COUNT(DISTINCT address) ist logisch falsch!

-- RECOMMENDATION:
-- ❌ NICHT GEEIGNET für SCD2 / Temporal Queries!
-- Das 7B Model versteht SCD2 Grundlagen, scheitert aber bei:
-- - MERGE Statements (0% Success)
-- - Temporal Joins (0% Success)
-- - Change Detection (0% Success)
-- Nur 15.4% Success Rate - VIEL zu niedrig für Production!

-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 50-70 (Sehr komplex, SCD2 ist Expert Level)
-- Parser Challenge: Extreme (MERGE, Temporal JOINs, Change Detection)
-- Model Compatibility: Expert models only (GPT-4, Claude, Large Qwen)
-- Special Focus:
--   - SCD2 Versioning Logic (valid_from, valid_to, is_current)
--   - Point-in-Time Queries (temporal WHERE clauses)
--   - MERGE Statements für SCD2 Maintenance
--   - Change Detection mit LAG/LEAD
--   - Temporal Joins zwischen Fact und SCD2 Dimensions
-- ============================================================================
