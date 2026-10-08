# sql/: shared SQLite queries

These `.sql` files are the single source of truth for every step that touches
more than 1,000 rows. R and Python run the same file verbatim, so the two
pipelines cannot drift apart. The style follows the course
`sql-industry-prep` (see `module-05/exercise.sql`), and each block names the
course module it exercises, so the files double as worked examples.

## Where this fits: two steps from raw data to the paper

1. **Raw data to spreadsheet (step 1, queries 1 and 4 onward).** The confidential
   inputs the authors shared (Forbes real-time billionaire snapshots, Form 4
   filings, Compustat extracts and so on) to the data sheets behind the public
   workbook `BSZ_MainTablesFigures.xlsx`. The code is public; the data are not.
   What can be published is the comparison of our recomputed sheets with the
   public ones.
2. **Spreadsheet to results (step 2, queries 2 and 3).** The public workbook's
   data sheets to the paper's tables and figures, in R (`_targets.R`, `R/`)
   and in Python (`py/run_export.py`). Two inputs have more than 1,000 rows,
   `data_sec_all` and the FTB table `2023-b-4a`; queries 2 and 3 summarise
   them, and the rest of step 2 works on the results.

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

R needs `DBI` and `RSQLite`, which are in `DESCRIPTION` (step 2 uses them).
`R/run_sql.R` only defines functions when sourced, so `_targets.R` and
`tests/testthat.R` are unaffected.

Queries 2 and 3 need only the public workbook and run as part of step 2:
`Rscript -e 'targets::tar_make()'` (target `workbook_db`, file
`data-raw/workbook.sqlite`) and `python py/run_export.py`
(`data-raw/workbook-py.sqlite`). Both databases are gitignored. The loaders
are `write_workbook_tables()` in `R/workbook_db.R` and its twin in
`py/workbook_db.py`.

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

## Query 2: `02_data_sec_agg.sql`, `data_sec_all` to the yearly aggregates

Recomputes the public sheet `data_sec_agg` from `data_sec_all` (1,341 rows
with a year and an id, August vintage): per year, the number of California
billionaires and 27 sums in $ billion. Before the sums, the ids on the
exclusion table (Ellison) are dropped, and so are exact re-pastes: August's
sheet repeats four 2025 rows at its tail, and a row counts as a copy when an
earlier row has the same year, id and worth.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `data_sec_all_kept` | Drops the excluded ids, then numbers the copies of each (year, id, worth) in sheet order and keeps the first | 4 (CTE chain, `NOT IN (SELECT ...)`), 5 (`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`) | `DROP TABLE IF EXISTS`; `CREATE TABLE AS` |
| Q2 `data_sec_agg` | Count and 27 sums per year, $ million to $ billion | 3 (GROUP BY with `COUNT` and `SUM`), 1 (`COALESCE`) | |

Check (`tests/testthat/test-sql-workbook.R`): the query reproduces the dplyr
code it replaced, counts identical and sums to 1e-12 (SQLite adds doubles
with a compensated sum, R one by one), also with an empty exclusion list.

## Query 3: `03_ftb_b4a.sql`, the FTB table to yearly totals and top brackets

The workbook copies FTB table B-4A (California resident returns by AGI
bracket, 59 or 60 brackets per year, 1995 to 2022) into sheet
`2023-b-4a__adjusted_gross_incom`. The billionairesCAinctax estimate needs
each year's totals (returns, CA AGI, taxable income, tax) and the rows of the
top brackets ($5M and over; from 2021 split at $10M). The R code used to
address both by sheet row numbers; the query selects them by the sheet's own
year and bracket-label columns.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `ftb_b4a_year` | Totals of the four columns over all brackets, per taxable year, with the bracket count | 3 (GROUP BY with `COUNT` and `SUM`), 1 (`WHERE ... IS NOT NULL`, `COALESCE`) | |
| Q2 `ftb_b4a_top` | The top-bracket rows with a short key (`5m_plus`, `5m_to_10m`, `10m_plus`) | 4 (CTE), 1 (`CASE WHEN`, `IN (...)` list) | `REPLACE` to normalise the labels' double spaces |

Check (`tests/testthat/test-sql-workbook.R`): for 2018 to 2022 the query
groups exactly the sheet rows the old row map used (59 or 60 per year, sums
identical) and picks the same top-bracket rows.

## Query 4: `04_form4_clean.sql`, Form 4 filings raw to clean

