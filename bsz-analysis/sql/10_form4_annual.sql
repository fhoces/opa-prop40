-- =============================================================================
-- Query 10: Form 4 income items to yearly sums per person (and per stock)
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook). Sums the
-- per-trade income items of query 9 and the capital gains of the basis step
-- (py/form4_basis.py or R/form4_basis.R) by person, stock and year, then by
-- person and year, then by year, and for the five largest fortunes. On the
-- way it applies the tax rule that losses on stock sales carry forward
-- against later long-term gains (kg_taxable), which is a running state from
-- one year to the next: a recursive CTE.
--
-- Inputs (built by the earlier steps in data-raw/bundle.sqlite):
--   form4_income       query 9's trades with income items
--   form4_kg           capital gain of each sale (the basis step)
--   form4_basis_held   cost basis of the shares held at the end of each year
--                      (the basis step)
--   form4_forbes_cik   forbes_id to filer CIK (query 4's input), used to find
--                      the five people of the top-5 table by Forbes id
--
-- Outputs (tables in the same database):
--   form4_trades_kg               intermediate: income items plus capital gains
--   form4_annual_firm_individual  per person, stock and year, 2004 to 2025
--   form4_annual_individual       per person and year, up to 2025, with
--                                 kg_taxable
--   form4_annual                  per year, all people, plus a Total row
--   form4_annual_top5             per year for the five largest fortunes,
--                                 with yearly and overall totals
--   (each of the four has an unrounded *_raw intermediate table)
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/10_form4_annual.sql --export form4_annual_firm_individual form4_annual_individual form4_annual form4_annual_top5
--   Rscript R/run_sql.R   sql/10_form4_annual.sql --export (same tables)
--   python  py/check_form4_annual.py
--
-- Money: dollars in, $ million in the person tables, $ billion in the yearly
-- table, $ million in the top-5 table.
--
-- Rounding: every money and share column is rounded to two decimals, as in
-- the authors' output, and the yearly and top-5 tables add up the rounded
-- person-year values. SQLite's ROUND() does not round the way R's round()
-- does, and the difference shows up often here: a value such as 16.395
-- (stored as a double a hair below or above) becomes 16.39 in SQLite and
-- 16.4 in R. R (version 4 on) takes the nearer of the two neighbouring cents,
-- computed in double arithmetic, and the even one when the two are equally
-- near. Each output table is therefore built in three moves:
--   1. an unrounded *_raw table;
--   2. long: one row per (key, column, value), a stack of one SELECT per
--      column (an "unpivot");
--   3. rounded, then back to one row per key with MAX(CASE WHEN col = ...)
--      per column (a "pivot"), so the rounding rule is written once per table.
-- The rule, for v and its absolute value |v|: lo = FLOOR(|v| x 100) / 100 and
-- hi = CEIL(|v| x 100) / 100; take hi when hi - |v| < |v| - lo, or when the two
-- are equal and FLOOR(|v| x 100) is odd; else lo; then put the sign back.
-- On 45,000 test values it gives R's result every time.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Trades with their capital gains (intermediate table)
--     Course: module 2 (LEFT JOIN)
--
--     The basis step wrote one row per sale; every other trade gets NULL.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_trades_kg;
CREATE TABLE form4_trades_kg AS
SELECT t.*, k.total_basis AS sale_basis, k.kg, k.kg_short, k.kg_long
FROM form4_income t
LEFT JOIN form4_kg k ON k.row_id = t.row_id;


-- -----------------------------------------------------------------------------
-- Q2. Per person, stock and year, 2004 to 2025 (unrounded, then rounded)
--     Course: module 3 (GROUP BY with SUM), module 1 (COALESCE, ROUND),
--     module 2 (LEFT JOIN), module 4 (CTE chain), module 5 (window functions:
--     a running COUNT, FIRST_VALUE, ROW_NUMBER)
--     Beyond the course: carrying the last known value down a column
--     (tidyr's fill(), which SQLite has no single function for).
--
--     * first_vals: the Forbes id and ticker of each group's first trade in
--       file order (dplyr's first()).
--     * sums: the sums in $ million (shares stay counts). R's sum(x, na.rm =
--       TRUE) is COALESCE(SUM(x), 0).
--     * with_basis: the year-end basis of the basis step, in $ million.
--     * filled: a year without a basis row takes the last year that has one.
--       The running COUNT(total_basis) only goes up at a row with a basis, so
--       it numbers the stretches that start at such a row; FIRST_VALUE over
--       each stretch is the value carried down. Years before the first basis
--       stay NULL.
--     form4_annual_firm_individual is then the rounded table (see the header).
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_firm_individual_raw;
CREATE TABLE form4_firm_individual_raw AS
WITH kept AS (
  SELECT * FROM form4_trades_kg WHERE year >= 2004
),
first_vals AS (
  SELECT owner_cik_1, issuer_cik, year, forbes_id, issuer_symbol
  FROM (
    SELECT kept.*,
           ROW_NUMBER() OVER (PARTITION BY owner_cik_1, issuer_cik, year
                              ORDER BY row_id) AS rn
    FROM kept
  )
  WHERE rn = 1
),
sums AS (
  SELECT
    owner_cik_1, issuer_cik, year,
    COALESCE(SUM(shares_purchased), 0)        AS shares_purchased,
    COALESCE(SUM(purchase), 0) / 1e6          AS purchase,
    COALESCE(SUM(shares_sold), 0)             AS shares_sold,
    COALESCE(SUM(sale), 0) / 1e6              AS sale,
    COALESCE(SUM(shares_donated), 0)          AS shares_donated,
    COALESCE(SUM(donation), 0) / 1e6          AS donation,
    COALESCE(SUM(shares_option), 0)           AS shares_option,
    COALESCE(SUM(option_profit), 0) / 1e6     AS option_profit,
    COALESCE(SUM(kg), 0) / 1e6                AS kg,
    COALESCE(SUM(kg_short), 0) / 1e6          AS kg_short,
    COALESCE(SUM(kg_long), 0) / 1e6           AS kg_long
  FROM kept
  GROUP BY owner_cik_1, issuer_cik, year
  HAVING year <= 2025
),
with_basis AS (
  SELECT s.*, b.total_basis / 1e6 AS total_basis
  FROM sums s
  LEFT JOIN form4_basis_held b
    ON  b.owner_cik_1 = s.owner_cik_1
    AND b.issuer_cik = s.issuer_cik
    AND b.year = s.year
),
stretches AS (
  SELECT
    with_basis.*,
    COUNT(total_basis) OVER (PARTITION BY owner_cik_1, issuer_cik ORDER BY year
                             ROWS UNBOUNDED PRECEDING) AS stretch
  FROM with_basis
),
filled AS (
  SELECT
    stretches.*,
    FIRST_VALUE(total_basis) OVER (PARTITION BY owner_cik_1, issuer_cik, stretch
                                   ORDER BY year) AS total_basis_filled
  FROM stretches
)
SELECT
  f.owner_cik_1, f.issuer_cik, f.year, v.forbes_id, v.issuer_symbol,
  shares_purchased AS shares_purchased,
  purchase AS purchase,
  shares_sold AS shares_sold,
  sale AS sale,
  shares_donated AS shares_donated,
  donation AS donation,
  shares_option AS shares_option,
  option_profit AS option_profit,
  kg AS kg,
  kg_short AS kg_short,
  kg_long AS kg_long,
  total_basis_filled AS total_basis
FROM filled f
JOIN first_vals v
  ON v.owner_cik_1 = f.owner_cik_1 AND v.issuer_cik = f.issuer_cik AND v.year = f.year
ORDER BY f.owner_cik_1, f.issuer_cik, f.year;


-- -----------------------------------------------------------------------------
-- Q2b. Per person, stock and year, rounded
--     Course: module 4 (CTE chain, UNION ALL), module 3 (GROUP BY with
--     MAX(CASE WHEN ...)), module 1 (CASE WHEN)
--     Beyond the course: unpivot and pivot; FLOOR, CEIL and SIGN; the rounding
--     rule of R's round() (see the header).
--
--     The text columns come back from the raw table by a join on the key.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_annual_firm_individual;
CREATE TABLE form4_annual_firm_individual AS
WITH long AS (
  SELECT owner_cik_1, issuer_cik, year, 'shares_purchased' AS col, shares_purchased AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'purchase' AS col, purchase AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'shares_sold' AS col, shares_sold AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'sale' AS col, sale AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'shares_donated' AS col, shares_donated AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'donation' AS col, donation AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'shares_option' AS col, shares_option AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'option_profit' AS col, option_profit AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'kg' AS col, kg AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'kg_short' AS col, kg_short AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'kg_long' AS col, kg_long AS v FROM form4_firm_individual_raw
  UNION ALL
  SELECT owner_cik_1, issuer_cik, year, 'total_basis' AS col, total_basis AS v FROM form4_firm_individual_raw
),
rounded AS (
  SELECT long.*,
    SIGN(v) * CASE
        WHEN CEIL(ABS(v) * 100) / 100.0 - ABS(v) < ABS(v) - FLOOR(ABS(v) * 100) / 100.0
          OR (CEIL(ABS(v) * 100) / 100.0 - ABS(v) = ABS(v) - FLOOR(ABS(v) * 100) / 100.0
              AND CAST(FLOOR(ABS(v) * 100) AS INTEGER) % 2 = 1)
        THEN CEIL(ABS(v) * 100) / 100.0
        ELSE FLOOR(ABS(v) * 100) / 100.0
      END AS rv
  FROM long
)
SELECT
  r.owner_cik_1, r.issuer_cik, r.year, t.forbes_id, t.issuer_symbol,
  MAX(CASE WHEN r.col = 'shares_purchased' THEN r.rv END) AS shares_purchased,
  MAX(CASE WHEN r.col = 'purchase' THEN r.rv END) AS purchase,
  MAX(CASE WHEN r.col = 'shares_sold' THEN r.rv END) AS shares_sold,
  MAX(CASE WHEN r.col = 'sale' THEN r.rv END) AS sale,
  MAX(CASE WHEN r.col = 'shares_donated' THEN r.rv END) AS shares_donated,
  MAX(CASE WHEN r.col = 'donation' THEN r.rv END) AS donation,
  MAX(CASE WHEN r.col = 'shares_option' THEN r.rv END) AS shares_option,
  MAX(CASE WHEN r.col = 'option_profit' THEN r.rv END) AS option_profit,
  MAX(CASE WHEN r.col = 'kg' THEN r.rv END) AS kg,
  MAX(CASE WHEN r.col = 'kg_short' THEN r.rv END) AS kg_short,
  MAX(CASE WHEN r.col = 'kg_long' THEN r.rv END) AS kg_long,
  MAX(CASE WHEN r.col = 'total_basis' THEN r.rv END) AS total_basis
FROM rounded r
JOIN form4_firm_individual_raw t ON t.owner_cik_1 = r.owner_cik_1 AND t.issuer_cik = r.issuer_cik AND t.year = r.year
GROUP BY r.owner_cik_1, r.issuer_cik, r.year
ORDER BY r.owner_cik_1, r.issuer_cik, r.year;


-- -----------------------------------------------------------------------------
-- Q3. Per person and year, with taxable capital gains (unrounded, then rounded)
--     Course: module 3 (GROUP BY), module 4 (CTE chain), module 5 (window
--     functions), module 2 (LEFT JOIN)
--     Beyond the course: WITH RECURSIVE (a CTE that refers to itself, here to
--     walk through the years one at a time); MAX() and MIN() with two
--     arguments, SQLite's scalar greatest and least.
--
--     All years with trades count here (there is no 2004 floor), up to 2025.
--     * yearly: the sums per person and year, $ million, unrounded.
--     * walk: the loss carry-forward, one year at a time. Each year adds its
--       short-term and long-term losses to the carried loss; a year with a
--       long-term gain uses up as much carried loss as the gain allows, and
--       the rest of the gain is taxable. The anchor row is each person's
--       first year (rn = 1); the recursive step joins year rn + 1 to year rn
--       and computes the new carry from the old one. This replaces the R
--       for loop over years.
--     * basis: the year-end basis summed over the person's stocks, then
--       carried down to years without one, as in Q2.
--     The carry-forward runs on unrounded values, as in R; only the output
--     is rounded (form4_annual_individual).
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_individual_raw;
CREATE TABLE form4_individual_raw AS
WITH RECURSIVE yearly AS (
  SELECT
    owner_cik_1, year,
    COALESCE(SUM(purchase), 0) / 1e6       AS purchase,
    COALESCE(SUM(sale), 0) / 1e6           AS sale,
    COALESCE(SUM(kg), 0) / 1e6             AS kg,
    COALESCE(SUM(kg_long), 0) / 1e6        AS kg_long,
    COALESCE(SUM(kg_short), 0) / 1e6       AS kg_short,
    COALESCE(SUM(donation), 0) / 1e6       AS donation,
    COALESCE(SUM(option_profit), 0) / 1e6  AS option_profit,
    ROW_NUMBER() OVER (PARTITION BY owner_cik_1 ORDER BY year) AS rn
  FROM form4_trades_kg
  GROUP BY owner_cik_1, year
  HAVING year <= 2025
),
first_ids AS (
  SELECT owner_cik_1, year, forbes_id
  FROM (
    SELECT owner_cik_1, year, forbes_id,
           ROW_NUMBER() OVER (PARTITION BY owner_cik_1, year ORDER BY row_id) AS r
    FROM form4_trades_kg
  )
  WHERE r = 1
),
walk (owner_cik_1, rn, year, carry, kg_taxable) AS (
  SELECT
    owner_cik_1, rn, year,
    MAX(-kg_short, 0) + MAX(-kg_long, 0)
      - CASE WHEN kg_long > 0 THEN MIN(kg_long, MAX(-kg_short, 0) + MAX(-kg_long, 0))
             ELSE 0 END,
    CASE WHEN kg_long > 0
         THEN kg_long - MIN(kg_long, MAX(-kg_short, 0) + MAX(-kg_long, 0))
         ELSE 0 END
  FROM yearly
  WHERE rn = 1
  UNION ALL
  SELECT
    y.owner_cik_1, y.rn, y.year,
    w.carry + MAX(-y.kg_short, 0) + MAX(-y.kg_long, 0)
      - CASE WHEN y.kg_long > 0
             THEN MIN(y.kg_long, w.carry + MAX(-y.kg_short, 0) + MAX(-y.kg_long, 0))
             ELSE 0 END,
    CASE WHEN y.kg_long > 0
         THEN y.kg_long - MIN(y.kg_long, w.carry + MAX(-y.kg_short, 0) + MAX(-y.kg_long, 0))
         ELSE 0 END
  FROM walk w
  JOIN yearly y ON y.owner_cik_1 = w.owner_cik_1 AND y.rn = w.rn + 1
),
basis AS (
  SELECT owner_cik_1, year, SUM(total_basis) / 1e6 AS total_basis
  FROM form4_basis_held
  GROUP BY owner_cik_1, year
),
with_basis AS (
  SELECT y.*, w.kg_taxable, b.total_basis,
         COUNT(b.total_basis) OVER (PARTITION BY y.owner_cik_1 ORDER BY y.year
                                    ROWS UNBOUNDED PRECEDING) AS stretch
  FROM yearly y
  JOIN walk w ON w.owner_cik_1 = y.owner_cik_1 AND w.year = y.year
  LEFT JOIN basis b ON b.owner_cik_1 = y.owner_cik_1 AND b.year = y.year
),
filled AS (
  SELECT with_basis.*,
         FIRST_VALUE(total_basis) OVER (PARTITION BY owner_cik_1, stretch
                                        ORDER BY year) AS total_basis_filled
  FROM with_basis
)
SELECT
  f.owner_cik_1, f.year, i.forbes_id,
  purchase AS purchase,
  sale AS sale,
  kg AS kg,
  kg_long AS kg_long,
  kg_short AS kg_short,
  option_profit AS option_profit,
  kg_taxable AS kg_taxable,
  donation AS donation,
  total_basis_filled AS total_basis
FROM filled f
JOIN first_ids i ON i.owner_cik_1 = f.owner_cik_1 AND i.year = f.year
ORDER BY f.owner_cik_1, f.year;


-- -----------------------------------------------------------------------------
-- Q3b. Per person and year, rounded
--     Course: module 4 (CTE chain, UNION ALL), module 3 (GROUP BY with
--     MAX(CASE WHEN ...)), module 1 (CASE WHEN)
--     Beyond the course: unpivot and pivot; FLOOR, CEIL and SIGN; the rounding
--     rule of R's round() (see the header).
--
--     The Forbes id comes back from the raw table by a join on the key.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_annual_individual;
CREATE TABLE form4_annual_individual AS
WITH long AS (
  SELECT owner_cik_1, year, 'purchase' AS col, purchase AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'sale' AS col, sale AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'kg' AS col, kg AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'kg_long' AS col, kg_long AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'kg_short' AS col, kg_short AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'option_profit' AS col, option_profit AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'kg_taxable' AS col, kg_taxable AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'donation' AS col, donation AS v FROM form4_individual_raw
  UNION ALL
  SELECT owner_cik_1, year, 'total_basis' AS col, total_basis AS v FROM form4_individual_raw
),
rounded AS (
  SELECT long.*,
    SIGN(v) * CASE
        WHEN CEIL(ABS(v) * 100) / 100.0 - ABS(v) < ABS(v) - FLOOR(ABS(v) * 100) / 100.0
          OR (CEIL(ABS(v) * 100) / 100.0 - ABS(v) = ABS(v) - FLOOR(ABS(v) * 100) / 100.0
              AND CAST(FLOOR(ABS(v) * 100) AS INTEGER) % 2 = 1)
        THEN CEIL(ABS(v) * 100) / 100.0
        ELSE FLOOR(ABS(v) * 100) / 100.0
      END AS rv
  FROM long
)
SELECT
  r.owner_cik_1, r.year, t.forbes_id,
  MAX(CASE WHEN r.col = 'purchase' THEN r.rv END) AS purchase,
  MAX(CASE WHEN r.col = 'sale' THEN r.rv END) AS sale,
  MAX(CASE WHEN r.col = 'kg' THEN r.rv END) AS kg,
  MAX(CASE WHEN r.col = 'kg_long' THEN r.rv END) AS kg_long,
  MAX(CASE WHEN r.col = 'kg_short' THEN r.rv END) AS kg_short,
  MAX(CASE WHEN r.col = 'option_profit' THEN r.rv END) AS option_profit,
  MAX(CASE WHEN r.col = 'kg_taxable' THEN r.rv END) AS kg_taxable,
  MAX(CASE WHEN r.col = 'donation' THEN r.rv END) AS donation,
  MAX(CASE WHEN r.col = 'total_basis' THEN r.rv END) AS total_basis
FROM rounded r
JOIN form4_individual_raw t ON t.owner_cik_1 = r.owner_cik_1 AND t.year = r.year
GROUP BY r.owner_cik_1, r.year
ORDER BY r.owner_cik_1, r.year;


-- -----------------------------------------------------------------------------
-- Q4. Per year, all people, plus a Total row
--     Course: module 3 (GROUP BY), module 4 (UNION ALL), module 1 (COALESCE)
--     Beyond the course: CAST of the year to text, so the Total row fits the
--     same column; sort_key to put the Total row last.
--
--     Sums of the rounded person-year values, as in the authors' code, in
--     $ billion, then rounded. A year in which nobody has a basis gets 0, as
--     R's sum(..., na.rm = TRUE) does.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_annual_raw;
CREATE TABLE form4_annual_raw AS
SELECT
  0 AS sort_key,
  CAST(year AS TEXT)                       AS year,
  SUM(purchase) / 1e3                      AS purchase,
  SUM(sale) / 1e3                          AS sale,
  SUM(kg) / 1e3                            AS kg,
  SUM(kg_long) / 1e3                       AS kg_long,
  SUM(kg_short) / 1e3                      AS kg_short,
  SUM(option_profit) / 1e3                 AS option_profit,
  SUM(kg_taxable) / 1e3                    AS kg_taxable,
  SUM(donation) / 1e3                      AS donation,
  COALESCE(SUM(total_basis), 0) / 1e3      AS total_basis
FROM form4_annual_individual
GROUP BY year
UNION ALL
SELECT
  1, 'Total',
  SUM(purchase) / 1e3, SUM(sale) / 1e3, SUM(kg) / 1e3, SUM(kg_long) / 1e3,
  SUM(kg_short) / 1e3, SUM(option_profit) / 1e3, SUM(kg_taxable) / 1e3,
  SUM(donation) / 1e3, COALESCE(SUM(total_basis), 0) / 1e3
FROM form4_annual_individual;

-- -----------------------------------------------------------------------------
-- Q4b. Per year, rounded
--     Course: module 4 (CTE chain, UNION ALL), module 3 (GROUP BY with
--     MAX(CASE WHEN ...)), module 1 (CASE WHEN)
--     Beyond the course: unpivot and pivot; FLOOR, CEIL and SIGN; the rounding
--     rule of R's round() (see the header).
--
--     sort_key keeps the Total row last when the table is read in key order.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_annual;
CREATE TABLE form4_annual AS
WITH long AS (
  SELECT sort_key, year, 'purchase' AS col, purchase AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'sale' AS col, sale AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'kg' AS col, kg AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'kg_long' AS col, kg_long AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'kg_short' AS col, kg_short AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'option_profit' AS col, option_profit AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'kg_taxable' AS col, kg_taxable AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'donation' AS col, donation AS v FROM form4_annual_raw
  UNION ALL
  SELECT sort_key, year, 'total_basis' AS col, total_basis AS v FROM form4_annual_raw
),
rounded AS (
  SELECT long.*,
    SIGN(v) * CASE
        WHEN CEIL(ABS(v) * 100) / 100.0 - ABS(v) < ABS(v) - FLOOR(ABS(v) * 100) / 100.0
          OR (CEIL(ABS(v) * 100) / 100.0 - ABS(v) = ABS(v) - FLOOR(ABS(v) * 100) / 100.0
              AND CAST(FLOOR(ABS(v) * 100) AS INTEGER) % 2 = 1)
        THEN CEIL(ABS(v) * 100) / 100.0
        ELSE FLOOR(ABS(v) * 100) / 100.0
      END AS rv
  FROM long
)
SELECT
  r.sort_key, r.year,
  MAX(CASE WHEN r.col = 'purchase' THEN r.rv END) AS purchase,
  MAX(CASE WHEN r.col = 'sale' THEN r.rv END) AS sale,
  MAX(CASE WHEN r.col = 'kg' THEN r.rv END) AS kg,
  MAX(CASE WHEN r.col = 'kg_long' THEN r.rv END) AS kg_long,
  MAX(CASE WHEN r.col = 'kg_short' THEN r.rv END) AS kg_short,
  MAX(CASE WHEN r.col = 'option_profit' THEN r.rv END) AS option_profit,
  MAX(CASE WHEN r.col = 'kg_taxable' THEN r.rv END) AS kg_taxable,
  MAX(CASE WHEN r.col = 'donation' THEN r.rv END) AS donation,
  MAX(CASE WHEN r.col = 'total_basis' THEN r.rv END) AS total_basis
FROM rounded r
JOIN form4_annual_raw t ON t.sort_key = r.sort_key AND t.year = r.year
GROUP BY r.sort_key, r.year
ORDER BY r.sort_key, r.year;


-- -----------------------------------------------------------------------------
-- Q5. The five largest fortunes: per person and year, per year, and overall
--     Course: module 4 (subquery IN (SELECT ...), UNION ALL, CTE),
--     module 3 (GROUP BY), module 1 (COALESCE)
--     Beyond the course: printf('%010d', x) to write a CIK with the leading
--     zeros of the Form 4 data.
--
--     The five people are the four the paper's abstract names and Larry
--     Ellison; their filer CIKs come from the forbes_id crosswalk, so no CIK
--     is written here. Three blocks are stacked: the person-year rows, one
--     Total row per year (owner_cik_1 empty), and one overall Total row. All
--     in $ million, from the rounded person-year values; a missing basis
--     counts as 0.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_top5_raw;
CREATE TABLE form4_top5_raw AS
WITH top5 AS (
  SELECT *
  FROM form4_annual_individual
  WHERE owner_cik_1 IN (
    SELECT printf('%010d', cik)
    FROM form4_forbes_cik
    WHERE forbes_id IN ('mark-zuckerberg', 'jensen-huang', 'larry-page',
                        'sergey-brin', 'larry-ellison')
      AND cik IS NOT NULL
  )
)
SELECT 1 AS block, owner_cik_1, CAST(year AS TEXT) AS year, forbes_id,
       purchase, sale, kg, kg_long, kg_short, option_profit, kg_taxable,
       donation, COALESCE(total_basis, 0) AS total_basis
FROM top5
UNION ALL
SELECT 2, '', CAST(year AS TEXT), 'Total',
       SUM(purchase), SUM(sale), SUM(kg), SUM(kg_long), SUM(kg_short),
       SUM(option_profit), SUM(kg_taxable), SUM(donation),
       COALESCE(SUM(total_basis), 0)
FROM top5
GROUP BY year
UNION ALL
SELECT 3, '', 'Total', 'Total',
       SUM(purchase), SUM(sale), SUM(kg), SUM(kg_long), SUM(kg_short),
       SUM(option_profit), SUM(kg_taxable), SUM(donation),
       COALESCE(SUM(total_basis), 0)
FROM top5;

-- -----------------------------------------------------------------------------
-- Q5b. Top 5, rounded
--     Course: module 4 (CTE chain, UNION ALL), module 3 (GROUP BY with
--     MAX(CASE WHEN ...)), module 1 (CASE WHEN)
--     Beyond the course: unpivot and pivot; FLOOR, CEIL and SIGN; the rounding
--     rule of R's round() (see the header).
--
--     block keeps the three stacked parts in order.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_annual_top5;
CREATE TABLE form4_annual_top5 AS
WITH long AS (
  SELECT block, owner_cik_1, year, forbes_id, 'purchase' AS col, purchase AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'sale' AS col, sale AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'kg' AS col, kg AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'kg_long' AS col, kg_long AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'kg_short' AS col, kg_short AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'option_profit' AS col, option_profit AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'kg_taxable' AS col, kg_taxable AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'donation' AS col, donation AS v FROM form4_top5_raw
  UNION ALL
  SELECT block, owner_cik_1, year, forbes_id, 'total_basis' AS col, total_basis AS v FROM form4_top5_raw
),
rounded AS (
  SELECT long.*,
    SIGN(v) * CASE
        WHEN CEIL(ABS(v) * 100) / 100.0 - ABS(v) < ABS(v) - FLOOR(ABS(v) * 100) / 100.0
          OR (CEIL(ABS(v) * 100) / 100.0 - ABS(v) = ABS(v) - FLOOR(ABS(v) * 100) / 100.0
              AND CAST(FLOOR(ABS(v) * 100) AS INTEGER) % 2 = 1)
        THEN CEIL(ABS(v) * 100) / 100.0
        ELSE FLOOR(ABS(v) * 100) / 100.0
      END AS rv
  FROM long
)
SELECT
  r.block, r.owner_cik_1, r.year, r.forbes_id,
  MAX(CASE WHEN r.col = 'purchase' THEN r.rv END) AS purchase,
  MAX(CASE WHEN r.col = 'sale' THEN r.rv END) AS sale,
  MAX(CASE WHEN r.col = 'kg' THEN r.rv END) AS kg,
  MAX(CASE WHEN r.col = 'kg_long' THEN r.rv END) AS kg_long,
  MAX(CASE WHEN r.col = 'kg_short' THEN r.rv END) AS kg_short,
  MAX(CASE WHEN r.col = 'option_profit' THEN r.rv END) AS option_profit,
  MAX(CASE WHEN r.col = 'kg_taxable' THEN r.rv END) AS kg_taxable,
  MAX(CASE WHEN r.col = 'donation' THEN r.rv END) AS donation,
  MAX(CASE WHEN r.col = 'total_basis' THEN r.rv END) AS total_basis
FROM rounded r
JOIN form4_top5_raw t ON t.block = r.block AND t.owner_cik_1 = r.owner_cik_1 AND t.year = r.year AND t.forbes_id = r.forbes_id
GROUP BY r.block, r.owner_cik_1, r.year, r.forbes_id
ORDER BY r.block, r.owner_cik_1, r.year, r.forbes_id;
