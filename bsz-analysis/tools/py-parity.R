# The R vs Python parity report: one row per output of py/run_export.py, with
# the number of values compared and the largest absolute and relative gaps
# against the R side. Writes export/py/parity.csv and prints a summary.
#
# Run from bsz-analysis/ after `python py/run_export.py` (and tar_make()):
#   Rscript tools/py-parity.R
#
# The comparison itself lives in tests/testthat/helper-py-parity.R, which
# test-py-parity.R also runs.

stopifnot(dir.exists("R"), file.exists("_targets.R"))
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))
source(file.path("tests", "testthat", "helper-py-parity.R"))

tab <- py_parity_table()
out <- file.path(py_parity_dir(), "parity.csv")
utils::write.csv(tab, out, row.names = FALSE, fileEncoding = "UTF-8")

by_group <- do.call(rbind, lapply(split(tab, tab$group), function(g) data.frame(
  group = g$group[1], outputs = nrow(g), values = sum(g$n_values),
  max_abs_diff = max(g$max_abs_diff, na.rm = TRUE),
  max_rel_diff = max(g$max_rel_diff, na.rm = TRUE), all_ok = all(g$ok))))
print(by_group, row.names = FALSE)
cat(sprintf("\n%d outputs, %d numbers compared, %d not matching. Wrote %s\n",
            nrow(tab), sum(tab$n_values), sum(!tab$ok), out))
if (any(!tab$ok)) {
  print(tab[!tab$ok, c("group", "output", "problems")], row.names = FALSE)
  quit(status = 1)
}
