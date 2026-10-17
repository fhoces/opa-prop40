# The published pages are exactly what the generator makes from the exports.
root <- comparison_root()
explorer <- file.path(root, "comparison", "site", "explorer", "index.html")
read_page <- function(p) paste(readLines(p, encoding = "UTF-8"), collapse = "\n")
pages <- c(root = file.path(root, "index.html"), explorer = explorer)

test_that("index.html, the explorer and assets/comparison-data.js are the generator's own output", {
  s <- render_site(root)
  expect_identical(s$html, read_page(file.path(root, "index.html")) |> paste0("\n"))
  expect_identical(s$explorer, read_page(explorer) |> paste0("\n"))
  expect_identical(s$js, read_page(file.path(root, "assets", "comparison-data.js")) |> paste0("\n"))
})

test_that("the explorer loads the data file with the hash of its content", {
  h <- data_hash(read_page(file.path(root, "assets", "comparison-data.js")) |> paste0("\n"))
  expect_true(grepl(sprintf('comparison-data.js?v=%s"', h), read_page(explorer), fixed = TRUE))
})

test_that("every comparison page opens its nav line with the same prefix", {
  # the shorter form of 3b6ef55 on the generated pages and the Quarto sources alike
  # (consistency review 004, C-11)
  srcs <- c(pages, repro = file.path(root, "comparison", "site", "repro.qmd"),
            materials = file.path(root, "comparison", "site", "materials.qmd"))
  for (p in srcs) {
    html <- read_page(p)
    expect_true(grepl("Prop 40 comparison:", html, fixed = TRUE), label = p)
    expect_false(grepl("Comparison of the two analyses of California Proposition 40:", html, fixed = TRUE), label = p)
  }
})

test_that("the Apply block, after the two panels, is the top equation's grid with labels and buttons", {
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  html <- read_page(explorer)
  eq <- regmatches(html, regexpr('<div class="pseudo-eq".*?</div>', html))
  ap <- regmatches(html, regexpr('<div class="pseudo-eq apply-eq".*?</div>', html))
  expect_length(ap, 1)
  # after both panels (the JR panel's slider list; the panel notes under the dials went in
  # review 005, U-09), before the notes fold; no longer in the BSZ panel
  at <- function(x) regexpr(x, html, fixed = TRUE)[[1]]
  expect_gt(at('<div class="pseudo-eq apply-eq"'), at('aria-label="The JR panel\'s sliders"'))
  expect_lt(at('<div class="pseudo-eq apply-eq"'), at('<details class="fold notes" id="notes-estimates">'))
  expect_identical(lengths(regmatches(html, gregexpr('class="pseudo-eq apply-eq"', html, fixed = TRUE))), 1L)
  expect_false(grepl('class="panel-note"', html, fixed = TRUE))
  # its one-line lead names the panel the buttons act on, once
  expect_identical(lengths(regmatches(html, gregexpr("Apply to the BSZ panel", html, fixed = TRUE))), 1L)
  expect_gt(at("Apply to the BSZ panel"), at('aria-label="The JR panel\'s sliders"'))
  # the top equation's markup: six terms, the same signs, each label in the amounts' bold face
  # (its bracketed symbols on their own line), then the term's button directly under it; no amounts
  top <- regmatches(eq, gregexpr("(?<=<small>)[^<]*(?=</small>)", eq, perl = TRUE))[[1]]
  terms <- regmatches(ap, gregexpr('<span class="term"><b class="ap-label">.*?</b><button[^>]*>[^<]*</button></span>', ap, perl = TRUE))[[1]]
  expect_length(terms, 6)
  words <- sub("<br>(", " (", sub('^<span class="term"><b class="ap-label">(.*?)</b>.*$', "\\1", terms, perl = TRUE), fixed = TRUE)
  expect_length(top, 6)
  expect_identical(words, top)
  expect_false(grepl("$", ap, fixed = TRUE))
  sig <- function(x) gsub('<span class="term"[^>]*>.*?</span></span>|<span class="term"[^>]*>.*?</span>', "T", x)
  expect_identical(sig(ap), sub('class="pseudo-eq" role="img" aria-label="[^"]*"', 'class="pseudo-eq apply-eq" role="group" aria-label="The equation above in words: each button moves those dials of the BSZ panel to the JR values, or back"', sig(eq)))
  # the buttons: Reset, one Apply per middle term, Apply all
  btn <- regmatches(ap, gregexpr("<button[^>]*>[^<]*</button>", ap))[[1]]
  expect_identical(sub(".*>([^<]*)</button>$", "\\1", btn), c("Reset", rep("Apply", 4), "Apply all"))
  dials <- strsplit(sub('.*data-dials="([^"]*)".*', "\\1", btn), " ", fixed = TRUE)
  # each middle term's dials, from the grouping rule (D, q, the loss box, the rest) with the
  # minor switch read as its three dials
  main <- match(c("confirmed_departures", "litigation_survival"), dp$step_id)
  loss <- match(c("income_loss_share", "income_level", "horizon", "discount_rate"), dp$step_id)
  rest <- setdiff(seq_len(nrow(dp)), c(main, loss))
  expand <- function(i) unlist(lapply(dp$step_id[i], function(id) if (id == "minor_inputs") EXPLORER_MINOR else id))
  want <- list(expand(main[1]), expand(main[2]), expand(loss), expand(rest))
  expect_identical(want[[4]], c("base_list", "avoidance", "noncitizens", "real_estate", "asset_sales"))
  expect_identical(dials[2:5], want)
  expect_identical(dials[2:5], eq_term_dials(dp))
  expect_identical(dials[[1]], unlist(want))
  expect_identical(dials[[6]], unlist(want))
  # every dial of the BSZ panel except the switch, once each
  ids <- regmatches(html, gregexpr('(?<=data-panel="bsz" data-id=")[a-z_]+', html, perl = TRUE))[[1]]
  expect_setequal(dials[[1]], setdiff(ids, "minor_inputs"))
  # each sign in the block is its term's sign: the remainder (W, a and the minor switch) raises
  # the estimate, so its sign is a plus
  ops <- regmatches(ap, gregexpr('(?<=<span class="op">)[^<]*(?=</span>)', ap, perl = TRUE))[[1]]
  ch <- c(dp$change[main], sum(dp$change[loss]), sum(dp$change[rest]))
  expect_identical(ops, c(ifelse(ch < 0, "&minus;", "+"), "="))
  expect_gt(ch[4], 0)
  # each Apply button names the top term it marks, and starts unpressed
  steps <- sub('.*data-steps="([^"]*)".*', "\\1", btn[2:5])
  for (st in steps) expect_true(grepl(sprintf('<span class="term" data-steps="%s">', st), eq, fixed = TRUE), label = st)
  expect_true(all(grepl('aria-pressed="false"', btn[2:5], fixed = TRUE)))
})

