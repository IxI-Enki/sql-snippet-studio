# 🚀 Setup Guide - DBI Test Survival Kit

## 📋 Prerequisites

- VS Code or Cursor IDE
- Node.js (optional, only for development)
- Git (optional, for version control)

---

## 🎯 Installation Methods

### Method 1: Quick Install (Recommended for Test Day)

<!-- markdownlint-disable MD029 -->
1. **Copy Extension Folder:**

  ```powershell
  # Copy the entire extension folder to your VS Code extensions directory
  xcopy "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit" "%USERPROFILE%\.vscode\extensions\dbi-test-survival-kit" /E /I /Y
  ```

2. **Reload VS Code:**

- Press `Ctrl+Shift+P`
- Type: "Reload Window"
- Press Enter

3. **Verify Installation:**

- Open a `.sql` file
- Type `star-schema`
- Press Tab
- ✅ Template should appear!

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

## 📦 Preparing for Test Day

### 1. Pre-Test Checklist

- [ ] Extension installed and working
- [ ] Test all snippets work
- [ ] Keyboard shortcuts memorized
- [ ] Settings configured
- [ ] Backup snippets exported

### 2. Export Your Snippets

Before test day, export your customized snippets:

```powershell
# Manual export
xcopy "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit\snippets" "D:\dbi-backup\snippets" /E /I /Y
```

Or use command: `Ctrl+Shift+P` → `DBI: Export Snippets`

### 3. USB Stick Backup

Copy to USB stick:

```file-tree
USB:\
├── dbi-test-survival-kit-1.0.0.vsix
├── snippets\
│   ├── shared-snippets.json
│   ├── postgres-snippets.json
│   └── oracle-snippets.json
└── INSTALL_INSTRUCTIONS.txt
```

---

## 🔧 Troubleshooting

### Issue: Snippets Don't Show Up

**Solution 1:** Check file extension

- File must be `.sql` or `.plsql`

**Solution 2:** Reload window

- `Ctrl+Shift+P` → "Reload Window"

**Solution 3:** Check extension is active

- `Ctrl+Shift+P` → "Show Installed Extensions"
- Search for "DBI Test Survival Kit"
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

### 4. Test

- Type `your-trigger` + Tab
- Should show your custom snippet!

---

## 🎓 Best Practices for Test Day

### 1. Know Your Triggers

Memorize common ones:

- `star-schema` - Complete schema
- `dim-table` - Dimension table
- `fact-table` - Fact table
- `sel-join` - JOIN query
- `with-cte` - CTE

### 2. Use Keyboard Shortcuts

- `Ctrl+Shift+S` - Insert Star Schema
- `Ctrl+Shift+D` - Insert Dimension
- `Ctrl+Shift+F` - Insert Fact Table

### 3. Practice Beforehand

- Go through previous DBI exercises
- Use snippets to solve them
- Get muscle memory for common patterns

### 4. Customize Before Test

- Add snippets for patterns from your exercises
- Export and backup everything
- Test that all snippets work

---

## 📊 Extension Structure

```file-tree
04_dbi_test_survival_kit/
├── package.json                  # Extension manifest
├── language-configuration.json   # SQL language config
├── README.md                     # User documentation
├── SETUP_GUIDE.md                # This file
├── PROJECT_CONTEXT.md            # Developer context
├── snippets/
│   ├── shared-snippets.json      # Common patterns
│   ├── postgres-snippets.json    # PostgreSQL specific
│   └── oracle-snippets.json      # Oracle specific
├── src/
│   └── extension.js              # Extension logic
├── images/
│   └── icon.png                  # Extension icon (TODO)
└── test/
    └── test-suite.sql            # Test cases (TODO)
```

---

## 🚨 Emergency Procedures

### If Extension Breaks During Test

**Plan A:** Use Snippets Manually

1. Open `snippets/shared-snippets.json`
2. Copy/paste templates manually
3. Edit in SQL file

**Plan B:** Use Backup USB

1. Plug in USB stick
2. Copy snippet files to desktop
3. Open and copy/paste

**Plan C:** Your Knowledge

1. You know the patterns!
2. Write from scratch
3. Use snippets as reference

---

## ✅ Final Checklist Before Test

- [ ] Extension installed
- [ ] All snippets tested
- [ ] Keyboard shortcuts work
- [ ] Settings optimized
- [ ] Backup on USB
- [ ] Practiced with previous exercises
- [ ] Read through snippet reference
- [ ] Confident and ready! 🚀

---

<!-- markdownlint-disable-next-line MD036 -->
**Good luck on your DBI test! You got this! 🤓🤜🏻🤛🏻🤖**
