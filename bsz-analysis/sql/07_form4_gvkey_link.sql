-- =============================================================================
-- Query 7: Form 4 issuers to Compustat securities (the link table)
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook), first half of
-- the join of the clean Form 4 trades (query 4) to daily share prices. SEC
-- filings identify a company by its CIK and ticker symbol; Compustat
-- identifies a security by gvkey (the company) and iid (the issue). This file
-- finds the security of every issuer in the Form 4 data:
--   1. by CIK and ticker together;
--   2. failing that, by CIK alone, preferring a security whose years in
--      Compustat overlap the issuer's years in the Form 4 data;
--   3. then a gitignored table of hand-checked fixes replaces a few wrong
--      matches of step 2 and fills a few issuers no rule matched
--      (data-raw/form4-gvkey-fixes.csv).
-- Its last table, form4_gvkey_list, tells py/load_bundle.py which securities
-- to keep from the 11 GB daily price file; sql/08_form4_compustat.sql then
-- joins the prices.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   form4_clean           query 4's clean trades (run sql/04_form4_clean.sql
--                         first)
--   comp_daily_snapshots  one January trading day per year, 2004 to 2026,
--                         every Compustat security; snap_order 1 is the newest
--   form4_gvkey_fixes     the hand-checked fixes (gitignored; see
--                         data-raw/form4-gvkey-fixes.example.csv)
--
-- Outputs (tables in the same database):
--   form4_sec_issuers   intermediate: one row per issuer CIK in the Form 4 data
--   form4_comp_secs     intermediate: one row per Compustat security (USD)
--   form4_gvkey_link    issuer CIK to (gvkey, iid), with the step that found it
--   form4_gvkey_list    the distinct gvkeys, as 6-digit text, for the loader
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/07_form4_gvkey_link.sql --export form4_gvkey_link
--   Rscript R/run_sql.R   sql/07_form4_gvkey_link.sql --export form4_gvkey_link
--   python  py/load_bundle.py comp_daily_form4
--
-- "Last" values: the R code summarises with dplyr's last(), which takes the
-- value of the last row of each group in the order the rows were stacked. In
-- SQL a table has no row order, so the order is a column (row_num,
-- snap_order) and "last" is the row with the largest one, picked with
-- ROW_NUMBER() ... ORDER BY ... DESC = 1.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. One row per issuer in the Form 4 data
--     Course: module 3 (GROUP BY with MIN and MAX), module 4 (CTE),
--     module 5 (ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ... DESC))
--     Beyond the course: UPPER(); CAST of text with leading zeros to a number.
--
--     Per issuer CIK: the name and ticker of its last trade in file order,
--     the ticker in capitals, and the first and last year it trades. The CIK
--     becomes a number ("0001341439" to 1341439) to match Compustat's.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_sec_issuers;
CREATE TABLE form4_sec_issuers AS
WITH ranked AS (
  SELECT
    issuer_cik,
    issuer_name,
    issuer_symbol,
    ROW_NUMBER() OVER (PARTITION BY issuer_cik ORDER BY row_num DESC) AS from_end
  FROM form4_clean
),
years AS (
  SELECT issuer_cik, MIN(year) AS sec_year_first, MAX(year) AS sec_year_last
  FROM form4_clean
  GROUP BY issuer_cik
)
SELECT
  CAST(r.issuer_cik AS INTEGER) AS issuer_cik,
  r.issuer_name,
  UPPER(r.issuer_symbol)        AS issuer_symbol,
  y.sec_year_first,
  y.sec_year_last
FROM ranked r
JOIN years y ON y.issuer_cik = r.issuer_cik
WHERE r.from_end = 1;


-- -----------------------------------------------------------------------------
-- Q2. One row per Compustat security traded in US dollars
--     Course: module 1 (WHERE), module 3 (GROUP BY with MIN and MAX),
--     module 4 (CTE), module 5 (ROW_NUMBER)
--
--     The snapshots are stacked newest first, so the "last" row of a security
--     is its row in the oldest snapshot that lists it: ticker, name, CIK and
--     CUSIP come from there, missing values included. Securities quoted in
--     another currency (Canadian listings) are left out first.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_comp_secs;
CREATE TABLE form4_comp_secs AS
WITH usd AS (
  SELECT *
  FROM comp_daily_snapshots
  WHERE curcdd = 'USD'
),
ranked AS (
  SELECT
    usd.*,
    ROW_NUMBER() OVER (PARTITION BY gvkey, iid
                       ORDER BY snap_order DESC, row_num DESC) AS from_end
  FROM usd
),
dates AS (
  SELECT gvkey, iid,
         MIN(datadate) AS comp_datadate_first,
         MAX(datadate) AS comp_datadate_last
  FROM usd
  GROUP BY gvkey, iid
)
SELECT
  r.gvkey,
  r.iid,
  r.tic,
  d.comp_datadate_first,
  d.comp_datadate_last,
  r.conm,
  r.cik,
  r.cusip
