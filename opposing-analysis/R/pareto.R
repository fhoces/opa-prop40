# Sec 5.1.1: Pareto tail fit to the FTB's cumulative AGI-bracket filer counts,
# and the rank-implied income tax schedule used as the input to the income-tax
# Monte Carlo (R/income_tax_mc.R). Ported from
# RAUH/NPV_data/monte_carlo_sim.R:33-71 (paper Sec 5.1, p.15-16, Table 8/Fig 1
# footnote 12). Fully deterministic: no RNG.

# FTB published cumulative filer counts above AGI thresholds (TY 2023).
# Source: CA Franchise Tax Board, PIT Annual Report 2024, Table B-4A.
pareto_thresholds <- c(1e6, 2e6, 3e6, 4e6, 5e6, 10e6)
pareto_filer_counts <- c(131400, 43900, 24700, 16700, 12200, 4729)

# monte_carlo_sim.R:37-44. OLS on the log-linearized Pareto survival
# function ln(N) = ln(A) - alpha * ln(y). Paper reports alpha = 1.44,
# R2 = 0.999 (p.15, eq. 15).
compute_pareto_fit <- function(thresholds = pareto_thresholds,
                                filer_counts = pareto_filer_counts) {
  fit <- lm(log(filer_counts) ~ log(thresholds))
  alpha <- unname(-coef(fit)[[2]])
  ln_a <- unname(coef(fit)[[1]])
  list(
    alpha = alpha,
    r_squared = summary(fit)$r.squared,
    A = exp(ln_a),
    thresholds = thresholds,
    filer_counts = filer_counts
  )
}

# monte_carlo_sim.R:50-75. Rank-implied income schedule for the 4,729 filers
# in the $10M+ bracket, rescaled so the discrete top-212 share matches the
# continuous Pareto share formula S(k, n) = (k/n)^((alpha-1)/alpha) (paper
# eq. 16, p.15; the ~11% discrete-vs-continuous gap is documented in the
# script's own comment at monte_carlo_sim.R:61-67).
compute_pareto_income_schedule <- function(pareto_fit,
                                            n_filers = 4729,
                                            bracket_tax_ty23 = 11.1,
                                            n_billionaires = 212) {
  alpha <- pareto_fit$alpha
  A <- pareto_fit$A

  ranks <- seq_len(n_filers)
  incomes <- (A / ranks)^(1 / alpha)
  income_shares <- incomes / sum(incomes)
  tax_by_rank <- income_shares * bracket_tax_ty23

  continuous_top_share <- (n_billionaires / n_filers)^((alpha - 1) / alpha)
  discrete_top_share <- sum(income_shares[seq_len(n_billionaires)])
  rescale_factor <- continuous_top_share / discrete_top_share
  tax_by_rank <- tax_by_rank * rescale_factor

  list(
    tax_by_rank = tax_by_rank,
    continuous_top_share = continuous_top_share,
    discrete_top_share = discrete_top_share,
    rescale_factor = rescale_factor,
    # Deterministic upper bound: billionaires ARE the top 212 filers
    # (K = 212). monte_carlo_sim.R:78-81; Table 8 row K=212 (paper p.17).
    top_212_tax_ty23 = sum(tax_by_rank[seq_len(n_billionaires)])
  )
}
