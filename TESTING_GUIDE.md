# 🧪 Testing Guide - DBI Survival Kit v1.6.0

## **🎯 Quick Testing Guide**

### **Step 1: Install Extension**
```bash
# Drag & Drop dbi-test-survival-kit-1.6.0.vsix into Cursor
# Reload Window: Ctrl+Shift+P → "Developer: Reload Window"
```

### **Step 2: Configure LLM**
```bash
# Open Settings: Ctrl+,
# Search: "DBI Survival Kit"
# Configure:
- ✅ Enable LLM: ON
- 🌐 Endpoint: http://localhost:1234/v1/chat/completions
- 🤖 Model: qwen2.5-7b-instruct (or your model)
```

### **Step 3: Start LM Studio**
```bash
# 1. Open LM Studio
# 2. Load a model (e.g., qwen2.5-7b-instruct)
# 3. Start Local Server (port 1234)
```

### **Step 4: Test**
```bash
# 1. Open: test/llm_test_01_retail_basic.sql
# 2. Place cursor after: -- Aufgabe 1: ...
# 3. Press: Ctrl+Alt+Shift+Q
# 4. Watch: Status bar (bottom right)
# 5. Verify: SQL is inserted below task
```

---

## **🔍 What to Check**

### **✅ Success Indicators:**
- ✅ Status bar shows: "$(database) LLM Ready"
- ✅ Hover shows: Model name & endpoint
- ✅ Toast notification: "🤖 Querying LLM..." (if enabled)
- ✅ SQL is inserted below task
- ✅ No `<think>` blocks in output
- ✅ Validation score: 85-100

### **⚠️ Warning Signs:**
- ⚠️ Validation score: 70-84
- ⚠️ Warnings in Output Channel
- ⚠️ Minor syntax issues (easily fixable)

### **❌ Failure Indicators:**
- ❌ No response after 10+ seconds
- ❌ Error message: "LLM returned empty response"
- ❌ `<think>` blocks still present
- ❌ Syntax errors (validation score <70)
- ❌ Completely wrong SQL

---

## **📊 Testing Protocol**

### **Test Each File:**

```bash
test/
├── llm_test_01_retail_basic.sql          (8 tasks)  🟢 START HERE
├── llm_test_02_logistics_advanced.sql    (8 tasks)  🟡
├── llm_test_03_sales_analytics_window.sql (8 tasks)  🟡
├── llm_test_04_time_series_lag_lead.sql  (12 tasks) 🟡
├── llm_test_05_product_catalog_merge.sql (8 tasks)  🟢
├── llm_test_06_banking_multifact.sql     (12 tasks) 🔴
├── llm_test_07_ecommerce_snowflake.sql   (13 tasks) 🔴
├── llm_test_08_healthcare_scd2.sql       (13 tasks) 🟡
├── llm_test_09_education_all_window.sql  (21 tasks) 🔴
└── llm_test_10_mixed_expert.sql          (18 tasks) 🔴 ULTIMATE TEST
```

### **For Each Task:**

1. **Trigger LLM:**
   - Place cursor after task
   - Press `Ctrl+Alt+Shift+Q`

2. **Watch Status:**
   - Status bar: "Querying LLM..."
   - Output Channel: Verbose logs (if enabled)

3. **Evaluate Result:**
   - SQL inserted? ✅/❌
   - Syntax correct? ✅/❌
   - Logic correct? ✅/❌
   - Validation score? XX/100

4. **Document:**
   - Copy to `TEST_RESULTS_TEMPLATE.md`
   - Note any issues
   - Rate difficulty

---

## **🐛 Debugging**

### **Problem: "No response"**

**Check:**
1. LM Studio running? (http://localhost:1234)
2. Model loaded?
3. Extension settings correct?
4. Check Output Channel: `Ctrl+Shift+U` → "DBI Survival Kit - LLM"

**Fix:**
```bash
# Test LM Studio connection:
curl http://localhost:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model",
    "messages": [{"role": "user", "content": "SELECT 1;"}]
  }'
```

### **Problem: "`<think>` blocks still present"**

**Check:**
1. Extension version 1.6.0+?
2. Parser enabled?
3. Model using `<think>` tags?

**Fix:**
- Update to v1.6.0+
- Parser should auto-remove
- Check Output Channel for parser logs

### **Problem: "Syntax errors"**

**Check:**
1. Model appropriate for task?
2. Validation score?
3. Specific error in Output Channel?

**Fix:**
- Try simpler test first (Test 1)
- Check if model supports SQL
- Consider trying different model

---

## **📈 Performance Benchmarks**

### **Expected Response Times:**

| Model Size | Simple Queries | Complex Queries | Expert Queries |
|------------|----------------|-----------------|----------------|
| **4B** | <3s | <5s | <10s |
| **7B** | <2s | <4s | <8s |
| **13B+** | <2s | <3s | <6s |

### **Expected Success Rates:**

| Test Difficulty | 4B Models | 7B Models | 13B+ Models |
|-----------------|-----------|-----------|-------------|
| **🟢 Beginner** | 80%+ | 90%+ | 95%+ |
| **🟡 Intermediate** | 60%+ | 80%+ | 90%+ |
| **🔴 Advanced** | 40%+ | 70%+ | 85%+ |
| **🔴 Expert** | 20%+ | 60%+ | 75%+ |

---

## **💡 Tips for Best Results**

### **Model Selection:**
- **Small (4B):** Tests 1-2, 5
- **Medium (7B):** Tests 1-8
- **Large (13B+):** Tests 1-10

### **Temperature Settings:**
- **Low (0.1-0.3):** More consistent, less creative
- **Medium (0.4-0.6):** Balanced
- **High (0.7-1.0):** More creative, less consistent

**Recommendation:** `0.1-0.2` for SQL queries

### **Max Tokens:**
- **Simple:** 200-300 tokens
- **Complex:** 400-600 tokens
- **Expert:** 600-1000 tokens

**Recommendation:** `500` (default)

---

## **📝 Reporting Issues**

### **Found a Bug?**

1. Document in `TEST_RESULTS_TEMPLATE.md`
2. Include:
   - Model name & version
   - Test file & task number
   - Expected vs actual result
   - Validation score
   - Error messages (from Output Channel)

### **Feature Request?**

1. Describe use case
2. Expected behavior
3. Why it would help

---

## **🎓 Best Practices**

1. **Start Simple:** Begin with Test 1, progress to Test 10
2. **Check Logs:** Always review Output Channel
3. **Compare Models:** Test multiple models on same task
4. **Document Everything:** Use `TEST_RESULTS_TEMPLATE.md`
5. **Be Patient:** Complex queries take time
6. **Iterate:** If query fails, try again or simplify task

---

## **📚 Resources**

- **Test Files:** `test/README_TESTS.md`
- **Research Plan:** `TEST_RESEARCH_PLAN.md`
- **Feature Docs:** `SMART_LLM_FEATURES.md`
- **LLM Setup:** `LLM_FEATURE.md`
- **Main README:** `README.md`

---

**Happy Testing! 🤓🤜🏻🤛🏻🤖**

**Questions? Check the documentation or open an issue!**
