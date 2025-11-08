-- ============================================================================
-- TEST 9: EDUCATION SYSTEM - ALL WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Bildungssystem (Schule/Universität)
-- Complexity: 🔴 Advanced
-- Focus: Alle Window Function Typen, ROLLUP, komplexe Analysen
-- Test Coverage: Complete Window Function Suite, NTILE, ROLLUP, Rankings
-- ============================================================================

-- Dieser Test wurde mit dem Model qwen3-coder-30b-a3b-instruct getestet.

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
    RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS rank_gpa,
    DENSE_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS dense_rank_gpa,
    ROW_NUMBER() OVER (ORDER BY AVG(f.grade_points) DESC) AS row_num_gpa
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
GROUP BY s.student_key, s.student_name
ORDER BY gpa DESC;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)

SELECT 
    s.student_name,
    s.major,
    AVG(f.grade_points) AS gpa,
    DENSE_RANK() OVER (PARTITION BY s.major ORDER BY AVG(f.grade_points) DESC) AS rank_in_major
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
GROUP BY s.student_key, s.student_name, s.major;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)

SELECT student_name, faculty, grade_points
FROM (
    SELECT s.student_name, s.faculty, f.grade_points,
           ROW_NUMBER() OVER (PARTITION BY s.faculty ORDER BY f.grade_points DESC) AS row_num
    FROM DIM_Student s
    JOIN FACT_Grade f ON s.student_key = f.student_key
) ranked
WHERE row_num <= 3;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))

SELECT 
    s.student_name,
    s.student_id,
    AVG(f.grade_points) AS gpa,
    NTILE(4) OVER (ORDER BY AVG(f.grade_points) DESC) AS performance_quartile
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
GROUP BY s.student_key, s.student_name, s.student_id
ORDER BY gpa DESC;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)

SELECT 
    s.student_key,
    s.student_id,
    s.student_name,
    AVG(f.grade_points) AS avg_gpa
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
GROUP BY s.student_key, s.student_id, s.student_name
ORDER BY avg_gpa DESC
LIMIT (
    SELECT COUNT(*) * 0.1 FROM DIM_Student
);


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)

SELECT 
    c.course_name,
    s.student_name,
    NTILE(5) OVER (PARTITION BY c.course_key ORDER BY f.grade_points DESC) AS performance_group
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Course c ON f.course_key = c.course_key
ORDER BY c.course_name, performance_group, s.student_name;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)

SELECT 
    s.student_name,
    t.semester,
    f.grade_points,
    LAG(f.grade_points) OVER (
        PARTITION BY s.student_key 
        ORDER BY t.time_key
    ) AS previous_semester_grade
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.student_key, t.time_key;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten


SELECT 
    s.student_key,
    s.student_name,
    t.semester,
    AVG(f.grade_points) AS current_gpa,
    LAG(AVG(f.grade_points)) OVER (PARTITION BY s.student_key ORDER BY t.time_key) AS previous_gpa,
    AVG(f.grade_points) - LAG(AVG(f.grade_points)) OVER (PARTITION BY s.student_key ORDER BY t.time_key) AS gpa_change
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Time t ON f.time_key = t.time_key
GROUP BY s.student_key, s.student_name, t.semester, t.time_key
ORDER BY s.student_key, t.time_key;

-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)

SELECT DISTINCT g1.student_key
FROM FACT_Grade g1
JOIN DIM_Time t1 ON g1.time_key = t1.time_key
JOIN FACT_Grade g2 ON g1.student_key = g2.student_key
JOIN DIM_Time t2 ON g2.time_key = t2.time_key
WHERE t1.full_date < t2.full_date
  AND g1.grade_points < LAG(g1.grade_points) OVER (PARTITION BY g1.student_key ORDER BY t1.full_date)
  AND g2.grade_points < LAG(g2.grade_points) OVER (PARTITION BY g2.student_key ORDER BY t2.full_date);


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)

