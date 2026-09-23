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
  # one panel column per element. Panel cols B..J = year 2018..2026. `row` is
  # always the MAY-numbered row; bci_row() resolves it to the right physical
  # row for whichever vintage is active (August inserted 2 rows in this
  # sheet - see R/vintage.R).
  num_row <- function(row, cols) {
    row <- bci_row(row)
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
  expect_equal(out$robustness$D99,  as.numeric(bci$D[bci_row(99)]),  tolerance = 1e-5)
  expect_equal(out$robustness$B100, as.numeric(bci$B[bci_row(100)]), tolerance = 1e-2)
  expect_equal(out$robustness$B102, as.numeric(bci$B[bci_row(102)]), tolerance = 1e-4)
  expect_equal(out$robustness$B103, as.numeric(bci$B[bci_row(103)]), tolerance = 1e-4)
  expect_equal(out$robustness$B104, as.numeric(bci$B[bci_row(104)]), tolerance = 1e-4)
  expect_equal(out$robustness$B105, as.numeric(bci$B[bci_row(105)]), tolerance = 1e-4)
  expect_equal(out$robustness$C105, as.numeric(bci$C[bci_row(105)]), tolerance = 1e-4)

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
  # Row 148 is total_taxes_b/total_w_ca; under August it chains through the
  # new passthrough-property term (also data_sec_agg-derived, 2dp-rounded in
  # Excel) on top of the pre-existing row-143 rounding - use $-tier tolerance
  # (same reasoning as row 143 above; 1e-5 is too tight by ~1e-5 under August).
  expect_equal(at$total_per_total_wealth[2:8],       num_row(148, pan_cols[2:8]), tolerance = 1e-4)
})

