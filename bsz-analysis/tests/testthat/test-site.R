# Tests for the public OPA site (site/) and the exports behind it
# (R/site_exports.R). Three kinds:
#   1. the explorer and the reproduction run ONE scorer, score_tab5_cell() in
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
  # and no second implementation of the scoring arithmetic is left in the site layer
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
  skip_if_not(identical(bsz_vintage(), "august"), "grid.js is committed for the August vintage")
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
    sprintf("workbook gives $%.2fB and $%.2fB", -miss$reproduced[1], -miss$reproduced[2])
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
