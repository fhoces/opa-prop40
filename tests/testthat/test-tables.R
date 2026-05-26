test_that("build_tab1 panel A reproduces Tab1 sheet 2022-2025 + growth row", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  lrs <- extract_longrunseries()
  tab1 <- build_tab1(agg, srs_r, lrs)

  pa <- attr(tab1, "panel_a")
  # Pull the Tab1 sheet's panel A cells (rows 6..10, cols B..H)
  xl <- read_sheet("Tab1", range = "B6:H10")

  expect_equal(pa$n_billionaires[1:4],   xl$A[1:4], tolerance = 1e-6)
  expect_equal(pa$wealth_b[1:4],         xl$B[1:4], tolerance = 1e-2)
  expect_equal(pa$annual_growth[2:4],    xl$C[2:4], tolerance = 1e-4)
  expect_equal(pa$fraction_public[1:4],  xl$D[1:4], tolerance = 1e-4)
  expect_equal(pa$top4_wealth_b[1:4],    xl$E[1:4], tolerance = 1e-2)
  expect_equal(pa$ca_gdp_b[1:4],         xl$F[1:4], tolerance = 1e-2)
  expect_equal(pa$wealth_per_gdp[1:4],   xl$G[1:4], tolerance = 1e-4)
  # Growth row (row 10 of Tab1 sheet) — B, E, F columns only
  expect_equal(pa$wealth_b[5],           xl$B[5], tolerance = 1e-4)
  expect_equal(pa$top4_wealth_b[5],      xl$E[5], tolerance = 1e-4)
  expect_equal(pa$ca_gdp_b[5],           xl$F[5], tolerance = 1e-4)
})

test_that("build_tab1 panel B reproduces Tab1 sheet 1982 + 2025 + ratios + annualized", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  lrs <- extract_longrunseries()
  tab1 <- build_tab1(agg, srs_r, lrs)

  pb <- attr(tab1, "panel_b")
  # Tab1 panel B is at rows 14..17, cols C..H
  xl <- read_sheet("Tab1", range = "C14:H17")
  expect_equal(pb$families_top0002_k,   xl$A, tolerance = 1e-3)
  expect_equal(pb$wealth_top0002_b,     xl$B, tolerance = 1e-2)
  expect_equal(pb$wealth_per_family_b,  xl$C, tolerance = 1e-3)
  expect_equal(pb$n_ca_families_m,      xl$D, tolerance = 1e-3)
  expect_equal(pb$ca_gdp_2025dollars_b, xl$E, tolerance = 1e-1)
  expect_equal(pb$gdp_per_family_k,     xl$F, tolerance = 1)
})

test_that("build_tab2 reproduces Tab2 sheet 2019-2025 + average row", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  tab2 <- build_tab2(agg, b, top4)
  p <- attr(tab2, "panel")
  xl <- read_sheet("Tab2", range = "B7:H14")  # cols B..H, rows 7..14

  expect_equal(p$wealth_b,                  xl$A, tolerance = 1e-2)
  expect_equal(p$ca_inctax_b,               xl$B, tolerance = 1e-3)
  expect_equal(p$ca_inctax_per_wealth,      xl$C, tolerance = 1e-5)
  expect_equal(p$top4_company_wealth_b,     xl$E, tolerance = 1e-2)
  expect_equal(p$top4_ca_inctax_b,          xl$F, tolerance = 1e-3)
  expect_equal(p$top4_ca_inctax_per_wealth, xl$G, tolerance = 1e-5)
})

test_that("build_tab2 renders to non-empty HTML and LaTeX", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  tab2 <- build_tab2(agg, b, top4)
  html <- as.character(gt::as_raw_html(tab2))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("Income Tax Paid by California Billionaires", html))
  tex <- as.character(gt::as_latex(tab2))
  expect_gt(nchar(tex), 200)
})

