-- =============================================================================
-- Query 3: the FTB table 2023-b-4a to yearly totals and top-bracket rows
-- =============================================================================
--
-- Step 2 of the reproduction (the public workbook to the paper's tables). The
-- public workbook copies the Franchise Tax Board's table B-4A (California
-- resident returns by AGI bracket, one block of 59 or 60 brackets per taxable
-- year, 1995 to 2022) into sheet 2023-b-4a__adjusted_gross_incom (1,657 rows).
-- The billionairesCAinctax estimate reads two things from it, for 2018 to
-- 2022:
--   * each year's totals over all brackets: returns, CA AGI, taxable income,
--     tax (sheet rows 13 to 15 of billionairesCAinctax);
--   * the rows of the top brackets ($5M and over; from 2021 split into $5M to
--     $9.999M and $10M and over), the inputs to its Pareto projection.
-- The R code used to address both by sheet row numbers (for example rows
-- 242 to 300 for 2018). Here they are selected by the sheet's own taxable
-- year and bracket label columns, which pick exactly the same rows
-- (tests/testthat/test-sql-workbook.R checks this).
--
-- Inputs (written into a SQLite database by write_workbook_tables() in
-- R/workbook_db.R, or by its twin in py/workbook_db.py):
--   ftb_b4a   one row per bracket and year: sheet row (row_num), columns A
--             (taxable_year), C (agic, the bracket label), D (all_returns),
--             H (ca_agi), J (taxable_income) and K (total_tax). Money in $,
--             as in the sheet. The sheet's title and header rows are not
--             loaded.
--
-- Outputs (tables in the same database):
--   ftb_b4a_year  one row per taxable year: number of brackets and the four sums
--   ftb_b4a_top   one row per taxable year and top bracket
--
-- Run from bsz-analysis/ (both write data-raw/*.sqlite, gitignored):
--   Rscript -e 'targets::tar_make()'     # R: target workbook_db
--   python py/run_export.py              # Python: data-raw/workbook-py.sqlite
--
-- Units stay in $ here. The R and Python code scales to $ billion (x 1e-9) at
-- the point where it uses a value, as it did before this query existed.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Yearly totals over all AGI brackets
--     Course: module 3 (GROUP BY with COUNT and SUM), module 1 (WHERE ...
--     IS NOT NULL, COALESCE)
--
--     Replaces sum(column[first_row:last_row], na.rm = TRUE), one call per
--     year and column. GROUP BY taxable_year does all years and all four
--     columns at once. n_brackets is there to check the grouping: 60 rows for
--     2021 and 2022, 59 for every earlier year.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS ftb_b4a_year;
CREATE TABLE ftb_b4a_year AS
SELECT
  taxable_year,
  COUNT(*)                          AS n_brackets,
  COALESCE(SUM(all_returns), 0)     AS all_returns,
  COALESCE(SUM(ca_agi), 0)          AS ca_agi,
  COALESCE(SUM(taxable_income), 0)  AS taxable_income,
  COALESCE(SUM(total_tax), 0)       AS total_tax
FROM ftb_b4a
WHERE taxable_year IS NOT NULL
GROUP BY taxable_year
ORDER BY taxable_year;


-- -----------------------------------------------------------------------------
-- Q2. The top-bracket rows, with a short bracket key
--     Course: module 4 (CTE), module 1 (CASE WHEN, IN (...) list, REPLACE)
--
--     The sheet's labels have two spaces around "to" and "and"
--     ('5,000,000  and  over'). The labelled CTE collapses double spaces
--     with REPLACE so the labels can be written normally below. A CASE then
--     maps each label to a short key:
--       5m_plus    $5,000,000 and over        (one row per year up to 2020)
--       5m_to_10m  $5,000,000 to $9,999,999   (2021 and 2022)
--       10m_plus   $10,000,000 and over       (2021 and 2022)
--     Every other bracket is dropped by the WHERE clause.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS ftb_b4a_top;
CREATE TABLE ftb_b4a_top AS
WITH labelled AS (
  SELECT
    row_num,
    taxable_year,
    REPLACE(agic, '  ', ' ') AS agic,
    all_returns,
    ca_agi,
    taxable_income,
    total_tax
  FROM ftb_b4a
  WHERE taxable_year IS NOT NULL
)
SELECT
  taxable_year,
  CASE agic
    WHEN '5,000,000 and over'       THEN '5m_plus'
    WHEN '5,000,000 to 9,999,999'   THEN '5m_to_10m'
    WHEN '10,000,000 and over'      THEN '10m_plus'
  END AS bracket,
  row_num,
  all_returns,
  ca_agi,
  taxable_income,
  total_tax
FROM labelled
WHERE agic IN ('5,000,000 and over', '5,000,000 to 9,999,999', '10,000,000 and over')
ORDER BY taxable_year, row_num;
