# 🚨 CRITICAL HOTFIX v1.8.4 - Deployment Instructions

**Priority:** 🔥 IMMEDIATE (fixes blocking activation bug)
**Date:** 2025-11-09
**For:** All team members experiencing activation issues

---

## 🎯 **PROBLEM THIS FIXES:**

If you experienced ANY of these issues:

- ❌ Extension status shows "Not yet activated"
- ❌ Error: "Unknown language in contributes: postgresql"
- ❌ Status bar doesn't show "LLM Ready"
- ❌ Commands missing from Command Palette
- ❌ Snippets not appearing (pg-*, ora-*, star-*)

**→ v1.8.4 FIXES ALL OF THESE!** ✅

---

## 📦 **INSTALLATION STEPS:**

### **Step 1: Uninstall Old Version**

**IMPORTANT:** Must uninstall first to avoid conflicts!

```bash
code --uninstall-extension dbi-team.dbi-test-survival-kit

```

Or manually:

1. Open VS Code
2. Extensions view (Ctrl+Shift+X)
3. Find "SQL Snippet Studio"
4. Click gear icon → Uninstall
5. **Close ALL VS Code windows!**

---

### **Step 2: Install v1.8.4**

**File:** `dbi-test-survival-kit-1.8.4.vsix` (1.09 MB)

Command Line:
```bash
code --install-extension dbi-test-survival-kit-1.8.4.vsix

```

Or GUI:

1. Open VS Code
2. Extensions view (Ctrl+Shift+X)
3. Click "..." (three dots) → "Install from VSIX..."
4. Select `dbi-test-survival-kit-1.8.4.vsix`
5. Wait for "Extension installed successfully"

---

### **Step 3: Full Restart**

**CRITICAL:** Must restart completely!

1. Close ALL VS Code windows
2. Wait 5 seconds (let processes terminate)
3. Reopen VS Code
4. Open any `.sql` file

---

### **Step 4: Verify Installation**

#### **✅ Check 1: Runtime Status**

1. Open Extensions view (Ctrl+Shift+X)
2. Click on "SQL Snippet Studio"
3. Click "Runtime Status" tab
4. **Expected:** "Activation: Activated"
5. **Expected:** No error messages

If you see "Not yet activated":

- Open a `.sql` file (this triggers activation)
- Wait 2 seconds
- Refresh Runtime Status

If you see error messages:

- Screenshot the error
- Report immediately!

---

#### **✅ Check 2: Status Bar**

If LLM enabled:

- Bottom right should show "LLM Ready" (green)

If LLM disabled:

- No status bar item (this is normal)

---

#### **✅ Check 3: Commands**

1. Open Command Palette (Ctrl+Shift+P)
2. Type: `SQL:`
3. **Expected:** All commands visible:
   - SQL: Query LLM for SQL Solution
   - SQL: Show LLM Statistics
   - SQL: Clear LLM Cache
   - SQL: Insert Star Schema Template
   - SQL: Insert Dimension Table
   - SQL: Insert Fact Table
   - etc.

If commands missing:

- Check Runtime Status (Step 1)
- Try opening a `.sql` file
- Full restart again

---

#### **✅ Check 4: Snippets**

1. Open any `.sql` file
2. Type: `pg-`
3. **Expected:** IntelliSense shows PostgreSQL snippets:
   - pg-create-table
   - pg-insert
   - pg-select
   - pg-trigger
   - etc.

4. Type: `ora-`
5. **Expected:** IntelliSense shows Oracle snippets

6. Type: `star-`
7. **Expected:** IntelliSense shows Star Schema snippets

If snippets NOT appearing:

- Check file is recognized as SQL (bottom right: "SQL" or "Plain Text")
- Try Ctrl+Space to force IntelliSense
- Check Runtime Status

---

#### **✅ Check 5: LLM Query (if enabled)**

1. Open `.sql` file with schema + task:
```sql
-- SCHEMA:
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- TASK: Show all customers

```

2. Select the schema + task
3. Press: `Ctrl+Alt+Shift+Q`
4. **Expected:** SQL query appears after schema

If nothing happens:

- Check settings: `dbiSurvivalKit.llm.enabled` = true
- Check LM Studio is running (http://localhost:1234)
- Check Output panel → "SQL Snippet Studio" for errors

---

## 🐛 **TROUBLESHOOTING:**

### **Problem: "Not yet activated"**

Solution:

1. Open a `.sql` file (triggers activation)
2. Wait 2 seconds
3. Check Runtime Status again

---

### **Problem: Snippets not appearing**

Solution:

1. Check file language (bottom right corner)
2. If "Plain Text", change to "SQL":
   - Click "Plain Text"
   - Type "SQL"
   - Select "SQL"
3. Try `Ctrl+Space` to force IntelliSense

---

### **Problem: Commands missing**

Solution:

1. Check Runtime Status for errors
2. Full restart (close ALL windows)
3. Reinstall extension (uninstall → install → restart)

---

### **Problem: LLM not responding**

Check:

1. Is LM Studio running? (http://localhost:1234)
2. Is model loaded in LM Studio?
3. Check settings:
   - `dbiSurvivalKit.llm.enabled` = true
   - `dbiSurvivalKit.llm.endpoint` = "http://localhost:1234/v1/chat/completions"
   - `dbiSurvivalKit.llm.model` = your model name
4. Check Output panel for errors

---

### **Problem: Still errors after v1.8.4**

Report:

1. Screenshot Runtime Status (with error messages)
2. Output panel content ("SQL Snippet Studio")
3. Your VS Code version: Help → About
4. Your OS: Windows/Mac/Linux

---

## 📊 **WHAT CHANGED IN v1.8.4:**

Technical Details:

Removed:

- `{"language": "postgresql", "path": "./snippets/postgres-snippets.json"}`
- `{"language": "postgresql", "path": "./snippets/shared-snippets.json"}`

**Why:** VS Code doesn't recognize `"postgresql"` as a built-in language ID, causing activation failures.

**Now using:** Only standard language IDs (`"sql"` and `"plsql"`)

**Result:** 100% VS Code compatibility ✅

---

## ✅ **SUCCESS CRITERIA:**

After installation, ALL of these should be TRUE:

- [ ] Runtime Status: "Activated" (no errors)
- [ ] Commands visible in Command Palette
- [ ] Snippets appear in `.sql` files (pg-*, ora-*, star-*)
- [ ] Status bar shows "LLM Ready" (if LLM enabled)
- [ ] LLM query works (Ctrl+Alt+Shift+Q) (if LLM enabled)

**If ALL checked → SUCCESS!** 🎉

**If ANY unchecked → Report issue!** 🐛

---

## 📞 **SUPPORT:**

If you have issues:

1. Follow Troubleshooting steps above
2. Try full uninstall → restart → reinstall
3. If still fails: Report with screenshots

**Expected:** 100% success rate for all team members! 💪

---

## 🎓 **WHY THIS HAPPENED:**

v1.8.2 introduced the bug:

- Added `"postgresql"` language ID for better snippet support
- Worked in Cursor (more forgiving)
- Failed in VS Code (stricter validation)
- 75% failure rate in team (3 out of 4 users!)

v1.8.4 fixes it:

- Use ONLY standard language IDs
- 100% VS Code compatibility
- Tested in clean installations

**Lesson learned:** Always test in clean VS Code, not just dev environments!

---

**Version:** 1.8.7
**Status:** ✅ Ready for deployment
**Priority:** 🔥 CRITICAL

**DEPLOY NOW!** 🚀
