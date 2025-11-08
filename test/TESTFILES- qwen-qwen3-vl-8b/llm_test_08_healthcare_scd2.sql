-- ============================================================================
-- TEST 8: HEALTHCARE - SLOWLY CHANGING DIMENSIONS TYPE 2 + MERGE
-- ============================================================================
-- Domain: Healthcare (Patienten, Behandlungen)
-- Complexity: 🟡 Intermediate
-- Focus: Historisierung (SCD Type 2), MERGE für Updates mit History
-- Test Coverage: SCD Type 2, Temporal Queries, ETL with Historization
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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

SELECT * FROM DIM_Patient WHERE is_current = TRUE;


-- Aufgabe 2: Zeige die vollständige Historie eines bestimmten Patienten (patient_id = 'P001') mit allen historischen Adressen

SELECT 
    dp.patient_name,
    dp.date_of_birth,
    dp.address,
    dp.city,
    dp.postal_code,
    dp.insurance_type,
    dp.valid_from,
    dp.valid_to,
    dp.is_current
FROM DIM_Patient dp
WHERE dp.patient_id = 'P001'
ORDER BY dp.valid_from;


-- Aufgabe 3: Finde alle Patienten die ihre Adresse in den letzten 6 Monaten geändert haben

SELECT DISTINCT p.patient_id, p.patient_name, p.address, p.city, p.postal_code
FROM DIM_Patient p
JOIN (
    SELECT patient_id, MAX(effective_date) AS latest_change
    FROM STG_Patient_Updates
    GROUP BY patient_id
) u ON p.patient_id = u.patient_id
WHERE u.latest_change >= CURRENT_DATE - INTERVAL '6 months'
AND p.valid_from <= u.latest_change
AND (p.valid_to IS NULL OR p.valid_to > u.latest_change);


-- Aufgabe 4: Zeige für jeden Patienten wie oft sich sein Versicherungstyp geändert hat

SELECT patient_id, COUNT(*) AS insurance_type_changes
FROM (
    SELECT patient_id, insurance_type, 
           ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY valid_from) AS rn
    FROM DIM_Patient
) sub
GROUP BY patient_id;


-- ============================================================================
-- TEST TASKS - TEMPORAL QUERIES (Point-in-Time)
-- ============================================================================

-- Aufgabe 5: Zeige die Patientendaten so wie sie am 1. Januar 2024 gültig waren

SELECT p.patient_id, p.patient_name, p.date_of_birth, p.address, p.city, p.postal_code, p.insurance_type
FROM DIM_Patient p
WHERE p.valid_from <= '2024-01-01' AND (p.valid_to IS NULL OR p.valid_to >= '2024-01-01');


-- Aufgabe 6: Berechne die Anzahl der Patienten pro Stadt basierend auf den Daten vom 1. Juli 2023

SELECT city, COUNT(*) AS patient_count
FROM DIM_Patient
WHERE valid_from <= '2023-07-01' AND (valid_to IS NULL OR valid_to >= '2023-07-01')
GROUP BY city;


-- ============================================================================
-- TEST TASKS - MERGE WITH SCD TYPE 2
-- ============================================================================

-- Aufgabe 7: Erstelle einen MERGE Statement der neue Patientendaten aus STG_Patient_Updates verarbeitet: (1) Wenn Patient neu ist: INSERT (2) Wenn sich relevante Attribute geändert haben: Setze is_current = FALSE für alten Record und INSERT neuen Record (3) Wenn keine Änderung: Keine Aktion

SELECT 
        stg.patient_id,
        stg.patient_name,
        stg.date_of_birth,
        stg.address,
        stg.city,
        stg.postal_code,
        stg.insurance_type,
        stg.effective_date,
        ROW_NUMBER() OVER (PARTITION BY stg.patient_id ORDER BY stg.effective_date DESC) AS rn
    FROM STG_Patient_Updates stg
) AS source
ON target.patient_id = source.patient_id
WHEN MATCHED AND (
    target.patient_name != source.patient_name OR
    target.date_of_birth != source.date_of_birth OR
    target.address != source.address OR
    target.city != source.city OR
    target.postal_code != source.postal_code OR
    target.insurance_type != source.insurance_type
) THEN
    UPDATE SET
        valid_to = source.effective_date,
        is_current = FALSE
WHEN NOT MATCHED THEN
    INSERT (patient_id, patient_name, date_of_birth, address, city, postal_code, insurance_type, valid_from, valid_to, is_current)
    VALUES (
        source.patient_id,
        source.patient_name,
        source.date_of_birth,
        source.address,
        source.city,
        source.postal_code,
        source.insurance_type,
        source.effective_date,
        NULL,
        TRUE
    );


-- Aufgabe 8: Erstelle einen Trigger oder Stored Procedure der automatisch das SCD Type 2 Update durchführt wenn sich die Adresse oder der Versicherungstyp eines Patienten ändert

