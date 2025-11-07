# 📚 DBI Test Survival Kit - Project Context

## 🎯 Project Goal
Create a **lightweight offline VSCode/Cursor extension** that provides intelligent SQL tab-completion for DBI tests when:
- ❌ No internet connection available
- ❌ Screen recording software prevents using external LLM
- ✅ Tab-completion is allowed during tests

## 🧠 Background Context

### User Situation
- Student taking DBI (Database & Information Systems) tests at HTL Leonding
- Tests will be given as `.sql` files (database schemas)
- Must work with both **PostgreSQL** and **Oracle PL/SQL**
- Screen recording may prevent using local LLM during test
- Tab-completion is explicitly allowed ✅

### Existing Tools
Located on `D:\`:
- **`TRANSFORM.ps1`** - Converts multi-line SQL to single-line text
- **`USE.ps1`** - Starts local LLM with SQL schema context
- **`angabe.sql`** - Example database schema (library management system)

These work well for preparation but can't be used during test if screen recording is active.

## 🎓 DBI Course Content

Based on GitHub repos:
- [DBI Übung 01](https://github.com/IxI-Enki/DBI_2025_26_uebung_01) - SQL Basics
- [DBI Übung 02](https://github.com/IxI-Enki/DBI_2025_26_uebung_02) - Star-Schema Firmendatenbank
- [DBI Übung 05](https://github.com/IxI-Enki/DBI_2025_26_uebung_05) - Advanced queries

### Key Topics to Support
1. **Star-Schema Design**
   - Dimension tables (DIM_*)
   - Fact tables (FACT_*)
   - Time dimensions
   - Slowly changing dimensions (SCD Type 1, 2, 3)

2. **SQL Patterns**
   - CREATE TABLE with constraints
   - Foreign keys and relationships
   - Indexes and performance optimization
   - Views and materialized views
   - Common queries (aggregations, joins, subqueries)

3. **PostgreSQL Specific**
   - SERIAL, BIGSERIAL
   - TIMESTAMP, INTERVAL
   - Array types
   - JSON/JSONB
   - Window functions

4. **Oracle PL/SQL Specific**
   - NUMBER, VARCHAR2
   - SEQUENCE
   - DATE handling
   - Triggers and stored procedures
   - Packages

## 🏗️ Extension Architecture

### Design Principles
1. **100% Offline** - No network calls, all data local
2. **Lightweight** - Minimal dependencies, fast startup
3. **Shareable** - Easy export/import for Kollegen
4. **Extensible** - Simple JSON format for adding patterns
5. **Context-Aware** - Smart suggestions based on current file

### Components

#### 1. Snippet System (`/snippets/`)
- `shared-snippets.json` - Common patterns (both DBs)
- `postgres-snippets.json` - PostgreSQL specific
- `oracle-snippets.json` - Oracle PL/SQL specific

#### 2. IntelliSense Provider (`/src/`)
- Schema-aware completions
- Keyword completions
- Pattern recognition

#### 3. Template Commands
- Insert Star Schema
- Insert Dimension Table
- Insert Fact Table

#### 4. Share System
- Export snippets as JSON
- Import from Kollegen
- Merge & update patterns

## 📋 Implementation Plan

### Phase 1: Core Snippets ✅ (Current)
- [x] Project structure
- [ ] Basic SQL snippets (CREATE, SELECT, etc.)
- [ ] Star-Schema templates
- [ ] Dimension table patterns
- [ ] Fact table patterns

### Phase 2: Intelligence Layer
- [ ] Context-aware completion provider
- [ ] Schema detection from current file
- [ ] Smart FK suggestions
- [ ] Index recommendations

### Phase 3: Sharing & Collaboration
- [ ] Export command
- [ ] Import command
- [ ] Snippet marketplace JSON format
- [ ] Documentation for Kollegen

### Phase 4: Testing & Polish
- [ ] Test with real DBI exercises
- [ ] Performance optimization
- [ ] User documentation
- [ ] Installation guide

## 🎮 Usage Workflow

### For Tests
1. Install extension before test
2. Open SQL file during test
3. Type trigger → Tab → Get completion
4. Modify template as needed

### For Sharing
1. Developer creates/improves snippets
2. Export via command: `DBI: Export Snippets`
3. Share JSON file with Kollegen
4. Kollegen import via: `DBI: Import Snippets`
5. Merge & iterate

## 🔑 Key Design Decisions

### Why Extension vs Just Snippets?
- Extensions can be context-aware
- Can read current file and suggest relevant completions
- Can provide commands for common patterns
- Can implement smart sharing system
- Still works 100% offline

### Why Lightweight?
- Must work without internet
- Must be installable quickly before test
- Must not slow down editor
- Must be simple enough for Kollegen to extend

### Why Separate DB Dialects?
- Different syntax (e.g., SERIAL vs SEQUENCE)
- Different data types
- Different best practices
- User can focus on relevant snippets

## 📝 Next Steps

When you open this project in Cursor:
1. Review the structure
2. Start building snippets based on:
   - Your `D:\angabe.sql` example
   - Your DBI übungen from GitHub
   - Common patterns from course
3. Test with real scenarios
4. Add more patterns iteratively
5. Share with Kollegen for feedback

## 💡 Future Ideas
- [ ] AI-assisted snippet generation (offline)
- [ ] Import from existing DBI exercises
- [ ] Visual Star-Schema builder
- [ ] Query optimizer hints
- [ ] Performance analysis
- [ ] Moodle integration for practice

## 🤓 Team
- Creator: You (IxI-Enki)
- Contributors: Your Kollegen
- Target: HTL Leonding DBI students

---

**Last Updated:** 2025-11-07
**Status:** Phase 1 - In Progress
**Location:** `D:\_Repositories\00_Die_Farm\04_dbi_test_survival_kit`
