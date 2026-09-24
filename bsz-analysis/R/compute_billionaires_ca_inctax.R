# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.
#
# The billionairesCAinctax sheet has 727 formula cells. This file re-derives
# four blocks:
#   - Method I year panel (rows 6..55): aggregate CA tax stats + top-bracket
#     Pareto projection + CA inctax paid by CA billionaires.
#   - Memo 1: US top .001% IRS Pareto calibration (rows 58..72).
#   - Memo 2 robustness check (rows 76..105): scalar sanity check on the
#     Method I projection.
#   - All-taxes block (rows 110..153): decomposes the billionaire tax burden
#     into CA inctax / fed inctax / corporate / property+sales on public and
#     private wealth.
#
# Variable names track the Excel row/column they correspond to; helpers keep
# those names verbatim so a reader can cross-reference each line with the
# cell it replaces.

# ---------------------------------------------------------------------------
# Static lookups
# ---------------------------------------------------------------------------

# Maps short letter -> data_sec_agg_r column name. The Excel sheet stores
# years 2019..2025 in panel cols C..I; data_sec_agg_r is one row per year
# 2019..2025 (so a column from data_sec_agg_r is a 7-vector that fills the
# C..I positions).
.BCI_AGG_MAP <- c(
  C  = "forbes_worth",       D  = "forbes_public_worth",
  S  = "ca_income_tax",      V  = "fed_income_tax",
  AB = "sales_tax",          AC = "w_txt",
  AD = "w_tax_ppent",        AF = "total_tax",
  AG = "economic_income"
)

# FTB row indices per year + per top-bracket position. 2022 sits at top of
# sheet; 2018 at bottom. Fields:
#   whole_year: (first, last) row of the year's 59-60 AGI brackets.
#   top_10m: single row for the $10M+ bracket (2021 / 2022 only).
#   top_5m_9m: single row for the $5M-$9.999M bracket (2021 / 2022 only).
#   top_5m: single row for the $5M+ aggregate (2018-2020 only; later
#                years split this into two rows).
.BCI_FTB_ROWS <- list(
  "2018" = list(whole_year = c(242, 300), top_5m  = 300),
  "2019" = list(whole_year = c(183, 241), top_5m  = 241),
  "2020" = list(whole_year = c(124, 182), top_5m  = 182),
  "2021" = list(whole_year = c(64,  123), top_10m = 123, top_5m_9m = 122),
  "2022" = list(whole_year = c(4,   63),  top_10m = 63,  top_5m_9m = 62)
)

# FTB published statistics for 2023 that the workbook hand-enters because
# ftb_b4a only goes through 2022. All from FTB's annual personal-income-tax-
# statistics release.
.BCI_FTB_2023 <- list(
  ca_agi_b           = 1946170 / 1000,   # G14: total CA AGI ($B)
  ca_inctax_b        = 97293 / 1000,     # G15: total CA inctax ($B)
  top_5m_9m_returns  = 7463,             # G32: # returns in $5m-9.999m
  top_5m_9m_agi_b    = 51.097,           # G33: AGI in $5m-9.999m ($B)
  top_5m_9m_tax_b    = 48.479,           # G34: taxable income in $5m-9.999m
  top_5m_9m_inctax_b = 4.347             # G35: tax in $5m-9.999m ($B)
)

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

.bci_make_agg <- function(agg_r) {
  # Closure that returns one column of data_sec_agg_r given an Excel-column
  # letter (using .BCI_AGG_MAP). Result is a length-7 numeric (years 2019..2025).
  function(letter) agg_r[[.BCI_AGG_MAP[[letter]]]]
}

.bci_make_ftb <- function(ftb_b4a) {
  # Wrap ftb_b4a's four numeric-coerced columns plus the row-range lookup.
  ftb_cols <- list(
    D = suppressWarnings(as.numeric(ftb_b4a$D)),
    H = suppressWarnings(as.numeric(ftb_b4a$H)),
    J = suppressWarnings(as.numeric(ftb_b4a$J)),
    K = suppressWarnings(as.numeric(ftb_b4a$K))
  )
  ftb_sum <- function(col, row_lo, row_hi, scale = 1) {
    sum(ftb_cols[[col]][row_lo:row_hi], na.rm = TRUE) * scale
  }
  ftb_sum_year <- function(col, yr, scale = 1) {
    rng <- .BCI_FTB_ROWS[[as.character(yr)]]$whole_year
    ftb_sum(col, rng[1], rng[2], scale)
  }
  list(cols = ftb_cols, sum_year = ftb_sum_year, rows = .BCI_FTB_ROWS)
}

# ---------------------------------------------------------------------------
# Memo 1: US top .001% IRS Pareto calibration (rows 58-72)
# ---------------------------------------------------------------------------

