.diff_column <- function(actual, expected, col_name, j, tolerance) {
  # Return a one-line diff message describing how `actual` differs from
  # `expected` for column j, or NULL if they match within tolerance.
  na_a <- is.na(actual); na_e <- is.na(expected)
  if (any(na_a != na_e)) {
    return(sprintf("Column %s (%d): NA pattern differs in %d cells",
                    col_name, j, sum(na_a != na_e)))
  }
  both <- !na_a & !na_e
  if (is.numeric(expected) && is.numeric(actual)) {
    d <- abs(actual[both] - expected[both])
    scale <- pmax(abs(expected[both]), 1)
    bad <- which(d / scale > tolerance)
    if (length(bad)) {
      return(sprintf("Column %s (%d): %d numeric cells differ beyond tolerance %g (max rel diff %g)",
                      col_name, j, length(bad), tolerance, max(d / scale)))
    }
  } else {
    bad <- which(as.character(actual[both]) != as.character(expected[both]))
    if (length(bad)) {
      return(sprintf("Column %s (%d): %d character cells differ",
                      col_name, j, length(bad)))
    }
  }
  NULL
}

expect_matches_excel <- function(actual,
                                 sheet,
                                 path = xlsx_path_default(),
                                 range = NULL,
                                 tolerance = 1e-6) {
  expected    <- read_sheet(sheet = sheet, path = path, range = range)
  actual_df   <- as.data.frame(actual)
  expected_df <- as.data.frame(expected)

  if (!identical(dim(actual_df), dim(expected_df))) {
    testthat::fail(sprintf(
      "Shape mismatch for sheet %s: actual=%dx%d, expected=%dx%d",
      sheet, nrow(actual_df), ncol(actual_df),
      nrow(expected_df), ncol(expected_df)
    ))
    return(invisible(actual))
  }

  diffs <- Filter(Negate(is.null),
                   lapply(seq_len(ncol(expected_df)), function(j) {
                     .diff_column(actual_df[[j]], expected_df[[j]],
                                   names(expected_df)[j], j, tolerance)
                   }))

  if (length(diffs)) {
    testthat::fail(paste0("Sheet '", sheet, "' mismatch:\n  ",
                           paste(unlist(diffs), collapse = "\n  ")))
  } else {
    testthat::succeed()
  }
  invisible(actual)
}
