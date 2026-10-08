-- =============================================================================
-- Query 8: Form 4 trades joined to Compustat daily share prices
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook), second half
-- of the join of the clean Form 4 trades to daily prices. Each trade gets the
-- closing price (prccd), shares outstanding (cshoc), split adjustment factor
-- (ajexdi) and currency of its security on the trade date. When the trade
-- date has no price (a weekend or holiday, or a day without a quote), the
-- next trading day with a row for that security is used instead. Later steps
-- use the price to value gifts of stock and option exercises, and ajexdi to
-- compare share counts across stock splits.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   form4_clean       query 4's clean trades
--   form4_gvkey_link  query 7's issuer-to-security link
--   comp_daily_form4  daily Compustat rows of the linked securities, loaded
--                     after query 7 (python py/load_bundle.py comp_daily_form4)
--
-- Outputs (tables in the same database):
--   form4_sec_gvkey   intermediate: trades from 2003-06-30 on, with gvkey/iid
--   form4_compustat   every such trade with its price data, 27 columns plus
--                     out_order (the authors' row order)
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/08_form4_compustat.sql --export form4_compustat
--   Rscript R/run_sql.R   sql/08_form4_compustat.sql --export form4_compustat
--   python  py/check_form4_compustat.py
--
-- Row order: the R code stacks four groups, in this order: trades priced on
-- their own date, trades priced on a later date, trades with a security but
-- no later price, trades with no security. out_order numbers the rows in that
-- order (by trade within each group), so an export lists them as the authors'
-- file does.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Trades with their Compustat security (intermediate table)
--     Course: module 2 (LEFT JOIN), module 1 (WHERE on a date), module 5
--     (ROW_NUMBER() OVER (ORDER BY ...) as a row id)
--     Beyond the course: comparing ISO dates as text ('2003-06-30').
--
--     row_id numbers the trades in file order before the date filter, as the
--     R code does. The daily file starts on 2003-06-30, so earlier trades are
--     left out. The issuer CIK becomes a number, the type of the link table.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_sec_gvkey;
CREATE TABLE form4_sec_gvkey AS
WITH numbered AS (
  SELECT
    f.*,
    CAST(f.issuer_cik AS INTEGER) AS issuer_cik_num,
    l.gvkey,
    l.iid,
    ROW_NUMBER() OVER (ORDER BY f.row_num, l.gvkey, l.iid) AS row_id
  FROM form4_clean f
  LEFT JOIN form4_gvkey_link l
    ON l.issuer_cik = CAST(f.issuer_cik AS INTEGER)
)
SELECT *
FROM numbered
WHERE transaction_date >= '2003-06-30';

CREATE INDEX idx_form4_sec_gvkey ON form4_sec_gvkey (row_id);


-- -----------------------------------------------------------------------------
-- Q2. Every trade with its price data
--     Course: module 2 (LEFT JOIN on three keys), module 3 (GROUP BY with
--     MIN), module 4 (CTE chain, UNION ALL, NOT IN (SELECT ...)), module 5
--     (ROW_NUMBER for the output order)
--     Beyond the course: a join condition with >= (a "next date on or after"
--     match); CAST(NULL AS ...) to type the empty columns of a UNION ALL.
--
--     * exact: each trade joined to the daily row of its security on the
--       trade date.
--     * matched: the trades that found a price that way. A daily row without
--       a price does not count; such a trade is retried below, as in R.
--     * unmatched: the others.
--     * next_date: for an unmatched trade with a security, the first date on
--       or after the trade date with a daily row for that security. The R
--       code joins every date of the security and keeps the earliest one
--       that is not before the trade; MIN() over the dates that pass the
--       test is the same thing.
--     * refilled: those trades joined to the daily row of that date.
--     * dropped: unmatched trades with a security but no daily row on or
--       after the trade date; they are kept, with empty price columns.
--     * no_security: trades whose issuer has no Compustat security; kept the
--       same way.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_compustat;
CREATE TABLE form4_compustat AS
WITH exact AS (
  SELECT
    s.*,
    d.tic, d.prccd, d.cshoc, d.adrrc, d.curcdd, d.ajexdi
  FROM form4_sec_gvkey s
  LEFT JOIN comp_daily_form4 d
    ON  d.gvkey = s.gvkey
    AND d.iid = s.iid
    AND d.datadate = s.transaction_date
),
matched AS (
  SELECT 1 AS part, exact.*, transaction_date AS comp_datadate
  FROM exact
  WHERE prccd IS NOT NULL
),
unmatched AS (
  SELECT row_id, gvkey, iid, transaction_date
  FROM exact
  WHERE prccd IS NULL
),
next_date AS (
  SELECT u.row_id, MIN(d.datadate) AS comp_datadate
  FROM (SELECT DISTINCT row_id, gvkey, iid, transaction_date
        FROM unmatched WHERE gvkey IS NOT NULL) u
  JOIN comp_daily_form4 d
    ON  d.gvkey = u.gvkey
    AND d.iid = u.iid
    AND d.datadate >= u.transaction_date
  GROUP BY u.row_id
),
refilled AS (
  SELECT
    2 AS part, s.*,
    d.tic, d.prccd, d.cshoc, d.adrrc, d.curcdd, d.ajexdi,
    n.comp_datadate
  FROM next_date n
  JOIN form4_sec_gvkey s ON s.row_id = n.row_id
  LEFT JOIN comp_daily_form4 d
    ON  d.gvkey = s.gvkey
    AND d.iid = s.iid
    AND d.datadate = n.comp_datadate
),
not_priced AS (
  SELECT
    CASE WHEN s.gvkey IS NULL THEN 4 ELSE 3 END AS part, s.*,
    CAST(NULL AS TEXT) AS tic, CAST(NULL AS REAL) AS prccd,
    CAST(NULL AS REAL) AS cshoc, CAST(NULL AS REAL) AS adrrc,
    CAST(NULL AS TEXT) AS curcdd, CAST(NULL AS REAL) AS ajexdi,
    CAST(NULL AS TEXT) AS comp_datadate
  FROM unmatched u
  JOIN form4_sec_gvkey s ON s.row_id = u.row_id
  WHERE u.row_id NOT IN (SELECT row_id FROM next_date)
),
stacked AS (
  SELECT * FROM matched
  UNION ALL
  SELECT * FROM refilled
  UNION ALL
  SELECT * FROM not_priced
)
SELECT
  ROW_NUMBER() OVER (ORDER BY part, row_id, comp_datadate, prccd, cshoc) AS out_order,
  folder,
  forbes_id,
  issuer_name,
  issuer_cik_num AS issuer_cik,
  issuer_symbol,
  security_title,
  transaction_date,
  table_num,
  code,
  shares_traded,
  price_per_share,
  type,
  ownership_nature,
  owner_name_1,
  owner_cik_1,
  year,
  sale,
  purchase,
  gvkey,
  iid,
  tic,
  prccd,
  cshoc,
  adrrc,
  curcdd,
  ajexdi,
  comp_datadate
FROM stacked
ORDER BY out_order;
