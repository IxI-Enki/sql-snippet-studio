# TEST 10 ANALYSIS: MIXED EXPERT - llama-3-sqlcoder-8b

**EXPERT-LEVEL ANALYSE** - Alle 18 Aufgaben

---

## SCORE: 11.1% (2/18)

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ | 2 | 1, 2 |
| ⚠️ | 3 | 3, 4, 14 |
| ❌ | 13 | 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 16, 17, 18 |

---

## DETAILLIERTE FEHLER

**STAR SCHEMA (1-2):**
- ✅ 1: Korrekt
- ✅ 2: Korrekt

**WINDOW FUNCTIONS (3-6):**
- ⚠️ 3: CTE korrekt, aber WHERE sales_rank <=5 fehlt!
- ⚠️ 4: Formel korrekt, aber Duplikate durch fehlende Aggregation
- ❌ 5: Verwendet p.list_price statt fs.revenue - komplett falsch!
- ❌ 6: LAG(SUM(...)) ungültig - kann nicht aggregieren!

**MERGE & ETL (7-8):**
- ❌ 7: Nur SELECT, kein MERGE!
- ❌ 8: Nur SELECT, kein UPDATE!

**ROLLUP (9-10):**
- ❌ 9: ROLLUP Syntax falsch + redundante GROUP BY Spalten
- ❌ 10: ROLLUP Syntax falsch + full_date statt year/quarter/month

**CTEs & SUBQUERIES (11-13):**
- ❌ 11: product_trend SELECT fehlt sales_quantity Spalte!
- ❌ 12: Vergleicht nur mit average, nicht mit Customer LTV
- ❌ 13: JOIN zu STG_Sales falsch (product_code vs product_key)

**MULTI-FACT (14-15):**
- ⚠️ 14: JOIN Syntax korrekt
- ❌ 15: Kein JOIN zwischen f und i!

**REAL-WORLD (16-18):**
- ❌ 16: Verwendet SUM(profit/cost) statt SUM(profit)/SUM(cost)
- ❌ 17: customer_orders Tabelle existiert nicht!
- ❌ 18: p.product_category existiert nicht (sollte p.category sein)

---

## HAUPTPROBLEME

1. **MERGE komplett nicht verstanden** - generiert SELECT statt INSERT/UPDATE
2. **Window Function Aggregation falsch** (LAG(SUM(...)))
3. **CTE Logik unvollständig** (fehlende Spalten, keine Filter)
4. **JOIN zu nicht-existierenden Tabellen** (customer_orders)
5. **Spalten-Namen falsch** (product_category statt category)
6. **ROLLUP Syntax durchgehend falsch**

---

## FAZIT: EXPERT TEST = **FAILED**

**NUR 2 von 18** korrekt!  
Model ist **NICHT** production-ready für komplexe Real-World Queries!

---
