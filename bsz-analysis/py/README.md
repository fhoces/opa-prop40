# py/: the Python side of the BSZ analysis

The BSZ side runs in two steps (see `sql/README.md`). Both have Python code
here:

1. **Raw data to spreadsheet (step 1).** The confidential inputs the authors
   shared, through the shared `.sql` files, to the data sheets behind the
   public workbook. Python loads the bundle, runs the queries and checks the
   results (`bundle_paths.py`, `load_bundle.py`, `run_sql.py`,
   `check_common.py`, one `check_*.py` per query, `test_sql.py` for query 1
   and `test_sql_steps.py` for the later ones). One step of the Form 4 chain
   is a loop rather than SQL, with an R twin: `form4_basis.py` (and
   `R/form4_basis.R`), the capital-gains cost basis.
2. **Spreadsheet to results (step 2).** The public workbook
   `BSZ_MainTablesFigures.xlsx` to every number the R pipeline exports: the
   computations, the data behind each table and figure, the site data and the
   export contract. Each Python file is the twin of one R file, with the same
   function names; `run_export.py` runs them all and writes `export/py/`.

## Step 2 files

| File | R twin | What it does |
|---|---|---|
| `vintage.py` | `R/vintage.R` | The literals that differ between the May and August workbooks (`BSZ_VINTAGE`, default `august`). |
| `ingest_excel.py` | `R/ingest_excel.R` | Workbook path; positional sheet reads (`read_sheet`) with columns named by Excel letter and rows numbered as in the sheet. |
| `excel_cells.py` | `R/excel_cells.R` | `xls_cell`, `xls_cells_row`, `xls_cells_col`, and `to_num`, R's `as.numeric()` on a cell. |
| `data_sheets.py` | `R/data_sheets.R` | The `extract_*` readers: rectangular sheets with readxl's typing rules, positional sheets. |
| `workbook_db.py` | `R/workbook_db.R` | Loads `data_sec_all` and the FTB table into SQLite and runs `sql/02_data_sec_agg.sql` and `sql/03_ftb_b4a.sql` verbatim. |
| `compute_data_sec_agg.py` | `R/compute_data_sec_agg.R` | Yearly aggregates of `data_sec_all` (query 2). |
| `compute_billionaires_ca_inctax.py` | `R/compute_billionaires_ca_inctax.R` | The CA income tax estimate (Method I panel, memos, all-taxes block), reading the FTB table through query 3. |
| `compute_shortrunseries.py` | `R/compute_shortrunseries.R` | Wealth-growth panel, 2025 summary, growth table. |
| `compute_pareto.py` | `R/compute_pareto.R` | Pareto-missing sheet, its summary cells, the Laffer curve. |
| `compute_top4taxes.py` | `R/compute_top4taxes.R` | Top-4 tax rates 2004-2025 and the period averages. |
| `compute_tab5.py` | `R/compute_tab5.R` | Table 5: `tab5_scoring_inputs`, `score_tab5_cell`, `compute_tab5`. |
| `site_exports.py` | `R/site_exports.R` | The explorer grid (with `main_estimate`, `income_tax_loss_pv`), inputs table, leavers, Table 5 vs the printed paper, `grid.js`. |
| `export_contract.py` | `R/export_contract.R` | `inputs.csv` and `outputs.csv` of the export contract. |
| `tables.py` | `R/tables.R` | The data frames behind Tables 1-5 and A1 (not the gt styling). |
| `figures.py` | `R/figures.R` | The data frames behind Figures 1-8 and A1-A4 (not the ggplot rendering). |
| `run_export.py` | `_targets.R` | Runs everything and writes `export/py/`. |

