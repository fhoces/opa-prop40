test_that("extract_data_sec_codebook returns the 38 documented variables", {
  cb <- extract_data_sec_codebook()
  expect_equal(nrow(cb), 38)
  expect_equal(names(cb), c("variable", "definition", "data_source"))
  expect_equal(cb$variable[1:3], c("year", "forbes_id", "forbes_worth"))
  expect_true(is.na(cb$data_source[1]))            # original "\" sentinel
  expect_equal(cb$data_source[2], "Forbes RTB")
})

test_that("extract_data_sec_top4 anchors at jensen-huang 2016", {
  t4 <- extract_data_sec_top4()
  expect_equal(nrow(t4), 116)
  expect_equal(ncol(t4), 36)
  expect_equal(names(t4)[1:4], c("year", "forbes_id", "forbes_worth", "public_worth"))
  row1 <- t4[1, ]
  expect_equal(row1$year, 2016L)
  expect_equal(row1$forbes_id, "jensen-huang")
  expect_equal(row1$forbes_worth, 1700)
  expect_equal(row1$public_worth, 2296.88, tolerance = 1e-4)
  expect_s3_class(t4$end_cyear, "Date")
})

test_that("extract_data_sec_all covers all CA billionaires 2019-2025", {
  d <- extract_data_sec_all()
  expect_equal(ncol(d), 31)
  expect_gt(nrow(d), 1000)
  expect_setequal(unique(d$year), 2019:2025)
  zuck_2019 <- d[d$year == 2019 & d$forbes_id == "mark-zuckerberg", ]
  expect_equal(zuck_2019$forbes_worth, 82173.426, tolerance = 1e-4)
})

test_that("extract_data_sec_agg covers years 2019-2025 with no summary rows", {
  agg <- extract_data_sec_agg()
  expect_equal(nrow(agg), 7)
  expect_equal(ncol(agg), 35)
  expect_equal(agg$year, 2019:2025)
  expect_equal(agg$n[agg$year == 2019], 168)
  # 2025 forbes_worth moved 2051.66 -> 2054.82 between vintages (a legitimate
  # input update; RC9b).
  expect_equal(
    agg$forbes_worth[agg$year == 2025],
    if (identical(bsz_vintage(), "may")) 2051.66 else 2054.82,
    tolerance = 1e-4
  )
})

test_that("extract_rtb_2026_industry returns the first industry block", {
  rtb <- extract_rtb_2026_industry()
  # August added a 15th industry row ("Service") before "Total" (RC9a).
  expect_equal(nrow(rtb), if (identical(bsz_vintage(), "may")) 14 else 15)
  expect_equal(ncol(rtb), 8)
  expect_equal(rtb$industries[1], "Technology")
  expect_equal(rtb$industries[nrow(rtb)], "Total")
  expect_equal(
    rtb$n_billionaires[rtb$industries == "Total"],
    if (identical(bsz_vintage(), "may")) 239 else 240
  )
})

test_that("extract_pareto_missing returns the main Pareto table", {
  par <- extract_pareto_missing()
  expect_equal(nrow(par), 17)
  expect_equal(ncol(par), 12)
  expect_equal(par$threshold_b[1], 1)
  expect_equal(par$threshold_b[nrow(par)], 30)
  expect_equal(par$n_above_threshold_emp[par$threshold_b == 1], 249)
})

test_that("extract_longrunseries returns the raw wide series", {
  lr <- extract_longrunseries()
  expect_s3_class(lr, "tbl_df")
  expect_gt(ncol(lr), 60)  # 67 named cols + buffer
  # 1980 row sits at row 6 (after Back-to-index, title, note, blank, headers)
  expect_equal(as.numeric(lr[[6, "A"]]), 1980)
  expect_equal(as.numeric(lr[[6, "B"]]), 3.012858, tolerance = 1e-4)
})

test_that("extract_shortrunseries returns the raw wide series", {
  sr <- extract_shortrunseries()
  expect_s3_class(sr, "tbl_df")
  # 2018 sits at row 6 in both vintages. The "top4/5 total Forbes wealth"
  # column moved E (May) -> K (August) along with the rest of the sheet's
  # reshuffle (RC1 / RC9d); the 2018 value itself is historical and
  # unchanged between vintages.
  expect_equal(as.numeric(sr[[6, "A"]]), 2018)
  expect_equal(as.numeric(sr[[6, srs_col("top5_total")]]), 173.8, tolerance = 1e-4)
})

test_that("positional dumps round-trip through expect_matches_excel", {
  expect_success(expect_matches_excel(extract_longrunseries(), "longrunseries"))
  expect_success(expect_matches_excel(extract_shortrunseries(), "shortrunseries"))
  expect_success(expect_matches_excel(extract_data_dina(), "data_dina"))
  expect_success(expect_matches_excel(extract_data_sec_propublica(), "data_sec_propublica"))
  expect_success(expect_matches_excel(extract_billionaires_ca_inctax(), "billionairesCAinctax"))
  expect_success(expect_matches_excel(extract_ftb_b4a(), "2023-b-4a__adjusted_gross_incom"))
})
