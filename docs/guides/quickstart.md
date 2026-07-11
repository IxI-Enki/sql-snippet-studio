# Quick start - SQL Snippet Studio

## Install version 2.0.1

1. Download [`sql-snippet-studio-2.0.1.vsix`](../../current_version/sql-snippet-studio-2.0.1.vsix).
2. In VS Code or Cursor, open **Extensions**.
3. Choose **Install from VSIX...** and select the downloaded file.
4. Run **Developer: Reload Window** from the Command Palette.

## Verify offline snippets

1. Create `example.sql`.
2. Type `star-schema`.
3. Press **Tab**.
4. Tab through the generated placeholders.

If no suggestion appears, press `Ctrl+Space`, select `star-schema`, and then check that `editor.tabCompletion` is set to `on`.

## Common triggers

| Trigger | Description |
| ------- | ----------- |
| `star-schema` | Complete Star Schema with dimensions and fact table |
| `dim-table` | Dimension table with SCD Type 2 support |
| `fact-table` | Fact table with measures and FK references |
| `sel-join` | JOIN query with aliases |
| `with-cte` | Common Table Expression (WITH clause) |
| `pg-function` | PostgreSQL plpgsql function |
| `ora-procedure` | Oracle stored procedure |

See the [complete reference](snippet_reference.md) for all 67 triggers and their canonical descriptions.

## Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `Ctrl+Alt+Shift+S` | Insert star schema |
| `Ctrl+Alt+Shift+D` | Insert dimension table |
| `Ctrl+Alt+Shift+F` | Insert fact table |
| `Ctrl+Alt+Shift+Q` | Manually query the optional LLM |
| `Ctrl+Alt+Shift+L` | Show LLM statistics |

The snippets remain fully functional without LM Studio or an API token. To enable local LLM suggestions, continue with the [LLM guide](llm_feature.md).

## More documentation

- [Setup and troubleshooting](setup_guide.md)
- [Complete snippet reference](snippet_reference.md)
- [Optional local LLM assistance](llm_feature.md)
- [Documentation index](../README.md)
