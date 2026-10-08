# Computation layer.
#
# Re-derives the workbook's Tab5 sheet (the one-time 5% CA wealth tax, four
# scenarios) from its upstream inputs; the test suite asserts the output
# matches the Excel extraction within a documented tolerance.
#
# One estimating function, two users. score_tab5_cell() estimates revenue at
# ONE setting of every guesswork input. compute_tab5() is the reproduction: the workbook's four rows
# are score_tab5_cell() at the workbook's own values. The explorer
# (R/site_exports.R) calls the same function at other values, so the published
# tool cannot drift from the reproduction.
#
# Two readings the workbook leaves implicit, both documented on the site:
#  1. Mobility share. Tab5!H6 is the literal "-0.05 * Tab2!C14". The row label
#     reads "10% evasion/avoidance (half due to mobility)" and the paper says
#     "half of the 10% avoidance takes the form of mobility" (PDF p.24), so the
#     function reads 0.05 as avoidance x mobility share (0.10 x 0.5). At the
#     workbook's own values this equals the literal 0.05 (which also equals the
#     tax rate; an earlier version of this file used the tax rate there).
#  2. Row 4 phase-in. Tab5!F7 (row 2) subtracts the $1B-1.1B phase-in
#     deduction; Tab5!F9 (row 4, rows 2+3 combined) does not. The function keeps
#     the workbook's literal behaviour; the site reports the size of the gap.

# ---- the fixed inputs the estimate needs, taken from the pipeline --------

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
    leaver_loss = sum(pre_loss) + sum(post_loss),
    # what row 4 would lose if it applied row 2's phase-in deduction (Tab5!F7 vs F9)
    row4_phasein_gap = W0 * pareto$pct_wealth_increase * pareto$fraction_in_phasein * 0.025
  )
}

# ---- the generalised Table 5 estimating function ------------------------

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

# ---- the reproduction: the workbook's four rows -----------------------------

compute_tab5 <- function(pareto_missing_r, tab2, tab3,
                         avoidance_rate    = 0.10,
                         avoidance_small   = 0.20,
                         wealth_tax_rate   = 0.05,
                         phasein_rate      = 0.025,
                         realization_share = 1/3,
                         ltcg_taxable      = 0.80,
                         ca_ltcg_rate      = 0.133) {
  # Tab5's four scenarios:
  #   1. Benchmark (Forbes snapshot + 10% avoidance)
  #   2. Benchmark + Pareto extrapolation for missing $1-4.5B billionaires
  #   3. Benchmark + aggressive pre/post-2026 leaver assumption (Tab5 rows 20-29)
  #   4. Both 2 and 3 combined
  inp <- tab5_scoring_inputs(pareto_missing_r, tab2, tab3)
  cell <- function(pareto, leavers) score_tab5_cell(
    inp, avoidance = avoidance_rate, mobility_share = 0.50,
    avoidance_small = avoidance_small, sell_share = realization_share,
    pareto = pareto, leavers = leavers, tax_rate = wealth_tax_rate,
    phasein_rate = phasein_rate, gains_share = ltcg_taxable, ca_cg_rate = ca_ltcg_rate)
  rows <- rbind(cell(FALSE, FALSE), cell(TRUE, FALSE), cell(FALSE, TRUE), cell(TRUE, TRUE))
  tibble::tibble(
    scenario              = paste0("Scenario ", 1:4),
    n_billionaires        = unname(rows[, "n_billionaires"]),
    wealth                = unname(rows[, "wealth"]),
    taxable_wealth        = unname(rows[, "taxable_wealth"]),
    avoidance_rate        = unname(rows[, "avoidance_rate"]),
    wealth_tax_revenue    = unname(rows[, "wealth_tax_revenue"]),
    extra_ca_inctax_sales = unname(rows[, "extra_ca_inctax_sales"]),
    annual_ca_inctax_loss = unname(rows[, "annual_ca_inctax_loss"])
  )
}
