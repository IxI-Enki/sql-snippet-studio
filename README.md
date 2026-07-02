---
title: SQL Snippet Studio
description: Offline SQL snippets and IntelliSense for PostgreSQL and Oracle PL/SQL — VS Code/Cursor extension with optional local LLM assistance.
dates:
  - created: 2025
  - updated: 2026-07-01
version: 2.0.0
status: published
author:
  - name: Jan Ritt
    email: janritt.office@gmail.com
    location: Österreich
    github:
      handle: IxI-Enki
      userpage: 'https://github.com/IxI-Enki'
tags: [ sql, vscode-extension, postgresql, oracle, offline, dbi ]
repo: IxI-Enki/dbi-test-survival-kit
---

**Offline SQL snippets and IntelliSense for PostgreSQL and Oracle PL/SQL** — a VS Code / Cursor extension for writing database queries without depending on the web.

---

## What it is

SQL Snippet Studio is a lightweight extension that brings **300+ SQL snippets**, **star-schema templates**, and **optional local LLM assistance** into your editor. Core features work fully offline; connect a local model (LM Studio, Ollama, etc.) only when you want AI-generated query suggestions.

---

## Built for HTL DBI — useful beyond the classroom

Designed for database courses at HTL, but built as a daily SQL companion: offline snippets, star-schema templates, and optional local LLM work the same in class, internships, and professional projects. No emergency-kit vibe — just a focused snippet studio for PostgreSQL and Oracle.

---

## Key features

- **300+ snippets** — PostgreSQL, Oracle PL/SQL, and shared SQL patterns (JOINs, CTEs, window functions, MERGE, and more)
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
| LLM features (v1.6+) | [docs/guides/smart_llm_features.md](docs/guides/smart_llm_features.md) |
| Latest changes | [docs/changelogs/changelog_v2_0_0.md](docs/changelogs/changelog_v2_0_0.md) |

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
