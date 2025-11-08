# TEST 4 ANALYSIS: TIME SERIES - qwen3-coder-30b-a3b-instruct

**KOMPAKTE ANALYSE** - Alle 12 Aufgaben

---

## SCORE: 66.7% (8/12)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 8 | 1, 2, 5, 6, 7, 9, 11, 12 |
| ⚠️ | 1 | 4 (fehlt Offset 7) |
| ❌ | 3 | 3, 8, 10 |

---

## DETAILLIERTE FEHLER

**Aufg. 1:** ✅ LAG perfekt  
**Aufg. 2:** ✅ LAG mit Prozent-Berechnung perfekt  
**Aufg. 3:** ❌ LAG(f.daily_revenue, 12) ohne Aggregation - arbeitet auf Tages-Ebene statt Monats-Ebene!  
**Aufg. 4:** ⚠️ LAG() und LEAD() ohne Offset 7! Sollte LAG(..., 7) und LEAD(..., 7) sein!  
**Aufg. 5:** ✅ Running Total perfekt  
**Aufg. 6:** ✅ Running Total pro Quartal perfekt  
**Aufg. 7:** ✅ 7-Day Moving Average perfekt  
**Aufg. 8:** ❌ WHERE + GROUP BY statt Window Function! Versteht Aufgabe falsch!  
**Aufg. 9:** ✅ Deviation Berechnung perfekt  
**Aufg. 10:** ❌ CHAOS! Duplizierte incomplete SELECTs (Zeilen 205-226)! Generierungsfehler!  
**Aufg. 11:** ✅ 14-Day Moving Average perfekt  
**Aufg. 12:** ✅ Min/Max/Avg ohne Window Function - aber für diese Aufgabe korrekt

---

## HAUPTPROBLEME

1. **Aufg. 3:** Monatliche Aggregation fehlt
2. **Aufg. 4:** Offset 7 fehlt bei LAG/LEAD
3. **Aufg. 8:** Keine Window Function verwendet
4. **Aufg. 10:** KRITISCHER GENERIERUNGSFEHLER - incomplete queries!

---
