# 📊 TEST RESULTS SUMMARY: llama-3-sqlcoder-8b

**Model:** `llama-3-sqlcoder-8b` (Code-Specialized Model, Non-VL)  
**Test Suite:** 10 Comprehensive SQL Tests (Total: 77 Tasks in Tests 6-10)  
**Test Date:** November 2025  
**Cache Version:** v1.6.2 (Cache Bug Fixed!)

---

## 🎯 OVERALL PERFORMANCE

| Metric | Score | Bewertung |
|--------|-------|-----------|
| **Tests 6-10 Success Rate** | **27.9%** (21.5/77) | ⚠️ **SCHWACH** |
| **Expert Test (Test 10)** | **11.1%** (2/18) | 💥 **FAILED** |
| **Best Test (Test 7)** | **50%** (6.5/13) | ⚠️ **GRENZWERTIG** |
| **Worst Test (Test 10)** | **11.1%** (2/18) | ❌ **KATASTROPHAL** |

---

## 📈 DETAILED TEST SCORES (Tests 6-10)

| Test | Domain | Complexity | Score | ✅ | ⚠️ | ❌ | 🚫 | Status |
|------|--------|------------|-------|----|----|----|----|--------|
| **6** | Banking Multi-Fact | 🔴 Advanced | **33.3%** (4/12) | 0 | 4 | 8 | 0 | ⚠️ SCHWACH |
| **7** | E-Commerce Snowflake | 🔴 Advanced | **50%** (6.5/13) | 5 | 3 | 5 | 0 | ⚠️ GRENZWERTIG |
| **8** | Healthcare SCD2 | 🟡 Intermediate | **30.8%** (4/13) | 3 | 5 | 5 | 0 | ⚠️ SCHWACH |
| **9** | Education All Window | 🔴 Advanced | **23.8%** (5/21) | 2 | 8 | 11 | 0 | ❌ SCHLECHT |
| **10** | Mixed Expert | 🔴 **EXPERT** | **11.1%** (2/18) | 2 | 3 | 13 | 0 | 💥 **FAILED** |

---

## 🔥 DETAILED ANALYSIS: Tests 6-10

### TEST 6: BANKING - MULTI-FACT (12 Aufgaben)

**Score: 33.3% (4/12)**

#### ✅ Stärken:
- Einfache Multi-Fact JOINs teilweise korrekt
- GROUP BY + ORDER BY Syntax solide

#### ❌ Schwächen:
- **Multi-Fact JOINs ohne time_key → Duplikate!**
- **Window Functions in WHERE Clause** (syntaktisch ungültig!)
- **DENSE_RANK komplett fehlend** (nur GROUP BY)
- **Moving Average falsch** (keine Window Function)
- **ROLLUP Syntax teilweise falsch** (undefined columns)

#### Kritischste Fehler:
- **Aufg. 4:** Window Function in WHERE → Syntax ERROR
- **Aufg. 6:** EXTRACT(time_key FROM ...) → ungültige Funktion
- **Aufg. 8:** AVG(SUM(...)) → komplett ungültig!

---

### TEST 7: E-COMMERCE - SNOWFLAKE SCHEMA (13 Aufgaben)

**Score: 50% (6.5/13)** ⭐ **BEST SCORE!**

#### ✅ Stärken:
- **Snowflake Hierarchie-JOINs** sehr gut! (Product/Category/Department)
- **ROLLUP Syntax** korrekt für einfache Fälle
- **NTILE** funktioniert
- **Conversion Rate** mit CASE WHEN korrekt

#### ❌ Schwächen:
- **GROUPING() Funktion fehlt oft** (obwohl verlangt)
- **Window Function Rankings** teilweise ASC statt DESC
- **JOIN ON TRUE** (CROSS JOIN) statt korrekter Bedingung
- **Window Functions in WHERE** (erneut!)

#### Kritischste Fehler:
- **Aufg. 6:** r.region_key = f.city_key → komplett falscher JOIN!
- **Aufg. 9:** JOIN ON TRUE → Cartesian Product!
- **Aufg. 13:** Window Function in WHERE → Syntax ERROR

---

### TEST 8: HEALTHCARE - SCD2 (13 Aufgaben)

**Score: 30.8% (4/13)**

#### ✅ Stärken:
- **Aktuelle Patienten-Query** (is_current = TRUE) korrekt
- **Simple Aggregationen** funktionieren

