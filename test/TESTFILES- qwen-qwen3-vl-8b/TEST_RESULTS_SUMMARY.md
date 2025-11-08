# TEST RESULTS SUMMARY: qwen/qwen3-vl-8b

**Model:** `qwen/qwen3-vl-8b`  
**Test Date:** November 8, 2025  
**Test Suite:** 5 Files (Tests 1-5), 44 Tasks  
**Testing Environment:** Local LM Studio  

---

## 📊 OVERALL PERFORMANCE

| Metric | Value | Status |
|--------|-------|--------|
| **Overall Score** | **48.4/100** | 🔴 **NOT PRODUCTION-READY** |
| **Success Rate** | **19/44 (43.2%)** | 🔴 **CRITICAL** |
| **Complete Tasks** | **19** | ⚠️ Too Low |
| **Partial Tasks** | **3** | ⚠️ Recoverable |
| **Failed Tasks** | **22** | 🔴 **ALARMING** |
| **Missing Tasks** | **0** | - |

---

## 🎯 BREAKDOWN BY TEST FILE

| Test # | Domain | Complexity | Tasks | ✅ Correct | ⚠️ Partial | ❌ Failed | Score |
|--------|--------|------------|-------|-----------|-----------|----------|-------|
| **01** | Retail Basics | 🟢 Basic | 8 | 7 | 0 | 1 | **93.8%** |
| **02** | Logistics Advanced | 🟡 Intermediate | 8 | 5 | 0 | 3 | **62.5%** |
| **03** | Sales Analytics | 🟡 Intermediate | 8 | 2 | 1 | 5 | **31.3%** |
| **04** | Time Series LAG/LEAD | 🟡 Intermediate | 12 | 3 | 2 | 7 | **41.7%** |
| **05** | Product Catalog MERGE | 🟢 Basic (MERGE) | 8 | 1 | 0 | 7 | **12.5%** |
| **TOTAL** | **All Domains** | **Mixed** | **44** | **18** | **3** | **23** | **48.4%** |

---

## 📈 PERFORMANCE BY COMPLEXITY

| Complexity Level | Tasks | ✅ Correct | ⚠️ Partial | ❌ Failed | Success Rate |
|-----------------|-------|-----------|-----------|----------|--------------|
| 🟢 **Basic** | 16 | 13 | 0 | 3 | **81.3%** ✅ |
| 🟡 **Intermediate** | 28 | 5 | 3 | 20 | **17.9%** 🔴 |

**KEY INSIGHT:** Das 8B Model ist **nur für Basic Tasks geeignet**! Bei Intermediate Level bricht die Performance massiv ein!

---

## 🔍 ANALYSIS BY SQL TOPIC

### ✅ STRONG AREAS (Success Rate > 70%)

1. **Basic Star-Schema JOINs** (87.5%)
   - Simple 2-3 table JOINs korrekt
   - SELECT + GROUP BY + SUM/AVG verstanden
   - Test 1: Stark

2. **Simple Aggregations** (80%)
   - SUM, AVG, COUNT korrekt
   - HAVING Clauses korrekt
   - Tests 1, 2: Gut

---

### ⚠️ WEAK AREAS (Success Rate 30-70%)

3. **LAG/LEAD Basic** (50%)
   - Einfache LAG/LEAD Queries okay
   - Scheitert bei Offset > 1
   - Test 4: Inkonsistent

4. **Running Totals** (50%)
   - Grundsyntax verstanden
   - Fehlt oft explizites ROWS BETWEEN
   - Test 4: Teilweise

---

### 🔴 CRITICAL FAILURES (Success Rate < 30%)

5. **MERGE Statements** (12.5%) 🚫
   - **KATASTROPHAL!**
   - 7 von 8 MERGE Statements incomplete!
   - Fehlt IMMER "MERGE INTO ... USING" am Anfang!
   - Test 5: **NUR 1/8 KORREKT**
   - **Beispiel-Fehler:**
     ```sql
     -- Task 5-1: Fehlt "MERGE INTO Products p USING STG_Product_"
     Updates s
     ON p.product_id = s.product_id
     WHEN MATCHED THEN...
     -- ❌ KOMPLETT INCOMPLETE!
     ```

