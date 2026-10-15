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
    q = pct(v, 0),
    own = if (v == 1) "the leavers' own tax" else "a flat share",
    L = paste0(money(v, 2), "/yr"),
    f0 = pct(v, 0),
    C = paste0(money(v, 2), "/yr"),
    H = if (is.infinite(v)) "perpetuity" else paste0(v, " years"),
    s = if (abs(v - 1/3) < 1e-9) "1/3" else pct(v, 0),
    format(v))
}

short_labels <- c(
  bsz = "BSZ Aug 2026", noncitizens = "Non-citizens", base_list = "Forbes source",
  real_estate = "Real estate", confirmed_departures = "Departed wealth", avoidance = "No avoidance",
  litigation_survival = "Litigation", income_loss_share = "Share lost",
  income_level = "Income tax level", horizon = "Horizon", asset_sales = "Asset sales",
  nber = "JR Sep 2026")

# The two values of a step as the pages print them (the share-lost step switches two
# arguments, kappa and f0, so its text names both), from export/r/inputs.csv.
step_texts <- function(inp, id) {
  ii <- inp[inp$step_id == id, ]
  if (id == "income_loss_share") {
    k <- ii[ii$input == "own", ]; f <- ii[ii$input == "f0", ]
    return(list(bsz = "what leavers paid",
                rjkdc = sprintf("%s of all", fmt_input("f0", f$rauh_value)),
                bsz_source = paste(k$supporting_source, f$supporting_source, sep = "; "),
                rjkdc_source = paste(f$rauh_source, k$rauh_source, sep = "; ")))
  }
  if (id == "confirmed_departures") {
    b <- ii[ii$input == "dep_b", ]; j <- ii[ii$input == "dep_j", ]
    return(list(bsz = "none",
                rjkdc = sprintf("the JR seven: %s on the BSZ list, %s on the JR list",
                                money(b$rauh_value, 0), money(j$rauh_value, 0)),
                bsz_source = b$supporting_source, rjkdc_source = paste(b$rauh_source, j$rauh_source, sep = "; "),
                bsz_short = "None", rjkdc_short = "JR seven"))
  }
  if (id == "base_list") ii <- ii[ii$input == "W_core", ]
  out <- list(bsz = fmt_input(ii$input, ii$supporting_value), rjkdc = fmt_input(ii$input, ii$rauh_value),
              bsz_source = ii$supporting_source, rjkdc_source = ii$rauh_source)
  # the explorer's dial ends name the list, the tables keep the dollars
  if (id == "base_list") {
    out$bsz_short <- "Forbes 2026"; out$rjkdc_short <- "Forbes 2025"
    out$bsz <- paste0("Forbes 2026, ", out$bsz); out$rjkdc <- paste0("Forbes 2025 grown 7%, ", out$rjkdc)
  }
  out
}
# The two ends as an explorer dial prints them: the short form where there is one.
# The share-lost dial's ends are f itself at each analysis's inputs (bi, from bridge_inputs());
# the page script then rewrites them from the other dials' positions.
dial_texts <- function(inp, id, bi = NULL) {
  tx <- step_texts(inp, id)
  if (id == "income_loss_share" && !is.null(bi))
    return(list(bsz = pct(score_common(bi$sup)[["f"]]), rjkdc = pct(score_common(bi$rauh)[["f"]])))
  list(bsz = tx$bsz_short %||% tx$bsz, rjkdc = tx$rjkdc_short %||% tx$rjkdc)
}

