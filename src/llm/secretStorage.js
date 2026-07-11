/**
 * Secure API token storage via VS Code SecretStorage.
 */

const vscode = require('vscode');
const extensionConfig = require('../config');

const SECRET_KEY = 'sqlSnippetStudio.llm.apiToken';

let secretStorage = null;

function initialize(context) {
    secretStorage = context.secrets;
}

async function getApiToken() {
    if (!secretStorage) {
        return '';
    }
    const stored = await secretStorage.get(SECRET_KEY);
    return stored || '';
}

async function setApiToken(token) {
    if (!secretStorage) {
        throw new Error('Secret storage is not initialized.');
    }
    await secretStorage.store(SECRET_KEY, token.trim());
}

async function clearApiToken() {
    if (!secretStorage) {
        return;
    }
    await secretStorage.delete(SECRET_KEY);
}

async function hasApiToken() {
    const token = await getApiToken();
    return token.length > 0;
}

/**
 * One-time migration from plaintext settings to SecretStorage.
 */
async function migratePlaintextApiKeyIfNeeded() {
    if (!secretStorage) {
        return false;
    }

    const existing = await getApiToken();
    if (existing) {
        return false;
    }

    const plaintext = extensionConfig.getSection('llm', 'apiKey', '');
    if (!plaintext || !String(plaintext).trim()) {
        return false;
    }

    const confirm = await vscode.window.showWarningMessage(
        'SQL Snippet Studio found a plaintext LLM API key in settings. Move it to secure storage?',
        { modal: true },
        'Move to secure storage',
        'Cancel'
    );

    if (confirm !== 'Move to secure storage') {
        return false;
    }

    await setApiToken(String(plaintext).trim());
    await clearPlaintextApiKeyFromSettings();
    return true;
}

async function clearPlaintextApiKeyFromSettings() {
    for (const namespace of [extensionConfig.NEW_NAMESPACE, extensionConfig.LEGACY_NAMESPACE]) {
        const config = vscode.workspace.getConfiguration(namespace);
        const inspect = config.inspect('llm.apiKey');
        if (!inspect) {
            continue;
        }
        if (inspect.globalValue !== undefined) {
            await config.update('llm.apiKey', undefined, vscode.ConfigurationTarget.Global);
        }
        if (inspect.workspaceValue !== undefined) {
            await config.update('llm.apiKey', undefined, vscode.ConfigurationTarget.Workspace);
        }
        if (inspect.workspaceFolderValue !== undefined) {
            await config.update('llm.apiKey', undefined, vscode.ConfigurationTarget.WorkspaceFolder);
        }
    }
}

module.exports = {
    SECRET_KEY,
    initialize,
    getApiToken,
    setApiToken,
    clearApiToken,
    hasApiToken,
    migratePlaintextApiKeyIfNeeded,
    clearPlaintextApiKeyFromSettings
};
