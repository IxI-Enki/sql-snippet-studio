$$
\fcolorbox{navy}{white}{%
  $\begin{array}{c}\LARGE{%
    \textcolor{royalblue}{\texttt{\underline{%
      SQL Snippet Studio}}}} \\[1em]
    \scriptsize\textcolor{black}{\texttt{%
      Cursor \& VS Code extension}}
  \end{array}$
}$$

> <small>
> 
> *Offline SQL **snippets** and **IntelliSense** for PostgreSQL and Oracle PL/SQL in **Cursor** and **VS Code**, with **optional local LLM assistance**.*
> </small>

## Features

- **67 snippets** — PostgreSQL (22), Oracle PL/SQL (25), shared SQL patterns (20)
- **Star-schema templates** — dimension tables, fact tables, and complete schemas
- **Fully offline core** — snippets work without network access
- **Optional local LLM** — manual `Ctrl+Alt+Shift+Q` workflow with secure token storage
- **Snippet export** — copy bundled snippet JSON to a folder for sharing


---

### Local LLM Demo (LM Studio)

- slowed down for demonstration purposes 
  > (real-time speed at demo end)

<div align="center">

<video controls src="clips/local-llm-demo.mp4" title="LM Studio local LLM Demo" alt="LM Studio local LLM Demo Video" style="width: 66%;"></video>

</div>


---

## In the IDE (Cursor & VS Code)

### Settings

<details>
<summary><small>show</small> <u>Settings</u> & <u>Token configuration</u></summary>


<div style="font-size: 0.8em;">

Search **SQL Snippet Studio** in editor settings.

<div style="text-align: left; margin-left: 3rem; width: 66%;">

<blockquote class="warning">

⚠️ &nbsp; &nbsp; **API tokens** 
: are stored through <kbd>> SQL: Set LLM API Token</kbd>,
*not* as plain text in `settings.json`.

</blockquote>

</div>

<img src="images/settings.png" alt="SQL Snippet Studio settings panel" style="width: 88%; margin-left: 3rem;">

</div>
</details>

### Oracle snippet IntelliSense

Type an Oracle prefix (for example `ora-`) in `.sql` or `.plsql` file to open the snippet picker.

<details>
<summary><small>show</small> Oracle snippets <u>dropdown example</u></summary>

<div style="font-size: 0.8em; margin-left: 3rem;">

<img src="images/oracle-snippets.png" alt="Oracle PL/SQL snippet autocomplete in the editor" style="width: 66%">

</div>
</details>

## Full Snippet catalog <sup><small> ${{\scriptsize\boxed{\texttt{67}}}} $</small></sup>

Type a prefix and press **Tab**.

<div style="text-align: left; margin-left: 5rem; width: 66%;">

<blockquote class="info">

ℹ️ &nbsp; &nbsp; **Full reference**: [Snippet_Guide.md](docs/guides/snippet_reference.md)

</blockquote>

</div>

### Shared SQL and dimensional modeling <sup><small> ${{\scriptsize\boxed{\texttt{20}}}} $</small></sup>

<div style="text-align: left; margin-left: 5rem;">

<details>
<summary><small>show</small> All <u>Shared SQL & dimensional modeling</u> snippets</summary>

| Prefix | Description |
| -----: | ----------- |
| `star-schema` | Complete Star Schema with dimensions and fact table |
| `dim-table` | Dimension table with SCD Type 2 support |
| `fact-table` | Fact table with measures and FK references |
| `dim-time` | Standard time dimension table |
| `create-table` | CREATE TABLE with common constraints |
| `fk` | Foreign key constraint |
| `view-analytics` | Analytical view with aggregations |
| `idx-fk` | Index on foreign key column for performance |
| `sel` | Simple SELECT statement |
| `sel-join` | JOIN query with aliases |
| `sel-agg` | Aggregate query with GROUP BY and HAVING |
| `sel-sub` | SELECT with subquery |
| `sel-window` | Query with window function |
| `case` | CASE statement |
| `with-cte` | Common Table Expression (WITH clause) |
| `ins` | INSERT statement |
| `upd` | UPDATE statement |
| `del` | DELETE statement |
| `trans` | Transaction block with COMMIT/ROLLBACK |
| `comment-block` | Formatted comment block |

</div>

### PostgreSQL <sup><small> ${{\scriptsize\boxed{\texttt{22}}}} $</small></sup>

<div style="text-align: left; margin-left: 5rem;">

<details>
<summary><small>show</small> All <u>PostgreSQL</u> snippets</summary>

