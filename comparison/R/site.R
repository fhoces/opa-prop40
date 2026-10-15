# Render the site-root reconciliation page (index.html), the comparison explorer
# (comparison/site/explorer/index.html) and their data file (assets/comparison-data.js)
# from comparison/export/r/*.csv plus the contracts and document inputs. Every number on
# the two pages passes through here; the templates (comparison/site/index.template.html,
# comparison/site/explorer.template.html) hold prose and {{tokens}} only.

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
    dtau = if (v == 0) "none applied" else paste0(formatC(100 * v, format = "f", digits = 0), " pp"),
    eps = formatC(v, format = "f", digits = 2),
    kappa = formatC(v, format = "f", digits = 2),
    C = paste0(money(v, 2), "/yr"),
    H = if (is.infinite(v)) "perpetuity" else paste0(v, " years"),
    s = if (abs(v - 1/3) < 1e-9) "1/3" else pct(v, 0),
    format(v))
}

short_labels <- c(
  bsz = "BSZ Aug 2026", noncitizens = "Non-citizens", base_list = "Base list, date",
  real_estate = "Real estate", confirmed_departures = "Departed", avoidance = "No avoidance",
  one_time_as_permanent = "Permanent-rate", elasticity_size = "Elasticity size",
  income_proportional = "Proportional loss", income_level = "Income tax level",
  horizon = "Horizon", asset_sales = "Asset sales", rauh_resid = "Model diff.",
  nber_step = "Sep 2026 revision", nber = "JR Sep 2026")

# The explorer's sliders. Three inputs move a main estimate by less than $7B each when moved
# alone (measured 2026-10-14 on the BSZ / JR panel: non-citizens -7.0 / +4.1, real estate
# -0.5 / +0.2, asset sales -3.7 / +1.8), so the page folds them into one switch,
# "minor_inputs": off keeps the panel's own values, on takes the other analysis's values for
# all three. The other inputs get a slider each. The data file lists the three under
# sliders.minor and the page script expands the switch before calling model.js.
EXPLORER_MINOR <- c("noncitizens", "real_estate", "asset_sales")
explorer_slider_ids <- function() setdiff(bridge_steps()$step_id, EXPLORER_MINOR)

# The bars of every view of the bridge, in display order. The page shows each analysis in
# its latest version only: the first bar is the BSZ analysis (August 2026, Table 5 row 1),
# the last the JR analysis (Jaros and Rauh, NBER, September 2026). Between them: one
# step per disputed input (BSZ value to the JR value of its March 2026 version, the one
# whose inputs the common function takes one by one), the model difference, and the
# September 2026 revision. The
# export tables still carry the GGSS and March 2026 totals; the page shows neither as an end.
build_series <- function(ex, resid_label) {
  br <- ex$bridge; en <- ex$ends; steps <- bridge_steps()
  settings <- unique(en$horizon_setting)
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
        add("bsz", "total", e$bsz_model,
            if (o == "a") "BSZ analysis (August 2026): Table 5 row 1 wealth tax revenue"
            else paste0("BSZ analysis (August 2026): Table 5 row 1 net of its own extra income tax and lost income tax",
                        if (st == "own") " (5 years)" else Hlab))
        for (i in seq_len(nrow(b))) {
          rowlab <- if (grepl("^\\d", b$disputes_row[i])) paste0("DISPUTES row ", b$disputes_row[i], ", ") else "not a DISPUTES row, "
          add(b$step_id[i], "step", b[[m]][i], b$title[i], paste0(rowlab, b$kind[i]))
        }
        add("rauh_resid", "model", e$rauh_residual, resid_label, "model difference")
        add("nber_step", "step", e$nber_step,
            "September 2026 revision of the JR analysis: litigation-survival weight, 7% grown base, departure fraction drawn separately (the steps before it reach the March 2026 version, whose inputs the common function takes one by one)",
            "guesswork (litigation risk) + data")
        add("nber", "total", e$nber_own,
            if (o == "a") "JR analysis (Jaros and Rauh, NBER, September 2026): expected revenue in the Monte Carlo"
            else paste0("JR analysis (Jaros and Rauh, NBER, September 2026): mean NPV", Hlab))
        out[[st]][[o]][[m]] <- L
      }
    }
  }
  out
}

