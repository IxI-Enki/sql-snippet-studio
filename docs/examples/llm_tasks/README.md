# LLM task examples

Sample `.sql` files for the optional local LLM workflow in SQL Snippet Studio.
Each file contains schema context plus `-- Task:` comments. Open a file, place
the cursor below a task, and press `Ctrl+Alt+Shift+Q`.

| File | Topic |
| ---- | ----- |
| [task_01_retail_basic.sql](task_01_retail_basic.sql) | Retail star schema basics |
| [task_02_logistics_advanced.sql](task_02_logistics_advanced.sql) | Logistics, MERGE, ETL |
| [task_03_sales_analytics_window.sql](task_03_sales_analytics_window.sql) | Window functions, ROLLUP |
| [task_04_time_series_lag_lead.sql](task_04_time_series_lag_lead.sql) | LAG / LEAD, moving averages |
| [task_05_product_catalog_merge.sql](task_05_product_catalog_merge.sql) | Product catalog MERGE / ETL |
| [task_06_banking_multifact.sql](task_06_banking_multifact.sql) | Multi-fact analytics |
| [task_07_ecommerce_snowflake.sql](task_07_ecommerce_snowflake.sql) | Snowflake schema analytics |
| [task_08_healthcare_scd2.sql](task_08_healthcare_scd2.sql) | SCD Type 2 with MERGE |
| [task_09_education_all_window.sql](task_09_education_all_window.sql) | Full window-function suite |
| [task_10_mixed_expert.sql](task_10_mixed_expert.sql) | Combined advanced patterns |

## Analysis

- [merge_task_analysis.md](merge_task_analysis.md) — observation notes for the
  product-catalog MERGE scenario (`task_05`) across extension versions 1.7.1–1.8.1
  with `qwen3-coder-30b-a3b-instruct`.

## Related documentation

- [Local LLM setup](../../guides/llm_feature.md)
- [LM Studio model recommendations](../../guides/lm_studio_model_recommendations.md)
- [Documentation index](../../README.md)
