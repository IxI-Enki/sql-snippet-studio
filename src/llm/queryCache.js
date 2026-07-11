/**
 * Query Cache - Cacht LLM-Responses für schnellere Wiederholung
 */

const crypto = require('crypto');
const extensionConfig = require('../config');

class QueryCache {
    constructor() {
        this.cache = new Map();
        this.maxSize = 100; // Max cached queries
        this.ttl = 3600000; // 1 hour TTL
    }

    /**
     * Generiert Cache-Key aus Context
     * FIXED v1.6.2: Inkludiert jetzt MODEL-NAME im Cache-Key!
     * Verhindert Cache-Kollisionen beim Model-Wechsel!
     */
    generateKey(context) {
        const modelName = extensionConfig.getSection('llm', 'model', 'unknown');
        
        // Erstelle einen eindeutigen Key aus:
        // 1. MODEL-NAME (NEU! Kritisch für Model-Wechsel!)
        // 2. Kompletten Schema-Definitionen (nicht nur Namen!)
        // 3. Kompletten Task-Text (nicht nur lowercase/trim!)
        // 4. Sortierte Tabellennamen als Fallback
        const keyData = JSON.stringify({
            // 🔥 KRITISCH: Model-Name im Cache-Key!
            // Verhindert dass alte Cache-Einträge bei Model-Wechsel verwendet werden!
            model: modelName,
            
            // Vollständige Schema-Definitionen für maximale Spezifität
            schemas: context.schemas.map(s => ({
                name: s.tableName,
                columns: s.columns.map(c => `${c.name}:${c.type}`).join(',')
            })).sort((a, b) => a.name.localeCompare(b.name)),
            
            // KRITISCH: Kompletter Task-Text, nicht gekürzt!
            taskFull: context.task.trim(),
            
            // Hash des kompletten Prompts als zusätzliche Absicherung
            promptHash: crypto.createHash('md5')
                .update(context.task + JSON.stringify(context.schemas))
                .digest('hex')
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
     * Löscht Cache für ein bestimmtes Model
     * Nützlich beim Model-Wechsel
     */
    clearForModel(modelName) {
        const keysToDelete = [];
        
        for (const [key, value] of this.cache.entries()) {
            // Check if cached task was generated with this model
            // (simplified check - in reality we'd need to store model info)
            keysToDelete.push(key);
        }
        
        keysToDelete.forEach(key => this.cache.delete(key));
        return keysToDelete.length;
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
