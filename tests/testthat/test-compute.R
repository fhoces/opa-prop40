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

test_that("compute_pareto_summary returns the I22-I24, J22-J23 derivatives", {
  par_r <- compute_pareto_missing(extract_pareto_missing())
  s <- compute_pareto_summary(par_r)
  expect_equal(s$total_wealth_emp,     2182.1,             tolerance = 1e-4)
  expect_equal(s$total_count_emp,      249,                tolerance = 1e-9)
  expect_equal(s$total_wealth_proj,    2797.2429706301136, tolerance = 1e-4)
  expect_equal(s$total_count_proj,     617.0811427959372,  tolerance = 1e-6)
  expect_equal(s$pct_wealth_increase,  0.2819041155905384, tolerance = 1e-8)
  expect_equal(s$pct_count_increase,   1.4782375212688241, tolerance = 1e-8)
  expect_equal(s$fraction_in_phasein,  0.12141926321056487, tolerance = 1e-8)
})

test_that("compute_tab5 matches the 4-scenario Excel Tab5 to 1e-3", {
  par_r <- compute_pareto_missing(extract_pareto_missing())
  t5_r  <- compute_tab5(par_r, extract_tab2(), extract_tab3())
  xl    <- read_sheet("Tab5", range = "B6:H9")  # cols B..H, scenarios 1..4

  expect_equal(nrow(t5_r), 4)
  expect_equal(t5_r$n_billionaires,        xl$A, tolerance = 1e-4)
  expect_equal(t5_r$wealth,                xl$B, tolerance = 1e-4)
  expect_equal(t5_r$taxable_wealth,        xl$C, tolerance = 1e-4)
  expect_equal(t5_r$avoidance_rate,        xl$D, tolerance = 1e-6)
  expect_equal(t5_r$wealth_tax_revenue,    xl$E, tolerance = 1e-4)
  expect_equal(t5_r$extra_ca_inctax_sales, xl$F, tolerance = 1e-4)
  expect_equal(t5_r$annual_ca_inctax_loss, xl$G, tolerance = 1e-4)
})

test_that("compute_fig8_laffer matches Excel Fig8 columns A-E across all rates", {
  laffer <- compute_fig8_laffer()
  xl <- read_sheet("Fig8", range = "A11:E211")  # 201 rows of computed Laffer values

  expect_equal(nrow(laffer), 201)
  expect_equal(laffer$tax_rate,               xl$A, tolerance = 1e-9)
  expect_equal(laffer$mechanical_tax_revenue, xl$B, tolerance = 1e-6)
  expect_equal(laffer$wealth_tax_base,        xl$C, tolerance = 1e-6)
  expect_equal(laffer$actual_tax_revenue,     xl$D, tolerance = 1e-6)
  expect_equal(laffer$long_run_tax_revenue,   xl$E, tolerance = 1e-6)
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
