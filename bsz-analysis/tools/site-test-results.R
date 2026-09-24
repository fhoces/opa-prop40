# Run the full test suite and write one row per test_that() block to
# site/data/test-results.csv, which the Open Materials page reads.
#
#   Rscript tools/site-test-results.R      (from bsz-analysis/)
#
# The CSV records the vintage, the date and the per-block expectation counts,
# so the counts published on the site are the output of a run, not typed.

suppressMessages(library(testthat))
if (!dir.exists("R")) stop("Run from bsz-analysis/ (the directory containing R/).")
invisible(lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source))

rep <- testthat::ListReporter$new()
invisible(testthat::test_dir("tests/testthat", reporter = rep, stop_on_failure = FALSE))

rows <- lapply(rep$get_results(), function(t) {
  cls <- vapply(t$results, function(e) class(e)[1], "")
  data.frame(
    file   = t$file,
    test   = t$test,
    passed = sum(cls == "expectation_success"),
    failed = sum(cls %in% c("expectation_failure", "expectation_error")),
    skipped = sum(cls == "expectation_skip"),
    stringsAsFactors = FALSE
  )
})
out <- do.call(rbind, rows)
out$vintage <- bsz_vintage()
out$run_date <- format(Sys.Date())
path <- file.path("site", "data", "test-results.csv")
dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(out, path, row.names = FALSE)
cat(sprintf("%s: %d passed, %d failed, %d skipped, %d test blocks -> %s\n",
            bsz_vintage(), sum(out$passed), sum(out$failed), sum(out$skipped),
            nrow(out), path))
