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
  expect_true(grepl(money(eb$nber_own, 2), html, fixed = TRUE))       # the (b) table
  expect_true(grepl(money(ea$nber_own, 1), html, fixed = TRUE))
  # the explorer's bridge text: both ends and the gap on the net fiscal effect, output (b)
  expect_true(grepl(sprintf("The BSZ end is\n    <b>%s</b> and the RJKDC end <b>%s</b>, a gap of <b>%s</b>.",
                            money(eb$bsz_model, 1), money(eb$nber_own, 1), money(eb$bsz_model - eb$nber_own, 1)),
                    ex_html, fixed = TRUE))
  # the explorer shows the net fiscal effect only: no output setting, no gross revenue
  # number (the two ends on output (a), its gap, Table 5 row 1), no output (a) in its data file
  expect_false(grepl("data-out=", ex_html, fixed = TRUE))
  for (x in c(money(ea$bsz_model, 1), money(ea$nber_own, 1), money(ea$bsz_model - ea$nber_own, 1),
              money(ea$bsz_model, 3)))
    expect_false(grepl(x, ex_html, fixed = TRUE), label = paste("explorer shows", x))
  txt <- read_page(file.path(root, "assets", "comparison-data.js"))
  D <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^{]*", "", txt)), simplifyVector = FALSE)
  for (st in names(D$series)) expect_identical(names(D$series[[st]]), "b", label = st)
  for (st in names(D$switchboard$grid)) expect_identical(names(D$switchboard$grid[[st]]), "b", label = st)
})

test_that("the switchboard: all off is the BSZ end, all on plus the revision is the RJKDC end", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  sb <- read_csv_plain(file.path(root, "comparison", "export", "r", "switchboard.csv"))
  txt <- read_page(file.path(root, "assets", "comparison-data.js"))
  D <- jsonlite::fromJSON(sub(";\\s*$", "", sub("^[^{]*", "", txt)), simplifyVector = FALSE)
  ids <- bridge_steps()$step_id
  # one switch per disputed input, in the bridge's order, plus the revision switch
  ex_html <- read_page(explorer)
  sw <- regmatches(ex_html, gregexpr('data-sw="[a-z_]+" aria-pressed="false"', ex_html))[[1]]
  expect_identical(sub('data-sw="([a-z_]+)".*', "\\1", sw), c(ids, "revision"))
  expect_identical(vapply(D$switchboard$inputs, `[[`, "", "id"), ids)
  for (st in unique(en$horizon_setting)) {
    n <- if (st == "own") length(ids) else length(ids) - 1
    for (o in c("a", "b")) {
      e <- en[en$horizon_setting == st & en$output == o, ]
      g <- sb[sb$horizon_setting == st & sb$output == o, ]
      g <- g[order(g$mask), ]
      expect_equal(nrow(g), 2^n, label = paste(st, o, "rows"))
      expect_equal(g$value[g$mask == 0], e$bsz_model, tolerance = 1e-9, label = paste(st, o, "all off"))
      expect_equal(g$value[nrow(g)] + e$rauh_residual + e$nber_step, e$nber_own, tolerance = 1e-9,
                   label = paste(st, o, "all on"))
      if (o == "b") {
        # the data file the explorer reads: the same grid and constants, to 6 decimals
        G <- unlist(D$switchboard$grid[[st]]$b); E <- D$switchboard$ends[[st]]$b
        expect_equal(length(G), 2^n, label = paste(st, "data file length"))
        expect_lt(max(abs(G - g$value)), 1e-6)
        expect_lt(abs(G[1] - E$bsz), 1e-9)
        expect_lt(abs(G[length(G)] + E$model + E$revision - E$rjkdc), 2e-6)
        expect_lt(abs(E$rjkdc - e$nber_own), 1e-6)
        expect_lt(abs(E$bsz - e$bsz_model), 1e-6)
      }
    }
  }
})

test_that("the headline is the two main estimates; the bridge's two ends under (b) are those quantities", {
  en <- read_csv_plain(file.path(root, "comparison", "export", "r", "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  ep <- read_csv_plain(file.path(root, "comparison", "export", "r", "endpoints.csv"))
  rj <- ep$contract_value[ep$endpoint_id == "rauh_nber_npv"]
  # the two values, pinned: BSZ net total over 5 years; RJKDC NBER mean NPV (seeded run)
  expect_equal(round(eb$bsz_model, 4), 106.7956)
  expect_equal(round(rj, 3), -38.886)
  expect_equal(round(rj, 1), ep$printed_value[ep$endpoint_id == "rauh_nber_npv"])   # printed -38.9
  # under (b) the two ends are the BSZ net constructed from Table 5 row 1 and the NBER expectation
  expect_equal(eb$bsz_model, ep$value[ep$endpoint_id == "bsz_net_constructed"])
  expect_equal(eb$nber_own, ep$value[ep$endpoint_id == "rauh_nber_npv"])
  expect_equal(round(eb$nber_own, 2), -38.98)
  # the steps between them (Shapley, the model difference, the September revision) add up
  br <- read_csv_plain(file.path(root, "comparison", "export", "r", "bridge.csv"))
  b <- br[br$horizon_setting == "own" & br$output == "b", ]
  expect_equal(sum(b$shapley) + eb$rauh_residual + eb$nber_step, eb$nber_own - eb$bsz_model,
               tolerance = 1e-9)
  for (p in pages) {
    html <- read_page(p)
    expect_true(grepl(sprintf('id="hl-bsz">%s<', money(eb$bsz_model, 1)), html, fixed = TRUE), label = p)
    expect_true(grepl(sprintf('id="hl-rjkdc">%s<', money(rj, 1)), html, fixed = TRUE), label = p)
    expect_true(grepl("BSZ main estimate<sup>1</sup>", html, fixed = TRUE), label = p)
    expect_true(grepl("RJKDC main estimate<sup>1</sup>", html, fixed = TRUE), label = p)
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
  expect_equal(B[[length(B)]]$id, "nber"); expect_equal(B[[length(B)]]$value, eb$nber_own)
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
    for (r in refs) {
      f <- file.path(dirname(p), r)
      if (grepl("/$", r)) f <- file.path(f, "index.html")
      # rjkdc-analysis/site/ is built in parallel on another branch
      if (grepl("rjkdc-analysis/site/$", r) && !file.exists(f)) next
      expect_true(file.exists(f), label = paste(basename(dirname(p)), r))
    }
  }
})