SELECT 
    s.student_key,
    s.student_name,
    t.full_date,
    SUM(c.credits) OVER (
        PARTITION BY s.student_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_credits
FROM FACT_Grade fg
JOIN DIM_Student s ON fg.student_key = s.student_key
JOIN DIM_Course c ON fg.course_key = c.course_key
JOIN DIM_Time t ON fg.time_key = t.time_key
ORDER BY s.student_key, t.full_date;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse

SELECT 
    s.student_key,
    s.student_name,
    c.course_name,
    f.grade_points,
    AVG(f.grade_points) OVER (
        PARTITION BY s.student_key 
        ORDER BY t.full_date 
        ROWS UNBOUNDED PRECEDING
    ) AS running_average_grade
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Course c ON f.course_key = c.course_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.student_key, t.full_date;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten

SELECT 
    s.student_key,
    t.full_date,
    AVG(f.grade_points) OVER (
        PARTITION BY s.student_key 
        ORDER BY t.full_date 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_gpa
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.student_key, t.full_date;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten

SELECT 
    s.student_key,
    s.student_name,
    AVG(f.grade_points) AS average_grade
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
WHERE f.course_key IN (
    SELECT course_key
    FROM FACT_Grade fg
    JOIN DIM_Course c ON fg.course_key = c.course_key
    ORDER BY c.course_code DESC
    LIMIT 5
)
GROUP BY s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)

SELECT 
    s.student_name,
    c.course_name,
    f.grade_points AS current_grade,
    FIRST_VALUE(f.grade_points) OVER (
        PARTITION BY s.student_key, c.course_key 
        ORDER BY t.full_date
    ) AS first_grade
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
JOIN DIM_Course c ON f.course_key = c.course_key
JOIN DIM_Time t ON f.time_key = t.time_key
ORDER BY s.student_name, c.course_name, t.full_date;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)

SELECT DISTINCT 
    s.student_name,
    FIRST_VALUE(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.grade_points DESC) AS best_grade,
    FIRST_VALUE(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.grade_points ASC) AS worst_grade
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)

SELECT 
    s.faculty,
    s.major,
    s.year_of_study,
    AVG(f.grade_points) AS average_gpa
FROM FACT_Grade f
JOIN DIM_Student s ON f.student_key = s.student_key
GROUP BY ROLLUP(s.faculty, s.major, s.year_of_study)
ORDER BY s.faculty, s.major, s.year_of_study;


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)

SELECT 
    COALESCE(d.department, 'Total') AS department,
    COALESCE(c.difficulty_level, 'All Levels') AS difficulty_level,
    COALESCE(p.professor_name, 'All Professors') AS professor_name,
    COUNT(*) AS course_count
FROM FACT_Grade f
JOIN DIM_Course c ON f.course_key = c.course_key
JOIN DIM_Professor p ON f.professor_key = p.professor_key
JOIN DIM_Student s ON f.student_key = s.student_key
WHERE f.passed = TRUE
GROUP BY ROLLUP(d.department, c.difficulty_level, p.professor_name)
ORDER BY department, difficulty_level, professor_name;


-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT 
    dt.academic_year,
    dt.semester,
    AVG(fg.grade_points) AS average_gpa,
    GROUPING(dt.academic_year) + GROUPING(dt.semester) AS is_rollup
FROM FACT_Grade fg
JOIN DIM_Time dt ON fg.time_key = dt.time_key
GROUP BY ROLLUP(dt.academic_year, dt.semester)
ORDER BY dt.academic_year, dt.semester;


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19 : Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)

SELECT DISTINCT dp.professor_name
FROM FACT_Grade fg
JOIN DIM_Professor dp ON fg.professor_key = dp.professor_key
WHERE fg.grade_points > (
    SELECT AVG(grade_points)
    FROM FACT_Grade
    WHERE course_key = fg.course_key
);


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function

SELECT DISTINCT s.student_name
FROM DIM_Student s
JOIN FACT_Grade fg ON s.student_key = fg.student_key
GROUP BY s.student_key, s.student_name
HAVING STDDEV(fg.grade_points) < 0.5;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)

SELECT 
    c.course_code,
    c.course_name,
    COUNT(*) AS student_count,
    PERCENT_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) * 100 AS percent_rank_above_avg
FROM FACT_Grade f
JOIN DIM_Course c ON f.course_key = c.course_key
GROUP BY c.course_code, c.course_name
ORDER BY percent_rank_above_avg;


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
