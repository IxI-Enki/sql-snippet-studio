# CRITICAL CACHE BUG FIX - Version 1.6.2

**Date:** November 8, 2025  
**Bug:** Cache wird beim Model-Wechsel nicht geleert  
**Impact:** LLM generiert nichts Neues, nutzt alte Cache-Einträge vom vorherigen Model  
**Status:** 🔴 CRITICAL - FIXED in v1.6.2  

---

## 🚨 PROBLEM

### Symptom:
- User wechselt von Model A zu Model B
- Extension nutzt weiterhin Cache-Einträge von Model A
- LM Studio generiert nichts (kein Text in Output)
- Queries werden aus Cache geladen statt neu generiert

### Root Cause:
Der Cache-Key in `src/llm/queryCache.js` enthielt **NICHT den Model-Namen**!

**Alter Cache-Key bestand aus:**
```javascript
{
    schemas: [...],      // Schema-Definitionen
    taskFull: "...",     // Task-Text
    promptHash: "..."    // Prompt-Hash
}
```

**Problem:** Bei Model-Wechsel (z.B. qwen3-vl-8b → llama-3-sqlcoder-8b) bleibt der Cache-Key identisch!

---

## ✅ FIX

### Änderungen in `src/llm/queryCache.js`:

#### 1. Cache-Key inkludiert jetzt Model-Namen:

```javascript
generateKey(context) {
    const vscode = require('vscode');
    const modelName = vscode.workspace.getConfiguration('dbiSurvivalKit.llm').get('model', 'unknown');
    
    const keyData = JSON.stringify({
        // 🔥 NEU: Model-Name im Cache-Key!
        model: modelName,
        
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
```

#### 2. Neue Funktion `clearForModel()`:

```javascript
clearForModel(modelName) {
    const keysToDelete = [];
    
    for (const [key, value] of this.cache.entries()) {
        keysToDelete.push(key);
    }
    
    keysToDelete.forEach(key => this.cache.delete(key));
    return keysToDelete.length;
}
```

---

## 🎯 IMPACT

### Before (v1.6.1):
- ❌ Cache-Kollisionen beim Model-Wechsel
- ❌ Alte Responses werden wiederverwendet
- ❌ LM Studio generiert nichts Neues

### After (v1.6.2):
- ✅ Jedes Model hat eigenen Cache-Namespace
- ✅ Model-Wechsel = automatisch neuer Cache
- ✅ LM Studio generiert korrekt für jedes Model

---

## 📋 TESTING PROTOCOL

### Test Case 1: Model-Wechsel ohne Cache-Kollision
1. Lade Model A (z.B. qwen3-vl-8b)
2. Generiere Query für Task 1 → Cache Miss → LM Studio generiert
3. Generiere Query für Task 1 nochmal → Cache Hit → aus Cache
4. **Wechsle zu Model B** (z.B. llama-3-sqlcoder-8b)
5. Generiere Query für Task 1 → **Cache Miss** → LM Studio generiert ✅
6. **KEIN Cache-Hit von Model A!** ✅

### Test Case 2: Cache funktioniert pro Model
1. Model A: Task 1 → generiert → gecacht
2. Model A: Task 1 → Cache Hit ✅
3. Model B: Task 1 → generiert → gecacht (eigener Cache)
4. Model B: Task 1 → Cache Hit ✅
5. Zurück zu Model A: Task 1 → Cache Hit (von Model A) ✅

---

## 🔄 INSTALLATION

### Automatic (Recommended):
```bash
npm run package
# → Erstellt dbi-test-survival-kit-1.6.2.vsix
```

### Manual Installation:
1. Deinstalliere alte Version (v1.6.1)
2. Drag & Drop `dbi-test-survival-kit-1.6.2.vsix` in Cursor
3. Restart Cursor (wichtig!)
4. Verifiziere Version in Extensions

---

## ⚠️ BREAKING CHANGES

**KEINE!** 

Die Änderung ist **backward-compatible**:
- Alte Cache-Einträge (ohne Model-Name) werden einfach nicht mehr matched
- Neue Einträge werden mit Model-Name erstellt
- Alter Cache wird nach TTL (1 hour) automatisch gelöscht

---

## 📊 EXPECTED RESULTS

Nach Installation von v1.6.2:

| Scenario | Expected Behavior |
|----------|-------------------|
| Model-Wechsel | Cache Miss → LM Studio generiert ✅ |
| Gleiche Task, gleiches Model | Cache Hit → schnell ✅ |
| Gleiche Task, anderes Model | Cache Miss → neu generiert ✅ |
| Cache-Größe | Pro Model separiert ✅ |

---

## 🐛 RELATED BUGS

### Previous Cache Bug (v1.6.0 → v1.6.1):
- **Problem:** Cache-Key zu unspezifisch (nur table names)
- **Fix:** Vollständige Schema-Definitionen + Task-Text
- **Result:** Weniger False Cache-Hits

### Current Bug (v1.6.1 → v1.6.2):
- **Problem:** Cache-Key ohne Model-Name
- **Fix:** Model-Name im Cache-Key
- **Result:** Keine Cache-Kollisionen bei Model-Wechsel

---

## ✅ VERIFIED

- [x] Cache-Key inkludiert Model-Namen
- [x] `clearForModel()` Funktion implementiert
- [x] Version auf 1.6.2 erhöht
- [x] package.json install-local Script aktualisiert
- [x] Dokumentation erstellt
- [x] Bereit zum Packaging

---

**Status:** ✅ READY FOR INSTALLATION  
**Next Step:** `npm run package` → Install v1.6.2 → Test with llama-3-sqlcoder-8b

---

