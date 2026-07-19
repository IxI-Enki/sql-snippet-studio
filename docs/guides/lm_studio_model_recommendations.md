# LM Studio model recommendations

Local GGUF model notes for SQL generation with SQL Snippet Studio
(PostgreSQL and Oracle PL/SQL).

| Field | Value |
| ----- | ----- |
| Last updated | 2025-11-08 |
| Focus | PostgreSQL and Oracle PL/SQL |
| Environment | LM Studio (GGUF) |
| Baseline observation | `qwen2.5-vl-7b` scored about 45/100 (success rate about 30.6%) in an earlier local run |

Larger coder-focused models are recommended for serious SQL work.

## Quick recommendations

| Use case | Recommended model | Size | Expected success rate |
| -------- | ----------------- | ---- | --------------------- |
| Basic SQL | Qwen2.5-Coder-7B-Instruct | 7B | 85-90% |
| Intermediate SQL | Qwen2.5-Coder-14B-Instruct | 14B | 70-80% |
| Advanced SQL | Qwen2.5-Coder-32B-Instruct | 32B | 80-90% |
| Expert SQL | DeepSeek-Coder-V2.5-236B | 236B | 90-95% |
| Budget / SQL-specialized | SQLCoder-7B-2 | 7B | 75-85% |
| Speed focus | Qwen2.5-Coder-14B (Q4_K_M) | 14B | 70-80% |
| Best balance | **Qwen2.5-Coder-32B-Instruct** | 32B | Recommended |

---

## Top models

### 1. Qwen2.5-Coder-32B-Instruct (best overall)

Highly recommended for SQL Snippet Studio production use.

| Item | Detail |
| ---- | ------ |
| Parameters | 32B |
| Context | 128K tokens |
| Download | [Qwen2.5-Coder-32B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF) |

**Quantization options**

| Quant | VRAM (approx.) | Notes |
| ----- | -------------- | ----- |
| Q4_K_M | 18 GB | Good balance |
| Q5_K_M | 22 GB | Better quality |
| Q6_K | 26 GB | Excellent quality |
| Q8_0 | 34 GB | Near-original quality |

**Performance estimates**

| Area | Estimate |
| ---- | -------- |
| Basic SQL | 95% |
| Intermediate SQL | 85% |
| Advanced SQL (window functions, CTEs) | 80% |
| Expert SQL (MERGE, SCD2, ROLLUP) | 75% |
| PostgreSQL dialect | Excellent |
| Oracle PL/SQL | Very good |

**Strengths:** strong code generation, dialect awareness, window functions, complex JOINs/CTEs, 128K context, usable speed at Q4_K_M.

**Weaknesses:** MERGE still challenging; SCD Type 2 needs careful prompting; occasional MySQL vs PostgreSQL confusion.

**RAM:** Q4_K_M about 20 GB (min 16 GB + swap); Q5_K_M about 24 GB (32 GB recommended); Q6_K about 28 GB.

**Best for:** complex SQL, multi-fact star-schema queries, window functions, LAG/LEAD, running totals.

Example prompt shape:

```text
You are an expert PostgreSQL/Oracle SQL developer. Generate ONLY valid SQL code without explanation.

Database Schema:
[SCHEMA HERE]

Task: [TASK HERE]

SQL:
```

### 2. Qwen2.5-Coder-14B-Instruct (balanced)

