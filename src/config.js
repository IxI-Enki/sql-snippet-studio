/**
 * Settings: sqlSnippetStudio (primary) with dbiSurvivalKit legacy fallback.
 */

const vscode = require('vscode');

const NEW_NAMESPACE = 'sqlSnippetStudio';
const LEGACY_NAMESPACE = 'dbiSurvivalKit';

const DEFAULTS = {
    llm: {
        enabled: false,
        endpoint: 'http://localhost:1234/v1/chat/completions',
        model: 'qwen2.5-coder-32b-instruct',
        maxTokens: 500,
        temperature: 0.1,
        timeout: 10000,
        autoCompletion: false,
        showDebugInfo: false,
        showNotifications: false,
        verboseLogging: false
    }
};

const DEFAULT_LLM_MODEL = DEFAULTS.llm.model;
const DEFAULT_LLM_ENDPOINT = DEFAULTS.llm.endpoint;
const LLM_DEFAULTS = DEFAULTS.llm;

function inspectHasUserValue(inspectResult) {
    if (!inspectResult) {
        return false;
    }

    return inspectResult.globalValue !== undefined
        || inspectResult.workspaceValue !== undefined
        || inspectResult.workspaceFolderValue !== undefined;
}

function get(key, defaultValue) {
    const newConfig = vscode.workspace.getConfiguration(NEW_NAMESPACE);
    const legacyConfig = vscode.workspace.getConfiguration(LEGACY_NAMESPACE);
    const inspect = newConfig.inspect(key);

    if (inspectHasUserValue(inspect)) {
        return newConfig.get(key, defaultValue);
    }

    return legacyConfig.get(key, defaultValue);
}

function getSection(section, key, defaultValue) {
    return get(section ? `${section}.${key}` : key, defaultValue);
}

function isValidHttpEndpoint(value) {
    if (typeof value !== 'string' || !value.trim()) {
        return false;
    }
    try {
        const url = new URL(value.trim());
        return url.protocol === 'http:' || url.protocol === 'https:';
    } catch {
        return false;
    }
}

function sanitizeLlmConfig(raw) {
    const config = { ...DEFAULTS.llm, ...raw };

    if (!isValidHttpEndpoint(config.endpoint)) {
        config.endpoint = DEFAULTS.llm.endpoint;
    }

    if (typeof config.model !== 'string' || !config.model.trim()) {
        config.model = DEFAULTS.llm.model;
    } else {
        config.model = config.model.trim();
    }

    if (!Number.isFinite(config.maxTokens) || config.maxTokens <= 0) {
        config.maxTokens = DEFAULTS.llm.maxTokens;
    }

    if (!Number.isFinite(config.temperature) || config.temperature < 0 || config.temperature > 2) {
        config.temperature = DEFAULTS.llm.temperature;
    }

    if (!Number.isFinite(config.timeout) || config.timeout <= 0) {
        config.timeout = DEFAULTS.llm.timeout;
    }

    return config;
}

function getLlmConfig() {
    return sanitizeLlmConfig({
        enabled: getSection('llm', 'enabled', DEFAULTS.llm.enabled),
        endpoint: getSection('llm', 'endpoint', DEFAULTS.llm.endpoint),
        model: getSection('llm', 'model', DEFAULTS.llm.model),
        maxTokens: getSection('llm', 'maxTokens', DEFAULTS.llm.maxTokens),
        temperature: getSection('llm', 'temperature', DEFAULTS.llm.temperature),
        timeout: getSection('llm', 'timeout', DEFAULTS.llm.timeout),
        autoCompletion: getSection('llm', 'autoCompletion', DEFAULTS.llm.autoCompletion),
        showDebugInfo: getSection('llm', 'showDebugInfo', DEFAULTS.llm.showDebugInfo),
        showNotifications: getSection('llm', 'showNotifications', DEFAULTS.llm.showNotifications),
        verboseLogging: getSection('llm', 'verboseLogging', DEFAULTS.llm.verboseLogging)
    });
}

function affectsExtensionConfig(event) {
    return event.affectsConfiguration(NEW_NAMESPACE)
        || event.affectsConfiguration(LEGACY_NAMESPACE);
}

module.exports = {
    NEW_NAMESPACE,
    LEGACY_NAMESPACE,
    DEFAULTS,
    DEFAULT_LLM_MODEL,
    DEFAULT_LLM_ENDPOINT,
    LLM_DEFAULTS,
    get,
    getSection,
    getLlmConfig,
    getLLMConfig: getLlmConfig,
    sanitizeLlmConfig,
    affectsExtensionConfig
};
