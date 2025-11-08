# 🤖 LLM-Assisted Tab-Completion

## 🎯 **Was ist das?**

Ein **subtiles AI-Feature**, das SQL-Queries **automatisch vorschlägt** – so als wäre es normale Tab-Completion!

### ✨ **Das Besondere:**

- 🧠 **Unsichtbar:** Sieht aus wie normale IntelliSense
- 📚 **Context-Aware:** Liest Schema + Aufgabe automatisch
- ⚡ **Schnell:** Lokales LLM = keine Internet-Abhängigkeit
- 🎓 **Perfekt für Tests:** Lehrer sieht nur "Tab-Completion"

---

## 🚀 **Wie funktioniert's?**

### **1. Setup**

#### **Option A: Lokales LLM (Empfohlen für Tests)**

```bash
# LM Studio oder Ollama installieren
# Modell laden: qwen2.5-coder (oder ähnlich)
# Server starten auf localhost:1234
```

#### **Option B: OpenAI API**

```json
{
  "dbiSurvivalKit.llm.endpoint": "https://api.openai.com/v1/chat/completions",
  "dbiSurvivalKit.llm.apiKey": "sk-..."
}
```

### **2. Extension-Settings aktivieren**

**VS Code / Cursor:**
1. `Ctrl + ,` (Settings öffnen)
2. Suche: `DBI Survival Kit`
3. ✅ Enable `Llm: Enabled`
4. Configure:
   ```json
   {
     "dbiSurvivalKit.llm.enabled": true,
     "dbiSurvivalKit.llm.endpoint": "http://localhost:1234/v1/chat/completions",
     "dbiSurvivalKit.llm.model": "qwen2.5-coder"
   }
   ```

### **3. Benutzung im Test**

#### **Workflow:**

```sql
-- 1️⃣ Lehrer gibt Schema:
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    grade INTEGER
);

-- 2️⃣ Aufgabe kopieren:
-- Aufgabe 1: Finde alle Studenten mit Note über 80

-- 3️⃣ Cursor ans Ende der Zeile
-- 4️⃣ Neue Zeile beginnen oder Ctrl+Space drücken
-- 5️⃣ Vorschlag erscheint: "🤖 AI: Finde alle Studenten..."
-- 6️⃣ Tab drücken → Query wird eingefügt!
```

**Resultat:**
```sql
-- Aufgabe 1: Finde alle Studenten mit Note über 80
SELECT * FROM students WHERE grade > 80;
```

---

## 🔍 **Technische Details**

### **Architektur**

```
┌────────────────────────────────────────────┐
│  1. Cursor bewegt sich nach Aufgabe        │
└────────────┬───────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────┐
│  2. Context Builder                        │
│     - Parst Schema (CREATE TABLE)          │
│     - Findet Aufgabe (-- Aufgabe: ...)     │
└────────────┬───────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────┐
│  3. LLM Provider                           │
│     - Sendet Prompt an LLM                 │
│     - Empfängt SQL-Query                   │
└────────────┬───────────────────────────────┘
             │
             ▼
┌────────────────────────────────────────────┐
│  4. Completion Provider                    │
│     - Zeigt als IntelliSense-Item          │
│     - Priorisiert AI-Vorschlag             │
└────────────────────────────────────────────┘
```

### **Komponenten**

| Datei | Beschreibung |
|-------|-------------|
| `contextBuilder.js` | Parst Schema und Aufgaben aus SQL-File |
| `llmProvider.js` | HTTP-Client für LLM-API (OpenAI-kompatibel) |
| `extension.js` | Integriert LLM in CompletionProvider |

### **Erkannte Aufgaben-Formate**

```sql
-- Aufgabe 1: SQL-Query schreiben
-- Task: Create a view
-- TODO: Implement trigger
-- Question: How to join tables?
```

Alle diese Formate werden automatisch erkannt!

---

## ⚙️ **Konfiguration**

### **Alle Settings**

