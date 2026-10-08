-- =============================================================================
-- Query 5: Forbes 400 and Forbes global lists to the California panel, 2004-2025
-- =============================================================================
--
-- Step 1 of the reproduction (raw data to the public workbook). One row per
-- California billionaire and year, 2004 to 2025, from three sources:
--   * 2019 to 2025: the year-end real-time lists of query 1 (rtb_ca_eoy),
--     with the public / private split of wealth;
--   * 2005 to 2018, US citizens: the Forbes 400, filtered to California;
--   * 2004 to 2018, non-US citizens living in California, and 2004 for US
--     citizens (the Forbes 400 has no 2004 list in the source): the Forbes
--     global billionaire lists, matched to California Forbes ids by name.
-- Before 2010 the Forbes 400 carries no Forbes id, so names are matched to
-- ids, first through the name-id pairs seen in the other sources, then through
-- a gitignored table of hand-made fixes (data-raw/forbes-name-ids.csv).
-- The 2019 to 2025 rows feed the public sheet data_sec_all (year, forbes_id,
-- forbes_worth); the earlier years feed the authors' long-run series.
--
-- Inputs (built by py/load_bundle.py into data-raw/bundle.sqlite):
--   rtb_ca_eoy          query 1's seven year-end lists (run sql/01_rtb_ca.sql
--                       first)
--   forbes400_raw       Forbes 400, 1982 to 2025, wealth in $ million
--   forbes_global_8810  Forbes global lists, 1988 to 2010, worth in $ billion
--   forbes_global_9724  Forbes global lists, 1997 to 2024, net_worth as text
--                       ("2.5 B")
--   forbes_name_ids     name-to-id fixes and id renames, by stage (gitignored;
--                       see data-raw/forbes-name-ids.example.csv)
--
-- Outputs (tables in the same database):
--   forbes_rtb_panel      intermediate: the 2019 to 2025 rows
--   forbes400_ca          intermediate: Forbes 400 California rows, 2005 to
--                         2018, each with a Forbes id where one is found
--   forbes_name_id_pairs  intermediate: the name-id pairs used to match the
--                         global lists
--   forbes_ca_2004_2025   the panel, 9 columns plus src and src_row (which
--                         source and which row of it, for a stable order)
--
-- Run from bsz-analysis/:
--   python  py/run_sql.py sql/05_forbes_ca_panel.sql --export forbes_ca_2004_2025
--   Rscript R/run_sql.R   sql/05_forbes_ca_panel.sql --export forbes_ca_2004_2025
--   python  py/check_forbes_ca_panel.py
--
-- Money: $ million throughout, as on the real-time lists. 2004 to 2018 worth
-- is rounded to the nearest million.
--
-- Name matching with a LEFT JOIN: when a name has two ids among the pairs
-- (two people with the same name, or an id Forbes renamed), the join returns
-- the row twice, once per id. The authors' left_join() does the same, so the
-- duplicates are kept, not resolved.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Q1. The 2019 to 2025 rows, from query 1's year-end lists
--     Course: module 1 (CASE WHEN)
--     Beyond the course: CAST and substr() to take the year from a date.
--
--     The 2026-01-01 snapshot is the "2025" list, so its year is set to 2025.
--     The R code stacked seven data frames with rbind(); in SQL the lists
--     already are one table.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS forbes_rtb_panel;
CREATE TABLE forbes_rtb_panel AS
SELECT
  CASE WHEN substr(date, 1, 4) = '2026' THEN 2025
       ELSE CAST(substr(date, 1, 4) AS INTEGER) END AS year,
  date,
  forbes_id,
  forbes_name,
  forbes_worth,
  state,
  country_citizenship,
  forbes_public_worth,
  forbes_private_worth,
  ROW_NUMBER() OVER (ORDER BY date, forbes_worth DESC, forbes_id) AS src_row
FROM rtb_ca_eoy;