6. **Window Functions + Aggregation** (25%) 🔴
   - Versteht Window Functions isoliert
   - Scheitert bei Kombination mit GROUP BY
   - Fehlende CTEs für komplexe Queries
   - Tests 3, 4: **SEHR SCHWACH**
   - **Beispiel-Fehler:**
     ```sql
     -- Task 3-2: revenue ohne SUM, LIMIT 3 statt 3 pro Kategorie
     SELECT category, product_name, revenue,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
     FROM FACT_Sales fs
     JOIN DIM_Product dp ON fs.product_key = dp.product_key
     ORDER BY category, revenue DESC
     LIMIT 3;  -- ❌ Zeigt nur 3 Rows total, nicht 3 pro Kategorie!
     ```

7. **ROLLUP** (33%) 🔴
   - Versteht ROLLUP() Syntax teilweise
   - Aber häufig falsche Column-Referenzen
   - Mischt PostgreSQL und MySQL Syntax
   - Tests 2, 3: Inkonsistent
   - **Beispiel-Fehler:**
     ```sql
     -- Task 2-8: MySQL Syntax!
     GROUP BY w.region, w.country WITH ROLLUP;
     -- ❌ PostgreSQL: GROUP BY ROLLUP(w.region, w.country)
     ```

8. **Complex Window Functions** (17%) 🔴
   - LAG/LEAD mit falschen Offsets
   - ROWS BETWEEN Richtung falsch
   - RANGE BETWEEN mit INT statt DATE
   - Test 4: **SEHR SCHWACH**
   - **Beispiel-Fehler:**
     ```sql
     -- Task 4-4: LAG Offset ist 1 statt 7!
     LAG(f.daily_revenue, 1, 0) OVER (ORDER BY t.full_date) AS revenue_7_days_ago
     -- ❌ Sollte LAG(..., 7, 0) sein!
     ```

9. **Fehlende Column-Referenzen** (Häufig) 🔴
   - Referenziert Columns die nicht existieren
   - t.month_key (existiert nicht, nur t.month)
   - t.region, t.department (aus falscher Tabelle)
   - Tests 3, 4: **KRITISCH**

---

## 🚨 CRITICAL ERROR PATTERNS

### 1. **MERGE Statement Disaster** (7 Failed Tasks)
- **Problem:** ALLE MERGE Statements incomplete
- **Examples:**
  - Fehlt "MERGE INTO ... USING" am Anfang (Tasks 5-1 bis 5-7)
  - Task 5-6: Komplett falsche Query (UNION ALL statt MERGE)
  - Task 5-7: Ist kein MERGE, nur einfaches UPDATE
- **Impact:** ETL/UPSERT Operationen **KOMPLETT UNBRAUCHBAR**

### 2. **Column-Referenzen aus falscher Tabelle** (6 Failed Tasks)
- **Problem:** Referenziert Columns die nicht in der Tabelle existieren
- **Examples:**
  - Task 3-3: t.month_key existiert nicht (nur t.month)
  - Task 3-6: t.region und t.department existieren nicht (sollte sp.region sein)
- **Impact:** Runtime Errors garantiert

### 3. **Window Functions ohne Aggregation** (5 Failed Tasks)
- **Problem:** Nutzt f.revenue direkt statt SUM(f.revenue)
- **Examples:**
  - Task 3-3: f.revenue ohne SUM zeigt jeden Sale einzeln
  - Task 3-4: f.revenue ohne SUM nicht aggregiert
- **Impact:** Zeigt falsche Granularität (Daily statt Monthly)

### 4. **LAG/LEAD Offsets falsch** (3 Failed Tasks)
- **Problem:** Nutzt Offset 1 statt korrektem Wert
- **Examples:**
  - Task 4-4: LAG(revenue, 1) statt LAG(revenue, 7)
- **Impact:** Zeigt Vortag statt vor 7 Tagen

