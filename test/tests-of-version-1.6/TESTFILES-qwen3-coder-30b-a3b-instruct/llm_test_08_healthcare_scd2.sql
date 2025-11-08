-- ============================================================================
-- TEST 8: HEALTHCARE - SLOWLY CHANGING DIMENSIONS TYPE 2 + MERGE
-- ============================================================================
-- Domain: Healthcare (Patienten, Behandlungen)
-- Complexity: 🟡 Intermediate
-- Focus: Historisierung (SCD Type 2), MERGE für Updates mit History
-- Test Coverage: SCD Type 2, Temporal Queries, ETL with Historization
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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

SELECT patient_id, patient_name, address, city, postal_code, insurance_type, valid_from, valid_to 
FROM DIM_Patient 
WHERE patient_id = 'P001' 
ORDER BY valid_from;


-- Aufgabe 3: Finde alle Patienten die ihre Adresse in den letzten 6 Monaten geändert haben

SELECT DISTINCT p.patient_name
FROM DIM_Patient p
WHERE p.valid_from >= CURRENT_DATE - INTERVAL '6 months'
AND p.valid_to IS NOT NULL;


-- Aufgabe 4: Zeige für jeden Patienten wie oft sich sein Versicherungstyp geändert hat

SELECT 
    p.patient_id,
    COUNT(*) AS insurance_change_count
FROM DIM_Patient p
WHERE p.valid_to IS NOT NULL
GROUP BY p.patient_id;


-- ============================================================================
-- TEST TASKS - TEMPORAL QUERIES (Point-in-Time)
-- ============================================================================

-- Aufgabe 5: Zeige die Patientendaten so wie sie am 1. Januar 2024 gültig waren

SELECT 
    patient_key,
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
FROM DIM_Patient
WHERE valid_from <= '2024-01-01' 
AND (valid_to IS NULL OR valid_to > '2024-01-01');


-- Aufgabe 6: Berechne die Anzahl der Patienten pro Stadt basierend auf den Daten vom 1. Juli 2023

SELECT 
    p.city,
    COUNT(DISTINCT p.patient_key) AS patient_count
FROM DIM_Patient p
JOIN FACT_Visit f ON p.patient_key = f.patient_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date = '2023-07-01'
GROUP BY p.city;


-- ============================================================================
-- TEST TASKS - MERGE WITH SCD TYPE 2
-- ============================================================================

-- Aufgabe 7: Erstelle einen MERGE Statement der neue Patientendaten aus STG_Patient_Updates verarbeitet: (1) Wenn Patient neu ist: INSERT (2) Wenn sich relevante Attribute geändert haben: Setze is_current = FALSE für alten Record und INSERT neuen Record (3) Wenn keine Änderung: Keine Aktion
!!! TIMEOUT !!!

-- Aufgabe 8: Erstelle einen Trigger oder Stored Procedure der automatisch das SCD Type 2 Update durchführt wenn sich die Adresse oder der Versicherungstyp eines Patienten ändert

CREATE OR REPLACE FUNCTION update_patient_scd()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if address or insurance_type has changed
    IF (OLD.address IS DISTINCT FROM NEW.address) OR 
       (OLD.insurance_type IS DISTINCT FROM NEW.insurance_type) THEN
        
        -- Mark the old record as not current
        UPDATE DIM_Patient 
        SET valid_to = CURRENT_DATE,
            is_current = FALSE
        WHERE patient_key = OLD.patient_key AND is_current = TRUE;
        
        -- Insert new record with updated information
        INSERT INTO DIM_Patient (
            patient_id, patient_name, date_of_birth, address, city, postal_code, insurance_type,
            valid_from, valid_to, is_current
        ) VALUES (
            NEW.patient_id, NEW.patient_name, NEW.date_of_birth, NEW.address, NEW.city, NEW.postal_code, NEW.insurance_type,
            CURRENT_DATE, NULL, TRUE
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_patient_scd
    AFTER UPDATE ON DIM_Patient
    FOR EACH ROW
    EXECUTE FUNCTION update_patient_scd();


-- ============================================================================
-- TEST TASKS - ANALYTICS WITH HISTORIZATION
-- ============================================================================

-- Aufgabe 9: Berechne die durchschnittlichen Kosten pro Besuch für jeden Versicherungstyp (verwende aktuelle Patient-Daten)

SELECT 
    p.insurance_type,
    AVG(f.actual_cost) AS avg_cost_per_visit
FROM FACT_Visit f
JOIN DIM_Patient p ON f.patient_key = p.patient_key
WHERE p.is_current = TRUE
GROUP BY p.insurance_type;


-- Aufgabe 10: Vergleiche die Kosten pro Besuch für Patienten die ihren Versicherungstyp gewechselt haben (vorher vs nachher)

SELECT 
    p.patient_name,
    pv.visit_id,
    pv.actual_cost AS cost_before_change,
    pv2.actual_cost AS cost_after_change,
    (pv2.actual_cost - pv.actual_cost) AS cost_difference
FROM FACT_Visit pv
JOIN DIM_Patient p ON pv.patient_key = p.patient_key
JOIN STG_Patient_Updates pu ON p.patient_id = pu.patient_id
JOIN FACT_Visit pv2 ON pv2.patient_key = p.patient_key
WHERE pv.time_key < (
    SELECT time_key 
    FROM DIM_Time 
    WHERE full_date = pu.effective_date
)
AND pv2.time_key >= (
    SELECT time_key 
    FROM DIM_Time 
    WHERE full_date = pu.effective_date
);


-- Aufgabe 11: Finde alle Behandlungen bei denen der Patient während der Behandlungszeit seine Adresse geändert hat

SELECT DISTINCT f.visit_id, t.treatment_name, p.patient_name, p.address AS current_address
FROM FACT_Visit f
JOIN DIM_Treatment t ON f.treatment_key = t.treatment_key
JOIN DIM_Patient p ON f.patient_key = p.patient_key
WHERE EXISTS (
    SELECT 1 FROM DIM_Patient dp
    WHERE dp.patient_id = p.patient_id
    AND dp.valid_from <= (SELECT full_date FROM DIM_Time WHERE time_key = f.time_key)
    AND dp.valid_to > (SELECT full_date FROM DIM_Time WHERE time_key = f.time_key)
    AND dp.address != p.address
);


-- ============================================================================
-- TEST TASKS - COMPLEX QUERIES
-- ============================================================================

-- Aufgabe 12: Berechne für jeden Arzt die Anzahl der unterschiedlichen Patienten die er behandelt hat (historische Daten berücksichtigen)

SELECT 
    d.doctor_key,
    d.doctor_name,
    COUNT(DISTINCT f.patient_key) AS unique_patients_treated
FROM DIM_Doctor d
JOIN FACT_Visit f ON d.doctor_key = f.doctor_key
GROUP BY d.doctor_key, d.doctor_name;


-- Aufgabe 13: Identifiziere Patienten die mehr als 3 Mal ihre Adresse geändert haben und zeige deren aktuelle Daten

SELECT 
    p.patient_id,
    p.patient_name,
    p.address,
    p.city,
    p.postal_code,
    p.insurance_type,
    COUNT(*) as address_change_count
FROM DIM_Patient p
WHERE p.valid_to IS NULL
GROUP BY p.patient_key, p.patient_id, p.patient_name, p.address, p.city, p.postal_code, p.insurance_type
HAVING COUNT(DISTINCT p.address) > 3;


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
