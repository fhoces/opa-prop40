# AUTHOR-JR: the author's answers of 2026-10-16, JR analysis share

Owner: opus implementer. Status: done (items 1, 2, 3, 13, 14, 16, 17, 22, 23, 25, 26); item 20 not applicable.
Nothing committed or pushed. No file outside `rjkdc-analysis/` touched except this report.

## Per item

1. **Contract provenance.** Done. The six rows `nber_growth_rate`, `nber_ceiling_hardcoded`,
   `nber_ceiling_recomputed`, `nber_international_net_worth`, `nber_departed_four_grown`,
   `nber_spielberg_sacks_net_worth` now carry `provenance = "public"` in `R/export.R` and
   `py/run_export.py`. Header comment of `R/export.R` and the README's export section say why
   (the authors' repository is public, MIT licence).
2. **Checks page q rows.** Done. The two rows with the 0 floor (q = 0.75, q = 0.50) are gone; one
   row is the explorer's paired setting (q = 0.50 with the lowest revenue raised to $35B,
   `site_named()$q50`): -48.23, 99.0% below zero. The note under the table now explains the pair.
   The table has nine settings plus the reference row (was ten).
3. **Badge.** Done for the JR overview and deck. Overview: the badge left the `<h1>`; a line of its
   own under it, `<p class="badge-line">This OPA site: <a class="ai-badge ai-badge-yellow" ...>AI
   generated, partially reviewed</a></p>`, with a page-local CSS rule (badge at 0.9em, since
   `paper.css` sizes it at 0.42em for use inside a title). Deck: the title is plain; the subtitle
   ends `<br><span class="badge-line">This OPA site: <badge></span>`, styled in the deck's css chunk.
   `test-ai-badges.R` has a new test: no badge inside `<h1>` or the deck title, and the
   "This OPA site: " line present on both.
13. **JR base kind.** Done. `nber_growth_rate` label is now `guesswork on data` (R and Python).
    The kind is not in a closed list for the JR contract: no test validates the JR contract's
    labels, and the comparison already uses `guesswork on data` (`comparison/R/model.R`,
    `test-shapley.R`, `test-site.R` line 578). The only closed list is
    `comparison/tests/testthat/test-sources.R` line 6, which checks `document-inputs.csv` only.
    `baseline_net_worth` (the 2025 list itself, 1,894.8) stays `data`: the grown base is not a JR
    contract row; it is built in `comparison/R/build.R`, so its kind is the comparison's.
    `materials.qmd` and the README list the new kind.
14. **5% rate.** Checked: `tax_rate` is `data` in the JR contract (R and Python). No change.
16. **SD test.** Done. `test-npv-mc.R`: `expect_equal(s$sd, 37.6, tolerance = 0.34, scale = 1)`
    (seeded run 37.62; 0.34 is 4 x sd / sqrt(2n)). Pages updated: overview "What reproduces"
    ("The test suite holds each of these comparisons, the SD included.") and the figure caption
    (the "except the SD" clause removed); the materials page's test kinds name the SD tolerance.
17. **Pareto 39.0%.** Done. `MISMATCHES.md` #10 records 39.0% (chapter PDF p.27, eq. 10; first
    version p.15) vs 38.8% (chapter PDF p.28; first version p.16) vs the code's 38.85% continuous
    and 34.75% unrescaled shares (`monte_carlo_sim.R:68-70`), all re-read from the PDFs and the
    script. `test-pareto.R` now holds `round(discrete_top_share * 100, 2) == 34.75` (was 39.0 at a
    20% tolerance), with the 39.0% noted in the comment. The count of mismatches moved from nine to
    ten (five on the chapter) on the overview (cards, "Difference" fold, figure caption, "What
    reproduces" text, plus an `<li value="10">`), the README, the materials page and the report
    (both now count `MISMATCHES.md` at render time). `test-site.R` pins 10 mismatches, the `<li>`
    count and the "<strong>ten mismatches</strong>" text. The deck's mismatch slide reads the file
    and now lists 3, 4, 5, 6 and 10 (checked as an image: fits).
20. **C dial label.** Not done, not applicable: the JR C dial is already "Billionaires' yearly
    California income tax ($B)".
22. **Residency date.** Done on the JR overview: "Proposition 40, the Billionaire Tax Act, would
    tax, once, people who lived in California on 1 January 2026 and are worth $1 billion or more,
    at 5% of their net worth, payable over five years." The deck already states the date (slide
    "What is being estimated").
