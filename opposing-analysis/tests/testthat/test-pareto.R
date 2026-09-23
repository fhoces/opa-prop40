test_that("Pareto fit matches the paper's printed alpha and R2 (p.15)", {
  fit <- compute_pareto_fit()
  expect_equal(round(fit$alpha, 2), 1.44)
  expect_equal(round(fit$r_squared, 3), 0.999)
})

test_that("rank-implied income schedule matches the paper's top-212 share (p.16)", {
  fit <- compute_pareto_fit()
  sched <- compute_pareto_income_schedule(fit)
  # "the top 212 positions collectively account for ... 38.8% of bracket tax
  # liability" (p.16, footnote 12).
  expect_equal(round(sched$continuous_top_share * 100, 1), 38.8, tolerance = 0.1)
  # "For the top 212 of 4,729 filers, this implies a 39.0% share ... $4.3
  # billion in Tax Year 2023" (p.15, eq.16 discussion) - this is the
  # DISCRETE (unrescaled) share, distinct from the continuous 38.8% above.
  expect_equal(round(sched$discrete_top_share * 100, 1), 39.0, tolerance = 0.2)
})

test_that("Pareto fit reproduces from the authors' own monte_carlo_sim.R", {
  skip_if_no_rauh()
  env <- run_author_script(rauh_income_tax_mc_script())
  skip_if(is.null(env), "author script not found")
  fit <- compute_pareto_fit()
  expect_equal(fit$alpha, unname(env$alpha), tolerance = 1e-9)
  expect_equal(fit$r_squared, unname(env$r_sq), tolerance = 1e-9)
})
