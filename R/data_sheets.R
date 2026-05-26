read_rectangular <- function(sheet,
                             path = xlsx_path_default(),
                             skip = 3,
                             col_types = NULL,
                             n_max = Inf,
                             key_cols = NULL,
                             names = NULL) {
  n_cols <- length(col_types)
  if (is.null(col_types) || n_cols == 0) {
    stop("read_rectangular requires explicit col_types (clips width).")
  }
  if (is.null(names)) {
    col_names_arg <- TRUE
    first_row <- skip + 1L  # readxl consumes this row as headers
    data_rows <- if (is.finite(n_max)) n_max else NA_integer_
    last_row <- if (is.finite(n_max)) first_row + n_max else NA_integer_
  } else {
    col_names_arg <- names
    first_row <- skip + 2L  # skip past the workbook's own header row
    last_row <- if (is.finite(n_max)) first_row + n_max - 1L else NA_integer_
  }
  range <- cellranger::cell_limits(
    ul = c(first_row, 1L),
    lr = c(last_row, n_cols)
  )
  out <- readxl::read_excel(
    path = path,
    sheet = sheet,
    range = range,
    col_names = col_names_arg,
    col_types = col_types,
    .name_repair = "minimal"
  )
  if (!is.null(key_cols)) {
    keep <- Reduce(`&`, lapply(key_cols, function(k) !is.na(out[[k]])))
    out <- out[keep, , drop = FALSE]
  } else {
    keep <- rowSums(!is.na(out)) > 0
    out <- out[keep, , drop = FALSE]
  }
  tibble::as_tibble(out, .name_repair = "minimal")
}

extract_data_sec_codebook <- function(path = xlsx_path_default()) {
  out <- read_rectangular(
    "data_sec_codebook",
    path = path,
    skip = 3,
    col_types = c("text", "text", "text")
  )
  names(out) <- c("variable", "definition", "data_source")
  out$data_source[out$data_source == "\\"] <- NA_character_
  out
}

extract_data_sec_top4 <- function(path = xlsx_path_default()) {
  # Data rows 5-120 (per-billionaire-year + per-year totals). A Walczak
  # comparison block sits below at rows 126-135; ignore here.
  ct <- c("text", "text", rep("numeric", 22), "text", rep("numeric", 11))
  out <- read_rectangular(
    "data_sec_top4",
    path = path,
    skip = 3,
    col_types = ct,
    key_cols = c("year", "forbes_id"),
    n_max = 116
  )
  out$year <- as.integer(out$year)
  out$end_cyear <- as.Date(out$end_cyear)
  out
}

extract_data_sec_all <- function(path = xlsx_path_default()) {
  ct <- c("numeric", "text", rep("numeric", 29))
  out <- read_rectangular(
    "data_sec_all",
    path = path,
    skip = 3,
    col_types = ct,
    key_cols = c("year", "forbes_id")
  )
  out$year <- as.integer(out$year)
  out
}

extract_data_sec_agg <- function(path = xlsx_path_default()) {
  # Years 2019-2025 only; the sheet has trailing "Average" and "Total" rows we drop.
  ct <- c("text", "numeric", rep("numeric", 33))
  out <- read_rectangular(
    "data_sec_agg",
    path = path,
    skip = 3,
    col_types = ct,
    key_cols = "year",
    n_max = 7
  )
  out$year <- as.integer(out$year)
  out
}

extract_rtb_2026_industry <- function(path = xlsx_path_default()) {
  # First block (industries x 8 cols, rows 5-18). A second block below (rows 20-35)
  # adds a top-4 wealth column; ignore here, retrieve separately if needed.
  ct <- c("text", rep("numeric", 7))
  read_rectangular(
    "rtb_2026_industry",
    path = path,
    skip = 3,
    col_types = ct,
    key_cols = "industries",
    n_max = 14
  )
}

extract_longrunseries <- function(path = xlsx_path_default()) {
  read_sheet("longrunseries", path = path)
}

extract_shortrunseries <- function(path = xlsx_path_default()) {
  read_sheet("shortrunseries", path = path)
}

extract_data_dina <- function(path = xlsx_path_default()) {
  read_sheet("data_dina", path = path)
}

extract_data_sec_propublica <- function(path = xlsx_path_default()) {
  read_sheet("data_sec_propublica", path = path)
}

extract_billionaires_ca_inctax <- function(path = xlsx_path_default()) {
  read_sheet("billionairesCAinctax", path = path)
}

extract_ftb_b4a <- function(path = xlsx_path_default()) {
  read_sheet("2023-b-4a__adjusted_gross_incom", path = path)
}

extract_pareto_missing <- function(path = xlsx_path_default()) {
  nm <- c(
    "threshold_b",
    "n_above_threshold_emp",
    "wealth_above_threshold",
    "pareto_b_emp",
    "wealth_in_bracket",
    "actual_density",
    "avg_wealth_in_bracket_emp",
    "n_above_threshold_proj",
    "projected_wealth_in_bracket",
    "projected_density",
    "avg_wealth_in_bracket_proj",
    "pareto_b_proj"
  )
  # Main Pareto block (rows 5-21). Trailing rows are summary stats and a
  # separate phase-in bracket table; ignore here.
  read_rectangular(
    "Pareto-missing",
    path = path,
    skip = 3,
    col_types = rep("numeric", length(nm)),
    names = nm,
    key_cols = "threshold_b",
    n_max = 17
  )
}
