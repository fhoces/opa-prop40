test_that("SSRN NPV MC matches the paper's printed Sec 5.5 summary (p.20)", {
  res <- compute_npv_mc_ssrn()
  s <- res$summary
  tol <- mc_tol(s$sd, s$n)
  expect_equal(s$mean, -24.7, tolerance = tol / 24.7)
  expect_equal(s$median, -19.1, tolerance = tol / 19.1)
  # Absolute, in points (scale = 1): the printed integer's rounding plus four standard errors
  # of a share, about 1.07 points.
  p <- s$pct_negative / 100
  expect_equal(s$pct_negative, 71, tolerance = 0.5 + 400 * sqrt(p * (1 - p) / s$n), scale = 1)
})

test_that("NBER NPV MC matches the NBER README's printed summary", {
  res <- compute_npv_mc_nber()
  s <- res$summary
  tol <- mc_tol(s$sd, s$n)
  expect_equal(s$mean, -38.9, tolerance = tol / 38.9)
  expect_equal(s$median, -35.3, tolerance = tol / 35.3)
  # Absolute, in points (scale = 1): the printed digit's rounding plus four standard errors
  # of a share, about 0.50 points.
  p <- s$pct_negative / 100
  expect_equal(s$pct_negative, 85.2, tolerance = 0.05 + 400 * sqrt(p * (1 - p) / s$n), scale = 1)
  # The SD (PDF p.35), absolute (scale = 1): four standard errors of an SD over 100,000 draws,
  # 4 x sd / sqrt(2n), about 0.34 (author answer 2026-10-16). The seeded run gives 37.62.
  expect_equal(s$sd, 37.6, tolerance = 0.34, scale = 1)
})

test_that("SSRN NPV MC reproduces from the authors' own NPV_dist.R", {
  skip_if_no_rauh()
  env <- run_author_script(rauh_npv_dist_script())
  skip_if(is.null(env), "author script not found")

  res <- compute_npv_mc_ssrn()
  expect_equal(mean(res$draws$npv), mean(env$results$npv), tolerance = 1e-9)
  expect_equal(sd(res$draws$npv), sd(env$results$npv), tolerance = 1e-9)
  expect_equal(res$draws$npv, env$results$npv, tolerance = 1e-9)
})

test_that("NBER NPV MC reproduces from the authors' own NPV_dist_v8.R", {
  skip_if_no_rauh()
  env <- run_author_script(rauh_npv_dist_v8_script())
  skip_if(is.null(env), "author script not found")

  res <- compute_npv_mc_nber()
  expect_equal(res$draws$npv, env$npv, tolerance = 1e-9)
})

test_that("analytic mean cross-check agrees with the Monte Carlo mean (both versions)", {
  ssrn <- compute_npv_mc_ssrn()
  nber <- compute_npv_mc_nber()

  analytic_ssrn <- npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045,
                                         f_mode = "ssrn", baseline_revenue = 94.2)
  analytic_nber <- npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045,
                                         f_mode = "nber", f_min = 0.30, f_max = 0.60)

  expect_equal(analytic_ssrn, ssrn$summary$mean, tolerance = mc_tol(ssrn$summary$sd, ssrn$summary$n) / abs(analytic_ssrn))
  expect_equal(analytic_nber, nber$summary$mean, tolerance = mc_tol(nber$summary$sd, nber$summary$n) / abs(analytic_nber))
})

test_that("the exact SD rounds to the printed SD, and each seeded run lies within Monte Carlo error of it (MISMATCHES.md note 9)", {
  ssrn <- compute_npv_mc_ssrn()
  nber <- compute_npv_mc_nber()
  sd_ssrn <- npv_mc_analytic_sd(35, 67.51, 3.3, 5.8, 0.015, 0.045,
                                f_mode = "ssrn", baseline_revenue = 94.2)
  sd_nber <- npv_mc_analytic_sd(0, 72, 3.3, 5.8, 0.015, 0.045,
                                f_mode = "nber", f_min = 0.30, f_max = 0.60)
  expect_equal(round(sd_ssrn, 1), 38.4)   # first version, p.20
  expect_equal(round(sd_nber, 1), 37.6)   # NBER, PDF p.35
  # the seeded SDs (38.60 and 37.62) within four standard errors of an SD, 4 x sd / sqrt(2n)
  expect_equal(ssrn$summary$sd, sd_ssrn, tolerance = 4 * sd_ssrn / sqrt(2 * ssrn$summary$n), scale = 1)
  expect_equal(nber$summary$sd, sd_nber, tolerance = 4 * sd_nber / sqrt(2 * nber$summary$n), scale = 1)
  # the first version's printed SD against its seeded run, as the NBER SD is tested above
  expect_equal(ssrn$summary$sd, 38.4, tolerance = 4 * ssrn$summary$sd / sqrt(2 * ssrn$summary$n), scale = 1)
})
