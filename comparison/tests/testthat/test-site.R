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

test_that("both pages carry the pseudo-equation: the eight dial-path terms in dial order, BSZ to JR", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  dp <- read_csv_plain(file.path(root, "comparison", "export", "r", "dial_path.csv"))
  expect_equal(eb$bsz_model + sum(dp$change), eb$rauh_model, tolerance = 1e-9)
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  me <- read_csv_plain(file.path(root, "comparison", "export", "r", "meta.csv"))
  r3 <- pct(me$value[me$key == "r_common"])
  # the JR rate gap note: the authors' headline, the draw range and the gap, from the exports
  gap_note <- sprintf(
    "The JR analysis's own headline is %s: the authors draw the discount rate at random between %s and %s and average, which is worth about %s more than one %s rate.",
    money(ep$contract_value[ep$endpoint_id == "rauh_nber_npv"], 1), pct(me$value[me$key == "r_min_jr"], 1),
    pct(me$value[me$key == "r_max_jr"], 1), money(eb$jr_rate_gap, 1), r3)
  for (p in pages) {
    html <- read_page(p)
    expect_true(grepl('<div class="pseudo-eq" role="img"', html, fixed = TRUE), label = p)
    eq <- regmatches(html, regexpr('<div class="pseudo-eq".*?</div>', html))
    # each label is the dial's title followed by its symbol, e.g. "(q)"; under it the running value
    pins <- vapply(seq_len(nrow(dp)), function(i) sprintf(
      '<span class="term" data-step="%d"><b>%s</b><small>%s</small><span class="run">to %s</span></span>',
      i, money(abs(dp$change[i]), 1),
      if (dp$step_id[i] == "minor_inputs") dp$title[i] else paste0(dp$title[i], " (", dp$symbol[i], ")"),
      money(dp$to[i], 1)), "")
    at <- vapply(pins, function(x) regexpr(x, eq, fixed = TRUE)[[1]], 0)
    expect_true(all(at > 0), label = paste(p, "terms"))
    expect_true(all(diff(at) > 0), label = paste(p, "dial order"))
    # BSZ at the left, JR at the right
    expect_lt(regexpr("<small>BSZ estimate</small>", eq, fixed = TRUE)[[1]], at[1])
    expect_gt(max(gregexpr("JR estimate", eq, fixed = TRUE)[[1]]), at[length(at)])
    # the printed end is the JR end at one 3% rate, and the gap note sits under the equation
    expect_true(grepl(sprintf('<b>%s</b><small>JR estimate at one %s rate</small>', money(eb$rauh_model, 1), r3), eq, fixed = TRUE), label = p)
    expect_true(grepl(sprintf('</div>\n<p class="eq-note eq-gap">%s</p>', gap_note), html, fixed = TRUE), label = p)
    # the draw range appears only inside the gap note, and no claim of an exact JR match is left
    rest <- gsub(gap_note, "", html, fixed = TRUE)
    for (x in c("1.5%", "4.5%")) expect_false(grepl(x, rest, fixed = TRUE), label = paste(p, x))
    expect_false(grepl("exact (mean|average) of the authors' Monte Carlo", html), label = p)
    # no Shapley numbers or wording on either page
    expect_false(grepl("shapley", html, ignore.case = TRUE), label = p)
  }
  ex_html <- read_page(explorer)
  expect_true(grepl("Move the BSZ panel's dials top to bottom, each to its far end: each term is what that dial changes.", ex_html, fixed = TRUE))
  for (panel in c("bsz", "rjkdc"))
    expect_true(grepl(sprintf('<button type="button" class="reset walk" data-panel="%s">Walk the path</button>', panel), ex_html, fixed = TRUE), label = panel)
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
  expect_true(grepl(money(eb$rauh_model, 2), html, fixed = TRUE))     # the (b) table: the JR end at 3%
  expect_true(grepl(money(eb$jr_rate_gap, 2), html, fixed = TRUE))    # beside the authors' headline, with the gap
  expect_true(grepl(money(ea$rauh_own, 1), html, fixed = TRUE))
  # the explorer's footnote: both ends and the gap on the net fiscal effect, output (b)
  expect_true(grepl(sprintf("The BSZ end is <b>%s</b> and the JR end <b>%s</b>, a gap of <b>%s</b>.",
                            money(eb$bsz_model, 1), money(eb$rauh_model, 1), money(eb$bsz_model - eb$rauh_model, 1)),
                    ex_html, fixed = TRUE))
  # the explorer shows the net fiscal effect only: no output setting, no gross revenue
  # number (the two ends on output (a), its gap, Table 5 row 1), no output (a) in its data file
  expect_false(grepl("data-out=", ex_html, fixed = TRUE))
  for (x in c(money(ea$bsz_model, 1), money(ea$rauh_own, 1), money(ea$bsz_model - ea$rauh_own, 1),
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
      expect_equal(g$value[nrow(g)], e$rauh_model, tolerance = 1e-9,
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
      expect_true(grepl(sprintf('data-id="%s" aria-describedby="%s-%s-tip"', id, panel, id), ex_html, fixed = TRUE), label = paste(panel, id, "describedby"))
    }
  }
  # the JR panel's sliders run right to left, so position 0 sits at the JR end
  expect_equal(length(gregexpr('data-panel="rjkdc" data-id="[a-z_]+" aria-describedby="[a-z_-]+" dir="rtl"', ex_html)[[1]]), length(shown) + 1 + length(EXPLORER_MINOR))
  expect_false(grepl('data-panel="bsz" data-id="[a-z_]+" aria-describedby="[a-z_-]+" dir="rtl"', ex_html))
  # the data file: every input in the bridge's order (the switch stands for three of them),
  # the argument each moves, both vectors, and the three the switch covers
  bi <- bridge_inputs(read_contracts(root))
  expect_identical(vapply(D$sliders$inputs, `[[`, "", "id"), ids)
  expect_identical(unlist(D$sliders$minor), EXPLORER_MINOR)
  # the walk button's path is the dial path's order
  expect_identical(unlist(D$sliders$path), EXPLORER_DIAL_ORDER)
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
  expect_equal(slider_value(bi, "rjkdc", all_at(0)), eb$rauh_model, tolerance = 1e-12)
  expect_equal(slider_value(bi, "bsz", far), eb$rauh_model, tolerance = 1e-12)
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
  expect_lt(abs(v[ss$panel == "rjkdc" & ss$draw == 1] - eb$rauh_model), 1e-9)
  expect_lt(abs(v[ss$panel == "bsz" & ss$draw == 2] - eb$rauh_model), 1e-9)
  expect_lt(abs(v[ss$panel == "rjkdc" & ss$draw == 2] - eb$bsz_model), 1e-9)
})

