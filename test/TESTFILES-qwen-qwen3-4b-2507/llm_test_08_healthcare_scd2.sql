-- ============================================================================
-- TEST 8: HEALTHCARE - SLOWLY CHANGING DIMENSIONS TYPE 2 + MERGE
-- ============================================================================
-- Domain: Healthcare (Patienten, Behandlungen)
-- Complexity: 🟡 Intermediate
-- Focus: Historisierung (SCD Type 2), MERGE für Updates mit History
-- Test Coverage: SCD Type 2, Temporal Queries, ETL with Historization
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

-- ============================================================================
-- SCHEMA: Healthcare Data Warehouse with SCD Type 2
-- ============================================================================

-- PATIENT DIMENSION (SCD Type 2 - Tracks Historical Changes)
CREATE TABLE DIM_Patient (
    patient_key SERIAL PRIMARY KEY,
    patient_id VARCHAR(20),              -- Business Key (not unique!)
    patient_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    address VARCHAR(200),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    insurance_type VARCHAR(50),
    -- SCD Type 2 Attributes
    valid_from DATE NOT NULL,
    valid_to DATE,                       -- NULL = current record
    is_current BOOLEAN DEFAULT TRUE
);

CREATE TABLE DIM_Doctor (
    doctor_key SERIAL PRIMARY KEY,
    doctor_id VARCHAR(20) UNIQUE,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    department VARCHAR(100),
    years_experience INT
);

CREATE TABLE DIM_Treatment (
    treatment_key SERIAL PRIMARY KEY,
    treatment_code VARCHAR(20) UNIQUE,
    treatment_name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    base_cost DECIMAL(10,2),
    duration_minutes INT
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    week INT,
    day_name VARCHAR(20)
);

-- FACT TABLE
CREATE TABLE FACT_Visit (
    visit_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    patient_key INT REFERENCES DIM_Patient(patient_key),
    doctor_key INT REFERENCES DIM_Doctor(doctor_key),
    treatment_key INT REFERENCES DIM_Treatment(treatment_key),
    actual_cost DECIMAL(10,2),
    insurance_covered DECIMAL(10,2),
    patient_paid DECIMAL(10,2),
    visit_duration_minutes INT,
    visit_status VARCHAR(20)  -- 'Completed', 'Cancelled', 'No-Show'
);

-- ============================================================================
-- STAGING TABLE FOR SCD TYPE 2 UPDATES
-- ============================================================================

CREATE TABLE STG_Patient_Updates (
    patient_id VARCHAR(20),
    patient_name VARCHAR(100),
    date_of_birth DATE,
    address VARCHAR(200),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    insurance_type VARCHAR(50),
    effective_date DATE
);

-- ============================================================================
-- TEST TASKS - SCD TYPE 2 QUERIES
-- ============================================================================

-- Aufgabe 1: Zeige alle aktuellen Patientendaten (is_current = TRUE)

-- ✅ PERFEKT (Score: 100/100)
--    Einfache WHERE Klausel, korrekt!

SELECT * FROM DIM_Patient WHERE is_current = TRUE;


-- Aufgabe 2: Zeige die vollständige Historie eines bestimmten Patienten (patient_id = 'P001') mit allen historischen Adressen

-- ⚠️ ÜBERKOMPLEX (Score: 80/100)
--    JOIN zu DIM_Time ist NICHT nötig für "historische Adressen"!
--    Query zeigt Patient-Daten für JEDEN Tag im Gültigkeitszeitraum!
--    Aufgabe will nur historische RECORDS, nicht expanded timeline!

SELECT 
    p.patient_id,
    p.patient_name,
    p.date_of_birth,
    p.address,
    p.city,
    p.postal_code,
    p.insurance_type,
    t.full_date,
    t.year,
    t.quarter,
    t.month,
    t.week,
    t.day_name
FROM DIM_Patient p
JOIN DIM_Time t ON p.valid_from <= t.full_date AND (p.valid_to IS NULL OR p.valid_to > t.full_date)
WHERE p.patient_id = 'P001'
ORDER BY t.full_date ASC;

-- KORREKTE LÖSUNG:
-- SELECT 
--     patient_id,
--     patient_name,
--     address,
--     city,
--     postal_code,
--     insurance_type,
--     valid_from,
--     valid_to,
--     is_current
-- FROM DIM_Patient
-- WHERE patient_id = 'P001'
-- ORDER BY valid_from;


