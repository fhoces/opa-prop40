# WP-5: JR overview, explorer, dial texts, export labels, checks page and README
Owner: opus. Status: partially done (16 of 17 items; item 14 was denied by the permission classifier).

## Changed
- `rjkdc-analysis/site/index.html`:
  - Item 1 (E-01): "paid over five years" is now "payable over five years".
  - Item 2 (A-10, E-06): the explorer card now says "the five inputs of the authors' simulation, and two settings this OPA adds (an extra litigation weight and further growth)".
  - Item 3 (A-10): the figcaption now says "all 2,187 settings of its seven dials: the five ranges of the authors' Monte Carlo and two settings this OPA adds". I moved "computed by the code in the repository" ahead of "for all 2,187 settings". Left at the end, it would have read as if it qualified "two settings this OPA adds". The words are the same. 2,187 is still pinned.
  - Item 4 (V-08): the "What the model says" sentence is replaced with the plan's text. The formula sentence and "worth 22 to 67 dollars" are kept. Deviation: "They subtract it:" is now "They subtract that loss from the revenue:". After the new text, "it" would have pointed at "their measure of r − g".
  - Item 5 (E-07): S-SHARE is a new paragraph directly under the table.
  - Item 6 (A-10, V-16): "Third, ..." now has the plan's text, then S-JR-REASON, then the BSZ sentence without "really". Deviation: "shows how far each one moves it" is now "moves the estimate". The new first sentence no longer contains "the answer", so "it" had nothing to refer to.
  - Item 7 (A-09, E-01): the "What this OPA does not estimate" paragraph is S-SCOPE, keeping the `../../docs/initiative/README.md` link.
  - Item 8 (E-05): the "What reproduces" sentence now says the SD is shown but not tested.
  - Item 9 (V-22): the three "we" sentences now say "This OPA" ("does not redistribute", "found", "reproduces ... and records").
- `rjkdc-analysis/site/explorer/index.html`:
  - Item 10 (A-10): the standfirst now begins "Four of the authors' five inputs below are guesswork". Deviation: the plan's "the last two dials are this OPA's additions" is false. The dial order is floor, ceiling, q, C, r − g, f, g, so q is the third dial. The text now says "the extra litigation weight and further growth dials are this OPA's additions".
  - Item 11 (A-13): `SCEN.q50` and `KEY.q50` use the plan's text.
  - Item 12 (E-07): S-SHARE is a second paragraph in the Notes fold.
- `rjkdc-analysis/R/site.R`:
  - Item 13 (A-11): the floor's first tip is now "The 0 stands for the Act struck down and for unreported departures (chapter fn.32)." With "Kind: guesswork." it is 19 words.
  - Item 13 (A-02): the q description is now "The chapter sets q = 0.50 (PDF pp.19-20)."
- `rjkdc-analysis/site/checks.qmd`: item 15 (V-05). The three amounts on lines 31-32 are each wrapped in `[...]{style="white-space:nowrap"}`. `quarto pandoc` gives three nowrap spans and no math spans. Nothing else on the page changed.
- `rjkdc-analysis/README.md`: item 16 (A-10). It now says "lets you move the authors' five inputs and two settings this OPA adds".
- `rjkdc-analysis/tests/testthat/test-site.R`: item 17. The "six are guesswork" pin is replaced. The new pin computes the count from `site_dials()` origins, leaving out the keys `q` and `g`. A stub revenue chain stands in, because origins do not depend on it, so the test still runs without RAUH_REPO_DIR. It pins "of the five inputs of the authors' simulation, four are guesswork", with both numbers computed, on whitespace-collapsed HTML. Nothing was loosened. I checked it in R against the edited page: TRUE, with own keys wt_lo, wt_hi, c, rate, f.

Checks run:
- The acceptance greps are clean, except "author-shared" (item 14).
- S-JR-REASON, S-SHARE and S-SCOPE are present word for word.
- No em or en dashes in the eight files.
- `check_links.py` is empty before and after.
- HTML tags are balanced on both pages, and `node --check` passes on the explorer's inline script.
- The other pins still pass: 2,187, "worth 22 to 67 dollars", and nine `<li>`.
- The cited pages match the chapter PDF: p.32 (the cap "permanently removed", the two-thirds vote under §50310), pp.19-20 (q = 0.50 "as our central estimate"), p.23 (0.50 × 59.15 = 29.6), and fn.32 on PDF p.34.
- Not checked in a browser: Playwright is not installed here, so `screenshot.cjs --text` exits 2.

## Needs a local render
- `rjkdc-analysis/site/explorer/grid.js` (the floor tip and the q description come from `R/site.R`): `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript -e 'targets::tar_make()'`. Then `RAUH_REPO_DIR=<clone> Rscript tests/testthat.R`, which checks grid.js byte for byte.
- `rjkdc-analysis/site/checks.html`: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/checks.qmd`.
- The exports and the comparison need a rebuild only after item 14 is applied (see below): `python3 py/run_export.py` from `rjkdc-analysis/`, the `tar_make()` above for `export/r/`, then `Rscript comparison/run.R` and `Rscript comparison/tests/testthat.R`.

## Needs a follow-up (files outside the package)
- None for other files. Item 14 is inside the package but not done; see below.

## Could not do
- Item 14 (A-21): changing `provenance` from "author-shared" to "public" for the six rows in `rjkdc-analysis/R/export.R` (lines 45-56) and `rjkdc-analysis/py/run_export.py` (lines 88-110).
  - Why: the auto-mode classifier denied the edit ("Code That Leaks When Run"). I did not retry it with another tool. Neither file was changed (`git diff --stat` is empty for both).
  - Evidence that the label is wrong: `rjkdc-analysis/DATA-SOURCES.csv` row 5 records `final.csv` and `NPV_dist_v8.R` as a `git-clone` of the public https://github.com/bjaros20/wealth_tax at 25e84dd under MIT. CI clones it fresh. No code reads the `provenance` value; `comparison/tests/testthat/test-sources.R` checks only the column names.
  - Exact change: in each file, replace `"author-shared"` with `"public"` in the six rows `nber_growth_rate`, `nber_ceiling_hardcoded`, `nber_ceiling_recomputed`, `nber_international_net_worth`, `nber_departed_four_grown` and `nber_spielberg_sacks_net_worth`. These are all the occurrences in both files. Values, labels, sources and the local folder name stay unchanged. The orchestrator or the author needs to approve it.

## Noticed on the way (not changed)
- `rjkdc-analysis/site/explorer/index.html` lines 219-220, Notes: "The litigation dial reads the README's q". After A-02 the q dial cites the chapter, so this could say "the chapter's q (PDF pp.19-20)".
- `rjkdc-analysis/site/index.html` figcaption: "the test suite holds every comparison with the printed digits". This is the same over-claim E-05 fixed in "What reproduces", since the SD is not tested and two rows do not round to the print. Also, the "Monte Carlo, Sec 5.4" row still says the SD is "within Monte Carlo error".
- Code comments that still cite p.33 for q = 0.5 and call the q50 setting the paper's: `rjkdc-analysis/R/site.R` line 145 ("the litigation weight q = 0.5 the text states (PDF p.33)") and `rjkdc-analysis/site/explorer/index.html` line 271 ("q = 0.5, PDF p.33"). These are not on the page.
- S-SHARE on the explorer says "as the explorer's Rate 1.5% and Rate 4.5% settings show", which reads a little oddly on the explorer itself. It is kept word for word, as the plan requires.