| Item | Detail |
| ---- | ------ |
| Parameters | 14B |
| Context | 128K tokens |
| Download | [Qwen2.5-Coder-14B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-Coder-14B-Instruct-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 9 GB |
| Q5_K_M | 11 GB |
| Q6_K | 13 GB |

| Area | Estimate |
| ---- | -------- |
| Basic SQL | 90% |
| Intermediate SQL | 75% |
| Advanced SQL | 65% |
| Expert SQL | 45% |
| PostgreSQL | Very good |
| Oracle PL/SQL | Good |

**Strengths:** fast on moderate hardware; solid basic/intermediate SQL; 128K context; 9-13 GB VRAM.

**Weaknesses:** MERGE often wrong; ROLLUP dialect mistakes; weak SCD2; multi-fact queries are hard.

**RAM:** Q4_K_M about 11 GB (usable on 16 GB systems).

**Best for:** development, basic to intermediate SQL, fast prototyping, 16 GB machines.

### 3. DeepSeek-Coder-V2.5-236B (ultimate quality)

Expert-level quality; needs powerful hardware. MoE with about 21B active parameters.

| Item | Detail |
| ---- | ------ |
| Parameters | 236B (MoE, ~21B active) |
| Context | 128K tokens |
| Download | [DeepSeek-Coder-V2.5-Instruct-GGUF](https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2.5-Instruct-GGUF) |

| Quant | VRAM/RAM (approx.) |
| ----- | ------------------ |
| IQ3_XS | 100 GB |
| Q4_K_M | 140 GB |
| Q5_K_M | 170 GB |

| Area | Estimate |
| ---- | -------- |
| Basic SQL | 98% |
| Intermediate SQL | 95% |
| Advanced SQL | 90% |
| Expert SQL (MERGE, SCD2) | 85% |
| PostgreSQL / Oracle | Excellent |

**Strengths:** strong MERGE/SCD2/ROLLUP and multi-fact results.

**Weaknesses:** extreme memory use; slow; impractical for most local setups.

**Best for:** cloud/distributed inference, maximum quality. Prefer DeepSeek-Coder-V2.5-16B for practical local use.

### 4. SQLCoder-34B (SQL-specialized)

| Item | Detail |
| ---- | ------ |
| Parameters | 34B |
| Context | 16K tokens |
| Download | [sqlcoder-34b-alpha-GGUF](https://huggingface.co/defog/sqlcoder-34b-alpha-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 20 GB |
| Q5_K_M | 24 GB |
| Q8_0 | 36 GB |

| Area | Estimate |
| ---- | -------- |
| Basic SQL | 95% |
| Intermediate SQL | 90% |
| Advanced SQL | 85% |
| Expert SQL | 70% |
| PostgreSQL | Excellent |
| Oracle PL/SQL | Good (PostgreSQL-focused) |

**Strengths:** trained for SQL; strong SELECT/JOIN/WHERE/GROUP BY; good window functions and star-schema sense; relatively clean output.

**Weaknesses:** smaller 16K context; MERGE/SCD2 still hard; Oracle less proven.

**Best for:** PostgreSQL-heavy warehouses and window-function work.

### 5. Qwen2.5-Coder-7B-Instruct (fast and efficient)

| Item | Detail |
| ---- | ------ |
| Parameters | 7B |
| Context | 128K tokens |
| Download | [Qwen2.5-Coder-7B-Instruct-GGUF](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 5 GB |
| Q5_K_M | 6 GB |
| Q8_0 | 8 GB |

| Area | Estimate |
| ---- | -------- |
| Basic SQL | 90% |
| Intermediate SQL | 60% |
| Advanced SQL | 40% |
| Expert SQL | 15% |

**Strengths:** very fast; low VRAM; fine for basic SQL.

**Weaknesses:** weak on MERGE, ROLLUP, SCD2, and complex window functions.

**Best for:** learning and quick basic prototypes. Not recommended as the primary model for advanced SQL with SQL Snippet Studio. Behavior is in the same class as the earlier `qwen2.5-vl-7b` baseline (~45/100).

### 6. Llama-3.3-70B-Instruct (general purpose)

| Item | Detail |
| ---- | ------ |
| Parameters | 70B |
| Context | 128K tokens |
| Download | [Llama-3.3-70B-Instruct-GGUF](https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 40 GB |
| Q5_K_M | 48 GB |
| Q6_K | 54 GB |

Solid general coding and SQL; not SQL-specialized. MERGE/ROLLUP can be inconsistent. High VRAM. Prefer Qwen2.5-Coder for pure SQL.

### 7. Mistral-Large-2-123B-Instruct (high quality)

| Item | Detail |
| ---- | ------ |
| Parameters | 123B |
| Context | 128K tokens |
| Download | [Mistral-Large-Instruct-2407-GGUF](https://huggingface.co/mistralai/Mistral-Large-Instruct-2407-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 70 GB |
| Q5_K_M | 85 GB |

Strong reasoning and dialect awareness; high hardware cost; not SQL-specialized.

### 8. DeepSeek-Coder-V2.5-16B (practical alternative)

| Item | Detail |
| ---- | ------ |
| Parameters | 16B |
| Context | 128K tokens |
| Download | [DeepSeek-Coder-V2.5-16B-Instruct-GGUF](https://huggingface.co/deepseek-ai/DeepSeek-Coder-V2.5-16B-Instruct-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 10 GB |
| Q5_K_M | 12 GB |
| Q6_K | 14 GB |

Good balance for intermediate SQL on 16 GB+ systems. MERGE/ROLLUP/SCD2 remain weak spots.

### 9. Codestral-22B (code-optimized)

| Item | Detail |
| ---- | ------ |
| Parameters | 22B |
| Context | 32K tokens |
| Download | [Codestral-22B-v0.1-GGUF](https://huggingface.co/mistralai/Codestral-22B-v0.1-GGUF) |

| Quant | VRAM (approx.) |
| ----- | -------------- |
| Q4_K_M | 13 GB |
| Q5_K_M | 16 GB |

Fine for general coding plus basic SQL. Smaller context than Qwen; weaker advanced SQL.

### 10. Phi-3.5-14B-Instruct (efficient)

| Item | Detail |
| ---- | ------ |
| Parameters | 14B |
| Context | 128K tokens |
| Download | [Phi-3.5 MoE instruct GGUF](https://huggingface.co/microsoft/Phi-3.5-MoE-instruct-GGUF) |

Efficient and fast, but SQL is not the primary focus. Not recommended for advanced MERGE/ROLLUP/SCD2 work.

---

## Comparison table

Estimates for Q4_K_M where applicable:

| Model | Size | VRAM | Basic | Advanced | MERGE | ROLLUP | SCD2 | Overall |
| ----- | ---- | ---- | ----: | -------: | ----: | -----: | ---: | ------: |
| DeepSeek-236B | 236B | 140 GB | 98% | 90% | 85% | 90% | 85% | 95% |
| Qwen2.5-32B | 32B | 18 GB | 95% | 80% | 70% | 75% | 65% | **85%** |
| SQLCoder-34B | 34B | 20 GB | 95% | 85% | 65% | 70% | 60% | 83% |
| Mistral-123B | 123B | 70 GB | 95% | 80% | 65% | 70% | 60% | 82% |
| Llama-3.3-70B | 70B | 40 GB | 93% | 70% | 50% | 55% | 45% | 75% |
| DeepSeek-16B | 16B | 10 GB | 92% | 68% | 45% | 50% | 40% | 72% |
| Qwen2.5-14B | 14B | 9 GB | 90% | 65% | 40% | 45% | 35% | 70% |
| Codestral-22B | 22B | 13 GB | 88% | 60% | 35% | 40% | 30% | 65% |
| Phi-3.5-14B | 14B | 9 GB | 85% | 50% | 20% | 25% | 20% | 55% |
| Qwen2.5-7B | 7B | 5 GB | 90% | 40% | 10% | 5% | 10% | 45% |

**Legend:** DeepSeek-236B = best overall quality; Qwen2.5-32B = best balance for local use; SQLCoder-34B = SQL-specialized; Qwen2.5-7B class matches the earlier weak local baseline.

---

## Recommendation by hardware

### 8-16 GB RAM

- Primary: Qwen2.5-Coder-7B-Instruct (Q4_K_M)
- Expected: about 45-50/100; basic SQL only
- Verdict: not enough for advanced SQL with this extension
- Alternative: cloud APIs when needed

### 16-24 GB RAM

- Primary: Qwen2.5-Coder-14B-Instruct (Q4_K_M)
- Expected: about 70-75/100
- Verdict: acceptable for development
- Alternative: DeepSeek-Coder-V2.5-16B (Q4_K_M)

### 24-32 GB RAM

- Primary: Qwen2.5-Coder-14B-Instruct (Q5_K_M), or upgrade to Qwen2.5-Coder-32B-Instruct (Q4_K_M) at about 20 GB
- Expected with 32B Q4_K_M: about 80-85/100
- Verdict: recommended for SQL Snippet Studio

### 32-64 GB RAM

- Primary: Qwen2.5-Coder-32B-Instruct (Q5_K_M)
- Expected: about 85-90/100
- Verdict: highly recommended for advanced SQL
- Alternative: SQLCoder-34B (Q5_K_M) for PostgreSQL focus

### 64 GB+ RAM

- Primary: Qwen2.5-Coder-32B-Instruct (Q6_K)
- Expected: about 87-92/100
- Alternative: Llama-3.3-70B (Q4_K_M) at about 42 GB

### 128 GB+ RAM

- Primary: DeepSeek-Coder-V2.5-236B (IQ3_XS)
- Expected: about 90-95/100
- Alternative: Mistral-Large-2-123B (Q4_K_M) at about 72 GB

---

## Quantization guide

| Quantization | Quality | Speed | VRAM | Use case |
| ------------ | ------- | ----- | ---- | -------- |
| Q2_K | Poor | Fastest | Lowest | Not recommended |
| Q3_K_M | Fair | Very fast | Low | Basic tasks only |
| **Q4_K_M** | Good | Fast | Moderate | Recommended balance |
| Q5_K_M | Very good | Moderate | Higher | Better quality |
| Q6_K | Excellent | Slower | High | High quality |
| Q8_0 | Near-perfect | Slow | Very high | Usually overkill |
| F16 | Perfect | Slowest | Extreme | Impractical locally |

Start with Q4_K_M; move to Q5_K_M if RAM allows.

---

## Installation outline

1. Install [LM Studio](https://lmstudio.ai/) and open the Discover tab.
2. Search for `Qwen2.5-Coder-32B-Instruct-GGUF` (or another model above) and download Q4_K_M or Q5_K_M.
3. Manual GGUF placement (optional):
   - Windows: `C:\Users\<You>\.cache\lm-studio\models`
   - macOS / Linux: `~/.cache/lm-studio/models`
4. Load the model in Chat / server mode. Suggested settings for SQL:
   - Temperature: `0.1` to `0.3`
   - Context length: `8192` to `32768`
   - GPU layers: as many as VRAM allows
5. Smoke-test with a small JOIN prompt before wiring the extension.

Example smoke prompt:

```text
You are a PostgreSQL expert. Generate ONLY valid SQL code.

Schema:
CREATE TABLE employees (emp_id INT, emp_name VARCHAR(100), dept_id INT);
CREATE TABLE departments (dept_id INT, dept_name VARCHAR(100));

Task: List all employees with their department names.

SQL:
```

Expected shape:

```sql
SELECT e.emp_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;
```

### Extension settings

Use current SQL Snippet Studio keys (store the token via **SQL: Set LLM API Token**, not in plain settings):

```json
{
  "sqlSnippetStudio.llm.enabled": true,
  "sqlSnippetStudio.llm.endpoint": "http://localhost:1234/v1/chat/completions",
  "sqlSnippetStudio.llm.model": "qwen2.5-coder-32b-instruct",
  "sqlSnippetStudio.llm.temperature": 0.1,
  "sqlSnippetStudio.llm.maxTokens": 500
}
```

Exact model id strings must match what LM Studio reports on `/v1/models`.

Full setup: [llm_feature.md](llm_feature.md).

---

## Validation with the example task set

Use the public examples under [docs/examples/llm_tasks/](../examples/llm_tasks/):

1. `task_01_retail_basic.sql` through `task_10_mixed_expert.sql`
2. Place the cursor below a `-- Task:` comment and press `Ctrl+Alt+Shift+Q`
3. Spot-check hard areas: MERGE, ROLLUP, SCD Type 2, multi-fact joins, complex window functions

Practical acceptance targets for a primary local model:

| Metric | Target |
| ------ | ------ |
| Overall usefulness | about 70/100 or better |
| Success rate on task comments | about 60%+ |
| Critical patterns | ROLLUP, LAG/LEAD, window functions usable |

Observation notes for the MERGE scenario: [merge_task_analysis.md](../examples/llm_tasks/merge_task_analysis.md).

---

## Expected improvement (7B class to 32B)

Illustrative uplift from the earlier ~7B baseline to Qwen2.5-Coder-32B:

| Metric | ~7B baseline | 32B expected | Delta |
| ------ | -----------: | -----------: | ----: |
| Overall score | 45/100 | 85/100 | +40 |
| Success rate | 30.6% | 75%+ | +44 pp |
| Basic SQL | 87.5% | 95%+ | +7.5 |
| Intermediate | 50.0% | 85%+ | +35 |
| Advanced | 28.4% | 80%+ | +51.6 |
| Expert | 4.3% | 65%+ | +60.7 |
| MERGE | 0% | 70%+ | +70 |
| ROLLUP | 0% | 75%+ | +75 |
| SCD2 | 15% | 65%+ | +50 |

---

## Cost notes

### Local hardware (one-time)

| Upgrade | Rough cost | Unlocks |
| ------- | ---------- | ------- |
| 16 GB to 32 GB RAM | about EUR 80-150 | Qwen2.5-14B, DeepSeek-16B |
| 32 GB to 64 GB RAM | about EUR 150-300 | Qwen2.5-32B, SQLCoder-34B |
| 64 GB to 128 GB RAM | about EUR 400-800 | Llama-70B, Mistral-123B |
| RTX 4090 class (24 GB) | about EUR 1800-2200 | GPU-accelerated inference |

### Cloud / API alternatives

| Service | Model | Cost (indicative) | Notes |
| ------- | ----- | ----------------- | ----- |
| OpenAI | GPT-4 Turbo | high | Highest quality |
| Anthropic | Claude 3.5 Sonnet | high | Strong SQL |
| DeepSeek | V2.5 | low | Budget API option |
| Groq | Llama 3.1 70B | free tier possible | Fast inference |

**Value pick:** about 32 GB RAM plus Qwen2.5-Coder-32B locally. For occasional peaks, a cheap cloud API can complement the local setup.

---

## Troubleshooting

### Model too large for RAM

- Use a smaller quant (for example Q4_K_M or Q3_K_M)
- Enable system swap (10-20 GB)
- Drop to a smaller model (32B to 14B)
- Close other applications

### Slow inference

- Raise GPU layers in LM Studio
- Prefer Q4_K_M over Q6_K
- Reduce context length (for example 32K to 8K)
- Lower temperature
- Prefer a faster model class when latency matters

### Poor SQL quality

- State the dialect explicitly (`PostgreSQL ONLY` / Oracle rules)
- Keep schema in the same file as the task
- Try a higher quant or larger model
- Lower temperature (for example `0.1`)

### Extension cannot connect

1. Confirm LM Studio server is running
2. Endpoint should be `http://localhost:1234/v1/chat/completions`
3. Load a model before testing
4. Check local firewall rules
5. Run **SQL: Test LLM Connection**

---

## Final recommendations

### Best overall (recommended)

**Qwen2.5-Coder-32B-Instruct (Q4_K_M)**

| Item | Value |
| ---- | ----- |
| Hardware | 24 GB+ RAM |
| Expected score | about 85/100 |
| Success rate | about 75%+ |
| Verdict | Production-ready for SQL Snippet Studio |

### Budget option

**Qwen2.5-Coder-14B-Instruct (Q5_K_M)**

| Item | Value |
| ---- | ----- |
| Hardware | 16 GB+ RAM |
| Expected score | about 72/100 |
| Verdict | Acceptable for development |

### SQL-specialized

**SQLCoder-34B (Q4_K_M)**

| Item | Value |
| ---- | ----- |
| Hardware | 24 GB+ RAM |
| Expected score | about 83/100 (PostgreSQL focus) |
| Verdict | Strong when the workload is mostly PostgreSQL |

### Ultimate quality (enterprise hardware)

**DeepSeek-Coder-V2.5-236B (IQ3_XS)**

| Item | Value |
| ---- | ----- |
| Hardware | 128 GB+ RAM |
| Expected score | about 95/100 |
| Verdict | Best quality; expensive locally |

---

## Suggested next steps

1. Install LM Studio if needed.
2. Pick a model by RAM:
   - 16-24 GB: Qwen2.5-Coder-14B (Q4_K_M)
   - 24-32 GB: Qwen2.5-Coder-32B (Q4_K_M)
   - 32 GB+: Qwen2.5-Coder-32B (Q5_K_M)
3. Configure SQL Snippet Studio and run **SQL: Test LLM Connection**.
4. Walk through [docs/examples/llm_tasks/](../examples/llm_tasks/).
5. If results stay weak on MERGE/ROLLUP/SCD2, move up one model size or quant.

Optional hybrid: 14B for quick basic tasks, 32B for harder patterns.

---

## Resources

- [LM Studio docs](https://lmstudio.ai/docs)
- [Qwen on Hugging Face](https://huggingface.co/Qwen)
- [DeepSeek on Hugging Face](https://huggingface.co/deepseek-ai)
- [SQLCoder / Defog](https://huggingface.co/defog)
- [GGUF models](https://huggingface.co/models?library=gguf)
- [SQL-Eval](https://github.com/defog-ai/sql-eval)

## Related documentation

- [Local LLM setup](llm_feature.md)
- [LLM task examples](../examples/llm_tasks/)
- [MERGE task analysis](../examples/llm_tasks/merge_task_analysis.md)
- [Documentation index](../README.md)
