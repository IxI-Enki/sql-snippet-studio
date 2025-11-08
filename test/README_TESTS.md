# 🧪 LLM Test Suite - DBI Survival Kit v1.6.0

## **📋 Overview**

This directory contains **10 comprehensive test files** designed to evaluate LLM performance across all DBI topics covered in **[DbiTheorie-003](https://github.com/IxI-Enki/DbiTheorie-003)**.

---

## **🎯 Test Coverage Matrix**

| Test # | File                                     | Domain          | Complexity      | Topics Covered                                 |
| ------ | ---------------------------------------- | --------------- | --------------- | ---------------------------------------------- |
| 1      | `llm_test_01_retail_basic.sql`           | Retail Sales    | 🟢 Beginner     | Star-Schema Basics, Simple JOINs, Aggregations |
| 2      | `llm_test_02_logistics_advanced.sql`     | Logistics       | 🟡 Intermediate | Advanced Star-Schema, MERGE, ETL, Hierarchies  |
| 3      | `llm_test_03_sales_analytics_window.sql` | Sales Analytics | 🟡 Intermediate | Window Functions (RANK, LAG), ROLLUP           |
| 4      | `llm_test_04_time_series_lag_lead.sql`   | Time Series     | 🟡 Intermediate | LAG/LEAD, Running Totals, Moving Averages      |
| 5      | `llm_test_05_product_catalog_merge.sql`  | Product Catalog | 🟢 Beginner     | SQL MERGE (UPSERT), ETL Patterns               |
| 6      | `llm_test_06_banking_multifact.sql`      | Banking         | 🔴 Advanced     | Multi-Fact Schema, Complex Analytics, ROLLUP   |
| 7      | `llm_test_07_ecommerce_snowflake.sql`    | E-Commerce      | 🔴 Advanced     | Snowflake Schema, Deep Hierarchies, NTILE      |
| 8      | `llm_test_08_healthcare_scd2.sql`        | Healthcare      | 🟡 Intermediate | SCD Type 2, Temporal Queries, MERGE            |
| 9      | `llm_test_09_education_all_window.sql`   | Education       | 🔴 Advanced     | ALL Window Functions, NTILE, ROLLUP            |
| 10     | `llm_test_10_mixed_expert.sql`           | Multi-Domain    | 🔴 EXPERT       | ALL Topics Combined, Real-World Scenarios      |

---

## **📚 Topic Coverage**

### ✅ Star-Schema & Dimensional Modeling

- Tests: 1, 2, 6, 7, 10
- **Focus:** Facts, Dimensions, Denormalization, Hierarchies

### ✅ Window Functions

- Tests: 3, 4, 6, 7, 9, 10
- **Focus:** RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD, NTILE, Running Totals, Moving Averages

### ✅ SQL MERGE (UPSERT)

- Tests: 2, 5, 8, 10
- **Focus:** INSERT, UPDATE, DELETE in one statement, ETL Patterns

### ✅ ROLLUP (Hierarchical Aggregations)

- Tests: 2, 3, 6, 7, 9, 10
- **Focus:** Subtotals, Grand Totals, GROUPING() function

### ✅ Complex JOINs & Aggregations

- Tests: 1, 2, 6, 7, 10
- **Focus:** Multiple JOINs, Subqueries, CTEs

### ✅ ETL Processes

- Tests: 2, 5, 8, 10
- **Focus:** Delta Loading, Staging Tables, Error Handling

### ✅ Advanced Topics

- **SCD Type 2:** Test 8 (Historization, Temporal Queries)
- **Multi-Fact:** Test 6, 10 (Multiple Fact Tables)
- **Snowflake Schema:** Test 7 (Normalized Dimensions)
- **Real-World Scenarios:** Test 10 (Business Questions)

---

## **🧪 How to Test**

### **Setup:**

1. Open any test file in Cursor/VS Code
2. Ensure DBI Survival Kit Extension v1.6.0+ is installed
3. Ensure LM Studio (or your LLM provider) is running
4. Configure extension settings: `Ctrl+,` → "DBI Survival Kit"

### **Testing Procedure:**

**For Each Task:**

1. Place cursor after the task comment:

   ```sql
   -- Aufgabe 1: Zeige alle Verkäufe mit Produktnamen
   
   [Place cursor here]
   ```

2. Press `Ctrl+Alt+Shift+Q` to trigger LLM query

3. Wait for response (watch status bar: "Querying LLM...")

4. Review generated SQL:
   - ✅ Syntax correct?
   - ✅ Logic correct?
   - ✅ Uses correct table/column names?
   - ✅ Appropriate complexity?

5. Check validation score in Output Channel:
   - `Ctrl+Shift+U` → Select "DBI Survival Kit - LLM"
   - Look for `[VALIDATOR] ✅ Validation complete: VALID (Score: XX)`

### **Expected Results:**

**Good Response (Score 85-100):**

- Clean SQL without `<think>` blocks
- Correct syntax
- Logical query structure
- Appropriate use of JOINs/Window Functions

**Acceptable Response (Score 70-84):**

- Minor warnings (e.g., mixed case keywords)
- Query works but could be optimized

**Problem Response (Score <70):**

- Syntax errors
- Unmatched parentheses
- Missing keywords
- Needs manual correction

---

## **📊 Model Testing Protocol**

### **Test All Models:**

```bash
# For each model in LM Studio:
1. Load model
2. Run through all 10 test files
3. Document results in TEST_RESULTS.md
```

### **Metrics to Track:**

| Metric                   | Description                                   |
| ------------------------ | --------------------------------------------- |
| **Success Rate**         | % of queries that are logically correct       |
| **Avg Validation Score** | Average score across all queries              |
| **Parser Effectiveness** | % of `<think>` blocks successfully removed    |
| **Response Time**        | Average time per query                        |
| **Failures**             | Number of queries that need manual correction |

---

## **🔬 Special Test Focus Areas**

### **Test 1 (Beginner):**

- Baseline: Even small models should pass
- If model fails here → unsuitable for production

### **Test 3 & 4 (Window Functions):**

- Critical syntax: `PARTITION BY`, `ORDER BY`, `ROWS BETWEEN`
- Common failure point for small models

### **Test 5 (MERGE):**

- Database-specific syntax (PostgreSQL vs Oracle)
- Model should use appropriate dialect

### **Test 6 (Multi-Fact):**

- Complex JOINs across multiple Fact tables
- Tests understanding of Star-Schema architecture

### **Test 7 (Snowflake):**

- Deep JOIN hierarchies (4+ levels)
- Tests ability to traverse normalized dimensions

### **Test 8 (SCD Type 2):**

- Temporal query logic
- valid_from, valid_to, is_current understanding

### **Test 9 (All Window Functions):**

- Comprehensive Window Function test
- If model passes → good Window Function support

### **Test 10 (Expert):**

- Ultimate test: Real-world business questions
- Only advanced models should attempt
- Tests: CTEs, Subqueries, Business Logic Interpretation

---

## **✅ Success Criteria**

**Model is PRODUCTION-READY if:**

- ✅ Tests 1-5: 90%+ success rate
- ✅ Tests 6-9: 75%+ success rate
- ✅ Test 10: 60%+ success rate
- ✅ Average Validation Score: 80+
- ✅ Parser removes 100% of `<think>` blocks
- ✅ Response time: <5 seconds per query

**Model is SUITABLE FOR TESTING if:**

- ✅ Tests 1-3: 80%+ success rate
- ✅ Tests 4-7: 60%+ success rate
- ✅ Parser handles reasoning blocks
- ✅ Response time: <10 seconds

**Model needs FINE-TUNING if:**

- ⚠️ Tests 1-3: <80% success rate
- ⚠️ Consistent syntax errors
- ⚠️ Cannot handle Window Functions
- ⚠️ Parser struggles with `<think>` blocks

---

## **📝 Testing Log Template**

```markdown
## Test Session: [Date]

**Model:** [Model Name & Version]
**LLM Provider:** [LM Studio / Ollama / etc.]
**Extension Version:** 1.6.0

### Results:

| Test # | Tasks Completed | Avg Score | Issues           | Notes                       |
| ------ | --------------- | --------- | ---------------- | --------------------------- |
| 1      | 8/8             | 95        | None             | Perfect                     |
| 2      | 8/8             | 88        | MERGE syntax     | Used PostgreSQL dialect     |
| 3      | 8/8             | 82        | ROLLUP order     | Fixed manually              |
| 4      | 12/12           | 78        | Window frames    | Some ROWS BETWEEN errors    |
| 5      | 8/8             | 90        | None             | Good ETL understanding      |
| 6      | 12/12           | 75        | Multi-Fact JOINs | Complex but correct         |
| 7      | 13/13           | 70        | Deep hierarchies | 2 queries needed correction |
| 8      | 13/13           | 80        | SCD Type 2       | Good temporal logic         |
| 9      | 21/21           | 68        | NTILE, LAG       | Some offset errors          |
| 10     | 18/18           | 65        | CTEs             | Very complex, acceptable    |

**Overall Success Rate:** 88% (130/148 queries)
**Average Validation Score:** 79/100
**Parser Effectiveness:** 100% (all `<think>` blocks removed)
**Recommendation:** ✅ PRODUCTION READY for Tests 1-7, needs review for 8-10
```

---

## **🚀 Next Steps**

After testing:

1. Document results in [`../docs/TEST_RESULTS_TEMPLATE.md`](../docs/TEST_RESULTS_TEMPLATE.md)
2. Compare models side-by-side
3. Identify best model for each test category
4. Report findings to extension development
5. Consider fine-tuning for weak areas

---

## **📄 Test Files Summary**

```file-tree
test/
├── llm_test_01_retail_basic.sql              8 tasks  🟢
├── llm_test_02_logistics_advanced.sql        8 tasks  🟡
├── llm_test_03_sales_analytics_window.sql    8 tasks  🟡
├── llm_test_04_time_series_lag_lead.sql     12 tasks  🟡
├── llm_test_05_product_catalog_merge.sql     8 tasks  🟢
├── llm_test_06_banking_multifact.sql        12 tasks  🔴
├── llm_test_07_ecommerce_snowflake.sql      13 tasks  🔴
├── llm_test_08_healthcare_scd2.sql          13 tasks  🟡
├── llm_test_09_education_all_window.sql     21 tasks  🔴
├── llm_test_10_mixed_expert.sql             18 tasks  🔴
└── README_TESTS.md                         This file

TOTAL: 121 Test Tasks across 10 scenarios
```

---

<!-- markdownlint-disable-next-line MD036 -->
**Happy Testing! 🤓🤜🏻🤛🏻🤖**
<!-- markdownlint-enable-next-line MD036 -->

**Version:** 1.0  
**Created:** 2025-11-08  
**For:** DBI Survival Kit v1.6.0+  
**Purpose:** Comprehensive LLM Testing for DBI Topics 2025/26