```json
{
  // Enable/Disable Feature
  "dbiSurvivalKit.llm.enabled": true,
  
  // LLM Endpoint (OpenAI-compatible)
  "dbiSurvivalKit.llm.endpoint": "http://localhost:1234/v1/chat/completions",
  
  // Model Name
  "dbiSurvivalKit.llm.model": "qwen2.5-coder",
  
  // API Key (für Remote-APIs)
  "dbiSurvivalKit.llm.apiKey": "",
  
  // Max Tokens in Response
  "dbiSurvivalKit.llm.maxTokens": 500,
  
  // Temperature (0 = deterministisch, 2 = kreativ)
  "dbiSurvivalKit.llm.temperature": 0.1,
  
  // Timeout (ms)
  "dbiSurvivalKit.llm.timeout": 10000
}
```

### **Empfohlene Modelle**

| Modell | Größe | Qualität | Speed | Verwendung |
|--------|-------|----------|-------|------------|
| `qwen2.5-coder-7b` | 7B | ⭐⭐⭐⭐⭐ | 🚀🚀🚀 | **Empfohlen** |
| `codellama-13b` | 13B | ⭐⭐⭐⭐ | 🚀🚀 | Gut für komplexe Queries |
| `deepseek-coder-6.7b` | 6.7B | ⭐⭐⭐⭐ | 🚀🚀🚀 | Schnell & kompakt |

---

## 🎓 **Test-Szenarien**

### **Szenario 1: Offline-Test mit Screenrecording**

✅ **Problem:** Screenrecording blockiert normales LLM  
✅ **Lösung:** Extension nutzt lokales LLM im Hintergrund  
✅ **Ergebnis:** Sieht aus wie normale Tab-Completion

### **Szenario 2: Online-Test mit Internet**

✅ **Problem:** Keine lokale Hardware für LLM  
✅ **Lösung:** Nutze OpenAI API oder Anthropic Claude  
✅ **Ergebnis:** Gleiche Experience, etwas langsamer

### **Szenario 3: Übung mit colleagues**

✅ **Problem:** Schema + Aufgaben vom Lehrer  
✅ **Lösung:** Kopiere Schema ins File, LLM erkennt automatisch  
✅ **Ergebnis:** Queries werden vorgeschlagen

---

## 🐛 **Troubleshooting**

### **LLM antwortet nicht**

```bash
# Test LLM Connection:
curl http://localhost:1234/v1/models

# Expected: Liste von verfügbaren Modellen
```

### **Completion erscheint nicht**

1. ✅ Check: `dbiSurvivalKit.llm.enabled` = true
2. ✅ Check: Cursor steht nach Aufgaben-Kommentar
3. ✅ Check: Schema ist im gleichen File
4. ✅ Check: LLM läuft (siehe oben)

### **Query ist falsch**

- 🔧 Reduziere `temperature` (0.0 = am deterministischsten)
- 🔧 Erhöhe `maxTokens` für komplexere Queries
- 🔧 Verwende besseres Modell (qwen2.5-coder-14b)

---

## 📊 **Performance**

| Metrik | Lokal (7B) | API (GPT-4) |
|--------|------------|-------------|
| Latenz | ~500ms | ~2000ms |
| Kosten | 0€ | ~$0.03/query |
| Offline | ✅ | ❌ |
| Qualität | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🎯 **Roadmap**

- [ ] Multi-Query Support (mehrere Aufgaben gleichzeitig)
- [ ] Cache für häufige Aufgaben
- [ ] Custom Prompts per Aufgabentyp
- [ ] Erklärungen in Tooltip
- [ ] Fine-tuning für DBI-spezifische Queries

---

## 🤓 **Tipp für Tests:**

**STRG + K + I** → Versteckt das "🤖 AI:" Label in IntelliSense!

Dann sieht's **wirklich** aus wie normale Tab-Completion! 😉

---

**Built with 🤓🤜🏻🤛🏻🤖 for HTL Leonding DBI Students**

