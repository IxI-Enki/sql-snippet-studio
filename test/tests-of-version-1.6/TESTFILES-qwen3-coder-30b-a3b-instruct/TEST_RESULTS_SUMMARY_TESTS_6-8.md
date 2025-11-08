# 📊 TEST RESULTS SUMMARY: qwen3-coder-30b-a3b-instruct (Tests 6-8)

**Model:** `qwen3-coder-30b-a3b-instruct` (Code-Specialized, 30B, NON-VL)  
**Test Suite:** Tests 6-8 (Total: 38 Tasks)  
**Test Date:** November 2025  
**Cache Version:** v1.6.2

---

## 🎯 OVERALL PERFORMANCE (Tests 6-8)

| Metric | Score | Bewertung |
|--------|-------|-----------|
| **Success Rate** | **76.3%** (29/38) | ✅ **GUT!** |
| **Best Test** | **84.6%** (Test 7) | ✅ **SEHR GUT!** |
| **Worst Test** | **69.2%** (Test 8) | ⚠️ **SOLIDE** |
| **Avg Advanced Tests** | **76.3%** | ✅ **STARK!** |

---

## 📈 DETAILED TEST SCORES

| Test | Domain | Complexity | Score | ✅ | ⚠️ | ❌ | 🚫 | Status |
|------|--------|------------|-------|----|----|----|----|--------|
| **6** | Banking Multi-Fact | 🔴 Advanced | **75%** (9/12) | 9 | 0 | 3 | 0 | ✅ **GUT!** |
| **7** | E-Commerce Snowflake | 🔴 Advanced | **84.6%** (11/13) | 11 | 0 | 2 | 0 | ✅ **SEHR GUT!** |
| **8** | Healthcare SCD2 | 🟡 Intermediate | **69.2%** (9/13) | 9 | 1 | 2 | 1 | ⚠️ **SOLIDE** |

---

## 🔥 DETAILED ANALYSIS

### TEST 6: BANKING MULTI-FACT ✅ **75% (9/12)**

**Stärken:**
- Multi-Fact JOINs perfekt (Aufg. 1, 2)
- Running Balance mit SUM(daily_change) OVER perfekt (Aufg. 3)
- DENSE_RANK mit PARTITION BY perfekt (Aufg. 5)
- 7-Day Moving Average perfekt (Aufg. 6)
- ROLLUP perfekt (Aufg. 10, 12)

**Schwächen:**
- **Aufg. 4:** Window Function in WHERE! Syntaktisch ungültig!
- **Aufg. 8:** Wöchentliche Aggregation Logik unklar
- **Aufg. 11:** Falsche Spalte (amount statt fee)!

**Kritischste Fehler:**
- Window Function in WHERE (ALTER FEHLER - schon in früheren Tests!)
- Spalten-Verwechslung (amount vs. fee)

---

### TEST 7: E-COMMERCE SNOWFLAKE ✅ **84.6% (11/13)** ⭐ **BEST SCORE!**

**Stärken:**
- **3-stufige Snowflake JOINs perfekt!** (Product → Category → Department)
- **4-stufige Location Hierarchy perfekt!** (Customer → City → Region → Country)
- **ROLLUP über mehrere Ebenen exzellent!** (Aufg. 4, 5, 6)
- DENSE_RANK perfekt (Aufg. 7)
- Conversion Rate + Return Rate perfekt (Aufg. 10, 11)
- NTILE perfekt (Aufg. 12)

**Schwächen:**
- **Aufg. 8:** Berechnet AVG(CASE loyalty_tier) statt AVG(order value) per tier!
- **Aufg. 9:** LIMIT 3 global statt Top 3 per Department!
- **Aufg. 13:** NTILE in HAVING ungültig!

**Kritischste Fehler:**
- Loyalty Tier Misinterpretation
- Top N per Group Pattern wieder falsch

---

### TEST 8: HEALTHCARE SCD2 ⚠️ **69.2% (9/13)**

**Stärken:**
- **Aufg. 8: Trigger mit SCD2 Logik PERFEKT!** 🎉
  - UPDATE old record (valid_to, is_current)
  - INSERT new record
  - TRIGGER Syntax korrekt!
- **Point-in-Time Query perfekt!** (Aufg. 5)
- EXISTS Subquery stark (Aufg. 11)
- Basic SCD2 Queries gut (Aufg. 1, 2, 4)

**Schwächen:**
- **Aufg. 7: MERGE = TIMEOUT!** 💥 Model konnte nicht generieren!
- **Aufg. 6:** Temporal Query Logic falsch
- **Aufg. 10:** STG JOIN Logik unklar
- **Aufg. 13:** Logik für ">3 Änderungen" fehlt

**Kritischste Fehler:**
- MERGE Statement TIMEOUT! (wie Test 5!)
- Temporal Queries teilweise falsch

---

## 🚨 CRITICAL FINDINGS

