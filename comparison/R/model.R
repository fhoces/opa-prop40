# The common estimating function and its decomposition.
#
# ONE function estimates both analyses. Every disputed input is an argument that takes
# either the BSZ analysis's value (GGSS July 2026 / BSZ August 2026, which share their
# benchmark) or the JR analysis's (Jaros and Rauh, NBER, September 2026). At the all-BSZ
# setting it must return BSZ Table 5 row 1; at the all-JR setting it must return the
# expectation of the JR analysis's own Monte Carlo (its inputs are independent uniforms,
# so the expectation has a closed form and needs no random draws).
#
#   Wn  = (W_core + W_noncit) * (1 - re)                   the base, net of real estate
#   D   = (1 - lam) * dep_b + lam * dep_j                  wealth already departed, valued on the
#         Forbes list in use (lam = 0 the BSZ analysis's 2026 list, 1 the JR analysis's 2025
#         list grown 7%); dep_b and dep_j value the same people on each list
#   d_conf = D / Wn                                        share of the base already departed
#   R0  = tau * Wn                                         no-behaviour revenue
#   S   = 1 - d_conf                                       share of the base still taxed
#   WT  = R0 * (1 - alpha) * S * q                         output (a), gross one-time revenue:
#         q is the chance the Act survives litigation. The JR Monte Carlo draws the revenue
#         uniformly between 0 (struck down) and the ceiling R0 S, whose mean is the ceiling
#         times q = 0.5, the weight the authors' README states
#   X   = WT * s * g * t_cg                                extra income tax from asset sales
#   f   = alpha*m + own * L / C + f0                       share of billionaire income tax lost:
#         the BSZ movers' share; with own = 1 (the BSZ analysis) the leavers' own income tax,
#         L dollars a year, as BSZ Table 5 counts it for the people who leave; with own = 0
#         (the JR analysis) none of that, and
#         a flat share (f0, the JR analysis's independent draw)
#   PV  = f * C * E_r[ annuity(r, H) ]                     present value of the lost income tax
#   NET = WT + X - PV                                      output (b), net fiscal effect
#
# annuity(r, H) = (1 - (1 + r)^-H) / r, the value of 1 per year for H years; H = Inf
# gives the JR perpetuity 1/r and r -> 0 gives H. r ~ U[r_min, r_max] as in the JR code;
# the BSZ analysis takes no position on r (it disputes the horizon), so r is a shared
# input, not a bridge step.

expected_annuity <- function(H, r_min, r_max) {
  if (is.infinite(H)) return(log(r_max / r_min) / (r_max - r_min))
  if (H == 0) return(0)
  f <- function(r) (1 - (1 + r)^(-H)) / r
  stats::integrate(f, r_min, r_max, rel.tol = 1e-12, abs.tol = 0)$value / (r_max - r_min)
}

score_common <- function(x) {
  Wn  <- (x$W_core + x$W_noncit) * (1 - x$re)
  D   <- (1 - x$lam) * x$dep_b + x$lam * x$dep_j
  d_conf <- D / Wn
  R0  <- x$tau * Wn
  S   <- 1 - d_conf
  WT  <- R0 * (1 - x$alpha) * S * x$q
  X   <- WT * x$s * x$g * x$t_cg
  f   <- x$alpha * x$m + x$own * x$L / x$C + x$f0
  A   <- expected_annuity(x$H, x$r_min, x$r_max)
  PV  <- f * x$C * A
  c(a = WT, b = WT + X - PV, R0 = R0, S = S, d_conf = d_conf, D = D, X = X, f = f,
    annual_loss = f * x$C, annuity = A, PV = PV)
}

