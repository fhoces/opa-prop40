# Sec 5.1.2: income-tax Monte Carlo (Table 8, p.17). Ported from
# RAUH/NPV_data/monte_carlo_sim.R:98-152. The 212 billionaires are drawn
# uniformly at random (without replacement) from the top K positions of the
# Pareto-implied income schedule, K = 212 ... 2000, 100,000 draws per K.
#
# RNG PARITY: the authors call set.seed(42) once at the top of the script and
# then loop over K_values IN ORDER, so each K's `replicate()` call consumes
# the RNG stream left over by the previous K. To reproduce Table 8's printed
# cells exactly we must replay the *entire* sweep in the same order, not just
# the reported K rows (verified in research: K=212's own draw is
# deterministic and does not touch the RNG, since sample(1:212, 212,
# replace=FALSE) always returns all 212 positions in some permutation whose
# sum is invariant - but the loop still calls sample() 100,000 times for it,
# so it still advances the RNG the same number of draws the authors' script
# does).

income_tax_mc_scale_factor <- function(bracket_tax_ty23 = 11.1,
                                        total_pit_fy25 = 130.0) {
  total_pit_ty23 <- bracket_tax_ty23 / 0.114
  total_pit_fy25 / total_pit_ty23
}

compute_income_tax_mc <- function(tax_by_rank,
                                   seed = 42,
                                   n_sims = 100000,
                                   n_billionaires = 212,
                                   K_values = c(212, seq(250, 2000, by = 50)),
                                   bracket_tax_ty23 = 11.1,
                                   total_pit_fy25 = 130.0) {
  scale_factor <- income_tax_mc_scale_factor(bracket_tax_ty23, total_pit_fy25)

  set.seed(seed)
  rows <- vector("list", length(K_values))
  for (i in seq_along(K_values)) {
    K <- K_values[i]
    sim_totals <- replicate(n_sims, {
      drawn_ranks <- sample(seq_len(K), size = n_billionaires, replace = FALSE)
      sum(tax_by_rank[drawn_ranks])
    })
    rows[[i]] <- tibble::tibble(
      K = K,
      mean = mean(sim_totals),
      median = stats::median(sim_totals),
      p05 = unname(stats::quantile(sim_totals, 0.05)),
      p10 = unname(stats::quantile(sim_totals, 0.10)),
      p25 = unname(stats::quantile(sim_totals, 0.25)),
      p75 = unname(stats::quantile(sim_totals, 0.75)),
      p90 = unname(stats::quantile(sim_totals, 0.90)),
      p95 = unname(stats::quantile(sim_totals, 0.95)),
      sd = stats::sd(sim_totals)
    )
  }
  results <- dplyr::bind_rows(rows)
  results$mean_fy25   <- results$mean   * scale_factor
  results$median_fy25 <- results$median * scale_factor
  results$p05_fy25     <- results$p05    * scale_factor
  results$p10_fy25     <- results$p10    * scale_factor
  results$p25_fy25     <- results$p25    * scale_factor
  results$p75_fy25     <- results$p75    * scale_factor
  results$p90_fy25     <- results$p90    * scale_factor
  results$p95_fy25     <- results$p95    * scale_factor
  attr(results, "scale_factor") <- scale_factor
  results
}

# Table 8's printed rows (paper p.17): K, mean, p05, p95, all FY24-25 $B.
income_tax_mc_table8 <- function(results) {
  reported_k <- c(212, 250, 300, 400, 500, 750, 1000)
  out <- results[results$K %in% reported_k, c("K", "mean_fy25", "p05_fy25", "p95_fy25")]
  out[order(out$K), ]
}
