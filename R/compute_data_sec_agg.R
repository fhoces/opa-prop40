# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

# Ellison was a CA resident only through ~mid-2023 per Forbes (paper note 2);
# he is excluded from all CA-billionaire aggregates throughout the panel.
ELLISON_FORBES_ID <- "larry-ellison"
compute_data_sec_agg <- function(data_sec_all,
                                 exclude_ids = ELLISON_FORBES_ID,
                                 m_to_b = 1000) {
  # Columns to sum (in panel order) — the 27 metric columns shared with data_sec_all
  sum_cols <- c(
    "forbes_worth", "forbes_public_worth",
    "purchase", "sale",
    "kg", "kg_long", "kg_short",
    "option_profit", "noneq_comp", "ordinary_income",
    "kg_taxable", "dividend", "fiscal_income",
    "donation", "donation_deductible", "income_taxable",
    "ca_income_tax", "fed_ordinary_income_tax", "fed_preferential_tax",
    "fed_income_tax", "fiscal_income_tax",
    "sales_tax", "w_txt", "w_tax_ppent", "w_pi",
    "total_tax", "economic_income"
  )
  filtered <- data_sec_all[!(data_sec_all$forbes_id %in% exclude_ids), ]
  out <- filtered |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      n = dplyr::n(),
      dplyr::across(
        dplyr::all_of(sum_cols),
        \(x) sum(x, na.rm = TRUE) / m_to_b
      ),
      .groups = "drop"
    )
  out$year <- as.integer(out$year)
  tibble::as_tibble(out)
}
