# MERGE task analysis (product catalog)

Observation notes for the local LLM workflow on
[`task_05_product_catalog_merge.sql`](task_05_product_catalog_merge.sql).

| Field | Value |
| ----- | ----- |
| Date | 2025-11-09 |
| Model | `qwen3-coder-30b-a3b-instruct` |
| Extension versions compared | 1.7.1, 1.8.0, 1.8.1 |
| Scenario | Product catalog MERGE / ETL |

Scores below measure whether the returned SQL matched the intended PostgreSQL
behavior for each task comment (8 tasks total).

## Results summary

| Task | Topic | 1.7.1 | 1.8.0 | Notes |
| ---: | ----- | ----: | ----: | ----- |
| 1 | Basic MERGE (insert + update) | 100% | 100% | Stable |
| 2 | Conditional UPDATE (price changed) | 100% | 100% | Stable |
| 3 | Delete rows missing from source | 0% | 50% | Dialect / consistency issue |
| 4 | Price change greater than 10% | 100% | 100% | Stable |
| 5 | CASE and stock addition | 100% | 100% | Stable |
| 6 | Change logging | 100% | 100% | Stable |
| 7 | UPDATE with correct WHERE target | 50% | 100% | Logic fix in 1.8.0 |
| 8 | Multi-stage ETL | 0% | 100% | Separate statements in 1.8.0 |

Aggregate for this scenario:

| Version | Score | Main change |
| ------- | ----: | ----------- |
| 1.7.0 | 0% | Parser failure blocked useful output |
| 1.7.1 | 62.5% | Parser fixed |
| 1.8.0 | 87.5% | Target-table logic + multi-stage ETL guidance |
| 1.8.1 | (expected higher on task 3) | Stronger PostgreSQL dialect warning for `BY SOURCE` |

## Findings

### Task 7 — WHERE clause must target the updated table

In 1.7.1 the model filtered stock on the staging table while updating `Products`:

```sql
UPDATE Products
SET stock_quantity = stock_quantity - 1,
    last_updated = CURRENT_TIMESTAMP
WHERE product_id IN (
    SELECT product_id
    FROM STG_Product_Updates
    WHERE stock_quantity < 10
)
RETURNING product_id, stock_quantity, last_updated;
```

In 1.8.0, with stronger logic guidance in the prompt context, the filter applied
to `Products` itself:

```sql
UPDATE Products
SET stock_quantity = stock_quantity - 1,
    last_updated = CURRENT_TIMESTAMP
WHERE stock_quantity < 10
RETURNING product_id, stock_quantity, last_updated;
```

### Task 8 — Multi-stage ETL without MERGE inside a CTE

In 1.7.1 the model nested `MERGE` inside a `WITH` clause. PostgreSQL does not
support that pattern, so the multi-stage flow failed.

In 1.8.0 the model emitted separate statements: supplier MERGE, product MERGE,
then a logging `INSERT`. That matches PostgreSQL constraints and the intended
ETL shape.

### Task 3 — Delete rows not present in source

Behavior in 1.8.0 was inconsistent across runs:

1. One run produced an incorrect `INSERT` branch instead of a delete.
2. A later run produced `WHEN NOT MATCHED BY SOURCE THEN DELETE`, which is
   SQL Server / Oracle wording and is not valid PostgreSQL MERGE syntax.

Correct PostgreSQL approach for this task:

```sql
DELETE FROM Products
WHERE product_id NOT IN (
    SELECT product_id FROM STG_Product_Updates
);
```

Version 1.8.1 strengthened the dialect warning to state that `BY SOURCE` is not
PostgreSQL syntax and to prefer a separate `DELETE` (or an explicit explanation
that the clause is unsupported).

## Takeaways

1. Parser correctness dominates quality; dialect and logic guidance only help
   after the response can be parsed.
2. Dialect limits need concrete wrong/right examples, not only a short “not
   supported” note.
3. Local model output is non-deterministic; the same task comment can yield
   different SQL on repeated runs.
4. Prompt context that names the correct target table and forbids MERGE-in-CTE
   patterns improved tasks 7 and 8 in this scenario.

## Related files

- Task SQL: [`task_05_product_catalog_merge.sql`](task_05_product_catalog_merge.sql)
- Full example set: [README.md](README.md)
- Local LLM setup: [../../guides/llm_feature.md](../../guides/llm_feature.md)
- LM Studio model notes: [../../guides/lm_studio_model_recommendations.md](../../guides/lm_studio_model_recommendations.md)