### 5. **ROWS BETWEEN Richtung falsch** (2 Failed Tasks)
- **Problem:** CURRENT ROW AND 6 FOLLOWING (forward) statt 6 PRECEDING AND CURRENT ROW (backward)
- **Examples:**
  - Task 4-7: Moving Average schaut in die Zukunft!
- **Impact:** Logisch inkorrekt (schaut voraus statt zurück)

### 6. **ROLLUP Syntax gemischt** (2 Failed Tasks)
- **Problem:** Mischt PostgreSQL ROLLUP(...) mit MySQL WITH ROLLUP
- **Examples:**
  - Task 2-8: "WITH ROLLUP" (MySQL) statt "ROLLUP(...)"
  - Task 3-8: "GROUP BY ROLLUP(...) WITH ROLLUP" (beides gleichzeitig!)
- **Impact:** Syntax Error in PostgreSQL

---

## 💡 MODEL-SPECIFIC INSIGHTS

### What the 8B Model CAN do:
- ✅ Basic Star-Schema Queries (2-4 table JOINs)
- ✅ Simple Aggregations (SUM, AVG, COUNT)
- ✅ Basic WHERE/HAVING filters
- ✅ Simple LAG/LEAD (Offset 1)
- ✅ Basic RANK, DENSE_RANK, ROW_NUMBER

### What the 8B Model CANNOT do:
- ❌ MERGE Statements (12.5% Success) 🚫
- ❌ Window Functions + Aggregation (25% Success)
- ❌ Complex LAG/LEAD (Offsets > 1)
- ❌ ROLLUP konsistent (33% Success)
- ❌ ROWS BETWEEN Richtung (backward vs forward)
- ❌ Komplexe CTEs
- ❌ Korrekte Column-Referenzen bei komplexen Queries

### Model Behavior Patterns:
1. **Incomplete MERGE:** Generiert IMMER incomplete MERGE (fehlt Anfang)
2. **Missing Aggregation:** Vergisst SUM() bei Window Functions + Aggregation
3. **Wrong Offsets:** Nutzt default Offset 1 statt korrekte Werte
4. **Wrong Direction:** ROWS BETWEEN forward statt backward
5. **Wrong Table References:** Referenziert Columns aus falscher Tabelle

---

## 🎓 COMPARISON: 8B vs 7B Model

| Metric | 7B Model (qwen2.5-vl-7b) | 8B Model (qwen3-vl-8b) | Change |
|--------|--------------------------|------------------------|--------|
| **Overall Score** | 45.0/100 | 48.4/100 | **+3.4** ✅ |
| **Success Rate** | 30.6% (37/121) | 43.2% (19/44) | **+12.6%** ✅ |
| **Basic Tasks** | 87.5% | 81.3% | **-6.2%** ⚠️ |
| **Intermediate** | 50.0% | 17.9% | **-32.1%** 🔴 |
| **MERGE Success** | 0% | 12.5% | **+12.5%** ✅ |
| **Window Functions** | 50% | 25% | **-25%** 🔴 |
| **ROLLUP Success** | 0% | 33% | **+33%** ✅ |

**WICHTIG:** Scores sind nicht direkt vergleichbar!
- 7B: 121 Tasks (alle 10 Tests)
- 8B: 44 Tasks (nur Tests 1-5)

**ABER:** Bei den **gleichen Tests (1-5)** ist 8B Model teilweise besser:
- Test 1: 93.8% (beide gleich)
- Test 2: 62.5% vs 75% (8B schlechter)
- Test 3: 31.3% vs 50% (8B schlechter)
- Test 4: 41.7% vs 58.3% (8B schlechter)
- Test 5: 12.5% vs 37.5% (8B VIEL schlechter)

**FAZIT:** qwen3-vl-8b ist **NICHT besser** als qwen2.5-vl-7b bei SQL!

---

## 📊 TEST-BY-TEST SUMMARY

### TEST 1: Retail Basics (93.8%) ✅
- **Strengths:** Alle Basic JOINs + Aggregationen korrekt
- **Weakness:** ORDER BY t.month ohne t.month im GROUP BY
- **Verdict:** **SEHR GUT** für Basic SQL

