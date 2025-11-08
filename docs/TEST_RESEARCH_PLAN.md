# 🔬 LLM Test Research Plan - DBI Survival Kit v1.6.0

## **📚 Repository Analysis: DbiTheorie-003**

### **✅ CONFIRMED TEST TOPICS:**

Based on [https://github.com/IxI-Enki/DbiTheorie-003](https://github.com/IxI-Enki/DbiTheorie-003):

#### **1. STAR-SCHEMA & DIMENSIONAL MODELING** ⭐

- **Facts:** Ereignistabellen mit Measures & Foreign Keys
- **Dimensions:** Beschreibende Attribute (Denormalisiert!)
- **Snowflake vs. Star:** Star bevorzugt für OLAP Performance
- **SCD Type 2:** Slowly Changing Dimensions mit Historisierung
- **Grain Definition:** Granularität der Fact-Tabelle
- **⚠️ CRITICAL:** Keine PKs der Quelldaten in Dimensionen!
- **⚠️ CRITICAL:** Mehrere Auflösungsstufen (Hierarchien) verwenden

#### **2. WINDOW FUNCTIONS / ANALYTIC FUNCTIONS** 🪟

- **OVER Clause:** Grundsyntax für Window Functions
- **PARTITION BY:** Gruppierung ohne Aggregation
- **ORDER BY:** Reihenfolge innerhalb der Partition
- **Ranking Functions:**
  - `RANK()` - Mit Lücken
  - `DENSE_RANK()` - Ohne Lücken
  - `ROW_NUMBER()` - Fortlaufend
- **Navigation Functions:**
  - `LAG(column, offset)` - Vorheriger Wert
  - `LEAD(column, offset)` - Nächster Wert
- **Aggregate Functions:**
  - Running Totals: `SUM() OVER (ORDER BY ...)`
  - Moving Averages: `AVG() OVER (ROWS BETWEEN ...)`
- **Window Frames:**
  - `ROWS BETWEEN x PRECEDING AND y FOLLOWING`
  - `RANGE BETWEEN ...`

#### **3. SQL MERGE (UPSERT)** 🔄

- **WHEN MATCHED:** UPDATE existierende Zeilen
- **WHEN NOT MATCHED:** INSERT neue Zeilen
- **WHEN NOT MATCHED BY SOURCE:** DELETE (optional)
- **Conditional Logic:** WHERE clauses in WHEN
- **ETL Use Cases:** Delta-Loading, Synchronisierung
- **Performance:** Besser als separate INSERT + UPDATE

#### **4. ROLLUP (Hierarchische Aggregationen)** 📊

- **ROLLUP:** Hierarchische Subtotals
  - `GROUP BY ROLLUP(a, b, c)` → Subtotals auf jeder Ebene
- **GROUPING():** Unterscheidung echte Werte vs. NULL
- **GROUPING SETS:** Custom Kombinationen
- **⚠️ NOTE:** CUBE wird aus Teststoff entfernt!

#### **5. ETL-PROZESS** 🔧

- **Extract:** Daten aus Quellsystemen extrahieren
- **Transform:** Bereinigung, Validierung, Berechnung
- **Load:** In Data Warehouse laden
- **Delta Loading:** Nur Änderungen verarbeiten
- **Error Handling:** Fehlerhafte Daten behandeln

#### **6. OLAP vs OLTP** 🏢

- **OLTP:** Transaction Processing (normalized, viele Writes)
- **OLAP:** Analytical Processing (denormalized, Read-optimiert)
- **Data Warehouse:** OLAP-Datenbank
- **Data Mart:** Abteilungsspezifisches DW

#### **7. COMPLEX JOINS & AGGREGATIONS** 🔗

- **Multiple JOINs:** 3+ Tabellen
- **Self-Joins:** Hierarchische Daten
- **Outer Joins:** LEFT, RIGHT, FULL
- **Aggregations:** GROUP BY, HAVING
- **Subqueries:** Correlated & Non-Correlated

---

## **🎯 TEST COVERAGE MATRIX**

| Test # | Schema Domain        | Star-Schema   | Window Funcs | MERGE     | ROLLUP | Joins | ETL | Complexity      |
| ------ | -------------------- | ------------- | ------------ | --------- | ------ | ----- | --- | --------------- |
| 1      | Retail Sales         | ✅ Basic      | -            | -         | -      | ✅    | -   | 🟢 Beginner     |
| 2      | Logistics/Warehouse  | ✅ Advanced   | -            | ✅        | -      | ✅    | ✅  | 🟡 Intermediate |
| 3      | Sales Analytics      | ✅            | ✅ Rankings  | -         | ✅     | ✅    | -   | 🟡 Intermediate |
| 4      | Time Series Analysis | ✅            | ✅ LAG/LEAD  | -         | -      | ✅    | -   | 🟡 Intermediate |
| 5      | Product Catalog      | -             | -            | ✅ UPSERT | -      | ✅    | ✅  | 🟢 Beginner     |
| 6      | Banking/Finance      | ✅ Multi-Fact | ✅ Window    | -         | ✅     | ✅    | -   | 🔴 Advanced     |
| 7      | E-Commerce           | ✅ Snowflake  | ✅           | -         | ✅     | ✅    | -   | 🔴 Advanced     |
| 8      | Healthcare           | ✅ SCD Type 2 | -            | ✅        | -      | ✅    | ✅  | 🟡 Intermediate |
| 9      | Education System     | ✅            | ✅ All Types | -         | ✅     | ✅    | -   | 🔴 Advanced     |
| 10     | Mixed/Combined       | ✅            | ✅           | ✅        | ✅     | ✅    | ✅  | 🔴 Expert       |

---

## **📋 TEST FILE SPECIFICATIONS**

### **Test 1: Retail Sales - Basic Star-Schema** 🟢

- **Domain:** Einzelhandel (Verkauf von Produkten)  
- **Schema Complexity:** Basic  
- **Tables:** DIM_Product, DIM_Customer, DIM_Time, FACT_Sales  
- **Focus:** Grundlegende Star-Schema Struktur, einfache Joins  
- **Tasks:**
  - Alle Verkäufe mit Produktnamen
  - Umsatz pro Kunde
  - Umsatz pro Monat
  - Top 5 Produkte

---

### **Test 2: Logistics - Advanced Star-Schema + MERGE** 🟡

- **Domain:** Logistik (Lager, Lieferungen, Transportrouten)  
- **Schema Complexity:** Advanced  
- **Tables:** DIM_Warehouse, DIM_Product, DIM_Supplier, DIM_Time, FACT_Delivery  
- **Focus:** Mehrere Dimensionen, Hierarchien (Warehouse → Region → Country), MERGE für Delta-Loading  
- **Tasks:**
  - Lieferungen pro Lager und Region (ROLLUP-ready)
  - Durchschnittliche Lieferzeit pro Lieferant
  - MERGE Statement für neue Lieferungen
  - Lagerbestand pro Region

---

### **Test 3: Sales Analytics - Window Functions + ROLLUP** 🟡

- **Domain:** Verkaufsanalyse  
- **Schema Complexity:** Intermediate  
- **Tables:** DIM_Region, DIM_Product, DIM_Time, FACT_Sales  
- **Focus:** Rankings, ROLLUP für hierarchische Aggregationen  
- **Tasks:**
  - Ranking der Verkäufer nach Umsatz (RANK, DENSE_RANK, ROW_NUMBER)
  - Umsatz pro Region mit Subtotals (ROLLUP)
  - Top 3 Produkte pro Kategorie (Window Functions)
  - Vergleich zum Vormonat (LAG)

---

### **Test 4: Time Series - LAG/LEAD & Moving Averages** 🟡

- **Domain:** Zeitreihenanalyse (Stock Market, Sales Trends)  
- **Schema Complexity:** Intermediate  
- **Tables:** DIM_Product, DIM_Time, FACT_Sales  
- **Focus:** LAG, LEAD, Running Totals, Moving Averages  
- **Tasks:**
  - Running Total des Umsatzes pro Produkt
  - 7-Tage Moving Average
  - Vergleich zum Vormonat (LAG)
  - Prozentuale Veränderung zum Vorjahr

---

### **Test 5: Product Catalog - SQL MERGE (UPSERT)** 🟢

- **Domain:** Produktkatalog (E-Commerce)  
- **Schema Complexity:** Simple  
- **Tables:** Products, Suppliers, Product_Updates (Staging)  
- **Focus:** MERGE Statement für ETL-Prozess  
- **Tasks:**
  - MERGE neue Produkte ein (INSERT wenn neu, UPDATE wenn existierend)
  - DELETE veraltete Produkte (WHEN NOT MATCHED BY SOURCE)
  - Update nur bei Preisänderung > 10%
  - Log Änderungen in Audit-Tabelle

---

### **Test 6: Banking - Multi-Fact + Window Functions + ROLLUP** 🔴

- **Domain:** Banking/Finance  
- **Schema Complexity:** Advanced (Multi-Fact)  
- **Tables:** DIM_Customer, DIM_Account, DIM_Time, FACT_Transaction, FACT_Balance  
- **Focus:** Mehrere Fact-Tabellen, komplexe Window Functions, ROLLUP  
- **Tasks:**
  - Kontostand-Entwicklung über Zeit (Running Total)
  - Durchschnittlicher Transaktionsbetrag pro Kunde (Window Functions)
  - Hierarchische Aggregation nach Kontentyp (ROLLUP)
  - Identifizierung verdächtiger Transaktionen (Window Functions + HAVING)

---

### **Test 7: E-Commerce - Snowflake Schema + Window + ROLLUP** 🔴

- **Domain:** E-Commerce (Online-Shop)  
- **Schema Complexity:** Snowflake (normalisierte Dimensions)  
- **Tables:** DIM_Product → DIM_Category → DIM_Department, DIM_Customer → DIM_City → DIM_Country, FACT_Order  
- **Focus:** Snowflake-Schema mit Hierarchien, Window Functions  
- **Tasks:**
  - Bestellungen pro Department > Category > Product (ROLLUP)
  - Ranking der Kunden nach Bestellwert pro Land
  - Durchschnittliche Bestellgröße pro Kategorie
  - Conversion Rate pro Produktkategorie (Window Functions)

---

### **Test 8: Healthcare - SCD Type 2 + MERGE** 🟡

- **Domain:** Healthcare (Patienten, Behandlungen)  
- **Schema Complexity:** Intermediate (Slowly Changing Dimensions)  
- **Tables:** DIM_Patient (SCD Type 2), DIM_Doctor, DIM_Treatment, FACT_Visit  
- **Focus:** Historisierung (Valid_From, Valid_To, Is_Current), MERGE für Updates  
- **Tasks:**
  - Aktuelle Patientendaten abfragen (Is_Current = 1)
  - Historische Adressen eines Patienten
  - MERGE neuer Patientendaten (mit SCD Type 2 Logik)
  - Behandlungen pro Arzt und Fachgebiet

---

### **Test 9: Education System - All Window Functions + ROLLUP** 🔴

- **Domain:** Bildungssystem (Schule/Universität)  
- **Schema Complexity:** Advanced  
- **Tables:** DIM_Student, DIM_Course, DIM_Professor, DIM_Time, FACT_Grade  
- **Focus:** Alle Window Function Typen, ROLLUP, komplexe Analysen  
- **Tasks:**
  - Ranking der Studenten nach Notendurchschnitt (RANK, DENSE_RANK)
  - Notenentwicklung über Semester (LAG, LEAD)
  - Moving Average der Noten pro Kurs
  - Hierarchische Aggregation (Fakultät → Studiengang → Kurs) (ROLLUP)
  - Identifizierung von Top-Performern (NTILE für Quartile)

---

### **Test 10: Mixed Scenario - ALL TOPICS COMBINED** 🔴

- **Domain:** Multi-Domain (Kombination aller Themen)  
- **Schema Complexity:** Expert  
- **Tables:** Complex Star-Schema mit allen Elementen  
- **Focus:** Kombination von Star-Schema, Window Functions, MERGE, ROLLUP, ETL  
- **Tasks:**
  - Star-Schema Design mit 4+ Dimensions
  - ETL mit MERGE und Delta-Loading
  - Complex Window Functions (PARTITION BY mehrere Spalten)
  - ROLLUP mit 3+ Ebenen
  - Performance-kritische Queries mit Subqueries & CTEs
  - Real-World Scenario: "Identifiziere profitable Produkte pro Region mit Trendanalyse"

---

## **🧪 TESTING METHODOLOGY**

### **Test Execution Plan:**

**For Each Test File:**

1. **LLM Query:** Trigger mit `Ctrl+Alt+Shift+Q` bei jeder Task
2. **Response Validation:**
   - ✅ Parser entfernt `<think>` Blöcke
   - ✅ Validator prüft SQL Syntax
   - ✅ Score ≥ 85/100
3. **Manual Review:**
   - Logische Korrektheit der Query
   - Verwendung korrekter Table Names
   - Optimale Joins (kein unnötiges CROSS JOIN)
   - Korrekte Window Function Syntax
4. **Documentation:**
   - Model Name
   - Response Time
   - Validation Score
   - Anzahl Parser-Stages benötigt
   - Issues / Notes

**Success Criteria:**

- ✅ 90%+ der Queries logisch korrekt
- ✅ 80%+ der Queries Validation Score ≥ 85
- ✅ Funktioniert mit mindestens 5 verschiedenen Models
- ✅ Parser entfernt erfolgreich `<think>` Blöcke (osmosis-mcp-4b!)

---

## **📊 MODEL TESTING MATRIX**

| Model                   | Test 1 | Test 2 | Test 3 | Test 4 | Test 5 | Test 6 | Test 7 | Test 8 | Test 9 | Test 10 | Avg Score |
| ----------------------- | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------ | ------- | --------- |
| **qwen2.5-7b-instruct** | -      | -      | -      | -      | -      | -      | -      | -      | -      | -       | TBD       |
| **qwen2.5-vl-7b**       | -      | -      | -      | -      | -      | -      | -      | -      | -      | -       | TBD       |
| **osmosis-mcp-4b**      | -      | -      | -      | -      | -      | -      | -      | -      | -      | -       | TBD       |
| **llama3-8b**           | -      | -      | -      | -      | -      | -      | -      | -      | -      | -       | TBD       |
| **codellama-7b**        | -      | -      | -      | -      | -      | -      | -      | -      | -      | -       | TBD       |

---

## **🚀 IMPLEMENTATION PLAN**

### **Phase 1: Create Test Files (1-5)** ✅

- Test 1: Retail Sales (Basic)
- Test 2: Logistics (Advanced + MERGE)
- Test 3: Sales Analytics (Window + ROLLUP)
- Test 4: Time Series (LAG/LEAD)
- Test 5: Product Catalog (MERGE)

### **Phase 2: Create Test Files (6-10)** ✅

- Test 6: Banking (Multi-Fact)
- Test 7: E-Commerce (Snowflake)
- Test 8: Healthcare (SCD Type 2)
- Test 9: Education (All Window Functions)
- Test 10: Mixed (Expert Level)

### **Phase 3: User Testing** 🧪

- User tests with local models
- Collection of results
- Iteration based on findings

---

**Created:** 2025-11-08  
**Version:** 1.0  
**Purpose:** Comprehensive LLM Testing for DBI Survival Kit v1.6.0  
**Target:** 100% Test Coverage für DBI Teststoff 2025/26
