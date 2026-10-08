# R twin of py/run_sql.py: run a shared .sql file against
# data-raw/bundle.sqlite and export tables to data-raw/sql-out/r/.
#
# Run from bsz-analysis/:
#   Rscript R/run_sql.R sql/01_rtb_ca.sql \
#     --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate
#
# Not wired into _targets.R. Both _targets.R and tests/testthat.R source every
# file in R/, so this file only defines functions; the command-line entry
# point at the bottom runs only under Rscript. DBI and RSQLite are called with
# `::` inside functions, so sourcing the file does not need them installed
# (they are not in DESCRIPTION, and CI does not install them).
#
# The .sql file is split into statements by sql_split_statements() and each
# statement goes through DBI::dbExecute(), which runs one statement at a
# time. Python's executescript() runs the whole file in one call; the two
# should therefore build the same tables.
#
# Exports use the same row order as Python (.EXPORT_ORDER, keep in step with
# EXPORT_ORDER in py/run_sql.py) and the same text format: NULL is an empty
# field, and a double is written with the fewest significant digits (15, 16
# or 17) that read back as the same number, plus ".0" when that looks like
# an integer, as Python's repr() prints. R's own text-to-number parser is not
# always correctly rounded in the 16th digit, so R sometimes falls through to
# 17 digits where Python prints 16. The two files can then differ as text
# while holding the same doubles; py/check_rtb_ca.py compares the parsed
# numbers.

.EXPORT_ORDER <- c(
  rtb_ca_eoy = "date, forbes_worth DESC, forbes_id",
  rtb_ca_2026_01_01_industry = "(industries = 'Total'), fraction_forbes_worth DESC, industries",
  rtb_ca_aggregate = "date",
  form4_clean = "row_num",
  forbes_ca_2004_2025 = "year, forbes_worth DESC, src, src_row, forbes_id",
  vm_annual_state = "state, year, deal_count, deal_value",
  vm_annual = "year",
  vm_quarterly_state = "state, year, quarter, deal_count, deal_value",
  vm_quarterly = "year, quarter",
  form4_gvkey_link = "issuer_cik, gvkey, iid",
  form4_compustat = "out_order",
  form4_kg = "row_id",
  form4_basis_held = "owner_cik_1, issuer_cik, year",
  form4_annual_firm_individual = "owner_cik_1, issuer_cik, year",
  form4_annual_individual = "owner_cik_1, year",
  form4_annual = "sort_key, year",
  form4_annual_top5 = "block, owner_cik_1, year"
)

# Split SQL text into statements at each `;` that is real code.
#
# A small state machine walks the text one character at a time and ignores a
# `;` that sits inside a `-- line comment`, a `/* block comment */`, a
# 'string', a "quoted identifier" or a `backtick identifier`. A doubled
# quote inside a string ('it''s') works because the scanner leaves the
# string at the first quote and re-enters it at the second.
#
# Limitation: statements that legitimately contain `;` in code, such as a
# CREATE TRIGGER ... BEGIN ...; ...; END body, would be split in the wrong
# place. The shared .sql files do not use triggers. Pieces that contain only
# comments and whitespace are dropped.
sql_split_statements <- function(sql) {
  ch <- strsplit(sql, "", fixed = TRUE)[[1]]
  n <- length(ch)
  out <- character()
  state <- "code"
  start <- 1L
  has_code <- FALSE
  i <- 1L
  while (i <= n) {
    c1 <- ch[i]
    c2 <- if (i < n) ch[i + 1L] else ""
    if (state == "code") {
      if (c1 == "-" && c2 == "-") {
        state <- "line"; i <- i + 1L
      } else if (c1 == "/" && c2 == "*") {
        state <- "block"; i <- i + 1L
      } else if (c1 == "'") {
        state <- "squote"; has_code <- TRUE
      } else if (c1 == "\"") {
        state <- "dquote"; has_code <- TRUE
      } else if (c1 == "`") {
        state <- "bquote"; has_code <- TRUE
      } else if (c1 == ";") {
        if (has_code) out <- c(out, paste(ch[start:i], collapse = ""))
        start <- i + 1L
        has_code <- FALSE
      } else if (!grepl("^\\s$", c1)) {
        has_code <- TRUE
      }
    } else if (state == "line") {
      if (c1 == "\n") state <- "code"
    } else if (state == "block") {
      if (c1 == "*" && c2 == "/") { state <- "code"; i <- i + 1L }
    } else if (state == "squote") {
      if (c1 == "'") state <- "code"
    } else if (state == "dquote") {
      if (c1 == "\"") state <- "code"
    } else if (state == "bquote") {
      if (c1 == "`") state <- "code"
    }
    i <- i + 1L
  }
  if (has_code && start <= n) out <- c(out, paste(ch[start:n], collapse = ""))
  trimws(out)
}

