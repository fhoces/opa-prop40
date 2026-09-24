# Render the site-root reconciliation page (index.html) and its data file
# (assets/comparison-data.js) from comparison/export/r/*.csv plus the contracts
# and document inputs. Every number on the page passes through here; the template
# (comparison/site/index.template.html) holds prose and {{tokens}} only.

money <- function(v, digits = 1, signed = FALSE) {
  if (length(v) != 1) return(vapply(v, money, "", digits = digits, signed = signed))
  if (is.na(v)) return("n/a")
  s <- formatC(abs(v), format = "f", digits = digits, big.mark = ",")
  sign <- if (v < 0) "−" else if (signed) "+" else ""
  paste0(sign, "$", s, "B")
}
pct <- function(v, digits = 0) paste0(formatC(100 * v, format = "f", digits = digits), "%")
esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

read_exports <- function(dir) {
  nm <- c("inputs", "bridge", "ends", "endpoints", "anchors", "loss", "hoopes", "meta")
  stats::setNames(lapply(nm, function(n) read_csv_plain(file.path(dir, paste0(n, ".csv")))), nm)
}

fmt_input <- function(input, v) {
  switch(input,
    W_noncit = , W_core = money(v, if (v %% 1 == 0) 0 else 1),
    re = , d_conf = , alpha = pct(v, 1),
    dtau = if (v == 0) "none scored" else paste0(formatC(100 * v, format = "f", digits = 0), " pp"),
    eps = formatC(v, format = "f", digits = 2),
    kappa = formatC(v, format = "f", digits = 2),
    C = paste0(money(v, 2), "/yr"),
    H = if (is.infinite(v)) "perpetuity" else paste0(v, " years"),
    s = if (abs(v - 1/3) < 1e-9) "1/3" else pct(v, 0),
    format(v))
}

short_labels <- c(
  ggss = "GGSS printed", ggss_rounding = "GGSS rounding", bsz = "BSZ row 1",
  bsz_net = "BSZ row 1 net", noncitizens = "Non-citizens", base_list = "Base list, date",
  real_estate = "Real estate", confirmed_departures = "Departed", avoidance = "No avoidance",
  one_time_as_permanent = "Permanent-rate", elasticity_size = "Elasticity size",
  income_proportional = "Proportional loss", income_level = "Income tax level",
  horizon = "Horizon", asset_sales = "Asset sales", rauh_resid = "Model diff.",
  rauh = "Rauh SSRN", nber_step = "NBER revision", nber = "Rauh NBER")

build_series <- function(ex, resid_label) {
  br <- ex$bridge; en <- ex$ends; ep <- ex$endpoints; steps <- bridge_steps()
  settings <- unique(en$horizon_setting)
  ggss <- ep$value[ep$endpoint_id == "ggss_headline"]
  out <- list()
  for (st in settings) {
    Hlab <- if (st == "own") "" else {
      h <- sub("common_", "", st); if (h == "Inf") " (perpetuity)" else paste0(" (", h, "-year horizon)") }
    out[[st]] <- list()
    for (o in c("a", "b")) {
      e <- en[en$horizon_setting == st & en$output == o, ]
      out[[st]][[o]] <- list()
      for (m in c("shapley", "sequential")) {
        b <- br[br$horizon_setting == st & br$output == o, ]
        b <- if (m == "sequential") b[order(b$sequential_rank), ] else b[match(steps$step_id, b$step_id), ]
        keep <- abs(b$shapley) > 1e-12 | abs(b$sequential) > 1e-12
        b <- b[keep, ]
        L <- list()
        add <- function(id, type, value, label, kind = NULL)
          L[[length(L) + 1]] <<- list(id = id, type = type, value = value, label = label,
                                     short = unname(short_labels[id]), kind = kind)
        if (o == "a") {
          add("ggss", "total", ggss, "GGSS headline, as printed (GGSS p.4)")
          add("ggss_rounding", "model", e$bsz_model - ggss,
              "GGSS round their scoring to the nearest $100B 'for simplicity' (p.4)", "rounding")
          add("bsz", "total", e$bsz_model, "BSZ Table 5 row 1 = the model at all-BSZ inputs (checkpoint)")
        } else {
          add("bsz_net", "total", e$bsz_model,
              paste0("BSZ row 1 net of its own asset-sale tax and income tax losses", Hlab, " (constructed)"))
        }
        for (i in seq_len(nrow(b))) {
          rowlab <- if (grepl("^\\d", b$disputes_row[i])) paste0("DISPUTES row ", b$disputes_row[i], ", ") else "not a DISPUTES row, "
          add(b$step_id[i], "step", b[[m]][i], b$title[i], paste0(rowlab, b$kind[i]))
        }
        add("rauh_resid", "model", e$rauh_residual, resid_label, "model difference")
        add("rauh", "total", e$rauh_own,
            if (o == "a") "Rauh SSRN: expected revenue in the Monte Carlo (Mar 2026)"
            else paste0("Rauh SSRN: mean NPV", if (st == "own") " (Mar 2026)" else paste0(" at Rauh's inputs", Hlab)))
        add("nber_step", "step", e$nber_step,
            "NBER revision: litigation-survival weight, 7% grown base, departure fraction drawn separately", "guesswork (litigation risk) + data")
        add("nber", "total", e$nber_own,
            if (o == "a") "Jaros and Rauh NBER: expected revenue in the Monte Carlo (Sep 2026)"
            else paste0("Jaros and Rauh NBER: mean NPV", if (st == "own") " (Sep 2026)" else Hlab))
        out[[st]][[o]][[m]] <- L
      }
    }
  }
  out
}

