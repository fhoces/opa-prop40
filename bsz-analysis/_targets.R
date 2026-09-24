library(targets)

tar_option_set(
  packages = c("tibble", "dplyr", "readxl", "cellranger", "gt", "ggplot2",
               "patchwork", "scales"),
  format = "rds"
)

invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))

list(
  tar_target(
    xlsx_path,
    xlsx_path_default(),
    format = "file"
  ),
  tar_target(sheet_names,           list_sheets(xlsx_path)),

  # Tier-1 extractors: rectangular, named columns
  tar_target(data_sec_codebook,     extract_data_sec_codebook(xlsx_path)),
  tar_target(data_sec_top4,         extract_data_sec_top4(xlsx_path)),
  tar_target(data_sec_all,          extract_data_sec_all(xlsx_path)),
  tar_target(data_sec_agg,          extract_data_sec_agg(xlsx_path)),
  tar_target(rtb_2026_industry,    extract_rtb_2026_industry(xlsx_path)),
  tar_target(pareto_missing,       extract_pareto_missing(xlsx_path)),
  tar_target(tab2,                 extract_tab2(xlsx_path)),
  tar_target(tab3,                 extract_tab3(xlsx_path)),

  # Tier-2/3 extractors: raw positional (letter-named columns)
  tar_target(longrunseries,         extract_longrunseries(xlsx_path)),
  tar_target(shortrunseries,        extract_shortrunseries(xlsx_path)),
  tar_target(data_dina,             extract_data_dina(xlsx_path)),
  tar_target(data_sec_propublica,   extract_data_sec_propublica(xlsx_path)),
  tar_target(billionaires_ca_inctax, extract_billionaires_ca_inctax(xlsx_path)),
  tar_target(ftb_b4a,                extract_ftb_b4a(xlsx_path)),

  # Phase 2 - re-derived from upstream inputs
  tar_target(data_sec_agg_r,        compute_data_sec_agg(data_sec_all)),
  tar_target(pareto_missing_r,      compute_pareto_missing(pareto_missing)),
  tar_target(pareto_summary,        compute_pareto_summary(pareto_missing_r)),
  tar_target(tab5_r,                compute_tab5(pareto_missing_r, tab2, tab3)),
  tar_target(fig8_laffer_r,         compute_fig8_laffer()),
  tar_target(billionaires_ca_inctax_r,
             compute_billionaires_ca_inctax(data_sec_agg_r,
                                            billionaires_ca_inctax,
                                            ftb_b4a)),
  tar_target(shortrunseries_r,
             compute_shortrunseries(data_sec_agg_r,
                                    data_sec_top4,
                                    billionaires_ca_inctax_r,
                                    shortrunseries)),
  tar_target(top4taxes_r,            compute_top4taxes(data_sec_top4)),

  # Phase 3 - gt tables + ggplot figures
  tar_target(tab1_gt,    build_tab1(data_sec_agg_r, shortrunseries_r, longrunseries,
                                    shortrunseries)),
  tar_target(tab1_html,  render_table_html(tab1_gt, "tab1"),  format = "file"),
  tar_target(tab1_latex, render_table_latex(tab1_gt, "tab1"), format = "file"),

  tar_target(tab2_gt,    build_tab2(data_sec_agg_r, billionaires_ca_inctax_r, data_sec_top4)),
  tar_target(tab2_html,  render_table_html(tab2_gt, "tab2"),  format = "file"),
  tar_target(tab2_latex, render_table_latex(tab2_gt, "tab2"), format = "file"),

  tar_target(tab3_gt,    build_tab3(data_sec_top4)),
  tar_target(tab3_html,  render_table_html(tab3_gt, "tab3"),  format = "file"),
  tar_target(tab3_latex, render_table_latex(tab3_gt, "tab3"), format = "file"),

  tar_target(tab4_gt,    build_tab4(data_sec_top4)),
  tar_target(tab4_html,  render_table_html(tab4_gt, "tab4"),  format = "file"),
  tar_target(tab4_latex, render_table_latex(tab4_gt, "tab4"), format = "file"),

  tar_target(tab5_gt,    build_tab5(tab5_r)),
  tar_target(tab5_html,  render_table_html(tab5_gt, "tab5"),  format = "file"),
  tar_target(tab5_latex, render_table_latex(tab5_gt, "tab5"), format = "file"),

  tar_target(tab_a1_gt,    build_tab_a1(shortrunseries, longrunseries)),
  tar_target(tab_a1_html,  render_table_html(tab_a1_gt, "tab_a1"),  format = "file"),
  tar_target(tab_a1_latex, render_table_latex(tab_a1_gt, "tab_a1"), format = "file"),

  tar_target(fig1,     build_fig1(shortrunseries_r)),
  tar_target(fig1_png, render_figure_png(fig1, "fig1"), format = "file"),
  tar_target(fig1_pdf, render_figure_pdf(fig1, "fig1"), format = "file"),

  tar_target(fig2,     build_fig2(longrunseries)),
  tar_target(fig2_png, render_figure_png(fig2, "fig2", width = 11, height = 5), format = "file"),
  tar_target(fig2_pdf, render_figure_pdf(fig2, "fig2", width = 11, height = 5), format = "file"),

  tar_target(fig3,     build_fig3(shortrunseries_r)),
  tar_target(fig3_png, render_figure_png(fig3, "fig3", width = 11, height = 5), format = "file"),
  tar_target(fig3_pdf, render_figure_pdf(fig3, "fig3", width = 11, height = 5), format = "file"),

  tar_target(fig4,     build_fig4(billionaires_ca_inctax_r)),
  tar_target(fig4_png, render_figure_png(fig4, "fig4"), format = "file"),
  tar_target(fig4_pdf, render_figure_pdf(fig4, "fig4"), format = "file"),

  tar_target(fig5,     build_fig5(data_sec_top4)),
  tar_target(fig5_png, render_figure_png(fig5, "fig5"), format = "file"),
  tar_target(fig5_pdf, render_figure_pdf(fig5, "fig5"), format = "file"),

  tar_target(fig6,     build_fig6(top4taxes_r)),
  tar_target(fig6_png, render_figure_png(fig6, "fig6", width = 11, height = 5), format = "file"),
  tar_target(fig6_pdf, render_figure_pdf(fig6, "fig6", width = 11, height = 5), format = "file"),

  tar_target(fig7,     build_fig7(top4taxes_r, data_dina)),
  tar_target(fig7_png, render_figure_png(fig7, "fig7", width = 11, height = 5), format = "file"),
  tar_target(fig7_pdf, render_figure_pdf(fig7, "fig7", width = 11, height = 5), format = "file"),

  tar_target(fig8,     build_fig8(fig8_laffer_r)),
  tar_target(fig8_png, render_figure_png(fig8, "fig8"), format = "file"),
  tar_target(fig8_pdf, render_figure_pdf(fig8, "fig8"), format = "file"),

  tar_target(fig_a1,     build_fig_a1(xlsx_path)),
  tar_target(fig_a1_png, render_figure_png(fig_a1, "fig_a1", width = 8, height = 6), format = "file"),
  tar_target(fig_a1_pdf, render_figure_pdf(fig_a1, "fig_a1", width = 8, height = 6), format = "file"),

  tar_target(fig_a2,     build_fig_a2(shortrunseries_r)),
  tar_target(fig_a2_png, render_figure_png(fig_a2, "fig_a2"), format = "file"),
  tar_target(fig_a2_pdf, render_figure_pdf(fig_a2, "fig_a2"), format = "file"),

  tar_target(fig_a3,     build_fig_a3(billionaires_ca_inctax_r)),
  tar_target(fig_a3_png, render_figure_png(fig_a3, "fig_a3", width = 11, height = 5), format = "file"),
  tar_target(fig_a3_pdf, render_figure_pdf(fig_a3, "fig_a3", width = 11, height = 5), format = "file"),

  tar_target(fig_a4,     build_fig_a4(pareto_missing_r)),
  tar_target(fig_a4_png, render_figure_png(fig_a4, "fig_a4", width = 11, height = 5), format = "file"),
  tar_target(fig_a4_pdf, render_figure_pdf(fig_a4, "fig_a4", width = 11, height = 5), format = "file"),

  # Site exports - data files for the public OPA pages under site/ (see
  # R/site_exports.R). They add no new reproduction: score_tab5_cell() is
  # pinned to tab5_r by tests/testthat/test-site.R.
  tar_target(site_scoring_inputs, tab5_scoring_inputs(pareto_missing_r, tab2, tab3)),
  tar_target(site_grid,           build_site_grid(site_scoring_inputs)),
  tar_target(site_inputs,         build_site_inputs(site_scoring_inputs)),
  tar_target(site_grid_csv,   write_site_csv(site_grid, "data/grid.csv"),     format = "file"),
  tar_target(site_inputs_csv, write_site_csv(site_inputs, "data/inputs.csv"), format = "file"),
  tar_target(site_tab5_csv,   write_site_csv(tab5_r, "data/tab5.csv"),        format = "file"),
  tar_target(site_leavers_csv,
             write_site_csv(site_scoring_inputs$leavers, "data/leavers.csv"), format = "file"),
  tar_target(site_tab5_printed, compare_tab5_printed(tab5_r)),
  tar_target(site_tab5_printed_csv,
             write_site_csv(site_tab5_printed, "data/tab5-vs-printed.csv"), format = "file"),
  tar_target(site_grid_js,    write_site_grid_js(site_grid, site_scoring_inputs), format = "file"),

  # Export contract for the comparison layer (R/export_contract.R): read off
  # existing targets only, same schema as rjkdc-analysis/export/r/.
  tar_target(export_inputs,  export_contract_inputs(site_scoring_inputs)),
  tar_target(export_outputs, export_contract_outputs(site_tab5_printed)),
  tar_target(export_inputs_csv,  write_export_csv(export_inputs, "inputs.csv"),   format = "file"),
  tar_target(export_outputs_csv, write_export_csv(export_outputs, "outputs.csv"), format = "file"),

  # Phase 4 - Quarto report. The render targets list every gt/figure object as
  # an explicit dependency so the report re-renders when any artifact changes.
  # Requires Quarto CLI on PATH (https://quarto.org/docs/get-started/).
  tar_target(report_qmd, "report.qmd", format = "file"),
  tar_target(report_html,
             render_report(report_qmd, "html",
                            tab1_gt, tab2_gt, tab3_gt, tab4_gt, tab5_gt, tab_a1_gt,
                            fig1, fig2, fig3, fig4, fig5, fig6, fig7, fig8,
                            fig_a1, fig_a2, fig_a3, fig_a4),
             format = "file"),
  tar_target(report_pdf,
             render_report(report_qmd, "pdf",
                            tab1_gt, tab2_gt, tab3_gt, tab4_gt, tab5_gt, tab_a1_gt,
                            fig1, fig2, fig3, fig4, fig5, fig6, fig7, fig8,
                            fig_a1, fig_a2, fig_a3, fig_a4),
             format = "file")
)