The first query of the Form 4 chain. SEC Form 4 is the form on which company
insiders report their trades. The authors scraped every Form 4 filed by the
California billionaires on their list and clean the transactions into one row
each, with the dollar amount of open-market sales and purchases and the
filer's Forbes id. Later steps join these rows to daily share prices and sum
them by person and year (the sale and purchase columns of `data_sec_all`).

Private inputs: one per-filing correction table,
`data-raw/form4-price-corrections.csv` (gitignored; schema in
`form4-price-corrections.example.csv`), for the few filings whose reported
price per share is off by a power of ten.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `form4_dedup` | Keeps single-owner filings, then drops a transaction that repeats an earlier one on every column but the accession number | 1 (WHERE), 4 (CTE), 5 (`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`) | a partition over 89 columns; `CREATE TABLE AS` |
| Q2 `form4_clean` | Drops foundation and advocacy holdings, computes sale and purchase amounts, applies the price corrections, adds the year and the Forbes id | 1 (`LIKE`, `IS NULL`, `CASE WHEN`), 2 (LEFT JOIN), 4 (CTE chain, `IN (SELECT ...)`) | `printf('%.15g', x)` to match a number written as text; `CAST(substr(...))` for the year |

Check (`py/check_form4_clean.py`, 2026-10-07): 198,719 rows, as in the
authors' clean file; every number and text cell equal (max relative
difference 0). The Forbes id differs on 34 rows of one filer, a vintage gap:
the CIK crosswalk in the bundle no longer maps that filer, so the query
leaves the id NULL where the authors' file still has one. R and Python
exports are identical.

## Query 5: `05_forbes_ca_panel.sql`, Forbes lists to the California panel 2004-2025

One row per California billionaire and year. 2019 to 2025 come from query
1's year-end real-time lists (so run `01_rtb_ca.sql` first); 2005 to 2018
from the Forbes 400 filtered to California; non-US citizens (2004 to 2018)
and the 2004 US list from the Forbes global lists, kept when the name matches
a California Forbes id. Before 2010 the Forbes 400 has no ids, so names are
matched to ids through the pairs seen elsewhere, then through a table of
hand-made fixes, `data-raw/forbes-name-ids.csv` (gitignored; schema in
`forbes-name-ids.example.csv`), which also maps ids Forbes renamed.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `forbes_rtb_panel` | The 2019 to 2025 rows from query 1, the 2026-01-01 list as 2025 | 1 (`CASE WHEN`) | `CAST(substr(...))`; `ROW_NUMBER() OVER (ORDER BY ...)` as a row counter |
| Q2 `forbes400_ca` | Forbes 400 California rows, two years rescaled, 2005 to 2009 matched to ids by name, a fix overriding a match | 1 (WHERE, `CASE WHEN`), 2 (LEFT JOIN), 4 (CTE chain, `UNION`, `UNION ALL`) | `COALESCE` over two joins ("the fix wins, else the match") |
| Q3 `forbes_name_id_pairs` | Distinct name-id pairs for matching the global lists | 4 (`UNION`), 1 (`IS NOT NULL`) | |
| Q4 `forbes_ca_2004_2025` | Global-list rows that match a CA id, plus the Forbes 400 and real-time rows, renamed ids mapped, sorted by year and worth | 1 (`ROUND`, `CASE WHEN`), 2 (LEFT JOIN), 4 (CTE chain, `UNION ALL`) | `REPLACE` and `CAST` to read "2.5 B" as a number; `CAST(NULL AS ...)` to type a column in a `UNION ALL`; a tie-break column for a stable sort |

Check (`py/check_forbes_ca_panel.py`, 2026-10-07): 2,726 rows. Against the
authors' panel (file and private sheet), 2004 to 2018 are equal row for row
(max relative difference 4e-15) and so are 2019 to 2025 except one vintage
gap: the authors' panel was built from year-end lists written before
larry-ellison joined the residency exclude list, so it has his 7 rows for
2019 to 2025 and ours does not. The (year, worth) order is the same. The 2019
to 2025 rows equal the public `data_sec_all` (year, `forbes_id`,
`forbes_worth`; 1,336 id-years, max difference 0), which follows the current
rule. R and Python exports are identical.

## Query 6: `06_venture_monitor.sql`, PitchBook venture monitor to annual and quarterly panels

Venture capital deals (count and $ value) per US state from the quarterly
PitchBook-NVCA Venture Monitor workbooks, to per-state tables and to US,
California and rest-of-US sums per year (2006 to 2026) and per quarter (2018
Q1 to 2026 Q2). The sums are the public sheets `data_venturemonitor_annual`
and `data_venturemonitor_quarterly`.