test_that("build_tab3 reproduces Tab3 sheet per-billionaire CA income tax + wealth", {
  top4 <- extract_data_sec_top4()
  tab3 <- build_tab3(top4)
  p <- attr(tab3, "panel")
  xl <- read_sheet("Tab3", range = "B6:F16")  # cols B..F (page,brin,zuck,huang,top4)

  # Rows 1..7 = yearly tax; 8 = average; 9 = begin wealth; 10 = end wealth; 11 = ratio
  expect_equal(p$page[1:7],       xl$A[1:7],  tolerance = 1e-3)
  expect_equal(p$brin[1:7],       xl$B[1:7],  tolerance = 1e-3)
  expect_equal(p$zuckerberg[1:7], xl$C[1:7],  tolerance = 1e-3)
  expect_equal(p$huang[1:7],      xl$D[1:7],  tolerance = 1e-3)
  expect_equal(p$all_top4[1:7],   xl$E[1:7],  tolerance = 1e-3)
  # Average row
  expect_equal(p$page[8],       xl$A[8],  tolerance = 1e-3)
  expect_equal(p$brin[8],       xl$B[8],  tolerance = 1e-3)
  expect_equal(p$zuckerberg[8], xl$C[8],  tolerance = 1e-3)
  expect_equal(p$huang[8],      xl$D[8],  tolerance = 1e-3)
  expect_equal(p$all_top4[8],   xl$E[8],  tolerance = 1e-3)
  # Wealth rows
  expect_equal(p$page[9:10],       xl$A[9:10],  tolerance = 1)
  expect_equal(p$brin[9:10],       xl$B[9:10],  tolerance = 1)
  expect_equal(p$zuckerberg[9:10], xl$C[9:10],  tolerance = 1)
  expect_equal(p$huang[9:10],      xl$D[9:10],  tolerance = 1)
  expect_equal(p$all_top4[9:10],   xl$E[9:10],  tolerance = 1)
  # Ratio row
  expect_equal(p$page[11],       xl$A[11],  tolerance = 1e-5)
  expect_equal(p$brin[11],       xl$B[11],  tolerance = 1e-5)
  expect_equal(p$zuckerberg[11], xl$C[11],  tolerance = 1e-5)
  expect_equal(p$huang[11],      xl$D[11],  tolerance = 1e-5)
  expect_equal(p$all_top4[11],   xl$E[11],  tolerance = 1e-5)
})

test_that("build_tab3 renders to non-empty HTML and LaTeX", {
  tab3 <- build_tab3(extract_data_sec_top4())
  html <- as.character(gt::as_raw_html(tab3))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("Top 4 on Company Wealth", html))
  tex <- as.character(gt::as_latex(tab3))
  expect_gt(nchar(tex), 200)
})

test_that("build_tab4 reproduces Tab4 sheet Total + Annual-average columns", {
  top4 <- extract_data_sec_top4()
  tab4 <- build_tab4(top4)
  p <- attr(tab4, "panel")
  xl <- read_sheet("Tab4", range = "D6:F23")  # cols D and F (skip blank E)

  # Map sheet rows 6..23 to panel rows; sheet has blank rows 10, 20.
  # panel rows: 1..4 = wealth (sheet 6..9), 5..10 = income items (sheet 11..16),
  # 11..13 = inctax + ratio (sheet 17..19), 14..16 = corporate (sheet 21..23)
  sheet_to_panel <- c(`6`=1,  `7`=2,  `8`=3,  `9`=4,
                      `11`=5, `12`=6, `13`=7, `14`=8, `15`=9, `16`=10,
                      `17`=11,`18`=12,`19`=13,
                      `21`=14,`22`=15,`23`=16)
  for (sheet_row in names(sheet_to_panel)) {
    pi <- sheet_to_panel[[sheet_row]]
    xl_i <- as.integer(sheet_row) - 5L
    if (!is.na(xl$A[xl_i])) {
      expect_equal(p$total[pi], xl$A[xl_i], tolerance = 1e-3,
                   info = paste("metric:", p$metric[pi]))
    }
    if (!is.na(xl$C[xl_i])) {
      expect_equal(p$annual_avg[pi], xl$C[xl_i], tolerance = 1e-3,
                   info = paste("metric:", p$metric[pi], "avg"))
    }
  }
})

test_that("build_tab4 renders to non-empty HTML and LaTeX", {
  tab4 <- build_tab4(extract_data_sec_top4())
  html <- as.character(gt::as_raw_html(tab4))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("Wealth, Income, and Taxes of the Top 4", html))
  tex <- as.character(gt::as_latex(tab4))
  expect_gt(nchar(tex), 200)
})

