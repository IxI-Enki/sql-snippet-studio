-- ============================================================================
-- TEST 9: EDUCATION SYSTEM - ALL WINDOW FUNCTIONS + ROLLUP
-- ============================================================================
-- Domain: Bildungssystem (Schule/Universität)
-- Complexity: 🔴 Advanced
-- Focus: Alle Window Function Typen, ROLLUP, komplexe Analysen
-- Test Coverage: Complete Window Function Suite, NTILE, ROLLUP, Rankings
-- ============================================================================

-- Dieser Test wurde mit dem Modell qwen/qwen3-4b-2507 getestet.

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

-- ✅ PERFEKT (Score: 100/100)
--    Alle 3 Ranking-Funktionen korrekt verwendet!
--    Gruppierung und Sortierung perfekt!

SELECT 
    s.student_name,
    AVG(f.grade_points) AS gpa,
    RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS rank_rank,
    DENSE_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY AVG(f.grade_points) DESC) AS row_number
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
GROUP BY 
    s.student_key, s.student_name
ORDER BY 
    gpa DESC;


-- Aufgabe 2: Ranke Studenten innerhalb ihres Studiengangs nach GPA (DENSE_RANK mit PARTITION BY major)

-- ❌ FAILED (Score: 30/100)
--    FEHLT: DENSE_RANK Window Function komplett!
--    Query zeigt nur Studenten sortiert, kein Ranking!

SELECT 
    s.student_name,
    s.major,
    AVG(f.grade_points) AS avg_gpa
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
GROUP BY 
    s.student_key, s.student_name, s.major
ORDER BY 
    s.major, avg_gpa DESC;


-- Aufgabe 3: Finde die Top 3 Studenten pro Fakultät (verwende ROW_NUMBER mit PARTITION BY faculty)

SELECT 
    s.student_name,
    s.faculty
FROM 
    DIM_Student s
ORDER BY 
    s.faculty, 
    s.student_name DESC
LIMIT 3;


-- ============================================================================
-- TEST TASKS - NTILE (QUARTILES/PERCENTILES)
-- ============================================================================

-- Aufgabe 4: Teile alle Studenten in 4 Performance-Quartile basierend auf ihrem GPA (verwende NTILE(4))

SELECT 
    s.student_name,
    NTILE(4) OVER (ORDER BY fg.grade_points DESC) AS performance_quartile
FROM 
    DIM_Student s
JOIN 
    FACT_Grade fg ON s.student_key = fg.student_key
ORDER BY 
    fg.grade_points DESC;


-- Aufgabe 5: Identifiziere die Top 10 Prozent der Studenten (verwende NTILE(10) und filtere auf Dezil 10)

SELECT 
    s.student_name,
    s.year_of_study,
    g.grade_points,
    g.percentage,
    g.letter_grade
FROM 
    DIM_Student s
JOIN 
    FACT_Grade g ON s.student_key = g.student_key
WHERE 
    g.grade_points = (
        SELECT 
            PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY grade_points)
        FROM 
            FACT_Grade
    )
ORDER BY 
    g.grade_points DESC
LIMIT 10;


-- Aufgabe 6: Teile Studenten pro Kurs in 5 Performance-Gruppen (NTILE(5) mit PARTITION BY course)

SELECT 
    c.course_code,
    s.student_name,
    NTILE(5) OVER (PARTITION BY c.course_code ORDER BY f.grade_points) AS performance_group
FROM 
    FACT_Grade f
JOIN 
    DIM_Student s ON f.student_key = s.student_key
JOIN 
    DIM_Course c ON f.course_key = c.course_key;


-- ============================================================================
-- TEST TASKS - LAG & LEAD (TREND ANALYSIS)
-- ============================================================================

-- Aufgabe 7: Zeige für jeden Studenten die Notenentwicklung über die Semester mit Vergleich zum vorherigen Semester (verwende LAG)

SELECT 
    s.student_name,
    t.semester,
    g.grade_points,
    LAG(g.grade_points) OVER (PARTITION BY s.student_key ORDER BY t.time_key) AS previous_semester_grade
FROM DIM_Student s
JOIN FACT_Grade g ON s.student_key = g.student_key
JOIN DIM_Time t ON g.time_key = t.time_key
ORDER BY s.student_key, t.time_key;


-- Aufgabe 8: Berechne die Veränderung des GPA vom vorherigen zum aktuellen Semester für jeden Studenten
!!!! FAILED TO GENERATE !!!

-- Aufgabe 9: Identifiziere Studenten deren Note in mindestens 2 aufeinanderfolgenden Semestern gefallen ist (verwende LAG zweimal)

!!! FAILED TO GENERATE !!!
-- ============================================================================
-- TEST TASKS - RUNNING TOTALS & CUMULATIVE
-- ============================================================================

-- Aufgabe 10: Berechne die kumulativen Credits die jeder Student über die Semester erreicht hat (Running Total)

SELECT 
    s.student_id,
    s.student_name,
    SUM(c.credits) AS cumulative_credits
FROM 
    DIM_Student s
JOIN 
    FACT_Grade fg ON s.student_key = fg.student_key
