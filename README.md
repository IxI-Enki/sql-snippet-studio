# SQL Snippet Studio

Offline SQL snippets and IntelliSense for PostgreSQL and Oracle PL/SQL in VS Code and Cursor — with optional local LLM assistance.

Originally built for a database course; now a focused offline SQL companion for day-to-day query work.

## Features

- **67 snippets** — PostgreSQL (22), Oracle PL/SQL (25), shared SQL patterns (20): JOINs, CTEs, window functions, MERGE, and more
- **Star-schema templates** — dimension tables, fact tables, and complete schemas via Tab completion or keyboard shortcuts
- **Fully offline core** — snippets and IntelliSense work without network access
- **Optional local LLM** — context-aware SQL suggestions from an OpenAI-compatible endpoint (LM Studio, Ollama, etc.)
- **Snippet sharing** — export and import custom snippets
- **Dialect support** — PostgreSQL, Oracle, or both (configurable in settings)

## In the editor

### Oracle snippet IntelliSense

Type an Oracle prefix (for example `ora-`) in a `.sql` or `.plsql` file to open the snippet picker. Each entry shows the trigger and a short description — select one and press **Tab** to expand.

![Oracle PL/SQL snippet autocomplete in the editor](images/oracle-snippets.png)

### Settings

Search **SQL Snippet Studio** in editor settings. All options use the `sqlSnippetStudio.*` namespace — dialect, completion, star-schema templates, and optional LLM integration in one place.

![SQL Snippet Studio settings panel](images/settings.png)

## Install

**From VSIX (recommended for local use)**

1. Open **Extensions** in VS Code or Cursor
2. Choose **Install from VSIX…**
3. Select `sql-snippet-studio-2.0.0.vsix`
4. Reload the window when prompted

**From source**

```powershell
Set-Location '<path-to-repo>'
npm install
npx @vscode/vsce package
```

Install the generated `.vsix` the same way as above.

Step-by-step setup: [docs/guides/quickstart.md](docs/guides/quickstart.md)

## Keyboard shortcuts

| Shortcut | Command |
| -------- | ------- |
| `Ctrl+Alt+Shift+Q` | Query LLM for SQL solution |
| `Ctrl+Alt+Shift+S` | Insert star schema template |
| `Ctrl+Alt+Shift+D` | Insert dimension table |
| `Ctrl+Alt+Shift+F` | Insert fact table |
| `Ctrl+Alt+Shift+L` | Show LLM statistics |

## Documentation

| Topic | Guide |
| ----- | ----- |
| Quick start | [docs/guides/quickstart.md](docs/guides/quickstart.md) |
| Setup and troubleshooting | [docs/guides/setup_guide.md](docs/guides/setup_guide.md) |
| Local LLM setup | [docs/guides/llm_feature.md](docs/guides/llm_feature.md) |
| Full docs index | [docs/README.md](docs/README.md) |

## Author

[IxI-Enki](https://github.com/IxI-Enki) — [github.com/IxI-Enki/sql-snippet-studio](https://github.com/IxI-Enki/sql-snippet-studio)