The loader is the lesson here. Over 35 workbooks the sheet is renamed, the
header row moves, the years shown change, and the count and value blocks
swap places. `load_vm_state_cells()` in `py/load_bundle.py` finds the sheet,
the header row, the two blocks and which block is which (from the title above
it), and writes one row per cell; the reshaping is SQL. Quarterly figures are
year-to-date in the source, so a quarter is a `LAG` difference.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| Q1 `vm_cells_paired` | Puts each cell's count and value side by side (a pivot by self-join) and keeps pairs with both numbers | 2 (INNER JOIN), 1 (`IS NOT NULL`) | joining a table to itself |
| Q2 `vm_annual_state` | Deals per state and year from two workbooks | 1 (WHERE, `NOT IN`), 4 (`UNION ALL`) | |
| Q3 `vm_annual` | Per year: all states, California, rest of US; values in $ billion | 3 (GROUP BY, `SUM`), 1 (`SUM(CASE WHEN ...)`, `COALESCE`) | |
| Q4 `vm_quarterly_state` | Each workbook's own-year column, then this quarter minus the previous one within state and year | 4 (CTE), 5 (`LAG ... OVER (PARTITION BY ... ORDER BY ...)`) | `LAG`'s default argument (0 for the first quarter) |
| Q5 `vm_quarterly` | Per quarter sums, as Q3 | 3 (GROUP BY two columns), 1 (`SUM(CASE WHEN ...)`) | |

Check (`py/check_venture_monitor.py`, 2026-10-07): 1,098, 21, 1,830 and 34
rows, as in the authors' four outputs; max relative difference 4.1e-15.
The annual and quarterly sums and the California shares equal the public
sheets (21 and 34 rows, 3e-15). R and Python exports are identical.

## Queries 7 and 8: Form 4 trades to Compustat daily prices

`07_form4_gvkey_link.sql` links each Form 4 issuer (SEC CIK and ticker) to a
Compustat security (gvkey and iid): by CIK and ticker, then by CIK alone
(preferring a security whose Compustat years overlap the issuer's Form 4
years), then through a gitignored table of hand-checked fixes,
`data-raw/form4-gvkey-fixes.csv` (schema in the `.example.csv`). Its last
table lists the linked gvkeys. The daily price file is 11 GB of text, so
`python py/load_bundle.py comp_daily_form4` streams it and keeps only those
securities (about 1 million of 108 million rows, in under a minute).
`08_form4_compustat.sql` then gives each trade the closing price, shares
outstanding and split factor of its security on the trade date, or on the
next trading day with a row when the date has none.

Order: `04_form4_clean.sql`, `07_form4_gvkey_link.sql`, the
`comp_daily_form4` loader, `08_form4_compustat.sql`.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| 07 Q1 `form4_sec_issuers` | One row per issuer: last name and ticker in file order, first and last year | 3 (GROUP BY, `MIN`, `MAX`), 4 (CTE), 5 (`ROW_NUMBER ... ORDER BY ... DESC` for "last") | `UPPER`; `CAST` of text with leading zeros |
| 07 Q2 `form4_comp_secs` | One row per USD Compustat security, with the values of its oldest snapshot | 1 (WHERE), 3 (GROUP BY), 4 (CTE), 5 (`ROW_NUMBER`) | |
| 07 Q3 `form4_gvkey_link` | CIK and ticker match, then CIK-only with the overlap preference, then the fixes | 2 (JOIN, LEFT JOIN), 4 (CTE chain, `UNION ALL`, `NOT IN (SELECT ...)`), 5 (`ROW_NUMBER` to pick one row), 1 (`CASE WHEN`, `COALESCE`) | ORDER BY a true/false expression to put NULLs last |
| 07 Q4 `form4_gvkey_list` | The distinct linked gvkeys, as 6-digit text | 1 (`DISTINCT`) | `printf('%06d', x)` |
| 08 Q1 `form4_sec_gvkey` | Trades with their security, from 2003-06-30 | 2 (LEFT JOIN), 5 (`ROW_NUMBER` as a row id) | comparing ISO dates as text |
| 08 Q2 `form4_compustat` | Price on the trade date, else on the next date with a row; unpriced trades kept | 2 (LEFT JOIN on three keys), 3 (GROUP BY with `MIN`), 4 (CTE chain, `UNION ALL`), 5 (`ROW_NUMBER`) | a `>=` join condition ("first date on or after"); `CAST(NULL AS ...)` |

