-- ============================================================================
-- TEST 9: EDUCATION SYSTEM - ALL WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Bildungssystem (Schule/Universität)
-- Complexity: 🔴 Advanced
-- Focus: Alle Window Function Typen, ROLLUP, komplexe Analysen
-- Test Coverage: Complete Window Function Suite, NTILE, ROLLUP, Rankings
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen2.5-vl-7b getestet.

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

SELECT student_key, student_name, AVG(grade_points) AS GPA, 
RANK() OVER (ORDER BY AVG(grade_points) DESC), 
DENSE_RANK() OVER (ORDER BY AVG(grade_points) DESC), 
ROW_NUMBER() OVER (ORDER BY AVG(grade_points) DESC)
FROM FACT_Grade
JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key
GROUP BY student_key, student_name
ORDER BY GPA DESC;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)

SELECT student_key, student_name, major, dense_rank() OVER (PARTITION BY major ORDER BY grade_points DESC) as rank_within_major FROM FACT_Grade INNER JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key WHERE passed = TRUE;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)

SELECT student_name, faculty, ROW_NUMBER() OVER(PARTITION BY faculty ORDER BY student_key) as rank FROM DIM_Student WHERE rank <= 3;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))

SELECT student_key, student_name, NTILE(4) OVER (ORDER BY grade_points DESC) AS performance_quartile FROM FACT_Grade JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)

SELECT student_key FROM DIM_Student WHERE NTILE(10) OVER () = 10;


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)

SELECT student_key, course_key, NTILE(5) OVER (PARTITION BY course_key ORDER BY grade_points DESC) AS performance_group FROM FACT_Grade;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)

SELECT s.student_name, t1.semester, t1.grade_points AS current_grade_points, 
       COALESCE(t2.grade_points, 0) AS previous_grade_points,
       CASE WHEN t1.grade_points > t2.grade_points THEN 'Verbessert' 
            WHEN t1.grade_points < t2.grade_points THEN 'Verschlechtert'
            ELSE 'Unverändert'
       END AS grade_trend
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
JOIN DIM_Time t1 ON f.time_key = t1.time_key
LEFT JOIN FACT_Grade f2 ON s.student_key = f2.student_key AND t1.semester - INTERVAL '1 semester' = f2.time_key
WHERE t1.semester >= 'Fall 2024'
GROUP BY s.student_name, t1.semester, COALESCE(t2.grade_points, 0)
ORDER BY s.student_name, t1.semester;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten

SELECT s.student_name,
       (f.current_grade_points - f.previous_grade_points) AS grade_point_change
FROM DIM_Student s
JOIN (
    SELECT student_key, MAX(grade_id) as max_grade_id
    FROM FACT_Grade
    GROUP BY student_key
) t ON s.student_key = t.student_key
JOIN FACT_Grade f ON t.max_grade_id = f.grade_id;


-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)

SELECT student_key FROM FACT_Grade WHERE grade_points < 2 AND LAG(grade_points, 1) OVER (PARTITION BY student_key ORDER BY time_key) = 0 AND LAG(grade_points, 2) OVER (PARTITION BY student_key ORDER BY time_key) = 0;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)

SELECT student_key, SUM(credits) OVER (PARTITION BY student_key ORDER BY time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_credits 
FROM FACT_Grade 
JOIN DIM_Course ON FACT_Grade.course_key = DIM_Course.course_key;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse

SELECT student_key, AVG(grade_points) AS running_average FROM FACT_Grade GROUP BY student_key ORDER BY student_key;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten

SELECT student_key, AVG(grade_points) OVER (PARTITION BY student_key ORDER BY time_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_semester_average FROM FACT_Grade;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten

SELECT s.student_name, AVG(f.grade_points) AS average_grade FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key GROUP BY s.student_name ORDER BY s.student_name;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)

SELECT s.student_name, f.grade_points - FIRST_VALUE(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.time_key ASC) AS current_grade_difference FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)

SELECT student_key, MAX(grade_points) OVER (PARTITION BY student_key) AS best_grade,
       MIN(grade_points) OVER (PARTITION BY student_key) AS worst_grade
FROM FACT_Grade;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)

SELECT faculty, major, year_of_study, AVG(grade_points) AS average_gpa 
FROM FACT_Grade 
JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key 
GROUP BY faculty, major, year_of_study WITH ROLLUP;


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)

SELECT 
    d.department,
    c.difficulty_level,
    p.title AS professor_title,
    COUNT(f.grade_id) AS course_count
FROM 
    DIM_Professor p
JOIN 
    FACT_Grade f ON p.professor_key = f.professor_key
JOIN 
    DIM_Course c ON f.course_key = c.course_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    f.passed = TRUE
GROUP BY 
    d.department, c.difficulty_level, p.title WITH ROLLUP;


-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT academic_year, semester, AVG(grade_points) AS average_gpa FROM FACT_Grade GROUP BY ROLLUP(academic_year, semester);


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19: Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)

SELECT p.professor_name FROM DIM_Professor p JOIN FACT_Grade fg ON p.professor_key = fg.professor_key GROUP BY p.professor_name HAVING AVG(fg.grade_points) > (SELECT AVG(grade_points) FROM FACT_Grade WHERE professor_key IN (SELECT professor_key FROM FACT_Grade));


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function

SELECT student_name FROM DIM_Student WHERE student_key IN (
    SELECT student_key 
    FROM FACT_Grade 
    GROUP BY student_key, semester 
    HAVING STDDEV(grade_points) < 0.5
);;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)


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