test_that("pressing the Apply buttons left to right gives each printed term exactly", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "node is not on PATH: model.js not checked")
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  html <- read_page(explorer)
  ap <- regmatches(html, regexpr('<div class="pseudo-eq apply-eq".*?</div>', html))
  eq <- regmatches(html, regexpr('<div class="pseudo-eq".*?</div>', html))
  btn <- regmatches(ap, gregexpr('<button[^>]*data-act="term"[^>]*>', ap))[[1]]
  dials <- lapply(strsplit(sub('.*data-dials="([^"]*)".*', "\\1", btn), " ", fixed = TRUE), identity)
  # the four middle amounts and their signs as the top equation prints them
  b <- regmatches(eq, gregexpr("(?<=<b>)[^<]*(?=</b>)", eq, perl = TRUE))[[1]]
  ops <- regmatches(eq, gregexpr('(?<=<span class="op">)[^<]*(?=</span>)', eq, perl = TRUE))[[1]]
  expect_length(b, 6); expect_length(ops, 5)
  js <- tempfile(fileext = ".js")
  writeLines(c(
    "globalThis.window = globalThis;",
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "assets", "comparison-data.js"), auto_unbox = TRUE)),
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "comparison", "site", "explorer", "model.js"), auto_unbox = TRUE)),
    sprintf("const S = window.__BRIDGE__.sliders, M = window.ComparisonModel, B = %s;", jsonlite::toJSON(dials)),
    "const p = {}, v = [M.panelValue(S, 'bsz', p).value];",
    "B.forEach(ids => { ids.forEach(i => { p[i] = S.inputs.find(x => x.id === i).max; }); v.push(M.panelValue(S, 'bsz', p).value); });",
    "console.log(JSON.stringify(v));"), js)
  v <- jsonlite::fromJSON(paste(system2(node, js, stdout = TRUE), collapse = ""))
  # the running values after each press are the path's values at the end of each term
  last <- vapply(strsplit(sub('.*data-steps="([^"]*)".*', "\\1", btn), " "), function(x) max(as.integer(x)), 0L)
  expect_identical(last, c(1L, 2L, 6L, 9L))
  expect_lt(max(abs(v - c(dp$from[1], dp$to[last]))), 1e-9)
  # each press changes the panel by the printed term: same amount, same sign
  d <- diff(v)
  expect_identical(vapply(abs(d), money, "", 2), b[2:5])
  expect_identical(ifelse(d < 0, "&minus;", "+"), ops[1:4])
  # the two ends print at one decimal since 2026-10-17 (author request), the main estimates' figures
  expect_identical(money(v[1], 1), b[1]); expect_identical(money(v[5], 1), b[6])
  expect_identical(b[2:5], c("$29.89B", "$39.44B", "$81.34B", "$4.89B"))
  expect_identical(ops[4], "+")
})

test_that("both pages carry the pseudo-equation: D and q, the loss box added up, the rest added up, BSZ to JR", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  expect_equal(eb$bsz_model + sum(dp$change), eb$jr_own, tolerance = 1e-9)
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  for (p in pages) {
    html <- read_page(p)
    expect_true(grepl('<div class="pseudo-eq" role="img"', html, fixed = TRUE), label = p)
    eq <- regmatches(html, regexpr('<div class="pseudo-eq".*?</div>', html))
    # the rule (author decision 2026-10-15): D and q one by one, each labelled with its dial's
    # title and symbol; the four loss-box dials added up as "Lost income tax"; W, a and the minor
    # switch added up as the last term; nothing under a term (no running value)
    main <- match(c("confirmed_departures", "litigation_survival"), dp$step_id)
    loss <- match(c("income_loss_share", "income_level", "horizon", "discount_rate"), dp$step_id)
    rest <- match(c("base_list", "avoidance", "minor_inputs"), dp$step_id)
    expect_identical(sort(c(main, loss, rest)), seq_len(nrow(dp)))
    expect_identical(dp$symbol[main], c("D", "q"))
    # the explorer labels each term with its dials' letters; the overview drops them (author
    # request 2026-10-15)
    lt <- function(x) if (identical(p, explorer)) paste0(" (", x, ")") else ""
    pins <- c(vapply(main, function(i) sprintf(
      '<span class="term" data-steps="%d"><b>%s</b><small>%s%s</small></span>',
      i, money(abs(dp$change[i]), 2), dp$title[i], lt(dp$symbol[i])), ""),
      sprintf('<span class="term" data-steps="%s"><b>%s</b><small>Lost income tax%s</small></span>',
              paste(loss, collapse = " "), money(abs(sum(dp$change[loss])), 2), lt("H, f, C, r")),
      sprintf('<span class="term" data-steps="%s"><b>%s</b><small>The other three steps together%s</small></span>',
              paste(rest, collapse = " "), money(abs(sum(dp$change[rest])), 2), lt("W, a, the minor switch")))
    if (!identical(p, explorer)) expect_false(grepl("\\([A-Za-z, ]+\\)</small>", eq), label = "no letters on the overview")
    at <- vapply(pins, function(x) regexpr(x, eq, fixed = TRUE)[[1]], 0)
    expect_true(all(at > 0), label = paste(p, "terms"))
    expect_true(all(diff(at) > 0), label = paste(p, "term order"))
    expect_identical(lengths(regmatches(eq, gregexpr('class="term"', eq, fixed = TRUE))), 6L, label = paste(p, "six terms"))
    # the four printed terms take the printed BSZ estimate exactly to the printed JR estimate
    # (author decision 2026-10-16: "=", every amount to two decimals, 106.80 - 29.89 - 39.44 -
    # 81.34 + 4.89 = -38.98). Since 2026-10-17 the two ends print at one decimal ($106.8B and
    # -$39.0B, author request), matching the headline's main estimates; the four terms still add
    # up to -38.98, which prints as -39.0, and this check keeps the two-decimal values.
    printed <- round(c(dp$change[main], sum(dp$change[loss]), sum(dp$change[rest])), 2)
    expect_lt(abs(round(eb$bsz_model, 2) + sum(printed) - round(eb$jr_own, 2)), 1e-9, label = paste(p, "sum"))
    expect_true(grepl('<span class="op">=</span><span class="term" data-end=', eq, fixed = TRUE), label = paste(p, "equals"))
    expect_false(grepl("&asymp;", eq, fixed = TRUE), label = paste(p, "no about"))
    expect_true(grepl(sprintf('<b>%s</b><small>BSZ estimate</small>', money(eb$bsz_model, 1)), eq, fixed = TRUE), label = p)
    # BSZ at the left, JR at the right
    expect_lt(regexpr("<small>BSZ estimate</small>", eq, fixed = TRUE)[[1]], at[1])
    expect_gt(max(gregexpr("JR estimate", eq, fixed = TRUE)[[1]]), at[length(at)])
    # the printed end is the JR estimate, the authors' exact mean (-$39.0B), and no rate-gap note is left
    expect_true(grepl(sprintf('<b>%s</b><small>JR estimate</small>', money(eb$jr_own, 1)), eq, fixed = TRUE), label = p)
    expect_identical(money(eb$jr_own, 1), "\u2212$39.0B")
    expect_false(grepl("eq-gap", html, fixed = TRUE), label = p)
    for (x in c("rate gap", "one 3% rate", "worth about $6.7B")) expect_false(grepl(x, html, fixed = TRUE), label = paste(p, x))
    # no Shapley numbers or wording on either page
    expect_false(grepl("shapley", html, ignore.case = TRUE), label = p)
  }
  ex_html <- read_page(explorer)
  # Footnote 2 on the explorer: the order point and the Apply buttons, then a link to the report.
  # The pin held the sentences on how the terms group the dials until 2026-10-17, when the author
  # asked for notes of three sentences at most (the rest in the report): those sentences now print
  # in the report's "The explorer's equation" (eq_terms()$note), so the pin moves to the new text.
  dp_q <- dp$change[dp$step_id == "litigation_survival"]
  fn2 <- regmatches(ex_html, regexpr('(?s)<p class="fn" id="fn-eq">.*?</p>', ex_html, perl = TRUE))
  expect_length(fn2, 1)
  expect_true(grepl(paste("<sup>2</sup> The equation adds up only when the terms are switched one after another,",
                          "in this order, from left to right."), fn2, fixed = TRUE))
  expect_true(grepl(sprintf('instead of <span style="white-space:nowrap">%s</span>', money(dp_q, 2)), fn2, fixed = TRUE))
  expect_true(grepl(paste("The Apply buttons work from left to right, each unlocking the next, so each press",
                          "changes the estimate by its amount in the equation (more in the report:",
                          '<a href="../repro.html#the-equation">The explorer\'s equation</a>).</p>'),
                    fn2, fixed = TRUE))
  for (panel in c("bsz", "rjkdc"))
    expect_true(grepl(sprintf('<button type="button" class="reset walk" data-panel="%s">Walk the path</button>', panel), ex_html, fixed = TRUE), label = panel)
  # the overview's section has no dial letters in brackets, in the equation or its note
  ov <- read_page(file.path(root, "index.html"))
  sec <- regmatches(ov, regexpr('<section class="eq-box" id="what-separates".*?</section>', ov))
  expect_false(grepl("\\((?:[A-Za-z], )*[A-Za-z](?: and [^)]*)?\\)", gsub("<[^>]*>", "", sec), perl = TRUE))
  expect_true(grepl("the departed wealth, the chance the tax survives in court, the four inputs of the", sec, fixed = TRUE))
})

