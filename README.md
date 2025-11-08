# 🎓 DBI Test Survival Kit

**Offline SQL Snippets & IntelliSense Extension for PostgreSQL and Oracle PL/SQL**

Perfect for DBI tests when you can't use external LLMs but tab-completion is allowed! 🤓

---

## ✨ Features

### 🧪 **Comprehensive Test Suite (NEW in v1.6.0!)**
- **10 Test Files** - 121 tasks covering ALL DBI topics
- **Real-World Scenarios** - Retail, Banking, E-Commerce, Healthcare, Education, etc.
- **All Complexity Levels** - Beginner 🟢 to Expert 🔴
- **Complete Coverage** - Star-Schema, Window Functions, MERGE, ROLLUP, SCD Type 2, ETL
- **See:** `test/README_TESTS.md` for testing guide

### 🚀 **300+ Professional SQL Snippets**
- ✅ **Star-Schema Templates** - Complete dimension and fact tables
- ✅ **PostgreSQL Specific** - SERIAL, JSONB, Arrays, Window Functions
- ✅ **Oracle PL/SQL Specific** - Sequences, Triggers, Packages, Procedures
- ✅ **Common Patterns** - JOINs, CTEs, Aggregations, Transactions

### 🤖 **AI-Powered Query Suggestions (ENHANCED in v1.6.0!)**
- **Smart Response Cleaning** - Multi-stage parser removes `<think>` blocks & explanations
- **SQL Validation** - Automatic syntax checking with quality scoring (0-100)
- **Enhanced Prompts** - Stop-sequences & few-shot examples for better results
- **Context-Aware** - Automatically reads schema and task from your file
- **Offline-Ready** - Works with ANY local LLM (LM Studio, Ollama, etc.)
- **Smart Caching** - Caches validated responses for instant retrieval
- **Debug Mode** - Visual feedback with validation scores

### 🧠 **Intelligent Tab-Completion**
- Context-aware suggestions
- Auto-completes foreign keys
- Smart dimension/fact table detection
- Optimized for test scenarios

### 🤝 **Share with Colleagues**
- Export your custom snippets
- Import snippets from team
- Merge and collaborate
- Build a shared knowledge base

### 📦 **100% Offline**
- No internet connection required
- No external API calls (unless you enable LLM)
- Instant performance
- Works during screen recording

---

## 🎯 Quick Start

### Installation

1. **From VSIX** (Recommended):
```bash
# Drag & Drop dbi-test-survival-kit-1.6.0.vsix into Cursor/VS Code
# OR: Extensions → Install from VSIX... → Select file
# THEN: Reload Window (Ctrl+Shift+P → "Reload Window")
```

2. **From Source** (Development):
```bash
cd D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit
npm install
vsce package
# Then install generated .vsix file
```

### Usage

**Basic Snippets:**
1. Open any `.sql` file
2. Type a trigger like `star-schema`
3. Press **Tab** ⌨️
4. Edit the template 🎨

**LLM-Assisted Queries:**
1. Open a `.sql` file with schema + task comments
2. Place cursor after task (e.g., `-- Aufgabe 1: ...`)
3. Press **`Ctrl+Alt+Shift+Q`** 🤖
4. LLM generates SQL query instantly!

**Testing:**
- See `test/README_TESTS.md` for 10 comprehensive test files
- 121 tasks covering ALL DBI topics
- Perfect for validating LLM performance!

---

## 📚 Snippet Reference

### Star-Schema Patterns

| Trigger | Description |
|---------|-------------|
| `star-schema` | Complete star schema with dimensions & fact table |
| `dim-table` | Dimension table with SCD Type 2 |
| `fact-table` | Fact table with measures and FKs |
| `dim-time` | Standard time dimension |

### PostgreSQL Specific

| Trigger | Description |
|---------|-------------|
| `pg-create-table` | Table with SERIAL and update trigger |
| `pg-serial` | SERIAL primary key |
| `pg-jsonb` | JSONB column |
| `pg-array` | Array column |
| `pg-matview` | Materialized view |
| `pg-function` | plpgsql function |
| `pg-trigger` | Trigger with function |
| `pg-upsert` | INSERT ON CONFLICT (upsert) |
| `pg-recursive` | Recursive CTE |

