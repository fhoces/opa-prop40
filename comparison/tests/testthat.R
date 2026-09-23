# Run from anywhere inside the repo:  Rscript comparison/tests/testthat.R
library(testthat)
here <- normalizePath(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))
for (f in list.files(file.path(here, "..", "R"), pattern = "\\.R$", full.names = TRUE)) source(f)
res <- test_dir(file.path(here, "testthat"), reporter = "summary", stop_on_failure = FALSE)
df <- as.data.frame(res)
cat(sprintf("\nexpectations: %d, failed: %d, skipped: %d\n",
            sum(df$nb), sum(df$failed), sum(df$skipped)))
if (sum(df$failed) > 0 || any(df$error)) quit(status = 1)
