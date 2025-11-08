-- ============================================================================
-- TEST 9: EDUCATION SYSTEM - ALL WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Bildungssystem (Schule/Universität)
-- Complexity: 🔴 Advanced
-- Focus: Alle Window Function Typen, ROLLUP, komplexe Analysen
-- Test Coverage: Complete Window Function Suite, NTILE, ROLLUP, Rankings
-- ============================================================================

-- Dieser Test wurde mit dem Modell llama-3-sqlcoder-8b getestet.

-- ============================================================================
-- SCHEMA: Education System Data Warehouse
-- ============================================================================

CREATE TABLE DIM_Student (
    student_key SERIAL PRIMARY KEY,
    student_id VARCHAR(20) UNIQUE,
    student_name VARCHAR(100) NOT NULL,
    enrollment_date DATE,
    major VARCHAR(100),
    faculty VARCHAR(100),
    year_of_study INT
);

CREATE TABLE DIM_Course (
    course_key SERIAL PRIMARY KEY,
    course_code VARCHAR(20) UNIQUE,
    course_name VARCHAR(200) NOT NULL,
    department VARCHAR(100),
    credits INT,
    difficulty_level VARCHAR(20)  -- 'Beginner', 'Intermediate', 'Advanced'
);

CREATE TABLE DIM_Professor (
    professor_key SERIAL PRIMARY KEY,
    professor_id VARCHAR(20) UNIQUE,
    professor_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    title VARCHAR(50),           -- 'Assistant', 'Associate', 'Full Professor'
    years_teaching INT
);

CREATE TABLE DIM_Time (
    time_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    semester VARCHAR(20),        -- 'Fall 2024', 'Spring 2024'
    academic_year VARCHAR(20)    -- '2024/2025'
);

CREATE TABLE FACT_Grade (
    grade_id SERIAL PRIMARY KEY,
    time_key INT REFERENCES DIM_Time(time_key),
    student_key INT REFERENCES DIM_Student(student_key),
    course_key INT REFERENCES DIM_Course(course_key),
    professor_key INT REFERENCES DIM_Professor(professor_key),
    grade_points DECIMAL(4,2),   -- 0.00 to 4.00 (GPA scale)
    percentage DECIMAL(5,2),     -- 0 to 100
    letter_grade VARCHAR(2),     -- 'A+', 'A', 'B+', etc.
    passed BOOLEAN
);

-- ============================================================================
-- TEST TASKS - RANKING FUNCTIONS
-- ============================================================================

-- Aufgabe 1: Ranke alle Studenten nach ihrem Gesamtnotendurchschnitt (GPA) - verwende RANK, DENSE_RANK und ROW_NUMBER zum Vergleich

SELECT s.student_name, f.grade_points, rank() OVER (ORDER BY f.grade_points DESC) AS rank FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key ORDER BY rank NULLS LAST;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)

SELECT s.student_name, dense_rank() OVER (PARTITION BY s.major ORDER BY f.grade_points DESC) AS rank FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)

SELECT s.student_name, row_number() OVER(PARTITION BY s.faculty ORDER BY COUNT(f.grade_id) DESC) AS rank FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key GROUP BY s.student_name, s.faculty;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))

SELECT s.student_key, s.student_name, ntile(4) OVER (ORDER BY f.grade_points DESC) AS quartile FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key ORDER BY quartile, grade_points DESC NULLS LAST;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)

SELECT s.student_name FROM DIM_Student s ORDER BY ntile(10) OVER (ORDER BY year_of_study DESC) = 10;


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)

SELECT s.student_name, c.course_name, ntile(5) OVER (PARTITION BY f.grade_id ORDER BY g.percentage DESC) AS performance_group FROM FACT_Grade f JOIN DIM_Student s ON f.student_key = s.student_key JOIN DIM_Course c ON f.course_key = c.course_key JOIN DIM_Professor p ON f.professor_key = p.professor_key;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)

SELECT s.student_name, t.full_date, lag(t.full_date) OVER (PARTITION BY s.student_key ORDER BY t.full_date) AS previous_semester FROM DIM_Student s JOIN FACT_Grade g ON s.student_key = g.student_key JOIN DIM_Time t ON g.time_key = t.time_key;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten

SELECT s.student_name, t.year AS previous_year, f.year AS current_year, (f.grade_points - lag(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY t.full_date)) AS gpa_change FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key JOIN DIM_Time t ON f.time_key = t.time_key;


