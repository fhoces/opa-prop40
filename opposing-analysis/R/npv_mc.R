# Sec 5.5 NPV Monte Carlo, both versions. Ported from
# RAUH/NPV_data/NPV_dist.R (SSRN) and
# RAUH/NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R (NBER).
#
# RNG PARITY: both scripts call set.seed(2026) once, then draw runif() in a
# fixed order. We replicate that exact order so our R output matches theirs
# to machine precision (verified in tests/testthat against a run of their
# own script from a scratch copy).
#
# SSRN (NPV_dist.R:24-63): f is NOT an independent draw. It is implied by
# the WT draw: f = 1 - WT/baseline_revenue. NPV = WT - f*C/r (plain r, not
# r-g - see MISMATCHES.md #2/#3).
compute_npv_mc_ssrn <- function(seed = 2026, n_sims = 100000,
                                 baseline_revenue = 94.2,
                                 wt_min = 35, wt_max = 67.51,
                                 c_min = 3.3, c_max = 5.8,
                                 r_min = 0.015, r_max = 0.045) {
  set.seed(seed)
  wt <- stats::runif(n_sims, wt_min, wt_max)
  c_income <- stats::runif(n_sims, c_min, c_max)
  r_discount <- stats::runif(n_sims, r_min, r_max)

  f <- 1 - (wt / baseline_revenue)
  annual_loss <- f * c_income
  pv_lost <- annual_loss / r_discount
  npv <- wt - pv_lost

  list(
    draws = tibble::tibble(wt = wt, c_income = c_income, r_discount = r_discount,
                            f = f, annual_loss = annual_loss, pv_lost = pv_lost, npv = npv),
    summary = npv_mc_summary(npv)
  )
}

# NBER (NPV_dist_v8.R:24-32): f IS an independent draw, U[0.30, 0.60],
# unrelated to the WT draw (mismatch candidate #5 in MISMATCHES.md - the
# NBER README's q=0.50 litigation-survival weight never appears as an
# explicit multiplier in this script). wt_max defaults to 72 (the script's
# own hard-coded literal, NPV_dist_v8.R:19) rather than the value
# re-derived from final.csv by compute_nber_ceiling() (R/nber_final.R) -
# see MISMATCHES.md #4.
compute_npv_mc_nber <- function(seed = 2026, n_sims = 100000,
                                 wt_min = 0, wt_max = 72,
                                 f_min = 0.30, f_max = 0.60,
                                 c_min = 3.3, c_max = 5.8,
                                 rg_min = 0.015, rg_max = 0.045) {
  set.seed(seed)
  wt <- stats::runif(n_sims, wt_min, wt_max)
  f  <- stats::runif(n_sims, f_min, f_max)
  c_income <- stats::runif(n_sims, c_min, c_max)
  rg_discount <- stats::runif(n_sims, rg_min, rg_max)

  npv <- wt - (f * c_income) / rg_discount

  list(
    draws = tibble::tibble(wt = wt, f = f, c_income = c_income,
                            rg_discount = rg_discount, npv = npv),
    summary = npv_mc_summary(npv)
  )
}

npv_mc_summary <- function(npv) {
  tibble::tibble(
    n = length(npv),
    mean = mean(npv),
    median = stats::median(npv),
    sd = stats::sd(npv),
    p05 = unname(stats::quantile(npv, 0.05)),
    p95 = unname(stats::quantile(npv, 0.95)),
    pct_negative = 100 * mean(npv < 0)
  )
}

# Seed-free analytic cross-check. WT, C and the discount-rate draw are
# mutually independent uniforms in both versions; f is a deterministic
# linear function of WT alone (SSRN) or an independent uniform of its own
# (NBER), so in both cases f is independent of C and of the discount-rate
# draw and E[f*C/rate] = E[f]*E[C]*E[1/rate]. For rate ~ U[a,b],
# E[1/rate] = ln(b/a)/(b-a) (the brief's given closed form).
# E[1/(rate - g)] for rate ~ U[lo, hi] (or a point when lo == hi). At g = 0
# this is the closed form ln(hi/lo)/(hi - lo).
npv_e_inv_rate <- function(lo, hi, g = 0) {
  if (hi > lo) log((hi - g) / (lo - g)) / (hi - lo) else 1 / (lo - g)
}

