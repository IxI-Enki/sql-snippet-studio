const vscode = require('vscode');

/**
 * Basic SQL Validator
 * Performs syntax checks and returns validation results
 */
class SQLValidator {
    constructor(debugHelper = null) {
        this.debugHelper = debugHelper;
    }

    /**
     * Validate SQL and return detailed results
     * @returns {Object} { isValid, warnings[], errors[], score }
     */
    validate(sql) {
        if (!sql || typeof sql !== 'string') {
            return {
                isValid: false,
                errors: ['SQL is empty or invalid'],
                warnings: [],
                score: 0
            };
        }

        const result = {
            isValid: true,
            errors: [],
            warnings: [],
            score: 100
        };

        this.log(`🔍 Validating SQL (${sql.length} chars)`);

        // Check 1: Has SQL keywords
        if (!this.hasValidKeywords(sql)) {
            result.errors.push('No SQL keywords found (SELECT, INSERT, UPDATE, etc.)');
            result.score -= 50;
            result.isValid = false;
        }

        // Check 2: Parentheses matching
        const parenCheck = this.checkParentheses(sql);
        if (!parenCheck.valid) {
            result.errors.push(`Unmatched parentheses: ${parenCheck.message}`);
            result.score -= 30;
            result.isValid = false;
        }

        // Check 3: Ends with semicolon
        if (!/;\s*$/.test(sql)) {
            result.warnings.push('Query should end with semicolon');
            result.score -= 5;
        }

        // Check 4: Has FROM clause (for SELECT)
        if (/^\s*SELECT\b/i.test(sql) && !/\bFROM\b/i.test(sql)) {
            // Check if it's not just "SELECT 1" or similar
            if (!/SELECT\s+[\d'"][^;]*;/i.test(sql)) {
                result.warnings.push('SELECT query without FROM clause');
                result.score -= 10;
            }
        }

        // Check 5: Common SQL injection patterns (for safety)
        if (this.hasSuspiciousPatterns(sql)) {
            result.warnings.push('Query contains potentially suspicious patterns');
            result.score -= 15;
        }

        // Check 6: Proper string quoting
        const quoteCheck = this.checkStringQuotes(sql);
        if (!quoteCheck.valid) {
            result.errors.push(`String quoting issue: ${quoteCheck.message}`);
            result.score -= 20;
            result.isValid = false;
        }

        // Check 7: Basic syntax structure
        const structureCheck = this.checkBasicStructure(sql);
        if (structureCheck.warnings.length > 0) {
            result.warnings.push(...structureCheck.warnings);
            result.score -= 5 * structureCheck.warnings.length;
        }

        // Ensure score doesn't go negative
        result.score = Math.max(0, result.score);

        this.log(`✅ Validation complete: ${result.isValid ? 'VALID' : 'INVALID'} (Score: ${result.score})`);
        if (result.errors.length > 0) {
            this.log(`❌ Errors: ${result.errors.join(', ')}`);
        }
        if (result.warnings.length > 0) {
            this.log(`⚠️ Warnings: ${result.warnings.join(', ')}`);
        }

        return result;
    }

    /**
     * Check if SQL has valid keywords
     */
    hasValidKeywords(sql) {
        const keywords = /\b(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|WITH|TRUNCATE|GRANT|REVOKE)\b/i;
        return keywords.test(sql);
    }

    /**
     * Check parentheses matching
     */
    checkParentheses(sql) {
        let count = 0;
        let inString = false;
        let stringChar = null;

        for (let i = 0; i < sql.length; i++) {
            const char = sql[i];
            const prevChar = i > 0 ? sql[i - 1] : null;

            // Handle string literals
            if ((char === "'" || char === '"') && prevChar !== '\\') {
                if (!inString) {
                    inString = true;
                    stringChar = char;
                } else if (char === stringChar) {
                    inString = false;
                    stringChar = null;
                }
                continue;
            }

            // Skip characters inside strings
            if (inString) continue;

            // Count parentheses
            if (char === '(') count++;
            if (char === ')') count--;

            // Check for negative count (more closing than opening)
            if (count < 0) {
                return {
                    valid: false,
                    message: `Unexpected closing parenthesis at position ${i}`
                };
            }
        }

        if (count !== 0) {
            return {
                valid: false,
                message: `Unmatched parentheses (${count > 0 ? 'missing closing' : 'extra closing'})`
            };
        }

        return { valid: true };
    }

    /**
     * Check string quotes
     */
    checkStringQuotes(sql) {
        let singleQuotes = 0;
        let doubleQuotes = 0;
        let prevChar = null;

        for (let i = 0; i < sql.length; i++) {
            const char = sql[i];

            // Skip escaped quotes
            if (prevChar === '\\') {
                prevChar = char;
                continue;
            }

            // Count quotes (handle doubled quotes like '' in SQL)
            if (char === "'") {
                if (i + 1 < sql.length && sql[i + 1] === "'") {
                    i++; // Skip doubled quote
                } else {
                    singleQuotes++;
                }
            }

            if (char === '"') {
                if (i + 1 < sql.length && sql[i + 1] === '"') {
                    i++; // Skip doubled quote
                } else {
                    doubleQuotes++;
                }
            }

            prevChar = char;
        }

        if (singleQuotes % 2 !== 0) {
            return {
                valid: false,
                message: 'Unmatched single quotes'
            };
        }

        if (doubleQuotes % 2 !== 0) {
            return {
                valid: false,
                message: 'Unmatched double quotes'
            };
        }

        return { valid: true };
    }

    /**
     * Check for suspicious patterns (basic SQL injection detection)
     */
    hasSuspiciousPatterns(sql) {
        const suspiciousPatterns = [
            /;\s*DROP\s+/i,
            /;\s*DELETE\s+FROM/i,
            /UNION\s+SELECT.*PASSWORD/i,
            /1\s*=\s*1/,
            /'.*OR.*'.*=.*'/i
        ];

        return suspiciousPatterns.some(pattern => pattern.test(sql));
    }

    /**
     * Check basic SQL structure
     */
    checkBasicStructure(sql) {
        const warnings = [];

        // Check for common mistakes
        if (/SELECT\s+\*\s+FROM/i.test(sql)) {
            // SELECT * is common and valid, but could be noted
            // (not adding warning for this as it's too common and valid)
        }

        // Check for missing spaces around operators
        if (/\w+=\w+/.test(sql)) {
            warnings.push('Consider adding spaces around = operator');
        }

        // Check for uppercase/lowercase consistency (just a note, not critical)
        const upperKeywords = (sql.match(/\b(SELECT|FROM|WHERE|JOIN|GROUP BY|ORDER BY|HAVING)\b/g) || []).length;
        const lowerKeywords = (sql.match(/\b(select|from|where|join|group by|order by|having)\b/g) || []).length;
        
        if (upperKeywords > 0 && lowerKeywords > 0 && Math.abs(upperKeywords - lowerKeywords) < 3) {
            warnings.push('Mixed case SQL keywords (consider consistent casing)');
        }

        return { warnings };
    }

    /**
     * Log helper
     */
    log(message) {
        if (this.debugHelper) {
            this.debugHelper.log(`[VALIDATOR] ${message}`);
        }
    }

    /**
     * Format validation result as user-friendly message
     */
    formatValidationMessage(validation) {
        if (validation.isValid && validation.warnings.length === 0) {
            return '✅ SQL is valid';
        }

        let message = '';

        if (!validation.isValid) {
            message += '❌ SQL Validation Failed:\n';
            message += validation.errors.map(e => `  • ${e}`).join('\n');
        }

        if (validation.warnings.length > 0) {
            if (message) message += '\n\n';
            message += '⚠️ Warnings:\n';
            message += validation.warnings.map(w => `  • ${w}`).join('\n');
        }

        message += `\n\n📊 Quality Score: ${validation.score}/100`;

        return message;
    }
}

module.exports = SQLValidator;
