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
-- ✅ KORREKT (Perfekt alle 3 Ranking Functions!)

SELECT student_key, student_name, AVG(grade_points) AS GPA, 
RANK() OVER (ORDER BY AVG(grade_points) DESC), 
DENSE_RANK() OVER (ORDER BY AVG(grade_points) DESC), 
ROW_NUMBER() OVER (ORDER BY AVG(grade_points) DESC)
FROM FACT_Grade
JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key
GROUP BY student_key, student_name
ORDER BY GPA DESC;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)
-- ❌ FEHLER: grade_points OHNE AVG! Braucht AVG(grade_points) + GROUP BY! Außerdem WHERE passed = TRUE filtert zu früh.

SELECT student_key, student_name, major, dense_rank() OVER (PARTITION BY major ORDER BY grade_points DESC) as rank_within_major FROM FACT_Grade INNER JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key WHERE passed = TRUE;

-- KORREKTUR:
-- SELECT 
--     s.student_key, 
--     s.student_name, 
--     s.major, 
--     DENSE_RANK() OVER (PARTITION BY s.major ORDER BY AVG(f.grade_points) DESC) as rank_within_major 
-- FROM FACT_Grade f
-- JOIN DIM_Student s ON f.student_key = s.student_key
-- GROUP BY s.student_key, s.student_name, s.major
-- ORDER BY s.major, rank_within_major;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)
-- ❌ FEHLER: WHERE rank <= 3 ist ungültig (rank ist Window Function Alias, muss CTE/Subquery sein)! Außerdem: ORDER BY student_key ist sinnlos (sollte GPA sein).

SELECT student_name, faculty, ROW_NUMBER() OVER(PARTITION BY faculty ORDER BY student_key) as rank FROM DIM_Student WHERE rank <= 3;

-- KORREKTUR:
-- WITH RankedStudents AS (
--     SELECT 
--         s.student_name, 
--         s.faculty, 
--         ROW_NUMBER() OVER(PARTITION BY s.faculty ORDER BY AVG(f.grade_points) DESC) as rank
--     FROM DIM_Student s
--     JOIN FACT_Grade f ON s.student_key = f.student_key
--     GROUP BY s.student_name, s.faculty
-- )
-- SELECT student_name, faculty, rank
-- FROM RankedStudents
-- WHERE rank <= 3
-- ORDER BY faculty, rank;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))
-- ❌ FEHLER: grade_points direkt in NTILE ohne AVG! Braucht AVG(grade_points) per Student!

SELECT student_key, student_name, NTILE(4) OVER (ORDER BY grade_points DESC) AS performance_quartile FROM FACT_Grade JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key;

-- KORREKTUR:
-- WITH StudentGPA AS (
--     SELECT 
--         s.student_key, 
--         s.student_name, 
--         AVG(f.grade_points) AS avg_gpa
--     FROM FACT_Grade f
--     JOIN DIM_Student s ON f.student_key = s.student_key
--     GROUP BY s.student_key, s.student_name
-- )
-- SELECT 
--     student_key, 
--     student_name, 
--     avg_gpa,
--     NTILE(4) OVER (ORDER BY avg_gpa DESC) AS performance_quartile 
-- FROM StudentGPA;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)
-- ❌ FEHLER: NTILE(10) über DIM_Student ohne grades! Braucht JOIN + AVG(grade_points)! WHERE in DIM_Student ist ungültig (kein NTILE dort).

SELECT student_key FROM DIM_Student WHERE NTILE(10) OVER () = 10;

-- KORREKTUR:
-- WITH StudentGPA AS (
--     SELECT 
--         s.student_key, 
--         s.student_name, 
--         AVG(f.grade_points) AS avg_gpa,
--         NTILE(10) OVER (ORDER BY AVG(f.grade_points) DESC) AS decile
--     FROM FACT_Grade f
--     JOIN DIM_Student s ON f.student_key = s.student_key
--     GROUP BY s.student_key, s.student_name
-- )
-- SELECT student_key, student_name, avg_gpa
-- FROM StudentGPA
-- WHERE decile = 1;  -- Dezil 1 ist Top 10%!


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)
-- ✅ KORREKT (Perfektes NTILE mit PARTITION BY!)

