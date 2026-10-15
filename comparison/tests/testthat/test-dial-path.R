# The dial path (author decision 2026-10-15): the pseudo-equation's eight terms are what the
# BSZ panel's dials change when moved top to bottom, each to its far end.
root <- comparison_root()
rdir <- file.path(root, "comparison", "export", "r")
pdir <- file.path(root, "comparison", "export", "py")

test_that("the eight changes add up to the JR end (one 3% rate) minus the BSZ end", {
  dp <- read_csv_plain(file.path(rdir, "dial_path.csv"))
  en <- read_csv_plain(file.path(rdir, "ends.csv"))
  eb <- en[en$horizon_setting == "own" & en$output == "b", ]
  expect_identical(dp$step_id, EXPLORER_DIAL_ORDER)
  expect_equal(nrow(dp), 8L)
  expect_equal(sum(dp$change), eb$rauh_model - eb$bsz_model, tolerance = 1e-9)
  expect_lt(abs(dp$from[1] - eb$bsz_model), 1e-9)
  expect_lt(abs(dp$to[8] - eb$rauh_model), 1e-9)
  # the path ends at the JR end at 3%, not at the JR headline: the JR rate gap apart
  expect_lt(abs(dp$to[8] - eb$jr_rate_gap - eb$rauh_own), 1e-9)
  expect_gt(eb$jr_rate_gap, 6)
  # the steps chain: each starts where the previous one ends
  expect_equal(dp$from[-1], dp$to[-8], tolerance = 1e-12)
  expect_equal(dp$to - dp$from, dp$change, tolerance = 1e-12)
})

test_that("each change is the explorer's value difference at the path's positions, in both panels", {
  bi <- bridge_inputs(read_contracts(root))
  dp <- dial_path(bi)
  at <- function(ids) stats::setNames(lapply(ids, slider_max), ids)
  moved <- function(k) unlist(lapply(EXPLORER_DIAL_ORDER[seq_len(k)], dial_ids))
  for (k in seq_len(nrow(dp))) {
    expect_equal(slider_value(bi, "bsz", at(moved(k))) - slider_value(bi, "bsz", at(moved(k - 1))),
                 dp$change[k], tolerance = 1e-12, label = paste("bsz", dp$step_id[k]))
    # the JR panel walks the same states in reverse: its first n - k + 1 path dials (from the
    # bottom) at the BSZ value leave the top k - 1 at the JR value
    rev_k <- function(j) unlist(lapply(rev(EXPLORER_DIAL_ORDER)[seq_len(j)], dial_ids))
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
            jsonlite::toJSON(EXPLORER_DIAL_ORDER)),
    "const ids = d => d === 'minor_inputs' ? S.minor : [d];",
    "const at = list => { const p = {}; list.forEach(d => ids(d).forEach(i => { p[i] = S.inputs.find(x => x.id === i).max; })); return p; };",
    "const bsz = [], rj = [];",
    "for (let k = 0; k <= n; k++) { bsz.push(M.panelValue(S, 'bsz', at(P.slice(0, k))).value); rj.push(M.panelValue(S, 'rjkdc', at(P.slice(n - k))).value); }",
    "console.log(JSON.stringify({path: P, bsz: bsz, rj: rj}));"), js)
  out <- jsonlite::fromJSON(paste(system2(node, js, stdout = TRUE), collapse = ""))
  expect_identical(out$path, EXPLORER_DIAL_ORDER)
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
