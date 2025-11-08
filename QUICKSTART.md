# ⚡ Quick Start - DBI Test Survival Kit

## 🚀 5-Minute Setup

### 1. Install (Choose One)

**Option A: PowerShell Script** (Recommended)
```powershell
cd "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit"
.\INSTALL.ps1
```

**Option B: Manual Copy**
```powershell
xcopy "D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit" "%USERPROFILE%\.vscode\extensions\dbi-test-survival-kit" /E /I /Y
```

### 2. Reload IDE
- Press `Ctrl+Shift+P`
- Type: "Reload Window"
- Press Enter

### 3. Test It Works
- Create file: `test.sql`
- Type: `star-schema`
- Press **Tab** ⌨️
- ✅ Template appears!

---

## 🎯 Essential Snippets

### Star Schema
```
star-schema → Complete star schema
dim-table   → Dimension table
fact-table  → Fact table
```

### Common SQL
```
sel         → SELECT statement
sel-join    → JOIN query
sel-agg     → Aggregate with GROUP BY
with-cte    → Common Table Expression
```

### PostgreSQL
```
pg-function → plpgsql function
pg-trigger  → Trigger with function
pg-serial   → SERIAL primary key
```

### Oracle
```
ora-procedure → Stored procedure
ora-trigger-bi → BEFORE INSERT trigger
ora-sequence → CREATE SEQUENCE
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+S` | Insert Star Schema |
| `Ctrl+Shift+D` | Insert Dimension Table |
| `Ctrl+Shift+F` | Insert Fact Table |

---

## 📝 Typical Workflow

### Example: Build Star Schema

1. **Open SQL File**
   ```sql
   -- Empty file: company_dwh.sql
   ```

2. **Insert Star Schema**
   - Type: `star-schema` + Tab
   - Fill placeholders:
     - Domain: "Sales"
     - Time dimension
     - Customer dimension
     - Sales facts

3. **Result: Complete Schema!**
   ```sql
   -- ═══════════════════════════════════════════════
   -- STAR SCHEMA: Sales
   -- ═══════════════════════════════════════════════
   
   CREATE TABLE DIM_Time (...);
   CREATE TABLE DIM_Customer (...);
   CREATE TABLE FACT_Sales (...);
   ```

---

## 🤝 Share with colleagues

### Export Your Snippets
```powershell
# Press Ctrl+Shift+P
# Type: DBI: Export Snippets
# Select save location
# Share folder with colleagues
```

### Import from colleagues
```powershell
# Press Ctrl+Shift+P
# Type: DBI: Import Snippets
# Select their folder
# Reload VS Code
```

---

## 🎓 Test Day Preparation

### Day Before Test
- [ ] Install extension
- [ ] Test all snippets
- [ ] Customize patterns
- [ ] Export backup to USB
- [ ] Practice with old exercises

### During Test
1. Open SQL file
2. Use snippets: `trigger` + Tab
3. Modify templates
4. Write queries
5. Pass test! 🎉

---

## 🐛 Quick Fixes

**Snippets not showing?**
→ Reload: `Ctrl+Shift+P` → "Reload Window"

**Tab not working?**
→ Settings: `"editor.tabCompletion": "on"`

**Wrong suggestions?**
→ Type full trigger (e.g., `star-schema`)

---

## 📚 More Info

- **Full Documentation:** `README.md`
- **Setup Guide:** `SETUP_GUIDE.md`
- **Developer Context:** `PROJECT_CONTEXT.md`

---

## 💪 You're Ready!

**What You Have:**
✅ 300+ professional SQL snippets  
✅ Star-Schema templates  
✅ PostgreSQL & Oracle support  
✅ 100% offline & fast  
✅ Shareable with team  

**Now Go Ace That Test! 🚀🤓**
