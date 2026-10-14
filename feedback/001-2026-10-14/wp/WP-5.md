# WP-5: The RJKDC explorer and its dial texts
Owner: opus. Status: done.

## Changed
- `rjkdc-analysis/site/explorer/index.html`: standfirst now opens "Jaros and Rauh (NBER, September 2026; the first version was by Rauh, Jaros, Kearney, Doran and Cosso, RJKDC for short) estimate" (A-10, K1). Item 1.
- `rjkdc-analysis/site/explorer/index.html`: `.def` now ends "averaged over the authors' Monte Carlo draws: 100,000 random runs of their model." (V-17, K2). Item 2.
- `rjkdc-analysis/site/explorer/index.html`: K2 sizes. `.headline .def` goes from 13.5px to 15px. The page has no `.headline .fn` rule: its headline footnote 1 is `p.fn#hl-fn`, the only `p.fn` on the page, so `p.fn` goes from 12px `--ink-3` to 13.5px `--ink-2` (the same reading WP-4 was told to use, "the page's rules for `.headline .def` and `.fn`") (V-02, V-09). Item 2.
- `rjkdc-analysis/site/explorer/index.html`, `render()`: at the main setting the cell name reads "Main estimate<sup>1</sup>, NBER September 2026, as printed". The sub-line reads "As printed: the mean NPV (PDF p.1, p.35); 85.2% of draws below zero (p.35, Figure 3 note; the text prints 85%). Seeded rerun of the authors' script (one run of the random draws from a fixed seed number, 2026): −38.89; exact expectation of this setting, its average computed by formula: −38.98." The page reference and both values are still read from `grid.js` (A-13, A-18, E-18). Item 3.
- `rjkdc-analysis/site/explorer/index.html`, outcomes table: new first row "Mean NPV, as printed (seeded run) ($B)". At the main setting its "This setting" cell is `f1(P[MAIN].printed_npv)`, elsewhere "not printed"; its main-estimate cell is always the printed mean. The main-estimate column header is "Main estimate (NBER, September 2026)" through a new `COLHEAD` map; the preset button keeps `nlabel()` (A-18, E-07, V-27). Item 4.
- `rjkdc-analysis/site/explorer/index.html`: footnote 1 now reads "NBER (the National Bureau of Economic Research) chapter c15504" (V-10). Item 5.
- `rjkdc-analysis/site/explorer/index.html`, "How this grid differs from the paper": "one seeded run of 100,000 draws (a run started from a fixed seed number, so it gives the same draws every time)" (E-18). Item 6.
- `rjkdc-analysis/site/explorer/index.html`: K9 scroll hint added for `.table-scroll`. The page has no `.chart-scroll` (V-14). Item 7.
- `rjkdc-analysis/R/site.R`, dial `q`: the plan's `desc` verbatim (the discount is already in the 0-floor draw's mean, 36 = 0.5 x 72; a q below 1 counts it twice; use q with the 35 or 45.59 low end; $29.57B is not a level of this grid). Level labels are now "1 (as coded)", "0.75 (OPA reading)", "0.50 (OPA reading)" (A-17, E-17). Item 8.
- `rjkdc-analysis/R/site.R`, dial `rate`: label "Discount rate, the range the model picks from, r" and the plan's `desc` verbatim (the anchor is the published value, which is why the contract and DISPUTES row 2 say research; the band's width is judgement, so the dial says guesswork; the code calls the draw (r - g), mismatch 3). Origin unchanged (Q1 assumption) (A-16, E-04, E-31, V-26). Item 9.
- `rjkdc-analysis/R/site.R`, the other dials (V-26). Item 10:
  - wt_lo and wt_hi labels are now "Revenue, lowest/highest value the model's random pick can take ($B)".
  - wt_lo `desc` now opens "Lower bound of the random pick (the uniform draw)". wt_hi `desc` now opens "Upper bound of the revenue's random pick (the WT draw)".
  - c `desc` now reads "Random pick (a uniform draw) between ...; The script picks at random anywhere between 3.3 and 5.8."
  - f `desc` now reads "The script picks f at random on its own, anywhere between 0.30 and 0.60, ...".
  - g `desc` now reads "The script uses the rate it picks at random (the drawn rate) as the whole denominator".
  - "Random pick" goes only on the first use in each `desc`; later uses of "draw" are kept.
  - No `origin`, level value or logic changed: `git diff rjkdc-analysis/R/site.R | grep '^[-+].*origin ='` is empty, there are still 7 `origin = "` lines, and no `levels =` line changed.