.bci_memo1 <- function(bci) {
  # Returns a list:
  #   $memo1: the tibble exposed downstream
  #   $fed_tax_per_agi: row 64 vector (used by D99 + the all-taxes block)
  #   $pct_overshoot: row 72 vector indexed by panel year 2018..2023
  m1_cols <- c("B", "C", "D", "E", "F")          # IRS years 2018..2022
  read_row <- function(row) xls_cells_row(bci, m1_cols, bci_row(row))

  n_returns        <- read_row(59)
  agi_cutoff_k     <- read_row(60)
  agi_avg_k        <- read_row(61)
  fed_tax_total_m  <- read_row(63)
  top10m_n         <- read_row(66)
  top10m_cutoff_k  <- read_row(67)
  top10m_agi_avg_k <- read_row(68)

  pareto_b_001     <- agi_avg_k / agi_cutoff_k                            # row 62
  fed_tax_per_agi  <- 1000 * (fed_tax_total_m / n_returns) / agi_avg_k    # row 64
  pareto_b_10m     <- top10m_agi_avg_k / top10m_cutoff_k                  # row 69
  proj_cutoff_001  <- top10m_cutoff_k *
                       (top10m_n / n_returns)^(1 - 1 / pareto_b_10m)      # row 70
  proj_agi_001     <- proj_cutoff_001 * pareto_b_10m                      # row 71
  pct_overshoot    <- (proj_agi_001 - agi_avg_k) / proj_agi_001           # row 72

  memo1 <- tibble::tibble(
    year                = 2018:2022,
    n_returns           = n_returns,
    agi_cutoff_k        = agi_cutoff_k,
    agi_avg_k           = agi_avg_k,
    pareto_b_001        = unname(pareto_b_001),
    fed_tax_total_m     = fed_tax_total_m,
    fed_tax_per_agi     = unname(fed_tax_per_agi),
    n_returns_10m       = top10m_n,
    agi_cutoff_10m_k    = top10m_cutoff_k,
    agi_avg_10m_k       = top10m_agi_avg_k,
    pareto_b_10m        = unname(pareto_b_10m),
    proj_cutoff_001_k   = unname(proj_cutoff_001),
    proj_agi_001_k      = unname(proj_agi_001),
    pct_overshoot       = unname(pct_overshoot)
  )

  # Map to billionairesCAinctax panel year (G72 = F72 for 2023).
  pct_by_panel_year <- c(
    `2018` = pct_overshoot[1], `2019` = pct_overshoot[2],
    `2020` = pct_overshoot[3], `2021` = pct_overshoot[4],
    `2022` = pct_overshoot[5], `2023` = pct_overshoot[5]
  )

  list(
    memo1            = memo1,
    fed_tax_per_agi  = unname(fed_tax_per_agi),
    pct_overshoot    = pct_by_panel_year
  )
}

# ---------------------------------------------------------------------------
# Block B: aggregate CA income tax stats (rows 13-21)
# ---------------------------------------------------------------------------

