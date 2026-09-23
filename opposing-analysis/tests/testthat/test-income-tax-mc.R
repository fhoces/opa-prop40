income_tax_mc_fixture <- function() {
  fit <- compute_pareto_fit()
  sched <- compute_pareto_income_schedule(fit)
  results <- compute_income_tax_mc(sched$tax_by_rank)
  income_tax_mc_table8(results)
}

test_that("income tax MC matches Table 8's printed cells (p.17)", {
  t8 <- income_tax_mc_fixture()
  printed <- tibble::tribble(
    ~K, ~mean, ~p05, ~p95,
    212, 5.76, 5.76, 5.76,
    250, 5.18, 4.79, 5.45,
    300, 4.61, 4.14, 5.01,
    400, 3.83, 3.33, 4.31,
    500, 3.31, 2.83, 3.82,
    750, 2.54, 2.12, 3.03,
    1000, 2.10, 1.73, 2.57
  )
  merged <- merge(t8, printed, by = "K")
  # Printed to 2 decimals; our fitted alpha (1.4379...) differs from the
  # paper's rounded-for-display 1.44 by enough to move even the
  # deterministic K=212 cell by ~0.003, so all rows get the same
  # printed-rounding tolerance rather than K=212 getting an exact match.
  tol <- 0.01
  for (i in seq_len(nrow(merged))) {
    expect_equal(merged$mean_fy25[i], merged$mean[i], tolerance = tol[i] / abs(merged$mean[i]))
    expect_equal(merged$p05_fy25[i], merged$p05[i], tolerance = tol[i] / abs(merged$p05[i]))
    expect_equal(merged$p95_fy25[i], merged$p95[i], tolerance = tol[i] / abs(merged$p95[i]))
  }
})

test_that("income tax MC reproduces from the authors' own monte_carlo_sim.R", {
  skip_if_no_rauh()
  env <- run_author_script(rauh_income_tax_mc_script())
  skip_if(is.null(env), "author script not found")

  t8 <- income_tax_mc_fixture()
  author_results <- env$results
  merged <- merge(t8, author_results[, c("K", "mean_fy25", "p05_fy25", "p95_fy25")],
                   by = "K", suffixes = c("", "_author"))
  # Same seed, same draw order -> should match to floating-point precision.
  expect_equal(merged$mean_fy25, merged$mean_fy25_author, tolerance = 1e-9)
  expect_equal(merged$p05_fy25, merged$p05_fy25_author, tolerance = 1e-9)
  expect_equal(merged$p95_fy25, merged$p95_fy25_author, tolerance = 1e-9)
})
