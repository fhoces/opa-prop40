library(testthat)

# Run from project root: Rscript tests/testthat.R
if (!dir.exists("R")) {
  stop("Run from project root (the directory containing R/ and tests/).")
}

invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

test_dir("tests/testthat", reporter = "summary")
