# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

# Six tax-type ratio columns that decompose into a total + a residual check.
# Used twice (per-income and per-wealth) and again when collapsing across
# years in the sub-period averages.
.T4T_INC_COMPONENTS <- c("ca_inctax_per_income", "fed_inctax_per_income",
                          "sales_tax_per_income", "corp_tax_per_income",
                          "property_tax_per_income")
.T4T_W_COMPONENTS   <- c("ca_inctax_per_wealth", "fed_inctax_per_wealth",
                          "sales_tax_per_wealth", "corp_tax_per_wealth",
                          "property_tax_per_wealth")

.t4t_period_avg <- function(panel, panel_cols, years) {
  # Average each column over the given panel years, then overwrite the two
  # check-decomp cells to match Excel: the sheet computes the average-row
  # check as (avg total) - SUM(avg components), not the mean of per-year
  # checks. Rounding differences make those two values differ.
  out <- vapply(panel_cols,
                 \(col) mean(panel[[col]][panel$year %in% years]),
                 numeric(1))
  out["check_income_decomp"] <-
    out["total_tax_per_income"] - sum(out[.T4T_INC_COMPONENTS])
  out["check_wealth_decomp"] <-
    out["total_tax_per_wealth"] - sum(out[.T4T_W_COMPONENTS])
  out
}

compute_top4taxes <- function(data_sec_top4) {
  # Re-derives the 429 formula cells of top4taxes: per-year tax rates of the
  # CA top-4 billionaires, 2004..2025, plus 2004-2016 / 2017-2025 averages.
  # The "top 4" composition shifts in three phases (see comment on `agg`).

  d <- data_sec_top4
  pick <- function(id, yr, col) {
    row <- d[d$forbes_id == id & d$year == yr, ]
    if (nrow(row) == 1L) row[[col]] else NA_real_
  }
  # Aggregate the 8 metric columns for the dynamic "top 4" composition.
  metric_cols <- c("ca_income_tax", "fed_income_tax", "sales_tax",
                   "w_txt", "w_tax_ppent", "total_tax", "economic_income",
                   "public_worth_avg")
  agg <- function(yr) {
    total <- vapply(metric_cols, pick, numeric(1),
                    id = "Total (excluding Ellison)", yr = yr)
    if (yr <= 2015) {
      ell <- vapply(metric_cols, pick, numeric(1), id = "larry-ellison", yr = yr)
      total + ell
    } else if (yr <= 2020) {
      ell <- vapply(metric_cols, pick, numeric(1), id = "larry-ellison", yr = yr)
      hua <- vapply(metric_cols, pick, numeric(1), id = "jensen-huang",  yr = yr)
      total + ell - hua
    } else {
      total
    }
  }

  yrs <- 2004:2025
  mat <- vapply(yrs, agg, numeric(length(metric_cols)))
  rownames(mat) <- metric_cols
  # Columns of `mat` are years; rows are metrics.
  ca_tax  <- mat["ca_income_tax", ]
  fed_tax <- mat["fed_income_tax", ]
  sales_t <- mat["sales_tax", ]
  corp_t  <- mat["w_txt", ]
  prop_t  <- mat["w_tax_ppent", ]
  total_t <- mat["total_tax", ]
  econ_i  <- mat["economic_income", ]      # T
  wealth  <- mat["public_worth_avg", ]     # S

  # Per-income ratios (cols C..H, /T)
  C_total_per_inc  <- total_t / econ_i
  D_ca_per_inc     <- ca_tax  / econ_i
  E_fed_per_inc    <- fed_tax / econ_i
  F_sales_per_inc  <- sales_t / econ_i
  G_corp_per_inc   <- corp_t  / econ_i
  H_prop_per_inc   <- prop_t  / econ_i
  I_check_inc      <- C_total_per_inc -
                       (D_ca_per_inc + E_fed_per_inc + F_sales_per_inc +
                        G_corp_per_inc + H_prop_per_inc)

  # Per-wealth ratios (cols J..O, /S)
  J_total_per_w  <- total_t / wealth
  K_ca_per_w     <- ca_tax  / wealth
  L_fed_per_w    <- fed_tax / wealth
  M_sales_per_w  <- sales_t / wealth
  N_corp_per_w   <- corp_t  / wealth
  O_prop_per_w   <- prop_t  / wealth
  P_check_w      <- J_total_per_w -
                     (K_ca_per_w + L_fed_per_w + M_sales_per_w +
                      N_corp_per_w + O_prop_per_w)

  R_inc_per_w    <- econ_i / wealth

  panel <- tibble::tibble(
    year = yrs,
    total_tax_per_income     = C_total_per_inc,
    ca_inctax_per_income     = D_ca_per_inc,
    fed_inctax_per_income    = E_fed_per_inc,
    sales_tax_per_income     = F_sales_per_inc,
    corp_tax_per_income      = G_corp_per_inc,
    property_tax_per_income  = H_prop_per_inc,
    check_income_decomp      = I_check_inc,
    total_tax_per_wealth     = J_total_per_w,
    ca_inctax_per_wealth     = K_ca_per_w,
    fed_inctax_per_wealth    = L_fed_per_w,
    sales_tax_per_wealth     = M_sales_per_w,
    corp_tax_per_wealth      = N_corp_per_w,
    property_tax_per_wealth  = O_prop_per_w,
    check_wealth_decomp      = P_check_w,
    income_per_wealth        = R_inc_per_w,
    avg_wealth_m             = wealth,
    economic_income_m        = econ_i
  )

  # Sub-period averages (rows 27, 28 of the sheet)
  panel_cols    <- setdiff(names(panel), "year")
  avg_2004_2016 <- .t4t_period_avg(panel, panel_cols, 2004:2016)
  avg_2017_2025 <- .t4t_period_avg(panel, panel_cols, 2017:2025)

  averages <- tibble::tibble(
    period = c("2004-2016", "2017-2025"),
    !!!setNames(
      lapply(panel_cols, \(col) c(avg_2004_2016[[col]], avg_2017_2025[[col]])),
      panel_cols
    )
  )

  list(panel = panel, averages = averages)
}
