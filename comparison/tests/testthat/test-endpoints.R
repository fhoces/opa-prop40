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

test_that("the rate dial: 3% at the BSZ end (the BSZ overview's rate), 1 / E[1/r] over the JR draw at the JR end", {
  r <- pick(k$docs, BSZ_RATE_ID)
  expect_equal(r, 0.03)
  expect_identical(bi$sup$r, r)
  oi <- k$rjkdc$inputs
  rmin <- pick(oi, "rauh_mc_r_min"); rmax <- pick(oi, "rauh_mc_r_max")
  expect_equal(r, (rmin + rmax) / 2, tolerance = 1e-12)                 # the middle of the JR draw
  grid <- paste(readLines(file.path(comparison_root(), "bsz-analysis", "export", "py", "site", "grid.js"),
                          warn = FALSE, encoding = "UTF-8"), collapse = "")
  expect_equal(as.numeric(sub('.*"pv_rate":([0-9.]+).*', "\\1", grid)), r)
  # the JR rate is computed from the contract's draw range, never typed
  expect_equal(bi$rauh$r, (rmax - rmin) / log(rmax / rmin), tolerance = 1e-14)
  expect_equal(bi$rauh$r, 0.03 / log(3), tolerance = 1e-14)
  expect_equal(round(bi$rauh$r, 6), 0.027307)
  expect_equal(1 / bi$rauh$r, expected_annuity(Inf, rmin, rmax), tolerance = 1e-14)
  # the rate range is not an argument of score_common(): neither input vector carries it
  expect_false(any(c("r_min", "r_max") %in% c(names(bi$sup), names(bi$rauh))))
  m <- res$meta; mv <- function(key) m$value[m$key == key]
  expect_equal(mv("r_bsz"), r); expect_equal(mv("r_jr"), bi$rauh$r)
  expect_equal(mv("A_5"), (1 - (1 + r)^-5) / r, tolerance = 1e-12)       # 5 years at 3%: 4.58
  expect_equal(mv("A_inf"), 1 / bi$rauh$r, tolerance = 1e-12)            # for ever at 2.73%: 36.62
  expect_equal(mv("A_inf"), mv("A_inf_jr_draw"), tolerance = 1e-12)
  expect_false("jr_rate_gap" %in% m$key)
})

test_that("BSZ end still exact: the net total over 5 years at 3% is 106.80", {
  eb <- res$ends[res$ends$horizon_setting == "own" & res$ends$output == "b", ]
  expect_equal(round(eb$bsz_model, 2), 106.80)
  expect_equal(eb$bsz_model, val("bsz_net_constructed"))
})

test_that("the common function at the all-JR inputs returns the JR analysis's own expectation, to 1e-9", {
  expect_lt(abs(score_common(bi$rauh)[["b"]] - val("rauh_nber_npv")), 1e-9)
  expect_lt(abs(score_common(bi$rauh)[["a"]] - val("rauh_nber_revenue_mc")), 1e-9)
  en <- res$ends
  inf <- en[en$horizon_setting %in% c("own", "common_Inf"), ]
  expect_lt(max(abs(inf$jr_residual)), 1e-9)                     # in perpetuity: exact
  expect_lt(max(abs(en$jr_residual[en$output == "a"])), 1e-9)    # revenue: exact everywhere
  expect_equal(round(val("rauh_nber_npv"), 2), -38.98)
  expect_false(any(c("jr_rate_gap") %in% names(en)))
  expect_false("rauh_common_end" %in% ep$endpoint_id)
})

test_that("at a finite common horizon, one rate misses f0 x C x (annuity(r_jr, H) - E[annuity]) of the authors' average", {
  oi <- k$rjkdc$inputs; rj <- bi$rauh$r
  rmin <- pick(oi, "rauh_mc_r_min"); rmax <- pick(oi, "rauh_mc_r_max")
  expect_equal(bi$rauh$alpha, 0); expect_equal(bi$rauh$own, 0)   # so f = f0 at the JR inputs
  for (H in c(5, 10, 20, 30, 50)) {
    e <- res$ends[res$ends$horizon_setting == paste0("common_", H) & res$ends$output == "b", ]
    expect_lt(abs(e$jr_residual - bi$rauh$f0 * bi$rauh$C * (annuity(rj, H) - expected_annuity(H, rmin, rmax))), 1e-9,
              label = paste("H =", H))
    expect_gt(e$jr_residual, 0)
  }
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

test_that("the annuity at one rate has the right limits", {
  expect_equal(annuity(0.03, Inf), 1 / 0.03)
  expect_equal(annuity(0.03, 0), 0)
  expect_equal(round(annuity(0.03, 5), 1), 4.6)
  expect_equal(annuity(1e-9, 5), 5, tolerance = 1e-6)                  # r -> 0 gives H
  expect_true(all(diff(sapply(c(5, 10, 20, 30, 50, 500), annuity, r = 0.03)) > 0))
})

test_that("the expected annuity over the JR draw (used for the JR rate) has the right limits", {
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
