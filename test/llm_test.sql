-- ════════════════════════════════════════════════════════
-- DBI Test: LLM-Assisted Completion Demo
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

-- Aufgabe 1: Finde alle Bücher die nach dem Jahr 2000 veröffentlicht wurden

SELECT * FROM books WHERE publication_year > 2000;


-- Aufgabe 2: Zeige alle Autoren mit ihren Büchern (auch Autoren ohne Bücher

SELECT * FROM authors LEFT JOIN books ON authors.author_id = books.author_id;

-- Aufgabe 3: Finde alle Mitglieder die aktuell Bücher ausgeliehen haben

SELECT * FROM members LEFT JOIN loans ON members.member_id = loans.member_id WHERE loans.return_date IS NULL;

-- Aufgabe 4: Erstelle eine Abfrage die die Anzahl der Bücher pro Autor zeigt

SELECT authors.author_id, COUNT(books.book_id) AS book_count FROM authors LEFT JOIN books ON authors.author_id = books.author_id GROUP BY authors.author_id;

-- Aufgabe 5: Finde das meistgeliehene Buch

SELECT books.book_id, COUNT(loans.loan_id) AS loan_count FROM books LEFT JOIN loans ON books.book_id = loans.book_id GROUP BY books.book_id ORDER BY loan_count DESC LIMIT 1;

-- Aufgabe 6: Zeige alle überfälligen Ausleihen (return_date < heute und noch nicht zurückgegeben)

SELECT * FROM loans WHERE return_date < CURRENT_DATE AND return_date IS NOT NULL;
SELECT * FROM loans WHERE return_date < CURRENT_DATE AND return_date IS NULL;

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
