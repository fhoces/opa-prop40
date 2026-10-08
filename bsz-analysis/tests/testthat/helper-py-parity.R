# R vs Python parity: every number py/run_export.py writes to export/py/
# against its R counterpart. Used by test-py-parity.R and by
# tools/py-parity.R, which writes the table to export/py/parity.csv.
#
# The R side of each comparison:
#   export/py/inputs.csv, outputs.csv  vs export/r/ (the export contract)
#   export/py/site/*.csv               vs site/data/*.csv
#   export/py/site/grid.js             vs site/explorer/grid.js (parsed JSON)
#   export/py/exhibits/*.csv           vs tests/snapshots/<vintage>/*.rds, the
#                                      pinned R values of every computation,
#                                      table panel and figure data layer
#
# Tolerance: |python - r| <= 1e-9 * max(1, |r|). The two sides read the same
# workbook cells and run the same SQL, but R parses the workbook's 17-digit
# text with its own strtod (off by up to a few units in the last place), R's
# mean() takes a second correction pass, and numpy sums pairwise. Those differ
# around 1e-16 of the value; 1e-9 leaves room for a long chain of them and
# still catches any real difference (the smallest printed digit is 1e-3).

PY_PARITY_TOL <- 1e-9

py_parity_dir <- function() file.path(project_root(), "export", "py")

.read_parity_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                  encoding = "UTF-8", na.strings = "NA")
}

# A snapshot as the named data frames run_export.py writes for it: a data
# frame as itself; a list holding no data frame as one key,value frame (keys
# from unlist()); any other list element by element, names joined with "__".
flatten_snapshot <- function(x, name) {
  if (is.data.frame(x)) return(stats::setNames(list(as.data.frame(x)), name))
  if (is.list(x) && !any(vapply(x, is.data.frame, logical(1)))) {
    u <- unlist(x)
    return(stats::setNames(list(data.frame(key = names(u), value = unname(u))), name))
  }
  out <- list()
  for (e in names(x)) out <- c(out, flatten_snapshot(x[[e]], paste0(name, "__", e)))
  out
}

# Compare two data frames column by column. Returns one row: the number of
# numeric values compared, the largest absolute and relative differences, and
# a description of anything that does not match (names, rows, missing values,
# text, or a numeric gap above the tolerance).
compare_parity_frames <- function(r, py, output, group) {
  r <- as.data.frame(r); py <- as.data.frame(py)
  problems <- character()
  n_num <- 0L; max_abs <- 0; max_rel <- 0
  if (!identical(names(r), names(py))) {
    problems <- c(problems, sprintf("columns differ: R [%s] vs Python [%s]",
                                    paste(names(r), collapse = ","), paste(names(py), collapse = ",")))
  }
  if (nrow(r) != nrow(py)) problems <- c(problems, sprintf("rows: R %d vs Python %d", nrow(r), nrow(py)))
  if (!length(problems)) {
    for (col in names(r)) {
      a <- r[[col]]; b <- py[[col]]
      if (is.factor(a)) a <- as.character(a)
      if (inherits(a, "Date")) { a <- as.character(a); b <- as.character(b) }
      if (is.numeric(a) && !is.logical(a)) {
        b <- suppressWarnings(as.numeric(b))
        if (!identical(is.na(a), is.na(b))) {
          problems <- c(problems, paste0(col, ": missing values differ"))
          next
        }
        ok <- !is.na(a)
        same_inf <- is.infinite(a) & is.infinite(b) & sign(a) == sign(b)
        d <- ifelse(same_inf, 0, abs(a - b))[ok]
        rel <- d / pmax(1, abs(a[ok]))
        n_num <- n_num + sum(ok)
        if (length(d)) {
          max_abs <- max(max_abs, d)
          max_rel <- max(max_rel, rel)
          if (any(rel > PY_PARITY_TOL)) problems <- c(problems, sprintf("%s: max rel diff %.3g", col, max(rel)))
        }
      } else {
        if (!identical(as.character(a), as.character(b))) problems <- c(problems, paste0(col, ": text differs"))
      }
    }
  }
  data.frame(group = group, output = output, n_values = n_num, max_abs_diff = max_abs,
             max_rel_diff = max_rel, ok = !length(problems),
             problems = paste(problems, collapse = "; "), stringsAsFactors = FALSE)
}

