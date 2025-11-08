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
        
        // 🔥 PHASE 1.1: Detect query patterns for enhanced instructions
        const isMergeQuery = /MERGE|UPSERT|WHEN\s+MATCHED|ETL|load.*into|sync.*table/i.test(task);
        const isWindowFunction = /rank|row_number|dense_rank|ntile|lag|lead|first_value|last_value|top\s+\d+.*per|partition\s+by/i.test(task);
        const isROLLUP = /ROLLUP|CUBE|subtotal|hierarchical.*aggreg|grand.*total/i.test(task);
        const isTopNPerGroup = /top\s+\d+.*per|top\s+\d+.*in.*each|best.*per.*group|highest.*per.*category/i.test(task);
        
        // Base prompt
        let prompt = `You are an expert SQL code generator. Your task is to generate ONLY valid SQL queries.

CRITICAL RULES:
1. Return ONLY the SQL query - no explanations, no markdown, no comments
2. Do NOT use <think> tags or reasoning blocks
3. Do NOT add text before or after the query
4. Start directly with SELECT/INSERT/UPDATE/DELETE/MERGE/WITH
5. End with a semicolon (;)
6. Use proper SQL syntax for PostgreSQL/Oracle

DATABASE SCHEMA:
${schemaText}

⚠️ SCHEMA AWARENESS - COMMON MISTAKES TO AVOID:
1. fiscal_year, fiscal_quarter, month_name → These are in DIM_Time, NOT in FACT tables!
2. region, country, city → These are in DIM_Customer or DIM_Location, NOT in DIM_Time!
3. category, subcategory, brand → These are in DIM_Product, NOT in FACT_Sales!
4. Always JOIN dimension tables to access their columns
5. Check which table contains each column before referencing it
6. Use correct table alias when referencing columns
`;

        // 🔥 PHASE 1.1 + 2.1: MERGE Statement Instructions (Enhanced with PostgreSQL Dialect Specifics)
        if (isMergeQuery) {
            prompt += `
⚠️ MERGE/UPSERT STATEMENT DETECTED! CRITICAL INSTRUCTIONS:

POSTGRESQL SYNTAX (Use INSERT ... ON CONFLICT):
INSERT INTO target_table (col1, col2, col3)
SELECT col1, col2, col3 
FROM source_table
ON CONFLICT (unique_key) 
DO UPDATE SET col1 = EXCLUDED.col1, col2 = EXCLUDED.col2;

ORACLE/SQL SERVER SYNTAX (Use MERGE):
MERGE INTO target_table t
USING (SELECT col1, col2, col3 FROM source_table) s
ON (t.key = s.key)
WHEN MATCHED THEN 
    UPDATE SET t.col1 = s.col1, t.col2 = s.col2
WHEN NOT MATCHED THEN 
    INSERT (key, col1, col2) VALUES (s.key, s.col1, s.col2);

COMPLETE STRUCTURE REQUIRED:
1. Start with MERGE INTO or INSERT INTO (never incomplete!)
2. Include USING clause (Oracle) or SELECT (PostgreSQL)
3. Define ON condition for matching
4. Add WHEN MATCHED and/or WHEN NOT MATCHED clauses
5. End with semicolon
6. Do NOT generate only fragments - COMPLETE statement required!

🚨 POSTGRESQL DIALECT LIMITATIONS (CRITICAL!):

1. ❌ "WHEN NOT MATCHED BY SOURCE THEN DELETE" → NOT SUPPORTED in PostgreSQL!
   ✅ Alternative: Use separate DELETE statement:
   DELETE FROM target WHERE key NOT IN (SELECT key FROM source);

2. ❌ MERGE in CTE (WITH clause) → NOT SUPPORTED in PostgreSQL!
   ✅ Alternative: Execute MERGE outside of WITH, use separate statements
   WRONG: WITH updated AS (MERGE INTO ...) SELECT * FROM updated;
   CORRECT: 
   -- Step 1: CTE for data prep
   WITH prep AS (SELECT ... FROM source)
   SELECT * FROM prep;
   -- Step 2: MERGE outside of CTE
   MERGE INTO target USING (SELECT ... FROM source) s ON (...);

3. ❌ OUTPUT clause → NOT SUPPORTED in PostgreSQL!
   ✅ Alternative: Use RETURNING clause or separate INSERT for logging
   WRONG: MERGE INTO ... OUTPUT inserted.*, deleted.* INTO log_table;
   CORRECT: 
   MERGE INTO target ... ;
   INSERT INTO log_table SELECT ... FROM target JOIN source ...;

4. ⚠️ Logic Validation - Check WHERE clause on CORRECT table!
   WRONG: WHERE product_id IN (SELECT id FROM staging WHERE stock < 10)
   → This checks stock in STAGING, not in TARGET!
   CORRECT: WHERE product_id IN (SELECT id FROM target WHERE stock < 10)
   → This checks stock in TARGET table!

EXAMPLE:
MERGE INTO products p
USING (SELECT product_id, name, price FROM stg_products WHERE price > 0) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET p.name = s.name, p.price = s.price, p.updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT (product_id, name, price, created_at) VALUES (s.product_id, s.name, s.price, CURRENT_TIMESTAMP);
`;
        }
        
        // 🔥 PHASE 1.2: Window Functions + CTE Pattern Instructions
        if (isWindowFunction || isTopNPerGroup) {
            prompt += `
⚠️ WINDOW FUNCTION DETECTED! CRITICAL PATTERN:

Window Functions CANNOT be used in WHERE or HAVING clauses!
They are evaluated AFTER WHERE, so use CTE or Subquery pattern!

CORRECT PATTERN (Use CTE):
WITH ranked AS (
    SELECT 
        column,
        other_column,
        RANK() OVER (PARTITION BY group_col ORDER BY order_col DESC) AS rank
    FROM table
    WHERE base_filter = true
)
SELECT * FROM ranked WHERE rank <= 3;

WRONG PATTERN (DO NOT USE):
SELECT 
    column,
    RANK() OVER (...) AS rank
FROM table
WHERE rank <= 3;  -- ❌ ERROR: rank not available in WHERE!

TOP N PER GROUP PATTERN:
WITH ranked_data AS (
    SELECT 
        group_column,
        value_column,
        ROW_NUMBER() OVER (PARTITION BY group_column ORDER BY value_column DESC) AS rn
    FROM table
)
SELECT group_column, value_column
FROM ranked_data
WHERE rn <= N;

REMEMBER: Window Function → CTE → Filter in outer query!
`;
        }
        
        // 🔥 PHASE 1.3: ROLLUP Instructions
        if (isROLLUP) {
            prompt += `
⚠️ ROLLUP DETECTED! USE POSTGRESQL SYNTAX:

CORRECT (PostgreSQL):
SELECT col1, col2, col3, SUM(amount)
FROM table
GROUP BY ROLLUP(col1, col2, col3);

WRONG (MySQL - DO NOT USE):
SELECT col1, col2, col3, SUM(amount)
FROM table
GROUP BY col1, col2, col3 WITH ROLLUP;

ROLLUP creates hierarchical subtotals:
- Grand Total (all columns NULL)
- Subtotal level 1 (col2, col3 NULL)
- Subtotal level 2 (col3 NULL)
- Detail rows (no NULLs)

EXAMPLE:
SELECT region, country, city, SUM(sales) AS total_sales
FROM sales_fact
JOIN dim_location ON sales_fact.location_key = dim_location.location_key
GROUP BY ROLLUP(region, country, city)
ORDER BY region NULLS LAST, country NULLS LAST, city NULLS LAST;
`;
        }
        
        // 🔥 Enhanced Examples (Context-Aware)
        prompt += `
EXAMPLES:
Task: Find all books published after 2000
Output: SELECT * FROM books WHERE publish_year > 2000;

Task: Count books per author
Output: SELECT a.first_name, a.last_name, COUNT(b.book_id) AS book_count FROM authors a LEFT JOIN books b ON a.author_id = b.author_id GROUP BY a.author_id, a.first_name, a.last_name;
`;

        // Add MERGE example if detected
        if (isMergeQuery) {
            prompt += `
Task: MERGE new products from staging into products table
Output: MERGE INTO products p USING (SELECT product_id, name, price FROM stg_products) s ON (p.product_id = s.product_id) WHEN MATCHED THEN UPDATE SET p.name = s.name, p.price = s.price WHEN NOT MATCHED THEN INSERT (product_id, name, price) VALUES (s.product_id, s.name, s.price);
`;
        }
        
        // Add Window Function example if detected
        if (isWindowFunction || isTopNPerGroup) {
            prompt += `
Task: Top 3 products per category by sales
Output: WITH ranked AS (SELECT c.category, p.product_name, SUM(s.amount) AS total_sales, ROW_NUMBER() OVER (PARTITION BY c.category ORDER BY SUM(s.amount) DESC) AS rn FROM products p JOIN sales s ON p.product_id = s.product_id JOIN categories c ON p.category_id = c.category_id GROUP BY c.category, p.product_name) SELECT category, product_name, total_sales FROM ranked WHERE rn <= 3;
`;
        }
        
        // 🔥 PHASE 2.2: UPDATE/DELETE Logic Validation (Detect UPDATE/DELETE patterns)
        const isUpdateOrDelete = /UPDATE|DELETE|aktualisier|lösch|entfern|update.*where|delete.*where/i.test(task);
        if (isUpdateOrDelete) {
            prompt += `
⚠️ UPDATE/DELETE LOGIC VALIDATION:

1. Check WHERE clause on CORRECT table:
   WRONG: UPDATE Products SET stock = stock - 1 WHERE product_id IN (SELECT id FROM Staging WHERE stock < 10);
   → This checks stock in STAGING, not in Products!
   
   CORRECT: UPDATE Products SET stock = stock - 1 WHERE product_id IN (SELECT id FROM Products WHERE stock < 10);
   → This checks stock in TARGET table!

2. Use FROM clause for complex conditions:
   CORRECT: UPDATE Products p SET stock = s.new_stock FROM Staging s WHERE p.product_id = s.product_id AND p.stock < 10;

3. RETURNING clause for logging (PostgreSQL):
   UPDATE Products SET stock = stock - 1 WHERE stock < 10 RETURNING product_id, stock, last_updated;
`;
        }
        
        // 🔥 PHASE 2.3: Multi-Stage ETL Hints (Detect complex/multi-stage patterns)
        const isComplexETL = /mehrstufig|multiple.*step|multi.*stage|etl.*process|(\d+)\)\s*.*(\d+)\)/i.test(task);
        if (isComplexETL) {
            prompt += `
⚠️ MULTI-STAGE ETL DETECTED:

For complex multi-step processes:
1. Use separate statements, NOT nested CTEs with MERGE
2. PostgreSQL does NOT support MERGE in CTE (WITH clause)
3. Structure: CTE for data prep → Execute MERGE separately → Separate logging

CORRECT APPROACH:
-- Step 1: Insert new entities (CTE allowed)
WITH new_entities AS (
    INSERT INTO target SELECT ... RETURNING id
)
SELECT * FROM new_entities;

-- Step 2: MERGE main data (outside CTE!)
MERGE INTO target USING source ON (...) WHEN MATCHED THEN UPDATE ... WHEN NOT MATCHED THEN INSERT ...;

-- Step 3: Log changes (separate statement)
INSERT INTO log_table SELECT ... FROM target JOIN source ...;
`;
        }
        
        prompt += `
YOUR TASK: ${task}

SQL QUERY:`;
        
        return prompt;
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