SELECT student_key, course_key, NTILE(5) OVER (PARTITION BY course_key ORDER BY grade_points DESC) AS performance_group FROM FACT_Grade;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)
-- ❌ FEHLER: Nutzt LEFT JOIN statt LAG! t1.semester - INTERVAL ist ungültig (semester ist VARCHAR, kein DATE)! t2 nicht definiert!

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

-- KORREKTUR mit LAG:
-- WITH GradeTrend AS (
--     SELECT 
--         s.student_name, 
--         t.semester, 
--         AVG(f.grade_points) AS current_grade_points,
--         LAG(AVG(f.grade_points)) OVER (PARTITION BY s.student_key ORDER BY t.semester) AS previous_grade_points
--     FROM DIM_Student s
--     JOIN FACT_Grade f ON s.student_key = f.student_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY s.student_name, s.student_key, t.semester
-- )
-- SELECT 
--     student_name, 
--     semester, 
--     current_grade_points, 
--     previous_grade_points,
--     CASE 
--         WHEN previous_grade_points IS NULL THEN 'First Semester'
--         WHEN current_grade_points > previous_grade_points THEN 'Verbessert' 
--         WHEN current_grade_points < previous_grade_points THEN 'Verschlechtert'
--         ELSE 'Unverändert'
--     END AS grade_trend
-- FROM GradeTrend
-- ORDER BY student_name, semester;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten
-- ❌ FEHLER: current_grade_points und previous_grade_points existieren nicht in FACT_Grade! Braucht LAG Window Function!

SELECT s.student_name,
       (f.current_grade_points - f.previous_grade_points) AS grade_point_change
FROM DIM_Student s
JOIN (
    SELECT student_key, MAX(grade_id) as max_grade_id
    FROM FACT_Grade
    GROUP BY student_key
) t ON s.student_key = t.student_key
JOIN FACT_Grade f ON t.max_grade_id = f.grade_id;

-- KORREKTUR mit LAG:
-- WITH SemesterGPA AS (
--     SELECT 
--         s.student_key,
--         s.student_name,
--         t.semester,
--         AVG(f.grade_points) AS current_gpa,
--         LAG(AVG(f.grade_points)) OVER (PARTITION BY s.student_key ORDER BY t.semester) AS previous_gpa
--     FROM DIM_Student s
--     JOIN FACT_Grade f ON s.student_key = f.student_key
--     JOIN DIM_Time t ON f.time_key = t.time_key
--     GROUP BY s.student_key, s.student_name, t.semester
-- )
-- SELECT 
--     student_name,
--     semester,
--     current_gpa - COALESCE(previous_gpa, 0) AS grade_point_change
-- FROM SemesterGPA
-- WHERE previous_gpa IS NOT NULL
-- ORDER BY student_name, semester;


-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)
-- ❌ FEHLER: LAG(grade_points, 1) = 0 prüft ob LAG-Wert 0 ist, NICHT ob gefallen! Logik ist falsch!

SELECT student_key FROM FACT_Grade WHERE grade_points < 2 AND LAG(grade_points, 1) OVER (PARTITION BY student_key ORDER BY time_key) = 0 AND LAG(grade_points, 2) OVER (PARTITION BY student_key ORDER BY time_key) = 0;

-- KORREKTUR:
-- WITH GradeTrends AS (
--     SELECT 
--         student_key,
--         time_key,
--         grade_points,
--         LAG(grade_points, 1) OVER (PARTITION BY student_key ORDER BY time_key) AS prev_grade_1,
--         LAG(grade_points, 2) OVER (PARTITION BY student_key ORDER BY time_key) AS prev_grade_2
--     FROM FACT_Grade
-- )
-- SELECT DISTINCT student_key
-- FROM GradeTrends
-- WHERE grade_points < prev_grade_1 AND prev_grade_1 < prev_grade_2
-- ORDER BY student_key;