.bci_aggregate_stats <- function(bci, ftb, tax_rate_5m, vintage = bsz_vintage()) {
  # Rows 13-21 (May numbering) of the Method I panel: # returns, CA AGI, CA
  # inctax (residents / passthrough / part-year), totals, and the fiscal-year
  # -> calendar-year adjustment. Returns a list of length-9 vectors aligned to
  # years 2018..2026. `tax_rate_5m` is `.bci_top_brackets()`'s row-36 series
  # (needed only by the August branch below).
  #
  # August's row 15 ("CA income tax, all resident returns") changed formula:
  # its own label gained "(and adding shifted pass-through entity in 2021+)",
  # and for 2021-2023 it now ADDS the passthrough-entity tax directly, rather
  # than keeping it in a separate row added at total time. This is a genuine
  # formula change confirmed against both workbooks' cell formulas (openpyxl,
  # data_only=False) - not a row-shift artifact: every upstream input (the
  # FTB sums, the passthrough/part-year literals) is IDENTICAL between
  # vintages, yet the two workbooks' cached row totals differ, because August
  # folds passthrough into a different row and computes the 2021 passthrough
  # off the $5M-bracket tax RATE instead of off dollar amounts.
  cell <- function(addr) bci_cell(bci, addr)
  pan_cols <- c("B","C","D","E","F","G","H","I","J")
  ftb_yrs <- 2018:2022   # years where FTB B4A has bracket-level data

  # Row 13: # returns. Sum the year's FTB rows on col D.
  n_returns_ca <- c(
    vapply(ftb_yrs, function(y) ftb$sum_year("D", y), numeric(1)),
    rep(NA_real_, 4)
  )
  # Row 14: total CA AGI ($B). FTB col H * 1e-9 for 2018-2022; 2023 literal.
  ca_agi_b <- c(
    vapply(ftb_yrs, function(y) ftb$sum_year("H", y, 1e-9), numeric(1)),
    .BCI_FTB_2023$ca_agi_b,
    rep(NA_real_, 3)
  )
  # Row 15 base (CA inctax residents $B, BEFORE any August passthrough fold):
  # FTB col K * 1e-9 for 2018-2022; 2023 literal. Identical in both vintages.
  ca_inctax_resid_base <- c(
    vapply(ftb_yrs, function(y) ftb$sum_year("K", y, 1e-9), numeric(1)),
    .BCI_FTB_2023$ca_inctax_b
  )

  # "row16" here always means the May-numbered passthrough row; `cell()`
  # resolves it to the correct physical row per vintage via bci_row().
  passthrough_2023 <- cell("G16")   # 15.219, unchanged literal both vintages

  if (identical(vintage, "may")) {
    # Row 16 passthrough: literal G16 (2023); F16 (2022) scales it by the
    # ratio of row-15 values; E16 (2021) = F16.
    F16 <- passthrough_2023 * ca_inctax_resid_base[5] / ca_inctax_resid_base[6]
    E16 <- F16
    pre_part16 <- c(NA, NA, NA, E16, F16, passthrough_2023)

    ca_inctax_resid_pre <- ca_inctax_resid_base

    # Row 17 part-year / non-resident: F17 literal; every other column scales
    # the SAME column's row-15 value by the constant ratio (F17 / row15-F).
    F17 <- cell("F17")
    ratio_partyear <- F17 / ca_inctax_resid_pre[5]
    pre_part17 <- c(ca_inctax_resid_pre[1:4] * ratio_partyear, F17,
                     ca_inctax_resid_pre[6] * ratio_partyear)

    # Row 18 (total) = row 15 + row 16 + row 17.
    ca_inctax_total_pre <- ca_inctax_resid_pre +
                            ifelse(is.na(pre_part16), 0, pre_part16) +
                            pre_part17
  } else {
    # August: passthrough (2022, 2023) is now a FLAT 15.219 (no 2022/2023
    # ratio scaling); 2021's passthrough is scaled off the $5M-bracket
    # effective tax RATE (tax_rate_5m[2020] vs [2021] vs [2023] - ported
    # verbatim from the cell formula: `=F17*($D$37-$E$37)/($D$37-$G$37)`,
    # where D/E/G37 = tax_rate_5m at indices 3/4/6 = 2020/2021/2023).
    passthrough_2022 <- passthrough_2023
    passthrough_2021 <- passthrough_2022 *
      (tax_rate_5m[3] - tax_rate_5m[4]) / (tax_rate_5m[3] - tax_rate_5m[6])
    pre_part16 <- rep(NA_real_, 6)   # nothing added separately at total time

    ca_inctax_resid_pre <- ca_inctax_resid_base
    ca_inctax_resid_pre[4] <- ca_inctax_resid_base[4] + passthrough_2021
    ca_inctax_resid_pre[5] <- ca_inctax_resid_base[5] + passthrough_2022
    ca_inctax_resid_pre[6] <- ca_inctax_resid_base[6] + passthrough_2023

    # Row 18 (August's part-year row, "row17" in May-numbered `cell()`
    # calls): same shape as May's row 17, but against the now-folded row-15
    # base, which changes the ratio's denominator (and hence every column's
    # value, even 2018-2020 which the fold itself never touched).
    F_partyear <- cell("F17")
    ratio_partyear <- F_partyear / ca_inctax_resid_pre[5]
    pre_part17 <- c(ca_inctax_resid_pre[1:4] * ratio_partyear, F_partyear,
                     ca_inctax_resid_pre[6] * ratio_partyear)

    # Row 19 (total) = row 15 + row 18 only (passthrough already folded in).
    ca_inctax_total_pre <- ca_inctax_resid_pre + pre_part17
  }

  # Row 20 (May) / row 21 (August): CA inctax revenue, fiscal year ($B).
  # Literal in sheet.
  ca_inctax_fy_b <- xls_cells_row(bci, pan_cols, bci_row(20))

  # Row 21 (May) / row 22 (August): fy-to-cy adjustment = total/fy - 1.
  ca_inctax_total_full <- numeric(9)
  ca_inctax_total_full[1:6] <- ca_inctax_total_pre
  fy_to_cy_adj <- numeric(9)
  fy_to_cy_adj[1:6] <- ca_inctax_total_pre / ca_inctax_fy_b[1:6] - 1
  fy_to_cy_adj[7] <- mean(fy_to_cy_adj[3:6])
  fy_to_cy_adj[8] <- fy_to_cy_adj[7]

  # Total for 2024/2025: fy figure * (1 + fy_to_cy_adj).
  ca_inctax_total_full[7] <- ca_inctax_fy_b[7] * (1 + fy_to_cy_adj[7])
  ca_inctax_total_full[8] <- ca_inctax_fy_b[8] * (1 + fy_to_cy_adj[8])
  ca_inctax_total_full[9] <- NA_real_

  # Residents for 2024/2025: backed out as total - part-year, with
  # part-year scaled off the 2023 part-year amount by the ratio of the new
  # total to the 2023 total.
  total_2023 <- ca_inctax_total_full[6]
  total_2024 <- ca_inctax_total_full[7]
  total_2025 <- ca_inctax_total_full[8]
  partyear_2023 <- pre_part17[6]
  partyear_2024 <- partyear_2023 * (total_2024 / total_2023)
  partyear_2025 <- partyear_2023 * (total_2025 / total_2023)
  resid_2024 <- total_2024 - partyear_2024
  resid_2025 <- total_2025 - partyear_2025

  list(
    n_returns_ca         = n_returns_ca,
    ca_agi_b             = ca_agi_b,
    ca_inctax_resid_b    = c(ca_inctax_resid_pre, resid_2024, resid_2025, NA_real_),
    ca_inctax_part16     = c(pre_part16, NA_real_, NA_real_, NA_real_),
    ca_inctax_part17     = c(pre_part17, partyear_2024, partyear_2025, NA_real_),
    ca_inctax_total_full = ca_inctax_total_full,
    ca_inctax_fy_b       = ca_inctax_fy_b,
    fy_to_cy_adj         = fy_to_cy_adj,
    H15                  = resid_2024,
    I15                  = resid_2025
  )
}

# ---------------------------------------------------------------------------
# Block C: top-bracket Pareto projection (rows 26-44)
# ---------------------------------------------------------------------------

