# Render the site-root reconciliation page (index.html), the comparison explorer
# (comparison/site/explorer/index.html) and their data file (assets/comparison-data.js)
# from comparison/export/r/*.csv plus the contracts and document inputs. Every number on
# the two pages passes through here; the templates (comparison/site/index.template.html,
# comparison/site/explorer.template.html) hold prose and {{tokens}} only.

# Halves round away from zero, with a 1e-9 tolerance (formatC alone rounds a tie to even, and
# the explorer's JavaScript rounds it up), so a value that is a tie in exact arithmetic but
# falls just below it in floating point (-32.25 held as -32.249999999999993) prints the same
# on both pages.
round_half_out <- function(a, digits) { m <- 10^digits; floor(a * m + 0.5 + 1e-9) / m }
money <- function(v, digits = 1, signed = FALSE) {
  if (length(v) != 1) return(vapply(v, money, "", digits = digits, signed = signed))
  if (is.na(v)) return("n/a")
  s <- formatC(round_half_out(abs(v), digits), format = "f", digits = digits, big.mark = ",")
  sign <- if (v < 0) "−" else if (signed) "+" else ""
  paste0(sign, "$", s, "B")
}
pct <- function(v, digits = 0) paste0(formatC(100 * v, format = "f", digits = digits), "%")
# A discount rate: whole percentages as "3%", the rest to two decimals ("2.73%"), as the
# explorer's script prints the rate dial's stops.
rate_txt <- function(v) if (abs(100 * v - round(100 * v)) < 1e-9) pct(v, 0) else pct(v, 2)
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
    r = rate_txt(v),
    s = if (abs(v - 1/3) < 1e-9) "1/3" else pct(v, 0),
    format(v))
}