-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)
-- ✅ KORREKT (Perfektes Running Total mit ROWS BETWEEN!)

SELECT student_key, SUM(credits) OVER (PARTITION BY student_key ORDER BY time_key ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_credits 
FROM FACT_Grade 
JOIN DIM_Course ON FACT_Grade.course_key = DIM_Course.course_key;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse
-- ❌ FEHLER: Nutzt GROUP BY statt Window Function! Zeigt nur Gesamt-AVG, NICHT laufenden Durchschnitt!

SELECT student_key, AVG(grade_points) AS running_average FROM FACT_Grade GROUP BY student_key ORDER BY student_key;

-- KORREKTUR mit Window Function:
-- SELECT 
--     student_key, 
--     time_key,
--     grade_points,
--     AVG(grade_points) OVER (
--         PARTITION BY student_key 
--         ORDER BY time_key 
--         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--     ) AS running_average 
-- FROM FACT_Grade
-- ORDER BY student_key, time_key;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten
-- ✅ KORREKT (Perfektes Moving Average mit ROWS BETWEEN!)

SELECT student_key, AVG(grade_points) OVER (PARTITION BY student_key ORDER BY time_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_semester_average FROM FACT_Grade;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten
-- ❌ FEHLER: Nutzt GROUP BY statt Window Function! Zeigt Gesamt-AVG über ALLE Kurse, NICHT nur letzte 5!

SELECT s.student_name, AVG(f.grade_points) AS average_grade FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key GROUP BY s.student_name ORDER BY s.student_name;

-- KORREKTUR mit Window Function:
-- SELECT 
--     s.student_name, 
--     f.grade_id,
--     f.time_key,
--     AVG(f.grade_points) OVER (
--         PARTITION BY s.student_key 
--         ORDER BY f.time_key 
--         ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
--     ) AS average_last_5_courses 
-- FROM DIM_Student s
-- JOIN FACT_Grade f ON s.student_key = f.student_key
-- ORDER BY s.student_name, f.time_key;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)
-- ❌ FEHLER: f.grade_points - FIRST_VALUE ist falsch (braucht aktuellen Wert minus ersten Wert)! Außerdem: zeigt ALLE Noten, nicht nur aktuellste.

SELECT s.student_name, f.grade_points - FIRST_VALUE(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.time_key ASC) AS current_grade_difference FROM DIM_Student s JOIN FACT_Grade f ON s.student_key = f.student_key;

-- KORREKTUR (nur aktuelle vs. erste Note):
-- WITH GradeComparison AS (
--     SELECT 
--         s.student_key,
--         s.student_name, 
--         f.time_key,
--         f.grade_points,
--         FIRST_VALUE(f.grade_points) OVER (PARTITION BY s.student_key ORDER BY f.time_key ASC) AS first_grade,
--         ROW_NUMBER() OVER (PARTITION BY s.student_key ORDER BY f.time_key DESC) AS rn
--     FROM DIM_Student s 
--     JOIN FACT_Grade f ON s.student_key = f.student_key
-- )
-- SELECT 
--     student_name, 
--     grade_points AS current_grade,
--     first_grade,
--     grade_points - first_grade AS grade_improvement
-- FROM GradeComparison
-- WHERE rn = 1
-- ORDER BY student_name;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)
-- ✅ KORREKT (Perfekte MIN/MAX Window Functions!)

SELECT student_key, MAX(grade_points) OVER (PARTITION BY student_key) AS best_grade,
       MIN(grade_points) OVER (PARTITION BY student_key) AS worst_grade
FROM FACT_Grade;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)
-- ❌ FEHLER: PostgreSQL Syntax ist GROUP BY ROLLUP(...), nicht GROUP BY ... WITH ROLLUP (MySQL)!

