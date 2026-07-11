/**
 * Query Cache - Cacht LLM-Responses fuer schnellere Wiederholung
 */

const crypto = require('crypto');

class QueryCache {
    constructor(options = {}) {
        this.cache = new Map();
        this.maxSize = 100;
        this.ttl = 3600000;
        this.getConfig = options.getConfig || null;
    }

    generateKey(context, config) {
        const effectiveConfig = config || (this.getConfig && this.getConfig());
        if (!effectiveConfig) {
            throw new Error('LLM configuration is required to generate a cache key.');
        }
        const keyData = JSON.stringify({
            model: effectiveConfig.model,
            endpoint: effectiveConfig.endpoint,
            temperature: effectiveConfig.temperature,
            maxTokens: effectiveConfig.maxTokens,
            schemas: context.schemas.map(s => ({
                name: s.tableName,
                columns: s.columns.map(c => `${c.name}:${c.type}`).join(',')
            })).sort((a, b) => a.name.localeCompare(b.name)),
            taskFull: context.task.trim(),
            promptHash: crypto.createHash('md5')
                .update(context.task + JSON.stringify(context.schemas))
                .digest('hex')
        });

        return crypto.createHash('md5').update(keyData).digest('hex');
    }

    get(context, config) {
        const key = this.generateKey(context, config);
        const cached = this.cache.get(key);

        if (!cached) {
            return null;
        }

        if (Date.now() - cached.timestamp > this.ttl) {
            this.cache.delete(key);
            return null;
        }

        cached.lastAccess = Date.now();
        cached.hits++;
        return cached.query;
    }

    set(context, query, config) {
        const key = this.generateKey(context, config);

        if (this.cache.size >= this.maxSize) {
            this.evictLeastRecentlyUsed();
        }

        this.cache.set(key, {
            query,
            timestamp: Date.now(),
            lastAccess: Date.now(),
            hits: 0,
            task: context.task
        });
    }

    evictLeastRecentlyUsed() {
        let oldestKey = null;
        let oldestTime = Infinity;

        for (const [key, value] of this.cache.entries()) {
            if (value.lastAccess < oldestTime) {
                oldestTime = value.lastAccess;
                oldestKey = key;
            }
        }

        if (oldestKey) {
            this.cache.delete(oldestKey);
        }
    }

    clear() {
        this.cache.clear();
    }

    clearForModel(modelName) {
        const keysToDelete = [];
        for (const key of this.cache.keys()) {
            keysToDelete.push(key);
        }
        keysToDelete.forEach(key => this.cache.delete(key));
        return keysToDelete.length;
    }

    getStats() {
        const entries = Array.from(this.cache.values());
        const totalHits = entries.reduce((sum, e) => sum + e.hits, 0);
        const avgHits = entries.length > 0 ? totalHits / entries.length : 0;

        return {
            size: this.cache.size,
            maxSize: this.maxSize,
            totalHits,
            avgHitsPerEntry: avgHits.toFixed(2),
            oldestEntry: entries.length > 0
                ? Math.floor((Date.now() - Math.min(...entries.map(e => e.timestamp))) / 1000)
                : 0
        };
    }
}

module.exports = QueryCache;