short_labels <- c(
  bsz = "BSZ Aug 2026", noncitizens = "Non-citizens", base_list = "Forbes source",
  real_estate = "Real estate", confirmed_departures = "Departed wealth", avoidance = "No avoidance",
  litigation_survival = "Litigation", income_loss_share = "Share lost",
  income_level = "Income tax level", horizon = "Horizon", discount_rate = "Discount rate",
  asset_sales = "Asset sales",
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
  # the explorer's asset-sales dial prints whole percentages at every stop, the tables keep 1/3
  if (id == "asset_sales") { out$bsz_short <- pct(ii$supporting_value, 0); out$rjkdc_short <- pct(ii$rauh_value, 0) }
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
# EXPLORER_MINOR and EXPLORER_DIAL_ORDER are in model.R (dial_path() reads them).
explorer_slider_ids <- function() setdiff(bridge_steps()$step_id, EXPLORER_MINOR)
# The pseudo-equation's terms (author decision 2026-10-15, revised the same day): the grouping is by
# box, not by size. D and q of the revenue box are shown one by one; the four dials of the loss box
# (EXPLORER_BOXES$loss: f, C, H and r) are one term, "Lost income tax"; W, a and the minor switch
# are the last term, added up. `steps` lists the path steps a term holds (the page script marks
# the term whose list holds the walk's step). Each term shows its amount and its name only (no
# running value under it; the panel's "With these sliders" line shows that).
EQ_SINGLE <- c("confirmed_departures", "litigation_survival")
eq_terms <- function(dp) {
  words <- c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten")
  main <- match(EQ_SINGLE, dp$step_id)
  loss <- which(dp$step_id %in% EXPLORER_BOXES$loss$ids)
  rest <- setdiff(seq_len(nrow(dp)), c(main, loss))
  stopifnot(!anyNA(main), length(loss) == length(EXPLORER_BOXES$loss$ids))
  name <- function(i) if (dp$step_id[i] == "minor_inputs") tolower(dp$title[i]) else dp$symbol[i]
  and_list <- function(x) if (length(x) < 2) x else paste0(paste(head(x, -1), collapse = ", "), " and ", tail(x, 1))
  # the loss term names H first, the step its label grew from, then the box's other dials in
  # dial order (author wording: "Lost income tax (H, f, C, r)")
  loss_syms <- dp$symbol[loss]; loss_syms <- c("H", setdiff(loss_syms, "H"))
  rest_names <- vapply(rest, name, "")
  terms <- data.frame(
    steps = c(as.character(dp$step[main]), paste(dp$step[loss], collapse = " "), paste(dp$step[rest], collapse = " ")),
    change = c(dp$change[main], sum(dp$change[loss]), sum(dp$change[rest])),
    label = c(paste0(dp$title[main], " (", dp$symbol[main], ")"),
              sprintf("Lost income tax (%s)", paste(loss_syms, collapse = ", ")),
              sprintf("The other %s steps together (%s)", words[length(rest)], paste(rest_names, collapse = ", "))),
    stringsAsFactors = FALSE)
  note <- sprintf(paste(
    "The %s terms are those %s steps of that walk.",
    "Lost income tax is the %s loss-box dials of the walk added up (%s).",
    "The last term is the other %s steps added up (%s)."),
    and_list(dp$symbol[main]), words[length(main)], words[length(loss)], and_list(dp$symbol[loss]),
    words[length(rest)], and_list(rest_names))
  list(main = main, loss = loss, rest = rest, terms = terms, note = note, n_words = words[nrow(dp)])
}
# The dials that act together, boxed on the page by the two terms of the net fiscal effect.
# Inside a box the inputs multiply each other, so one dial's effect depends on where the
# others stand; between the boxes the terms are added (the BSZ share lost also scales with
# the departed dial, and the avoidance allowance enters both terms; the box notes say so).
EXPLORER_BOXES <- list(
  revenue = list(ids = c("base_list", "confirmed_departures", "avoidance", "litigation_survival"),
                 report = "step-revenue",   # the report's steps 1 to 3 of score_common()
                 name = "Wealth tax collected",
                 eq = "Wealth tax collected = 5% &times; (W &minus; D) &times; (1 &minus; a) &times; q",
                 lead = "The tax takes 5% of the wealth. W is the wealth on the list, D the part already gone, a the share lost to avoidance, q the chance the tax survives in court.",
                 more = "The four dials multiply, so one dial's effect depends on the others. W and D are valued on the same Forbes list."),
  loss = list(ids = c("income_loss_share", "income_level", "horizon", "discount_rate"),
              report = "step-loss",      # the report's steps 5 and 6
              name = "Income tax lost",
              eq = "Income tax lost = f &times; C &times; A(H, r)",
              gloss = "A(H, r): what $1 a year for H years is worth today at rate r.",
              lead = "f is the share of billionaires' income tax lost, C that tax per year, H the years it is counted, and r the rate that discounts it.",
              more = "f, C and A(H, r) multiply, so one dial's effect depends on the others. f also moves with D and a."))
# Each dial shows only its symbol; the name and the explanation are in its hover box.
DIAL_SYMBOLS <- c(base_list = "W", confirmed_departures = "D", avoidance = "a",
                  litigation_survival = "q", income_loss_share = "f", income_level = "C",
                  horizon = "H", discount_rate = "r")
# One or two words shown under a symbol (author instructions: f, C and H; then every symbol of the
# revenue box too, 2026-10-15).
DIAL_WORDS <- c(base_list = "wealth", confirmed_departures = "departed", avoidance = "avoidance",
                litigation_survival = "litigation", income_loss_share = "share lost",
                income_level = "yearly tax revenue", horizon = "years", discount_rate = "rate")
# What each symbol stands for, at the start of its tip. The bridge's step names (short_labels)
# name a step, not the dial: "No avoidance" is the JR end of the a dial, not the dial.
DIAL_NAMES <- c(base_list = "wealth on the list", confirmed_departures = "wealth already gone",
                avoidance = "avoidance share", litigation_survival = "chance it survives court",
                income_loss_share = "share lost", income_level = "yearly income tax",
                horizon = "years counted", discount_rate = "discount rate")

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
        add("nber", "total", e$rauh_model,
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

# The differences between Hoopes's Figure 2 and this bridge, one HTML item each (the
# report's Hoopes section lists them). Every number is read from the exports and contracts.
hoopes_differences <- function(ex, k) {
  d <- k$docs; inp <- ex$inputs; ep <- ex$endpoints; hz <- ex$hoopes; hraw <- k$hoopes
  ea <- ex$ends[ex$ends$horizon_setting == "own" & ex$ends$output == "a", ]
  epv <- function(id) ep$value[ep$endpoint_id == id]
  dv <- function(id) as.numeric(d$value[d$input_id == id])
  opp <- function(id) pick(k$rjkdc$outputs, id, "printed_value")
  hs_ <- function(id) hz$hoopes[hz$step_id == id]; ho <- function(id) hz$ours[hz$step_id == id]
  hfmt <- function(x, u) if (is.na(x)) "none" else paste0(money(x, 1, TRUE), if (!is.na(u)) paste0(" &plusmn; ", formatC(u, format = "f", digits = 1)) else "")
  hz_end <- as.numeric(hraw$end[hraw$step_id == "income_tax_loss"])
  hz_pre <- as.numeric(hraw$end[hraw$step_id == "real_estate_exclusion"])
  n_sup <- pick(k$bsz$inputs, "n_billionaires")
  tok <- list(ggss_headline = money(epv("ggss_headline"), 0))
  c(
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
    sprintf("<b>Income tax.</b> His single bar, %s, ends at %s, close to the March 2026 version's %s. Ours is %s, the September 2026 version's present value of lost income tax against %s of revenue, and we split it into five labelled steps (the share lost, the income tax level, the horizon, the discount rate, asset-sale tax), which interact with the base steps.",
            hfmt(hs_("income_tax_loss"), NA), money(hz_end, 1), money(opp("npv_mc_ssrn_mean"), 1), money(ho("income_tax_loss"), 2, TRUE),
            money(ea$rauh_own, 2)),
    "<b>Order and labels.</b> His is one sequential order, with no provenance labels. Ours follows the explorer's dials in the order the page prints them, with each step labelled data, research, guesswork or scenario. The Shapley average (a step's effect averaged over every order the inputs could be switched in) checks it without choosing an order, and the column here reads our steps in his order.",
    "<b>Steps he does not have.</b> The non-US-citizen residents, the BSZ analysis's avoidance allowance being dropped, the asset-sale income tax, and the litigation weight of the September 2026 version (which postdates his note)."
  )
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
  # the comparison's pages print the JR estimate as the exact expectation of the authors' model
  # (author decision 2026-10-15); footnote 1 gives the paper's seeded-run figure
  tok$nber_npv <- money(eb$rauh_own, 1)
  tok$nber_npv_abs <- money(-eb$rauh_own, 1)
  # The discount rate at each end (the rate dial, author decision 2026-10-15), from the exports:
  # 3% at the BSZ end, 1 / E[1/r] over the JR draw at the JR end.
  tok$r_bsz <- rate_txt(mv("r_bsz")); tok$r_jr <- rate_txt(mv("r_jr"))
  r_min <- pct(mv("r_min_jr"), 1); r_max <- pct(mv("r_max_jr"), 1)
  tok$nber_growth <- pct(pick(k$rjkdc$inputs, "nber_growth_rate"))

  # ---- the headline: the two analyses' main estimates, next to each other ----
  # The BSZ main estimate is the net total over 5 years, which is also the BSZ end of the
  # bridge under the common output (b). The JR main estimate on the comparison's pages is the
  # exact expectation of the authors' NBER Monte Carlo (author decision 2026-10-15), the JR end
  # of the bridge and the number the sliders start at. The paper prints the mean of one seeded
  # run (the contract row npv_mc_nber_mean, printed -$38.9B); footnote 1 says so, and the JR
  # analysis's own pages keep the printed figure. The explorer reads the same values from
  # assets/comparison-data.js.
  rj_main <- eb$rauh_own
  rj_printed <- ep$printed_value[ep$endpoint_id == "rauh_nber_npv"]
  tok$hl_bsz <- money(eb$bsz_model, 1)
  tok$hl_rjkdc <- money(rj_main, 1)
  tok$jr_end_b <- money(eb$rauh_model, 1)
  tok$bsz_end_b <- money(eb$bsz_model, 1)
  # Footnote 1's provenance sentence for the JR number, on both pages (hrefs per page).
  jr_fn <- function(report, jr_report) sprintf(paste(
    "The paper prints %s, the average of one seeded run of 100,000 draws.",
    "The exact average of the same formula is %s, used throughout this page",
    "(<a href=\"%s\">report</a>, <a href=\"%s\">Step 6 of the JR analysis's report</a>)."),
    money(rj_printed, 1), money(eb$rauh_own, 2), report, jr_report)
  tok$jr_fn_root <- jr_fn("comparison/site/repro.html#the-main-estimate", "rjkdc-analysis/site/repro.html#step-npv")
  tok$jr_fn_x <- jr_fn("../repro.html#the-main-estimate", "../../../rjkdc-analysis/site/repro.html#step-npv")
  # The gap on (b), stated in the explorer's footnote, not in the headline.
  gap_b <- eb$bsz_model - eb$rauh_model
  tok$gap_b <- money(gap_b, 1)
  # Output (a), the secondary setting.
  gap <- ea$bsz_model - ea$rauh_own
  tok$gap_a <- money(gap, 1)
  tok$gap_a_signed <- money(-gap, 1)
  tok$bsz_end_a <- money(ea$bsz_model, 1)
  tok$nber_end_a <- money(ea$rauh_own, 1)

  # ---- the bridge series for the data file (the report draws the chart) ----
  series <- build_series(ex)

  # ---- the two slider panels: one slider per disputed input that moves the estimate, in
  # the bridge's order, then the minor-inputs switch and the September 2026 revision switch.
  # Every dial runs from its smaller value at the left end to its larger value at the right
  # end, in both panels, whichever analysis each value belongs to (author instruction
  # 2026-10-15; dial_lo_side() below). Each end prints its value in the wording of the
  # disputed-inputs table (fmt_input) and a tag naming whose value it is. The value of a slider
  # is its position as slider_inputs() (model.R) defines it, 0 = the panel's own analysis, so
  # a slider runs right to left (dir="rtl") wherever the panel's own value is the larger one.
  # Each slider carries an explanation (slider_tips), shown while the pointer is over it. The
  # page script reads the rest from D.sliders.
  hz_fin <- SLIDER_HORIZONS[is.finite(SLIDER_HORIZONS)]
  hz_words <- paste0(paste(head(hz_fin, -1), collapse = ", "), " and ", tail(hz_fin, 1),
                     " years, and a perpetuity")
  bi0 <- bridge_inputs(k)
  # Every tip is two or three lines (author instruction 2026-10-15): the dial's symbol gives a
  # one-sentence definition, and each end says what that analysis assumes and its one reason.
  slider_tips <- c(
    base_list = "The billionaires' wealth the tax applies to, from one of two Forbes lists.",
    confirmed_departures = "Wealth that left before the 1 January 2026 residency date. Middle stop: the BSZ aggressive case's four leavers.",
    avoidance = "The share of the tax lost to avoidance and evasion other than leaving.",
    litigation_survival = "The chance that the tax survives a court challenge, applied to the revenue.",
    income_loss_share = "The share of billionaires' income tax California loses to people leaving. Under the BSZ rule it depends on the number of leavers.",
    income_level = "Billionaires' yearly California income tax revenue, the amount at risk each year.",
    horizon = sprintf("How many years the lost income tax is counted. Middle stops: %s years.",
                      paste(hz_fin[-1], collapse = ", ") |> sub(pattern = ", ([^,]*)$", replacement = " and \\1")),
    discount_rate = "The discount rate that turns a yearly loss into today's dollars.",
    minor_inputs = "One switch for three inputs that each move the estimate by less than $7 billion. Open the fold below to set them one by one.",
    noncitizens = "Wealth of California billionaires who are not US citizens.",
    real_estate = "The share of the base deducted for directly held homes.",
    asset_sales = "The share of the tax paid by selling assets, whose gains raise extra income tax.")
  # What each dial end means, shown while the pointer is over that end (or on a tap).
  end_tips <- list(
    base_list = c(
      bsz = sprintf("BSZ: the Forbes list on 1 July 2026, %s California billionaires worth %s. The %s of non-US citizens is a separate dial.",
                    n_sup, money(bi0$sup$W_core + bi0$sup$W_noncit, 0), money(bi0$sup$W_noncit, 0)),
      rjkdc = sprintf("JR: the 2025 list, 212 billionaires, grown 7%% to the 31 December 2026 valuation date: %s.", money(bi0$rauh$W_core, 0))),
    confirmed_departures = c(
      bsz = "BSZ: nobody, since announcing a move is not a legal change of residence.",
      rjkdc = "JR: its seven confirmed leavers, Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks."),
    avoidance = c(
      bsz = "BSZ: a small allowance, argued from enforcement rather than estimated. Half of it is moving away, which also costs income tax (f).",
      rjkdc = "JR: none on top of the departures it counts."),
    litigation_survival = c(
      bsz = "BSZ: the Act is taken as written and collected in full.",
      rjkdc = "JR: the revenue weighted by 50%, the accounting threshold for a tax more likely than not to stand."),
    income_loss_share = c(
      bsz = "The BSZ rule: only the leavers' own income tax is lost, the people in D and the half of avoiders who move.",
      rjkdc = sprintf("The JR rule: %s of all billionaires' income tax, whoever leaves (the middle of a 30%% to 60%% guess), plus movers from a.",
                      pct(bi0$rauh$f0))),
    income_level = c(
      bsz = "BSZ: from tax data, since top wealth holders earn about half of what top earners do.",
      rjkdc = "JR: the middle of a $3.3 billion to $5.8 billion range from two model bounds."),
    horizon = c(
      bsz = "BSZ: about the payment period, treating the responses as temporary.",
      rjkdc = "JR: for ever, so the loss never ends."),
    discount_rate = c(
      bsz = sprintf("%s: the rate this OPA applies to the BSZ analysis's 5-year loss, the middle of the JR range. BSZ give no rate.",
                    tok$r_bsz),
      rjkdc = sprintf("%s: the one rate worth the same as the JR analysis's random draw between %s and %s ($1 a year for ever is worth $%s).",
                      tok$r_jr, r_min, r_max, formatC(mv("A_inf_jr_draw"), format = "f", digits = 1))),
    minor_inputs = c(
      bsz = "BSZ: non-citizens taxed, no real-estate deduction, the extra tax from asset sales counted.",
      rjkdc = "JR: non-citizens left out, homes deducted, no extra tax from asset sales."),
    noncitizens = c(
      bsz = "BSZ: taxed like any other California resident.",
      rjkdc = "JR: left out with its 28 international billionaires."),
    real_estate = c(
      bsz = "BSZ: no deduction.",
      rjkdc = "JR: nets out directly held real estate, about 0.5% of the base."),
    asset_sales = c(
      bsz = "BSZ: one third, an assumption (BSZ p.24: \"paid one-third by selling assets\").",
      rjkdc = "JR: does not count this extra income tax."))
  # Each end's tip closes with the kind of that analysis's value (bridge_steps()$kind; a step
  # whose kind reads "X vs Y" is X in the BSZ analysis and Y in the JR analysis).
  end_kind <- function(id, side) {
    k <- steps$kind[steps$step_id == id]
    if (!length(k)) return("")
    k <- strsplit(k, " vs ", fixed = TRUE)[[1]]
    paste0(" Kind: ", if (side == "bsz") k[1] else k[length(k)], ".")
  }
  # Which analysis's value sits at the left end of dial `id` in `panel`: the smaller one (ties
  # and the minor switch, whose two ends are not numbers, keep the BSZ value at the left). The
  # share-lost dial compares its two rules' f at the panel's starting positions; a dial that
  # moves several arguments compares its first (the Forbes list by its core wealth, the
  # departures by the wealth gone, dep_b).
  dial_lo_side <- function(panel, id) {
    if (id == "minor_inputs") return("bsz")
    if (id == "income_loss_share") {
      from <- if (panel == "bsz") bi0$sup else bi0$rauh
      to <- if (panel == "bsz") bi0$rauh else bi0$sup
      f <- vapply(c(0L, slider_max(id)), function(p)
        score_common(slider_inputs(from, to, stats::setNames(list(p), id), bi0$ladder))[["f"]], 0)
      v <- if (panel == "bsz") f else rev(f)
    } else {
      nm <- step_inputs[[id]][1]
      v <- c(bi0$sup[[nm]], bi0$rauh[[nm]])
    }
    if (v[1] <= v[2]) "bsz" else "rjkdc"
  }
  end_tag <- c(bsz = "BSZ", rjkdc = "JR")
  end_span <- function(panel, id, side, txt, at) {
    tp <- end_tips[[id]][side]
    if (!is.null(tp) && !is.na(tp)) tp <- paste0(tp, end_kind(id, side))
    val <- sprintf('<span class="sl-end-v">%s</span><span class="sl-end-tag">%s</span>', txt, end_tag[[side]])
    if (is.null(tp) || is.na(tp))
      return(sprintf('<span class="sl-end sl-%s" data-side="%s">%s</span>', at, side, val))
    sprintf(paste0('<span class="sl-end sl-%1$s has-tip" data-side="%4$s" tabindex="0" aria-describedby="%2$s-%3$s-%4$s-tip">',
                   '%5$s<span class="end-tip" role="tooltip" id="%2$s-%3$s-%4$s-tip">%6$s</span></span>'),
            at, panel, id, side, val, esc(tp))
  }
  slider_row <- function(panel, id, name, title, tip, bsz_txt, rj_txt, max, sym = FALSE) {
    lo <- dial_lo_side(panel, id); hi <- setdiff(c("bsz", "rjkdc"), lo)
    txt <- c(bsz = bsz_txt, rjkdc = rj_txt)
    # the panel's own value (position 0) is the larger one: the slider runs right to left
    rtl <- lo != panel
    ticks <- paste(sprintf('<i style="--t:%s"></i>', format((0:max) / max)), collapse = "")
    sprintf(paste0(
      '        <li class="sl%13$s" data-id="%2$s">\n',
      '          <label for="%1$s-%2$s"><b>%3$s</b> <span class="sl-title">%4$s</span></label>\n',
      '          <span class="sl-tip" role="tooltip" id="%1$s-%2$s-tip">%5$s</span>\n',
      '          <div class="sl-row">%6$s<span class="sl-track',
      '%9$s"><span class="sl-ticks" aria-hidden="true">%10$s</span><span class="sl-other" aria-hidden="true"></span>',
      '<input type="range" class="sl-in" id="%1$s-%2$s" min="0" max="%8$d" step="1" value="0" data-panel="%1$s" data-id="%2$s" aria-describedby="%1$s-%2$s-tip"%11$s>',
      '<output class="sl-cur" for="%1$s-%2$s">%12$s</output></span>%7$s</div>\n',
      '          <span class="sl-note"></span>\n',
      '        </li>'),
      # the word first, the symbol under it (author instruction 2026-10-15)
      panel, id, if (sym) paste0(if (!is.na(DIAL_WORDS[id])) paste0('<span class="sym-word">', DIAL_WORDS[[id]], '</span>') else "",
                                 '<span class="sym">', esc(name), '</span>')
                 else esc(name),
      if (sym) paste0('<span class="sr">', esc(title), '</span>') else esc(title), gsub("\n", "<br>", esc(tip), fixed = TRUE),
      end_span(panel, id, lo, txt[[lo]], "lo"), end_span(panel, id, hi, txt[[hi]], "hi"), as.integer(max),
      if (rtl) " is-rtl" else "", ticks, if (rtl) ' dir="rtl"' else "",
      txt[[panel]], if (sym) " has-sym" else "")
  }
  step_row <- function(panel, id) {
    i <- match(id, steps$step_id); tx <- dial_texts(inp, id, bi0)
    slider_row(panel, id, unname(DIAL_SYMBOLS[id]), unname(short_labels[id]),
               paste0(DIAL_SYMBOLS[[id]], ", ", DIAL_NAMES[[id]], ". ", slider_tips[[id]]),
               tx$bsz, tx$rjkdc, slider_max(id), sym = TRUE)
  }
  # Each box heading shows the box's name only; its formula is in a tip that opens on hover
  # (mouse) or tap (touch), the same mechanism as the dial tips (author item 2026-10-15). The
  # loss box's tip adds a line glossing A(H, r), since a tip cannot hold another tip.
  box <- function(panel, key) {
    bx <- EXPLORER_BOXES[[key]]
    tip_id <- paste0(panel, "-", key, "-eq")
    tip <- paste0('<span class="tip-eq">', bx$eq, '</span>',
                  if (!is.null(bx$gloss)) paste0('<span class="tip-line">', esc(bx$gloss), '</span>') else "")
    paste0(
      '        <li class="sl-box" role="group" aria-labelledby="', panel, '-', key, '-head">\n',
      '          <div class="sl-box-head">\n',
      '            <p class="box-eq"><span class="info box-name" tabindex="0" aria-describedby="', tip_id, '">',
      '<span id="', panel, '-', key, '-head">', bx$name, '</span>',
      '<span class="info-tip" role="tooltip" id="', tip_id, '">', tip, '</span></span></p>\n',
      '            <p class="box-lead">', bx$lead, ' <a class="info" href="../repro.html#', bx$report, '" aria-describedby="', panel, '-', key, '-more">more',
      '<span class="info-tip" role="tooltip" id="', panel, '-', key, '-more">', bx$more, '</span></a></p>\n',
      '          </div>\n',
      '          <ul class="sl-list">\n',
      paste(vapply(bx$ids, function(id) step_row(panel, id), ""), collapse = "\n"), "\n",
      '          </ul>\n',
      '        </li>')
  }
  stopifnot(identical(unname(unlist(lapply(EXPLORER_BOXES, `[[`, "ids"))), explorer_slider_ids()))
  # The three minor inputs: one switch that moves all three, and a fold that opens into the
  # three dials themselves (the switch sets them; each can then be moved on its own).
  minor_tips <- slider_tips[EXPLORER_MINOR]
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
  # ---- the pseudo-equation: the BSZ estimate, the D and q steps of the dial path, the loss
  # box's four steps added up, the other three steps added up, the JR estimate (author decisions
  # 2026-10-15: everything from the explorer's own dials; grouped by box, eq_terms()). The dial
  # path moves the BSZ panel's dials top to bottom, each to its far end (dial_path() in model.R,
  # export/r/dial_path.csv). The terms take the BSZ end to the JR end exactly. eq_terms() is
  # shared with the deck (slides.Rmd).
  stopifnot(identical(EXPLORER_DIAL_ORDER, c(explorer_slider_ids(), "minor_inputs")))
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  stopifnot(identical(dp$step_id, EXPLORER_DIAL_ORDER))
  et <- eq_terms(dp)
  term <- function(j) {
    x <- et$terms[j, ]
    sprintf(
      '<span class="eq-step"><span class="op">%s</span><span class="term" data-steps="%s"><b>%s</b><small>%s</small></span></span>',
      if (x$change < 0) "&minus;" else "+", x$steps, money(abs(x$change), 1), esc(x$label))
  }
  jr_label <- "JR estimate"
  say <- function(j) sprintf("%s %s for %s", if (et$terms$change[j] < 0) "minus" else "plus",
                             money(abs(et$terms$change[j]), 1), tolower(et$terms$label[j]))
  pseudo_eq <- function(page) paste0(
    '<div class="pseudo-eq" role="img" aria-label="', esc(sprintf(
      "The BSZ estimate, %s, %s, gives about the JR estimate, %s.",
      money(eb$bsz_model, 1), paste(vapply(seq_len(nrow(et$terms)), say, ""), collapse = ", "),
      money(eb$rauh_model, 1))), '">\n',
    sprintf('  <span class="term" data-steps="0"><b>%s</b><small>BSZ estimate</small></span>\n', money(eb$bsz_model, 1)),
    paste(vapply(seq_len(nrow(et$terms)), function(j) paste0("  ", term(j)), ""), collapse = "\n"), "\n",
    sprintf('  <span class="eq-step"><span class="op">&asymp;</span><span class="term" data-end="%d"><b>%s</b><small>%s</small></span></span>\n', nrow(dp), money(eb$rauh_model, 1), jr_label),
    '</div>')
  tok$pseudo_eq_x <- pseudo_eq("x")
  tok$pseudo_eq <- pseudo_eq("root")
  # The note reads the same on both pages (author item 2026-10-15), except that the overview
  # has no Walk the path button, so it drops that sentence, and links "BSZ panel" to the explorer.
  eq_note <- function(href, panel, walk) paste0(
    "Move the ", panel, "'s dials top to bottom, each to its far end. ", esc(et$note), " ",
    walk,
    sprintf("The <a href=\"%s\">report</a> gives all %s steps.", href, et$n_words))
  tok$pseudo_eq_note_x <- eq_note("../repro.html#the-bridge", "BSZ panel",
                                  "The Walk the path button in each panel does it for you. ")
  tok$pseudo_eq_note_root <- eq_note("comparison/site/repro.html#the-bridge",
                                     "<a href=\"comparison/site/explorer/\">BSZ panel</a>", "")

  # ---- anchors (output (a) candidates; default decided in PLAN.md) ----
  an <- ex$anchors
  tok$anchor_rows <- paste(sprintf(
    '    <tr%s><td>%s%s</td><td class="num">%s</td><td>%s</td><td class="num">%s</td></tr>',
    ifelse(an$default, ' class="total"', ""), esc(an$label), ifelse(an$default, " (used)", ""),
    vapply(an$value, money, "", digits = 2), esc(an$where),
    vapply(an$value - an$value[an$default], function(z) if (abs(z) < 1e-9) "none" else money(z, 2, TRUE), "")),
    collapse = "\n")

  dv <- function(id) as.numeric(d$value[d$input_id == id])
  # Row 3 departure share: the script's ceiling literal over the grown domestic face value
  oval <- function(id) pick(k$rjkdc$outputs, id)
  tok$dconf_sept <- pct(inp$rauh_value[inp$input == "d_conf"], 1)
  tok$ceiling_literal <- formatC(pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"), format = "f", digits = 0)
  tok$ceiling_file <- formatC(oval("nber_ceiling"), format = "f", digits = 2)
  tok$domestic_grown <- formatC(oval("nber_domestic_grown"), format = "f", digits = 3)

  # ---- vintage ----
  tok$vintage_rows <- paste(c(
    # the March document's own base, the 2025 list before the September version grows it 7%
    # (SSRN 6340778 p.5: "Sum $1,894.8 billion Count 212")
    sprintf('    <tr><td>Rauh et al., SSRN 6340778</td><td>17 Mar 2026</td><td>%s billionaires, %s, 2025 Forbes list (p.5)</td></tr>',
            n_rauh, money(pick(k$rjkdc$inputs, "baseline_net_worth"), 1)),
    '    <tr><td>Galle, Gamage, Saez, Shanske, response to Rauh</td><td>17 Mar 2026</td><td>answers Rauh\'s 4 Mar version, not the 17 Mar copy used here</td></tr>',
    sprintf('    <tr><td>Hoopes, SSRN 6428578</td><td>2026 (uses the February GGSS text)</td><td>%s billionaires, %s (p.3 fn.1)</td></tr>',
            dv("hoopes_n_billionaires"), money(dv("hoopes_wealth"), 0)),
    sprintf('    <tr><td>GGSS expert report</td><td>updated 20 Jul 2026</td><td>%s billionaires, %s at 1 Jul 2026, non-citizens included, Ellison excluded</td></tr>',
            n_sup, money(inp$supporting_value[inp$input == "W_core"] + inp$supporting_value[inp$input == "W_noncit"], 0)),
    '    <tr><td>Boll, Saez, Zucman, NBER WP 35218</td><td>Aug 2026 revision</td><td>same 1 Jul 2026 base; Table 5 adds missing billionaires and leaver scenarios</td></tr>',
    sprintf('    <tr><td>Jaros and Rauh, NBER c15504</td><td>Sep 2026</td><td>Rauh\'s base grown %s to 31 Dec 2026, seven departures, litigation weight</td></tr>', pct(pick(k$rjkdc$inputs, "nber_growth_rate"))),
    '    <tr><td>LAO ballot analysis</td><td>for the 3 Nov 2026 ballot</td><td>no point estimate</td></tr>'), collapse = "\n")

  # ---- differences table: the two values only; the report's table gives their sources ----
  tx <- lapply(steps$step_id, function(id) step_texts(inp, id))
  tok$differences_rows <- paste(sprintf(
    '    <tr><td>%s</td><td>%s</td><td><span class="kind">%s</span></td><td class="small"><b>%s</b></td><td class="small"><b>%s</b></td></tr>',
    esc(steps$disputes_row), esc(steps$title), steps$kind,
    vapply(tx, `[[`, "", "bsz"), vapply(tx, `[[`, "", "rjkdc")), collapse = "\n")

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
  # two ends under the common output (b), each analysis's own horizon and rate (bsz_end_b,
  # rjkdc_end_b).
  headline <- list(bsz = eb$bsz_model, rjkdc = rj_main,
                   rjkdc_printed = rj_printed,
                   bsz_end_b = eb$bsz_model, rjkdc_end_b = eb$rauh_model)
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
    minor = EXPLORER_MINOR,
    path = EXPLORER_DIAL_ORDER)
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