FROM ranked r
JOIN dates d ON d.gvkey = r.gvkey AND d.iid = r.iid
WHERE r.from_end = 1;


-- -----------------------------------------------------------------------------
-- Q3. The link table: issuer CIK to Compustat security
--     Course: module 2 (LEFT JOIN, INNER JOIN), module 4 (CTE chain,
--     UNION ALL), module 5 (ROW_NUMBER to pick one row per group), module 1
--     (CASE WHEN, COALESCE)
--     Beyond the course: ORDER BY on a true/false expression to put NULLs
--     last.
--
--     * by_cik_tic: step 1, CIK and ticker both equal. A CIK and ticker
--       shared by two securities gives two rows, as dplyr's left_join() does.
--     * unmatched: the issuers step 1 did not match.
--     * by_cik: step 2, CIK alone. overlap is true when the issuer's Form 4
--       years and the security's Compustat years overlap (NULL when either
--       side has no years). Per issuer the first row is kept in this order:
--       overlap true, then false, then NULL; then iid; then gvkey (the order
--       in which the R code meets the candidates).
--     * fixed: step 3. A cik_match fix replaces the security step 2 found; a
--       manual fix gives one to an issuer still without a match. COALESCE
--       keeps the original value when there is no fix.
--     method records which step decided the row.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_gvkey_link;
CREATE TABLE form4_gvkey_link AS
WITH by_cik_tic AS (
  SELECT s.issuer_cik, c.gvkey, c.iid
  FROM form4_sec_issuers s
  JOIN form4_comp_secs c
    ON c.cik = s.issuer_cik
   AND c.tic = s.issuer_symbol
),
unmatched AS (
  SELECT *
  FROM form4_sec_issuers
  WHERE issuer_cik NOT IN (SELECT issuer_cik FROM by_cik_tic)
),
candidates AS (
  SELECT
    u.issuer_cik,
    c.gvkey,
    c.iid,
    (u.sec_year_first <= CAST(substr(c.comp_datadate_last, 1, 4) AS INTEGER))
      AND (u.sec_year_last >= CAST(substr(c.comp_datadate_first, 1, 4) AS INTEGER))
      AS overlap
  FROM unmatched u
  LEFT JOIN form4_comp_secs c
    ON c.cik = u.issuer_cik
),
by_cik AS (
  SELECT issuer_cik, gvkey, iid
  FROM (
    SELECT
      candidates.*,
      ROW_NUMBER() OVER (
        PARTITION BY issuer_cik
        ORDER BY (overlap IS NULL), overlap DESC, (iid IS NULL), iid, gvkey
      ) AS pick
    FROM candidates
  )
  WHERE pick = 1
),
fixed AS (
  SELECT
    b.issuer_cik,
    CASE WHEN b.gvkey IS NOT NULL THEN COALESCE(fc.gvkey, b.gvkey)
         ELSE fm.gvkey END AS gvkey,
    CASE WHEN b.gvkey IS NOT NULL THEN COALESCE(fc.iid, b.iid)
         ELSE fm.iid END   AS iid,
    CASE WHEN b.gvkey IS NOT NULL AND fc.gvkey IS NOT NULL THEN 'fix of cik match'
         WHEN b.gvkey IS NOT NULL THEN 'cik'
         WHEN fm.gvkey IS NOT NULL THEN 'manual fix'
         ELSE 'none' END   AS method
  FROM by_cik b
  LEFT JOIN form4_gvkey_fixes fc
    ON fc.stage = 'cik_match' AND fc.issuer_cik = b.issuer_cik
  LEFT JOIN form4_gvkey_fixes fm
    ON fm.stage = 'manual' AND fm.issuer_cik = b.issuer_cik
)
SELECT issuer_cik, gvkey, iid, 'cik and ticker' AS method FROM by_cik_tic
UNION ALL
SELECT issuer_cik, gvkey, iid, method FROM fixed
ORDER BY issuer_cik, gvkey, iid;


-- -----------------------------------------------------------------------------
-- Q4. The securities to keep from the daily price file
--     Course: module 1 (WHERE ... IS NOT NULL, DISTINCT)
--     Beyond the course: printf('%06d', x) to write a number with leading
--     zeros, as the price file writes gvkey.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_gvkey_list;
CREATE TABLE form4_gvkey_list AS
SELECT DISTINCT printf('%06d', gvkey) AS gvkey_text
FROM form4_gvkey_link
WHERE gvkey IS NOT NULL
ORDER BY gvkey_text;
