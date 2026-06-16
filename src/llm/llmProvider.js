/**
 * LLM Provider - Verbindung zu lokalem oder Remote-LLM
 */

const vscode = require('vscode');
const https = require('https');
const http = require('http');
const ResponseParser = require('./responseParser');
const SQLValidator = require('./sqlValidator');

class LLMProvider {
    constructor(debugHelper = null, queryCache = null) {
        this.config = null;
        this.debugHelper = debugHelper;
        this.queryCache = queryCache;
        this.responseParser = new ResponseParser(debugHelper);
        this.sqlValidator = new SQLValidator(debugHelper);
        this.updateConfig();
    }

    /**
     * Aktualisiert die Konfiguration aus VS Code Settings
     */
    updateConfig() {
        const config = vscode.workspace.getConfiguration('dbiSurvivalKit');
        
        this.config = {
            enabled: config.get('llm.enabled', false),
            endpoint: config.get('llm.endpoint', 'http://localhost:1234/v1/chat/completions'),
            model: config.get('llm.model', 'qwen2.5-coder'),
            apiKey: config.get('llm.apiKey', ''),
            maxTokens: config.get('llm.maxTokens', 500),
            temperature: config.get('llm.temperature', 0.1),
            timeout: config.get('llm.timeout', 10000)
        };
    }

    /**
     * Sendet Query an LLM
     * @param {string} prompt - Der Prompt für das LLM
     * @param {Object} context - Context für Caching
     * @returns {Promise<Object>} Object mit { sql, validation }
     */
    async query(prompt, context = null) {
        if (!this.config.enabled) {
            return null;
        }

        const startTime = Date.now();

        try {
            // Check cache first
            if (this.queryCache && context) {
                const cached = this.queryCache.get(context);
                if (cached) {
                    if (this.debugHelper) {
                        this.debugHelper.logCacheHit(context.task);
                    }
                    return cached;
                }
            }

            // Log request start
            if (this.debugHelper && context) {
                this.debugHelper.logRequestStart(context.task, context.schemas);
            }

            // Query LLM with stop sequences
            const stopSequences = context?.stopSequences || [];
            const response = await this.sendRequest(prompt, stopSequences);
            
            if (this.debugHelper) {
                this.debugHelper.log(`[LLM] Raw response length: ${response.length} chars`);
            }

            // Parse response with advanced parser
            const sqlQuery = this.responseParser.parse(response);
            
            if (!sqlQuery) {
                throw new Error('Failed to extract SQL from LLM response');
            }

            // Validate SQL
            const validation = this.sqlValidator.validate(sqlQuery);
            
            if (this.debugHelper) {
                this.debugHelper.log(`[LLM] Validation score: ${validation.score}/100`);
                if (!validation.isValid) {
                    this.debugHelper.log(`[LLM] Validation errors: ${validation.errors.join(', ')}`);
                }
            }

            const result = {
                sql: sqlQuery,
                validation: validation
            };

            // Cache result (only if validation passes)
            if (this.queryCache && context && validation.isValid) {
                this.queryCache.set(context, result);
            }

            // Log success
            if (this.debugHelper) {
                const duration = Date.now() - startTime;
                this.debugHelper.logRequestSuccess(sqlQuery, duration);
            }

            return result;

        } catch (error) {
            console.error('[SQL Snippet Studio] LLM query failed:', error.message);
            
            if (this.debugHelper) {
                this.debugHelper.logRequestError(error);
            }
            
            return null;
        }
    }

    /**
     * Sendet HTTP-Request an LLM-Endpoint
     * @param {string} prompt - Der Prompt
     * @param {Array} stopSequences - Optional stop sequences
     * @returns {Promise<string>} Die Antwort vom LLM
     */
    async sendRequest(prompt, stopSequences = []) {
        return new Promise((resolve, reject) => {
            const url = new URL(this.config.endpoint);
            const isHttps = url.protocol === 'https:';
            const client = isHttps ? https : http;

            // Enhanced system message with strict instructions
            const systemMessage = `You are an expert SQL code generator. Generate ONLY valid SQL queries.
RULES: 
- No explanations, no markdown, no comments
- No <think> tags or reasoning
- Start directly with SQL keywords (SELECT/INSERT/UPDATE/DELETE/CREATE)
- End with semicolon (;)`;

            const requestBody = {
                model: this.config.model,
                messages: [
                    {
                        role: 'system',
                        content: systemMessage
                    },
                    {
                        role: 'user',
                        content: prompt
                    }
                ],
                max_tokens: this.config.maxTokens,
                temperature: this.config.temperature,
                stream: false
            };

            // Add stop sequences if provided
            if (stopSequences && stopSequences.length > 0) {
                requestBody.stop = stopSequences;
            }

            const requestData = JSON.stringify(requestBody);

            const options = {
                hostname: url.hostname,
                port: url.port || (isHttps ? 443 : 80),
                path: url.pathname + url.search,
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Content-Length': Buffer.byteLength(requestData)
                },
                timeout: this.config.timeout
            };

            // API Key hinzufügen wenn vorhanden
            if (this.config.apiKey) {
                options.headers['Authorization'] = `Bearer ${this.config.apiKey}`;
            }

            const req = client.request(options, (res) => {
                let data = '';

                res.on('data', (chunk) => {
                    data += chunk;
                });

                res.on('end', () => {
                    if (res.statusCode === 200) {
                        try {
                            const json = JSON.parse(data);
                            const content = json.choices?.[0]?.message?.content || '';
                            resolve(content);
                        } catch (error) {
                            reject(new Error(`Failed to parse LLM response: ${error.message}`));
                        }
                    } else {
                        reject(new Error(`LLM request failed with status ${res.statusCode}: ${data}`));
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            req.on('timeout', () => {
                req.destroy();
                reject(new Error('LLM request timeout'));
            });

            req.write(requestData);
            req.end();
        });
    }

    /**
     * DEPRECATED: Use responseParser.parse() instead
     * Kept for backward compatibility
     */
    extractSQL(response) {
        return this.responseParser.parse(response);
    }

    /**
     * Test-Methode um LLM-Verbindung zu prüfen
     * @returns {Promise<boolean>} true wenn LLM erreichbar ist
     */
    async testConnection() {
        try {
            const response = await this.query('SELECT 1 as test;');
            return response !== null;
        } catch (error) {
            return false;
        }
    }
}

module.exports = LLMProvider;
