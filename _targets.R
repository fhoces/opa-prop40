library(targets)

tar_option_set(
  packages = c("tibble", "dplyr", "readxl", "cellranger"),
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

  # Tier-2/3 extractors: raw positional (letter-named columns)
  tar_target(longrunseries,         extract_longrunseries(xlsx_path)),
  tar_target(shortrunseries,        extract_shortrunseries(xlsx_path)),
  tar_target(data_dina,             extract_data_dina(xlsx_path)),
  tar_target(data_sec_propublica,   extract_data_sec_propublica(xlsx_path)),
  tar_target(billionaires_ca_inctax, extract_billionaires_ca_inctax(xlsx_path)),
  tar_target(ftb_b4a,                extract_ftb_b4a(xlsx_path))
)
