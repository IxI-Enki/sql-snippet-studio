> **Archive:** Historical document. Kept for reference; may not reflect current product naming or structure.

# 🚀 EXTENSION OPTIMIZATION ROADMAP - DBI Survival Kit

**Created:** November 8, 2025  
**Analyst:** Claude Sonnet 4.5  
**Basis:** Comprehensive Analysis of 5 LLM Models (121 SQL Tasks each)

---

## 📊 EXECUTIVE SUMMARY

Nach intensivem Testing von **5 LLM Models** (qwen3-4b, qwen2.5-vl-7b, qwen3-vl-8b, llama-3-sqlcoder-8b, qwen3-coder-30b) über **121 SQL Tasks** haben wir **systematische Schwächen** identifiziert, die durch **gezielte Prompt Engineering** und **Post-Processing** signifikant verbessert werden können.

### Current State:
- **Best Model:** qwen3-coder-30b-a3b-instruct mit **72.3%** Success
- **Worst Model:** llama-3-sqlcoder-8b mit **27.9%** Success
- **VL Models:** Durchweg schwach (30-42%)

### Target State After Optimization:
- **30B Model:** 72.3% → **85-90%** (+15-18 Punkte!)
- **8B Models:** 28-42% → **50-65%** (+15-20 Punkte!)
- **All Models:** MERGE Success 0-12.5% → **60-80%** 🎯

---

## 🔥 PHASE 1: CRITICAL FIXES (SOFORT)

### Priorität: 🔴 **ULTRA-HIGH**

---

### 1.1 MERGE Statement Support (Impact: +20-30 Punkte!)

**Problem:**
- **ALLE Models scheitern** bei MERGE (0-12.5% Success)
- Generieren incomplete Syntax oder nur SELECT
- 30B Model: 10/10 MERGE Tasks incomplete oder Timeout

**Lösung - Enhanced Prompt:**

```javascript
// src/llm/contextBuilder.js - buildPrompt()

buildPrompt(schemas, task) {
    const schemaText = schemas.map(s => s.raw).join('\n\n');
    
    // 🔥 NEU: Detect MERGE queries
    const isMergeQuery = /MERGE|UPSERT|WHEN\s+MATCHED/i.test(task);
    
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
`;

    // 🔥 NEU: Special instructions for MERGE
    if (isMergeQuery) {
        prompt += `
⚠️ MERGE STATEMENT DETECTED! CRITICAL INSTRUCTIONS:

POSTGRESQL SYNTAX (Use INSERT ... ON CONFLICT):
INSERT INTO target_table (columns...)
SELECT columns... FROM source_table
ON CONFLICT (unique_key) DO UPDATE SET col1 = EXCLUDED.col1, ...;

ORACLE/SQL SERVER SYNTAX (Use MERGE):
MERGE INTO target_table t
USING (SELECT ... FROM source_table) s
ON (t.key = s.key)
WHEN MATCHED THEN UPDATE SET t.col1 = s.col1, ...
WHEN NOT MATCHED THEN INSERT (cols...) VALUES (s.cols...);

COMPLETE STRUCTURE REQUIRED:
1. Start with MERGE INTO or INSERT INTO
2. Include USING clause (Oracle) or SELECT (PostgreSQL)
3. Define ON condition
4. Add WHEN MATCHED and/or WHEN NOT MATCHED clauses
5. End with semicolon

DO NOT generate incomplete MERGE! Include ALL clauses!
`;
    }
    
    prompt += `
EXAMPLES:
Task: Find all books published after 2000
Output: SELECT * FROM books WHERE publish_year > 2000;

Task: Count books per author
Output: SELECT a.first_name, a.last_name, COUNT(b.book_id) AS book_count FROM authors a LEFT JOIN books b ON a.author_id = b.author_id GROUP BY a.author_id, a.first_name, a.last_name;
`;

    // 🔥 NEU: Add MERGE example if detected
    if (isMergeQuery) {
        prompt += `
Task: MERGE new products from staging into products table
Output: MERGE INTO products p USING (SELECT product_id, name, price FROM stg_products) s ON (p.product_id = s.product_id) WHEN MATCHED THEN UPDATE SET p.name = s.name, p.price = s.price WHEN NOT MATCHED THEN INSERT (product_id, name, price) VALUES (s.product_id, s.name, s.price);
`;
    }
    
    prompt += `
YOUR TASK: ${task}

SQL QUERY:`;
    
    return prompt;
}
```

**Expected Impact:**
- MERGE Success: 0-12.5% → **60-80%**
- Test 5 (MERGE): 12.5% → **70%**
- Test 8 (SCD2 MERGE): 30.8% → **65%**

---

### 1.2 Window Functions in WHERE/HAVING Fix (Impact: +5-10 Punkte!)

**Problem:**
- **Wiederkehrender Fehler** in ALLEN Models
- `WHERE rank <= 3` oder `HAVING NTILE() = 1` syntaktisch ungültig
- Modelle verstehen CTE/Subquery Pattern nicht

**Lösung - Enhanced Prompt + Examples:**

```javascript
// src/llm/contextBuilder.js - buildPrompt()

