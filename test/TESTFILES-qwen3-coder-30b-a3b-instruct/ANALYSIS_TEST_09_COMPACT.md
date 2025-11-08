# TEST 9 ANALYSIS: EDUCATION ALL WINDOW - qwen3-coder-30b-a3b-instruct

**ULTRA-KOMPAKTE ANALYSE** - Alle 21 Aufgaben

---

## SCORE: 76.2% (16/21)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 16 | 1, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15, 16, 18, 19, 20 |
| ⚠️ | 2 | 5, 13 |
| ❌ | 3 | 9, 17, 21 |

---

## KRITISCHE FEHLER-ÜBERSICHT

### ✅ PERFEKT (16/21):
- **RANK/DENSE_RANK/ROW_NUMBER** (Aufg. 1, 2, 3) ✅
- **NTILE** (Aufg. 4, 6) ✅
- **LAG/LEAD** (Aufg. 7, 8) ✅
- **Running Totals** (Aufg. 10, 11) ✅
- **Moving Averages** (Aufg. 12) ✅
- **FIRST_VALUE** (Aufg. 14, 15) ✅
- **ROLLUP** (Aufg. 16, 18) ✅
- **Subqueries** (Aufg. 19, 20) ✅

### ⚠️ TEILWEISE (2/21):
- **Aufg. 5:** LIMIT statt NTILE! Berechnet Top 10% korrekt, aber nicht mit NTILE(10)!
- **Aufg. 13:** Subquery Logik unklar - filtert nicht "letzte 5 Kurse pro Student"

### ❌ FALSCH (3/21):
- **Aufg. 9:** LAG in WHERE! Syntaktisch ungültig! (ALTER FEHLER!)
- **Aufg. 17:** d.department undefined! Fehlt JOIN zu DIM_Course!
- **Aufg. 21:** PERCENT_RANK falsch interpretiert - sollte % über Durchschnitt sein, nicht Ranking

---

## DETAILLIERTE FEHLER

**Aufg. 1:** ✅ Alle 3 Rankings perfekt  
**Aufg. 2:** ✅ DENSE_RANK mit PARTITION BY major perfekt  
**Aufg. 3:** ✅ ROW_NUMBER + Subquery + WHERE row_num <= 3 perfekt!  
**Aufg. 4:** ✅ NTILE(4) perfekt  
**Aufg. 5:** ⚠️ Verwendet LIMIT statt NTILE(10) + Filter! Konzeptuell ok, aber nicht wie verlangt!  
**Aufg. 6:** ✅ NTILE(5) mit PARTITION BY course perfekt  
**Aufg. 7:** ✅ LAG mit PARTITION BY student perfekt  
**Aufg. 8:** ✅ LAG(AVG(...)) mit GPA-Berechnung perfekt  
**Aufg. 9:** ❌ LAG in WHERE! Syntaktisch ungültig!  
**Aufg. 10:** ✅ Running Total Credits perfekt  
**Aufg. 11:** ✅ Running Average perfekt  
**Aufg. 12:** ✅ 3-Semester Moving Average perfekt  
**Aufg. 13:** ⚠️ Subquery filtert nicht "letzte 5 Kurse PRO STUDENT"  
**Aufg. 14:** ✅ FIRST_VALUE perfekt  
**Aufg. 15:** ✅ FIRST_VALUE für MAX/MIN - clever! (statt MAX/MIN Window Functions)  
**Aufg. 16:** ✅ ROLLUP perfekt  
**Aufg. 17:** ❌ d.department undefined! Fehlt JOIN!  
**Aufg. 18:** ✅ ROLLUP + GROUPING() perfekt  
**Aufg. 19:** ✅ Subquery korrekt  
**Aufg. 20:** ✅ STDDEV mit HAVING perfekt  
**Aufg. 21:** ❌ PERCENT_RANK Interpretation falsch - berechnet Ranking statt % über Durchschnitt  

---

## HAUPTPROBLEME

1. **Aufg. 9: LAG in WHERE** (ALTER FEHLER - schon mehrfach!)
2. **Aufg. 17: Fehlender JOIN** zu DIM_Course
3. **Aufg. 21: PERCENT_RANK falsch interpretiert**

---

## POSITIV

- **Top 3 per Group (Aufg. 3): PERFEKT!** 🎉 (endlich!)
- **LAG(AVG(...)): PERFEKT!** (komplexe Verschachtelung)
- **FIRST_VALUE für MAX/MIN: CLEVER!** 💡

---

## FAZIT

**76.2% ist STARK!** Window Functions exzellent! Nur 3 echte Fehler!

---
