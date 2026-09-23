# Golden-master snapshot tests. The .rds files under tests/snapshots/ pin the
# exact numeric output of every Phase-2 R re-derivation and every Phase-3
# exhibit at the commit when they were captured.
#
# A refactor that changes ANY numeric value will fail these tests. Re-baseline
# only when the change is intentional: run `Rscript tests/snapshot_regenerate.R`
# and commit the updated .rds files with an explanatory message.

SNAP_DIR <- testthat::test_path("..", "snapshots")
load_snap <- function(name) {
  path <- file.path(SNAP_DIR, paste0(name, ".rds"))
  if (!file.exists(path)) {
    skip(sprintf("snapshot %s not found at %s", name, path))
  }
  readRDS(path)
}
# expect_equal with default tolerance still allows tiny FP noise from
# x87/SSE differences across builds; for true byte-equality we'd use
# tolerance = 0, but that's too strict for a 2-decade-old R numeric stack.
# Default tolerance (~1.5e-8) is what we want.
check_snap <- function(actual, name) {
  testthat::expect_equal(actual, load_snap(name))
}

# ---- Build everything once -----------------------------------------------
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

data_sec_agg_r       <- compute_data_sec_agg(agg_raw)
pareto_missing_r     <- compute_pareto_missing(pareto_raw)
pareto_summary_v     <- compute_pareto_summary(pareto_missing_r)
tab5_r_v             <- compute_tab5(pareto_missing_r, tab2_raw, tab3_raw)
fig8_laffer_r_v      <- compute_fig8_laffer()
b_r                  <- compute_billionaires_ca_inctax(data_sec_agg_r, bci_raw, ftb_raw)
shortrunseries_r_v   <- compute_shortrunseries(data_sec_agg_r, top4_raw, b_r, srs_raw)
top4taxes_r_v        <- compute_top4taxes(top4_raw)

# ---- Phase-2 output snapshots --------------------------------------------
test_that("data_sec_agg_r matches snapshot",          check_snap(data_sec_agg_r,       "data_sec_agg_r"))
test_that("pareto_missing_r matches snapshot",        check_snap(pareto_missing_r,     "pareto_missing_r"))
test_that("pareto_summary matches snapshot",          check_snap(pareto_summary_v,     "pareto_summary"))
test_that("tab5_r matches snapshot",                  check_snap(tab5_r_v,             "tab5_r"))
test_that("fig8_laffer_r matches snapshot",           check_snap(fig8_laffer_r_v,      "fig8_laffer_r"))
test_that("billionaires_ca_inctax_r matches snapshot",check_snap(b_r,                  "billionaires_ca_inctax_r"))
test_that("shortrunseries_r matches snapshot",        check_snap(shortrunseries_r_v,   "shortrunseries_r"))
test_that("top4taxes_r matches snapshot",             check_snap(top4taxes_r_v,        "top4taxes_r"))

# ---- Phase-3 table panel snapshots ---------------------------------------
tab1_gt   <- build_tab1(data_sec_agg_r, shortrunseries_r_v, lrs_raw)
tab2_gt   <- build_tab2(data_sec_agg_r, b_r, top4_raw)
tab3_gt   <- build_tab3(top4_raw)
tab4_gt   <- build_tab4(top4_raw)
tab5_gt   <- build_tab5(tab5_r_v)
tab_a1_gt <- build_tab_a1(srs_raw, lrs_raw)

test_that("tab1 panel A matches snapshot",  check_snap(attr(tab1_gt,   "panel_a"), "tab1_panel_a"))
test_that("tab1 panel B matches snapshot",  check_snap(attr(tab1_gt,   "panel_b"), "tab1_panel_b"))
test_that("tab2 panel matches snapshot",    check_snap(attr(tab2_gt,   "panel"),   "tab2_panel"))
test_that("tab3 panel matches snapshot",    check_snap(attr(tab3_gt,   "panel"),   "tab3_panel"))
test_that("tab4 panel matches snapshot",    check_snap(attr(tab4_gt,   "panel"),   "tab4_panel"))
test_that("tab5 panel matches snapshot",    check_snap(attr(tab5_gt,   "panel"),   "tab5_panel"))
test_that("tab_a1 panel A matches snapshot",check_snap(attr(tab_a1_gt, "panel_a"), "tab_a1_panel_a"))
test_that("tab_a1 panel B matches snapshot",check_snap(attr(tab_a1_gt, "panel_b"), "tab_a1_panel_b"))

# ---- Phase-3 figure data-layer snapshots ---------------------------------
check_fig <- function(obj, name) {
  if (inherits(obj, "patchwork")) {
    for (i in seq_along(obj)) {
      check_snap(obj[[i]]$data, paste0(name, "_panel_", i))
    }
  } else {
    check_snap(obj$data, name)
  }
}

test_that("fig1 data matches snapshot",   check_fig(build_fig1(shortrunseries_r_v),                "fig1"))
test_that("fig2 data matches snapshot",   check_fig(build_fig2(lrs_raw),                            "fig2"))
test_that("fig3 data matches snapshot",   check_fig(build_fig3(shortrunseries_r_v),                "fig3"))
test_that("fig4 data matches snapshot",   check_fig(build_fig4(b_r),                                "fig4"))
test_that("fig5 data matches snapshot",   check_fig(build_fig5(top4_raw),                           "fig5"))
test_that("fig6 data matches snapshot",   check_fig(build_fig6(top4taxes_r_v),                      "fig6"))
test_that("fig7 data matches snapshot",   check_fig(build_fig7(top4taxes_r_v, dina_raw),            "fig7"))
test_that("fig8 data matches snapshot",   check_fig(build_fig8(fig8_laffer_r_v),                    "fig8"))
test_that("fig_a1 data matches snapshot", check_fig(build_fig_a1(xlsx_path_default()),              "fig_a1"))
test_that("fig_a2 data matches snapshot", check_fig(build_fig_a2(shortrunseries_r_v),               "fig_a2"))
test_that("fig_a3 data matches snapshot", check_fig(build_fig_a3(b_r),                              "fig_a3"))
test_that("fig_a4 data matches snapshot", check_fig(build_fig_a4(pareto_missing_r),                 "fig_a4"))
