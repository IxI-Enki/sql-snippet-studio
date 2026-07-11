/**
 * LLM Provider - Verbindung zu lokalem oder Remote-LLM
 */

const https = require('https');
const http = require('http');
const ResponseParser = require('./responseParser');
const SQLValidator = require('./sqlValidator');
const extensionConfig = require('../config');
const {
    LlmError,
    AuthenticationError,
    TimeoutError,
    ResponseError,
    EndpointError,
    mapHttpStatusToError
} = require('./llmErrors');

class LLMProvider {
    constructor(debugHelper = null, queryCache = null, tokenOrOptions = null) {
        this.config = null;
        this.debugHelper = debugHelper;
        this.queryCache = queryCache;
        const options = tokenOrOptions && typeof tokenOrOptions === 'object'
            ? tokenOrOptions
            : {};
        this.configOverride = options.config || null;
        this.getApiToken = options.tokenProvider
            || (typeof tokenOrOptions === 'function' ? tokenOrOptions : async () => '');
        this.responseParser = new ResponseParser(debugHelper);
        this.sqlValidator = new SQLValidator(debugHelper);
        this.updateConfig();
    }

    updateConfig() {
        this.config = this.configOverride || extensionConfig.getLLMConfig();
    }

    /**
     * @returns {Promise<{sql: string, validation: object}|null>}
     */
    async query(prompt, context = null, options = {}) {
        if (!this.config.enabled) {
            return null;
        }

        const startTime = Date.now();

        try {
            if (this.queryCache && context) {
                const cached = this.queryCache.get(context, this.config);
                if (cached) {
                    if (this.debugHelper) {
                        this.debugHelper.logCacheHit(context.task);
                    }
                    return cached;
                }
            }

            if (this.debugHelper && context) {
                this.debugHelper.logRequestStart(context.task, context.schemas);
            }

            const stopSequences = context?.stopSequences || [];
            const response = await this.sendRequest(prompt, stopSequences, options.signal);

            if (this.debugHelper) {
                this.debugHelper.log(`[LLM] Raw response length: ${response.length} chars`);
            }

            const sqlQuery = this.responseParser.parse(response);

            if (!sqlQuery) {
                throw new ResponseError(
                    'EMPTY_RESPONSE',
                    'Failed to extract SQL from LLM response.',
                    'Try a code-focused model or lower temperature.'
                );
            }

            const validation = this.sqlValidator.validate(sqlQuery);

            if (this.debugHelper) {
                this.debugHelper.log(`[LLM] Validation score: ${validation.score}/100`);
                if (!validation.isValid) {
                    this.debugHelper.log(`[LLM] Validation errors: ${validation.errors.join(', ')}`);
                }
            }

            const result = { sql: sqlQuery, validation };

            if (this.queryCache && context && validation.isValid) {
                this.queryCache.set(context, result, this.config);
            }

            if (this.debugHelper) {
                const duration = Date.now() - startTime;
                this.debugHelper.logRequestSuccess(sqlQuery, duration);
            }

            return result;
        } catch (error) {
            if (this.debugHelper) {
                this.debugHelper.logRequestError(error);
            }
            throw error;
        }
    }

    async sendRequest(prompt, stopSequences = [], signal) {
        const apiToken = await this.getApiToken();
        if (!apiToken || !String(apiToken).trim()) {
            throw new AuthenticationError(
                'AUTH_TOKEN_MISSING',
                'No LLM API token is configured.',
                'Run SQL: Set LLM API Token and paste the token from LM Studio Developer > Server Settings.'
            );
        }
        return this.sendRequestWithToken(prompt, stopSequences, apiToken, signal);
    }

