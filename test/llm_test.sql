-- Demo
-- ════════════════════════════════════════════════════════
-- Lehrer-Angabe: Bibliotheksverwaltung
-- ════════════════════════════════════════════════════════

-- Datenbank-Schema
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_year INTEGER
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(200),
    isbn VARCHAR(20),
    publication_year INTEGER,
    author_id INTEGER,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

CREATE TABLE members (
    member_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    join_date DATE
);

CREATE TABLE loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INTEGER,
    member_id INTEGER,
    loan_date DATE,
    return_date DATE,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (member_id) REFERENCES members(member_id)
);

-- ════════════════════════════════════════════════════════
-- AUFGABEN
-- ════════════════════════════════════════════════════════

-- Aufgabe 1: finde alle bücher die nach dem jahr 2000 veröffentlicht wurden

-- Aufgabe 2: Zeige alle Autoren mit ihren Büchern (auch Autoren ohne Bücher)

-- Aufgabe: Autoren ohne Bücher:

-- Aufgabe: Autoren mit Büchern:

SELECT a.first_name, a.last_name, b.title 
FROM authors a 
JOIN books b ON a.author_id = b.author_id;

-- Aufgabe 3: Finde alle Mitglieder die aktuell Bücher ausgeliehen haben

SELECT m.first_name, m.last_name 
FROM members m 
JOIN loans l ON m.member_id = l.member_id 
WHERE l.return_date IS NULL;

-- Aufgabe 4: erstelle eine abfrage die die anzahl der bücher pro autor zeigt

-- Aufgabe 5: finde das meistgeliehene buch

SELECT b.title AS book_title
FROM books b
JOIN loans l ON b.book_id = l.book_id
GROUP BY b.book_id
ORDER BY COUNT(l.loan_id) DESC
LIMIT 1;


-- Aufgabe 6: Zeige alle überfälligen Ausleihen (return_date < heute und noch nicht zurückgegeben)









-- ════════════════════════════════════════════════════════
-- USAGE INSTRUCTIONS:
-- ════════════════════════════════════════════════════════
-- 1. Enable LLM in settings:
--    File > Preferences > Settings
--    Search for "DBI Survival Kit"
--    Enable "Llm: Enabled"
--
-- 2. Configure your LLM endpoint:
--    - For local LM Studio: http://localhost:1234/v1/chat/completions
--    - For OpenAI API: https://api.openai.com/v1/chat/completions
--
-- 3. Position cursor after a task comment (e.g., after "Aufgabe 1:")
--
-- 4. Press Ctrl+Space or just start typing
--
-- 5. Select the "🤖 AI: ..." suggestion
--
-- 6. TA-DA! The query appears as if it's normal tab-completion!
-- ════════════════════════════════════════════════════════