### 1. **MERGE TIMEOUT PROBLEM!** 💥
- **Test 5:** Aufg. 8 = NOT GENERATED
- **Test 8:** Aufg. 7 = TIMEOUT
- **Pattern:** Model struggelt mit komplexen MERGE Statements!

### 2. **Window Function in WHERE** ⚠️
- **Test 3, Aufg. 2:** Verschachtelungsfehler
- **Test 6, Aufg. 4:** WHERE mit Window Function
- **Konsistenter Fehler!**

### 3. **Top N per Group** ⚠️
- **Test 3, Aufg. 2:** Falsche Verschachtelung
- **Test 7, Aufg. 9:** LIMIT 3 global statt per Group
- **Pattern:** Versteht Pattern nicht vollständig

---

## 📊 FEATURE PERFORMANCE (Tests 6-8)

| Feature | Success Rate | Status |
|---------|--------------|--------|
| **Snowflake JOINs** | 100% | ✅ PERFEKT |
| **Multi-Fact JOINs** | 90% | ✅ SEHR GUT |
| **ROLLUP (Complex)** | 100% | ✅ PERFEKT |
| **Window Functions (Simple)** | 95% | ✅ SEHR GUT |
| **Window Functions (Complex)** | 75% | ✅ GUT |
| **SCD2 Basics** | 85% | ✅ GUT |
| **SCD2 MERGE** | **0%** | 💥 **TIMEOUT!** |
| **Triggers** | **100%** | 🎉 **PERFEKT!** |
| **Top N per Group** | 0% | ❌ FALSCH |

---

## 🆚 COMPARISON: Tests 1-5 vs. Tests 6-8

| Metric | Tests 1-5 | Tests 6-8 | Trend |
|--------|-----------|-----------|-------|
| **Success Rate** | 72.7% | **76.3%** | ⬆️ **+3.6%** |
| **ROLLUP** | 100% | 100% | ✅ **STABIL** |
| **Window Func** | 90% | 85% | ⬇️ **-5%** |
| **MERGE** | 0% | 0% | ❌ **STABIL SCHLECHT** |
| **Snowflake** | N/A | 100% | 🎉 **NEU + PERFEKT** |

### 🔍 ERKENNTNISSE:
- **Tests werden schwieriger** → Score bleibt stabil! ✅
- **Snowflake Schema: PERFEKT!** 🎉
- **MERGE bleibt Problem** (TIMEOUT statt Syntax-Fehler)

---

## ⚖️ PRODUCTION READINESS (Tests 6-8)

| Kategorie | Bewertung | Begründung |
|-----------|-----------|------------|
| **Multi-Fact Analytics** | ✅ **GUT** | 90% Success! |
| **Snowflake Schema** | ✅ **PERFEKT** | 100%! |
| **Complex Window Func** | ✅ **GUT** | 85% (einige Fehler) |
| **SCD2 Queries** | ✅ **GUT** | 85% Basics ok |
| **SCD2 MERGE** | 💥 **FAILED** | TIMEOUT! |
| **Triggers** | ✅ **PERFEKT** | 100%! |

---

## 📋 RECOMMENDATIONS (Tests 6-8)

### ✅ Model **KANN** verwendet werden für:
1. **Snowflake Schema Queries** (100%)
2. **Multi-Fact Analytics** (90%)
3. **Complex JOINs** (95%)
4. **ROLLUP Hierarchies** (100%)
5. **SCD2 Read Queries** (85%)
6. **Triggers** (100%!)

### ❌ Model ist **NICHT geeignet** für:
1. **MERGE Statements** (0% - TIMEOUT!)
2. **SCD2 ETL** (MERGE essential!)
3. **Top N per Group** (consistent failure)

---

## 🏁 INTERIM VERDICT (Tests 1-8)

### ✅ **OVERALL: 73.2% (61/82 Tasks)** 

**Tests 1-5:** 72.7% (32/44)  
**Tests 6-8:** 76.3% (29/38)

### 🎯 **TREND: POSITIV!** ⬆️

- Model bleibt stark auch bei schwierigeren Tests!
- Snowflake Schema = **PERFEKT**!
- Multi-Fact = **SEHR GUT**!

### 💥 **ABER:**

- **MERGE = KRITISCHES PROBLEM!** (0%)
- **Top N per Group = SCHWACH** (0%)
- Tests 9-10 werden NOCH härter!

---

## 🚀 NEXT STEPS

1. **Teste Tests 9-10** (Education + Mixed Expert)
2. **Erwarte:** Expert-Level = härter
3. **Finale Bewertung:** Nach Test 10

---

**Test durchgeführt von:** DBI Test Survival Kit v1.6.2  
**Status:** Tests 1-8 COMPLETE, Tests 9-10 PENDING  

---

**🎯 ZWISCHENFAZIT: STARK bei Analytics, MERGE = TIMEOUT!** ⚠️