-- -----------------------------------------------------------------------------
-- Q2. Forbes 400, California, 2005 to 2018, with a Forbes id
--     Course: module 1 (WHERE, CASE WHEN), module 2 (LEFT JOIN), module 4
--     (CTE chain, UNION to collect distinct pairs, UNION ALL to stack rows)
--     Beyond the course: COALESCE over two joins as "the fix wins, else the
--     match".
--
--     * ca: the California rows of 2004 to 2018 (the source has no 2004 list).
--       Two years are stored in thousands of dollars rather than millions,
--       so their wealth is divided by 1000.
--     * pairs: every distinct (name, id) pair from the real-time lists and
--       from the Forbes 400 rows that have an id (2010 on). UNION, unlike
--       UNION ALL, drops repeated pairs, as R's unique() does.
--     * early: 2005 to 2009 rows matched to an id by name. A name on the fix
--       table (stage forbes400_2004_2009) takes the fixed id; the R code
--       applies the fixes after the join, so a fix overrides a match.
--     * the 2010 to 2018 rows keep their own id.
--     src_row keeps the source's row order inside each part.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS forbes400_ca;
CREATE TABLE forbes400_ca AS
WITH ca AS (
  SELECT
    row_num,
    year,
    name                                                AS forbes_name,
    CASE WHEN year IN (2005, 2009) THEN wealth / 1000.0
         ELSE wealth END                                AS forbes_worth,
    state,
    country                                             AS country_citizenship,
    forbes_id
  FROM forbes400_raw
  WHERE year >= 2004 AND year < 2019
    AND state = 'California'
),
pairs AS (
  SELECT forbes_name, forbes_id FROM forbes_rtb_panel
  UNION
  SELECT forbes_name, forbes_id FROM ca WHERE forbes_id IS NOT NULL
),
early AS (
  SELECT
    ca.row_num,
    ca.year,
    ca.forbes_name,
    ca.forbes_worth,
    ca.state,
    ca.country_citizenship,
    COALESCE(fix.forbes_id, p.forbes_id) AS forbes_id
  FROM ca
  LEFT JOIN pairs p
    ON p.forbes_name = ca.forbes_name
  LEFT JOIN forbes_name_ids fix
    ON  fix.stage = 'forbes400_2004_2009'
    AND fix.match = ca.forbes_name
  WHERE ca.year <= 2009
)
SELECT 3 AS src, row_num, year, forbes_name, forbes_worth, state,
       country_citizenship, forbes_id
FROM early
UNION ALL
SELECT 4 AS src, row_num, year, forbes_name, forbes_worth, state,
       country_citizenship, forbes_id
FROM ca
WHERE year > 2009;


-- -----------------------------------------------------------------------------
-- Q3. The name-id pairs for matching the global lists
--     Course: module 4 (UNION), module 1 (WHERE ... IS NOT NULL)
--
--     The Forbes 400 pairs after Q2's matching, plus the real-time pairs,
--     without repeats and without missing ids.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS forbes_name_id_pairs;
CREATE TABLE forbes_name_id_pairs AS
SELECT forbes_name, forbes_id FROM forbes400_ca WHERE forbes_id IS NOT NULL
UNION
SELECT forbes_name, forbes_id FROM forbes_rtb_panel WHERE forbes_id IS NOT NULL;


