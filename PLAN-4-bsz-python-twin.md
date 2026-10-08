# opa-prop40: plan, phase 4 (BSZ step 2 in Python and SQL)

> Written 2026-10-07. The standing rule (`PLAN.md`, "Standing conventions"): every analysis runs in
> both R and Python, and any step on a dataset of more than 1,000 rows goes through shared `.sql`
> files that both languages run verbatim. The RJKDC side and the comparison layer meet it. The BSZ
> side's step 2 (the public workbook to the paper's tables, figures and the site) is R only. This
> phase closes that gap. Step 1's remaining raw-data queries are a later phase.

## Scope

Python twins, in `bsz-analysis/py/`, of every R function that computes something:

| R file | What it computes |
|---|---|
| `R/ingest_excel.R`, `R/excel_cells.R`, `R/data_sheets.R`, `R/vintage.R` | reading the workbook's sheets and cells (August vintage is the target; keep the vintage switch if cheap) |
| `R/compute_data_sec_agg.R` | yearly aggregates of `data_sec_all` (1,345 rows: SQL) |
| `R/compute_billionaires_ca_inctax.R` | the CA income tax estimate, including the FTB `2023-b-4a` table (1,657 rows: SQL for the step that reads it) |
| `R/compute_shortrunseries.R`, `R/compute_pareto.R`, `R/compute_top4taxes.R`, `R/compute_tab5.R` | the remaining computations |
| `R/site_exports.R` | the explorer grid (including `main_estimate`, `income_tax_loss_pv`), inputs table, leavers, Pareto exports |
| `R/tables.R`, `R/figures.R` | **the data frames** behind each table and figure only, not the gt or ggplot rendering |

Not in scope: `R/render.R`, `R/code_listing.R`, `R/verify.R` (R-side test helpers), `R/run_sql.R`
(already has its Python twin), the gt/ggplot styling.

## Rules

1. **SQL for the two large inputs.** `sql/02_data_sec_agg.sql` and `sql/03_ftb_b4a.sql` (names may
   differ), in the house style of `sql/01_rtb_ca.sql` and `~/Desktop/sandbox/courses/sql-industry-prep`:
   SQLite, banner header, `-- Q` blocks, CTEs, uppercase keywords, no dot-commands, `CREATE TABLE AS`,
   each block tagged with the course module it exercises. Both the R pipeline and Python run the same
   file. The input tables are loaded from the **public** workbook into a SQLite database under the
   gitignored `data-raw/` (a new loader function or script; never commit the database). The R pipeline
   switches the corresponding step to the SQL path, and its existing tests must still pass unchanged:
   the SQL result must equal the current R result.
2. **Parity.** A Python runner writes `export/py/` (or another clearly named directory) mirroring what
   the R side exports for the same targets, and a parity test (`tests/testthat/test-py-parity.R` and/or
   `py/test_parity.py`) compares every numeric output R vs Python at 1e-9 (or a stated tolerance with a
   reason). Snapshot tests in `tests/snapshots/august/` are the reference for figure and table data.
3. **Style.** Plain pandas + numpy (+ openpyxl for the workbook); no new heavy dependencies. Function
   names mirror the R names (`compute_tab5` -> `compute_tab5`). Each Python file opens with a comment
   naming its R twin. Comments explain the R idiom it mirrors where the translation is not obvious.
4. **No changes to published numbers.** `site/data/*.csv`, `site/explorer/grid.js` and the deck must
   be byte-identical after the work (regenerate and diff). If anything differs, stop and report.
5. **Repository hygiene.** Commit, never push. Commit only files you created or changed, with
   explicit paths (never `git add -A` or `git add .`): another session is editing `site/` pages in
   parallel. Do not edit anything under `bsz-analysis/site/`, `rjkdc-analysis/`, `comparison/` or the
   root `index.html`. No em-dash characters anywhere. Nothing from `original-materials/` is committed.
6. **Docs.** Update `bsz-analysis/py/README.md` and `bsz-analysis/sql/README.md` (course map for the
   new queries), and the BSZ `README.md` pipeline section, briefly.

## Acceptance

- `Rscript tests/testthat.R` (from `bsz-analysis/`) passes, including the new parity test.
- The Python runner reproduces every exported number; the parity report shows the max difference per
  output.
- `site/data/*.csv` and `site/explorer/grid.js` unchanged after `tar_make()`.
- `git grep` for em-dashes in new files prints nothing.

## Final report (under 250 words)

Files added per language, the SQL queries and their course modules, parity results (max diff per
output group), test results, anything not twinned and why, commit SHAs.
