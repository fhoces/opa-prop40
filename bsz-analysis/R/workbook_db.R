# The public workbook's two large input sheets in SQLite, for the shared
# queries sql/02_data_sec_agg.sql and sql/03_ftb_b4a.sql. Python twin:
# py/workbook_db.py.
#
# Two ways in, one set of queries:
#   * the pipeline: target `workbook_db` writes the input tables into
#     data-raw/workbook.sqlite (gitignored, a build artifact like _targets/),
#     runs both .sql files there, and later targets only read the result
#     tables (read-only connection, so the file target stays unchanged);
#   * a direct call such as compute_data_sec_agg(extract_data_sec_all()), as
#     the tests make: the same tables and queries in an in-memory database.
#
# The loader takes the data frames the extract_*() functions already return,
# so the database holds exactly what the R code used to compute on. Numeric
# coercion of the positional FTB sheet (character cells from readxl) happens
# here, as it did in .bci_make_ftb() before.
#
# DBI and RSQLite are called with `::`; they are in DESCRIPTION Imports.

workbook_db_path <- function() file.path(project_root(), "data-raw", "workbook.sqlite")

workbook_sql_file <- function(name) file.path(project_root(), "sql", name)

WORKBOOK_SQL_FILES <- c("02_data_sec_agg.sql", "03_ftb_b4a.sql")

# The input tables, as data frames. `row_num` keeps the sheet order, which the
# re-paste filter in query 2 needs (it keeps the first copy). For ftb_b4a it is
# the sheet row number; only data rows (a numeric taxable year in column A)
# are kept.
workbook_input_tables <- function(data_sec_all = NULL, ftb_b4a = NULL,
                                  exclude_ids = ELLISON_FORBES_ID) {
  out <- list()
  if (!is.null(data_sec_all)) {
    d <- as.data.frame(data_sec_all)
    d$year <- as.integer(d$year)
    out$data_sec_all <- cbind(row_num = seq_len(nrow(d)), d)
    out$data_sec_agg_exclude <- data.frame(forbes_id = as.character(exclude_ids))
  }
  if (!is.null(ftb_b4a)) {
    num <- function(x) suppressWarnings(as.numeric(x))
    f <- data.frame(
      row_num        = seq_len(nrow(ftb_b4a)),
      taxable_year   = as.integer(num(ftb_b4a$A)),
      agic           = as.character(ftb_b4a$C),
      all_returns    = num(ftb_b4a$D),
      ca_agi         = num(ftb_b4a$H),
      taxable_income = num(ftb_b4a$J),
      total_tax      = num(ftb_b4a$K)
    )
    out$ftb_b4a <- f[!is.na(f$taxable_year), ]
  }
  out
}

write_workbook_tables <- function(con, tables) {
  for (nm in names(tables)) {
    DBI::dbWriteTable(con, nm, tables[[nm]], overwrite = TRUE)
  }
  invisible(names(tables))
}

# Writes the inputs, runs the queries, returns the path (a file target).
build_workbook_db <- function(data_sec_all, ftb_b4a,
                              sql_files = workbook_sql_file(WORKBOOK_SQL_FILES),
                              path = workbook_db_path()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) file.remove(path)
  con <- DBI::dbConnect(RSQLite::SQLite(), path)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  write_workbook_tables(con, workbook_input_tables(data_sec_all, ftb_b4a))
  for (f in sql_files) run_sql_file(con, f)
  path
}

# A connection to a built database (read-only) or an in-memory one holding
# `tables` with `sql_files` already run. The caller disconnects.
.workbook_con <- function(db = NULL, tables = NULL, sql_files = NULL) {
  if (!is.null(db)) {
    return(DBI::dbConnect(RSQLite::SQLite(), db, flags = RSQLite::SQLITE_RO))
  }
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  write_workbook_tables(con, tables)
  for (f in sql_files) run_sql_file(con, f)
  con
}

# ---- query 2: data_sec_agg ---------------------------------------------------

.read_data_sec_agg <- function(con) {
  out <- DBI::dbGetQuery(con, "SELECT * FROM data_sec_agg ORDER BY year")
  out$year <- as.integer(out$year)
  out$n <- as.integer(out$n)
  tibble::as_tibble(out)
}

read_data_sec_agg <- function(db = workbook_db_path()) {
  con <- .workbook_con(db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  .read_data_sec_agg(con)
}

# ---- query 3: the FTB table --------------------------------------------------

.read_ftb_b4a <- function(con) {
  structure(
    list(
      year = DBI::dbGetQuery(con, "SELECT * FROM ftb_b4a_year ORDER BY taxable_year"),
      top  = DBI::dbGetQuery(con, "SELECT * FROM ftb_b4a_top ORDER BY taxable_year, row_num")
    ),
    class = "ftb_b4a_sql"
  )
}

read_ftb_b4a <- function(db = workbook_db_path()) {
  con <- .workbook_con(db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  .read_ftb_b4a(con)
}

# The raw positional sheet (extract_ftb_b4a()) through query 3, in memory.
query_ftb_b4a <- function(ftb_b4a) {
  con <- .workbook_con(tables = workbook_input_tables(ftb_b4a = ftb_b4a),
                       sql_files = workbook_sql_file("03_ftb_b4a.sql"))
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  .read_ftb_b4a(con)
}
