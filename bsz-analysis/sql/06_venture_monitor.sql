-- =============================================================================
-- Query 6: PitchBook-NVCA Venture Monitor to annual and quarterly panels
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook). Venture
-- capital deals per US state, from the quarterly PitchBook-NVCA Venture
-- Monitor workbooks, to four tables: deals per state and year, per state and
-- quarter, and their sums for the US, California and the rest of the US. The
-- two sums land in the public sheets data_venturemonitor_annual and
-- data_venturemonitor_quarterly (which add the California shares).
--
-- Each workbook reports, per state, the deal count and the deal value
-- ($ million) for every year shown, the current year being year to date.
--   * Annual: the latest workbook (2026 Q2) for 2016 to 2026, and the 2017 Q4
--     workbook for 2006 to 2015 (the 2026 workbook starts at 2016).
--   * Quarterly, 2018 Q1 to 2026 Q2: each workbook's current-year column is
--     the year to date, so a quarter is the difference between two
--     consecutive workbooks of the same year, and the first quarter is the
--     value itself. That difference is a window function, LAG.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   vm_state_cells  one row per workbook, sheet row, measure ('count' or
--                   'value') and year column: the state, the column's year and
--                   the cell value (NULL when empty). The loader finds the
--                   sheet, the header row and the two blocks in each layout;
--                   see the comment above load_vm_state_cells().
--
-- Outputs (tables in the same database):
--   vm_cells_paired          intermediate: count and value side by side
--   vm_annual_state          deals per state and year, 2006 to 2026
--   vm_annual                per year: totals, California, rest of US
--   vm_quarterly_state       deals per state and quarter, 2018 Q1 to 2026 Q2
--   vm_quarterly             per quarter: totals, California, rest of US
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/06_venture_monitor.sql --export vm_annual_state vm_annual vm_quarterly_state vm_quarterly
--   Rscript R/run_sql.R   sql/06_venture_monitor.sql --export vm_annual_state vm_annual vm_quarterly_state vm_quarterly
--   python  py/check_venture_monitor.py
--
-- Money: the workbooks report $ million; the two summary tables report
-- $ billion (divided by 1000), the state tables keep $ million.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Count and value side by side (intermediate table)
--     Course: module 2 (INNER JOIN of a table with itself), module 1 (WHERE
--     ... IS NOT NULL)
--     Beyond the course: a self-join to turn rows into columns (a pivot).
--
--     The loader wrote one row per cell. Joining the count cells to the value
--     cells of the same workbook, sheet row and year puts the two measures in
--     one row. The R code reshapes with two pivot_longer() calls and keeps
--     the pairs whose two year labels agree; the join on year does the same
--     in one step. A pair is kept only when both cells hold a number, as in
--     the R code; that also drops the note rows under the table ("As of ...").
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS vm_cells_paired;
CREATE TABLE vm_cells_paired AS
SELECT
  c.file_year,
  c.file_quarter,
  c.sheet_row,
  c.state,
  c.year,
  c.value AS deal_count,
  v.value AS deal_value
FROM vm_state_cells c
JOIN vm_state_cells v
  ON  v.file_year = c.file_year
  AND v.file_quarter = c.file_quarter
  AND v.sheet_row = c.sheet_row
  AND v.year = c.year
  AND v.measure = 'value'
WHERE c.measure = 'count'
  AND c.value IS NOT NULL
  AND v.value IS NOT NULL;


-- -----------------------------------------------------------------------------
-- Q2. Deals per state and year, 2006 to 2026
--     Course: module 1 (WHERE with AND / OR, NOT IN), module 4 (UNION ALL)
--
--     Two workbooks: the latest one (2026 Q2) for the years it shows, and
--     the 2017 Q4 one for the years before (its 2016 and 2017 columns are
--     dropped, since the latest workbook covers them).
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS vm_annual_state;
CREATE TABLE vm_annual_state AS
SELECT state, year, deal_count, deal_value
FROM vm_cells_paired
WHERE file_year = 2026 AND file_quarter = 2
UNION ALL
SELECT state, year, deal_count, deal_value
FROM vm_cells_paired
WHERE file_year = 2017 AND file_quarter = 4
  AND year NOT IN (2016, 2017)
