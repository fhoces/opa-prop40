# Seed spread of the first version's Monte Carlo (NPV_data/NPV_dist.R as shipped, 100,000 draws),
# for MISMATCHES.md note 9. Run from the repository root: Rscript feedback/006-2026-10-16-jr-author-mismatches/seed-spread.R
# It replays the shipped seed (2026), then 400 other seeds, and reports how far each summary moves
# from seed to seed and how many seeds give all four printed values (p.20: -24.7, -19.1, 38.4, 71).
sim <- function(seed, n = 1e5, baseline = 94.2, wt_max = 67.51) {
  set.seed(seed)
  wt <- runif(n, 35, wt_max)
  c_income <- runif(n, 3.3, 5.8)
  r <- runif(n, 0.015, 0.045)
  npv <- wt - (1 - wt / baseline) * c_income / r
  c(mean = mean(npv), median = median(npv), sd = sd(npv), pct_negative = 100 * mean(npv < 0))
}
shipped <- sim(2026)
print(round(shipped, 3))
res <- t(sapply(1:400, sim))
cat(sprintf("seed-to-seed SD of the mean: %.3f; of the sd: %.3f\n", sd(res[, "mean"]), sd(res[, "sd"])))
cat(sprintf("gaps from the print in those units: mean %.2f, sd %.2f\n",
            (shipped[["mean"]] + 24.7) / sd(res[, "mean"]), (shipped[["sd"]] - 38.4) / sd(res[, "sd"])))
all4 <- round(res[, "mean"], 1) == -24.7 & round(res[, "median"], 1) == -19.1 &
  round(res[, "sd"], 1) == 38.4 & round(res[, "pct_negative"]) == 71
cat(sprintf("seeds (of 400) giving all four printed values: %d\n", sum(all4)))
