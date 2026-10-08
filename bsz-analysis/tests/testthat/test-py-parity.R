# R vs Python parity (helper-py-parity.R). export/py/ is committed, written by
# `python py/run_export.py`; this test skips, rather than fails, when it is
# absent or was built from the other vintage, so an R-only run is not
# blocked. Every number must match at 1e-9 relative (see the helper).

test_that("export/py reproduces every number the R side exports", {
  skip_if_not(dir.exists(py_parity_dir()), "export/py not built yet (python py/run_export.py)")
  skip_if_not(identical(py_parity_vintage(), bsz_vintage()),
              paste("export/py was built from another vintage than", bsz_vintage()))
  tab <- py_parity_table()
  expect_gt(nrow(tab), 40)
  expect_setequal(unique(tab$group), c("contract", "site", "exhibits"))
  for (i in seq_len(nrow(tab))) {
    expect_true(tab$ok[i], label = paste0(tab$group[i], "/", tab$output[i], ": ", tab$problems[i]))
  }
  # The explorer's data file is the same text in both languages.
  expect_match(tab$problems[tab$output == "grid.js"], "byte-identical")
})

test_that("flatten_snapshot names list parts the way run_export.py names its files", {
  x <- list(panel = data.frame(a = 1), summary = list(v = c(p = 1, q = 2), s = 3))
  f <- flatten_snapshot(x, "obj")
  expect_named(f, c("obj__panel", "obj__summary"))
  expect_equal(f$obj__summary$key, c("v.p", "v.q", "s"))
  expect_named(flatten_snapshot(list(a = 1, b = 2), "kv"), "kv")
})
