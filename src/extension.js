const vscode = require('vscode');
const fs = require('fs');
const path = require('path');

/**
 * Extension activation entry point
 */
function activate(context) {
    console.log('DBI Test Survival Kit is now active!');

    // Register commands
    registerCommands(context);
    
    // Register completion provider
    registerCompletionProvider(context);
    
    // Show welcome message on first activation
    showWelcomeMessage(context);
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
}

/**
 * Register intelligent completion provider
 */
function registerCompletionProvider(context) {
    const provider = vscode.languages.registerCompletionItemProvider(
        ['sql', 'plsql'],
        {
            provideCompletionItems(document, position) {
                const linePrefix = document.lineAt(position).text.substr(0, position.character);
                const completions = [];

                // Detect context and provide smart suggestions
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

                return completions;
            }
        },
        '.' // Trigger on dot
    );

    context.subscriptions.push(provider);
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
            'Share this folder with your Kollegen!'
        );
    } catch (error) {
        vscode.window.showErrorMessage(`Export failed: ${error.message}`);
    }
}

/**
 * Import snippets from Kollegen
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
}

module.exports = {
    activate,
    deactivate
};
