# bsz-analysis

The BSZ side of [opa-prop40](../README.md). It began as the standalone CAWT-BSZ repository,
imported with its history.

R replication pipeline for **Boll, Saez, and Zucman (2026)**, *California
Billionaires: Wealth, Taxes, and Wealth Tax Revenue Estimates* (NBER Working
Paper No. 35218).

This repository re-derives every cell of the authors' supplementary Excel
workbook in R via a [`{targets}`](https://docs.ropensci.org/targets/) pipeline,
verifies each derivation against the Excel-cached values element-wise, and
renders the paper's six tables and the twelve figures of the May paper (August adds a
new Figure 8 and Appendix Figure A1, not built) plus a Quarto report.

## Reproduction status

| Layer | Source of truth | Status |
|---|---|---|
| Paper PDF | `original-materials/BSZ26CAbillionaires.pdf` | **Required input. NOT redistributed in this repo** |
| Authors' supplementary workbook | `original-materials/BSZ_MainTablesFigures.xlsx` (August, default) or `original-materials/may-2026/BSZ_MainTablesFigures.xlsx` (`BSZ_VINTAGE=may`) | **Required input. NOT redistributed in this repo** |
| Excel extractors | 14 `tar_target`s reading the workbook, one per sheet | Complete |
| R re-derivations | 8 `compute_*` functions, ~1,640 Excel formula cells | Complete; all verified within tolerance |
| Tables | 6 `gt` builders + HTML/LaTeX renders | Complete |
| Figures | 12 `ggplot` builders + PNG/PDF renders | Complete |
| Quarto report | `report.qmd` -> `report.{html,pdf}` | Complete |
| Primary-source cross-validation | SEC EDGAR / BEA / FTB / DINA | **Partial, see below** |
| CI | `../.github/workflows/bsz-ci.yml` | Rebuilds from a fresh workbook download (SHA-256 checked) and runs the full suite on every push touching `bsz-analysis/`; green |
| Environment lock | `renv.lock` | Not started; CI installs from `DESCRIPTION` |
| OPA site | `site/` (explorer, `repro.qmd`, slides, `materials.qmd`) | Complete; see `site/materials.qmd` |
| Export contract | `export/r/{inputs,outputs}.csv` (`R/export_contract.R`) | Complete; the only files `../comparison/` reads |

See `DATA-SOURCES.csv` for the full source manifest (one row per file, with provenance, terms
and SHA-256) and `DATA-SOURCES.md` for what the columns mean, including the `author-shared`
convention for raw data the paper's authors may share later.

## What is and is not in the repo

### Provided

- All R source (`R/*.R`), pipeline definition (`_targets.R`), tests
  (`tests/testthat/*`), and the Quarto report (`report.qmd`).
- The SEC EDGAR cross-validation script and its findings document
  (`data-raw/sec/fetch_huang_2025.R`, `data-raw/sec/POC_findings.md`).

### NOT in the repo (must be obtained separately)

Nothing under `original-materials/` is tracked; the whole directory is
gitignored. The pipeline reads two vintages of the authors' workbook, chosen
by the `BSZ_VINTAGE` environment variable (default `august`; set
`BSZ_VINTAGE=may` to use the May vintage instead) via `xlsx_path_default()`
in `R/ingest_excel.R`:

- **`original-materials/BSZ_MainTablesFigures.xlsx`** (August, default):
  every Excel extractor reads from this file unless `BSZ_VINTAGE=may` is set.
  Without it the default pipeline cannot run. Download from:

  ```
  https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx
  ```

  As of 2026-09-23 that URL serves the August vintage:
  ```
  SHA-256  c236cc9413374402973d61bfdfc02b7e573b05ad9c2f0658ee6b66ad898cb6ce
  ```

  Quick fetch + verify:
  ```sh
  curl -L -o original-materials/BSZ_MainTablesFigures.xlsx \
       https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx
  shasum -a 256 original-materials/BSZ_MainTablesFigures.xlsx
  # Expected: c236cc9413374402973d61bfdfc02b7e573b05ad9c2f0658ee6b66ad898cb6ce
  ```