| Prefix | Description |
| -----: | ----------- |
| `pg-create-table` | PostgreSQL Table with SERIAL and update trigger |
| `pg-serial` | PostgreSQL SERIAL primary key |
| `pg-bigserial` | PostgreSQL BIGSERIAL primary key |
| `pg-jsonb` | PostgreSQL JSONB column |
| `pg-array` | PostgreSQL Array column |
| `pg-enum` | PostgreSQL CREATE ENUM type |
| `pg-matview` | PostgreSQL Materialized view |
| `pg-function` | PostgreSQL plpgsql function |
| `pg-trigger` | PostgreSQL Trigger with function |
| `pg-row-number` | PostgreSQL ROW_NUMBER window function |
| `pg-rank` | PostgreSQL RANK window function |
| `pg-upsert` | PostgreSQL UPSERT (ON CONFLICT) |
| `pg-series` | PostgreSQL Generate series of numbers |
| `pg-date-series` | PostgreSQL Generate date series |
| `pg-recursive` | PostgreSQL Recursive CTE |
| `pg-fts` | PostgreSQL Full-text search setup |
| `pg-explain` | PostgreSQL EXPLAIN ANALYZE for query performance |
| `pg-savepoint` | PostgreSQL Transaction with savepoint |
| `pg-idx-btree` | PostgreSQL BTREE index |
| `pg-idx-hash` | PostgreSQL HASH index |
| `pg-idx-gin` | PostgreSQL GIN index for arrays/JSONB |
| `pg-partition-range` | PostgreSQL Range partitioned table |

</details>
</div>

### Oracle PL/SQL <sup><small> ${{\scriptsize\boxed{\texttt{25}}}} $</small></sup>

<div style="text-align: left; margin-left: 5rem;">

<details>
<summary><small>show</small> All <u>Oracle PL/SQL</u> snippets</summary>

| Prefix | Description |
| -----: | ----------- |
| `ora-create-table` | Oracle table with sequence and triggers |
| `ora-sequence` | CREATE SEQUENCE (Oracle) |
| `ora-types` | Common Oracle data types |
| `ora-trigger-bi` | BEFORE INSERT trigger (Oracle) |
| `ora-trigger-bu` | BEFORE UPDATE trigger (Oracle) |
| `ora-procedure` | Oracle stored procedure |
| `ora-function` | Oracle function |
| `ora-package-spec` | Oracle package specification |
| `ora-package-body` | Oracle package body |
| `ora-cursor` | Oracle cursor with loop |
| `ora-for-cursor` | Oracle FOR loop with implicit cursor |
| `ora-bulk` | Oracle BULK COLLECT for performance |
| `ora-merge` | Oracle MERGE statement (UPSERT) |
| `ora-hierarchy` | Oracle hierarchical query (tree structure) |
| `ora-analytic` | Oracle analytic (window) function |
| `ora-with` | Oracle WITH clause (CTE) |
| `ora-exception` | Oracle exception handling block |
| `ora-dbms-output` | Oracle DBMS_OUTPUT for debugging |
| `ora-autonomous` | Oracle autonomous transaction |
| `ora-dynamic-sql` | Oracle dynamic SQL with EXECUTE IMMEDIATE |
| `ora-explain` | Oracle EXPLAIN PLAN for query analysis |
| `ora-idx-btree` | Oracle BTREE index (default) |
| `ora-idx-bitmap` | Oracle BITMAP index for low-cardinality columns |
| `ora-matview` | Oracle materialized view |
| `ora-partition-range` | Oracle partitioned table (RANGE) |

</details>
</div>

---

## Optional local LLM

<div style="text-align: left; margin-left: 5rem;">

<blockquote class="info">

ℹ️ &nbsp; &nbsp; **Full Local LLM guide**: [Detailed_Guide.md](docs/guides/Detailed_Guide.md)

</blockquote>

</div>

<div style="text-align: left; margin-left: 5rem;">
<br>

> <div style="font-size: 1.1em;"> 💡 <u>Example integration with LM Studio</u></div><br>
>
> **1.** &nbsp; Enable LM Studio API-token authentication and create a token
> **2.** &nbsp; Run **SQL: Set LLM API Token**
> **3.** &nbsp; Set `sqlSnippetStudio.llm.enabled` to `true`
> **4.** &nbsp; Load `qwen2.5-coder-32b-instruct` in LM Studio
> **5.** &nbsp; Run **SQL: Test LLM Connection**
> **6.** &nbsp; Place the cursor below `-- Task: ...` and press `Ctrl+Alt+Shift+Q`

</div>

---

## Keyboard shortcuts

<div style="text-align: left; margin-left: 5rem; width: 66%;">

| Shortcut | Command |
| -------: | ------- |
| `Ctrl+Alt+Shift+Q` | Query LLM for SQL solution |
| `Ctrl+Alt+Shift+S` | Insert star schema template |
| `Ctrl+Alt+Shift+D` | Insert dimension table |
| `Ctrl+Alt+Shift+F` | Insert fact table |
| `Ctrl+Alt+Shift+L` | Show LLM statistics |

</div>

---

## Install <sup><small> ${{\scriptsize\color{lightgray}{\texttt{(\color{lime}{\texttt{recommended}}\color{lightgray}{)}}}}}$</small></sup>

1. Download [`current_version/sql-snippet-studio-2.0.1.vsix`](current_version/sql-snippet-studio-2.0.1.vsix)
2. Open **Extensions** in VS Code or Cursor
3. Choose **Install from VSIX...** or drag and drop the `.vsix` file into the Extensions view
4. Reload the window when prompted

