# Computation layer.
#
# Re-derives an Excel sheet from its upstream inputs in R; the test suite
# asserts the R output matches the upstream Excel extraction within a
# documented tolerance.

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

  # Bracket metrics (Excel treats the cell below the last row as 0; replicate)
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

pareto_n_above <- function(threshold, anchor_threshold, anchor_count, pareto_a) {
  # # billionaires above wealth threshold under a Pareto tail with given anchor
  anchor_count * (anchor_threshold / threshold)^pareto_a
}

pareto_wealth_in_bracket <- function(lo, hi, anchor_threshold, anchor_count,
                                     pareto_a, pareto_b) {
  # Total wealth held by people with wealth in [lo, hi) under the Pareto tail.
  # Matches Excel I-column formula: D23 * H * (lo - hi * (lo/hi)^D24).
  H_lo <- pareto_n_above(lo, anchor_threshold, anchor_count, pareto_a)
  pareto_b * H_lo * (lo - hi * (lo / hi)^pareto_a)
}

compute_pareto_summary <- function(pareto_missing_r,
                                   anchor_threshold = 4.5,
                                   phasein_lo = 1.0,
                                   phasein_hi = 1.1) {
  d <- pareto_missing_r
  required <- c("threshold_b", "n_above_threshold_emp", "wealth_above_threshold",
                "pareto_b_emp", "wealth_in_bracket", "actual_density",
                "n_above_threshold_proj", "projected_wealth_in_bracket",
                "projected_density")
  stopifnot(all(required %in% names(d)))

  anchor_i <- which(d$threshold_b == anchor_threshold)
  anchor_count <- d$n_above_threshold_emp[anchor_i]
  pareto_b <- mean(d$pareto_b_emp[anchor_i:nrow(d)])
  pareto_a <- pareto_b / (pareto_b - 1)

  total_wealth_emp  <- sum(d$wealth_in_bracket,           na.rm = TRUE)  # E22
  total_count_emp   <- sum(d$actual_density,              na.rm = TRUE)  # F22
  total_wealth_proj <- sum(d$projected_wealth_in_bracket, na.rm = TRUE)  # I22
  total_count_proj  <- sum(d$projected_density,           na.rm = TRUE)  # J22

  pct_wealth_increase <- total_wealth_proj / total_wealth_emp - 1        # I23
  pct_count_increase  <- total_count_proj  / total_count_emp  - 1        # J23

  wealth_in_phasein <- pareto_wealth_in_bracket(
    phasein_lo, phasein_hi,
    anchor_threshold = anchor_threshold,
    anchor_count = anchor_count,
    pareto_a = pareto_a,
    pareto_b = pareto_b
  )                                                                       # I29
  fraction_in_phasein <- wealth_in_phasein / (total_wealth_proj - total_wealth_emp)  # I24

  list(
    pareto_a            = pareto_a,
    pareto_b            = pareto_b,
    total_wealth_emp    = total_wealth_emp,
    total_count_emp     = total_count_emp,
    total_wealth_proj   = total_wealth_proj,
    total_count_proj    = total_count_proj,
    pct_wealth_increase = pct_wealth_increase,
    pct_count_increase  = pct_count_increase,
    wealth_in_phasein   = wealth_in_phasein,
    fraction_in_phasein = fraction_in_phasein
  )
}

compute_fig8_laffer <- function(
  semi_elasticity_mobility   = 10,      # Fig8!B8 - mobility semi-elasticity e
  current_inctax_per_wealth  = 0.002,   # Fig8!C8 - current CA income tax / wealth
  current_wealth_tax_base    = 2000,    # Fig8!D8 - current wealth tax base ($B)
  deconcentration_elasticity = 15,      # Fig8!E8 - deconcentration elasticity d
  rate_step                  = 0.001,
  max_rate                   = 0.20
) {
  # Laffer curve for a permanent annual CA wealth tax under mobility +
  # deconcentration responses. Mirrors Fig8 columns A-E.
  rates  <- seq(0, max_rate, by = rate_step)
  base   <- current_wealth_tax_base *
              exp(-(rates - current_inctax_per_wealth) * semi_elasticity_mobility)
  ref_pow <- (1 - current_inctax_per_wealth)^deconcentration_elasticity
  tibble::tibble(
    tax_rate               = rates,
    mechanical_tax_revenue = rates * current_wealth_tax_base,
    wealth_tax_base        = base,
    actual_tax_revenue     = rates * base,
    long_run_tax_revenue   = rates * base * (1 - rates)^deconcentration_elasticity / ref_pow
  )
}