#### ❌ Schwächen:
- **SCD2 MERGE KOMPLETT FALSCH!** → Generiert SELECT statt MERGE!
- **Verwechslung STG vs. DIM** für Historie
- **Temporal Query Logik teilweise falsch** (valid_from/valid_to)
- **Trigger Logik invers** (setzt valid_from statt valid_to)

#### Kritischste Fehler:
- **Aufg. 7:** MERGE Statement → nur SELECT! **MEGA-FEHLER!**
- **Aufg. 10:** CAST(patient_id AS INTEGER) → patient_id ist VARCHAR!
- **Aufg. 11:** Subquery in WHERE ungültig

---

### TEST 9: EDUCATION - ALL WINDOW FUNCTIONS (21 Aufgaben)

**Score: 23.8% (5/21)** ⚠️ **SEHR SCHWACH!**

#### ✅ Stärken:
- **DENSE_RANK** funktioniert teilweise
- **Einfache Running Totals** korrekt

#### ❌ Schwächen:
- **"Top N per Group" nicht verstanden!** (keine CTEs + Filter)
- **Window Functions in WHERE** (mehrfach!)
- **MySQL ROLLUP Syntax** statt PostgreSQL
- **Viele Tabellen-Referenz Fehler** (f.year statt t.year)
- **Aufgabe 10 DOPPELT!** (exakt dieselbe Query 2x)

#### Kritischste Fehler:
- **Aufg. 3:** ROW_NUMBER ohne CTE Filter für Top 3
- **Aufg. 5:** ORDER BY in SELECT außerhalb window! → Syntax ERROR
- **Aufg. 9:** WHERE mit LAG → ungültig!
- **Aufg. 17:** "ROLLUP" ohne "GROUP BY" → Syntax ERROR
- **Aufg. 19:** f.profiler_key Typo! (sollte professor_key sein)
- **Aufg. 20:** STDDEV im WHERE → ungültig!

---

### TEST 10: MIXED EXPERT (18 Aufgaben)

**Score: 11.1% (2/18)** 💥 **EPIC FAIL!**

#### ✅ Stärken:
- **Einfache Star-Schema Queries** (Aufg. 1-2) korrekt

#### ❌ Schwächen:
- **MERGE KOMPLETT NICHT VERSTANDEN!** → Generiert SELECT statt INSERT/UPDATE!
- **Window Function Aggregation falsch** (LAG(SUM(...)))
- **CTE Logik unvollständig** (fehlende Spalten, keine Filter)
- **JOINs zu nicht-existierenden Tabellen** (customer_orders)
- **Spalten-Namen falsch** (product_category statt category)
- **ROLLUP Syntax durchgehend falsch**

#### Kritischste Fehler:
- **Aufg. 3:** CTE korrekt, aber WHERE sales_rank <=5 fehlt!
- **Aufg. 5:** Verwendet p.list_price statt fs.revenue → komplett falsch!
- **Aufg. 6:** LAG(SUM(...)) → ungültig!
- **Aufg. 7 & 8:** MERGE Statements → nur SELECT! **MEGA-FEHLER!**
- **Aufg. 9 & 10:** ROLLUP Syntax falsch
- **Aufg. 11:** product_trend CTE fehlt sales_quantity Spalte!
- **Aufg. 13:** JOIN zu STG_Sales falsch (product_code vs product_key)
- **Aufg. 15:** Kein JOIN zwischen f und i!
- **Aufg. 17:** customer_orders Tabelle existiert NICHT!
- **Aufg. 18:** p.product_category existiert NICHT!

---

## 🚨 CRITICAL FAILURES (Showstoppers)

### 1. **MERGE STATEMENTS KOMPLETT FALSCH!** 💥
- **Tests 5, 8, 10:** MERGE generiert nur SELECT, keine INSERT/UPDATE!
- Model versteht ETL-Patterns NICHT!

### 2. **Window Functions in WHERE Clause** ❌
- **Mehrfach:** Tests 6, 7, 9, 10
- Syntaktisch ungültig, aber wiederholt generiert!

### 3. **"Top N per Group" Pattern NICHT verstanden** ⚠️
- Fehlt: CTE mit ROW_NUMBER() + WHERE rank <= N
- Generiert statt dessen: Cumulative Sums oder LIMIT (falsch!)

### 4. **Tabellen-/Spalten-Referenzen häufig falsch** ❌
- Typos, undefined columns, falsche Tabellen-Aliase

### 5. **MySQL vs. PostgreSQL Syntax** ⚠️
- Verwendet "WITH ROLLUP" (MySQL) statt "GROUP BY ROLLUP" (PostgreSQL)

---