run_sql_file <- function(con, sql_file) {
  sql <- paste(readLines(sql_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  stmts <- sql_split_statements(sql)
  for (s in stmts) DBI::dbExecute(con, s)
  invisible(length(stmts))
}

# Shortest of 15, 16 or 17 significant digits that round-trips, as Python's
# repr() does for the magnitudes in these tables.
.format_double <- function(x) {
  out <- character(length(x))
  for (k in seq_along(x)) {
    v <- x[k]
    if (is.na(v)) { out[k] <- ""; next }
    s <- sprintf("%.15g", v)
    if (as.numeric(s) != v) s <- sprintf("%.16g", v)
    if (as.numeric(s) != v) s <- sprintf("%.17g", v)
    if (!grepl("[.eEn]", s)) s <- paste0(s, ".0")
    out[k] <- s
  }
  out
}

.csv_field <- function(x) {
  x[is.na(x)] <- ""
  needs <- grepl("[\",\n\r]", x)
  x[needs] <- paste0("\"", gsub("\"", "\"\"", x[needs], fixed = TRUE), "\"")
  x
}

export_sql_table <- function(con, table, out_dir) {
  cols <- DBI::dbListFields(con, table)
  order <- if (table %in% names(.EXPORT_ORDER)) .EXPORT_ORDER[[table]] else
    paste(seq_along(cols), collapse = ", ")
  df <- DBI::dbGetQuery(con, sprintf("SELECT * FROM %s ORDER BY %s", table, order))
  txt <- lapply(df, function(col) {
    if (is.double(col)) .format_double(col) else .csv_field(as.character(col))
  })
  lines <- c(
    paste(.csv_field(names(df)), collapse = ","),
    if (nrow(df) > 0) do.call(paste, c(txt, sep = ","))
  )
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(out_dir, paste0(table, ".csv"))
  writeLines(lines, path, useBytes = TRUE)
  list(path = path, n = nrow(df))
}

run_sql_main <- function(args, bsz_dir = ".") {
  if (length(args) < 1L) stop("usage: Rscript R/run_sql.R FILE.sql [--export TABLE ...] [--db PATH] [--out DIR]")
  sql_file <- args[1L]
  opt <- function(flag, default) {
    j <- match(flag, args)
    if (is.na(j) || j == length(args)) default else args[j + 1L]
  }
  db <- opt("--db", file.path(bsz_dir, "data-raw", "bundle.sqlite"))
  out_dir <- opt("--out", file.path(bsz_dir, "data-raw", "sql-out", "r"))
  tables <- character()
  j <- match("--export", args)
  if (!is.na(j) && j < length(args)) {
    rest <- args[(j + 1L):length(args)]
    stop_at <- which(startsWith(rest, "--"))
    tables <- if (length(stop_at)) rest[seq_len(stop_at[1L] - 1L)] else rest
  }
  if (!file.exists(db)) stop(db, " not found. Build it first: python py/load_bundle.py")
  con <- DBI::dbConnect(RSQLite::SQLite(), db)
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  run_sql_file(con, sql_file)
  for (t in tables) {
    res <- export_sql_table(con, t, out_dir)
    cat(sprintf("%s: %s rows -> %s\n", t, format(res$n, big.mark = ","), res$path))
  }
  invisible(tables)
}

# Command-line entry point: runs under `Rscript R/run_sql.R ...` only, not
# when the file is sourced (sys.nframe() is 0 only at the top level of a
# script run directly).
if (sys.nframe() == 0L && !interactive()) {
  run_sql_main(commandArgs(trailingOnly = TRUE))
}