test_that("the headline is the two main estimates; the bridge's two ends under (b) are those quantities", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  rj <- ep$contract_value[ep$endpoint_id == "rauh_nber_npv"]
  # the two values, pinned: BSZ net total over 5 years; JR NBER mean NPV (seeded run)
  expect_equal(round(eb$bsz_model, 4), 106.7960)   # 5 years at 3%, as on the BSZ overview
  expect_equal(round(rj, 3), -38.886)
  expect_equal(round(rj, 1), ep$printed_value[ep$endpoint_id == "rauh_nber_npv"])   # printed -38.9
  # under (b) the two ends are the BSZ net constructed from Table 5 row 1 and the JR inputs at
  # one 3% rate; the NBER expectation is that JR end less the JR rate gap
  expect_equal(eb$bsz_model, ep$value[ep$endpoint_id == "bsz_net_constructed"])
  expect_equal(eb$rauh_own, ep$value[ep$endpoint_id == "rauh_nber_npv"])
  expect_equal(eb$rauh_model, ep$value[ep$endpoint_id == "rauh_common_end"])
  expect_equal(round(eb$rauh_own, 2), -38.98)
  expect_equal(round(eb$rauh_model, 2), -32.25)
  # the Shapley steps between them add up
  br <- read_csv_plain(file.path(root, "comparison", "export", "r", "bridge.csv"))
  b <- br[br$horizon_setting == "own" & br$output == "b", ]
  expect_equal(sum(b$shapley), eb$rauh_model - eb$bsz_model,
               tolerance = 1e-9)
  for (p in pages) {
    html <- read_page(p)
    expect_true(grepl(sprintf('id="hl-bsz">%s<', money(eb$bsz_model, 1)), html, fixed = TRUE), label = p)
    expect_true(grepl(sprintf('id="hl-rjkdc">%s<', money(rj, 1)), html, fixed = TRUE), label = p)
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
  B <- D$series$own$b$shapley
  expect_equal(B[[1]]$id, "bsz"); expect_equal(B[[1]]$value, eb$bsz_model)
  expect_equal(B[[length(B)]]$id, "nber"); expect_equal(B[[length(B)]]$value, eb$rauh_model)
  expect_equal(D$headline$rjkdc_end_b, eb$rauh_model)
  expect_equal(D$headline$jr_rate_gap, eb$jr_rate_gap)
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
