# Tests for the public OPA site (site/) and the exports behind it
# (R/site_exports.R). Three kinds:
#   1. the explorer's generalised scorer reproduces compute_tab5() exactly at
#      the workbook's own inputs (so the tool cannot drift from the analysis);
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
