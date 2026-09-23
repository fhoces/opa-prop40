# Regenerate the golden-master snapshots in tests/snapshots/<vintage>/.
#
# Run from project root: Rscript tests/snapshot_regenerate.R
# (or BSZ_VINTAGE=may Rscript tests/snapshot_regenerate.R for the other vintage)
#
# Snapshots capture the current numeric output of every Phase-2 R re-derivation
# AND every Phase-3 exhibit (table tibbles + figure data layers), for the
# CURRENTLY ACTIVE vintage (BSZ_VINTAGE; default "august" - see
# R/ingest_excel.R's xlsx_path_default()). The corresponding testthat block
# (test-snapshots.R) asserts byte-level equality against
# tests/snapshots/<vintage>/ on every test run, so any refactor that changes a
# value is caught immediately - separately per vintage, since May and August
# legitimately produce different numbers from the same code.
#
# Re-run this script ONLY when an output change is intentional. Each
# regeneration should be its own commit with a clear "re-baseline" message
# explaining what changed.

stopifnot(dir.exists("R"), file.exists("_targets.R"))
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

SNAP_DIR <- file.path("tests/snapshots", bsz_vintage())
dir.create(SNAP_DIR, showWarnings = FALSE, recursive = TRUE)

save_snap <- function(obj, name) {
  path <- file.path(SNAP_DIR, paste0(name, ".rds"))
  saveRDS(obj, path, version = 2)
  cat(sprintf("  %-32s %s bytes\n", name,
              format(file.info(path)$size, big.mark = ",")))
}

# ---- Phase-1 inputs (read once, reused) -----------------------------------
agg_raw   <- extract_data_sec_all()
bci_raw   <- extract_billionaires_ca_inctax()
ftb_raw   <- extract_ftb_b4a()
top4_raw  <- extract_data_sec_top4()
srs_raw   <- extract_shortrunseries()
lrs_raw   <- extract_longrunseries()
dina_raw  <- extract_data_dina()
pareto_raw <- extract_pareto_missing()
tab2_raw  <- extract_tab2()
tab3_raw  <- extract_tab3()

# ---- Phase-2 R re-derivations --------------------------------------------
cat("Phase 2 (compute_*):\n")
data_sec_agg_r <- compute_data_sec_agg(agg_raw)
save_snap(data_sec_agg_r, "data_sec_agg_r")

pareto_missing_r <- compute_pareto_missing(pareto_raw)
save_snap(pareto_missing_r, "pareto_missing_r")

pareto_summary <- compute_pareto_summary(pareto_missing_r)
save_snap(pareto_summary, "pareto_summary")

tab5_r <- compute_tab5(pareto_missing_r, tab2_raw, tab3_raw)
save_snap(tab5_r, "tab5_r")

fig8_laffer_r <- compute_fig8_laffer()
save_snap(fig8_laffer_r, "fig8_laffer_r")

billionaires_ca_inctax_r <- compute_billionaires_ca_inctax(
  data_sec_agg_r, bci_raw, ftb_raw
)
save_snap(billionaires_ca_inctax_r, "billionaires_ca_inctax_r")

shortrunseries_r <- compute_shortrunseries(
  data_sec_agg_r, top4_raw, billionaires_ca_inctax_r, srs_raw
)
save_snap(shortrunseries_r, "shortrunseries_r")

top4taxes_r <- compute_top4taxes(top4_raw)
save_snap(top4taxes_r, "top4taxes_r")

# ---- Phase-3 exhibits: table tibbles -------------------------------------
cat("\nPhase 3 — table tibbles (attr 'panel' or 'panel_a' / 'panel_b'):\n")
tab1_gt    <- build_tab1(data_sec_agg_r, shortrunseries_r, lrs_raw, srs_raw)
save_snap(attr(tab1_gt, "panel_a"), "tab1_panel_a")
save_snap(attr(tab1_gt, "panel_b"), "tab1_panel_b")

tab2_gt    <- build_tab2(data_sec_agg_r, billionaires_ca_inctax_r, top4_raw)
save_snap(attr(tab2_gt, "panel"), "tab2_panel")

tab3_gt    <- build_tab3(top4_raw)
save_snap(attr(tab3_gt, "panel"), "tab3_panel")

tab4_gt    <- build_tab4(top4_raw)
save_snap(attr(tab4_gt, "panel"), "tab4_panel")

tab5_gt    <- build_tab5(tab5_r)
save_snap(attr(tab5_gt, "panel"), "tab5_panel")

tab_a1_gt  <- build_tab_a1(srs_raw, lrs_raw)
save_snap(attr(tab_a1_gt, "panel_a"), "tab_a1_panel_a")
save_snap(attr(tab_a1_gt, "panel_b"), "tab_a1_panel_b")

# ---- Phase-3 exhibits: figure data layers --------------------------------
# Single-ggplot figures: snapshot $data directly.
# Patchwork figures: snapshot each sub-plot's $data as <name>_panel_<i>.rds.
cat("\nPhase 3 — figure $data layers:\n")
save_fig <- function(obj, name) {
  if (inherits(obj, "patchwork")) {
    for (i in seq_along(obj)) {
      save_snap(obj[[i]]$data, paste0(name, "_panel_", i))
    }
  } else {
    save_snap(obj$data, name)
  }
}
save_fig(build_fig1(shortrunseries_r),                                       "fig1")
save_fig(build_fig2(lrs_raw),                                                "fig2")
save_fig(build_fig3(shortrunseries_r),                                       "fig3")
save_fig(build_fig4(billionaires_ca_inctax_r),                               "fig4")
save_fig(build_fig5(top4_raw),                                               "fig5")
save_fig(build_fig6(top4taxes_r),                                            "fig6")
save_fig(build_fig7(top4taxes_r, dina_raw),                                  "fig7")
save_fig(build_fig8(fig8_laffer_r),                                          "fig8")
save_fig(build_fig_a1(xlsx_path_default()),                                  "fig_a1")
save_fig(build_fig_a2(shortrunseries_r),                                     "fig_a2")
save_fig(build_fig_a3(billionaires_ca_inctax_r),                             "fig_a3")
save_fig(build_fig_a4(pareto_missing_r),                                     "fig_a4")

cat("\nAll snapshots written to", SNAP_DIR, "\n")
cat("Snapshot count:", length(list.files(SNAP_DIR, pattern = "\\.rds$")), "\n")
