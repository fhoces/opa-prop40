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

compute_billionaires_ca_inctax <- function(data_sec_agg_r,
                                            billionaires_ca_inctax,
                                            ftb_b4a) {
  # Re-derives the 727 formula cells of the billionairesCAinctax sheet.
  # Returns a list of four blocks; literal-input cells (Forbes counts, IRS/SCF
  # published stats, state-budget revenue, FTB top-bracket 2023 figures that
  # aren't in ftb_b4a) are read through from the positional dump.

  bci <- billionaires_ca_inctax
  cell <- function(addr) xls_cell(bci, addr)
  agg_map <- c(
    C  = "forbes_worth",       D  = "forbes_public_worth",
    S  = "ca_income_tax",      V  = "fed_income_tax",
    AB = "sales_tax",          AC = "w_txt",
    AD = "w_tax_ppent",        AF = "total_tax",
    AG = "economic_income"
  )
  agg <- function(letter) {
    # data_sec_agg_r is years 2019..2025 (rows in panel = columns C..I in Excel)
    data_sec_agg_r[[agg_map[[letter]]]]
  }
  ftb_D <- suppressWarnings(as.numeric(ftb_b4a$D))
  ftb_H <- suppressWarnings(as.numeric(ftb_b4a$H))
  ftb_J <- suppressWarnings(as.numeric(ftb_b4a$J))
  ftb_K <- suppressWarnings(as.numeric(ftb_b4a$K))
  ftb_cols <- list(D = ftb_D, H = ftb_H, J = ftb_J, K = ftb_K)
  ftb_sum <- function(col_letter, row_lo, row_hi, scale = 1) {
    sum(ftb_cols[[col_letter]][row_lo:row_hi], na.rm = TRUE) * scale
  }
  # FTB year row ranges (year -> start, end). 2022 sits at top of sheet; 2018 bottom.
  ftb_yr <- list(
    "2018" = c(242, 300),
    "2019" = c(183, 241),
    "2020" = c(124, 182),
    "2021" = c(64,  123),
    "2022" = c(4,   63)
  )
  # FTB top-bracket rows per year:
  #   2021 / 2022: $10m+ is the last row; $5m-9.999m is the row above
  #   2018-2020:   $5m+ aggregated (only the last row)
  ftb_10m  <- list("2021" = 123, "2022" = 63)
  ftb_5m99 <- list("2021" = 122, "2022" = 62)
  ftb_5m   <- list("2018" = 300, "2019" = 241, "2020" = 182)

  # ---- Memo 1: US top .001% income calibration (rows 58-72) ----------------
  # Calendar-year panel 2018..2022 (cols B..F).
  m1_years <- 2018:2022
  m1_cols  <- c("B","C","D","E","F")
  # Inputs (literal IRS / Pareto stats)
  m1_n_returns       <- xls_cells_row(bci, m1_cols, 59)
  m1_agi_cutoff      <- xls_cells_row(bci, m1_cols, 60)
  m1_agi_avg         <- xls_cells_row(bci, m1_cols, 61)
  m1_tax_total       <- xls_cells_row(bci, m1_cols, 63)
  m1_top10m_n        <- xls_cells_row(bci, m1_cols, 66)
  m1_top10m_cutoff   <- xls_cells_row(bci, m1_cols, 67)
  m1_top10m_agi_avg  <- xls_cells_row(bci, m1_cols, 68)

  m1_pareto_b_001    <- m1_agi_avg / m1_agi_cutoff               # row 62
  m1_fed_tax_per_agi <- 1000 * (m1_tax_total / m1_n_returns) / m1_agi_avg  # row 64
  m1_pareto_b_10m    <- m1_top10m_agi_avg / m1_top10m_cutoff     # row 69
  m1_proj_cutoff_001 <- m1_top10m_cutoff *
                         (m1_top10m_n / m1_n_returns)^(1 - 1 / m1_pareto_b_10m)  # row 70
  m1_proj_agi_001    <- m1_proj_cutoff_001 * m1_pareto_b_10m     # row 71
  m1_pct_overshoot   <- unname((m1_proj_agi_001 - m1_agi_avg) / m1_proj_agi_001)  # row 72 (B..F)
  m1_pareto_b_001    <- unname(m1_pareto_b_001)
  m1_fed_tax_per_agi <- unname(m1_fed_tax_per_agi)
  m1_pareto_b_10m    <- unname(m1_pareto_b_10m)
  m1_proj_cutoff_001 <- unname(m1_proj_cutoff_001)
  m1_proj_agi_001    <- unname(m1_proj_agi_001)
  # G72 = F72 (continuation for 2023)

  memo1 <- tibble::tibble(
    year                = m1_years,
    n_returns           = m1_n_returns,
    agi_cutoff_k        = m1_agi_cutoff,
    agi_avg_k           = m1_agi_avg,
    pareto_b_001        = m1_pareto_b_001,
    fed_tax_total_m     = m1_tax_total,
    fed_tax_per_agi     = m1_fed_tax_per_agi,
    n_returns_10m       = m1_top10m_n,
    agi_cutoff_10m_k    = m1_top10m_cutoff,
    agi_avg_10m_k       = m1_top10m_agi_avg,
    pareto_b_10m        = m1_pareto_b_10m,
    proj_cutoff_001_k   = m1_proj_cutoff_001,
    proj_agi_001_k      = m1_proj_agi_001,
    pct_overshoot       = m1_pct_overshoot
  )
  # Mapped to panel-year offsets: 2018->B (panel col B), ..., 2023->G uses F-value
  pct_overshoot_panel <- c(
    "2018" = m1_pct_overshoot[1], "2019" = m1_pct_overshoot[2],
    "2020" = m1_pct_overshoot[3], "2021" = m1_pct_overshoot[4],
    "2022" = m1_pct_overshoot[5], "2023" = m1_pct_overshoot[5]   # G72 = F72
  )

  # ---- D99 correction (Memo 2 robustness, scalar) --------------------------
  B96 <- cell("B96")  # 172669
  B98 <- cell("B98")  # 36894
  B99 <- B98 / B96
  C99 <- mean(m1_fed_tax_per_agi[1:3])     # AVERAGE(B64:D64) = years 2018-2020
  D99 <- B99 / C99                          # ~0.92118

  # ---- Method I year panel (rows 6..55) ------------------------------------
  yrs <- 2018:2026
  pan_cols <- c("B","C","D","E","F","G","H","I","J")  # 9 panel columns
  # Block A: CA billionaires (row 8 = counts; row 10 = total wealth from data_sec_agg)
  n_ca_b      <- xls_cells_row(bci, pan_cols, 8)               # row 8
  total_w_ca  <- c(NA_real_, agg("C"), NA_real_)               # row 10 (2018=NA, 2019..2025, 2026=NA)
  avg_w_ca    <- total_w_ca / n_ca_b                           # row 9

  # Block B: aggregate CA income tax stats
  # Row 13 (#returns): SUM(FTB col D) by year; 2023+ missing
  n_returns_ca <- c(
    ftb_sum("D", ftb_yr$`2018`[1], ftb_yr$`2018`[2]),
    ftb_sum("D", ftb_yr$`2019`[1], ftb_yr$`2019`[2]),
    ftb_sum("D", ftb_yr$`2020`[1], ftb_yr$`2020`[2]),
    ftb_sum("D", ftb_yr$`2021`[1], ftb_yr$`2021`[2]),
    ftb_sum("D", ftb_yr$`2022`[1], ftb_yr$`2022`[2]),
    NA_real_, NA_real_, NA_real_, NA_real_
  )
  # Row 14 (CA AGI $B): SUM(H) * 1e-9 for 2018-2022; 2023 literal (G14=1946170/1000)
  ca_agi_b <- c(
    ftb_sum("H", ftb_yr$`2018`[1], ftb_yr$`2018`[2], 1e-9),
    ftb_sum("H", ftb_yr$`2019`[1], ftb_yr$`2019`[2], 1e-9),
    ftb_sum("H", ftb_yr$`2020`[1], ftb_yr$`2020`[2], 1e-9),
    ftb_sum("H", ftb_yr$`2021`[1], ftb_yr$`2021`[2], 1e-9),
    ftb_sum("H", ftb_yr$`2022`[1], ftb_yr$`2022`[2], 1e-9),
    1946170 / 1000,    # G14 published 2023 literal
    NA_real_, NA_real_, NA_real_
  )
  # Row 15 (CA inctax all residents $B): SUM(K)*1e-9 for 2018-2022; 2023 literal;
  # 2024, 2025 derived from row 18 - row 17
  ca_inctax_resid_b_pre <- c(
    ftb_sum("K", ftb_yr$`2018`[1], ftb_yr$`2018`[2], 1e-9),
    ftb_sum("K", ftb_yr$`2019`[1], ftb_yr$`2019`[2], 1e-9),
    ftb_sum("K", ftb_yr$`2020`[1], ftb_yr$`2020`[2], 1e-9),
    ftb_sum("K", ftb_yr$`2021`[1], ftb_yr$`2021`[2], 1e-9),
    ftb_sum("K", ftb_yr$`2022`[1], ftb_yr$`2022`[2], 1e-9),
    97293 / 1000       # G15 published 2023 literal
  )
  # Row 16 passthrough: literal G16 = 15.219; F16 = G16*F15/G15; E16 = F16
  G16 <- cell("G16")   # 15.219 literal
  F16 <- G16 * ca_inctax_resid_b_pre[5] / ca_inctax_resid_b_pre[6]
  E16 <- F16
  # Row 17 part-year/non-resident: cells B..E = B15*(F17/F15) (panel col F = year 2022)
  F17 <- cell("F17")   # literal 6.6 (panel 2022)
  G17 <- ca_inctax_resid_b_pre[6] * (F17 / ca_inctax_resid_b_pre[5])
  # Row 18 = row 15 + row 16 + row 17 (and for 2024,2025 row 18 = row 20*(1+row21))
  # Row 20 (CA inctax revenue fiscal year $B): literal sums
  ca_inctax_fy_b <- xls_cells_row(bci, pan_cols, 20)
  # Row 18 for 2018-2023:
  pre_part17 <- c(
    ca_inctax_resid_b_pre[1] * (F17 / ca_inctax_resid_b_pre[5]),   # B17
    ca_inctax_resid_b_pre[2] * (F17 / ca_inctax_resid_b_pre[5]),   # C17
    ca_inctax_resid_b_pre[3] * (F17 / ca_inctax_resid_b_pre[5]),   # D17
    ca_inctax_resid_b_pre[4] * (F17 / ca_inctax_resid_b_pre[5]),   # E17
    F17,                                                             # F17 literal
    G17                                                              # G17 formula
  )
  pre_part16 <- c(NA, NA, NA, E16, F16, G16)                          # rows 16 (panel B..G)
  ca_inctax_total_b_pre <- ca_inctax_resid_b_pre +
                            ifelse(is.na(pre_part16), 0, pre_part16) +
                            pre_part17
  # Row 21 (fy_to_cy_adj) for 2018-2023: =(B18)/B20-1; H21, I21 = AVG(D21:G21)
  ca_inctax_total_b_full <- numeric(9)
  ca_inctax_total_b_full[1:6] <- ca_inctax_total_b_pre
  fy_to_cy_adj <- numeric(9)
  fy_to_cy_adj[1:6] <- ca_inctax_total_b_pre / ca_inctax_fy_b[1:6] - 1
  fy_to_cy_adj[7] <- mean(fy_to_cy_adj[3:6])    # H21 = AVERAGE(D21:G21)
  fy_to_cy_adj[8] <- fy_to_cy_adj[7]            # I21
  ca_inctax_total_b_full[7] <- ca_inctax_fy_b[7] * (1 + fy_to_cy_adj[7])    # H18
  ca_inctax_total_b_full[8] <- ca_inctax_fy_b[8] * (1 + fy_to_cy_adj[8])    # I18
  ca_inctax_total_b_full[9] <- NA_real_
  # Row 15 for 2024,2025: =H18 - H17 (where H17 = $G17 * (H18/$G18); but $G18 is from pre)
  G18 <- ca_inctax_total_b_full[6]
  H18 <- ca_inctax_total_b_full[7]
  I18 <- ca_inctax_total_b_full[8]
  H17 <- G17 * (H18 / G18)
  I17 <- G17 * (I18 / G18)
  H15 <- H18 - H17
  I15 <- I18 - I17
  ca_inctax_resid_b <- c(ca_inctax_resid_b_pre, H15, I15, NA_real_)
  ca_inctax_part17  <- c(pre_part17, H17, I17, NA_real_)
  ca_inctax_part16  <- c(pre_part16, NA_real_, NA_real_, NA_real_)

  # Row 22 CA total tax revenue fiscal year — literal pass-through (not used downstream here)

  # Block C: top-bracket rows 26..44 — only 2018..2023 (panel cols B..G)
  pc6 <- pan_cols[1:6]   # B..G
  # Row 26 (# returns $10m+): cells E26, F26 from FTB; G26 = literal; others NA
  n_ret_10m <- rep(NA_real_, 6)
  n_ret_10m[4] <- ftb_D[ftb_10m$`2021`]      # E26 = D123 for 2021
  n_ret_10m[5] <- ftb_D[ftb_10m$`2022`]      # F26 = D63 for 2022
  n_ret_10m[6] <- cell("G26")                     # G26 literal 4729
  # Row 27 (CA AGI $B $10m+): from FTB col H * 1e-9; G27 literal
  agi_10m_b <- rep(NA_real_, 6)
  agi_10m_b[4] <- ftb_H[ftb_10m$`2021`] * 1e-9
  agi_10m_b[5] <- ftb_H[ftb_10m$`2022`] * 1e-9
  agi_10m_b[6] <- cell("G27")                     # 150.394
  # Row 28 (taxable income $B $10m+): FTB col J for 2021/2022; G28 not present
  taxable_10m_b <- rep(NA_real_, 6)
  taxable_10m_b[4] <- ftb_J[ftb_10m$`2021`] * 1e-9
  taxable_10m_b[5] <- ftb_J[ftb_10m$`2022`] * 1e-9
  taxable_10m_b[6] <- cell("G28")                 # literal (no value in sheet, NA)
  # Row 29 (tax $B $10m+): FTB col K for 2021/2022; G29 literal
  tax_10m_b <- rep(NA_real_, 6)
  tax_10m_b[4] <- ftb_K[ftb_10m$`2021`] * 1e-9
  tax_10m_b[5] <- ftb_K[ftb_10m$`2022`] * 1e-9
  tax_10m_b[6] <- cell("G29")                     # literal
  # Row 30 = row 29 / row 28
  tax_rate_10m <- tax_10m_b / taxable_10m_b
  # Row 31 = 1000 * row 27 / (10 * row 26)
  pareto_b_10m <- 1000 * agi_10m_b / (10 * n_ret_10m)

  # Row 32 (# returns $5m+): formulas tie to FTB sheet differently by year
  n_ret_5m <- numeric(6)
  n_ret_5m[1] <- ftb_D[ftb_5m$`2018`]                                    # B32 = D300
  n_ret_5m[2] <- ftb_D[ftb_5m$`2019`]                                    # C32 = D241
  n_ret_5m[3] <- ftb_D[ftb_5m$`2020`]                                    # D32 = D182
  n_ret_5m[4] <- ftb_D[ftb_5m99$`2021`] + ftb_D[ftb_10m$`2021`]      # E32 = D122+D123
  n_ret_5m[5] <- ftb_D[ftb_5m99$`2022`] + ftb_D[ftb_10m$`2022`]      # F32 = D62+D63
  n_ret_5m[6] <- 7463 + n_ret_10m[6]                                          # G32 = 7463 + G26
  # Row 33 (CA AGI $B $5m+): same pattern
  agi_5m_b <- numeric(6)
  agi_5m_b[1] <- ftb_H[ftb_5m$`2018`] * 1e-9
  agi_5m_b[2] <- ftb_H[ftb_5m$`2019`] * 1e-9
  agi_5m_b[3] <- ftb_H[ftb_5m$`2020`] * 1e-9
  agi_5m_b[4] <- agi_10m_b[4] + ftb_H[ftb_5m99$`2021`] * 1e-9            # E33 = E27 + H122*1e-9
  agi_5m_b[5] <- agi_10m_b[5] + ftb_H[ftb_5m99$`2022`] * 1e-9
  agi_5m_b[6] <- agi_10m_b[6] + 51.097                                        # G33 = G27 + 51.097
  # Row 34 (taxable income $B $5m+)
  taxable_5m_b <- numeric(6)
  taxable_5m_b[1] <- ftb_J[ftb_5m$`2018`] * 1e-9
  taxable_5m_b[2] <- ftb_J[ftb_5m$`2019`] * 1e-9
  taxable_5m_b[3] <- ftb_J[ftb_5m$`2020`] * 1e-9
  taxable_5m_b[4] <- taxable_10m_b[4] + ftb_J[ftb_5m99$`2021`] * 1e-9
  taxable_5m_b[5] <- taxable_10m_b[5] + ftb_J[ftb_5m99$`2022`] * 1e-9
  taxable_5m_b[6] <- taxable_10m_b[6] + 48.479                                # G34 = G28 + 48.479
  # Row 35 (tax $B $5m+)
  tax_5m_b <- numeric(6)
  tax_5m_b[1] <- ftb_K[ftb_5m$`2018`] * 1e-9
  tax_5m_b[2] <- ftb_K[ftb_5m$`2019`] * 1e-9
  tax_5m_b[3] <- ftb_K[ftb_5m$`2020`] * 1e-9
  tax_5m_b[4] <- tax_10m_b[4] + ftb_K[ftb_5m99$`2021`] * 1e-9
  tax_5m_b[5] <- tax_10m_b[5] + ftb_K[ftb_5m99$`2022`] * 1e-9
  tax_5m_b[6] <- 4.347 + tax_10m_b[6]                                         # G35 = 4.347 + G29
  # Row 36, 37
  tax_rate_5m  <- tax_5m_b / taxable_5m_b
  pareto_b_5m  <- 1000 * agi_5m_b / (5 * n_ret_5m[1:6])

  # Row 38 (proj cutoff $m top taxpayer using $10m anchor):
  # B-D38: =B41*($F38/$F41) (Pareto-scaling adjustment to row-41 cutoff)
  # E-G38: =10*(row26/row8)^(1-1/row31)
  F8_v <- n_ca_b[5]      # 2022 panel B = year 2022 count = 175
  proj_cutoff_top <- numeric(6)
  # First compute E38..G38 directly
  proj_cutoff_top[4] <- 10 * (n_ret_10m[4] / n_ca_b[4])^(1 - 1 / pareto_b_10m[4])
  proj_cutoff_top[5] <- 10 * (n_ret_10m[5] / n_ca_b[5])^(1 - 1 / pareto_b_10m[5])
  proj_cutoff_top[6] <- 10 * (n_ret_10m[6] / n_ca_b[6])^(1 - 1 / pareto_b_10m[6])
  # Row 41 first (B-G): =5*(row32/row8)^(1-1/row37)
  proj_cutoff_top_5m <- 5 * (n_ret_5m[1:6] / n_ca_b[1:6])^(1 - 1 / pareto_b_5m)
  # B-D38: scale row 41 cutoff by row38/row41 ratio at F (2022 reference)
  F38 <- proj_cutoff_top[5]; F41 <- proj_cutoff_top_5m[5]
  for (i in 1:3) proj_cutoff_top[i] <- proj_cutoff_top_5m[i] * (F38 / F41)
  # Row 39 (proj AGI top taxpayer $B):
  # E-G39: =0.001*row38*row31*row8
  # B-D39: =B42*($F39/$F42); row42 below
  proj_agi_top <- numeric(6)
  proj_agi_top[4] <- 0.001 * proj_cutoff_top[4] * pareto_b_10m[4] * n_ca_b[4]
  proj_agi_top[5] <- 0.001 * proj_cutoff_top[5] * pareto_b_10m[5] * n_ca_b[5]
  proj_agi_top[6] <- 0.001 * proj_cutoff_top[6] * pareto_b_10m[6] * n_ca_b[6]
  proj_agi_top_5m <- 0.001 * proj_cutoff_top_5m * pareto_b_5m * n_ca_b[1:6]
  F39 <- proj_agi_top[5]; F42 <- proj_agi_top_5m[5]
  for (i in 1:3) proj_agi_top[i] <- proj_agi_top_5m[i] * (F39 / F42)
  # Row 40 (proj tax top taxpayer $B):
  # B-D40: =row39*(row35/row33)   (5m tax rate)
  # E-G40: =row39*(row29/row27)   (10m tax rate)
  proj_tax_top <- numeric(6)
  for (i in 1:3) proj_tax_top[i] <- proj_agi_top[i] * (tax_5m_b[i] / agi_5m_b[i])
  for (i in 4:6) proj_tax_top[i] <- proj_agi_top[i] * (tax_10m_b[i] / agi_10m_b[i])
  # Row 43 (corrected AGI top taxpayer): row39 * (1 - row72)
  pct_overshoot_yr <- c(
    pct_overshoot_panel["2018"], pct_overshoot_panel["2019"],
    pct_overshoot_panel["2020"], pct_overshoot_panel["2021"],
    pct_overshoot_panel["2022"], pct_overshoot_panel["2023"]
  )
  pct_overshoot_yr <- unname(pct_overshoot_yr)
  proj_agi_top_corr <- proj_agi_top * (1 - pct_overshoot_yr)
  # Row 44 (corrected tax top taxpayer): row40 * (1 - row72)
  # E-G44 also multiplied by AVERAGE($B$36:$D$36)/row30 to use $5m rate context
  avg_tax_rate_5m_bcd <- mean(tax_rate_5m[1:3])
  proj_tax_top_corr <- proj_tax_top * (1 - pct_overshoot_yr)
  for (i in 4:6) proj_tax_top_corr[i] <- proj_tax_top_corr[i] * avg_tax_rate_5m_bcd / tax_rate_10m[i]

  # Row 46 literal (0.5 for B..G); rows 47 = D99
  inc_top_w_rel <- c(rep(cell("B46"), 6), NA_real_, NA_real_, NA_real_)   # row 46 over panel
  corr_passthru <- c(rep(D99, 6), NA_real_, NA_real_, NA_real_)            # row 47

  # Row 49 (CA income tax paid by CA Forbes billionaires $B) — MAIN OUTPUT
  # B-G49: =row44 * row46 * row47
  ca_inctax_ca_b <- rep(NA_real_, 9)
  ca_inctax_ca_b[1:6] <- proj_tax_top_corr * inc_top_w_rel[1:6] * corr_passthru[1:6]
  # H49: =H50*H15; I49: =I50*I15
  # Row 50 (% CA inctax paid by CA billionaires): row49/row18
  # H50 = AVERAGE(B50:G50); I50 = E50
  pct_ca_inctax_by_b <- numeric(9)
  pct_ca_inctax_by_b[1:6] <- ca_inctax_ca_b[1:6] / ca_inctax_total_b_full[1:6]
  pct_ca_inctax_by_b[7] <- mean(pct_ca_inctax_by_b[1:6])    # H50
  pct_ca_inctax_by_b[8] <- pct_ca_inctax_by_b[4]            # I50 = E50 (year 2021)
  pct_ca_inctax_by_b[9] <- NA_real_
  ca_inctax_ca_b[7] <- pct_ca_inctax_by_b[7] * H15           # H49
  ca_inctax_ca_b[8] <- pct_ca_inctax_by_b[8] * I15           # I49

  # Row 51 = row49 / row10 (C..I columns; B51 NA since total_w_ca[B]=NA)
  ca_inctax_b_per_w <- ca_inctax_ca_b / total_w_ca

  # Row 53 (CA inctax public assets $B) = data_sec_agg!S (C..I = years 2019..2025)
  ca_inctax_public_b <- c(NA_real_, agg("S"), NA_real_)
  # Row 54: data_sec_agg!D / data_sec_agg!C (public_share)
  public_share_b <- c(NA_real_, agg("D") / agg("C"), NA_real_)
  # Row 55: row53 / row49
  ca_inctax_public_per_b_b <- ca_inctax_public_b / ca_inctax_ca_b

  method1 <- tibble::tibble(
    year                          = yrs,
    n_ca_billionaires             = n_ca_b,
    avg_wealth_ca_b               = avg_w_ca,
    total_wealth_ca_b             = total_w_ca,
    n_returns_ca                  = n_returns_ca,
    ca_agi_b                      = ca_agi_b,
    ca_inctax_residents_b         = ca_inctax_resid_b,
    ca_inctax_passthrough_b       = ca_inctax_part16,
    ca_inctax_partyear_nonres_b   = ca_inctax_part17,
    ca_inctax_total_b             = ca_inctax_total_b_full,
    ca_inctax_fy_b                = ca_inctax_fy_b,
    fy_to_cy_adjustment           = fy_to_cy_adj,
    n_returns_10m                 = c(n_ret_10m, NA_real_, NA_real_, NA_real_),
    ca_agi_10m_b                  = c(agi_10m_b, NA_real_, NA_real_, NA_real_),
    ca_taxable_10m_b              = c(taxable_10m_b, NA_real_, NA_real_, NA_real_),
    ca_tax_10m_b                  = c(tax_10m_b, NA_real_, NA_real_, NA_real_),
    ca_tax_rate_10m               = c(tax_rate_10m, NA_real_, NA_real_, NA_real_),
    pareto_b_10m_bracket          = c(pareto_b_10m, NA_real_, NA_real_, NA_real_),
    n_returns_5m                  = c(n_ret_5m, NA_real_, NA_real_, NA_real_),
    ca_agi_5m_b                   = c(agi_5m_b, NA_real_, NA_real_, NA_real_),
    ca_taxable_5m_b               = c(taxable_5m_b, NA_real_, NA_real_, NA_real_),
    ca_tax_5m_b                   = c(tax_5m_b, NA_real_, NA_real_, NA_real_),
    ca_tax_rate_5m                = c(tax_rate_5m, NA_real_, NA_real_, NA_real_),
    pareto_b_5m_bracket           = c(pareto_b_5m, NA_real_, NA_real_, NA_real_),
    proj_cutoff_top_pre_m         = c(proj_cutoff_top, NA_real_, NA_real_, NA_real_),
    proj_agi_top_pre_b            = c(proj_agi_top, NA_real_, NA_real_, NA_real_),
    proj_tax_top_pre_b            = c(proj_tax_top, NA_real_, NA_real_, NA_real_),
    proj_cutoff_top_5m_m          = c(proj_cutoff_top_5m, NA_real_, NA_real_, NA_real_),
    proj_agi_top_5m_b             = c(proj_agi_top_5m, NA_real_, NA_real_, NA_real_),
    proj_agi_top_corr_b           = c(proj_agi_top_corr, NA_real_, NA_real_, NA_real_),
    proj_tax_top_corr_b           = c(proj_tax_top_corr, NA_real_, NA_real_, NA_real_),
    income_top_wealth_relative    = inc_top_w_rel,
    correction_passthrough        = corr_passthru,
    ca_inctax_ca_billionaires_b   = ca_inctax_ca_b,
    pct_ca_inctax_by_billionaires = pct_ca_inctax_by_b,
    ca_inctax_per_wealth          = ca_inctax_b_per_w,
    ca_inctax_public_assets_b     = ca_inctax_public_b,
    public_assets_share           = public_share_b,
    ca_inctax_public_share_of_total = ca_inctax_public_per_b_b
  )

  # ---- Memo 2 robustness check (rows 76-105) -------------------------------
  # B100 = D99 * B96 * SUM(row35[B..D]) / SUM(row33[B..D])  -- avg CA tax rate * top .0002% AGI
  B100 <- D99 * B96 * sum(tax_5m_b[1:3]) / sum(agi_5m_b[1:3])
  B101 <- cell("B101")                                # 90 literal (# CA residents in top .0002%)
  B102 <- B101 * B100 / 1e6                            # ~1.70
  B103 <- mean(ca_inctax_ca_b[1:3])                    # 2018-2020 avg of row 49
  # B104 = AVG(D104:F104) — those are literal pre-filled from data_sec_agg's scaled column
  D104 <- cell("D104"); E104 <- cell("E104"); F104 <- cell("F104")
  B104 <- mean(c(D104, E104, F104))
  B105 <- B102 * B103 / B104
  C105 <- B105 / B103 - 1

  robustness <- list(
    D99   = D99,
    B100  = B100,
    B102  = B102,
    B103  = B103,
    B104  = B104,
    B105  = B105,
    C105  = C105
  )

  # ---- All-taxes block (rows 110-153) --------------------------------------
  # Years (panel cols B..J = 2018..2026); only 2019-2025 has data.
  # Row 111: CA AGI for all CA Forbes billionaires
  #   B-G111 = row43 * row46   (proj_agi_corr * 0.5)
  #   H,I111 = $G111 * H,I112 / $G112
  ca_agi_billionaires <- numeric(9)
  ca_agi_billionaires[1:6] <- proj_agi_top_corr * inc_top_w_rel[1:6]
  G111 <- ca_agi_billionaires[6]
  G112 <- ca_inctax_ca_b[6]
  ca_agi_billionaires[7] <- G111 * ca_inctax_ca_b[7] / G112
  ca_agi_billionaires[8] <- G111 * ca_inctax_ca_b[8] / G112
  ca_agi_billionaires[9] <- NA_real_
  # Row 112 = row 49
  ca_inctax_b_at <- ca_inctax_ca_b
  # Row 113 Fed inctax billionaires:
  #   B-F113 = row64(memo1) * row111 * D99
  #   G,H,I113 = row112 * row114
  fed_inctax_b <- numeric(9)
  fed_inctax_b[1] <- m1_fed_tax_per_agi[1] * ca_agi_billionaires[1] * D99
  fed_inctax_b[2] <- m1_fed_tax_per_agi[2] * ca_agi_billionaires[2] * D99
  fed_inctax_b[3] <- m1_fed_tax_per_agi[3] * ca_agi_billionaires[3] * D99
  fed_inctax_b[4] <- m1_fed_tax_per_agi[4] * ca_agi_billionaires[4] * D99
  fed_inctax_b[5] <- m1_fed_tax_per_agi[5] * ca_agi_billionaires[5] * D99
  # Row 114 = row113 / row112 (B..F)
  fed_to_ca_ratio <- rep(NA_real_, 9)
  fed_to_ca_ratio[1:5] <- fed_inctax_b[1:5] / ca_inctax_b_at[1:5]
  fed_to_ca_ratio[6] <- fed_to_ca_ratio[5]                              # G114 = F114
  fed_to_ca_ratio[7] <- mean(fed_to_ca_ratio[1:3])                       # H114 = AVG(B114:D114)
  fed_to_ca_ratio[8] <- fed_to_ca_ratio[7]                               # I114 = H114
  # Then 113[6:8] = 112[6:8] * 114[6:8]
  fed_inctax_b[6] <- ca_inctax_b_at[6] * fed_to_ca_ratio[6]
  fed_inctax_b[7] <- ca_inctax_b_at[7] * fed_to_ca_ratio[7]
  fed_inctax_b[8] <- ca_inctax_b_at[8] * fed_to_ca_ratio[8]
  fed_inctax_b[9] <- NA_real_

  # Row 115 = row 54 (public_share_b, C..I = 2019..2025; B = NA)
  public_share_a <- public_share_b
  # Row 116 = 0.11 * row 115
  sales_gross_up_public <- 0.11 * public_share_a
  # Row 117 = data_sec_agg!S, row118 = !V, row119 = !AC, row120 = !AD, row121 = !AB,
  # row122 = !AF, row130 = !AG  (all panel cols C..I)
  ca_inctax_pub <- c(NA_real_, agg("S"), NA_real_)
  fed_inctax_pub <- c(NA_real_, agg("V"), NA_real_)
  corp_tax_pub   <- c(NA_real_, agg("AC"), NA_real_)
  prop_tax_pub   <- c(NA_real_, agg("AD"), NA_real_)
  sales_tax_pub  <- c(NA_real_, agg("AB"), NA_real_)
  total_tax_pub  <- c(NA_real_, agg("AF"), NA_real_)
  econ_income_pub <- c(NA_real_, agg("AG"), NA_real_)
  # Row 123 = row115 * row10  (public wealth $B)
  public_wealth_b <- public_share_a * total_w_ca
  # Rows 124..128: per-wealth ratios
  tot_tax_per_wealth     <- total_tax_pub / public_wealth_b
  ca_inctax_per_w        <- ca_inctax_pub / public_wealth_b
  fed_inctax_per_w       <- fed_inctax_pub / public_wealth_b
  corp_per_w             <- corp_tax_pub  / public_wealth_b
  prop_sales_per_w       <- (prop_tax_pub + sales_tax_pub) / public_wealth_b
  check_w                <- tot_tax_per_wealth - (ca_inctax_per_w + fed_inctax_per_w +
                                                   corp_per_w + prop_sales_per_w)
  # Rows 131..135: per-econ_inc ratios
  tot_tax_per_ei  <- total_tax_pub / econ_income_pub
  ca_inctax_per_ei <- ca_inctax_pub / econ_income_pub
  fed_inctax_per_ei <- fed_inctax_pub / econ_income_pub
  corp_per_ei     <- corp_tax_pub  / econ_income_pub
  prop_sales_per_ei <- (prop_tax_pub + sales_tax_pub) / econ_income_pub
  check_ei         <- tot_tax_per_ei - (ca_inctax_per_ei + fed_inctax_per_ei +
                                         corp_per_ei + prop_sales_per_ei)
  # Row 137 = 1 - row115 - row116 (private + diversified share)
  private_share    <- 1 - public_share_a - sales_gross_up_public
  # Row 138 = row137 * (46.8+25)/(61+46.8+25)
  passthrough_share <- private_share * (46.8 + 25) / (61 + 46.8 + 25)
  # Row 139 = row137 * 61/(61+46.8+25)
  private_c_share   <- private_share * 61 / (61 + 46.8 + 25)
  # Row 140 = row115 + row116 + row138 + row139
  test_share        <- public_share_a + sales_gross_up_public + passthrough_share + private_c_share
  # Row 141 = row119 * (row139 / row115)
  corp_tax_priv_c   <- corp_tax_pub * (private_c_share / public_share_a)
  # Row 142 = 0.11 * row119
  corp_tax_div      <- 0.11 * corp_tax_pub
  # Row 143 = (row120/row119) * (row141 + row142)
  prop_tax_priv     <- (prop_tax_pub / corp_tax_pub) * (corp_tax_priv_c + corp_tax_div)
  # Row 144 = (row119 + row120) + row141 + row142 + row143
  tot_corp_prop     <- (corp_tax_pub + prop_tax_pub) + corp_tax_priv_c + corp_tax_div + prop_tax_priv
  # Row 145 = 0.03 * (row111 - row112 - row113 - 0.25*row111) * 0.5
  total_sales_tax <- 0.03 * (ca_agi_billionaires - ca_inctax_b_at - fed_inctax_b -
                              0.25 * ca_agi_billionaires) * 0.5
  # Row 146 = row112 + row113
  total_inctax_b  <- ca_inctax_b_at + fed_inctax_b
  # Row 147 = row144 + row145 + row146
  total_taxes_b   <- tot_corp_prop + total_sales_tax + total_inctax_b
  # Rows 148..152: per-total-wealth ratios (using row10 = total_w_ca)
  tot_per_total_w  <- total_taxes_b / total_w_ca
  ca_per_total_w   <- ca_inctax_b_at / total_w_ca
  fed_per_total_w  <- fed_inctax_b   / total_w_ca
  corp_per_total_w <- (corp_tax_pub + corp_tax_priv_c + corp_tax_div) / total_w_ca
  ps_per_total_w   <- (prop_tax_pub + prop_tax_priv + total_sales_tax) / total_w_ca
  check_total      <- tot_per_total_w - (ca_per_total_w + fed_per_total_w +
                                          corp_per_total_w + ps_per_total_w)

  all_taxes <- tibble::tibble(
    year                          = yrs,
    ca_agi_ca_billionaires_b      = ca_agi_billionaires,
    ca_inctax_ca_billionaires_b   = ca_inctax_b_at,
    fed_inctax_ca_billionaires_b  = fed_inctax_b,
    fed_to_ca_inctax_ratio        = fed_to_ca_ratio,
    public_assets_share           = public_share_a,
    sales_gross_up_public         = sales_gross_up_public,
    ca_inctax_public_b            = ca_inctax_pub,
    fed_inctax_public_b           = fed_inctax_pub,
    corp_tax_public_b             = corp_tax_pub,
    property_tax_public_b         = prop_tax_pub,
    sales_tax_public_b            = sales_tax_pub,
    total_tax_public_b            = total_tax_pub,
    public_wealth_b               = public_wealth_b,
    total_tax_per_public_wealth   = tot_tax_per_wealth,
    ca_inctax_per_public_wealth   = ca_inctax_per_w,
    fed_inctax_per_public_wealth  = fed_inctax_per_w,
    corp_per_public_wealth        = corp_per_w,
    prop_sales_per_public_wealth  = prop_sales_per_w,
    check_decomp_public_wealth    = check_w,
    public_econ_income_b          = econ_income_pub,
    total_tax_per_econ_income     = tot_tax_per_ei,
    ca_inctax_per_econ_income     = ca_inctax_per_ei,
    fed_inctax_per_econ_income    = fed_inctax_per_ei,
    corp_per_econ_income          = corp_per_ei,
    prop_sales_per_econ_income    = prop_sales_per_ei,
    check_decomp_econ_income      = check_ei,
    private_share                 = private_share,
    passthrough_share             = passthrough_share,
    private_c_share               = private_c_share,
    test_share_sum                = test_share,
    corp_tax_private_c_b          = corp_tax_priv_c,
    corp_tax_diversified_b        = corp_tax_div,
    property_tax_private_b        = prop_tax_priv,
    total_corp_property_b         = tot_corp_prop,
    total_sales_tax_b             = total_sales_tax,
    total_inctax_b                = total_inctax_b,
    total_taxes_b                 = total_taxes_b,
    total_per_total_wealth        = tot_per_total_w,
    ca_inctax_per_total_wealth    = ca_per_total_w,
    fed_inctax_per_total_wealth   = fed_per_total_w,
    corp_per_total_wealth         = corp_per_total_w,
    prop_sales_per_total_wealth   = ps_per_total_w,
    check_total_decomp            = check_total
  )

  list(
    method1     = method1,
    memo1       = memo1,
    robustness  = robustness,
    all_taxes   = all_taxes
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

compute_shortrunseries <- function(data_sec_agg_r,
                                    data_sec_top4,
                                    billionaires_ca_inctax_r,
                                    shortrunseries) {
  # Re-derives the 268 formula cells of the shortrunseries sheet.
  # Wealth-growth panel + averages + cumulative growth from base years.
  # Returns list(panel, summary_2025, growth).
  srs <- shortrunseries
  cell <- function(addr) xls_cell(srs, addr)
  # Pull per-billionaire CA income tax (col S) and wealth (cols C/D, $M)
  top4 <- data_sec_top4
  # The 5 "top 5" billionaires, in Excel column order AJ..AN. Used to query
  # per-billionaire columns of data_sec_top4. Mapping: short name -> forbes_id.
  TOP5 <- c(
    brin    = "sergey-brin",
    page    = "larry-page",
    zuck    = "mark-zuckerberg",
    ellison = "larry-ellison",
    huang   = "jensen-huang"
  )
  # For a data_sec_top4 column + year span, return a named list (one vector
  # per billionaire in TOP5).
  query_top5 <- function(col, yrs) {
    lapply(TOP5, function(id) {
      vapply(yrs, function(y) {
        row <- top4[top4$forbes_id == id & top4$year == y, ]
        if (nrow(row) == 1L) row[[col]] else NA_real_
      }, numeric(1))
    })
  }

  yrs <- 2018:2025
  yrs_data <- 2019:2025  # years where data_sec_agg_r has rows
  m1 <- billionaires_ca_inctax_r$method1

  # Literal inputs (panel rows 6..13)
  B_wealth_incl_nonus <- c(NA_real_, xls_cells_col(srs, "B", 7:13))   # row 7..13
  K_ellison           <- xls_cells_col(srs, "K", 6:13)                # 2018..2025
  Q_top5_incl_nonus   <- xls_cells_col(srs, "Q", 6:13)                # 2018..2025

  # Col C = total CA billionaire wealth (US citizens only) = data_sec_agg_r$forbes_worth
  C_wealth <- c(NA_real_, data_sec_agg_r$forbes_worth)
  # Col E = top5 total Forbes wealth ($B): data_sec_top4 "Total (excluding Ellison)" col C
  total_excl <- top4[top4$forbes_id == "Total (excluding Ellison)" & top4$year %in% yrs, ]
  total_excl <- total_excl[order(total_excl$year), ]
  E_top5_total      <- total_excl$forbes_worth        / 1000          # length 8
  G_top5_company    <- total_excl$public_worth / 1000                 # length 8 (data_sec_top4 col D)
  H_share_public    <- G_top5_company / E_top5_total
  # Col D, F: only row 13 (2025) has formula = base * (1 - 0.05); row 12 (2024) = base
  D_wealth_w_avoid <- rep(NA_real_, 8)
  D_wealth_w_avoid[7] <- C_wealth[7]                                    # D12 = C12
  D_wealth_w_avoid[8] <- C_wealth[8] * (1 - 0.05)                       # D13 = C13*(1-0.05)
  F_top5_w_avoid <- rep(NA_real_, 8)
  F_top5_w_avoid[7] <- E_top5_total[7]                                  # F12 = E12
  F_top5_w_avoid[8] <- E_top5_total[8] * (1 - 0.05)                     # F13 = E13*(1-0.05)
  # Col J = data_sec_agg_r$n
  J_n_ca   <- c(NA_real_, data_sec_agg_r$n)
  # Col L = K / C (share Ellison)
  L_share_ellison <- K_ellison / C_wealth
  # Col M = yoy growth in C
  M_yoy_growth <- c(NA_real_, C_wealth[-1] / C_wealth[-8] - 1)
  # Col N = C / C[2019] - 1, panel rows 7..13 (N7=0)
  ref_2019 <- C_wealth[2]
  N_cum_2019 <- C_wealth / ref_2019 - 1
  N_cum_2019[1] <- NA_real_
  # Col O = C / C[2022] - 1, panel rows 10..13
  ref_2022 <- C_wealth[5]
  O_cum_2022 <- rep(NA_real_, 8)
  O_cum_2022[5:8] <- C_wealth[5:8] / ref_2022 - 1
  # Col P = C / C[2023] - 1, panel rows 11..13
  ref_2023 <- C_wealth[6]
  P_cum_2023 <- rep(NA_real_, 8)
  P_cum_2023[6:8] <- C_wealth[6:8] / ref_2023 - 1
  # Col R = Q / Q[t-1] - 1
  R_yoy <- c(NA_real_, Q_top5_incl_nonus[-1] / Q_top5_incl_nonus[-8] - 1)
  # Col S = Q / Q[2019] - 1, EXCEPT S10 which references B (wealth incl non-US)
  # instead of Q — apparent typo in the original sheet but reproduced for fidelity.
  S_cum_2019 <- Q_top5_incl_nonus / Q_top5_incl_nonus[2] - 1
  S_cum_2019[1] <- NA_real_                            # S6 empty in Excel
  S_cum_2019[2] <- NA_real_                            # S7 empty (no formula)
  S_cum_2019[5] <- B_wealth_incl_nonus[5] / B_wealth_incl_nonus[2] - 1   # S10 anomaly
  # Col T = Q / Q[2022] - 1 starting row 10
  T_cum_2022 <- rep(NA_real_, 8)
  T_cum_2022[5:8] <- Q_top5_incl_nonus[5:8] / Q_top5_incl_nonus[5] - 1
  # Col V = B / Q (share CA in top5)
  V_share_top5_in_total <- B_wealth_incl_nonus / Q_top5_incl_nonus
  # Col X = billionairesCAinctax row 49 (CA inctax paid by CA Forbes billionaires)
  # Map panel year 2018..2025 to billionairesCAinctax method1 year column
  m1_idx_per_year <- match(yrs, m1$year)
  X_ca_inctax  <- m1$ca_inctax_ca_billionaires_b[m1_idx_per_year]
  # Col Y = X / B
  Y_ca_inctax_per_wealth <- X_ca_inctax / B_wealth_incl_nonus
  # Col Z = billionairesCAinctax row 18 (CA inctax total)
  Z_ca_inctax_total <- m1$ca_inctax_total_b[m1_idx_per_year]
  # Col AA = X / Z
  AA_share <- X_ca_inctax / Z_ca_inctax_total
  # Col AE = top5 SEC ca_income_tax (data_sec_top4 "Total" col S / 1000)
  AE_top5_ca_inctax_sec <- total_excl$ca_income_tax / 1000
  # Col AD = AE / G
  AD_top5_sec_tax_rate <- AE_top5_ca_inctax_sec / G_top5_company
  # Col AF = AE / Z
  AF_top5_share_of_total <- AE_top5_ca_inctax_sec / Z_ca_inctax_total

  # Cols AJ..AN per-billionaire CA income tax / 1000 (years 2018..2025)
  tax_b <- lapply(query_top5("ca_income_tax", yrs), `/`, 1000)
  # Col AG = top 3 sum (Brin + Page + Zuck); Col AH = top 2 sum (Brin + Page)
  AG_top3 <- tax_b$brin + tax_b$page + tax_b$zuck
  AH_top2 <- tax_b$brin + tax_b$page

  panel <- tibble::tibble(
    year                     = yrs,
    wealth_incl_nonus_b      = B_wealth_incl_nonus,
    wealth_us_citizens_b     = C_wealth,
    wealth_w_avoid_b         = D_wealth_w_avoid,
    top5_total_b             = E_top5_total,
    top5_w_avoid_b           = F_top5_w_avoid,
    top5_company_wealth_b    = G_top5_company,
    share_public             = H_share_public,
    n_ca_billionaires        = J_n_ca,
    ellison_wealth_b         = K_ellison,
    share_ellison            = L_share_ellison,
    yoy_growth_wealth        = M_yoy_growth,
    cum_growth_from_2019     = N_cum_2019,
    cum_growth_from_2022     = O_cum_2022,
    cum_growth_from_2023     = P_cum_2023,
    top5_incl_nonus_b        = Q_top5_incl_nonus,
    top5_yoy_growth          = R_yoy,
    top5_cum_growth_from_2019 = S_cum_2019,
    top5_cum_growth_from_2022 = T_cum_2022,
    share_ca_in_top5_b       = V_share_top5_in_total,
    ca_inctax_billionaires_b = X_ca_inctax,
    ca_inctax_per_wealth     = Y_ca_inctax_per_wealth,
    ca_inctax_total_b        = Z_ca_inctax_total,
    ca_inctax_share_total    = AA_share,
    top5_sec_tax_rate        = AD_top5_sec_tax_rate,
    top5_sec_ca_inctax_b     = AE_top5_ca_inctax_sec,
    top5_sec_share_of_total  = AF_top5_share_of_total,
    top3_ca_inctax_sum_b     = AG_top3,
    top2_ca_inctax_sum_b     = AH_top2,
    brin_ca_inctax_b         = tax_b$brin,
    page_ca_inctax_b         = tax_b$page,
    zuck_ca_inctax_b         = tax_b$zuck,
    ellison_ca_inctax_b      = tax_b$ellison,
    huang_ca_inctax_b        = tax_b$huang
  )

  # Row 14 = "2026 (feb 1)" public-wealth snapshot of TOP 5 using 2025 values
  # (AJ14 = data_sec_top4!D$98/1000 = Brin 2025 public wealth, etc.)
  pub_2025 <- vapply(query_top5("public_worth", 2025), `[`, numeric(1), 1L) / 1000
  AG14 <- pub_2025[["brin"]] + pub_2025[["page"]] + pub_2025[["zuck"]]   # top 3
  AH14 <- pub_2025[["brin"]] + pub_2025[["page"]]                         # top 2

  # Row 17 = top 5 TOTAL wealth (incl private) end of 2025: col C ($M) of each
  tot_2025 <- vapply(query_top5("forbes_worth", 2025), `[`, numeric(1), 1L) / 1000
  AG17 <- tot_2025[["brin"]] + tot_2025[["page"]] + tot_2025[["zuck"]]
  AH17 <- tot_2025[["brin"]] + tot_2025[["page"]]

  # Row 18 = row 14 / row 17 (public share by group)
  share_2025 <- pub_2025 / tot_2025
  AG18 <- AG14 / AG17
  AH18 <- AH14 / AH17

  # Row 15: averages of cols X..AN over rows 7..13 (years 2019..2025)
  idx_2019_2025 <- 2:8
  X15 <- mean(X_ca_inctax[idx_2019_2025])
  Y15 <- mean(Y_ca_inctax_per_wealth[idx_2019_2025])
  AA15 <- mean(AA_share[idx_2019_2025])
  AD15 <- mean(AD_top5_sec_tax_rate[idx_2019_2025])
  AE15 <- mean(AE_top5_ca_inctax_sec[idx_2019_2025])
  AF15 <- AE15 / X15
  AG15 <- mean(AG_top3[idx_2019_2025])
  AH15 <- mean(AH_top2[idx_2019_2025])
  # Per-billionaire 2019-2025 averages of CA income tax
  tax_b_avg <- vapply(tax_b, function(v) mean(v[idx_2019_2025]), numeric(1))
  Q15  <- V_share_top5_in_total[8]      # =B13/Q13

  # Row 16: AG16 = AG13/AG14 (% wealth in 2025 CA inctax / 2025 public wealth)
  AG16 <- AG_top3[8] / AG14
  AH16 <- AH_top2[8] / AH14
  # Per-billionaire: 2025 CA inctax / 2025 public wealth
  share_2025_tax <- vapply(names(TOP5),
                            function(nm) tax_b[[nm]][8] / pub_2025[[nm]],
                            numeric(1))

  summary_2025 <- list(
    top5_public_b      = c(pub_2025, top3 = AG14, top2 = AH14),
    top5_total_b       = c(tot_2025, top3 = AG17, top2 = AH17),
    public_share       = c(share_2025, top3 = AG18, top2 = AH18),
    avg_2019_2025      = list(
      X = X15, Y = Y15, AA = AA15, AD = AD15, AE = AE15, AF = AF15,
      AG = AG15, AH = AH15,
      AJ = unname(tax_b_avg["brin"]),
      AK = unname(tax_b_avg["page"]),
      AL = unname(tax_b_avg["zuck"]),
      AM = unname(tax_b_avg["ellison"]),
      AN = unname(tax_b_avg["huang"])
    ),
    avg_share_2025_wealth = c(top3 = AG16, top2 = AH16, share_2025_tax),
    share_top5_2025_in_total = Q15
  )

  # Growth-summary block (rows 16..21): B and C cols cumulative growth from base
  # year to 2025; M col = annualized growth from cumulative growth.
  base_years <- c(2019, 2020, 2021, 2022, 2023, 2024)
  base_idx <- match(base_years, yrs)
  yrs_to_2025 <- 2025 - base_years
  total_growth_incl <- B_wealth_incl_nonus[8] / B_wealth_incl_nonus[base_idx] - 1
  total_growth_excl <- C_wealth[8]            / C_wealth[base_idx]            - 1
  annualized_excl   <- (1 + total_growth_excl)^(1 / yrs_to_2025) - 1

  growth <- tibble::tibble(
    base_year             = base_years,
    yrs_to_2025           = yrs_to_2025,
    total_growth_incl_nonus = total_growth_incl,
    total_growth_us_only  = total_growth_excl,
    annualized_us_only    = annualized_excl
  )

  list(
    panel        = panel,
    summary_2025 = summary_2025,
    growth       = growth
  )
}

compute_top4taxes <- function(data_sec_top4) {
  # Re-derives the 429 formula cells of top4taxes: per-year tax rates of the
  # CA top-4 billionaires, 2004..2025, plus 2004-2016 / 2017-2025 averages.
  # The "top 4" composition shifts in three phases (see comment on `agg`).

  d <- data_sec_top4
  pick <- function(id, yr, col) {
    row <- d[d$forbes_id == id & d$year == yr, ]
    if (nrow(row) == 1L) row[[col]] else NA_real_
  }
  # Aggregate the 8 metric columns for the dynamic "top 4" composition.
  metric_cols <- c("ca_income_tax", "fed_income_tax", "sales_tax",
                   "w_txt", "w_tax_ppent", "total_tax", "economic_income",
                   "public_worth_avg")
  agg <- function(yr) {
    total <- vapply(metric_cols, pick, numeric(1),
                    id = "Total (excluding Ellison)", yr = yr)
    if (yr <= 2015) {
      ell <- vapply(metric_cols, pick, numeric(1), id = "larry-ellison", yr = yr)
      total + ell
    } else if (yr <= 2020) {
      ell <- vapply(metric_cols, pick, numeric(1), id = "larry-ellison", yr = yr)
      hua <- vapply(metric_cols, pick, numeric(1), id = "jensen-huang",  yr = yr)
      total + ell - hua
    } else {
      total
    }
  }

  yrs <- 2004:2025
  mat <- vapply(yrs, agg, numeric(length(metric_cols)))
  rownames(mat) <- metric_cols
  # Columns of `mat` are years; rows are metrics.
  ca_tax  <- mat["ca_income_tax", ]
  fed_tax <- mat["fed_income_tax", ]
  sales_t <- mat["sales_tax", ]
  corp_t  <- mat["w_txt", ]
  prop_t  <- mat["w_tax_ppent", ]
  total_t <- mat["total_tax", ]
  econ_i  <- mat["economic_income", ]      # T
  wealth  <- mat["public_worth_avg", ]     # S

  # Per-income ratios (cols C..H, /T)
  C_total_per_inc  <- total_t / econ_i
  D_ca_per_inc     <- ca_tax  / econ_i
  E_fed_per_inc    <- fed_tax / econ_i
  F_sales_per_inc  <- sales_t / econ_i
  G_corp_per_inc   <- corp_t  / econ_i
  H_prop_per_inc   <- prop_t  / econ_i
  I_check_inc      <- C_total_per_inc -
                       (D_ca_per_inc + E_fed_per_inc + F_sales_per_inc +
                        G_corp_per_inc + H_prop_per_inc)

  # Per-wealth ratios (cols J..O, /S)
  J_total_per_w  <- total_t / wealth
  K_ca_per_w     <- ca_tax  / wealth
  L_fed_per_w    <- fed_tax / wealth
  M_sales_per_w  <- sales_t / wealth
  N_corp_per_w   <- corp_t  / wealth
  O_prop_per_w   <- prop_t  / wealth
  P_check_w      <- J_total_per_w -
                     (K_ca_per_w + L_fed_per_w + M_sales_per_w +
                      N_corp_per_w + O_prop_per_w)

  R_inc_per_w    <- econ_i / wealth

  panel <- tibble::tibble(
    year = yrs,
    total_tax_per_income     = C_total_per_inc,
    ca_inctax_per_income     = D_ca_per_inc,
    fed_inctax_per_income    = E_fed_per_inc,
    sales_tax_per_income     = F_sales_per_inc,
    corp_tax_per_income      = G_corp_per_inc,
    property_tax_per_income  = H_prop_per_inc,
    check_income_decomp      = I_check_inc,
    total_tax_per_wealth     = J_total_per_w,
    ca_inctax_per_wealth     = K_ca_per_w,
    fed_inctax_per_wealth    = L_fed_per_w,
    sales_tax_per_wealth     = M_sales_per_w,
    corp_tax_per_wealth      = N_corp_per_w,
    property_tax_per_wealth  = O_prop_per_w,
    check_wealth_decomp      = P_check_w,
    income_per_wealth        = R_inc_per_w,
    avg_wealth_m             = wealth,
    economic_income_m        = econ_i
  )

  # Sub-period averages (rows 27, 28 of the sheet)
  panel_cols <- setdiff(names(panel), "year")
  avg_2004_2016 <- vapply(panel_cols,
                          \(col) mean(panel[[col]][panel$year %in% 2004:2016]),
                          numeric(1))
  avg_2017_2025 <- vapply(panel_cols,
                          \(col) mean(panel[[col]][panel$year %in% 2017:2025]),
                          numeric(1))
  # Excel re-derives the check cells in the avg row as J27-SUM(K27:O27),
  # not as the mean of the per-year checks; match that.
  avg_2004_2016["check_income_decomp"] <-
    avg_2004_2016["total_tax_per_income"] -
      sum(avg_2004_2016[c("ca_inctax_per_income", "fed_inctax_per_income",
                          "sales_tax_per_income", "corp_tax_per_income",
                          "property_tax_per_income")])
  avg_2004_2016["check_wealth_decomp"] <-
    avg_2004_2016["total_tax_per_wealth"] -
      sum(avg_2004_2016[c("ca_inctax_per_wealth", "fed_inctax_per_wealth",
                          "sales_tax_per_wealth", "corp_tax_per_wealth",
                          "property_tax_per_wealth")])
  avg_2017_2025["check_income_decomp"] <-
    avg_2017_2025["total_tax_per_income"] -
      sum(avg_2017_2025[c("ca_inctax_per_income", "fed_inctax_per_income",
                          "sales_tax_per_income", "corp_tax_per_income",
                          "property_tax_per_income")])
  avg_2017_2025["check_wealth_decomp"] <-
    avg_2017_2025["total_tax_per_wealth"] -
      sum(avg_2017_2025[c("ca_inctax_per_wealth", "fed_inctax_per_wealth",
                          "sales_tax_per_wealth", "corp_tax_per_wealth",
                          "property_tax_per_wealth")])

  averages <- tibble::tibble(
    period = c("2004-2016", "2017-2025"),
    !!!setNames(
      lapply(panel_cols, \(col) c(avg_2004_2016[[col]], avg_2017_2025[[col]])),
      panel_cols
    )
  )

  list(panel = panel, averages = averages)
}