JOIN 
    DIM_Course c ON fg.course_key = c.course_key
JOIN 
    DIM_Time t ON fg.time_key = t.time_key
GROUP BY 
    s.student_id, s.student_name
ORDER BY 
    s.student_id, t.full_date;


-- Aufgabe 11: Berechne den laufenden Durchschnitt der Noten für jeden Studenten über alle Kurse

SELECT 
    s.student_id, 
    s.student_name, 
    AVG(f.grade_points) AS average_grade
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
GROUP BY 
    s.student_id, 
    s.student_name;


-- ============================================================================
-- TEST TASKS - MOVING AVERAGES
-- ============================================================================

-- Aufgabe 12: Berechne den 3-Semester Moving Average des GPA für jeden Studenten

SELECT 
    s.student_id,
    AVG(f.grade_points) AS moving_average_gpa
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    t.semester LIKE '%Semester%'
GROUP BY 
    s.student_id
ORDER BY 
    s.student_id;


-- Aufgabe 13: Berechne die durchschnittliche Kursnote der letzten 5 Kurse für jeden Studenten

SELECT 
    s.student_name,
    AVG(f.grade_points) AS average_grade
FROM 
    DIM_Student s
JOIN 
    FACT_Grade f ON s.student_key = f.student_key
JOIN 
    DIM_Time t ON f.time_key = t.time_key
WHERE 
    t.academic_year IN (
        SELECT academic_year 
        FROM DIM_Time 
        ORDER BY full_date DESC 
        LIMIT 5
    )
GROUP BY 
    s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - FIRST_VALUE & LAST_VALUE
-- ============================================================================

-- Aufgabe 14: Vergleiche die aktuelle Note jedes Studenten mit seiner ersten Note (FIRST_VALUE)

SELECT 
    s.student_name,
    c.course_code,
    g.grade_points,
    FIRST_VALUE(g.grade_points) OVER (PARTITION BY s.student_key ORDER BY g.time_key) AS first_grade_points
FROM FACT_Grade g
JOIN DIM_Student s ON g.student_key = s.student_key
JOIN DIM_Course c ON g.course_key = c.course_key
ORDER BY s.student_key, c.course_code;


-- Aufgabe 15: Zeige für jeden Studenten die beste und schlechteste Note die er je erreicht hat (MAX und MIN als Window Functions)

SELECT 
    s.student_name,
    MAX(f.grade_points) AS best_grade,
    MIN(f.grade_points) AS worst_grade
FROM DIM_Student s
JOIN FACT_Grade f ON s.student_key = f.student_key
GROUP BY s.student_key, s.student_name;


-- ============================================================================
-- TEST TASKS - ROLLUP (HIERARCHICAL REPORTING)
-- ============================================================================

-- Aufgabe 16: Berechne den durchschnittlichen GPA mit hierarchischen Subtotals nach Fakultät, Studiengang und Jahr (verwende ROLLUP)

SELECT 
    faculty,
    major,
    year_of_study,
    AVG(grade_points) AS avg_gpa
FROM 
    DIM_Student
JOIN 
    FACT_Grade ON DIM_Student.student_key = FACT_Grade.student_key
GROUP BY 
    faculty, major, year_of_study WITH ROLLUP;


-- Aufgabe 17: Berechne die Anzahl der bestandenen Kurse mit Subtotals nach Department, Difficulty Level und Professor (ROLLUP)

SELECT 
    department,
    difficulty_level,
    professor_name,
    COUNT(*) AS passed_courses
FROM 
    FACT_Grade fg
JOIN 
    DIM_Course dc ON fg.course_key = dc.course_key
JOIN 
    DIM_Professor dp ON fg.professor_key = dp.professor_key
GROUP BY 
    department, 
    difficulty_level, 
    professor_name WITH ROLLUP;


-- Aufgabe 18: Erstelle einen Bericht mit dem durchschnittlichen GPA nach Academic Year, Semester mit Grand Total (ROLLUP mit GROUPING Funktion)

SELECT 
    academic_year,
    semester,
    AVG(grade_points) AS avg_gpa,
    COUNT(*) AS total_grades
FROM 
    FACT_Grade
JOIN 
    DIM_Time ON FACT_Grade.time_key = DIM_Time.time_key
GROUP BY 
    academic_year, 
    semester WITH ROLLUP;


-- ============================================================================
-- TEST TASKS - ADVANCED ANALYTICS
-- ============================================================================

-- Aufgabe 19: Identifiziere Professoren deren Studenten überdurchschnittlich gut abschneiden (Vergleich zum Gesamtdurchschnitt des Kurses)

SELECT 
    p.professor_name,
    c.course_code,
    AVG(f.grade_points) AS avg_grade_points
FROM 
    DIM_Professor p
JOIN 
    FACT_Grade f ON p.professor_key = f.professor_key
JOIN 
    DIM_Course c ON f.course_key = c.course_key
GROUP BY 
    p.professor_name, c.course_code
HAVING 
    AVG(f.grade_points) > (SELECT AVG(grade_points) FROM FACT_Grade fg JOIN DIM_Course cc ON fg.course_key = cc.course_key);


