-- ============================================================================
-- TEST 8: HEALTHCARE - SLOWLY CHANGING DIMENSIONS TYPE 2 + MERGE
-- ============================================================================
-- Domain: Healthcare (Patienten, Behandlungen)
-- Complexity: 🟡 Intermediate
-- Focus: Historisierung (SCD Type 2), MERGE für Updates mit History
-- Test Coverage: SCD Type 2, Temporal Queries, ETL with Historization
-- ============================================================================

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


-- Aufgabe 2: Zeige die vollständige Historie eines bestimmten Patienten (patient_id = 'P001') mit allen historischen Adressen


-- Aufgabe 3: Finde alle Patienten die ihre Adresse in den letzten 6 Monaten geändert haben


-- Aufgabe 4: Zeige für jeden Patienten wie oft sich sein Versicherungstyp geändert hat


-- ============================================================================
-- TEST TASKS - TEMPORAL QUERIES (Point-in-Time)
-- ============================================================================

-- Aufgabe 5: Zeige die Patientendaten so wie sie am 1. Januar 2024 gültig waren


-- Aufgabe 6: Berechne die Anzahl der Patienten pro Stadt basierend auf den Daten vom 1. Juli 2023


-- ============================================================================
-- TEST TASKS - MERGE WITH SCD TYPE 2
-- ============================================================================

-- Aufgabe 7: Erstelle einen MERGE Statement der neue Patientendaten aus STG_Patient_Updates verarbeitet: (1) Wenn Patient neu ist: INSERT (2) Wenn sich relevante Attribute geändert haben: Setze is_current = FALSE für alten Record und INSERT neuen Record (3) Wenn keine Änderung: Keine Aktion


-- Aufgabe 8: Erstelle einen Trigger oder Stored Procedure der automatisch das SCD Type 2 Update durchführt wenn sich die Adresse oder der Versicherungstyp eines Patienten ändert


-- ============================================================================
-- TEST TASKS - ANALYTICS WITH HISTORIZATION
-- ============================================================================

-- Aufgabe 9: Berechne die durchschnittlichen Kosten pro Besuch für jeden Versicherungstyp (verwende aktuelle Patient-Daten)


-- Aufgabe 10: Vergleiche die Kosten pro Besuch für Patienten die ihren Versicherungstyp gewechselt haben (vorher vs nachher)


-- Aufgabe 11: Finde alle Behandlungen bei denen der Patient während der Behandlungszeit seine Adresse geändert hat


-- ============================================================================
-- TEST TASKS - COMPLEX QUERIES
-- ============================================================================

-- Aufgabe 12: Berechne für jeden Arzt die Anzahl der unterschiedlichen Patienten die er behandelt hat (historische Daten berücksichtigen)


-- Aufgabe 13: Identifiziere Patienten die mehr als 3 Mal ihre Adresse geändert haben und zeige deren aktuelle Daten


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
