# Endpoints: the common estimating function must reproduce each side's own number.
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

test_that("Rauh SSRN: analytic expectation is -24.707 and rounds to the printed -24.7", {
  expect_equal(val("rauh_ssrn_npv"), -24.707, tolerance = 5e-4 / 24.707)
  expect_equal(round(val("rauh_ssrn_npv"), 1), val("rauh_ssrn_npv", "printed_value"))
  # the RJKDC side's own seeded run is within Monte Carlo error of the expectation
  expect_lt(abs(val("rauh_ssrn_npv", "contract_value") - val("rauh_ssrn_npv")), 0.5)
  expect_equal(val("rauh_ssrn_revenue_mc"), (35 + 67.51) / 2)
})

test_that("Rauh NBER: analytic -38.98 vs printed -38.9 (one Monte Carlo run)", {
  expect_equal(round(val("rauh_nber_npv"), 2), -38.98)
  expect_lt(abs(val("rauh_nber_npv") - val("rauh_nber_npv", "printed_value")), 0.5)
  expect_lt(abs(val("rauh_nber_npv", "contract_value") - val("rauh_nber_npv", "printed_value")), 0.05)
  expect_equal(val("rauh_nber_revenue_mc"), 36)
})

test_that("the model at all-Rauh inputs differs from Rauh's own number only by a small, labelled residual", {
  own <- res$ends[res$ends$horizon_setting == "own", ]
  expect_lt(abs(own$rauh_residual[own$output == "a"]), 0.001)
  expect_lt(abs(own$rauh_residual[own$output == "b"]), 0.15)
  expect_equal(own$rauh_model + own$rauh_residual, own$rauh_own, tolerance = 1e-12)
})

test_that("Rauh's MC ceiling and floor are reproduced by the switched inputs", {
  r <- bi$rauh
  R0 <- score_common(r)[["R0"]]
  expect_equal(R0, pick(k$rjkdc$outputs, "revenue_baseline"), tolerance = 1e-12)
  expect_equal(R0 * (1 - r$d_conf), pick(k$rjkdc$outputs, "revenue_confirmed6"), tolerance = 1e-12)
  expect_equal(R0 * (1 - r$eps * r$dtau), 35, tolerance = 1e-12)
})

test_that("the expected annuity has the right limits", {
  expect_equal(expected_annuity(Inf, 0.015, 0.045), log(3) / 0.03)
  expect_lt(expected_annuity(5, 0.015, 0.045), 5)
  expect_equal(expected_annuity(5, 1e-4, 2e-4), 5, tolerance = 1e-3)   # r -> 0 gives H
  expect_true(all(diff(sapply(c(5, 10, 20, 30, 50, 500), expected_annuity, 0.015, 0.045)) > 0))
})

test_that("output (a): every candidate for Rauh's output (a) is reported, MC mean is the default", {
  a <- res$anchors
  expect_equal(nrow(a), 4)
  expect_equal(a$anchor_id[a$default], "mc_expected")
  expect_equal(a$value[a$anchor_id == "literature_calibrated"], 45.59)
  expect_equal(a$value[a$anchor_id == "table9_central"], 42)
  expect_equal(a$value[a$anchor_id == "preferred_about_40"], 40)
})
