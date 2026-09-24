# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.
#
# The shortrunseries sheet has 268 formula cells covering three blocks:
#   - a wealth-growth PANEL (2018..2025, one row per year, ~33 columns)
#   - a SUMMARY block (rows 14..18: 2025 snapshots, 2019-2025 averages)
#   - a GROWTH table (cumulative + annualized growth from each base year to 2025)
#
# Variable names inside the helpers keep the Excel column letter as a prefix
# (e.g. `C_wealth`, `S_cum_2019`) so each R line can be cross-referenced with
# the cell it replaces. Don't rename without preserving that mapping.

# The 5 "top 5" billionaires, in Excel column order AJ..AN.
# Maps short name -> forbes_id used in data_sec_top4.
.SRS_TOP5 <- c(
  brin    = "sergey-brin",
  page    = "larry-page",
  zuck    = "mark-zuckerberg",
  ellison = "larry-ellison",
  huang   = "jensen-huang"
)

.srs_query_top5 <- function(top4, col, yrs) {
  # For a data_sec_top4 column + year span, return a named list with one
  # numeric vector per TOP5 billionaire (vector aligned to `yrs`).
  lapply(.SRS_TOP5, function(id) {
    vapply(yrs, function(y) {
      row <- top4[top4$forbes_id == id & top4$year == y, ]
      if (nrow(row) == 1L) row[[col]] else NA_real_
    }, numeric(1))
  })
}