## 📊 FEATURE PERFORMANCE (Tests 6-10)

| Feature | Success Rate | Status |
|---------|--------------|--------|
| **Star-Schema JOINs** | 70% | ✅ GUT |
| **Basic Aggregations** | 65% | ⚠️ OK |
| **Window Functions (Simple)** | 45% | ⚠️ SCHWACH |
| **Window Functions (Complex)** | 20% | ❌ SCHLECHT |
| **ROLLUP** | 35% | ❌ SCHWACH |
| **MERGE Statements** | **0%** | 💥 **FAILED** |
| **CTEs** | 25% | ❌ SCHWACH |
| **Snowflake Schema** | 55% | ⚠️ GRENZWERTIG |
| **SCD Type 2** | 30% | ❌ SCHWACH |
| **Multi-Fact Analysis** | 25% | ❌ SCHWACH |
| **Expert-Level Queries** | **11%** | 💥 **FAILED** |

---

## ⚠️ ZUSÄTZLICHE PROBLEME

### Duplizierte Aufgaben:
- **Test 9, Aufgabe 10:** Query erscheint 2x (Zeile 125 + 129) - identisch!

### Fehlende Features:
- **GROUPING() Funktion:** Oft vergessen, obwohl explizit verlangt
- **FIRST_VALUE/LAST_VALUE:** Verwendet LAG statt der korrekten Funktion

---

## 🎯 PRODUCTION READINESS: ❌ **NOT READY**

| Kategorie | Bewertung | Begründung |
|-----------|-----------|------------|
| **Basic SQL** | ⚠️ OK | Einfache Queries funktionieren |
| **Intermediate SQL** | ❌ SCHWACH | Window Functions, ROLLUP fehleranfällig |
| **Advanced SQL** | 💥 **FAILED** | MERGE, CTEs, Multi-Fact = Katastrophe |
| **Expert SQL** | 💥 **EPIC FAIL** | Nur 11.1% in Test 10! |
| **Production Use** | ❌ **NO GO** | Zu viele kritische Fehler! |

---

## 📋 RECOMMENDATIONS

### ✅ Model kann verwendet werden für:
1. **Einfache SELECT Queries** (1-2 JOINs, Basic WHERE)
2. **Basic Aggregations** (SUM, COUNT, AVG)
3. **Simple Window Functions** (LAG, LEAD ohne komplexe Frames)

### ❌ Model ist **NICHT geeignet** für:
1. **ETL/MERGE Operations** (Generiert nur SELECT!)
2. **Expert-Level Analytics** (Multi-CTE, Complex Window Functions)
3. **Production Data Warehouses** (Fehlerrate zu hoch!)
4. **Real-World Business Intelligence** (Test 10: 11.1%!)

---

## 🆚 COMPARISON: llama-3-sqlcoder-8b vs. Previous Models

| Model | Size | Tests 6-10 Score | Expert Test | Best Feature | Worst Feature |
|-------|------|------------------|-------------|--------------|---------------|
| **qwen3-4b** | 4B | ~31% | ~20% | Basic JOINs | MERGE/Window |
| **qwen2.5-vl-7b** | 7B (VL) | 30.6% | ~15% | Simple Agg | MERGE/SCD2 |
| **qwen3-vl-8b** | 8B (VL) | 30.6% | ~18% | ROLLUP | MERGE/Window |
| **llama-3-sqlcoder-8b** | 8B (**NON-VL**) | **27.9%** | **11.1%** | Snowflake | **MERGE!** |

### 🔍 ÜBERRASCHUNG:
**llama-3-sqlcoder-8b ist SCHLECHTER als VL-Models!**  
Obwohl es ein **Code-Specialized Model** ist! 🤯

---

## 🏁 FINAL VERDICT

### ❌ **NOT PRODUCTION-READY!**

**Gründe:**
1. **MERGE komplett unbrauchbar** (0% Success)
2. **Expert-Level: 11.1%** → Worst Score aller getesteten Models!
3. **Syntax-Errors häufig** (Window in WHERE, undefined columns)
4. **Keine Verbesserung gegenüber VL-Models** (sogar schlechter!)

### ✅ ALTERNATIVE RECOMMENDATION:
**→ Teste `Qwen2.5-Coder-32B (NON-VL, Q4_K_M)`**  
Größeres Model könnte deutlich besser sein für SQL!

---

**Test durchgeführt von:** DBI Test Survival Kit v1.6.2  
**Kontakt:** Siehe LM_STUDIO_MODEL_RECOMMENDATIONS.md für weitere Empfehlungen