-- -----------------------------------------------------------------------------
-- Q4. The panel, 2004 to 2025
--     Course: module 1 (WHERE, CASE WHEN, ROUND), module 2 (LEFT JOIN),
--     module 4 (CTE chain, UNION ALL)
--     Beyond the course: REPLACE and CAST to read "2.5 B" as a number; CAST
--     of NULL to fix a column's type in a UNION ALL.
--
--     * global_foreign: non-US citizens on the global lists, 2004 to 2010
--       from the older file and 2011 to 2018 from the newer one, worth to
--       $ million. A name joins to the pairs of Q3, a fix (stage
--       global_foreign) overrides, and only the rows that found an id stay:
--       those are the California residents. A NULL citizenship fails the
--       test "<> 'United States'" and is dropped, as in R.
--     * global_2004_us: US citizens on the 2004 global list, matched the
--       same way (stage global_2004_us); this is the US part of 2004, since
--       the Forbes 400 source has no 2004 list.
--     * early: those two plus the Forbes 400 rows of Q2, worth rounded to
--       the nearest $ million. SQLite's ROUND() rounds halves away from zero
--       and R's round() to even; no worth in these years ends in exactly .5,
--       so the two agree here.
--     * stacked: early plus the 2019 to 2025 rows of Q1. The early rows have
--       no date and no public / private split.
--     * final SELECT: ids that Forbes renamed are mapped to their current
--       spelling (stage rename_id), and the rows are sorted by year and
--       worth, largest first. src and src_row break ties in the order the
--       R code stacked the sources (its sort is stable).
--
--     net_worth: REPLACE(net_worth, ' B', '') drops the unit. CAST of a text
--     that is not a number gives 0 in SQLite, where R's as.numeric() gives
--     NA; every net_worth of these years has the form "<number> B", so the
--     difference does not arise.
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS forbes_ca_2004_2025;
CREATE TABLE forbes_ca_2004_2025 AS
WITH global_rows AS (
  SELECT 'old' AS file, row_num, year, name AS forbes_name,
         ccitiz AS country_citizenship, worth * 1000 AS forbes_worth
  FROM forbes_global_8810
  UNION ALL
  SELECT 'new' AS file, row_num, year, full_name AS forbes_name,
         country_of_citizenship AS country_citizenship,
         CAST(REPLACE(net_worth, ' B', '') AS REAL) * 1000 AS forbes_worth
  FROM forbes_global_9724
),
global_foreign AS (
  SELECT
    2 AS src,
    (g.file = 'new') * 1000000 + g.row_num AS src_row,
    g.year,
    g.forbes_name,
    g.country_citizenship,
    g.forbes_worth,
    COALESCE(fix.forbes_id, p.forbes_id) AS forbes_id
  FROM global_rows g
  LEFT JOIN forbes_name_id_pairs p
    ON p.forbes_name = g.forbes_name
  LEFT JOIN forbes_name_ids fix
    ON  fix.stage = 'global_foreign'
    AND fix.match = g.forbes_name
  WHERE g.country_citizenship <> 'United States'
    AND ((g.file = 'old' AND g.year >= 2004)
      OR (g.file = 'new' AND g.year > 2010 AND g.year < 2019))
),
global_2004_us AS (
  SELECT
    1 AS src,
    g.row_num AS src_row,
    g.year,
    g.forbes_name,
    g.country_citizenship,
    g.forbes_worth,
    COALESCE(fix.forbes_id, p.forbes_id) AS forbes_id
  FROM global_rows g
  LEFT JOIN forbes_name_id_pairs p
    ON p.forbes_name = g.forbes_name
  LEFT JOIN forbes_name_ids fix
    ON  fix.stage = 'global_2004_us'
    AND fix.match = g.forbes_name
  WHERE g.file = 'old'
    AND g.year = 2004
    AND g.country_citizenship = 'United States'
),
early AS (
  SELECT src, src_row, year, forbes_name, country_citizenship,
         ROUND(forbes_worth) AS forbes_worth, forbes_id,
         CAST(NULL AS TEXT) AS state
  FROM global_2004_us
  WHERE forbes_id IS NOT NULL
  UNION ALL
  SELECT src, src_row, year, forbes_name, country_citizenship,
         ROUND(forbes_worth), forbes_id, CAST(NULL AS TEXT)
  FROM global_foreign
  WHERE forbes_id IS NOT NULL AND year IS NOT NULL
  UNION ALL
  SELECT src, row_num, year, forbes_name, country_citizenship,
         ROUND(forbes_worth), forbes_id, state
  FROM forbes400_ca
),
stacked AS (
  SELECT src, src_row, year, forbes_name, country_citizenship, forbes_worth,
         forbes_id, state,
         CAST(NULL AS TEXT) AS date,
         CAST(NULL AS REAL) AS forbes_private_worth,
         CAST(NULL AS REAL) AS forbes_public_worth
  FROM early
  UNION ALL
  SELECT 5, src_row, year, forbes_name, country_citizenship, forbes_worth,
         forbes_id, state, date, forbes_private_worth, forbes_public_worth
  FROM forbes_rtb_panel
)
SELECT
  s.year,
  s.forbes_name,
  s.country_citizenship,
  s.forbes_worth,
  COALESCE(r.forbes_id, s.forbes_id) AS forbes_id,
  s.state,
  s.date,
  s.forbes_private_worth,
  s.forbes_public_worth,
  s.src,
  s.src_row
FROM stacked s
LEFT JOIN forbes_name_ids r
  ON  r.stage = 'rename_id'
  AND r.match = s.forbes_id
ORDER BY s.year, s.forbes_worth DESC, s.src, s.src_row;
