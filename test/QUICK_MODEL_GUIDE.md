# 🚀 QUICK MODEL SELECTION GUIDE

**TL;DR:** Upgrade from 7B to 32B for Production!

---

## ⚡ QUICK DECISION TREE

### ❓ How much RAM do you have?

#### **8-16GB RAM:**
→ **Qwen2.5-Coder-7B (Q4_K_M)** - 5GB  
⚠️ Score: ~45/100 (NOT RECOMMENDED for DBI Tests)  
💡 **Better:** Use cloud API (DeepSeek, GPT-4)

---

#### **16-24GB RAM:**
→ **Qwen2.5-Coder-14B (Q4_K_M)** - 9GB ⭐  
✅ Score: ~72/100 (ACCEPTABLE for Development)

**Download:**
```
https://huggingface.co/Qwen/Qwen2.5-Coder-14B-Instruct-GGUF
File: qwen2.5-coder-14b-instruct-q4_k_m.gguf
```

---

#### **24-32GB RAM:**
→ **Qwen2.5-Coder-32B (Q4_K_M)** - 18GB ⭐⭐  
✅✅ Score: ~85/100 (**RECOMMENDED FOR PRODUCTION**)

**Download:**
```
https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF
File: qwen2.5-coder-32b-instruct-q4_k_m.gguf
```

---

#### **32-64GB RAM:**
→ **Qwen2.5-Coder-32B (Q5_K_M)** - 22GB ⭐⭐⭐  
✅✅✅ Score: ~87/100 (**HIGHLY RECOMMENDED**)

**Download:**
```
https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF
File: qwen2.5-coder-32b-instruct-q5_k_m.gguf
```

---

#### **64GB+ RAM:**
→ **Llama-3.3-70B (Q4_K_M)** - 40GB  
OR **SQLCoder-34B (Q6_K)** - 26GB  
✅✅✅ Score: ~82-88/100 (**EXCELLENT**)

---

#### **128GB+ RAM:**
→ **DeepSeek-V2.5-236B (IQ3_XS)** - 100GB 🚀  
✅✅✅✅ Score: ~95/100 (**ULTIMATE**)

---

## 📊 QUICK COMPARISON

| Model | RAM | Score | Speed | Best For |
|-------|-----|-------|-------|----------|
| **Qwen-7B** | 5GB | 45/100 | ⚡⚡⚡ | 🔴 Too Weak |
| **Qwen-14B** | 9GB | 72/100 | ⚡⚡ | ✅ Development |
| **Qwen-32B** | 18GB | 85/100 | ⚡ | ✅✅ **PRODUCTION** |
| **SQLCoder-34B** | 20GB | 83/100 | ⚡ | ✅✅ PostgreSQL |
| **Llama-70B** | 40GB | 82/100 | 🐌 | ✅ General Purpose |
| **DeepSeek-236B** | 100GB | 95/100 | 🐌🐌 | 🚀 Ultimate |

---

## 🎯 YOUR BEST CHOICE

Based on **qwen2.5-vl-7b** test results (45/100):

### **UPGRADE TO: Qwen2.5-Coder-32B (Q4_K_M)**

**Why?**
- ✅ **+40 points** improvement (45 → 85)
- ✅ **+44%** success rate (31% → 75%)
- ✅ Fixes MERGE, ROLLUP, SCD2 issues
- ✅ Runs on 24GB+ RAM (affordable upgrade)
- ✅ Fast enough for real-time use

**Expected Results:**
- Basic SQL: **95%** (vs 88%)
- Intermediate: **85%** (vs 50%)
- Advanced: **80%** (vs 28%)
- Expert: **65%** (vs 4%)

---

## 📥 INSTALLATION (3 Steps)

### 1️⃣ Download LM Studio
```
https://lmstudio.ai/
```

### 2️⃣ Download Model
In LM Studio → Search: **"Qwen2.5-Coder-32B"**  
Select: **Q4_K_M** (or Q5_K_M if 32GB+ RAM)  
Click: **Download**

### 3️⃣ Configure Extension
Update `settings.json`:
```json
{
  "dbiSurvivalKit.llm.model": "qwen2.5-coder-32b-instruct-q4_k_m"
}
```

---

## ⚙️ OPTIMAL SETTINGS

```json
{
  "dbiSurvivalKit.llm.endpoint": "http://127.0.0.1:1234/v1",
  "dbiSurvivalKit.llm.model": "qwen2.5-coder-32b-instruct-q4_k_m",
  "dbiSurvivalKit.llm.temperature": 0.2,
  "dbiSurvivalKit.llm.maxTokens": 2048,
  "dbiSurvivalKit.llm.cacheEnabled": true,
  "dbiSurvivalKit.llm.debugMode": false
}
```

**Key Settings:**
- **Temperature 0.2:** Low = precise SQL (vs creative)
- **MaxTokens 2048:** Enough for complex queries
- **Cache:** Faster repeated queries

---

## 🧪 QUICK TEST

After installation, test with:

```sql
-- Schema:
CREATE TABLE employees (id INT, name VARCHAR(100), dept_id INT);
CREATE TABLE departments (id INT, name VARCHAR(100));

-- Task: Join tables, show employee names with departments
```

**Expected Output (Qwen-32B):**
```sql
SELECT e.name AS employee_name, d.name AS department_name
FROM employees e
JOIN departments d ON e.dept_id = d.id;
```

**Bad Output (Qwen-7B):**
```sql
SELECT * FROM employees, departments WHERE employees.dept_id = departments.id;
-- ❌ Wrong: SELECT *, old-style JOIN
```

---

## 💡 PRO TIPS

1. **Start Model BEFORE using extension**  
   → LM Studio → Load Model → Start Server

2. **Use Q4_K_M for speed, Q5_K_M for quality**  
   → Q4_K_M = 85/100 (Fast)  
   → Q5_K_M = 87/100 (Better)

3. **Close other apps to free RAM**  
   → Chrome, Discord, etc. use lots of RAM

4. **Enable GPU Layers in LM Studio**  
   → Settings → GPU Offload → Max

5. **Test with ALL 10 test files**  
   → Run `test/TESTFILES-qwen2.5-coder-32b/` folder

---

## 🚨 TROUBLESHOOTING

### "Out of Memory" Error:
→ Use smaller model (32B → 14B)  
→ OR use smaller quantization (Q5_K_M → Q4_K_M)  
→ OR enable 10GB+ swap file

### "Model too slow":
→ Enable GPU layers in LM Studio  
→ OR use Q4_K_M instead of Q5_K_M  
→ OR upgrade GPU (RTX 3060+ recommended)

### "Wrong SQL syntax":
→ Lower temperature (0.5 → 0.2)  
→ Add "PostgreSQL ONLY" to prompt  
→ OR upgrade to 32B model

---

## 📞 NEED HELP?

- **Full Guide:** See `test/LM_STUDIO_MODEL_RECOMMENDATIONS.md`
- **Test Results:** See `test/TESTFILES-qwen-qwen2.5-vl-7b/TEST_RESULTS_SUMMARY.md`
- **LM Studio Docs:** https://lmstudio.ai/docs
- **Discord:** https://discord.gg/lmstudio

---

**🤓🤜🏻🤛🏻🤖 HAPPY TESTING!**

**Last Updated:** November 8, 2025