- **`original-materials/may-2026/BSZ_MainTablesFigures.xlsx`**: the May 2026
  vintage of the same workbook, used when `BSZ_VINTAGE=may`. This is the
  version the CAWT-BSZ pipeline was originally built and tested against.

  ```
  SHA-256  cffe04bd950fc63350ce4f084b9d6cdf9bc1e5a8ab6b80ca0ccebb4f796b7b1a
  ```
- **`original-materials/BSZ26CAbillionaires.pdf`**: the paper PDF (August
  vintage), for quoting and section-structure reference. Not redistributed.

  ```
  SHA-256  ee1f2ea5a06c78ae0b9c3fbc6cc628f060ba7ee2c0f3363776b457c38d789fd9
  ```
- **`original-materials/may-2026/BSZ26CAbillionaires.pdf`**: the May 2026
  vintage of the paper PDF.

  ```
  SHA-256  cd8588edf529502560af81b18ba64663c5baa3539b804e3ed6d49eb3f4c50ffa
  ```
- **`original-materials/additional-documentation/`**: six supporting PDFs
  (legal and policy commentary by Galle, Gamage, Saez, Shanske and others,
  plus a response to Rauh et al.). Not redistributed; not read by the
  pipeline.
- **`outputs/`, `_targets/`, `data-raw/sec/cache/`, `report.{html,pdf}`**:
  generated artifacts. Gitignored. Rebuild via `targets::tar_make()`.

### Raw data sources that are NOT yet independently pulled

<!-- include:_raw-sources.md -->
The Excel workbook combines several public and proprietary inputs.
Independent re-pulls from each primary source (to cross-check the workbook's
cached values) are an ongoing strand of this project. Status:

