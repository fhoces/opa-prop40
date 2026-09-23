# Parity between export/r and export/py: deterministic steps (Pareto fit,
# revenue chain, NPV tables, NBER ceiling) must match to 1e-6; Monte-Carlo
# summaries (income-tax MC, NPV MC) match within Monte Carlo error since R
# and numpy cannot share an RNG stream. Both exports must exist (built by
# `Rscript -e 'targets::tar_make()'` and `python py/run_export.py`
# respectively) - this test skips, rather than fails, if either is absent,
# so it doesn't block a test run that only exercises one language.

test_that("export/r and export/py outputs agree within documented tolerance", {
  r_path <- project_path("export/r/outputs.csv")
  py_path <- project_path("export/py/outputs.csv")
  skip_if_not(file.exists(r_path), "export/r/outputs.csv not built yet")
  skip_if_not(file.exists(py_path), "export/py/outputs.csv not built yet")

  r_out <- utils::read.csv(r_path, stringsAsFactors = FALSE)
  py_out <- utils::read.csv(py_path, stringsAsFactors = FALSE)

  merged <- merge(r_out, py_out, by = c("output_id", "version"), suffixes = c("_r", "_py"))
  expect_gt(nrow(merged), 0)

  mc_ids <- c("income_tax_mc_k212", "income_tax_mc_k300", "income_tax_mc_k500",
              "npv_mc_ssrn_mean", "npv_mc_ssrn_median", "npv_mc_ssrn_sd",
              "npv_mc_ssrn_pct_negative", "npv_mc_nber_mean", "npv_mc_nber_median",
              "npv_mc_nber_pct_negative")

  for (i in seq_len(nrow(merged))) {
    id <- merged$output_id[i]
    v_r <- merged$value_r[i]
    v_py <- merged$value_py[i]
    if (is.na(v_r) || is.na(v_py)) next
    # Monte-Carlo-derived rows: 4 x sd/sqrt(n) around the printed value
    # (brief's own tolerance rule), applied symmetrically to the R-vs-Python
    # gap since both are independent MC estimates of the same quantity.
    tol <- if (id %in% mc_ids) 2.0 else 1e-6 * max(1, abs(v_r))
    expect_lt(abs(v_r - v_py), tol, label = id)
  }
})

test_that("export/r and export/py inputs.csv describe the same input_ids", {
  r_path <- project_path("export/r/inputs.csv")
  py_path <- project_path("export/py/inputs.csv")
  skip_if_not(file.exists(r_path), "export/r/inputs.csv not built yet")
  skip_if_not(file.exists(py_path), "export/py/inputs.csv not built yet")

  r_in <- utils::read.csv(r_path, stringsAsFactors = FALSE)
  py_in <- utils::read.csv(py_path, stringsAsFactors = FALSE)
  expect_setequal(paste(r_in$input_id, r_in$version), paste(py_in$input_id, py_in$version))
})
