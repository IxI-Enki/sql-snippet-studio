## Learned User Preferences

- Create git commits only when explicitly asked.
- Do not delete git branches when merging or finishing work.
- Use lower_snake_case for directories and files.
- Run terminal commands in PowerShell 7; use [OK]/[ERROR]/[INFO]/[WARN] markers and avoid emojis, umlauts, and decorative ASCII in command output.
- Frame the product as a professional offline SQL tool; avoid test, exam, or cheat-kit language in user-facing docs.
- Keep README as a concise product overview; detailed guides belong under `docs/`.
- This is a personal Spaßprojekt shown on resume; omit license boilerplate wherever it is not technically required.

## Learned Workspace Facts

- VS Code/Cursor extension for offline SQL snippets (PostgreSQL/Oracle PL/SQL) with optional local LLM (LM Studio, Ollama).
- User-facing display name is SQL Snippet Studio (v2.0.0); package ID is `sql-snippet-studio` (extension ID `dbi-team.sql-snippet-studio`); `dbiSurvivalKit.*` config and command keys unchanged.
- Repository: github.com/IxI-Enki/dbi-test-survival-kit.
- Documentation lives under `docs/` (`guides/`, `changelogs/`, `archive/`); only root `README.md` is tracked markdown outside `docs/`.
- Local `test/` suite is gitignored and kept on disk only, not versioned.
- `_build.ps1` reads extension version and VSIX naming from `package.json`.
- graphify knowledge graph output lives in `graphify-out/`.