### Oracle PL/SQL Specific

| Trigger | Description |
|---------|-------------|
| `ora-create-table` | Table with sequence and triggers |
| `ora-sequence` | CREATE SEQUENCE |
| `ora-trigger-bi` | BEFORE INSERT trigger |
| `ora-procedure` | Stored procedure |
| `ora-function` | Function |
| `ora-package-spec` | Package specification |
| `ora-package-body` | Package body |
| `ora-cursor` | Cursor with loop |
| `ora-merge` | MERGE statement (upsert) |
| `ora-hierarchy` | Hierarchical query |

### Common SQL Patterns

| Trigger | Description |
|---------|-------------|
| `create-table` | CREATE TABLE with constraints |
| `sel` | Simple SELECT |
| `sel-join` | JOIN query |
| `sel-agg` | Aggregate with GROUP BY |
| `sel-sub` | Subquery |
| `sel-window` | Window function |
| `with-cte` | Common Table Expression |
| `ins` | INSERT statement |
| `upd` | UPDATE statement |
| `del` | DELETE statement |
| `trans` | Transaction block |

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Command |
|----------|---------|
| **`Ctrl+Alt+Shift+Q`** | **Query LLM for SQL Solution** 🤖 |
| `Ctrl+Alt+Shift+S` | Insert Star Schema |
| `Ctrl+Alt+Shift+D` | Insert Dimension Table |
| `Ctrl+Alt+Shift+F` | Insert Fact Table |
| `Ctrl+Alt+Shift+L` | Show LLM Statistics |

**Note:** Changed to `Ctrl+Alt+Shift` to avoid conflicts with built-in shortcuts!

---

## 🤝 Sharing with Colleagues

### Export Snippets
1. Press `Ctrl+Shift+P`
2. Type: `DBI: Export Snippets`
3. Choose save location
4. Share folder with colleagues

### Import Snippets
1. Press `Ctrl+Shift+P`
2. Type: `DBI: Import Snippets`
3. Select folder from colleagues
4. Reload VS Code

### Manual Sharing
Simply share the JSON files from:
```
D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit\snippets\
```

---

## 🤖 AI-Powered Completion (v1.1.0+)

### Quick Setup

1. **Enable LLM** in settings:
   ```json
   {
     "dbiSurvivalKit.llm.enabled": true,
     "dbiSurvivalKit.llm.endpoint": "http://localhost:1234/v1/chat/completions",
     "dbiSurvivalKit.llm.model": "qwen2.5-coder"
   }
   ```

2. **Use it in tests:**
   - Copy teacher's schema into your `.sql` file
   - Add task as comment: `-- Task: Find all books after 2000`
   - Position cursor below task
   - Press `Ctrl+Space` or start typing
   - Select the `🤖 AI: ...` suggestion
   - **Boom!** Query appears!

### Debug Mode

Enable visual feedback during development:

```json
{
  "dbiSurvivalKit.llm.showDebugInfo": true,
  "dbiSurvivalKit.llm.showNotifications": true,
  "dbiSurvivalKit.llm.verboseLogging": true
}
```

**Features:**
- 📊 Status bar shows LLM activity
- 🔔 Toast notifications for requests
- 📝 Verbose logging to output channel
- 🏷️ Debug labels in completion items

### Commands

| Command | Description |
|---------|-------------|
| `DBI: Show LLM Statistics` | View request count, cache hits, etc. |
| `DBI: Clear LLM Cache` | Clear cached responses |

See [LLM_FEATURE.md](LLM_FEATURE.md) for detailed documentation!

---

## 🎓 Based on HTL Leonding DBI Course

This extension was built specifically for the DBI (Datenbanken und Informationssysteme) course exercises:

