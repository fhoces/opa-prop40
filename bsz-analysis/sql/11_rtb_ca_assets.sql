-- =============================================================================
-- Query 11: Forbes real-time asset files to California holdings and a
--           ticker-to-Compustat crosswalk
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook), first step of
-- the Compustat chain for public equity wealth and dividends. Forbes publishes,
-- with each real-time snapshot, the holdings behind every fortune: listed
-- stocks (with ticker, shares and value), private stakes and option grants.
-- This file keeps, for the seven year-end snapshots of query 1, the listed
-- holdings of California billionaires, one row per person and security, and
-- matches each ticker to a Compustat security (gvkey and iid), so that the
-- next step can value the holdings and their dividends with Compustat prices.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   rtb_assets                 one row per person, holding and snapshot
--   comp_na_yearend            Compustat North America securities on the last
--                              trading day of 2019 to 2025
--   asset_residency_overrides  the residency rule of this step (gitignored;
--                              same schema as residency-overrides.csv). It is
--                              its own list: the authors' asset code and their
--                              query-1 code do not name the same people.
--   rtb_asset_ticker_fixes     tickers missing from the asset files, filled
--                              by hand (gitignored; see the .example.csv)
--   rtb_ticker_gvkey_fixes     tickers matched to a security by hand
--                              (gitignored; see the .example.csv)
--
-- Outputs (tables in the same database):
--   rtb_ca_assets          listed holdings of CA billionaires, per snapshot
--   rtb_tickers            distinct tickers, split into the bare code and the
--                          market suffix, with their region
--   comp_na_tickers        intermediate: one row per Compustat security
--   rtb_ticker_gvkey_na    North American tickers to (gvkey, iid)
--   rtb_ticker_gvkey_int   international tickers to (gvkey, iid)
--   rtb_gvkey_na_list      the distinct North American gvkeys
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/11_rtb_ca_assets.sql --export rtb_ca_assets rtb_ticker_gvkey_na rtb_ticker_gvkey_int
--   Rscript R/run_sql.R   sql/11_rtb_ca_assets.sql --export (same tables)
--   python  py/check_rtb_ca_assets.py
--
-- Money: $ million, as in the asset files.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Listed holdings of California billionaires, per snapshot
--     Course: module 1 (WHERE, IN (SELECT ...), NOT IN (SELECT ...), COALESCE),
--     module 2 (LEFT JOIN), module 3 (GROUP BY with SUM), module 4 (CTE
--     chain), module 5 (ROW_NUMBER for "first")
--     Beyond the course: renaming every column with a prefix in the final
--     SELECT.
--
--     * kept: California residents by this step's rule (Forbes state, plus
--       the override table's includes, minus its excludes); without private
--       wealth (company "Forbes Private Wealth") and without unexercised
--       options (stockOption 1). As in R, a holding with no company name or
--       no stockOption value fails these tests and is dropped.
--     * grouped: one row per person, exchange and ticker: shares, value and
--       share value summed, the other columns from the group's first row in
--       file order. A missing exchange or ticker is a group of its own, as in
--       dplyr's group_by().
--     * final SELECT: the hand-filled tickers (and exchanges) for holdings
--       that have none, then the authors' column names with a forbes_
--       prefix. snapshot is the list's date; year is its year, 2025 for the
--       2026-01-01 list. Rows are sorted by value, largest first; ties keep
--       the order of the R summary (by id, exchange and ticker, missing
--       values last).
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS rtb_ca_assets;
CREATE TABLE rtb_ca_assets AS
WITH kept AS (
  SELECT *
  FROM rtb_assets
  WHERE (state = 'California'
         OR forbes_id IN (SELECT forbes_id FROM asset_residency_overrides
                          WHERE rule = 'include'))
    AND forbes_id NOT IN (SELECT forbes_id FROM asset_residency_overrides
                          WHERE rule = 'exclude')
    AND companyName <> 'Forbes Private Wealth'
    AND stockOption <> 1
),
ranked AS (
  SELECT
    kept.*,
    ROW_NUMBER() OVER (PARTITION BY snapshot, forbes_id, exchange, ticker
                       ORDER BY row_num) AS rn
  FROM kept
),
grouped AS (
  SELECT
    snapshot, forbes_id, exchange, ticker,
    COALESCE(SUM(numberOfShares), 0) AS numberOfShares,
    COALESCE(SUM(currentValue), 0)   AS currentValue,
    COALESCE(SUM(shareValue), 0)     AS shareValue
  FROM kept
  GROUP BY snapshot, forbes_id, exchange, ticker
),
with_first AS (
  SELECT
    g.*,
    f.date, f.forbes_name, f.companyName, f.currencyCode, f.exchangeRate,
    f.sharePrice, f.currentPrice
  FROM grouped g
  JOIN ranked f
    ON  f.snapshot = g.snapshot
    AND f.forbes_id = g.forbes_id
    AND f.exchange IS g.exchange
    AND f.ticker IS g.ticker
    AND f.rn = 1
)
SELECT
  w.snapshot,
  CASE WHEN substr(w.snapshot, 1, 4) = '2026' THEN 2025
       ELSE CAST(substr(w.snapshot, 1, 4) AS INTEGER) END  AS year,
  w.forbes_id,
  COALESCE(fx.exchange, w.exchange)  AS forbes_exchange,
  COALESCE(fx.ticker, w.ticker)      AS forbes_ticker,
  w.date                             AS forbes_date,
  w.forbes_name,
  w.companyName                      AS forbes_companyname,
  w.numberOfShares                   AS forbes_numberofshares,
  w.currentValue                     AS forbes_currentvalue,
  w.shareValue                       AS forbes_sharevalue,
  w.currencyCode                     AS forbes_currencycode,
  w.exchangeRate                     AS forbes_exchangerate,
  w.sharePrice                       AS forbes_shareprice,
  w.currentPrice                     AS forbes_currentprice