Check (`py/check_form4_compustat.py`, 2026-10-07): the 262 gvkeys equal the
authors' own list. 198,654 trades, as in the authors' file; 165 without a
price and 23 without a security, as there; every cell equal (max relative
difference 6e-16) except the Forbes id of query 4's 34 vintage-gap rows. R
and Python exports are identical.

## Queries 9 and 10, and the basis step: Form 4 income items to yearly sums

`09_form4_income.sql` turns each priced trade into income items: open-market
sales and purchases, gifts of stock valued at the day's close (the
charitable contributions), and profits from option exercises and RSU
vestings, which look at the whole filing (MAX over a 0/1 flag per filing is
SQL's "any row"). One filing is left out through a gitignored list,
`data-raw/form4-excluded-filings.csv` (schema in the `.example.csv`).

Capital gains need a loop: each sale uses up the shares bought before it,
highest cost first, with share counts put on the sale's stock-split basis,
and the holding period decides short or long term. That is state carried
from row to row, so it is an R and Python twin, `py/form4_basis.py` and
`R/form4_basis.R`, reading `form4_basis_input` (written by query 9) and
writing `form4_kg` and `form4_basis_held` back. The rules are listed at the
top of `py/form4_basis.py`.

`10_form4_annual.sql` sums by person, stock and year; by person and year;
by year; and for the five largest fortunes. Losses carried forward against
later long-term gains (`kg_taxable`) are a year-to-year state too, written
here as a recursive CTE. Values are rounded to cents the way R's `round()`
does, which SQLite's `ROUND()` does not (16.395 is 16.4 in R and 16.39 in
SQLite); the rule is spelled out once per table, after an unpivot.

Order: `09_form4_income.sql`, then `python py/form4_basis.py` (or
`Rscript R/form4_basis.R`), then `10_form4_annual.sql`.

| Block | What it does | Course module | Beyond the course |
|---|---|---|---|
| 09 Q1 `form4_income` | Per trade: sales, purchases, gifts, option and RSU profits from filing-level flags | 1 (`CASE WHEN`), 4 (CTE chain, `NOT IN (SELECT ...)`), 5 (`MAX(...) OVER (PARTITION BY ...)`) | MAX of a 0/1 flag as "any" |
| 09 Q2 `form4_basis_input` | The trades that build or draw down a holding, numbered in processing order | 1 (WHERE with AND / OR), 5 (`ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`) | |
| basis step (R and Python) | Lots, sales against the highest-cost lots, short and long term, year-end basis | not SQL: a loop with state | |
| 10 Q1 `form4_trades_kg` | Trades with their capital gains | 2 (LEFT JOIN) | |
| 10 Q2 `form4_firm_individual_raw` | Sums per person, stock and year; year-end basis carried down to years without one | 3 (GROUP BY), 2 (LEFT JOIN), 4 (CTE chain), 5 (running `COUNT`, `FIRST_VALUE`, `ROW_NUMBER`) | filling a column down (tidyr's `fill()`) |
| 10 Q3 `form4_individual_raw` | Sums per person and year, the loss carry-forward year by year | 3, 4, 5, 2 | `WITH RECURSIVE`; two-argument `MAX` / `MIN` |
| 10 Q4, Q5 | Per year with a Total row; the top 5 with yearly and overall totals | 3 (GROUP BY), 4 (`UNION ALL`, `IN (SELECT ...)`) | `printf('%010d', x)` |
| 10 Q2b to Q5b | The four output tables, rounded to cents as R rounds | 4 (`UNION ALL`), 3 (`MAX(CASE WHEN ...)` per column) | unpivot and pivot; `FLOOR`, `CEIL`, `SIGN` |

Check (`py/check_form4_annual.py`, 2026-10-07): the four tables equal the
authors' files (2,110, 1,619, 24 and 118 rows; max difference 0) and the same
tables in their private workbook (one sheet keeps a stale row after the
file's rows, set aside); the Forbes id differs only on query 4's vintage-gap
rows. The eight Form 4 columns of the public `data_sec_all` (purchase, sale,
kg, kg_long, kg_short, option_profit, kg_taxable, donation; 1,337 rows,
2019 to 2025) equal ours exactly. The R and Python basis steps and all
exports are identical.

## Later queries (planned)

The rest of the Compustat-based chain: the `wrds_*` summaries (public equity
wealth, dividends and fundamentals from Compustat), and `main_annual_*`,
which combine them with the Form 4 sums into the remaining columns of the
public `data_sec_*` sheets (taxes, economic income). See
`PLAN-2-raw-to-workbook.md` at the repo root.
