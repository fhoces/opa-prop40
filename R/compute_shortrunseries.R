# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

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