render_site <- function(root = comparison_root(),
                        template = file.path(root, "comparison", "site", "index.template.html"),
                        explorer = file.path(root, "comparison", "site", "explorer.template.html")) {
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
  tok$bsz_printed <- money(ep$printed_value[ep$endpoint_id == "bsz_tab5_row1"], 0)   # the digit the paper prints
  tok$bsz_row1_exact <- money(epv("bsz_tab5_row1"), 3)
  tok$rauh_npv <- money(epv("rauh_ssrn_npv"), 1)
  tok$nber_npv <- money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1)
  tok$rauh_a <- money(epv("rauh_ssrn_revenue_mc"), 2)
  tok$r_min <- pct(pick(k$rjkdc$inputs, "rauh_mc_r_min"), 1)
  tok$r_max <- pct(pick(k$rjkdc$inputs, "rauh_mc_r_max"), 1)
  tok$nber_growth <- pct(pick(k$rjkdc$inputs, "nber_growth_rate"))
  tok$x_sup <- money(mv("X_bsz"), 2)
  tok$pv_sup <- money(mv("PV_bsz_own"), 2)
  tok$loss_sup <- money(ex$loss$annual_loss[ex$loss$source_id == "bsz_row1"], 2)

  # ---- the headline: the two analyses' main estimates, next to each other ----
  # The BSZ main estimate is the net total over 5 years, which is also the BSZ end of the
  # bridge under the common output (b). The JR main estimate is the NBER mean NPV as the
  # JR pipeline reproduces the authors' seeded Monte Carlo (its contract row
  # npv_mc_nber_mean); the bridge's JR end is the exact expectation of the same Monte
  # Carlo. The explorer reads the same values from assets/comparison-data.js.
  rj_main <- ep$contract_value[ep$endpoint_id == "rauh_nber_npv"]
  tok$hl_bsz <- money(eb$bsz_model, 1)
  tok$hl_rjkdc <- money(rj_main, 1)
  tok$nber_end_b <- money(eb$nber_own, 1)
  tok$nber_end_b2 <- money(eb$nber_own, 2)
  tok$bsz_end_b <- money(eb$bsz_model, 1)
  # The gap on (b), stated in the explorer's footnote, not in the headline.
  gap_b <- eb$bsz_model - eb$nber_own
  tok$gap_b <- money(gap_b, 1)
  # Output (a), the secondary setting.
  gap <- ea$bsz_model - ea$nber_own
  tok$gap_a <- money(gap, 1)
  tok$gap_a_signed <- money(-gap, 1)
  tok$bsz_end_a <- money(ea$bsz_model, 1)
  tok$nber_end_a <- money(ea$nber_own, 1)
  tok$nber_wt_max <- money(pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"), 0)

  # ---- the two analyses on the common output, (b) first ----
  hr <- function(name, b, a, printed) sprintf(
    '    <tr><td>%s</td><td class="num">%s</td><td class="num">%s</td><td>%s</td></tr>',
    name, b, a, printed)
  tok$headline_rows <- paste(c(
    hr("BSZ analysis: Boll, Saez and Zucman, NBER WP 35218, Table 5 row 1 (Aug 2026)",
       money(eb$bsz_model, 1), money(ea$bsz_model, 1),
       sprintf("%s revenue (PDF p.39); no net figure", money(ep$printed_value[ep$endpoint_id == "bsz_tab5_row1"], 0))),
    hr("JR analysis: Jaros and Rauh, NBER c15504 (Sep 2026)", money(eb$nber_own, 2), money(ea$nber_own, 1),
       sprintf("mean NPV %s; revenue 'approximately %s' (p.1)", money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1),
               money(as.numeric(d$value[d$input_id == "nber_headline_revenue"]), 0)))
  ), collapse = "\n")

  # ---- the bridge series for the data file (the report draws the chart) ----
  resid_label <- sprintf(
    "Model difference: the JR Monte Carlo that the input values come from uses the rounded literals %s and %s where the model uses the workbook's own %s and %s",
    opp("revenue_baseline"), opp("revenue_confirmed6"),
    formatC(pick(k$rjkdc$outputs, "revenue_baseline"), format = "f", digits = 3),
    formatC(pick(k$rjkdc$outputs, "revenue_confirmed6"), format = "f", digits = 3))
  series <- build_series(ex, resid_label)

  # ---- the two slider panels: one slider per disputed input that moves the estimate, in
  # the bridge's order, then the minor-inputs switch and the September 2026 revision switch.
  # In both panels a slider prints the BSZ value at its left end and the JR value at its
  # right end, in the wording of the disputed-inputs table (fmt_input). The value of a slider
  # is its position as slider_inputs() (model.R) defines it, 0 = the panel's own analysis: the
  # BSZ panel's sliders run left to right, the JR panel's right to left (dir="rtl"). Each
  # slider carries an explanation (slider_tips), shown while the pointer is over it. The page
  # script reads the rest from D.sliders.
  dis0 <- inp[match(steps$step_id, inp$step_id), ]
  hz_fin <- SLIDER_HORIZONS[is.finite(SLIDER_HORIZONS)]
  hz_words <- paste0(paste(head(hz_fin, -1), collapse = ", "), " and ", tail(hz_fin, 1),
                     " years, and a perpetuity")
  slider_tips <- c(
    base_list = "The wealth the tax applies to, before departures and behaviour. The BSZ analysis values the Forbes list on 1 July 2026 (250 people), less the non-US citizens. The JR analysis uses the 2025 Forbes list (212 people), removing Ellison, Houston and Snyder and adding Sacks. DISPUTES row 7, data.",
    confirmed_departures = "The share of the base counted as already gone before the 1 January 2026 residency date. The BSZ analysis taxes every resident on that date, since an announced move is not a legal change of residence. The JR analysis drops six confirmed departures (Page, Brin, Thiel, Hankey, Spielberg, Sacks), 28% of its base. DISPUTES row 3, guesswork on data.",
    avoidance = "The share of the tax lost to avoidance and evasion other than leaving. The BSZ analysis allows 10%. The JR analysis allows none: its mobility response stands in for all behaviour. Not a DISPUTES row, guesswork.",
    one_time_as_permanent = "Whether the one-time 5% tax is estimated as if it were a permanent yearly rate. The BSZ analysis applies no mobility response, because a tax paid once cannot be escaped by leaving later. The JR analysis applies the response measured for recurring wealth taxes to the full 5 points, arguing that a constitutional amendment with no sunset is priced as recurring. DISPUTES row 1, scenario and guesswork.",
    elasticity_size = "How strongly the base shrinks per point of a permanent tax rate (the semi-elasticity: percent of the base lost per point). The BSZ analysis uses 10, and only for a permanent tax. The JR analysis uses about 12.6, above the 10.3 its literature source implies. Acts only once the permanent-rate slider is on. DISPUTES row 4, research and guesswork.",
    income_proportional = "Whether the income tax lost scales one for one with the wealth that leaves. The BSZ analysis uses the leavers' own tax from SEC filings: per dollar of wealth, the largest leavers pay about a third of the billionaire average. The JR analysis assumes full proportionality. DISPUTES row 6, data vs guesswork.",
    income_level = "Billionaires' yearly California income tax, the amount at risk each year. The BSZ analysis: about $3.1 billion from tax data, since top wealth holders earn about half of what top earners do. The JR analysis: $4.55 billion, the midpoint of a $3.3 billion to $5.8 billion range from two model bounds. DISPUTES row 5, research vs guesswork.",
    horizon = sprintf("How many years the income tax loss is counted. The BSZ analysis: 5 years, about the payment period, with responses temporary. The JR analysis: for ever, discounted at %s to %s. The slider's five settings are %s. DISPUTES row 2, scenario.",
                      tok$r_min, tok$r_max, hz_words),
    minor_inputs = "Three inputs that each move the estimate by less than $7 billion when moved alone: the 24 non-US-citizen residents ($150 billion of wealth; the BSZ analysis taxes them, the JR analysis omits them), the real-estate deduction (none in the BSZ analysis; the JR analysis deducts directly held homes, about 0.5% of the base) and the extra income tax from assets sold to pay the tax (the BSZ analysis counts it, the JR analysis does not). Off keeps this panel's own values; on takes the other analysis's values for all three.",
    revision = sprintf("The JR analysis's September 2026 revision (Jaros and Rauh, NBER). It weights the revenue by the chance that the tax survives litigation, grows the base %s to the end of 2026 and draws the share who leave independently of the revenue. Not an input of the common function: on, it adds a fixed step at this panel's horizon setting (see the note under the panels).",
                       tok$nber_growth))
  slider_row <- function(panel, id, name, title, tip, bsz_txt, rj_txt, max) {
    rtl <- panel == "rjkdc"
    ticks <- paste(sprintf('<i style="--t:%s"></i>', format((0:max) / max)), collapse = "")
    sprintf(paste0(
      '        <li class="sl" data-id="%2$s">\n',
      '          <label for="%1$s-%2$s"><b>%3$s</b> <span class="sl-title">%4$s</span></label>\n',
      '          <span class="sl-tip" role="tooltip" id="%1$s-%2$s-tip">%5$s</span>\n',
      '          <div class="sl-row"><span class="sl-end sl-lo">%6$s</span><span class="sl-track',
      '%9$s"><span class="sl-ticks" aria-hidden="true">%10$s</span><span class="sl-other" aria-hidden="true"></span>',
      '<input type="range" class="sl-in" id="%1$s-%2$s" min="0" max="%8$d" step="1" value="0" data-panel="%1$s" data-id="%2$s" aria-describedby="%1$s-%2$s-tip"%11$s>',
      '<output class="sl-cur" for="%1$s-%2$s">%12$s</output></span><span class="sl-end sl-hi">%7$s</span></div>\n',
      '          <span class="sl-note"></span>\n',
      '        </li>'),
      panel, id, esc(name), esc(title), esc(tip), bsz_txt, rj_txt, as.integer(max),
      if (rtl) " is-rtl" else "", ticks, if (rtl) ' dir="rtl"' else "",
      if (rtl) rj_txt else bsz_txt)
  }
  shown <- match(explorer_slider_ids(), steps$step_id)
  slider_rows <- function(panel) paste(c(vapply(shown, function(i) {
    slider_row(panel, steps$step_id[i], unname(short_labels[steps$step_id[i]]), steps$title[i],
               slider_tips[[steps$step_id[i]]],
               fmt_input(dis0$input[i], dis0$supporting_value[i]), fmt_input(dis0$input[i], dis0$rauh_value[i]),
               SLIDER_STEPS)
  }, ""),
    slider_row(panel, "minor_inputs", "Three minor inputs", "Non-citizens, real-estate deduction, asset-sale tax",
               slider_tips[["minor_inputs"]], "BSZ values", "JR values", 1),
    slider_row(panel, "revision", "September 2026 revision",
               "Not an input of the common function: see the note under the panels",
               slider_tips[["revision"]], "not applied", "applied", 1)),
    collapse = "\n")
  tok$sliders_bsz <- slider_rows("bsz")
  tok$sliders_rjkdc <- slider_rows("rjkdc")
  tok$hz_words <- hz_words
  ss <- read_csv_plain(file.path(root, "comparison", "export", "r", "slider_sample.csv"))
  tok$n_slider_sample <- format(nrow(ss), big.mark = ",")
  tok$n_slider_per_panel <- format(sum(ss$panel == "bsz"), big.mark = ",")
  tok$rev_step_b <- money(eb$nber_step, 1, TRUE)
  tok$rev_model_b <- money(eb$rauh_residual, 2, TRUE)

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
    sprintf('    <tr class="total"><td>End: Rauh net fiscal effect</td><td class="num">%s</td><td class="num">%s</td><td class="small">the March 2026 version&rsquo;s mean NPV</td></tr>',
            money(hz_end, 1), money(eb$rauh_own, 2))), collapse = "\n")
  dv <- function(id) as.numeric(d$value[d$input_id == id])
  hs_ <- function(id) hz$hoopes[hz$step_id == id]; ho <- function(id) hz$ours[hz$step_id == id]
  tok$hoopes_differences <- paste(sprintf("  <li>%s</li>", c(
    sprintf("<b>Vintage.</b> Hoopes's estimate uses the February GGSS text: %s billionaires, %s of wealth, %s gross, %s after 10%% avoidance, rounded up to %s (p.3 fn.1). The July GGSS text covers %s billionaires and %s: %s after avoidance, rounded down to %s. The same printed headline hides a rounding of %s in one vintage and of %s in the other.",
            dv("hoopes_n_billionaires"), money(dv("hoopes_wealth"), 0),
            money(dv("hoopes_gross"), 0), money(dv("hoopes_net"), 0), tok$ggss_headline,
            n_sup, money(inp$supporting_value[inp$input == "W_core"] + inp$supporting_value[inp$input == "W_noncit"], 0),
            money(epv("ggss_scoring"), 1), tok$ggss_headline,
            money(epv("ggss_headline") - dv("hoopes_net"), 0, TRUE), money(-ho("ggss_rounding"), 1, TRUE)),
    sprintf("<b>Residency.</b> His bar is %s, close to Rauh's own %s for dropping Ellison, Houston and Snyder and adding Sacks (Rauh p.5). By July the BSZ analysis has itself dropped Ellison, so our step is a different quantity: the %s of non-US-citizen residents Rauh omits plus the list and valuation-date difference, %s in one order.",
            hfmt(hs_("residency_correction"), NA), money(-dv("rauh_residency_correction"), 2), money(inp$supporting_value[inp$input == "W_noncit"], 0), money(ho("residency_correction"), 1, TRUE)),
    sprintf("<b>Confirmed departures.</b> His bar is %s; Rauh's own step is %s before avoidance (%s to %s, p.11), and ours is %s at that point of the order. We could not trace his figure to a number in Rauh et al.",
            hfmt(hs_("confirmed_departures"), NA), money(opp("revenue_confirmed6") - opp("revenue_baseline"), 2, TRUE),
            opp("revenue_baseline"), opp("revenue_confirmed6"), money(ho("confirmed_departures"), 1, TRUE)),
    sprintf("<b>Additional movers.</b> His %s matches Rauh's expanded ten-departure estimate (%s to %s, a step of %s, pp.12-13). The March 2026 version's own %s mean NPV does not use that estimate, so our bridge has no such step.",
            hfmt(hs_("additional_movers"), NA), opp("revenue_confirmed6"), opp("revenue_expanded10"),
            money(opp("revenue_expanded10") - opp("revenue_confirmed6"), 2, TRUE), tok$rauh_npv),
    sprintf("<b>Behaviour.</b> His %s is close to Rauh's step from the expanded estimate to the literature calibration (%s to %s, %s, p.14). Ours, %s in one order, nets three labelled steps: dropping the %s avoidance allowance (up), estimating the one-time tax as a permanent rate (down) and the elasticity from %s to %s (down).",
            hfmt(hs_("additional_behavioral_response"), NA), opp("revenue_expanded10"), opp("revenue_literature_calibrated"),
            money(opp("revenue_literature_calibrated") - opp("revenue_expanded10"), 2, TRUE),
            money(ho("additional_behavioral_response"), 1, TRUE),
            fmt_input("alpha", inp$supporting_value[inp$input == "alpha"]),
            fmt_input("eps", inp$supporting_value[inp$input == "eps"]), fmt_input("eps", inp$rauh_value[inp$input == "eps"])),
    sprintf("<b>Real estate.</b> His bar is drawn near zero (%s read off the chart), while his text says the exclusion reduces the base by about %s (p.4). The two are consistent: %s of base is about %s of revenue at 5%%. Ours is %s.",
            hfmt(hs_("real_estate_exclusion"), hz$hoopes_uncertainty[hz$step_id == "real_estate_exclusion"]),
            money(dv("hoopes_real_estate_base"), 0), money(dv("hoopes_real_estate_base"), 0),
            money(0.05 * dv("hoopes_real_estate_base"), 1), money(ho("real_estate_exclusion"), 2, TRUE)),
    sprintf("<b>Level before income tax.</b> His revenue level before the income-tax bar is about %s; Rauh's preferred estimate is 'about %s' (p.14) and the expected revenue in the Monte Carlo behind its mean NPV is %s. Our bridge uses the last, %s.",
            money(hz_pre, 1), money(dv("rauh_headline_revenue"), 0), money(ea$rauh_own, 2), money(ea$rauh_own, 2)),
    sprintf("<b>Income tax.</b> His single bar, %s, ends at %s, close to the March 2026 version's %s. That version's own expected present value of lost income tax is %s against %s of revenue, so with a different starting level his bar works as a plug. We split it into four labelled steps (proportionality, the income tax level, the horizon, asset-sale tax), which interact with the base steps.",
            hfmt(hs_("income_tax_loss"), NA), money(hz_end, 1), tok$rauh_npv, money(ho("income_tax_loss"), 2, TRUE), money(ea$rauh_own, 2)),
    "<b>Order and labels.</b> His is one sequential order, with no provenance labels; ours shows Shapley averages over all orders (a Shapley value: a step's effect averaged over every order the inputs could be switched in, so the steps add up to the gap) as well as one order, with each step labelled data, research, guesswork or scenario.",
    "<b>Steps he does not have.</b> The non-US-citizen residents, the BSZ analysis's avoidance allowance being dropped, the asset-sale income tax, and the September 2026 revision (which postdates his note)."
  )), collapse = "\n")
  tok$hoopes_fit <- money(as.numeric(hraw$tick_fit_max_resid[1]), 1)
  # Row 3 departure share, page (workbook values) vs DISPUTES / JR f dial (printed 94.2)
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
    sprintf('    <tr><td>Hoopes, SSRN 6428578</td><td>2026 (uses the February GGSS text)</td><td>%s billionaires, %s (p.3 fn.1)</td></tr>',
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
  ls <- ex$loss[ex$loss$source_id != "rauh_ssrn", ]
  who <- c(bsz = "BSZ", rjkdc = "JR", neutral = "neutral", "walczak (credited dial)" = "Walczak / CalTax (alternative dial; same direction as JR)")
  ls$label[ls$source_id == "rauh_nber"] <- "JR, Jaros and Rauh NBER: E[f] x E[C]"
  tok$loss_rows <- paste(sprintf(
    '    <tr><td>%s <span class="small">(%s)</span></td><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td></tr>',
    esc(ls$label), esc(ls$where), unname(who[ls$side]), vapply(ls$annual_loss, money, "", digits = 2),
    vapply(ls$pv_5yr, money, "", digits = 1), vapply(ls$pv_perpetuity, money, "", digits = 1),
    vapply(ls$net_at_nber_revenue_perpetuity, money, "", digits = 1)), collapse = "\n")
  tok$nber_a <- money(ea$nber_own, 1)

  tok$walczak_range <- sprintf("$%s-%sB", formatC(dv("walczak_loss_low"), format = "f", digits = 2),
                               formatC(dv("walczak_loss_high"), format = "f", digits = 2))
  # ---- parity note ----
  tok$parity_note <- "R and Python agree to 1e-9 on every exported number; see comparison/tests"

  fill <- function(path) {
    html <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    for (nm in names(tok)) html <- gsub(paste0("{{", nm, "}}"), tok[[nm]], html, fixed = TRUE)
    left <- regmatches(html, gregexpr("\\{\\{[a-z_0-9]+\\}\\}", html))[[1]]
    if (length(left)) stop("unfilled tokens in ", basename(path), ": ", paste(unique(left), collapse = ", "))
    paste0(html, "\n")
  }
  html <- fill(template)
  html_explorer <- fill(explorer)

  # headline: the two main estimates the explorer prints (bsz, rjkdc), and the bridge's
  # two ends under the common output (b), each analysis's own horizon (bsz_end_b, rjkdc_end_b).
  headline <- list(bsz = eb$bsz_model, rjkdc = rj_main,
                   rjkdc_printed = ep$printed_value[ep$endpoint_id == "rauh_nber_npv"],
                   bsz_end_b = eb$bsz_model, rjkdc_end_b = eb$nber_own)
  # The sliders: the two input vectors (bridge_inputs(), full precision; the perpetuity is
  # written "Inf"), the horizon settings and the number of steps of slider_inputs(), the two
  # revision constants at each horizon setting (slider_revision(), from ends.csv), and for
  # each slider the argument it moves and its two values as the page prints them, and the
  # inputs the page folds into one switch. The page's model.js computes every panel value
  # from these; test-site checks it against export/r/slider_sample.csv.
  bi <- bridge_inputs(k)
  sl_vec <- function(v) lapply(v, function(z) if (is.infinite(z)) "Inf" else z)
  rt <- slider_revision(en)
  sliders <- list(
    steps = SLIDER_STEPS, horizons = sl_vec(SLIDER_HORIZONS),
    values = list(bsz = sl_vec(bi$sup), rjkdc = sl_vec(bi$rauh)),
    revision = list(model = rt$model, revision = rt$revision),
    inputs = lapply(seq_len(nrow(steps)), function(i) list(
      id = steps$step_id[i], input = step_inputs[[steps$step_id[i]]],
      short = unname(short_labels[steps$step_id[i]]),
      bsz_text = fmt_input(dis0$input[i], dis0$supporting_value[i]),
      rjkdc_text = fmt_input(dis0$input[i], dis0$rauh_value[i]))),
    revision_text = list(bsz = "not applied", rjkdc = "applied"),
    minor = EXPLORER_MINOR)
  # The explorer shows the net fiscal effect, output (b), only, and the bridge at each
  # analysis's own horizon; output (a) and the common horizons stay in the exports, the
  # report and the tests, not in the data file the explorer reads.
  data <- list(headline = headline, series = list(own = list(b = series$own$b)), sliders = sliders)
  js <- paste0("/* Generated by comparison/R/site.R from comparison/export/r/. Do not edit. */\n",
               "window.__BRIDGE__ = ",
               jsonlite::toJSON(data, auto_unbox = TRUE, digits = NA, null = "null"), ";\n")
  list(html = html, explorer = html_explorer, js = js)
}

write_site <- function(root = comparison_root()) {
  s <- render_site(root)
  dir.create(file.path(root, "assets"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(s$html)), file.path(root, "index.html"))
  dir.create(file.path(root, "comparison", "site", "explorer"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(s$explorer)), file.path(root, "comparison", "site", "explorer", "index.html"))
  writeBin(charToRaw(enc2utf8(s$js)), file.path(root, "assets", "comparison-data.js"))
  invisible(s)
}
