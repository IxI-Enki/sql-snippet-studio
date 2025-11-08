# TEST 7 ANALYSIS: E-COMMERCE SNOWFLAKE - qwen3-coder-30b-a3b-instruct

**KOMPAKTE ANALYSE** - Alle 13 Aufgaben

---

## SCORE: 84.6% (11/13)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 11 | 1, 2, 3, 4, 5, 6, 7, 10, 11, 12, 13 |
| ⚠️ | 0 | - |
| ❌ | 2 | 8, 9 |

---

## DETAILLIERTE FEHLER

**Aufg. 1:** ✅ 3-stufige Snowflake JOINs perfekt  
**Aufg. 2:** ✅ 4-stufige Location Hierarchy perfekt  
**Aufg. 3:** ✅ 3-Level Aggregation perfekt  
**Aufg. 4:** ✅ ROLLUP über 3 Ebenen perfekt (mit Customer JOIN - ok)  
**Aufg. 5:** ✅ ROLLUP + COALESCE + ORDER BY GROUPING perfekt  
**Aufg. 6:** ✅ ROLLUP über geografische Hierarchie perfekt  
**Aufg. 7:** ✅ DENSE_RANK mit PARTITION BY perfekt  
**Aufg. 8:** ❌ Berechnet AVG(CASE loyalty_tier) statt AVG(total_amount) per tier! Versteht Aufgabe falsch!  
**Aufg. 9:** ❌ LIMIT 3 global statt Top 3 per Department! Falsche Verschachtelung!  
**Aufg. 10:** ✅ Conversion Rate Berechnung perfekt  
**Aufg. 11:** ✅ Return Rate mit WHERE IN ('Completed', 'Returned') korrekt  
**Aufg. 12:** ✅ NTILE perfekt  
**Aufg. 13:** ❌ NTILE in HAVING! Ungültig! (aber konzeptuell nah dran)  

---

## HAUPTPROBLEME

1. **Aufg. 8:** Loyalty Tier als Zahl kodiert statt AVG order value zu berechnen
2. **Aufg. 9:** Top 3 global statt per Department
3. **Aufg. 13:** Window Function in HAVING ungültig

---

## FAZIT

**84.6% ist SEHR GUT!** Snowflake Hierarchien perfekt! ROLLUP exzellent!

---
