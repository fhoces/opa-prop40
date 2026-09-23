revenue_chain_fixture <- function() {
  skip_if_no_rauh()
  wb <- rauh_workbook_path()
  skip_if_not(file.exists(wb), "workbook not found")
  pref <- extract_calculations_preferred(wb)
  exp <- extract_calculations_expanded(wb)
  compute_revenue_chain(pref, exp)
}

test_that("revenue chain matches the paper's printed figures (pp.10-14)", {
  rc <- revenue_chain_fixture()
  expect_equal(round(rc$baseline_precise, 2), 94.30)   # paper rounds to 94.20 - MISMATCHES #6
  expect_equal(round(rc$confirmed6_ceiling, 2), 67.51)
  expect_equal(round(rc$expanded10_estimate, 2), 55.10)
  expect_equal(round(rc$literature_calibrated, 2), 45.59)
})

test_that("revenue chain matches the workbook's own cached Summary cells", {
  skip_if_no_rauh()
  wb <- rauh_workbook_path()
  skip_if_not(file.exists(wb), "workbook not found")

  cached <- function(sheet, cell) {
    suppressMessages(readxl::read_excel(wb, range = paste0(sheet, "!", cell),
                                         col_names = FALSE))[[1]][[1]]
  }
  rc <- revenue_chain_fixture()
  expect_equal(rc$baseline_precise, cached("Summary_Preferred", "C5"), tolerance = 1e-6)
  expect_equal(rc$confirmed6_ceiling, cached("Summary_Preferred", "F5"), tolerance = 1e-6)
  expect_equal(rc$expanded10_estimate, cached("Summary_Expanded", "F5"), tolerance = 1e-6)
  expect_equal(rc$literature_calibrated, cached("Summary_Preferred", "F8"), tolerance = 1e-6)
})
