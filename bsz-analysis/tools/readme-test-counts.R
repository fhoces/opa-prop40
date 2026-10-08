# Rewrite the test-count block in README.md from site/data/test-results.csv, so the
# README carries the counts of the last recorded run, not typed numbers.
#
#   Rscript tools/readme-test-counts.R      (from bsz-analysis/; site-test-results.R calls it)
#
# The block sits between the markers <!-- test-counts:start --> and <!-- test-counts:end -->.

readme_test_counts <- function(csv = file.path("site", "data", "test-results.csv"),
                               readme = "README.md") {
  res  <- utils::read.csv(csv, stringsAsFactors = FALSE)
  per  <- tapply(res$passed, sub("^test-(.*)[.]R$", "\\1", res$file), sum)
  note <- c(site = "the explorer runs compute_tab5.R's estimating function; grid.js is the exporter's output",
            snapshots = "pin exact output of every exhibit + compute_* fn")
  row  <- function(k, n) {
    s <- sprintf("%-14s%3d", paste0(k, ":"), n)
    if (k %in% names(note)) paste0(s, "       # ", note[[k]]) else s
  }
  block <- c("<!-- test-counts:start -->", "```",
             mapply(row, names(per), per, USE.NAMES = FALSE),
             sprintf("%14s---", ""),
             sprintf("%-14s%3d       # %s vintage, %s, %d test blocks across %d files, %d failed, %d skipped",
                     "total:", sum(res$passed), tools::toTitleCase(res$vintage[1]), res$run_date[1], nrow(res),
                     length(per), sum(res$failed), sum(res$skipped)),
             "```", "<!-- test-counts:end -->")
  l <- readLines(readme, warn = FALSE)
  a <- grep("<!-- test-counts:start -->", l, fixed = TRUE)
  b <- grep("<!-- test-counts:end -->", l, fixed = TRUE)
  if (length(a) != 1 || length(b) != 1 || b < a) stop("README.md: test-count markers not found once each")
  writeLines(c(l[seq_len(a - 1)], block, l[-seq_len(b)]), readme)
  invisible(sum(res$passed))
}

if (sys.nframe() == 0) {
  if (!file.exists("README.md") || !dir.exists("R")) stop("Run from bsz-analysis/.")
  cat(sprintf("README.md: test counts rewritten (%d passed)\n", readme_test_counts()))
}