# The model's exact expectation for one setting of every input:
#   NPV = q*WT - f*C/(rate - g), WT ~ U[wt_min, wt_max], C ~ U[c_min, c_max],
#   rate ~ U[rate_min, rate_max], mutually independent, with f either implied
#   by WT (SSRN, f_spec = list(mode = "implied", baseline = B): f = 1 - WT/B),
#   an independent uniform (NBER, list(mode = "uniform", lo, hi)), or fixed
#   (list(mode = "fixed", value)). q (litigation survival applied to revenue)
#   and g (growth of the lost income) are 1 and 0 in both scripts as shipped;
#   the explorer moves them (MISMATCHES #2, #3, #5). Used by
#   npv_mc_analytic_mean() below and by the explorer grid (R/site.R).
npv_expectation <- function(wt_min, wt_max, c_min, c_max, rate_min, rate_max,
                            f_spec, q = 1, g = 0) {
  e_wt <- (wt_min + wt_max) / 2
  e_f <- switch(f_spec$mode,
    implied = 1 - e_wt / f_spec$baseline,
    uniform = (f_spec$lo + f_spec$hi) / 2,
    fixed   = f_spec$value
  )
  pv_lost <- e_f * mean(c(c_min, c_max)) * npv_e_inv_rate(rate_min, rate_max, g)
  collected <- q * e_wt
  c(mean_npv = collected - pv_lost, wt_collected = collected, pv_lost = pv_lost)
}

npv_mid_nodes <- function(lo, hi, n) {
  if (hi > lo) lo + (seq_len(n) - 0.5) * (hi - lo) / n else lo
}

# P(NPV < 0) for the same model, seed-free: WT's uniform CDF is integrated
# exactly, C and rate (and f when it is drawn) by the midpoint rule (accurate
# to about 0.01 points at the default node counts; test-site.R checks it
# against the seeded Monte Carlo).
npv_share_negative_exact <- function(wt_min, wt_max, c_min, c_max, rate_min, rate_max,
                                     f_spec, q = 1, g = 0, n2 = 400, n3 = 100) {
  f_drawn <- identical(f_spec$mode, "uniform")
  n <- if (f_drawn) n3 else n2
  cn <- npv_mid_nodes(c_min, c_max, n)
  rn <- npv_mid_nodes(rate_min, rate_max, n)
  k <- as.vector(outer(cn, 1 / (rn - g)))           # C / (rate - g)
  thr <- switch(f_spec$mode,
    implied = k / (q + k / f_spec$baseline),         # q*WT < (1 - WT/B) k
    fixed   = f_spec$value * k / q,
    uniform = as.vector(outer(k, npv_mid_nodes(f_spec$lo, f_spec$hi, n))) / q
  )
  mean(stats::punif(thr, wt_min, wt_max))
}

npv_mc_analytic_mean <- function(wt_min, wt_max, c_min, c_max,
                                  rate_min, rate_max,
                                  f_mode = c("ssrn", "nber"),
                                  baseline_revenue = NULL,
                                  f_min = NULL, f_max = NULL) {
  f_mode <- match.arg(f_mode)
  f_spec <- if (f_mode == "ssrn") {
    stopifnot(!is.null(baseline_revenue))
    list(mode = "implied", baseline = baseline_revenue)
  } else {
    stopifnot(!is.null(f_min), !is.null(f_max))
    list(mode = "uniform", lo = f_min, hi = f_max)
  }
  npv_expectation(wt_min, wt_max, c_min, c_max, rate_min, rate_max, f_spec)[["mean_npv"]]
}
