# Quick Start — SQL Snippet Studio

## 5-minute setup

### 1. Install

Option A: From VSIX (recommended)

1. Build or obtain `sql-snippet-studio-*.vsix`
2. In VS Code / Cursor: **Extensions → Install from VSIX…**
3. Select the `.vsix` file

Option B: From source

```powershell
cd <path-to-repo>
npm install
npx vsce package
# Install the generated .vsix via Extensions → Install from VSIX…

```

### 2. Reload IDE

- Press `Ctrl+Shift+P`
- Type: **Reload Window**
- Press Enter

### 3. Verify it works

- Create a file: `example.sql`
- Type: `star-schema`
- Press **Tab**
- A template should appear

---

## Essential snippets

### Star schema

| Trigger | Result |
| ------- | ------ |
| `star-schema` | Complete star schema |
| `dim-table` | Dimension table |
| `fact-table` | Fact table |

### Common SQL

| Trigger | Result |
| ------- | ------ |
| `sel` | SELECT statement |
| `sel-join` | JOIN query |
| `sel-agg` | Aggregate with GROUP BY |
| `with-cte` | Common Table Expression |

### PostgreSQL

| Trigger | Result |
| ------- | ------ |
| `pg-function` | plpgsql function |
| `pg-trigger` | Trigger with function |
| `pg-serial` | SERIAL primary key |

### Oracle

| Trigger | Result |
| ------- | ------ |
| `ora-procedure` | Stored procedure |
| `ora-trigger-bi` | BEFORE INSERT trigger |
| `ora-sequence` | CREATE SEQUENCE |

---

## Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `Ctrl+Alt+Shift+S` | Insert star schema |
| `Ctrl+Alt+Shift+D` | Insert dimension table |
| `Ctrl+Alt+Shift+F` | Insert fact table |
| `Ctrl+Alt+Shift+Q` | Query LLM for SQL solution |

---

## Typical workflow

1. Open a `.sql` file with your schema
2. Type a snippet trigger (e.g. `star-schema`) and press **Tab**
3. Fill in placeholders
4. Optionally enable [local LLM assistance](guides/llm_feature.md) for query suggestions

---

## Share snippets

- **Export:** `Ctrl+Shift+P` → **SQL: Export Snippets**
- **Import:** `Ctrl+Shift+P` → **SQL: Import Snippets** → reload window

---

## Quick fixes

| Problem | Fix |
| ------- | --- |
| Snippets not showing | Reload window (`Ctrl+Shift+P` → Reload Window) |
| Tab not working | Set `"editor.tabCompletion": "on"` |
| Wrong suggestions | Type the full trigger (e.g. `star-schema`) |

---

## More documentation

- [Setup guide](guides/setup_guide.md) — installation, configuration, troubleshooting
- [LLM feature](guides/llm_feature.md) — optional local LLM setup
- [Documentation index](../README.md)
