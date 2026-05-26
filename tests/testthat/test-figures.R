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
