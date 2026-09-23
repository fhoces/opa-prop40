library(targets)
library(tarchetypes)

tar_option_set(
  packages = c("tibble", "dplyr", "readxl", "ggplot2", "ggthemes"),
  format = "rds"
)

invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

list(
  # ---- Sec 5.1: Pareto fit + income-tax Monte Carlo (shared by both
  # versions; SSRN paper Sec 5.1, NBER README "Section 5.1 is shared") ----
  tar_target(pareto_fit, compute_pareto_fit()),
  tar_target(pareto_income_schedule, compute_pareto_income_schedule(pareto_fit)),
  tar_target(income_tax_mc, compute_income_tax_mc(pareto_income_schedule$tax_by_rank)),
  tar_target(income_tax_table8, income_tax_mc_table8(income_tax_mc)),

  # ---- Sec 4: revenue chain (94.20 -> 67.51 -> 55.10 -> 45.59) ----
  tar_target(rauh_workbook, rauh_workbook_path(), format = "file"),
  tar_target(calc_preferred, extract_calculations_preferred(rauh_workbook)),
  tar_target(calc_expanded, extract_calculations_expanded(rauh_workbook)),
  tar_target(revenue_chain, compute_revenue_chain(calc_preferred, calc_expanded)),

  # ---- Sec 5.2-5.4: Table 9 / Table 10 (SSRN only - these scenario tables
  # do not appear in the NBER version) ----
  tar_target(npv_table9, compute_npv_table9()),
  tar_target(npv_table10, compute_npv_table10()),

  # ---- NBER bridge inputs, rebuilt from final.csv ----
  tar_target(nber_final_csv, rauh_nber_final_csv(), format = "file"),
  tar_target(nber_final, extract_nber_final(nber_final_csv)),
  tar_target(nber_ceiling, compute_nber_ceiling(nber_final)),

  # ---- Sec 5.5 NPV Monte Carlo, two versions side by side ----
  tar_target(npv_mc_ssrn, compute_npv_mc_ssrn()),
  tar_target(npv_mc_nber, compute_npv_mc_nber()),
  tar_target(npv_mc_ssrn_summary, npv_mc_ssrn$summary),
  tar_target(npv_mc_nber_summary, npv_mc_nber$summary),

  # Seed-free analytic cross-check (brief: E[WT] - E[f]E[C]E[1/r]).
  tar_target(npv_mc_ssrn_analytic_mean,
             npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045,
                                   f_mode = "ssrn", baseline_revenue = 94.2)),
  tar_target(npv_mc_nber_analytic_mean,
             npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045,
                                   f_mode = "nber", f_min = 0.30, f_max = 0.60)),

  # ---- export/r ----
  tar_target(export_inputs, compute_export_inputs(pareto_fit, revenue_chain, nber_ceiling)),
  tar_target(export_outputs, compute_export_outputs(pareto_fit, income_tax_table8, revenue_chain,
                                                     npv_table9, npv_mc_ssrn_summary,
                                                     npv_mc_nber_summary, nber_ceiling)),
  tar_target(export_inputs_csv,
             { readr_write(export_inputs, "export/r/inputs.csv"); "export/r/inputs.csv" },
             format = "file"),
  tar_target(export_outputs_csv,
             { readr_write(export_outputs, "export/r/outputs.csv"); "export/r/outputs.csv" },
             format = "file"),

  # ---- site/ exports (R/site.R): read-only consumers of the targets above ----
  # NBER revenue headline (PDF pp.22-23): q x recognized base from final.csv.
  tar_target(nber_collectible, compute_nber_collectible(nber_final)),
  # Explorer grid: 3^7 cells, analytic means + quadrature shares, seed-free.
  tar_target(site_grid, compute_site_grid(revenue_chain)),
  tar_target(site_headlines,
             compute_site_headlines(site_grid, npv_mc_ssrn_summary, npv_mc_nber_summary,
                                    npv_mc_ssrn_analytic_mean, npv_mc_nber_analytic_mean,
                                    revenue_chain, nber_collectible)),
  tar_target(site_headlines_csv,
             { readr_write(site_headlines, "site/data/headlines.csv"); "site/data/headlines.csv" },
             format = "file"),
  tar_target(site_grid_js,
             write_site_grid_js(site_grid, revenue_chain, site_headlines),
             format = "file")
)
