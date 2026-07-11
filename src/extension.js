const vscode = require('vscode');

const ContextBuilder = require('./llm/contextBuilder');
const LLMProvider = require('./llm/llmProvider');
const DebugHelper = require('./llm/debugHelper');
const QueryCache = require('./llm/queryCache');
const CompletionCoordinator = require('./llm/completionCoordinator');
const extensionConfig = require('./config');
const secretStorage = require('./llm/secretStorage');
const { LlmError } = require('./llm/llmErrors');

let debugHelper = null;
let queryCache = null;
let llmProvider = null;

const AUTO_DEBOUNCE_MS = 800;
const completionCoordinator = new CompletionCoordinator(AUTO_DEBOUNCE_MS);

const LEGACY_COMMAND_NAMESPACE = 'dbiSurvivalKit';

function registerCommand(context, commandName, handler) {
    context.subscriptions.push(
        vscode.commands.registerCommand(`sqlSnippetStudio.${commandName}`, handler)
    );
    context.subscriptions.push(
        vscode.commands.registerCommand(`${LEGACY_COMMAND_NAMESPACE}.${commandName}`, handler)
    );
}

function createLlmProvider() {
    return new LLMProvider(debugHelper, queryCache, {
        tokenProvider: () => secretStorage.getApiToken()
    });
}

function refreshRuntimeState() {
    if (debugHelper) {
        debugHelper.updateConfig();
    }
    if (llmProvider) {
        llmProvider.updateConfig();
    }
}

function formatLlmError(error) {
    if (error instanceof LlmError) {
        return error.remediation ? `${error.message}\n\n${error.remediation}` : error.message;
    }
    return error.message;
}

async function activate(context) {
    console.log('SQL Snippet Studio is now active!');

    debugHelper = new DebugHelper();
    debugHelper.initialize(context);
    queryCache = new QueryCache();
    secretStorage.initialize(context);
    llmProvider = createLlmProvider();

    registerCommands(context);
    registerCompletionProvider(context);
    showWelcomeMessage(context);

    context.subscriptions.push(
        vscode.workspace.onDidChangeConfiguration(event => {
            if (extensionConfig.affectsExtensionConfig(event)) {
                refreshRuntimeState();
            }
        })
    );

    await secretStorage.migratePlaintextApiKeyIfNeeded();
    refreshRuntimeState();
}

function registerCommands(context) {
    registerCommand(context, 'insertStarSchema', () => insertTemplate('star-schema'));
    registerCommand(context, 'insertDimensionTable', () => insertTemplate('dim-table'));
    registerCommand(context, 'insertFactTable', () => insertTemplate('fact-table'));
    registerCommand(context, 'showLLMStats', () => {
        if (debugHelper) {
            debugHelper.showStats();
        }
    });
    registerCommand(context, 'clearCache', () => {
        if (queryCache) {
            queryCache.clear();
            vscode.window.showInformationMessage('LLM cache cleared.');
        }
    });
    registerCommand(context, 'queryLLM', async () => executeLLMQuery());
    registerCommand(context, 'setLlmApiToken', async () => setLlmApiToken());
    registerCommand(context, 'clearLlmApiToken', async () => clearLlmApiToken());
    registerCommand(context, 'testLlmConnection', async () => testLlmConnection());
}

async function setLlmApiToken() {
    const token = await vscode.window.showInputBox({
        prompt: 'Paste your LM Studio API token',
        password: true,
        ignoreFocusOut: true,
        placeHolder: 'sk-lm-...'
    });

    if (!token || !token.trim()) {
        return;
    }

    await secretStorage.setApiToken(token.trim());
    vscode.window.showInformationMessage('LLM API token stored securely.');
}

async function clearLlmApiToken() {
    await secretStorage.clearApiToken();
    vscode.window.showInformationMessage('LLM API token cleared.');
}

async function testLlmConnection() {
    const config = extensionConfig.getLlmConfig();
    if (!config.enabled) {
        vscode.window.showWarningMessage('Enable sqlSnippetStudio.llm.enabled before testing the connection.');
        return;
    }

    try {
        await llmProvider.testConnection();
        if (debugHelper) {
            debugHelper.markConnectionReady();
        }
        vscode.window.showInformationMessage('LLM connection successful.');
    } catch (error) {
        vscode.window.showErrorMessage(formatLlmError(error), 'Show Log').then(selection => {
            if (selection === 'Show Log' && debugHelper) {
                debugHelper.logRequestError(error);
            }
        });
    }
}