Acceptance:
- `grep "with Kearney"` on the explorer finds nothing.
- The strings `test-site.R` pins (`var MAIN = "nber";`, `var ORDER = [MAIN];`, `drawBars(i);` inside `render()`, the bars SVG before the table) are all present.
- "SSRN March 2026" and "pref-card" are absent.
- `check_links.py` reports no broken link outside `feedback/`.
- No non-ASCII characters and no dashes in the added lines.
- `R/site.R`: a tokenizer pass (strings, comments, backticks) finds every bracket balanced, both in this version and in HEAD. Each assembled `desc` was printed and read.
- `screenshot.cjs --text` renders without errors and shows "−$38.9B" in the header, "MAIN ESTIMATE1, NBER SEPTEMBER 2026, AS PRINTED", the new sub-line and the new first row "Mean NPV, as printed (seeded run) ($B) −38.9 −38.9".
- A Playwright click on q = 0.50 at 390px gives "not printed" in the first row, no script errors, and `scrollWidth` 390. The hint shows at phone width, `.def` measures 15px and footnote 1 13.5px.

## Needs a local render
- `rjkdc-analysis/site/explorer/grid.js` and `rjkdc-analysis/site/data/*.csv`: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript -e 'targets::tar_make()' && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R`. Until then the explorer still shows the old dial labels, descriptions and q level labels, and `test-site.R`'s byte-for-byte check on `grid.js` fails.
- `rjkdc-analysis/R/site.R`: R was not available here. Confirm it parses: `Rscript -e 'invisible(parse("rjkdc-analysis/R/site.R"))'`.
- `rjkdc-analysis/site/repro.html` and `rjkdc-analysis/site/slides/slides.html`: both build their "inputs by origin" tables from `site_dials()`, so they pick up the new dial labels and the "(OPA reading)" level labels at their next render (WP-6's renders): `cd rjkdc-analysis && quarto render site/repro.qmd` and `Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'`.

## Needs a follow-up (files outside the package)
- None. Under the Q1 assumption, `rjkdc-analysis/export/r/inputs.csv` and `comparison/DISPUTES.md` keep "research". The new rate text cites both and agrees with them: DISPUTES line 38 reads "research (discount rate)", and `rauh_mc_r_min` and `rauh_mc_r_max` are labelled "research".

## Could not do
- Run R to parse `site.R` or regenerate `grid.js` (no R in the container). Checked by tokenizer instead; see above.

## Noticed on the way (not changed)
- NBER placement:
  - Item 1 puts "NBER" in the standfirst, so the standfirst is now the term's first use on the page.
  - The package puts the gloss in footnote 1.
  - A strict KG first-use reading would move "(the National Bureau of Economic Research)" to the standfirst.
- Non-main heading: at any setting other than the main one, the headline name reads "Main estimate<sup>1</sup>, a setting the authors did not publish". This existed before this change, and it calls a setting that is not the main estimate "Main estimate". Suggested text for that branch: "This setting, which the authors did not publish".
- Table caption:
  - The caption "Exact expectations for the setting you chose, next to the NBER setting (the main estimate)." no longer covers the new first row.
  - Suggested addition: "The first row is the authors' printed mean, from their seeded run; the rows under it are exact expectations."
- `.headline .sub` stays 12px `--ink-3`. It holds the "As printed ... seeded rerun ... exact expectation" explanation, which is V-09's concern, but K2 does not cover `.sub`.
- K9 hint: the hint shows at 640px and below, but the outcomes table fits at 390px, so phone readers are told to scroll a box that does not scroll.
- Undefined terms still on the explorer (KG terms, and two other abbreviations), not in this package:
  - "export contract": new in the rate `desc`, visible once `grid.js` is rebuilt.
  - "perpetuity": in the rate and g `desc`s.
  - "present value": in the standfirst. The RJKDC overview's K2 "Today's dollars" sentence is not on the explorer.
  - "README" and "mismatch 5", which the dial texts cite.
- The f dial's level button still reads "U[0.30, 0.60] (as coded)". It is a level label, and V-26 and the plan named the descriptions only.
- Page references in the sub-line: `printed_page` from `grid.js` gives "PDF p.1, p.35", and the plan's added cite reads "p.35, Figure 3 note". One sentence now mixes "PDF p." and "p.". Also, `site.R` line 197's source record calls 85.2% "figure alt text", where the plan says "Figure 3 note".
- The sub-line types "85%" (the text's rounding) and the seed "2026" as literals, per the plan. Neither is a field of `grid.js`: it holds 85.2, and the seed is only in `headlines.csv`'s `reproduced_by` string.
- Bar label: the chart's bar is still labelled "Main estimate (NBER)", while the new column header reads "Main estimate (NBER, September 2026)".
