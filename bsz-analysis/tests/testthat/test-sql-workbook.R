# Queries 2 and 3 (sql/02_data_sec_agg.sql, sql/03_ftb_b4a.sql) against the
# R code they replaced. Both now run inside compute_data_sec_agg() and
# compute_billionaires_ca_inctax(), so every other test exercises them too;
# these tests pin the SQL to the earlier R logic directly.

# The dplyr version of compute_data_sec_agg() before query 2 replaced it.
.data_sec_agg_dplyr <- function(data_sec_all, exclude_ids = ELLISON_FORBES_ID) {
  sum_cols <- c(
    "forbes_worth", "forbes_public_worth", "purchase", "sale",
    "kg", "kg_long", "kg_short", "option_profit", "noneq_comp", "ordinary_income",
    "kg_taxable", "dividend", "fiscal_income", "donation", "donation_deductible",
    "income_taxable", "ca_income_tax", "fed_ordinary_income_tax", "fed_preferential_tax",
    "fed_income_tax", "fiscal_income_tax", "sales_tax", "w_txt", "w_tax_ppent", "w_pi",
    "total_tax", "economic_income"
  )
  f <- data_sec_all[!(data_sec_all$forbes_id %in% exclude_ids), ]
  f <- f[!duplicated(f[c("year", "forbes_id", "forbes_worth")]), ]
  out <- f |>
    dplyr::group_by(year) |>
    dplyr::summarise(n = dplyr::n(),
                     dplyr::across(dplyr::all_of(sum_cols), \(x) sum(x, na.rm = TRUE) / 1000),
                     .groups = "drop")
  out$year <- as.integer(out$year)
  tibble::as_tibble(out)
}

test_that("query 2 reproduces the dplyr aggregation of data_sec_all", {
  d_all <- extract_data_sec_all()
  sql <- compute_data_sec_agg(d_all)
  ref <- .data_sec_agg_dplyr(d_all)
  expect_identical(names(sql), names(ref))
  expect_identical(sql$year, ref$year)
  expect_identical(sql$n, ref$n)
  # SQLite's compensated SUM vs R's running sum: last-digit differences only.
  expect_equal(sql, ref, tolerance = 1e-12)
  # The exclusion list is an input table, so an empty one keeps every id.
  expect_equal(compute_data_sec_agg(d_all, exclude_ids = character(0)),
               .data_sec_agg_dplyr(d_all, exclude_ids = character(0)), tolerance = 1e-12)
})

test_that("query 3 selects the same FTB rows the sheet-row map used to", {
  ftb <- extract_ftb_b4a()
  q <- query_ftb_b4a(ftb)
  # The sheet-row ranges the R code used before query 3 (2022 at the top).
  ranges <- list("2018" = c(242, 300), "2019" = c(183, 241), "2020" = c(124, 182),
                 "2021" = c(64, 123), "2022" = c(4, 63))
  cols <- c(D = "all_returns", H = "ca_agi", J = "taxable_income", K = "total_tax")
  for (yr in names(ranges)) {
    rows <- ranges[[yr]][1]:ranges[[yr]][2]
    y <- q$year[q$year$taxable_year == as.integer(yr), ]
    expect_equal(nrow(y), 1L)
    expect_equal(y$n_brackets, length(rows), info = yr)
    for (L in names(cols)) {
      old <- sum(suppressWarnings(as.numeric(ftb[[L]][rows])), na.rm = TRUE)
      expect_identical(y[[cols[[L]]]], old, info = paste(yr, L))
    }
  }
  # Top-bracket rows: same sheet rows as the old map.
  top_rows <- c("2018 5m_plus" = 300, "2019 5m_plus" = 241, "2020 5m_plus" = 182,
                "2021 5m_to_10m" = 122, "2021 10m_plus" = 123,
                "2022 5m_to_10m" = 62, "2022 10m_plus" = 63)
  key <- paste(q$top$taxable_year, q$top$bracket)
  expect_false(any(duplicated(key)))
  expect_equal(unname(q$top$row_num[match(names(top_rows), key)]), unname(top_rows))
  # Every year has its top bracket(s): 5m_plus up to 2020, the split after.
  expect_setequal(q$top$bracket[q$top$taxable_year <= 2020], "5m_plus")
  expect_setequal(q$top$bracket[q$top$taxable_year >= 2021], c("5m_to_10m", "10m_plus"))
})

test_that("the pipeline database gives the same results as the in-memory run", {
  db <- workbook_db_path()
  skip_if_not(file.exists(db), "data-raw/workbook.sqlite not built yet (targets::tar_make())")
  expect_equal(read_data_sec_agg(db), compute_data_sec_agg(extract_data_sec_all()))
  expect_equal(unclass(read_ftb_b4a(db)), unclass(query_ftb_b4a(extract_ftb_b4a())))
})
