# CAWT-BSZ

R replication pipeline for **Boll, Saez, and Zucman (2026)**, *California
Billionaires: Wealth, Taxes, and Wealth Tax Revenue Estimates* (NBER Working
Paper No. 35218).

This repository re-derives every cell of the authors' supplementary Excel
workbook in R via a [`{targets}`](https://docs.ropensci.org/targets/) pipeline,
verifies each derivation against the Excel-cached values element-wise, and
renders the paper's six tables and twelve figures plus a Quarto report.

## Reproduction status

| Layer | Source of truth | Status |
|---|---|---|
| Paper PDF | `original-materials/BSZ26CAbillionaires.pdf` | Tracked verbatim where quoted |
| Authors' supplementary workbook | `original-materials/BSZ_MainTablesFigures.xlsx` | **Required input. NOT redistributed in this repo** |
| Excel extractors | 16 `tar_target`s reading the workbook | Complete |
| R re-derivations | 8 `compute_*` functions, ~1,640 Excel formula cells | Complete; all verified within tolerance |
| Tables | 6 `gt` builders + HTML/LaTeX renders | Complete |
| Figures | 12 `ggplot` builders + PNG/PDF renders | Complete |
| Quarto report | `report.qmd` -> `report.{html,pdf}` | Complete |
| Primary-source cross-validation | SEC EDGAR / BEA / FTB / DINA | **Partial — see below** |
| Environment lock + CI | `renv.lock`, `.github/workflows/` | Not started |

## What is and is not in the repo

### Provided

- All R source (`R/*.R`), pipeline definition (`_targets.R`), tests
  (`tests/testthat/*`), and the Quarto report (`report.qmd`).
- The original paper PDF (`original-materials/BSZ26CAbillionaires.pdf`),
  included for quoting and section-structure reference.
- The SEC EDGAR cross-validation script and its findings document
  (`data-raw/sec/fetch_huang_2025.R`, `data-raw/sec/POC_findings.md`).

### NOT in the repo (must be obtained separately)

- **`original-materials/BSZ_MainTablesFigures.xlsx`** — the authors' Excel
  supplement. Every Excel extractor reads from this file. Without it the
  pipeline cannot run. The workbook is the authors' work and is not
  redistributed here; download it from:

  ```
  https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx
  ```

  Verified version (Last-Modified 2026-05-13):
  ```
  SHA-256  cffe04bd950fc63350ce4f084b9d6cdf9bc1e5a8ab6b80ca0ccebb4f796b7b1a
  ```

  Quick fetch + verify:
  ```sh
  curl -L -o original-materials/BSZ_MainTablesFigures.xlsx \
       https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx
  shasum -a 256 original-materials/BSZ_MainTablesFigures.xlsx
  # Expected: cffe04bd950fc63350ce4f084b9d6cdf9bc1e5a8ab6b80ca0ccebb4f796b7b1a
  ```
- **`outputs/`, `_targets/`, `data-raw/sec/cache/`, `report.{html,pdf}`** —
  generated artifacts. Gitignored. Rebuild via `targets::tar_make()`.

### Raw data sources that are NOT yet independently pulled

The Excel workbook combines several public and proprietary inputs.
Independent re-pulls from each primary source — to cross-check the workbook's
cached values — are an ongoing strand of this project. Status:

| Raw source | Workbook sheet it feeds | Status |
|---|---|---|
| SEC EDGAR Form 4 (insider transactions) | `data_sec_top4`, `data_sec_all`, `data_sec_agg` | **POC done** — Huang 2025 only. `sale` matches exactly; donation $ requires per-day stock close prices (deferred). Other top-4 billionaires and earlier years not yet pulled. |
| BEA SAGDP / SQGDP macro series (CA + US GDP, deflators) | `longrunseries` cols AS, AT, W | **Not pulled** |
| California FTB Personal Income Tax Statistics (B4A bracket detail) | `ftb_b4a` | **Not pulled** (workbook ships its own copy; data.ca.gov may have newer release) |
| Saez-Zucman DINA tables (US-wide + CA-wide effective tax rates) | `data_dina` (cols K, S) | **Not pulled** |
| IRS SOI Top .001% income statistics | `billionairesCAinctax` rows 59-72 | **Not pulled** (literal pass-through from authors' compilation) |
| Forbes Real-Time Billionaires snapshots | `shortrunseries` cols B, K, Q | **Not pulled** (no public historical archive) |
| ProPublica IRS leak | `data_sec_propublica` | **Cannot be re-pulled** — restricted-access data |
| Compustat (corporate financials feeding SEC top-4 columns) | parts of `data_sec_top4` | **Cannot be re-pulled here** — paywalled |

**Interpretation:** The R pipeline verifies that R reproduces the Excel
cells. The cross-validation work (in progress) verifies that the Excel
cells in turn reproduce the public raw data. Until that second layer is
complete, the replication is "faithful to the authors' workbook" but not
yet "independently sourced from underlying public data" for most series.

## Repository layout

```
CAWT-BSZ/
├── original-materials/
│   ├── BSZ_MainTablesFigures.xlsx        # REQUIRED — not in repo, see above
│   └── BSZ26CAbillionaires.pdf           # paper PDF (provided)
├── _targets.R                            # {targets} DAG
├── DESCRIPTION                           # package manifest (deps)
├── R/
│   ├── ingest_excel.R                    # helpers: read_sheet, list_sheets
│   ├── excel_cells.R                     # xls_cell, xls_cells_row, xls_cells_col
│   ├── verify.R                          # expect_matches_excel testthat helper
│   ├── data_sheets.R                     # 16 extract_* functions (read Excel)
│   ├── compute_data_sec_agg.R            # group-by aggregator (excludes Ellison)
│   ├── compute_pareto.R                  # Pareto extrapolation + Laffer sweep
│   ├── compute_tab5.R                    # one-time wealth-tax scoring (4 scenarios)
│   ├── compute_billionaires_ca_inctax.R  # 727-formula sheet (Method I + memos + all-taxes)
│   ├── compute_shortrunseries.R          # wealth-growth panel + 2025 snapshot
│   ├── compute_top4taxes.R               # 22-year per-billionaire tax-rate panel
│   ├── tables.R                          # 6 build_tab*_gt functions
│   ├── figures.R                         # 12 build_fig*_ggplot functions
│   └── render.R                          # render_table_*, render_figure_*, render_report
├── report.qmd                            # Quarto narrative report
├── tests/
│   ├── testthat.R                        # entry point
│   ├── snapshots/*.rds                   # 34 golden-master outputs (committed)
│   ├── snapshot_regenerate.R             # re-baseline script (run on intentional change)
│   └── testthat/                         # 506 expectations across 7 files
├── data-raw/
│   └── sec/
│       ├── fetch_huang_2025.R            # SEC cross-validation script
│       ├── POC_findings.md               # SEC cross-validation results
│       └── cache/                        # SEC XML downloads (gitignored)
└── outputs/                              # all generated artifacts (gitignored)
    ├── tables/                           # tab1..tab5, tab_a1 × {.html, .tex}
    └── figures/                          # fig1..fig8, fig_a1..fig_a4 × {.png, .pdf}
```

## Inputs and outputs (by `tar_target`)

### Excel extractors (16 targets, all read `BSZ_MainTablesFigures.xlsx`)

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

### R re-derivations (8 targets, `_r` suffix)

| Target | Verifies against | Tolerance |
|---|---|---|
| `data_sec_agg_r` | `data_sec_agg` cells | 1e-2 ($M scale, Excel 2-decimal rounding) |
| `pareto_missing_r` | `pareto_missing` cells (cols D-L) | 1e-6 |
| `pareto_summary` | I22-I24, J22-J23 of `Pareto-missing` | 1e-4..1e-8 |
| `tab5_r` | `Tab5` rows 6-9 (4 scenarios) | 1e-4 |
| `fig8_laffer_r` | `Fig8` rows 11-211 (201-row Laffer sweep) | 1e-6 |
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
# 1. Place the workbook here:
#    original-materials/BSZ_MainTablesFigures.xlsx

# 2. Install R packages:
Rscript -e 'install.packages(c(
  "targets", "tibble", "dplyr", "readxl", "cellranger",
  "gt", "ggplot2", "patchwork", "scales",
  "testthat", "xml2", "curl", "jsonlite",
  "pdftools"
))'

