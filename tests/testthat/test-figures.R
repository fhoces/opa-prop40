test_that("build_fig1 returns a ggplot with two line series + dashed counterfactual", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)

  p <- build_fig1(srs_r)
  expect_s3_class(p, "ggplot")
  # Data layer: two series × 7 years = 14 rows.
  expect_equal(nrow(p$data), 14)
  expect_setequal(unique(p$data$year), 2019:2025)
  expect_setequal(levels(p$data$series),
                  c("All CA billionaires", "Top 4 (Page, Brin, Zuck, Huang)"))
  # Headline values match shortrunseries (2025 totals)
  d25 <- p$data[p$data$year == 2025, ]
  expect_equal(d25$wealth[d25$series == "All CA billionaires"], 2051.66, tolerance = 1e-2)
  expect_equal(d25$wealth[d25$series == "Top 4 (Page, Brin, Zuck, Huang)"], 882.363, tolerance = 1e-2)
})

test_that("build_fig2 returns a patchwork object spanning 1982-2025", {
  lrs <- extract_longrunseries()
  p <- build_fig2(lrs)
  expect_s3_class(p, "patchwork")
  # First subplot's data: Panel A (44 rows: 1982-2025)
  pa <- p[[1]]
  expect_s3_class(pa, "ggplot")
  expect_equal(nrow(pa$data), 44)
  expect_equal(range(pa$data$year), c(1982, 2025))
  # Panel B should have 2 series x 44 yrs = 88 rows
  pb <- p[[2]]
  expect_equal(nrow(pb$data), 88)
  expect_setequal(levels(pb$data$region),
                  c("US (top 400)", "California (top 45)"))
  # Sanity checks on values: AZ 2025 ≈ 28.37, AW 2025 ≈ 0.298
  expect_equal(pa$data$wealth[pa$data$year == 2025], 28.365, tolerance = 1e-2)
  expect_equal(pb$data$share[pb$data$year == 2025 & pb$data$region == "California (top 45)"],
                0.2979, tolerance = 1e-3)
})

test_that("build_fig2 renders to a non-empty PNG", {
  p <- build_fig2(extract_longrunseries())
  tmpdir <- tempfile("fig2_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig2.png")
  ggplot2::ggsave(png_path, plot = p, width = 11, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig3 returns a 2-panel patchwork over 2019-2025", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  p <- build_fig3(srs_r)
  expect_s3_class(p, "patchwork")
  pa <- p[[1]]; pb <- p[[2]]
  expect_equal(nrow(pa$data), 14)   # 2 series × 7 yrs
  expect_equal(nrow(pb$data), 14)
  # Sanity: 2025 all-billionaires CA inctax ≈ 4.14 $B
  expect_equal(pa$data$value[pa$data$year == 2025 &
                              pa$data$series == "All CA billionaires"],
                4.14264, tolerance = 1e-3)
})

test_that("build_fig3 renders to a non-empty PNG", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  p <- build_fig3(srs_r)
  tmpdir <- tempfile("fig3_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig3.png")
  ggplot2::ggsave(png_path, plot = p, width = 11, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig4 returns a stacked area chart with 4 tax components", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  p <- build_fig4(b)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 28)   # 4 components × 7 yrs
  expect_setequal(levels(p$data$tax),
                  c("CA income tax", "Federal income tax",
                    "Corporate taxes", "Property + sales taxes"))
  # 2025 CA inctax/wealth ≈ 0.00202
  expect_equal(p$data$share[p$data$year == 2025 & p$data$tax == "CA income tax"],
                0.002019, tolerance = 1e-5)
})

test_that("build_fig4 renders to a non-empty PNG", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  p <- build_fig4(b)
  tmpdir <- tempfile("fig4_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig4.png")
  ggplot2::ggsave(png_path, plot = p, width = 7, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig5 returns stacked-bar data summing to Fig5 totals", {
  top4 <- extract_data_sec_top4()
  p <- build_fig5(top4)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 15)   # 3 bars × 5 components
  # Check each bar's total against Excel cached: Fiscal=18.44, Econ=142.9, Wealth=723.2
  totals <- aggregate(value ~ bar, data = p$data, sum)
  expect_equal(totals$value[totals$bar == "Fiscal Income"],   18.443, tolerance = 1e-2)
  expect_equal(totals$value[totals$bar == "Economic Income"], 142.9,  tolerance = 1e-1)
  # Wealth Gain bar adds 5% wealth tax to net + corp + CA + Fed:
  # Excel C5+C6 type structure: wealth_gain (723.2) + 5% tax (42.78) = 765.98
  expect_equal(totals$value[totals$bar == "Wealth Gain"],     765.98, tolerance = 1e-1)
})

