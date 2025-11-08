/**
 * Query Cache - Cacht LLM-Responses für schnellere Wiederholung
 */

const crypto = require('crypto');

class QueryCache {
    constructor() {
        this.cache = new Map();
        this.maxSize = 100; // Max cached queries
        this.ttl = 3600000; // 1 hour TTL
    }

    /**
     * Generiert Cache-Key aus Context
     */
    generateKey(context) {
        const keyData = JSON.stringify({
            schemas: context.schemas.map(s => s.tableName).sort(),
            task: context.task.toLowerCase().trim()
        });
        
        return crypto
            .createHash('md5')
            .update(keyData)
            .digest('hex');
    }

    /**
     * Holt Wert aus Cache
     */
    get(context) {
        const key = this.generateKey(context);
        const cached = this.cache.get(key);

        if (!cached) {
            return null;
        }

        // Check TTL
        if (Date.now() - cached.timestamp > this.ttl) {
            this.cache.delete(key);
            return null;
        }

        // Update access time
        cached.lastAccess = Date.now();
        cached.hits++;

        return cached.query;
    }

    /**
     * Speichert Wert in Cache
     */
    set(context, query) {
        const key = this.generateKey(context);

        // Enforce max size
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

    /**
     * Entfernt am längsten nicht benutzte Einträge
     */
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

    /**
     * Löscht Cache
     */
    clear() {
        this.cache.clear();
    }

    /**
     * Cache-Statistiken
     */
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