| Raw source | Workbook sheet it feeds | Status |
|---|---|---|
| SEC EDGAR Form 4 (insider transactions) | `data_sec_top4`, `data_sec_all`, `data_sec_agg` | **POC done**: Huang 2025 only. `sale` matches exactly; donation $ requires per-day stock close prices (deferred). Other top-4 billionaires and earlier years not yet pulled. |
| BEA SAGDP / SQGDP macro series (CA + US GDP, deflators) | `longrunseries` cols AS, AT, W | **Not pulled** |
| California FTB Personal Income Tax Statistics (B4A bracket detail) | `ftb_b4a` | **Not pulled** (workbook ships its own copy; data.ca.gov may have newer release) |
| Saez-Zucman DINA tables (US-wide + CA-wide effective tax rates) | `data_dina` (cols K, S) | **Not pulled** |
| IRS SOI Top .001% income statistics | `billionairesCAinctax` rows 59-72 | **Not pulled** (literal pass-through from authors' compilation) |
| Forbes Real-Time Billionaires snapshots | `shortrunseries` cols B, K, Q | **Author-shared** daily snapshots; query 1 (`sql/01_rtb_ca.sql`) reproduces the CA lists and aggregate |
| ProPublica IRS leak | `data_sec_propublica` | **Cannot be re-pulled**: restricted-access data |
| Compustat (corporate financials feeding SEC top-4 columns) | parts of `data_sec_top4` | **Shared by the authors** under confidential terms; the extracts are not redistributable |

**Interpretation.** The R pipeline verifies that R reproduces the Excel
cells. The cross-validation work (in progress) verifies that the Excel
cells in turn reproduce the public raw data. Until that second layer is
complete, the replication is "faithful to the authors' workbook" but not
yet "independently sourced from underlying public data" for most series.
<!-- /include -->

<!--
The block above is auto-synced from _raw-sources.md. Do not edit by hand;
edit _raw-sources.md and run tools/sync-readme.sh to refresh.
-->


## Repository layout

```
bsz-analysis/
├── original-materials/                   # GITIGNORED, see above
│   ├── BSZ_MainTablesFigures.xlsx        # August (default vintage)
│   ├── BSZ26CAbillionaires.pdf           # August paper PDF
│   ├── may-2026/
│   │   ├── BSZ_MainTablesFigures.xlsx    # May vintage (BSZ_VINTAGE=may)
│   │   └── BSZ26CAbillionaires.pdf       # May paper PDF
│   └── additional-documentation/         # six supporting PDFs
├── _targets.R                            # {targets} DAG
├── VERIFY-AUGUST.md                      # the August re-verification: 10 root causes, fixes
├── DATA-SOURCES.csv, DATA-SOURCES.md     # source manifest with SHA-256 and terms
├── DESCRIPTION                           # package manifest (deps)
├── R/
│   ├── ingest_excel.R                    # helpers: read_sheet, list_sheets, xlsx_path_default
│   ├── vintage.R                         # everything that differs between May and August
│   ├── excel_cells.R                     # xls_cell, xls_cells_row, xls_cells_col
│   ├── verify.R                          # expect_matches_excel testthat helper
│   ├── data_sheets.R                     # 14 extract_* functions (read Excel)
│   ├── workbook_db.R                     # data_sec_all + FTB table into SQLite, runs sql/02, sql/03
│   ├── compute_data_sec_agg.R            # yearly aggregates via sql/02 (excludes Ellison)
│   ├── compute_pareto.R                  # Pareto extrapolation + Laffer sweep
│   ├── compute_tab5.R                    # one-time wealth-tax estimate (the explorer runs it too) + 4 scenarios
│   ├── compute_billionaires_ca_inctax.R  # 727-formula sheet (Method I + memos + all-taxes)
│   ├── compute_shortrunseries.R          # wealth-growth panel + 2025 snapshot
│   ├── compute_top4taxes.R               # 22-year per-billionaire tax-rate panel
│   ├── tables.R                          # 6 build_tab*_gt functions
│   ├── figures.R                         # 12 build_fig*_ggplot functions
│   ├── render.R                          # render_table_*, render_figure_*, render_report
│   ├── code_listing.R                    # code listings for the report
│   ├── site_exports.R                    # the site's data: dials, grid, input origins
│   └── export_contract.R                 # export/r/*.csv for the comparison layer
├── report.qmd                            # Quarto narrative report
├── tests/
│   ├── testthat.R                        # entry point
│   ├── snapshots/{august,may}/*.rds      # 34 golden-master outputs per vintage (committed)
│   ├── snapshot_regenerate.R             # re-baseline script (run on intentional change)
│   └── testthat/                         # the test files (counts: see Verification approach)
├── tools/site-test-results.R             # runs the suite, writes site/data/test-results.csv
├── tools/py-parity.R                     # R vs Python parity report, export/py/parity.csv
├── site/                                 # the OPA site: explorer/, repro.qmd, slides/, materials.qmd
├── export/r/                             # export contract read by ../comparison/
├── export/py/                            # the Python twin's outputs (py/run_export.py), for parity
├── sql/                                  # shared SQLite queries, run verbatim by R and Python
├── py/                                   # Python twin of step 2 + the step-1 query runners
├── data-raw/
│   └── sec/
│       ├── fetch_huang_2025.R            # SEC cross-validation script
│       ├── POC_findings.md               # SEC cross-validation results
│       └── cache/                        # SEC XML downloads (gitignored)
└── outputs/                              # all generated artifacts (gitignored)
    ├── tables/                           # tab1..tab5, tab_a1 × {.html, .tex}
    └── figures/                          # fig1..fig8, fig_a1..fig_a4 × {.png, .pdf}
```

## Pipeline execution flow

`targets::tar_make()` walks the DAG below in topological order. Each layer
reads from the layer above and writes new `tar_target`s consumed downstream.

```
                  original-materials/BSZ_MainTablesFigures.xlsx
                                  │
                                  │  xlsx_path  (format = "file")
                                  ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Excel extractors  (R/data_sheets.R, 14 tar_target's)            │
   │   data_sec_codebook   data_sec_top4   data_sec_all              │
   │   data_sec_agg        rtb_2026_industry   pareto_missing        │
   │   tab2   tab3   longrunseries   shortrunseries                  │
   │   data_dina   data_sec_propublica                               │
   │   billionaires_ca_inctax   ftb_b4a                              │
   └────────────────────────────────┬────────────────────────────────┘
                                    ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Shared SQL  (R/workbook_db.R, sql/02 + sql/03)                  │
   │   workbook_db  →  data-raw/workbook.sqlite (gitignored)         │
   │   data_sec_agg_r  ← sql/02_data_sec_agg.sql (data_sec_all)      │
   │   ftb_b4a_sql     ← sql/03_ftb_b4a.sql (the FTB table)          │
   └────────────────────────────────┬────────────────────────────────┘
                                    ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ R re-derivations  (R/compute_*.R, 7 tar_target's, _r suffix)    │
   │   pareto_missing_r,                                             │
   │   pareto_summary,                                               │
   │   fig8_laffer_r         ← compute_pareto.R                      │
   │   tab5_r                ← compute_tab5.R                        │
   │   billionaires_ca_inctax_r  ← compute_billionaires_ca_inctax.R  │
   │   shortrunseries_r      ← compute_shortrunseries.R              │
   │   top4taxes_r           ← compute_top4taxes.R                   │
   └────────────────────────────────┬────────────────────────────────┘
                                    ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Exhibits  (R/tables.R + R/figures.R, 18 builder tar_target's)   │
   │   tab1_gt .. tab5_gt   tab_a1_gt           (6 gt tables)        │
   │   fig1 .. fig8   fig_a1 .. fig_a4          (12 ggplots)         │
   │                                  │                              │
   │                                  ▼                              │
   │ Rendered files  (R/render.R, 36 file tar_target's)              │
   │   outputs/tables/tab*.html  outputs/tables/tab*.tex             │
   │   outputs/figures/fig*.png  outputs/figures/fig*.pdf            │
   └────────────────────────────────┬────────────────────────────────┘
                                    ▼
   ┌─────────────────────────────────────────────────────────────────┐
   │ Quarto report  (report.qmd, 2 file tar_target's)                │
   │   report_html  →  report.html                                   │
   │   report_pdf   →  report.pdf                                    │
   │   (depends explicitly on every gt + ggplot above; re-renders    │
   │    whenever any exhibit changes)                                │
   └─────────────────────────────────────────────────────────────────┘
```

Helper modules (loaded by `_targets.R` but not part of the DAG):

- `R/ingest_excel.R`: `read_sheet()`, `list_sheets()`, `xlsx_path_default()`.
- `R/excel_cells.R`: `xls_cell()`, `xls_cells_row()`, `xls_cells_col()`
  shared by the larger `compute_*` functions.
- `R/verify.R`: `expect_matches_excel()` testthat helper.

### The two large inputs go through SQL, and the whole step has a Python twin

The two inputs of more than 1,000 rows, `data_sec_all` (1,341 rows) and the
FTB table `2023-b-4a` (1,657 rows), are summarised by shared SQLite queries,
`sql/02_data_sec_agg.sql` and `sql/03_ftb_b4a.sql`, which R and Python run
verbatim. In the pipeline, target `workbook_db` loads both sheets into
`data-raw/workbook.sqlite` (gitignored) and runs the queries there;
`compute_data_sec_agg()` and `compute_billionaires_ca_inctax()` run the same
queries in memory when called directly, as the tests do.

`py/` holds a Python twin of every R file that computes something (same
function names; pandas, numpy, openpyxl). `python py/run_export.py` writes
`export/py/`: the export contract, the site data and one CSV per R snapshot.
`tests/testthat/test-py-parity.R` compares all of it with the R side at 1e-9
relative; the largest gap is about 5e-15 (`export/py/parity.csv`, written by
`Rscript tools/py-parity.R`). `site/explorer/grid.js` comes out byte-identical
from both languages. See `py/README.md` and `sql/README.md`.

## Inputs and outputs (by `tar_target`)

### Excel extractors (14 targets, all read `BSZ_MainTablesFigures.xlsx`)

| Target | Sheet | Notes |
|---|---|---|
| `data_sec_codebook` | `data_sec_codebook` | variable name -> definition -> data source |
| `data_sec_top4` | `data_sec_top4` | per-billionaire SEC panel (Page/Brin/Zuck/Huang/Ellison) |
| `data_sec_all` | `data_sec_all` | all CA billionaires SEC panel |
| `data_sec_agg` | `data_sec_agg` | year-aggregated SEC totals |
| `rtb_2026_industry` | `rtb_2026_industry` | first block: industry x metric |
| `pareto_missing` | `Pareto-missing` | rows 5-21 only |
| `tab2`, `tab3` | `Tab2`, `Tab3` | tier-1 named-column reads |
| `longrunseries` | `longrunseries` | positional dump (letter-named cols) |
| `shortrunseries` | `shortrunseries` | positional dump |
| `data_dina` | `data_dina` | positional dump |
| `data_sec_propublica` | `data_sec_propublica` | positional dump |
| `billionaires_ca_inctax` | `billionairesCAinctax` | positional dump |
| `ftb_b4a` | `2023-b-4a__adjusted_gross_incom` | FTB AGI brackets |

### R re-derivations (8 targets, `_r` suffix; `data_sec_agg_r` is read from the SQL step)

| Target | Verifies against | Tolerance |
|---|---|---|
| `data_sec_agg_r` | `data_sec_agg` cells | 1e-2 ($M scale, Excel 2-decimal rounding) |
| `pareto_missing_r` | `pareto_missing` cells (cols D-L) | 1e-6 |
| `pareto_summary` | I22-I24, J22-J23 of `Pareto-missing` | 1e-4..1e-8 |
| `tab5_r` | `Tab5` rows 6-9 (4 scenarios) | 1e-4 |
| `fig8_laffer_r` | `Fig8` (May) / `Fig9` (August) rows 11-211 (201-row Laffer sweep) | 1e-6 |
| `billionaires_ca_inctax_r` | `billionairesCAinctax` 727 formula cells | 1e-3 / 1e-2 |
| `shortrunseries_r` | `shortrunseries` 268 formula cells | 1e-3 / 1e-2 |
| `top4taxes_r` | `top4taxes` 429 formula cells | 1e-4 / 1e-2 |

### Tables (gt) and figures (ggplot)

| Target | Output files | Inputs |
|---|---|---|
| `tab1_gt` | `outputs/tables/tab1.{html,tex}` | `data_sec_agg_r`, `shortrunseries_r`, `longrunseries` |
| `tab2_gt` | `outputs/tables/tab2.{html,tex}` | `data_sec_agg_r`, `billionaires_ca_inctax_r`, `data_sec_top4` |
| `tab3_gt` | `outputs/tables/tab3.{html,tex}` | `data_sec_top4` |
| `tab4_gt` | `outputs/tables/tab4.{html,tex}` | `data_sec_top4` |
| `tab5_gt` | `outputs/tables/tab5.{html,tex}` | `tab5_r` |
| `tab_a1_gt` | `outputs/tables/tab_a1.{html,tex}` | `shortrunseries`, `longrunseries` |
| `fig1` | `outputs/figures/fig1.{png,pdf}` | `shortrunseries_r` |
| `fig2` | `outputs/figures/fig2.{png,pdf}` | `longrunseries` |
| `fig3` | `outputs/figures/fig3.{png,pdf}` | `shortrunseries_r` |
| `fig4` | `outputs/figures/fig4.{png,pdf}` | `billionaires_ca_inctax_r` |
| `fig5` | `outputs/figures/fig5.{png,pdf}` | `data_sec_top4` |
| `fig6` | `outputs/figures/fig6.{png,pdf}` | `top4taxes_r` |
| `fig7` | `outputs/figures/fig7.{png,pdf}` | `top4taxes_r`, `data_dina` |
| `fig8` | `outputs/figures/fig8.{png,pdf}` | `fig8_laffer_r` |
| `fig_a1` | `outputs/figures/fig_a1.{png,pdf}` | second block of `rtb_2026_industry` (read directly in builder) |
| `fig_a2` | `outputs/figures/fig_a2.{png,pdf}` | `shortrunseries_r` |
| `fig_a3` | `outputs/figures/fig_a3.{png,pdf}` | `billionaires_ca_inctax_r$all_taxes` |
| `fig_a4` | `outputs/figures/fig_a4.{png,pdf}` | `pareto_missing_r` |

### Quarto report

| Target | Output | Inputs |
|---|---|---|
| `report_html` | `report.html` | all `tab*_gt` + all `fig*` objects |
| `report_pdf` | `report.pdf` | same |

## How to reproduce

```sh
# 1. Place the workbook here (August, default vintage):
#    original-materials/BSZ_MainTablesFigures.xlsx
#    or, for the May vintage, here, and run with BSZ_VINTAGE=may:
#    original-materials/may-2026/BSZ_MainTablesFigures.xlsx

# 2. Install R packages:
Rscript -e 'install.packages(c(
  "targets", "tibble", "dplyr", "readxl", "cellranger",
  "gt", "ggplot2", "patchwork", "scales",
  "testthat", "xml2", "curl", "jsonlite",
  "pdftools", "DBI", "RSQLite"
))'

# 3. Install Quarto CLI (https://quarto.org/docs/get-started/).
#    On macOS:  brew install --cask quarto

# 4. Build the pipeline (all targets + Quarto report):
Rscript -e 'targets::tar_make()'

# 5. Run the test suite (counts: see Verification approach below):
Rscript tests/testthat.R
#    or, to also write site/data/test-results.csv for the materials page:
Rscript tools/site-test-results.R

# 6. The Python twin (Python 3.11 with pandas, numpy, openpyxl) and the
#    parity report; step 5 already runs the parity test on export/py/:
python py/run_export.py
Rscript tools/py-parity.R
```

To rebuild the data + tables + figures without rendering the (slow) Quarto report:

```sh
Rscript -e 'targets::tar_make(names = -c(report_html, report_pdf))'
```

## Verification approach

Every `compute_*` R function is paired with a `testthat` block that reads the
corresponding Excel sheet's cached values via `read_sheet()` (a thin
`readxl` wrapper) and asserts element-wise equality within a documented
tolerance. The counts below are from the last recorded run (`site/data/test-results.csv`,
written by `Rscript tools/site-test-results.R`, which also rewrites this block):

