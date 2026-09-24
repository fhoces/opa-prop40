# Exports for the public site (site/): the explorer grid, the NBER
# collectible-revenue figure, and the headline table the landing page and the
# prose-number test read. Nothing here changes an existing computation; every
# default below is read from the pipeline's own functions (formals of
# compute_npv_mc_ssrn()/compute_npv_mc_nber(), revenue_chain) so the site
# cannot drift from the reproduction.

# ---- NBER revenue headline (PDF pp.22-23, eqs. 5-8) -------------------------
# final.csv carries each person's treatment bucket. Recognized base =
# stayer_base + ambiguous ($59.15B, eq.5); E[R] = q x recognized ($29.6B,
# eq.6/8). Upper end keeps Zuckerberg (eq.7, $35.6B); lower end drops the
# ambiguous rows and the three reported leavers still in stayer_base
# (Koum, Hastings, Fang: "falls ... to $28.4 billion", PDF p.23).
nber_gray_zone_names <- function() c("Jan Koum", "Reed Hastings", "Andy Fang")

compute_nber_collectible <- function(final_df, q = 0.50) {
  dom <- final_df[final_df$panel == "domestic", ]
  tot <- function(b) sum(dom$face_tax_5pct[dom$bucket %in% b]) / 1e9
  stayers <- tot("stayer_base")
  ambiguous <- tot("ambiguous")
  zuck <- tot("zuckerberg")
  prefiling <- tot("removed_prefiling")
  gray <- sum(dom$face_tax_5pct[dom$bucket == "stayer_base" &
                                  dom$name %in% nber_gray_zone_names()]) / 1e9
  recognized <- stayers + ambiguous
  list(
    q = q,
    stayer_base = stayers,
    ambiguous = ambiguous,
    zuckerberg = zuck,
    removed_prefiling = prefiling,
    collectible_base = recognized + zuck,          # $71.17B (PDF p.22)
    recognized = recognized,                       # $59.15B (eq.5)
    central = q * recognized,                      # $29.6B (eq.6)
    upper = q * (recognized + zuck),               # $35.6B (eq.7)
    lower = q * (stayers - gray)                   # $28.4B (p.23)
  )
}

