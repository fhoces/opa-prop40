nber_final_fixture <- function() {
  skip_if_no_rauh()
  path <- rauh_nber_final_csv()
  skip_if_not(file.exists(path), "final.csv not found")
  extract_nber_final(path)
}

test_that("final.csv has the row counts described in the NBER README", {
  df <- nber_final_fixture()
  expect_equal(nrow(df), 240)
  expect_equal(sum(df$panel == "domestic"), 212)
  expect_equal(sum(df$panel == "international"), 28)
})

test_that("NBER ceiling rebuilds the README's printed figures from final.csv", {
  df <- nber_final_fixture()
  ceiling <- compute_nber_ceiling(df)

  expect_equal(ceiling$n_removed_departed, 7)
  expect_equal(round(ceiling$domestic_total_grown, 1), 100.9)
  expect_equal(round(ceiling$international_net_worth, 1), 146.3)
  # README prints 72.06; our recomputation is 72.05 (rounds differently -
  # MISMATCHES.md #4). Both are within 1 cent of the true sum.
  expect_equal(round(ceiling$ceiling_recomputed, 2), 72.05)
  expect_equal(round(ceiling$ceiling_recomputed, 1), 72.1)

  # The 7 removed = SSRN's 6 confirmed departures + Travis Kalanick.
  expect_true(all(c("Larry Page", "Sergey Brin", "Peter Thiel", "Don Hankey",
                     "Steven Spielberg", "David Sacks", "Travis Kalanick")
                   %in% ceiling$removed_names))
})

test_that("NPV_dist_v8.R's hard-coded wt_max (72) differs from the recomputed ceiling", {
  df <- nber_final_fixture()
  ceiling <- compute_nber_ceiling(df)
  # This is MISMATCHES.md #4: the script itself uses the literal 72, not
  # the ~72.05 this function derives from final.csv.
  expect_gt(abs(72 - ceiling$ceiling_recomputed), 0.001)
})