-- Aufgabe 3: Finde alle Patienten die ihre Adresse in den letzten 6 Monaten geändert haben

-- ⚠️ TEILWEISE KORREKT (Score: 60/100)
--    PROBLEM: Query nutzt STG_Patient_Updates, nicht DIM_Patient!
--    Sollte valid_from in DIM_Patient prüfen, nicht Staging!
--    Staging ist für ETL, nicht für Queries über Historie!

SELECT DISTINCT p.patient_name
FROM DIM_Patient p
JOIN STG_Patient_Updates su ON p.patient_id = su.patient_id
WHERE su.effective_date >= CURRENT_DATE - INTERVAL '6 months';

-- KORREKTE LÖSUNG:
-- SELECT DISTINCT patient_name
-- FROM DIM_Patient
-- WHERE valid_from >= CURRENT_DATE - INTERVAL '6 months'
--   AND is_current = FALSE;


-- Aufgabe 4: Zeige für jeden Patienten wie oft sich sein Versicherungstyp geändert hat

-- ❌ FAILED (Score: 30/100)
--    PROBLEM: Query nutzt STG_Patient_Updates, nicht DIM_Patient!
--    COUNT(p2.insurance_type) zählt NUR NICHT-NULL Werte, nicht Änderungen!
--    Sollte SCD2 Historie in DIM_Patient nutzen (Anzahl Records - 1)!

SELECT 
    p.patient_id,
    COUNT(p2.insurance_type) AS insurance_type_changes
FROM 
    DIM_Patient p
JOIN 
    STG_Patient_Updates p2 ON p.patient_id = p2.patient_id
WHERE 
    p2.effective_date IS NOT NULL
GROUP BY 
    p.patient_id;

-- KORREKTE LÖSUNG:
-- SELECT 
--     patient_id,
--     COUNT(*) - 1 AS insurance_type_changes
-- FROM DIM_Patient
-- GROUP BY patient_id
-- HAVING COUNT(*) > 1;


-- ============================================================================
-- TEST TASKS - TEMPORAL QUERIES (Point-in-Time)
-- ============================================================================

-- Aufgabe 5: Zeige die Patientendaten so wie sie am 1. Januar 2024 gültig waren

-- ❌ LOGIKFEHLER (Score: 20/100)
--    FEHLER: "valid_to <= '2024-01-01'" ist FALSCH!
--    FEHLER: "valid_from > '2024-01-01'" ist ebenfalls FALSCH!
--    Korrekt: valid_from <= date AND (valid_to > date OR valid_to IS NULL)

SELECT 
    p.patient_id,
    p.patient_name,
    p.date_of_birth,
    p.address,
    p.city,
    p.postal_code,
    p.insurance_type,
    p.valid_from,
    p.valid_to,
    p.is_current
FROM 
    DIM_Patient p
WHERE 
    p.valid_to <= '2024-01-01' 
    AND (p.valid_from > '2024-01-01' OR p.valid_to IS NULL)
    AND p.valid_from <= '2024-01-01';

-- KORREKTE LÖSUNG:
-- SELECT 
--     patient_id,
--     patient_name,
--     address,
--     city,
--     postal_code,
--     insurance_type
-- FROM DIM_Patient
-- WHERE valid_from <= '2024-01-01'
--   AND (valid_to > '2024-01-01' OR valid_to IS NULL);


-- Aufgabe 6: Berechne die Anzahl der Patienten pro Stadt basierend auf den Daten vom 1. Juli 2023

-- ❌ FAILED (Score: 30/100)
--    FEHLER: WHERE t.full_date >= '2023-07-01' ist FALSCH!
--    Aufgabe sagt "VOM 1. Juli 2023" (Point-in-Time), nicht ">=" !
--    JOIN zu DIM_Time ist unnötig komplex!

SELECT 
    p.city,
    COUNT(p.patient_key) AS patient_count
FROM 
    DIM_Patient p
JOIN 
    DIM_Time t ON p.valid_from <= t.full_date AND (p.valid_to IS NULL OR p.valid_to >= t.full_date)
WHERE 
    t.full_date >= '2023-07-01'
GROUP BY 
    p.city;

