# WP-5: JR overview, explorer, dial texts and checks page
Owner: opus. Status: done.

## Changed
- `rjkdc-analysis/site/index.html`: "What the model says" now describes a growing perpetuity in r − g, drawn between 1.5% and 4.5% and anchored on the S&P 500 dividend yield (PDF pp.31-32), with NPV = revenue − f × C / (r − g) (A-10, change 1).
- `rjkdc-analysis/site/index.html`: mismatch item 3 rewritten as planned, still one `<li>` (A-23, change 2).
- `rjkdc-analysis/site/index.html`: the A-11 sentence was added after "above the 30 the paper calls collectible" and to the original-analysis figcaption, with the same wording in both (A-11, change 3). The page reference is **p.24**, not the plan's "p.23, fn.24". In the PDF, "should therefore be understood as upper bounds that assume zero stealth departures" is on PDF p.24. Footnote 24 hangs off that sentence but is about the Appendix B stress test, so the sentence cites "(p.24)" with no footnote number.
- `rjkdc-analysis/site/index.html`: new "What reproduces" row after the variations row: "Other numbers the papers print", seven match, two close, Table 8 expanded departures unreachable, with a link to the checks (E-06, change 4). The wording follows `feedback/scenario-tests-2026-10-15/jr.md`.
- `rjkdc-analysis/site/explorer/index.html`: the header definition now reads NPV = WT − f·C / (r − g) (A-10, change 5). The notes now cite mismatch 5 for the litigation dial and mismatch 3 for the growth dial, each with its own link. `KEY.rate15` and `KEY.rate45` now say "r − g, the discount rate net of growth", and rate15 adds "the authors' measure of r − g".
- `rjkdc-analysis/site/explorer/index.html`: the extremes now skip cells where the `wt_lo` level is 0 and the `q` level is above 0. Both dials are found by key in `G.dials` (V-17, change 6). The buttons are now "Highest in the grid ($38.0B)", unchanged, and "Lowest in the grid (−$793.2B)", which was −$807.0B. The new lowest cell is q 1, floor 0, ceiling 55.10, C 5.8, r − g 1.5%, f = 1 − WT/94.2 and g 1.0%. A new key entry "Highest and Lowest in the grid" uses the planned text. The two code comments describing the presets were updated to match.
- `rjkdc-analysis/R/site.R`: rate dial (A-10, change 7):
  - label "Discount rate net of growth" and sym "r − g". A multi-character symbol renders cleanly in the dial label (checked in headless Chrome).
  - desc and tip 1 as planned.
  - tips 2-3 read "This OPA's level: r − g fixed at …%. $1 a year for ever, growing, is worth about $… today." I added "growing" so the tips match the new desc. Without it, $67 at 1.5% would describe a flat perpetuity.
- `rjkdc-analysis/R/site.R`: g dial label, desc and the three tips as planned (A-10, change 8).
- `rjkdc-analysis/R/site.R`: q dial (E-15, change 9):
  - label "Extra litigation weight on the revenue".
  - desc built with `sprintf` from `nb$wt_max`, so 36 and 72 are not typed. The plan's semicolon became a full stop ("… q = 0.50. The script has no separate multiplier (mismatch 5).").
  - level labels "1 (none extra)", "0.75", "0.50". Tips unchanged.
- `rjkdc-analysis/R/site.R`: outcome label "Share of outcomes with NPV below zero, exact" (V-18). The `r − g` in the edited strings uses non-breaking spaces around the minus, as the file already did.
- `rjkdc-analysis/site/checks.qmd`: the rate rows, the Results paragraph and the 2% row now say r − g. The two growth rows now say "a further 0.5% / 1% a year on top of the authors' r − g (this OPA's illustration)" (A-10, change 10).
- `rjkdc-analysis/site/checks.qmd`: "What could not be checked" now says "Litigation weight q = 0.5" changes two inputs. A note under the second table says the two litigation rows count the risk twice. The litigation rows themselves are unchanged, per Q2 (A-20, E-25, V-19, change 11).
- `rjkdc-analysis/site/checks.qmd`: changes for E-26, E-27 and V-20 (change 12):
  - the jr.md summary now says seven match and two are close.
  - a note under the second table explains 85.3% exact against the seeded 85.17%, printed 85.2%. The plan's semicolon became two sentences.
  - "The values were copied from … on 15 October 2026."
  - both tables are wrapped in `::: {.table-scroll}`, with blank lines inside the fences. `repro.css` already has the `.table-scroll` rule, so no CSS was added.