FROM with_first w
LEFT JOIN rtb_asset_ticker_fixes fx
  ON  fx.year = CASE WHEN substr(w.snapshot, 1, 4) = '2026' THEN 2025
                     ELSE CAST(substr(w.snapshot, 1, 4) AS INTEGER) END
  AND fx.forbes_id = w.forbes_id
  AND fx.company_name = w.companyName
ORDER BY w.snapshot, w.currentValue DESC, w.forbes_id,
         (w.exchange IS NULL), w.exchange, (w.ticker IS NULL), w.ticker;


-- -----------------------------------------------------------------------------
-- Q2. The distinct tickers, split into code and market suffix
--     Course: module 1 (CASE WHEN, WHERE ... IS NOT NULL), module 4 (CTE)
--     Beyond the course: SQLite has no regular expressions, so the suffix is
--     cut with rtrim(), substr() and GLOB.
--
--     A Forbes ticker ends in a market suffix: "-US", "-CA", "-FR", and so
--     on (made-up examples: "ABC-US", "1234-JP", "XYZ-B-US"). R takes the
--     suffix with the pattern "-[A-Za-z]+$" (a hyphen and letters up to the
--     end). Here:
--       * prefix: rtrim(t, replace(t, '-', '')) strips from the right every
--         character that is not a hyphen, so it keeps t up to its last
--         hyphen ("XYZ-B-" for "XYZ-B-US");
--       * tail: what follows the last hyphen ("US");
--       * when there is a hyphen and the tail is letters only (GLOB
--         '*[^A-Za-z]*' finds a non-letter), the suffix is "-" || tail and the
--         code is the prefix without its hyphen; otherwise there is no suffix
--         and the code is the whole ticker.
--     region is North America for the suffixes -US and -CA, international
--     otherwise (including no suffix).
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS rtb_tickers;
CREATE TABLE rtb_tickers AS
WITH t AS (
  SELECT DISTINCT forbes_ticker
  FROM rtb_ca_assets
  WHERE forbes_ticker IS NOT NULL
),
parts AS (
  SELECT
    forbes_ticker,
    rtrim(forbes_ticker, replace(forbes_ticker, '-', '')) AS prefix
  FROM t
),
split AS (
  SELECT
    forbes_ticker,
    prefix,
    substr(forbes_ticker, length(prefix) + 1) AS tail
  FROM parts
),
coded AS (
  SELECT
    forbes_ticker,
    CASE WHEN prefix <> '' AND tail <> '' AND tail NOT GLOB '*[^A-Za-z]*'
         THEN '-' || tail END                                        AS ticker_suffix,
    CASE WHEN prefix <> '' AND tail <> '' AND tail NOT GLOB '*[^A-Za-z]*'
         THEN substr(prefix, 1, length(prefix) - 1)
         ELSE forbes_ticker END                                      AS ticker_clean
  FROM split
)
SELECT
  forbes_ticker,
  ticker_clean,
  ticker_suffix,
  CASE WHEN ticker_suffix IN ('-US', '-CA') THEN 'NorthAmerica'
       ELSE 'International' END AS region