- [DBI Übung 01](https://github.com/IxI-Enki/DBI_2025_26_uebung_01) - SQL Basics
- [DBI Übung 02](https://github.com/IxI-Enki/DBI_2025_26_uebung_02) - Star-Schema
- [DBI Übung 05](https://github.com/IxI-Enki/DBI_2025_26_uebung_05) - Advanced Queries

---

## 🛠️ Configuration

### Settings

```json
{
  "dbiSurvivalKit.enableAutoCompletion": true,
  "dbiSurvivalKit.enableStarSchemaTemplates": true,
  "dbiSurvivalKit.databaseDialect": "both"  // "postgres" | "oracle" | "both"
}
```

---

## 📖 Examples

### Example 1: Create Complete Star Schema

1. Type: `star-schema` + Tab
2. Fill in placeholders:
   - BusinessDomain: "Sales"
   - Time dimension
   - Customer dimension
   - Sales fact table
3. Result: Complete schema ready to run!

### Example 2: PostgreSQL Function

1. Type: `pg-function` + Tab
2. Define function name and parameters
3. Add logic
4. Done!

### Example 3: Oracle Package

1. Type: `ora-package-spec` + Tab
2. Define public interface
3. Type: `ora-package-body` + Tab
4. Implement procedures and functions

---

## 🐛 Troubleshooting

### Snippets not showing?
- Make sure file extension is `.sql` or `.plsql`
- Try reloading VS Code: `Ctrl+Shift+P` → "Reload Window"

### Import failed?
- Check that imported files are valid JSON
- Ensure file names match pattern: `*-snippets.json`

### Tab completion not working?
- Check VS Code settings: `"editor.tabCompletion": "on"`
- Verify extension is activated: Check status bar

---

## 📝 Contributing

Want to add more snippets?

1. Edit JSON files in `snippets/`
2. Follow existing pattern
3. Test with `F5` in VS Code
4. Share with colleagues!

### Snippet Format

```json
{
  "Snippet Name": {
    "prefix": "trigger-text",
    "body": [
      "Line 1 with ${1:placeholder}",
      "Line 2 with ${2:another}",
      "$0"
    ],
    "description": "What this snippet does"
  }
}
```

---

## 🤓 Credits

- **Created by:** IxI-Enki
- **For:** HTL Leonding DBI Students
- **Course:** Datenbanken und Informationssysteme (DBI) 2025/26
- **With Support From:** Cursor AI & Claude Sonnet

---

## 📄 License

MIT License - Use and share freely!

---

## 🎯 Version History

### 1.6.0 (2025-11-08) 🚀 **MAJOR UPDATE**
- 🧠 **NEW:** Smart Response Cleaning Pipeline (Multi-Stage Parser)
- ✅ **NEW:** SQL Validation Engine with Quality Scoring (0-100)
- 🎯 **NEW:** Enhanced Prompt Engineering with Stop-Sequences
- 📚 **NEW:** Few-Shot Examples in Prompts
- 🔧 **IMPROVED:** Works with ANY LLM (handles `<think>` blocks, explanations, etc.)
- 📊 **IMPROVED:** Validation-aware feedback notifications
- 🎨 **IMPROVED:** Model & endpoint display in status bar tooltip
- 📚 **DOCS:** Added SMART_LLM_FEATURES.md

### 1.5.0 (2025-11-08)
- 📊 **NEW:** Model name in status bar tooltip
- 🔧 **IMPROVED:** Better configuration display

### 1.4.0 (2025-11-08)
- ⌨️ **NEW:** Command-based LLM query (Ctrl+Alt+Shift+Q)
- 🐛 **FIXED:** Reliable LLM triggering mechanism

### 1.1.0 - 1.3.0 (2025-11-08)
- 🤖 **NEW:** AI-Powered Query Suggestions
- 📊 **NEW:** Debug Mode with Status Bar & Notifications
- ⚡ **NEW:** Smart Caching for LLM Responses
- ⌨️ **IMPROVED:** Better Keyboard Shortcuts (Ctrl+Alt+Shift)
- 🐛 **FIXED:** Installation & caching issues

### 1.0.0 (2025-11-07)
- ✅ Initial release
- ✅ 300+ snippets for PostgreSQL and Oracle
- ✅ Star-Schema templates
- ✅ Import/Export functionality
- ✅ Intelligent completion provider

---

**Happy Coding! May your queries be fast and your schemas normalized! 🚀**
