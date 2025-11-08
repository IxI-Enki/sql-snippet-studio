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
        
        return `You are a SQL expert assistant. Given the following database schema and task, provide ONLY the SQL query without any explanation.

Database Schema:
${schemaText}

Task: ${task}

Provide only the SQL query (no explanations, no markdown, just the query):`;
    }

    /**
     * Prüft ob der Cursor an einer Position ist, wo Completion Sinn macht
     * @param {string} lineText - Text der aktuellen Zeile
     * @param {number} character - Character-Position in der Zeile
     * @returns {boolean} true wenn Completion aktiv werden soll
     */
    shouldTriggerCompletion(lineText, character) {
        const beforeCursor = lineText.substring(0, character).trim();
        
        // Trigger nur wenn:
        // - Zeile leer ist
        // - Zeile mit -- beginnt (Kommentar)
        // - Nach einem Semikolon
        return (
            beforeCursor === '' ||
            beforeCursor.endsWith(';') ||
            beforeCursor.startsWith('--')
        );
    }
}

module.exports = ContextBuilder;