23. **Checks tables generated.** Done. `site/checks.qmd` now builds both tables in R chunks:
    the settings table from `site/explorer/grid.js` (the explorer's own file, read with the new
    `read_site_grid_js()`, `site_grid_js_cell()`, `site_checks_settings()`, `site_checks_table()`
    in `R/site.R`; row text built from the dials' labels), and the variations table from the grid
    (main and first-version Monte Carlo), `data/headlines.csv`, `compute_npv_table9()` and
    `data/printed-tables.csv`. The 2% case's -67.22 is now computed in the page (same call as
    `jr-sensitivity.R` case 5). Every other number in the page prose is inline R. The "copied on
    15 October 2026" sentence is replaced by one saying the tables are built at render and tested.
    New test in `test-site.R`: the rendered `checks.html` settings table equals `grid.js` cell by
    cell, the paired q row is there (-48.2), the first-version and Table 9 values are on the page,
    and no hand-copied table is left in the `.qmd`.
25. **"Lowest in the grid".** Done. The button and its code are removed from
    `site/explorer/index.html`; the key line now reads "Highest in the grid: the grid's highest
    mean NPV, leaving out settings ...". Checked in headless Chrome: the presets render
    (main, Rate 1.5%, Rate 4.5%, Litigation weight q = 0.5, Highest in the grid ($38.0B)).
26. **Deck mirror.** Done: badge line in the subtitle (item 3); the residency date was already on
    the deck; the C label already says income tax.

## Files changed (all under rjkdc-analysis/)

Sources: `R/export.R`, `py/run_export.py`, `R/site.R`, `MISMATCHES.md`, `README.md`,
`site/index.html`, `site/explorer/index.html`, `site/checks.qmd`, `site/materials.qmd`,
`site/repro.qmd`, `site/slides/slides.Rmd`, `tests/testthat/test-ai-badges.R`,
`tests/testthat/test-npv-mc.R`, `tests/testthat/test-pareto.R`, `tests/testthat/test-site.R`.
Regenerated: `export/r/inputs.csv`, `export/py/inputs.csv` (labels and provenance only),
`site/data/test-summary.csv`, `site/checks.html`, `site/materials.html`, `site/repro.html`,
`site/slides/slides.html`. `grid.js` and `headlines.csv` unchanged.

## Tests and renders

- `Rscript -e 'targets::tar_make()'` (only `export_inputs*` rebuilt) and `python3 py/run_export.py`.
- `RAUH_REPO_DIR=... Rscript tests/testthat.R`: all pass, no failures, no skips (one ggplot2
  version warning, pre-existing).
- `Rscript tests/count_tests.R`: 33 tests, 199 expectations, 33 passed, 0 failed, 0 skipped
  (the file now also counts `test-ai-badges.R`; `test-site.R` 10 tests, 73 expectations).
- `quarto render` of `site/repro.qmd`, `site/materials.qmd`, `site/checks.qmd`; deck rendered
  with the Positron pandoc. Deck slide 1 (title, badge) and slide 19 (mismatches) checked as images.
- `check_links.py`: no broken links. No em or en dashes in the added text.

## Needs a follow-up (files outside the package)

- `README.md` (root) line 67: "9 documented mismatches" becomes "10 documented mismatches".
- `AUDIT.md` line 39: "`MISMATCHES.md` (9 items)" becomes "(10 items)".
- Comparison: if the comparison shows the JR contract's `label` for `nber_growth_rate` or counts
  JR kinds, it now reads `guesswork on data`; `provenance` is `public` on every JR row.
- The badge line markup and the residency sentence above, for the comparison overview to match.

## Noticed on the way (not changed)

- `nber_departed_four_grown` is also wealth grown by the assumed 7%; it stays `data`.
- The checks page still says the settings table "has been sent" to the authors (the plan's rule
  forbids changing that sentence); the table now differs from any copy sent before today (the q
  rows), so a copy sent earlier is out of date.
- Headless-Chrome screenshots of the overview at 390 px show the text cut at the right edge on
  every line, including the unchanged site-nav, which looks like the screenshot's viewport rather
  than the page; Playwright is not installed, so `screenshot.cjs` could not confirm.
