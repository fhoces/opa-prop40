# py/: the Python side of phase 2

Phase 2 rebuilds the public workbook's data sheets from the confidential raw
inputs the authors shared. The heavy lifting is in shared `.sql` files
(`sql/`), which Python and R both run verbatim; the Python files here load
the data, run the queries, and check the results. Phase 1 (the workbook to
the paper's tables and figures) is in R and does not use these files.

## Files

| File | What it does |
|---|---|
| `bundle_paths.py` | Where things live: the bundle root (`BSZ_BUNDLE_DIR`, else `original-materials/author-shared/2026-09-23_bsz-replication-code-data/`), `data-raw/bundle.sqlite`, `data-raw/sql-out/`, the two gitignored private files (`residency-overrides.csv`, `private-paths.csv`), the public workbook. Raises an error naming the env var when the bundle is missing. |
| `load_bundle.py` | Builds `data-raw/bundle.sqlite`: the Forbes snapshots, the CIK crosswalk, and the residency override table. One loader function per table, registered in `LOADERS`; each drops and recreates its own table. A later query adds its inputs by adding one function. |
| `run_sql.py` | Runs a `.sql` file with `executescript` and exports named tables to `data-raw/sql-out/py/<table>.csv`, sorted, floats written with `repr`. |
| `check_rtb_ca.py` | Compares query 1's exports with the answer keys (the authors' private sheets and aggregate export, located through `data-raw/private-paths.csv`; the public workbook) and with the R exports. Writes `data-raw/sql-out/check_rtb_ca.md`; exit code 1 on any failing check. |
| `test_sql.py` | Row-count tests for query 1. Skips without the database. |

## Usage

From `bsz-analysis/`:

```sh
python py/load_bundle.py                       # all tables, about 15 s
python py/load_bundle.py rtb_residency_overrides   # one table
python py/run_sql.py sql/01_rtb_ca.sql --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate
Rscript R/run_sql.R sql/01_rtb_ca.sql --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate
python py/check_rtb_ca.py
python -m pytest py/test_sql.py                # or: python py/test_sql.py
```

Needs Python 3.11 with `openpyxl` (the loader and the checker read `.xlsx`
files); the rest is the standard library (`csv`, `sqlite3`).

## Conventions

- **Nothing from the bundle is committed.** The database and every export are
  gitignored, and so are the residency override table and the answer-key
  paths (schemas in `data-raw/*.example.csv`). The check report prints
  counts, totals and maximum differences only; it never prints a row of the
  private sheets. Rows of the public workbook may be printed.
- **Loader typing**: text and ISO dates `TEXT`, money `REAL`, ids `INTEGER`.
  Fields are trimmed of leading and trailing spaces and tabs, as
  `readr::read_csv` does by default (many `source` values in the Forbes CSV
  have a trailing space). Empty strings become `NULL`.
- **Tests skip, never fail, without the data**, so CI stays green. They are
  not wired into CI.

## Query 1 check, in short

Every target matches the authors' private sheets and the public workbook to
about 1e-12 (the public `data_sec_agg` cells to their 2-decimal rounding), and
the R and Python exports are identical as numbers. The table is in
`sql/README.md`.