.bci_top_brackets <- function(bci, ftb, n_ca_b, pct_overshoot_yr) {
  # Build the top-bracket inputs (#returns, AGI, taxable, tax) for the $10M+
  # and $5M+ brackets, then project AGI / tax for the top CA-billionaire-sized
  # taxpayer using a Pareto extrapolation. Years 2018..2023 only (panel B..G).
  cell <- function(addr) bci_cell(bci, addr)
  ftb_D <- ftb$cols$D; ftb_H <- ftb$cols$H
  ftb_J <- ftb$cols$J; ftb_K <- ftb$cols$K
  rows  <- ftb$rows
  scale_b <- 1e-9     # FTB columns are in $; outputs are $B

  # --- $10M+ bracket (rows 26-31) ---
  # 2018-2020 lack a dedicated $10M+ split; 2021/2022 use FTB rows;
  # 2023 is hand-entered literal in G26..G29.
  n_ret_10m     <- rep(NA_real_, 6)
  agi_10m_b     <- rep(NA_real_, 6)
  taxable_10m_b <- rep(NA_real_, 6)
  tax_10m_b     <- rep(NA_real_, 6)
  for (i_year in c(4, 5)) {
    yr <- as.character(2017 + i_year)         # i_year=4 -> 2021, =5 -> 2022
    r <- rows[[yr]]$top_10m
    n_ret_10m[i_year]     <- ftb_D[r]
    agi_10m_b[i_year]     <- ftb_H[r] * scale_b
    taxable_10m_b[i_year] <- ftb_J[r] * scale_b
    tax_10m_b[i_year]     <- ftb_K[r] * scale_b
  }
  n_ret_10m[6]     <- cell("G26")
  agi_10m_b[6]     <- cell("G27")
  taxable_10m_b[6] <- cell("G28")
  tax_10m_b[6]     <- cell("G29")

  tax_rate_10m  <- tax_10m_b / taxable_10m_b                # row 30
  pareto_b_10m  <- 1000 * agi_10m_b / (10 * n_ret_10m)      # row 31

  # --- $5M+ bracket (rows 32-37) ---
  # 2018-2020: single FTB row gives the whole $5M+ aggregate.
  # 2021-2022: must sum the $5M-$9.999M row with the $10M+ row.
  # 2023: 2023 literals (TOP_5M_9M_*) added to the $10M+ value.
  ftb_top5m <- function(col, yr) {
    r <- rows[[as.character(yr)]]$top_5m
    col[r] * scale_b
  }
  ftb_top5m_9m <- function(col, yr) {
    r <- rows[[as.character(yr)]]$top_5m_9m
    col[r] * scale_b
  }
  n_ret_5m     <- numeric(6)
  agi_5m_b     <- numeric(6)
  taxable_5m_b <- numeric(6)
  tax_5m_b     <- numeric(6)
  for (i_year in 1:3) {
    yr <- 2017 + i_year
    n_ret_5m[i_year]     <- ftb_D[rows[[as.character(yr)]]$top_5m]
    agi_5m_b[i_year]     <- ftb_top5m(ftb_H, yr)
    taxable_5m_b[i_year] <- ftb_top5m(ftb_J, yr)
    tax_5m_b[i_year]     <- ftb_top5m(ftb_K, yr)
  }
  for (i_year in c(4, 5)) {
    yr <- 2017 + i_year
    n_ret_5m[i_year]     <- ftb_D[rows[[as.character(yr)]]$top_5m_9m] +
                              ftb_D[rows[[as.character(yr)]]$top_10m]
    agi_5m_b[i_year]     <- agi_10m_b[i_year]     + ftb_top5m_9m(ftb_H, yr)
    taxable_5m_b[i_year] <- taxable_10m_b[i_year] + ftb_top5m_9m(ftb_J, yr)
    tax_5m_b[i_year]     <- tax_10m_b[i_year]     + ftb_top5m_9m(ftb_K, yr)
  }
  n_ret_5m[6]     <- .BCI_FTB_2023$top_5m_9m_returns + n_ret_10m[6]
  agi_5m_b[6]     <- agi_10m_b[6] + .BCI_FTB_2023$top_5m_9m_agi_b
  taxable_5m_b[6] <- taxable_10m_b[6] + .BCI_FTB_2023$top_5m_9m_tax_b
  tax_5m_b[6]     <- tax_10m_b[6] + .BCI_FTB_2023$top_5m_9m_inctax_b

  tax_rate_5m  <- tax_5m_b / taxable_5m_b                   # row 36
  pareto_b_5m  <- 1000 * agi_5m_b / (5 * n_ret_5m)          # row 37

  # --- Row 38: projected cutoff ($M) for the top-N-th taxpayer ---
  # E-G38 (2021-2023): use $10M+ Pareto coefficient.
  # B-D38 (2018-2020): no $10M+ data; scale row-41 (5M Pareto) cutoff by
  # F38 / F41 (the 2022 ratio between the two estimates).
  proj_cutoff_top    <- numeric(6)
  proj_cutoff_top_5m <- 5 * (n_ret_5m / n_ca_b[1:6])^(1 - 1 / pareto_b_5m)
  for (i in 4:6) {
    proj_cutoff_top[i] <- 10 * (n_ret_10m[i] / n_ca_b[i])^(1 - 1 / pareto_b_10m[i])
  }
  F38 <- proj_cutoff_top[5]; F41 <- proj_cutoff_top_5m[5]
  for (i in 1:3) proj_cutoff_top[i] <- proj_cutoff_top_5m[i] * (F38 / F41)

  # --- Row 39: projected AGI ($B) for the top taxpayer ---
  # E-G39: 0.001 * row38 * row31 * row8
  # B-D39: scale row-42 (5M version) by F39 / F42.
  proj_agi_top      <- numeric(6)
  proj_agi_top_5m   <- 0.001 * proj_cutoff_top_5m * pareto_b_5m * n_ca_b[1:6]
  for (i in 4:6) proj_agi_top[i] <- 0.001 * proj_cutoff_top[i] * pareto_b_10m[i] * n_ca_b[i]
  F39 <- proj_agi_top[5]; F42 <- proj_agi_top_5m[5]
  for (i in 1:3) proj_agi_top[i] <- proj_agi_top_5m[i] * (F39 / F42)

  # --- Row 40: projected tax ($B) for the top taxpayer ---
  # B-D40 use the 5M tax rate; E-G40 use the 10M tax rate.
  proj_tax_top <- numeric(6)
  for (i in 1:3) proj_tax_top[i] <- proj_agi_top[i] * (tax_5m_b[i]  / agi_5m_b[i])
  for (i in 4:6) proj_tax_top[i] <- proj_agi_top[i] * (tax_10m_b[i] / agi_10m_b[i])

  # --- Rows 43-44: overshoot correction ---
  # Row 43 = row 39 * (1 - row 72 pct_overshoot).
  # Row 44 = row 40 * (1 - pct_overshoot); E-G44 additionally rescales by
  # AVERAGE($B$36:$D$36) / row30 (i.e. uses the 5M-bracket tax rate context).
  proj_agi_top_corr <- proj_agi_top * (1 - pct_overshoot_yr)
  proj_tax_top_corr <- proj_tax_top * (1 - pct_overshoot_yr)
  avg_tax_rate_5m_bcd <- mean(tax_rate_5m[1:3])
  for (i in 4:6) {
    proj_tax_top_corr[i] <- proj_tax_top_corr[i] * avg_tax_rate_5m_bcd / tax_rate_10m[i]
  }

  list(
    n_ret_10m          = n_ret_10m,
    agi_10m_b          = agi_10m_b,
    taxable_10m_b      = taxable_10m_b,
    tax_10m_b          = tax_10m_b,
    tax_rate_10m       = tax_rate_10m,
    pareto_b_10m       = pareto_b_10m,
    n_ret_5m           = n_ret_5m,
    agi_5m_b           = agi_5m_b,
    taxable_5m_b       = taxable_5m_b,
    tax_5m_b           = tax_5m_b,
    tax_rate_5m        = tax_rate_5m,
    pareto_b_5m        = pareto_b_5m,
    proj_cutoff_top    = proj_cutoff_top,
    proj_agi_top       = proj_agi_top,
    proj_tax_top       = proj_tax_top,
    proj_cutoff_top_5m = proj_cutoff_top_5m,
    proj_agi_top_5m    = proj_agi_top_5m,
    proj_agi_top_corr  = proj_agi_top_corr,
    proj_tax_top_corr  = proj_tax_top_corr
  )
}