## Build from source <sup><small> ${{\scriptsize\color{lightgray}{\texttt{(\color{yellow}{\texttt{optional}}\color{lightgray}{)}}}}}$</small></sup>

<div style="text-align: left; margin-left: 5rem; width: 66%;">

```powershell
git clone https://github.com/IxI-Enki/sql-snippet-studio.git
Set-Location -LiteralPath .\sql-snippet-studio; npm ci; .\_build.ps1
```

</div>

---

## Documentation

<div style="text-align: left; margin-left: 5rem; width: 66%;">

| Topic | Guide |
| ----- | ----- |
| Quick start | [docs/guides/quickstart.md](docs/guides/quickstart.md) |
| Snippet reference | [docs/guides/snippet_reference.md](docs/guides/snippet_reference.md) |
| Setup and troubleshooting | [docs/guides/setup_guide.md](docs/guides/setup_guide.md) |
| Local LLM setup | [docs/guides/llm_feature.md](docs/guides/llm_feature.md) |
| Full docs index | [docs/README.md](docs/README.md) |

</div>

---

<div align="center">

## Maintainer

<table cellpadding="0" cellspacing="0" style="margin: 2rem auto 0; border-collapse: collapse; border: 6px solid #ffffff00; border-radius: 12px; box-shadow: 0 0 28px rgba(159, 199, 255, 0.24), inset 0 0.2em 0 2px rgba(255, 255, 255, 0.2); width: 400px;">
<tr>
<td colspan="2" style="height: 0.05rem; padding: 0; background: linear-gradient(90deg, #0d1117, #388bfd55 18%, #79c0ff 25% , #ffffff 50%, #79c0ff 75%, #388bfd55 82%, #0d1117); border-radius: 13px 13px 0 0;"></td>
</tr>
<tr>
<td style="padding-top: 0.5rem; margin-bottom: 0; vertical-align: middle; text-align: center; border-bottom: 2px solid #388bfd22;">

<a href="https://github.com/IxI-Enki" style="text-decoration: none; display: inline-block; line-height: 0;">
<img src="images/000_ixi_enki_cartouche.svg" alt="IxI-Enki on GitHub" height="54" style="display: block; margin: 0; pointer-events: none; border: 0;">
</a>

</td>
<!-- <td style="padding: 0.55rem 0.9rem 0.45rem 0.75rem; vertical-align: middle; text-align: center; width: 38%;"> -->
<a href="https://github.com/IxI-Enki" style="text-decoration: none; color: #8b949e;">
<!-- <img src="https://img.shields.io/badge/-GitHub-161b22?style=flat-square&logo=github&logoColor=58a6ff" alt="GitHub profile" height="28"> -->
</a>
</td>

</tr>
<tr>
<td colspan="2" style="padding: 0.7rem 1rem 0.85rem; border-top: 1px solid #21262d; text-align: left;">
<a href="https://github.com/IxI-Enki/sql-snippet-studio" style="text-decoration: none; color: #58a6ff; font-family: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas, monospace; font-size: 0.92rem; font-weight: 600;">SQL Snippet Studio</a>
<span style="display: block; margin-top: 0.35rem; color: #8b949e; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; font-size: 0.76rem; line-height: 1.5;">
<img src="images/signoff_vscode.svg" width="12" height="12" alt="" style="vertical-align: -2px;"> VS Code
<span style="color: #484f58;"> &#183; </span>
<img src="images/signoff_cursor.svg" width="12" height="12" alt="" style="vertical-align: -2px;"> Cursor
<span style="color: #484f58;"> &#183; </span>
offline snippets
<span style="color: #484f58;"> &#183; </span>
<img src="images/signoff_lmstudio.svg" width="12" height="12" alt="" style="vertical-align: -2px;"> LM Studio
</span>
</td>
<tr>
<td colspan="2" style="height: 1px; padding: 0; background: linear-gradient(90deg, #0d1117, #388bfd55 18%, #79c0ff 25% , #ffffff 50%, #79c0ff 75%, #388bfd55 82%, #0d1117); border-radius: 11px 11px 0 0;"></td>
</tr>
</table>

<table cellpadding="0" cellspacing="0" style="margin: 0.65rem auto 0; border-collapse: collapse;">
<tr>
<!-- <td style="text-align: center;">
<a href="https://github.com/IxI-Enki" style="text-decoration: none;">
<img src="https://img.shields.io/badge/IxI--Enki-GitHub_Profile-21262d?style=flat-square&logo=github&logoColor=e6edf3" alt="GitHub profile" height="22">
</a>
&nbsp;
<a href="https://github.com/IxI-Enki/sql-snippet-studio" style="text-decoration: none;">
<img src="https://img.shields.io/badge/SQL_Snippet_Studio-Repository-21262d?style=flat-square&logo=postgresql&logoColor=58a6ff" alt="Repository" height="22">
</a>
</td> -->

</tr>
</table>

</div>
