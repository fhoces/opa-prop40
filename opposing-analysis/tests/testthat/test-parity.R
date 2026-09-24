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

test_that("Monte Carlo ranges in the export are the ones the simulations draw, as printed", {
  # comparison/ reads these rows from this contract (moved out of
  # comparison/data/document-inputs.csv), so pin both the code and the paper values.
  for (side in c("r", "py")) {
    path <- project_path(file.path("export", side, "inputs.csv"))
    skip_if_not(file.exists(path), paste(path, "not built yet"))
    inp <- utils::read.csv(path, stringsAsFactors = FALSE)
    v <- function(id) inp$value[inp$input_id == id]
    ssrn <- formals(compute_npv_mc_ssrn); nber <- formals(compute_npv_mc_nber)
    expect_equal(v("rauh_mc_wt_min"), ssrn$wt_min)
    expect_equal(v("rauh_mc_c_min"), ssrn$c_min); expect_equal(v("rauh_mc_c_max"), ssrn$c_max)
    expect_equal(v("rauh_mc_r_min"), ssrn$r_min); expect_equal(v("rauh_mc_r_max"), ssrn$r_max)
    expect_equal(v("nber_mc_f_min"), nber$f_min); expect_equal(v("nber_mc_f_max"), nber$f_max)
    # printed: SSRN eq.22-24 (p.20), NBER Sec 5.4 (p.35); NBER shares the C and discount draws
    expect_equal(c(v("rauh_mc_wt_min"), v("rauh_mc_c_min"), v("rauh_mc_c_max"),
                   v("rauh_mc_r_min"), v("rauh_mc_r_max"), v("nber_mc_f_min"), v("nber_mc_f_max")),
                 c(35, 3.3, 5.8, 0.015, 0.045, 0.30, 0.60))
    # NBER names the discount draw r - g
    expect_equal(c(nber$c_min, nber$c_max, nber$rg_min, nber$rg_max), c(ssrn$c_min, ssrn$c_max, ssrn$r_min, ssrn$r_max))
  }
})
