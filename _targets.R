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
    "original-materials/BSZ_MainTablesFigures.xlsx",
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
  tar_target(tab1_gt,    build_tab1(data_sec_agg_r, shortrunseries_r, longrunseries)),
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
  tar_target(fig3_pdf, render_figure_pdf(fig3, "fig3", width = 11, height = 5), format = "file")
)
