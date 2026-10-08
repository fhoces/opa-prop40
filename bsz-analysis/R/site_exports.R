# Site exports: the data files behind the public OPA pages in site/.
#
# Nothing here changes a reproduced number. The explorer's grid is computed by
# score_tab5_cell() in R/compute_tab5.R, the SAME function compute_tab5() uses
# to reproduce the workbook's Tab5 sheet: this file only chooses which input
# values to feed it (the dials) and writes the results out. The two implicit
# readings of the workbook the explorer exposes (the mobility share, row 4's
# phase-in) are documented in R/compute_tab5.R.

# ---- the explorer's dials: exactly the inputs the report labels guesswork,
# plus the two scenario rows Table 5 itself varies -------------------------

site_dials <- function() {
  list(
    list(key = "avoidance", label = "Avoidance and evasion", sym = "α",
         origin = "guesswork",
         desc = "Share of listed wealth that escapes the tax. GGSS p.4: \"a relatively small avoidance rate of 10%\", argued from enforcement, not estimated.",
         levels = c(0, 0.05, 0.10, 0.15, 0.20, 0.30), default = 3L, fmt = "pct"),
    list(key = "mobility_share", label = "Share of avoidance that is leaving", sym = "m",
         origin = "guesswork",
         desc = "Only this part costs income tax. BSZ PDF p.24: \"If we assume that half of the 10% avoidance takes the form of mobility\".",
         levels = c(0, 0.25, 0.50, 0.75, 1), default = 3L, fmt = "pct"),
    list(key = "avoidance_small", label = "Avoidance by the less visible billionaires", sym = "αₛ",
         origin = "guesswork",
         desc = "Applies only when the Pareto-missing billionaires are counted. BSZ PDF p.25: \"Assuming a higher evasion rate of 20%\".",
         levels = c(0.10, 0.20, 0.30, 0.50), default = 2L, fmt = "pct"),
    list(key = "sell_share", label = "Share of the tax paid by selling assets", sym = "s",
         origin = "guesswork",
         desc = "Sales realise capital gains, which raise extra CA income tax. BSZ PDF p.24: \"paid one-third by selling assets\".",
         levels = c(0, 1/3, 2/3, 1), default = 2L, fmt = "frac3"),
    list(key = "pareto", label = "Count billionaires Forbes misses", sym = "P",
         origin = "research",
         desc = "Pareto extrapolation of the $1B-4.5B range (Table 5 rows 2 and 4). BSZ PDF pp.24-25 and Appendix Figure A4.",
         levels = c(0, 1), default = 1L, fmt = "bool"),
    list(key = "leavers", label = "Aggressive assumption on leavers", sym = "L",
         origin = "guesswork",
         desc = "Page, Thiel, Hankey, Kalanick escape the tax; Brin, Zuckerberg, Fang leave later (Table 5 rows 3 and 4). A legal judgment on residency, BSZ PDF p.26.",
         levels = c(0, 1), default = 1L, fmt = "bool")
  )
}

# The four Table 5 rows as dial settings (1-based level indices).
site_named_rows <- function() {
  list(
    "Base"                 = c(3L, 3L, 2L, 2L, 1L, 1L),   # Table 5 row 1
    "Missing billionaires" = c(3L, 3L, 2L, 2L, 2L, 1L),   # Table 5 row 2
    "Leavers"              = c(3L, 3L, 2L, 2L, 1L, 2L),   # Table 5 row 3
    "Missing + leavers"    = c(3L, 3L, 2L, 2L, 2L, 2L)    # Table 5 row 4
  )
}

# The main estimate: the one-time wealth tax, plus the one-time extra income tax from
# selling assets, minus the present value of the yearly income tax lost to leavers over
# BSZ's horizon of about 5 years (PDF p.27), discounted at 3% a year (the middle of the
# 1.5%-4.5% range the RJKDC report uses; BSZ give no rate). Same definition as the deck.
site_pv_rate  <- 0.03
site_pv_years <- 5
site_pv_factor <- function(r = site_pv_rate, H = site_pv_years) (1 - (1 + r)^(-H)) / r

