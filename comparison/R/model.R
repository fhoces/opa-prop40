# The common scoring function and its decomposition.
#
# ONE function scores both sides. Every disputed input is an argument that takes
# either the BSZ side's value (GGSS July 2026 / BSZ August 2026, which share
# their benchmark) or Rauh et al.'s (SSRN, March 2026). At the all-BSZ
# setting it must return BSZ Table 5 row 1; at the all-Rauh setting it must return
# the expectation of Rauh's own Monte Carlo (its inputs are independent uniforms,
# so the expectation has a closed form and needs no random draws).
#
#   R0  = tau * (W_core + W_noncit) * (1 - re)             no-behaviour revenue
#   S   = 1 - (d_conf + max(d_conf, eps * dtau)) / 2       share of the base still taxed:
#         Rauh's WT is uniform between the confirmed-departure ceiling, R0 (1 - d_conf),
#         and the elasticity floor, R0 (1 - eps dtau); S is its mean over R0
#   WT  = R0 * (1 - alpha) * S                             output (a), gross one-time revenue
#   X   = WT * s * g * t_cg                                extra income tax from asset sales
#   f   = alpha*m + kappa * (1 - S) * (1 - alpha*m)        share of billionaire income tax lost
#   PV  = f * C * E_r[ annuity(r, H) ]                     present value of the lost income tax
#   NET = WT + X - PV                                      output (b), net fiscal effect
#
# annuity(r, H) = (1 - (1 + r)^-H) / r, the value of 1 per year for H years; H = Inf
# gives Rauh's perpetuity 1/r and r -> 0 gives H. r ~ U[r_min, r_max] as in Rauh
# eq.24; the BSZ side takes no position on r (it disputes the horizon), so r
# is a shared input, not a bridge step.

expected_annuity <- function(H, r_min, r_max) {
  if (is.infinite(H)) return(log(r_max / r_min) / (r_max - r_min))
  if (H == 0) return(0)
  f <- function(r) (1 - (1 + r)^(-H)) / r
  stats::integrate(f, r_min, r_max, rel.tol = 1e-12, abs.tol = 0)$value / (r_max - r_min)
}

score_common <- function(x) {
  R0  <- x$tau * (x$W_core + x$W_noncit) * (1 - x$re)
  S   <- 1 - (x$d_conf + max(x$d_conf, x$eps * x$dtau)) / 2
  WT  <- R0 * (1 - x$alpha) * S
  X   <- WT * x$s * x$g * x$t_cg
  f   <- x$alpha * x$m + x$kappa * (1 - S) * (1 - x$alpha * x$m)
  A   <- expected_annuity(x$H, x$r_min, x$r_max)
  PV  <- f * x$C * A
  c(a = WT, b = WT + X - PV, R0 = R0, S = S, X = X, f = f, annual_loss = f * x$C,
    annuity = A, PV = PV)
}

# The bridge steps (Shapley players). One per row of comparison/DISPUTES.md, row 7
# split into its two parts, plus the two inputs DISPUTES.md does not list as rows
# (the 10% avoidance allowance and the asset-sale income tax). `inputs` are the
# score_common() arguments the step switches from the BSZ to the Rauh value.
bridge_steps <- function() {
  data.frame(
    step_id = c("noncitizens", "base_list", "real_estate", "confirmed_departures",
                "avoidance", "one_time_as_permanent", "elasticity_size",
                "income_proportional", "income_level", "horizon", "asset_sales"),
    disputes_row = c("8", "7", "7", "3", "(not a row)", "1", "4", "6", "5", "2",
                     "(not a row)"),
    title = c(
      "Non-US-citizen residents",
      "Base list and valuation date",
      "Real-estate deduction",
      "Billionaires already departed",
      "Avoidance and evasion allowance",
      "One-time tax scored as a permanent 5 pp rate",
      "Size of the mobility semi-elasticity",
      "Lost income tax proportional to lost wealth",
      "Billionaires' annual CA income tax",
      "How long the income tax loss lasts",
      "Extra income tax from selling assets to pay"),
    kind = c("data", "data", "data", "guesswork on data", "guesswork", "scenario + guesswork",
             "research + guesswork", "data vs guesswork", "research vs guesswork", "scenario",
             "guesswork"),
    stringsAsFactors = FALSE)
}