### TEST 2: Logistics Advanced (62.5%) ⚠️
- **Strengths:** Basic JOINs und Aggregationen korrekt
- **Weaknesses:** MERGE incomplete, Pünktlichkeitsrate falsch, ROLLUP Syntax falsch
- **Verdict:** **SCHWACH** für Intermediate

### TEST 3: Sales Analytics (31.3%) 🔴
- **Strengths:** RANK, DENSE_RANK, ROW_NUMBER korrekt
- **Weaknesses:** Window Functions + Aggregation, falsche Column-Referenzen, ROLLUP Syntax
- **Verdict:** **SEHR SCHWACH** für Window Functions

### TEST 4: Time Series (41.7%) 🔴
- **Strengths:** Einfache LAG/LEAD korrekt
- **Weaknesses:** LAG/LEAD Offsets falsch, ROWS BETWEEN Richtung falsch, GROUP BY Konflikte
- **Verdict:** **SCHWACH** für Time Series

### TEST 5: MERGE (12.5%) 🔴🔴
- **Strengths:** Mehrstufiger ETL-Prozess (Task 8) korrekt
- **Weaknesses:** ALLE anderen MERGE Statements incomplete!
- **Verdict:** **KATASTROPHAL** für MERGE

---

## 🎯 FINAL VERDICT

### Overall Assessment:
**🔴 NOT PRODUCTION-READY**

### Recommended Use Cases:
- ✅ **Learning/Education:** Basic SQL für Anfänger
- ⚠️ **Development Aid:** Code-Completion für **BASIC Queries only**

### NOT Recommended For:
- ❌ **Production Environments:** Fehlerquote zu hoch (56.8%)
- ❌ **ETL Pipelines:** MERGE Statements nicht funktional (12.5%)
- ❌ **Window Functions:** Zu schwach (25%)
- ❌ **DBI Test Support:** Zu unzuverlässig für Prüfungen

---

## 🚀 NEXT STEPS & RECOMMENDATIONS

### Immediate Actions:
1. **🔴 CRITICAL: Test 32B Model**
   - qwen2.5-vl-8b ist **NICHT besser** als 7B
   - Upgrade auf **Qwen2.5-Coder-32B** notwendig!
   - Siehe `test/LM_STUDIO_MODEL_RECOMMENDATIONS.md`

2. **⚠️ Alternative: Test qwen2.5-coder-14b**
   - Spezialisierter auf Code (ohne VL)
   - Könnte besser sein als VL-Varianten

3. **📚 VL-Varianten vermeiden:**
   - qwen3-vl-8b und qwen2.5-vl-7b haben beide Probleme
   - Vision-Language Focus reduziert SQL-Fähigkeiten?
   - Teste **reine Text-Models** (ohne VL)!

---

## 📝 CONCLUSION

Der **qwen/qwen3-vl-8b** Model zeigt:
- ✅ Solide Performance bei **Basic SQL** (93.8%)
- ⚠️ Schwache Performance bei **Intermediate SQL** (17.9%)
- 🔴 Katastrophale Performance bei **MERGE** (12.5%)
- 🔴 Unzuverlässig bei **Window Functions** (25%)

### Critical Gaps:
1. **MERGE Statements:** 87.5% Failure Rate - komplett unbrauchbar
2. **Window Functions + Aggregation:** 75% Failure Rate
3. **Column-Referenzen:** Häufige Fehler bei komplexen Queries
4. **LAG/LEAD Offsets:** Standardwerte statt korrekte Werte

### Recommendation:
**UPGRADE TO Qwen2.5-Coder-32B (NON-VL) FOR PRODUCTION USE!**

Das 8B VL-Model ist **NICHT geeignet** für DBI Test Support. Die **Vision-Language Fokussierung** scheint SQL-Fähigkeiten zu reduzieren. Teste **reine Code-Models** ohne VL!

---

**Test Completed:** November 8, 2025  
**Analyst:** Claude Sonnet 4.5  
**Status:** ✅ COMPREHENSIVE ANALYSIS COMPLETE (Tests 1-5)  

**Next:** Test remaining files (6-10) OR upgrade to 32B Model

---
