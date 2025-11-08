-- ============================================================================
-- TEST 9: EDUCATION SYSTEM - ALL WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Bildungssystem (Schule/Universität)
-- Complexity: 🔴 Advanced
-- Focus: Alle Window Function Typen, ROLLUP, komplexe Analysen
-- Test Coverage: Complete Window Function Suite, NTILE, ROLLUP, Rankings
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-vl-8b getestet.

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

SELECT 
    s.student_name,
    AVG(f.grade_points) AS gpa,
    RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS rank_dense,
    DENSE_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY AVG(f.grade_points) DESC) AS row_number
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
GROUP BY s.student_key, s.student_name
ORDER BY AVG(f.grade_points) DESC;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)

SELECT 
    s.student_name, 
    s.major, 
    g.grade_points AS gpa, 
    DENSE_RANK() OVER (PARTITION BY s.major ORDER BY g.grade_points DESC) AS gpa_rank
FROM 
    DIM_Student s
JOIN 
    FACT_Grade g ON s.student_key = g.student_key
ORDER BY 
    s.major, 
    g.grade_points DESC;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)

SELECT faculty, student_name, grade_points
FROM (
    SELECT 
        s.faculty,
        s.student_name,
        g.grade_points,
        ROW_NUMBER() OVER (PARTITION BY s.faculty ORDER BY g.grade_points DESC) as rn
    FROM DIM_Student s
    JOIN FACT_Grade g ON s.student_key = g.student_key
) ranked
WHERE rn <= 3;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))

SELECT 
    s.student_name, 
    s.student_id, 
    f.grade_points AS gpa, 
    NTILE(4) OVER (ORDER BY f.grade_points DESC) AS performance_quartile
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
ORDER BY 
    f.grade_points DESC;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)

SELECT student_key, student_name, NTILE(10) OVER (ORDER BY year_of_study DESC) AS decile
FROM DIM_Student
WHERE NTILE(10) OVER (ORDER BY year_of_study DESC) = 10;


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)

SELECT 
    f.time_key,
    f.student_key,
    f.course_key,
    f.grade_points,
    NTILE(5) OVER (PARTITION BY f.course_key ORDER BY f.grade_points DESC) AS performance_group
FROM FACT_Grade f;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)

SELECT 
    s.student_name,
    t.semester,
    g.grade_points,
    LAG(g.grade_points, 1, 0) OVER (PARTITION BY s.student_key ORDER BY t.time_key) AS previous_grade_points
FROM 
    FACT_Grade g
JOIN 
    DIM_Student s ON g.student_key = s.student_key
JOIN 
    DIM_Time t ON g.time_key = t.time_key
ORDER BY 
    s.student_key, t.time_key;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten

SELECT 
    s.student_name,
    t1.semester AS previous_semester,
    t2.semester AS current_semester,
    AVG(f1.grade_points) AS previous_gpa,
    AVG(f2.grade_points) AS current_gpa,
    (AVG(f2.grade_points) - AVG(f1.grade_points)) AS gpa_change
FROM DIM_Student s
JOIN FACT_Grade f1 ON s.student_key = f1.student_key
JOIN DIM_Time t1 ON f1.time_key = t1.time_key
JOIN FACT_Grade f2 ON s.student_key = f2.student_key
JOIN DIM_Time t2 ON f2.time_key = t2.time_key
WHERE t1.semester < t2.semester
GROUP BY s.student_key, s.student_name, t1.semester, t2.semester
ORDER BY s.student_name, t2.semester;


-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)

SELECT DISTINCT s.student_id, s.student_name
FROM FACT_Grade g1
JOIN FACT_Grade g2 ON g1.student_key = g2.student_key
JOIN DIM_Time t1 ON g1.time_key = t1.time_key
JOIN DIM_Time t2 ON g2.time_key = t2.time_key
JOIN DIM_Student s ON g1.student_key = s.student_key
WHERE g1.passed = FALSE
  AND g2.passed = FALSE
  AND t1.semester < t2.semester
  AND EXTRACT(YEAR FROM t1.full_date) = EXTRACT(YEAR FROM t2.full_date)
  AND EXTRACT(SEMESTER FROM t1.full_date) = EXTRACT(SEMESTER FROM t2.full_date) - 1;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)

SELECT 
    s.student_name,
    t.semester,
    c.course_name,
    c.credits,
    SUM(c.credits) OVER (PARTITION BY s.student_key ORDER BY t.time_key) AS cumulative_credits