site_outcomes <- function() {
  tibble::tribble(
    ~key,                    ~label,                                   ~unit,
    "main_estimate",         "Main estimate (net)",                    "$B",
    "wealth_tax_revenue",    "Wealth tax revenue (one-time)",          "$B",
    "extra_ca_inctax_sales", "Extra CA income tax from asset sales",   "$B",
    "income_tax_loss_pv",    "Income tax lost to leavers, present value (5 years at 3%)", "$B",
    "annual_ca_inctax_loss", "Income tax lost to leavers, per year",   "$B/yr",
    "taxable_wealth",        "Taxable wealth after avoidance",         "$B",
    "wealth",                "Wealth of CA billionaires",              "$B",
    "n_billionaires",        "Number of billionaires",                 "count",
    "avoidance_rate",        "Overall avoidance rate",                 "share"
  )
}

# Every cell of the dial grid, in itertools.product order (first dial slowest).
build_site_grid <- function(inp) {
  dials <- site_dials()
  idx <- rev(expand.grid(rev(lapply(dials, function(d) seq_along(d$levels)))))
  names(idx) <- vapply(dials, `[[`, "", "key")
  rows <- lapply(seq_len(nrow(idx)), function(i) {
    v <- mapply(function(d, j) d$levels[j], dials, as.integer(idx[i, ]))
    out <- score_tab5_cell(inp,
                           avoidance = v[[1]], mobility_share = v[[2]],
                           avoidance_small = v[[3]], sell_share = v[[4]],
                           pareto = v[[5]] == 1, leavers = v[[6]] == 1)
    loss_pv <- out[["annual_ca_inctax_loss"]] * site_pv_factor()
    c(cell = i, stats::setNames(v, names(idx)), out,
      income_tax_loss_pv = loss_pv,
      main_estimate = out[["wealth_tax_revenue"]] + out[["extra_ca_inctax_sales"]] + loss_pv)
  })
  tibble::as_tibble(as.data.frame(do.call(rbind, rows)))
}

# Every input of the one-time estimate, with its value and origin label.
build_site_inputs <- function(inp) {
  lv <- inp$leavers
  tibble::tribble(
    ~symbol, ~input, ~value, ~origin, ~basis,
    "τ", "Wealth tax rate", "5% one-time", "scenario",
      "The Act as written: 5%, payable 1%/yr over 5 years (GGSS p.1).",
    "W₀", "Wealth of CA billionaires, 1 Jul 2026",
      sprintf("$%s B", format(inp$W0, big.mark = ",")), "data",
      "Forbes real-time list, 7/1/2026 (Tab5!C6; BSZ PDF p.24).",
    "n₀", "Number of CA billionaires, 1 Jul 2026", as.character(inp$n0), "data",
      "Forbes real-time list, 7/1/2026 (Tab5!B6).",
    "α", "Avoidance and evasion", "10%", "guesswork",
      "Asserted, argued from enforcement (GGSS p.4; BSZ PDF p.23). Explorer dial.",
    "m", "Share of avoidance that is leaving", "50%", "guesswork",
      "Asserted (BSZ PDF p.24; Tab5 row 1 label). Explorer dial.",
    "αₛ", "Avoidance, less visible billionaires", "20%", "guesswork",
      "Asserted (BSZ PDF p.25). Explorer dial.",
    "s", "Share of the tax paid by selling assets", "1/3", "guesswork",
      "Asserted (BSZ PDF p.24). Explorer dial.",
    "L", "Who left before 1 Jan 2026 (Table 5 rows 3 and 4)", "no one (row 1)", "guesswork",
      "A legal judgment on residency; rows 3-4 assume Page, Thiel, Hankey, Kalanick (BSZ PDF p.26). Explorer dial.",
    "g", "Capital-gain share of a sale", "80%", "research",
      "BSZ's own estimate that CA billionaire wealth is 80% unrealized gains (PDF p.24).",
    "t_cg", "Top CA income tax rate on gains", "13.3%", "data",
      "California statute, top marginal rate (Tab5!G6).",
    "C", "CA income tax paid by billionaires, 2019-2025 average",
      sprintf("$%.2f B/yr", inp$C), "research",
      "BSZ's own FTB + Pareto estimate (Tab2!C14; Table 2 of the paper), reproduced in this pipeline.",
    "b", "Pareto coefficient above $4.5B", sprintf("%.2f", inp$pareto_b), "research",
      "Estimated from Forbes 4/15/2026 (Pareto-missing sheet; BSZ PDF p.25).",
    "ΔW_P", "Wealth added by the Pareto extrapolation",
      sprintf("+%.1f%%", 100 * inp$pct_wealth_increase), "research",
      "Pareto-missing!I23, derived from b.",
    "Δn_P", "Billionaires added by the Pareto extrapolation",
      sprintf("+%.0f%%", 100 * inp$pct_count_increase), "research",
      "Pareto-missing!J23, derived from b.",
    "f_ph", "Share of added wealth in the $1B-1.1B phase-in",
      sprintf("%.1f%%", 100 * inp$fraction_in_phasein), "derived",
      "Pareto-missing!I24, derived from b.",
    "W_pre", "Wealth of pre-2026 leavers (Page, Thiel, Hankey, Kalanick)",
      sprintf("$%.1f B", inp$W_pre), "data",
      "Forbes 7/1/2026 values typed into Tab5!B20:B23.",
    "L_lv", "Annual CA income tax of all seven named leavers",
      sprintf("$%.2f B/yr", inp$leaver_loss), "derived",
      "Top-3 company income tax from SEC data (Tab3 row 13) plus a wealth-proportional rate on the rest (Tab5!F19+F24).",
    "date", "Valuation date", "1 Jul 2026", "convention",
      "The Act values wealth at 31 Dec 2026; BSZ and GGSS estimate on the latest Forbes snapshot."
  )
}

