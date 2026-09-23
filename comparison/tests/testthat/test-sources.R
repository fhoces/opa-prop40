# Provenance: every transcribed input has a label and a page; Hoopes's digitized bars hang together.
k <- read_contracts()

test_that("document inputs carry a kind label, a source and a page", {
  d <- k$docs
  expect_true(all(d$label %in% c("data", "research", "guesswork", "scenario", "derived")))
  expect_true(all(nzchar(d$source)))
  expect_false(any(is.na(d$page)))
  expect_false(any(duplicated(d$input_id)))
})

test_that("both sides' contracts have the agreed schema", {
  ins <- c("input_id", "version", "description", "value", "unit", "label", "provenance", "source", "page")
  outs <- c("output_id", "version", "value", "unit", "printed_value", "printed_page", "abs_diff")
  for (s in c("supporting", "opposing")) {
    expect_identical(names(k[[s]]$inputs), ins, label = paste(s, "inputs"))
    expect_identical(names(k[[s]]$outputs), outs, label = paste(s, "outputs"))
  }
})

test_that("Hoopes Figure 2 as digitized is a closed waterfall ending near Rauh's -24.7", {
  h <- k$hoopes
  st <- h[h$step_id != "galle_estimate", ]
  # each bar starts where the previous one ended, to within the reading uncertainty
  expect_true(all(abs(st$start[-1] - st$end[-nrow(st)]) <= st$uncertainty[-1]))
  # bars measured on their own edges: the small gaps between them add up to under $1B
  expect_lt(abs(sum(st$delta) + 100 - st$end[nrow(st)]), 1)
  expect_lt(abs(st$end[nrow(st)] - (-24.7)), 1)
  expect_true(all(grepl("read off the chart", h$source)))
})

test_that("GGSS non-citizen figure is consistent with BSZ's January count grown to July", {
  d <- k$docs
  grown <- pick(d, "bsz_noncitizen_wealth_jan") * pick(k$supporting$inputs, "baseline_net_worth") /
    pick(d, "bsz_wealth_jan")
  expect_lt(abs(grown - pick(d, "ggss_noncitizen_wealth")), 5)
})
