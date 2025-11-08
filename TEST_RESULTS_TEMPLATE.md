# 📊 LLM Test Results - DBI Survival Kit v1.6.0

## **Test Session Information**

- **Date:** [YYYY-MM-DD]
- **Tester:** [Your Name]
- **Extension Version:** 1.6.0
- **LLM Provider:** [LM Studio / Ollama / Other]

---

## **Models Tested**

| Model Name | Version | Parameters | Context Length | Notes |
|------------|---------|------------|----------------|-------|
| qwen2.5-7b-instruct | latest | 7B | 32K | - |
| qwen2.5-vl-7b | latest | 7B | 32K | - |
| osmosis-mcp-4b | latest | 4B | 8K | Uses `<think>` blocks |
| llama3-8b | latest | 8B | 8K | - |
| codellama-7b | latest | 7B | 16K | - |

---

## **Test Results Summary**

| Model | Avg Score | Success Rate | Parser Effectiveness | Avg Response Time | Status |
|-------|-----------|--------------|---------------------|-------------------|--------|
| qwen2.5-7b-instruct | - | - | - | - | ⏳ Pending |
| qwen2.5-vl-7b | - | - | - | - | ⏳ Pending |
| osmosis-mcp-4b | - | - | - | - | ⏳ Pending |
| llama3-8b | - | - | - | - | ⏳ Pending |
| codellama-7b | - | - | - | - | ⏳ Pending |

---

## **Detailed Results**

### **Model: [Model Name]**

#### **Test 1: Retail Basic (🟢 Beginner)**
```
Tasks Completed: X/8
Average Validation Score: XX/100
Issues:
- [Issue 1]
- [Issue 2]

Notes:
- [Observation 1]
```

#### **Test 2: Logistics Advanced (🟡 Intermediate)**
```
Tasks Completed: X/8
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 3: Sales Analytics Window (🟡 Intermediate)**
```
Tasks Completed: X/8
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 4: Time Series LAG/LEAD (🟡 Intermediate)**
```
Tasks Completed: X/12
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 5: Product Catalog MERGE (🟢 Beginner)**
```
Tasks Completed: X/8
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 6: Banking Multi-Fact (🔴 Advanced)**
```
Tasks Completed: X/12
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 7: E-Commerce Snowflake (🔴 Advanced)**
```
Tasks Completed: X/13
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 8: Healthcare SCD2 (🟡 Intermediate)**
```
Tasks Completed: X/13
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 9: Education All Window (🔴 Advanced)**
```
Tasks Completed: X/21
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

#### **Test 10: Mixed Expert (🔴 EXPERT)**
```
Tasks Completed: X/18
Average Validation Score: XX/100
Issues:
- [Issue 1]

Notes:
- [Observation 1]
```

---

## **Parser Performance**

### **`<think>` Block Removal:**
- ✅ Successfully removed: XX/XX
- ❌ Failed to remove: XX/XX
- Notes: [Any patterns observed]

### **Markdown Code Block Extraction:**
- ✅ Successfully extracted: XX/XX
- ❌ Failed to extract: XX/XX

### **Response Cleaning:**
- ✅ Clean SQL generated: XX/XX
- ⚠️ Manual cleanup needed: XX/XX

---

## **Validator Performance**

### **Validation Accuracy:**
- ✅ Correctly identified valid SQL: XX/XX
- ✅ Correctly identified invalid SQL: XX/XX
- ⚠️ False positives: XX/XX
- ⚠️ False negatives: XX/XX

### **Most Common Warnings:**
1. [Warning 1] - XX occurrences
2. [Warning 2] - XX occurrences
3. [Warning 3] - XX occurrences

### **Most Common Errors:**
1. [Error 1] - XX occurrences
2. [Error 2] - XX occurrences
3. [Error 3] - XX occurrences

---

## **Observations & Insights**

### **Strengths:**
- [Strength 1]
- [Strength 2]
- [Strength 3]

### **Weaknesses:**
- [Weakness 1]
- [Weakness 2]
- [Weakness 3]

### **Surprising Findings:**
- [Finding 1]
- [Finding 2]

---

## **Model Recommendations**

### **Best for Beginners (Tests 1-2):**
- **Winner:** [Model Name]
- **Reason:** [Why]

### **Best for Window Functions (Tests 3-4, 9):**
- **Winner:** [Model Name]
- **Reason:** [Why]

### **Best for MERGE/ETL (Tests 2, 5, 8):**
- **Winner:** [Model Name]
- **Reason:** [Why]

### **Best for Advanced Queries (Tests 6-10):**
- **Winner:** [Model Name]
- **Reason:** [Why]

### **Best Overall:**
- **Winner:** [Model Name]
- **Average Score:** XX/100
- **Success Rate:** XX%
- **Reason:** [Why]

---

## **Issues & Bug Reports**

### **Extension Issues:**
1. [Issue 1]
   - **Severity:** High/Medium/Low
   - **Description:** [Details]
   - **Reproduction:** [Steps]

### **Parser Issues:**
1. [Issue 1]
   - **Model:** [Model Name]
   - **Description:** [Details]
   - **Example:** [SQL snippet]

### **Validator Issues:**
1. [Issue 1]
   - **Description:** [Details]
   - **Example:** [SQL snippet]

---

## **Feature Requests**

1. [Feature 1]
   - **Priority:** High/Medium/Low
   - **Description:** [Details]
   - **Use Case:** [Why needed]

---

## **Conclusion**

**Overall Assessment:**
[Your summary of the testing session]

**Recommended Model for DBI Tests:**
[Model Name] because [reasons]

**Next Steps:**
- [ ] [Action 1]
- [ ] [Action 2]
- [ ] [Action 3]

---

**Tested by:** [Your Name]  
**Date:** [YYYY-MM-DD]  
**Total Testing Time:** [X hours]