test_that("every fold on the overview has a # link to its own id, and the fold-URL script", {
  html <- read_page(file.path(root, "index.html"))
  ids <- regmatches(html, gregexpr('(?<=<details class="fold" id=")[a-z0-9-]+', html, perl = TRUE))[[1]]
  expect_gt(length(ids), 0)
  for (id in ids) expect_true(grepl(sprintf(
    '<details class="fold" id="%s">\n  <summary><h2[^>]*>[^<]* <a class="fold-link" href="#%s" aria-label="Link to this section">#</a></h2>', id, id),
    html), label = id)
  expect_true(grepl('history.replaceState(null, "", "#" + d.id)', html, fixed = TRUE))
})

test_that("money() rounds a tie away from zero on either side of it, as the explorer's script does", {
  # the JR end at 3% is -32.25 exactly; R holds -32.249999999999993, model.js about -32.25
  for (v in c(-32.25 + 7e-15, -32.25, -32.25 - 7e-15)) expect_identical(money(v, 1), "\u2212$32.3B")
  expect_identical(money(0.04999, 1), "$0.0B")
})

test_that("no unfilled tokens, no em-dashes on either page", {
  for (p in pages) {
    html <- read_page(p)
    expect_false(grepl("{{", html, fixed = TRUE), label = p)
    expect_false(grepl(intToUtf8(0x2014), html, fixed = TRUE), label = p)
  }
})

test_that("key numbers appear on the pages as computed", {
  html <- read_page(file.path(root, "index.html"))
  ex_html <- read_page(explorer)
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  ea <- en[en$horizon_setting == "own" & en$output == "a", ]
  v <- function(id) ep$value[ep$endpoint_id == id]
  expect_true(grepl(money(v("bsz_tab5_row1"), 1), html, fixed = TRUE))
  # the overview's table of the two analyses on the common output went on 2026-10-15 (it is in
  # the report): the JR estimate is the equation's right end
  expect_true(grepl(money(eb$jr_model, 1), html, fixed = TRUE))
  # the explorer's footnote: both ends and the gap on the net fiscal effect, output (b)
  expect_true(grepl(sprintf("The BSZ end is <b>%s</b> and the JR end <b>%s</b>, a gap of <b>%s</b>.",
                            money(eb$bsz_model, 1), money(eb$jr_model, 1), money(eb$bsz_model - eb$jr_model, 1)),
                    ex_html, fixed = TRUE))
  # the explorer shows the net fiscal effect only: no output setting, no gross revenue
  # number (the two ends on output (a), its gap, Table 5 row 1), no output (a) in its data file
  expect_false(grepl("data-out=", ex_html, fixed = TRUE))
  for (x in c(money(ea$bsz_model, 1), money(ea$jr_own, 1), money(ea$bsz_model - ea$jr_own, 1),
              money(ea$bsz_model, 3)))
    expect_false(grepl(x, ex_html, fixed = TRUE), label = paste("explorer shows", x))
  txt <- read_page(file.path(root, "assets", "comparison-data.js"))
  D <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^{]*", "", txt)), simplifyVector = FALSE)
  for (st in names(D$series)) expect_identical(names(D$series[[st]]), "b", label = st)
  # the slider panels read inputs, not a precomputed grid
  expect_null(D$switchboard)
})

test_that("the switchboard: all off is the BSZ end, all on is the JR end", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  sb <- read_csv_plain(file.path(root, "comparison", "export", "r", "switchboard.csv"))
  ids <- bridge_steps()$step_id
  for (st in unique(en$horizon_setting)) {
    n <- if (st == "own") length(ids) else length(ids) - 1
    for (o in c("a", "b")) {
      e <- en[en$horizon_setting == st & en$output == o, ]
      g <- sb[sb$horizon_setting == st & sb$output == o, ]
      g <- g[order(g$mask), ]
      expect_equal(nrow(g), 2^n, label = paste(st, o, "rows"))
      expect_equal(g$value[g$mask == 0], e$bsz_model, tolerance = 1e-9, label = paste(st, o, "all off"))
      expect_equal(g$value[nrow(g)], e$jr_model, tolerance = 1e-9,
                   label = paste(st, o, "all on"))
    }
  }
})

test_that("the slider panels: the dials in their two boxes in the bridge's order, then the minor switch, both panels", {
  ids <- bridge_steps()$step_id
  shown <- explorer_slider_ids()
  expect_identical(shown, setdiff(ids, c("noncitizens", "real_estate", "asset_sales")))
  ex_html <- read_page(explorer)
  txt <- read_page(file.path(root, "assets", "comparison-data.js"))
  D <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^{]*", "", txt)), simplifyVector = FALSE)
  for (panel in c("bsz", "rjkdc")) {
    sl <- regmatches(ex_html, gregexpr(sprintf('<input type="range" class="sl-in" id="%s-[a-z_]+" min="0" max="[0-9]" step="1" value="0" data-panel="%s" data-id="[a-z_]+"', panel, panel), ex_html))[[1]]
    all_ids <- c(shown, "minor_inputs", EXPLORER_MINOR)
    expect_identical(sub('.*data-id="([a-z_]+)"$', "\\1", sl), all_ids, label = panel)
    expect_identical(sub('.*max="([0-9])".*', "\\1", sl),
                     as.character(c(vapply(shown, slider_max, 0L), 1L, vapply(EXPLORER_MINOR, slider_max, 0L))), label = panel)
    # every slider carries its explanation, and the input points at it
    # the two boxes hold the shown dials, in order
    expect_equal(length(gregexpr(sprintf('<li class="sl-box" role="group" aria-labelledby="%s-', panel), ex_html)[[1]]), 2L, label = panel)
    for (id in all_ids) {
      expect_true(grepl(sprintf('<span class="sl-tip" role="tooltip" id="%s-%s-tip">(?:[^<]|<br>){30,}</span>', panel, id), ex_html, perl = TRUE), label = paste(panel, id, "tip"))
      for (side in c("bsz", "rjkdc"))
        expect_true(grepl(sprintf('<span class="end-tip" role="tooltip" id="%s-%s-%s-tip">[^<]{15,}</span>', panel, id, side), ex_html), label = paste(panel, id, side, "end tip"))
      # the slider is the dial's one tab stop; its description names the symbol tip and both end
      # tips, and the ends are not focusable (author answer 2026-10-16, review 005 U-18)
      expect_true(grepl(sprintf('data-id="%s" aria-describedby="%s-%s-tip %s-%s-bsz-tip %s-%s-rjkdc-tip"', id, panel, id, panel, id, panel, id), ex_html, fixed = TRUE), label = paste(panel, id, "describedby"))
    }
  }
  # Every dial has its smaller value at the left end and its larger at the right, in both
  # panels, whichever analysis each belongs to (author instruction 2026-10-15). Each end is
  # tagged with its analysis; a slider runs right to left exactly where the panel's own value
  # (position 0) is at the right end. The values compared are the data file's (the first
  # argument a dial moves), the printed percentages for the share lost; the minor switch's
  # ends are not numbers and keep the BSZ values at the left.
  expect_false(grepl("sl-head", ex_html, fixed = TRUE))
  expect_false(grepl("<span>BSZ value</span>", ex_html, fixed = TRUE))
  expect_false(grepl('class="sl-end sl-(lo|hi) has-tip"[^>]*tabindex', ex_html))
  rows <- regmatches(ex_html, gregexpr('(?s)<li class="sl(?: has-sym)?" data-id="[a-z_]+">.*?</li>', ex_html, perl = TRUE))[[1]]
  expect_length(rows, 2L * (length(shown) + 1L + length(EXPLORER_MINOR)))
  num <- function(z) if (identical(z, "Inf")) Inf else z
  inp_of <- stats::setNames(lapply(D$sliders$inputs, function(x) unlist(x$input)), vapply(D$sliders$inputs, `[[`, "", "id"))
  rtl_ids <- list(bsz = character(), rjkdc = character())
  for (li in rows) {
    id <- sub('(?s)^<li class="sl(?: has-sym)?" data-id="([a-z_]+)">.*', "\\1", li, perl = TRUE)
    panel <- sub('(?s).*data-panel="([a-z]+)".*', "\\1", li, perl = TRUE)
    ends <- regmatches(li, gregexpr('class="sl-end sl-(lo|hi)[^"]*" data-side="(bsz|rjkdc)"[^>]*><span class="sl-end-v">[^<]*</span><span class="sl-end-tag">(BSZ|JR)</span>', li))[[1]]
    expect_length(ends, 2L)
    at <- sub('class="sl-end sl-(lo|hi).*', "\\1", ends)
    side <- sub('.*data-side="(bsz|rjkdc)".*', "\\1", ends)
    tag <- sub('.*<span class="sl-end-tag">(BSZ|JR)</span>$', "\\1", ends)
    lab <- paste(panel, id)
    expect_identical(at, c("lo", "hi"), label = lab)
    expect_setequal(side, c("bsz", "rjkdc"))
    expect_identical(tag, c(bsz = "BSZ", rjkdc = "JR")[side] |> unname(), label = lab)
    if (id == "minor_inputs") {
      expect_identical(side, c("bsz", "rjkdc"), label = lab)
    } else if (id == "income_loss_share") {
      v <- as.numeric(sub("%", "", sub('.*<span class="sl-end-v">([^<]*)</span>.*', "\\1", ends), fixed = TRUE))
      expect_lte(v[1], v[2], label = lab)
    } else {
      nm <- inp_of[[id]][1]
      v <- vapply(side, function(sd) num(D$sliders$values[[sd]][[nm]]), 0)
      expect_lte(v[[1]], v[[2]], label = lab)
    }
    rtl <- grepl(sprintf('data-panel="%s" data-id="%s" aria-describedby="%s-%s-tip %s-%s-bsz-tip %s-%s-rjkdc-tip" dir="rtl"', panel, id, panel, id, panel, id, panel, id), li, fixed = TRUE)
    expect_identical(rtl, side[2] == panel, label = paste(lab, "direction"))
    if (rtl) rtl_ids[[panel]] <- c(rtl_ids[[panel]], id)
  }
  # the flips this rule makes: the BSZ panel's W, a, q, r and two minor dials run right to left,
  # the JR panel's D, f, C, H, the minor switch and the real-estate dial
  expect_identical(rtl_ids$bsz, c("base_list", "avoidance", "litigation_survival", "discount_rate", "noncitizens", "asset_sales"))
  expect_identical(rtl_ids$rjkdc, c("confirmed_departures", "income_loss_share", "income_level", "horizon", "minor_inputs", "real_estate"))
  # the data file: every input in the bridge's order (the switch stands for three of them),
  # the argument each moves, both vectors, and the three the switch covers
  bi <- bridge_inputs(read_contracts(root))
  expect_identical(vapply(D$sliders$inputs, `[[`, "", "id"), ids)
  expect_identical(unlist(D$sliders$minor), EXPLORER_MINOR)
  # the walk button's path is the dial path's order
  expect_identical(unlist(D$sliders$path), DIAL_PATH_ORDER)
  expect_identical(lapply(D$sliders$inputs, function(x) unlist(x$input)), unname(step_inputs[ids]))
  num <- function(z) if (identical(z, "Inf")) Inf else z
  for (nm in names(bi$sup)) {
    expect_equal(num(D$sliders$values$bsz[[nm]]), bi$sup[[nm]], tolerance = 1e-14, label = paste("bsz", nm))
    expect_equal(num(D$sliders$values$rjkdc[[nm]]), bi$rauh[[nm]], tolerance = 1e-14, label = paste("rjkdc", nm))
  }
  expect_equal(vapply(D$sliders$horizons, num, 0), SLIDER_HORIZONS)
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  expect_null(D$sliders$revision)
})