# ---- Explorer grid ----------------------------------------------------------
# Seven dials, three levels each (3^7 = 2187 cells). For every cell the grid
# stores four outcomes, all seed-free:
#   1. mean NPV: closed form, q*E[WT] - E[f]*E[C]*E[1/(rho - g)], computed by
#      npv_expectation() in R/npv_mc.R, the function behind
#      npv_mc_analytic_mean();
#   2. share of outcomes with NPV < 0: deterministic midpoint quadrature over
#      C, rho (and f when it is drawn), with WT's uniform CDF done exactly;
#   3. expected wealth tax collected, q*E[WT];
#   4. expected present value of lost income tax.
# f is either implied by WT (SSRN, f = 1 - WT/baseline), an independent
# uniform (NBER), or fixed at the confirmed-departure share.
site_dials <- function(revenue_chain) {
  ss <- formals(compute_npv_mc_ssrn)
  nb <- formals(compute_npv_mc_nber)
  f_fixed <- 1 - revenue_chain$confirmed6_ceiling / ss$baseline_revenue
  list(
    list(key = "wt_lo", label = "Revenue, low end of the draw ($B)",
         origin = "guesswork",
         desc = paste0("Lower bound of the uniform draw for one-time wealth tax revenue WT. ",
                       "0 is the NBER script (its only trace of litigation risk); 35 is the SSRN ",
                       "script (a 12-13 semi-elasticity, above the literature's 10.32); ",
                       "45.59 is the literature-calibrated revenue (Sec 4.4)."),
         levels = c(nb$wt_min, ss$wt_min, revenue_chain$literature_calibrated),
         labels = c("0 (NBER)", "35 (SSRN)", sprintf("%.2f", revenue_chain$literature_calibrated))),
    list(key = "wt_hi", label = "Revenue, high end of the draw ($B)",
         origin = "data",
         desc = paste0("Upper bound of the WT draw: revenue after publicly reported departures. ",
                       "55.10 removes 10 departures (Sec 4.3); 67.51 the 6 confirmed ones (Sec 4.2, SSRN script); ",
                       "72 the 7 confirmed ones at the 7%-grown NBER vintage (the NBER script's literal)."),
         levels = c(revenue_chain$expanded10_estimate, ss$wt_max, nb$wt_max),
         labels = c(sprintf("%.2f", revenue_chain$expanded10_estimate),
                    sprintf("%.2f (SSRN)", ss$wt_max), sprintf("%g (NBER)", nb$wt_max))),
    list(key = "q", label = "Litigation survival, applied to revenue",
         origin = "guesswork",
         desc = paste0("Probability the Act survives constitutional challenge, as a multiplier on revenue ",
                       "collected (the NBER README's stated mechanism). Neither script has this multiplier, ",
                       "so both preferred settings use 1; the NBER script instead puts q into the 0 lower ",
                       "bound (mismatch 5). Lost income tax is not scaled by q (NBER PDF p.33)."),
         levels = c(1, 0.75, 0.5),
         labels = c("1 (as coded)", "0.75", "0.50")),
    list(key = "c", label = "Annual billionaire income tax, C ($B)",
         origin = "guesswork",
         desc = paste0("Uniform draw between the two income-tax Monte Carlo bounds (Table 8: K = 212 ",
                       "gives 5.76, K = 500 gives 3.31). Both scripts draw U[3.3, 5.8]; the choice of ",
                       "K = 500 as the floor is the authors' judgement (disputes row 5)."),
         levels = list(c(ss$c_min, ss$c_max), c(ss$c_min, ss$c_min), c(ss$c_max, ss$c_max)),
         labels = c(sprintf("%.1f to %.1f", ss$c_min, ss$c_max),
                    sprintf("%.1f only", ss$c_min), sprintf("%.1f only", ss$c_max))),
    list(key = "rate", label = "Discount rate drawn, r",
         origin = "guesswork",
         desc = paste0("Uniform draw for the rate in the perpetuity's denominator. 1.5% is the S&P ",
                       "dividend-yield anchor (p.18); both scripts draw 1.5% to 4.5%."),
         levels = list(c(ss$r_min, ss$r_max), c(ss$r_min, ss$r_min), c(ss$r_max, ss$r_max)),
         labels = c(sprintf("%.1f%% to %.1f%%", 100 * ss$r_min, 100 * ss$r_max),
                    sprintf("%.1f%% only", 100 * ss$r_min), sprintf("%.1f%% only", 100 * ss$r_max))),
    list(key = "f", label = "Share of the income tax base that leaves, f",
         origin = "guesswork",
         desc = paste0("SSRN: implied by the revenue draw, f = 1 - WT/94.2 (income tax lost in ",
                       "proportion to wealth lost). NBER: an independent U[0.30, 0.60]. Third option: ",
                       "fixed at the 6 confirmed departures' share of the base."),
         levels = list(list(mode = "implied", baseline = ss$baseline_revenue),
                       list(mode = "uniform", lo = nb$f_min, hi = nb$f_max),
                       list(mode = "fixed", value = f_fixed)),
         labels = c("1 - WT/94.2 (SSRN)",
                    sprintf("U[%.2f, %.2f] (NBER)", nb$f_min, nb$f_max),
                    sprintf("%.3f fixed", f_fixed))),
    list(key = "g", label = "Growth of lost income, g (r vs r - g reading)",
         origin = "guesswork",
         desc = paste0("Both scripts use the drawn rate as the whole denominator, so g = 0 is 'as coded'. ",
                       "Eq. 17-20 describe a growing perpetuity f*C/(r - g) without giving g; reading the ",
                       "draw as a real r and subtracting a positive g shows how much that ambiguity is worth ",
                       "(mismatches 2 and 3). The two non-zero values are this reproduction's illustration, ",
                       "not the authors'."),
         levels = c(0, 0.005, 0.01),
         labels = c("0 (as coded)", "0.5% (illustrative)", "1.0% (illustrative)"))
  )
}

site_named <- function() {
  list(
    ssrn = c(wt_lo = 1, wt_hi = 1, q = 0, c = 0, rate = 0, f = 0, g = 0),
    nber = c(wt_lo = 0, wt_hi = 2, q = 0, c = 0, rate = 0, f = 1, g = 0)
  )
}

