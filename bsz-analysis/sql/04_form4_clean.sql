-- =============================================================================
-- Query 4: Form 4 filings, raw to clean
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook). SEC Form 4 is
-- the form on which company insiders report their trades in the company's
-- stock. The authors scraped every Form 4 filed by the California
-- billionaires on their list (about 222k reported transactions) and clean
-- them into one row per kept transaction, with the sale or purchase amount in
-- dollars and the Forbes id of the filer. The clean table is the input of
-- the later steps: the join to daily share prices, the yearly sums of sales
-- and purchases per person, and from there the sale and purchase columns of
-- the public sheet data_sec_all.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   form4_raw                one row per reported transaction, 90 source
--                            columns plus row_num (the file order); Folder is
--                            loaded as folder and table as table_num
--   form4_forbes_cik         forbes_id to SEC filer CIK
--   form4_price_corrections  filings whose reported price per share is off by
--                            a power of ten (gitignored; see
--                            data-raw/form4-price-corrections.example.csv)
--
-- Outputs (tables in the same database):
--   form4_dedup   intermediate: single-owner filings, exact copies removed
--   form4_clean   the clean transactions, 18 columns plus row_num
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/04_form4_clean.sql --export form4_clean
--   Rscript R/run_sql.R   sql/04_form4_clean.sql --export form4_clean
--   python  py/check_form4_clean.py
--
-- House style follows sql-industry-prep and sql/01_rtb_ca.sql: no sqlite3
-- dot-commands, and each block creates a table.
--
-- Money: the sale and purchase amounts are price per share times shares, in
-- dollars (not millions), as in the source.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. Single-owner filings, exact copies removed (intermediate table)
--     Course: module 1 (WHERE), module 4 (CTE), module 5 (window function
--     ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...))
--     Beyond the course: DROP TABLE IF EXISTS, CREATE TABLE AS; a PARTITION BY
--     over 89 columns.
--
--     Two steps, in the authors' order:
--       * single: keep filings with one reporting owner. A filing by several
--         owners (a person and their trust, say) cannot be given to one
--         person.
--       * numbered / WHERE copy_num = 1: the scrape can hold the same
--         transaction twice under two accession numbers (an amendment, or the
--         same filing fetched twice). A row is a copy when an earlier row
--         (lower row_num) agrees with it on every column except the
--         accession number. R does this with distinct() over all columns but
--         one, which also keeps the first occurrence. PARTITION BY treats two
--         NULLs as equal, as distinct() treats two NAs as equal.
--     The multi-owner columns (owner_*_2 to owner_*_10) are all NULL once
--     the multi-owner filings are gone. They stay in the partition anyway, so
--     the rule is "every column but the accession number" with no exception.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_dedup;
CREATE TABLE form4_dedup AS
WITH single AS (
  SELECT *
  FROM form4_raw
  WHERE single_owner = 1
),
numbered AS (
  SELECT
    single.*,
    ROW_NUMBER() OVER (
      PARTITION BY
        filer_cik, document_type, issuer_name, issuer_cik, issuer_symbol,
        table_num, security_title, transaction_date, transaction_code,
        shares_traded, price_per_share, transaction_type,
        shares_owned_after_transaction, ownership_type, ownership_nature,
        ownership_nature_footnote, conversion_price, owner_name_1,
        owner_cik_1, owner_title_1, owner_director_1, owner_officer_1,
        owner_ten_percent_1, owner_other_1, num_owners, single_owner,
        owner_name_2, owner_cik_2, owner_title_2, owner_director_2,
        owner_officer_2, owner_ten_percent_2, owner_other_2, owner_name_3,
        owner_name_4, owner_cik_3, owner_cik_4, owner_title_3,
        owner_title_4, owner_director_3, owner_director_4,
        owner_officer_3, owner_officer_4, owner_ten_percent_3,
        owner_ten_percent_4, owner_other_3, owner_other_4, owner_name_5,
        owner_name_6, owner_name_7, owner_name_8, owner_name_9,
        owner_name_10, owner_cik_5, owner_cik_6, owner_cik_7, owner_cik_8,
        owner_cik_9, owner_cik_10, owner_title_5, owner_title_6,
        owner_title_7, owner_title_8, owner_title_9, owner_title_10,
        owner_director_5, owner_director_6, owner_director_7,
        owner_director_8, owner_director_9, owner_director_10,
        owner_officer_5, owner_officer_6, owner_officer_7,
        owner_officer_8, owner_officer_9, owner_officer_10,
        owner_ten_percent_5, owner_ten_percent_6, owner_ten_percent_7,
        owner_ten_percent_8, owner_ten_percent_9, owner_ten_percent_10,
        owner_other_5, owner_other_6, owner_other_7, owner_other_8,
        owner_other_9, owner_other_10
      ORDER BY row_num
    ) AS copy_num
  FROM single
)
SELECT *
FROM numbered
WHERE copy_num = 1;


