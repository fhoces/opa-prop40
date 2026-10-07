# opa-prop40: plan, phase 2 (raw data to the public workbook, in SQL and Python)

> Written 2026-10-07. Phase 1 (`PLAN.md`) reproduced the paper from the public
> workbook's cached cells. This phase reproduces the public workbook's *data sheets*
> from the raw inputs the authors shared. The first deliverable is one query
> (Forbes real-time billionaires to the California lists), plus the harness that every
> later query reuses. Later queries are outlined at the end and are NOT in scope for
> the session that executes this file.

## Why

The user is learning SQL and Python. The repo's standing rule (`PLAN.md`, "Standing
conventions") is that any step touching more than 1,000 rows goes through shared
`.sql` files that both R and Python run verbatim, in the house style of the course
`~/Desktop/sandbox/courses/sql-industry-prep`. No such file exists yet. This phase
builds the first one against real data with a real answer key, so the user can read a
working reproduction before writing the next query themselves.

## The two-step structure of the reproduction

- **Step 1, raw to spreadsheet (this phase).** Confidential author-shared inputs to the
  data sheets of the public workbook `BSZ_MainTablesFigures.xlsx`. Code is public, data
  is not. What can be published is the comparison: our recomputed sheet against the
  public sheet, both already public.
- **Step 2, spreadsheet to results (phase 1, done in R).** The public workbook's data
  sheets to the paper's tables and figures.

## Ground rules (read before touching anything)

1. **Confidentiality.** Everything under `bsz-analysis/original-materials/` is
   gitignored and must stay out of git. Terms of the author bundle: re-analysis
   permitted, no public sharing. Concretely:
   - Never commit a file that contains rows from the bundle, including CSV exports of
     SQL results and the SQLite database. Write them under
     `bsz-analysis/data-raw/sql-out/` and add that directory to
     `bsz-analysis/.gitignore`.
   - Never copy the authors' code into the repo. Describe its logic in your own words
     in SQL comments. Citing a script by file name and line is fine.
   - A check report that prints counts, row totals and max absolute differences is
     fine to commit. A report that prints individual rows from `MainData.xlsx` is
     not. Rows from the public workbook may be printed.
   - The SQL will necessarily name individual billionaires (the authors' residency
     overrides). Those names already appear in the public workbook's `rtb_ca_*`
     sheets, so this is acceptable, but flag it in your final report so the user can
     confirm before the commit is pushed.
2. **Commit, never push.** Commit in small steps with messages in the repo's style
   (see `git log`). The push is the user's decision.
3. **Repo is public.** No em-dash characters in anything you write (prose, comments,
   commit messages). Use commas, parentheses or two sentences.
4. **Do not modify** `bsz-analysis/_targets.R`, `R/`, `tests/testthat/test-*.R` that
   already exist, the site, or the export contract. This phase adds files; it does not
   rewire phase 1. (One exception: the two stale lines about Compustat, see task 7.)
5. **CI must stay green without the bundle.** GitHub Actions has no bundle. Every
   test added here skips, never fails, when the bundle or the SQLite file is absent.
6. **Verify, do not trust this document.** Re-read every author script and sheet you
   depend on. The facts below were checked on 2026-10-07 but you are responsible for
   them.

## Where things are

Bundle root (set `BSZ_BUNDLE_DIR` to override; this is the default):

```
bsz-analysis/original-materials/author-shared/2026-09-23_bsz-replication-code-data/
```

Inputs for query 1:

| File (relative to bundle root) | Rows | Notes |
|---|---:|---|
| `Forbes_RTB/03_outdata/rtb_all_combined.csv` | 5,933,481 + header | Daily Forbes real-time billionaire snapshots, 2020-07-22 to mid-2026 plus some 2019 dates. Columns: `date, forbes_id, forbes_name, state, country_citizenship, source, industries, forbes_worth, forbes_public_worth, forbes_private_worth`. Worth columns are $ million. Missing values are **empty strings**, not `NA`. `state` is empty for roughly half the rows (non-US). |
| `Forms4/02_indata/rtb_ca_cik_2026_01_01.xlsx` | 237 | `forbes_id` to SEC `cik` (float column; some blank). Joined onto the 2026-01-01 list only. |

Author script to reproduce: `Forbes_RTB/01_code/build/02_export_rtb.R`, sections 01
to 03 (lines 11 to 135). Section 04 onward (mobility, NYT snapshot) is out of scope.

Answer keys:

| Target | Answer key (private) | Public landing |
|---|---|---|
| Seven year-end CA lists | `MainData.xlsx` sheets `rtb_ca_2019_12_31` ... `rtb_ca_2024_12_31`, `rtb_ca_2026_01_01` | Not published as lists; they feed `shortrunseries` and the SEC panel. |
| Industry decomposition | `MainData.xlsx` sheet `rtb_ca_2026_01_01_industry` (14 rows incl. Total, 8 columns; the last two are Excel-side extras) | `BSZ_MainTablesFigures.xlsx` sheet `rtb_2026_industry`, header on row 4. Same numbers, with "Finance & Investments" renamed "Finance" and a hand-added subtotal row "Other" (every industry except Technology and Finance: 68 people). Also a second block from row 22 that splits the top 4; out of scope. |
| Daily CA aggregate | `MainData.xlsx` sheet `rtb_ca_aggregate` (2,213 rows, 4 columns: `date, n_billionaires, forbes_worth_total, forbes_worth_top4`) | `shortrunseries` (phase 1 already reads it; identify which columns come from this aggregate and compare those). |

