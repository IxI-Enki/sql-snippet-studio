# v2.0.0 - SQL Snippet Studio Rebrand

**Release Date:** 2026-06-16  
**Type:** MAJOR (User-facing rebrand + extension package ID change)  
**Priority:** HIGH (Product positioning)

---

## Summary

Version 2.0.0 renames the extension from **DBI Survival Kit** to **SQL Snippet Studio**. Display name, VSIX filename, and extension package ID change. Settings keys and command IDs are unchanged — only uninstall/reinstall is required if upgrading from a pre-v2 install.

---

## What changed

### Display and branding

| Area | Before | After |
| ---- | ------ | ----- |
| Display name | DBI Survival Kit | SQL Snippet Studio |
| Settings panel title | DBI Survival Kit | SQL Snippet Studio |
| Command palette prefix | `DBI:` | `SQL:` |
| Output channel | DBI Survival Kit - LLM | SQL Snippet Studio - LLM |
| Welcome / log messages | DBI Survival Kit | SQL Snippet Studio |

### Extension package ID (breaking for install path only)

| Field | Before | After |
| ----- | ------ | ----- |
| Extension ID | `dbi-team.dbi-test-survival-kit` | `dbi-team.sql-snippet-studio` |
| Package name | `dbi-test-survival-kit` | `sql-snippet-studio` |
| VSIX filename | `dbi-test-survival-kit-2.0.0.vsix` | `sql-snippet-studio-2.0.0.vsix` |

Uninstall the old extension ID before installing v2.0.0. Existing `settings.json` entries under `dbiSurvivalKit.*` continue to work without edits.

### Packaging

- Added `.vscodeignore` to exclude dev-only paths (`.cursor/`, `graphify-out/`, `test/`, `AGENTS.md`, etc.)
- VSIX size reduced by excluding non-runtime repository content

### Documentation

- Root `README.md` and active guides updated to SQL Snippet Studio
- New section: **Built for HTL DBI — useful beyond the classroom**
- Design spec: `docs/superpowers/specs/2026-06-16-rebrand-design.md`

### Icon

- `images/icon.svg`: removed survival-kit cross motif; updated aria-label
- `images/icon.png`: unchanged in this release (regenerate from SVG when tooling is available)

---

## What did NOT change (no settings migration required)

- Config keys: `dbiSurvivalKit.*`
- Command IDs: `dbiSurvivalKit.*`
- Keybindings: unchanged (`Ctrl+Alt+Shift+Q`, etc.)

---

## Upgrade

```powershell
code --uninstall-extension dbi-team.dbi-test-survival-kit
code --install-extension sql-snippet-studio-2.0.0.vsix
```

If you already installed an earlier v2.0.0 build under the old ID, uninstall both IDs before reinstalling:

```powershell
code --uninstall-extension dbi-team.dbi-test-survival-kit
code --uninstall-extension dbi-team.sql-snippet-studio
code --install-extension sql-snippet-studio-2.0.0.vsix
```

Or install the VSIX via **Extensions → Install from VSIX…** and reload the window.

---

## Package

**File:** `sql-snippet-studio-2.0.0.vsix`

Build:

```powershell
npm install
.\_build.ps1
# or: npx vsce package --no-dependencies
```

---

## Verification checklist

1. Extensions panel shows **SQL Snippet Studio** with ID `dbi-team.sql-snippet-studio`
2. Settings search finds **SQL Snippet Studio**; `dbiSurvivalKit.llm.enabled` still works
3. Command palette: type `SQL:` — all commands listed with new titles
4. Output panel: **SQL Snippet Studio - LLM** (when LLM logging enabled)
5. Keybindings unchanged

---

**Previous release:** [changelog_v1_8_7.md](changelog_v1_8_7.md)
