expect_matches_excel <- function(actual,
                                 sheet,
                                 path = xlsx_path_default(),
                                 range = NULL,
                                 tolerance = 1e-6) {
  expected <- read_sheet(sheet = sheet, path = path, range = range)
  actual_df <- as.data.frame(actual)
  expected_df <- as.data.frame(expected)

  if (!identical(dim(actual_df), dim(expected_df))) {
    msg <- sprintf(
      "Shape mismatch for sheet %s: actual=%dx%d, expected=%dx%d",
      sheet,
      nrow(actual_df), ncol(actual_df),
      nrow(expected_df), ncol(expected_df)
    )
    testthat::fail(msg)
    return(invisible(actual))
  }

  diffs <- list()
  for (j in seq_len(ncol(expected_df))) {
    a <- actual_df[[j]]
    e <- expected_df[[j]]
    na_a <- is.na(a); na_e <- is.na(e)
    if (any(na_a != na_e)) {
      diffs[[length(diffs) + 1L]] <- sprintf(
        "Column %s (%d): NA pattern differs in %d cells",
        names(expected_df)[j], j, sum(na_a != na_e)
      )
      next
    }
    both <- !na_a & !na_e
    if (is.numeric(e) && is.numeric(a)) {
      d <- abs(a[both] - e[both])
      scale <- pmax(abs(e[both]), 1)
      bad <- which(d / scale > tolerance)
      if (length(bad)) {
        diffs[[length(diffs) + 1L]] <- sprintf(
          "Column %s (%d): %d numeric cells differ beyond tolerance %g (max rel diff %g)",
          names(expected_df)[j], j, length(bad), tolerance, max(d / scale)
        )
      }
    } else {
      bad <- which(as.character(a[both]) != as.character(e[both]))
      if (length(bad)) {
        diffs[[length(diffs) + 1L]] <- sprintf(
          "Column %s (%d): %d character cells differ",
          names(expected_df)[j], j, length(bad)
        )
      }
    }
  }

  if (length(diffs)) {
    testthat::fail(paste0(
      "Sheet '", sheet, "' mismatch:\n  ",
      paste(unlist(diffs), collapse = "\n  ")
    ))
  } else {
    testthat::succeed()
  }
  invisible(actual)
}
