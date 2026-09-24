test_that("expect_matches_excel succeeds on a perfect round-trip", {
  tab1 <- read_sheet("Tab1")
  expect_success(expect_matches_excel(tab1, "Tab1"))
})

test_that("expect_matches_excel succeeds within an explicit range", {
  block <- read_sheet("Tab1", range = "A6:C9")
  expect_success(expect_matches_excel(block, "Tab1", range = "A6:C9"))
})

test_that("expect_matches_excel fails when a numeric cell is perturbed beyond tolerance", {
  # Range A6:H9 is the Panel A numeric block: every column reads as numeric.
  panel_a <- read_sheet("Tab1", range = "A6:H9")
  panel_a[[1, "C"]] <- panel_a[[1, "C"]] + 1  # 842.53 -> 843.53
  expect_failure(
    expect_matches_excel(panel_a, "Tab1", range = "A6:H9", tolerance = 1e-6),
    regexp = "numeric cells differ"
  )
})

test_that("expect_matches_excel tolerates small numeric perturbations", {
  panel_a <- read_sheet("Tab1", range = "A6:H9")
  panel_a[[1, "C"]] <- panel_a[[1, "C"]] * (1 + 1e-9)
  expect_success(expect_matches_excel(panel_a, "Tab1", range = "A6:H9", tolerance = 1e-6))
})

test_that("expect_matches_excel detects NA-pattern differences", {
  panel_a <- read_sheet("Tab1", range = "A6:H9")
  # Row 1 col D is NA in source (no annual growth for the base year 2022)
  expect_true(is.na(panel_a[[1, "D"]]))
  panel_a[[1, "D"]] <- 0
  expect_failure(
    expect_matches_excel(panel_a, "Tab1", range = "A6:H9"),
    regexp = "NA pattern differs"
  )
})

test_that("expect_matches_excel detects shape mismatches", {
  tab1 <- read_sheet("Tab1")
  truncated <- tab1[, -ncol(tab1)]
  expect_failure(
    expect_matches_excel(truncated, "Tab1"),
    regexp = "Shape mismatch"
  )
})
