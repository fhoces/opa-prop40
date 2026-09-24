# Assemble every number the reconciliation page shows, from the contracts only.

HORIZONS <- c(5, 10, 20, 30, 50, Inf)

# The two input vectors, each value traced to a contract row or a document page.
bridge_inputs <- function(k) {
  si <- k$bsz$inputs; so <- k$bsz$outputs
  oi <- k$rjkdc$inputs;   oo <- k$rjkdc$outputs
  d  <- k$docs
  W0      <- pick(si, "baseline_net_worth")
  noncit  <- pick(d, "ggss_noncitizen_wealth")
  C_sup   <- pick(si, "ca_inctax_billionaires")
  kappa_s <- (pick(si, "leavers_annual_inctax") / pick(si, "leavers_wealth")) / (C_sup / W0)
  tau     <- pick(oi, "tax_rate")
  stopifnot(isTRUE(all.equal(tau, pick(si, "tax_rate"))))
  base_r  <- pick(oi, "baseline_net_worth")
  R0_r    <- pick(oo, "revenue_baseline")           # 94.304, the workbook's own sum
  conf6   <- pick(oo, "revenue_confirmed6")         # 67.511
  wt_min  <- pick(oi, "rauh_mc_wt_min")              # 35
  shared <- list(tau = tau, m = pick(si, "mobility_share"), g = pick(si, "gains_share"),
                 t_cg = pick(si, "ca_cg_rate"),
                 r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
  sup <- c(shared, list(
    W_noncit = noncit, W_core = W0 - noncit, re = 0, d_conf = 0,
    alpha = pick(si, "avoidance_rate"), dtau = 0, eps = pick(si, "semi_elasticity_permanent"),
    kappa = kappa_s, C = C_sup, H = pick(d, "bsz_loss_horizon"),
    s = pick(si, "sell_share")))
  rauh <- c(shared, list(
    W_noncit = 0, W_core = base_r, re = 1 - R0_r / (tau * base_r),
    d_conf = 1 - conf6 / R0_r, alpha = 0, dtau = tau,
    eps = (1 - wt_min / R0_r) / tau,
    kappa = 1, C = (pick(oi, "rauh_mc_c_min") + pick(oi, "rauh_mc_c_max")) / 2,
    H = pick(d, "rauh_loss_horizon"), s = 0))
  list(sup = sup, rauh = rauh)
}

# How each input is shown on the page: both values and where each comes from.
bridge_input_table <- function(bi) {
  s <- bi$sup; r <- bi$rauh
  data.frame(
    step_id = c("noncitizens", "base_list", "real_estate", "confirmed_departures", "avoidance",
                "one_time_as_permanent", "elasticity_size", "income_proportional",
                "income_level", "horizon", "asset_sales"),
    input = c("W_noncit", "W_core", "re", "d_conf", "alpha", "dtau", "eps", "kappa", "C", "H", "s"),
    supporting_value = c(s$W_noncit, s$W_core, s$re, s$d_conf, s$alpha, s$dtau, s$eps,
                         s$kappa, s$C, s$H, s$s),
    rauh_value = c(r$W_noncit, r$W_core, r$re, r$d_conf, r$alpha, r$dtau, r$eps,
                   r$kappa, r$C, r$H, r$s),
    unit = c("$B", "$B", "share", "share", "share", "rate", "coefficient", "ratio",
             "$B/yr", "years", "share"),
    supporting_source = c(
      "GGSS 20 Jul 2026 p.2 fn.1 (24 people, about $150B); BSZ PDF p.54 ($132B at 1 Jan)",
      "BSZ export baseline_net_worth ($2,307B, 1 Jul 2026; BSZ PDF p.24, GGSS p.4) minus the non-citizens",
      "no separate deduction (BSZ PDF p.24: 90% x 5% x $2,307B)",
      "benchmark taxes all 1 Jan 2026 residents (BSZ PDF p.23); aggressive row 3 is a checkpoint",
      "BSZ export avoidance_rate (GGSS p.4; BSZ PDF p.24)",
      "one-time tax, responses temporary: no elasticity applied (BSZ PDF p.22 fn.29; Resp pp.1-3)",
      "BSZ export semi_elasticity_permanent (BSZ PDF p.28; Fig8!B8), used only for a permanent tax",
      "leavers' tax per $ of wealth / average, from BSZ export leavers_annual_inctax, leavers_wealth, ca_inctax_billionaires (SEC data, BSZ PDF p.26, Table 4 p.38)",
      "BSZ export ca_inctax_billionaires (Tab2!C14; BSZ PDF p.11)",
      "BSZ PDF p.27 ('If they last say only 5 years')",
      "BSZ export sell_share (BSZ PDF p.24)"),
    rauh_source = c(
      "omitted: Forbes CA-residence field (Rauh p.4; DISPUTES row 8)",
      "RJKDC export baseline_net_worth (212 billionaires, 2025 Forbes list; Rauh pp.4-5)",
      "1 - revenue_baseline / (5% x base) from the RJKDC export (Rauh p.8 Table 5, $8.19B among stayers)",
      "1 - revenue_confirmed6 / revenue_baseline from the RJKDC export (Rauh p.11, 6 departures)",
      "none: the elasticity replaces any avoidance allowance (Rauh pp.13-14)",
      "semi-elasticity applied to a 5.00 pp rate change (Rauh p.11 eq.7-8, p.14 eq.13)",
      "the Monte Carlo floor of $35B (Rauh p.20 eq.22; 'approximately 12.6', p.19)",
      "f = 1 - WT/94.20 (Rauh p.19, p.20)",
      "midpoint of C ~ U[3.3, 5.8] (Rauh p.20 eq.23)",
      "perpetuity (Rauh p.18 eq.17-18)",
      "not modelled"),
    stringsAsFactors = FALSE)
}

build_all <- function(k = read_contracts()) {
  bi <- bridge_inputs(k); sup <- bi$sup; rauh <- bi$rauh
  so <- k$bsz$outputs; oo <- k$rjkdc$outputs; d <- k$docs
  oi <- k$rjkdc$inputs
  steps <- bridge_steps()
  ids <- steps$step_id

  # ---- each side's own numbers ------------------------------------------------
  ggss_printed <- pick(so, "ggss_headline", "printed_value")
  bsz_row1     <- pick(so, "tab5_row1_wealth_tax_revenue")
  rauh_args <- list(wt_min = pick(oi, "rauh_mc_wt_min"),
                    wt_max = pick(oo, "revenue_confirmed6", "printed_value"),  # 67.51
                    baseline = pick(oo, "revenue_baseline", "printed_value"),  # 94.2
                    c_min = pick(oi, "rauh_mc_c_min"), c_max = pick(oi, "rauh_mc_c_max"),
                    r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
  nber_args <- list(wt_min = 0, wt_max = pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"),
                    f_min = pick(oi, "nber_mc_f_min"), f_max = pick(oi, "nber_mc_f_max"),
                    c_min = rauh_args$c_min, c_max = rauh_args$c_max,
                    r_min = rauh_args$r_min, r_max = rauh_args$r_max)
  rauh_own <- function(H) do.call(rauh_ssrn_expectation, c(rauh_args, list(H = H)))
  nber_own <- function(H) do.call(rauh_nber_expectation, c(nber_args, list(H = H)))

  # ---- bridges, for each horizon setting ---------------------------------------
  settings <- c("own", paste0("common_", HORIZONS))
  bridge <- list(); ends <- list()
  for (st in settings) {
    s2 <- sup; r2 <- rauh
    players <- ids
    if (st != "own") {
      H <- as.numeric(sub("common_", "", st))
      s2$H <- H; r2$H <- H
      players <- setdiff(ids, "horizon")
    }
    Hr <- r2$H
    v_sup  <- score_common(s2); v_rauh <- score_common(r2)
    own_r  <- rauh_own(Hr); own_n <- nber_own(Hr)
    for (out in c("a", "b")) {
      sh  <- shapley_bridge(s2, r2, players, out)
      sq  <- sequential_bridge(s2, r2, intersect(sequential_order(), players), out)
      full_sh <- stats::setNames(rep(0, length(ids)), ids); full_sh[players] <- sh
      full_sq <- stats::setNames(rep(0, length(ids)), ids); full_sq[names(sq)] <- sq
      bridge[[length(bridge) + 1]] <- data.frame(
        horizon_setting = st, output = out, step_id = ids,
        shapley = unname(full_sh), sequential = unname(full_sq),
        sequential_rank = match(ids, sequential_order()), stringsAsFactors = FALSE)
      ends[[length(ends) + 1]] <- data.frame(
        horizon_setting = st, output = out,
        bsz_model = v_sup[[out]], rauh_model = v_rauh[[out]],
        rauh_own = own_r[[out]], rauh_residual = own_r[[out]] - v_rauh[[out]],
        nber_own = own_n[[out]], nber_step = own_n[[out]] - own_r[[out]],
        stringsAsFactors = FALSE)
    }
  }
  bridge <- do.call(rbind, bridge); ends <- do.call(rbind, ends)
  bridge <- merge(bridge, steps, by = "step_id", sort = FALSE)
  bridge <- bridge[order(bridge$horizon_setting, bridge$output, match(bridge$step_id, ids)), ]
  rownames(bridge) <- NULL

  # ---- endpoint checks against printed numbers ---------------------------------
  own <- ends[ends$horizon_setting == "own", ]
  ea <- own[own$output == "a", ]; eb <- own[own$output == "b", ]
  endpoints <- data.frame(
    endpoint_id = c("ggss_headline", "ggss_scoring", "bsz_tab5_row1", "bsz_net_constructed",
                    "rauh_ssrn_revenue_mc", "rauh_ssrn_npv", "rauh_nber_revenue_mc", "rauh_nber_npv"),
    description = c(
      "GGSS headline: BSZ model + their rounding step",
      "GGSS scoring before rounding (p.4, '$104 billion')",
      "BSZ Table 5 row 1 wealth tax revenue = model at all-BSZ inputs",
      "BSZ row 1 net of its own extra income tax and 5 years of losses (not printed by BSZ; constructed here)",
      "Rauh SSRN expected revenue in the Monte Carlo, E[WT] = (35 + 67.51)/2",
      "Rauh SSRN mean NPV, analytic expectation of the Monte Carlo",
      "Rauh NBER expected revenue in the Monte Carlo, E[WT] = (0 + 72)/2",
      "Rauh NBER mean NPV, analytic expectation of the Monte Carlo"),
    value = c(ea$bsz_model + (ggss_printed - ea$bsz_model),
              ea$bsz_model, ea$bsz_model, eb$bsz_model,
              ea$rauh_own, eb$rauh_own, ea$nber_own, eb$nber_own),
    printed_value = c(ggss_printed, pick(so, "ggss_scoring", "printed_value"),
                      pick(so, "tab5_row1_wealth_tax_revenue", "printed_value"), NA,
                      NA, pick(oo, "npv_mc_ssrn_mean", "printed_value"),
                      NA, pick(oo, "npv_mc_nber_mean", "printed_value")),
    printed_where = c("GGSS p.4", "GGSS p.4", "BSZ Table 5, PDF p.39", "",
                      "", "Rauh SSRN p.20", "", "Jaros-Rauh NBER p.1, p.35"),
    contract_value = c(pick(so, "ggss_headline"), pick(so, "ggss_scoring"), bsz_row1, NA,
                       NA, pick(oo, "npv_mc_ssrn_mean"), NA, pick(oo, "npv_mc_nber_mean")),
    stringsAsFactors = FALSE)
  endpoints$abs_diff_printed <- abs(endpoints$value - endpoints$printed_value)

  # ---- output (a): which Rauh number is "the" revenue? (decided: MC mean, PLAN.md) --
  anchors <- data.frame(
    anchor_id = c("mc_expected", "literature_calibrated", "table9_central", "preferred_about_40"),
    label = c(sprintf("Expected WT in the Monte Carlo behind the %s mean NPV",
                      formatC(pick(oo, "npv_mc_ssrn_mean", "printed_value"), format = "f", digits = 1)),
              sprintf("Literature-calibrated (semi-elasticity %s)",
                      formatC(pick(k$rjkdc$inputs, "brulhart_semi_elasticity"), format = "f", digits = 2)),
              "Table 9 central scenario",
              "Preferred estimate, 'about $40 billion'"),
    value = c(ea$rauh_own, pick(oo, "revenue_literature_calibrated", "printed_value"),
              pick(k$rjkdc$inputs, "wt_central_scenario"), pick(d, "rauh_headline_revenue")),
    where = c("Rauh p.20 eq.22 (with the code's 67.51 ceiling)", "Rauh p.14 eq.13",
              "Rauh p.19 Table 9", "Rauh p.1 abstract, p.14"),
    default = c(TRUE, FALSE, FALSE, FALSE), stringsAsFactors = FALSE)
  anchors$residual_vs_model <- anchors$value - ea$rauh_model

  # ---- annual income tax loss: every source on one scale ------------------------
  A5 <- expected_annuity(5, sup$r_min, sup$r_max); Ainf <- expected_annuity(Inf, sup$r_min, sup$r_max)
  loss <- data.frame(
    source_id = c("bsz_row1", "bsz_row3", "lao_upper", "rauh_ssrn", "rauh_nber", "walczak_low", "walczak_high"),
    label = c("BSZ Table 5 row 1 (benchmark)", "BSZ Table 5 row 3 (aggressive leavers)",
              "LAO ballot analysis (upper bound, 'less than $1 billion')",
              "Rauh SSRN: E[f] x E[C]", "Rauh NBER: E[f] x E[C]",
              "Walczak / CalTax, low (incl. spillovers)", "Walczak / CalTax, high (incl. spillovers)"),
    side = c("bsz", "bsz", "neutral", "rjkdc", "rjkdc", "rjkdc (credited dial)", "rjkdc (credited dial)"),
    annual_loss = c(-pick(so, "tab5_row1_annual_ca_inctax_loss"), -pick(so, "tab5_row3_annual_ca_inctax_loss"),
                    pick(d, "lao_loss_upper"),
                    (1 - ea$rauh_own / rauh_args$baseline) * (rauh_args$c_min + rauh_args$c_max) / 2,
                    (nber_args$f_min + nber_args$f_max) / 2 * (rauh_args$c_min + rauh_args$c_max) / 2,
                    pick(d, "walczak_loss_low"), pick(d, "walczak_loss_high")),
    where = c("BSZ PDF p.39", "BSZ PDF p.39", "LAO p.2", "Rauh p.20", "NBER p.35", "Walczak p.1", "Walczak p.1"),
    stringsAsFactors = FALSE)
  loss$pv_5yr <- loss$annual_loss * A5
  loss$pv_perpetuity <- loss$annual_loss * Ainf
  # Walczak as a credited dial: Rauh's expected revenue net of Walczak's loss.
  loss$net_at_rauh_revenue_perpetuity <- ea$rauh_own - loss$pv_perpetuity

  # ---- Hoopes (2026) Figure 2 beside a Hoopes-shaped chain of ours ----------------
  hz <- k$hoopes
  seqa <- bridge[bridge$horizon_setting == "own" & bridge$output == "a", ]
  sq <- function(ids) sum(seqa$sequential[seqa$step_id %in% ids])
  ours <- c(galle_estimate = ggss_printed,
            ggss_rounding = ea$bsz_model - ggss_printed,
            residency_correction = sq(c("noncitizens", "base_list")),
            confirmed_departures = sq("confirmed_departures"),
            additional_movers = NA,
            additional_behavioral_response = sq(c("avoidance", "one_time_as_permanent", "elasticity_size")),
            real_estate_exclusion = sq("real_estate"),
            rauh_rounding = ea$rauh_residual,
            income_tax_loss = eb$rauh_own - ea$rauh_own)
  hoopes <- data.frame(step_id = names(ours), ours = unname(ours), stringsAsFactors = FALSE)
  hoopes$hoopes <- hz$delta[match(hoopes$step_id, hz$step_id)]
  hoopes$hoopes_uncertainty <- hz$uncertainty[match(hoopes$step_id, hz$step_id)]
  hoopes$our_steps <- c("GGSS printed headline", "GGSS's own rounding of their scoring",
                        "Non-US-citizen residents + base list and valuation date",
                        "Billionaires already departed",
                        "(none: Rauh's Monte Carlo headline does not use the ten 'expanded' departures)",
                        "Avoidance allowance + one-time tax as a permanent rate + elasticity size",
                        "Real-estate deduction", "Model difference (Rauh's rounded literals)",
                        "Rauh's own NPV minus his own expected revenue (all income-tax steps together)")

  list(inputs = bridge_input_table(bi), bridge = bridge, ends = ends, endpoints = endpoints,
       anchors = anchors, loss = loss, hoopes = hoopes,
       meta = data.frame(key = c("A_5", "A_inf", "kappa_bsz", "R0_rauh", "S_rauh",
                                 "X_bsz", "PV_bsz_own", "f_rauh", "C_rauh"),
                         value = c(A5, Ainf, sup$kappa, score_common(rauh)[["R0"]],
                                   score_common(rauh)[["S"]], score_common(sup)[["X"]],
                                   score_common(sup)[["PV"]], score_common(rauh)[["f"]], rauh$C)))
}

write_exports <- function(res, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (nm in c("inputs", "bridge", "ends", "endpoints", "anchors", "loss", "hoopes", "meta")) {
    utils::write.csv(res[[nm]], file.path(dir, paste0(nm, ".csv")), row.names = FALSE,
                     fileEncoding = "UTF-8")
  }
  invisible(dir)
}
