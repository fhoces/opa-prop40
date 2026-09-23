# Site exports: the data files behind the public OPA pages in site/.
#
# Nothing here changes a reproduced number. compute_tab5() (R/compute_tab5.R)
# remains the reproduction of the workbook's Tab5 sheet; this file adds a
# GENERALISED scorer, score_tab5_cell(), whose every guesswork input is an
# argument, so the explorer can move one input at a time. At the workbook's
# own input values it must return compute_tab5()'s four rows exactly; that is
# pinned by tests/testthat/test-site.R, so the explorer cannot drift from the
# reproduction.
#
# Two readings the workbook leaves implicit, both documented on the site:
#  1. Mobility share. Tab5!H6 is the literal "-0.05 * Tab2!C14". The row label
#     reads "10% evasion/avoidance (half due to mobility)" and the paper says
#     "half of the 10% avoidance takes the form of mobility" (PDF p.24), so we
#     read 0.05 as avoidance x mobility share (0.10 x 0.5). compute_tab5()
#     happens to use wealth_tax_rate (also 0.05) there; the two coincide only
#     at the workbook's own values.
#  2. Row 4 phase-in. Tab5!F7 (row 2) subtracts the $1B-1.1B phase-in
#     deduction; Tab5!F9 (row 4, rows 2+3 combined) does not. We keep the
#     workbook's literal behaviour and report the size of the gap.

# ---- the fixed inputs the scorer needs, taken from the pipeline ----------

tab5_scoring_inputs <- function(pareto_missing_r, tab2, tab3) {
  pareto   <- compute_pareto_summary(pareto_missing_r)
  avg_row  <- tab2[grepl("^2019.*average", tab2$year), ]
  avg_tax  <- tab3[grepl("^Average", tab3$metric), ]
  C        <- avg_row$ca_inctax_estimated                     # Tab2!C14, $B/yr

  W0 <- tab5_const("baseline_wealth"); n0 <- tab5_const("baseline_n")
  top4_wealth  <- tab5_const("page_wealth_B") + tab5_const("brin_wealth_B") +
                  tab5_const("zuck_wealth_B") + tab5_const("huang_wealth_B")
  top4_private <- tab5_const("page_private_B") + tab5_const("brin_private_B") +
                  tab5_const("zuck_private_B") + tab5_const("huang_private_B")
  # income tax per $ of wealth outside the top 4's company wealth (Tab5!F18/B18)
  resid_rate <- (C - avg_tax$all_top4 / 1000) / (W0 - (top4_wealth - top4_private))

  pre_names  <- c("page", "thiel", "hankey", "kalanick")
  pre_wealth <- c(tab5_const("page_wealth_B"), tab5_const("thiel_wealth_B"),
                  tab5_const("hankey_wealth_B"), tab5_const("kalanick_wealth_B"))
  pre_loss   <- c(avg_tax$page / 1000 + tab5_const("page_private_B") * resid_rate,
                  pre_wealth[2:4] * resid_rate)
  post_names <- c("brin", "zuckerberg", "fang")
  post_wealth <- c(tab5_const("brin_wealth_B"), tab5_const("zuck_wealth_B"),
                   tab5_const("fang_wealth_B"))
  post_loss  <- c(avg_tax$brin / 1000 + tab5_const("brin_private_B") * resid_rate,
                  avg_tax$zuckerberg / 1000 + tab5_const("zuck_private_B") * resid_rate,
                  tab5_const("fang_wealth_B") * resid_rate)

  list(
    vintage             = bsz_vintage(),
    n0                  = n0,
    W0                  = W0,
    C                   = C,
    pct_wealth_increase = pareto$pct_wealth_increase,
    pct_count_increase  = pareto$pct_count_increase,
    fraction_in_phasein = pareto$fraction_in_phasein,
    pareto_b            = pareto$pareto_b,
    pareto_extra_n      = pareto$total_count_proj - pareto$total_count_emp,
    pareto_extra_wealth = pareto$total_wealth_proj - pareto$total_wealth_emp,
    resid_rate          = resid_rate,
    leavers = tibble::tibble(
      name   = c(pre_names, post_names),
      timing = c(rep("pre-2026 (escapes the wealth tax)", 4),
                 rep("post-2026 (pays it, then leaves)", 3)),
      wealth = c(pre_wealth, post_wealth),
      annual_inctax_loss = c(pre_loss, post_loss)
    ),
    W_pre       = sum(pre_wealth),
    leaver_loss = sum(pre_loss) + sum(post_loss)
  )
}

# ---- the generalised Table 5 scorer --------------------------------------

score_tab5_cell <- function(inp,
                            avoidance      = 0.10,  # alpha: benchmark avoidance/evasion
                            mobility_share = 0.50,  # share of alpha that is people leaving
                            avoidance_small = 0.20, # alpha for Pareto-added billionaires
                            sell_share     = 1/3,   # share of the tax paid by selling assets
                            pareto         = FALSE, # add the Pareto-missing billionaires
                            leavers        = FALSE, # aggressive leaver assumption
                            tax_rate       = 0.05,
                            phasein_rate   = 0.025,
                            gains_share    = 0.80,
                            ca_cg_rate     = 0.133) {
  pw <- if (pareto) inp$pct_wealth_increase else 0
  W  <- inp$W0 * (1 + pw)
  n  <- inp$n0 * (if (pareto) 1 + inp$pct_count_increase else 1)
  taxable <- (1 - avoidance) * (inp$W0 - if (leavers) inp$W_pre else 0) +
             (1 - avoidance_small) * inp$W0 * pw
  # Row 2 subtracts the phase-in deduction; row 4 (pareto AND leavers) does not
  # (Tab5!F9). Literal workbook behaviour, see the header note.
  phasein <- if (pareto && !leavers) inp$W0 * pw * inp$fraction_in_phasein * phasein_rate else 0
  revenue <- tax_rate * taxable - phasein
  extra   <- revenue * sell_share * gains_share * ca_cg_rate
  loss    <- -(avoidance * mobility_share) * inp$C * (1 + pw) -
             (if (leavers) inp$leaver_loss else 0)
  c(n_billionaires        = n,
    wealth                = W,
    taxable_wealth        = taxable,
    avoidance_rate        = 1 - taxable / W,
    wealth_tax_revenue    = revenue,
    extra_ca_inctax_sales = extra,
    annual_ca_inctax_loss = loss)
}

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
    "Row 1: benchmark"             = c(3L, 3L, 2L, 2L, 1L, 1L),
    "Row 2: + missing billionaires" = c(3L, 3L, 2L, 2L, 2L, 1L),
    "Row 3: + aggressive leavers"  = c(3L, 3L, 2L, 2L, 1L, 2L),
    "Row 4: rows 2 and 3"          = c(3L, 3L, 2L, 2L, 2L, 2L)
  )
}

site_outcomes <- function() {
  tibble::tribble(
    ~key,                    ~label,                                   ~unit,
    "wealth_tax_revenue",    "Wealth tax revenue (one-time)",          "$B",
    "extra_ca_inctax_sales", "Extra CA income tax from asset sales",   "$B",
    "annual_ca_inctax_loss", "Annual CA income tax lost to leavers",   "$B/yr",
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
    c(cell = i, stats::setNames(v, names(idx)), out)
  })
  tibble::as_tibble(as.data.frame(do.call(rbind, rows)))
}

# Every input of the one-time scoring, with its value and origin label.
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
      "The Act values wealth at 31 Dec 2026; BSZ and GGSS score on the latest Forbes snapshot."
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
    preferred = "Row 1: benchmark",
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