site_named_labels <- function() {
  c(ssrn = "SSRN, Mar 2026", nber = "NBER, Sept 2026")
}

# One cell of the grid: the analysis's own closed form and exact share
# (npv_expectation(), npv_share_negative_exact() in R/npv_mc.R), so the
# explorer runs the same code as the reproduction.
cell_outcomes <- function(a, b, q, c_rng, r_rng, f_spec, g) {
  e <- npv_expectation(a, b, c_rng[1], c_rng[2], r_rng[1], r_rng[2], f_spec, q = q, g = g)
  c(mean_npv = e[["mean_npv"]],
    pct_negative = 100 * npv_share_negative_exact(a, b, c_rng[1], c_rng[2], r_rng[1], r_rng[2],
                                                  f_spec, q = q, g = g),
    wt_collected = e[["wt_collected"]],
    pv_lost = e[["pv_lost"]])
}

# One row per cell, in mixed-radix order with the LAST dial varying fastest
# (the explorer's idx() function), i.e. expand.grid with the first dial
# varying slowest.
compute_site_grid <- function(revenue_chain) {
  dials <- site_dials(revenue_chain)
  sizes <- vapply(dials, function(d) length(d$levels), integer(1))
  ix <- expand.grid(rev(lapply(sizes, function(s) seq_len(s) - 1L)))
  ix <- ix[, rev(seq_along(sizes)), drop = FALSE]
  names(ix) <- vapply(dials, `[[`, "", "key")
  out <- t(vapply(seq_len(nrow(ix)), function(i) {
    lv <- function(k) dials[[k]]$levels[[ix[i, k] + 1L]]
    cell_outcomes(a = lv(1), b = lv(2), q = lv(3), c_rng = lv(4), r_rng = lv(5),
                  f_spec = lv(6), g = lv(7))
  }, numeric(4)))
  tibble::as_tibble(cbind(ix, out))
}

site_grid_cell <- function(grid, levels) {
  keep <- Reduce(`&`, Map(function(k, v) grid[[k]] == v, names(levels), levels))
  grid[keep, ]
}

# ---- Headline table ---------------------------------------------------------
# Printed values are transcriptions from the PDFs (page = PDF page); every
# other column is computed. The landing page and the deck quote this table,
# and tests/testthat/test-site.R checks the landing page's strings against it.
compute_site_headlines <- function(site_grid, npv_mc_ssrn_summary, npv_mc_nber_summary,
                                    npv_mc_ssrn_analytic_mean, npv_mc_nber_analytic_mean,
                                    revenue_chain, nber_collectible) {
  named <- site_named()
  cell <- function(nm) site_grid_cell(site_grid, as.list(named[[nm]]))
  s <- cell("ssrn"); n <- cell("nber")
  tibble::tribble(
    ~version, ~quantity, ~printed, ~printed_page, ~reproduced, ~reproduced_by, ~grid_exact,
    "ssrn", "revenue_headline", 40, "PDF p.1, p.14", NA_real_, "not computed by the authors' code (paper's rounded judgement, range 35 to 46)", NA_real_,
    "ssrn", "revenue_range_high", 46, "PDF p.14", revenue_chain$literature_calibrated, "revenue_chain$literature_calibrated", NA_real_,
    "ssrn", "mc_mean_npv", -24.7, "PDF p.1, p.20", npv_mc_ssrn_summary$mean, "npv_mc_ssrn_summary (seed 2026, 100,000 draws)", s$mean_npv,
    "ssrn", "mc_median_npv", -19.1, "PDF p.20", npv_mc_ssrn_summary$median, "npv_mc_ssrn_summary", NA_real_,
    "ssrn", "mc_sd_npv", 38.4, "PDF p.20", npv_mc_ssrn_summary$sd, "npv_mc_ssrn_summary", NA_real_,
    "ssrn", "mc_pct_negative", 71, "PDF p.1, p.20", npv_mc_ssrn_summary$pct_negative, "npv_mc_ssrn_summary", s$pct_negative,
    "ssrn", "analytic_mean_npv", NA_real_, NA_character_, npv_mc_ssrn_analytic_mean, "npv_mc_ssrn_analytic_mean", s$mean_npv,
    "ssrn", "mc_expected_revenue", NA_real_, NA_character_, s$wt_collected, "site_grid (E[WT] of the draw)", s$wt_collected,
    "ssrn", "pv_lost", NA_real_, NA_character_, s$pv_lost, "site_grid", s$pv_lost,
    "nber", "revenue_headline", 29.6, "PDF p.23, eq.6 (about $30B, p.1)", nber_collectible$central, "nber_collectible$central", NA_real_,
    "nber", "revenue_range_low", 28.4, "PDF p.23", nber_collectible$lower, "nber_collectible$lower", NA_real_,
    "nber", "revenue_range_high", 35.6, "PDF p.23, eq.7", nber_collectible$upper, "nber_collectible$upper", NA_real_,
    "nber", "mc_mean_npv", -38.9, "PDF p.1, p.35", npv_mc_nber_summary$mean, "npv_mc_nber_summary (seed 2026, 100,000 draws)", n$mean_npv,
    "nber", "mc_median_npv", -35.3, "PDF p.35", npv_mc_nber_summary$median, "npv_mc_nber_summary", NA_real_,
    "nber", "mc_sd_npv", 37.6, "PDF p.35", npv_mc_nber_summary$sd, "npv_mc_nber_summary", NA_real_,
    "nber", "mc_pct_negative", 85.2, "PDF p.35 (figure alt text; 85% in the text)", npv_mc_nber_summary$pct_negative, "npv_mc_nber_summary", n$pct_negative,
    "nber", "analytic_mean_npv", NA_real_, NA_character_, npv_mc_nber_analytic_mean, "npv_mc_nber_analytic_mean", n$mean_npv,
    "nber", "mc_expected_revenue", NA_real_, NA_character_, n$wt_collected, "site_grid (E[WT] of the draw)", n$wt_collected,
    "nber", "pv_lost", NA_real_, NA_character_, n$pv_lost, "site_grid", n$pv_lost
  )
}