ORDER BY state, year;


-- -----------------------------------------------------------------------------
-- Q3. Per year: all states, California, the rest of the US
--     Course: module 3 (GROUP BY with SUM), module 1 (SUM(CASE WHEN ...))
--
--     The R code sums sub-vectors (deal_count[state == "California"]); the
--     CASE expression returns the value for the rows that qualify and NULL
--     otherwise, and SUM skips the NULLs. COALESCE(..., 0) gives 0 rather
--     than NULL for a year without California rows, as R's sum() of an empty
--     vector does. Values to $ billion.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS vm_annual;
CREATE TABLE vm_annual AS
SELECT
  year,
  SUM(deal_count)                                                    AS tot_count,
  COALESCE(SUM(CASE WHEN state = 'California' THEN deal_count END), 0)  AS count_ca,
  COALESCE(SUM(CASE WHEN state <> 'California' THEN deal_count END), 0) AS count_rest_us,
  SUM(deal_value) / 1000.0                                           AS tot_value,
  COALESCE(SUM(CASE WHEN state = 'California' THEN deal_value END), 0) / 1000.0
                                                                     AS value_ca,
  COALESCE(SUM(CASE WHEN state <> 'California' THEN deal_value END), 0) / 1000.0
                                                                     AS value_rest_us
FROM vm_annual_state
GROUP BY year
ORDER BY year;


-- -----------------------------------------------------------------------------
-- Q4. Deals per state and quarter, 2018 Q1 to 2026 Q2
--     Course: module 4 (CTE), module 5 (window function LAG with PARTITION BY
--     and ORDER BY)
--     Beyond the course: the third argument of LAG, the value to use when
--     there is no earlier row.
--
--     * ytd: from each workbook of 2018 onward, the column of its own year:
--       the year-to-date count and value per state.
--     * final SELECT: the quarter's deals are this quarter's year to date
--       minus the previous quarter's, within the same state and year. LAG(x,
--       1, 0) OVER (PARTITION BY state, year ORDER BY quarter) is the
--       previous quarter's value, or 0 for the first quarter, so Q1 is its
--       own year to date. This is R's group_by(state, year) then
--       x - lag(x, default = 0) on rows sorted by quarter. Like lag(), LAG
--       looks at the previous row, not the previous calendar quarter: a state
--       missing from one workbook is differenced against the last one that
--       has it.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS vm_quarterly_state;
CREATE TABLE vm_quarterly_state AS
WITH ytd AS (
  SELECT
    state,
    year,
    file_quarter AS quarter,
    deal_count   AS ytd_count,
    deal_value   AS ytd_value
  FROM vm_cells_paired
  WHERE file_year >= 2018
    AND year = file_year
)
SELECT
  state,
  year,
  quarter,
  ytd_count - LAG(ytd_count, 1, 0) OVER (
    PARTITION BY state, year ORDER BY quarter) AS deal_count,
  ytd_value - LAG(ytd_value, 1, 0) OVER (
    PARTITION BY state, year ORDER BY quarter) AS deal_value
FROM ytd
ORDER BY state, year, quarter;


-- -----------------------------------------------------------------------------
-- Q5. Per quarter: all states, California, the rest of the US
--     Course: module 3 (GROUP BY over two columns), module 1
--     (SUM(CASE WHEN ...))
--
--     The same sums as Q3, per year and quarter.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS vm_quarterly;
CREATE TABLE vm_quarterly AS
SELECT
  year,
  quarter,
  SUM(deal_count)                                                    AS tot_count,
  COALESCE(SUM(CASE WHEN state = 'California' THEN deal_count END), 0)  AS count_ca,
  COALESCE(SUM(CASE WHEN state <> 'California' THEN deal_count END), 0) AS count_rest_us,
  SUM(deal_value) / 1000.0                                           AS tot_value,
  COALESCE(SUM(CASE WHEN state = 'California' THEN deal_value END), 0) / 1000.0
                                                                     AS value_ca,
  COALESCE(SUM(CASE WHEN state <> 'California' THEN deal_value END), 0) / 1000.0
                                                                     AS value_rest_us
FROM vm_quarterly_state
GROUP BY year, quarter
ORDER BY year, quarter;
