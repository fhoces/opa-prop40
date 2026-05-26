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
