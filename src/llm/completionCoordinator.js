class CompletionCoordinator {
    constructor(delayMs = 800) {
        this.delayMs = delayMs;
        this.pendingByDocument = new Map();
    }

    schedule(documentKey, taskKey, run) {
        const existing = this.pendingByDocument.get(documentKey);
        if (existing && existing.taskKey === taskKey) {
            return existing.promise;
        }

        if (existing) {
            existing.cancel();
        }

        const controller = new AbortController();
        let timeout;
        let settle;
        let settled = false;

        const promise = new Promise((resolve, reject) => {
            settle = resolve;
            timeout = setTimeout(async () => {
                try {
                    const result = await run(controller.signal);
                    settled = true;
                    resolve(result);
                } catch (error) {
                    settled = true;
                    reject(error);
                } finally {
                    if (this.pendingByDocument.get(documentKey)?.promise === promise) {
                        this.pendingByDocument.delete(documentKey);
                    }
                }
            }, this.delayMs);
        });

        const cancel = () => {
            if (settled) {
                return;
            }
            settled = true;
            clearTimeout(timeout);
            controller.abort();
            settle(null);
        };

        this.pendingByDocument.set(documentKey, {
            taskKey,
            promise,
            cancel
        });
        return promise;
    }

    dispose() {
        for (const pending of this.pendingByDocument.values()) {
            pending.cancel();
        }
        this.pendingByDocument.clear();
    }
}

module.exports = CompletionCoordinator;