SELECT faculty, major, year_of_study, AVG(grade_points) AS average_gpa 
FROM FACT_Grade 
JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key 
GROUP BY faculty, major, year_of_study WITH ROLLUP;

-- KORREKTUR (PostgreSQL):
-- SELECT 
--     faculty, 
--     major, 
--     year_of_study, 
--     AVG(grade_points) AS average_gpa 
-- FROM FACT_Grade 
-- JOIN DIM_Student ON FACT_Grade.student_key = DIM_Student.student_key 
-- GROUP BY ROLLUP(faculty, major, year_of_study)
-- ORDER BY faculty, major, year_of_study;


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)
-- ❌ FEHLER: d.department ohne JOIN zu DIM_Course! d ist nicht definiert! Außerdem: WITH ROLLUP (MySQL) statt ROLLUP(...).

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

-- KORREKTUR:
-- SELECT 
--     c.department,
--     c.difficulty_level,
--     p.title AS professor_title,
--     COUNT(f.grade_id) AS course_count
-- FROM 
--     DIM_Professor p
-- JOIN 
--     FACT_Grade f ON p.professor_key = f.professor_key
-- JOIN 
--     DIM_Course c ON f.course_key = c.course_key
-- WHERE 
--     f.passed = TRUE
-- GROUP BY 
--     ROLLUP(c.department, c.difficulty_level, p.title)
-- ORDER BY 
--     c.department, c.difficulty_level, p.title;


-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)
-- ❌ FEHLER: Fehlt JOIN zu DIM_Time! academic_year und semester sind NICHT in FACT_Grade! Fehlt GROUPING() Funktion.

SELECT academic_year, semester, AVG(grade_points) AS average_gpa FROM FACT_Grade GROUP BY ROLLUP(academic_year, semester);

-- KORREKTUR:
-- SELECT 
--     t.academic_year, 
--     t.semester, 
--     AVG(f.grade_points) AS average_gpa,
--     GROUPING(t.academic_year) AS is_year_total,
--     GROUPING(t.semester) AS is_semester_total
-- FROM FACT_Grade f
-- JOIN DIM_Time t ON f.time_key = t.time_key
-- GROUP BY ROLLUP(t.academic_year, t.semester)
-- ORDER BY t.academic_year, t.semester;


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19: Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)
-- ⚠️ TEILWEISE: Subquery ist sinnlos (identisch zu WHERE ohne professor_key filter). Funktioniert aber grundsätzlich.

SELECT p.professor_name FROM DIM_Professor p JOIN FACT_Grade fg ON p.professor_key = fg.professor_key GROUP BY p.professor_name HAVING AVG(fg.grade_points) > (SELECT AVG(grade_points) FROM FACT_Grade WHERE professor_key IN (SELECT professor_key FROM FACT_Grade));

-- BESSERE LÖSUNG:
-- SELECT p.professor_name, AVG(fg.grade_points) AS professor_avg
-- FROM DIM_Professor p 
-- JOIN FACT_Grade fg ON p.professor_key = fg.professor_key 
-- GROUP BY p.professor_name 
-- HAVING AVG(fg.grade_points) > (SELECT AVG(grade_points) FROM FACT_Grade)
-- ORDER BY professor_avg DESC;


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function
-- ❌ FEHLER: Nutzt GROUP BY statt Window Function! Außerdem: GROUP BY student_key, semester ist zu granular (sollte nur student_key sein).

SELECT student_name FROM DIM_Student WHERE student_key IN (
    SELECT student_key 
    FROM FACT_Grade 
    GROUP BY student_key, semester 
    HAVING STDDEV(grade_points) < 0.5
);;

-- KORREKTUR mit Window Function:
-- WITH StudentStdDev AS (
--     SELECT 
--         student_key,
--         STDDEV(grade_points) OVER (PARTITION BY student_key) AS std_dev
--     FROM FACT_Grade
-- )
-- SELECT DISTINCT s.student_name, ssd.std_dev
-- FROM StudentStdDev ssd
-- JOIN DIM_Student s ON ssd.student_key = s.student_key
-- WHERE ssd.std_dev < 0.5
-- ORDER BY s.student_name;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)
-- 🚫 KOMPLETT FEHLEND! (Keine Antwort vom Model)

