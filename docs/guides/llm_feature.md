# LLM-assisted SQL suggestions

Optional AI-powered query suggestions for **SQL Snippet Studio**. Works with any OpenAI-compatible local endpoint (LM Studio, Ollama, etc.) or remote API.

---

## What it does

- Reads schema and task comments from your `.sql` file
- Sends context to a configured LLM
- Offers SQL as IntelliSense items or via `Ctrl+Alt+Shift+Q`
- Caches validated responses for faster repeat use

Core snippets work **without** LLM — enable this only when you want AI assistance.

---

## Setup

### Option A: Local LLM (recommended)

```bash
# Install LM Studio or Ollama
# Load a code model (e.g. qwen2.5-coder)
# Start server on localhost:1234

```

### Option B: Remote API

```json
{
  "dbiSurvivalKit.llm.endpoint": "https://api.openai.com/v1/chat/completions",
  "dbiSurvivalKit.llm.apiKey": "sk-..."
}

```

### Enable in VS Code / Cursor

1. `Ctrl + ,` → search **SQL Snippet Studio**
2. Enable **Llm: Enabled**
3. Configure endpoint and model:

```json
{
  "dbiSurvivalKit.llm.enabled": true,
  "dbiSurvivalKit.llm.endpoint": "http://localhost:1234/v1/chat/completions",
  "dbiSurvivalKit.llm.model": "qwen2.5-coder"
}

```

---

## Usage

### Workflow

```sql
-- Schema in the same file:
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    grade INTEGER
);

-- Task as a comment:
-- Task: Find all students with grade above 80

-- Place cursor below, press Ctrl+Alt+Shift+Q or use IntelliSense

```

Result:

```sql
SELECT * FROM students WHERE grade > 80;

```

### Recognized task comment formats

```sql
-- Task: Write a JOIN query
-- TODO: Implement trigger
-- Question: How to aggregate by month?

```

---

## Configuration

| Setting | Default | Description |
| ------- | ------- | ----------- |
| `dbiSurvivalKit.llm.enabled` | `false` | Enable LLM suggestions |
| `dbiSurvivalKit.llm.endpoint` | `http://localhost:1234/v1/chat/completions` | OpenAI-compatible URL |
| `dbiSurvivalKit.llm.model` | `qwen2.5-coder` | Model name |
| `dbiSurvivalKit.llm.apiKey` | `""` | API key (empty for local) |
| `dbiSurvivalKit.llm.maxTokens` | `500` | Max response tokens |
| `dbiSurvivalKit.llm.temperature` | `0.1` | Lower = more deterministic |
| `dbiSurvivalKit.llm.timeout` | `10000` | Request timeout (ms) |
| `dbiSurvivalKit.llm.verboseLogging` | `false` | Log parser and validation stages to the output channel |
| `dbiSurvivalKit.llm.showNotifications` | `true` | Show quality-score notifications after LLM insert |

---

## Advanced: response quality

When LLM assistance is enabled, the extension cleans and validates generated SQL before inserting it.

### Response cleaning

Multi-stage extraction turns varied model output into executable SQL:

1. **Remove reasoning blocks** — strips tags such as `<think>` and `<reasoning>`, plus leading explanation paragraphs.
2. **Extract from code blocks** — prefers ` ```sql ` fenced blocks, then generic fenced blocks.
3. **Locate SQL statements** — finds keywords (`SELECT`, `INSERT`, `UPDATE`, and others) through the closing semicolon.
4. **Final cleanup** — trims trailing explanation text, normalizes whitespace, and ensures a terminating semicolon.

### Validation and caching

Each generated query is checked for common syntax issues (unmatched parentheses or quotes, missing `FROM` on `SELECT`, and similar). A quality score from 0–100 is shown when notifications are enabled. Validated responses are cached so repeat requests stay fast.

### Debug settings

Enable verbose logging to inspect parser and validator output in the **SQL Snippet Studio - LLM** output channel:

```json
{
  "dbiSurvivalKit.llm.verboseLogging": true,
  "dbiSurvivalKit.llm.showNotifications": true
}
```

---

## Recommended models

| Model | Size | Notes |
| ----- | ---- | ----- |
| `qwen2.5-coder-7b` | 7B | Good balance of speed and quality |
| `codellama-13b` | 13B | Strong on complex queries |
| `deepseek-coder-6.7b` | 6.7B | Fast and compact |

---

## Troubleshooting

LLM not responding

```bash
curl http://localhost:1234/v1/models

```

No completion appears

1. Confirm `dbiSurvivalKit.llm.enabled` is `true`
2. Cursor is below the task comment
3. Schema is in the same file
4. Local server is running

Poor query quality

- Lower `temperature` (e.g. `0.0`)
- Increase `maxTokens` for longer queries
- Try a larger code model

---

## Related docs

- [guides/setup_guide.md](guides/setup_guide.md) — full installation guide
- [Documentation index](../README.md)