Known vintage gaps to document, not "fix": the script computes a fifth aggregate
column `forbes_private_worth` that the sheet does not have; the bundle's
`Forbes_RTB/03_outdata/rtb_ca_aggregate.xlsx` has 2,209 rows while the sheet has
2,213; the CSV may extend past the sheet's last date (2026-06-08). Compare on the
intersection of dates and report what is extra on each side.

## The rules of query 1, in plain words (verify against the script)

1. Keep rows with `forbes_worth >= 1000` ($1 billion).
2. California residency: `state = 'California'`, OR `forbes_id` in a list of ten named
   inclusions (people the authors treat as CA residents despite the Forbes state
   field), AND NOT in a list of three named exclusions (two people the authors judge
   not includible, plus one id). Take both lists verbatim from the script's section 02.
3. Year-end lists: one snapshot per year on these exact dates: 2019-12-31, 2020-12-31,
   2021-12-31, 2022-12-31, 2023-12-31, 2024-12-31, and 2026-01-01 (the "2025" list).
   Sorted by `forbes_worth` descending. The 2026-01-01 list gets `sec_cik` by a left
   join on `forbes_id` to the cik file.
4. Industry table (2026-01-01 list only): per `industries`, count, sum of public worth
   / 1000, sum of worth / 1000, `fraction_public_worth = public / worth`,
   `fraction_forbes_worth = worth / grand total`; plus a `Total` row; sorted by
   `fraction_forbes_worth` descending with Total last.
5. Daily aggregate: per `date`, count, sum of worth / 1000, sum of worth / 1000 over
   the four ids `mark-zuckerberg, jensen-huang, larry-page, sergey-brin`; drop three
   dates listed in the script (`2022-07-18, 2026-03-29, 2026-03-30`).

Sums ignore NULLs (SQL `SUM` does this; R used `na.rm = TRUE`).

## What to build

All paths relative to `bsz-analysis/`.

### 1. `py/bundle_paths.py`

Resolve the bundle root (`BSZ_BUNDLE_DIR` env var, else the default above) and the
SQLite path `data-raw/bundle.sqlite`. One function each. Raise a clear error naming
the env var when the bundle is absent.

### 2. `py/load_bundle.py`

Build `data-raw/bundle.sqlite` from the bundle. Idempotent: drop and recreate each
table it owns. For query 1, two tables:

- `rtb_all_combined`: typed columns (`TEXT` for strings and the ISO date, `REAL` for
  the three worth columns). Empty strings become `NULL`. Load in chunks (pandas
  `read_csv(chunksize=...)` with `keep_default_na=False` then explicit empty-to-NULL,
  or the `csv` module with `executemany`); 5.9M rows should load in a few minutes.
  Create indexes on `(date)` and `(forbes_id)` after loading. Print row count and
  elapsed time.
- `rtb_ca_cik`: `forbes_id TEXT, cik INTEGER` (cast from float; blanks to NULL).

Design the script so later queries add tables by adding one loader function each.

### 3. `sql/01_rtb_ca.sql`

The query, in the house style of `sql-industry-prep/module-05/exercise.sql`: banner
header, one `-- Q1. Title` block per step, CTEs, uppercase keywords, SQLite dialect.
Two differences from the course files, both explained in the header comment:

- **No sqlite3 dot-commands** (`.headers`, `.mode`). This file is executed verbatim by
  Python (`sqlite3.Connection.executescript`) and R (`DBI::dbExecute` statement by
  statement), and dot-commands are CLI-only.
- **It creates tables, not result sets.** Each block ends in `DROP TABLE IF EXISTS x;
  CREATE TABLE x AS ...;` so both languages read the result back the same way.

Output tables:

- `rtb_ca_eoy`: all seven snapshots in one long table (add nothing but the source
  columns plus `sec_cik`, NULL except on 2026-01-01). The per-year sheets are slices
  of this table by `date`. Note in a comment why one long table is the SQL-native
  shape where R wrote seven data frames.
- `rtb_ca_2026_01_01_industry`: same columns as the authors' sheet, first six only.
- `rtb_ca_aggregate`: the four sheet columns plus `forbes_private_worth` (the script's
  fifth column), in that order.

Tag every block with the course module it exercises (`-- Course: module 1 (WHERE,
CASE)`, `module 3 (GROUP BY with a total row)`, `module 5 (window)` if you use one for
the ranking), and add a `-- Beyond the course:` comment wherever you use something
the five modules do not cover (e.g. `CREATE TABLE AS`, `UNION ALL` for the total row,
`NULLIF`). Comment each block with the R idiom it replaces, in your own words, with a
pointer to the script line. Do not paste the R.

