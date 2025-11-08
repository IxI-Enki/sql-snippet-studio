const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

// LLM-Integration
const ContextBuilder = require('./llm/contextBuilder');
const LLMProvider = require('./llm/llmProvider');
const DebugHelper = require('./llm/debugHelper');
const QueryCache = require('./llm/queryCache');

// Global instances
let debugHelper = null;
let queryCache = null;

/**
 * Extension activation entry point
 */
function activate(context) {
    console.log('DBI Test Survival Kit is now active!');

    // Initialize global instances
    debugHelper = new DebugHelper();
    debugHelper.initialize(context);
    queryCache = new QueryCache();

    // Register commands
    registerCommands(context);
    
    // Register completion provider
    registerCompletionProvider(context);
    
    // Show welcome message on first activation
    showWelcomeMessage(context);

    // Register show stats command
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.showLLMStats', () => {
            if (debugHelper) {
                debugHelper.showStats();
            }
        })
    );

    // Register clear cache command
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.clearCache', () => {
            if (queryCache) {
                queryCache.clear();
                vscode.window.showInformationMessage('✅ LLM Cache cleared!');
            }
        })
    );

    // Listen for config changes
    context.subscriptions.push(
        vscode.workspace.onDidChangeConfiguration(e => {
            if (e.affectsConfiguration('dbiSurvivalKit')) {
                if (debugHelper) {
                    debugHelper.updateConfig();
                }
            }
        })
    );
}

/**
 * Register all extension commands
 */
function registerCommands(context) {
    // Insert Star Schema Template
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.insertStarSchema', () => {
            insertTemplate('star-schema');
        })
    );

    // Insert Dimension Table
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.insertDimensionTable', () => {
            insertTemplate('dim-table');
        })
    );

    // Insert Fact Table
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.insertFactTable', () => {
            insertTemplate('fact-table');
        })
    );

    // Share Snippets
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.shareSnippets', () => {
            exportSnippets();
        })
    );

    // Import Snippets
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.importSnippets', () => {
            importSnippets();
        })
    );

    // NEW: Direct LLM Query Command (Ctrl+Alt+Shift+Q)
    context.subscriptions.push(
        vscode.commands.registerCommand('dbiSurvivalKit.queryLLM', async () => {
            await executeLLMQuery();
        })
    );
}

/**
 * Execute LLM Query on current cursor position
 * This is the MAIN function that users will trigger via keyboard shortcut
 */
async function executeLLMQuery() {
    try {
        const editor = vscode.window.activeTextEditor;
        
        if (!editor) {
            vscode.window.showErrorMessage('No active editor!');
            return;
        }

        // Check if LLM is enabled
        const config = vscode.workspace.getConfiguration('dbiSurvivalKit.llm');
        const isEnabled = config.get('enabled', false);
        const showNotifications = config.get('showNotifications', false);
        
        if (!isEnabled) {
            vscode.window.showWarningMessage('🤖 LLM is disabled! Enable it in settings: dbiSurvivalKit.llm.enabled');
            return;
        }

        // Show immediate feedback (only if notifications enabled)
        if (showNotifications) {
            vscode.window.showInformationMessage('🤖 Querying LLM...');
        }
        
        if (debugHelper) {
            debugHelper.updateStatusBar('requesting');
            debugHelper.log('[COMMAND] LLM Query triggered by user');
        }

        const document = editor.document;
        const position = editor.selection.active;
        const documentText = document.getText();
        
        // Build context
        const contextBuilder = new ContextBuilder();
        const context = contextBuilder.buildContext(documentText, position.line);
        
        if (!context || !context.task) {
            if (showNotifications) {
                vscode.window.showWarningMessage('❌ No task found at cursor position!\n\nPlace cursor after a task comment like:\n-- Aufgabe 1: ...');
            }
            if (debugHelper) {
                debugHelper.log('[COMMAND] No task found');
                debugHelper.updateStatusBar('idle');
            }
            return;
        }

        if (debugHelper) {
            debugHelper.log(`[COMMAND] Task found: "${context.task}"`);
            debugHelper.log(`[COMMAND] Schemas found: ${context.schemas.length}`);
        }

        // Query LLM
        const llmProvider = new LLMProvider(debugHelper, queryCache);
        const sqlQuery = await llmProvider.query(context.prompt, context);

        if (!sqlQuery) {
            if (showNotifications) {
                vscode.window.showErrorMessage('❌ LLM returned empty response!\n\nCheck:\n- LM Studio is running\n- Model is loaded\n- Server is on port 1234');
            }
            if (debugHelper) {
                debugHelper.log('[COMMAND] LLM returned empty query');
                debugHelper.updateStatusBar('error');
            }
            return;
        }

        if (debugHelper) {
            debugHelper.log(`[COMMAND] LLM returned query: ${sqlQuery.substring(0, 200)}...`);
            debugHelper.updateStatusBar('idle');
        }

        // Insert the query at cursor position
        await editor.edit(editBuilder => {
            editBuilder.insert(position, '\n' + sqlQuery + '\n');
        });

        if (showNotifications) {
            vscode.window.showInformationMessage(`✅ LLM Query inserted! (${sqlQuery.length} chars)`);
        }

    } catch (error) {
        if (showNotifications) {
            vscode.window.showErrorMessage(`❌ LLM Error: ${error.message}`);
        }
        if (debugHelper) {
            debugHelper.log(`[COMMAND] Error: ${error.message}`);
            debugHelper.logError(error);
            debugHelper.updateStatusBar('error');
        }
    }
}

