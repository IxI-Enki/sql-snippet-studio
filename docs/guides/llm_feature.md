# Local LLM-assisted SQL suggestions

SQL Snippet Studio 2.0.1 can send the current SQL context and task comment to an OpenAI-compatible LM Studio endpoint. This feature is optional; all 67 snippets work offline without LM Studio or a token.

## Security model

- Store the LM Studio token through **SQL: Set LLM API Token**.
- The extension stores it in VS Code SecretStorage, not in `settings.json`.
- Never paste a token into documentation, source files, screenshots, logs, or workspace settings.
- Use **SQL: Clear LLM API Token** to remove the stored token.
- A legacy plaintext `sqlSnippetStudio.llm.apiKey` value may be imported only after explicit confirmation and must then be removed from user and workspace settings.

## Configure LM Studio 0.4+

1. Install LM Studio 0.4 or newer.
2. Download and load `qwen2.5-coder-32b-instruct`.
3. Open the Developer page and start the local server on port `1234`.
4. Enable LM Studio API-token authentication and create a new token.
5. In VS Code or Cursor, run **SQL: Set LLM API Token** and paste the token into the masked prompt.
6. Configure the non-secret settings:

```json
{
  "sqlSnippetStudio.llm.enabled": true,
  "sqlSnippetStudio.llm.endpoint": "http://localhost:1234/v1/chat/completions",
  "sqlSnippetStudio.llm.model": "qwen2.5-coder-32b-instruct",
  "sqlSnippetStudio.llm.autoCompletion": false
}
```

7. Run **SQL: Test LLM Connection**.

The manual request is the default: place the cursor below a task comment and press `Ctrl+Alt+Shift+Q`. Automatic completion is opt-in and remains disabled unless `sqlSnippetStudio.llm.autoCompletion` is set to `true`.

## Token-safe PowerShell health check

This PowerShell 7 check prompts for the token without displaying it and sends a Bearer header. It contains no real or example credential:

```powershell
$secureToken = Read-Host 'LM Studio API token' -AsSecureString
$token = [System.Net.NetworkCredential]::new('', $secureToken).Password
$headers = @{ Authorization = "Bearer $token" }

try {
    Invoke-RestMethod `
        -Method Get `
        -Uri 'http://localhost:1234/v1/models' `
        -Headers $headers
}
finally {
    $token = $null
    $headers = $null
    $secureToken.Dispose()
}
```

Prefer **SQL: Test LLM Connection** for routine checks because the token stays inside the extension's SecretStorage workflow.

## Request workflow

Keep the relevant schema and task in the same `.sql` file:

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    grade INTEGER
);

-- Task: Find all students with grade above 80
```

Place the cursor below the task, then press `Ctrl+Alt+Shift+Q`. Recognized task markers include:

```sql
-- Task: Write a JOIN query
-- TODO: Implement trigger
-- Question: How should results be aggregated by month?
```

The extension cleans and validates the returned SQL before insertion and caches validated responses.

## Settings

| Setting | Default | Purpose |
| ------- | -------------------- | ------- |
| `sqlSnippetStudio.llm.enabled` | `false` | Enable LLM requests |
| `sqlSnippetStudio.llm.endpoint` | `http://localhost:1234/v1/chat/completions` | OpenAI-compatible chat-completions endpoint |
| `sqlSnippetStudio.llm.model` | `qwen2.5-coder-32b-instruct` | Exact LM Studio model identifier |
| `sqlSnippetStudio.llm.autoCompletion` | `false` | Opt in to debounced automatic requests |
| `sqlSnippetStudio.llm.maxTokens` | `500` | Maximum generated tokens |
| `sqlSnippetStudio.llm.temperature` | `0.1` | Sampling temperature |
| `sqlSnippetStudio.llm.timeout` | `10000` | Request timeout in milliseconds |
| `sqlSnippetStudio.llm.verboseLogging` | `false` | Log parser and validation stages |
| `sqlSnippetStudio.llm.showNotifications` | `false` | Show LLM request notifications |

The token is intentionally absent from this table because it is not a setting.

## Troubleshooting

### 401 Unauthorized

1. Confirm authentication is enabled in LM Studio.
2. Create a new LM Studio token if the old token may have been exposed or revoked.
3. Run **SQL: Set LLM API Token** and enter the new token.
4. Run **SQL: Test LLM Connection**.

Do not add the token to `settings.json` as a workaround.

### Endpoint or connection error

1. Confirm the LM Studio server is running on port `1234`.
2. Confirm the endpoint is `http://localhost:1234/v1/chat/completions`.
3. Run the PowerShell health check above.
4. Check local firewall or proxy rules if `/v1/models` is unreachable.

### Model not found

Load `qwen2.5-coder-32b-instruct` in LM Studio and verify that the identifier returned by `/v1/models` exactly matches the configured value.

### No manual result

1. Confirm `sqlSnippetStudio.llm.enabled` is `true`.
2. Keep a recognized task comment and relevant schema in the active file.
3. Place the cursor below the task.
4. Press `Ctrl+Alt+Shift+Q`.
5. Run **SQL: Test LLM Connection** if the request still fails.

### Remove the stored token

Run **SQL: Clear LLM API Token**. LLM requests will remain unavailable until a token is stored again, while offline snippets continue to work.

## Related documentation

- [Quick start](quickstart.md)
- [Complete snippet reference](snippet_reference.md)
- [Setup guide](setup_guide.md)
- [LM Studio model recommendations](lm_studio_model_recommendations.md)
- [LLM task examples](../examples/llm_tasks/)
- [MERGE task analysis](../examples/llm_tasks/merge_task_analysis.md)
- [Documentation index](../README.md)
