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


-- Aufgabe 2: Zeige alle Autoren mit ihren Büchern (auch Autoren ohne Bücher)


-- Aufgabe 3: Finde alle Mitglieder die aktuell Bücher ausgeliehen haben


-- Aufgabe 4: Erstelle eine Abfrage die die Anzahl der Bücher pro Autor zeigt


-- Aufgabe 5: Finde das meistgeliehene Buch


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

