# Phase 2 - computation layer.
#
# Each function here re-derives an Excel sheet from its upstream inputs in R.
# The test suite asserts the R output matches the Phase-1 Excel extraction
# within a small tolerance (default 1e-2 in $B = $10M, since Excel rounds
# many displayed values to two decimal places).

# Ellison was a CA resident only through ~mid-2023 per Forbes (paper note 2);
# he is excluded from all CA-billionaire aggregates throughout the panel.
ELLISON_FORBES_ID <- "larry-ellison"

compute_pareto_missing <- function(pareto_inputs,
                                   anchor_threshold = 4.5) {
  # Inputs (columns A, B, C of the Pareto-missing sheet):
  #   threshold_b           - wealth threshold ($B)
  #   n_above_threshold_emp - count of CA billionaires with wealth >= threshold
  #   wealth_above_threshold- total wealth ($B) above threshold
  # Derives columns D-L = Pareto extrapolation of billionaires Forbes misses
  # below $4.5B, assuming Pareto b averaged over anchor..tail thresholds.
  d <- pareto_inputs
  required <- c("threshold_b", "n_above_threshold_emp", "wealth_above_threshold")
  stopifnot(all(required %in% names(d)))

  A <- d$threshold_b
  B <- d$n_above_threshold_emp
  C <- d$wealth_above_threshold
  n <- length(A)

  # Empirical Pareto b at each threshold
  pareto_b_emp <- C / (B * A)

  # Bracket metrics (Excel treats the cell below the last row as 0 — replicate)
  next_C <- c(C[-1], 0)
  next_B <- c(B[-1], 0)
  next_A <- c(A[-1], NA_real_)
  wealth_in_bracket <- C - next_C
  actual_density   <- B - next_B
  avg_wealth_in_bracket_emp <- wealth_in_bracket / actual_density

  # Anchor row (threshold 4.5) and average-Pareto-b constants
  anchor_i <- which(A == anchor_threshold)
  if (length(anchor_i) != 1L) {
    stop("Anchor threshold ", anchor_threshold, " not present uniquely in pareto_inputs$threshold_b")
  }
  D23 <- mean(pareto_b_emp[anchor_i:n])   # Average Pareto b above anchor
  D24 <- D23 / (D23 - 1)                  # Corresponding Pareto a

  # Projected count: empirical at/above anchor; Pareto-extrapolated below.
  n_above_threshold_proj <- B
  below <- seq_len(anchor_i - 1L)
  n_above_threshold_proj[below] <-
    B[anchor_i] * (A[anchor_i] / A[below])^D24

  next_H <- c(n_above_threshold_proj[-1], 0)
  projected_density <- n_above_threshold_proj - next_H

  # Projected wealth in bracket: empirical bracket at/above anchor;
  # Pareto-formula below.
  projected_wealth_in_bracket <- wealth_in_bracket
  for (i in below) {
    projected_wealth_in_bracket[i] <-
      D23 * n_above_threshold_proj[i] *
        (A[i] - next_A[i] * (A[i] / next_A[i])^D24)
  }

  avg_wealth_in_bracket_proj <- projected_wealth_in_bracket / projected_density

  pareto_b_proj <- pareto_b_emp
  pareto_b_proj[below] <- D23

  tibble::tibble(
    threshold_b                 = A,
    n_above_threshold_emp       = B,
    wealth_above_threshold      = C,
    pareto_b_emp                = pareto_b_emp,
    wealth_in_bracket           = wealth_in_bracket,
    actual_density              = actual_density,
    avg_wealth_in_bracket_emp   = avg_wealth_in_bracket_emp,
    n_above_threshold_proj      = n_above_threshold_proj,
    projected_wealth_in_bracket = projected_wealth_in_bracket,
    projected_density           = projected_density,
    avg_wealth_in_bracket_proj  = avg_wealth_in_bracket_proj,
    pareto_b_proj               = pareto_b_proj
  )
}

pareto_n_above <- function(threshold, anchor_threshold, anchor_count, pareto_a) {
  # # billionaires above wealth threshold under a Pareto tail with given anchor
  anchor_count * (anchor_threshold / threshold)^pareto_a
}

pareto_wealth_in_bracket <- function(lo, hi, anchor_threshold, anchor_count,
                                     pareto_a, pareto_b) {
  # Total wealth held by people with wealth in [lo, hi) under the Pareto tail.
  # Matches Excel I-column formula: D23 * H * (lo - hi * (lo/hi)^D24).
  H_lo <- pareto_n_above(lo, anchor_threshold, anchor_count, pareto_a)
  pareto_b * H_lo * (lo - hi * (lo / hi)^pareto_a)
}