test_that("build_fig5 renders to a non-empty PNG", {
  p <- build_fig5(extract_data_sec_top4())
  tmpdir <- tempfile("fig5_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig5.png")
  ggplot2::ggsave(png_path, plot = p, width = 7, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig6 returns 2-panel patchwork with 22-year top4taxes data", {
  t4t <- compute_top4taxes(extract_data_sec_top4())
  p <- build_fig6(t4t)
  expect_s3_class(p, "patchwork")
  pa <- p[[1]]; pb <- p[[2]]
  expect_equal(nrow(pa$data), 44)  # 2 series × 22 yrs
  expect_equal(nrow(pb$data), 44)
  # 2025: total_tax/wealth ≈ 0.0106, ca_inctax/wealth ≈ 0.000529
  expect_equal(pa$data$value[pa$data$year == 2025 &
                              pa$data$series == "Total taxes / wealth"],
                0.01060, tolerance = 1e-4)
})

test_that("build_fig6 renders to a non-empty PNG", {
  t4t <- compute_top4taxes(extract_data_sec_top4())
  p <- build_fig6(t4t)
  tmpdir <- tempfile("fig6_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig6.png")
  ggplot2::ggsave(png_path, plot = p, width = 11, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig7 returns 2-panel patchwork comparing top4 vs US/CA averages", {
  t4t <- compute_top4taxes(extract_data_sec_top4())
  dina <- extract_data_dina()
  p <- build_fig7(t4t, dina)
  expect_s3_class(p, "patchwork")
  pa <- p[[1]]; pb <- p[[2]]
  expect_equal(nrow(pa$data), 44)
  expect_setequal(levels(pa$data$series), c("Top 4 (CA billionaires)", "US average"))
  # 2025 DINA values: K=0.311, S=0.0496
  expect_equal(pa$data$value[pa$data$year == 2025 & pa$data$series == "US average"],
                0.311, tolerance = 1e-3)
  expect_equal(pb$data$value[pb$data$year == 2025 & pb$data$series == "CA average"],
                0.0496, tolerance = 1e-3)
})

test_that("build_fig7 renders to a non-empty PNG", {
  t4t <- compute_top4taxes(extract_data_sec_top4())
  dina <- extract_data_dina()
  p <- build_fig7(t4t, dina)
  tmpdir <- tempfile("fig7_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig7.png")
  ggplot2::ggsave(png_path, plot = p, width = 11, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig8 returns 3-series Laffer curve over 201 rates", {
  laffer <- compute_fig8_laffer()
  p <- build_fig8(laffer)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 603)   # 201 rates × 3 series
  expect_equal(range(p$data$rate), c(0, 0.20))
})

test_that("build_fig8 renders to a non-empty PNG", {
  p <- build_fig8(compute_fig8_laffer())
  tmpdir <- tempfile("fig8_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig8.png")
  ggplot2::ggsave(png_path, plot = p, width = 7, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig_a1 returns industry stacked bar with 3 components", {
  p <- build_fig_a1(xlsx_path_default())
  expect_s3_class(p, "ggplot")
  # 13 industries × 3 components = 39 rows (assuming all rows kept)
  expect_equal(nrow(p$data) %% 3, 0)
  expect_setequal(levels(p$data$component),
                  c("Public stock (Top 4)", "Public stock (other)",
                    "Private stock"))
  # Technology row's Top-4 share ≈ 0.417 (the dominant industry)
  tech_top4 <- p$data$share[p$data$industry == "Technology" &
                              p$data$component == "Public stock (Top 4)"]
  expect_equal(tech_top4, 0.417, tolerance = 1e-3)
})

test_that("build_fig_a1 renders to a non-empty PNG", {
  p <- build_fig_a1(xlsx_path_default())
  tmpdir <- tempfile("fig_a1_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig_a1.png")
  ggplot2::ggsave(png_path, plot = p, width = 8, height = 6, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})

test_that("build_fig1 renders to a non-empty PNG file", {
  agg <- compute_data_sec_agg(extract_data_sec_all())
  bci_x <- extract_billionaires_ca_inctax()
  ftb <- extract_ftb_b4a()
  b <- compute_billionaires_ca_inctax(agg, bci_x, ftb)
  top4 <- extract_data_sec_top4()
  srs_raw <- extract_shortrunseries()
  srs_r <- compute_shortrunseries(agg, top4, b, srs_raw)
  p <- build_fig1(srs_r)

  tmpdir <- tempfile("fig1_"); dir.create(tmpdir)
  png_path <- file.path(tmpdir, "fig1.png")
  ggplot2::ggsave(png_path, plot = p, width = 7, height = 5, dpi = 100)
  expect_true(file.exists(png_path))
  expect_gt(file.info(png_path)$size, 5000)
})