FROM FACT_Grade fg
JOIN DIM_Student s ON fg.student_key = s.student_key
JOIN DIM_Time t ON fg.time_key = t.time_key
JOIN DIM_Course c ON fg.course_key = c.course_key
ORDER BY s.student_key, t.time_key;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse

SELECT 
    s.student_name,
    AVG(f.grade_points) AS average_grade
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
GROUP BY 
    s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten

SELECT 
    s.student_key,
    s.student_name,
    t.full_date,
    AVG(f.grade_points) OVER (
        PARTITION BY s.student_key 
        ORDER BY t.full_date 
        RANGE BETWEEN INTERVAL '1 semester' PRECEDING 
        AND CURRENT ROW
    ) AS moving_avg_gpa
FROM 
    FACT_Grade f
JOIN 
    DIM_Student s ON f.student_key = s.student_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    t.semester IN ('Fall', 'Spring')
ORDER BY 
    s.student_key, t.full_date;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten

SELECT s.student_name, AVG(f.grade_points) AS avg_grade
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
JOIN DIM_Time t ON f.time_key = t.time_key
WHERE t.full_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)

SELECT 
    s.student_name,
    g.grade_points,
    FIRST_VALUE(g.grade_points) OVER (PARTITION BY s.student_key ORDER BY g.time_key) AS first_grade_points
FROM 
    FACT_Grade g
JOIN 
    DIM_Student s ON g.student_key = s.student_key
ORDER BY 
    s.student_name, g.time_key;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)

SELECT 
    s.student_name,
    MAX(f.grade_points) AS best_grade,
    MIN(f.grade_points) AS worst_grade
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
GROUP BY 
    s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)

SELECT 
    d.faculty,
    d.major,
    d.year_of_study,
    AVG(f.grade_points) AS avg_gpa
FROM 
    DIM_Student d
JOIN 
    FACT_Grade f ON d.student_key = f.student_key
GROUP BY 
    ROLLUP (d.faculty, d.major, d.year_of_study);


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)

SELECT 
    d.department,
    c.difficulty_level,
    p.professor_name,
    COUNT(*) AS passed_courses
FROM FACT_Grade fg
JOIN DIM_Course c ON fg.course_key = c.course_key
JOIN DIM_Professor p ON fg.professor_key = p.professor_key
JOIN DIM_Time t ON fg.time_key = t.time_key
JOIN DIM_Student s ON fg.student_key = s.student_key
JOIN DIM_Course c2 ON c2.course_key = c.course_key
JOIN DIM_Professor p2 ON p2.professor_key = p.professor_key
WHERE fg.passed = TRUE
GROUP BY ROLLUP (c.difficulty_level, p.professor_name, d.department)
ORDER BY d.department, c.difficulty_level, p.professor_name;


-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT 
    dt.academic_year,
    dt.semester,
    AVG(f.grade_points) AS avg_gpa,
    GROUPING(dt.academic_year) AS g1,
    GROUPING(dt.semester) AS g2,
    GROUPING(dt.academic_year, dt.semester) AS g3
FROM FACT_Grade f
JOIN DIM_Time dt ON f.time_key = dt.time_key
GROUP BY ROLLUP(dt.academic_year, dt.semester)
ORDER BY dt.academic_year, dt.semester;


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19: Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)

SELECT p.professor_name, AVG(f.grade_points) AS avg_student_grade
FROM FACT_Grade f
JOIN DIM_Professor p ON f.professor_key = p.professor_key
JOIN DIM_Course c ON f.course_key = c.course_key
WHERE f.passed = TRUE
GROUP BY p.professor_key, p.professor_name
HAVING AVG(f.grade_points) > (SELECT AVG(grade_points) FROM FACT_Grade WHERE passed = TRUE);


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function

SELECT 
    s.student_name,
    c.course_name,
    AVG(f.grade_points) AS avg_grade,
    STDDEV(f.grade_points) AS grade_stddev
FROM 
    FACT_Grade f
JOIN 
    DIM_Student s ON f.student_key = s.student_key
JOIN 
    DIM_Course c ON f.course_key = c.course_key
GROUP BY 
    s.student_key, s.student_name, c.course_name
HAVING 
    STDDEV(f.grade_points) < 0.5;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)

SELECT 
    c.course_key,
    c.course_name,
    PERCENT_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS percent_above_average
FROM 
    DIM_Course c
JOIN 
    FACT_Grade f ON c.course_key = f.course_key
GROUP BY 
    c.course_key, c.course_name;


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