CREATE OR REPLACE FUNCTION update_patient_scd_type2()
RETURNS TRIGGER AS $$
BEGIN
    -- Find the current record (valid_to is NULL)
    UPDATE DIM_Patient
    SET valid_to = CURRENT_DATE,
        is_current = FALSE
    WHERE patient_key = OLD.patient_key;

    -- Insert new record with new values and current date
    INSERT INTO DIM_Patient (
        patient_id,
        patient_name,
        date_of_birth,
        address,
        city,
        postal_code,
        insurance_type,
        valid_from,
        valid_to,
        is_current
    ) VALUES (
        NEW.patient_id,
        NEW.patient_name,
        NEW.date_of_birth,
        NEW.address,
        NEW.city,
        NEW.postal_code,
        NEW.insurance_type,
        NEW.effective_date,
        NULL,
        TRUE
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_patient_scd_type2
AFTER UPDATE ON STG_Patient_Updates
FOR EACH ROW
WHEN (OLD.address IS DISTINCT FROM NEW.address OR OLD.insurance_type IS DISTINCT FROM NEW.insurance_type)
EXECUTE FUNCTION update_patient_scd_type2();


-- ============================================================================
-- TEST TASKS - ANALYTICS WITH HISTORIZATION
-- ============================================================================

-- Aufgabe 9: Berechne die durchschnittlichen Kosten pro Besuch für jeden Versicherungstyp (verwende aktuelle Patient-Daten)

SELECT 
    p.insurance_type,
    AVG(f.actual_cost) AS avg_cost_per_visit
FROM 
    FACT_Visit f
JOIN 
    DIM_Patient p ON f.patient_key = p.patient_key
WHERE 
    p.is_current = TRUE
GROUP BY 
    p.insurance_type;


-- Aufgabe 10: Vergleiche die Kosten pro Besuch für Patienten die ihren Versicherungstyp gewechselt haben (vorher vs nachher)

SELECT 
    p.patient_id,
    p.patient_name,
    t1.treatment_name AS treatment_before,
    t2.treatment_name AS treatment_after,
    SUM(CASE WHEN pt.valid_from < ptu.effective_date THEN fv.actual_cost ELSE 0 END) AS total_cost_before,
    SUM(CASE WHEN pt.valid_from >= ptu.effective_date THEN fv.actual_cost ELSE 0 END) AS total_cost_after
FROM STG_Patient_Updates ptu
JOIN DIM_Patient p ON ptu.patient_id = p.patient_id
JOIN FACT_Visit fv ON p.patient_key = fv.patient_key
JOIN DIM_Treatment t1 ON fv.treatment_key = t1.treatment_key
JOIN DIM_Treatment t2 ON fv.treatment_key = t2.treatment_key
JOIN DIM_Patient pt ON pt.patient_id = ptu.patient_id
WHERE pt.valid_from < ptu.effective_date
GROUP BY p.patient_id, p.patient_name, t1.treatment_name, t2.treatment_name;


-- Aufgabe 11: Finde alle Behandlungen bei denen der Patient während der Behandlungszeit seine Adresse geändert hat

SELECT DISTINCT t.treatment_key, t.treatment_name, p.patient_id, p.patient_name, p.address, p.city, p.postal_code, v.visit_duration_minutes, v.visit_status
FROM FACT_Visit v
JOIN DIM_Patient p ON v.patient_key = p.patient_key
JOIN DIM_Treatment t ON v.treatment_key = t.treatment_key
JOIN STG_Patient_Updates pu ON p.patient_id = pu.patient_id
WHERE pu.effective_date BETWEEN v.time_key AND v.time_key
AND pu.effective_date > p.valid_from
AND (pu.effective_date < p.valid_to OR p.valid_to IS NULL);


-- ============================================================================
-- TEST TASKS - COMPLEX QUERIES
-- ============================================================================

-- Aufgabe 12: Berechne für jeden Arzt die Anzahl der unterschiedlichen Patienten die er behandelt hat (historische Daten berücksichtigen)

SELECT d.doctor_key, d.doctor_name, COUNT(DISTINCT fv.patient_key) AS patient_count
FROM DIM_Doctor d
JOIN FACT_Visit fv ON d.doctor_key = fv.doctor_key
GROUP BY d.doctor_key, d.doctor_name;


-- Aufgabe 13: Identifiziere Patienten die mehr als 3 Mal ihre Adresse geändert haben und zeige deren aktuelle Daten

SELECT p.patient_id, p.patient_name, p.date_of_birth, p.address, p.city, p.postal_code, p.insurance_type
FROM DIM_Patient p
WHERE p.is_current = TRUE
AND (
    SELECT COUNT(*)
    FROM DIM_Patient p2
    WHERE p2.patient_id = p.patient_id
    AND p2.valid_from <= p.valid_from
    AND p2.valid_to > p.valid_from
    AND p2.patient_key != p.patient_key
) > 3;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 70-85 (SCD Type 2 Logik kann komplex sein)
-- Parser Challenge: Medium-High (Temporal Conditions, Complex MERGE)
-- Model Compatibility: Advanced models preferred
-- Special Focus:
--   - Korrekte Verwendung von valid_from, valid_to, is_current
--   - MERGE Statement mit SCD Type 2 Logik
--   - Point-in-Time Queries (WHERE valid_from <= date AND (valid_to > date OR valid_to IS NULL))
--   - Historische vs. aktuelle Daten unterscheiden
-- ============================================================================
