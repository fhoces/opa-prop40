# Single resolver for the authors' MIT-licensed repo (bjaros20/wealth_tax,
# pinned SHA 25e84ddbb67fe0293a64cd9108ed4d35d8ae37ab). Every path into RAUH
# goes through this one function, mirroring xlsx_path_default() in
# bsz-analysis/R/ingest_excel.R: one env var, one place that knows the
# default location.
#
# Default is relative to rjkdc-analysis/ (this project's working
# directory when targets/testthat run). While developing against the main
# checkout's gitignored copy, export RAUH_REPO_DIR to its absolute path.

rauh_repo_dir <- function() {
  Sys.getenv(
    "RAUH_REPO_DIR",
    unset = "original-materials/author-shared/2026-09-23_wealth_tax-repo"
  )
}

rauh_path <- function(...) file.path(rauh_repo_dir(), ...)

rauh_available <- function() dir.exists(rauh_repo_dir())

# Paths to the specific files the pipeline reads, all resolved through
# rauh_repo_dir() above.
rauh_workbook_path <- function() {
  rauh_path("NPV_data", "CA_Billionaires_Revenues_and_Migration_final.xlsx")
}

rauh_npv_calc_path <- function() {
  rauh_path("NPV_data", "NPV_calculations_5.2.xlsx")
}

rauh_income_tax_mc_script <- function() {
  rauh_path("NPV_data", "monte_carlo_sim.R")
}

rauh_npv_dist_script <- function() {
  rauh_path("NPV_data", "NPV_dist.R")
}

rauh_npv_dist_v8_script <- function() {
  rauh_path("NBER_2026_litigation_weighted", "NPV_data", "NPV_dist_v8.R")
}

rauh_nber_final_csv <- function() {
  rauh_path("NBER_2026_litigation_weighted", "NPV_data", "final.csv")
}
