# export/{r,py}/inputs.csv + outputs.csv. Schema fixed by the brief:
#   inputs.csv:  input_id, version, description, value, unit, label, provenance, source, page
#   outputs.csv: output_id, version, value, unit, printed_value, printed_page, abs_diff
# label in {data, research, guesswork, scenario} (OPA input taxonomy).

compute_export_inputs <- function(pareto_fit, revenue_chain, nber_ceiling) {
  # Monte Carlo ranges come from the simulation functions' own defaults, so the
  # contract always carries what the pipeline actually draws.
  mc_ssrn <- formals(compute_npv_mc_ssrn)
  mc_nber <- formals(compute_npv_mc_nber)
  tibble::tribble(
    ~input_id, ~version, ~description, ~value, ~unit, ~label, ~provenance, ~source, ~page,
    "n_billionaires", "both", "CA billionaires in the domestic base", 212, "count", "data", "public",
      "CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!D15", 11,
    "baseline_net_worth", "both", "Aggregate net worth, 212 domestic billionaires", 1894.8, "$B", "data", "public",
      "CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!E15", 11,
    "tax_rate", "both", "Statutory wealth tax rate", 0.05, "rate", "data", "public",
      "CA_Billionaires_Revenues_and_Migration_final.xlsx!Calculations_Preferred!N3", 10,
    "pareto_alpha", "both", "Pareto tail parameter fit to FTB AGI thresholds", pareto_fit$alpha, "coefficient", "research", "public",
      "monte_carlo_sim.R:33-44 (FTB PIT Annual Report 2024, Table B-4A)", 15,
    "bracket_tax_ty23", "both", "TY2023 tax liability, $10M+ AGI bracket", 11.1, "$B", "data", "public",
      "monte_carlo_sim.R:51 (FTB Table B-4A)", 15,
    "total_pit_fy25", "both", "Total FY2024-25 PIT collections", 130.0, "$B", "data", "public",
      "monte_carlo_sim.R:89 (CA State Controller cash receipts)", 15,
    "brulhart_semi_elasticity", "ssrn", "Migration semi-elasticity, Brulhart et al. (2022)", 10.32, "coefficient", "research", "public",
      "Summary_Preferred!I8 (paper eq.12)", 13,
    "wt_central_scenario", "ssrn", "Table 9 Central Scenario wealth tax revenue (literal input, not linked to Sec 4's chain)", 42.0, "$B", "scenario", "public",
      "NPV_calculations_5.2.xlsx!B12", 19,
    "rauh_mc_wt_min", "ssrn", "Monte Carlo wealth tax floor (literature-calibrated scenario; semi-elasticity about 12.6)", mc_ssrn$wt_min, "$B", "guesswork", "public",
      "NPV_dist.R (wt ~ U[35, 67.51]); paper eq.22 and Table 9", 20,
    "rauh_mc_c_min", "both", "Annual CA income tax of billionaires: lower bound of the draw", mc_ssrn$c_min, "$B/yr", "guesswork", "public",
      "NPV_dist.R; paper eq.23 (from the K=500 dispersion draw)", 20,
    "rauh_mc_c_max", "both", "Annual CA income tax of billionaires: upper bound of the draw", mc_ssrn$c_max, "$B/yr", "guesswork", "public",
      "NPV_dist.R; paper eq.23 (Pareto upper bound)", 20,
    "rauh_mc_r_min", "both", "Discount rate draw: lower bound", mc_ssrn$r_min, "rate", "research", "public",
      "NPV_dist.R:47; paper eq.24 (S&P 500 dividend yield anchor p.18; eq.18-20 instead specify r-g)", 20,
    "rauh_mc_r_max", "both", "Discount rate draw: upper bound", mc_ssrn$r_max, "rate", "research", "public",
      "NPV_dist.R:47; paper eq.24", 20,
    "nber_mc_f_min", "nber", "NBER departure fraction of the income tax base: lower bound (drawn independently of WT)", mc_nber$f_min, "share", "guesswork", "public",
      "NPV_dist_v8.R; Jaros and Rauh NBER c15504 Sec 5.4", 35,
    "nber_mc_f_max", "nber", "NBER departure fraction of the income tax base: upper bound", mc_nber$f_max, "share", "guesswork", "public",
      "NPV_dist_v8.R; Jaros and Rauh NBER c15504 Sec 5.4", 35,
    "q_litigation_survival", "nber", "Probability the Act survives constitutional challenge (ASC 740-10 more-likely-than-not)", 0.50, "probability", "guesswork", "public",
      "NBER_2026_litigation_weighted/README.md (assumptions table); not an explicit multiplier in NPV_dist_v8.R - see MISMATCHES.md #5", NA_real_,
    "nber_growth_rate", "nber", "Growth applied to the Jan-1-2026 snapshot to the Dec-31-2026 valuation date", 0.07, "rate", "data", "author-shared",
      "final.csv (net_worth_usd_7pct column); NBER README assumptions table", NA_real_,
    "nber_ceiling_hardcoded", "nber", "wt_max literal in NPV_dist_v8.R (script uses this, not the value re-derived from final.csv)", 72, "$B", "data", "author-shared",
      "NPV_dist_v8.R:19", NA_real_,
    "nber_ceiling_recomputed", "nber", "wt_max re-derived from final.csv: domestic total minus 7 removed_departed rows", nber_ceiling$ceiling_recomputed, "$B", "derived", "author-shared",
      "R/nber_final.R:compute_nber_ceiling() from final.csv", NA_real_,
    "nber_international_net_worth", "nber", "28 international billionaires excluded from the domestic base", nber_ceiling$international_net_worth, "$B", "data", "author-shared",
      "final.csv (panel == international, net_worth_usd)", NA_real_
  )
}