.srs_panel_columns <- function(srs, agg, top4, m1, yrs, vintage = bsz_vintage()) {
  # Compute every Excel-column-letter vector that feeds either the panel
  # tibble, the summary block, or the growth table. Returns a named list
  # keyed by Excel column letter (B, C, ..., AH, plus tax_b): the LETTERS
  # here are always the MAY ones (the return list's own naming convention);
  # the actual sheet column read for each concept is resolved per-vintage via
  # `srs_col()` (R/vintage.R). Panel ROWS (6:13 = 2018:2025) are unchanged in
  # both vintages, so no row-mapping is needed here (only the summary/growth
  # blocks below the panel shifted rows; see srs_summary_row()).

  # Total CA billionaire wealth, US citizens only (never read from Excel:
  # this is R's own re-derivation, used as-is below).
  C_wealth <- c(NA_real_, agg$forbes_worth)

  K_ellison <- xls_cells_col(srs, srs_col("K_ellison", vintage), 6:13)
  Q_top5_incl_nonus <- xls_cells_col(srs, srs_col("Q_us_wealth", vintage), 6:13)

  # "CA wealth, US citizens only" memo column: present in May (column B) as a
  # standalone cached series; August dropped it and its own dependent
  # formulas (the "CA share in US billionaire wealth" / "CA inctax per
  # wealth" columns) fall back to the all-CA-billionaires total instead
  # (verified: August's AC7 = C7/X7 exactly, where May's equivalent V7 =
  # B7/Q7: the only thing that changed is which wealth total feeds the
  # ratio). Reuse C_wealth for August so every downstream formula below stays
  # vintage-agnostic.
  B_wealth_incl_nonus <- if (identical(vintage, "may")) {
    c(NA_real_, xls_cells_col(srs, "B", 7:13))
  } else {
    C_wealth
  }

  # Top-5 totals from data_sec_top4 "Total (excluding Ellison)" rows.
  total_excl <- top4[top4$forbes_id == "Total (excluding Ellison)" & top4$year %in% yrs, ]
  total_excl <- total_excl[order(total_excl$year), ]
  E_top5_total   <- total_excl$forbes_worth / 1000
  G_top5_company <- total_excl$public_worth / 1000
  H_share_public <- G_top5_company / E_top5_total

  # D / F: only the 2024 and 2025 rows have formulas in the sheet.
  # 2024 (row 12) = same as base; 2025 (row 13) = base * (1 - 0.05).
  D_wealth_w_avoid <- rep(NA_real_, 8)
  D_wealth_w_avoid[7] <- C_wealth[7]
  D_wealth_w_avoid[8] <- C_wealth[8] * (1 - 0.05)
  F_top5_w_avoid <- rep(NA_real_, 8)
  F_top5_w_avoid[7] <- E_top5_total[7]
  F_top5_w_avoid[8] <- E_top5_total[8] * (1 - 0.05)

  J_n_ca <- c(NA_real_, agg$n)

  # Growth / share derivations on the C and Q series.
  L_share_ellison <- K_ellison / C_wealth
  M_yoy_growth    <- c(NA_real_, C_wealth[-1] / C_wealth[-8] - 1)

  # Cumulative growth in C from base years. N7=0 by definition; O / P start
  # at panel row 10 / 11 (2022 / 2023).
  N_cum_2019 <- C_wealth / C_wealth[2] - 1
  N_cum_2019[1] <- NA_real_
  O_cum_2022 <- rep(NA_real_, 8); O_cum_2022[5:8] <- C_wealth[5:8] / C_wealth[5] - 1
  P_cum_2023 <- rep(NA_real_, 8); P_cum_2023[6:8] <- C_wealth[6:8] / C_wealth[6] - 1

  # Same shape on the Q (top-5 incl non-US) series.
  R_yoy <- c(NA_real_, Q_top5_incl_nonus[-1] / Q_top5_incl_nonus[-8] - 1)
  S_cum_2019 <- Q_top5_incl_nonus / Q_top5_incl_nonus[2] - 1
  S_cum_2019[1] <- NA_real_   # S6 empty in Excel
  S_cum_2019[2] <- NA_real_   # S7 empty (no formula)
  if (identical(vintage, "may")) {
    # S10 references B instead of Q: apparent typo in the original May
    # sheet, reproduced for fidelity. Verified this typo is gone in August
    # (its Z10 cell, the equivalent position, equals X10/X7-1, the standard
    # Q-based formula, not the B-based one), so no override there.
    S_cum_2019[5] <- B_wealth_incl_nonus[5] / B_wealth_incl_nonus[2] - 1
  }
  T_cum_2022 <- rep(NA_real_, 8)
  T_cum_2022[5:8] <- Q_top5_incl_nonus[5:8] / Q_top5_incl_nonus[5] - 1

  V_share_top5_in_total <- B_wealth_incl_nonus / Q_top5_incl_nonus

  # CA-tax columns: pull rows 49 (CA inctax paid by CA Forbes billionaires)
  # and 18 (CA inctax total) from billionairesCAinctax, mapped to panel year.
  m1_idx <- match(yrs, m1$year)
  X_ca_inctax           <- m1$ca_inctax_ca_billionaires_b[m1_idx]
  Y_ca_inctax_per_wealth <- X_ca_inctax / B_wealth_incl_nonus
  Z_ca_inctax_total     <- m1$ca_inctax_total_b[m1_idx]
  AA_share              <- X_ca_inctax / Z_ca_inctax_total

  # Top-5 SEC-derived CA inctax (data_sec_top4 "Total" col S / 1000).
  AE_top5_ca_inctax_sec  <- total_excl$ca_income_tax / 1000
  AD_top5_sec_tax_rate   <- AE_top5_ca_inctax_sec / G_top5_company
  AF_top5_share_of_total <- AE_top5_ca_inctax_sec / Z_ca_inctax_total

  # Per-billionaire CA income tax / 1000 (years 2018..2025), and the
  # top-3 / top-2 sums.
  tax_b <- lapply(.srs_query_top5(top4, "ca_income_tax", yrs), `/`, 1000)
  AG_top3 <- tax_b$brin + tax_b$page + tax_b$zuck
  AH_top2 <- tax_b$brin + tax_b$page

  list(
    B = B_wealth_incl_nonus, C = C_wealth, D = D_wealth_w_avoid,
    E = E_top5_total, F = F_top5_w_avoid, G = G_top5_company, H = H_share_public,
    J = J_n_ca, K = K_ellison, L = L_share_ellison, M = M_yoy_growth,
    N = N_cum_2019, O = O_cum_2022, P = P_cum_2023,
    Q = Q_top5_incl_nonus, R = R_yoy, S = S_cum_2019, T = T_cum_2022,
    V = V_share_top5_in_total,
    X = X_ca_inctax, Y = Y_ca_inctax_per_wealth, Z = Z_ca_inctax_total, AA = AA_share,
    AD = AD_top5_sec_tax_rate, AE = AE_top5_ca_inctax_sec, AF = AF_top5_share_of_total,
    AG = AG_top3, AH = AH_top2,
    tax_b = tax_b
  )
}

.srs_assemble_panel <- function(cols, yrs) {
  tibble::tibble(
    year                      = yrs,
    wealth_incl_nonus_b       = cols$B,
    wealth_us_citizens_b      = cols$C,
    wealth_w_avoid_b          = cols$D,
    top5_total_b              = cols$E,
    top5_w_avoid_b            = cols$F,
    top5_company_wealth_b     = cols$G,
    share_public              = cols$H,
    n_ca_billionaires         = cols$J,
    ellison_wealth_b          = cols$K,
    share_ellison             = cols$L,
    yoy_growth_wealth         = cols$M,
    cum_growth_from_2019      = cols$N,
    cum_growth_from_2022      = cols$O,
    cum_growth_from_2023      = cols$P,
    top5_incl_nonus_b         = cols$Q,
    top5_yoy_growth           = cols$R,
    top5_cum_growth_from_2019 = cols$S,
    top5_cum_growth_from_2022 = cols$T,
    share_ca_in_top5_b        = cols$V,
    ca_inctax_billionaires_b  = cols$X,
    ca_inctax_per_wealth      = cols$Y,
    ca_inctax_total_b         = cols$Z,
    ca_inctax_share_total     = cols$AA,
    top5_sec_tax_rate         = cols$AD,
    top5_sec_ca_inctax_b      = cols$AE,
    top5_sec_share_of_total   = cols$AF,
    top3_ca_inctax_sum_b      = cols$AG,
    top2_ca_inctax_sum_b      = cols$AH,
    brin_ca_inctax_b          = cols$tax_b$brin,
    page_ca_inctax_b          = cols$tax_b$page,
    zuck_ca_inctax_b          = cols$tax_b$zuck,
    ellison_ca_inctax_b       = cols$tax_b$ellison,
    huang_ca_inctax_b         = cols$tax_b$huang
  )
}

