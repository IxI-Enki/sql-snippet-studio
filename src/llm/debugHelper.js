/**
 * Debug Helper - Visualisiert LLM-Aktivität für Entwickler
 */

const vscode = require('vscode');
const extensionConfig = require('../config');

class DebugHelper {
    constructor() {
        this.statusBarItem = null;
        this.outputChannel = null;
        this.config = null;
        this.requestCount = 0;
        this.cacheHits = 0;
        this.updateConfig();
    }

    /**
     * Initialisiert Debug-Tools
     */
    initialize(context) {
        // Status Bar Item
        this.statusBarItem = vscode.window.createStatusBarItem(
            vscode.StatusBarAlignment.Right,
            100
        );
        this.statusBarItem.command = 'sqlSnippetStudio.showLLMStats';
        context.subscriptions.push(this.statusBarItem);

        // Output Channel
        this.outputChannel = vscode.window.createOutputChannel('SQL Snippet Studio - LLM');
        context.subscriptions.push(this.outputChannel);

        this.updateStatusBar('idle');
    }

    /**
     * Aktualisiert Konfiguration aus Settings
     */
    updateConfig() {
        this.config = {
            showDebugInfo: extensionConfig.getSection('llm', 'showDebugInfo', false),
            showNotifications: extensionConfig.getSection('llm', 'showNotifications', false),
            verboseLogging: extensionConfig.getSection('llm', 'verboseLogging', false)
        };
    }

    /**
     * Zeigt Status in Status Bar
     */
    updateStatusBar(state, message = '') {
        if (!this.statusBarItem) {
            return;
        }
        
        // ALWAYS show status bar (not just when debug is enabled)
        // Get current model from settings
        const currentModel = extensionConfig.getSection('llm', 'model', 'Not configured');
        const endpoint = extensionConfig.getSection('llm', 'endpoint', 'Not configured');

        switch (state) {
            case 'idle':
                this.statusBarItem.text = `$(database) LLM Ready`;
                this.statusBarItem.tooltip = `LLM-Assisted Completion\n\n` +
                    `📊 Statistics:\n` +
                    `  Requests: ${this.requestCount}\n` +
                    `  Cache Hits: ${this.cacheHits}\n` +
                    `  Status: Idle\n\n` +
                    `🤖 Configuration:\n` +
                    `  Model: ${currentModel}\n` +
                    `  Endpoint: ${endpoint}`;
                this.statusBarItem.backgroundColor = undefined;
                break;

            case 'thinking':
                this.statusBarItem.text = `$(sync~spin) LLM Thinking...`;
                this.statusBarItem.tooltip = `Querying LLM...\n` +
                    `Model: ${currentModel}\n` +
                    `${message}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor(
                    'statusBarItem.warningBackground'
                );
                break;

            case 'success':
                this.statusBarItem.text = `$(check) LLM Success`;
                this.statusBarItem.tooltip = `Query successful!\n` +
                    `Model: ${currentModel}\n` +
                    `${message}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor(
                    'statusBarItem.prominentBackground'
                );
                setTimeout(() => this.updateStatusBar('idle'), 3000);
                break;

            case 'error':
                this.statusBarItem.text = `$(error) LLM Error`;
                this.statusBarItem.tooltip = `Error: ${message}\n` +
                    `Model: ${currentModel}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor(
                    'statusBarItem.errorBackground'
                );
                setTimeout(() => this.updateStatusBar('idle'), 5000);
                break;

            case 'cache':
                this.statusBarItem.text = `$(zap) LLM Cache Hit`;
                this.statusBarItem.tooltip = `Response from cache\n` +
                    `Model: ${currentModel}\n` +
                    `${message}`;
                this.statusBarItem.backgroundColor = undefined;
                setTimeout(() => this.updateStatusBar('idle'), 2000);
                break;

            case 'requesting':
                this.statusBarItem.text = `$(sync~spin) Querying LLM...`;
                this.statusBarItem.tooltip = `Connecting to LLM...\n` +
                    `Model: ${currentModel}\n` +
                    `${message}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor(
                    'statusBarItem.warningBackground'
                );
                break;
        }

        this.statusBarItem.show();
    }

