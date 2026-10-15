# Endpoints: the common estimating function must reproduce each analysis's own number.
k   <- read_contracts()
res <- build_all(k)
ep  <- res$endpoints
val <- function(id, col = "value") ep[[col]][ep$endpoint_id == id]
bi  <- bridge_inputs(k)

test_that("all-BSZ inputs reproduce BSZ Table 5 row 1 exactly", {
  expect_equal(score_common(bi$sup)[["a"]], pick(k$bsz$outputs, "tab5_row1_wealth_tax_revenue"),
               tolerance = 1e-12)
  expect_equal(round(val("bsz_tab5_row1")), val("bsz_tab5_row1", "printed_value"))   # 104, PDF p.39
  expect_equal(round(val("bsz_tab5_row1"), 1), 103.8)
})

test_that("GGSS: the estimate rounds to the printed $104B and the headline is their $100B rounding", {
  expect_equal(round(val("ggss_scoring")), val("ggss_scoring", "printed_value"))
  expect_equal(val("ggss_headline"), val("ggss_headline", "printed_value"))
  expect_equal(val("ggss_headline"), 100)
})

test_that("BSZ-side net components equal BSZ Table 5 row 1's own columns", {
  x <- score_common(bi$sup)
  expect_equal(x[["X"]], pick(k$bsz$outputs, "tab5_row1_extra_ca_inctax_sales"), tolerance = 1e-10)
  expect_equal(-x[["annual_loss"]], pick(k$bsz$outputs, "tab5_row1_annual_ca_inctax_loss"), tolerance = 1e-10)
})

test_that("JR NBER: analytic -38.98 vs printed -38.9 (one Monte Carlo run)", {
  expect_equal(round(val("rauh_nber_npv"), 2), -38.98)
  expect_lt(abs(val("rauh_nber_npv") - val("rauh_nber_npv", "printed_value")), 0.5)
  expect_lt(abs(val("rauh_nber_npv", "contract_value") - val("rauh_nber_npv", "printed_value")), 0.05)
  expect_equal(val("rauh_nber_revenue_mc"), 36)
})

test_that("the common function at the all-JR inputs returns the JR analysis's own expectation exactly", {
  own <- res$ends[res$ends$horizon_setting == "own", ]
  expect_equal(own$rauh_model, own$rauh_own, tolerance = 1e-12)
  expect_lt(max(abs(res$ends$rauh_residual)), 1e-10)          # every horizon setting
  expect_equal(score_common(bi$rauh)[["b"]], val("rauh_nber_npv"), tolerance = 1e-12)
})

test_that("the JR inputs rebuild the September version's base, ceiling and weights from its contract", {
  r <- bi$rauh; oi <- k$rjkdc$inputs; oo <- k$rjkdc$outputs
  x <- score_common(r)
  expect_equal(r$W_core, pick(oi, "baseline_net_worth") * 1.07, tolerance = 1e-12)
  expect_equal(x[["R0"]], pick(oo, "nber_domestic_grown"), tolerance = 1e-12)       # 100.906
  expect_equal(x[["R0"]] * x[["S"]], pick(oi, "nber_ceiling_hardcoded"), tolerance = 1e-12)  # 72
  expect_equal(x[["a"]], 36, tolerance = 1e-12)                                       # 0.5 x 72
  expect_equal(x[["f"]], 0.45, tolerance = 1e-12)                                     # E[U(0.30, 0.60)]
  expect_equal(r$q, 0.5); expect_equal(r$own, 0); expect_equal(bi$sup$own, 1); expect_equal(bi$sup$q, 1); expect_equal(bi$sup$f0, 0)
})

test_that("the expected annuity has the right limits", {
  expect_equal(expected_annuity(Inf, 0.015, 0.045), log(3) / 0.03)
  expect_lt(expected_annuity(5, 0.015, 0.045), 5)
  expect_equal(expected_annuity(5, 1e-4, 2e-4), 5, tolerance = 1e-3)   # r -> 0 gives H
  expect_true(all(diff(sapply(c(5, 10, 20, 30, 50, 500), expected_annuity, 0.015, 0.045)) > 0))
})

test_that("output (a): both JR revenue figures are reported, the Monte Carlo mean is the default", {
  a <- res$anchors
  expect_equal(nrow(a), 2)
  expect_equal(a$anchor_id[a$default], "mc_expected")
  expect_equal(a$value[a$anchor_id == "mc_expected"], 36)
  expect_equal(a$value[a$anchor_id == "preferred_about_30"], 30)
})