/**
 * Register intelligent completion provider (with LLM support)
 */
function registerCompletionProvider(context) {
    const contextBuilder = new ContextBuilder();
    const llmProvider = new LLMProvider(debugHelper, queryCache);

    const provider = vscode.languages.registerCompletionItemProvider(
        ['sql', 'plsql'],
        {
            async provideCompletionItems(document, position) {
                // DEBUG: Log every invocation
                if (debugHelper) {
                    debugHelper.log(`[TRIGGER] provideCompletionItems called at line ${position.line}, char ${position.character}`);
                }

                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                const completions = [];

                if (debugHelper) {
                    debugHelper.log(`[TRIGGER] Line prefix: "${linePrefix}"`);
                }

                // Standard completions (existing)
                if (linePrefix.includes('CREATE TABLE')) {
                    completions.push(createCompletion('DIM_ (Dimension Table)', 'DIM_', 
                        'Start of a dimension table name'));
                    completions.push(createCompletion('FACT_ (Fact Table)', 'FACT_', 
                        'Start of a fact table name'));
                }

                if (linePrefix.includes('FOREIGN KEY')) {
                    completions.push(createCompletion('ON DELETE CASCADE', 
                        'ON DELETE CASCADE', 'Cascade delete to child records'));
                    completions.push(createCompletion('ON DELETE SET NULL', 
                        'ON DELETE SET NULL', 'Set foreign key to NULL on delete'));
                }

                if (linePrefix.match(/DIM_\w+\s*\(/)) {
                    completions.push(createCompletion('Surrogate Key', 
                        '${1:dim}_key INTEGER PRIMARY KEY,\n    ', 
                        'Standard surrogate key for dimension'));
                }

                // LLM-based completion (NEW!)
                if (contextBuilder.shouldTriggerCompletion(linePrefix, position.character)) {
                    const llmCompletion = await getLLMCompletion(
                        document, 
                        position, 
                        contextBuilder, 
                        llmProvider
                    );

                    if (llmCompletion) {
                        completions.push(llmCompletion);
                    }
                }

                return completions;
            }
        },
        '.', ' ', ';', '-', 'S', 'E', 'L', 'C', 'T'  // Trigger on: dot, space, semicolon, dash, SQL keywords
    );

    context.subscriptions.push(provider);
}

/**
 * Get LLM-based completion for current context
 */
async function getLLMCompletion(document, position, contextBuilder, llmProvider) {
    try {
        // Check if LLM is enabled in settings
        const config = vscode.workspace.getConfiguration('dbiSurvivalKit.llm');
        const isEnabled = config.get('enabled', false);
        
        if (!isEnabled) {
            if (debugHelper) {
                debugHelper.log('LLM is disabled in settings');
            }
            return null;
        }

        const documentText = document.getText();
        const cursorLine = position.line;

        if (debugHelper) {
            debugHelper.log(`LLM triggered at line ${cursorLine}`);
        }

        // Build context from document
        const context = contextBuilder.buildContext(documentText, cursorLine);
        
        if (!context || !context.task) {
            if (debugHelper) {
                debugHelper.log('No task found at cursor position');
            }
            return null; // No task found
        }

        if (debugHelper) {
            debugHelper.log(`Task found: "${context.task}"`);
            debugHelper.log(`Schemas found: ${context.schemas.length}`);
        }

        // Query LLM (with context for caching)
        const sqlQuery = await llmProvider.query(context.prompt, context);

        if (!sqlQuery) {
            if (debugHelper) {
                debugHelper.log('LLM returned empty query');
            }
            return null;
        }

        if (debugHelper) {
            debugHelper.log(`LLM generated query: ${sqlQuery.substring(0, 100)}...`);
        }

        // Create completion item with debug label
        const debugLabel = debugHelper ? debugHelper.getDebugLabel('llm') : '';
        const completion = new vscode.CompletionItem(
            debugLabel + ' AI: ' + context.task.substring(0, 50) + '...',
            vscode.CompletionItemKind.Snippet
        );
        
        completion.insertText = sqlQuery;
        completion.detail = 'AI-generated SQL query';
        completion.documentation = new vscode.MarkdownString(
            `**Task:** ${context.task}\n\n` +
            `**Schema:**\n\`\`\`sql\n${context.schemaText}\n\`\`\`\n\n` +
            `**Generated Query:**\n\`\`\`sql\n${sqlQuery}\n\`\`\`\n\n` +
            `_Powered by LLM_`
        );
        
        // Higher sort priority so it appears first
        completion.sortText = '0000';
        completion.preselect = true;

        return completion;

    } catch (error) {
        console.error('[DBI Survival Kit] LLM completion failed:', error);
        return null;
    }
}

/**
 * Create a completion item
 */
function createCompletion(label, insertText, documentation) {
    const completion = new vscode.CompletionItem(label);
    completion.insertText = new vscode.SnippetString(insertText);
    completion.documentation = new vscode.MarkdownString(documentation);
    return completion;
}

/**
 * Insert a template at cursor position
 */
function insertTemplate(snippetPrefix) {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showErrorMessage('No active editor');
        return;
    }

    // Trigger snippet
    vscode.commands.executeCommand('editor.action.insertSnippet', {
        name: snippetPrefix
    });
}