# ---------------------------------------------------------------------------
# Memo 2 robustness check (rows 76-105)
# ---------------------------------------------------------------------------

.bci_robustness <- function(bci, D99, ca_inctax_ca_b, tax_5m_b, agi_5m_b) {
  # Scalar sanity check: average CA inctax rate at top × #residents in top
  # .0002% × Memo-1 correction (D99) ought to roughly match the average of
  # row 49 across 2018-2020. C105 is the residual; small means the Method I
  # projection is consistent with directly-observed FTB tax-rate aggregates.
  cell <- function(addr) bci_cell(bci, addr)
  B96 <- cell("B96")                                          # 172669 literal
  B100 <- D99 * B96 * sum(tax_5m_b[1:3]) / sum(agi_5m_b[1:3])
  B101 <- cell("B101")                                        # 90 literal
  B102 <- B101 * B100 / 1e6
  B103 <- mean(ca_inctax_ca_b[1:3])
  B104 <- mean(c(cell("D104"), cell("E104"), cell("F104")))
  B105 <- B102 * B103 / B104
  C105 <- B105 / B103 - 1

  list(D99 = D99, B100 = B100, B102 = B102,
        B103 = B103, B104 = B104, B105 = B105, C105 = C105)
}

# ---------------------------------------------------------------------------
# All-taxes block (rows 110-153)
# ---------------------------------------------------------------------------