// 🔥 NEU: Detect Window Function filtering
const needsCTE = /top\s+\d+.*per|rank.*<=|ntile.*=/i.test(task) || 
                 /window\s+function.*where/i.test(task);

if (needsCTE) {
    prompt += `
⚠️ WINDOW FUNCTION FILTERING DETECTED!

CRITICAL: Window Functions CANNOT be used in WHERE or HAVING clauses!

CORRECT PATTERN (Use CTE or Subquery):
WITH ranked AS (
    SELECT 
        column,
        RANK() OVER (PARTITION BY group_col ORDER BY order_col) AS rank
    FROM table
)
SELECT * FROM ranked WHERE rank <= 3;

WRONG PATTERN (DO NOT USE):
SELECT ... , RANK() OVER (...) AS rank
FROM table
WHERE rank <= 3;  -- ❌ ERROR: rank not available in WHERE!

REMEMBER: 
- Window Functions are evaluated AFTER WHERE
- Use CTE, Subquery, or QUALIFY clause (if supported)
`;
}
```

**Additional Examples:**

```javascript
// Add to Few-Shot Examples section
if (needsCTE) {
    prompt += `
Example: Top 3 products per category by sales
Output: WITH ranked_products AS (SELECT p.category, p.product_name, SUM(s.amount) AS total_sales, ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(s.amount) DESC) AS rn FROM products p JOIN sales s ON p.product_id = s.product_id GROUP BY p.category, p.product_name) SELECT category, product_name, total_sales FROM ranked_products WHERE rn <= 3;
`;
}
```

**Expected Impact:**
- "Top N per Group" Tasks: 20% → **80%**
- Test 3, 7, 9: +5-10 Punkte

---

### 1.3 ROLLUP Syntax Fix (Impact: +8-12 Punkte!)

**Problem:**
- VL-Models nutzen MySQL `WITH ROLLUP` statt PostgreSQL `ROLLUP(...)`
- 30B Model hat ROLLUP perfekt, aber kleinere Models scheitern

**Lösung - Syntax Detection + Auto-Correction:**

```javascript
// src/llm/responseParser.js - parse()

parse(rawResponse) {
    let sql = this.extractSQL(rawResponse);
    
    if (sql) {
        // 🔥 NEU: Auto-fix MySQL ROLLUP syntax
        sql = this.fixROLLUPSyntax(sql);
        
        // Existing cleanup
        sql = this.cleanupSQL(sql);
    }
    
    return sql;
}

// 🔥 NEU: Fix ROLLUP Syntax
fixROLLUPSyntax(sql) {
    // Replace MySQL "GROUP BY col1, col2 WITH ROLLUP" 
    // with PostgreSQL "GROUP BY ROLLUP(col1, col2)"
    
    const mysqlRollupPattern = /GROUP\s+BY\s+([\w\s,\.]+?)\s+WITH\s+ROLLUP/gi;
    
    if (mysqlRollupPattern.test(sql)) {
        sql = sql.replace(mysqlRollupPattern, (match, columns) => {
            // Remove trailing commas/whitespace
            const cleanColumns = columns.trim().replace(/,\s*$/, '');
            return `GROUP BY ROLLUP(${cleanColumns})`;
        });
        
        if (this.debugHelper) {
            this.debugHelper.log('[PARSER] Auto-fixed MySQL ROLLUP → PostgreSQL ROLLUP');
        }
    }
    
    return sql;
}
```

**Prompt Enhancement:**

```javascript
// Add to buildPrompt()
const hasROLLUP = /ROLLUP|subtotal|hierarchical.*aggreg/i.test(task);