test_that("the sliders' ends are the two analyses, and the departures dial stops at the BSZ four", {
  k <- read_contracts(root); bi <- bridge_inputs(k)
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  ids <- bridge_steps()$step_id
  all_at <- function(p) stats::setNames(as.list(rep(p, length(ids))), ids)
  far <- stats::setNames(as.list(vapply(ids, slider_max, 0L)), ids)
  expect_equal(slider_value(bi, "bsz", all_at(0)), eb$bsz_model, tolerance = 1e-12)
  expect_equal(slider_value(bi, "rjkdc", all_at(0)), eb$jr_model, tolerance = 1e-12)
  expect_equal(slider_value(bi, "bsz", far), eb$jr_model, tolerance = 1e-12)
  expect_equal(slider_value(bi, "rjkdc", far), eb$bsz_model, tolerance = 1e-12)
  # the far positions are the other analysis's values exactly; the horizon steps through the settings
  xf <- slider_inputs(bi$sup, bi$rauh, far, bi$ladder)
  for (nm in names(bi$rauh)) expect_identical(xf[[nm]], bi$rauh[[nm]], label = nm)
  expect_equal(vapply(0:4, function(p) slider_inputs(bi$rauh, bi$sup, list(horizon = p), bi$ladder)$H, 0),
               rev(SLIDER_HORIZONS))
  expect_identical(slider_max("base_list"), 1L); expect_identical(slider_max("confirmed_departures"), 2L)
  expect_identical(slider_max("income_loss_share"), 4L)
  # f at the middle stop of the share-lost dial is halfway between the two rules' f
  fx <- function(p) score_common(slider_inputs(bi$sup, bi$rauh, list(income_loss_share = p), bi$ladder))[["f"]]
  expect_equal(fx(2), (fx(0) + fx(4)) / 2, tolerance = 1e-12)
  # the middle stop of the departures dial in the BSZ panel is the BSZ analysis's own Table 5 row 3
  x1 <- slider_inputs(bi$sup, bi$rauh, list(confirmed_departures = 1), bi$ladder)
  expect_equal(score_common(x1)[["a"]], pick(k$bsz$outputs, "tab5_row3_wealth_tax_revenue"), tolerance = 1e-9)
  expect_equal(score_common(x1)[["X"]], pick(k$bsz$outputs, "tab5_row3_extra_ca_inctax_sales"), tolerance = 1e-9)
  expect_equal(-score_common(x1)[["annual_loss"]], pick(k$bsz$outputs, "tab5_row3_annual_ca_inctax_loss"), tolerance = 1e-9)
  # one numeric input at 1, 2, 3 with the rest at 0: the middle value lies strictly between
  for (panel in c("bsz", "rjkdc")) for (id in c("income_level", "litigation_survival")) {
    v <- vapply(1:3, function(p) slider_value(bi, panel, stats::setNames(list(p), id)), 0)
    expect_true((v[2] - v[1]) * (v[3] - v[2]) > 0, label = paste(panel, id))
  }
})

test_that("every dial symbol in both boxes has one or two words above it (author items 2026-10-15)", {
  ex_html <- read_page(explorer)
  expect_identical(sort(names(DIAL_WORDS)), sort(names(DIAL_SYMBOLS)))
  expect_identical(unname(DIAL_WORDS[EXPLORER_BOXES$revenue$ids]), c("wealth", "departed", "avoidance", "litigation"))
  for (id in names(DIAL_SYMBOLS))
    expect_identical(lengths(regmatches(ex_html, gregexpr(sprintf('<span class="sym-word">%s</span><span class="sym">%s</span>',
                                                                  DIAL_WORDS[[id]], DIAL_SYMBOLS[[id]]), ex_html, fixed = TRUE))), 2L, label = id)
})

