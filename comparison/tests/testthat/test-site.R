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

test_that("the main estimate is the gap on output (a) between the bridge's two ends", {
  html <- paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n")
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  ea <- en[en$horizon_setting == "own" & en$output == "a", ]
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  # the two ends are the endpoints the page calls BSZ row 1 and the NBER expected revenue
  expect_equal(ea$bsz_model, ep$value[ep$endpoint_id == "bsz_tab5_row1"])
  expect_equal(ea$nber_own, ep$value[ep$endpoint_id == "rauh_nber_revenue_mc"])
  # the steps between them (Shapley, the model difference, the NBER revision) add up to it
  br <- read_csv_plain(file.path(root, "comparison", "export", "r", "bridge.csv"))
  b <- br[br$horizon_setting == "own" & br$output == "a", ]
  expect_equal(sum(b$shapley) + ea$rauh_residual + ea$nber_step, ea$nber_own - ea$bsz_model,
               tolerance = 1e-9)
  expect_true(grepl(sprintf('id="hl-main">%s<', money(ea$bsz_model - ea$nber_own, 1)), html, fixed = TRUE))
  expect_true(grepl("Main estimate<sup>1</sup>, the gap on the common output", html, fixed = TRUE))
})

test_that("every relative link on the page resolves to a file in the repo (sub-sites may be pending)", {
  html <- paste(readLines(file.path(root, "index.html"), encoding = "UTF-8"), collapse = "\n")
  refs <- regmatches(html, gregexpr('(href|src)="[^"#]+"', html))[[1]]
  refs <- unique(sub('^(href|src)="', "", sub('"$', "", refs)))
  refs <- refs[!grepl("^(https?:|mailto:)", refs)]
  pending <- "rjkdc-analysis/site/"   # built in parallel on another branch
  for (r in setdiff(refs, pending)) {
    p <- file.path(root, r)
    if (grepl("/$", r)) p <- file.path(p, "index.html")
    expect_true(file.exists(p), label = r)
  }
})
