library(targets)

tar_option_set(
  packages = c("tibble", "dplyr", "readxl"),
  format = "rds"
)

lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source)

list(
  tar_target(
    xlsx_path,
    "original-materials/BSZ_MainTablesFigures.xlsx",
    format = "file"
  ),
  tar_target(
    sheet_names,
    list_sheets(xlsx_path)
  )
)
