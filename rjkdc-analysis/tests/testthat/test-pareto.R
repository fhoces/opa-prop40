test_that("Pareto fit matches the paper's printed alpha and R2 (p.15)", {
  fit <- compute_pareto_fit()
  expect_equal(round(fit$alpha, 2), 1.44)
  expect_equal(round(fit$r_squared, 3), 0.999)
})

test_that("rank-implied income schedule matches the paper's top-212 share (p.16)", {
  fit <- compute_pareto_fit()
  sched <- compute_pareto_income_schedule(fit)
  # "the top 212 positions collectively account for ... 38.8% of bracket tax
  # liability" (chapter PDF p.28; first version p.16, footnote 12).
  expect_equal(round(sched$continuous_top_share * 100, 1), 38.8)
  # The share of the top 212 in the rank-implied schedule before the script
  # rescales it to the continuous share (monte_carlo_sim.R:69): 34.75%. The text
  # prints the same formula as "a 39.0% share ... $4.3 billion in Tax Year 2023"
  # (chapter PDF p.27, eq. 10; first version p.15) and as 38.8% (chapter PDF
  # p.28); no step of the code gives 39.0% (NOTES.md note 10).
  expect_equal(round(sched$discrete_top_share * 100, 2), 34.75)
})

test_that("Pareto fit reproduces from the authors' own monte_carlo_sim.R", {
  skip_if_no_rauh()
  env <- run_author_script(rauh_income_tax_mc_script())
  skip_if(is.null(env), "author script not found")
  fit <- compute_pareto_fit()
  expect_equal(fit$alpha, unname(env$alpha), tolerance = 1e-9)
  expect_equal(fit$r_squared, unname(env$r_sq), tolerance = 1e-9)
})