test_that("the rate dial: r after H in the loss box, ends 3% and 2.73%, its tips and the box headings' formula tips", {
  ex_html <- read_page(explorer)
  me <- read_csv_plain(file.path(root, "comparison", "export", "r", "meta.csv"))
  mv <- function(key) me$value[me$key == key]
  expect_identical(EXPLORER_BOXES$loss$ids, c("income_loss_share", "income_level", "horizon", "discount_rate"))
  expect_identical(rate_txt(mv("r_bsz")), "3%"); expect_identical(rate_txt(mv("r_jr")), "2.73%")
  for (panel in c("bsz", "rjkdc")) {
    li <- regmatches(ex_html, gregexpr('<li class="sl has-sym" data-id="discount_rate">.*?</li>', ex_html))[[1]][match(panel, c("bsz", "rjkdc"))]
    expect_true(grepl('<span class="sym-word">rate</span><span class="sym">r</span>', li, fixed = TRUE), label = panel)
    expect_true(grepl("r, discount rate. The discount rate that turns a yearly loss into today's dollars.", li, fixed = TRUE), label = panel)
    expect_true(grepl('<span class="sl-end-v">3%</span>', li, fixed = TRUE), label = panel)
    expect_true(grepl('<span class="sl-end-v">2.73%</span>', li, fixed = TRUE), label = panel)
    expect_true(grepl("Kind: scenario.</span>", li, fixed = TRUE), label = panel)
    expect_true(grepl("($1 a year for ever is worth $36.6). Kind: derived.</span>", li, fixed = TRUE), label = panel)
    # each box heading shows its name only; the formula (and, for the loss box, the A(H, r)
    # gloss) is in the heading's tip (author item 2026-10-15)
    expect_true(grepl(sprintf(paste0('<p class="box-eq"><span class="info box-name" tabindex="0" aria-describedby="%1$s-loss-eq">',
                                     '<span id="%1$s-loss-head">Income tax lost</span><span class="info-tip" role="tooltip" id="%1$s-loss-eq">',
                                     '<span class="tip-eq">Income tax lost = f &times; C &times; A(H, r)</span>',
                                     '<span class="tip-line">A(H, r): what $1 a year for H years is worth today at rate r.</span></span></span></p>'), panel),
                      ex_html, fixed = TRUE), label = paste(panel, "loss heading"))
    expect_true(grepl(sprintf(paste0('<span id="%1$s-revenue-head">Wealth tax collected</span><span class="info-tip" role="tooltip" id="%1$s-revenue-eq">',
                                     '<span class="tip-eq">Wealth tax collected = 5%% &times; (W &minus; D) &times; (1 &minus; a) &times; q</span></span>'), panel),
                      ex_html, fixed = TRUE), label = paste(panel, "revenue heading"))
  }
  expect_false(grepl("ah-tip", ex_html, fixed = TRUE))
  # the H dial's tips name no rate, except the BSZ end's worked value of A(H, r) at the BSZ rate
  # (review 005, U-14): "$1 a year for 5 years is worth $4.6 at 3%", with A_5 from meta.csv
  h <- regmatches(ex_html, gregexpr('<li class="sl has-sym" data-id="horizon">.*?</li>', ex_html))[[1]]
  expect_length(h, 2L)
  worked <- sprintf("$1 a year for 5 years is worth $%s at %s.", formatC(mv("A_5"), format = "f", digits = 1), rate_txt(mv("r_bsz")))
  expect_equal(mv("A_5"), annuity(mv("r_bsz"), 5), tolerance = 1e-12)
  for (x in h) {
    expect_true(grepl(worked, x, fixed = TRUE))
    expect_false(grepl("%", gsub(worked, "", x, fixed = TRUE), fixed = TRUE))
  }
})

test_that("model.js returns the R values on every slider mix of the sample, to 1e-9", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "node is not on PATH: model.js parity not checked")
  ss <- read_csv_plain(file.path(root, "comparison", "export", "r", "slider_sample.csv"))
  expect_equal(nrow(ss), 600)
  pos_cols <- setdiff(names(ss), c("panel", "draw", "value"))
  tmp <- tempfile(fileext = ".json")
  writeLines(jsonlite::toJSON(lapply(seq_len(nrow(ss)), function(i)
    list(panel = ss$panel[i], pos = as.list(ss[i, pos_cols]))), auto_unbox = TRUE), tmp)
  js <- tempfile(fileext = ".js")
  writeLines(c(
    "const path = require('path'), fs = require('fs');",
    "globalThis.window = globalThis;",
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "assets", "comparison-data.js"), auto_unbox = TRUE)),
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "comparison", "site", "explorer", "model.js"), auto_unbox = TRUE)),
    sprintf("const rows = JSON.parse(fs.readFileSync(%s, 'utf8'));", jsonlite::toJSON(tmp, auto_unbox = TRUE)),
    "const S = window.__BRIDGE__.sliders, M = window.ComparisonModel;",
    "console.log(JSON.stringify(rows.map(r => M.panelValue(S, r.panel, r.pos).value)));"), js)
  out <- system2(node, js, stdout = TRUE)
  v <- unlist(jsonlite::fromJSON(paste(out, collapse = "")))
  expect_equal(length(v), nrow(ss))
  expect_lt(max(abs(v - ss$value)), 1e-9)
  # the two panels' starting values and far ends, on the page, are the two analyses' ends
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  expect_lt(abs(v[ss$panel == "bsz" & ss$draw == 1] - eb$bsz_model), 1e-9)
  expect_lt(abs(v[ss$panel == "rjkdc" & ss$draw == 1] - eb$jr_model), 1e-9)
  expect_lt(abs(v[ss$panel == "bsz" & ss$draw == 2] - eb$jr_model), 1e-9)
  expect_lt(abs(v[ss$panel == "rjkdc" & ss$draw == 2] - eb$bsz_model), 1e-9)
})

test_that("the headline is the two main estimates; the bridge's two ends under (b) are those quantities", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  # the JR headline on the comparison's pages is the exact expectation of the authors' model
  # (author decision 2026-10-15); the paper's seeded run stays in footnote 1
  rj <- eb$jr_own
  rj_run <- ep$contract_value[ep$endpoint_id == "rauh_nber_npv"]
  rj_printed <- ep$printed_value[ep$endpoint_id == "rauh_nber_npv"]
  # the two values, pinned: BSZ net total over 5 years; JR NBER exact mean NPV
  expect_equal(round(eb$bsz_model, 4), 106.7960)   # 5 years at 3%, as on the BSZ overview
  expect_equal(round(rj, 2), -38.98)
  expect_identical(money(rj, 1), "\u2212$39.0B")
  expect_equal(round(rj_run, 3), -38.886)
  expect_equal(round(rj_run, 1), rj_printed)   # printed -38.9
  # under (b) the two ends are the BSZ net constructed from Table 5 row 1 and the analytic
  # expectation of the NBER Monte Carlo, which the seeded run approximates
  expect_equal(eb$bsz_model, ep$value[ep$endpoint_id == "bsz_net_constructed"])
  expect_equal(eb$jr_own, ep$value[ep$endpoint_id == "rauh_nber_npv"])
  expect_lt(abs(eb$jr_model - eb$jr_own), 1e-9)
  expect_equal(round(eb$jr_own, 2), -38.98)
  # the Shapley steps between them add up
  br <- read_csv_plain(file.path(root, "comparison", "export", "r", "bridge.csv"))
  b <- br[br$horizon_setting == "own" & br$output == "b", ]
  expect_equal(sum(b$shapley), eb$jr_model - eb$bsz_model,
               tolerance = 1e-9)
  for (p in pages) {
    html <- read_page(p)
    expect_true(grepl(sprintf('id="hl-bsz">%s<', money(eb$bsz_model, 1)), html, fixed = TRUE), label = p)
    expect_true(grepl(sprintf('id="hl-rjkdc">%s<', money(rj, 1)), html, fixed = TRUE), label = p)
    # footnote 1 keeps the provenance of the paper's printed figure
    expect_true(grepl(sprintf("The paper prints %s, the average of one seeded run of 100,000 draws. The exact average of the same formula is %s, used throughout this page",
                              money(rj_printed, 1), money(rj, 2)), html, fixed = TRUE), label = paste(p, "footnote 1"))
    expect_false(grepl("the header number", html, fixed = TRUE), label = p)
    expect_true(grepl("BSZ main estimate<sup>(<a [^>]*>)?1(</a>)?</sup>", html), label = p)
    expect_true(grepl("JR main estimate<sup>(<a [^>]*>)?1(</a>)?</sup>", html), label = p)
    expect_false(grepl("the gap on the common output", html, fixed = TRUE), label = p)
  }
  # the explorer reads the same values from the data file: the headline object, and the
  # first and last bars of the default view (output (b), Shapley, own horizon)
  txt <- read_page(file.path(root, "assets", "comparison-data.js"))
  D <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^{]*", "", txt)), simplifyVector = FALSE)
  expect_equal(D$headline$bsz, eb$bsz_model)
  expect_equal(D$headline$rjkdc, rj)
  expect_equal(D$headline$rjkdc_printed, rj_printed)
  # the JR panel head and its "With these sliders" line read the same number at the start
  ex_html <- read_page(explorer)
  expect_true(grepl(sprintf('id="ph-rjkdc-main">%s<', money(rj, 1)), ex_html, fixed = TRUE))
  expect_true(grepl(sprintf('id="now-rjkdc" aria-live="polite">%s<', money(eb$jr_model, 1)), ex_html, fixed = TRUE))
  expect_false(grepl("seeded run prints", ex_html, fixed = TRUE))
  B <- D$series$own$b$shapley
  expect_equal(B[[1]]$id, "bsz"); expect_equal(B[[1]]$value, eb$bsz_model)
  expect_equal(B[[length(B)]]$id, "nber"); expect_equal(B[[length(B)]]$value, eb$jr_model)
  expect_equal(D$headline$rjkdc_end_b, eb$jr_model)
  expect_null(D$headline$jr_rate_gap)
  # neither the GGSS headline nor the March 2026 version is an end on the pages
  ids <- vapply(B, `[[`, "", "id")
  expect_false(any(c("ggss", "ggss_rounding", "rauh") %in% ids))
})

