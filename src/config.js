/**
 * Backward-compatible settings access for sqlSnippetStudio (new) and dbiSurvivalKit (legacy).
 */

const vscode = require('vscode');

const NEW_NAMESPACE = 'sqlSnippetStudio';
const LEGACY_NAMESPACE = 'dbiSurvivalKit';

function inspectHasUserValue(inspectResult) {
    if (!inspectResult) {
        return false;
    }

    return inspectResult.globalValue !== undefined
        || inspectResult.workspaceValue !== undefined
        || inspectResult.workspaceFolderValue !== undefined;
}

/**
 * Read a setting, preferring sqlSnippetStudio when explicitly set, else dbiSurvivalKit.
 * @param {string} key Dotted key relative to extension root (e.g. "llm.enabled")
 * @param {*} defaultValue
 * @returns {*}
 */
function get(key, defaultValue) {
    const newConfig = vscode.workspace.getConfiguration(NEW_NAMESPACE);
    const legacyConfig = vscode.workspace.getConfiguration(LEGACY_NAMESPACE);
    const inspect = newConfig.inspect(key);

    if (inspectHasUserValue(inspect)) {
        return newConfig.get(key, defaultValue);
    }

    return legacyConfig.get(key, defaultValue);
}

/**
 * Read a setting from a subsection (e.g. section "llm", key "enabled").
 * @param {string} section
 * @param {string} key
 * @param {*} defaultValue
 * @returns {*}
 */
function getSection(section, key, defaultValue) {
    return get(section ? `${section}.${key}` : key, defaultValue);
}

/**
 * Whether a configuration change event affects extension settings.
 * @param {vscode.ConfigurationChangeEvent} event
 * @returns {boolean}
 */
function affectsExtensionConfig(event) {
    return event.affectsConfiguration(NEW_NAMESPACE)
        || event.affectsConfiguration(LEGACY_NAMESPACE);
}

module.exports = {
    NEW_NAMESPACE,
    LEGACY_NAMESPACE,
    get,
    getSection,
    affectsExtensionConfig
};