render_site <- function(root = comparison_root(),
                        template = file.path(root, "comparison", "site", "index.template.html")) {
  ex <- read_exports(file.path(root, "comparison", "export", "r"))
  k  <- read_contracts(root)
  d  <- k$docs
  ep <- ex$endpoints; en <- ex$ends; meta <- ex$meta; br <- ex$bridge
  mv <- function(key) meta$value[meta$key == key]
  epv <- function(id) ep$value[ep$endpoint_id == id]
  own <- en[en$horizon_setting == "own", ]
  ea <- own[own$output == "a", ]; eb <- own[own$output == "b", ]
  inp <- ex$inputs
  steps <- bridge_steps()
  tok <- list()
  opp <- function(id) pick(k$rjkdc$outputs, id, "printed_value")
  n_sup <- pick(k$bsz$inputs, "n_billionaires")
  n_rauh <- pick(k$rjkdc$inputs, "n_billionaires")

  tok$ggss_headline <- money(epv("ggss_headline"), 0)
  tok$ggss_scoring <- money(epv("ggss_scoring"), 1)
  tok$bsz_row1 <- money(epv("bsz_tab5_row1"), 1)
  tok$bsz_row1_exact <- money(epv("bsz_tab5_row1"), 3)
  tok$rauh_npv <- money(epv("rauh_ssrn_npv"), 1)
  tok$nber_npv <- money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1)
  tok$rauh_a <- money(epv("rauh_ssrn_revenue_mc"), 2)
  tok$r_min <- pct(pick(k$rjkdc$inputs, "rauh_mc_r_min"), 1)
  tok$r_max <- pct(pick(k$rjkdc$inputs, "rauh_mc_r_max"), 1)
  tok$x_sup <- money(mv("X_bsz"), 2)
  tok$pv_sup <- money(mv("PV_bsz_own"), 2)
  tok$loss_sup <- money(ex$loss$annual_loss[ex$loss$source_id == "bsz_row1"], 2)
  tok$rauh_resid_b <- money(eb$rauh_residual, 2)
  tok$n_orders <- format(factorial(nrow(steps)), big.mark = ",")

  # ---- headline table ----
  hr <- function(name, a, b, printed) sprintf(
    '    <tr><td>%s</td><td class="num">%s</td><td class="num">%s</td><td>%s</td></tr>',
    name, a, b, printed)
  tok$headline_rows <- paste(c(
    hr("GGSS expert report (20 Jul 2026)", money(epv("ggss_headline"), 0), "not computed",
       sprintf("%s scoring, rounded to %s (p.4)", money(epv("ggss_scoring"), 0), money(epv("ggss_headline"), 0))),
    hr("BSZ NBER WP 35218, Table 5 row 1 (Aug 2026)", money(epv("bsz_tab5_row1"), 1), money(eb$bsz_model, 1),
       sprintf("%s revenue (PDF p.39); no net figure", money(ep$printed_value[ep$endpoint_id == "bsz_tab5_row1"], 0))),
    hr("Rauh et al., SSRN 6340778 (17 Mar 2026)", money(ea$rauh_own, 2), money(eb$rauh_own, 2),
       sprintf("mean NPV %s (p.20); revenue 'about %s' (p.14)", money(ep$printed_value[ep$endpoint_id == "rauh_ssrn_npv"], 1),
               money(as.numeric(d$value[d$input_id == "rauh_headline_revenue"]), 0))),
    hr("Jaros and Rauh, NBER c15504 (Sep 2026)", money(ea$nber_own, 1), money(eb$nber_own, 2),
       sprintf("mean NPV %s; revenue 'approximately %s' (p.1)", money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1),
               money(as.numeric(d$value[d$input_id == "nber_headline_revenue"]), 0)))
  ), collapse = "\n")

  # ---- horizon buttons and notes ----
  hs <- setdiff(unique(en$horizon_setting), "own")
  hlab <- function(st) { h <- sub("common_", "", st); if (h == "Inf") "Perpetuity" else paste(h, "years") }
  tok$horizon_buttons <- paste(sprintf('    <button type="button" data-h="%s" aria-pressed="false">%s</button>', hs,
                                       vapply(hs, hlab, "")), collapse = "\n")
  notes <- list(own = sprintf(
    "Each side's own horizon: the BSZ side counts the losses for %s (BSZ PDF p.27), Rauh in perpetuity; the horizon is then one of the bridge steps. Output (a) does not depend on the horizon.",
    fmt_input("H", inp$supporting_value[inp$input == "H"])))
  for (st in hs) {
    e <- en[en$horizon_setting == st & en$output == "b", ]
    notes[[st]] <- sprintf(
      "Both sides at a common %s horizon, so the horizon is no longer a step. BSZ net %s; Rauh's inputs give %s at this horizon (his own printed number assumes a perpetuity).",
      tolower(hlab(st)), money(e$bsz_model, 1), money(e$rauh_own, 1))
  }
  tok$horizon_note_own <- notes$own

  # ---- bridge table (static default: (a), Shapley, own horizon) ----
  resid_label <- sprintf(
    "Model difference: Rauh's Monte Carlo uses the rounded literals %s and %s where the model uses the workbook's own %s and %s",
    opp("revenue_baseline"), opp("revenue_confirmed6"),
    formatC(pick(k$rjkdc$outputs, "revenue_baseline"), format = "f", digits = 3),
    formatC(pick(k$rjkdc$outputs, "revenue_confirmed6"), format = "f", digits = 3))
  series <- build_series(ex, resid_label)
  def <- series$own$a$shapley
  all_ids <- c("ggss", "ggss_rounding", "bsz", "bsz_net", steps$step_id, "rauh_resid", "rauh", "nber_step", "nber")
  in_def <- vapply(def, `[[`, "", "id")
  run <- 0; runs <- list()
  for (b in def) { run <- if (b$type == "total") b$value else run + b$value; runs[[b$id]] <- run }
  row_html <- vapply(all_ids, function(id) {
    b <- def[in_def == id]
    stp <- steps[steps$step_id == id, ]
    ii <- inp[inp$step_id == id, ]
    lab <- if (length(b)) b[[1]]$label else if (nrow(stp)) stp$title else id
    type <- if (length(b)) b[[1]]$type else if (nrow(stp)) "step" else if (id %in% c("ggss_rounding", "rauh_resid")) "model" else "total"
    cls <- switch(type, total = ' class="total"', model = ' class="model"', "")
    hide <- if (length(b)) "" else ' style="display:none"'
    val <- if (length(b) && type != "total") money(b[[1]]$value, if (abs(b[[1]]$value) < 0.05) 2 else 1, TRUE) else ""
    vcl <- if (length(b) && type == "step") (if (b[[1]]$value >= 0) "num step-pos" else "num step-neg") else "num"
    sprintf('    <tr data-id="%s"%s%s><td>%s</td><td>%s</td><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="%s">%s</td><td class="num">%s</td></tr>',
            id, cls, hide, esc(lab),
            if (nrow(stp)) esc(stp$disputes_row) else "",
            if (nrow(stp)) sprintf('<span class="kind">%s</span>', stp$kind) else "",
            if (nrow(ii)) fmt_input(ii$input, ii$supporting_value) else "",
            if (nrow(ii)) fmt_input(ii$input, ii$rauh_value) else "",
            vcl, val, if (length(b)) money(runs[[id]], 1) else "")
  }, "")
  tok$bridge_rows <- paste(row_html, collapse = "\n")

  # ---- findings, computed ----
  ba <- br[br$horizon_setting == "own" & br$output == "a", ]
  bb <- br[br$horizon_setting == "own" & br$output == "b", ]
  v <- function(df, id, col = "shapley") df[[col]][df$step_id == id]
  top3 <- ba[order(ba$shapley), ][1:3, ]
  tok$bridge_findings <- paste(sprintf("  <li>%s</li>", c(
    sprintf("Output (a) falls from %s to %s. The three largest Shapley steps are %s.",
            money(ea$bsz_model, 1), money(ea$rauh_own, 1),
            paste(sprintf("%s (%s, %s)", tolower(top3$title), money(top3$shapley, 1, TRUE), top3$kind), collapse = "; ")),
    sprintf("One step favours the BSZ side's number going up: Rauh applies no avoidance or evasion allowance beyond migration (his semi-elasticity is the migration share of Brulhart et al.'s response, Rauh pp.13-14), so dropping GGSS's 10%% adds %s (Shapley). DISPUTES.md does not list this as a row.",
            money(v(ba, "avoidance"), 1, TRUE)),
    sprintf("Order matters most for scoring the one-time tax as a permanent 5-percentage-point rate: %s averaged over all orders, %s in the one order shown. Rauh's revenue is uniform between a confirmed-departures ceiling and an elasticity floor, so the elasticity bites only on top of whatever departures are already in: the step is large when switched early and smaller when switched after the departures.",
            money(v(ba, "one_time_as_permanent"), 1, TRUE), money(v(ba, "one_time_as_permanent", "sequential"), 1, TRUE)),
    sprintf("For output (b) the horizon is the single largest step read in Hoopes's order (%s, the last switch, when the loss is already Rauh-sized) but only %s averaged over orders, because a perpetuity multiplies whatever annual loss the other inputs imply. The annual loss runs from %s (BSZ) to %s (Rauh).",
            money(v(bb, "horizon", "sequential"), 1, TRUE), money(v(bb, "horizon"), 1, TRUE),
            money(ex$loss$annual_loss[ex$loss$source_id == "bsz_row1"], 2),
            money(ex$loss$annual_loss[ex$loss$source_id == "rauh_ssrn"], 2)),
    sprintf("Model differences are small and shown, not hidden: %s on (a) and %s on (b), from Rauh's rounded literals (MISMATCHES #6 in rjkdc-analysis). Rauh's printed %s is the expectation of his Monte Carlo (%s); his seed-2026 run gives %s.",
            money(ea$rauh_residual, 4, TRUE), money(eb$rauh_residual, 2, TRUE),
            money(ep$printed_value[ep$endpoint_id == "rauh_ssrn_npv"], 1), money(eb$rauh_own, 3),
            money(ep$contract_value[ep$endpoint_id == "rauh_ssrn_npv"], 2)),
    sprintf("The NBER revision is one further step: %s on (a) and %s on (b). Its printed %s is one Monte Carlo run; the expectation is %s.",
            money(ea$nber_step, 1, TRUE), money(eb$nber_step, 1, TRUE),
            money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1), money(eb$nber_own, 2))
  )), collapse = "\n")

  # ---- anchors (output (a) candidates; default decided in PLAN.md) ----
  an <- ex$anchors
  tok$anchor_rows <- paste(sprintf(
    '    <tr%s><td>%s%s</td><td class="num">%s</td><td>%s</td><td class="num">%s</td></tr>',
    ifelse(an$default, ' class="total"', ""), esc(an$label), ifelse(an$default, " (used)", ""),
    vapply(an$value, money, "", digits = 2), esc(an$where),
    vapply(an$value - an$value[an$default], function(z) if (abs(z) < 1e-9) "none" else money(z, 2, TRUE), "")),
    collapse = "\n")

  # ---- Hoopes ----
  hz <- ex$hoopes; hraw <- k$hoopes
  hoopes_names <- c(galle_estimate = "Galle estimate", ggss_rounding = "(no bar)",
                    residency_correction = "Residency correction", confirmed_departures = "Confirmed departures",
                    additional_movers = "Additional movers", additional_behavioral_response = "Additional behavioral response",
                    real_estate_exclusion = "Real estate exclusion", rauh_rounding = "(no bar)",
                    income_tax_loss = "Income tax loss")
  hfmt <- function(x, u) if (is.na(x)) "none" else paste0(money(x, 1, TRUE), if (!is.na(u)) paste0(" &plusmn; ", formatC(u, format = "f", digits = 1)) else "")
  hz_end <- as.numeric(hraw$end[hraw$step_id == "income_tax_loss"])
  hz_pre <- as.numeric(hraw$end[hraw$step_id == "real_estate_exclusion"])
  tok$hoopes_rows <- paste(c(sprintf(
    '    <tr><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="small">%s</td></tr>',
    hoopes_names[hz$step_id],
    mapply(function(x, u, id) if (id == "galle_estimate") money(x, 0) else hfmt(x, u), hz$hoopes, hz$hoopes_uncertainty, hz$step_id),
    mapply(function(x, id) if (is.na(x)) "none" else if (id == "galle_estimate") money(x, 0) else money(x, if (abs(x) < 0.05) 4 else 1, TRUE), hz$ours, hz$step_id),
    esc(hz$our_steps)),
    sprintf('    <tr class="total"><td>End: Rauh net fiscal effect</td><td class="num">%s</td><td class="num">%s</td><td class="small">Rauh SSRN mean NPV</td></tr>',
            money(hz_end, 1), money(eb$rauh_own, 2))), collapse = "\n")
  dv <- function(id) as.numeric(d$value[d$input_id == id])
  hs_ <- function(id) hz$hoopes[hz$step_id == id]; ho <- function(id) hz$ours[hz$step_id == id]
  tok$hoopes_differences <- paste(sprintf("  <li>%s</li>", c(
    sprintf("<b>Vintage.</b> Hoopes scores the February GGSS text: %s billionaires, %s of wealth, %s gross, %s after 10%% avoidance, rounded up to %s (p.3 fn.1). The July GGSS text scores %s billionaires and %s: %s after avoidance, rounded down to %s. The same printed headline hides a rounding of %s in one vintage and of %s in the other.",
            dv("hoopes_n_billionaires"), money(dv("hoopes_wealth"), 0),
            money(dv("hoopes_gross"), 0), money(dv("hoopes_net"), 0), tok$ggss_headline,
            n_sup, money(inp$supporting_value[inp$input == "W_core"] + inp$supporting_value[inp$input == "W_noncit"], 0),
            money(epv("ggss_scoring"), 1), tok$ggss_headline,
            money(epv("ggss_headline") - dv("hoopes_net"), 0, TRUE), money(-ho("ggss_rounding"), 1, TRUE)),
    sprintf("<b>Residency.</b> His bar is %s, close to Rauh's own %s for dropping Ellison, Houston and Snyder and adding Sacks (Rauh p.5). By July the BSZ side has itself dropped Ellison, so our step is a different quantity: the %s of non-US-citizen residents Rauh omits plus the list and valuation-date difference, %s in one order.",
            hfmt(hs_("residency_correction"), NA), money(-dv("rauh_residency_correction"), 2), money(inp$supporting_value[inp$input == "W_noncit"], 0), money(ho("residency_correction"), 1, TRUE)),
    sprintf("<b>Confirmed departures.</b> His bar is %s; Rauh's own step is %s before avoidance (%s to %s, p.11), and ours is %s at that point of the order. We could not trace his figure to a number in Rauh et al.",
            hfmt(hs_("confirmed_departures"), NA), money(opp("revenue_confirmed6") - opp("revenue_baseline"), 2, TRUE),
            opp("revenue_baseline"), opp("revenue_confirmed6"), money(ho("confirmed_departures"), 1, TRUE)),
    sprintf("<b>Additional movers.</b> His %s matches Rauh's expanded ten-departure estimate (%s to %s, a step of %s, pp.12-13). Rauh's own %s headline does not use that estimate, so our bridge has no such step.",
            hfmt(hs_("additional_movers"), NA), opp("revenue_confirmed6"), opp("revenue_expanded10"),
            money(opp("revenue_expanded10") - opp("revenue_confirmed6"), 2, TRUE), tok$rauh_npv),
    sprintf("<b>Behaviour.</b> His %s is close to Rauh's step from the expanded estimate to the literature calibration (%s to %s, %s, p.14). Ours, %s in one order, nets three labelled steps: dropping the %s avoidance allowance (up), scoring the one-time tax as a permanent rate (down) and the elasticity from %s to %s (down).",
            hfmt(hs_("additional_behavioral_response"), NA), opp("revenue_expanded10"), opp("revenue_literature_calibrated"),
            money(opp("revenue_literature_calibrated") - opp("revenue_expanded10"), 2, TRUE),
            money(ho("additional_behavioral_response"), 1, TRUE),
            fmt_input("alpha", inp$supporting_value[inp$input == "alpha"]),
            fmt_input("eps", inp$supporting_value[inp$input == "eps"]), fmt_input("eps", inp$rauh_value[inp$input == "eps"])),
    sprintf("<b>Real estate.</b> His bar is drawn near zero (%s read off the chart), while his text says the exclusion reduces the base by about %s (p.4). The two are consistent: %s of base is about %s of revenue at 5%%. Ours is %s.",
            hfmt(hs_("real_estate_exclusion"), hz$hoopes_uncertainty[hz$step_id == "real_estate_exclusion"]),
            money(dv("hoopes_real_estate_base"), 0), money(dv("hoopes_real_estate_base"), 0),
            money(0.05 * dv("hoopes_real_estate_base"), 1), money(ho("real_estate_exclusion"), 2, TRUE)),
    sprintf("<b>Level before income tax.</b> His revenue level before the income-tax bar is about %s; Rauh's preferred estimate is 'about %s' (p.14) and the expected revenue in the Monte Carlo behind the headline is %s. Our bridge uses the last, %s.",
            money(hz_pre, 1), money(dv("rauh_headline_revenue"), 0), money(ea$rauh_own, 2), money(ea$rauh_own, 2)),
    sprintf("<b>Income tax.</b> His single bar, %s, ends at %s, close to Rauh's %s. Rauh's own expected present value of lost income tax is %s against %s of revenue, so with a different starting level his bar works as a plug. We split it into four labelled steps (proportionality, the income tax level, the horizon, asset-sale tax), which interact with the base steps.",
            hfmt(hs_("income_tax_loss"), NA), money(hz_end, 1), tok$rauh_npv, money(ho("income_tax_loss"), 2, TRUE), money(ea$rauh_own, 2)),
    "<b>Order and labels.</b> His is one sequential order, with no provenance labels; ours shows Shapley averages over all orders as well as one order, with each step labelled data, research, guesswork or scenario.",
    "<b>Steps he does not have.</b> The non-US-citizen residents, the BSZ side's avoidance allowance being dropped, the asset-sale income tax, and the NBER revision (which postdates his note)."
  )), collapse = "\n")
  tok$hoopes_fit <- money(as.numeric(hraw$tick_fit_max_resid[1]), 1)
  # Row 3 departure share, page (workbook values) vs DISPUTES / RJKDC f dial (printed 94.2)
  oval <- function(id) pick(k$rjkdc$outputs, id)
  tok$dconf_page <- pct(1 - oval("revenue_confirmed6") / oval("revenue_baseline"), 1)
  tok$dconf_printed <- pct(1 - opp("revenue_confirmed6") / opp("revenue_baseline"), 1)
  tok$conf6_value <- formatC(oval("revenue_confirmed6"), format = "f", digits = 2)
  tok$baseline_value <- formatC(oval("revenue_baseline"), format = "f", digits = 3)
  tok$baseline_printed <- formatC(opp("revenue_baseline"), format = "f", digits = 1)
  tok$hoopes_unc <- money(as.numeric(hraw$uncertainty[hraw$step_id == "confirmed_departures"]), 1)

  # ---- vintage ----
  tok$vintage_rows <- paste(c(
    sprintf('    <tr><td>Rauh et al., SSRN 6340778</td><td>17 Mar 2026</td><td>%s billionaires, %s, 2025 Forbes list</td></tr>',
            n_rauh, money(inp$rauh_value[inp$input == "W_core"], 1)),
    '    <tr><td>Galle, Gamage, Saez, Shanske, response to Rauh</td><td>17 Mar 2026</td><td>answers Rauh\'s 4 Mar version, not the 17 Mar copy used here</td></tr>',
    sprintf('    <tr><td>Hoopes, SSRN 6428578</td><td>2026 (scores the February GGSS text)</td><td>%s billionaires, %s (p.3 fn.1)</td></tr>',
            dv("hoopes_n_billionaires"), money(dv("hoopes_wealth"), 0)),
    sprintf('    <tr><td>GGSS expert report</td><td>updated 20 Jul 2026</td><td>%s billionaires, %s at 1 Jul 2026, non-citizens included, Ellison excluded</td></tr>',
            n_sup, money(inp$supporting_value[inp$input == "W_core"] + inp$supporting_value[inp$input == "W_noncit"], 0)),
    '    <tr><td>Boll, Saez, Zucman, NBER WP 35218</td><td>Aug 2026 revision</td><td>same 1 Jul 2026 base; Table 5 adds missing billionaires and leaver scenarios</td></tr>',
    sprintf('    <tr><td>Jaros and Rauh, NBER c15504</td><td>Sep 2026</td><td>Rauh\'s base grown %s to 31 Dec 2026, seven departures, litigation weight</td></tr>', pct(pick(k$rjkdc$inputs, "nber_growth_rate"))),
    '    <tr><td>LAO ballot analysis</td><td>for the 3 Nov 2026 ballot</td><td>no point estimate</td></tr>'), collapse = "\n")

  # ---- disputes table ----
  dis <- merge(steps, inp, by = "step_id", sort = FALSE)
  dis <- dis[match(steps$step_id, dis$step_id), ]
  tok$disputes_rows <- paste(sprintf(
    '    <tr><td>%s</td><td>%s</td><td><span class="kind">%s</span></td><td class="small"><b>%s</b>. %s</td><td class="small"><b>%s</b>. %s</td></tr>',
    esc(dis$disputes_row), esc(dis$title), dis$kind,
    mapply(fmt_input, dis$input, dis$supporting_value), esc(dis$supporting_source),
    mapply(fmt_input, dis$input, dis$rauh_value), esc(dis$rauh_source)), collapse = "\n")

  # ---- loss table ----
  ls <- ex$loss
  tok$loss_rows <- paste(sprintf(
    '    <tr><td>%s <span class="small">(%s)</span></td><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td></tr>',
    esc(ls$label), esc(ls$where), esc(ls$side), vapply(ls$annual_loss, money, "", digits = 2),
    vapply(ls$pv_5yr, money, "", digits = 1), vapply(ls$pv_perpetuity, money, "", digits = 1),
    vapply(ls$net_at_rauh_revenue_perpetuity, money, "", digits = 1)), collapse = "\n")

  tok$walczak_range <- sprintf("$%s-%sB", formatC(dv("walczak_loss_low"), format = "f", digits = 2),
                               formatC(dv("walczak_loss_high"), format = "f", digits = 2))
  # ---- parity note ----
  tok$parity_note <- "R and Python agree to 1e-9 on every exported number; see comparison/tests"

  html <- paste(readLines(template, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  for (nm in names(tok)) html <- gsub(paste0("{{", nm, "}}"), tok[[nm]], html, fixed = TRUE)
  left <- regmatches(html, gregexpr("\\{\\{[a-z_0-9]+\\}\\}", html))[[1]]
  if (length(left)) stop("unfilled tokens: ", paste(unique(left), collapse = ", "))

  data <- list(series = series, horizon_notes = notes)
  js <- paste0("/* Generated by comparison/R/site.R from comparison/export/r/. Do not edit. */\n",
               "window.__BRIDGE__ = ",
               jsonlite::toJSON(data, auto_unbox = TRUE, digits = NA, null = "null"), ";\n")
  list(html = paste0(html, "\n"), js = js)
}

write_site <- function(root = comparison_root()) {
  s <- render_site(root)
  dir.create(file.path(root, "assets"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(s$html)), file.path(root, "index.html"))
  writeBin(charToRaw(enc2utf8(s$js)), file.path(root, "assets", "comparison-data.js"))
  invisible(s)
}
