# Helper for embedding R-source listings in the Quarto report. The function
# body lives once in its R/*.R file; this helper pulls the source lines via
# getSrcref() at render time, so the listing never drifts from the actual
# definition. Appends a "Read-only. Edit at R/<file>:<lines>." footer.

deparse_function <- function(fn_name) {
  fn  <- get(fn_name, envir = globalenv())
  ref <- attr(fn, "srcref")
  if (is.null(ref)) {
    return(c(
      paste0(fn_name, " <- "),
      deparse(fn),
      "",
      "# Read-only display (no source reference available)."
    ))
  }
  src_lines <- as.character(ref)
  file      <- basename(attr(ref, "srcfile")$filename)
  start_ln  <- ref[1L]
  end_ln    <- ref[3L]
  c(src_lines, "",
    paste0("# Read-only display. Edit R/", file,
           ":", start_ln, "-", end_ln, "."))
}