-- Aufgabe 20: Finde Studenten die konsistente Performance zeigen (Standardabweichung der Noten < 0.5) - verwende STDDEV als Window Function

SELECT 
    s.student_id,
    s.student_name,
    STDDEV(grade_points) AS grade_stddev
FROM 
    DIM_Student s
JOIN 
    FACT_Grade fg ON s.student_key = fg.student_key
GROUP BY 
    s.student_key, s.student_id, s.student_name
HAVING 
    STDDEV(grade_points) < 0.5;


-- Aufgabe 21: Berechne für jeden Kurs wie viel Prozent der Studenten über dem Kursdurchschnitt liegen (PERCENT_RANK)

SELECT 
    c.course_code,
    c.course_name,
    PERCENT_RANK() OVER (ORDER BY AVG(f.grade_points) DESC) AS percent_rank
FROM 
    DIM_Course c
JOIN 
    FACT_Grade f ON c.course_key = f.course_key
GROUP BY 
    c.course_key, c.course_code, c.course_name;


-- ============================================================================
-- TEST RESULTS: qwen/qwen3-4b-2507
-- ============================================================================
-- GESAMTSCORE: 49.0/100 ⭐⭐
-- SUCCESS RATE: 23.8% (5/21 tasks korrekt)
-- 
-- AUFGABE BREAKDOWN (KURZFASSUNG):
--   ✅ Aufgabe 1:  100/100 - RANK, DENSE_RANK, ROW_NUMBER perfekt
--   ❌ Aufgabe 2:   30/100 - Fehlt DENSE_RANK komplett
--   ❌ Aufgabe 3:   20/100 - Fehlt ROW_NUMBER + PARTITION BY
--   ✅ Aufgabe 4:  100/100 - NTILE(4) perfekt
--   ❌ Aufgabe 5:   40/100 - PERCENTILE_CONT statt NTILE(10)
--   ✅ Aufgabe 6:  100/100 - NTILE(5) mit PARTITION BY perfekt
--   ✅ Aufgabe 7:  100/100 - LAG mit PARTITION BY perfekt
--   ❌ Aufgabe 8:    0/100 - NICHT generiert!
--   ❌ Aufgabe 9:    0/100 - NICHT generiert!
--   ❌ Aufgabe 10:  25/100 - Fehlt ROWS UNBOUNDED PRECEDING
--   ❌ Aufgabe 11:  25/100 - Fehlt ROWS UNBOUNDED PRECEDING
--   ❌ Aufgabe 12:  25/100 - Fehlt ROWS BETWEEN (nur WHERE)
--   ❌ Aufgabe 13:  30/100 - Fehlt ROWS BETWEEN (nur Subquery)
--   ✅ Aufgabe 14: 100/100 - FIRST_VALUE perfekt
--   ❌ Aufgabe 15:  30/100 - MAX/MIN ohne OVER
--   ❌ Aufgabe 16:  40/100 - MySQL Syntax (WITH ROLLUP)
--   ❌ Aufgabe 17:  40/100 - MySQL Syntax (WITH ROLLUP)
--   ❌ Aufgabe 18:  40/100 - MySQL Syntax + fehlt GROUPING()
--   ❌ Aufgabe 19:  40/100 - Subquery statt Window Function
--   ⚠️ Aufgabe 20:  70/100 - STDDEV ohne OVER
--   ⚠️ Aufgabe 21:  60/100 - PERCENT_RANK falsch angewendet
--
-- STÄRKEN:
--   + Einfache Rankings ohne PARTITION BY: PERFEKT (RANK, DENSE_RANK, ROW_NUMBER)
--   + NTILE ohne PARTITION BY: PERFEKT
--   + NTILE mit PARTITION BY: PERFEKT (endlich!)
--   + LAG mit PARTITION BY: PERFEKT
--   + FIRST_VALUE: PERFEKT
--
-- SCHWÄCHEN:
--   - ROWS BETWEEN: KOMPLETT MISSVERSTANDEN (0% bei Moving Averages!)
--   - ROWS UNBOUNDED PRECEDING: FEHLT (verwendet nur SUM/AVG)
--   - ROLLUP: Inkonsistent (MySQL Syntax)
--   - Window Functions "PRO X": MANCHMAL vergessen
--   - MAX/MIN als Window Function: NICHT VERSTANDEN
--
-- KRITISCHE FEHLER:
--   ⚠️ ROWS BETWEEN für Moving Averages: FEHLT KOMPLETT!
--   ⚠️ Running Totals: Fehlt ROWS UNBOUNDED PRECEDING
--   ⚠️ ROLLUP: Immer noch MySQL Syntax (WITH ROLLUP)
--   ⚠️ PERCENT_RANK: Falsch verwendet (über Kurse statt Studenten)
--
-- EMPFEHLUNG: ⚠️ BEDINGT geeignet für Window Functions
--              Gut für: Einfache Rankings, NTILE, LAG, FIRST_VALUE
--              NICHT für: Moving Averages, Running Totals mit Frames, ROLLUP
-- ============================================================================
