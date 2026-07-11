# Setup Guide - SQL Snippet Studio

## 📋 Prerequisites

- VS Code or Cursor IDE
- Node.js (optional, only for development)
- Git (optional, for version control)

---

## 🎯 Installation Methods

### Method 1: Install from VSIX (recommended)

<!-- markdownlint-disable MD029 -->

1. **Package or obtain VSIX:**

```powershell
cd <path-to-repo>
npm install
npx vsce package

```

2. **Install:** Extensions → Install from VSIX… → select the `.vsix` file

3. **Reload VS Code:** `Ctrl+Shift+P` → Reload Window

4. **Verify:** Open a `.sql` file, type `star-schema`, press Tab

---

### Method 2: Package as VSIX (Recommended for Sharing)

1. **Install vsce (VS Code Extension Manager):**

```powershell
npm install -g @vscode/vsce

```

2. **Package Extension:**

```powershell
cd <path-to-repo>
vsce package

```

3. **Install VSIX:**

```powershell
code --install-extension sql-snippet-studio-2.0.0.vsix

```

4. **Share with colleagues:**

- Send them the `.vsix` file
- They run: `code --install-extension sql-snippet-studio-2.0.0.vsix`

---

### Method 3: Development Mode

1. **Open Extension in VS Code:**

```powershell
cd <path-to-repo>
code .

```

2. **Run Extension:**

- Press `F5`
- A new VS Code window opens with extension loaded
- Test your snippets
- Make changes and reload

<!-- markdownlint-enable MD029 -->

---

## Verify your installation

### Check 1: Basic snippets

1. Create a new file: `example.sql`
2. Type: `create-table` + Tab
3. You should see a CREATE TABLE template

### Check 2: Star schema

1. Type: `star-schema` + Tab
2. You should see a complete star-schema template
3. Tab through placeholders

### Check 3: PostgreSQL

1. Type: `pg-function` + Tab
2. You should see a PL/pgSQL function template

### Check 4: Oracle

1. Type: `ora-procedure` + Tab
2. You should see an Oracle procedure template

### Check 5: Commands

1. Press `Ctrl+Shift+P`
2. Type: `SQL:`
3. All SQL commands should be listed

---

## ⚙️ Configuration

### Enable Tab Completion

Add to your `settings.json`:

```json
{
  "editor.tabCompletion": "on",
  "editor.snippetSuggestions": "top",
  "editor.suggest.showSnippets": true,
  "editor.quickSuggestions": {
    "other": true,
    "comments": false,
    "strings": true
  }
}

```

### Database-Specific Mode

If you only work with one database:

```json
{
  "sqlSnippetStudio.databaseDialect": "postgres"  // or "oracle"
}

```

---

## Backup and export

### Export your snippets

```powershell
# Or use: Ctrl+Shift+P → SQL: Export Snippets
xcopy "<path-to-repo>\snippets" "%USERPROFILE%\sql-snippet-studio-backup\snippets" /E /I /Y

```

Keep a copy of your customized snippets and the latest `.vsix` for reinstall or sharing.

---

## 🔧 Troubleshooting

### Issue: Snippets Don't Show Up

**Solution 1:** Check file extension

- File must be `.sql` or `.plsql`

**Solution 2:** Reload window

- `Ctrl+Shift+P` → "Reload Window"

**Solution 3:** Check extension is active

- `Ctrl+Shift+P` → "Show Installed Extensions"
- Search for "SQL Snippet Studio"
- Should show "Active"

### Issue: Wrong Suggestions Appearing

**Solution:** Adjust trigger context

- Type full prefix (e.g., `star-schema`)
- Don't rely on partial matches
- Use `Ctrl+Space` to force suggestion

### Issue: Tab Not Working

**Solution:** Check tab completion settings

```json
{
  "editor.tabCompletion": "on"
}

```

### Issue: Extension Not Loading

**Solution 1:** Check logs

- Help → Toggle Developer Tools
- Check Console for errors

**Solution 2:** Reinstall

```powershell
# Uninstall both IDs if upgrading from v1.8.x or after a partial v2 install
code --uninstall-extension IxI-Enki.sql-snippet-studio
code --uninstall-extension dbi-team.dbi-test-survival-kit   # pre-v2 extension ID
code --install-extension sql-snippet-studio-2.0.0.vsix

```

---

## 🤝 Sharing with colleagues

### Method 1: Share VSIX File

1. Package extension: `vsce package`
2. Send `.vsix` file to colleagues
3. They install: `code --install-extension <file>.vsix`

### Method 2: Share Snippets Only

1. Export snippets: `Ctrl+Shift+P` → `SQL: Export Snippets`
2. Send folder to colleagues
3. They import: `Ctrl+Shift+P` → `SQL: Import Snippets`

### Method 3: Git Repository

<!-- markdownlint-disable MD029 -->

1. Push to GitHub:

```bash
cd <path-to-repo>
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main

```

2. colleagues clone and install:

```bash
git clone <repo-url>
cd sql-snippet-studio
npm install
vsce package
code --install-extension sql-snippet-studio-2.0.0.vsix

```

<!-- markdownlint-enable MD029 -->

---

## 📝 Adding Custom Snippets

### 1. Edit Snippet Files

Open:

- `snippets/shared-snippets.json` - For both databases
- `snippets/postgres-snippets.json` - PostgreSQL only
- `snippets/oracle-snippets.json` - Oracle only

### 2. Add Your Snippet

```json
{
  "Your Custom Snippet": {
    "prefix": "your-trigger",
    "body": [
      "-- Your custom SQL",
      "SELECT ${1:columns}",
      "FROM ${2:table}",
      "WHERE ${3:condition};",
      "$0"
    ],
    "description": "What your snippet does"
  }
}

```

### 3. Reload VS Code

- `Ctrl+Shift+P` → "Reload Window"

### 4. Try it

- Type `your-trigger` + Tab
- Your custom snippet should appear

---

## Tips for daily use

### Know common triggers

- `star-schema` — Complete schema
- `dim-table` — Dimension table
- `fact-table` — Fact table
- `sel-join` — JOIN query
- `with-cte` — CTE

### Use keyboard shortcuts

- `Ctrl+Alt+Shift+S` — Insert star schema
- `Ctrl+Alt+Shift+D` — Insert dimension table
- `Ctrl+Alt+Shift+F` — Insert fact table
- `Ctrl+Alt+Shift+Q` — Query LLM for SQL solution

### Customize snippets

- Add patterns you use often under `snippets/`
- Export a backup via **SQL: Export Snippets**

---

## Extension structure

```file-tree
sql-snippet-studio/
├── package.json
├── language-configuration.json
├── README.md
├── docs/
│   ├── README.md
│   └── guides/
├── snippets/
│   ├── shared-snippets.json
│   ├── postgres-snippets.json
│   └── oracle-snippets.json
├── src/
│   └── extension.js
└── images/
    └── icon.png

```

---

## Related documentation

- [guides/quickstart.md](quickstart.md)
- [guides/llm_feature.md](llm_feature.md)
- [Documentation index](../README.md)
