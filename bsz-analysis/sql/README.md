# sql/: shared SQLite queries (phase 2)

These `.sql` files are the single source of truth for every step that touches
more than 1,000 rows. R and Python run the same file verbatim, so the two
pipelines cannot drift apart. The style follows the course
`sql-industry-prep` (see `module-05/exercise.sql`), and each block names the
course module it exercises, so the files double as worked examples.

## Where this fits: two steps from raw data to the paper

1. **Raw data to spreadsheet (phase 2, these files).** The confidential
   inputs the authors shared (Forbes real-time billionaire snapshots, Form 4
   filings, Compustat extracts and so on) to the data sheets behind the public
   workbook `BSZ_MainTablesFigures.xlsx`. The code is public; the data are not.
   What can be published is the comparison of our recomputed sheets with the
   public ones.
2. **Spreadsheet to results (phase 1, done in R).** The public workbook's data
   sheets to the paper's tables and figures (`_targets.R`, `R/`).

## Running a query

From `bsz-analysis/`, with the bundle in place (see `py/bundle_paths.py`;
set `BSZ_BUNDLE_DIR` if it lives elsewhere):

```sh
# 1. Build data-raw/bundle.sqlite from the bundle (about 15 s; gitignored).
#    Needs data-raw/residency-overrides.csv (gitignored, see the .example.csv).
python py/load_bundle.py

# 2a. Run query 1 from Python and export its tables to data-raw/sql-out/py/
python py/run_sql.py sql/01_rtb_ca.sql \
  --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate

# 2b. The same from R, exports to data-raw/sql-out/r/
Rscript R/run_sql.R sql/01_rtb_ca.sql \
  --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate

# 3. Compare with the answer keys and R vs Python; writes data-raw/sql-out/check_rtb_ca.md
python py/check_rtb_ca.py
```

You can also open the database in the sqlite3 CLI and run any block by hand:
`sqlite3 data-raw/bundle.sqlite`, then `.headers on`, `.mode column`, and
`SELECT * FROM rtb_ca_aggregate LIMIT 5;`.

R needs `DBI` and `RSQLite` (not in `DESCRIPTION`: phase 1 and CI do not use
them). `R/run_sql.R` only defines functions when sourced, so `_targets.R` and
`tests/testthat.R` are unaffected.

## Conventions

- **Confidential data never reach git.** The database (`*.sqlite`) and
  everything under `data-raw/sql-out/` are gitignored. The authors' code is
  not copied, and the public files do not describe it beyond what the SQL
  itself does. Private details (residency overrides, answer-key paths) live
  in gitignored files whose schemas are committed as `*.example.csv`.
- **Banner header, one `-- Q<n>. Title` block per step, CTEs, uppercase
  keywords, SQLite dialect**, as in the course.
- **No sqlite3 dot-commands** (`.headers`, `.mode`). Python runs a file with
  `sqlite3.Connection.executescript`, R statement by statement with
  `DBI::dbExecute`; dot-commands only work in the CLI.
- **Blocks create tables** (`DROP TABLE IF EXISTS x; CREATE TABLE x AS ...;`)
  instead of printing results, so both languages read the results back the
  same way.
- **Each block is tagged** with `-- Course: module N (...)`, with
  `-- Beyond the course:` for anything the five modules do not cover, and with
  the R idiom it replaces, described in general terms.
- **Loader conventions** (`py/load_bundle.py`): text and ISO dates are `TEXT`,
  money `REAL`, ids `INTEGER`; fields are trimmed of spaces as
  `readr::read_csv` does; empty cells become `NULL`, so `SUM` skips them as R's
  `na.rm = TRUE` does. `COALESCE(SUM(x), 0)` covers the all-missing case, where
  R returns 0 and SQL returns `NULL`.
- **Exports are deterministic**: each table has a fixed sort order, kept in
  step between `py/run_sql.py` and `R/run_sql.R`.

## Query 1: `01_rtb_ca.sql`, Forbes real-time billionaires to the CA lists

Reproduces the first part of the authors' build code for the Forbes
real-time billionaire data (confidential bundle): the seven year-end lists
of California billionaires, the 2026-01-01 industry table and the daily CA
aggregate.

Which ids count as California residents regardless of the Forbes state field
(and which never count) is decided by the residency override table,
`data-raw/residency-overrides.csv`. It is gitignored because its rows come
from the confidential bundle; `data-raw/residency-overrides.example.csv`
documents the schema. The only ids written in the SQL are the four the
paper's abstract names (the top 4). The answer-key files are located through
`data-raw/private-paths.csv`, also gitignored (schema in
`private-paths.example.csv`).

### Course map

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `rtb_ca_all` | Keeps billionaire-days with worth of at least $1 billion and California residence (Forbes state, plus the override table's includes, minus its excludes) | 1 (WHERE, AND / OR, NULL in comparisons), 4 (`IN (SELECT ...)`, `NOT IN (SELECT ...)`) | `DROP TABLE IF EXISTS`; `CREATE TABLE AS`; `CREATE INDEX` |
| Q2 `rtb_ca_eoy` | Stacks the seven year-end lists in one long table and adds `sec_cik` to the 2026-01-01 list | 1 (WHERE), 2 (LEFT JOIN) | `IN (...)` list; an extra condition in the `ON` clause of a `LEFT JOIN` |
| Q3 `rtb_ca_2026_01_01_industry` | Wealth by industry on 2026-01-01, shares of the total, and a Total row | 3 (GROUP BY), 4 (CTE chain, `UNION ALL` to stack rows), 5 (window `SUM(...) OVER ()`), 1 (`COALESCE`) | an empty `OVER ()` as the grand total; `ORDER BY` on a true/false expression to put Total last |
| Q4 `rtb_ca_aggregate` | Per date: count, total worth, top-4 worth and private worth, leaving out three snapshot dates | 3 (GROUP BY), 1 (`SUM(CASE WHEN ...)`) | `IN (...)` / `NOT IN (...)` lists |

### Check summary (from `py/check_rtb_ca.py`, 2026-10-07)

Every target matches. `py/check_rtb_ca.py` exits 0.

| Target | Compared | Max abs diff |
|---|---:|---:|
| Year-end lists, 2019 to 2024 and 2026-01-01 (vs the authors' private sheets) | 168, 175, 195, 175, 187, 197, 240 rows; same ids, same text | 1.8e-12 |
| Industry table (vs the private sheet, and vs public `rtb_2026_industry`) | 14 rows | 2.3e-13 |
| Daily aggregate (vs the private sheet, and vs the authors' own export of it) | 2,209 dates, counts equal | 1.1e-12 |
| Year-end counts and totals (vs public `data_sec_agg`, which feeds `shortrunseries` C and Q) | 7 years, counts equal | 0.0037, within the 2-decimal rounding of the cells |
| R vs Python exports | 1,337 + 14 + 2,234 rows | 0 |

The SQL has 25 more aggregate dates than the private sheet, which the check
reports without counting them as failures. `forbes_private_worth` is in
neither answer key, so only R vs Python parity checks it.

## Later queries (planned)

Form 4 raw to clean, Forbes 400 and global lists to the CA panel, the
Pitchbook venture monitor, and the Compustat-based steps. See
`PLAN-2-raw-to-workbook.md` at the repo root.