compute_pareto_summary <- function(pareto_missing_r,
                                   anchor_threshold = 4.5,
                                   phasein_lo = 1.0,
                                   phasein_hi = 1.1) {
  d <- pareto_missing_r
  required <- c("threshold_b", "n_above_threshold_emp", "wealth_above_threshold",
                "pareto_b_emp", "wealth_in_bracket", "actual_density",
                "n_above_threshold_proj", "projected_wealth_in_bracket",
                "projected_density")
  stopifnot(all(required %in% names(d)))

  anchor_i <- which(d$threshold_b == anchor_threshold)
  anchor_count <- d$n_above_threshold_emp[anchor_i]
  pareto_b <- mean(d$pareto_b_emp[anchor_i:nrow(d)])
  pareto_a <- pareto_b / (pareto_b - 1)

  total_wealth_emp  <- sum(d$wealth_in_bracket,           na.rm = TRUE)  # E22
  total_count_emp   <- sum(d$actual_density,              na.rm = TRUE)  # F22
  total_wealth_proj <- sum(d$projected_wealth_in_bracket, na.rm = TRUE)  # I22
  total_count_proj  <- sum(d$projected_density,           na.rm = TRUE)  # J22

  pct_wealth_increase <- total_wealth_proj / total_wealth_emp - 1        # I23
  pct_count_increase  <- total_count_proj  / total_count_emp  - 1        # J23

  wealth_in_phasein <- pareto_wealth_in_bracket(
    phasein_lo, phasein_hi,
    anchor_threshold = anchor_threshold,
    anchor_count = anchor_count,
    pareto_a = pareto_a,
    pareto_b = pareto_b
  )                                                                       # I29
  fraction_in_phasein <- wealth_in_phasein / (total_wealth_proj - total_wealth_emp)  # I24

  list(
    pareto_a            = pareto_a,
    pareto_b            = pareto_b,
    total_wealth_emp    = total_wealth_emp,
    total_count_emp     = total_count_emp,
    total_wealth_proj   = total_wealth_proj,
    total_count_proj    = total_count_proj,
    pct_wealth_increase = pct_wealth_increase,
    pct_count_increase  = pct_count_increase,
    wealth_in_phasein   = wealth_in_phasein,
    fraction_in_phasein = fraction_in_phasein
  )
}

