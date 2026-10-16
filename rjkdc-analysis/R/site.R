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
# Each dial carries a one-line definition (desc), a formula symbol (sym), one short tip per
# level (tips, aligned with levels; the explorer appends " Kind: <origin>." to the main
# estimate's level) and the report section that explains it (more, an explicit {#id} in
# site/repro.qmd).
site_dials <- function(revenue_chain) {
  ss <- formals(compute_npv_mc_ssrn)
  nb <- formals(compute_npv_mc_nber)
  f_fixed <- 1 - revenue_chain$confirmed6_ceiling / ss$baseline_revenue
  list(
    list(key = "wt_lo", sym = "WT", label = "Lowest revenue the draw can pick ($B)",
         origin = "guesswork",
         desc = "The bottom of the range the model draws the wealth tax revenue from.",
         tips = c("The NBER script. The 0 stands for the Act struck down and for unreported departures (chapter fn.32).",
                  "The first version's floor (March 2026), a semi-elasticity of 12 to 13.",
                  "The first version's literature-calibrated revenue (March 2026)."),
         more = "step-wt",
         levels = c(nb$wt_min, ss$wt_min, revenue_chain$literature_calibrated),
         labels = c(sprintf("%g", nb$wt_min), sprintf("%g", ss$wt_min), sprintf("%.2f", revenue_chain$literature_calibrated))),
    list(key = "wt_hi", sym = "WT", label = "Highest revenue the draw can pick ($B)",
         origin = "data",
         desc = "The top of the revenue range: what the tax collects after publicly reported departures.",
         tips = c("First version: removes ten reported departures, before growth to the valuation date.",
                  "First version: removes six publicly reported moves, before growth to the valuation date.",
                  "The NBER script: removes seven publicly reported moves, with net worth grown 7% to 31 December 2026 (PDF p.21)."),
         more = "step-wt",
         levels = c(revenue_chain$expanded10_estimate, ss$wt_max, nb$wt_max),
         labels = c(sprintf("%.2f", revenue_chain$expanded10_estimate),
                    sprintf("%.2f", ss$wt_max), sprintf("%g", nb$wt_max))),
    list(key = "q", sym = "q", label = "Extra litigation weight on the revenue",
         origin = "guesswork",
         desc = sprintf("Multiplies the revenue again, on top of the draw's 0 floor, which already halves its mean (%g = 0.5 × %g). The chapter sets q = 0.50 (PDF pp.19-20). The script has no separate multiplier (mismatch 5).",
                        0.5 * nb$wt_max, nb$wt_max),
         tips = c(sprintf("The script. Its 0 revenue floor already halves the mean revenue (%g = 0.5 × %g).",
                          0.5 * nb$wt_max, nb$wt_max),
                  "This OPA's reading. With the 0 floor it counts litigation risk twice, so pair it with the 35 or 45.59 floor.",
                  "This OPA's reading of the paper's q (PDF pp.19-20) as a multiplier. Pair it with the 35 or 45.59 floor."),
         more = "monte-carlo",
         levels = c(1, 0.75, 0.5),
         labels = c("1 (none extra)", "0.75", "0.50")),
    list(key = "c", sym = "C", label = "Billionaires' yearly California income tax ($B)",
         origin = "guesswork",
         desc = "Drawn between the two ends of the authors' income tax simulation (Table 9).",
         tips = c("The authors' draw.",
                  sprintf("This OPA's level: C fixed at %.1f, the billionaires spread at random among the top 500 filers. K = 500 is the authors' judgement.",
                          ss$c_min),
                  sprintf("This OPA's level: C fixed at %.1f, the Pareto upper bound, where the billionaires are the 212 highest earners.",
                          ss$c_max)),
         more = "step-c",
         levels = list(c(ss$c_min, ss$c_max), c(ss$c_min, ss$c_min), c(ss$c_max, ss$c_max)),
         labels = c(sprintf("%.1f to %.1f", ss$c_min, ss$c_max),
                    sprintf("%.1f only", ss$c_min), sprintf("%.1f only", ss$c_max))),
    list(key = "rate", sym = "r − g", label = "Discount rate net of growth",
         origin = "guesswork",
         desc = "The authors draw r − g, the real discount rate net of the growth of the lost tax: $1 a year for ever, growing, is worth 1/(r − g) today.",
         tips = c(sprintf("The authors' draw of r − g. %.1f%% is the S&P 500 dividend yield, their measure of r − g (PDF p.32). The width of the band is their judgement.",
                          100 * ss$r_min),
                  sprintf("This OPA's level: r − g fixed at %.1f%%. $1 a year for ever, growing, is worth about $%.0f today.",
                          100 * ss$r_min, 1 / ss$r_min),
                  sprintf("This OPA's level: r − g fixed at %.1f%%. $1 a year for ever, growing, is worth about $%.0f today.",
                          100 * ss$r_max, 1 / ss$r_max)),
         more = "step-r",
         levels = list(c(ss$r_min, ss$r_max), c(ss$r_min, ss$r_min), c(ss$r_max, ss$r_max)),
         labels = c(sprintf("%.1f%% to %.1f%%", 100 * ss$r_min, 100 * ss$r_max),
                    sprintf("%.1f%% only", 100 * ss$r_min), sprintf("%.1f%% only", 100 * ss$r_max))),
    list(key = "f", sym = "f", label = "Share of the income tax base that leaves",
         origin = "guesswork",
         desc = "Of each dollar of billionaire income tax, the share that leaves with the movers.",
         tips = c("First version: income tax is lost in proportion to wealth lost, so f moves with the revenue draw.",
                  "The NBER script draws f on its own, \"centered conservatively around the observed wealth-base departure fraction\" (PDF p.31).",
                  "First version: the share of the base held by the six billionaires with publicly reported moves."),
         more = "step-f",
         levels = list(list(mode = "implied", baseline = ss$baseline_revenue),
                       list(mode = "uniform", lo = nb$f_min, hi = nb$f_max),
                       list(mode = "fixed", value = f_fixed)),
         labels = c("1 − WT/94.2",
                    sprintf("%.2f to %.2f", nb$f_min, nb$f_max),
                    sprintf("%.3f fixed", f_fixed))),
    list(key = "g", sym = "g", label = "Further growth of the lost income tax",
         origin = "guesswork",
         desc = "Growth beyond what the authors' r − g already nets out: the loss becomes f·C/(r − g − this g).",
         tips = c("None: the authors' draw already nets out growth (r − g).",
                  "This OPA's illustration, not the authors': growth on top of their r − g, so it counts growth twice.",
                  "This OPA's illustration, not the authors': growth on top of their r − g, so it counts growth twice."),
         more = "perpetuity",
         levels = c(0, 0.005, 0.01),
         labels = c("0", "0.5%", "1.0%"))
  )
}