compute_export_outputs <- function(pareto_fit, income_tax_table8, revenue_chain,
                                    npv_table9, npv_mc_ssrn_summary,
                                    npv_mc_nber_summary, nber_ceiling) {
  abs_diff <- function(v, p) abs(v - p)

  central9 <- npv_table9[npv_table9$scenario == "central" & npv_table9$r == 0.015, ]

  rows <- tibble::tribble(
    ~output_id, ~version, ~value, ~unit, ~printed_value, ~printed_page,
    "pareto_alpha", "both", pareto_fit$alpha, "coefficient", 1.44, 15,
    "income_tax_mc_k212", "both", income_tax_table8$mean_fy25[income_tax_table8$K == 212], "$B", 5.76, 17,
    "income_tax_mc_k300", "both", income_tax_table8$mean_fy25[income_tax_table8$K == 300], "$B", 4.61, 17,
    "income_tax_mc_k500", "both", income_tax_table8$mean_fy25[income_tax_table8$K == 500], "$B", 3.31, 17,
    "revenue_baseline", "both", revenue_chain$baseline_precise, "$B", 94.20, 10,
    "revenue_confirmed6", "both", revenue_chain$confirmed6_ceiling, "$B", 67.51, 11,
    "revenue_expanded10", "both", revenue_chain$expanded10_estimate, "$B", 55.10, 13,
    "revenue_literature_calibrated", "ssrn", revenue_chain$literature_calibrated, "$B", 45.59, 14,
    "table9_central_npv_r015", "ssrn", central9$npv, "$B", -126.1, 19,
    "npv_mc_ssrn_mean", "ssrn", npv_mc_ssrn_summary$mean, "$B", -24.7, 20,
    "npv_mc_ssrn_median", "ssrn", npv_mc_ssrn_summary$median, "$B", -19.1, 20,
    "npv_mc_ssrn_sd", "ssrn", npv_mc_ssrn_summary$sd, "$B", 38.4, 20,
    "npv_mc_ssrn_pct_negative", "ssrn", npv_mc_ssrn_summary$pct_negative, "%", 71, 20,
    "nber_domestic_grown", "nber", nber_ceiling$domestic_total_grown, "$B", 100.9, NA_real_,
    "nber_ceiling", "nber", nber_ceiling$ceiling_recomputed, "$B", 72.06, NA_real_,
    "nber_international", "nber", nber_ceiling$international_net_worth, "$B", 146.3, NA_real_,
    "npv_mc_nber_mean", "nber", npv_mc_nber_summary$mean, "$B", -38.9, NA_real_,
    "npv_mc_nber_median", "nber", npv_mc_nber_summary$median, "$B", -35.3, NA_real_,
    "npv_mc_nber_pct_negative", "nber", npv_mc_nber_summary$pct_negative, "%", 85.2, NA_real_
  )
  rows$abs_diff <- abs_diff(rows$value, rows$printed_value)
  rows
}