# The bridge steps (Shapley players). One per row of comparison/DISPUTES.md that the
# September 2026 version's headline uses (rows 1 and 4, the permanent-rate framing and the
# size of the elasticity, do not: that version predicts no departures from an elasticity),
# row 7 split into its two parts, row 9 (the litigation weight) added for that version, plus
# the two inputs DISPUTES.md does not list as rows (the 10% avoidance allowance and the
# asset-sale income tax). `step_inputs` are the score_common() arguments a step switches
# from the BSZ to the JR value; the share-lost step switches two together.
bridge_steps <- function() {
  data.frame(
    step_id = c("noncitizens", "base_list", "real_estate", "confirmed_departures",
                "avoidance", "litigation_survival", "income_loss_share", "income_level",
                "horizon", "asset_sales"),
    disputes_row = c("8", "7", "7", "3", "(not a row)", "9", "6", "5", "2", "(not a row)"),
    title = c(
      "Non-US-citizen residents",
      "Forbes source: which list and valuation date",
      "Real-estate deduction",
      "Billionaires already departed",
      "Avoidance and evasion allowance",
      "Chance the tax survives litigation",
      "Share of billionaire income tax lost",
      "Billionaires' annual CA income tax",
      "How long the income tax loss lasts",
      "Extra income tax from selling assets to pay"),
    kind = c("data", "data", "data", "guesswork on data", "guesswork", "guesswork",
             "data vs guesswork", "research vs guesswork", "scenario", "guesswork"),
    stringsAsFactors = FALSE)
}

step_inputs <- list(
  noncitizens = "W_noncit", base_list = c("W_core", "lam"), real_estate = "re",
  confirmed_departures = c("dep_b", "dep_j", "L"), avoidance = "alpha", litigation_survival = "q",
  income_loss_share = c("own", "f0"), income_level = "C", horizon = "H", asset_sales = "s")

# The order Hoopes (2026) Figure 2 reads in: base and residency, departures,
# behaviour, real estate, then everything about income tax last.
sequential_order <- function() {
  c("noncitizens", "base_list", "confirmed_departures", "avoidance", "litigation_survival",
    "real_estate", "asset_sales", "income_loss_share", "income_level", "horizon")
}

switch_inputs <- function(sup, rauh, on) {
  x <- sup
  for (st in on) for (nm in step_inputs[[st]]) x[[nm]] <- rauh[[nm]]
  x
}

# ---- the explorer's sliders ---------------------------------------------------------
# The explorer has two panels. The BSZ panel starts every disputed input at the BSZ value and
# moves it towards the JR value; the JR panel starts at the JR value and moves towards
# the BSZ value. Position 0 is the panel's own analysis's value, the last position the other
# analysis's. This is the one definition of what the positions mean; the Python twin
# (slider_inputs in py/bridge.py) and the page (site/explorer/model.js) mirror it, and
# test-parity / test-site check both against the values written here.
#   most numeric inputs: five positions, linear in the parameter, (1 - p/4) own + (p/4)
#                   other, so 0 and 4 are the two values exactly;
#   the Forbes source: two positions, one list or the other (no blend of the two lists);
#   the departures: three stops, read from the ladder in bridge_inputs(): no departures
#                   (the BSZ analysis), BSZ's aggressive scenario (Table 5 row 3: four escape
#                   the tax, and the income tax of all seven named leavers is lost), the
#                   seven the JR analysis removes; each valued on both lists, with the
#                   leavers' own income tax L;
#   the horizon:    the five settings 5, 10, 20, 50 years and perpetuity, in that order from
#                   the BSZ analysis's 5 years (or in reverse from the JR perpetuity).
SLIDER_STEPS <- 4L
SLIDER_HORIZONS <- c(5, 10, 20, 50, Inf)
slider_max <- function(id) switch(id, base_list = 1L, confirmed_departures = 2L, SLIDER_STEPS)

slider_inputs <- function(from, to, positions, ladder = NULL) {
  x <- from
  for (st in names(step_inputs)) {
    p <- positions[[st]]
    if (is.null(p)) p <- 0
    mx <- slider_max(st)
    stopifnot(p %in% 0:mx)
    t <- p / mx
    if (st == "confirmed_departures") {
      stopifnot(!is.null(ladder))
      k <- if (from$dep_b <= to$dep_b) p + 1 else mx + 1 - p
      x$dep_b <- ladder$dep_b[k]; x$dep_j <- ladder$dep_j[k]; x$L <- ladder$L[k]
      next
    }
    for (nm in step_inputs[[st]]) {
      if (nm == "H") {
        lad <- if (from$H <= to$H) SLIDER_HORIZONS else rev(SLIDER_HORIZONS)
        stopifnot(lad[1] == from$H, lad[length(lad)] == to$H)
        x$H <- lad[p + 1]
      } else {
        x[[nm]] <- (1 - t) * from[[nm]] + t * to[[nm]]
      }
    }
  }
  x
}

