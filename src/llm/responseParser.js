const vscode = require('vscode');

/**
 * Advanced LLM Response Parser
 * Multi-stage pipeline to extract clean SQL from various response formats
 */
class ResponseParser {
    constructor(debugHelper = null) {
        this.debugHelper = debugHelper;
    }

    /**
     * Main parsing function - tries multiple strategies
     */
    parse(rawResponse) {
        if (!rawResponse || typeof rawResponse !== 'string') {
            this.log('❌ Invalid response type');
            return null;
        }

        this.log(`📥 Raw response length: ${rawResponse.length} chars`);
        this.log(`📝 First 200 chars: ${rawResponse.substring(0, 200)}`);

        // Stage 1: Remove <think> blocks
        let cleaned = this.removeThinkBlocks(rawResponse);
        
        // Stage 2: Try extracting from code blocks
        let sql = this.extractFromCodeBlocks(cleaned);
        if (sql && this.hasSQL(sql)) {
            this.log('✅ Extracted from code block');
            return this.finalCleanup(sql);
        }

        // Stage 3: Try finding SQL statements directly
        sql = this.extractSQLStatements(cleaned);
        if (sql && this.hasSQL(sql)) {
            this.log('✅ Extracted SQL statements');
            return this.finalCleanup(sql);
        }

        // Stage 4: Try finding any SELECT/INSERT/UPDATE/DELETE/CREATE
        sql = this.extractByKeyword(cleaned);
        if (sql && this.hasSQL(sql)) {
            this.log('✅ Extracted by keyword');
            return this.finalCleanup(sql);
        }

        // Stage 5: Last resort - return cleaned response
        this.log('⚠️ Using fallback - returning cleaned response');
        return this.finalCleanup(cleaned);
    }

