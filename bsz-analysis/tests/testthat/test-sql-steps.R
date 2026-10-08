# Phase 2, step 1, the queries after query 1 (sql/04_*.sql onward), run
# through R/run_sql.R.
#
# Local only. data-raw/bundle.sqlite is built from the confidential author
# bundle (python py/load_bundle.py), which CI does not have, so every test
# skips there, and also when the database lacks a query's input tables.

.steps_bsz_dir <- function() normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)

.steps_connect <- function(sql_names, needs) {
  root <- .steps_bsz_dir()
  db <- file.path(root, "data-raw", "bundle.sqlite")
  testthat::skip_if_not(file.exists(db), "data-raw/bundle.sqlite absent (built from the confidential bundle)")
  testthat::skip_if_not_installed("DBI")
  testthat::skip_if_not_installed("RSQLite")
  if (!exists("run_sql_file", mode = "function")) {
    source(file.path(root, "R", "run_sql.R"), local = globalenv())
  }
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  lacking <- setdiff(needs, DBI::dbListTables(con))
  if (length(lacking)) {
    DBI::dbDisconnect(con)
    testthat::skip(paste("input tables not loaded:", paste(lacking, collapse = ", ")))
  }
  for (f in sql_names) run_sql_file(con, file.path(root, "sql", f))
  con
}

.steps_one <- function(con, sql) DBI::dbGetQuery(con, sql)[[1]]

test_that("query 4 cleans the Form 4 filings to the authors' row count", {
  con <- .steps_connect("04_form4_clean.sql",
                        c("form4_raw", "form4_forbes_cik", "form4_price_corrections"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  expect_equal(.steps_one(con, "SELECT COUNT(*) FROM form4_clean"), 198719)
  expect_equal(.steps_one(con, "SELECT COUNT(*) FROM form4_clean WHERE ownership_nature LIKE '%foundation%'"), 0)
  expect_equal(.steps_one(con, "SELECT COUNT(*) FROM form4_clean WHERE sale IS NOT NULL AND code <> 'S'"), 0)
  expect_length(DBI::dbListFields(con, "form4_clean"), 19)
})

test_that("query 5 builds the 2004-2025 California panel", {
  con <- .steps_connect(c("01_rtb_ca.sql", "05_forbes_ca_panel.sql"),
                        c("rtb_all_combined", "rtb_ca_cik", "rtb_residency_overrides",
                          "forbes400_raw", "forbes_global_9724", "forbes_global_8810",
                          "forbes_name_ids"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  per_year <- DBI::dbGetQuery(con, "SELECT year, COUNT(*) AS n FROM forbes_ca_2004_2025 GROUP BY year ORDER BY year")
  eoy <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM rtb_ca_eoy GROUP BY date ORDER BY date")$n
  expect_equal(per_year$year, 2004:2025)
  # Rows per year of the authors' panel, 2004 to 2018.
  expect_equal(per_year$n[per_year$year <= 2018],
               c(66, 98, 94, 93, 86, 88, 87, 93, 92, 97, 96, 98, 97, 102, 102))
  expect_equal(per_year$n[per_year$year >= 2019], eoy)
})

test_that("query 6 builds the venture monitor panels", {
  con <- .steps_connect("06_venture_monitor.sql", "vm_state_cells")
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  n <- vapply(c("vm_annual_state", "vm_annual", "vm_quarterly_state", "vm_quarterly"),
              function(t) .steps_one(con, paste("SELECT COUNT(*) FROM", t)), numeric(1))
  # Row counts of the authors' four output files.
  expect_equal(unname(n), c(1098, 21, 1830, 34))
  expect_equal(DBI::dbGetQuery(con, "SELECT year FROM vm_annual ORDER BY year")$year, 2006:2026)
  expect_equal(.steps_one(con, "SELECT MIN(year * 10 + quarter) FROM vm_quarterly"), 20181)
  expect_equal(.steps_one(con, "SELECT MAX(year * 10 + quarter) FROM vm_quarterly"), 20262)
})

test_that("queries 7 and 8 join the Form 4 trades to daily prices", {
  con <- .steps_connect(c("04_form4_clean.sql", "07_form4_gvkey_link.sql", "08_form4_compustat.sql"),
                        c("form4_raw", "form4_forbes_cik", "form4_price_corrections",
                          "comp_daily_snapshots", "form4_gvkey_fixes", "comp_daily_form4"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  link <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n, COUNT(gvkey) AS linked FROM form4_gvkey_link")
  expect_equal(c(link$n, link$linked), c(276, 270))
  expect_equal(.steps_one(con, "SELECT COUNT(*) FROM form4_gvkey_list"), 262)
  got <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n, SUM(prccd IS NULL) AS no_price, SUM(gvkey IS NULL) AS no_sec FROM form4_compustat")
  # The authors' file: 198,654 trades, 165 without a price, 23 without a security.
  expect_equal(unname(unlist(got)), c(198654, 165, 23))
})
