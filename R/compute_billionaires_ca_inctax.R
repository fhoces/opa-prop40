# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

.bci_memo1 <- function(bci) {
  # Memo 1: US top .001% IRS Pareto calibration (billionairesCAinctax rows
  # 58-72). Returns a list:
  #   $memo1            — the tibble exposed downstream
  #   $fed_tax_per_agi  — row 64 vector (used by D99 + the all-taxes block)
  #   $pct_overshoot    — row 72 vector indexed by panel year 2018..2023
  m1_cols <- c("B", "C", "D", "E", "F")          # IRS years 2018..2022
  read_row <- function(row) xls_cells_row(bci, m1_cols, row)

  n_returns        <- read_row(59)
  agi_cutoff_k     <- read_row(60)
  agi_avg_k        <- read_row(61)
  fed_tax_total_m  <- read_row(63)
  top10m_n         <- read_row(66)
  top10m_cutoff_k  <- read_row(67)
  top10m_agi_avg_k <- read_row(68)

  pareto_b_001     <- agi_avg_k / agi_cutoff_k                     # row 62
  fed_tax_per_agi  <- 1000 * (fed_tax_total_m / n_returns) / agi_avg_k  # row 64
  pareto_b_10m     <- top10m_agi_avg_k / top10m_cutoff_k           # row 69
  proj_cutoff_001  <- top10m_cutoff_k *
                       (top10m_n / n_returns)^(1 - 1 / pareto_b_10m)  # row 70
  proj_agi_001     <- proj_cutoff_001 * pareto_b_10m              # row 71
  pct_overshoot    <- (proj_agi_001 - agi_avg_k) / proj_agi_001    # row 72

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

  # Map to billionairesCAinctax panel-year offsets (G72 = F72 for 2023).
  pct_by_panel_year <- c(
    `2018` = pct_overshoot[1], `2019` = pct_overshoot[2],
    `2020` = pct_overshoot[3], `2021` = pct_overshoot[4],
    `2022` = pct_overshoot[5], `2023` = pct_overshoot[5]
  )

  list(
    memo1            = memo1,
    fed_tax_per_agi  = unname(fed_tax_per_agi),
    pct_overshoot    = pct_by_panel_year   # keep names; downstream uses ["2018"] etc.
  )
}

