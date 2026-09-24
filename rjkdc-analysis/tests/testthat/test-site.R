# The public site (site/): the explorer grid is the exporter's own output, its
# cells agree with the pipeline's analytic means and with brute-force Monte
# Carlo, the printed-value transcription agrees with the pipeline, and every
# number typed into the landing page still matches its source.

site_path <- function(...) project_path("site", ...)
minus <- function(x, d) {
  s <- formatC(abs(x), format = "f", digits = d)
  if (x < 0) paste0("−", s) else s
}

test_that("the explorer grid and the analytic mean run the same functions", {
  # OPA Guidelines step 2 Level 3: the tool shares the analysis's key code.
  expect_true(all(c("npv_expectation", "npv_share_negative_exact") %in% all.names(body(cell_outcomes))))
  expect_true("npv_expectation" %in% all.names(body(npv_mc_analytic_mean)))
  site_src <- readLines(project_path("R", "site.R"))
  expect_false(any(grepl("(e_inv_rate|mid_nodes|cell_share_negative)\\s*<-\\s*function", site_src)))
})

test_that("the preferred grid cells equal the pipeline's analytic means", {
  ss <- formals(compute_npv_mc_ssrn); nb <- formals(compute_npv_mc_nber)
  s <- cell_outcomes(ss$wt_min, ss$wt_max, 1, c(ss$c_min, ss$c_max), c(ss$r_min, ss$r_max),
                     list(mode = "implied", baseline = ss$baseline_revenue), 0)
  n <- cell_outcomes(nb$wt_min, nb$wt_max, 1, c(nb$c_min, nb$c_max), c(nb$rg_min, nb$rg_max),
                     list(mode = "uniform", lo = nb$f_min, hi = nb$f_max), 0)
  expect_equal(unname(s["mean_npv"]),
               npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045, f_mode = "ssrn", baseline_revenue = 94.2),
               tolerance = 1e-12)
  expect_equal(unname(n["mean_npv"]),
               npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode = "nber", f_min = 0.30, f_max = 0.60),
               tolerance = 1e-12)
  # the grid's exact share negative vs the authors' own seeded draws (MC error ~0.14 points)
  expect_equal(unname(s["pct_negative"]), compute_npv_mc_ssrn()$summary$pct_negative, tolerance = 4 * 0.15, scale = 1)
  expect_equal(unname(n["pct_negative"]), compute_npv_mc_nber()$summary$pct_negative, tolerance = 4 * 0.15, scale = 1)
})

test_that("an off-preferred cell (q, g and fixed f all active) matches brute-force Monte Carlo", {
  set.seed(7)
  m <- 2e6
  wt <- runif(m, 35, 67.51); cc <- runif(m, 3.3, 5.8); r <- runif(m, 0.015, 0.045)
  npv_i <- 0.75 * wt - (1 - wt / 94.2) * cc / (r - 0.01)
  npv_f <- 0.5 * runif(m, 0, 72) - 0.283 * cc / (r - 0.005)
  a <- cell_outcomes(35, 67.51, 0.75, c(3.3, 5.8), c(0.015, 0.045), list(mode = "implied", baseline = 94.2), 0.01)
  b <- cell_outcomes(0, 72, 0.5, c(3.3, 5.8), c(0.015, 0.045), list(mode = "fixed", value = 0.283), 0.005)
  expect_equal(unname(a["mean_npv"]), mean(npv_i), tolerance = 4 * sd(npv_i) / sqrt(m), scale = 1)
  expect_equal(unname(b["mean_npv"]), mean(npv_f), tolerance = 4 * sd(npv_f) / sqrt(m), scale = 1)
  expect_equal(unname(a["pct_negative"]), 100 * mean(npv_i < 0), tolerance = 0.1, scale = 1)
  expect_equal(unname(b["pct_negative"]), 100 * mean(npv_f < 0), tolerance = 0.1, scale = 1)
})

test_that("site/data/printed-tables.csv agrees with the pipeline at printed rounding", {
  p <- utils::read.csv(site_path("data", "printed-tables.csv"))
  t9 <- compute_npv_table9(); t10 <- compute_npv_table10()
  key9 <- paste0(t9$scenario, "@", t9$r)
  p9 <- p[p$table == "table9", ]
  got9 <- ifelse(p9$column == "npv", t9$npv[match(p9$row, key9)], t9$pv_lost[match(p9$row, key9)])
  expect_equal(round(got9, 1), p9$printed)
  p10 <- p[p$table == "table10", ]
  expect_equal(round(100 * t10$break_even_pct[match(p10$row, paste0(t10$scenario, "@", t10$r))], 1), p10$printed)
  n10 <- compute_npv_table10(scenarios = list(central = list(label = "Central", WT = 0.5 * 72, C = 4.55)))
  pn <- p[p$table == "nber_table10", ]
  expect_equal(round(100 * n10$break_even_pct[match(pn$row, paste0("central@", n10$r))], 1), pn$printed)
  expect_equal(nrow(p[p$table == "table8", ]), 21)
})