# The explorer's sliders. Three inputs move a main estimate by less than $7B each when moved
# alone (measured 2026-10-14 on the BSZ / JR panel: non-citizens -7.0 / +4.1, real estate
# -0.5 / +0.2, asset sales -3.7 / +1.8), so the page folds them into one switch,
# "minor_inputs": off keeps the panel's own values, on takes the other analysis's values for
# all three. The other inputs get a slider each. The data file lists the three under
# sliders.minor and the page script expands the switch before calling model.js.
EXPLORER_MINOR <- c("noncitizens", "real_estate", "asset_sales")
explorer_slider_ids <- function() setdiff(bridge_steps()$step_id, EXPLORER_MINOR)
# The dials that act together, boxed on the page by the two terms of the net fiscal effect.
# Inside a box the inputs multiply each other, so one dial's effect depends on where the
# others stand; between the boxes the terms are added (the BSZ share lost also scales with
# the departed dial, and the avoidance allowance enters both terms; the box notes say so).
EXPLORER_BOXES <- list(
  revenue = list(ids = c("base_list", "confirmed_departures", "avoidance", "litigation_survival"),
                 eq = "Wealth tax collected = 5% &times; (W &minus; D) &times; (1 &minus; a) &times; q",
                 lead = "The wealth on the list, less what has already left, less avoidance, times the chance the tax survives in court.",
                 more = "The four dials multiply each other, so the effect of one depends on where the others stand. W and D are valued on the same Forbes list. Hover over or tap a dial for what each analysis assumes."),
  loss = list(ids = c("income_loss_share", "income_level", "horizon"),
              eq = "Income tax lost = f &times; C &times; A(H)",
              lead = "The share of billionaires' income tax that leaves, times that income tax per year, counted over H years.",
              more = "A(H) is what $1 a year for H years is worth today, at the 1.5% to 4.5% discount rates both analyses use: about 5 for 5 years, about 37 for ever. The three dials multiply each other. In the BSZ analysis f also follows D in the box above. Hover over or tap a dial for what each analysis assumes."))
# Each dial shows only its symbol; the name and the explanation are in its hover box.
DIAL_SYMBOLS <- c(base_list = "W", confirmed_departures = "D", avoidance = "a",
                  litigation_survival = "q", income_loss_share = "f", income_level = "C",
                  horizon = "H")
# One or two words shown under a symbol (author instruction: f, C and H).
DIAL_WORDS <- c(income_loss_share = "share lost", income_level = "yearly tax", horizon = "years")

# The bars of every view of the bridge, in display order: the BSZ analysis (August 2026,
# Table 5 row 1), one step per disputed input (BSZ value to the JR value of its September
# 2026 version), and the JR analysis (Jaros and Rauh, NBER, September 2026). The common
# function returns both ends exactly, so there is no model-difference bar.
build_series <- function(ex) {
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
        add("nber", "total", e$rauh_own,
            if (o == "a") "JR analysis (Jaros and Rauh, NBER, September 2026): expected revenue in the Monte Carlo"
            else paste0("JR analysis (Jaros and Rauh, NBER, September 2026): mean NPV", Hlab))
        out[[st]][[o]][[m]] <- L
      }
    }
  }
  out
}