/**
 * Export snippets for sharing
 */
async function exportSnippets() {
    const snippetsDir = path.join(__dirname, '..', 'snippets');
    const exportDir = await vscode.window.showSaveDialog({
        defaultUri: vscode.Uri.file(path.join(require('os').homedir(), 'dbi-snippets-export.zip')),
        filters: { 'ZIP files': ['zip'] }
    });

    if (!exportDir) return;

    try {
        // Simple export (in production, use a proper ZIP library)
        const exportPath = exportDir.fsPath.replace('.zip', '');
        fs.mkdirSync(exportPath, { recursive: true });
        
        // Copy snippet files
        const files = fs.readdirSync(snippetsDir);
        files.forEach(file => {
            fs.copyFileSync(
                path.join(snippetsDir, file),
                path.join(exportPath, file)
            );
        });

        vscode.window.showInformationMessage(
            `Snippets exported to: ${exportPath}\n` +
            'Share this folder with your colleagues!'
        );
    } catch (error) {
        vscode.window.showErrorMessage(`Export failed: ${error.message}`);
    }
}

/**
 * Import snippets from colleagues
 */
async function importSnippets() {
    const importUri = await vscode.window.showOpenDialog({
        canSelectFiles: false,
        canSelectFolders: true,
        canSelectMany: false,
        openLabel: 'Select snippets folder'
    });

    if (!importUri || importUri.length === 0) return;

    try {
        const importPath = importUri[0].fsPath;
        const snippetsDir = path.join(__dirname, '..', 'snippets');
        
        // Copy and merge snippets
        const files = fs.readdirSync(importPath);
        let imported = 0;
        
        files.forEach(file => {
            if (file.endsWith('.json')) {
                const sourcePath = path.join(importPath, file);
                const targetPath = path.join(snippetsDir, file);
                
                if (fs.existsSync(targetPath)) {
                    // Merge snippets
                    const existingSnippets = JSON.parse(fs.readFileSync(targetPath, 'utf8'));
                    const newSnippets = JSON.parse(fs.readFileSync(sourcePath, 'utf8'));
                    const merged = { ...existingSnippets, ...newSnippets };
                    fs.writeFileSync(targetPath, JSON.stringify(merged, null, 2));
                } else {
                    // Copy new file
                    fs.copyFileSync(sourcePath, targetPath);
                }
                imported++;
            }
        });

        vscode.window.showInformationMessage(
            `Successfully imported ${imported} snippet file(s)!\n` +
            'Reload VS Code to see the new snippets.'
        );
    } catch (error) {
        vscode.window.showErrorMessage(`Import failed: ${error.message}`);
    }
}

/**
 * Show welcome message on first use
 */
function showWelcomeMessage(context) {
    const hasShownWelcome = context.globalState.get('hasShownWelcome');
    
    if (!hasShownWelcome) {
        vscode.window.showInformationMessage(
            '🎓 DBI Test Survival Kit activated! Type "star-schema" and press Tab to get started.',
            'Show Commands'
        ).then(selection => {
            if (selection === 'Show Commands') {
                vscode.commands.executeCommand('workbench.action.showCommands');
            }
        });
        
        context.globalState.update('hasShownWelcome', true);
    }
}

/**
 * Extension deactivation
 */
function deactivate() {
    console.log('DBI Test Survival Kit deactivated');
    
    if (debugHelper) {
        debugHelper.dispose();
    }
    if (queryCache) {
        queryCache.clear();
    }
}

module.exports = {
    activate,
    deactivate
};