test_that("grid.js and headlines.csv are exactly the exporter's own output", {
  skip_if_no_rauh()
  wb <- rauh_workbook_path()
  rc <- compute_revenue_chain(extract_calculations_preferred(wb), extract_calculations_expanded(wb))
  grid <- compute_site_grid(rc)
  expect_equal(nrow(grid), 3^7)
  hl <- compute_site_headlines(
    grid, compute_npv_mc_ssrn()$summary, compute_npv_mc_nber()$summary,
    npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045, f_mode = "ssrn", baseline_revenue = 94.2),
    npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode = "nber", f_min = 0.30, f_max = 0.60),
    rc, compute_nber_collectible(extract_nber_final()))
  tmp <- tempfile(fileext = ".js")
  write_site_grid_js(grid, rc, hl, path = tmp)
  expect_identical(readLines(tmp), readLines(site_path("explorer", "grid.js")))
  tmpc <- tempfile(fileext = ".csv")
  readr_write(hl, tmpc)
  expect_identical(readLines(tmpc), readLines(site_path("data", "headlines.csv")))
})

test_that("the NBER collectible revenue reproduces PDF p.23 (29.6, 28.4, 35.6)", {
  skip_if_no_rauh()
  nc <- compute_nber_collectible(extract_nber_final())
  expect_equal(round(nc$recognized, 2), 59.15)
  expect_equal(round(nc$central, 1), 29.6)
  expect_equal(round(nc$lower, 1), 28.4)
  expect_equal(round(nc$upper, 1), 35.6)
  # the paper prints 71.17 for 71.176 (truncated rather than rounded), hence 0.01
  expect_equal(nc$collectible_base, 71.17, tolerance = 0.01, scale = 1)
})

test_that("every number typed into the landing page matches its source", {
  html <- paste(readLines(site_path("index.html"), warn = FALSE), collapse = "\n")
  hl <- utils::read.csv(site_path("data", "headlines.csv"))
  outs <- utils::read.csv(project_path("export", "r", "outputs.csv"))
  h <- function(v, q, col = "reproduced") hl[[col]][hl$version == v & hl$quantity == q]
  o <- function(id) outs$value[outs$output_id == id]
  expected <- c(
    minus(h("ssrn", "mc_mean_npv", "printed"), 1), minus(h("nber", "mc_mean_npv", "printed"), 1),
    paste0(format(h("ssrn", "mc_pct_negative", "printed")), "%"), paste0(format(h("nber", "mc_pct_negative", "printed")), "%"),
    minus(h("ssrn", "mc_mean_npv"), 2), minus(h("nber", "mc_mean_npv"), 2),
    minus(h("ssrn", "analytic_mean_npv"), 2), minus(h("nber", "analytic_mean_npv"), 2),
    minus(h("ssrn", "mc_expected_revenue"), 2), minus(h("nber", "mc_expected_revenue"), 2),
    minus(h("ssrn", "pv_lost"), 2), minus(h("nber", "pv_lost"), 2),
    minus(h("nber", "revenue_headline"), 2), minus(h("nber", "revenue_range_low"), 2),
    minus(h("nber", "revenue_range_high"), 2),
    sprintf("about %g (%g to %g)", h("ssrn", "revenue_headline", "printed"), 35, h("ssrn", "revenue_range_high", "printed")),
    sprintf("about 30 (%g to %g)", h("nber", "revenue_range_low", "printed"), h("nber", "revenue_range_high", "printed")),
    sprintf("%s / %s / %s / %s", minus(o("revenue_baseline"), 2), minus(o("revenue_confirmed6"), 2),
            minus(o("revenue_expanded10"), 2), minus(o("revenue_literature_calibrated"), 2)),
    sprintf("worth %.0f to %.0f dollars", 1 / 0.045, 1 / 0.015),
    sprintf("%s in the person-level data", minus(o("nber_ceiling"), 2)),
    format(3^7, big.mark = ","),
    sprintf("alpha %s", minus(o("pareto_alpha"), 2))
  )
  for (e in expected) expect_true(grepl(e, html, fixed = TRUE), info = e)
  # the SSRN printed mean is the exact expectation to the printed digit
  expect_equal(round(h("ssrn", "analytic_mean_npv"), 1), h("ssrn", "mc_mean_npv", "printed"))
  # "roughly 75 ... lost" and "six are guesswork"
  expect_equal(round(mean(c(h("ssrn", "pv_lost"), h("nber", "pv_lost")))), 75)
  expect_true(grepl("six\n   are guesswork", html, fixed = TRUE) || grepl("six are guesswork", html, fixed = TRUE))
  # nine mismatches listed, as in MISMATCHES.md
  n_mm <- sum(grepl("^## [0-9]+\\.", readLines(project_path("MISMATCHES.md"))))
  expect_equal(n_mm, 9)
  expect_equal(lengths(regmatches(html, gregexpr("<li>", html))), n_mm)
})

test_that("every explorer dial carries an OPA origin label", {
  dials_src <- paste(deparse(body(site_dials)), collapse = "\n")
  origins <- regmatches(dials_src, gregexpr('origin = "[a-z]+"', dials_src))[[1]]
  expect_length(origins, 7)
  expect_true(all(sub('origin = "([a-z]+)"', "\\1", origins) %in% c("data", "research", "guesswork", "scenario")))
})
