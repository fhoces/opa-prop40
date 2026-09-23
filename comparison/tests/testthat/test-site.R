# The published page is exactly what the generator makes from the exports.
root <- comparison_root()

test_that("index.html and assets/comparison-data.js are the generator's own output", {
  s <- render_site(root)
  expect_identical(s$html, paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n") |> paste0("\n"))
  expect_identical(s$js, paste(readLines(file.path(root, "assets", "comparison-data.js"), encoding = "UTF-8"), collapse = "\n") |> paste0("\n"))
})

test_that("no unfilled tokens, no em-dashes on the page", {
  html <- paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n")
  expect_false(grepl("{{", html, fixed = TRUE))
  expect_false(grepl(intToUtf8(0x2014), html, fixed = TRUE))
})

test_that("key numbers appear on the page as computed", {
  html <- paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n")
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  v <- function(id) ep$value[ep$endpoint_id == id]
  expect_true(grepl(money(v("bsz_tab5_row1"), 1), html, fixed = TRUE))
  expect_true(grepl(money(v("rauh_ssrn_npv"), 2), html, fixed = TRUE))
  expect_true(grepl(money(v("rauh_ssrn_revenue_mc"), 2), html, fixed = TRUE))
})

test_that("every relative link on the page resolves to a file in the repo (sub-sites may be pending)", {
  html <- paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n")
  refs <- regmatches(html, gregexpr('(href|src)="[^"#]+"', html))[[1]]
  refs <- unique(sub('^(href|src)="', "", sub('"$', "", refs)))
  refs <- refs[!grepl("^(https?:|mailto:)", refs)]
  pending <- "opposing-analysis/site/"   # built in parallel on another branch
  for (r in setdiff(refs, pending)) {
    p <- file.path(root, r)
    if (grepl("/$", r)) p <- file.path(p, "index.html")
    expect_true(file.exists(p), label = r)
  }
})