Not twinned, on purpose: `R/render.R`, `R/code_listing.R` (rendering and the
report's code listings), `R/verify.R` (an R test helper) and the gt and
ggplot styling. `R/run_sql.R` already has its twin, `run_sql.py`.

## Usage

From `bsz-analysis/`, with the public workbook in `original-materials/`:

```sh
pip install -r requirements.txt   # numpy, openpyxl, pandas, pinned (Python 3.11)
python py/run_export.py        # about 2 s; writes export/py/ and data-raw/workbook-py.sqlite
Rscript tools/py-parity.R      # per-output max differences -> export/py/parity.csv
Rscript tests/testthat.R       # includes test-py-parity.R
BSZ_VINTAGE=may python py/run_export.py   # the May workbook (writes over export/py/)
```

`export/py/` is committed (like `rjkdc-analysis/export/py/`), so the parity
test also runs where Python is not installed. Re-run `py/run_export.py` after
changing either language. The May vintage reproduces the May snapshots too
(checked by hand; the committed export is August).

Step 1, with the confidential bundle in place:

```sh
python py/load_bundle.py                       # all tables, about 15 s
python py/load_bundle.py rtb_residency_overrides   # one table
python py/run_sql.py sql/01_rtb_ca.sql --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate
Rscript R/run_sql.R sql/01_rtb_ca.sql --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate
python py/check_rtb_ca.py
python -m pytest py/test_sql.py                # or: python py/test_sql.py

# Query 4, Form 4 raw to clean (same pattern for the later queries; the
# export list and the checker of each are in sql/README.md)
python py/run_sql.py sql/04_form4_clean.sql --export form4_clean
Rscript R/run_sql.R sql/04_form4_clean.sql --export form4_clean
python py/check_form4_clean.py
python -m pytest py/test_sql_steps.py          # or: python py/test_sql_steps.py
```

Needs Python 3.11 with `pandas`, `numpy` and `openpyxl`; the step-1 files
use only `openpyxl` and the standard library.

## Parity, in short

`tests/testthat/test-py-parity.R` compares every file in `export/py/` with
its R counterpart: the contract with `export/r/`, the site files with
`site/data/` and `site/explorer/grid.js`, and the exhibits with the R
snapshots in `tests/snapshots/august/`. The tolerance is 1e-9 relative
(`|python - r| <= 1e-9 * max(1, |r|)`). On 2026-10-07: 50 outputs, 53,855
numbers, largest gap 5e-15 relative; `grid.js` is byte-identical.

| Group | Outputs | Numbers | Max abs diff | Max rel diff |
|---|---:|---:|---:|---:|
| Export contract | 2 | 100 | 2.3e-12 | 1.6e-15 |
| Site data (incl. `grid.js`) | 8 | 48,294 | 5.0e-12 | 5.0e-15 |
| Computations, table and figure data | 40 | 5,461 | 5.8e-11 | 2.4e-15 |

The gaps come from three places, all around 1e-16 of the value: R parses the
workbook's 17-digit cell text with its own `strtod` (a few units in the last
place off at times), R's `mean()` adds a second correction pass, and numpy
sums pairwise.

## How the translation handles R idioms

- **1-based vectors.** Year-aligned R vectors become numpy arrays; R's
  `x[4]` (2021 in a 2018-based panel) is `x[3]`. The compute files keep the
  R index in a comment where it matters.
- **NA.** Missing numbers are `NaN`. `sum(x, na.rm = TRUE)` is `np.nansum`;
  a plain `sum()` of a short vector is a left-to-right loop, as in R.
- **Positional sheets.** R reads mixed columns as character and calls
  `as.numeric()`; `excel_cells.to_num()` does the same, and dates come back as
  Excel serial numbers, as readxl reports them.
- **Lists.** R's named lists become dicts; a data frame is a pandas data
  frame with the same column names and order.
- **`seq(0, 0.2, by = 0.001)`** is `0 + (0:n) * by`, not an accumulated
  `np.arange`, so the Laffer rates are the same doubles.
- **Signed zero.** `grid.js` writes `-0` where R does; the dial levels are
  floats so `-(0 * 0) * C` keeps its sign.

## Conventions

- **Nothing from the bundle is committed.** The databases and every step-1
  export are gitignored, and so are the residency override table and the
  answer-key paths (schemas in `data-raw/*.example.csv`). The step-1 check
  report prints counts, totals and maximum differences only.
- **Loader typing** (`load_bundle.py`, `workbook_db.py`): text and ISO dates
  `TEXT`, money `REAL`, ids and years `INTEGER`, missing values `NULL`.
- **Tests skip, never fail, without the data.**

## Query 1 check, in short

Every target matches the authors' private sheets and the public workbook to
about 1e-12 (the public `data_sec_agg` cells to their 2-decimal rounding), and
the R and Python exports are identical as numbers. The table is in
`sql/README.md`.
