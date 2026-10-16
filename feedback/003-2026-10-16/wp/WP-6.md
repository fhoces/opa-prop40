# WP-6: JR report, deck, mismatches, materials page and three test files
Owner: opus. Status: done.

## Changed
- `rjkdc-analysis/site/repro.qmd`:
  - Introduction (V-21): \$36B is now "the average revenue in the authors' simulation (half of `r nb$wt_max`)", then "The chapter's own revenue estimate is lower, about \$30B, and it sets that against the \$104B benchmark ... This report rebuilds the net present value step by step." ("the net present value" instead of the plan's "the number": after the new sentence, "the number" would point at the \$30B.)
  - Open Output bullet (A-10): "seven dials: the five ranges of the authors' Monte Carlo and two settings this OPA adds".
  - Sources callout (E-07): S-SHARE word for word after "the text on p.1 says 85%)"; the next sentence's "That mean NPV" became "The mean NPV" (its antecedent moved).
  - Sources callout (E-21, V-22): `{targets}` glossed at first use ("an R package that runs the pipeline's steps in order and records which outputs are current"); "we compare against" became "this OPA compares against".
  - "We follow that order." became "This report follows that order." (V-22).
  - Step 1 (A-11): "The chapter also grounds the 0 in its stress test of unreported departures, in which revenue falls to \$4.82B (fn.32, PDF p.34; Appendix B, PDF p.43)." Pages checked in the chapter PDF.
  - Step 4 footnote (E-16): the plan's three sentences, linking disputes row 10 (checked: row 10 is the rate, kind "scenario (BSZ) vs derived from the authors' draw (JR)").
  - Section 4.3 (A-04): opens with the chapter's term "publicly confirmed pre-snapshot departures" (Table 7, PDF p.21, checked) and why this OPA says "publicly reported moves" (disputes row 3, linked).
  - Section 5.2, the horizon bullet (V-16): starts with S-JR-REASON word for word, then "Treating the loss as permanent is one of the disputed choices: ..." (rest unchanged).
  - Section 5.4 (A-11): after "(mismatch 5)": "The script's comment says the draw "embeds litigation range", and the chapter also grounds the 0 in unreported departures (fn.32, PDF p.34)."
  - Every input, by origin (A-10): the headline counts the authors' inputs only, computed from a new `own_dials` (site_dials() without keys q and g, set in the setup chunk with a `stopifnot` that exactly two are dropped): "4 of the authors' 5 inputs ... are guesswork. The explorer's other two dials (an extra litigation weight and further growth) are this OPA's settings." (Plan's semicolon split into two sentences.)
  - What reproduces (E-05): the plan's sentence, with N computed from the output rows: `digits_printed` (decimals the print shows) and `off_print` (rows whose reproduced value does not round to the print); a `stopifnot` ties the prose to exactly `revenue_baseline` and `nber_ceiling`. Renders as "except two: the baseline revenue (mismatch 6) and the ceiling (mismatch 4)". Logic run against `export/r/outputs.csv`: two rows, as named.
  - Mismatch list (V-22): "This OPA records them rather than fixing them."
  - Internal identities (E-16, E-21): "NPV = WT - x* C/(r - g)"; "Share negative: exact integration (quadrature) vs seeded MC (points)".
  - `usdb()` (V-05): a word joiner after the minus sign, written as the escape `"−⁠"` so it is visible in the source. Checked in headless Chrome on "−$126.1B" in a box swept from 30 to 320 px: the sign and the "$" split onto two lines at 137 widths without the joiner, 0 with it.
- `rjkdc-analysis/site/slides/slides.Rmd`:
  - Slide `monte-carlo` (A-11): "this zero is its only trace of $q$, and the chapter also grounds it in unreported departures (fn.32; mismatch 5)". To hold the height, "people who left do not come back" became "leavers do not come back". Rendered: the left column grows one line, the box below does not move.
  - Slide `seven-inputs` (A-10): "4 of the authors' 5 inputs are guesswork; the litigation weight and further growth rows are this OPA's settings." Computed from `own_dials` (setup chunk, with the same `stopifnot`). Not the plan's "the last two rows": the table lists the dials in `site_dials()` order, where the litigation weight is row 3. Rendered: the box stays two lines.
  - Slide `headline` (E-07): fits, so done. "(a summary of the draws' ranges, not a probability; PDF p.35, Figure 3 note; 85% in the text, p.1)", merged into the existing parenthesis. Rendered: one more line, with room left above the footnote.
- `rjkdc-analysis/MISMATCHES.md` #5 (A-11): quotes line 19 with its comment and header lines 5-6 (checked in the clone at `25e84dd`); "The only place a 0.5 could be hiding is that" became "The script's comment says the draw "embeds litigation range":"; adds "The chapter also grounds the 0 floor in unreported departures (fn.32, PDF p.34)." Headings unchanged (test-site.R counts them).
- `rjkdc-analysis/site/materials.qmd` (E-05): kind 1 of the tests rewritten as planned. One change of wording: "where the print differs from the authors' workbook and person-level file (mismatches 6 and 4), against those files". The ceiling test (`test-nber-final.R`) pins the `final.csv` sum (72.05), not a workbook cell.
- `rjkdc-analysis/tests/testthat/test-npv-mc.R` (E-05): both share-negative checks are absolute (`scale = 1`), as planned: SSRN `0.5 + 400 * sqrt(p(1-p)/n)` = 1.074 points (reproduced 71.024); NBER `0.05 + 400 * sqrt(p(1-p)/n)` = 0.4995 points (reproduced 85.172).
- `rjkdc-analysis/tests/testthat/test-pareto.R` (E-05): line 12 drops `tolerance = 0.1` (continuous share 38.846, rounds to 38.8). Line 16 unchanged (Q8).
- `rjkdc-analysis/tests/testthat/test-income-tax-mc.R` (E-05): `tol <- 0.005`, with the comment updated.

Checks run: the three changed test files, with `RAUH_REPO_DIR` set, through `testthat::test_file` (edition 2, so `scale = 1` makes the band absolute; checked that 85.172 against 86 now fails). Results: test-npv-mc 5 tests, 13 expectations, 0 failed, 0 skipped; test-pareto 3 tests, 6 expectations, 0 failed, 0 skipped; test-income-tax-mc 2 tests, 24 expectations, 0 failed, 0 skipped. The number of expectations is unchanged, so the materials page's test counts do not move. Acceptance greps pass ("could be hiding" and "We follow that order" gone; "x* C/(r - g)" and "embeds litigation range" present). No em or en dashes in the added lines. `check_links.py` prints nothing, as in `00-links-before.txt`. The deck was rendered to the scratchpad only (the tracked `slides.html` is untouched) and the three changed slides were printed and read as images.

## Needs a local render
- `rjkdc-analysis/site/repro.qmd`: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd`. Then check "−$126.1B" and "−$24.7B" at 390 px.
- `rjkdc-analysis/site/materials.qmd` (also carries the new MISMATCHES #5): `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/materials.qmd`
- `rjkdc-analysis/site/slides/slides.Rmd`: `RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'`
- The full JR suite: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R`. Also `tests/count_tests.R` if the materials page's counts are refreshed; they should not change.

## Needs a follow-up (files outside the package)
- None required by this package.

## Could not do
- Nothing. The 390 px check of the two amounts in the rendered report waits for the render. The word joiner itself was verified in the browser.

## Noticed on the way (not changed)
- `slides.Rmd` line 73, the `opa-frame` legend: "the mean NPV for every combination of seven inputs". This is the same wording A-10 fixed on the report's Open Output bullet. If the author wants it consistent: "for every combination of seven dials: the five ranges of the authors' Monte Carlo and two settings this OPA adds".
- Other "we" and "our" left in the package's files (V-22 listed only three): repro.qmd "we build it one input at a time" (Main estimate intro), "Our R port replays it" (Step 6), "Our R port replays the authors' script" (Section 5.4), "Our R port agrees" (appendix); the deck's mismatches slide, "We reproduce the code as shipped"; MISMATCHES.md's preamble and several entries ("we do not "fix" the authors", "We reproduce the code as shipped", "We treat 67.51", "We rebuild the ceiling"). A deck setup comment also still says "values we compare against" (not rendered).
- MISMATCHES #9 says the first version's "median and %negative match exactly" (E-05 "Also on"). This is true at the printed rounding (71.02 prints as 71). The test now holds the share within 1.07 points absolute.
- Q7 stands: no test compares the seeded SD with the printed 37.6. The report's What-reproduces sentence does not claim one.
- The deck's own `usdb()` (line 38) has no word joiner. It only prints the headline in `.big` and the revenue range, which do not wrap on a fixed 16:9 slide.
