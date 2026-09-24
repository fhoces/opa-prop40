# Small shared helper for writing the export/ CSVs (both export/r and,
# indirectly via the schema it fixes, export/py).
readr_write <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}
