# Tests for the public OPA site (site/) and the exports behind it
# (R/site_exports.R). Three kinds:
#   1. the explorer and the reproduction run ONE estimating function, score_tab5_cell() in
#      R/compute_tab5.R, and its defaults are the workbook's own inputs (so the
#      tool cannot drift from the analysis, which test-compute.R pins to Excel);
#   2. the committed site/explorer/grid.js is exactly the exporter's output;
#   3. every number typed into a hand-written page is recomputed here and its
#      formatted string must still be in that page (prose-number test).

SITE <- testthat::test_path("..", "..", "site")

site_inp <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      par_r <- compute_pareto_missing(extract_pareto_missing())
      cache <<- list(par_r = par_r, tab2 = extract_tab2(), tab3 = extract_tab3())
      cache$inp   <<- tab5_scoring_inputs(par_r, cache$tab2, cache$tab3)
      cache$tab5  <<- compute_tab5(par_r, cache$tab2, cache$tab3)
    }
    cache
  }
})

test_that("score_tab5_cell reproduces compute_tab5's four rows at the workbook inputs", {
  s <- site_inp()
  rows <- rbind(
    score_tab5_cell(s$inp),
    score_tab5_cell(s$inp, pareto = TRUE),
    score_tab5_cell(s$inp, leavers = TRUE),
    score_tab5_cell(s$inp, pareto = TRUE, leavers = TRUE)
  )
  for (col in colnames(rows)) {
    expect_equal(unname(rows[, col]), s$tab5[[col]], tolerance = 1e-12, info = col)
  }
})

test_that("the reproduction and the explorer grid both call score_tab5_cell()", {
  # OPA Guidelines step 2 Level 3: the tool shares the analysis's key code.
  expect_true("score_tab5_cell" %in% all.names(body(compute_tab5)))
  expect_true("score_tab5_cell" %in% all.names(body(build_site_grid)))
  # and no second implementation of the estimating arithmetic is left in the site layer
  site_src <- readLines(testthat::test_path("..", "..", "R", "site_exports.R"))
  expect_false(any(grepl("score_tab5_cell\\s*<-\\s*function", site_src)))
})

test_that("the named explorer rows are the Table 5 rows, cell for cell", {
  s <- site_inp()
  grid <- build_site_grid(s$inp)
  dials <- site_dials()
  expect_equal(nrow(grid), prod(vapply(dials, function(d) length(d$levels), 1L)))
  sizes <- vapply(dials, function(d) length(d$levels), 1L)
  named <- site_named_rows()
  for (k in seq_along(named)) {
    lv <- named[[k]] - 1L
    i <- 0L
    for (j in seq_along(lv)) i <- i * sizes[j] + lv[j]
    expect_equal(grid$wealth_tax_revenue[i + 1L], s$tab5$wealth_tax_revenue[k],
                 tolerance = 1e-12, info = names(named)[k])
    expect_equal(grid$annual_ca_inctax_loss[i + 1L], s$tab5$annual_ca_inctax_loss[k],
                 tolerance = 1e-12, info = names(named)[k])
  }
})

test_that("site/explorer/grid.js is exactly the exporter's output", {
  skip_if_not(identical(bsz_snapshot_set(), "august"),
              "grid.js is committed for the default workbook (August, data appendix of 2026-10-08)")
  path <- file.path(SITE, "explorer", "grid.js")
  skip_if_not(file.exists(path), "site/explorer/grid.js not present")
  s <- site_inp()
  expected <- site_grid_js_text(build_site_grid(s$inp), s$inp)
  expect_identical(paste(readLines(path, encoding = "UTF-8"), collapse = "\n"),
                   sub("\n$", "", expected))
})

test_that("exactly two Table 5 cells miss the digit the paper prints", {
  skip_if_not(identical(bsz_vintage(), "august"), "printed values are the August paper's")
  s <- site_inp()
  p <- compare_tab5_printed(s$tab5)
  miss <- p[!p$matches_printed, ]
  expect_equal(nrow(p), 28L)
  expect_equal(paste(miss$column, miss$row),
               c("annual_ca_inctax_loss 2", "annual_ca_inctax_loss 3"))
})

test_that("every number typed into the landing page matches the pipeline", {
  skip_if_not(identical(bsz_vintage(), "august"), "the site is published for the August vintage")
  path <- file.path(SITE, "index.html")
  skip_if_not(file.exists(path), "site/index.html not present")
  html <- gsub("\\s+", " ", paste(readLines(path, encoding = "UTF-8"), collapse = " "))
  s <- site_inp(); t5 <- s$tab5
  b1 <- function(x) sprintf("$%.1fB", x)
  b2 <- function(x) sprintf("$%.2fB", x)
  p  <- compare_tab5_printed(t5)
  miss <- p[!p$matches_printed, ]
  n_cells <- nrow(build_site_grid(s$inp))
  expected <- c(
    sprintf("<strong>$%.1f billion</strong>", t5$wealth_tax_revenue[1]),
    sprintf("$%s billion that Forbes lists for %d California",
            format(s$inp$W0, big.mark = ","), s$inp$n0),
    b1(t5$wealth_tax_revenue), b1(t5$extra_ca_inctax_sales), b2(-t5$annual_ca_inctax_loss),
    sprintf("plus %s settings", format(n_cells - 4L, big.mark = ",")),
    sprintf("All %d cells match", nrow(p)),
    sprintf("%d round to the digit", sum(p$matches_printed)),
    sprintf("the other %d, the income tax loss in rows 2 and 3", nrow(miss)),
    sprintf("printed as $%.2fB and $%.2fB", -miss$printed[1], -miss$printed[2]),
    sprintf("workbook gives $%.2fB and $%.2fB", -miss$reproduced[1], -miss$reproduced[2]),
    # the main estimate: wealth tax + extra income tax - present value of the loss (5 years at 3%)
    sprintf("<strong>$%.1f billion</strong>", t5$wealth_tax_revenue[1] + t5$extra_ca_inctax_sales[1] +
              t5$annual_ca_inctax_loss[1] * site_pv_factor()),
    b1(t5$wealth_tax_revenue + t5$extra_ca_inctax_sales + t5$annual_ca_inctax_loss * site_pv_factor())
  )
  for (e in expected) expect_true(grepl(e, html, fixed = TRUE), info = e)
})