if (hasROLLUP) {
    prompt += `
⚠️ ROLLUP DETECTED! USE POSTGRESQL SYNTAX:

CORRECT (PostgreSQL):
GROUP BY ROLLUP(col1, col2, col3)

WRONG (MySQL - DO NOT USE):
GROUP BY col1, col2, col3 WITH ROLLUP

ROLLUP creates hierarchical subtotals:
- Grand Total
- Subtotals for each level
- Detail rows

Example: Sales by Region, Country, City with subtotals
Output: SELECT region, country, city, SUM(sales) FROM sales_fact GROUP BY ROLLUP(region, country, city);
`;
}
```

**Expected Impact:**
- ROLLUP Success: 0-75% → **90-100%**
- Test 2, 3, 6, 9: +8-12 Punkte

---

### 1.4 Column Reference Validation (Impact: +10-15 Punkte!)

**Problem:**
- Modelle referenzieren Spalten aus falschen Tabellen
- `t.region` (region ist in DIM_Customer, nicht DIM_Time!)
- `f.fiscal_year` (fiscal_year ist in DIM_Time!)

**Lösung - Schema-Aware Validation + Suggestions:**

```javascript
// src/llm/sqlValidator.js - validate()

validate(sqlQuery) {
    const errors = [];
    let score = 100;
    
    // Existing validations...
    
    // 🔥 NEU: Column Reference Validation
    const columnErrors = this.validateColumnReferences(sqlQuery, this.currentSchemas);
    if (columnErrors.length > 0) {
        errors.push(...columnErrors);
        score -= columnErrors.length * 10; // -10 per invalid reference
    }
    
    return {
        isValid: score >= 50,
        score: Math.max(0, score),
        errors
    };
}

// 🔥 NEU: Validate Column References
validateColumnReferences(sql, schemas) {
    const errors = [];
    
    if (!schemas || schemas.length === 0) return errors;
    
    // Build column-to-table mapping
    const columnMap = new Map();
    schemas.forEach(schema => {
        schema.columns.forEach(col => {
            const colName = col.name.toLowerCase();
            if (!columnMap.has(colName)) {
                columnMap.set(colName, []);
            }
            columnMap.get(colName).push(schema.tableName);
        });
    });
    
    // Extract column references from SQL
    // Pattern: alias.column_name
    const refPattern = /(\w+)\.(\w+)/g;
    let match;
    
    while ((match = refPattern.exec(sql)) !== null) {
        const alias = match[1].toUpperCase();
        const column = match[2].toLowerCase();
        
        // Skip if it's a function or keyword
        if (['SELECT', 'FROM', 'WHERE', 'JOIN', 'GROUP', 'ORDER', 'HAVING'].includes(alias)) {
            continue;
        }
        
        // Check if column exists in schema
        if (!columnMap.has(column)) {
            errors.push(`Column "${column}" does not exist in any table`);
        }
    }
    
    return errors;
}
```

**Prompt Enhancement:**

```javascript
// Add to buildPrompt()
prompt += `
⚠️ SCHEMA AWARENESS:
- ONLY use columns that exist in the provided schema
- Reference columns with correct table alias
- Check which table contains each column before using it

COMMON MISTAKES TO AVOID:
- fiscal_year, fiscal_quarter, month_name → These are in DIM_Time, NOT in FACT tables!
- region, country, city → These are in DIM_Customer or DIM_Location, NOT in DIM_Time!
- category, subcategory, brand → These are in DIM_Product, NOT in FACT_Sales!

ALWAYS verify column location in schema before writing query!
`;
```

**Expected Impact:**
- Column Reference Errors: 15-20% → **5%**
- All Tests: +10-15 Punkte

---

## 🟡 PHASE 2: SIGNIFICANT IMPROVEMENTS (1-2 Wochen)

### Priorität: 🟡 **HIGH**

---

### 2.1 Query Complexity Detection + Model Routing (Impact: +15-25 Punkte!)

**Problem:**
- Kleine Models (4B-8B) werden auch für Expert-Level Queries genutzt
- 30B Model ist für Basic Queries "overkill" (langsamer)

**Lösung - Adaptive Model Selection:**

```javascript
// src/llm/queryComplexityAnalyzer.js (NEW FILE)

