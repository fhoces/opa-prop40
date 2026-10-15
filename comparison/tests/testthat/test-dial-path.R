# The dial path (author decisions 2026-10-15): the nine steps are what the BSZ panel's dials
# change when moved in the equation's order, each to its far end: D, q, the loss box's dials
# (f, C, H, r), then W, a and the minor switch ("the equation's order: D, q, lost income tax,
# the rest"). The pseudo-equation shows D and q, the loss box's four steps added up, and the
# other three added up (eq_terms() in R/site.R).
root <- comparison_root()
rdir <- file.path(root, "comparison", "export", "r")
pdir <- file.path(root, "comparison", "export", "py")

test_that("the nine changes add up to the JR estimate minus the BSZ estimate", {
  dp <- read_csv_plain(file.path(rdir, "dial_path.csv"))
  en <- read_csv_plain(file.path(rdir, "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  expect_identical(dp$step_id, DIAL_PATH_ORDER)
  # the equation's order, left to right (author decision 2026-10-15)
  expect_identical(dp$symbol, c("D", "q", "f", "C", "H", "r", "W", "a", "minor"))
  expect_identical(DIAL_PATH_ORDER, eq_path_order())
  expect_equal(nrow(dp), 9L)
  expect_equal(sum(dp$change), eb$rauh_own - eb$bsz_model, tolerance = 1e-9)
  expect_lt(abs(dp$from[1] - eb$bsz_model), 1e-9)
  # the path ends at the JR analysis's own expectation, -38.98
  expect_lt(abs(dp$to[9] - eb$rauh_own), 1e-9)
  expect_equal(money(dp$to[9], 1), "\u2212$39.0B")
  # the rate step sits after H in the loss box, with D, q, f, C and H already at the JR end
  expect_identical(dp$symbol[6], "r")
  expect_equal(round(dp$change[6], 2), -7.48)
  # the steps chain: each starts where the previous one ends
  expect_equal(dp$from[-1], dp$to[-9], tolerance = 1e-12)
  expect_equal(dp$to - dp$from, dp$change, tolerance = 1e-12)
})

test_that("each change is the explorer's value difference at the path's positions, in both panels", {
  bi <- bridge_inputs(read_contracts(root))
  dp <- dial_path(bi)
  at <- function(ids) stats::setNames(lapply(ids, slider_max), ids)
  moved <- function(k) unlist(lapply(DIAL_PATH_ORDER[seq_len(k)], dial_ids))
  for (k in seq_len(nrow(dp))) {
    expect_equal(slider_value(bi, "bsz", at(moved(k))) - slider_value(bi, "bsz", at(moved(k - 1))),
                 dp$change[k], tolerance = 1e-12, label = paste("bsz", dp$step_id[k]))
    # the JR panel walks the same states in reverse: its first n - k + 1 path dials (from the
    # bottom) at the BSZ value leave the top k - 1 at the JR value
    rev_k <- function(j) unlist(lapply(rev(DIAL_PATH_ORDER)[seq_len(j)], dial_ids))
    n <- nrow(dp)
    expect_equal(slider_value(bi, "rjkdc", at(rev_k(n - k + 1))) - slider_value(bi, "rjkdc", at(rev_k(n - k))),
                 -dp$change[k], tolerance = 1e-9, label = paste("rjkdc", dp$step_id[k]))
  }
})

test_that("model.js gives the path's running values in both panels, to 1e-9", {
  node <- Sys.which("node")
  skip_if(!nzchar(node), "node is not on PATH: model.js not checked")
  dp <- read_csv_plain(file.path(rdir, "dial_path.csv"))
  js <- tempfile(fileext = ".js")
  writeLines(c(
    "globalThis.window = globalThis;",
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "assets", "comparison-data.js"), auto_unbox = TRUE)),
    sprintf("require(%s);", jsonlite::toJSON(file.path(root, "comparison", "site", "explorer", "model.js"), auto_unbox = TRUE)),
    sprintf("const S = window.__BRIDGE__.sliders, M = window.ComparisonModel, P = %s, n = P.length;",
            jsonlite::toJSON(DIAL_PATH_ORDER)),
    "const ids = d => d === 'minor_inputs' ? S.minor : [d];",
    "const at = list => { const p = {}; list.forEach(d => ids(d).forEach(i => { p[i] = S.inputs.find(x => x.id === i).max; })); return p; };",
    "const bsz = [], rj = [];",
    "for (let k = 0; k <= n; k++) { bsz.push(M.panelValue(S, 'bsz', at(P.slice(0, k))).value); rj.push(M.panelValue(S, 'rjkdc', at(P.slice(n - k))).value); }",
    "console.log(JSON.stringify({path: P, bsz: bsz, rj: rj}));"), js)
  out <- jsonlite::fromJSON(paste(system2(node, js, stdout = TRUE), collapse = ""))
  expect_identical(out$path, DIAL_PATH_ORDER)
  expect_lt(max(abs(out$bsz - c(dp$from[1], dp$to))), 1e-9)
  expect_lt(max(abs(rev(out$rj) - c(dp$from[1], dp$to))), 1e-9)
})

test_that("the Python twin's dial path equals R's to 1e-9", {
  skip_if_not(file.exists(file.path(pdir, "dial_path.csv")), "run python comparison/py/bridge.py first")
  r <- read_csv_plain(file.path(rdir, "dial_path.csv")); p <- read_csv_plain(file.path(pdir, "dial_path.csv"))
  expect_identical(p$step_id, r$step_id)
  expect_identical(p$symbol, r$symbol)
  expect_identical(p$title, r$title)
  for (col in c("from", "to", "change"))
    expect_equal(as.numeric(p[[col]]), r[[col]], tolerance = 1e-9, label = col)
})
