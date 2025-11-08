/**
 * Context Builder - Analysiert SQL-Schema und Aufgabenstellungen
 */

class ContextBuilder {
    constructor() {
        this.schemaPattern = /CREATE\s+TABLE\s+(\w+)\s*\(([\s\S]*?)\);/gi;
        this.taskPattern = /--\s*(?:Aufgabe|Task|TODO|Question)\s*\d*\s*:?\s*(.+)/gi;
    }

    /**
     * Extrahiert SQL-Schema aus dem Dokument
     * @param {string} documentText - Der komplette Dokumenttext
     * @returns {Array} Array von Schema-Objekten
     */
    extractSchema(documentText) {
        const schemas = [];
        let match;

        while ((match = this.schemaPattern.exec(documentText)) !== null) {
            const tableName = match[1];
            const columns = this.parseColumns(match[2]);
            
            schemas.push({
                tableName,
                columns,
                raw: match[0]
            });
        }

        return schemas;
    }

    /**
     * Parst Spalten aus CREATE TABLE Statement
     * @param {string} columnText - Text zwischen Klammern
     * @returns {Array} Array von Column-Objekten
     */
    parseColumns(columnText) {
        const columns = [];
        const lines = columnText.split(',').map(l => l.trim());

        for (const line of lines) {
            if (!line || line.startsWith('CONSTRAINT') || line.startsWith('PRIMARY KEY') || line.startsWith('FOREIGN KEY')) {
                continue;
            }

            const parts = line.trim().split(/\s+/);
            if (parts.length >= 2) {
                columns.push({
                    name: parts[0],
                    type: parts[1],
                    constraints: parts.slice(2).join(' ')
                });
            }
        }

        return columns;
    }

    /**
     * Extrahiert Aufgabenstellungen aus Kommentaren
     * @param {string} documentText - Der komplette Dokumenttext
     * @param {number} cursorLine - Aktuelle Cursor-Position (Zeilennummer)
     * @returns {Object|null} Die relevante Aufgabe oder null
     */
    extractTaskAtCursor(documentText, cursorLine) {
        const lines = documentText.split('\n');
        
        // Suche rückwärts vom Cursor nach der nächsten Aufgabe
        for (let i = cursorLine; i >= 0; i--) {
            const line = lines[i];
            const taskMatch = /--\s*(?:Aufgabe|Task|TODO|Question)\s*\d*\s*:?\s*(.+)/i.exec(line);
            
            if (taskMatch) {
                return {
                    lineNumber: i,
                    task: taskMatch[1].trim(),
                    fullText: line
                };
            }

            // Stoppe, wenn wir auf Code treffen (nicht mehr in Kommentar-Bereich)
            if (line.trim() && !line.trim().startsWith('--')) {
                break;
            }
        }

        return null;
    }

    /**
     * Baut den vollständigen Context für LLM
     * @param {string} documentText - Der komplette Dokumenttext
     * @param {number} cursorLine - Aktuelle Cursor-Position
     * @returns {Object} Context-Objekt mit Schema und Aufgabe
     */
    buildContext(documentText, cursorLine) {
        const schemas = this.extractSchema(documentText);
        const task = this.extractTaskAtCursor(documentText, cursorLine);

        if (!task) {
            return null;
        }

        return {
            schemas,
            task: task.task,
            taskLine: task.lineNumber,
            schemaText: schemas.map(s => s.raw).join('\n\n'),
            prompt: this.buildPrompt(schemas, task.task)
        };
    }

    /**
     * Erstellt den Prompt für das LLM
     * @param {Array} schemas - Array von Schema-Objekten
     * @param {string} task - Die Aufgabenstellung
     * @returns {string} Der fertige Prompt
     */
    buildPrompt(schemas, task) {
        const schemaText = schemas.map(s => s.raw).join('\n\n');
        
        // Enhanced prompt with strict instructions and few-shot examples
        return `You are an expert SQL code generator. Your task is to generate ONLY valid SQL queries.

CRITICAL RULES:
1. Return ONLY the SQL query - no explanations, no markdown, no comments
2. Do NOT use <think> tags or reasoning blocks
3. Do NOT add text before or after the query
4. Start directly with SELECT/INSERT/UPDATE/DELETE/CREATE/etc.
5. End with a semicolon (;)
6. Use proper SQL syntax for PostgreSQL/Oracle

DATABASE SCHEMA:
${schemaText}

EXAMPLES:
Task: Find all books published after 2000
Output: SELECT * FROM books WHERE publish_year > 2000;

Task: Count books per author
Output: SELECT a.first_name, a.last_name, COUNT(b.book_id) AS book_count FROM authors a LEFT JOIN books b ON a.author_id = b.author_id GROUP BY a.author_id, a.first_name, a.last_name;

YOUR TASK: ${task}

SQL QUERY:`;
    }

    /**
     * Get stop sequences for LLM (to prevent over-generation)
     * @returns {Array} Array of stop sequences
     */
    getStopSequences() {
        return [
            '<think>',
            '<reasoning>',
            'Explanation:',
            'Note:',
            'This query',
            'This will',
            '\n\n\n',  // Stop at triple newline
            'Here is',
            'Here\'s',
            '```'       // Stop at code block markers
        ];
    }

    /**
     * Prüft ob der Cursor an einer Position ist, wo Completion Sinn macht
     * @param {string} lineText - Text der aktuellen Zeile
     * @param {number} character - Character-Position in der Zeile
     * @returns {boolean} true wenn Completion aktiv werden soll
     */
    shouldTriggerCompletion(lineText, character) {
        const beforeCursor = lineText.substring(0, character).trim();
        
        // Trigger wenn:
        // - Zeile leer ist
        // - Zeile mit -- beginnt (Kommentar) 
        // - Nach einem Semikolon
        // - Nach einem Space (Space getippt)
        // - Zeile beginnt mit SQL Keywords (SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER)
        const sqlKeywords = /^(SELECT|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER|WITH|FROM|WHERE|JOIN|INNER|LEFT|RIGHT|OUTER|ON|GROUP|ORDER|HAVING)/i;
        
        return (
            beforeCursor === '' ||
            beforeCursor.endsWith(';') ||
            beforeCursor.startsWith('--') ||
            beforeCursor.endsWith(' ') ||
            sqlKeywords.test(beforeCursor)
        );
    }
}

module.exports = ContextBuilder;