class QueryComplexityAnalyzer {
    constructor() {
        this.complexityPatterns = {
            basic: {
                score: 1,
                patterns: [
                    /SELECT.*FROM.*WHERE/i,
                    /GROUP\s+BY/i,
                    /ORDER\s+BY/i,
                    /simple.*join/i
                ]
            },
            intermediate: {
                score: 2,
                patterns: [
                    /RANK\(\)/i,
                    /DENSE_RANK\(\)/i,
                    /ROW_NUMBER\(\)/i,
                    /LAG\(|LEAD\(/i,
                    /\d+\s+table.*join/i,
                    /NTILE\(/i
                ]
            },
            advanced: {
                score: 3,
                patterns: [
                    /MERGE/i,
                    /ROLLUP\(/i,
                    /CUBE\(/i,
                    /CTE|WITH\s+\w+\s+AS/i,
                    /SCD.*Type.*2|valid_from.*valid_to/i,
                    /snowflake.*schema/i,
                    /multi.*fact/i,
                    /ROWS\s+BETWEEN/i
                ]
            },
            expert: {
                score: 4,
                patterns: [
                    /multiple.*cte|nested.*cte/i,
                    /business.*logic|real.*world/i,
                    /complex.*analytic/i,
                    /temporal.*query|point.*in.*time/i,
                    /recursive/i,
                    /pivot|unpivot/i
                ]
            }
        };
    }
    
    /**
     * Analyze task complexity
     * @param {string} task - The SQL task description
     * @returns {Object} { level: 'basic'|'intermediate'|'advanced'|'expert', score: 1-4 }
     */
    analyzeComplexity(task) {
        let maxScore = 0;
        let level = 'basic';
        
        // Check each complexity level
        for (const [levelName, config] of Object.entries(this.complexityPatterns)) {
            const matches = config.patterns.filter(pattern => pattern.test(task)).length;
            
            if (matches > 0 && config.score > maxScore) {
                maxScore = config.score;
                level = levelName;
            }
        }
        
        return { level, score: maxScore };
    }
    
    /**
     * Recommend model based on complexity
     * @param {Object} complexity - Result from analyzeComplexity()
     * @returns {string} Recommended model name
     */
    recommendModel(complexity) {
        const config = vscode.workspace.getConfiguration('dbiSurvivalKit.llm');
        
        switch (complexity.level) {
            case 'basic':
                return config.get('model.basic', 'qwen3-coder-30b-a3b-instruct');
            case 'intermediate':
                return config.get('model.intermediate', 'qwen3-coder-30b-a3b-instruct');
            case 'advanced':
                return config.get('model.advanced', 'qwen3-coder-30b-a3b-instruct');
            case 'expert':
                return config.get('model.expert', 'qwen3-coder-30b-a3b-instruct');
            default:
                return config.get('model', 'qwen3-coder-30b-a3b-instruct');
        }
    }
}

module.exports = QueryComplexityAnalyzer;
```

**Integration in Extension:**

```javascript
// src/extension.js - executeLLMQuery()

async function executeLLMQuery() {
    // ... existing code ...
    
    const context = contextBuilder.buildContext(documentText, cursorLine);
    
    // 🔥 NEU: Analyze query complexity
    const complexityAnalyzer = new QueryComplexityAnalyzer();
    const complexity = complexityAnalyzer.analyzeComplexity(context.task);
    const recommendedModel = complexityAnalyzer.recommendModel(complexity);
    
    if (debugHelper) {
        debugHelper.log(`[COMPLEXITY] Level: ${complexity.level}, Score: ${complexity.score}`);
        debugHelper.log(`[COMPLEXITY] Recommended Model: ${recommendedModel}`);
    }
    
    // 🔥 NEU: Update model dynamically (if multi-model enabled)
    const config = vscode.workspace.getConfiguration('dbiSurvivalKit.llm');
    const useAdaptiveModel = config.get('adaptiveModelSelection', false);
    
    if (useAdaptiveModel) {
        // Temporarily override model for this query
        await config.update('model', recommendedModel, vscode.ConfigurationTarget.Global);
    }
    
    // ... continue with LLM query ...
}
```

**Configuration:**

```json
// package.json - Add new settings
"dbiSurvivalKit.llm.adaptiveModelSelection": {
    "type": "boolean",
    "default": false,
    "description": "Automatically select best model based on query complexity"
},
"dbiSurvivalKit.llm.model.basic": {
    "type": "string",
    "default": "qwen3-coder-30b-a3b-instruct",
    "description": "Model for basic queries (simple SELECTs, 1-2 JOINs)"
},
"dbiSurvivalKit.llm.model.intermediate": {
    "type": "string",
    "default": "qwen3-coder-30b-a3b-instruct",
    "description": "Model for intermediate queries (Window Functions, 3-5 JOINs)"
},
"dbiSurvivalKit.llm.model.advanced": {
    "type": "string",
    "default": "qwen3-coder-30b-a3b-instruct",
    "description": "Model for advanced queries (MERGE, ROLLUP, CTEs)"
},
"dbiSurvivalKit.llm.model.expert": {
    "type": "string",
    "default": "qwen3-coder-30b-a3b-instruct",
    "description": "Model for expert queries (Multi-CTE, Business Logic)"
}
```

**Expected Impact:**
- 8B Models können Basic Tasks übernehmen (85% Success)
- 30B Model wird für Complex Tasks reserviert (schnellere Response)
- Overall Score: +15-25 Punkte durch optimale Model-Nutzung

---

### 2.2 Enhanced Few-Shot Examples (Impact: +10-15 Punkte!)

**Problem:**
- Aktuelle Examples sind zu generic
- Keine Examples für MERGE, ROLLUP, Window Functions, CTEs

**Lösung - Comprehensive Example Library:**

```javascript
// src/llm/exampleLibrary.js (NEW FILE)

class ExampleLibrary {
    constructor() {
        this.examples = {
            basic: [
                {
                    task: "Find all books published after 2000",
                    sql: "SELECT * FROM books WHERE publish_year > 2000;"
                },
                {
                    task: "Count books per author",
                    sql: "SELECT a.first_name, a.last_name, COUNT(b.book_id) AS book_count FROM authors a LEFT JOIN books b ON a.author_id = b.author_id GROUP BY a.author_id, a.first_name, a.last_name;"
                }
            ],
            windowFunctions: [
                {
                    task: "Rank products by sales within each category",
                    sql: "SELECT p.category, p.product_name, SUM(s.amount) AS total_sales, RANK() OVER (PARTITION BY p.category ORDER BY SUM(s.amount) DESC) AS sales_rank FROM products p JOIN sales s ON p.product_id = s.product_id GROUP BY p.category, p.product_name;"
                },
                {
                    task: "Top 3 products per category by sales",
                    sql: "WITH ranked AS (SELECT p.category, p.product_name, SUM(s.amount) AS total_sales, ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(s.amount) DESC) AS rn FROM products p JOIN sales s ON p.product_id = s.product_id GROUP BY p.category, p.product_name) SELECT category, product_name, total_sales FROM ranked WHERE rn <= 3;"
                },
                {
                    task: "7-day moving average of sales",
                    sql: "SELECT date, daily_sales, AVG(daily_sales) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d FROM daily_sales;"
                }
            ],
            merge: [
                {
                    task: "MERGE new products from staging into products table",
                    sql: "MERGE INTO products p USING (SELECT product_id, name, price FROM stg_products) s ON (p.product_id = s.product_id) WHEN MATCHED THEN UPDATE SET p.name = s.name, p.price = s.price WHEN NOT MATCHED THEN INSERT (product_id, name, price) VALUES (s.product_id, s.name, s.price);"
                },
                {
                    task: "UPSERT customer data (PostgreSQL)",
                    sql: "INSERT INTO customers (customer_id, name, email) SELECT customer_id, name, email FROM stg_customers ON CONFLICT (customer_id) DO UPDATE SET name = EXCLUDED.name, email = EXCLUDED.email;"
                }
            ],
            rollup: [
                {
                    task: "Sales by region and country with subtotals",
                    sql: "SELECT region, country, SUM(sales) AS total_sales FROM sales_fact GROUP BY ROLLUP(region, country);"
                }
            ],
            cte: [
                {
                    task: "Multi-step analysis with CTEs",
                    sql: "WITH monthly_sales AS (SELECT product_id, EXTRACT(MONTH FROM sale_date) AS month, SUM(amount) AS total FROM sales GROUP BY product_id, month), sales_growth AS (SELECT product_id, month, total, LAG(total) OVER (PARTITION BY product_id ORDER BY month) AS prev_month FROM monthly_sales) SELECT product_id, month, total, prev_month, (total - prev_month) / prev_month * 100 AS growth_pct FROM sales_growth WHERE prev_month IS NOT NULL;"
                }
            ]
        };
    }
    
    /**
     * Get relevant examples for task
     * @param {string} task - The SQL task
     * @param {number} maxExamples - Max number of examples to return
     * @returns {Array} Array of {task, sql} objects
     */
    getRelevantExamples(task, maxExamples = 3) {
        const taskLower = task.toLowerCase();
        const examples = [];
        
        // Detect query type and add relevant examples
        if (/merge|upsert|when\s+matched/i.test(task)) {
            examples.push(...this.examples.merge);
        }
        
        if (/rank|row_number|dense_rank|ntile|top\s+\d+.*per/i.test(task)) {
            examples.push(...this.examples.windowFunctions);
        }
        
        if (/rollup|subtotal|hierarchical/i.test(task)) {
            examples.push(...this.examples.rollup);
        }
        
        if (/cte|with.*as|multi.*step/i.test(task)) {
            examples.push(...this.examples.cte);
        }
        
        // Add basic examples if none matched or as fallback
        if (examples.length === 0) {
            examples.push(...this.examples.basic);
        }
        
        // Limit to maxExamples
        return examples.slice(0, maxExamples);
    }
}

module.exports = ExampleLibrary;
```

**Integration:**

```javascript
// src/llm/contextBuilder.js

const ExampleLibrary = require('./exampleLibrary');

class ContextBuilder {
    constructor() {
        this.schemaPattern = /CREATE\s+TABLE\s+(\w+)\s*\(([\s\S]*?)\);/gi;
        this.exampleLibrary = new ExampleLibrary(); // 🔥 NEU
    }
    
    buildPrompt(schemas, task) {
        // ... existing code ...
        
        // 🔥 NEU: Get relevant examples
        const examples = this.exampleLibrary.getRelevantExamples(task, 3);
        
        prompt += `\nEXAMPLES:\n`;
        examples.forEach(ex => {
            prompt += `Task: ${ex.task}\nOutput: ${ex.sql}\n\n`;
        });
        
        prompt += `YOUR TASK: ${task}\n\nSQL QUERY:`;
        
        return prompt;
    }
}
```

**Expected Impact:**
- MERGE Understanding: +40-50 Punkte
- Window Functions: +10-15 Punkte
- Overall: +10-15 Punkte durch bessere Few-Shot Examples

---

### 2.3 Timeout Management + Incremental Generation (Impact: +5-8 Punkte!)

**Problem:**
- Complex Queries führen zu Timeouts (3 Tasks in 30B Model)
- Timeout = 10 Sekunden aktuell

**Lösung:**

```javascript
// package.json - Increase timeout
"dbiSurvivalKit.llm.timeout": {
    "type": "number",
    "default": 30000, // 🔥 NEU: 30 seconds statt 10
    "description": "LLM request timeout in milliseconds"
},
"dbiSurvivalKit.llm.timeoutComplex": {
    "type": "number",
    "default": 60000, // 🔥 NEU: 60 seconds für complex queries
    "description": "LLM timeout for complex queries (MERGE, Expert)"
}
```

```javascript
// src/llm/llmProvider.js

async query(prompt, context = null) {
    // ... existing code ...
    
    // 🔥 NEU: Dynamic timeout based on complexity
    let timeout = this.config.timeout;
    
    if (context && context.task) {
        const isComplex = /MERGE|recursive|multi.*cte|expert/i.test(context.task);
        if (isComplex) {
            timeout = this.config.timeoutComplex || 60000;
            if (this.debugHelper) {
                this.debugHelper.log(`[LLM] Using extended timeout: ${timeout}ms for complex query`);
            }
        }
    }
    
    // Use timeout in request
    const response = await this.sendRequest(prompt, stopSequences, timeout);
    
    // ... rest of code ...
}
```

**Expected Impact:**
- Timeout Failures: 3 Tasks → **0-1 Tasks**
- Test 10 (Expert): +5-8 Punkte

---

## 🟢 PHASE 3: ADVANCED FEATURES (2-4 Wochen)

### Priorität: 🟢 **MEDIUM**

---

### 3.1 SQL Dialect Auto-Detection (Impact: +5-10 Punkte!)

**Problem:**
- Models mischen PostgreSQL und Oracle Syntax
- MySQL Patterns (WITH ROLLUP, LIMIT) in PostgreSQL Queries

**Lösung:**

```javascript
// src/llm/dialectDetector.js (NEW FILE)

class DialectDetector {
    detectDialect(schemas, task) {
        // Check schema DDL for dialect hints
        const schemaText = schemas.map(s => s.raw).join(' ').toLowerCase();
        
        // PostgreSQL indicators
        if (/serial|text\[\]|jsonb|pg_|nextval/i.test(schemaText)) {
            return 'postgresql';
        }
        
        // Oracle indicators
        if (/number\(\d+,\d+\)|varchar2|clob|blob|sysdate|dual/i.test(schemaText)) {
            return 'oracle';
        }
        
        // Default to PostgreSQL (more common in modern systems)
        return 'postgresql';
    }
    
    getDialectInstructions(dialect) {
        const instructions = {
            postgresql: `
POSTGRESQL-SPECIFIC SYNTAX:
- SERIAL for auto-increment
- TEXT for long strings
- LIMIT N for row limiting
- INSERT ... ON CONFLICT for UPSERT
- ROLLUP() syntax: GROUP BY ROLLUP(col1, col2)
- No WITH keyword before ROLLUP
`,
            oracle: `
ORACLE-SPECIFIC SYNTAX:
- NUMBER for integers/decimals
- VARCHAR2 for strings
- ROWNUM or FETCH FIRST N ROWS for limiting
- MERGE INTO for UPSERT
- ROLLUP() syntax: GROUP BY ROLLUP(col1, col2)
- DUAL table for single-row selects
`
        };
        
        return instructions[dialect] || instructions.postgresql;
    }
}
```

**Integration:**

```javascript
// src/llm/contextBuilder.js

buildPrompt(schemas, task) {
    // ... existing code ...
    
    // 🔥 NEU: Detect dialect
    const dialectDetector = new DialectDetector();
    const dialect = dialectDetector.detectDialect(schemas, task);
    const dialectInstructions = dialectDetector.getDialectInstructions(dialect);
    
    prompt += `\n${dialectInstructions}\n`;
    
    // ... rest of prompt ...
}
```

**Expected Impact:**
- Syntax Consistency: +5-10 Punkte
- ROLLUP Auto-Fix Rate: +10%

---

### 3.2 Interactive Query Refinement (Impact: User Experience!)

**Problem:**
- User sieht nur finales Ergebnis
- Keine Möglichkeit für Iterationen

**Lösung - Multi-Turn Dialog:**

```javascript
// src/extension.js - NEW COMMAND

async function refineLastQuery() {
    const editor = vscode.window.activeTextEditor;
    if (!editor) return;
    
    // Get last generated query from context
    const lastQuery = queryCache.getLastGenerated();
    if (!lastQuery) {
        vscode.window.showErrorMessage('No previous query found!');
        return;
    }
    
    // Ask for refinement instructions
    const refinement = await vscode.window.showInputBox({
        prompt: 'How should I refine the query?',
        placeHolder: 'e.g., "Add ORDER BY date", "Include customer name", "Fix MERGE syntax"'
    });
    
    if (!refinement) return;
    
    // Build refinement prompt
    const prompt = `You previously generated this SQL query:
    
${lastQuery.sql}

The user wants you to refine it with these instructions:
${refinement}

Generate the IMPROVED SQL query:`;
    
    // Query LLM
    const llmProvider = new LLMProvider(debugHelper, queryCache);
    const result = await llmProvider.query(prompt, null);
    
    // Insert refined query
    const position = editor.selection.active;
    await editor.edit(editBuilder => {
        editBuilder.insert(position, '\n-- REFINED QUERY:\n' + result.sql + '\n');
    });
}
```

**Expected Impact:**
- User Satisfaction: **HOCH**
- Iterative Improvement möglich

---

### 3.3 Schema Learning + Context Enhancement (Impact: +8-12 Punkte!)

**Problem:**
- Model versteht Schema-Beziehungen nicht
- Keine Informationen über Foreign Keys, Relationships

**Lösung - Enhanced Schema Context:**

```javascript
// src/llm/schemaEnhancer.js (NEW FILE)

class SchemaEnhancer {
    /**
     * Extract foreign key relationships from schema
     */
    extractRelationships(schemas) {
        const relationships = [];
        
        schemas.forEach(schema => {
            const fkPattern = /FOREIGN\s+KEY\s*\((\w+)\)\s*REFERENCES\s+(\w+)\s*\((\w+)\)/gi;
            let match;
            
            while ((match = fkPattern.exec(schema.raw)) !== null) {
                relationships.push({
                    from: schema.tableName,
                    fromColumn: match[1],
                    to: match[2],
                    toColumn: match[3]
                });
            }
        });
        
        return relationships;
    }
    
    /**
     * Build enhanced schema description
     */
    buildEnhancedSchemaText(schemas) {
        const relationships = this.extractRelationships(schemas);
        
        let enhancedText = `DATABASE SCHEMA:\n`;
        
        // Add tables
        schemas.forEach(s => {
            enhancedText += s.raw + '\n\n';
        });
        
        // Add relationships
        if (relationships.length > 0) {
            enhancedText += `\nRELATIONSHIPS:\n`;
            relationships.forEach(rel => {
                enhancedText += `- ${rel.from}.${rel.fromColumn} → ${rel.to}.${rel.toColumn}\n`;
            });
        }
        
        // Add common patterns
        enhancedText += `\nCOMMON JOIN PATTERNS:\n`;
        enhancedText += `- Fact tables JOIN Dimension tables via foreign keys\n`;
        enhancedText += `- Use time_key to join FACT tables with DIM_Time\n`;
        enhancedText += `- Star Schema: FACT in center, DIM tables around it\n`;
        enhancedText += `- Snowflake Schema: DIM tables may join to other DIM tables\n`;
        
        return enhancedText;
    }
}
```

**Expected Impact:**
- JOIN Correctness: +10-15%
- Column Reference Errors: -5%

---

## 🔵 PHASE 4: LONG-TERM ENHANCEMENTS (1-2 Monate)

### Priorität: 🔵 **LOW** (Future)

---

### 4.1 Fine-Tuning on DBI Test Data

**Approach:**
- Collect all 121 SQL tasks + correct solutions
- Fine-tune 8B model specifically on this data
- Expected improvement: 28% → **65-70%**

---

### 4.2 Multi-Model Ensemble

**Approach:**
- Query 2-3 models simultaneously
- Vote on best result
- Use validation score for selection

---

### 4.3 Feedback Learning Loop

**Approach:**
- Track user corrections
- Learn from common mistakes
- Adjust prompts dynamically

---

## 📊 EXPECTED OVERALL IMPACT

### Before Optimization:
- **qwen3-coder-30b:** 72.3%
- **qwen3-vl-8b:** 42.1%
- **llama-3-sqlcoder-8b:** 27.9%

### After Phase 1-2 (4-6 Wochen):
- **qwen3-coder-30b:** 72.3% → **85-90%** (+15-18 Punkte)
- **qwen3-vl-8b:** 42.1% → **60-70%** (+18-28 Punkte)
- **llama-3-sqlcoder-8b:** 27.9% → **50-65%** (+22-37 Punkte!)

### Critical Improvements:
- **MERGE Success:** 0-12.5% → **60-80%**
- **Window Functions:** 20-76% → **80-95%**
- **Expert Queries:** 11-72% → **65-85%**

---

## 🔀 GIT BRANCHING STRATEGY

### ✅ EMPFEHLUNG: **JA, BRANCH-STRATEGIE NUTZEN!**

```bash
# 1. Current state in master mergen
git checkout master
git merge feature/llm-integration --no-ff
git tag v1.6.2-tested "All models tested, baseline established"
git push origin master --tags

# 2. Neuen Feature Branch für Optimierungen
git checkout -b feature/llm-optimization-phase1
```

### Branch Structure:
```
master (v1.6.2) - Tested Baseline
  ↓
feature/llm-optimization-phase1 (MERGE fixes, Window Functions, ROLLUP)
  ↓
feature/llm-optimization-phase2 (Complexity Detection, Examples, Timeout)
  ↓
feature/llm-optimization-phase3 (Dialect Detection, Schema Enhancement)
```

### Merge Strategy:
- **Phase 1 Complete** → Merge to master (v1.7.0)
- **Phase 2 Complete** → Merge to master (v1.8.0)
- **Phase 3 Complete** → Merge to master (v2.0.0)

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1 (SOFORT - 1 Woche):
- [ ] MERGE Statement Enhanced Prompt
- [ ] Window Functions CTE Pattern Instructions
- [ ] ROLLUP Syntax Auto-Fix (Parser)
- [ ] Column Reference Validation
- [ ] Test mit qwen3-coder-30b (Target: 85%+)
- [ ] Test mit qwen3-vl-8b (Target: 60%+)

### Phase 2 (1-2 Wochen):
- [ ] Query Complexity Analyzer
- [ ] Adaptive Model Routing
- [ ] Enhanced Few-Shot Example Library
- [ ] Dynamic Timeout Management
- [ ] Test mit allen Models

### Phase 3 (2-4 Wochen):
- [ ] SQL Dialect Auto-Detection
- [ ] Interactive Query Refinement
- [ ] Schema Relationship Extraction
- [ ] Enhanced Schema Context

---

## 🎯 SUCCESS METRICS

### Primary Goals:
- **30B Model:** 72.3% → **85%+** ✅
- **8B Models:** 28-42% → **60%+** ✅
- **MERGE Success:** 12.5% → **70%+** ✅

### Secondary Goals:
- **User Satisfaction:** Measured by query acceptance rate
- **Response Time:** Keep under 5 seconds for basic, 30 seconds for complex
- **Cache Hit Rate:** Improve from current baseline

---

## 🚀 NEXT IMMEDIATE STEPS

1. **✅ Merge current state to master:**
   ```bash
   git checkout master
   git merge feature/llm-integration
   git tag v1.6.2-baseline
   git push origin master --tags
   ```

2. **✅ Create optimization branch:**
   ```bash
   git checkout -b feature/llm-optimization-phase1
   ```

3. **🔴 Implement Phase 1 Critical Fixes:**
   - Start with MERGE prompt enhancement (biggest impact!)
   - Then Window Functions CTE pattern
   - Then ROLLUP auto-fix
   - Test after each change

4. **📊 Continuous Testing:**
   - Re-run test suite after each optimization
   - Track improvement per change
   - Document results

---

**ROADMAP COMPLETE! READY TO ROCK! 🚀🔥💪**

**Estimated Timeline:**
- Phase 1: 1 Woche
- Phase 2: 2-3 Wochen
- Phase 3: 4-6 Wochen
- **TOTAL: 6-8 Wochen to 85%+ Performance!**

🤓🤜🏻🤛🏻🤖