test_that("compute_shortrunseries matches Excel formula cells", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs <- extract_shortrunseries()
  out <- compute_shortrunseries(agg, top4, b, srs)

  # Helper: numeric coercion of positional dump cells. Panel rows 6..13 = years 2018..2025
  # (unchanged in both vintages - only the COLUMN letters differ; `L` is
  # always a MAY-numbered concept name resolved via srs_col()).
  num_col <- function(concept, rows) {
    L <- srs_col(concept)
    unname(vapply(rows, function(r) suppressWarnings(as.numeric(srs[[L]][r])), numeric(1)))
  }
  # A handful of columns are unchanged position in both vintages (C, D) and
  # are read directly rather than through srs_col().
  num_col_lit <- function(L, rows) {
    unname(vapply(rows, function(r) suppressWarnings(as.numeric(srs[[L]][r])), numeric(1)))
  }
  rows_panel <- 6:13   # year 2018..2025

  panel <- out$panel
  # Column C (forbes_worth), rows 7..13 (years 2019..2025)
  expect_equal(panel$wealth_us_citizens_b[2:8], num_col_lit("C", 7:13), tolerance = 1e-2)
  expect_equal(panel$top5_total_b,              num_col("top5_total", rows_panel), tolerance = 1e-2)
  expect_equal(panel$top5_company_wealth_b,     num_col("top5_company", rows_panel), tolerance = 1e-2)
  expect_equal(panel$share_public,              num_col("share_public", rows_panel), tolerance = 1e-4)
  expect_equal(panel$n_ca_billionaires[2:8],    num_col("n_ca", 7:13),       tolerance = 1e-6)
  expect_equal(panel$share_ellison[2:8],        num_col("share_ellison", 7:13),       tolerance = 1e-4)
  expect_equal(panel$yoy_growth_wealth[3:8],    num_col("yoy_growth", 8:13),       tolerance = 1e-4)
  expect_equal(panel$cum_growth_from_2019[2:8], num_col("cum2019", 7:13),       tolerance = 1e-4)
  expect_equal(panel$cum_growth_from_2022[5:8], num_col("cum2022", 10:13),      tolerance = 1e-4)
  expect_equal(panel$cum_growth_from_2023[6:8], num_col("cum2023", 11:13),      tolerance = 1e-4)
  expect_equal(panel$top5_yoy_growth[3:8],      num_col("top5_yoy", 8:13),       tolerance = 1e-4)
  expect_equal(panel$top5_cum_growth_from_2019, num_col("top5_cum2019", rows_panel), tolerance = 1e-4)
  expect_equal(panel$top5_cum_growth_from_2022[5:8], num_col("top5_cum2022", 10:13), tolerance = 1e-4)
  expect_equal(panel$share_ca_in_top5_b[2:8],   num_col("V_share", 7:13),       tolerance = 1e-4)
  expect_equal(panel$ca_inctax_billionaires_b[2:8], num_col("ca_inctax", 7:13),   tolerance = 1e-3)
  expect_equal(panel$ca_inctax_per_wealth[2:8],     num_col("ca_inctax_per_wealth", 7:13),   tolerance = 1e-5)
  expect_equal(panel$ca_inctax_total_b[2:8],        num_col("ca_inctax_total", 7:13),   tolerance = 1e-2)
  expect_equal(panel$ca_inctax_share_total[2:8],    num_col("ca_inctax_share", 7:13),  tolerance = 1e-4)
  expect_equal(panel$top5_sec_tax_rate[2:8],        num_col("top5_sec_rate", 7:13),  tolerance = 1e-4)
  expect_equal(panel$top5_sec_ca_inctax_b[2:8],     num_col("top5_sec_inctax", 7:13),  tolerance = 1e-4)
  expect_equal(panel$top5_sec_share_of_total[2:8],  num_col("top5_sec_share", 7:13),  tolerance = 1e-4)
  expect_equal(panel$top3_ca_inctax_sum_b[2:8],     num_col("top3_sum", 7:13),  tolerance = 1e-4)
  expect_equal(panel$top2_ca_inctax_sum_b[2:8],     num_col("top2_sum", 7:13),  tolerance = 1e-4)
  expect_equal(panel$brin_ca_inctax_b[2:8],         num_col("brin", 7:13),  tolerance = 1e-4)
  expect_equal(panel$page_ca_inctax_b[2:8],         num_col("page", 7:13),  tolerance = 1e-4)
  expect_equal(panel$zuck_ca_inctax_b[2:8],         num_col("zuck", 7:13),  tolerance = 1e-4)
  expect_equal(panel$ellison_ca_inctax_b[2:8],      num_col("ellison", 7:13),  tolerance = 1e-4)
  expect_equal(panel$huang_ca_inctax_b[2:8],        num_col("huang", 7:13),  tolerance = 1e-4)
  # D and F columns only filled rows 12-13 (2024, 2025)
  expect_equal(panel$wealth_w_avoid_b[7:8],  num_col_lit("D", 12:13), tolerance = 1e-2)
  expect_equal(panel$top5_w_avoid_b[7:8],    num_col("top5_wavoid", 12:13), tolerance = 1e-2)

  # Summary block. May: rows 14/15/16/17/18. August: shifted +2 (a numeric
  # 2026 row plus a blank spacer were inserted between the year panel and
  # this block) - see srs_summary_row() / R/vintage.R.
  r14 <- srs_summary_row(14); r15 <- srs_summary_row(15)
  r16 <- srs_summary_row(16); r17 <- srs_summary_row(17); r18 <- srs_summary_row(18)

  # Row 14 "2026 (feb 1)" snapshot
  s <- out$summary_2025
  expect_equal(unname(s$top5_public_b["brin"]),   as.numeric(srs[[srs_col("brin")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["page"]),   as.numeric(srs[[srs_col("page")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["zuck"]),   as.numeric(srs[[srs_col("zuck")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["ellison"]),as.numeric(srs[[srs_col("ellison")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["huang"]),  as.numeric(srs[[srs_col("huang")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["top3"]),   as.numeric(srs[[srs_col("top3_sum")]][r14]), tolerance = 1e-2)
  expect_equal(unname(s$top5_public_b["top2"]),   as.numeric(srs[[srs_col("top2_sum")]][r14]), tolerance = 1e-2)
  # Row 17 = total wealth incl private end of 2025
  expect_equal(unname(s$top5_total_b["brin"]),    as.numeric(srs[[srs_col("brin")]][r17]), tolerance = 1e-2)
  expect_equal(unname(s$top5_total_b["page"]),    as.numeric(srs[[srs_col("page")]][r17]), tolerance = 1e-2)
  expect_equal(unname(s$top5_total_b["zuck"]),    as.numeric(srs[[srs_col("zuck")]][r17]), tolerance = 1e-2)
  expect_equal(unname(s$top5_total_b["top3"]),    as.numeric(srs[[srs_col("top3_sum")]][r17]), tolerance = 1e-2)
  # Row 18 = public share by group
  expect_equal(unname(s$public_share["top3"]),    as.numeric(srs[[srs_col("top3_sum")]][r18]), tolerance = 1e-4)
  expect_equal(unname(s$public_share["brin"]),    as.numeric(srs[[srs_col("brin")]][r18]), tolerance = 1e-4)
  expect_equal(unname(s$public_share["page"]),    as.numeric(srs[[srs_col("page")]][r18]), tolerance = 1e-4)

  # Row 15 averages
  avg <- s$avg_2019_2025
  expect_equal(avg$X,  as.numeric(srs[[srs_col("ca_inctax")]][r15]),  tolerance = 1e-4)
  expect_equal(avg$Y,  as.numeric(srs[[srs_col("ca_inctax_per_wealth")]][r15]),  tolerance = 1e-6)
  expect_equal(avg$AA, as.numeric(srs[[srs_col("ca_inctax_share")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AD, as.numeric(srs[[srs_col("top5_sec_rate")]][r15]), tolerance = 1e-6)
  expect_equal(avg$AE, as.numeric(srs[[srs_col("top5_sec_inctax")]][r15]), tolerance = 1e-4)
  expect_equal(avg$AF, as.numeric(srs[[srs_col("top5_sec_share")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AG, as.numeric(srs[[srs_col("top3_sum")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AH, as.numeric(srs[[srs_col("top2_sum")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AJ, as.numeric(srs[[srs_col("brin")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AK, as.numeric(srs[[srs_col("page")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AL, as.numeric(srs[[srs_col("zuck")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AM, as.numeric(srs[[srs_col("ellison")]][r15]), tolerance = 1e-5)
  expect_equal(avg$AN, as.numeric(srs[[srs_col("huang")]][r15]), tolerance = 1e-5)

  # Row 16 (per-2025-wealth ratios) — uses /row14 etc. (small denominators -> tolerance loose)
  ratios <- s$avg_share_2025_wealth
  expect_equal(unname(ratios["top3"]), as.numeric(srs[[srs_col("top3_sum")]][r16]), tolerance = 1e-5)
  expect_equal(unname(ratios["brin"]), as.numeric(srs[[srs_col("brin")]][r16]), tolerance = 1e-5)
  expect_equal(unname(ratios["page"]), as.numeric(srs[[srs_col("page")]][r16]), tolerance = 1e-5)

  # Growth-summary block. May: rows 16..21. August: shifted +2 (same reason
  # as the summary block above) - see srs_growth_row().
  growth <- out$growth
  growth_rows <- vapply(16:21, srs_growth_row, integer(1))
  # This mini-table's own "total growth" column is literal "C" in BOTH
  # vintages (Excel just extends column C - the same one panel rows 6:13 use
  # for wealth - downward into this separate bottom table; confirmed against
  # both workbooks directly). The "annualized growth" column reuses the
  # panel's yoy_growth column ("M" May / "T" August) the same way.
  expect_equal(growth$total_growth_us_only, num_col_lit("C", growth_rows), tolerance = 1e-3)
  expect_equal(growth$annualized_us_only,   num_col("yoy_growth", growth_rows), tolerance = 1e-4)
  if (identical(bsz_vintage(), "may")) {
    # August dropped the separate "CA wealth, US citizens only" column that
    # the "incl_nonus" growth series was based on (see
    # compute_shortrunseries.R); under August this series is identical to
    # total_growth_us_only (both alias the same C_wealth total), and Excel's
    # own August sheet has no separate cached cell for it to compare
    # against (only the "us only" growth column survives).
    expect_equal(growth$total_growth_incl_nonus, num_col_lit("B", growth_rows), tolerance = 1e-3)
  } else {
    expect_equal(growth$total_growth_incl_nonus, growth$total_growth_us_only, tolerance = 1e-12)
  }
})

test_that("compute_top4taxes matches Excel formula cells", {
  top4 <- extract_data_sec_top4()
  out <- compute_top4taxes(top4)
  t4x <- read_sheet("top4taxes")
  num_col <- function(L, rows) {
    unname(vapply(rows, function(r) suppressWarnings(as.numeric(t4x[[L]][r])), numeric(1)))
  }
  panel_rows <- 5:26  # years 2004..2025

  panel <- out$panel
  expect_equal(panel$total_tax_per_income,    num_col("C", panel_rows), tolerance = 1e-4)
  expect_equal(panel$ca_inctax_per_income,    num_col("D", panel_rows), tolerance = 1e-4)
  expect_equal(panel$fed_inctax_per_income,   num_col("E", panel_rows), tolerance = 1e-4)
  expect_equal(panel$sales_tax_per_income,    num_col("F", panel_rows), tolerance = 1e-5)
  expect_equal(panel$corp_tax_per_income,     num_col("G", panel_rows), tolerance = 1e-4)
  expect_equal(panel$property_tax_per_income, num_col("H", panel_rows), tolerance = 1e-5)
  expect_equal(panel$check_income_decomp,     num_col("I", panel_rows), tolerance = 1e-6)
  expect_equal(panel$total_tax_per_wealth,    num_col("J", panel_rows), tolerance = 1e-4)
  expect_equal(panel$ca_inctax_per_wealth,    num_col("K", panel_rows), tolerance = 1e-5)
  expect_equal(panel$fed_inctax_per_wealth,   num_col("L", panel_rows), tolerance = 1e-5)
  expect_equal(panel$sales_tax_per_wealth,    num_col("M", panel_rows), tolerance = 1e-6)
  expect_equal(panel$corp_tax_per_wealth,     num_col("N", panel_rows), tolerance = 1e-4)
  expect_equal(panel$property_tax_per_wealth, num_col("O", panel_rows), tolerance = 1e-6)
  expect_equal(panel$check_wealth_decomp,     num_col("P", panel_rows), tolerance = 1e-7)
  expect_equal(panel$income_per_wealth,       num_col("R", panel_rows), tolerance = 1e-4)
  expect_equal(panel$avg_wealth_m,            num_col("S", panel_rows), tolerance = 1e-2)
  expect_equal(panel$economic_income_m,       num_col("T", panel_rows), tolerance = 1e-3)

  # Sub-period averages (rows 27, 28)
  avg <- out$averages
  expect_equal(avg$total_tax_per_income,    num_col("C", 27:28), tolerance = 1e-5)
  expect_equal(avg$ca_inctax_per_income,    num_col("D", 27:28), tolerance = 1e-5)
  expect_equal(avg$fed_inctax_per_income,   num_col("E", 27:28), tolerance = 1e-5)
  expect_equal(avg$sales_tax_per_income,    num_col("F", 27:28), tolerance = 1e-6)
  expect_equal(avg$corp_tax_per_income,     num_col("G", 27:28), tolerance = 1e-5)
  expect_equal(avg$property_tax_per_income, num_col("H", 27:28), tolerance = 1e-6)
  expect_equal(avg$check_income_decomp,     num_col("I", 27:28), tolerance = 1e-7)
  expect_equal(avg$total_tax_per_wealth,    num_col("J", 27:28), tolerance = 1e-5)
  expect_equal(avg$ca_inctax_per_wealth,    num_col("K", 27:28), tolerance = 1e-6)
  expect_equal(avg$fed_inctax_per_wealth,   num_col("L", 27:28), tolerance = 1e-6)
  expect_equal(avg$sales_tax_per_wealth,    num_col("M", 27:28), tolerance = 1e-7)
  expect_equal(avg$corp_tax_per_wealth,     num_col("N", 27:28), tolerance = 1e-5)
  expect_equal(avg$property_tax_per_wealth, num_col("O", 27:28), tolerance = 1e-6)
  expect_equal(avg$check_wealth_decomp,     num_col("P", 27:28), tolerance = 1e-7)
  expect_equal(avg$income_per_wealth,       num_col("R", 27:28), tolerance = 1e-5)
  expect_equal(avg$avg_wealth_m,            num_col("S", 27:28), tolerance = 1)
  expect_equal(avg$economic_income_m,       num_col("T", 27:28), tolerance = 1e-1)
})