async function executeLLMQuery() {
    const config = extensionConfig.getLlmConfig();

    try {
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            vscode.window.showErrorMessage('No active editor.');
            return;
        }

        if (!config.enabled) {
            vscode.window.showWarningMessage('LLM is disabled. Enable sqlSnippetStudio.llm.enabled in settings.');
            return;
        }

        if (config.showNotifications) {
            vscode.window.showInformationMessage('Querying LLM...');
        }

        if (debugHelper) {
            debugHelper.updateStatusBar('requesting');
            debugHelper.log('[COMMAND] LLM Query triggered by user');
        }

        const document = editor.document;
        const position = editor.selection.active;
        const documentText = document.getText();
        const contextBuilder = new ContextBuilder();
        const llmContext = contextBuilder.buildContext(documentText, position.line);

        if (!llmContext || !llmContext.task) {
            if (config.showNotifications) {
                vscode.window.showWarningMessage('No task found at cursor position.\n\nPlace the cursor below a comment like:\n-- Task: ...');
            }
            if (debugHelper) {
                debugHelper.log('[COMMAND] No task found');
                debugHelper.refreshStatusBar();
            }
            return;
        }

        if (debugHelper) {
            debugHelper.log(`[COMMAND] Task found: "${llmContext.task}"`);
            debugHelper.log(`[COMMAND] Schemas found: ${llmContext.schemas.length}`);
        }

        llmContext.stopSequences = contextBuilder.getStopSequences();
        const result = await llmProvider.query(llmContext.prompt, llmContext);

        if (!result || !result.sql) {
            if (config.showNotifications) {
                vscode.window.showErrorMessage('LLM returned an empty response. Check the output channel for details.');
            }
            if (debugHelper) {
                debugHelper.log('[COMMAND] LLM returned empty query');
                debugHelper.refreshStatusBar();
            }
            return;
        }

        const { sql: sqlQuery, validation } = result;

        if (debugHelper) {
            debugHelper.log(`[COMMAND] LLM returned query: ${sqlQuery.substring(0, 200)}...`);
            debugHelper.log(`[COMMAND] Validation score: ${validation.score}/100`);
            debugHelper.refreshStatusBar();
        }

        await editor.edit(editBuilder => {
            editBuilder.insert(position, '\n' + sqlQuery + '\n');
        });

        if (config.showNotifications) {
            if (validation.isValid) {
                if (validation.warnings.length > 0) {
                    vscode.window.showWarningMessage(`Query inserted with warnings (Score: ${validation.score}/100)\n${validation.warnings[0]}`);
                } else {
                    vscode.window.showInformationMessage(`Query inserted (Score: ${validation.score}/100)`);
                }
            } else {
                vscode.window.showWarningMessage(`Query may have issues (Score: ${validation.score}/100)\n${validation.errors[0]}`);
            }
        }
    } catch (error) {
        if (config.showNotifications) {
            const authenticationCodes = new Set(['AUTH_TOKEN_MISSING', 'AUTH_UNAUTHORIZED']);
            vscode.window.showErrorMessage(
                formatLlmError(error),
                ...(authenticationCodes.has(error.code) ? ['Set API Token'] : [])
            ).then(selection => {
                if (selection === 'Set API Token') {
                    vscode.commands.executeCommand('sqlSnippetStudio.setLlmApiToken');
                }
            });
        }
        if (debugHelper) {
            debugHelper.log(`[COMMAND] Error: ${error.message}`);
            debugHelper.logRequestError(error);
        }
    }
}

