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

test_that("compute_billionaires_ca_inctax matches Excel formula cells", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  out <- compute_billionaires_ca_inctax(agg, bci, ftb)

  # Helper: numeric coercion of positional dump cells in a given row range,
  # one panel column per element. Panel cols B..J = year 2018..2026.
  num_row <- function(row, cols) {
    unname(vapply(cols, function(L) suppressWarnings(as.numeric(bci[[L]][row])), numeric(1)))
  }
  pan_cols <- c("B", "C", "D", "E", "F", "G", "H", "I", "J")

  m1 <- out$method1
  # Block A (rows 9-10): wealth + avg wealth (years 2019..2025 only)
  expect_equal(m1$total_wealth_ca_b[2:8],            num_row(10, pan_cols[2:8]), tolerance = 1e-2)
  expect_equal(m1$avg_wealth_ca_b[2:8],              num_row(9,  pan_cols[2:8]), tolerance = 1e-3)

  # Block B (rows 13..18, 21): FTB aggregates
  expect_equal(m1$n_returns_ca[1:5],                 num_row(13, pan_cols[1:5]), tolerance = 1e-3)
  expect_equal(m1$ca_agi_b[1:6],                     num_row(14, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$ca_inctax_residents_b[1:8],        num_row(15, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(m1$ca_inctax_total_b[1:8],            num_row(18, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(m1$fy_to_cy_adjustment[1:8],          num_row(21, pan_cols[1:8]), tolerance = 1e-4)

  # Block C (rows 32..44): top-bracket Pareto projections
  expect_equal(m1$n_returns_5m[1:6],                 num_row(32, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$ca_agi_5m_b[1:6],                  num_row(33, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$ca_tax_5m_b[1:6],                  num_row(35, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$pareto_b_5m_bracket[1:6],          num_row(37, pan_cols[1:6]), tolerance = 1e-4)
  expect_equal(m1$proj_cutoff_top_5m_m[1:6],         num_row(41, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_agi_top_5m_b[1:6],            num_row(42, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_cutoff_top_pre_m[1:6],        num_row(38, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_agi_top_pre_b[1:6],           num_row(39, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_tax_top_pre_b[1:6],           num_row(40, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_agi_top_corr_b[1:6],          num_row(43, pan_cols[1:6]), tolerance = 1e-3)
  expect_equal(m1$proj_tax_top_corr_b[1:6],          num_row(44, pan_cols[1:6]), tolerance = 1e-3)

  # Final block (rows 49..55): headline outputs
  expect_equal(m1$ca_inctax_ca_billionaires_b[1:8],    num_row(49, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(m1$pct_ca_inctax_by_billionaires[1:8],  num_row(50, pan_cols[1:8]), tolerance = 1e-4)
  expect_equal(m1$ca_inctax_per_wealth[2:8],           num_row(51, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(m1$ca_inctax_public_assets_b[2:8],      num_row(53, pan_cols[2:8]), tolerance = 1e-2)
  expect_equal(m1$public_assets_share[2:8],            num_row(54, pan_cols[2:8]), tolerance = 1e-4)
  # Row 55 ratio uses data_sec_agg!S which Excel rounds to 2 decimals; use $-tier tolerance.
  expect_equal(m1$ca_inctax_public_share_of_total[2:8], num_row(55, pan_cols[2:8]), tolerance = 1e-2)

  # Memo 1 (rows 62, 64, 72): US top .001% Pareto calibration
  memo1 <- out$memo1
  m1_cols <- c("B","C","D","E","F")
  expect_equal(memo1$pareto_b_001,    num_row(62, m1_cols), tolerance = 1e-4)
  expect_equal(memo1$fed_tax_per_agi, num_row(64, m1_cols), tolerance = 1e-5)
  expect_equal(memo1$pct_overshoot,   num_row(72, m1_cols), tolerance = 1e-5)

  # Robustness scalars (D99, B100, B102..B105, C105)
  expect_equal(out$robustness$D99,  as.numeric(bci$D[99]),  tolerance = 1e-5)
  expect_equal(out$robustness$B100, as.numeric(bci$B[100]), tolerance = 1e-2)
  expect_equal(out$robustness$B102, as.numeric(bci$B[102]), tolerance = 1e-4)
  expect_equal(out$robustness$B103, as.numeric(bci$B[103]), tolerance = 1e-4)
  expect_equal(out$robustness$B104, as.numeric(bci$B[104]), tolerance = 1e-4)
  expect_equal(out$robustness$B105, as.numeric(bci$B[105]), tolerance = 1e-4)
  expect_equal(out$robustness$C105, as.numeric(bci$C[105]), tolerance = 1e-4)

  # All-taxes block (rows 111..148)
  at <- out$all_taxes
  expect_equal(at$ca_agi_ca_billionaires_b[1:8],     num_row(111, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(at$ca_inctax_ca_billionaires_b[1:8],  num_row(112, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(at$fed_inctax_ca_billionaires_b[1:8], num_row(113, pan_cols[1:8]), tolerance = 1e-3)
  expect_equal(at$fed_to_ca_inctax_ratio[1:8],       num_row(114, pan_cols[1:8]), tolerance = 1e-4)
  expect_equal(at$sales_gross_up_public[2:8],        num_row(116, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(at$public_wealth_b[2:8],              num_row(123, pan_cols[2:8]), tolerance = 1e-2)
  expect_equal(at$total_tax_per_public_wealth[2:8],  num_row(124, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(at$ca_inctax_per_public_wealth[2:8],  num_row(125, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(at$private_share[2:8],                num_row(137, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(at$passthrough_share[2:8],            num_row(138, pan_cols[2:8]), tolerance = 1e-5)
  expect_equal(at$corp_tax_private_c_b[2:8],         num_row(141, pan_cols[2:8]), tolerance = 1e-3)
  expect_equal(at$corp_tax_diversified_b[2:8],       num_row(142, pan_cols[2:8]), tolerance = 1e-3)
  # Row 143 chains data_sec_agg columns (rounded to 2dp in Excel) — use $-tier tolerance.
  expect_equal(at$property_tax_private_b[2:8],       num_row(143, pan_cols[2:8]), tolerance = 1e-2)
  expect_equal(at$total_corp_property_b[2:8],        num_row(144, pan_cols[2:8]), tolerance = 1e-3)
  expect_equal(at$total_sales_tax_b[2:8],            num_row(145, pan_cols[2:8]), tolerance = 1e-4)
  expect_equal(at$total_inctax_b[2:8],               num_row(146, pan_cols[2:8]), tolerance = 1e-3)
  expect_equal(at$total_taxes_b[2:8],                num_row(147, pan_cols[2:8]), tolerance = 1e-3)
  expect_equal(at$total_per_total_wealth[2:8],       num_row(148, pan_cols[2:8]), tolerance = 1e-5)
})
