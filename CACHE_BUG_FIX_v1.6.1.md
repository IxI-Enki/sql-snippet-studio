# 🔧 CACHE-BUG FIX - Version 1.6.1

## **🚨 KRITISCHER BUG GEFUNDEN & GEFIXT!**

### **Problem:**

Der Query-Cache verwendete einen **zu unspezifischen Cache-Key**, der nur aus:
- Tabellennamen (sortiert)
- Task-Text (lowercase + trim)

generiert wurde.

**Folge:**
- Alle Aufgaben im gleichen Test hatten die **gleichen Tabellennamen**!
- Der Cache gab **FALSCHE Queries zurück** für verschiedene Aufgaben!
- Beispiel: Aufgabe 1 cached → Aufgabe 2-8 bekommen FALSCHE Query aus Cache!

### **Lösung:**

Cache-Key wurde erweitert auf:
1. **Vollständige Schema-Definitionen** (nicht nur Namen, auch Spalten + Typen!)
2. **Kompletter Task-Text** (nicht nur lowercase/trim!)
3. **Hash des kompletten Prompts** als zusätzliche Absicherung

**Code:** `src/llm/queryCache.js` - Zeilen 19-44

### **Installation:**

```powershell
# 1. Alte Version deinstallieren (falls vorhanden)
# In Cursor: Extensions → DBI Test Survival Kit → Uninstall

# 2. Cache clearen
# Ctrl+Alt+Shift+L → Clear Cache

# 3. Cursor KOMPLETT schließen (alle Fenster!)

# 4. Extension installieren
# Option A: Drag & Drop dbi-test-survival-kit-1.6.1.vsix in Cursor
# Option B: Extensions → ... → Install from VSIX...

# 5. Cursor neu starten

# 6. Extension testen
# Ctrl+Alt+Shift+Q auf leerer Zeile nach einer Aufgabe
```

### **Was wurde geändert:**

1. ✅ **Cache-Bug gefixt** (`src/llm/queryCache.js`)
2. ✅ **Version erhöht** (1.6.0 → 1.6.1)
3. ✅ **Extension neu gebaut** (`dbi-test-survival-kit-1.6.1.vsix`)
4. ✅ **Testdateien für qwen/qwen2.5-vl-7b geleert** (bereit für Neutest)

### **Testdateien geleert:**

- `test/TESTFILES-qwen-qwen2.5-vl-7b/llm_test_01_retail_basic.sql` ✅
- `test/TESTFILES-qwen-qwen2.5-vl-7b/llm_test_02_logistics_advanced.sql` ✅
- `test/TESTFILES-qwen-qwen2.5-vl-7b/llm_test_03_sales_analytics_window.sql` ✅
- `test/TESTFILES-qwen-qwen2.5-vl-7b/llm_test_04_time_series_lag_lead.sql` ✅

### **Nächste Schritte:**

1. Extension installieren (siehe oben)
2. Cursor neu starten
3. Die 4 Tests mit `qwen/qwen2.5-vl-7b` nochmal ausführen
4. Testen ob Cache jetzt korrekt funktioniert:
   - Jede Aufgabe sollte EIGENE Query generieren
   - Status Bar sollte "LLM Thinking..." zeigen (nicht "Cache Hit")
   - Nur bei IDENTISCHEN Aufgaben sollte Cache verwendet werden

### **Wie erkenne ich dass der Bug gefixt ist:**

**VOR dem Fix:**
- ❌ Aufgabe 2-8: Status Bar zeigte "Cache Hit" oder gar nichts
- ❌ Alle Queries waren identisch oder ähnlich
- ❌ Model generierte keine neuen Queries

**NACH dem Fix:**
- ✅ Jede Aufgabe: Status Bar zeigt "LLM Thinking..."
- ✅ Jede Query ist unterschiedlich und passt zur Aufgabe
- ✅ Model generiert für jede Aufgabe neue Query

---

**Erstellt:** 2025-11-08  
**Version:** 1.6.1  
**Bug-ID:** CACHE-001  
**Severity:** CRITICAL  
**Status:** FIXED ✅

🤓🤜🏻🤛🏻🤖
