# Snippet reference

SQL Snippet Studio 2.0.1 includes 67 snippets: 20 shared SQL and dimensional-modeling patterns, 22 PostgreSQL snippets, and 25 Oracle PL/SQL snippets. Prefixes and descriptions below are copied from the packaged JSON snippet definitions.

Type a prefix in a SQL editor and press **Tab**. Use `Ctrl+Space` first if the suggestion list is not visible.

## Shared SQL and dimensional modeling (20)

| Prefix | Description |
| ------ | ----------- |
| `star-schema` | Complete Star Schema with dimensions and fact table |
| `dim-table` | Dimension table with SCD Type 2 support |
| `fact-table` | Fact table with measures and FK references |
| `dim-time` | Standard time dimension table |
| `create-table` | CREATE TABLE with common constraints |
| `fk` | Foreign key constraint |
| `view-analytics` | Analytical view with aggregations |
| `idx-fk` | Index on foreign key column for performance |
| `sel` | Simple SELECT statement |
| `sel-join` | JOIN query with aliases |
| `sel-agg` | Aggregate query with GROUP BY and HAVING |
| `sel-sub` | SELECT with subquery |
| `sel-window` | Query with window function |
| `case` | CASE statement |
| `with-cte` | Common Table Expression (WITH clause) |
| `ins` | INSERT statement |
| `upd` | UPDATE statement |
| `del` | DELETE statement |
| `trans` | Transaction block with COMMIT/ROLLBACK |
| `comment-block` | Formatted comment block |

## PostgreSQL (22)

| Prefix | Description |
| ------ | ----------- |
| `pg-create-table` | PostgreSQL Table with SERIAL and update trigger |
| `pg-serial` | PostgreSQL SERIAL primary key |
| `pg-bigserial` | PostgreSQL BIGSERIAL primary key |
| `pg-jsonb` | PostgreSQL JSONB column |
| `pg-array` | PostgreSQL Array column |
| `pg-enum` | PostgreSQL CREATE ENUM type |
| `pg-matview` | PostgreSQL Materialized view |
| `pg-function` | PostgreSQL plpgsql function |
| `pg-trigger` | PostgreSQL Trigger with function |
| `pg-row-number` | PostgreSQL ROW_NUMBER window function |
| `pg-rank` | PostgreSQL RANK window function |
| `pg-upsert` | PostgreSQL UPSERT (ON CONFLICT) INSERT ON CONFLICT (upsert) |
| `pg-series` | PostgreSQL Generate series of numbers |
| `pg-date-series` | PostgreSQL Generate date series |
| `pg-recursive` | PostgreSQL Recursive CTE |
| `pg-fts` | PostgreSQL Full-text search setup |
| `pg-explain` | PostgreSQL EXPLAIN ANALYZE for query performance |
| `pg-savepoint` | PostgreSQL Transaction with savepoint |
| `pg-idx-btree` | PostgreSQL BTREE index |
| `pg-idx-hash` | PostgreSQL HASH index |
| `pg-idx-gin` | PostgreSQL GIN index for arrays/JSONB |
| `pg-partition-range` | PostgreSQL Range partitioned table |

## Oracle PL/SQL (25)

| Prefix | Description |
| ------ | ----------- |
| `ora-create-table` | Oracle table with sequence and triggers |
| `ora-sequence` | CREATE SEQUENCE (Oracle) |
| `ora-types` | Common Oracle data types |
| `ora-trigger-bi` | BEFORE INSERT trigger (Oracle) |
| `ora-trigger-bu` | BEFORE UPDATE trigger (Oracle) |
| `ora-procedure` | Oracle stored procedure |
| `ora-function` | Oracle function |
| `ora-package-spec` | Oracle package specification |
| `ora-package-body` | Oracle package body |
| `ora-cursor` | Oracle cursor with loop |
| `ora-for-cursor` | Oracle FOR loop with implicit cursor |
| `ora-bulk` | Oracle BULK COLLECT for performance |
| `ora-merge` | Oracle MERGE statement (UPSERT) |
| `ora-hierarchy` | Oracle hierarchical query (tree structure) |
| `ora-analytic` | Oracle analytic (window) function |
| `ora-with` | Oracle WITH clause (CTE) |
| `ora-exception` | Oracle exception handling block |
| `ora-dbms-output` | Oracle DBMS_OUTPUT for debugging |
| `ora-autonomous` | Oracle autonomous transaction |
| `ora-dynamic-sql` | Oracle dynamic SQL with EXECUTE IMMEDIATE |
| `ora-explain` | Oracle EXPLAIN PLAN for query analysis |
| `ora-idx-btree` | Oracle BTREE index (default) |
| `ora-idx-bitmap` | Oracle BITMAP index for low-cardinality columns |
| `ora-matview` | Oracle materialized view |
| `ora-partition-range` | Oracle partitioned table (RANGE) |

## Related guides

- [Quick start](quickstart.md)
- [Setup guide](setup_guide.md)
- [Optional LLM assistance](llm_feature.md)
