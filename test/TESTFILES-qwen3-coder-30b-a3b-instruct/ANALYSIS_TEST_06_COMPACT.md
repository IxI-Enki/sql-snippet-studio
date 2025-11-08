# TEST 6 ANALYSIS: BANKING MULTI-FACT - qwen3-coder-30b-a3b-instruct

**KOMPAKTE ANALYSE** - Alle 12 Aufgaben

---

## SCORE: 75% (9/12)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 9 | 1, 2, 3, 5, 6, 7, 9, 10, 12 |
| ⚠️ | 0 | - |
| ❌ | 3 | 4, 8, 11 |

---

## DETAILLIERTE FEHLER

**Aufg. 1:** ✅ Multi-Fact JOIN + Aggregation korrekt (MAX für current balance)  
**Aufg. 2:** ✅ Multi-Fact JOIN korrekt  
**Aufg. 3:** ✅ Running Balance mit SUM(daily_change) OVER perfekt  
**Aufg. 4:** ❌ **Window Function in WHERE!** Syntaktisch ungültig!  
**Aufg. 5:** ✅ DENSE_RANK mit PARTITION BY perfekt  
**Aufg. 6:** ✅ 7-Day Moving Average mit ROWS BETWEEN 6 PRECEDING perfekt  
**Aufg. 7:** ✅ GROUP BY + HAVING mit time_key JOIN korrekt  
**Aufg. 8:** ❌ Subquery Logik komplex, aber weekly_sum ohne GROUP BY week problematic  
**Aufg. 9:** ✅ Window Function mit WHERE is_suspicious korrekt  
**Aufg. 10:** ✅ ROLLUP perfekt  
**Aufg. 11:** ❌ SUM(f.amount) statt SUM(f.fee)! Falsche Spalte!  
**Aufg. 12:** ✅ ROLLUP + COALESCE + ORDER BY GROUPING perfekt  

---

## HAUPTPROBLEME

1. **Aufg. 4:** Window Function in WHERE (ALTER FEHLER!)
2. **Aufg. 8:** Wöchentliche Aggregation unklar/komplex
3. **Aufg. 11:** Falsche Spalte (amount statt fee)

---

## FAZIT

**75% ist GUT!** Multi-Fact JOINs funktionieren! Window Functions stark!

---
