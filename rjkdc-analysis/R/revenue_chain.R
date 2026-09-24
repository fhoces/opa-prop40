# Sec 4: the revenue chain 94.20 -> 67.51 -> 55.10, plus the 45.59
# literature-calibrated figure (paper pp.10-14). Ported from
# CA_Billionaires_Revenues_and_Migration_final.xlsx (workbook cell formulas
# enumerated with openpyxl, data_only=False/True; see port-excel-formula
# skill). Per-row formulas (sheet Calculations_Preferred / _Expanded,
# columns D "Net Worth", K "Total Residential Real Estate*", F "Moving?
# (Y/N)", O "5% Wealth Tax Revenues"):
#   L<r> = D<r> - K<r>                     (net worth net of real estate)
#   O<r> = L<r> * 0.05                     (5% wealth tax on that person)
# Summary_Preferred!C5 = SUM(O3:O214)/1e9                          -> 94.20B (baseline, no departures)
# Summary_Preferred!F5 = SUMIF(F="N", O3:O214)/1e9                 -> 67.51B (6 confirmed departures removed)
# Summary_Expanded!F5  = SUMIF(Calculations_Expanded!F="N", O)/1e9 -> 55.10B (10 departures removed)
# Summary_Preferred!F8 = (1 - 0.516) * 94.2                        -> 45.59B (literature-calibrated;
#   0.516 = 10.32 (Brulhart et al. migration semi-elasticity, eq.12) * 0.05 (tax rate, eq.13);
#   NOTE: this branch uses the literal 94.2, not the more precise C5 = 94.30426206 - see MISMATCHES.md #6)

read_calc_column <- function(path, sheet, col, rows = 3:214, col_name) {
  rng <- paste0(sheet, "!", col, min(rows), ":", col, max(rows))
  out <- suppressMessages(
    readxl::read_excel(path, range = rng, col_names = FALSE, col_types = "text")
  )[[1]]
  if (identical(col_name, "moving")) return(out)
  as.numeric(out)
}

read_calculations_sheet <- function(path, sheet) {
  tibble::tibble(
    net_worth = read_calc_column(path, sheet, "D", col_name = "net_worth"),
    trre      = read_calc_column(path, sheet, "K", col_name = "trre"),
    moving    = read_calc_column(path, sheet, "F", col_name = "moving"),
    wealth_tax_revenue = read_calc_column(path, sheet, "O", col_name = "wealth_tax_revenue")
  )
}

extract_calculations_preferred <- function(path = rauh_workbook_path()) {
  read_calculations_sheet(path, "Calculations_Preferred")
}

extract_calculations_expanded <- function(path = rauh_workbook_path()) {
  read_calculations_sheet(path, "Calculations_Expanded")
}

# Re-derive the per-row wealth tax revenue O = (D - K) * tax_rate, rather
# than trusting the cached O column, so a change to trre or net_worth would
# be caught (port-excel-formula step 3/4).
revenue_chain_row_wt <- function(df, tax_rate = 0.05) {
  (df$net_worth - df$trre) * tax_rate
}

compute_revenue_chain <- function(calc_preferred, calc_expanded,
                                   baseline_literal = 94.2,
                                   brulhart_semi_elasticity = 10.32,
                                   tax_rate = 0.05) {
  wt_preferred <- revenue_chain_row_wt(calc_preferred, tax_rate)
  wt_expanded  <- revenue_chain_row_wt(calc_expanded, tax_rate)

  baseline_precise   <- sum(wt_preferred) / 1e9
  confirmed6_ceiling  <- sum(wt_preferred[calc_preferred$moving == "N"]) / 1e9
  expanded10_estimate <- sum(wt_expanded[calc_expanded$moving == "N"]) / 1e9

  migration_share <- brulhart_semi_elasticity * tax_rate   # eq.13's I8 = K8*J8 -> 0.516
  literature_calibrated <- (1 - migration_share) * baseline_literal  # 45.5928

  list(
    baseline_precise = baseline_precise,             # 94.30 (Summary_Preferred!C5), paper prints 94.20
    baseline_literal = baseline_literal,              # 94.2, literal used downstream in F8 (MISMATCHES #6)
    confirmed6_ceiling = confirmed6_ceiling,           # 67.51 (Summary_Preferred!F5), paper 67.51
    expanded10_estimate = expanded10_estimate,         # 55.10 (Summary_Expanded!F5), paper 55.10
    migration_share = migration_share,                # 0.516
    literature_calibrated = literature_calibrated      # 45.59 (Summary_Preferred!F8), paper 45.59
  )
}