step_inputs <- list(
  noncitizens = "W_noncit", base_list = "W_core", real_estate = "re",
  confirmed_departures = "d_conf", avoidance = "alpha", one_time_as_permanent = "dtau",
  elasticity_size = "eps", income_proportional = "kappa", income_level = "C",
  horizon = "H", asset_sales = "s")

# The order Hoopes (2026) Figure 2 reads in: base and residency, departures,
# behaviour, real estate, then everything about income tax last.
sequential_order <- function() {
  c("noncitizens", "base_list", "confirmed_departures", "avoidance",
    "one_time_as_permanent", "elasticity_size", "real_estate", "asset_sales",
    "income_proportional", "income_level", "horizon")
}

switch_inputs <- function(sup, rauh, on) {
  x <- sup
  for (st in on) for (nm in step_inputs[[st]]) x[[nm]] <- rauh[[nm]]
  x
}

# Exact Shapley values by enumerating all 2^n coalitions (n = 11: 2,048 scorings).
# `players` can exclude steps (e.g. the horizon when both ends share one horizon).
shapley_bridge <- function(sup, rauh, players, output = c("a", "b")) {
  output <- match.arg(output)
  n <- length(players)
  masks <- 0:(2^n - 1)
  inset <- function(mask) players[bitwAnd(mask, 2^(0:(n - 1))) > 0]
  v <- vapply(masks, function(mk) score_common(switch_inputs(sup, rauh, inset(mk)))[[output]], 0)
  size <- vapply(masks, function(mk) sum(bitwAnd(mk, 2^(0:(n - 1))) > 0), 0)
  # weight of a coalition of `size` others (the full coalition never lacks i)
  w <- ifelse(size < n, factorial(size) * factorial(pmax(n - size - 1, 0)) / factorial(n), 0)
  phi <- vapply(seq_len(n), function(i) {
    bit <- 2^(i - 1)
    without <- masks[bitwAnd(masks, bit) == 0]
    sum(w[without + 1] * (v[without + bit + 1] - v[without + 1]))
  }, 0)
  stats::setNames(phi, players)
}

sequential_bridge <- function(sup, rauh, order, output = c("a", "b")) {
  output <- match.arg(output)
  prev <- score_common(sup)[[output]]
  out <- numeric(length(order))
  for (k in seq_along(order)) {
    cur <- score_common(switch_inputs(sup, rauh, order[seq_len(k)]))[[output]]
    out[k] <- cur - prev
    prev <- cur
  }
  stats::setNames(out, order)
}

# Rauh's own expectation, from his literal inputs (SSRN eq.22-24, with the code's
# 67.51 ceiling and the 94.2 literal baseline): E[WT] - E[f] E[C] E[annuity].
# At H = Inf this is -24.707, which rounds to the printed -24.7 (p.20).
rauh_ssrn_expectation <- function(wt_min, wt_max, baseline, c_min, c_max, r_min, r_max, H = Inf) {
  e_wt <- (wt_min + wt_max) / 2
  c(a = e_wt, b = e_wt - (1 - e_wt / baseline) * (c_min + c_max) / 2 *
      expected_annuity(H, r_min, r_max))
}

# NBER (Sept 2026): WT ~ U[0, 72], f ~ U[0.30, 0.60] independent of WT.
rauh_nber_expectation <- function(wt_min, wt_max, f_min, f_max, c_min, c_max, r_min, r_max, H = Inf) {
  e_wt <- (wt_min + wt_max) / 2
  c(a = e_wt, b = e_wt - (f_min + f_max) / 2 * (c_min + c_max) / 2 *
      expected_annuity(H, r_min, r_max))
}
