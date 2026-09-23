test_that("SSRN NPV MC matches the paper's printed Sec 5.5 summary (p.20)", {
  res <- compute_npv_mc_ssrn()
  s <- res$summary
  tol <- mc_tol(s$sd, s$n)
  expect_equal(s$mean, -24.7, tolerance = tol / 24.7)
  expect_equal(s$median, -19.1, tolerance = tol / 19.1)
  expect_equal(s$pct_negative, 71, tolerance = 1)
})

test_that("NBER NPV MC matches the NBER README's printed summary", {
  res <- compute_npv_mc_nber()
  s <- res$summary
  tol <- mc_tol(s$sd, s$n)
  expect_equal(s$mean, -38.9, tolerance = tol / 38.9)
  expect_equal(s$median, -35.3, tolerance = tol / 35.3)
  expect_equal(s$pct_negative, 85.2, tolerance = 0.5)
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