# One panel's value: output (b) of score_common() at the slider positions.
slider_value <- function(bi, panel = c("bsz", "rjkdc"), positions) {
  panel <- match.arg(panel)
  from <- if (panel == "bsz") bi$sup else bi$rauh
  to   <- if (panel == "bsz") bi$rauh else bi$sup
  score_common(slider_inputs(from, to, positions, bi$ladder))[["b"]]
}

# A fixed sample of slider mixes for the parity tests (R, Python and model.js): per panel,
# all at 0, all at the far end, then n - 2 draws. The draws come from the Park-Miller
# generator (x <- 16807 x mod 2^31 - 1), integer-exact in R, Python and JavaScript alike, so
# the R and Python twins write the same positions without sharing a random number library.
slider_sample <- function(bi, n = 300, seed = 20261014) {
  ids <- names(step_inputs)
  x <- seed
  draw <- function(k) { x <<- (16807 * x) %% 2147483647; x %% k }
  rows <- list()
  for (panel in c("bsz", "rjkdc")) {
    for (i in seq_len(n)) {
      pos <- if (i == 1) rep(0, length(ids))
             else if (i == 2) vapply(ids, slider_max, 0L)
             else vapply(ids, function(id) draw(slider_max(id) + 1), 0)
      names(pos) <- ids
      rows[[length(rows) + 1]] <- data.frame(
        panel = panel, draw = i, as.list(pos),
        value = slider_value(bi, panel, as.list(pos)), check.names = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  for (nm in c("draw", ids)) out[[nm]] <- as.integer(out[[nm]])
  rownames(out) <- NULL
  out
}

# The value of every coalition: v[mask + 1] is score_common() with the players whose bit
# is set in `mask` (bit i-1 = players[i]) at the JR value and the rest at the BSZ value.
# mask 0 is the all-BSZ setting, mask 2^n - 1 the all-JR one (comparison/export/r/switchboard.csv).
coalition_values <- function(sup, rauh, players, output = c("a", "b")) {
  output <- match.arg(output)
  n <- length(players)
  inset <- function(mask) players[bitwAnd(mask, 2^(0:(n - 1))) > 0]
  vapply(0:(2^n - 1), function(mk) score_common(switch_inputs(sup, rauh, inset(mk)))[[output]], 0)
}

# Exact Shapley values by enumerating all 2^n coalitions (n = 10: 1,024 scorings).
# `players` can exclude steps (e.g. the horizon when both ends share one horizon).
# `v` can pass coalition_values() already computed for the same players and output.
shapley_bridge <- function(sup, rauh, players, output = c("a", "b"), v = NULL) {
  output <- match.arg(output)
  n <- length(players)
  masks <- 0:(2^n - 1)
  if (is.null(v)) v <- coalition_values(sup, rauh, players, output)
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

# The JR analysis's own expectation (Jaros and Rauh, NBER, September 2026, NPV_dist_v8.R):
# WT ~ U[0, 72], f ~ U[0.30, 0.60] independent of WT, C ~ U[3.3, 5.8], r ~ U[1.5%, 4.5%],
# all independent, so E[NPV] = E[WT] - E[f] E[C] E[annuity]. At H = Inf this is -38.980,
# which rounds to the printed -38.9 (one seeded run of the same draws, p.1 and p.35).
rauh_nber_expectation <- function(wt_min, wt_max, f_min, f_max, c_min, c_max, r_min, r_max, H = Inf) {
  e_wt <- (wt_min + wt_max) / 2
  c(a = e_wt, b = e_wt - (f_min + f_max) / 2 * (c_min + c_max) / 2 *
      expected_annuity(H, r_min, r_max))
}