-- -----------------------------------------------------------------------------
-- Q2. The clean transactions
--     Course: module 1 (WHERE with LIKE, IS NULL, OR; CASE WHEN), module 2
--     (LEFT JOIN), module 4 (CTE chain)
--     Beyond the course: printf() to turn a number into text; CAST and
--     substr() to take the year from an ISO date.
--
--     Steps, each a CTE:
--       * kept: drop trades held through a foundation or an advocacy
--         organisation (the ownership_nature text names it). They are not the
--         person's taxable income. R tests the text with grepl(...,
--         ignore.case = TRUE); SQLite's LIKE ignores case for ASCII letters,
--         and '%x%' means "contains x". A NULL ownership_nature is kept, as
--         grepl() returns FALSE on NA.
--       * amounts: sale = price x shares for a disposal (type D) coded as an
--         open-market sale (code S), purchase = price x shares for an
--         acquisition (type A) coded as an open-market purchase (code P),
--         NULL otherwise. This is R's ifelse(cond, value, NA).
--       * corrected: a few filings report a price per share that is off by
--         a power of ten. The correction table names each filing and the sale
--         amount the wrong price produces, and gives the right price. The
--         authors match the sale amount as text (R compares a number with a
--         string by writing the number with 15 significant digits), so the
--         join does the same with printf('%.15g', sale).
--         One side effect is reproduced on purpose: in R the test is
--         "same filing AND same sale amount", and for a row of a corrected
--         filing with no sale amount (an option exercise, say) that test is
--         NA rather than FALSE, so ifelse() sets its price to NA. The CASE
--         below gives such rows a NULL price too. The sale amounts of these
--         rows are NULL either way; only their price_per_share column is
--         affected.
--       * final SELECT: the sale amount again from the corrected price (the
--         purchase amount is not recomputed, as in the authors' code; no
--         corrected row is a purchase), the year of the transaction, and the
--         forbes_id of the filer by a LEFT JOIN on the filer CIK. A filer
--         CIK missing from the crosswalk gets a NULL forbes_id. A CIK listed
--         twice would duplicate rows, as dplyr's left_join() does; the
--         crosswalk has no such CIK.
--     row_num (the file order) is kept so that exports list the rows in the
--     order of the authors' output.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS form4_clean;
CREATE TABLE form4_clean AS
WITH kept AS (
  SELECT *
  FROM form4_dedup
  WHERE (ownership_nature IS NULL OR ownership_nature NOT LIKE '%foundation%')
    AND (ownership_nature IS NULL OR ownership_nature NOT LIKE '%advocacy%')
),
amounts AS (
  SELECT
    kept.*,
    CASE WHEN transaction_type = 'D' AND transaction_code = 'S'
         THEN price_per_share * shares_traded END AS sale_reported,
    CASE WHEN transaction_type = 'A' AND transaction_code = 'P'
         THEN price_per_share * shares_traded END AS purchase
  FROM kept
),
corrected AS (
  SELECT
    a.*,
    CASE
      WHEN a.folder IN (SELECT folder FROM form4_price_corrections)
           AND a.sale_reported IS NULL       THEN NULL
      WHEN c.price_per_share IS NOT NULL     THEN c.price_per_share
      ELSE a.price_per_share
    END AS price_fixed
  FROM amounts a
  LEFT JOIN form4_price_corrections c
    ON  c.folder = a.folder
    AND c.sale_text = printf('%.15g', a.sale_reported)
)
SELECT
  co.row_num,
  co.folder,
  x.forbes_id,
  co.issuer_name,
  co.issuer_cik,
  co.issuer_symbol,
  co.security_title,
  co.transaction_date,
  co.table_num,
  co.transaction_code                                 AS code,
  co.shares_traded,
  co.price_fixed                                      AS price_per_share,
  co.transaction_type                                 AS type,
  co.ownership_nature,
  co.owner_name_1,
  co.owner_cik_1,
  CAST(substr(co.transaction_date, 1, 4) AS INTEGER)  AS year,
  CASE WHEN co.transaction_type = 'D' AND co.transaction_code = 'S'
       THEN co.price_fixed * co.shares_traded END     AS sale,
  co.purchase
FROM corrected co
LEFT JOIN form4_forbes_cik x
  ON x.cik = co.filer_cik
ORDER BY co.row_num;
