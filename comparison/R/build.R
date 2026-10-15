# Assemble every number the reconciliation page shows, from the contracts only.

HORIZONS <- c(5, 10, 20, 30, 50, Inf)

# The two input vectors, each value traced to a contract row or a document page. The JR
# values are those of the September 2026 version (Jaros and Rauh, NBER): the 2025 Forbes
# base grown 7% to the 31 December 2026 valuation date, net of real estate, the seven
# confirmed departures, the litigation-survival weight and the independently drawn share of
# the income tax base that leaves. The ceiling is the script's literal, 72 (the person-level
# file gives 72.05; the JR analysis's mismatch 4), so that the function returns the authors'
# own expectation exactly.
bridge_inputs <- function(k) {
  si <- k$bsz$inputs; so <- k$bsz$outputs
  oi <- k$rjkdc$inputs;   oo <- k$rjkdc$outputs
  d  <- k$docs
  W0      <- pick(si, "baseline_net_worth")
  noncit  <- pick(d, "ggss_noncitizen_wealth")
  C_sup   <- pick(si, "ca_inctax_billionaires")
  tau     <- pick(oi, "tax_rate")
  stopifnot(isTRUE(all.equal(tau, pick(si, "tax_rate"))))
  base_r  <- pick(oi, "baseline_net_worth") * (1 + pick(oi, "nber_growth_rate"))   # 2,027.4 at 31 Dec 2026
  R0_r    <- pick(oo, "nber_domestic_grown")           # 100.906, 5% of the grown base net of real estate
  ceiling <- pick(oi, "nber_ceiling_hardcoded")        # 72, after the seven confirmed departures
  # Departed wealth, the same people valued on each list. On the BSZ list (1 Jul 2026,
  # Table 5): the four pre-2026 leavers, plus Brin, plus Spielberg and Sacks, whom the BSZ
  # workbook does not list by name and who are valued at the JR file's net worth. On the JR
  # list (grown 7%, net of real estate): the four from the person-level file, and all seven
  # as the base less the script's 72 ceiling (the file itself sums to 72.05; mismatch 4).
  four_b  <- pick(si, "pre2026_leavers_wealth")
  seven_b <- four_b + pick(si, "brin_wealth") + pick(oi, "nber_spielberg_sacks_net_worth")
  four_j  <- pick(oi, "nber_departed_four_grown")
  seven_j <- (R0_r - ceiling) / tau
  # The leavers' own income tax at each stop, as the BSZ analysis counts it (Table 5): its
  # aggressive row loses the tax of all seven named leavers (four escape the wealth tax, three
  # pay it and leave later); the JR seven are Page, Thiel, Hankey and Kalanick, Brin, and
  # Spielberg and Sacks at BSZ's rate for billionaires without SEC data.
  L_bsz   <- pick(si, "leavers_annual_inctax")
  L_seven <- pick(si, "pre2026_leavers_annual_inctax") + pick(si, "brin_annual_inctax") +
    pick(si, "resid_inctax_rate") * pick(oi, "nber_spielberg_sacks_net_worth")
  shared <- list(tau = tau, m = pick(si, "mobility_share"), g = pick(si, "gains_share"),
                 t_cg = pick(si, "ca_cg_rate"),
                 r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
  sup <- c(shared, list(
    W_noncit = noncit, W_core = W0 - noncit, lam = 0, re = 0, dep_b = 0, dep_j = 0, L = 0,
    alpha = pick(si, "avoidance_rate"), q = 1,
    own = 1, f0 = 0, C = C_sup, H = pick(d, "bsz_loss_horizon"),
    s = pick(si, "sell_share")))
  rauh <- c(shared, list(
    W_noncit = 0, W_core = base_r, lam = 1, re = 1 - R0_r / (tau * base_r),
    dep_b = seven_b, dep_j = seven_j, L = L_seven, alpha = 0, q = pick(oi, "q_litigation_survival"),
    own = 0, f0 = (pick(oi, "nber_mc_f_min") + pick(oi, "nber_mc_f_max")) / 2,
    C = (pick(oi, "rauh_mc_c_min") + pick(oi, "rauh_mc_c_max")) / 2,
    H = pick(d, "rauh_loss_horizon"), s = 0))
  list(sup = sup, rauh = rauh,
       ladder = list(dep_b = c(0, four_b, seven_b), dep_j = c(0, four_j, seven_j), L = c(0, L_bsz, L_seven)))
}

# How each input is shown on the page: both values and where each comes from. The
# share-lost step has two rows, one per argument it switches.
bridge_input_table <- function(bi) {
  s <- bi$sup; r <- bi$rauh
  data.frame(
    step_id = c("noncitizens", "base_list", "base_list", "real_estate", "confirmed_departures", "confirmed_departures", "confirmed_departures", "avoidance",
                "litigation_survival", "income_loss_share", "income_loss_share",
                "income_level", "horizon", "asset_sales"),
    input = c("W_noncit", "W_core", "lam", "re", "dep_b", "dep_j", "L", "alpha", "q", "own", "f0", "C", "H", "s"),
    supporting_value = c(s$W_noncit, s$W_core, s$lam, s$re, s$dep_b, s$dep_j, s$L, s$alpha, s$q, s$own, s$f0,
                         s$C, s$H, s$s),
    rauh_value = c(r$W_noncit, r$W_core, r$lam, r$re, r$dep_b, r$dep_j, r$L, r$alpha, r$q, r$own, r$f0,
                   r$C, r$H, r$s),
    unit = c("$B", "$B", "list", "share", "$B", "$B", "$B/yr", "share", "probability", "rule", "share",
             "$B/yr", "years", "share"),
    supporting_source = c(
      "GGSS 20 Jul 2026 p.2 fn.1 (24 people, about $150B); BSZ PDF p.54 ($132B at 1 Jan)",
      "BSZ export baseline_net_worth ($2,307B, 1 Jul 2026; BSZ PDF p.24, GGSS p.4) minus the non-citizens",
      "the Forbes 2026 list (0 = BSZ list)",
      "no separate deduction (BSZ PDF p.24: 90% x 5% x $2,307B)",
      "benchmark taxes all 1 Jan 2026 residents (BSZ PDF p.23); the aggressive row 3 (Page, Thiel, Hankey, Kalanick, BSZ export pre2026_leavers_wealth) is the dial's middle stop",
      "no departures (on the JR list)",
      "no leavers' income tax lost",
      "BSZ export avoidance_rate (GGSS p.4; BSZ PDF p.24)",
      "the Act as written, collected in full: neither BSZ nor GGSS discounts for litigation",
      "the leavers' own income tax, in dollars, as BSZ Table 5 counts it (data: SEC filings for the top 3 and a wealth-proportional rate for the rest, BSZ PDF p.26, Table 4 p.38)",
      "no flat share: the loss follows the people who leave",
      "BSZ export ca_inctax_billionaires (Tab2!C14; BSZ PDF p.11): research, top wealth holders' income is 50% of top earners' (Balkir et al. 2025)",
      "BSZ PDF p.27 ('If they last say only 5 years')",
      "BSZ export sell_share (BSZ PDF p.24)"),
    rauh_source = c(
      "omitted: 28 international billionaires, $146.3B, excluded from the domestic base (JR export nber_international_net_worth; NBER chapter Sec. 3.5)",
      "JR export baseline_net_worth (212 billionaires, 2025 Forbes list) grown 7% to 31 Dec 2026 (JR export nber_growth_rate; NBER README, chapter p.19)",
      "the Forbes 2025 list grown 7% (1 = JR list)",
      "1 - nber_domestic_grown / (5% x grown base) from the JR export: the person-level file nets out directly held real estate (NBER README; chapter p.19)",
      "the seven confirmed departures (Page, Brin, Thiel, Hankey, Spielberg, Kalanick, Sacks) valued on the BSZ list: BSZ exports pre2026_leavers_wealth and brin_wealth (Table 5, 1 Jul 2026), plus Spielberg and Sacks at the JR file's net worth (JR export nber_spielberg_sacks_net_worth), as the BSZ workbook does not list them by name",
      "the same seven on the JR list: (nber_domestic_grown - 72) / 5%, the script's ceiling literal (NPV_dist_v8.R:19; the person-level file sums to 72.05, mismatch 4)",
      "the seven's own income tax as the BSZ analysis counts it: BSZ exports pre2026_leavers_annual_inctax and brin_annual_inctax, plus Spielberg and Sacks at resid_inctax_rate (used only under the BSZ rule for the share lost)",
      "none: no avoidance allowance (NBER chapter Secs. 4-5)",
      "q = 0.50, the ASC 740-10 'more likely than not' threshold (NBER README assumptions table; the script draws WT ~ U[0, 72], whose mean is 0.5 x 72; mismatch 5)",
      "not used: the share lost does not follow who leaves",
      "midpoint of f ~ U[0.30, 0.60], drawn independently of the revenue (NPV_dist_v8.R; chapter Sec. 5.4): guesswork",
      "midpoint of C ~ U[3.3, 5.8] (NPV_dist_v8.R:21; chapter pp.29-31): guesswork, the K = 500 floor is the authors' judgement",
      "perpetuity (chapter Sec. 5.4, eq. 18-19)",
      "not modelled"),
    stringsAsFactors = FALSE)
}

build_all <- function(k = read_contracts()) {
  bi <- bridge_inputs(k); sup <- bi$sup; rauh <- bi$rauh
  so <- k$bsz$outputs; oo <- k$rjkdc$outputs; d <- k$docs
  oi <- k$rjkdc$inputs
  ggss_printed <- pick(so, "ggss_headline", "printed_value")
  bsz_row1 <- pick(so, "tab5_row1_wealth_tax_revenue")
  # The JR analysis's own Monte Carlo (NPV_dist_v8.R), as the authors ship it.
  nber_args <- list(wt_min = 0, wt_max = pick(oi, "nber_ceiling_hardcoded"),
                    f_min = pick(oi, "nber_mc_f_min"), f_max = pick(oi, "nber_mc_f_max"),
                    c_min = pick(oi, "rauh_mc_c_min"), c_max = pick(oi, "rauh_mc_c_max"),
                    r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
  nber_own <- function(H) do.call(rauh_nber_expectation, c(nber_args, list(H = H)))

  steps <- bridge_steps(); ids <- steps$step_id
  settings <- c("own", paste0("common_", ifelse(is.infinite(HORIZONS), "Inf", HORIZONS)))
  bridge <- list(); ends <- list(); board <- list()
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
    own_n <- nber_own(Hr)
    # bit i-1 of a switchboard mask = input i in the bridge's order (ids); with a common
    # horizon the horizon is not a player, so only masks with its bit off are listed
    full_bit <- 2^(match(players, ids) - 1)
    for (out in c("a", "b")) {
      v   <- coalition_values(s2, r2, players, out)
      sh  <- shapley_bridge(s2, r2, players, out, v = v)
      cmask <- 0:(2^length(players) - 1)
      board[[length(board) + 1]] <- data.frame(
        output = out, horizon_setting = st,
        mask = vapply(cmask, function(m) sum(full_bit[bitwAnd(m, 2^(seq_along(players) - 1)) > 0]), 0),
        value = v, stringsAsFactors = FALSE)
      sq  <- sequential_bridge(s2, r2, intersect(sequential_order(), players), out)
      full_sh <- stats::setNames(rep(0, length(ids)), ids); full_sh[players] <- sh
      full_sq <- stats::setNames(rep(0, length(ids)), ids); full_sq[names(sq)] <- sq
      bridge[[length(bridge) + 1]] <- data.frame(
        horizon_setting = st, output = out, step_id = ids,
        shapley = unname(full_sh), sequential = unname(full_sq),
        sequential_rank = match(ids, sequential_order()), stringsAsFactors = FALSE)
      # rauh_own is the JR analysis's own expectation; rauh_residual, what the common
      # function at the JR inputs misses of it, is zero by construction (the script's
      # ceiling literal is the input) and kept so the identity is tested, not assumed
      ends[[length(ends) + 1]] <- data.frame(
        horizon_setting = st, output = out,
        bsz_model = v_sup[[out]], rauh_model = v_rauh[[out]],
        rauh_own = own_n[[out]], rauh_residual = own_n[[out]] - v_rauh[[out]],
        stringsAsFactors = FALSE)
    }
  }
  bridge <- do.call(rbind, bridge); ends <- do.call(rbind, ends)
  board <- do.call(rbind, board)
  board <- board[order(board$output, match(board$horizon_setting, settings), board$mask), ]
  board$mask <- as.integer(board$mask)
  rownames(board) <- NULL
  bridge <- merge(bridge, steps, by = "step_id", sort = FALSE)
  bridge <- bridge[order(bridge$horizon_setting, bridge$output, match(bridge$step_id, ids)), ]
  rownames(bridge) <- NULL

  # ---- endpoint checks against printed numbers ---------------------------------
  own <- ends[ends$horizon_setting == "own", ]
  ea <- own[own$output == "a", ]; eb <- own[own$output == "b", ]
  endpoints <- data.frame(
    endpoint_id = c("ggss_headline", "ggss_scoring", "bsz_tab5_row1", "bsz_net_constructed",
                    "rauh_nber_revenue_mc", "rauh_nber_npv"),
    description = c(
      "GGSS headline: BSZ model + their rounding step",
      "GGSS estimate before rounding (p.4, '$104 billion')",
      "BSZ Table 5 row 1 wealth tax revenue = model at all-BSZ inputs",
      "BSZ row 1 net of its own extra income tax and 5 years of losses (not printed by BSZ; constructed here)",
      "JR expected revenue in the Monte Carlo, E[WT] = (0 + 72)/2 = model at all-JR inputs",
      "JR mean NPV, analytic expectation of the Monte Carlo = model at all-JR inputs"),
    value = c(ea$bsz_model + (ggss_printed - ea$bsz_model),
              ea$bsz_model, ea$bsz_model, eb$bsz_model,
              ea$rauh_own, eb$rauh_own),
    printed_value = c(ggss_printed, pick(so, "ggss_scoring", "printed_value"),
                      pick(so, "tab5_row1_wealth_tax_revenue", "printed_value"), NA,
                      NA, pick(oo, "npv_mc_nber_mean", "printed_value")),
    printed_where = c("GGSS p.4", "GGSS p.4", "BSZ Table 5, PDF p.39", "",
                      "", "Jaros-Rauh NBER p.1, p.35"),
    contract_value = c(pick(so, "ggss_headline"), pick(so, "ggss_scoring"), bsz_row1, NA,
                       NA, pick(oo, "npv_mc_nber_mean")),
    stringsAsFactors = FALSE)
  endpoints$abs_diff_printed <- abs(endpoints$value - endpoints$printed_value)

  # ---- output (a): which JR revenue is "the" revenue? (decided: MC mean, PLAN.md) ------
  anchors <- data.frame(
    anchor_id = c("mc_expected", "preferred_about_30"),
    label = c(sprintf("Expected WT in the Monte Carlo behind the %s mean NPV",
                      formatC(pick(oo, "npv_mc_nber_mean", "printed_value"), format = "f", digits = 1)),
              "Preferred estimate, 'approximately $30 billion'"),
    value = c(ea$rauh_own, pick(d, "nber_headline_revenue")),
    where = c("NBER p.35, NPV_dist_v8.R (WT uniform between 0 and the 72 ceiling)",
              "NBER p.1 abstract, p.23 (0.5 x the recognized base, Zuckerberg excluded)"),
    default = c(TRUE, FALSE), stringsAsFactors = FALSE)
  anchors$residual_vs_model <- anchors$value - ea$rauh_model

  # ---- annual income tax loss: every source on one scale ------------------------
  A5 <- expected_annuity(5, sup$r_min, sup$r_max); Ainf <- expected_annuity(Inf, sup$r_min, sup$r_max)
  loss <- data.frame(
    source_id = c("bsz_row1", "bsz_row3", "lao_upper", "rauh_nber", "walczak_low", "walczak_high"),
    label = c("BSZ Table 5 row 1 (benchmark)", "BSZ Table 5 row 3 (aggressive leavers)",
              "LAO ballot analysis (upper bound, 'less than $1 billion')",
              "JR, Jaros and Rauh NBER: E[f] x E[C]",
              "Walczak / CalTax, low (incl. spillovers)", "Walczak / CalTax, high (incl. spillovers)"),
    side = c("bsz", "bsz", "neutral", "rjkdc", "walczak (credited dial)", "walczak (credited dial)"),
    annual_loss = c(-pick(so, "tab5_row1_annual_ca_inctax_loss"), -pick(so, "tab5_row3_annual_ca_inctax_loss"),
                    pick(d, "lao_loss_upper"),
                    (nber_args$f_min + nber_args$f_max) / 2 * (nber_args$c_min + nber_args$c_max) / 2,
                    pick(d, "walczak_loss_low"), pick(d, "walczak_loss_high")),
    where = c("BSZ PDF p.39", "BSZ PDF p.39", "LAO p.2", "NBER p.35", "Walczak p.1", "Walczak p.1"),
    stringsAsFactors = FALSE)
  loss$pv_5yr <- loss$annual_loss * A5
  loss$pv_perpetuity <- loss$annual_loss * Ainf
  # Each loss netted against the JR analysis's expected revenue on (a), in perpetuity.
  loss$net_at_nber_revenue_perpetuity <- ea$rauh_own - loss$pv_perpetuity

  # ---- Hoopes (2026) Figure 2 beside a Hoopes-shaped chain of ours ----------------
  hz <- k$hoopes
  seqa <- bridge[bridge$horizon_setting == "own" & bridge$output == "a", ]
  sq <- function(ids) sum(seqa$sequential[seqa$step_id %in% ids])
  ours <- c(galle_estimate = ggss_printed,
            ggss_rounding = ea$bsz_model - ggss_printed,
            residency_correction = sq(c("noncitizens", "base_list")),
            confirmed_departures = sq("confirmed_departures"),
            additional_movers = NA,
            additional_behavioral_response = sq(c("avoidance", "litigation_survival")),
            real_estate_exclusion = sq("real_estate"),
            rauh_rounding = ea$rauh_residual,
            income_tax_loss = eb$rauh_own - ea$rauh_own)
  hoopes <- data.frame(step_id = names(ours), ours = unname(ours), stringsAsFactors = FALSE)
  hoopes$hoopes <- hz$delta[match(hoopes$step_id, hz$step_id)]
  hoopes$hoopes_uncertainty <- hz$uncertainty[match(hoopes$step_id, hz$step_id)]
  hoopes$our_steps <- c("GGSS printed headline", "GGSS's own rounding of their estimate",
                        "Non-US-citizen residents + base list and valuation date",
                        "Billionaires already departed",
                        "(none: Rauh's Monte Carlo headline does not use the ten 'expanded' departures)",
                        "Avoidance allowance + chance the tax survives litigation (his bar is the March 2026 version's elasticity response, which the September version does not use)",
                        "Real-estate deduction", "(none: the common function returns the September version's expectation exactly)",
                        "The JR analysis's own NPV minus its own expected revenue (all income-tax steps together)")

  list(inputs = bridge_input_table(bi), bridge = bridge, ends = ends, endpoints = endpoints,
       anchors = anchors, loss = loss, hoopes = hoopes, switchboard = board,
       slider_sample = slider_sample(bi),
       dial_path = dial_path(bi),
       meta = data.frame(key = c("A_5", "A_inf", "L_bsz_aggressive", "R0_rauh", "S_rauh",
                                 "X_bsz", "PV_bsz_own", "f_rauh", "C_rauh"),
                         value = c(A5, Ainf, bi$ladder$L[2], score_common(rauh)[["R0"]],
                                   score_common(rauh)[["S"]], score_common(sup)[["X"]],
                                   score_common(sup)[["PV"]], score_common(rauh)[["f"]], rauh$C)))
}

write_exports <- function(res, dir) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (nm in c("inputs", "bridge", "ends", "endpoints", "anchors", "loss", "hoopes", "meta",
               "switchboard", "slider_sample", "dial_path")) {
    utils::write.csv(res[[nm]], file.path(dir, paste0(nm, ".csv")), row.names = FALSE,
                     fileEncoding = "UTF-8")
  }
  invisible(dir)
}