-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)

SELECT s.student_name FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key WHERE f.letter_grade = 'A' AND f.percentage >= 80 AND lag(f.letter_grade) OVER (PARTITION BY s.student_key ORDER BY f.time_key) = 'A' AND lag(f.percentage) OVER (PARTITION BY s.student_key ORDER BY f.time_key) >= 80;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

SELECT s.student_key, s.student_name, SUM(c.credits) OVER (PARTITION BY s.student_key ORDER BY t.full_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_credits FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key JOIN DIM_Course c ON f.course_key = c.course_key JOIN DIM_Time t ON f.time_key = t.time_key;

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)

SELECT s.student_key, s.student_name, SUM(c.credits) OVER (PARTITION BY s.student_key ORDER BY t.full_date ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS cumulative_credits FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key JOIN DIM_Course c ON f.course_key = c.course_key JOIN DIM_Time t ON f.time_key = t.time_key;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse

SELECT s.student_name, AVG(f.grade_points) AS average_grade FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key GROUP BY s.student_name;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten

SELECT s.student_name, AVG(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.time_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_semester_moving_average FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten

SELECT s.student_name, AVG(f.grade_points) AS average_grade FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key WHERE f.time_key IN (SELECT MAX(time_key) FROM FACT_Grade GROUP BY student_key ORDER BY time_key DESC LIMIT 5) GROUP BY s.student_name;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)

SELECT s.student_name, f.grade_points AS first_grade, lag(f.grade_points) OVER (PARTITION BY f.student_key ORDER BY f.time_key) AS previous_grade FROM FACT_Grade f JOIN DIM_Student s ON f.student_key = s.student_key;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)

SELECT s.student_name, MAX(f.grade_points) AS highest_grade, MIN(f.grade_points) AS lowest_grade FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key GROUP BY s.student_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)

SELECT d.faculty, d.major, d.year_of_study, AVG(f.grade_points) AS average_gpa FROM DIM_Student d JOIN FACT_Grade f ON d.student_key = f.student_key GROUP BY d.faculty, d.major, d.year_of_study WITH ROLLUP;


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)


SELECT d.department, c.difficulty_level, p.title, COUNT(f.grade_id) AS total_passed_courses FROM FACT_Grade f JOIN DIM_Course c ON f.course_key = c.course_key JOIN DIM_Professor p ON f.professor_key = p.professor_key JOIN DIM_Student s ON f.student_key = s.student_key JOIN DIM_Time t ON f.time_key = t.time_key WHERE f.passed = TRUE GROUP BY d.department, c.difficulty_level, p.title ROLLUP;

-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT t.academic_year, t.semester, AVG(f.grade_points) AS average_gpa FROM FACT_Grade f JOIN DIM_Time t ON f.time_key = t.time_key GROUP BY t.academic_year, t.semester WITH ROLLUP;


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19: Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)

SELECT p.professor_key, p.professor_id, p.professor_name FROM DIM_Professor p JOIN FACT_Grade f ON p.professor_key = f.profiler_key WHERE f.grade_points > (SELECT AVG(grade_points) FROM FACT_Grade);


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function

SELECT s.student_name FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key WHERE STDDEV(f.grade_points) < 0.5 ORDER BY s.student_name NULLS LAST;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)

SELECT c.course_code, percent_rank() OVER (PARTITION BY c.course_key ORDER BY f.grade_points DESC) AS percentage_of_students_above_average FROM FACT_Grade f JOIN DIM_Course c ON f.course_key = c.course_key WHERE f.passed = TRUE;


-- ============================================================================
-- NOTES FOR LLM TESTING:
-- ============================================================================
-- Expected Validation Score: 60-75 (Sehr viele verschiedene Window Functions)
-- Parser Challenge: Very High (Alle Window Function Typen, komplexe Frames)
-- Model Compatibility: Advanced models only
-- Special Focus:
--   - Alle Window Function Typen korrekt verwendet
--   - NTILE für Quartile/Perzentile
--   - FIRST_VALUE, LAST_VALUE mit korrekten Frames
--   - LAG/LEAD mit verschiedenen Offsets
--   - Running Totals vs. Moving Averages unterscheiden
--   - ROLLUP mit korrekter Hierarchie-Reihenfolge
-- ============================================================================