-- KORREKTE LÖSUNG:
-- SELECT 
--     city,
--     COUNT(*) AS patient_count
-- FROM DIM_Patient
-- WHERE valid_from <= '2023-07-01'
--   AND (valid_to > '2023-07-01' OR valid_to IS NULL)
-- GROUP BY city;


-- ============================================================================
-- TEST TASKS - MERGE WITH SCD TYPE 2
-- ============================================================================

-- Aufgabe 7: Erstelle einen MERGE Statement der neue Patientendaten aus STG_Patient_Updates verarbeitet: (1) Wenn Patient neu ist: INSERT (2) Wenn sich relevante Attribute geändert haben: Setze is_current = FALSE für alten Record und INSERT neuen Record (3) Wenn keine Änderung: Keine Aktion

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEIN MERGE Statement generieren!
--    SCD Type 2 MERGE ist sehr komplex!

-- Aufgabe 8: Erstelle einen Trigger oder Stored Procedure der automatisch das SCD Type 2 Update durchführt wenn sich die Adresse oder der Versicherungstyp eines Patienten ändert

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINEN Trigger/Procedure generieren!
--    Stored Procedures sind sehr komplex für 4B Model!

-- ============================================================================
-- TEST TASKS - ANALYTICS WITH HISTORIZATION
-- ============================================================================

-- Aufgabe 9: Berechne die durchschnittlichen Kosten pro Besuch für jeden Versicherungstyp (verwende aktuelle Patient-Daten)

-- ✅ PERFEKT (Score: 100/100)
--    SCD Type 2 korrekt berücksichtigt (is_current = TRUE)!
--    Gruppierung und Aggregation korrekt!

SELECT 
    p.insurance_type,
    AVG(f.actual_cost) AS average_cost_per_visit
FROM 
    DIM_Patient p
JOIN 
    FACT_Visit f ON p.patient_key = f.patient_key
WHERE 
    p.is_current = TRUE
GROUP BY 
    p.insurance_type;


-- Aufgabe 10: Vergleiche die Kosten pro Besuch für Patienten die ihren Versicherungstyp gewechselt haben (vorher vs nachher)

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!
--    Benötigt Self-JOIN über DIM_Patient Historie!

-- Aufgabe 11: Finde alle Behandlungen bei denen der Patient während der Behandlungszeit seine Adresse geändert hat

-- ❌ LOGIKFEHLER (Score: 30/100)
--    FEHLER: fv.time_key::DATE zu (SELECT MAX... WHERE time_key = ...) macht keinen Sinn!
--    FEHLER: Nutzt STG_Patient_Updates statt DIM_Patient Historie!
--    FEHLER: BETWEEN start und start ist immer FALSE!
--    Behandlungszeit sollte über visit_duration_minutes berechnet werden!

SELECT DISTINCT t.treatment_name
FROM FACT_Visit fv
JOIN DIM_Treatment t ON fv.treatment_key = t.treatment_key
JOIN DIM_Patient p ON fv.patient_key = p.patient_key
WHERE EXISTS (
    SELECT 1
    FROM STG_Patient_Updates spu
    WHERE spu.patient_id = p.patient_id
      AND spu.effective_date BETWEEN fv.time_key::DATE AND (SELECT MAX(full_date) FROM DIM_Time WHERE time_key = fv.time_key)
);

-- KORREKTE LÖSUNG:
-- SELECT DISTINCT t.treatment_name
-- FROM FACT_Visit fv
-- JOIN DIM_Treatment t ON fv.treatment_key = t.treatment_key
-- JOIN DIM_Time dt ON fv.time_key = dt.time_key
-- WHERE EXISTS (
--     SELECT 1
--     FROM DIM_Patient p1
--     JOIN DIM_Patient p2 ON p1.patient_id = p2.patient_id
--     WHERE fv.patient_key IN (p1.patient_key, p2.patient_key)
--       AND p1.valid_to BETWEEN dt.full_date AND dt.full_date + INTERVAL '1 day' * fv.visit_duration_minutes / 1440
--       AND p1.address <> p2.address
-- );


-- ============================================================================
-- TEST TASKS - COMPLEX QUERIES
-- ============================================================================

-- Aufgabe 12: Berechne für jeden Arzt die Anzahl der unterschiedlichen Patienten die er behandelt hat (historische Daten berücksichtigen)

