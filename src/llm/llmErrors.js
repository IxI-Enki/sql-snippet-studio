/**
 * Structured LLM error types for user-facing handling.
 */

class LlmError extends Error {
    constructor(code, message, remediation = '') {
        super(message);
        this.name = 'LlmError';
        this.code = code;
        this.remediation = remediation;
    }
}

class AuthenticationError extends LlmError {
    constructor(code, message, remediation) {
        super(code, message, remediation);
        this.name = 'AuthenticationError';
    }
}

class EndpointError extends LlmError {
    constructor(code, message, remediation) {
        super(code, message, remediation);
        this.name = 'EndpointError';
    }
}

class ModelError extends LlmError {
    constructor(message, remediation) {
        super('MODEL_ERROR', message, remediation);
        this.name = 'ModelError';
    }
}

class TimeoutError extends LlmError {
    constructor(message, remediation) {
        super('TIMEOUT', message, remediation);
        this.name = 'TimeoutError';
    }
}

class ResponseError extends LlmError {
    constructor(code, message, remediation) {
        super(code, message, remediation);
        this.name = 'ResponseError';
    }
}

function mapHttpStatusToError(statusCode, body) {
    const bodyText = typeof body === 'string' ? body : JSON.stringify(body);
    const lower = bodyText.toLowerCase();

    if (statusCode === 401 || lower.includes('invalid_api_key') || lower.includes('api token is required')) {
        return new AuthenticationError(
            'AUTH_UNAUTHORIZED',
            'LM Studio rejected the request (401 Unauthorized).',
            'Run SQL: Set LLM API Token and paste the token from LM Studio Developer > Server Settings.'
        );
    }

    if (statusCode === 404 || lower.includes('unexpected endpoint')) {
        return new EndpointError(
            'ENDPOINT_NOT_FOUND',
            `LLM endpoint returned ${statusCode}.`,
            'Set sqlSnippetStudio.llm.endpoint to http://localhost:1234/v1/chat/completions and ensure LM Studio server is running.'
        );
    }

    if (statusCode === 400 && (lower.includes('model') || lower.includes('not found'))) {
        return new ModelError(
            'The configured model is not loaded on the LLM server.',
            'Load the model in LM Studio and set sqlSnippetStudio.llm.model to the exact model identifier.'
        );
    }

    return new LlmError(
        'HTTP_ERROR',
        `LLM request failed with status ${statusCode}: ${bodyText.substring(0, 300)}`,
        'Check the SQL Snippet Studio - LLM output channel for details.'
    );
}

module.exports = {
    LlmError,
    AuthenticationError,
    EndpointError,
    ModelError,
    TimeoutError,
    ResponseError,
    mapHttpStatusToError
};
