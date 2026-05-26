# Phase 2 - computation layer.
#
# Each function here re-derives an Excel sheet from its upstream inputs in R.
# The test suite asserts the R output matches the Phase-1 Excel extraction
# within a small tolerance (default 1e-2 in $B = $10M, since Excel rounds
# many displayed values to two decimal places).

# Ellison was a CA resident only through ~mid-2023 per Forbes (paper note 2);
# he is excluded from all CA-billionaire aggregates throughout the panel.
ELLISON_FORBES_ID <- "larry-ellison"

compute_pareto_missing <- function(pareto_inputs,
                                   anchor_threshold = 4.5) {
  # Inputs (columns A, B, C of the Pareto-missing sheet):
  #   threshold_b           - wealth threshold ($B)
  #   n_above_threshold_emp - count of CA billionaires with wealth >= threshold
  #   wealth_above_threshold- total wealth ($B) above threshold
  # Derives columns D-L = Pareto extrapolation of billionaires Forbes misses
  # below $4.5B, assuming Pareto b averaged over anchor..tail thresholds.
  d <- pareto_inputs
  required <- c("threshold_b", "n_above_threshold_emp", "wealth_above_threshold")
  stopifnot(all(required %in% names(d)))

  A <- d$threshold_b
  B <- d$n_above_threshold_emp
  C <- d$wealth_above_threshold
  n <- length(A)

  # Empirical Pareto b at each threshold
  pareto_b_emp <- C / (B * A)

  # Bracket metrics (Excel treats the cell below the last row as 0 — replicate)
  next_C <- c(C[-1], 0)
  next_B <- c(B[-1], 0)
  next_A <- c(A[-1], NA_real_)
  wealth_in_bracket <- C - next_C
  actual_density   <- B - next_B
  avg_wealth_in_bracket_emp <- wealth_in_bracket / actual_density

  # Anchor row (threshold 4.5) and average-Pareto-b constants
  anchor_i <- which(A == anchor_threshold)
  if (length(anchor_i) != 1L) {
    stop("Anchor threshold ", anchor_threshold, " not present uniquely in pareto_inputs$threshold_b")
  }
  D23 <- mean(pareto_b_emp[anchor_i:n])   # Average Pareto b above anchor
  D24 <- D23 / (D23 - 1)                  # Corresponding Pareto a

  # Projected count: empirical at/above anchor; Pareto-extrapolated below.
  n_above_threshold_proj <- B
  below <- seq_len(anchor_i - 1L)
  n_above_threshold_proj[below] <-
    B[anchor_i] * (A[anchor_i] / A[below])^D24

  next_H <- c(n_above_threshold_proj[-1], 0)
  projected_density <- n_above_threshold_proj - next_H

  # Projected wealth in bracket: empirical bracket at/above anchor;
  # Pareto-formula below.
  projected_wealth_in_bracket <- wealth_in_bracket
  for (i in below) {
    projected_wealth_in_bracket[i] <-
      D23 * n_above_threshold_proj[i] *
        (A[i] - next_A[i] * (A[i] / next_A[i])^D24)
  }

  avg_wealth_in_bracket_proj <- projected_wealth_in_bracket / projected_density

  pareto_b_proj <- pareto_b_emp
  pareto_b_proj[below] <- D23

  tibble::tibble(
    threshold_b                 = A,
    n_above_threshold_emp       = B,
    wealth_above_threshold      = C,
    pareto_b_emp                = pareto_b_emp,
    wealth_in_bracket           = wealth_in_bracket,
    actual_density              = actual_density,
    avg_wealth_in_bracket_emp   = avg_wealth_in_bracket_emp,
    n_above_threshold_proj      = n_above_threshold_proj,
    projected_wealth_in_bracket = projected_wealth_in_bracket,
    projected_density           = projected_density,
    avg_wealth_in_bracket_proj  = avg_wealth_in_bracket_proj,
    pareto_b_proj               = pareto_b_proj
  )
}

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