FROM coded
ORDER BY forbes_ticker, ticker_clean;


-- -----------------------------------------------------------------------------
-- Q3. One row per Compustat North America security (intermediate table)
--     Course: module 4 (CTE), module 5 (ROW_NUMBER for "first")
--
--     The seven year-end files are stacked from 2019 on, and each security
--     takes its ticker from the first file that lists it, as R's first()
--     does after the stacking.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS comp_na_tickers;
CREATE TABLE comp_na_tickers AS
SELECT gvkey, iid, tic, conm
FROM (
  SELECT
    comp_na_yearend.*,
    ROW_NUMBER() OVER (PARTITION BY gvkey, iid ORDER BY snap_order, row_num) AS rn
  FROM comp_na_yearend
)
WHERE rn = 1;


-- -----------------------------------------------------------------------------
-- Q4. North American tickers to Compustat securities
--     Course: module 2 (LEFT JOIN), module 1 (COALESCE, CASE WHEN)
--
--     A ticker's code joins to the Compustat ticker; a code shared by two
--     securities gives two rows, as dplyr's left_join() does. A hand fix
--     (region na) then sets the security of every row of its code.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS rtb_ticker_gvkey_na;
CREATE TABLE rtb_ticker_gvkey_na AS
SELECT
  t.forbes_ticker,
  COALESCE(fx.gvkey, c.gvkey) AS gvkey,
  CASE WHEN fx.gvkey IS NOT NULL THEN fx.iid ELSE c.iid END AS iid
FROM rtb_tickers t
LEFT JOIN comp_na_tickers c
  ON c.tic = t.ticker_clean
LEFT JOIN rtb_ticker_gvkey_fixes fx
  ON fx.region = 'na' AND fx.ticker_clean = t.ticker_clean
WHERE t.region = 'NorthAmerica'
ORDER BY t.forbes_ticker, t.ticker_clean, c.gvkey, c.iid;


-- -----------------------------------------------------------------------------
-- Q5. International tickers to Compustat securities
--     Course: module 2 (LEFT JOIN)
--
--     No automatic match: only the hand fixes (region int) give a security.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS rtb_ticker_gvkey_int;
CREATE TABLE rtb_ticker_gvkey_int AS
SELECT t.forbes_ticker, fx.gvkey, fx.iid
FROM rtb_tickers t
LEFT JOIN rtb_ticker_gvkey_fixes fx
  ON fx.region = 'int' AND fx.ticker_clean = t.ticker_clean
WHERE t.region = 'International'
ORDER BY t.forbes_ticker, t.ticker_clean;


-- -----------------------------------------------------------------------------
-- Q6. The distinct North American gvkeys
--     Course: module 1 (DISTINCT, WHERE ... IS NOT NULL)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS rtb_gvkey_na_list;
CREATE TABLE rtb_gvkey_na_list AS
SELECT DISTINCT gvkey
FROM rtb_ticker_gvkey_na
WHERE gvkey IS NOT NULL;