test_that("build_tab5 reproduces Tab5 sheet (uses tab5_r already verified)", {
  par_r <- compute_pareto_missing(extract_pareto_missing())
  t5_r  <- compute_tab5(par_r, extract_tab2(), extract_tab3())
  tab5 <- build_tab5(t5_r)
  p <- attr(tab5, "panel")
  xl <- read_sheet("Tab5", range = "B6:H9")

  expect_equal(p$n_billionaires,        xl$A, tolerance = 1e-4)
  expect_equal(p$wealth,                xl$B, tolerance = 1e-4)
  expect_equal(p$taxable_wealth,        xl$C, tolerance = 1e-4)
  expect_equal(p$avoidance_rate,        xl$D, tolerance = 1e-6)
  expect_equal(p$wealth_tax_revenue,    xl$E, tolerance = 1e-4)
  expect_equal(p$extra_ca_inctax_sales, xl$F, tolerance = 1e-4)
  expect_equal(p$annual_ca_inctax_loss, xl$G, tolerance = 1e-4)
})

test_that("build_tab5 renders to non-empty HTML and LaTeX", {
  par_r <- compute_pareto_missing(extract_pareto_missing())
  t5_r  <- compute_tab5(par_r, extract_tab2(), extract_tab3())
  tab5  <- build_tab5(t5_r)
  html <- as.character(gt::as_raw_html(tab5))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("One-Time 5% California Wealth Tax", html))
  tex <- as.character(gt::as_latex(tab5))
  expect_gt(nchar(tex), 200)
})

test_that("build_tab_a1 panel A reproduces TabA1 sheet 2022-2025 + growth row", {
  srs <- extract_shortrunseries()
  lrs <- extract_longrunseries()
  ta1 <- build_tab_a1(srs, lrs)
  pa <- attr(ta1, "panel_a")
  xl <- read_sheet("TabA1", range = "B6:D10")

  expect_equal(pa$n_us_billionaires[1:4], xl$A[1:4], tolerance = 1e-6)
  expect_equal(pa$wealth_b[1:4],          xl$B[1:4], tolerance = 1e-2)
  expect_equal(pa$annual_growth[2:4],     xl$C[2:4], tolerance = 1e-4)
  expect_equal(pa$wealth_b[5],            xl$B[5],   tolerance = 1e-4)
})

test_that("build_tab_a1 panel B reproduces TabA1 sheet 1982 vs 2025", {
  srs <- extract_shortrunseries()
  lrs <- extract_longrunseries()
  ta1 <- build_tab_a1(srs, lrs)
  pb <- attr(ta1, "panel_b")
  xl <- read_sheet("TabA1", range = "B14:G17")
  expect_equal(pb$families_top0002_k,   xl$A, tolerance = 1e-2)
  expect_equal(pb$wealth_top0002_b,     xl$B, tolerance = 1e-1)
  expect_equal(pb$wealth_per_family_b,  xl$C, tolerance = 1e-3)
  expect_equal(pb$n_us_families_m,      xl$D, tolerance = 1e-3)
  expect_equal(pb$us_gdp_2025dollars_b, xl$E, tolerance = 1)
  expect_equal(pb$gdp_per_family_k,     xl$F, tolerance = 1)
})

test_that("build_tab_a1 renders to non-empty HTML and LaTeX", {
  srs <- extract_shortrunseries()
  lrs <- extract_longrunseries()
  ta1 <- build_tab_a1(srs, lrs)
  html <- as.character(gt::as_raw_html(ta1))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("Wealth Growth of US Billionaires", html))
  tex <- as.character(gt::as_latex(ta1))
  expect_gt(nchar(tex), 200)
})

test_that("build_tab1 renders to non-empty HTML and LaTeX", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  lrs <- extract_longrunseries()
  tab1 <- build_tab1(agg, srs_r, lrs)

  html <- as.character(gt::as_raw_html(tab1))
  expect_gt(nchar(html), 1000)
  expect_true(grepl("Wealth Growth of California Billionaires", html))
  expect_true(grepl("Recent nominal wealth growth", html))
  expect_true(grepl("Long-term real wealth growth", html))

  tex <- as.character(gt::as_latex(tab1))
  expect_gt(nchar(tex), 200)
  expect_true(grepl("\\\\begin\\{longtable\\}|\\\\begin\\{tabular\\}", tex))
})
