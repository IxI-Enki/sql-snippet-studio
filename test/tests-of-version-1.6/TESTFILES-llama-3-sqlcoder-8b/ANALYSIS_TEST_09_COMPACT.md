# TEST 9 ANALYSIS: EDUCATION ALL WINDOW FUNCTIONS - llama-3-sqlcoder-8b

**ULTRA-KOMPAKTE ANALYSE** - Alle 21 Aufgaben

---

## SCORE: 23.8% (5/21)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 2 | 2, 10 (Duplikat von Aufgabe 10!) |
| ⚠️ | 8 | 1, 4, 7, 12, 14, 16, 18 |
| ❌ | 11 | 3, 5, 6, 8, 9, 11, 13, 15, 17, 19, 20, 21 |

---

## KRITISCHE FEHLER

**RANK/DENSE_RANK/ROW_NUMBER:**
- Aufg. 1: ⚠️ Keine GROUP BY für aggregierten GPA
- Aufg. 2: ✅ KORREKT
- Aufg. 3: ❌ ROW_NUMBER ohne CTE Filter für Top 3

**NTILE:**
- Aufg. 4: ⚠️ Sortiert nach grade_points DESC (korrekt)
- Aufg. 5: ❌ ORDER BY in SELECT außerhalb window! Syntax falsch!
- Aufg. 6: ❌ Falsche Spalte (g.percentage statt f.grade_points)

**LAG/LEAD:**
- Aufg. 7: ⚠️ Zeigt nur Datum statt GPA-Vergleich
- Aufg. 8: ❌ f.year existiert nicht (sollte t.year sein)
- Aufg. 9: ❌ WHERE mit LAG - ungültig!

**RUNNING TOTALS:**
- Aufg. 10 (doppelt!): ✅ KORREKT (aber 2x dieselbe Query!)
- Aufg. 11: ❌ Keine Window Function! Nur GROUP BY!

**MOVING AVERAGES:**
- Aufg. 12: ⚠️ Korrekte Syntax
- Aufg. 13: ❌ WHERE mit MAX(time_key) statt Window

**FIRST_VALUE/LAST_VALUE:**
- Aufg. 14: ⚠️ Verwendet LAG statt FIRST_VALUE
- Aufg. 15: ❌ Nur GROUP BY, keine Window Functions!

**ROLLUP:**
- Aufg. 16: ⚠️ MySQL "WITH ROLLUP" statt PostgreSQL Syntax
- Aufg. 17: ❌ d.department undefined + "ROLLUP" ohne "GROUP BY"
- Aufg. 18: ⚠️ MySQL Syntax

**ADVANCED:**
- Aufg. 19: ❌ f.profiler_key Typo! (sollte professor_key sein)
- Aufg. 20: ❌ STDDEV im WHERE - ungültig!
- Aufg. 21: ⚠️ PERCENT_RANK Syntax korrekt

---

## HAUPTPROBLEME

1. **"Top N per Group" nicht verstanden** (keine CTEs + Filter)
2. **Window Functions in WHERE** (mehrfach!)
3. **MySQL ROLLUP Syntax** statt PostgreSQL
4. **Viele Tabellen-Referenz Fehler**
5. **Aufgabe 10 DOPPELT!** (Zeile 125 + 129)

---