-- ⚠️ TEILWEISE KORREKT (Score: 80/100)
--    COUNT(DISTINCT patient_key) ist technisch korrekt!
--    ABER: Aufgabe sagt "historische Daten berücksichtigen" - impliziert patient_id, nicht patient_key!
--    Ein Patient mit 3 SCD2-Records hat 3 patient_keys, aber nur 1 patient_id!

SELECT 
    d.doctor_id,
    COUNT(DISTINCT v.patient_key) AS distinct_patients_count
FROM 
    DIM_Doctor d
JOIN 
    FACT_Visit v ON d.doctor_key = v.doctor_key
GROUP BY 
    d.doctor_id;

-- KORREKTE LÖSUNG (wenn patient_id gemeint):
-- SELECT 
--     d.doctor_id,
--     COUNT(DISTINCT p.patient_id) AS distinct_patients_count
-- FROM DIM_Doctor d
-- JOIN FACT_Visit v ON d.doctor_key = v.doctor_key
-- JOIN DIM_Patient p ON v.patient_key = p.patient_key
-- GROUP BY d.doctor_id;


-- Aufgabe 13: Identifiziere Patienten die mehr als 3 Mal ihre Adresse geändert haben und zeige deren aktuelle Daten

-- ❌ FAILED (Score: 0/100)
--    Model konnte KEINE Query generieren!

-- KORREKTE LÖSUNG:
-- WITH address_changes AS (
--     SELECT 
--         patient_id,
--         COUNT(*) - 1 AS change_count
--     FROM DIM_Patient
--     GROUP BY patient_id
--     HAVING COUNT(*) > 3
-- )
-- SELECT p.*
-- FROM DIM_Patient p
-- JOIN address_changes ac ON p.patient_id = ac.patient_id
-- WHERE p.is_current = TRUE;

-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 37.7/100 ⭐⭐
-- SUCCESS RATE: 15.4% (2/13 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN:
--   ✅ Aufgabe 1:  100/100 - Perfekt (Simple WHERE)
--   ⚠️ Aufgabe 2:   80/100 - Überkomplex (JOIN zu DIM_Time unnötig)
--   ⚠️ Aufgabe 3:   60/100 - Nutzt Staging statt DIM_Patient Historie
--   ❌ Aufgabe 4:   30/100 - Zählt Staging-Records, nicht Historie
--   ❌ Aufgabe 5:   20/100 - Point-in-Time Logik KOMPLETT FALSCH!
--   ❌ Aufgabe 6:   30/100 - WHERE >= statt = (Point-in-Time)
--   ❌ Aufgabe 7:    0/100 - MERGE NICHT generiert!
--   ❌ Aufgabe 8:    0/100 - Trigger/Procedure NICHT generiert!
--   ✅ Aufgabe 9:  100/100 - Perfekt (is_current = TRUE korrekt)
--   ❌ Aufgabe 10:   0/100 - NICHT generiert!
--   ❌ Aufgabe 11:  30/100 - Logikfehler + nutzt Staging
--   ⚠️ Aufgabe 12:  80/100 - patient_key vs patient_id (mehrdeutig)
--   ❌ Aufgabe 13:   0/100 - NICHT generiert!
--
-- STÄRKEN:
--   + Simple WHERE Klauseln verstanden
--   + is_current = TRUE Filter korrekt verwendet
--
-- SCHWÄCHEN:
--   - Point-in-Time Queries: KOMPLETT FALSCH!
--   - valid_from/valid_to Logik: NICHT VERSTANDEN!
--   - Nutzt STG_Patient_Updates statt DIM_Patient Historie
--   - MERGE für SCD Type 2: KANN ES NICHT!
--   - Trigger/Procedures: ZU KOMPLEX!
--
-- KRITISCHE FEHLER:
--   ⚠️ Point-in-Time Logic: valid_from <= date AND (valid_to > date OR NULL) - FALSCH!
--   ⚠️ Verwechselt Staging (STG_) mit Dimension (DIM_) für Historie!
--   ⚠️ MERGE Statements: KANN DAS MODEL NICHT!
--   ⚠️ SCD Type 2 Konzept: NUR OBERFLÄCHLICH VERSTANDEN!
--
-- EMPFEHLUNG: ❌ ABSOLUT UNGEEIGNET für SCD Type 2!
--              Versteht Konzept nicht, Point-in-Time Queries falsch!
--              Für Production: NICHT VERWENDEN für Temporale Daten!
-- ============================================================================