-- KORREKTUR:
-- WITH CourseStats AS (
--     SELECT 
--         course_key,
--         student_key,
--         grade_points,
--         AVG(grade_points) OVER (PARTITION BY course_key) AS course_avg,
--         PERCENT_RANK() OVER (PARTITION BY course_key ORDER BY grade_points) AS percentile_rank
--     FROM FACT_Grade
-- )
-- SELECT 
--     c.course_name,
--     COUNT(*) AS total_students,
--     SUM(CASE WHEN cs.grade_points > cs.course_avg THEN 1 ELSE 0 END) AS above_average,
--     ROUND(100.0 * SUM(CASE WHEN cs.grade_points > cs.course_avg THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_above_avg
-- FROM CourseStats cs
-- JOIN DIM_Course c ON cs.course_key = c.course_key
-- GROUP BY c.course_name
-- ORDER BY c.course_name;


-- ============================================================================
-- TEST RESULTS: qwen/qwen2.5-vl-7b
-- ============================================================================

-- SCORE: 33.3/100
-- SUCCESS RATE: 4/21 (19.0%)

-- BREAKDOWN:
-- ✅ Korrekt:  4 (Tasks 1, 6, 10, 12, 15)
-- ⚠️ Teilweise: 1 (Task 19)
-- ❌ Fehler:   15 (Tasks 2, 3, 4, 5, 7, 8, 9, 11, 13, 14, 16, 17, 18, 20)
-- 🚫 Failed:   1 (Task 21 - komplett fehlend)

-- STRENGTHS:
-- + RANK, DENSE_RANK, ROW_NUMBER korrekt (Task 1)
-- + NTILE mit PARTITION BY korrekt (Task 6)
-- + Running Totals korrekt (Task 10)
-- + Moving Averages korrekt (Task 12)
-- + MIN/MAX Window Functions korrekt (Task 15)

-- WEAKNESSES:
-- - LAG/LEAD komplett fehlerhaft (Tasks 7, 8, 9 - nutzt JOIN statt Window Functions)
-- - ROLLUP Syntax falsch (WITH ROLLUP ist MySQL, nicht PostgreSQL)
-- - Fehlende JOINs (Tasks 17, 18)
-- - GROUP BY statt Window Functions (Tasks 11, 13, 20)
-- - WHERE mit Window Function Alias (Task 3 - ungültig)
-- - NTILE ohne Aggregation (Tasks 4, 5)
-- - FIRST_VALUE Logik falsch (Task 14 - zeigt alle Rows statt nur aktuellste)
-- - Komplett fehlende Aufgabe (Task 21)

-- CRITICAL ERRORS:
-- - Tasks 7, 8, 9: LAG/LEAD nicht verwendet (Aufgabe explizit verlangt!)
-- - Tasks 16, 17, 18: ROLLUP Syntax ist MySQL, nicht PostgreSQL!
-- - Task 21: Komplett fehlend!
-- - Task 3: WHERE mit Window Function Alias ist syntaktisch ungültig!
-- - Tasks 4, 5: NTILE über einzelne Grades statt über Student-GPA!

-- RECOMMENDATION:
-- ⚠️ SCHWACH für Window Functions!
-- Das 7B Model versteht einfache Window Functions (RANK, NTILE, SUM/AVG),
-- scheitert aber bei:
-- - LAG/LEAD (0% Success)
-- - FIRST_VALUE Logik (0% Success)
-- - ROLLUP Syntax (0% Success - MySQL statt PostgreSQL)
-- - Komplexe Logik (fehlende CTEs, falsche WHERE Clauses)
-- Nur 19.0% Success Rate - NICHT Production-Ready!

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