compute_fig8_laffer <- function(
  semi_elasticity_mobility   = 10,      # Fig8!B8 - mobility semi-elasticity e
  current_inctax_per_wealth  = 0.002,   # Fig8!C8 - current CA income tax / wealth
  current_wealth_tax_base    = 2000,    # Fig8!D8 - current wealth tax base ($B)
  deconcentration_elasticity = 15,      # Fig8!E8 - deconcentration elasticity d
  rate_step                  = 0.001,
  max_rate                   = 0.20
) {
  # Laffer curve for a permanent annual CA wealth tax under mobility +
  # deconcentration responses. Mirrors Fig8 columns A-E.
  rates  <- seq(0, max_rate, by = rate_step)
  base   <- current_wealth_tax_base *
              exp(-(rates - current_inctax_per_wealth) * semi_elasticity_mobility)
  ref_pow <- (1 - current_inctax_per_wealth)^deconcentration_elasticity
  tibble::tibble(
    tax_rate               = rates,
    mechanical_tax_revenue = rates * current_wealth_tax_base,
    wealth_tax_base        = base,
    actual_tax_revenue     = rates * base,
    long_run_tax_revenue   = rates * base * (1 - rates)^deconcentration_elasticity / ref_pow
  )
}

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

  # Bridge to Tab5 row 17/18 (wealth and CA income tax denominators
  # used to apportion the leaver CA income tax loss by wealth share):
  B17 <- baseline_wealth                                # all CA billionaire wealth
  F17 <- ca_inctax_avg                                  # all CA billionaire avg CA tax
  # B18: wealth excluding top-4 company wealth
  top4_company_wealth_M <- wealth_end_row$all_top4
  page_wealth_M         <- wealth_end_row$page
  brin_wealth_M         <- wealth_end_row$brin
  zuck_wealth_M         <- wealth_end_row$zuckerberg
  huang_wealth_M        <- wealth_end_row$huang
  # Tab5 row 30: All top 4 (private + company breakouts hardcoded in Tab5)
  page_wealth_B  <- 276;   page_private_B  <- 13.4
  brin_wealth_B  <- 254.6; brin_private_B  <- 13.2
  zuck_wealth_B  <- 230.2; zuck_private_B  <- 2.5
  huang_wealth_B <- 172;   huang_private_B <- 2.84
  top4_total_B   <- page_wealth_B + brin_wealth_B + zuck_wealth_B + huang_wealth_B
  top4_private_B <- page_private_B + brin_private_B + zuck_private_B + huang_private_B
  B18 <- B17 - (top4_total_B - top4_private_B)
  F18 <- F17 - (top4_avg_tax_M / 1000)                  # convert $M -> $B

  # Pre-2026 leavers (Page, Thiel, Hankey, Kalanick) -- Tab5 rows 20-23
  thiel_wealth_B    <- 28.9
  hankey_wealth_B   <- 8.15
  kalanick_wealth_B <- 3.56
  B19 <- page_wealth_B + thiel_wealth_B + hankey_wealth_B + kalanick_wealth_B
  F20 <- (page_avg_tax_M / 1000) + page_private_B * (F18 / B18)
  F21 <- thiel_wealth_B    * (F18 / B18)
  F22 <- hankey_wealth_B   * (F18 / B18)
  F23 <- kalanick_wealth_B * (F18 / B18)
  F19 <- F20 + F21 + F22 + F23

  # Post-2026 leavers (Brin, Zuckerberg, Andy Fang) -- Tab5 rows 25-27
  fang_wealth_B <- 1.5
  B24 <- brin_wealth_B + zuck_wealth_B + fang_wealth_B
  F25 <- (brin_avg_tax_M / 1000) + brin_private_B * (F18 / B18)
  F26 <- (zuck_avg_tax_M / 1000) + zuck_private_B * (F18 / B18)
  F27 <- fang_wealth_B * (F18 / B18)
  F24 <- F25 + F26 + F27

  # --- Scenario 1: Benchmark ---
  C6 <- baseline_wealth
  D6 <- C6 * (1 - avoidance_rate)
  E6 <- avoidance_rate
  F6 <- C6 * (1 - E6) * wealth_tax_rate
  G6 <- F6 * realization_share * ltcg_taxable * ca_ltcg_rate
  H6 <- -wealth_tax_rate * ca_inctax_avg

  # --- Scenario 2: Adding missing small billionaires ---
  B7 <- baseline_n * (1 + pareto$pct_count_increase)
  C7 <- C6 * (1 + pareto$pct_wealth_increase)
  D7 <- C6 * ((1 - avoidance_rate) + (1 - avoidance_small) * pareto$pct_wealth_increase)
  E7 <- 1 - D7 / C7
  F7 <- C7 * (1 - E7) * wealth_tax_rate -
        (C7 - C6) * pareto$fraction_in_phasein * phasein_rate
  G7 <- F7 * realization_share * ltcg_taxable * ca_ltcg_rate
  H7 <- -wealth_tax_rate * ca_inctax_avg * (1 + pareto$pct_wealth_increase)

  # --- Scenario 3: Aggressive pre/post-2026 leavers ---
  B8 <- baseline_n
  C8 <- C6
  D8 <- 0.9 * (C6 - B19)
  E8 <- 1 - D8 / C8
  F8 <- C8 * (1 - E8) * wealth_tax_rate
  G8 <- F8 * realization_share * ltcg_taxable * ca_ltcg_rate
  H8 <- H6 - (F19 + F24)

  # --- Scenario 4: Both 2 and 3 ---
  B9 <- B7
  C9 <- C8 + (C7 - C6)
  D9 <- D8 + (D7 - D6)
  E9 <- 1 - D9 / C9
  F9 <- C9 * (1 - E9) * wealth_tax_rate
  G9 <- F9 * realization_share * ltcg_taxable * ca_ltcg_rate
  H9 <- H7 - (F19 + F24)

  tibble::tibble(
    scenario = paste0("Scenario ", 1:4),
    n_billionaires            = c(baseline_n, B7, B8, B9),
    wealth                    = c(C6, C7, C8, C9),
    taxable_wealth            = c(D6, D7, D8, D9),
    avoidance_rate            = c(E6, E7, E8, E9),
    wealth_tax_revenue        = c(F6, F7, F8, F9),
    extra_ca_inctax_sales     = c(G6, G7, G8, G9),
    annual_ca_inctax_loss     = c(H6, H7, H8, H9)
  )
}

compute_data_sec_agg <- function(data_sec_all,
                                 exclude_ids = ELLISON_FORBES_ID,
                                 m_to_b = 1000) {
  # Columns to sum (in panel order) — the 27 metric columns shared with data_sec_all
  sum_cols <- c(
    "forbes_worth", "forbes_public_worth",
    "purchase", "sale",
    "kg", "kg_long", "kg_short",
    "option_profit", "noneq_comp", "ordinary_income",
    "kg_taxable", "dividend", "fiscal_income",
    "donation", "donation_deductible", "income_taxable",
    "ca_income_tax", "fed_ordinary_income_tax", "fed_preferential_tax",
    "fed_income_tax", "fiscal_income_tax",
    "sales_tax", "w_txt", "w_tax_ppent", "w_pi",
    "total_tax", "economic_income"
  )
  filtered <- data_sec_all[!(data_sec_all$forbes_id %in% exclude_ids), ]
  out <- filtered |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      n = dplyr::n(),
      dplyr::across(
        dplyr::all_of(sum_cols),
        \(x) sum(x, na.rm = TRUE) / m_to_b
      ),
      .groups = "drop"
    )
  out$year <- as.integer(out$year)
  tibble::as_tibble(out)
}
