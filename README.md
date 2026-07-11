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

## Install

**From VSIX (recommended for local use)**

1. Open **Extensions** in VS Code or Cursor
2. Choose **Install from VSIX…**
3. Select `sql-snippet-studio-2.0.0.vsix`
4. Reload the window when prompted

**From source**

```bash
npm install
vsce package
```

Install the generated `.vsix` the same way as above.

Step-by-step setup: [docs/guides/quickstart.md](docs/guides/quickstart.md)

## Snippet library

| File | Count | Focus |
| ---- | ----- | ----- |
| `postgres-snippets.json` | 22 | PostgreSQL-specific syntax |
| `oracle-snippets.json` | 25 | Oracle PL/SQL patterns |
| `shared-snippets.json` | 20 | Portable SQL (JOINs, CTEs, aggregates) |

Type a snippet prefix (for example `star-schema`) and press **Tab** to expand.

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

## Settings

Search **SQL Snippet Studio** in editor settings. Keys use the `sqlSnippetStudio.*` namespace (for example `sqlSnippetStudio.databaseDialect`, `sqlSnippetStudio.llm.enabled`).

## Author

[IxI-Enki](https://github.com/IxI-Enki) — [github.com/IxI-Enki/sql-snippet-studio](https://github.com/IxI-Enki/sql-snippet-studio)
