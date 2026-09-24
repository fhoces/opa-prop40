test_that("excel_col_letters covers single, transitional, and double-letter ranges", {
  expect_equal(excel_col_letters(3), c("A", "B", "C"))
  expect_equal(excel_col_letters(26)[26], "Z")
  expect_equal(excel_col_letters(27)[27], "AA")
  expect_equal(excel_col_letters(28)[28], "AB")
  expect_equal(excel_col_letters(52)[52], "AZ")
  expect_equal(excel_col_letters(53)[53], "BA")
})

test_that("list_sheets returns the sheets in the BSZ workbook", {
  sheets <- list_sheets()
  # August added 4 sheets (Fig9's predecessor moved there, plus
  # 2023-b-1__adjusted_gross_income, data_venturemonitor_annual,
  # data_venturemonitor_quarterly - see RC9c / section 4 of VERIFY-AUGUST.md).
  expect_length(sheets, if (identical(bsz_vintage(), "may")) 36 else 40)
  expect_true("Index" %in% sheets)
  expect_true("Tab1" %in% sheets)
  expect_true("data_sec_top4" %in% sheets)
  expect_true("Pareto-missing" %in% sheets)
})

test_that("read_sheet on Tab1 returns the 2022 anchor row", {
  tab1 <- read_sheet("Tab1")
  expect_s3_class(tab1, "tbl_df")
  # Row 6 (Excel 1-indexed) is the first data row: 2022 panel A entry
  expect_equal(as.numeric(tab1[[6, "A"]]), 2022)
  expect_equal(as.numeric(tab1[[6, "B"]]), 175)
  expect_equal(as.numeric(tab1[[6, "C"]]), 842.53, tolerance = 1e-4)
})

test_that("read_sheet accepts an explicit range", {
  block <- read_sheet("Tab1", range = "A6:C9")
  expect_equal(nrow(block), 4)
  expect_equal(ncol(block), 3)
  expect_equal(as.numeric(block[[1, "A"]]), 2022)
  expect_equal(as.numeric(block[[4, "A"]]), 2025)
})

test_that("read_sheet preserves NA cells", {
  tab1 <- read_sheet("Tab1")
  # Col D (annual growth) on the 2022 row is empty in the source
  expect_true(is.na(tab1[[6, "D"]]))
})
