# TEST 10 ANALYSIS: MIXED EXPERT - qwen3-coder-30b-a3b-instruct

**EXPERT-LEVEL ANALYSE** - Alle 18 Aufgaben

---

## SCORE: 72.2% (13/18)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 13 | 1, 2, 3, 4, 9, 10, 11, 12, 13, 14, 15, 16, 18 |
| ⚠️ | 1 | 8 |
| ❌ | 2 | 5, 6 |
| 🚫 | 2 | 7, 17 (BEIDE TIMEOUT!) |

---

## KRITISCHE FEHLER-ÜBERSICHT

### ✅ PERFEKT (13/18):
- **Star Schema** (Aufg. 1, 2) ✅
- **Top N per Group mit CTE** (Aufg. 3) ✅ 🎉
- **Window Functions** (Aufg. 4) ✅
- **ROLLUP** (Aufg. 9, 10) ✅
- **Multi-CTE** (Aufg. 11) ✅ 💪
- **Subqueries** (Aufg. 12) ✅
- **Multi-Fact** (Aufg. 13, 14, 15) ✅
- **Real-World** (Aufg. 16, 18) ✅

### ⚠️ TEILWEISE (1/18):
- **Aufg. 8:** UPDATE statt MERGE, aber Logik korrekt

### ❌ FALSCH (2/18):
- **Aufg. 5:** LAG in WHERE! (ALTER FEHLER - schon 4x!)
- **Aufg. 6:** LAG(SUM(...)) verschachtelt - Syntax komplex/fragwürdig

### 🚫 TIMEOUT (2/18):
- **Aufg. 7:** MERGE = TIMEOUT! (wie Test 5, 8!)
- **Aufg. 17:** Complex Query = TIMEOUT!

---

## DETAILLIERTE FEHLER

**Aufg. 1:** ✅ Complete Star Schema JOIN perfekt  
**Aufg. 2:** ✅ Profitabilität Berechnung perfekt  
**Aufg. 3:** ✅ **Top 5 per Category mit CTE + DENSE_RANK perfekt!** 🎉  
**Aufg. 4:** ✅ Percent of Total mit SUM(SUM(...)) OVER perfekt  
**Aufg. 5:** ❌ LAG in WHERE! Syntaktisch ungültig!  
**Aufg. 6:** ❌ LAG(SUM(...) OVER (...)) verschachtelt - sehr komplex, fragwürdig!  
**Aufg. 7:** 🚫 **MERGE = TIMEOUT!** (wie Test 5, 8!)  
**Aufg. 8:** ⚠️ UPDATE statt MERGE, aber Logik für "no sales in 6 months" korrekt  
**Aufg. 9:** ✅ ROLLUP + GROUPING() perfekt  
**Aufg. 10:** ✅ ROLLUP perfekt  
**Aufg. 11:** ✅ **Multi-CTE (3 CTEs) perfekt!** 💪  
**Aufg. 12:** ✅ Subqueries für Top Performers perfekt  
**Aufg. 13:** ✅ Multi-Fact + Sales Velocity perfekt  
**Aufg. 14:** ✅ Multi-Fact JOINs perfekt  
**Aufg. 15:** ✅ **Sales-to-Stock Ratio mit komplexen CASE WHEN perfekt!** 🔥  
**Aufg. 16:** ✅ **Real-World Query mit LAG + Window + ROLLUP perfekt!** 🚀  
**Aufg. 17:** 🚫 **TIMEOUT!** (RFM + Product Affinity zu komplex)  
**Aufg. 18:** ✅ Channel Efficiency + ROLLUP perfekt  

---

## HAUPTPROBLEME

1. **2x TIMEOUT!** (Aufg. 7, 17)
   - MERGE zu komplex
   - RFM Segmentation zu komplex
2. **LAG in WHERE** (Aufg. 5 - ALTER FEHLER!)
3. **Aufg. 6:** Verschachtelung fragwürdig

---

## POSITIV - **MEGA-LEISTUNG!** 🎉

1. **Aufg. 3: Top N per Group ENDLICH PERFEKT!** 🎉
2. **Aufg. 11: 3 CTEs perfekt verschachtelt!** 💪
3. **Aufg. 15: Komplexe CASE WHEN Logic perfekt!** 🔥
4. **Aufg. 16: Real-World Query mit ALLEM perfekt!** 🚀
5. **Multi-Fact Queries: EXZELLENT!** ✅

---

## FAZIT

**72.2% im EXPERT TEST ist HERVORRAGEND!** 🎉🔥💪

Trotz 2x TIMEOUT zeigt das Model **STARKE** Expert-Level Performance!

---