    /**
     * Simple log method for general messages
     */
    log(message) {
        if (!this.outputChannel) {
            return;
        }
        
        if (this.config.verboseLogging) {
            this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ${message}`);
        }
    }

    /**
     * Loggt LLM-Request Start
     */
    logRequestStart(task, schema) {
        this.requestCount++;
        this.updateStatusBar('thinking', `Task: ${task.substring(0, 50)}...`);

        if (this.config.verboseLogging) {
            this.outputChannel.appendLine('');
            this.outputChannel.appendLine(`[${ new Date().toLocaleTimeString()}] ===== LLM REQUEST START =====`);
            this.outputChannel.appendLine(`Request #${this.requestCount}`);
            this.outputChannel.appendLine(`Task: ${task}`);
            this.outputChannel.appendLine(`Schema Tables: ${schema.length}`);
            this.outputChannel.appendLine('');
        }

        if (this.config.showNotifications) {
            vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: '🤖 LLM is thinking...',
                cancellable: false
            }, async (progress) => {
                progress.report({ message: task.substring(0, 60) + '...' });
                await new Promise(resolve => setTimeout(resolve, 500));
            });
        }
    }

    /**
     * Loggt LLM-Response
     */
    logRequestSuccess(query, duration) {
        this.updateStatusBar('success', `Completed in ${duration}ms`);

        if (this.config.verboseLogging) {
            this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== LLM RESPONSE =====`);
            this.outputChannel.appendLine(`Duration: ${duration}ms`);
            this.outputChannel.appendLine(`Generated Query:`);
            this.outputChannel.appendLine(query);
            this.outputChannel.appendLine('');
        }

        if (this.config.showNotifications) {
            vscode.window.showInformationMessage(
                `✅ LLM generated query (${duration}ms)`,
                'Show Query'
            ).then(selection => {
                if (selection === 'Show Query') {
                    this.outputChannel.show();
                }
            });
        }
    }

    /**
     * Loggt Fehler
     */
    logRequestError(error) {
        this.updateStatusBar('error', error.message);

        this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== LLM ERROR =====`);
        this.outputChannel.appendLine(`Error: ${error.message}`);
        this.outputChannel.appendLine(`Stack: ${error.stack}`);
        this.outputChannel.appendLine('');

        if (this.config.showNotifications) {
            vscode.window.showErrorMessage(
                `❌ LLM Error: ${error.message}`,
                'Show Log'
            ).then(selection => {
                if (selection === 'Show Log') {
                    this.outputChannel.show();
                }
            });
        }
    }

    /**
     * Loggt Cache-Hit
     */
    logCacheHit(task) {
        this.cacheHits++;
        this.updateStatusBar('cache', `Task: ${task.substring(0, 50)}...`);

        if (this.config.verboseLogging) {
            this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== CACHE HIT =====`);
            this.outputChannel.appendLine(`Task: ${task}`);
            this.outputChannel.appendLine(`Cache Hits: ${this.cacheHits}/${this.requestCount}`);
            this.outputChannel.appendLine('');
        }
    }

    /**
     * Logs errors
     */
    logError(error) {
        if (!this.outputChannel) {
            return;
        }
        
        this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ❌ ERROR: ${error.message}`);
        if (error.stack) {
            this.outputChannel.appendLine(error.stack);
        }
    }

    /**
     * Zeigt Statistiken
     */
    showStats() {
        const cacheHitRate = this.requestCount > 0 
            ? ((this.cacheHits / this.requestCount) * 100).toFixed(1)
            : 0;

        const message = `📊 LLM Statistics\n\n` +
            `Total Requests: ${this.requestCount}\n` +
            `Cache Hits: ${this.cacheHits}\n` +
            `Cache Hit Rate: ${cacheHitRate}%\n` +
            `\n` +
            `Debug Mode: ${this.config.showDebugInfo ? '✅' : '❌'}\n` +
            `Notifications: ${this.config.showNotifications ? '✅' : '❌'}\n` +
            `Verbose Logging: ${this.config.verboseLogging ? '✅' : '❌'}`;

        vscode.window.showInformationMessage(message, 'Show Log', 'Reset Stats').then(selection => {
            if (selection === 'Show Log') {
                this.outputChannel.show();
            } else if (selection === 'Reset Stats') {
                this.requestCount = 0;
                this.cacheHits = 0;
                this.updateStatusBar('idle');
            }
        });
    }

    /**
     * Erstellt Debug-Label für Completion-Item
     */
    getDebugLabel(source) {
        if (!this.config.showDebugInfo) {
            return '';
        }

        const labels = {
            'llm': '🤖 [LLM]',
            'cache': '⚡ [Cached]',
            'snippet': '📝 [Snippet]'
        };

        return labels[source] || '';
    }

    /**
     * Cleanup
     */
    dispose() {
        if (this.statusBarItem) {
            this.statusBarItem.dispose();
        }
        if (this.outputChannel) {
            this.outputChannel.dispose();
        }
    }
}

module.exports = DebugHelper;