### 4. `py/run_sql.py`

`python py/run_sql.py sql/01_rtb_ca.sql --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate`

Executes the file with `executescript`, then writes each named table to
`data-raw/sql-out/py/<table>.csv` (sorted by the table's natural key so files are
deterministic; floats written with `repr` precision). Prints row counts.

### 5. `R/run_sql.R`

The R twin of 4, not wired into `_targets.R`: reads the same file, splits on
statement terminators (handle `;` inside comments and strings sensibly, or use a
small tokenizer; document the limitation), executes with `DBI`/`RSQLite`, exports the
same tables to `data-raw/sql-out/r/<table>.csv` with the same ordering.

### 6. `py/check_rtb_ca.py`

Compares the three Python exports with the answer keys and with the R exports, and
writes `data-raw/sql-out/check_rtb_ca.md` (gitignored) plus a short summary to
stdout. Exit code 1 on any failure.

- Year-end lists: for each of the seven dates, row count equal, same set of
  `forbes_id`, and each numeric column within `1e-6` absolute after aligning on
  `forbes_id`. Report extra and missing ids by count only (names are from the private
  sheet).
- Industry: align on `industries`, six columns, tolerance `1e-6`; then against the
  public `rtb_2026_industry` after mapping "Finance & Investments" to "Finance" and
  skipping the "Other" row; here mismatches may be printed row by row (public data).
- Aggregate: align on `date`, intersection of dates, tolerance `1e-6` on the three
  numeric columns, counts exact; report the dates present on only one side.
- R vs Python parity: every exported table equal within `1e-9` after numeric parse.

### 7. Documentation

- Replace `sql/README.md` (currently a one-liner) with: purpose, the two-step
  structure, how to build the database and run a query from each language, the
  conventions above, a **course map table** (block, what it does, course module, beyond
  the course?), and the check summary (counts and max differences only).
- Replace `py/README.md` similarly for the Python side.
- In `bsz-analysis/README.md` and `bsz-analysis/_raw-sources.md`, the Compustat row
  says "Cannot be re-pulled here: paywalled". Change it to say the extracts were shared
  by the authors under confidential terms and are not redistributable; the Forbes RTB
  row changes from "Not pulled (no public historical archive)" to "author-shared
  daily snapshots; query 1 reproduces the CA lists and aggregate". Keep the table
  format.
- Add `data-raw/sql-out/` to `bsz-analysis/.gitignore`.

### 8. Tests

- `tests/testthat/test-sql.R`: skips if `data-raw/bundle.sqlite` is absent; otherwise
  runs `R/run_sql.R` on query 1 and checks row counts (seven dates, 2026-01-01 has 240
  rows, aggregate has at least 2,209 rows) and the parity with the Python export if
  present.
- `py/test_sql.py` (pytest, or a plain `__main__` guard if pytest is not installed):
  same skips, same counts.
- Do not add either to CI workflows. They are local by design.

## Acceptance

1. `python py/load_bundle.py` builds the database; `python py/run_sql.py ...` and
   `Rscript R/run_sql.R ...` both succeed.
2. `python py/check_rtb_ca.py` exits 0, or exits 1 with every failure explained in the
   report as a documented vintage gap (not a logic error). If you cannot tell which,
   say so in the final report rather than lowering a tolerance.
3. `git status` shows no file from `original-materials/` or `data-raw/sql-out/`, and
   no `.sqlite`.
4. `grep -rn $'—'` over the new and edited files prints nothing.
5. Phase 1 still passes: `cd bsz-analysis && Rscript -e 'testthat::test_dir("tests/testthat")'`
   (the existing snapshot tests must be untouched).

## Final report (keep it under 300 words)

Counts per target and max absolute differences; every discrepancy and whether it is
a vintage gap or unexplained; which course modules each block exercises; the list of
individual names that appear in the SQL (for the user's publication decision); the
commit SHAs. No file dumps.

## Later queries (outline only, not for this session)

2. **Form 4 raw to clean**: `Forms4/03_outdata/form4_raw.csv` (223k rows) to
   `form4_clean.csv` (199k), script `Forms4/01_code/build/03_clean_form4.R`. Dedupe on
   all columns but `Folder`, text filters, `CASE WHEN` for sale and purchase, four
   per-filing price corrections, join to `forbes_id` via CIK.
3. **Forbes 400 and global lists to the CA panel 2004 to 2025**:
   `Forbes/01_code/merge_forbes_rtb.R`; name matching may need Python.
4. **Pitchbook venture monitor**: 34 quarterly workbooks with drifting sheet names to
   annual and quarterly panels; the loader is the lesson, `LAG` for within-year
   differences.
5. **Compustat-based steps** (now possible, extracts are in the bundle): Form 4 to
   daily prices, donation values, the `wrds_*` sheets, then `main_annual_*` to
   `data_sec_*`. The capital-gains basis loop in `Forms4/01_code/analysis/01_main_form4.R`
   is sequential and becomes an R and Python twin with SQL on either side.
