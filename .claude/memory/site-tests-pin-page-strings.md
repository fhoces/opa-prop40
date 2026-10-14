---
name: site-tests-pin-page-strings
description: Each part's test-site.R pins typed strings on the pages and checks generated pages byte for byte; grep the tests before editing a page
metadata:
  type: project
---
`bsz-analysis/tests/testthat/test-site.R`, `rjkdc-analysis/tests/testthat/test-site.R` and
`comparison/tests/testthat/test-site.R` pin literal strings that the pages must contain. Known
ones (2026-10-14): the RJKDC overview's "six are guesswork" (page line 390, test line 126), the
root page's common-output table value "−$38.98B", the comparison explorer's bridge sentence and
`var MAIN = "nber";`, `var ORDER = [MAIN];`, `drawBars(i);` on the RJKDC explorer, and the seven
`origin = "..."` lines in `rjkdc-analysis/R/site.R`. The comparison suite and CI also check the
committed `index.html`, `comparison/site/explorer/index.html` and `assets/comparison-data.js`
against the generator's output, and the RJKDC and BSZ suites check `grid.js` byte for byte.

`comparison/tests/testthat/test-parity.R` compares numeric columns of the R and Python exports,
not source strings, so a changed source cell in `comparison/R/build.R` needs no Python change,
only a rebuild of the R exports.

**Why:** an edit that drops a pinned string turns CI red even when the page is better.

**How to apply:** before editing a page, grep its part's `test-site.R` for strings on the lines
you touch and keep them, or change the test in the same package with a stated reason.