    sendRequestWithToken(prompt, stopSequences = [], apiToken = '', signal) {
        return new Promise((resolve, reject) => {
            if (signal?.aborted) {
                reject(new LlmError('ABORTED', 'LLM request was cancelled.'));
                return;
            }
            const url = new URL(this.config.endpoint);
            const isHttps = url.protocol === 'https:';
            const client = isHttps ? https : http;

            const systemMessage = `You are an expert SQL code generator. Generate ONLY valid SQL queries.
RULES: 
- No explanations, no markdown, no comments
- No <think> tags or reasoning
- Start directly with SQL keywords (SELECT/INSERT/UPDATE/DELETE/CREATE)
- End with semicolon (;)`;

            const requestBody = {
                model: this.config.model,
                messages: [
                    { role: 'system', content: systemMessage },
                    { role: 'user', content: prompt }
                ],
                max_tokens: this.config.maxTokens,
                temperature: this.config.temperature,
                stream: false
            };

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

            if (apiToken) {
                options.headers.Authorization = `Bearer ${apiToken}`;
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
                            if (!content) {
                                reject(new ResponseError(
                                    'EMPTY_RESPONSE',
                                    'LLM returned an empty response body.',
                                    'Check that the model is loaded and the endpoint is correct.'
                                ));
                                return;
                            }
                            resolve(content);
                        } catch (error) {
                            reject(new ResponseError(
                                'INVALID_RESPONSE',
                                `Failed to parse LLM response: ${error.message}`,
                                'Inspect the SQL Snippet Studio - LLM output channel.'
                            ));
                        }
                        return;
                    }

                    reject(mapHttpStatusToError(res.statusCode, data));
                });
            });

            const abortRequest = () => {
                req.destroy();
                reject(new LlmError('ABORTED', 'LLM request was cancelled.'));
            };
            signal?.addEventListener('abort', abortRequest, { once: true });
            req.on('close', () => signal?.removeEventListener('abort', abortRequest));

            req.on('error', (error) => {
                reject(new EndpointError(
                    'NETWORK_ERROR',
                    `Could not reach LLM endpoint: ${error.message}`,
                    'Start LM Studio server on port 1234 or verify sqlSnippetStudio.llm.endpoint.'
                ));
            });

            req.on('timeout', () => {
                req.destroy();
                reject(new TimeoutError(
                    'LLM request timed out.',
                    'Increase sqlSnippetStudio.llm.timeout or use a smaller model.'
                ));
            });

            req.write(requestData);
            req.end();
        });
    }

    extractSQL(response) {
        return this.responseParser.parse(response);
    }

    async testConnection() {
        const url = new URL(this.config.endpoint);
        const modelsUrl = `${url.protocol}//${url.hostname}:${url.port || (url.protocol === 'https:' ? 443 : 80)}/v1/models`;
        const apiToken = await this.getApiToken();
        if (!apiToken || !String(apiToken).trim()) {
            throw new AuthenticationError(
                'AUTH_TOKEN_MISSING',
                'No LLM API token is configured.',
                'Run SQL: Set LLM API Token before testing the connection.'
            );
        }
        const isHttps = url.protocol === 'https:';
        const client = isHttps ? https : http;
        const parsed = new URL(modelsUrl);

        return new Promise((resolve, reject) => {
            const options = {
                hostname: parsed.hostname,
                port: parsed.port || (isHttps ? 443 : 80),
                path: parsed.pathname + parsed.search,
                method: 'GET',
                headers: {},
                timeout: this.config.timeout
            };

            if (apiToken) {
                options.headers.Authorization = `Bearer ${apiToken}`;
            }

            const req = client.request(options, (res) => {
                let data = '';
                res.on('data', (chunk) => { data += chunk; });
                res.on('end', () => {
                    if (res.statusCode === 200) {
                        resolve(true);
                        return;
                    }
                    reject(mapHttpStatusToError(res.statusCode, data));
                });
            });

            req.on('error', (error) => {
                reject(new EndpointError(
                    'NETWORK_ERROR',
                    `Could not reach LLM endpoint: ${error.message}`,
                    'Start LM Studio and verify the server port.'
                ));
            });

            req.on('timeout', () => {
                req.destroy();
                reject(new TimeoutError('Connection test timed out.', 'Increase sqlSnippetStudio.llm.timeout.'));
            });

            req.end();
        });
    }
}

module.exports = LLMProvider;
module.exports.LLMProvider = LLMProvider;
module.exports.LLMProviderError = LlmError;