.srs_summary_2025 <- function(cols, top4) {
  # Cross-sectional block in rows 14..18 of the sheet:
  #   row 14 = 2026 (feb 1) PUBLIC-wealth snapshot of TOP 5 (= 2025 public)
  #   row 15 = 2019..2025 averages of cols X..AN
  #   row 16 = (2025 CA inctax) / (2025 public wealth)
  #   row 17 = 2025 TOTAL wealth (incl private) of TOP 5
  #   row 18 = row 14 / row 17 (public share by group)
  pub_2025 <- vapply(.srs_query_top5(top4, "public_worth", 2025),  `[`, numeric(1), 1L) / 1000
  tot_2025 <- vapply(.srs_query_top5(top4, "forbes_worth", 2025),  `[`, numeric(1), 1L) / 1000

  AG14 <- pub_2025[["brin"]] + pub_2025[["page"]] + pub_2025[["zuck"]]
  AH14 <- pub_2025[["brin"]] + pub_2025[["page"]]
  AG17 <- tot_2025[["brin"]] + tot_2025[["page"]] + tot_2025[["zuck"]]
  AH17 <- tot_2025[["brin"]] + tot_2025[["page"]]
  share_2025 <- pub_2025 / tot_2025
  AG18 <- AG14 / AG17
  AH18 <- AH14 / AH17

  # Row 15 averages over panel rows 7..13 (= years 2019..2025 = indices 2:8).
  idx <- 2:8
  X15  <- mean(cols$X[idx])
  Y15  <- mean(cols$Y[idx])
  AA15 <- mean(cols$AA[idx])
  AD15 <- mean(cols$AD[idx])
  AE15 <- mean(cols$AE[idx])
  AF15 <- AE15 / X15
  AG15 <- mean(cols$AG[idx])
  AH15 <- mean(cols$AH[idx])
  tax_b_avg <- vapply(cols$tax_b, function(v) mean(v[idx]), numeric(1))
  Q15 <- cols$V[8]   # =B13/Q13: share of CA top5 wealth in worldwide top5 wealth

  # Row 16 share-of-public-wealth on 2025 CA inctax.
  AG16 <- cols$AG[8] / AG14
  AH16 <- cols$AH[8] / AH14
  share_2025_tax <- vapply(names(.SRS_TOP5),
                            function(nm) cols$tax_b[[nm]][8] / pub_2025[[nm]],
                            numeric(1))

  list(
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
}

.srs_growth <- function(cols, yrs) {
  # Growth-summary block (rows 16..21 of the sheet's growth section): for
  # each base year 2019..2024, cumulative growth in B (incl non-US) and C
  # (US only) to 2025, plus the implied annualized growth on C.
  base_years <- c(2019, 2020, 2021, 2022, 2023, 2024)
  base_idx   <- match(base_years, yrs)
  yrs_to_2025 <- 2025 - base_years

  total_growth_incl <- cols$B[8] / cols$B[base_idx] - 1
  total_growth_excl <- cols$C[8] / cols$C[base_idx] - 1
  annualized_excl   <- (1 + total_growth_excl)^(1 / yrs_to_2025) - 1

  tibble::tibble(
    base_year               = base_years,
    yrs_to_2025             = yrs_to_2025,
    total_growth_incl_nonus = total_growth_incl,
    total_growth_us_only    = total_growth_excl,
    annualized_us_only      = annualized_excl
  )
}

compute_shortrunseries <- function(data_sec_agg_r,
                                    data_sec_top4,
                                    billionaires_ca_inctax_r,
                                    shortrunseries) {
  yrs  <- 2018:2025
  m1   <- billionaires_ca_inctax_r$method1
  cols <- .srs_panel_columns(
    srs   = shortrunseries,
    agg   = data_sec_agg_r,
    top4  = data_sec_top4,
    m1    = m1,
    yrs   = yrs
  )

  list(
    panel        = .srs_assemble_panel(cols, yrs),
    summary_2025 = .srs_summary_2025(cols, data_sec_top4),
    growth       = .srs_growth(cols, yrs)
  )
}