.bci_all_taxes <- function(yrs, proj_agi_top_corr, inc_top_w_rel,
                            ca_inctax_ca_b, m1_fed_tax_per_agi, D99,
                            agg, public_share_b, total_w_ca,
                            vintage = bsz_vintage()) {
  # All-taxes block (billionairesCAinctax rows 110-153). Decomposes the tax
  # burden of CA billionaires into CA inctax / fed inctax / corporate /
  # property+sales on both PUBLIC-asset wealth (rows 117-129) and the broader
  # TOTAL wealth (rows 144-153), with sub-shares for private-C / passthrough
  # imputed from national-accounts weights (46.8 / 25 / 61).

  # Row 111: CA AGI for all CA Forbes billionaires.
  # B-G111 = row43 * row46 (proj_agi_corr * 0.5); H,I111 = $G111 * H,I112 / $G112.
  ca_agi_billionaires <- numeric(9)
  ca_agi_billionaires[1:6] <- proj_agi_top_corr * inc_top_w_rel[1:6]
  ca_agi_billionaires[7]   <- ca_agi_billionaires[6] * ca_inctax_ca_b[7] / ca_inctax_ca_b[6]
  ca_agi_billionaires[8]   <- ca_agi_billionaires[6] * ca_inctax_ca_b[8] / ca_inctax_ca_b[6]
  ca_agi_billionaires[9]   <- NA_real_

  # Row 113: Fed inctax billionaires.
  # B-F113 = row64(memo1) * row111 * D99; G,H,I113 = row112 * row114.
  fed_inctax_b <- numeric(9)
  fed_inctax_b[1:5] <- m1_fed_tax_per_agi * ca_agi_billionaires[1:5] * D99
  fed_to_ca_ratio <- rep(NA_real_, 9)
  fed_to_ca_ratio[1:5] <- fed_inctax_b[1:5] / ca_inctax_ca_b[1:5]
  fed_to_ca_ratio[6]   <- fed_to_ca_ratio[5]               # G114 = F114
  fed_to_ca_ratio[7]   <- mean(fed_to_ca_ratio[1:3])       # H114 = AVG(B114:D114)
  fed_to_ca_ratio[8]   <- fed_to_ca_ratio[7]               # I114 = H114
  fed_inctax_b[6:8] <- ca_inctax_ca_b[6:8] * fed_to_ca_ratio[6:8]
  fed_inctax_b[9]   <- NA_real_

  # Rows 115-116 (May) / 116-117 (August) share + gross-up on public assets.
  # The gross-up rate itself changed 11% -> 9.5% in August (a genuine
  # parameter update by the authors, confirmed by the row's own label text
  # and formula: May C116 = 0.11*C115, August C117 = 0.095*C116). The OTHER
  # 11% in this file (corp_tax_div below) is a different, unrelated constant
  # that did not change between vintages (verified against both workbooks'
  # formulas) - do not touch it.
  public_share         <- public_share_b
  sales_gross_up_public <- bci_sales_gross_up_rate() * public_share

  # Rows 117-122, 130: pull data_sec_agg columns (years 2019..2025 only).
  pad <- function(v) c(NA_real_, v, NA_real_)
  ca_inctax_pub   <- pad(agg("S"))
  fed_inctax_pub  <- pad(agg("V"))
  corp_tax_pub    <- pad(agg("AC"))
  prop_tax_pub    <- pad(agg("AD"))
  sales_tax_pub   <- pad(agg("AB"))
  total_tax_pub   <- pad(agg("AF"))
  econ_income_pub <- pad(agg("AG"))
  public_wealth_b <- public_share * total_w_ca                # row 123

  # Rows 124-128: per-public-wealth ratios.
  per_wealth        <- function(x) x / public_wealth_b
  tot_tax_per_w     <- per_wealth(total_tax_pub)
  ca_inctax_per_w   <- per_wealth(ca_inctax_pub)
  fed_inctax_per_w  <- per_wealth(fed_inctax_pub)
  corp_per_w        <- per_wealth(corp_tax_pub)
  prop_sales_per_w  <- per_wealth(prop_tax_pub + sales_tax_pub)
  check_w <- tot_tax_per_w -
              (ca_inctax_per_w + fed_inctax_per_w + corp_per_w + prop_sales_per_w)

  # Rows 131-135: per-economic-income ratios.
  per_ei            <- function(x) x / econ_income_pub
  tot_tax_per_ei    <- per_ei(total_tax_pub)
  ca_inctax_per_ei  <- per_ei(ca_inctax_pub)
  fed_inctax_per_ei <- per_ei(fed_inctax_pub)
  corp_per_ei       <- per_ei(corp_tax_pub)
  prop_sales_per_ei <- per_ei(prop_tax_pub + sales_tax_pub)
  check_ei <- tot_tax_per_ei -
               (ca_inctax_per_ei + fed_inctax_per_ei + corp_per_ei + prop_sales_per_ei)

  # Rows 137-140 (May) / 138-141 (August): private-wealth share decomposition
  # (BSZ Saez-Zucman national-accounts weights). The weights themselves
  # changed in August - confirmed against both workbooks' formulas (May:
  # passthrough 46.8+25=71.8, private-C 61; August: passthrough 93,
  # private-C 116) - a genuine methodology update, not a row-shift artifact.
  private_share     <- 1 - public_share - sales_gross_up_public
  if (identical(vintage, "may")) {
    weight_passthrough <- 46.8 + 25
    weight_private_c   <- 61
  } else {
    weight_passthrough <- 93
    weight_private_c   <- 116
  }
  weight_total       <- weight_passthrough + weight_private_c
  passthrough_share  <- private_share * weight_passthrough / weight_total
  private_c_share    <- private_share * weight_private_c   / weight_total
  test_share         <- public_share + sales_gross_up_public + passthrough_share + private_c_share

  # Rows 141-145 (May) / 142-146 (August): imputed corporate, property, and
  # sales taxes on private wealth.
  corp_tax_priv_c  <- corp_tax_pub * (private_c_share / public_share)
  corp_tax_div     <- 0.11 * corp_tax_pub
  prop_tax_priv    <- (prop_tax_pub / corp_tax_pub) * (corp_tax_priv_c + corp_tax_div)
  # August adds a NEW row ("Property taxes on passthrough") not present in
  # May: property tax imputed on the passthrough share specifically, using
  # (public_share + sales_gross_up_public) as its denominator (verified
  # formula: `=C121*C139/(C116+C117)`, i.e. prop_tax_pub * passthrough_share
  # / (public_share + sales_gross_up_public)). May's total simply omits this
  # term (it did not exist in that vintage's sheet).
  if (identical(vintage, "may")) {
    prop_tax_passthrough <- 0
  } else {
    prop_tax_passthrough <- prop_tax_pub * passthrough_share /
      (public_share + sales_gross_up_public)
  }
  tot_corp_prop    <- (corp_tax_pub + prop_tax_pub) + corp_tax_priv_c + corp_tax_div +
                       prop_tax_priv + prop_tax_passthrough
  # Row 145 (May) / 147 (August): 3% sales tax on (AGI - CA inctax - fed
  # inctax - 25% standard ded) × 0.5 propensity.
  total_sales_tax  <- 0.03 * (ca_agi_billionaires - ca_inctax_ca_b - fed_inctax_b -
                               0.25 * ca_agi_billionaires) * 0.5
  total_inctax_b   <- ca_inctax_ca_b + fed_inctax_b
  total_taxes_b    <- tot_corp_prop + total_sales_tax + total_inctax_b

  # Rows 148-152: per-total-wealth ratios.
  per_total_w      <- function(x) x / total_w_ca
  tot_per_total_w  <- per_total_w(total_taxes_b)
  ca_per_total_w   <- per_total_w(ca_inctax_ca_b)
  fed_per_total_w  <- per_total_w(fed_inctax_b)
  corp_per_total_w <- per_total_w(corp_tax_pub + corp_tax_priv_c + corp_tax_div)
  ps_per_total_w   <- per_total_w(prop_tax_pub + prop_tax_priv + total_sales_tax)
  check_total      <- tot_per_total_w -
                       (ca_per_total_w + fed_per_total_w + corp_per_total_w + ps_per_total_w)

  tibble::tibble(
    year                          = yrs,
    ca_agi_ca_billionaires_b      = ca_agi_billionaires,
    ca_inctax_ca_billionaires_b   = ca_inctax_ca_b,
    fed_inctax_ca_billionaires_b  = fed_inctax_b,
    fed_to_ca_inctax_ratio        = fed_to_ca_ratio,
    public_assets_share           = public_share,
    sales_gross_up_public         = sales_gross_up_public,
    ca_inctax_public_b            = ca_inctax_pub,
    fed_inctax_public_b           = fed_inctax_pub,
    corp_tax_public_b             = corp_tax_pub,
    property_tax_public_b         = prop_tax_pub,
    sales_tax_public_b            = sales_tax_pub,
    total_tax_public_b            = total_tax_pub,
    public_wealth_b               = public_wealth_b,
    total_tax_per_public_wealth   = tot_tax_per_w,
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
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

compute_billionaires_ca_inctax <- function(data_sec_agg_r,
                                            billionaires_ca_inctax,
                                            ftb_b4a) {
  bci  <- billionaires_ca_inctax
  cell <- function(addr) bci_cell(bci, addr)
  agg  <- .bci_make_agg(data_sec_agg_r)
  ftb  <- .bci_make_ftb(ftb_b4a)

  # ---- Memo 1 + D99 correction --------------------------------------------
  m1 <- .bci_memo1(bci)
  # D99 = (Memo 2 implied fed-tax rate) / (Memo 1 fed-tax rate, 2018-2020 avg)
  B96 <- cell("B96"); B98 <- cell("B98")
  D99 <- (B98 / B96) / mean(m1$fed_tax_per_agi[1:3])

  # ---- Method I year panel (rows 6..55) -----------------------------------
  yrs <- 2018:2026
  pan_cols <- c("B","C","D","E","F","G","H","I","J")

  # Block A: CA billionaires (rows 8-10).
  n_ca_b     <- xls_cells_row(bci, pan_cols, bci_row(8))
  total_w_ca <- c(NA_real_, agg("C"), NA_real_)
  avg_w_ca   <- total_w_ca / n_ca_b

  # Block C: top-bracket Pareto projection (rows 26-44). Computed BEFORE
  # block B because August's row-15 passthrough fold (see
  # .bci_aggregate_stats) needs this block's tax_rate_5m series.
  pct_overshoot_yr <- unname(m1$pct_overshoot[c("2018","2019","2020","2021","2022","2023")])
  brk <- .bci_top_brackets(bci, ftb, n_ca_b, pct_overshoot_yr)

  # Block B: aggregate CA income tax stats (rows 13-21).
  stats <- .bci_aggregate_stats(bci, ftb, tax_rate_5m = brk$tax_rate_5m)

  # Rows 46-47: literal correction factors.
  inc_top_w_rel <- c(rep(cell("B46"), 6), NA_real_, NA_real_, NA_real_)
  corr_passthru <- c(rep(D99,         6), NA_real_, NA_real_, NA_real_)

  # Row 49 (CA inctax paid by CA Forbes billionaires) -- MAIN OUTPUT.
  # B-G49: row44 * row46 * row47; H49, I49 = row50 * row15 (computed below).
  ca_inctax_ca_b <- rep(NA_real_, 9)
  ca_inctax_ca_b[1:6] <- brk$proj_tax_top_corr * inc_top_w_rel[1:6] * corr_passthru[1:6]
  # Row 50 = row 49 / row 18. H50 = AVG(B50:G50); I50 = E50 (2021).
  pct_ca_inctax_by_b <- numeric(9)
  pct_ca_inctax_by_b[1:6] <- ca_inctax_ca_b[1:6] / stats$ca_inctax_total_full[1:6]
  pct_ca_inctax_by_b[7] <- mean(pct_ca_inctax_by_b[1:6])
  pct_ca_inctax_by_b[8] <- pct_ca_inctax_by_b[4]
  pct_ca_inctax_by_b[9] <- NA_real_
  ca_inctax_ca_b[7] <- pct_ca_inctax_by_b[7] * stats$H15
  ca_inctax_ca_b[8] <- pct_ca_inctax_by_b[8] * stats$I15

  # Row 51 = row 49 / row 10. Row 53 from data_sec_agg!S. Row 54 = D/C share.
  # Row 55 = row 53 / row 49.
  ca_inctax_b_per_w        <- ca_inctax_ca_b / total_w_ca
  ca_inctax_public_b       <- c(NA_real_, agg("S"), NA_real_)
  public_share_b           <- c(NA_real_, agg("D") / agg("C"), NA_real_)
  ca_inctax_public_per_b_b <- ca_inctax_public_b / ca_inctax_ca_b

  method1 <- tibble::tibble(
    year                          = yrs,
    n_ca_billionaires             = n_ca_b,
    avg_wealth_ca_b               = avg_w_ca,
    total_wealth_ca_b             = total_w_ca,
    n_returns_ca                  = stats$n_returns_ca,
    ca_agi_b                      = stats$ca_agi_b,
    ca_inctax_residents_b         = stats$ca_inctax_resid_b,
    ca_inctax_passthrough_b       = stats$ca_inctax_part16,
    ca_inctax_partyear_nonres_b   = stats$ca_inctax_part17,
    ca_inctax_total_b             = stats$ca_inctax_total_full,
    ca_inctax_fy_b                = stats$ca_inctax_fy_b,
    fy_to_cy_adjustment           = stats$fy_to_cy_adj,
    n_returns_10m                 = c(brk$n_ret_10m,     NA_real_, NA_real_, NA_real_),
    ca_agi_10m_b                  = c(brk$agi_10m_b,     NA_real_, NA_real_, NA_real_),
    ca_taxable_10m_b              = c(brk$taxable_10m_b, NA_real_, NA_real_, NA_real_),
    ca_tax_10m_b                  = c(brk$tax_10m_b,     NA_real_, NA_real_, NA_real_),
    ca_tax_rate_10m               = c(brk$tax_rate_10m,  NA_real_, NA_real_, NA_real_),
    pareto_b_10m_bracket          = c(brk$pareto_b_10m,  NA_real_, NA_real_, NA_real_),
    n_returns_5m                  = c(brk$n_ret_5m,      NA_real_, NA_real_, NA_real_),
    ca_agi_5m_b                   = c(brk$agi_5m_b,      NA_real_, NA_real_, NA_real_),
    ca_taxable_5m_b               = c(brk$taxable_5m_b,  NA_real_, NA_real_, NA_real_),
    ca_tax_5m_b                   = c(brk$tax_5m_b,      NA_real_, NA_real_, NA_real_),
    ca_tax_rate_5m                = c(brk$tax_rate_5m,   NA_real_, NA_real_, NA_real_),
    pareto_b_5m_bracket           = c(brk$pareto_b_5m,   NA_real_, NA_real_, NA_real_),
    proj_cutoff_top_pre_m         = c(brk$proj_cutoff_top,    NA_real_, NA_real_, NA_real_),
    proj_agi_top_pre_b            = c(brk$proj_agi_top,       NA_real_, NA_real_, NA_real_),
    proj_tax_top_pre_b            = c(brk$proj_tax_top,       NA_real_, NA_real_, NA_real_),
    proj_cutoff_top_5m_m          = c(brk$proj_cutoff_top_5m, NA_real_, NA_real_, NA_real_),
    proj_agi_top_5m_b             = c(brk$proj_agi_top_5m,    NA_real_, NA_real_, NA_real_),
    proj_agi_top_corr_b           = c(brk$proj_agi_top_corr,  NA_real_, NA_real_, NA_real_),
    proj_tax_top_corr_b           = c(brk$proj_tax_top_corr,  NA_real_, NA_real_, NA_real_),
    income_top_wealth_relative    = inc_top_w_rel,
    correction_passthrough        = corr_passthru,
    ca_inctax_ca_billionaires_b   = ca_inctax_ca_b,
    pct_ca_inctax_by_billionaires = pct_ca_inctax_by_b,
    ca_inctax_per_wealth          = ca_inctax_b_per_w,
    ca_inctax_public_assets_b     = ca_inctax_public_b,
    public_assets_share           = public_share_b,
    ca_inctax_public_share_of_total = ca_inctax_public_per_b_b
  )

  robustness <- .bci_robustness(bci, D99, ca_inctax_ca_b,
                                 brk$tax_5m_b, brk$agi_5m_b)

  all_taxes <- .bci_all_taxes(
    yrs                = yrs,
    proj_agi_top_corr  = brk$proj_agi_top_corr,
    inc_top_w_rel      = inc_top_w_rel,
    ca_inctax_ca_b     = ca_inctax_ca_b,
    m1_fed_tax_per_agi = m1$fed_tax_per_agi,
    D99                = D99,
    agg                = agg,
    public_share_b     = public_share_b,
    total_w_ca         = total_w_ca
  )

  list(
    method1    = method1,
    memo1      = m1$memo1,
    robustness = robustness,
    all_taxes  = all_taxes
  )
}
