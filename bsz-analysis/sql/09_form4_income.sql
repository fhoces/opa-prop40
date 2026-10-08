-- =============================================================================
-- Query 9: Form 4 trades to income items (sales, gifts, option and RSU profits)
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook). From the
-- trades with prices (query 8), per trade:
--   * open-market sales and purchases: shares and dollars;
--   * gifts of stock (code G, the charitable contributions): shares, valued
--     at the day's closing price;
--   * profits from exercised stock options and vested restricted stock units
--     (RSUs), which are ordinary income, with rules that look at the whole
--     filing (an option exercise has an exercise price above zero; an RSU
--     vesting shows up either as an exercise at price zero or as shares
--     withheld for tax, code F).
-- It also writes the input of the capital-gains step: the trades that add to
-- or draw from a person's holding of a stock, in the order they are
-- processed. That step is sequential (each sale uses up the lots bought
-- before it), so it is not SQL: py/form4_basis.py and its R twin
-- R/form4_basis.R read form4_basis_input and write the results back.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   form4_compustat           query 8's trades with prices
--   form4_excluded_filings    filings left out of every income item
--                             (gitignored; see
--                             data-raw/form4-excluded-filings.example.csv)
--
-- Outputs (tables in the same database):
--   form4_income       one row per trade kept: the trade, the income items
--                      and the filing-level flags behind them
--   form4_basis_input  the trades that matter for capital gains, with the
--                      processing order (seq) within each owner and issuer
--
-- Run from bsz-analysis/ (then the basis step, then query 10):
--   python  py/run_sql.py sql/09_form4_income.sql
--   python  py/form4_basis.py          (or: Rscript R/form4_basis.R)
--   python  py/run_sql.py sql/10_form4_annual.sql --export ...
--
-- Money: dollars, as in the source.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Income items per trade
--     Course: module 1 (CASE WHEN), module 4 (CTE chain, NOT IN (SELECT ...)),
--     module 5 (window aggregates MAX(...) OVER (PARTITION BY ...))
--     Beyond the course: MAX over a 0/1 flag as "any row of the group".
--
--     * flags: per filing (accession number), whether any of its rows is an
--       exercise at price zero (has_ma0), a withholding of shares for tax
--       (has_f), or an option exercise in the derivative table at a price
--       above zero (has_option_derivative). R's any(..., na.rm = TRUE) is
--       MAX(CASE WHEN condition THEN 1 ELSE 0 END) over the filing: a row
--       whose condition is unknown (NULL) counts as 0, as na.rm drops it.
--     * items: the income items of each trade. The three cases of options
--       and RSUs are tried in order and the first that holds wins, as in R's
--       case_when(). For an RSU vesting seen only through the withholding,
--       the shares received are twice the shares withheld (the withholding
--       is taken to cover half), valued at the withholding price.
--     * final SELECT: the filings on the exclusion table are dropped after
--       the flags are computed, as in the authors' code.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_income;
CREATE TABLE form4_income AS
WITH base AS (
  SELECT
    out_order AS row_id,
    *,
    (code = 'M' AND type = 'A' AND price_per_share > 0) AS is_option_exercise,
    (code = 'M' AND type = 'A' AND price_per_share = 0) AS is_ma0
  FROM form4_compustat
),
flags AS (
  SELECT
    base.*,
    MAX(CASE WHEN is_ma0 THEN 1 ELSE 0 END)
      OVER (PARTITION BY folder) AS has_ma0,
    MAX(CASE WHEN code = 'F' AND type = 'D' THEN 1 ELSE 0 END)
      OVER (PARTITION BY folder) AS has_f,
    MAX(CASE WHEN code = 'M' AND type = 'A' AND table_num = 2
              AND price_per_share > 0 THEN 1 ELSE 0 END)
      OVER (PARTITION BY folder) AS has_option_derivative
  FROM base
),
items AS (
  SELECT
    flags.*,
    CASE WHEN type = 'D' AND code = 'S' THEN shares_traded END AS shares_sold,
    CASE WHEN type = 'A' AND code = 'P' THEN shares_traded END AS shares_purchased,
    CASE WHEN type = 'D' AND code = 'G' THEN shares_traded END AS shares_donated,
    CASE WHEN type = 'D' AND code = 'F' AND has_f = 1 AND has_option_derivative = 0
         THEN shares_traded END                                AS shares_rsu_withheld
  FROM flags
)
SELECT
  row_id,
  folder,
  forbes_id,
  issuer_cik,
  issuer_symbol,
  transaction_date,
  table_num,
  code,
  type,
  shares_traded,
  price_per_share,
  owner_cik_1,
  year,
  prccd,
  ajexdi,
  has_ma0,
  has_f,
  has_option_derivative,
  shares_sold,
  shares_purchased,
  shares_sold * price_per_share      AS sale,
  shares_purchased * price_per_share AS purchase,
  shares_donated,
  shares_donated * prccd             AS donation,
  shares_rsu_withheld,
  CASE
    WHEN is_option_exercise THEN shares_traded
    WHEN has_ma0 = 1 AND is_ma0 THEN shares_traded
    WHEN has_ma0 = 0 AND has_f = 1 AND has_option_derivative = 0
         AND type = 'D' AND code = 'F' THEN shares_rsu_withheld * 2
  END AS shares_option,
  CASE
    WHEN is_option_exercise THEN shares_traded * (prccd - price_per_share)
    WHEN has_ma0 = 1 AND is_ma0 THEN shares_traded * prccd
    WHEN has_ma0 = 0 AND has_f = 1 AND has_option_derivative = 0
         AND type = 'D' AND code = 'F' THEN shares_rsu_withheld * price_per_share * 2
  END AS option_profit
FROM items
WHERE folder NOT IN (SELECT folder FROM form4_excluded_filings)
ORDER BY row_id;


-- -----------------------------------------------------------------------------
-- Q2. The input of the capital-gains step
--     Course: module 1 (WHERE with AND / OR, CASE WHEN), module 5
--     (ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...))
--
--     The trades that build up or draw down a holding: from the
--     non-derivative table (table 1), exercises (M, A), purchases (P, A),
--     withholdings (F, D) and sales (S, D); from the derivative table
--     (table 2), exercises. seq is the processing order within one owner and
--     issuer: by date, acquisitions before sales on the same day (so a lot
--     bought and sold the same day is in the cost basis), then file order.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_basis_input;
CREATE TABLE form4_basis_input AS
SELECT
  owner_cik_1,
  issuer_cik,
  ROW_NUMBER() OVER (
    PARTITION BY owner_cik_1, issuer_cik
    ORDER BY transaction_date,
             CASE WHEN code = 'S' AND type = 'D' THEN 2 ELSE 1 END,
             row_id
  ) AS seq,
  row_id,
  folder,
  year,
  transaction_date,
  code,
  type,
  price_per_share,
  prccd,
  ajexdi,
  shares_sold,
  shares_purchased,
  shares_option
FROM form4_income
WHERE (table_num = 1 AND ((code = 'M' AND type = 'A') OR (code = 'P' AND type = 'A')
                          OR (code = 'F' AND type = 'D') OR (code = 'S' AND type = 'D')))
   OR (table_num = 2 AND code = 'M' AND type = 'A')
ORDER BY owner_cik_1, issuer_cik, seq;
