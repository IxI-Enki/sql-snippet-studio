-- ============================================================================
-- TEST 8: HEALTHCARE - SLOWLY CHANGING DIMENSIONS TYPE 2 + MERGE
-- ============================================================================
-- Domain: Healthcare (Patienten, Behandlungen)
-- Complexity: 🟡 Intermediate
-- Focus: Historisierung (SCD Type 2), MERGE für Updates mit History
-- Test Coverage: SCD Type 2, Temporal Queries, ETL with Historization
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

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

SELECT p.patient_key, p.patient_id, p.patient_name, p.date_of_birth, p.address, p.city, p.postal_code, p.insurance_type FROM DIM_Patient p WHERE p.is_current = TRUE;


-- Aufgabe 2: Zeige die vollständige Historie eines bestimmten Patienten (patient_id = 'P001') mit allen historischen Adressen

SELECT p.patient_key, p.valid_from, s.address FROM DIM_Patient p JOIN STG_Patient_Updates s ON p.patient_id = s.patient_id WHERE p.patient_id = 'P001' ORDER BY p.valid_from NULLS LAST;


-- Aufgabe 3: Finde alle Patienten die ihre Adresse in den letzten 6 Monaten geändert haben

SELECT p.patient_name, s.address FROM DIM_Patient p JOIN STG_Patient_Updates s ON p.patient_id = s.patient_id WHERE s.effective_date > CURRENT_DATE - INTERVAL '6 months';


-- Aufgabe 4: Zeige für jeden Patienten wie oft sich sein Versicherungstyp geändert hat

SELECT p.patient_key, COUNT(DISTINCT s.insurance_type) AS insurance_type_changes FROM DIM_Patient p JOIN STG_Patient_Updates s ON p.patient_id = s.patient_id WHERE s.effective_date IS NOT NULL GROUP BY p.patient_key ORDER BY p.patient_key;


-- ============================================================================
-- TEST TASKS - TEMPORAL QUERIES (Point-in-Time)
-- ============================================================================

-- Aufgabe 5: Zeige die Patientendaten so wie sie am 1. Januar 2024 gültig waren

SELECT p.patient_id, p.patient_name, p.date_of_birth, p.address, p.city, p.postal_code, p.insurance_type FROM DIM_Patient p WHERE p.valid_to >= '2024-01-01' AND (p.valid_from <= '2024-01-01' OR p.valid_from IS NULL);


-- Aufgabe 6: Berechne die Anzahl der Patienten pro Stadt basierend auf den Daten vom 1. Juli 2023

SELECT d.city, COUNT(DISTINCT f.patient_key) AS patient_count FROM DIM_Patient p JOIN FACT_Visit f ON p.patient_key = f.patient_key WHERE f.time_key IN (SELECT time_key FROM DIM_Time WHERE full_date >= '2023-07-01') GROUP BY d.city;


-- ============================================================================
-- TEST TASKS - MERGE WITH SCD TYPE 2
-- ============================================================================

-- Aufgabe 7: Erstelle einen MERGE Statement der neue Patientendaten aus STG_Patient_Updates verarbeitet: (1) Wenn Patient neu ist: INSERT (2) Wenn sich relevante Attribute geändert haben: Setze is_current = FALSE für alten Record und INSERT neuen Record (3) Wenn keine Änderung: Keine Aktion

SELECT s.patient_id, s.patient_name, s.date_of_birth, s.address, s.city, s.postal_code, s.insurance_type, COALESCE(p.valid_from, CURRENT_DATE) AS valid_from, p.is_current FROM STG_Patient_Updates s LEFT JOIN DIM_Patient p ON s.patient_id = p.patient_id AND s.date_of_birth = p.date_of_birth AND s.address = p.address AND s.city = p.city AND s.postal_code = p.postal_code AND s.insurance_type = p.insurance_type;


-- Aufgabe 8: Erstelle einen Trigger oder Stored Procedure der automatisch das SCD Type 2 Update durchführt wenn sich die Adresse oder der Versicherungstyp eines Patienten ändert

CREATE OR REPLACE FUNCTION update_patient_scd() RETURNS TRIGGER AS $update_scd$ BEGIN IF NEW.address IS DISTINCT FROM OLD.address OR NEW.insurance_type IS DISTINCT FROM OLD.insurance_type THEN UPDATE DIM_Patient SET valid_from = CURRENT_DATE, valid_to = (SELECT MAX(valid_to) FROM DIM_Patient WHERE patient_id = NEW.patient_id AND valid_to > CURRENT_DATE), is_current = TRUE WHERE patient_id = NEW.patient_id; END IF; RETURN NEW; END; $update_scd$ LANGUAGE plpgsql; CREATE TRIGGER update_patient_scd_trigger BEFORE UPDATE ON STG_Patient_Updates FOR EACH ROW EXECUTE PROCEDURE update_patient_scd();


-- ============================================================================
-- TEST TASKS - ANALYTICS WITH HISTORIZATION
-- ============================================================================

-- Aufgabe 9: Berechne die durchschnittlichen Kosten pro Besuch für jeden Versicherungstyp (verwende aktuelle Patient-Daten)

SELECT p.insurance_type, AVG(f.actual_cost) AS average_cost FROM FACT_Visit f JOIN DIM_Patient p ON f.patient_key = p.patient_key WHERE p.is_current = TRUE GROUP BY p.insurance_type;


-- Aufgabe 10: Vergleiche die Kosten pro Besuch für Patienten die ihren Versicherungstyp gewechselt haben (vorher vs nachher)

SELECT f.patient_key, AVG(f.actual_cost) AS avg_actual_cost_before, AVG(f2.actual_cost) AS avg_actual_cost_after FROM FACT_Visit f JOIN STG_Patient_Updates s ON f.patient_key = CAST(s.patient_id AS INTEGER) LEFT JOIN FACT_Visit f2 ON f.patient_key = CAST(s.patient_id AS INTEGER) AND f2.time_key > (SELECT time_key FROM DIM_Time WHERE full_date = s.effective_date) GROUP BY f.patient_key HAVING COUNT(f.actual_cost) > 1;


-- Aufgabe 11: Finde alle Behandlungen bei denen der Patient während der Behandlungszeit seine Adresse geändert hat

SELECT f.visit_id FROM FACT_Visit f JOIN DIM_Patient p ON f.patient_key = p.patient_key WHERE p.address != (SELECT s.address FROM STG_Patient_Updates s WHERE s.effective_date BETWEEN p.valid_from AND COALESCE(p.valid_to, CURRENT_DATE));


-- ============================================================================
-- TEST TASKS - COMPLEX QUERIES
-- ============================================================================

-- Aufgabe 12: Berechne für jeden Arzt die Anzahl der unterschiedlichen Patienten die er behandelt hat (historische Daten berücksichtigen)

SELECT d.doctor_key, COUNT(DISTINCT f.patient_key) AS patient_count FROM FACT_Visit f JOIN DIM_Doctor d ON f.doctor_key = d.doctor_key GROUP BY d.doctor_key ORDER BY patient_count DESC NULLS LAST;


-- Aufgabe 13: Identifiziere Patienten die mehr als 3 Mal ihre Adresse geändert haben und zeige deren aktuelle Daten

SELECT p.patient_name, p.address FROM DIM_Patient p WHERE p.is_current = TRUE AND p.valid_to IS NULL ORDER BY p.patient_key;


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
