# Phase 2, query 1 (sql/01_rtb_ca.sql) run through R/run_sql.R.
#
# Local only. data-raw/bundle.sqlite is built from the confidential author
# bundle (python py/load_bundle.py), which CI does not have, so every test
# that needs it skips there. The statement splitter test needs nothing.

.sql_bsz_dir <- function() normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)

.sql_source_runner <- function() {
  # tests/testthat.R sources R/ already; a bare test_dir() call does not.
  if (!exists("sql_split_statements", mode = "function")) {
    source(file.path(.sql_bsz_dir(), "R", "run_sql.R"), local = globalenv())
  }
}

test_that("sql_split_statements ignores semicolons in comments and strings", {
  .sql_source_runner()
  sql <- paste(
    "SELECT 1; -- a comment; with a semicolon",
    "SELECT 'x;y', 'it''s';",
    "/* block; comment */ SELECT \"a;b\";",
    "-- trailing comment only;",
    sep = "\n"
  )
  s <- sql_split_statements(sql)
  expect_length(s, 3)
  expect_equal(s[1], "SELECT 1;")
  expect_match(s[2], "'it''s';$")
  expect_match(s[3], "SELECT \"a;b\";$")
})

test_that("query 1 builds the seven year-end lists and the daily aggregate", {
  root <- .sql_bsz_dir()
  db <- file.path(root, "data-raw", "bundle.sqlite")
  skip_if_not(file.exists(db), "data-raw/bundle.sqlite absent (built from the confidential bundle)")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  .sql_source_runner()

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  run_sql_file(con, file.path(root, "sql", "01_rtb_ca.sql"))

  per_date <- DBI::dbGetQuery(
    con, "SELECT date, COUNT(*) AS n FROM rtb_ca_eoy GROUP BY date ORDER BY date"
  )
  expect_equal(per_date$date, c("2019-12-31", "2020-12-31", "2021-12-31", "2022-12-31",
                                "2023-12-31", "2024-12-31", "2026-01-01"))
  # 240, as in the public workbook (data_sec_agg, n for 2025).
  expect_equal(per_date$n[per_date$date == "2026-01-01"], 240)

  n_agg <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM rtb_ca_aggregate")$n
  expect_gte(n_agg, 2209)

  ind <- DBI::dbGetQuery(con, "SELECT * FROM rtb_ca_2026_01_01_industry ORDER BY rowid")
  expect_equal(ncol(ind), 6)
  expect_equal(ind$industries[nrow(ind)], "Total")
  expect_equal(ind$n_billionaires[nrow(ind)], 240)
})

test_that("R exports of query 1 match the Python exports", {
  root <- .sql_bsz_dir()
  db <- file.path(root, "data-raw", "bundle.sqlite")
  py_dir <- file.path(root, "data-raw", "sql-out", "py")
  skip_if_not(file.exists(db), "data-raw/bundle.sqlite absent (built from the confidential bundle)")
  skip_if_not(dir.exists(py_dir), "no Python exports yet (python py/run_sql.py ...)")
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")
  .sql_source_runner()

  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  run_sql_file(con, file.path(root, "sql", "01_rtb_ca.sql"))
  out <- file.path(tempdir(), "sql-out-r")
  for (t in c("rtb_ca_eoy", "rtb_ca_2026_01_01_industry", "rtb_ca_aggregate")) {
    py_csv <- file.path(py_dir, paste0(t, ".csv"))
    if (!file.exists(py_csv)) next
    r_csv <- export_sql_table(con, t, out)$path
    a <- utils::read.csv(py_csv, colClasses = "character", na.strings = character())
    b <- utils::read.csv(r_csv, colClasses = "character", na.strings = character())
    expect_identical(names(a), names(b))
    expect_identical(nrow(a), nrow(b))
    for (col in names(a)) {
      na <- suppressWarnings(as.numeric(a[[col]]))
      nb <- suppressWarnings(as.numeric(b[[col]]))
      numeric_col <- all(is.na(na) == (a[[col]] == "")) && any(!is.na(na))
      if (numeric_col) {
        expect_equal(nb, na, tolerance = 1e-9, info = paste(t, col))
      } else {
        expect_identical(b[[col]], a[[col]], info = paste(t, col))
      }
    }
  }
})
