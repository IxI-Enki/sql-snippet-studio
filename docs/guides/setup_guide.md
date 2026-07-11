# Setup guide - SQL Snippet Studio

## Requirements

- VS Code or Cursor
- PowerShell 7 only when using the optional command-line or source-build steps
- LM Studio 0.4+ only for optional local LLM assistance

## Install the release VSIX

1. Download [`sql-snippet-studio-2.0.1.vsix`](../../current_version/sql-snippet-studio-2.0.1.vsix).
2. Open **Extensions** in VS Code or Cursor.
3. Choose **Install from VSIX...** and select the file.
4. Run **Developer: Reload Window** from the Command Palette.

You can also install the same downloaded file from PowerShell 7:

```powershell
$vsixPath = Read-Host 'Path to sql-snippet-studio-2.0.1.vsix'
code --install-extension $vsixPath
```

## Verify the offline features

Create `example.sql` and verify these triggers with **Tab**:

| Trigger | Expected template |
| ------- | ----------------- |
| `create-table` | Shared CREATE TABLE |
| `star-schema` | Complete star schema |
| `pg-function` | PostgreSQL PL/pgSQL function |
| `ora-procedure` | Oracle stored procedure |

The [snippet reference](snippet_reference.md) lists all 67 canonical triggers.

## Editor configuration

The snippets normally appear in the suggestion list without extra configuration. If **Tab** does not expand a selected snippet, add:

```json
{
  "editor.tabCompletion": "on",
  "editor.snippetSuggestions": "top",
  "editor.suggest.showSnippets": true
}
```

## Optional local LLM

Offline snippets need no token. For local LLM suggestions, follow the [LM Studio guide](llm_feature.md). Tokens are set and cleared through commands backed by VS Code SecretStorage; do not place a token in `settings.json`.

## Optional source build

Use this route only for development:

```powershell
$repositoryPath = Read-Host 'Repository path'
Set-Location $repositoryPath
npm ci
npm run package
```

Install the generated `.vsix` through **Extensions > Install from VSIX...**.

## Troubleshooting

### Snippets do not appear

1. Use a supported SQL or PL/SQL editor.
2. Type the complete trigger.
3. Press `Ctrl+Space` to open suggestions.
4. Run **Developer: Reload Window**.
5. Confirm SQL Snippet Studio is enabled in the Extensions view.

### Tab does not expand a snippet

Set `"editor.tabCompletion": "on"`, select the snippet in the suggestion list, and press **Tab**.

### Reinstall version 2.0.1

```powershell
code --uninstall-extension IxI-Enki.sql-snippet-studio
$vsixPath = Read-Host 'Path to sql-snippet-studio-2.0.1.vsix'
code --install-extension $vsixPath
```

The old `dbi-team.dbi-test-survival-kit` ID belongs to pre-2.0 releases. Remove it only if it is still installed:

```powershell
code --uninstall-extension dbi-team.dbi-test-survival-kit
```

### LLM connection fails

Use the token-safe checks and status-specific guidance in [LLM troubleshooting](llm_feature.md#troubleshooting).

## Related documentation

- [Quick start](quickstart.md)
- [Complete snippet reference](snippet_reference.md)
- [Optional local LLM assistance](llm_feature.md)
- [Documentation index](../README.md)