# ---- grid.js writer ---------------------------------------------------------
site_grid_payload <- function(site_grid, revenue_chain, site_headlines) {
  dials <- site_dials(revenue_chain)
  named <- site_named()
  outcome_cols <- c("mean_npv", "pct_negative", "wt_collected", "pv_lost")
  hl <- function(v, qn, col) site_headlines[[col]][site_headlines$version == v & site_headlines$quantity == qn]
  pref <- lapply(names(named), function(v) list(
    key = v, label = unname(site_named_labels()[v]),
    printed_npv = hl(v, "mc_mean_npv", "printed"),
    printed_pct_negative = hl(v, "mc_pct_negative", "printed"),
    printed_revenue = hl(v, "revenue_headline", "printed"),
    printed_page = hl(v, "mc_mean_npv", "printed_page"),
    mc_npv = round(hl(v, "mc_mean_npv", "reproduced"), 3),
    mc_pct_negative = round(hl(v, "mc_pct_negative", "reproduced"), 3)
  ))
  list(
    generated_by = "rjkdc-analysis/R/site.R::write_site_grid_js() via targets (target site_grid_js); do not edit by hand",
    dials = lapply(dials, function(d) list(key = d$key, label = d$label, origin = d$origin,
                                           desc = d$desc, labels = d$labels,
                                           levels = seq_along(d$labels) - 1L)),
    outcomes = c("Mean NPV to the state", "Share of outcomes with NPV below zero",
                 "Expected wealth tax collected", "Expected present value of lost income tax"),
    units = c("$B", "%", "$B", "$B"),
    named = lapply(named, function(x) unname(as.integer(x))),
    named_labels = as.list(site_named_labels()),
    preferred = pref,
    snap = unname(lapply(seq_len(nrow(site_grid)), function(i)
      round(unlist(site_grid[i, outcome_cols]), 3)))
  )
}

write_site_grid_js <- function(site_grid, revenue_chain, site_headlines,
                               path = "site/explorer/grid.js") {
  payload <- site_grid_payload(site_grid, revenue_chain, site_headlines)
  json <- jsonlite::toJSON(payload, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(c(
    "/* GENERATED FILE: written by rjkdc-analysis/R/site.R::write_site_grid_js()",
    "   (targets: site_grid_js). Do not edit by hand; tests/testthat/test-site.R",
    "   fails if this file differs from the exporter's own output. */",
    paste0("window.__GRID__ = ", json, ";")
  ), path)
  path
}