# ---- writers --------------------------------------------------------------

site_dir <- function(...) file.path(project_root(), "site", ...)

write_site_csv <- function(df, rel) {
  path <- site_dir(rel)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(df, path, row.names = FALSE, fileEncoding = "UTF-8")
  path
}

# grid.js is the explorer's only data source. Its text is a pure function of
# site_grid + the dial metadata, so tests can regenerate it and compare.
site_grid_js_text <- function(grid, inp) {
  dials <- site_dials()
  outs  <- site_outcomes()
  named <- lapply(site_named_rows(), function(v) v - 1L)
  snap  <- lapply(seq_len(nrow(grid)), function(i)
    unname(round(as.numeric(grid[i, outs$key]), 6)))
  payload <- list(
    source  = paste0("Generated by write_site_grid_js() in R/site_exports.R from the ",
                     "targets pipeline (BSZ workbook, ", inp$vintage, " vintage). Do not edit."),
    vintage = inp$vintage,
    dials   = lapply(dials, function(d) d[c("key", "label", "sym", "origin", "desc", "levels", "fmt")]),
    outcomes = outs$label,
    keys     = outs$key,
    units    = outs$unit,
    named    = named,
    preferred = "Base",
    facts    = list(W0 = inp$W0, n0 = inp$n0, C = round(inp$C, 6),
                    pv_rate = site_pv_rate, pv_years = site_pv_years,
                    row4_phasein_gap = round(inp$row4_phasein_gap, 6)),
    snap     = snap
  )
  json <- jsonlite::toJSON(payload, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  paste0("/* Generated file: do not edit. See R/site_exports.R. */\n",
         "window.__GRID__ = ", json, ";\n")
}

write_site_grid_js <- function(grid, inp) {
  path <- site_dir("explorer", "grid.js")
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  # Raw UTF-8 bytes, exactly the text (writeLines would add a second newline).
  writeBin(charToRaw(enc2utf8(site_grid_js_text(grid, inp))), path)
  path
}

# ---- Table 5 as printed in the paper ---------------------------------------
# Transcribed from BSZ (August 2026) PDF p.39, with the number of decimals the
# paper prints. Used to count cells that match the printed digit, which is a
# stricter test than matching the workbook's cached value.
bsz_tab5_printed <- function() {
  tibble::tibble(
    column = rep(c("n_billionaires", "wealth", "taxable_wealth", "avoidance_rate",
                   "wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss"), 4),
    row    = rep(1:4, each = 7),
    printed = c(250, 2307, 2076, 10.0, 104, 3.7, -0.15,
                620, 2957, 2597, 12.2, 128, 4.5, -0.19,
                250, 2307, 1776, 23.0,  89, 3.1, -0.51,
                620, 2957, 2296, 22.4, 115, 4.1, -0.56),
    digits = rep(c(0, 0, 0, 1, 0, 1, 2), 4),
    scale  = rep(c(1, 1, 1, 100, 1, 1, 1), 4)
  )
}

# One row per Table 5 cell: reproduced value, printed value, and whether the
# reproduced value rounds to the printed digit.
compare_tab5_printed <- function(tab5_r) {
  p <- bsz_tab5_printed()
  p$reproduced <- mapply(function(col, r, sc) tab5_r[[col]][r] * sc, p$column, p$row, p$scale)
  p$matches_printed <- round(p$reproduced, p$digits) == p$printed
  p
}
