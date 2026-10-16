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
    return(list(bsz = "the movers' proportional share, plus named leavers' own tax",
                rjkdc = sprintf("%s of all", fmt_input("f0", f$rauh_value)),
                bsz_source = paste(k$supporting_source, f$supporting_source, sep = "; "),
                rjkdc_source = paste(f$rauh_source, k$rauh_source, sep = "; ")))
  }
  if (id == "confirmed_departures") {
    b <- ii[ii$input == "dep_b", ]; j <- ii[ii$input == "dep_j", ]
    return(list(bsz = "no named leaver",
                rjkdc = sprintf("the JR seven: %s on the BSZ list, %s on the JR list",
                                money(b$rauh_value, 0), money(j$rauh_value, 0)),
                bsz_source = b$supporting_source, rjkdc_source = paste(b$rauh_source, j$rauh_source, sep = "; "),
                bsz_short = "None named", rjkdc_short = "JR seven"))
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
# EXPLORER_MINOR and DIAL_PATH_ORDER are in model.R (dial_path() reads them).
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
  # the minor switch is one dial for three inputs, so the last term names it as one step
  name <- function(i) if (dp$step_id[i] == "minor_inputs") "the minor switch" else dp$symbol[i]
  and_list <- function(x) if (length(x) < 2) x else paste0(paste(head(x, -1), collapse = ", "), " and ", tail(x, 1))
  # the loss term names H first, the step its label grew from, then the box's other dials in
  # dial order (author wording: "Lost income tax (H, f, C, r)"); the note lists them in the same order
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
    and_list(dp$symbol[main]), words[length(main)], words[length(loss)], and_list(loss_syms),
    words[length(rest)], and_list(rest_names))
  list(main = main, loss = loss, rest = rest, terms = terms, note = note, n_words = words[nrow(dp)])
}
# The dials each term of eq_terms() moves, one character vector per term: the term's path steps
# with the minor switch read as its three dials (dial_ids() in model.R). The explorer's Apply
# buttons carry these (data-dials).
eq_term_dials <- function(dp, et = eq_terms(dp)) {
  lapply(strsplit(et$terms$steps, " ", fixed = TRUE), function(st)
    unlist(lapply(dp$step_id[as.integer(st)], dial_ids), use.names = FALSE))
}
# The equation's order, left to right (author decision 2026-10-15, "the equation's order: D, q,
# lost income tax, the rest"): D and q, the loss box's dials in their box order, then the other
# sliders in the page's order and the minor switch. DIAL_PATH_ORDER in model.R must equal it.
eq_path_order <- function() {
  c(EQ_SINGLE, EXPLORER_BOXES$loss$ids,
    setdiff(explorer_slider_ids(), c(EQ_SINGLE, EXPLORER_BOXES$loss$ids)), "minor_inputs")
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
# The quantities table (render_site()): the four answers the OPA author's credibility column can
# take, the longest a value-and-why cell may run, and the short source a cell cites, cut from the
# source columns of export/r/inputs.csv (the first page, section or script line they name).
CREDIBILITY_LEVELS <- c("BSZ more credible", "JR more credible", "About equally credible", "Not yet assessed")
# The credibility column is hidden until the author's assessments are in (author request
# 2026-10-15); the file is still read and checked, so TRUE brings the column back.
SHOW_CREDIBILITY <- FALSE
# Dials the author assesses as one group (author request 2026-10-15): one row each in the
# quantities table, in the order of each group's first dial on the page. D, a and f go together
# because under the BSZ rule f is built from the leavers in D and the movers among the avoiders
# in a; H and r together set A(H, r); the three minor inputs share their switch.
QUANTITY_GROUPS <- list(
  base_list = "base_list",
  departures_share = c("confirmed_departures", "avoidance", "income_loss_share"),
  litigation_survival = "litigation_survival",
  income_level = "income_level",
  horizon_rate = c("horizon", "discount_rate"),
  minor_inputs = c("noncitizens", "real_estate", "asset_sales"))
QUANTITY_WORDS <- 25
# A JR source that leads with the chapter's own place ("chapter Table 7, PDF p.21", "chapter eq. 3,
# PDF pp.19-20", "chapter PDF p.32") matches whole; a section, table or equation without a PDF
# page, the script line and the README still match after it. quantity_source() then cuts a chapter
# place to its PDF page, so every chapter cell reads "chapter PDF p.N", as the BSZ cells read
# "BSZ PDF p.N".
QUANTITY_SOURCE_PATTERN <- paste0(
  "BSZ PDF pp?\\.[0-9]+(-[0-9]+)?|GGSS( [0-9]+ [A-Z][a-z]+ [0-9]{4})? pp?\\.[0-9]+|BSZ Table [0-9]+|",
  "(NBER )?chapter ((Secs?\\. [0-9.]+(-[0-9.]+)?|Table [0-9]+|eqs?\\. [0-9]+(-[0-9]+)?), )*PDF pp?\\.[0-9]+(-[0-9]+)?|",
  "(NBER )?chapter (Secs?\\. [0-9.]+(-[0-9.]+)?|Table [0-9]+|eqs?\\. [0-9]+(-[0-9]+)?|pp?\\.[0-9]+(-[0-9]+)?)|",
  "NPV_dist_v8\\.R(:[0-9]+)?|NBER README")
quantity_source <- function(hit) sub("^(NBER )?chapter .*?(PDF pp?[.])", "chapter \\2", hit, perl = TRUE)
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
    "<b>Order and labels.</b> His is one sequential order, with no provenance labels. Ours moves the explorer's dials in the order of the equation at the top (D, q, the loss box's dials, then the rest), with each step labelled data, research, guesswork, scenario or derived (\"A vs B\" reads the BSZ value's kind against the JR value's). The Shapley average (a step's effect averaged over every order the inputs could be switched in) checks it without choosing an order, and the column here reads our steps in his order.",
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
  # the overview's first paragraph rounds it to whole billions and names the chapter's own figure
  tok$nber_npv_round <- money(-eb$rauh_own, 0)
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
  tok$nber_printed <- money(rj_printed, 1)
  tok$hl_bsz <- money(eb$bsz_model, 1)
  tok$hl_rjkdc <- money(rj_main, 1)
  tok$jr_end_b <- money(eb$rauh_model, 1)
  tok$bsz_end_b <- money(eb$bsz_model, 1)
  # Footnote 1's provenance sentence for the JR number, on both pages (hrefs per page).
  # The last sentence glosses "seeded run" (test-site.R pins the first two together, so the gloss
  # follows them).
  jr_fn <- function(report, jr_report) sprintf(paste(
    "The paper prints %s, the average of one seeded run of 100,000 draws.",
    "The exact average of the same formula is %s, used throughout this page",
    "(<a href=\"%s\">report</a>, <a href=\"%s\">Step 6 of the JR analysis's report</a>).",
    "A seeded run starts the random draws from a fixed number, so it gives the same draws every time."),
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
    confirmed_departures = "Wealth that left before the 1 January 2026 residency date. Middle stop: BSZ Table 5 row 3, where Page, Thiel, Hankey and Kalanick left in time.",
    avoidance = "The share of the tax lost to avoidance and evasion, including moves by people no one names (D holds the named ones).",
    litigation_survival = "The chance that the tax survives a court challenge, applied to the revenue.",
    # "lost to leavers", not "California loses to people leaving": the longer wording takes the
    # tip to four lines at 390 px
    income_loss_share = "The share of billionaires' income tax lost to leavers. Both ends include the movers in a (at the JR end, this OPA's addition), and the BSZ end also the leavers in D.",
    income_level = "Billionaires' yearly California income tax revenue, the amount at risk each year.",
    horizon = sprintf("How many years the lost income tax is counted. Middle stops: %s years.",
                      paste(hz_fin[-1], collapse = ", ") |> sub(pattern = ", ([^,]*)$", replacement = " and \\1")),
    discount_rate = sprintf("The discount rate that turns a yearly loss into today's dollars. To see how much it matters inside the JR draw, use the JR explorer's Rate %s and %s settings.",
                            r_min, r_max),
    minor_inputs = "One switch for three inputs that each move the estimate by less than $7 billion. Open the fold below to set them one by one.",
    noncitizens = "Wealth of California billionaires who are not US citizens.",
    real_estate = "The share of the base deducted for directly held homes.",
    asset_sales = "The share of the tax paid by selling assets, whose gains raise extra income tax.")
  # The share of the JR list's wealth the seven publicly reported moves took: the script's ceiling
  # literal over the grown domestic face value, the 28.6% around which the chapter sets its draw of
  # f (PDF p.31). The JR draw of C runs between the contract's two bounds.
  d_conf_jr <- 1 - pick(k$rjkdc$inputs, "nber_ceiling_hardcoded") / pick(k$rjkdc$outputs, "nber_domestic_grown")
  c_bounds <- formatC(c(pick(k$rjkdc$inputs, "rauh_mc_c_min"), pick(k$rjkdc$inputs, "rauh_mc_c_max")),
                      format = "f", digits = 1)
  # What each dial end means, shown while the pointer is over that end (or on a tap). An end that
  # the quantities table shows (q_cell) must fit there in 25 words, with its source and kind, either
  # whole, without its parentheses, or as its first sentence: the wording of D, q, f and r at the
  # ends below is cut to fit.
  end_tips <- list(
    # the W dial's BSZ end is the US citizens' wealth only (W_core); the non-citizens are their own dial
    base_list = c(
      bsz = sprintf("BSZ: the Forbes list on 1 July 2026, %s California billionaires, of whom the US citizens hold %s. The %s of non-US citizens is a separate dial.",
                    n_sup, money(bi0$sup$W_core, 0), money(bi0$sup$W_noncit, 0)),
      rjkdc = sprintf("JR: the 2025 list, %s billionaires, grown %s to the 31 December 2026 valuation date: %s.",
                      n_rauh, tok$nber_growth, money(bi0$rauh$W_core, 0))),
    # BSZ remove no named leaver (BSZ PDF p.23 fn.30), but half of their 10% avoidance is
    # billionaires who left before 1 January (BSZ PDF p.24): alpha times m. Tips name no source
    # (author tip rules 2026-10-15); the quantities table adds it from export/r/inputs.csv.
    confirmed_departures = c(
      bsz = "BSZ: no named move counted, since press reports do not establish a residence change before 1 January. Half of a is people who left in time.",
      rjkdc = "JR: seven publicly reported moves, by Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks."),
    avoidance = c(
      bsz = "BSZ: a small allowance, argued from enforcement rather than estimated. Half of it is moving away, which also costs income tax (f).",
      # the chapter puts unreported departures in the 0 floor of its revenue draw (fn.32, PDF
      # p.34) and in its draw of f (PDF p.33)
      rjkdc = "JR: none on top of the departures it counts. Its 0 revenue floor and its share-lost range also allow for unreported moves."),
    litigation_survival = c(
      bsz = "BSZ: collected in full; its expert report argues the Act was designed to stay clear of constitutional issues.",
      rjkdc = "JR: half the revenue, the 'more likely than not' line an accounting rule (ASC 740-10) uses to judge whether a tax stands."),
    # the BSZ end at the BSZ values is alpha times m, the movers among the avoiders, who take a
    # proportional share of the income tax with them (BSZ PDF p.24); both ends are guesswork
    income_loss_share = c(
      bsz = "The BSZ rule: only the leavers' own income tax is lost, with the movers from a assumed to pay a proportional share. Leavers in D add theirs, from tax filings.",
      # the chapter centres its draw of f "conservatively around the observed wealth-base departure
      # fraction" (PDF p.31) and lets it cover departures "not publicly documented" (PDF p.33)
      rjkdc = sprintf("The JR rule: %s of all billionaires' income tax, whoever leaves, from a draw set around the %s of wealth that left. It covers unreported moves too.",
                      pct(bi0$rauh$f0), pct(d_conf_jr, 1))),
    income_level = c(
      bsz = "BSZ: from tax data, since top wealth holders earn about half of what top earners do.",
      rjkdc = sprintf("JR: the middle of $%s billion to $%s billion, both estimated from tax data. The floor's pool of 500 filers is the authors' judgement.",
                      c_bounds[1], c_bounds[2])),
    horizon = c(
      bsz = "BSZ: about the payment period, treating the responses as temporary.",
      rjkdc = "JR: for ever, since leavers are assumed not to return once the Act permanently lifts the intangible property tax cap."),
    # the JR draw is r - g, the real rate net of the lost tax's growth (chapter eqs. 14 and 18);
    # one rate matches the draw's average only for a perpetuity (model.R, rauh_residual)
    discount_rate = c(
      bsz = sprintf("%s: the rate this OPA applies to the BSZ analysis's 5-year loss, the middle of the JR range. BSZ give no rate.",
                    tok$r_bsz),
      rjkdc = sprintf("%s: worth the same as the JR draw (%s to %s) of r − g, the interest rate minus the lost tax's growth ($1 a year for ever is worth $%s).",
                      tok$r_jr, r_min, r_max, formatC(mv("A_inf_jr_draw"), format = "f", digits = 1))),
    minor_inputs = c(
      bsz = "BSZ: non-citizens taxed, no real-estate deduction, the extra tax from asset sales counted.",
      rjkdc = "JR: non-citizens left out, homes deducted, no extra tax from asset sales."),
    noncitizens = c(
      bsz = "BSZ: taxed like any other California resident.",
      rjkdc = "JR: left out. The 28 non-citizen billionaires live in California, but the chapter deems them too uncertain to collect from (treaties, apportionment)."),
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
  # ---- "But what are the actual quantities?" (author request 2026-10-15): after the panels and
  # the Apply block, one row per group of dials the author assesses together (QUANTITY_GROUPS).
  # Each analysis's cell holds one line per dial: its value as the dial's end prints it, the end's tip (end_tips above, without its "BSZ:" or "JR:" lead), a short source
  # cut from the dial's source column of export/r/inputs.csv, and the tip's "Kind:" label, so a
  # cell cannot drift from the tip it repeats. If a cell runs past QUANTITY_WORDS words it drops
  # the tip's parentheses, then keeps its first sentence only. The last column is the OPA
  # author's own judgement, read from comparison/data/author-credibility.csv (shown only when
  # SHOW_CREDIBILITY is TRUE); no code or agent writes an assessment.
  q_ids <- c(unlist(lapply(EXPLORER_BOXES, `[[`, "ids"), use.names = FALSE), EXPLORER_MINOR)
  stopifnot(setequal(unlist(QUANTITY_GROUPS, use.names = FALSE), q_ids),
            !anyDuplicated(unlist(QUANTITY_GROUPS, use.names = FALSE)))
  cred <- read_csv_plain(file.path(root, "comparison", "data", "author-credibility.csv"))
  stopifnot(setequal(cred$group_id, names(QUANTITY_GROUPS)), !anyDuplicated(cred$group_id),
            all(cred$assessment %in% CREDIBILITY_LEVELS))
  q_cell <- function(id, side) {
    ii <- inp[inp$step_id == id, ]
    if (id == "income_loss_share" && side == "rjkdc") ii <- ii[order(ii$input != "f0"), ]
    src <- ii[[if (side == "bsz") "supporting_source" else "rauh_source"]]
    hit <- quantity_source(unlist(regmatches(src, regexpr(QUANTITY_SOURCE_PATTERN, src))))
    tip <- sub("^[^:]{1,14}: ", "", end_tips[[id]][[side]])
    tip <- paste0(toupper(substr(tip, 1, 1)), substring(tip, 2))
    first <- sub("^(.*?[.])( [A-Z].*)?$", "\\1", tip, perl = TRUE)
    val <- dial_texts(inp, id, bi0)[[side]]
    # the source goes in parentheses at the end of the tip's first sentence, unless the tip
    # already cites a page
    make <- function(t) paste0(val, ". ",
      if (length(hit) && !grepl("p[.][0-9]", t)) sub("[.](?= [A-Z]|$)", paste0(" (", hit[1], ")."), t, perl = TRUE) else t,
      end_kind(id, side))
    bare <- function(t) gsub(" \\([^()]*\\)", "", t)
    words <- function(x) length(strsplit(x, " ")[[1]])
    for (t in c(tip, bare(tip), first, bare(first))) { out <- make(t); if (words(out) <= QUANTITY_WORDS) break }
    list(text = out, html = paste0("<b>", esc(val), ".</b> ", esc(substring(out, nchar(val) + 3))))
  }
  q_dial <- function(id) if (id %in% names(DIAL_SYMBOLS))
    sprintf('<i>%s</i> <span class="q-word">%s</span>', DIAL_SYMBOLS[[id]], esc(DIAL_WORDS[[id]])) else
    sprintf('<span class="q-word">%s</span>', esc(unname(short_labels[id])))
  q_heads <- c("Dial", "The BSZ analysis's value and why", "The JR analysis's value and why",
               if (SHOW_CREDIBILITY) "Which is more credible (the author of this OPA)")
  # one row per group: the dial column names every dial in it, and each analysis's cell holds one
  # line per dial, led by the dial's symbol when the group has more than one
  q_line <- function(id, side, many) paste0(
    '<span class="q-line" data-id="', id, '">',
    if (many) paste0(q_dial(id), " ") else "", q_cell(id, side)$html, "</span>")
  tok$quantity_rows <- paste(vapply(names(QUANTITY_GROUPS), function(g) {
    ids <- QUANTITY_GROUPS[[g]]; many <- length(ids) > 1
    cr <- cred[cred$group_id == g, ]
    has <- function(x) length(x) == 1 && !is.na(x) && nzchar(as.character(x))
    verdict <- paste0(esc(cr$assessment), if (has(cr$note)) paste0(". ", esc(cr$note)) else "",
                      if (has(cr$date)) paste0(" (", esc(as.character(cr$date)), ")") else "")
    paste0(sprintf(paste0('      <tr data-id="%s"><td data-label="%s">%s</td><td data-label="%s">%s</td>',
                          '<td data-label="%s">%s</td>'),
                   g, q_heads[1], paste(vapply(ids, q_dial, ""), collapse = "<br>"),
                   esc(q_heads[2]), paste(vapply(ids, q_line, "", "bsz", many), collapse = ""),
                   esc(q_heads[3]), paste(vapply(ids, q_line, "", "rjkdc", many), collapse = "")),
           if (SHOW_CREDIBILITY) sprintf('<td data-label="%s" class="q-cred">%s</td>', esc(q_heads[4]), verdict),
           "</tr>")
  }, ""), collapse = "\n")
  tok$quantity_heads <- paste(sprintf("<th>%s</th>", esc(q_heads)), collapse = "")
  # The same table on the explorer and in the overview's "The differences" fold (author request
  # 2026-10-15); only the link to the report differs by page.
  q_table <- function(report) paste0(
    '    <p class="q-sub">All these are empirical quantities. Their values should not depend on whether one\n',
    '    supports or opposes a wealth tax. An expert should be able to appraise each value from more to less\n',
    '    credible.</p>\n',
    '    <table class="q-table">\n',
    '      <thead><tr>', tok$quantity_heads, '</tr></thead>\n',
    '      <tbody>\n', tok$quantity_rows, '\n      </tbody>\n',
    '    </table>\n',
    '    <p class="q-foot">Each value\'s full source is in the <a href="', report,
    '#the-disputed-inputs">report\'s table of differences</a>.</p>')
  tok$quantity_table_root <- q_table("comparison/site/repro.html")
  # The explorer's section shows no table (author request 2026-10-15): the subtitle, then one large
  # button to the survey. The two survey versions (Value A and B swapped) live in
  # comparison/data/survey-links.csv; the page script sends each click to one of them at random.
  # With no links yet, the button is shown disabled.
  sv <- read_csv_plain(file.path(root, "comparison", "data", "survey-links.csv"))
  sv <- sv[!is.na(sv$url) & nzchar(sv$url), , drop = FALSE]
  stopifnot(all(grepl("^https://", sv$url)))
  survey_button <- paste0(
    '    <p class="q-cta">',
    if (nrow(sv)) sprintf('<a class="q-survey" href="%s" data-links="%s" target="_blank" rel="noopener">Take the survey: what do you think these values are?</a>',
                          esc(sv$url[1]), esc(paste(sv$url, collapse = " ")))
    else '<span class="q-survey is-off" aria-disabled="true">Take the survey: what do you think these values are? (opening soon)</span>',
    '</p>\n',
    '    <p class="q-share">Share this survey with people you think have expertise in this area, to learn what they think these values are.',
    if (nrow(sv)) paste0(' <button type="button" class="q-copy" data-url="', SURVEY_SHARE_URL, '">Copy link</button>') else "",
    '</p>')
  tok$quantity_survey_x <- paste0(
    '    <p class="q-sub">All these are empirical quantities. Their values should not depend on whether one\n',
    '    supports or opposes a wealth tax. An expert should be able to appraise each value from more to less\n',
    '    credible.</p>\n', survey_button)
  # the overview's differences fold: the same button under its table (author request 2026-10-15)
  tok$quantity_survey_root <- survey_button
  # Two smaller buttons at the top of the overview's differences fold, above the table (author
  # request 2026-10-15): take the survey (a random version, as above) and share it (copies the
  # share page's address). Nothing when the survey has no links yet.
  tok$quantity_survey_mini <- if (nrow(sv)) paste0(
    '<p class="q-mini">',
    sprintf('<a class="q-survey q-survey-mini" href="%s" data-links="%s" target="_blank" rel="noopener">Take the survey</a>',
            esc(sv$url[1]), esc(paste(sv$url, collapse = " "))),
    sprintf('<button type="button" class="q-copy q-copy-mini" data-url="%s">Share the survey: copy link</button>', SURVEY_SHARE_URL),
    '</p>') else ""
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
    # the hidden title a screen reader announces is the dial's name, not a step name ("No
    # avoidance" is the JR end of the a dial)
    slider_row(panel, id, unname(DIAL_SYMBOLS[id]), DIAL_NAMES[[id]],
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
  # path moves the BSZ panel's dials in the equation's order, each to its far end (dial_path() in
  # model.R, export/r/dial_path.csv), so the terms, pressed left to right, are the path's steps.
  # The terms take the BSZ end to the JR end exactly. eq_terms() is shared with the deck (slides.Rmd).
  stopifnot(identical(DIAL_PATH_ORDER, eq_path_order()))
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  stopifnot(identical(dp$step_id, DIAL_PATH_ORDER))
  et <- eq_terms(dp)
  jr_label <- "JR estimate"
  # the six labels, left to right; the top equation and the Apply block both print these
  eq_labels <- c("BSZ estimate", et$terms$label, jr_label)
  eq_ops <- c("", ifelse(et$terms$change < 0, "&minus;", "+"), "&asymp;")
  # One builder for both equations (author request 2026-10-15: the Apply block mirrors the top
  # equation, so both share this markup and its CSS). `inner` is each term's content, `attrs`
  # each term's attributes; the first term has no sign, and each later sign sits in one
  # .eq-step with its term, so a line never ends with a sign.
  eq_html <- function(class, attrs, inner, term_attrs) paste0(
    '<div class="', class, '"', attrs, '>\n',
    paste(vapply(seq_along(inner), function(j) if (j == 1)
      sprintf('  <span class="term"%s>%s</span>', term_attrs[j], inner[j]) else
      sprintf('  <span class="eq-step"><span class="op">%s</span><span class="term"%s>%s</span></span>',
              eq_ops[j], term_attrs[j], inner[j]), ""), collapse = "\n"), "\n",
    '</div>')
  say <- function(j) sprintf("%s %s for %s", if (et$terms$change[j] < 0) "minus" else "plus",
                             money(abs(et$terms$change[j]), 1), tolower(et$terms$label[j]))
  eq_amounts <- c(money(eb$bsz_model, 1), money(abs(et$terms$change), 1), money(eb$rauh_model, 1))
  pseudo_eq <- function(page) eq_html(
    "pseudo-eq",
    paste0(' role="img" aria-label="', esc(sprintf(
      "The BSZ estimate, %s, %s, gives about the JR estimate, %s.",
      money(eb$bsz_model, 1), paste(vapply(seq_len(nrow(et$terms)), say, ""), collapse = ", "),
      money(eb$rauh_model, 1))), '"'),
    # the overview's labels drop the bracketed dial letters (author request 2026-10-15): the
    # letters name the explorer's dials, which the overview does not show
    sprintf("<b>%s</b><small>%s</small>", eq_amounts,
            esc(if (page == "root") sub(" \\([^()]*\\)$", "", eq_labels) else eq_labels)),
    c(' data-steps="0"', sprintf(' data-steps="%s"', et$terms$steps), sprintf(' data-end="%d"', nrow(dp))))
  tok$pseudo_eq_x <- pseudo_eq("x")
  # The Apply block (author requests 2026-10-15): after the two panels, the top equation's grid
  # with each term's label where the top equation shows its caption, and a small button under
  # it. A middle term's button moves that term's dials of the BSZ panel (data-dials:
  # eq_term_dials(), the minor switch read as its three dials) to the JR end, or back; "Reset"
  # under the BSZ estimate and "Apply all" under the JR estimate move every dial.
  td <- eq_term_dials(dp, et)
  ap_btn <- function(act, dials, text, extra = "") sprintf(
    '<button type="button" class="ap-btn" data-act="%s" data-dials="%s"%s>%s</button>',
    act, paste(dials, collapse = " "), extra, text)
  all_dials <- unlist(td)
  ap_btns <- c(ap_btn("reset", all_dials, "Reset"),
               vapply(seq_len(nrow(et$terms)), function(j) ap_btn("term", td[[j]], "Apply",
                      sprintf(' data-steps="%s" aria-pressed="false"', et$terms$steps[j])), ""),
               ap_btn("all", all_dials, "Apply all"))
  tok$apply_eq <- eq_html(
    "pseudo-eq apply-eq",
    ' role="group" aria-label="The equation above in words: each button moves those dials of the BSZ panel to the JR values, or back"',
    # each label in the amounts' face (bold, the same size), its bracketed symbols on a line of
    # their own (author request 2026-10-15: the words now take the place of the numbers)
    sprintf('<b class="ap-label">%s</b>%s', sub(" (", "<br>(", esc(eq_labels), fixed = TRUE), ap_btns),
    rep("", length(eq_labels)))
  tok$pseudo_eq <- pseudo_eq("root")
  # Both notes end by saying the terms depend on the path's order, and why, and are not totals;
  # that the rounded terms add up to the JR end only to rounding (the unrounded sum, the BSZ end
  # plus every step of the path, is the JR end exactly); and the two analyses' own present values
  # of lost income tax for scale (the equation's loss term is a change along the path, not either
  # of these). The order-free check is the report's fold #order-free-check; the link names no
  # method (test-site.R bans the method's name on both pages). Every amount is kept on one line
  # with its sign.
  nowrap <- function(x) paste0('<span style="white-space:nowrap">', x, '</span>')
  order_note <- function(href) sprintf(paste(
    " Each amount is what its group changes when the dials move in this order. It is not a total,",
    "and its size depends on the order, because the inputs multiply each other: a departure",
    "matters more when more wealth is left to tax. The report's <a href=\"%s\">order-free check</a>",
    "averages each input's step over every order the dials could move in. The amounts are rounded",
    "to one decimal. Unrounded, they add up exactly to %s. For scale, the lost income tax itself",
    "is worth %s today in the JR analysis and %s in the BSZ analysis."),
    href, nowrap(money(eb$bsz_model + sum(dp$change), 2)),
    nowrap(money(score_common(bi0$rauh)[["PV"]], 1)), nowrap(money(score_common(bi0$sup)[["PV"]], 1)))
  # The explorer's note names the dial letters and the Walk the path button.
  eq_note <- function(href, panel, walk, of_href) paste0(
    "Move the ", panel, "'s dials to their far ends, term by term from left to right. ", esc(et$note), " ",
    walk,
    sprintf("The <a href=\"%s\">report</a> gives all %s steps.", href, et$n_words),
    order_note(of_href))
  tok$pseudo_eq_note_x <- eq_note("../repro.html#the-bridge", "BSZ panel",
                                  "The Walk the path button in each panel does it for you. ",
                                  "../repro.html#order-free-check")
  # the overview names no dial letters (author request 2026-10-15), so its note says the same in
  # words; its old "Each term is what its group changes" is now the first sentence of order_note()
  tok$pseudo_eq_note_root <- paste0(
    "Move the <a href=\"comparison/site/explorer/\">explorer</a>'s BSZ panel to the JR values one group at a time, ",
    "from left to right: the departed wealth, the chance the tax survives in court, the four inputs of the ",
    "lost income tax, then the other three. ",
    sprintf("The <a href=\"%s\">report</a> gives all %s steps.", "comparison/site/repro.html#the-bridge", et$n_words),
    order_note("comparison/site/repro.html#order-free-check"))

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
  # (d_conf_jr, above the end tips; export/r/inputs.csv has no d_conf row)
  oval <- function(id) pick(k$rjkdc$outputs, id)
  tok$dconf_sept <- pct(d_conf_jr, 1)
  tok$ceiling_literal <- formatC(pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"), format = "f", digits = 0)
  tok$ceiling_file <- formatC(oval("nber_ceiling"), format = "f", digits = 2)
  tok$domestic_grown <- formatC(oval("nber_domestic_grown"), format = "f", digits = 3)

  # ---- vintage ----
  tok$vintage_rows <- paste(c(
    # the March document's own base, the 2025 list before the September version grows it 7%
    # (SSRN 6340778 p.5: "Sum $1,894.8 billion Count 212")
    sprintf('    <tr><td>Rauh et al., SSRN 6340778</td><td>17 Mar 2026</td><td>%s billionaires, %s, 2025 Forbes list (p.5)</td></tr>',
            n_rauh, money(pick(k$rjkdc$inputs, "baseline_net_worth"), 1)),
    '    <tr><td>Galle, Gamage, Saez, Shanske, response to Rauh</td><td>17 Mar 2026</td><td>answers Rauh\'s 4 Mar version, not the 17 Mar version this project reproduces as the JR first version</td></tr>',
    sprintf('    <tr><td>Hoopes, SSRN 6428578</td><td>2026 (uses the February GGSS text)</td><td>%s billionaires, %s (p.3 fn.1)</td></tr>',
            dv("hoopes_n_billionaires"), money(dv("hoopes_wealth"), 0)),
    sprintf('    <tr><td>GGSS expert report</td><td>updated 20 Jul 2026</td><td>%s billionaires, %s at 1 Jul 2026, non-citizens included, Ellison excluded</td></tr>',
            n_sup, money(inp$supporting_value[inp$input == "W_core"] + inp$supporting_value[inp$input == "W_noncit"], 0)),
    '    <tr><td>Boll, Saez, Zucman, NBER WP 35218</td><td>Aug 2026 revision</td><td>same 1 Jul 2026 base; Table 5 adds missing billionaires and leaver scenarios</td></tr>',
    sprintf('    <tr><td>Jaros and Rauh, NBER c15504</td><td>Sep 2026</td><td>Rauh\'s base grown %s to 31 Dec 2026, seven departures, litigation weight</td></tr>', pct(pick(k$rjkdc$inputs, "nber_growth_rate"))),
    # the LAO's three bounds (LAO pp.2-3); the income tax one is read from document-inputs.csv
    sprintf('    <tr><td>LAO ballot analysis</td><td>for the 3 Nov 2026 ballot</td><td>no point estimate. It puts the wealth tax at tens of billions of dollars over several years, the ongoing income tax loss at under $%s billion a year, and administration costs at tens of millions a year (pp.2-3)</td></tr>',
            dv("lao_loss_upper"))), collapse = "\n")

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
    path = DIAL_PATH_ORDER)
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

# The survey's shareable address: a page that sends each visitor to one of the two versions at
# random, so a copied link keeps the half-and-half split (author request 2026-10-15).
SURVEY_SHARE_URL <- "https://fhoces.github.io/opa-prop40/comparison/site/survey/"
survey_share_page <- function(root) {
  sv <- read_csv_plain(file.path(root, "comparison", "data", "survey-links.csv"))
  urls <- sv$url[!is.na(sv$url) & nzchar(sv$url)]
  paste0('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">\n',
         '<meta name="viewport" content="width=device-width, initial-scale=1">\n',
         '<title>Proposition 40 survey</title>\n<meta name="robots" content="noindex">\n',
         '<link rel="stylesheet" href="../../../assets/paper.css">\n</head>\n<body class="pg">\n',
         '<!-- Generated by comparison/R/site.R from comparison/data/survey-links.csv. Do not edit. -->\n',
         '<p style="margin:3em auto;max-width:30em;text-align:center">Opening the survey&hellip; ',
         if (length(urls)) sprintf('If nothing happens, <a href="%s">open it here</a>.', esc(urls[1])) else 'The survey is not open yet.',
         '</p>\n',
         if (length(urls)) sprintf('<script>var L = %s; location.replace(L[Math.floor(Math.random() * L.length)]);</script>\n',
                                   jsonlite::toJSON(urls, auto_unbox = FALSE)) else '',
         '</body></html>\n')
}
write_site <- function(root = comparison_root()) {
  s <- render_site(root)
  dir.create(file.path(root, "comparison", "site", "survey"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(survey_share_page(root))), file.path(root, "comparison", "site", "survey", "index.html"))
  dir.create(file.path(root, "assets"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(s$html)), file.path(root, "index.html"))
  dir.create(file.path(root, "comparison", "site", "explorer"), showWarnings = FALSE)
  writeBin(charToRaw(enc2utf8(s$explorer)), file.path(root, "comparison", "site", "explorer", "index.html"))
  writeBin(charToRaw(enc2utf8(s$js)), file.path(root, "assets", "comparison-data.js"))
  invisible(s)
}