.grid_js_payload <- function(path) {
  txt <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  json <- sub(";\\s*$", "", sub("^[^\n]*\n\\s*window\\.__GRID__ = ", "", txt))
  jsonlite::fromJSON(json, simplifyVector = FALSE)
}

# The full parity table, one row per output. `snap_dir` holds the R
# reference snapshots for the vintage the Python export was built from.
py_parity_table <- function(py_dir = py_parity_dir(),
                            snap_dir = file.path(project_root(), "tests", "snapshots", bsz_vintage())) {
  root <- project_root()
  rows <- list()
  add <- function(x) rows[[length(rows) + 1L]] <<- x
  missing <- function(group, output) {
    add(data.frame(group = group, output = output, n_values = 0L, max_abs_diff = NA_real_,
                   max_rel_diff = NA_real_, ok = FALSE, problems = "Python file missing",
                   stringsAsFactors = FALSE))
  }

  for (f in c("inputs.csv", "outputs.csv")) {
    p <- file.path(py_dir, f)
    if (!file.exists(p)) { missing("contract", f); next }
    add(compare_parity_frames(.read_parity_csv(file.path(root, "export", "r", f)),
                              .read_parity_csv(p), f, "contract"))
  }

  for (f in sort(list.files(file.path(root, "site", "data"), pattern = "\\.csv$"))) {
    if (f == "test-results.csv") next   # written by tools/site-test-results.R, not the pipeline
    p <- file.path(py_dir, "site", f)
    if (!file.exists(p)) { missing("site", f); next }
    add(compare_parity_frames(.read_parity_csv(file.path(root, "site", "data", f)),
                              .read_parity_csv(p), f, "site"))
  }

  js_r <- file.path(root, "site", "explorer", "grid.js")
  js_py <- file.path(py_dir, "site", "grid.js")
  if (!file.exists(js_py)) {
    missing("site", "grid.js")
  } else {
    a <- .grid_js_payload(js_r); b <- .grid_js_payload(js_py)
    snap_r <- do.call(rbind, lapply(a$snap, unlist))
    snap_py <- do.call(rbind, lapply(b$snap, unlist))
    row <- compare_parity_frames(as.data.frame(snap_r), as.data.frame(snap_py), "grid.js", "site")
    a$snap <- NULL; b$snap <- NULL
    if (!identical(a, b)) {
      row$ok <- FALSE
      row$problems <- paste(c(row$problems[nzchar(row$problems)], "metadata (dials, facts, labels) differ"),
                            collapse = "; ")
    }
    same_bytes <- identical(unname(tools::md5sum(js_r)), unname(tools::md5sum(js_py)))
    row$problems <- paste(c(row$problems[nzchar(row$problems)],
                            if (same_bytes) "byte-identical" else "same JSON, different text"),
                          collapse = "; ")
    add(row)
  }

  ex_dir <- file.path(py_dir, "exhibits")
  expected <- character()
  for (snap in sort(list.files(snap_dir, pattern = "\\.rds$", full.names = TRUE))) {
    name <- sub("\\.rds$", "", basename(snap))
    parts <- flatten_snapshot(readRDS(snap), name)
    for (nm in names(parts)) {
      expected <- c(expected, nm)
      p <- file.path(ex_dir, paste0(nm, ".csv"))
      if (!file.exists(p)) { missing("exhibits", nm); next }
      add(compare_parity_frames(parts[[nm]], .read_parity_csv(p), nm, "exhibits"))
    }
  }
  extra <- setdiff(sub("\\.csv$", "", list.files(ex_dir, pattern = "\\.csv$")), expected)
  for (nm in extra) {
    add(data.frame(group = "exhibits", output = nm, n_values = 0L, max_abs_diff = NA_real_,
                   max_rel_diff = NA_real_, ok = FALSE, problems = "no R snapshot for this file",
                   stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

# The vintage export/py was built from (grid.js records it).
py_parity_vintage <- function(py_dir = py_parity_dir()) {
  js <- file.path(py_dir, "site", "grid.js")
  if (!file.exists(js)) return(NA_character_)
  .grid_js_payload(js)$vintage
}
