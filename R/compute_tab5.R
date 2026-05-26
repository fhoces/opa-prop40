# Phase 2 computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the Phase-1 Excel extraction within a
# documented tolerance.

compute_tab5 <- function(pareto_missing_r, tab2, tab3,
                         baseline_n        = 249,
                         baseline_wealth   = 2182,
                         avoidance_rate    = 0.10,
                         avoidance_small   = 0.20,
                         wealth_tax_rate   = 0.05,
                         phasein_rate      = 0.025,
                         realization_share = 1/3,
                         ltcg_taxable      = 0.80,
                         ca_ltcg_rate      = 0.133) {
  # Replicates Tab5: 4 scenarios for the one-time 5% CA wealth tax.
  #   1. Benchmark (Forbes 4/15/2026 + 10% avoidance)
  #   2. Benchmark + Pareto extrapolation for missing $1-4.5B billionaires
  #   3. Benchmark + aggressive pre/post-2026 leaver assumption
  #   4. Both 2 and 3 combined
  pareto <- compute_pareto_summary(pareto_missing_r)

  # Inputs from Tab2 (2019-2025 average row, col C):
  #   tab2 row "2019-2025 average" -> ca_inctax_estimated = $3.03B/yr
  avg_row <- tab2[grepl("^2019.*average", tab2$year), ]
  ca_inctax_avg <- avg_row$ca_inctax_estimated         # Tab2!C14

  # Inputs from Tab3 (averages of CA income tax for top 4, in $M):
  avg_metric_row <- tab3[grepl("^Average", tab3$metric), ]
  # Inputs from Tab3 (Wealth at end of 2025, in $M):
  wealth_end_row <- tab3[grepl("^Wealth at end", tab3$metric), ]

  # Scenario 3 leaver block (hard-coded wealth + private-wealth values from
  # Tab5 rows 20-29). Pre-2026 leavers: Page, Thiel, Hankey, Kalanick.
  # Post-2026 leavers: Brin, Zuckerberg, Andy Fang.
  page_avg_tax_M    <- avg_metric_row$page              # Tab3!$B$13
  brin_avg_tax_M    <- avg_metric_row$brin              # Tab3!$C$13
  zuck_avg_tax_M    <- avg_metric_row$zuckerberg        # Tab3!$D$13
  top4_avg_tax_M    <- avg_metric_row$all_top4          # Tab3!F13

  # Top-4 wealth breakouts hardcoded in Tab5 row 30 (in $B):
  page_wealth_B  <- 276;   page_private_B  <- 13.4
  brin_wealth_B  <- 254.6; brin_private_B  <- 13.2
  zuck_wealth_B  <- 230.2; zuck_private_B  <- 2.5
  huang_wealth_B <- 172;   huang_private_B <- 2.84
  top4_wealth_B  <- page_wealth_B + brin_wealth_B + zuck_wealth_B + huang_wealth_B
  top4_private_B <- page_private_B + brin_private_B + zuck_private_B + huang_private_B

  # Wealth and CA income tax denominators used to apportion the leaver CA
  # income tax loss by wealth share (Tab5 rows 17-18):
  total_wealth_all_b        <- baseline_wealth
  avg_ca_inctax_all_b       <- ca_inctax_avg
  wealth_excl_top4_company  <- total_wealth_all_b - (top4_wealth_B - top4_private_B)
  ca_inctax_excl_top4       <- avg_ca_inctax_all_b - top4_avg_tax_M / 1000
  inctax_per_wealth_residual <- ca_inctax_excl_top4 / wealth_excl_top4_company

  # Pre-2026 leavers (Page, Thiel, Hankey, Kalanick) — Tab5 rows 20-23.
  # Page contributes company-tax + private-wealth share; the other three
  # contribute private-wealth share only (apportioned from residual rate).
  thiel_wealth_B    <- 28.9
  hankey_wealth_B   <- 8.15
  kalanick_wealth_B <- 3.56
  ca_inctax_loss_pre2026 <-
      (page_avg_tax_M / 1000) + page_private_B * inctax_per_wealth_residual +
      (thiel_wealth_B + hankey_wealth_B + kalanick_wealth_B) * inctax_per_wealth_residual

  # Post-2026 leavers (Brin, Zuckerberg, Andy Fang) — Tab5 rows 25-27.
  fang_wealth_B <- 1.5
  ca_inctax_loss_post2026 <-
      (brin_avg_tax_M / 1000) + brin_private_B * inctax_per_wealth_residual +
      (zuck_avg_tax_M / 1000) + zuck_private_B * inctax_per_wealth_residual +
      fang_wealth_B * inctax_per_wealth_residual

  total_leaver_inctax_loss <- ca_inctax_loss_pre2026 + ca_inctax_loss_post2026
  wealth_pre2026_leavers   <- page_wealth_B + thiel_wealth_B + hankey_wealth_B + kalanick_wealth_B

  # Scenario engine: given a scenario's wealth + taxable wealth + the
  # baseline-inctax denominator + optional adjustments, compute the 7 result
  # columns. Avoidance rate is derived as (1 - taxable/wealth).
  scenario_revenue <- function(n, wealth, taxable_wealth,
                                baseline_inctax_effective,
                                phasein_deduction = 0,
                                extra_inctax_loss = 0) {
    avoidance        <- 1 - taxable_wealth / wealth
    wealth_tax_rev   <- taxable_wealth * wealth_tax_rate - phasein_deduction
    extra_inctax     <- wealth_tax_rev * realization_share * ltcg_taxable * ca_ltcg_rate
    annual_loss      <- -wealth_tax_rate * baseline_inctax_effective - extra_inctax_loss
    c(n              = n,
      wealth         = wealth,
      taxable_wealth = taxable_wealth,
      avoidance_rate = avoidance,
      wealth_tax_rev = wealth_tax_rev,
      extra_inctax   = extra_inctax,
      annual_loss    = annual_loss)
  }

  # --- Scenario 1: Benchmark (Forbes 4/15/2026 + 10% avoidance) ---
  s1 <- scenario_revenue(
    n                          = baseline_n,
    wealth                     = baseline_wealth,
    taxable_wealth             = baseline_wealth * (1 - avoidance_rate),
    baseline_inctax_effective  = ca_inctax_avg
  )

  # --- Scenario 2: + Pareto-missing small billionaires ---
  wealth_2 <- baseline_wealth * (1 + pareto$pct_wealth_increase)
  s2 <- scenario_revenue(
    n                          = baseline_n * (1 + pareto$pct_count_increase),
    wealth                     = wealth_2,
    taxable_wealth             = baseline_wealth *
        ((1 - avoidance_rate) + (1 - avoidance_small) * pareto$pct_wealth_increase),
    baseline_inctax_effective  = ca_inctax_avg * (1 + pareto$pct_wealth_increase),
    phasein_deduction          = (wealth_2 - baseline_wealth) *
        pareto$fraction_in_phasein * phasein_rate
  )

  # --- Scenario 3: + Aggressive pre/post-2026 leavers ---
  s3 <- scenario_revenue(
    n                          = baseline_n,
    wealth                     = baseline_wealth,
    taxable_wealth             = 0.9 * (baseline_wealth - wealth_pre2026_leavers),
    baseline_inctax_effective  = ca_inctax_avg,
    extra_inctax_loss          = total_leaver_inctax_loss
  )

  # --- Scenario 4: scenarios 2 and 3 combined ---
  s4 <- scenario_revenue(
    n                          = s2[["n"]],
    wealth                     = s3[["wealth"]] + (s2[["wealth"]] - baseline_wealth),
    taxable_wealth             = s3[["taxable_wealth"]] +
                                  (s2[["taxable_wealth"]] - s1[["taxable_wealth"]]),
    baseline_inctax_effective  = ca_inctax_avg * (1 + pareto$pct_wealth_increase),
    extra_inctax_loss          = total_leaver_inctax_loss
  )

  rows <- rbind(s1, s2, s3, s4)
  tibble::tibble(
    scenario              = paste0("Scenario ", 1:4),
    n_billionaires        = unname(rows[, "n"]),
    wealth                = unname(rows[, "wealth"]),
    taxable_wealth        = unname(rows[, "taxable_wealth"]),
    avoidance_rate        = unname(rows[, "avoidance_rate"]),
    wealth_tax_revenue    = unname(rows[, "wealth_tax_rev"]),
    extra_ca_inctax_sales = unname(rows[, "extra_inctax"]),
    annual_ca_inctax_loss = unname(rows[, "annual_loss"])
  )
}
