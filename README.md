---
title: SQL Snippet Studio
description: Offline SQL snippets and IntelliSense for PostgreSQL and Oracle PL/SQL — VS Code/Cursor extension with optional local LLM assistance.
dates:
  - created: 2025
  - updated: 2026-07-01
version: 2.0.0
status: published
author: IxI-Enki
tags: [ sql, vscode-extension, cursor-extension, postgresql, oracle, offline ]
repo: IxI-Enki/sql-snippet-studio
---

**Offline SQL snippets and IntelliSense for PostgreSQL and Oracle PL/SQL** — a VS Code / Cursor extension for writing database queries without depending on the web.

---

## What it is

SQL Snippet Studio is a lightweight extension that brings **67 SQL snippets**, **star-schema templates**, and **optional local LLM assistance** into your editor. Core features work fully offline; connect a local model (LM Studio, Ollama, etc.) only when you want AI-generated query suggestions.

---

## Origin

Originally built for a school database course; now a focused offline SQL companion for PostgreSQL and Oracle.

---

## Key features

- **67 snippets** — PostgreSQL (22), Oracle PL/SQL (25), and shared SQL patterns (20): JOINs, CTEs, window functions, MERGE, and more
- **Star-schema templates** — dimension tables, fact tables, and complete schemas via Tab completion or keyboard shortcuts
- **100% offline core** — no internet required for snippets and IntelliSense
- **Optional local LLM** — context-aware SQL suggestions from a local OpenAI-compatible endpoint
- **Snippet sharing** — export and import custom snippets with colleagues
- **Dialect support** — PostgreSQL, Oracle, or both (configurable)

---

## Quick install

1. Install from a `.vsix` package: **Extensions → Install from VSIX…** → reload the window.
2. Or build from source: `npm install` → `vsce package` → install the generated `.vsix`.

Step-by-step setup: **[Quickstart](docs/guides/quickstart.md)**

---

## Documentation

Full documentation lives under **[docs/](docs/README.md)**:

| Topic | Guide |
| ----- | ----- |
| Quick start | [docs/guides/quickstart.md](docs/guides/quickstart.md) |
| Setup & troubleshooting | [docs/guides/setup_guide.md](docs/guides/setup_guide.md) |
| Local LLM setup | [docs/guides/llm_feature.md](docs/guides/llm_feature.md) |

---

## Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `Ctrl+Alt+Shift+Q` | Query LLM for SQL solution |
| `Ctrl+Alt+Shift+S` | Insert star schema template |
| `Ctrl+Alt+Shift+D` | Insert dimension table |
| `Ctrl+Alt+Shift+F` | Insert fact table |
| `Ctrl+Alt+Shift+L` | Show LLM statistics |

---

**Author:** [IxI-Enki](https://github.com/IxI-Enki)
