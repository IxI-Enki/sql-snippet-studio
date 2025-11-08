/**
 * LLM Provider - Verbindung zu lokalem oder Remote-LLM
 */

const vscode = require('vscode');
const https = require('https');
const http = require('http');

class LLMProvider {
    constructor() {
        this.config = null;
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
     * @returns {Promise<string>} Die generierte SQL-Query
     */
    async query(prompt) {
        if (!this.config.enabled) {
            return null;
        }

        try {
            const response = await this.sendRequest(prompt);
            return this.extractSQL(response);
        } catch (error) {
            console.error('[DBI Survival Kit] LLM query failed:', error.message);
            return null;
        }
    }

    /**
     * Sendet HTTP-Request an LLM-Endpoint
     * @param {string} prompt - Der Prompt
     * @returns {Promise<string>} Die Antwort vom LLM
     */
    async sendRequest(prompt) {
        return new Promise((resolve, reject) => {
            const url = new URL(this.config.endpoint);
            const isHttps = url.protocol === 'https:';
            const client = isHttps ? https : http;

            const requestData = JSON.stringify({
                model: this.config.model,
                messages: [
                    {
                        role: 'system',
                        content: 'You are a SQL expert. Provide only SQL queries without explanations.'
                    },
                    {
                        role: 'user',
                        content: prompt
                    }
                ],
                max_tokens: this.config.maxTokens,
                temperature: this.config.temperature,
                stream: false
            });

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
     * Extrahiert saubere SQL-Query aus LLM-Response
     * @param {string} response - Die LLM-Antwort
     * @returns {string} Die extrahierte SQL-Query
     */
    extractSQL(response) {
        if (!response) {
            return null;
        }

        // Entferne Markdown Code-Blocks
        let sql = response.replace(/```sql\n?/gi, '').replace(/```\n?/g, '');
        
        // Entferne führende/trailing Whitespace
        sql = sql.trim();
        
        // Entferne Erklärungen (alles nach dem ersten Semikolon und Leerzeile)
        const firstQuery = sql.split(/;\s*\n\s*\n/)[0];
        if (firstQuery) {
            sql = firstQuery + (firstQuery.endsWith(';') ? '' : ';');
        }

        return sql;
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