test_that("every relative link on both pages resolves to a file in the repo (sub-sites may be pending)", {
  for (p in pages) {
    html <- read_page(p)
    refs <- regmatches(html, gregexpr('(href|src)="[^"#]+"', html))[[1]]
    refs <- unique(sub('^(href|src)="', "", sub('"$', "", refs)))
    refs <- refs[!grepl("^(https?:|mailto:)", refs)]
    refs <- sub("\\?.*$", "", refs)   # the data file's cache-busting ?v=<hash>
    for (r in refs) {
      f <- file.path(dirname(p), r)
      if (grepl("/$", r)) f <- file.path(f, "index.html")
      # rjkdc-analysis/site/ is built in parallel on another branch
      if (grepl("rjkdc-analysis/site/$", r) && !file.exists(f)) next
      expect_true(file.exists(f), label = paste(basename(dirname(p)), r))
    }
  }
})

test_that("the explorer's quantities section: the subtitle and the survey button, no table (author request 2026-10-15)", {
  html <- read_page(explorer)
  at <- function(x) regexpr(x, html, fixed = TRUE)[[1]]
  expect_true(grepl('<h3 id="q-title">But what are the actual quantities?</h3>', html, fixed = TRUE))
  expect_gt(at('<section class="quantities"'), at('<div class="pseudo-eq apply-eq"'))
  expect_lt(at('<section class="quantities"'), at('<details class="fold notes" id="notes-estimates">'))
  # the subtitle and the share line below follow the survey's approved wording since 2026-10-17
  # (author request 2026-10-17, survey wording carried to the pages): the survey asks which of two
  # values is more credible, not for a ranking or for the respondent's own values
  expect_true(grepl("Most of these are empirical quantities, and none should depend on whether one supports\n    or opposes a wealth tax. H and r are scenario choices. An expert should be able to judge which of\n    the two values is more credible.", html, fixed = TRUE))
  expect_false(grepl("appraise each value from more to less", html, fixed = TRUE))
  expect_false(grepl('<table class="q-table">', html, fixed = TRUE))
  expect_true(grepl('<p class="q-cta">', html, fixed = TRUE))
  # the label asks which value is more credible (author, 2026-10-17; pilot 008: "what do you
  # think these values are?" led respondents to expect to type their own numbers)
  expect_true(grepl("Take the survey: which values are more credible?", html, fixed = TRUE))
  expect_false(grepl("Take the survey: what do you think these values are?", html, fixed = TRUE))
  expect_true(grepl("Share this survey with people you think have expertise in this area, to learn which values they find more credible.", html, fixed = TRUE))
  expect_false(grepl("to learn what they think these values are", html, fixed = TRUE))
  # the button's links are the explorer entry point's pair: with none yet it is shown disabled
  pair <- survey_pair(read_survey_links(root), "explorer")
  if (length(pair)) expect_true(grepl(sprintf('data-entry="explorer" data-links="%s"', paste(pair, collapse = " ")), html, fixed = TRUE))
  else expect_true(grepl('<span class="q-survey is-off" aria-disabled="true">', html, fixed = TRUE))
})

test_that("the quantities table (on the overview's differences fold): one row per group of dials, credibility column only when switched on", {
  page <- read_page(file.path(root, "index.html"))
  # the table and the line under it, nothing else of the page
  html <- regmatches(page, regexpr('<table class="q-table">.*?<p class="q-foot">.*?</p>', page))
  # the four columns
  head <- regmatches(html, regexpr("<thead><tr>.*?</tr></thead>", html, perl = TRUE))
  th <- regmatches(head, gregexpr("(?<=<th>)[^<]*(?=</th>)", head, perl = TRUE))[[1]]
  expect_identical(th, esc(c("Dial", "The BSZ analysis's value and why", "The JR analysis's value and why",
                             if (SHOW_CREDIBILITY) "Which is more credible (the author of this OPA)")))
  # one row per group the author assesses together (author request 2026-10-15), covering every
  # dial once: W; D, a and f; q; C; H and r; the three minor inputs
  expect_identical(QUANTITY_GROUPS, list(
    base_list = "base_list",
    departures_share = c("confirmed_departures", "avoidance", "income_loss_share"),
    litigation_survival = "litigation_survival", income_level = "income_level",
    horizon_rate = c("horizon", "discount_rate"),
    minor_inputs = c("noncitizens", "real_estate", "asset_sales")))
  expect_setequal(unlist(QUANTITY_GROUPS, use.names = FALSE),
                  c(unlist(lapply(EXPLORER_BOXES, `[[`, "ids"), use.names = FALSE), EXPLORER_MINOR))
  rows <- regmatches(html, gregexpr('<tr data-id="[a-z_]+">.*?</tr>', html))[[1]]
  gids <- sub('^<tr data-id="([a-z_]+)">.*$', "\\1", rows)
  expect_identical(gids, names(QUANTITY_GROUPS))
  # the credibility column is the author's file, one line per group; today every row is "Not yet assessed"
  cred <- read_csv_plain(file.path(root, "comparison", "data", "author-credibility.csv"))
  expect_identical(names(cred), c("group_id", "dials", "assessment", "note", "date"))
  expect_true(all(cred$assessment %in% CREDIBILITY_LEVELS))
  expect_true(all(cred$assessment == "Not yet assessed"))
  cell <- function(r, k) regmatches(r, gregexpr("<td[^>]*>.*?</td>", r))[[1]][k]
  txt <- function(x) gsub("&#39;", "'", gsub("&amp;", "&", gsub("<[^>]*>", "", x), fixed = TRUE), fixed = TRUE)
  # hidden until the author's assessments are in (author request 2026-10-15): three cells a row
  for (i in seq_along(rows))
    if (SHOW_CREDIBILITY) expect_identical(txt(cell(rows[i], 4)), cred$assessment[cred$group_id == gids[i]], label = gids[i])
    else expect_identical(length(regmatches(rows[i], gregexpr("<td[^>]*>", rows[i]))[[1]]), 3L, label = gids[i])
  expect_identical(grepl('class="q-cred"', html, fixed = TRUE), SHOW_CREDIBILITY)
  # each analysis's cell has one line per dial of the group; every line within 25 words (plus the
  # symbol lead in a group), starts with the value its dial's end prints, and ends with its Kind
  inp <- read_csv_plain(file.path(root, "comparison", "export", "r", "inputs.csv"))
  bi <- bridge_inputs(read_contracts(root))
  for (i in seq_along(rows)) for (k in 2:3) {
    ids <- QUANTITY_GROUPS[[gids[i]]]
    lines <- regmatches(cell(rows[i], k), gregexpr('<span class="q-line" data-id="[a-z_]+">.*?</span>(?=<span class="q-line"|</td>)', cell(rows[i], k), perl = TRUE))[[1]]
    expect_identical(sub('^<span class="q-line" data-id="([a-z_]+)">.*$', "\\1", lines), ids, label = paste(gids[i], k))
    for (j in seq_along(ids)) {
      body <- sub('^<span class="q-line" data-id="[a-z_]+">(<i>[^<]*</i> <span class="q-word">[^<]*</span> |<span class="q-word">[^<]*</span> )?', "",
                  if (length(ids) > 1) lines[j] else lines[j])
      x <- txt(body)
      expect_lte(length(strsplit(x, " ")[[1]]), 25, label = paste(ids[j], k, x))
      expect_true(grepl("Kind: (data|research|guesswork|scenario|derived|guesswork on data)\\.$", x), label = paste(ids[j], k))
      dt <- dial_texts(inp, ids[j], bi)
      expect_true(startsWith(x, paste0(if (k == 2) dt$bsz else dt$rjkdc, ".")), label = paste(ids[j], k))
    }
  }
  # the line under the table links to the report's differences table
  expect_true(grepl("Each value's full source is in the <a href=\"comparison/site/repro.html#the-disputed-inputs\">report's table of differences</a>.", html, fixed = TRUE))
})

