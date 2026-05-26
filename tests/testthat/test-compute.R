test_that("compute_data_sec_agg matches Excel data_sec_agg for shared columns", {
  d_all <- extract_data_sec_all()
  agg_xlsx <- extract_data_sec_agg()
  agg_r <- compute_data_sec_agg(d_all)

  expect_equal(nrow(agg_r), 7)
  expect_equal(agg_r$year, 2019:2025)
  expect_equal(agg_r$n, agg_xlsx$n)

  # Compare every column R computes against the Excel cached value.
  shared <- intersect(names(agg_r), names(agg_xlsx))
  shared <- setdiff(shared, c("year"))  # year compared separately above
  for (col in shared) {
    expect_equal(
      agg_r[[col]],
      agg_xlsx[[col]],
      tolerance = 1e-2,    # Excel rounds many cells to 2 decimals = $10M in $B
      info = paste("Column:", col)
    )
  }
})

test_that("compute_pareto_missing reproduces every derived column", {
  par_xlsx <- extract_pareto_missing()
  par_r <- compute_pareto_missing(par_xlsx)

  expect_equal(nrow(par_r), nrow(par_xlsx))
  for (col in names(par_xlsx)) {
    expect_equal(
      par_r[[col]],
      par_xlsx[[col]],
      tolerance = 1e-6,
      info = paste("Column:", col)
    )
  }
})

test_that("compute_data_sec_agg excludes Ellison from every year", {
  d_all <- extract_data_sec_all()
  # If we DON'T exclude Ellison, totals must diverge for years he was on the list
  agg_with_ell <- compute_data_sec_agg(d_all, exclude_ids = character(0))
  agg_no_ell   <- compute_data_sec_agg(d_all)
  expect_gt(
    agg_with_ell$forbes_worth[agg_with_ell$year == 2019],
    agg_no_ell$forbes_worth[agg_no_ell$year == 2019] + 60   # Ellison ~ $68B in 2019
  )
})
