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
npv_mc_analytic_mean <- function(wt_min, wt_max, c_min, c_max,
                                  rate_min, rate_max,
                                  f_mode = c("ssrn", "nber"),
                                  baseline_revenue = NULL,
                                  f_min = NULL, f_max = NULL) {
  f_mode <- match.arg(f_mode)
  e_wt <- (wt_min + wt_max) / 2
  e_c <- (c_min + c_max) / 2
  e_inv_rate <- log(rate_max / rate_min) / (rate_max - rate_min)
  e_f <- if (f_mode == "ssrn") {
    stopifnot(!is.null(baseline_revenue))
    1 - e_wt / baseline_revenue
  } else {
    stopifnot(!is.null(f_min), !is.null(f_max))
    (f_min + f_max) / 2
  }
  e_wt - e_f * e_c * e_inv_rate
}
