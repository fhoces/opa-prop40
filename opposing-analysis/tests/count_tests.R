# Run the full suite with a ListReporter and write one row per test file to
# site/data/test-summary.csv, which the materials page reads. Run from the
# project root (opposing-analysis/): Rscript tests/count_tests.R
# (testthat's "summary" reporter prints only the first failures, so counts come
# from the ListReporter, not from the console.)
library(testthat)
if (!dir.exists("R")) stop("Run from project root (the directory containing R/ and tests/).")
invisible(lapply(list.files("R", pattern = "[.]R$", full.names = TRUE), source))

res <- as.data.frame(test_dir("tests/testthat", reporter = ListReporter$new(), stop_on_failure = FALSE))
by_file <- do.call(rbind, lapply(split(res, res$file), function(d) data.frame(
  file = d$file[1],
  tests = nrow(d),
  expectations = sum(d$nb),
  passed = sum(!d$skipped & !d$error & d$failed == 0),
  failed = sum(d$failed > 0 | d$error),
  skipped = sum(d$skipped)
)))
by_file$run_date <- format(Sys.Date())
by_file$authors_repo_available <- rauh_available()
by_file$r_version <- paste(R.version$major, R.version$minor, sep = ".")
dir.create("site/data", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(by_file, "site/data/test-summary.csv", row.names = FALSE)
print(by_file[, 1:6])
cat(sprintf("TOTAL tests %d, expectations %d, passed %d, failed %d, skipped %d\n",
            sum(by_file$tests), sum(by_file$expectations), sum(by_file$passed),
            sum(by_file$failed), sum(by_file$skipped)))