test_that("the two guesses that move the revenue on their own are avoidance and leavers", {
  s <- site_inp()
  grid <- build_site_grid(s$inp)
  dials <- site_dials()
  keys <- vapply(dials, `[[`, "", "key")
  base <- stats::setNames(mapply(function(d, j) d$levels[j], dials, site_named_rows()[[1]]), keys)
  moves <- vapply(keys, function(k) {
    keep <- Reduce(`&`, lapply(setdiff(keys, k), function(o) abs(grid[[o]] - base[[o]]) < 1e-9))
    diff(range(grid$wealth_tax_revenue[keep])) > 1e-9
  }, TRUE)
  guess <- vapply(dials, `[[`, "", "origin") == "guesswork"
  expect_equal(unname(keys[moves & guess]), c("avoidance", "leavers"))
})

# The checks page (site/checks.qmd) builds its two tables from the explorer's grid.js when it
# is rendered (author answer 2026-10-16, item 23). Pin the rendered tables against the grid
# recomputed here, so a stale render or a retyped table fails.
test_that("the checks page's tables show the explorer's values", {
  skip_if_not(identical(bsz_snapshot_set(), "august"), "the site is published for the default workbook")
  qmd <- file.path(SITE, "checks.qmd"); html_path <- file.path(SITE, "checks.html")
  skip_if_not(file.exists(html_path), "site/checks.html not rendered")
  src <- paste(readLines(qmd, encoding = "UTF-8"), collapse = "\n")
  expect_true(grepl('readLines("explorer/grid.js"', src, fixed = TRUE))
  expect_false(grepl("copied", src, fixed = TRUE))   # no hand-copied table or "copied on" date
  html <- paste(readLines(html_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  rows <- regmatches(html, gregexpr("(?s)<tr[^>]*>.*?</tr>", html, perl = TRUE))[[1]]
  cells <- lapply(rows, function(r)
    gsub("<[^>]+>", "", regmatches(r, gregexpr("(?s)<td[^>]*>.*?</td>", r, perl = TRUE))[[1]]))
  has_row <- function(want, at) any(vapply(cells, function(cl)
    length(cl) >= max(at) && identical(cl[at], want), TRUE))
  f2 <- function(x) { s <- formatC(abs(round(x, 2)), format = "f", digits = 2)
                      ifelse(round(x, 2) < 0, paste0("−", s), s) }

  s <- site_inp(); grid <- as.data.frame(build_site_grid(s$inp))
  base <- list(avoidance = 0.10, mobility_share = 0.5, avoidance_small = 0.2,
               sell_share = 1/3, pareto = 0, leavers = 0)
  pick <- function(...) {
    ch <- utils::modifyList(base, list(...))
    keep <- Reduce(`&`, Map(function(k, v) abs(grid[[k]] - v) < 1e-6, names(ch), ch))
    expect_equal(sum(keep), 1L)
    grid[keep, ]
  }
  # Table 1: Table 5's four August rows (explorer) and four May rows (May workbook).
  aug <- list(pick(), pick(pareto = 1), pick(leavers = 1), pick(pareto = 1, leavers = 1))
  printed <- c(104, 128, 89, 115)   # August paper, Table 5 rows 1 to 4, PDF p.39
  for (r in 1:4) {
    expect_true(has_row(c(sprintf("%g", printed[r]), f2(aug[[r]]$wealth_tax_revenue), "Match"), 3:5),
                info = paste("August row", r))
  }
  may_inp <- withr::with_envvar(c(BSZ_VINTAGE = "may"),
    tab5_scoring_inputs(compute_pareto_missing(extract_pareto_missing()), extract_tab2(), extract_tab3()))
  may <- withr::with_envvar(c(BSZ_VINTAGE = "may"), c(
    score_tab5_cell(may_inp)[["wealth_tax_revenue"]],
    score_tab5_cell(may_inp, pareto = TRUE)[["wealth_tax_revenue"]],
    score_tab5_cell(may_inp, leavers = TRUE)[["wealth_tax_revenue"]],
    score_tab5_cell(may_inp, pareto = TRUE, leavers = TRUE)[["wealth_tax_revenue"]]))
  for (r in 1:4) {
    expect_true(has_row(c(sprintf("May, Table 5 row %d", r), sprintf("%g", c(98, 121, 84, 109)[r]),
                          f2(may[r]), "Match"), 2:5), info = paste("May row", r))
  }
  # Table 2: the ten one-at-a-time settings, plus the base for reference.
  settings <- list(pick(), pick(avoidance = 0), pick(avoidance = 0.05), pick(avoidance = 0.20),
                   pick(avoidance = 0.30), pick(mobility_share = 0), pick(mobility_share = 1),
                   pick(sell_share = 0), pick(sell_share = 1),
                   pick(pareto = 1, avoidance_small = 0.10), pick(pareto = 1, avoidance_small = 0.50))
  for (g in settings) {
    want <- f2(c(g$wealth_tax_revenue, g$extra_ca_inctax_sales, g$annual_ca_inctax_loss, g$main_estimate))
    expect_true(has_row(want, 2:5), info = paste(want, collapse = " | "))
  }
})