    /**
     * Stage 1: Remove <think> and similar reasoning blocks
     */
    removeThinkBlocks(text) {
        // Remove <think>...</think> blocks (case insensitive)
        let cleaned = text.replace(/<think>[\s\S]*?<\/think>/gi, '');
        
        // Remove <reasoning>...</reasoning> blocks
        cleaned = cleaned.replace(/<reasoning>[\s\S]*?<\/reasoning>/gi, '');
        
        // Remove [REASONING]...[/REASONING] blocks
        cleaned = cleaned.replace(/\[REASONING\][\s\S]*?\[\/REASONING\]/gi, '');
        
        // Remove "Okay, let's..." type reasoning paragraphs at start
        cleaned = cleaned.replace(/^(Okay|Alright|Let me|Let's|First|So)[\s\S]*?\n\n/i, '');

        return cleaned.trim();
    }

    /**
     * Stage 2: Extract from markdown code blocks
     */
    extractFromCodeBlocks(text) {
        // Try ```sql block first
        let match = text.match(/```sql\s*\n([\s\S]*?)```/i);
        if (match) {
            return match[1].trim();
        }

        // Try ```plsql block
        match = text.match(/```plsql\s*\n([\s\S]*?)```/i);
        if (match) {
            return match[1].trim();
        }

        // Try generic ``` block
        match = text.match(/```\s*\n([\s\S]*?)```/);
        if (match) {
            const content = match[1].trim();
            // Check if it looks like SQL
            if (this.hasSQL(content)) {
                return content;
            }
        }

        return null;
    }

    /**
     * Stage 3: Extract SQL statements (multiple semicolon-terminated statements)
     */
    extractSQLStatements(text) {
        // Find all text that looks like SQL (starts with keyword, ends with semicolon)
        const sqlKeywords = /\b(MERGE|SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|WITH)\b/i;
        
        if (!sqlKeywords.test(text)) {
            return null;
        }

        // Try to find from first SQL keyword to last semicolon
        const match = text.match(/(MERGE|SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|WITH)[\s\S]*;/i);
        if (match) {
            return match[0].trim();
        }

        return null;
    }

    /**
     * Stage 4: Extract by finding SQL keywords
     */
    extractByKeyword(text) {
        const keywords = ['MERGE', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE', 'ALTER', 'DROP', 'WITH'];
        
        for (const keyword of keywords) {
            const regex = new RegExp(`\\b${keyword}\\b[\\s\\S]*`, 'i');
            const match = text.match(regex);
            if (match) {
                let sql = match[0];
                
                // Trim after last semicolon
                const lastSemicolon = sql.lastIndexOf(';');
                if (lastSemicolon !== -1) {
                    sql = sql.substring(0, lastSemicolon + 1);
                }
                
                return sql.trim();
            }
        }

        return null;
    }

    /**
     * Check if text contains SQL keywords
     */
    hasSQL(text) {
        if (!text) return false;
        
        const sqlPattern = /\b(MERGE|SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|WITH|FROM|WHERE|JOIN|GROUP BY|ORDER BY|HAVING)\b/i;
        return sqlPattern.test(text);
    }

    /**
     * Final cleanup: trim whitespace, remove trailing explanations, apply auto-fixes
     */
    finalCleanup(sql) {
        if (!sql) return null;

        // Trim whitespace
        sql = sql.trim();

        // Remove common explanation prefixes
        sql = sql.replace(/^(Here is|Here's|The query is|Query:?|SQL:?|Answer:?|Solution:?)\s*/i, '');

        // Remove text after last semicolon that looks like explanation
        const lastSemicolon = sql.lastIndexOf(';');
        if (lastSemicolon !== -1) {
            const afterSemicolon = sql.substring(lastSemicolon + 1).trim();
            
            // If text after semicolon starts with explanation words, cut it
            if (/^(This|The|Note|Explanation|This query|This will)/i.test(afterSemicolon)) {
                sql = sql.substring(0, lastSemicolon + 1).trim();
            }
        }

        // 🔥 PHASE 1.3: Auto-fix ROLLUP Syntax (MySQL → PostgreSQL)
        sql = this.fixROLLUPSyntax(sql);

        // 🔥 PHASE 2.1++: Auto-fix BY SOURCE Syntax (SQL Server → PostgreSQL)
        sql = this.fixBySourceSyntax(sql);

        // Clean up multiple blank lines
        sql = sql.replace(/\n\s*\n\s*\n/g, '\n\n');

        // Ensure ends with semicolon
        if (!/;\s*$/.test(sql)) {
            sql += ';';
        }

        this.log(`📤 Final SQL length: ${sql.length} chars`);
        return sql;
    }

    /**
     * 🔥 PHASE 1.3: Fix ROLLUP Syntax
     * Converts MySQL "GROUP BY col1, col2 WITH ROLLUP" 
     * to PostgreSQL "GROUP BY ROLLUP(col1, col2)"
     */
    fixROLLUPSyntax(sql) {
        if (!sql) return sql;
        
        // Pattern: GROUP BY ... WITH ROLLUP
        const mysqlRollupPattern = /GROUP\s+BY\s+([\w\s,\.]+?)\s+WITH\s+ROLLUP/gi;
        
        if (mysqlRollupPattern.test(sql)) {
            sql = sql.replace(mysqlRollupPattern, (match, columns) => {
                // Remove trailing commas/whitespace
                const cleanColumns = columns.trim().replace(/,\s*$/, '');
                
                this.log(`🔧 Auto-fixing ROLLUP: MySQL → PostgreSQL`);
                this.log(`   Before: GROUP BY ${cleanColumns} WITH ROLLUP`);
                this.log(`   After:  GROUP BY ROLLUP(${cleanColumns})`);
                
                return `GROUP BY ROLLUP(${cleanColumns})`;
            });
        }
        
        return sql;
    }

    /**
     * 🔥 PHASE 2.1++: Fix BY SOURCE Syntax
     * Converts SQL Server "MERGE ... WHEN NOT MATCHED BY SOURCE THEN DELETE" 
     * to PostgreSQL "DELETE FROM ... WHERE key NOT IN (...)"
     */
    fixBySourceSyntax(sql) {
        if (!sql) return sql;
        
        // Pattern: MERGE with BY SOURCE DELETE
        const bySourcePattern = /MERGE\s+INTO\s+(\w+)\s+(\w+)\s+USING\s+\((.*?)\)\s+(\w+)\s+ON\s+\((.*?)\)\s+WHEN\s+NOT\s+MATCHED\s+BY\s+SOURCE\s+THEN\s+DELETE\s*;?/gis;
        
        if (bySourcePattern.test(sql)) {
            sql = sql.replace(bySourcePattern, (match, targetTable, targetAlias, sourceQuery, sourceAlias, onCondition) => {
                this.log(`🔧 Auto-fixing BY SOURCE: SQL Server → PostgreSQL`);
                this.log(`   Before: MERGE INTO ${targetTable} ... BY SOURCE THEN DELETE`);
                
                // Extract key column from ON condition (e.g., "p.product_id = s.product_id")
                const keyMatch = onCondition.match(/\w+\.(\w+)\s*=\s*\w+\.(\w+)/);
                const keyColumn = keyMatch ? keyMatch[1] : 'id';
                
                // Extract column name from source query (e.g., "SELECT product_id FROM ...")
                const sourceColumnMatch = sourceQuery.match(/SELECT\s+(\w+)/i);
                const sourceColumn = sourceColumnMatch ? sourceColumnMatch[1] : keyColumn;
                
                // Generate PostgreSQL DELETE
                const postgresDelete = `DELETE FROM ${targetTable} WHERE ${keyColumn} NOT IN (${sourceQuery.trim()})`;
                
                this.log(`   After:  ${postgresDelete}`);
                
                return postgresDelete;
            });
        }
        
        return sql;
    }

    /**
     * Log helper
     */
    log(message) {
        if (this.debugHelper) {
            this.debugHelper.log(`[PARSER] ${message}`);
        }
    }
}

module.exports = ResponseParser;
