# Rebrand Design Spec: SQL Snippet Studio (v2.0.0)

**Date:** 2026-06-16
**Status:** Implemented — Option A (full package + extension ID rename)
**Branch:** `release/v2-rebrand`

---

## Decision

Rebrand the VS Code extension from **DBI Survival Kit** to **SQL Snippet Studio**.

| Field | Before (v1.8.x) | After (v2.0.0) |
| ----- | --------------- | -------------- |
| Display name | DBI Survival Kit | SQL Snippet Studio |
| Package `name` | `dbi-test-survival-kit` | `sql-snippet-studio` |
| Extension ID | `dbi-team.dbi-test-survival-kit` | `dbi-team.sql-snippet-studio` |
| VSIX filename | `dbi-test-survival-kit-*.vsix` | `sql-snippet-studio-*.vsix` |
| Version | 1.8.7 | 2.0.0 |
| Positioning | Emergency/cheat-tool vibe | Professional SQL snippet studio |

**User choice:** Option A — SQL Snippet Studio (Build click = go).

**Implementation note:** The original spec planned a non-breaking cosmetic rebrand (same package name and extension ID). The shipped v2.0.0 uses a clean package and extension ID rename while preserving `dbiSurvivalKit.*` settings and command keys so existing `settings.json` entries keep working after reinstall.

---

## Rationale

"Survival Kit" implies emergency, cheat-sheet, or test-hacking — misaligned with a legitimate offline SQL tool (300+ snippets, star-schema templates, optional local LLM). **SQL Snippet Studio** describes the core value, stays marketplace-neutral, and works beyond the classroom while DBI remains visible in keywords and description.

**Tagline context:** PostgreSQL and Oracle patterns — offline-first. Ideal for DBI courses and daily SQL work.

---

## Scope: v2.0.0

### Changed (user-visible and packaging)

- `package.json`: `name`, `displayName`, `description`, `version`, configuration `title`, command `title` prefix (`DBI:` → `SQL:`)
- Extension ID: `dbi-team.sql-snippet-studio` (derived from `publisher` + `name`)
- VSIX: `sql-snippet-studio-2.0.0.vsix`
- `src/extension.js`: logs, toasts, welcome message
- `src/llm/debugHelper.js`, `src/llm/llmProvider.js`: output channel name, log prefix
- `README.md`, `docs/README.md`, `docs/guides/*.md` (active guides only)
- `images/icon.svg`: aria-label, remove survival imagery
- `_build.ps1`: VSIX cleanup driven solely by `package.json` `name`

### Unchanged (intentional)

| Item | Value | Reason |
| ---- | ----- | ------ |
| Config namespace | `dbiSurvivalKit.*` | Preserve existing `settings.json` |
| Command IDs | `dbiSurvivalKit.*` | Preserve keybindings and scripts |
| Publisher | `dbi-team` | No publisher migration in v2.0 |
| Git repository URL | `github.com/IxI-Enki/dbi-test-survival-kit` | Repo folder name not renamed |
| Historical changelogs | `docs/changelogs/changelog_v1_*.md` | Accurate version history |
| Archive docs | `docs/archive/*` | Historical reference |
| v1.8.4 hotfix guide | `docs/guides/deployment_instructions_v1_8_4.md` | Version-specific accuracy |

---

## Migration note for users

Upgrading from v1.8.x requires **uninstall of the old extension ID** and **install of the new VSIX**. Settings keys (`dbiSurvivalKit.*`) and keybindings are unchanged — no manual settings migration.

```powershell
code --uninstall-extension dbi-team.dbi-test-survival-kit
code --install-extension sql-snippet-studio-2.0.0.vsix

```

If both IDs are present after a partial upgrade:

```powershell
code --uninstall-extension dbi-team.sql-snippet-studio
code --uninstall-extension dbi-team.dbi-test-survival-kit
code --install-extension sql-snippet-studio-2.0.0.vsix

```

Full migration table: `docs/changelogs/changelog_v2_0_0.md`.

---

## Release artifacts

- Changelog: `docs/changelogs/changelog_v2_0_0.md`
- VSIX: `sql-snippet-studio-2.0.0.vsix` (name tied to `package.json` `name`)
- Build: `_build.ps1` or `npm install` + `vsce package`

---

## Future (out of scope for v2.0)

- Rename Git repository from `dbi-test-survival-kit` to `sql-snippet-studio` (optional; URL in `package.json` would follow)
- Migrate config namespace to `sqlSnippetStudio.*` (breaking; only if a clean settings break is desired in a future major)