function registerCompletionProvider(context) {
    const contextBuilder = new ContextBuilder();

    const provider = vscode.languages.registerCompletionItemProvider(
        ['sql', 'plsql'],
        {
            async provideCompletionItems(document, position) {
                const config = extensionConfig.getLlmConfig();
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                const completions = [];

                if (linePrefix.includes('CREATE TABLE')) {
                    completions.push(createCompletion('DIM_ (Dimension Table)', 'DIM_', 'Start of a dimension table name'));
                    completions.push(createCompletion('FACT_ (Fact Table)', 'FACT_', 'Start of a fact table name'));
                }

                if (linePrefix.includes('FOREIGN KEY')) {
                    completions.push(createCompletion('ON DELETE CASCADE', 'ON DELETE CASCADE', 'Cascade delete to child records'));
                    completions.push(createCompletion('ON DELETE SET NULL', 'ON DELETE SET NULL', 'Set foreign key to NULL on delete'));
                }

                if (linePrefix.match(/DIM_\w+\s*\(/)) {
                    completions.push(createCompletion('Surrogate Key', '${1:dim}_key INTEGER PRIMARY KEY,\n    ', 'Standard surrogate key for dimension'));
                }

                if (config.enabled && config.autoCompletion && contextBuilder.shouldTriggerCompletion(linePrefix, position.character)) {
                    const llmCompletion = await getLLMCompletion(document, position, contextBuilder);
                    if (llmCompletion) {
                        completions.push(llmCompletion);
                    }
                }

                return completions;
            }
        },
        '.', ' ', ';', '-'
    );

    context.subscriptions.push(provider);
}

async function getLLMCompletion(document, position, contextBuilder) {
    const config = extensionConfig.getLlmConfig();

    if (!config.enabled || !config.autoCompletion) {
        return null;
    }

    const documentText = document.getText();
    const cursorLine = position.line;
    const llmContext = contextBuilder.buildContext(documentText, cursorLine);

    if (!llmContext || !llmContext.task) {
        return null;
    }

    try {
        return await completionCoordinator.schedule(
            document.uri.toString(),
            llmContext.task,
            async signal => {
                if (debugHelper) {
                    debugHelper.log(`[AUTO] Task found: "${llmContext.task}"`);
                }

                llmContext.stopSequences = contextBuilder.getStopSequences();
                const result = await llmProvider.query(
                    llmContext.prompt,
                    llmContext,
                    { signal }
                );

                if (!result || !result.sql) {
                    return null;
                }

                const sqlQuery = result.sql;
                const debugLabel = debugHelper ? debugHelper.getDebugLabel('llm') : '';
                const completion = new vscode.CompletionItem(
                    `${debugLabel} AI: ${llmContext.task.substring(0, 50)}...`,
                    vscode.CompletionItemKind.Snippet
                );

                completion.insertText = sqlQuery;
                completion.detail = 'AI-generated SQL query';
                completion.documentation = new vscode.MarkdownString(
                    `**Task:** ${llmContext.task}\n\n` +
                    `**Schema:**\n\`\`\`sql\n${llmContext.schemaText}\n\`\`\`\n\n` +
                    `**Generated Query:**\n\`\`\`sql\n${sqlQuery}\n\`\`\``
                );
                completion.sortText = '0000';
                completion.preselect = true;
                return completion;
            }
        );
    } catch (error) {
        if (error.code !== 'ABORTED' && debugHelper) {
            debugHelper.logRequestError(error);
        }
        return null;
    }
}

function createCompletion(label, insertText, documentation) {
    const completion = new vscode.CompletionItem(label);
    completion.insertText = new vscode.SnippetString(insertText);
    completion.documentation = new vscode.MarkdownString(documentation);
    return completion;
}

function insertTemplate(snippetPrefix) {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor');
        return;
    }

    vscode.commands.executeCommand('editor.action.insertSnippet', {
        name: snippetPrefix
    });
}

function showWelcomeMessage(context) {
    const hasShownWelcome = context.globalState.get('hasShownWelcome');

    if (!hasShownWelcome) {
        vscode.window.showInformationMessage(
            'SQL Snippet Studio activated. Type "star-schema" and press Tab to get started.',
            'Show Commands'
        ).then(selection => {
            if (selection === 'Show Commands') {
                vscode.commands.executeCommand('workbench.action.showCommands');
            }
        });

        context.globalState.update('hasShownWelcome', true);
    }
}

function deactivate() {
    console.log('SQL Snippet Studio deactivated');

    if (debugHelper) {
        debugHelper.dispose();
    }
    if (queryCache) {
        queryCache.clear();
    }
    completionCoordinator.dispose();
}

module.exports = {
    activate,
    deactivate
};