<!-- test-counts:start -->
```
compute:      215
data_sheets:   45
figures:       76
ingest_excel:  20
py-parity:     56
site:          48       # the explorer runs compute_tab5.R's estimating function; grid.js is the exporter's output
snapshots:     34       # pin exact output of every exhibit + compute_* fn
sql:           38
sql-steps:     18
sql-workbook:  41
tables:       121
verify:         7
              ---
total:        719       # August vintage, 2026-10-07, 114 test blocks across 12 files, 0 failed, 0 skipped
```
<!-- test-counts:end -->

The snapshot tests load `tests/snapshots/<vintage>/*.rds` (`august/` or `may/`; committed golden masters of
every Phase-2 R output and every Phase-3 exhibit) and assert byte-level
equality against the current pipeline. They catch any refactor that changes
a numeric value, even within Excel-rounding tolerance. Re-baseline only when
an output change is intentional:

```sh
Rscript tests/snapshot_regenerate.R
```

and commit the updated `.rds` files with an explanatory message.

If you see a different total, something has regressed or new tests were
added since this README.

## Status, in plain English

- The R pipeline reproduces the authors' Excel workbook exactly (modulo
  documented Excel display-rounding noise at 1e-2 on a few `data_sec_agg`
  columns).
- It reproduces the paper's six tables and the twelve figures of the May paper (August
  adds a new Figure 8 and Appendix Figure A1, not built), formatted for
  HTML / LaTeX / PNG / PDF.
- Known issues, disclosed rather than fixed: the workbook repeats rows 1338 to 1341 of
  `data_sec_all` at rows 1342 to 1345 (handled in `R/compute_data_sec_agg.R`; not yet reported
  to the authors), and Tables 1 and A1 still carry May wording in their labels over August
  values. See `VERIFY-AUGUST.md` and `site/materials.qmd`.
- It does **not yet** independently re-fetch raw data from SEC EDGAR, BEA,
  FTB, DINA, IRS SOI, or Forbes, except for a one-entity-year SEC proof of
  concept (Huang 2025, sale matched exactly). Until that work is complete,
  any error in the Excel workbook would silently propagate through the
  whole pipeline.

## License and attribution

The code in this repository is provided under the MIT License (forthcoming).
The paper and supplementary materials in `original-materials/` belong to
their respective authors (Boll, Saez, Zucman 2026, NBER WP 35218); see
NBER's terms for re-use.