# The first eight hex digits of the MD5 of a text, as written (the data file's cache key).
data_hash <- function(txt) {
  tf <- tempfile(fileext = ".js"); on.exit(unlink(tf))
  writeBin(charToRaw(txt), tf)
  substr(unname(tools::md5sum(tf)), 1, 8)
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
  tok$nber_npv <- money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1)
  tok$nber_npv_abs <- money(-ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1)
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
  tok$nber_end_b <- money(eb$rauh_own, 1)
  tok$nber_end_b2 <- money(eb$rauh_own, 2)
  tok$bsz_end_b <- money(eb$bsz_model, 1)
  # The gap on (b), stated in the explorer's footnote, not in the headline.
  gap_b <- eb$bsz_model - eb$rauh_own
  tok$gap_b <- money(gap_b, 1)
  # Output (a), the secondary setting.
  gap <- ea$bsz_model - ea$rauh_own
  tok$gap_a <- money(gap, 1)
  tok$gap_a_signed <- money(-gap, 1)
  tok$bsz_end_a <- money(ea$bsz_model, 1)
  tok$nber_end_a <- money(ea$rauh_own, 1)
  tok$nber_wt_max <- money(pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"), 0)

  # ---- the two analyses on the common output, (b) first ----
  hr <- function(name, b, a, printed) sprintf(
    '    <tr><td>%s</td><td class="num">%s</td><td class="num">%s</td><td>%s</td></tr>',
    name, b, a, printed)
  tok$headline_rows <- paste(c(
    hr("BSZ analysis: Boll, Saez and Zucman, NBER WP 35218, Table 5 row 1 (Aug 2026)",
       money(eb$bsz_model, 1), money(ea$bsz_model, 1),
       sprintf("%s revenue (PDF p.39); no net figure", money(ep$printed_value[ep$endpoint_id == "bsz_tab5_row1"], 0))),
    hr("JR analysis: Jaros and Rauh, NBER c15504 (Sep 2026)", money(eb$rauh_own, 2), money(ea$rauh_own, 1),
       sprintf("mean NPV %s; revenue 'approximately %s' (p.1)", money(ep$printed_value[ep$endpoint_id == "rauh_nber_npv"], 1),
               money(as.numeric(d$value[d$input_id == "nber_headline_revenue"]), 0)))
  ), collapse = "\n")

  # ---- the bridge series for the data file (the report draws the chart) ----
  series <- build_series(ex)

  # ---- the two slider panels: one slider per disputed input that moves the estimate, in
  # the bridge's order, then the minor-inputs switch and the September 2026 revision switch.
  # In both panels a slider prints the BSZ value at its left end and the JR value at its
  # right end, in the wording of the disputed-inputs table (fmt_input). The value of a slider
  # is its position as slider_inputs() (model.R) defines it, 0 = the panel's own analysis: the
  # BSZ panel's sliders run left to right, the JR panel's right to left (dir="rtl"). Each
  # slider carries an explanation (slider_tips), shown while the pointer is over it. The page
  # script reads the rest from D.sliders.
  hz_fin <- SLIDER_HORIZONS[is.finite(SLIDER_HORIZONS)]
  hz_words <- paste0(paste(head(hz_fin, -1), collapse = ", "), " and ", tail(hz_fin, 1),
                     " years, and a perpetuity")
  bi0 <- bridge_inputs(k)
  slider_tips <- c(
    base_list = "Which Forbes list the base comes from, and so the wealth the tax applies to before departures and behaviour. Forbes 2026: the BSZ analysis values California's billionaires on 1 July 2026 (250 people, $2,157 billion without the non-US citizens). Forbes 2025: the JR analysis takes the 2025 list (212 people, with Ellison, Houston and Snyder removed and Sacks added) and grows it 7% to the 31 December 2026 valuation date ($2,027 billion). Two positions: one list or the other. Kind: data.",
    confirmed_departures = sprintf(paste(
      "Billionaires counted as already gone before the 1 January 2026 residency date, whose wealth the tax cannot reach.",
      "Three stops. None: the BSZ analysis's main estimate taxes every resident on that date, since an announced move is not a legal change of residence.",
      "BSZ four: Page, Thiel, Hankey and Kalanick, the BSZ analysis's own aggressive scenario (Table 5 row 3), %s on the BSZ list.",
      "JR seven: those four plus Brin, Spielberg and Sacks, the JR analysis's confirmed departures, %s on the BSZ list and %s on the JR list.",
      "Each stop is valued on the list chosen by the Forbes source dial.",
      "Kind: guesswork resting on data."),
      money(bi0$ladder$dep_b[2], 0), money(bi0$ladder$dep_b[3], 0), money(bi0$ladder$dep_j[3], 0)),
    avoidance = "The share of the tax lost to avoidance and evasion other than leaving. The BSZ analysis allows 10%. The JR analysis allows none. Kind: guesswork.",
    litigation_survival = "The chance that the Act survives a constitutional challenge, applied to the revenue. The BSZ analysis takes the Act as written and collected in full. The JR analysis weights the revenue by 50%, the accounting threshold for a tax that is more likely than not to stand; its simulation draws the revenue anywhere between zero and the ceiling, which has the same average. Kind: guesswork.",
    income_loss_share = sprintf(paste0(
      "The share of billionaires' income tax lost because people leave California.\n",
      "BSZ: what the leavers paid. %s with nobody gone (the half of avoidance done by moving), %s with D at its middle stop.\n",
      "JR: %s of all of it, whoever leaves (the middle of a 30%% to 60%% guess).\n",
      "Each end shows f where the other dials stand, so moving D or a changes it."),
      pct(score_common(bi0$sup)[["f"]]),
      pct(bi0$sup$alpha * bi0$sup$m + bi0$ladder$L[2] / bi0$sup$C), pct(bi0$rauh$f0)),
    income_level = "Billionaires' yearly California income tax, the amount at risk each year. The BSZ analysis: about $3.1 billion from tax data, since top wealth holders earn about half of what top earners do. The JR analysis: $4.55 billion, the midpoint of a $3.3 billion to $5.8 billion range from two model bounds. Kind: research (BSZ) against guesswork (JR).",
    horizon = sprintf("How many years the income tax loss is counted. The BSZ analysis: 5 years, about the payment period, with responses temporary. The JR analysis: for ever, discounted at %s to %s. The slider's five settings are %s. Kind: scenario.",
                      tok$r_min, tok$r_max, hz_words),
    minor_inputs = "Three inputs that each move the estimate by less than $7 billion when moved alone: the non-US-citizen residents ($150 billion of wealth; the BSZ analysis taxes them, the JR analysis leaves its 28 international billionaires out), the real-estate deduction (none in the BSZ analysis; the JR analysis nets out directly held homes, about 0.5% of the base) and the extra income tax from assets sold to pay the tax (the BSZ analysis counts it, the JR analysis does not). Off keeps this panel's own values; on takes the other analysis's values for all three.")
  slider_row <- function(panel, id, name, title, tip, bsz_txt, rj_txt, max, sym = FALSE) {
    rtl <- panel == "rjkdc"
    ticks <- paste(sprintf('<i style="--t:%s"></i>', format((0:max) / max)), collapse = "")
    sprintf(paste0(
      '        <li class="sl%13$s" data-id="%2$s">\n',
      '          <label for="%1$s-%2$s"><b>%3$s</b> <span class="sl-title">%4$s</span></label>\n',
      '          <span class="sl-tip" role="tooltip" id="%1$s-%2$s-tip">%5$s</span>\n',
      '          <div class="sl-row"><span class="sl-end sl-lo">%6$s</span><span class="sl-track',
      '%9$s"><span class="sl-ticks" aria-hidden="true">%10$s</span><span class="sl-other" aria-hidden="true"></span>',
      '<input type="range" class="sl-in" id="%1$s-%2$s" min="0" max="%8$d" step="1" value="0" data-panel="%1$s" data-id="%2$s" aria-describedby="%1$s-%2$s-tip"%11$s>',
      '<output class="sl-cur" for="%1$s-%2$s">%12$s</output></span><span class="sl-end sl-hi">%7$s</span></div>\n',
      '          <span class="sl-note"></span>\n',
      '        </li>'),
      panel, id, if (sym) paste0('<span class="sym">', esc(name), '</span>',
                                 if (!is.na(DIAL_WORDS[id])) paste0('<span class="sym-word">', DIAL_WORDS[[id]], '</span>') else "")
                 else esc(name),
      if (sym) paste0('<span class="sr">', esc(title), '</span>') else esc(title), gsub("\n", "<br>", esc(tip), fixed = TRUE), bsz_txt, rj_txt, as.integer(max),
      if (rtl) " is-rtl" else "", ticks, if (rtl) ' dir="rtl"' else "",
      if (rtl) rj_txt else bsz_txt, if (sym) " has-sym" else "")
  }
  step_row <- function(panel, id) {
    i <- match(id, steps$step_id); tx <- dial_texts(inp, id, bi0)
    slider_row(panel, id, unname(DIAL_SYMBOLS[id]), unname(short_labels[id]),
               paste0(DIAL_SYMBOLS[[id]], ", ", sub("^forbes", "Forbes", tolower(unname(short_labels[id]))), ". ", slider_tips[[id]]),
               tx$bsz, tx$rjkdc, slider_max(id), sym = TRUE)
  }
  box <- function(panel, key) {
    bx <- EXPLORER_BOXES[[key]]
    paste0(
      '        <li class="sl-box" role="group" aria-labelledby="', panel, '-', key, '-head">\n',
      '          <div class="sl-box-head">\n',
      '            <p class="box-eq" id="', panel, '-', key, '-head">', bx$eq, '</p>\n',
      '            <p class="box-lead">', bx$lead, ' <span class="info" tabindex="0" aria-describedby="', panel, '-', key, '-more">more',
      '<span class="info-tip" role="tooltip" id="', panel, '-', key, '-more">', bx$more, '</span></span></p>\n',
      '          </div>\n',
      '          <ul class="sl-list">\n',
      paste(vapply(bx$ids, function(id) step_row(panel, id), ""), collapse = "\n"), "\n",
      '          </ul>\n',
      '        </li>')
  }
  stopifnot(identical(unname(unlist(lapply(EXPLORER_BOXES, `[[`, "ids"))), explorer_slider_ids()))
  # The three minor inputs: one switch that moves all three, and a fold that opens into the
  # three dials themselves (the switch sets them; each can then be moved on its own).
  minor_tips <- c(
    noncitizens = "The non-US-citizen residents: $150 billion of wealth that the BSZ analysis taxes and the JR analysis leaves out with its 28 international billionaires. Kind: data.",
    real_estate = "The real-estate deduction: none in the BSZ analysis; the JR analysis nets out directly held homes, about 0.5% of the base. Kind: data.",
    asset_sales = "Extra income tax from assets sold to pay the tax: the BSZ analysis assumes a third of the tax is paid by selling assets, whose gains are taxed; the JR analysis does not count this. Kind: guesswork.")
  minor_block <- function(panel) paste0(
    slider_row(panel, "minor_inputs", "Three minor inputs", "Non-citizens, real-estate deduction, asset-sale tax",
               slider_tips[["minor_inputs"]], "BSZ values", "JR values", 1), "\n",
    '        <li class="sl-minor"><details class="minor-fold"><summary>Show the three inputs one by one</summary>\n',
    '          <ul class="sl-list">\n',
    paste(vapply(EXPLORER_MINOR, function(id) {
      i <- match(id, steps$step_id); tx <- dial_texts(inp, id, bi0)
      slider_row(panel, id, unname(short_labels[id]), steps$title[i], minor_tips[[id]],
                 tx$bsz, tx$rjkdc, slider_max(id))
    }, ""), collapse = "\n"), "\n",
    '          </ul>\n',
    '        </details></li>')
  slider_rows <- function(panel) paste(c(
    vapply(names(EXPLORER_BOXES), function(key) box(panel, key), ""),
    minor_block(panel)),
    collapse = "\n")
  tok$sliders_bsz <- slider_rows("bsz")
  tok$sliders_rjkdc <- slider_rows("rjkdc")
  tok$hz_words <- hz_words
  ss <- read_csv_plain(file.path(root, "comparison", "export", "r", "slider_sample.csv"))
  tok$n_slider_sample <- format(nrow(ss), big.mark = ",")
  tok$n_slider_per_panel <- format(sum(ss$panel == "bsz"), big.mark = ",")
  # ---- the pseudo-equation: BSZ estimate - the three largest steps - the rest = JR estimate.
  # Each term is a Shapley step on (b), read from the BSZ end to the JR end, so the terms take
  # the BSZ end to the JR end exactly.
  bb <- br[br$horizon_setting == "own" & br$output == "b", ]
  bb <- bb[order(-abs(bb$shapley)), ]
  top <- bb[1:3, ]; rest <- sum(bb$shapley[-(1:3)])
  term <- function(v, label) sprintf('<span class="op">%s</span><span class="term"><b>%s</b><small>%s</small></span>',
                                     if (v < 0) "&minus;" else "+", money(abs(v), 1), esc(label))
  say <- function(v, what) sprintf("%s %s for %s", if (v < 0) "minus" else "plus", money(abs(v), 1), what)
  tok$pseudo_eq <- paste0(
    '<div class="pseudo-eq" role="img" aria-label="', esc(sprintf(
      "The BSZ estimate, %s, %s, %s, %s, and %s, gives about the JR estimate, %s.",
      money(eb$bsz_model, 1),
      say(top$shapley[1], tolower(top$title[1])), say(top$shapley[2], tolower(top$title[2])),
      say(top$shapley[3], tolower(top$title[3])),
      say(rest, sprintf("the %d other inputs", nrow(bb) - 3)), money(eb$rauh_own, 1))), '">\n',
    sprintf('  <span class="term"><b>%s</b><small>BSZ estimate</small></span>\n', money(eb$bsz_model, 1)),
    paste(vapply(1:3, function(i) paste0("  ", term(top$shapley[i], top$title[i])), ""), collapse = "\n"), "\n",
    "  ", term(rest, sprintf("the %d other inputs together", nrow(bb) - 3)), "\n",
    sprintf('  <span class="op">&asymp;</span><span class="term"><b>%s</b><small>JR estimate</small></span>\n', money(eb$rauh_own, 1)),
    '</div>')
  tok$pseudo_eq_note <- sprintf(paste0(
    "Start from the BSZ estimate and take away what each disagreement costs: each term is that input's effect on the net fiscal effect when switched from the BSZ value to the JR value, averaged over every order the inputs could be switched in (its Shapley value). The terms add up exactly. ",
    "The JR estimate here is the exact mean of the authors' Monte Carlo, %s; their seeded run prints %s. The <a href=\"%s\">report</a> gives every step."),
    money(eb$rauh_own, 1), tok$hl_rjkdc, "%s")
  tok$pseudo_eq_note_x <- sub("%s", "../repro.html#the-bridge", tok$pseudo_eq_note, fixed = TRUE)
  tok$pseudo_eq_note_root <- sub("%s", "comparison/site/repro.html#the-bridge", tok$pseudo_eq_note, fixed = TRUE)
  tok$pseudo_eq_note <- NULL

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
    sprintf('    <tr class="total"><td>End: Rauh net fiscal effect</td><td class="num">%s</td><td class="num">%s</td><td class="small">his: the March 2026 version&rsquo;s mean NPV; ours: the September 2026 version&rsquo;s</td></tr>',
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
            money(opp("revenue_expanded10") - opp("revenue_confirmed6"), 2, TRUE), money(opp("npv_mc_ssrn_mean"), 1)),
    sprintf("<b>Behaviour.</b> His %s is close to the March 2026 version's step from the expanded estimate to the literature calibration (%s to %s, %s, p.14), a mobility response from a European elasticity. The September 2026 version predicts no such departures; in their place it weights the revenue by the chance the tax survives litigation. Ours, %s in one order, nets two labelled steps: dropping the %s avoidance allowance (up) and the litigation weight (down).",
            hfmt(hs_("additional_behavioral_response"), NA), opp("revenue_expanded10"), opp("revenue_literature_calibrated"),
            money(opp("revenue_literature_calibrated") - opp("revenue_expanded10"), 2, TRUE),
            money(ho("additional_behavioral_response"), 1, TRUE),
            fmt_input("alpha", inp$supporting_value[inp$input == "alpha"])),
    sprintf("<b>Real estate.</b> His bar is drawn near zero (%s read off the chart), while his text says the exclusion reduces the base by about %s (p.4). The two are consistent: %s of base is about %s of revenue at 5%%. Ours is %s.",
            hfmt(hs_("real_estate_exclusion"), hz$hoopes_uncertainty[hz$step_id == "real_estate_exclusion"]),
            money(dv("hoopes_real_estate_base"), 0), money(dv("hoopes_real_estate_base"), 0),
            money(0.05 * dv("hoopes_real_estate_base"), 1), money(ho("real_estate_exclusion"), 2, TRUE)),
    sprintf("<b>Level before income tax.</b> His revenue level before the income-tax bar is about %s, near the March 2026 version's preferred 'about %s' (p.14). Ours ends at %s, the expected revenue in the Monte Carlo behind the September 2026 version's mean NPV (its text prefers 'approximately %s', p.1).",
            money(hz_pre, 1), money(dv("rauh_headline_revenue"), 0), money(ea$rauh_own, 2), money(dv("nber_headline_revenue"), 0)),
    sprintf("<b>Income tax.</b> His single bar, %s, ends at %s, close to the March 2026 version's %s. Ours is %s, the September 2026 version's expected present value of lost income tax against %s of revenue, and we split it into four labelled steps (the share lost, the income tax level, the horizon, asset-sale tax), which interact with the base steps.",
            hfmt(hs_("income_tax_loss"), NA), money(hz_end, 1), money(opp("npv_mc_ssrn_mean"), 1), money(ho("income_tax_loss"), 2, TRUE), money(ea$rauh_own, 2)),
    "<b>Order and labels.</b> His is one sequential order, with no provenance labels; ours shows Shapley averages over all orders (a Shapley value: a step's effect averaged over every order the inputs could be switched in, so the steps add up to the gap) as well as one order, with each step labelled data, research, guesswork or scenario.",
    "<b>Steps he does not have.</b> The non-US-citizen residents, the BSZ analysis's avoidance allowance being dropped, the asset-sale income tax, and the litigation weight of the September 2026 version (which postdates his note)."
  )), collapse = "\n")
  tok$hoopes_fit <- money(as.numeric(hraw$tick_fit_max_resid[1]), 1)
  # Row 3 departure share: the script's ceiling literal over the grown domestic face value
  oval <- function(id) pick(k$rjkdc$outputs, id)
  tok$dconf_sept <- pct(inp$rauh_value[inp$input == "d_conf"], 1)
  tok$ceiling_literal <- formatC(pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"), format = "f", digits = 0)
  tok$ceiling_file <- formatC(oval("nber_ceiling"), format = "f", digits = 2)
  tok$domestic_grown <- formatC(oval("nber_domestic_grown"), format = "f", digits = 3)
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
  tx <- lapply(steps$step_id, function(id) step_texts(inp, id))
  tok$disputes_rows <- paste(sprintf(
    '    <tr><td>%s</td><td>%s</td><td><span class="kind">%s</span></td><td class="small"><b>%s</b>. %s</td><td class="small"><b>%s</b>. %s</td></tr>',
    esc(steps$disputes_row), esc(steps$title), steps$kind,
    vapply(tx, `[[`, "", "bsz"), esc(vapply(tx, `[[`, "", "bsz_source")),
    vapply(tx, `[[`, "", "rjkdc"), esc(vapply(tx, `[[`, "", "rjkdc_source"))), collapse = "\n")

  # ---- loss table ----
  ls <- ex$loss
  who <- c(bsz = "BSZ", rjkdc = "JR", neutral = "neutral", "walczak (credited dial)" = "Walczak / CalTax (alternative dial; same direction as JR)")
  tok$loss_rows <- paste(sprintf(
    '    <tr><td>%s <span class="small">(%s)</span></td><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td></tr>',
    esc(ls$label), esc(ls$where), unname(who[ls$side]), vapply(ls$annual_loss, money, "", digits = 2),
    vapply(ls$pv_5yr, money, "", digits = 1), vapply(ls$pv_perpetuity, money, "", digits = 1),
    vapply(ls$net_at_nber_revenue_perpetuity, money, "", digits = 1)), collapse = "\n")
  tok$nber_a <- money(ea$rauh_own, 1)

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
  # headline: the two main estimates the explorer prints (bsz, rjkdc), and the bridge's
  # two ends under the common output (b), each analysis's own horizon (bsz_end_b, rjkdc_end_b).
  headline <- list(bsz = eb$bsz_model, rjkdc = rj_main,
                   rjkdc_printed = ep$printed_value[ep$endpoint_id == "rauh_nber_npv"],
                   bsz_end_b = eb$bsz_model, rjkdc_end_b = eb$rauh_own)
  # The sliders: the two input vectors (bridge_inputs(), full precision; the perpetuity is
  # written "Inf"), the horizon settings and the number of steps of slider_inputs(), and for
  # each slider the arguments it moves (one, or two for the share-lost step) and its two
  # values as the page prints them, and the inputs the page folds into one switch. The
  # page's model.js computes every panel value from these; test-site checks it against
  # export/r/slider_sample.csv.
  bi <- bridge_inputs(k)
  sl_vec <- function(v) lapply(v, function(z) if (is.infinite(z)) "Inf" else z)
  sliders <- list(
    steps = SLIDER_STEPS, horizons = sl_vec(SLIDER_HORIZONS),
    values = list(bsz = sl_vec(bi$sup), rjkdc = sl_vec(bi$rauh)),
    ladder = bi$ladder,
    inputs = lapply(seq_len(nrow(steps)), function(i) list(
      id = steps$step_id[i], input = I(step_inputs[[steps$step_id[i]]]), max = slider_max(steps$step_id[i]),
      short = unname(short_labels[steps$step_id[i]]),
      bsz_text = dial_texts(inp, steps$step_id[i], bi)$bsz,
      rjkdc_text = dial_texts(inp, steps$step_id[i], bi)$rjkdc)),
    minor = EXPLORER_MINOR)
  # The explorer shows the net fiscal effect, output (b), only, and the bridge at each
  # analysis's own horizon; output (a) and the common horizons stay in the exports, the
  # report and the tests, not in the data file the explorer reads.
  data <- list(headline = headline, series = list(own = list(b = series$own$b)), sliders = sliders)
  js <- paste0("/* Generated by comparison/R/site.R from comparison/export/r/. Do not edit. */\n",
               "window.__BRIDGE__ = ",
               jsonlite::toJSON(data, auto_unbox = TRUE, digits = NA, null = "null"), ";\n")
  # The explorer loads the data file with ?v=<its content hash>, so a browser that cached an
  # earlier data file (GitHub Pages serves it with a ten-minute max-age) refetches it with
  # the page that reads it instead of running a new page against old data.
  tok$data_v <- data_hash(js)
  html <- fill(template)
  html_explorer <- fill(explorer)
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
