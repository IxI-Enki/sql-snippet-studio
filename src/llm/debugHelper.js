/**
 * Debug Helper - Visualisiert LLM-Aktivitaet
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
        this.connectionVerified = false;
        this.updateConfig();
    }

    initialize(context) {
        this.statusBarItem = vscode.window.createStatusBarItem(
            vscode.StatusBarAlignment.Right,
            100
        );
        this.statusBarItem.command = 'sqlSnippetStudio.showLLMStats';
        context.subscriptions.push(this.statusBarItem);

        this.outputChannel = vscode.window.createOutputChannel('SQL Snippet Studio - LLM');
        context.subscriptions.push(this.outputChannel);

        this.refreshStatusBar();
    }

    updateConfig() {
        this.config = extensionConfig.getLlmConfig();
        this.connectionVerified = false;
        this.refreshStatusBar();
    }

    markConnectionReady() {
        this.connectionVerified = true;
        this.refreshStatusBar();
    }

    isLlmEnabled() {
        return this.config.enabled;
    }

    refreshStatusBar() {
        if (!this.statusBarItem) {
            return;
        }

        if (!this.config.enabled) {
            this.statusBarItem.hide();
            return;
        }

        this.updateStatusBar('idle');
    }

    updateStatusBar(state, message = '') {
        if (!this.statusBarItem || !this.config.enabled) {
            return;
        }

        const currentModel = this.config.model;
        const endpoint = this.config.endpoint;

        switch (state) {
            case 'idle':
                this.statusBarItem.text = this.connectionVerified
                    ? '$(database) LLM Ready'
                    : '$(database) LLM Configured';
                this.statusBarItem.tooltip = `LLM-Assisted Completion\n\nConnection: ${this.connectionVerified ? 'Verified' : 'Not tested'}\nRequests: ${this.requestCount}\nCache Hits: ${this.cacheHits}\nModel: ${currentModel}\nEndpoint: ${endpoint}`;
                this.statusBarItem.backgroundColor = undefined;
                break;
            case 'thinking':
            case 'requesting':
                this.statusBarItem.text = '$(sync~spin) Querying LLM...';
                this.statusBarItem.tooltip = `Querying LLM...\nModel: ${currentModel}\n${message}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
                break;
            case 'success':
                this.statusBarItem.text = '$(check) LLM Success';
                this.statusBarItem.tooltip = `Query successful\nModel: ${currentModel}\n${message}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.prominentBackground');
                setTimeout(() => this.refreshStatusBar(), 3000);
                break;
            case 'error':
                this.statusBarItem.text = '$(error) LLM Error';
                this.statusBarItem.tooltip = `Error: ${message}\nModel: ${currentModel}`;
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
                setTimeout(() => this.refreshStatusBar(), 5000);
                break;
            case 'cache':
                this.statusBarItem.text = '$(zap) LLM Cache Hit';
                this.statusBarItem.tooltip = `Response from cache\nModel: ${currentModel}\n${message}`;
                this.statusBarItem.backgroundColor = undefined;
                setTimeout(() => this.refreshStatusBar(), 2000);
                break;
            default:
                break;
        }

        this.statusBarItem.show();
    }

    log(message) {
        if (!this.outputChannel || !this.config.verboseLogging) {
            return;
        }
        this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ${message}`);
    }

    logRequestStart(task, schema) {
        this.requestCount++;
        this.updateStatusBar('thinking', `Task: ${task.substring(0, 50)}...`);

        if (this.config.verboseLogging) {
            this.outputChannel.appendLine('');
            this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== LLM REQUEST START =====`);
            this.outputChannel.appendLine(`Request #${this.requestCount}`);
            this.outputChannel.appendLine(`Task: ${task}`);
            this.outputChannel.appendLine(`Schema Tables: ${schema.length}`);
            this.outputChannel.appendLine('');
        }

        if (this.config.showNotifications) {
            vscode.window.withProgress({
                location: vscode.ProgressLocation.Notification,
                title: 'Querying LLM...',
                cancellable: false
            }, async (progress) => {
                progress.report({ message: task.substring(0, 60) + '...' });
                await new Promise(resolve => setTimeout(resolve, 500));
            });
        }
    }

    logRequestSuccess(query, duration) {
        this.connectionVerified = true;
        this.updateStatusBar('success', `Completed in ${duration}ms`);

        if (this.config.verboseLogging) {
            this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== LLM RESPONSE =====`);
            this.outputChannel.appendLine(`Duration: ${duration}ms`);
            this.outputChannel.appendLine(`Generated Query:`);
            this.outputChannel.appendLine(query);
            this.outputChannel.appendLine('');
        }
    }

    logRequestError(error) {
        const safeMessage = error.remediation
            ? `${error.message}\n\n${error.remediation}`
            : error.message;

        this.updateStatusBar('error', error.message);

        this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ===== LLM ERROR =====`);
        this.outputChannel.appendLine(`Error: ${error.message}`);
        if (error.remediation) {
            this.outputChannel.appendLine(`Remediation: ${error.remediation}`);
        }
        if (error.stack) {
            this.outputChannel.appendLine(`Stack: ${error.stack}`);
        }
        this.outputChannel.appendLine('');

        if (this.config.showNotifications) {
            const actions = ['Show Log'];
            if (error.code === 'AUTHENTICATION') {
                actions.unshift('Set API Token');
            }
            vscode.window.showErrorMessage(`LLM Error: ${error.message}`, ...actions).then(selection => {
                if (selection === 'Show Log') {
                    this.outputChannel.show();
                } else if (selection === 'Set API Token') {
                    vscode.commands.executeCommand('sqlSnippetStudio.setLlmApiToken');
                }
            });
        }
    }

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

    logError(error) {
        if (!this.outputChannel) {
            return;
        }
        this.outputChannel.appendLine(`[${new Date().toLocaleTimeString()}] ERROR: ${error.message}`);
        if (error.stack) {
            this.outputChannel.appendLine(error.stack);
        }
    }

    showStats() {
        const cacheHitRate = this.requestCount > 0
            ? ((this.cacheHits / this.requestCount) * 100).toFixed(1)
            : 0;

        const message = `LLM Statistics\n\nTotal Requests: ${this.requestCount}\nCache Hits: ${this.cacheHits}\nCache Hit Rate: ${cacheHitRate}%\n\nEnabled: ${this.config.enabled ? 'yes' : 'no'}\nModel: ${this.config.model}\nEndpoint: ${this.config.endpoint}`;

        vscode.window.showInformationMessage(message, 'Show Log', 'Reset Stats').then(selection => {
            if (selection === 'Show Log') {
                this.outputChannel.show();
            } else if (selection === 'Reset Stats') {
                this.requestCount = 0;
                this.cacheHits = 0;
                this.refreshStatusBar();
            }
        });
    }

    getDebugLabel(source) {
        if (!this.config.showDebugInfo) {
            return '';
        }

        const labels = {
            llm: '[LLM]',
            cache: '[Cached]',
            snippet: '[Snippet]'
        };

        return labels[source] || '';
    }

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