test_that("the overview's \"The differences\" fold holds the quantities table; the explorer links the survey instead", {
  ex <- read_page(explorer); ov <- read_page(file.path(root, "index.html"))
  fold <- regmatches(ov, regexpr('<details class="fold" id="differences">.*?</details>', ov))
  expect_true(grepl('<table class="q-table">', fold, fixed = TRUE))
  expect_true(grepl('href="comparison/site/repro.html#the-disputed-inputs"', fold, fixed = TRUE))
  expect_false(grepl('<table class="q-table">', ex, fixed = TRUE))
  # the same survey button sits under the table on the overview (author request 2026-10-15)
  btn <- function(h) regmatches(h, regexpr('<p class="q-cta">.*?</p>', h))
  expect_true(grepl('<p class="q-cta">', fold, fixed = TRUE))
  expect_identical(btn(ov), btn(ex))
  # a "Copy link" button next to the share line on both pages, and the share page that draws a
  # form at random (author request 2026-10-15), now from the share entry point's pair (plan 4.3)
  pair <- survey_pair(read_survey_links(root), "share")
  if (length(pair)) {
    for (h in list(ov, ex)) expect_true(grepl(sprintf('<button type="button" class="q-copy" data-url="%s">Copy link</button>', SURVEY_SHARE_URL), h, fixed = TRUE))
    sp <- read_page(file.path(root, "comparison", "site", "survey", "index.html"))
    for (u in pair) expect_true(grepl(u, sp, fixed = TRUE))
    expect_true(grepl('var arm = Math.random() < 0.5 ? "treatment" : "control";', sp, fixed = TRUE))
    expect_true(grepl('location.replace(L[arm === "treatment" ? 1 : 0]);', sp, fixed = TRUE))
  }
})

test_that("an assessment in the author's file shows in the table when the column is on, and an unknown one stops the build", {
  f <- file.path(root, "comparison", "data", "author-credibility.csv")
  old <- readLines(f); on.exit(writeLines(old, f), add = TRUE)
  writeLines(sub("^horizon_rate,H r,Not yet assessed,,$", "horizon_rate,H r,About equally credible,test note,2026-10-15", old), f)
  s <- render_site(root)
  if (SHOW_CREDIBILITY)
    expect_true(grepl('<tr data-id="horizon_rate">.*?<td data-label="Which is more credible \\(the author of this OPA\\)" class="q-cred">About equally credible. test note \\(2026-10-15\\)</td></tr>', s$html))
  else expect_false(grepl("About equally credible. test note", s$html, fixed = TRUE))
  writeLines(sub("^horizon_rate,H r,Not yet assessed,,$", "horizon_rate,H r,Probably BSZ,,", old), f)
  expect_error(render_site(root))
})

test_that("the overview's differences fold opens with two smaller survey buttons: take it and share it", {
  ov <- read_page(file.path(root, "index.html"))
  fold <- regmatches(ov, regexpr('<details class="fold" id="differences">.*?</details>', ov))
  # the overview's buttons join the explorer entry point (author decision 2026-10-17)
  urls <- survey_pair(read_survey_links(root), "explorer")
  if (length(urls)) {
    mini <- regmatches(fold, regexpr('<p class="q-mini">.*?</p>', fold))
    expect_length(mini, 1)
    expect_true(grepl(sprintf('data-entry="explorer" data-links="%s"', paste(urls, collapse = " ")), mini, fixed = TRUE))
    expect_true(grepl(">Take the survey</a>", mini, fixed = TRUE))
    expect_true(grepl(sprintf('data-url="%s">Share the survey: copy link</button>', SURVEY_SHARE_URL), mini, fixed = TRUE))
    # above the table, below the fold's first paragraph
    expect_lt(regexpr('<p class="q-mini">', fold), regexpr('<table class="q-table">', fold))
  } else expect_false(grepl('class="q-mini"', fold, fixed = TRUE))
  expect_false(grepl("crosswalk", fold, fixed = TRUE))
})

# The survey experiment (comparison/survey/PRE-ANALYSIS-PLAN.md, 4.2, 4.3 and 8;
# feedback/005-2026-10-16-explorer-ux/03-landing-survey-plan.md, B1, B3 and B5).
share_page <- file.path(root, "comparison", "site", "survey", "index.html")
# every survey link on a page: its entry point and its links
survey_links_on <- function(html) {
  m <- regmatches(html, gregexpr('<a [^>]*data-entry="[a-z]+" data-links="[^"]*"[^>]*>', html))[[1]]
  data.frame(entry = sub('.*data-entry="([a-z]+)".*', "\\1", m),
             links = sub('.*data-links="([^"]*)".*', "\\1", m), stringsAsFactors = FALSE)
}

test_that("survey-links.csv lists the six forms, one per entry point and arm", {
  sv <- read_survey_links(root)
  expect_identical(names(sv), c("entry", "arm", "url"))
  expect_setequal(paste(sv$entry, sv$arm), as.vector(outer(SURVEY_ENTRIES, SURVEY_ARMS, paste)))
  expect_true(all(grepl("^https://docs[.]google[.]com/forms/", sv$url)))
  for (e in SURVEY_ENTRIES) expect_length(survey_pair(sv, e), 2)
})

test_that("every survey link carries exactly two links, its own entry point's pair, control first", {
  sv <- read_survey_links(root)
  ex <- survey_links_on(read_page(explorer))
  ov <- survey_links_on(read_page(file.path(root, "index.html")))
  # the explorer: the landing panel's button and the lower button; the overview: its two buttons,
  # both in the explorer entry point (author decision 2026-10-17)
  expect_identical(ex$entry, c("landing", "explorer"))
  expect_identical(ov$entry, c("explorer", "explorer"))
  for (d in list(ex, ov)) for (i in seq_len(nrow(d))) {
    l <- strsplit(d$links[i], " ", fixed = TRUE)[[1]]
    expect_length(l, 2)
    expect_identical(l, survey_pair(sv, d$entry[i]), label = d$entry[i])
  }
  # each draws its arm at the click with probability 1/2 (plan 4.2)
  for (h in list(read_page(explorer), read_page(file.path(root, "index.html")))) {
    expect_true(grepl('var arm = Math.random() < 0.5 ? "treatment" : "control";', h, fixed = TRUE))
    expect_true(grepl('a.href = L[arm === "treatment" ? 1 : 0];', h, fixed = TRUE))
  }
  # opened without a click, a survey link goes to the share page, which draws, never to one form
  for (h in list(read_page(explorer), read_page(file.path(root, "index.html")))) {
    a <- regmatches(h, gregexpr('<a [^>]*data-entry="[a-z]+"[^>]*>', h))[[1]]
    expect_true(all(grepl(sprintf('href="%s"', SURVEY_SHARE_URL), a, fixed = TRUE)))
  }
})