# Named settings (level indices into site_dials()). ssrn and nber are the two printed
# versions; ssrn stays for the pipeline and the report but the explorer does not show it.
# The other three sit on the main (nber) setting: the rate fixed at each end of its draw,
# the two single rates the paper presents with 3.0% (PDF p.32), and this OPA's reading of
# the chapter's q = 0.5 (PDF pp.19-20) as a multiplier, with the 35 revenue floor so the 0
# floor does not count the risk a second time.
site_named <- function() {
  list(
    ssrn = c(wt_lo = 1, wt_hi = 1, q = 0, c = 0, rate = 0, f = 0, g = 0),
    nber = c(wt_lo = 0, wt_hi = 2, q = 0, c = 0, rate = 0, f = 1, g = 0),
    rate15 = c(wt_lo = 0, wt_hi = 2, q = 0, c = 0, rate = 1, f = 1, g = 0),
    rate45 = c(wt_lo = 0, wt_hi = 2, q = 0, c = 0, rate = 2, f = 1, g = 0),
    q50 = c(wt_lo = 1, wt_hi = 2, q = 2, c = 0, rate = 0, f = 1, g = 0)
  )
}

site_named_labels <- function() {
  c(ssrn = "First version, March 2026", nber = "NBER, Sept 2026",
    rate15 = "Rate 1.5%", rate45 = "Rate 4.5%", q50 = "Litigation weight q = 0.5")
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
  # Printed values exist only for the two published versions.
  pref <- lapply(intersect(names(named), unique(site_headlines$version)), function(v) list(
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
    dials = lapply(dials, function(d) list(key = d$key, sym = d$sym, label = d$label, origin = d$origin,
                                           desc = d$desc, tips = d$tips, more = d$more,
                                           labels = d$labels, levels = seq_along(d$labels) - 1L)),
    outcomes = c("Mean NPV, exact average", "Share of outcomes with NPV below zero, exact",
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

# ---- Checks page (site/checks.qmd) ------------------------------------------
# The checks page builds its tables from the explorer's own data file, so it shows the
# values the explorer shows (author answer 2026-10-16, item 23); tests/testthat/test-site.R
# pins the rendered page to this file.
read_site_grid_js <- function(path = "site/explorer/grid.js") {
  js <- readLines(path, warn = FALSE)
  js <- paste(js[grepl("^window.__GRID__", js)], collapse = "")
  jsonlite::fromJSON(sub(";\\s*$", "", sub("^window.__GRID__ = ", "", js)), simplifyVector = FALSE)
}

# One cell of grid.js: `changes` (named level indices) applied to the named setting `from`,
# found in the same mixed-radix order as the explorer's idx() (the last dial varies fastest).
site_grid_js_cell <- function(G, changes = integer(0), from = "nber") {
  keys <- vapply(G$dials, `[[`, "", "key")
  lv <- setNames(unlist(G$named[[from]]), keys)
  lv[names(changes)] <- changes
  sizes <- vapply(G$dials, function(d) length(d$labels), integer(1))
  i <- 0L
  for (k in seq_along(lv)) i <- i * sizes[k] + lv[[k]]
  setNames(unlist(G$snap[[i + 1L]]), c("mean_npv", "pct_negative", "wt_collected", "pv_lost"))
}

# The settings the papers do not print, each made from the main (NBER) setting. The litigation
# weight comes as the explorer's paired setting (q = 0.5 with the 35 floor, site_named()$q50),
# because with the 0 floor it counts the risk twice (author answer 2026-10-16, item 2). Row
# text is built from the dials' own labels, so no value is typed here.
site_checks_settings <- function(G) {
  d <- setNames(G$dials, vapply(G$dials, `[[`, "", "key"))
  lab <- function(k, i) sub(" (only|fixed)$", "", d[[k]]$labels[[i + 1L]])
  usd <- function(x) if (x == "0") "$0" else paste0("$", x, "B")
  main <- setNames(unlist(G$named$nber), names(d))
  at_main <- function(k) d[[k]]$labels[[main[[k]] + 1L]]
  q50 <- setNames(unlist(G$named$q50), names(d))
  q50 <- q50[q50 != main]
  stopifnot(setequal(names(q50), c("q", "wt_lo")))
  list(
    list(text = "None, the main assumptions, for reference", changes = integer(0)),
    list(text = sprintf("r − g, the discount rate net of growth, fixed at %s (instead of drawn from %s)",
                        lab("rate", 1), at_main("rate")), changes = c(rate = 1L)),
    list(text = sprintf("r − g, the discount rate net of growth, fixed at %s", lab("rate", 2)),
         changes = c(rate = 2L)),
    list(text = sprintf("Revenue multiplied by a chance of surviving in court of %s, with the lowest revenue the draw can pick raised to %s (instead of %s) so the risk is not counted twice (the explorer's \"%s\")",
                        d$q$labels[[q50[["q"]] + 1L]], usd(lab("wt_lo", q50[["wt_lo"]])), usd(at_main("wt_lo")),
                        G$named_labels$q50),
         changes = q50),
    list(text = sprintf("Yearly income tax fixed at $%sB (instead of drawn from $%sB)",
                        lab("c", 1), sub(" to ", "B to $", at_main("c"))), changes = c(c = 1L)),
    list(text = sprintf("Yearly income tax fixed at $%sB", lab("c", 2)), changes = c(c = 2L)),
    list(text = sprintf("Lost income tax grows a further %s a year on top of the authors' r − g (this OPA's illustration)",
                        lab("g", 1)), changes = c(g = 1L)),
    list(text = sprintf("Lost income tax grows a further %s a year on top of the authors' r − g (this OPA's illustration)",
                        sub("[.]0%$", "%", lab("g", 2))), changes = c(g = 2L)),
    list(text = sprintf("Lowest revenue the draw can pick of %s (instead of %s)",
                        usd(lab("wt_lo", 1)), usd(at_main("wt_lo"))), changes = c(wt_lo = 1L)),
    list(text = sprintf("Share of the income tax base that leaves fixed at %s (instead of drawn from %s)",
                        lab("f", 2), at_main("f")), changes = c(f = 2L))
  )
}

# The table of those settings: the mean NPV and the share below zero of each, from grid.js.
site_checks_table <- function(G) {
  s <- site_checks_settings(G)
  do.call(rbind, lapply(s, function(x) {
    v <- site_grid_js_cell(G, x$changes)
    data.frame(setting = x$text, mean_npv = v[["mean_npv"]], pct_negative = v[["pct_negative"]],
               stringsAsFactors = FALSE)
  }))
}
