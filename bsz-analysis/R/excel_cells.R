# Helpers for reading single cells / row slices / column slices out of a
# positional Excel dump (a tibble whose columns are named by Excel letter,
# as produced by `read_sheet()` in R/ingest_excel.R).
#
# Each helper coerces the underlying character cells to numeric and silences
# the coercion warning: the positional dumps come back as `character` because
# `readxl` auto-detects per column and many cells in the BSZ workbook mix
# headers, labels, and numbers.

xls_cell <- function(df, addr) {
  m <- regmatches(addr, regexec("^([A-Z]+)([0-9]+)$", addr))[[1]]
  v <- df[[m[2]]][as.integer(m[3])]
  suppressWarnings(as.numeric(v))
}

xls_cells_row <- function(df, cols, row) {
  unname(vapply(cols, function(L) xls_cell(df, paste0(L, row)), numeric(1)))
}

xls_cells_col <- function(df, col, rows) {
  unname(vapply(rows, function(r) xls_cell(df, paste0(col, r)), numeric(1)))
}