test_that("the share page draws from the share pair; without JavaScript it opens the share control form", {
  pair <- survey_pair(read_survey_links(root), "share")
  sp <- read_page(share_page)
  expect_true(grepl(sprintf('If nothing happens, <a href="%s">open it here</a>.', pair[1]), sp, fixed = TRUE))
  expect_true(grepl(sprintf('var L = ["%s","%s"], entry = "share";', pair[1], pair[2]), sp, fixed = TRUE))
  # no other form address on the page
  forms <- regmatches(sp, gregexpr("https://docs[.]google[.]com/forms/[^\"' ]+", sp))[[1]]
  expect_setequal(unique(forms), pair)
})

test_that("Copy link and the share text carry the share page's address, never a form's", {
  expect_false(grepl("docs.google.com", SURVEY_SHARE_URL, fixed = TRUE))
  for (p in c(explorer, file.path(root, "index.html"))) {
    h <- read_page(p)
    urls <- sub('.*data-url="([^"]*)".*', "\\1", regmatches(h, gregexpr('<button type="button" class="q-copy[^"]*" data-url="[^"]*"', h))[[1]])
    expect_gt(length(urls), 0)
    expect_true(all(urls == SURVEY_SHARE_URL), label = p)
    # the share line's text names no form address either
    sh <- regmatches(h, gregexpr('<p class="q-(share|mini)">.*?</p>', h))[[1]]
    expect_false(any(grepl("docs.google.com", gsub('data-links="[^"]*"', "", sh), fixed = TRUE)), label = p)
  }
})

test_that("the landing panel: on the explorer only, its text, its two buttons, shown once per browser", {
  ex <- read_page(explorer); ov <- read_page(file.path(root, "index.html"))
  panel <- regmatches(ex, regexpr('<div id="landing" role="dialog".*?\n</div>', ex))
  expect_length(panel, 1)
  expect_true(grepl('aria-modal="true" aria-labelledby="landing-h"', panel, fixed = TRUE))
  expect_true(grepl('<h2 id="landing-h">Before you look at the results</h2>', panel, fixed = TRUE))
  expect_true(grepl(paste("Two analyses of Proposition 40 reach very different numbers. Before you see why, we",
                          "invite you to judge which of two proposed values for each key input is more credible.",
                          "It takes 5 to 10 minutes. You can also take it later from the button on this page."),
                    panel, fixed = TRUE))
  expect_true(grepl('target="_blank" rel="noopener">Take the survey first</a>', panel, fixed = TRUE))
  expect_true(grepl('<button type="button" class="landing-skip">Skip to the results</button>', panel, fixed = TRUE))
  # the body's first element, and the class that shows it set in the head, before the first paint
  expect_true(grepl('<body class="pg pg-explorer">\n<div id="landing"', ex, fixed = TRUE))
  head <- regmatches(ex, regexpr("<head>.*?</head>", ex))
  expect_lt(regexpr('classList.add("has-landing")', head, fixed = TRUE), regexpr("<style>", head, fixed = TRUE))
  expect_true(grepl('localStorage.getItem("p40.landing") === "seen"', head, fixed = TRUE))
  expect_true(grepl('localStorage.setItem("p40.landing", "seen")', ex, fixed = TRUE))
  # Escape dismisses it; the page behind is blurred and does not scroll
  expect_true(grepl('e.key === "Escape"', ex, fixed = TRUE))
  expect_true(grepl("html.has-landing body > :not(#landing) { filter: blur(6px); }", ex, fixed = TRUE))
  expect_true(grepl("html.has-landing { overflow: hidden; }", ex, fixed = TRUE))
  expect_true(grepl("max-width: 30em", regmatches(ex, regexpr("\n  [.]landing-box [{][^}]*[}]", ex)), fixed = TRUE))
  expect_true(grepl("@media (prefers-reduced-motion: reduce) { * { transition: none !important; } }", ex, fixed = TRUE))
  # its script does not depend on the data file: it runs before it loads
  expect_lt(regexpr('var LP = document.getElementById("landing")', ex, fixed = TRUE),
            regexpr('<script src="../../../assets/comparison-data.js', ex, fixed = TRUE))
  # the overview has no panel
  expect_false(grepl('id="landing"', ov, fixed = TRUE))
  expect_false(grepl("has-landing", ov, fixed = TRUE))
})

test_that("the texts a respondent meets before a form name neither analysis", {
  names_re <- "BSZ|JR|RJKDC|Saez|Zucman|Boll|Jaros|Rauh|Kearney|supporting|opposing"
  ex <- read_page(explorer)
  panel <- regmatches(ex, regexpr('<div id="landing" role="dialog".*?\n</div>', ex))
  shown <- function(h) gsub("<[^>]+>", " ", h)
  expect_false(grepl(names_re, shown(panel)))
  expect_false(grepl(names_re, SURVEY_LABEL))
  expect_false(grepl(names_re, paste(unlist(LANDING), collapse = " ")))
  for (h in list(ex, read_page(file.path(root, "index.html")))) {
    links <- regmatches(h, gregexpr('<a [^>]*data-entry="[a-z]+"[^>]*>[^<]*</a>', h))[[1]]
    expect_false(any(grepl(names_re, shown(links))))
  }
  sp <- read_page(share_page)
  expect_false(grepl(names_re, shown(gsub("<script>.*?</script>", "", sp))))
})

test_that("the draw count: no request while draws_url is empty; with it, one beacon per draw, entry and arm only", {
  cf <- file.path(root, "comparison", "data", "survey-config.csv")
  expect_identical(read_survey_config(root)$draws_url, "")
  for (h in list(read_page(explorer), read_page(file.path(root, "index.html")), read_page(share_page))) {
    expect_false(grepl("sendBeacon", h, fixed = TRUE))
    expect_false(grepl("DRAWS_URL", h, fixed = TRUE))
  }
  expect_false(grepl("Survey links.", read_page(explorer), fixed = TRUE))
  old <- readLines(cf); on.exit(writeLines(old, cf), add = TRUE)
  writeLines(c("key,value", "draws_url,https://script.google.com/macros/s/TEST/exec"), cf)
  s <- render_site(root); sp <- survey_share_page(root)
  beacon <- 'try { navigator.sendBeacon(DRAWS_URL + "?entry=" + entry + "&arm=" + arm); } catch (e) {}'
  for (h in list(s$explorer, s$html, sp)) {
    expect_true(grepl('var DRAWS_URL = "https://script.google.com/macros/s/TEST/exec";', h, fixed = TRUE))
    expect_identical(lengths(regmatches(h, gregexpr("sendBeacon(", h, fixed = TRUE))), 1L)
    expect_true(grepl(beacon, h, fixed = TRUE))
    expect_false(grepl("document.cookie", h, fixed = TRUE))
  }
  # right after the draw: in drawSurvey() after the arm, on the share page before it leaves
  expect_lt(regexpr("var arm = Math.random()", sp, fixed = TRUE), regexpr("sendBeacon", sp, fixed = TRUE))
  expect_lt(regexpr("sendBeacon", sp, fixed = TRUE), regexpr("location.replace", sp, fixed = TRUE))
  expect_true(grepl("This page records, without any identifying data, that a survey link was opened and which form it drew.", s$explorer, fixed = TRUE))
  writeLines(c("key,value", "draws_url,http://example.com/x?y"), cf)
  expect_error(read_survey_config(root))
})

test_that("a missing pair turns its button off and, for the landing pair, drops the panel", {
  f <- file.path(root, "comparison", "data", "survey-links.csv")
  old <- readLines(f); on.exit(writeLines(old, f), add = TRUE)
  writeLines(old[!grepl("^(landing|explorer),treatment,", old)], f)
  s <- render_site(root)
  expect_false(grepl('id="landing"', s$explorer, fixed = TRUE))
  expect_false(grepl('classList.add("has-landing")', s$explorer, fixed = TRUE))
  expect_true(grepl(sprintf('<span class="q-survey is-off" aria-disabled="true">%s (opening soon)</span>', SURVEY_LABEL), s$explorer, fixed = TRUE))
  expect_false(grepl('class="q-mini"', s$html, fixed = TRUE))
  # a row outside the six stops the build
  writeLines(c(old, "other,control,https://example.com/form"), f)
  expect_error(render_site(root))
})