.bci_all_taxes <- function(yrs, proj_agi_top_corr, inc_top_w_rel,
                            ca_inctax_ca_b, m1_fed_tax_per_agi, D99,
                            agg, public_share_b, total_w_ca) {
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
  fed_to_ca_ratio[6]   <- fed_to_ca_ratio[5]              # G114 = F114
  fed_to_ca_ratio[7]   <- mean(fed_to_ca_ratio[1:3])       # H114 = AVG(B114:D114)
  fed_to_ca_ratio[8]   <- fed_to_ca_ratio[7]               # I114 = H114
  fed_inctax_b[6:8] <- ca_inctax_ca_b[6:8] * fed_to_ca_ratio[6:8]
  fed_inctax_b[9]   <- NA_real_

  # Rows 115-116 share + 11% gross-up on public assets.
  public_share         <- public_share_b
  sales_gross_up_public <- 0.11 * public_share

  # Rows 117-122, 130: pull data_sec_agg columns (years 2019..2025 only).
  pad <- function(v) c(NA_real_, v, NA_real_)
  ca_inctax_pub   <- pad(agg("S"))
  fed_inctax_pub  <- pad(agg("V"))
  corp_tax_pub    <- pad(agg("AC"))
  prop_tax_pub    <- pad(agg("AD"))
  sales_tax_pub   <- pad(agg("AB"))
  total_tax_pub   <- pad(agg("AF"))
  econ_income_pub <- pad(agg("AG"))
  public_wealth_b <- public_share * total_w_ca           # row 123

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
  per_ei           <- function(x) x / econ_income_pub
  tot_tax_per_ei   <- per_ei(total_tax_pub)
  ca_inctax_per_ei <- per_ei(ca_inctax_pub)
  fed_inctax_per_ei <- per_ei(fed_inctax_pub)
  corp_per_ei      <- per_ei(corp_tax_pub)
  prop_sales_per_ei <- per_ei(prop_tax_pub + sales_tax_pub)
  check_ei <- tot_tax_per_ei -
               (ca_inctax_per_ei + fed_inctax_per_ei + corp_per_ei + prop_sales_per_ei)

  # Rows 137-140: private-wealth share decomposition (BSZ Saez-Zucman national
  # accounts weights: passthroughs 46.8 + 25, private-C corps 61).
  private_share     <- 1 - public_share - sales_gross_up_public
  weight_passthrough <- 46.8 + 25
  weight_private_c   <- 61
  weight_total       <- weight_passthrough + weight_private_c
  passthrough_share  <- private_share * weight_passthrough / weight_total
  private_c_share    <- private_share * weight_private_c   / weight_total
  test_share         <- public_share + sales_gross_up_public + passthrough_share + private_c_share

  # Rows 141-145: imputed corporate, property, and sales taxes on private wealth.
  corp_tax_priv_c  <- corp_tax_pub * (private_c_share / public_share)
  corp_tax_div     <- 0.11 * corp_tax_pub
  prop_tax_priv    <- (prop_tax_pub / corp_tax_pub) * (corp_tax_priv_c + corp_tax_div)
  tot_corp_prop    <- (corp_tax_pub + prop_tax_pub) + corp_tax_priv_c + corp_tax_div + prop_tax_priv
  # Row 145: 3% sales tax on (AGI - CA inctax - fed inctax - 25% standard ded) × 0.5 propensity.
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
  # FTB row indices per year + per top-bracket position. 2022 sits at top
  # of sheet; 2018 at bottom. Fields:
  #   whole_year — (first, last) row of the year's 59-60 AGI brackets
  #                (use with ftb_sum_year() below).
  #   top_10m    — single row for the $10M+ bracket (2021 / 2022 only).
  #   top_5m_9m  — single row for the $5M-$9.999M bracket (2021 / 2022 only).
  #   top_5m     — single row for the $5M+ aggregate (2018-2020 only;
  #                later years split this into two rows).
  ftb_rows <- list(
    "2018" = list(whole_year = c(242, 300), top_5m  = 300),
    "2019" = list(whole_year = c(183, 241), top_5m  = 241),
    "2020" = list(whole_year = c(124, 182), top_5m  = 182),
    "2021" = list(whole_year = c(64,  123), top_10m = 123, top_5m_9m = 122),
    "2022" = list(whole_year = c(4,   63),  top_10m = 63,  top_5m_9m = 62)
  )
  ftb_sum_year <- function(col, yr, scale = 1) {
    rng <- ftb_rows[[as.character(yr)]]$whole_year
    ftb_sum(col, rng[1], rng[2], scale)
  }

  # FTB published statistics for 2023 that the workbook hand-enters (the
  # ftb_b4a sheet only goes through 2022). All from FTB's annual personal-
  # income-tax-statistics release.
  CA_AGI_2023_B          <- 1946170 / 1000  # G14: total CA AGI ($B)
  CA_INCTAX_2023_B       <- 97293 / 1000    # G15: total CA inctax ($B)
  TOP_5M_9M_2023_RETURNS <- 7463            # G32: # returns in $5m-9.999m
  TOP_5M_9M_2023_AGI_B   <- 51.097          # G33: AGI in $5m-9.999m ($B)
  TOP_5M_9M_2023_TAX_B   <- 48.479          # G34: taxable income in $5m-9.999m
  TOP_5M_9M_2023_INCTAX_B <- 4.347          # G35: tax in $5m-9.999m ($B)

  # ---- Memo 1: US top .001% income calibration (rows 58-72) ----------------
  m1            <- .bci_memo1(bci)
  memo1         <- m1$memo1
  m1_fed_tax_per_agi  <- m1$fed_tax_per_agi
  pct_overshoot_panel <- m1$pct_overshoot

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
  ftb_yrs_with_data <- 2018:2022
  # Row 13 (#returns): SUM(FTB col D) by year; 2023+ missing
  n_returns_ca <- c(
    vapply(ftb_yrs_with_data, function(y) ftb_sum_year("D", y), numeric(1)),
    rep(NA_real_, 4)
  )
  # Row 14 (CA AGI $B): SUM(H) * 1e-9 for 2018-2022; 2023 literal (G14=1946170/1000)
  ca_agi_b <- c(
    vapply(ftb_yrs_with_data, function(y) ftb_sum_year("H", y, 1e-9), numeric(1)),
    CA_AGI_2023_B,
    rep(NA_real_, 3)
  )
  # Row 15 (CA inctax all residents $B): SUM(K)*1e-9 for 2018-2022; 2023 literal;
  # 2024, 2025 derived from row 18 - row 17
  ca_inctax_resid_b_pre <- c(
    vapply(ftb_yrs_with_data, function(y) ftb_sum_year("K", y, 1e-9), numeric(1)),
    CA_INCTAX_2023_B
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
  n_ret_10m[4] <- ftb_D[ftb_rows$`2021`$top_10m]      # E26 = D123 for 2021
  n_ret_10m[5] <- ftb_D[ftb_rows$`2022`$top_10m]      # F26 = D63 for 2022
  n_ret_10m[6] <- cell("G26")                     # G26 literal 4729
  # Row 27 (CA AGI $B $10m+): from FTB col H * 1e-9; G27 literal
  agi_10m_b <- rep(NA_real_, 6)
  agi_10m_b[4] <- ftb_H[ftb_rows$`2021`$top_10m] * 1e-9
  agi_10m_b[5] <- ftb_H[ftb_rows$`2022`$top_10m] * 1e-9
  agi_10m_b[6] <- cell("G27")                     # 150.394
  # Row 28 (taxable income $B $10m+): FTB col J for 2021/2022; G28 not present
  taxable_10m_b <- rep(NA_real_, 6)
  taxable_10m_b[4] <- ftb_J[ftb_rows$`2021`$top_10m] * 1e-9
  taxable_10m_b[5] <- ftb_J[ftb_rows$`2022`$top_10m] * 1e-9
  taxable_10m_b[6] <- cell("G28")                 # literal (no value in sheet, NA)
  # Row 29 (tax $B $10m+): FTB col K for 2021/2022; G29 literal
  tax_10m_b <- rep(NA_real_, 6)
  tax_10m_b[4] <- ftb_K[ftb_rows$`2021`$top_10m] * 1e-9
  tax_10m_b[5] <- ftb_K[ftb_rows$`2022`$top_10m] * 1e-9
  tax_10m_b[6] <- cell("G29")                     # literal
  # Row 30 = row 29 / row 28
  tax_rate_10m <- tax_10m_b / taxable_10m_b
  # Row 31 = 1000 * row 27 / (10 * row 26)
  pareto_b_10m <- 1000 * agi_10m_b / (10 * n_ret_10m)

  # Row 32 (# returns $5m+): formulas tie to FTB sheet differently by year
  n_ret_5m <- numeric(6)
  n_ret_5m[1] <- ftb_D[ftb_rows$`2018`$top_5m]                                    # B32 = D300
  n_ret_5m[2] <- ftb_D[ftb_rows$`2019`$top_5m]                                    # C32 = D241
  n_ret_5m[3] <- ftb_D[ftb_rows$`2020`$top_5m]                                    # D32 = D182
  n_ret_5m[4] <- ftb_D[ftb_rows$`2021`$top_5m_9m] + ftb_D[ftb_rows$`2021`$top_10m]      # E32 = D122+D123
  n_ret_5m[5] <- ftb_D[ftb_rows$`2022`$top_5m_9m] + ftb_D[ftb_rows$`2022`$top_10m]      # F32 = D62+D63
  n_ret_5m[6] <- TOP_5M_9M_2023_RETURNS + n_ret_10m[6]                       # G32
  # Row 33 (CA AGI $B $5m+): same pattern
  agi_5m_b <- numeric(6)
  agi_5m_b[1] <- ftb_H[ftb_rows$`2018`$top_5m] * 1e-9
  agi_5m_b[2] <- ftb_H[ftb_rows$`2019`$top_5m] * 1e-9
  agi_5m_b[3] <- ftb_H[ftb_rows$`2020`$top_5m] * 1e-9
  agi_5m_b[4] <- agi_10m_b[4] + ftb_H[ftb_rows$`2021`$top_5m_9m] * 1e-9            # E33 = E27 + H122*1e-9
  agi_5m_b[5] <- agi_10m_b[5] + ftb_H[ftb_rows$`2022`$top_5m_9m] * 1e-9
  agi_5m_b[6] <- agi_10m_b[6] + TOP_5M_9M_2023_AGI_B                          # G33
  # Row 34 (taxable income $B $5m+)
  taxable_5m_b <- numeric(6)
  taxable_5m_b[1] <- ftb_J[ftb_rows$`2018`$top_5m] * 1e-9
  taxable_5m_b[2] <- ftb_J[ftb_rows$`2019`$top_5m] * 1e-9
  taxable_5m_b[3] <- ftb_J[ftb_rows$`2020`$top_5m] * 1e-9
  taxable_5m_b[4] <- taxable_10m_b[4] + ftb_J[ftb_rows$`2021`$top_5m_9m] * 1e-9
  taxable_5m_b[5] <- taxable_10m_b[5] + ftb_J[ftb_rows$`2022`$top_5m_9m] * 1e-9
  taxable_5m_b[6] <- taxable_10m_b[6] + TOP_5M_9M_2023_TAX_B                  # G34
  # Row 35 (tax $B $5m+)
  tax_5m_b <- numeric(6)
  tax_5m_b[1] <- ftb_K[ftb_rows$`2018`$top_5m] * 1e-9
  tax_5m_b[2] <- ftb_K[ftb_rows$`2019`$top_5m] * 1e-9
  tax_5m_b[3] <- ftb_K[ftb_rows$`2020`$top_5m] * 1e-9
  tax_5m_b[4] <- tax_10m_b[4] + ftb_K[ftb_rows$`2021`$top_5m_9m] * 1e-9
  tax_5m_b[5] <- tax_10m_b[5] + ftb_K[ftb_rows$`2022`$top_5m_9m] * 1e-9
  tax_5m_b[6] <- TOP_5M_9M_2023_INCTAX_B + tax_10m_b[6]                       # G35
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
  all_taxes <- .bci_all_taxes(
    yrs                = yrs,
    proj_agi_top_corr  = proj_agi_top_corr,
    inc_top_w_rel      = inc_top_w_rel,
    ca_inctax_ca_b     = ca_inctax_ca_b,
    m1_fed_tax_per_agi = m1_fed_tax_per_agi,
    D99                = D99,
    agg                = agg,
    public_share_b     = public_share_b,
    total_w_ca         = total_w_ca
  )

  list(
    method1     = method1,
    memo1       = memo1,
    robustness  = robustness,
    all_taxes   = all_taxes
  )
}
