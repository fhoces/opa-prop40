test_that("Table 9 matches the paper's printed NPV cells (p.19)", {
  t9 <- compute_npv_table9()
  printed <- tibble::tribble(
    ~scenario, ~r, ~npv,
    "six_confirmed", 0.015, 5.2,
    "six_confirmed", 0.03, 36.3,
    "six_confirmed", 0.045, 46.7,
    "central", 0.015, -126.1,
    "central", 0.03, -42.0,
    "central", 0.045, -14.0,
    "lit_calibrated", 0.015, -208.0,
    "lit_calibrated", 0.03, -86.5,
    "lit_calibrated", 0.045, -46.0
  )
  merged <- merge(t9, printed, by = c("scenario", "r"))
  expect_equal(nrow(merged), 9)
  expect_equal(round(merged$npv.x, 1), merged$npv.y, tolerance = 0.05)
})

test_that("Table 9 matches NPV_calculations_5.2.xlsx's own cached cells", {
  skip_if_no_rauh()
  path <- rauh_npv_calc_path()
  skip_if_not(file.exists(path), "workbook not found")
  cached <- function(cell) {
    suppressMessages(readxl::read_excel(path, sheet = "Sheet1", range = paste0("Sheet1!", cell),
                                         col_names = FALSE))[[1]][[1]]
  }
  t9 <- compute_npv_table9()
  npv_central_015 <- t9$npv[t9$scenario == "central" & t9$r == 0.015]
  npv_six_045 <- t9$npv[t9$scenario == "six_confirmed" & t9$r == 0.045]
  npv_lit_03 <- t9$npv[t9$scenario == "lit_calibrated" & t9$r == 0.03]
  expect_equal(npv_central_015, cached("D35"), tolerance = 1e-6)
  expect_equal(npv_six_045, cached("D43"), tolerance = 1e-6)
  expect_equal(npv_lit_03, cached("D49"), tolerance = 1e-6)
})

test_that("Table 10 matches the paper's printed break-even fractions (p.20)", {
  t10 <- compute_npv_table10()
  printed <- tibble::tribble(
    ~scenario, ~r, ~pct,
    "six_confirmed", 0.015, 30.7,
    "six_confirmed", 0.03, 61.4,
    "six_confirmed", 0.045, 92.1,
    "central", 0.015, 13.8,
    "central", 0.03, 27.7,
    "central", 0.045, 41.5,
    "lit_calibrated", 0.015, 9.1,
    "lit_calibrated", 0.03, 18.1,
    "lit_calibrated", 0.045, 27.2
  )
  merged <- merge(t10, printed, by = c("scenario", "r"))
  expect_equal(nrow(merged), 9)
  expect_equal(round(merged$break_even_pct * 100, 1), merged$pct, tolerance = 0.05)
})