# 3. Install Quarto CLI (https://quarto.org/docs/get-started/).
#    On macOS:  brew install --cask quarto

# 4. Build the pipeline (all targets + Quarto report):
Rscript -e 'targets::tar_make()'

# 5. Run the test suite (506 expectations):
Rscript tests/testthat.R
```

To rebuild the data + tables + figures without rendering the (slow) Quarto report:

```sh
Rscript -e 'targets::tar_make(names = -c(report_html, report_pdf))'
```

## Verification approach

Every `compute_*` R function is paired with a `testthat` block that reads the
corresponding Excel sheet's cached values via `read_sheet()` (a thin
`readxl` wrapper) and asserts element-wise equality within a documented
tolerance. The test count is reported by `Rscript tests/testthat.R`:

```
compute:      215
data_sheets:   45
figures:       76
ingest_excel:  20
snapshots:     34       # pin exact output of every exhibit + compute_* fn
tables:       109
verify:         7
              ---
total:        506
```

The snapshot tests load `tests/snapshots/*.rds` (committed golden masters of
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
- It reproduces the paper's six tables and twelve figures, formatted for
  HTML / LaTeX / PNG / PDF.
- It does **not yet** independently re-fetch raw data from SEC EDGAR, BEA,
  FTB, DINA, IRS SOI, or Forbes — except for a one-entity-year SEC proof of
  concept (Huang 2025, sale matched exactly). Until that work is complete,
  any error in the Excel workbook would silently propagate through the
  whole pipeline.

## License and attribution

The code in this repository is provided under the MIT License (forthcoming).
The paper and supplementary materials in `original-materials/` belong to
their respective authors (Boll, Saez, Zucman 2026, NBER WP 35218); see
NBER's terms for re-use.
