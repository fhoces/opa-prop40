# Phase 2, step 1, the queries after query 1 (sql/04_*.sql onward), run
# through R/run_sql.R.
#
# Local only. data-raw/bundle.sqlite is built from the confidential author
# bundle (python py/load_bundle.py), which CI does not have, so every test
# skips there, and also when the database lacks a query's input tables.

.steps_bsz_dir <- function() normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)

.steps_connect <- function(sql_name, needs) {
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
  run_sql_file(con, file.path(root, "sql", sql_name))
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
