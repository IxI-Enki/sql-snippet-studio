# 🚀 Setup Guide - DBI Survival Kit

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
cd "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit"
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
cd "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit"
vsce package
```

3. **Install VSIX:**

```powershell
code --install-extension dbi-test-survival-kit-1.0.0.vsix
```

4. **Share with colleagues:**

- Send them the `.vsix` file
- They run: `code --install-extension dbi-test-survival-kit-1.0.0.vsix`

---

### Method 3: Development Mode

1. **Open Extension in VS Code:**

```powershell
cd "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit"
code .
```

2. **Run Extension:**

- Press `F5`
- A new VS Code window opens with extension loaded
- Test your snippets
- Make changes and reload

<!-- markdownlint-enable MD029 -->

---

## 🧪 Testing Your Installation

### Test 1: Basic Snippets

1. Create new file: `test.sql`
2. Type: `create-table` + Tab
3. Should show CREATE TABLE template

### Test 2: Star Schema

1. Type: `star-schema` + Tab
2. Should show complete Star Schema template
3. Tab through placeholders

### Test 3: PostgreSQL Specific

1. Type: `pg-function` + Tab
2. Should show plpgsql function template

### Test 4: Oracle Specific

1. Type: `ora-procedure` + Tab
2. Should show Oracle procedure template

### Test 5: Commands

1. Press `Ctrl+Shift+P`
2. Type: `DBI:`
3. Should see all DBI commands listed

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
  "dbiSurvivalKit.databaseDialect": "postgres"  // or "oracle"
}
```

---

## Backup and export

### Export your snippets

```powershell
# Or use: Ctrl+Shift+P → DBI: Export Snippets
xcopy "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit\snippets" "D:\dbi-backup\snippets" /E /I /Y
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
- Search for "DBI Survival Kit"
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
code --uninstall-extension dbi-team.dbi-test-survival-kit
code --install-extension dbi-test-survival-kit-1.0.0.vsix
```

---

## 🤝 Sharing with colleagues

### Method 1: Share VSIX File

1. Package extension: `vsce package`
2. Send `.vsix` file to colleagues
3. They install: `code --install-extension <file>.vsix`

### Method 2: Share Snippets Only

1. Export snippets: `Ctrl+Shift+P` → `DBI: Export Snippets`
2. Send folder to colleagues
3. They import: `Ctrl+Shift+P` → `DBI: Import Snippets`

### Method 3: Git Repository

<!-- markdownlint-disable MD029 -->

1. Push to GitHub:

```bash
cd "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit"
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main
```

2. colleagues clone and install:

```bash
git clone <repo-url>
cd dbi-test-survival-kit
code --install-extension .
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
- Export a backup via **DBI: Export Snippets**

---

## 📊 Extension Structure

```file-tree
04_dbi_test_survival_kit/
├── package.json
├── language-configuration.json
├── README.md
├── docs/
│   ├── guides/          # Setup, quickstart, LLM
│   ├── changelogs/
│   └── archive/
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

- [guides/quickstart.md](guides/quickstart.md)
- [guides/llm_feature.md](guides/llm_feature.md)
- [Documentation index](../README.md)