Checks run:
- `parse()` of site.R passes.
- The nine `<li>` and every landing-page pin pass, computed from `headlines.csv` and `outputs.csv` as `test-site.R` does.
- The explorer pins (`var MAIN`, `var ORDER`, `drawBars(i);`, bars svg and title) pass.
- None of the seven forbidden strings is in the four files.
- `node --check` on the explorer's inline script passes.
- No em or en dash was added.
- `check_links.py` reports no broken link.
- Playwright is missing, so I used headless Chrome on a scratch copy of the explorer. Its `grid.js` was patched with the dial texts that the edited `site.R` produces. The committed `grid.js` was not touched. All new labels, descs, tips, buttons, the key and the "exact" row render. In a 390 px iframe the page is 390 px wide and every tip is at most 3 lines (the rate tip 1 is 3 lines).

## Needs a local render
- `rjkdc-analysis/site/explorer/grid.js`: run `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript -e 'targets::tar_make()'`, then `RAUH_REPO_DIR=<clone> Rscript tests/testthat.R`. Until then the test "grid.js and headlines.csv are exactly the exporter's own output" fails.
- `rjkdc-analysis/site/checks.qmd`: run `cd rjkdc-analysis && quarto render site/checks.qmd`.
- `rjkdc-analysis/site/repro.qmd`: run `quarto render site/repro.qmd`. Its `origins` chunk prints `site_dials()` labels, so the input table changes: "Extra litigation weight on the revenue", "Discount rate net of growth", "Further growth of the lost income tax" and "1 (none extra)".
- `rjkdc-analysis/site/slides/slides.Rmd`: run `Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'`. Slide `seven-inputs` prints the same labels.

## Needs a follow-up (files outside the package)
- `review/seed_rjkdc.py`: my one added line in site.R (the q desc now spans two lines) shifts two ranges by one. Line 163 `[230, 273]` becomes `[231, 274]` (`site_grid_payload()`, `write_site_grid_js()`). Line 183 `[199, 227]` becomes `[200, 228]` (`compute_site_headlines()`). Reseed with review-sync.

## Could not do
- Nothing. One deviation from the plan's text: the page reference for the upper-bounds sentence is p.24, not p.23 with fn.24 (see Changed).

## Noticed on the way (not changed)
- `rjkdc-analysis/site/checks.qmd`: two passages still call all three named settings one-input settings, though "Litigation weight q = 0.5" changes two inputs:
  - the bold lead "**The explorer's one-input settings.**" (line 62). Suggested: "**The explorer's named settings.**"
  - the opening paragraph's "the papers give no printed check of the explorer's one-input settings" (line 26-27). Suggested: "… of the explorer's named settings".
- `rjkdc-analysis/site/index.html` line 476: "At the draws' 1.5% to 4.5% rates, a dollar a year for ever is worth 22 to 67 dollars today." To match the r − g reading: "At the draws' 1.5% to 4.5% values of r − g, a dollar a year for ever, growing, is worth 22 to 67 dollars today." This keeps the pinned "worth 22 to 67 dollars".
- `rjkdc-analysis/site/explorer/index.html`: the scenario labels "Rate 1.5% scenario (PDF p.32)" (`SCEN`) and the preset names "Rate 1.5%" / "Rate 4.5%" (`site_named_labels()` in site.R) still say "Rate". The JS comment at lines 263-264 says "the rate fixed at 1.5% or 4.5%".
- `rjkdc-analysis/R/site.R`: the q dial's level-0 tip ("Its 0 revenue floor already halves the mean revenue (36 = 0.5 × 72)") now repeats the new desc.
- The new "Lowest in the grid" (−$793.2B) still combines the 1.0% growth illustration with the first version's f rule. The key line says so in general terms, as planned.
