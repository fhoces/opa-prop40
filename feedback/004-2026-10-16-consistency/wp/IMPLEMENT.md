# Implementation of run 004 (consistency review)

Start commit 80ddb60. Nothing committed or pushed. The author's uncommitted files
(`bsz-analysis/py/run_export.py`, `.gitignore`, `PLAN-3-learning-materials.md`) were not touched.

## Items

1. C-01, done. `rjkdc-analysis/site/repro.qmd`, chunk `origins-count`: the levels are the six
   known origins (with "guesswork on data") plus any other origin present, and a `stopifnot`
   checks the counts add to the table's rows. Rendered: data 10, research 3, guesswork 11,
   guesswork on data 1, scenario 0, derived 1 = 26, matching the caption.
2. C-02, done. `AUDIT.md` JR step 7: "data 9, research 4, guesswork 6, guesswork on data 1,
   derived 1, scenario 1", recounted from `rjkdc-analysis/export/r/inputs.csv` (22 rows), with
   the dated note on the 7% growth rate.
3. C-03, done. `AUDIT.md` comparison step 4: four documents, naming the voter guide's
   arguments with Hoopes and the LAO in `comparison/DATA-SOURCES.csv`. The header line already
   listed "steps 1, 4 and 7 on 2026-10-16 (review loop run 003)"; it now adds "the JR step 7
   and the comparison step 4 again on 2026-10-16, consistency review run 004".
4. C-04, done. Root (`comparison/site/index.template.html`): "finds that it raises about
   {{bsz_round_words}} of wealth tax (its Table 5 prints {{bsz_printed}})". Report intro
   (`comparison/site/repro.qmd`): the same wording. "$100 billion" is generated, not typed:
   from the endpoint `ggss_headline` (value 100, the authors' rounding of Table 5's 103.8),
   token `bsz_round_words` in `comparison/R/site.R` and helper `bsz_round_words` in the report.
   BSZ overview and BSZ explorer `<meta name="description">` now say "the estimate of about
   $100 billion".
5. C-05, done. New token `fn1_lead` in `comparison/R/site.R`, used as footnote 1's opening on
   both templates: "Each analysis can be run at many settings. The BSZ overview leads with
   $106.8B, this OPA's net total. The JR overview leads with the printed −$38.9B. This page
   uses the exact average of the same formula, −$38.98B, shown as −$39.0B." All four numbers
   from the exports. On the explorer the next two sentences now read "The BSZ number is..." and
   "The JR number is..." (they read "The BSZ analysis's is..." after the old first sentence).
   The pinned provenance sentence ("The paper prints −$38.9B, the average of one seeded run...
   The exact average... is −$38.98B, used throughout this page") is kept, so the footnote now
   states −$38.98B twice. The author may want one of the two shortened, which would mean
   changing the pin in `test-site.R` (around line 469).
6. C-06, done. Report intro: "finds the state about **$39B** poorer in today's dollars (their
   paper prints an average of −$38.9B)", both from the exports (`eb$jr_own` rounded,
   `rauh_nber_npv` printed value).
7. C-07, done. `comparison/R/site.R`: removed the asset-sales override that printed whole
   percentages, so the dial ends and the root's table use `fmt_input("s", ...)` ("1/3" and
   "0%"). The explorer script's `fmtValue("s")` prints "1/3" at one third too, so the
   current-value label at the end stop agrees. The middle stops still print 25%, 17%, 8%.
8. C-08, done. `comparison/DISPUTES.md` row 3: "28.5% of the domestic base (Table 7, PDF
   p.21), or 28.6% of the revenue, net of real estate, which is the share the explorer and the
   deck print." (placed after the page reference, to avoid two parentheses in a row).
9. C-09, not done, by the item's own rule. With "Shown at this panel's D and a." the four f end
   tips measure 4 lines at 390 px (3 at 1280); without it, 3. Measured with Playwright and
   Chrome on the rebuilt explorer (48 end tips). Reverted; the box tip still carries "f also
   moves with D and a".
10. C-10, done. (a) Comparison deck slide 2: the "$25" is now `round(abs(rj_march))`, with
    `rj_march <- pick(k$rjkdc$outputs, "npv_mc_ssrn_mean")` (−24.77, prints 25 as before;
    `rauh_ssrn_npv` does not exist in `endpoints.csv`, so the JR contract's March mean is read
    instead). (b) `date: today` on `bsz-analysis/site/checks.qmd` and
    `rjkdc-analysis/site/checks.qmd`. (c) with item 4.
11. C-11, done. "Prop 40 comparison:" on both nav lines of `comparison/site/repro.qmd` and of
    `comparison/site/materials.qmd`. New test in `comparison/tests/testthat/test-site.R`
    ("every comparison page opens its nav line with the same prefix"): the root, the explorer
    and the two `.qmd` sources carry the prefix and not the long form. There were no earlier
    nav checks in that file, so it sits after the data-file hash test.
12. C-12, done. `rjkdc-analysis/README.md`: "Four kinds, per file", with item 4, the site
    tests, in the materials page's words.
13. C-13, done. `eq_terms()` in `comparison/R/site.R` returns `loss_order`, appended to the
    explorer's footnote 2 after the pinned sentence: "H is listed first because its step is the
    largest. The walk moves the four in the order f, C, H and r." The order is read from
    `dial_path.csv`, and a `stopifnot` fails the build if H's step stops being the largest of
    the four. The label and the report are unchanged.
14. C-14, done. BSZ overview first sentence now "would tax, once, people who lived in
    California on 1 January 2026 and are worth $1 billion or more, at 5% of their net worth,
    payable over five years." No BSZ test pinned the old sentence.
15. C-15, done. The BSZ and JR overviews already opened the credit fold with the JR sentence
    (BSZ with its extra clause and its "How the table was made" fold), so only the root
    changed: the JR sentence added before "This work was a collaboration". The JR sentence does
    not name the JR analysis, so no word needed swapping.
16. C-16, done. JR deck nav: "JR analysis of California Proposition 40:". Slide 3 rendered and
    checked as an image: the nav fits on one line.
17. C-17, done. `rjkdc-analysis/R/site.R`: "1 − WT/94.2" (minus sign). The Python twin does not
    hold the dial labels (`py/` writes only `export/py/`), so no Python change. Flows to
    `grid.js`, the JR explorer, the checks page and the report's input table.
18. C-18, done. `comparison/DISPUTES.md`: "Updated 2026-10-16."
19. C-19, done. JR explorer Notes (`rjkdc-analysis/site/explorer/index.html`), after the
    mismatch 5 sentence: "The comparison explorer's litigation dial stands at one half at the JR
    end. That is this same half, which here comes from the revenue draw's 0 floor.", linking
    `../../../comparison/site/explorer/`. "One half" is written in words, not as "50%", since
    this hand-written page cannot read the comparison's data file.

## Files changed

Sources: `AUDIT.md`; `comparison/DISPUTES.md`, `comparison/R/site.R`,
`comparison/site/index.template.html`, `comparison/site/explorer.template.html`,
`comparison/site/repro.qmd`, `comparison/site/materials.qmd`, `comparison/site/slides/slides.Rmd`,
`comparison/tests/testthat/test-site.R`; `bsz-analysis/site/index.html`,
`bsz-analysis/site/explorer/index.html`, `bsz-analysis/site/checks.qmd`;
`rjkdc-analysis/R/site.R`, `rjkdc-analysis/README.md`, `rjkdc-analysis/site/repro.qmd`,
`rjkdc-analysis/site/checks.qmd`, `rjkdc-analysis/site/explorer/index.html`,
`rjkdc-analysis/site/slides/slides.Rmd`.

Generated: `index.html`, `assets/comparison-data.js`, `comparison/site/explorer/index.html`,
`comparison/site/repro.html`, `comparison/site/materials.html`,
`bsz-analysis/site/checks.html`, `rjkdc-analysis/site/explorer/grid.js`,
`rjkdc-analysis/site/repro.html`, `rjkdc-analysis/site/checks.html`,
`rjkdc-analysis/site/slides/slides.html`. The comparison deck re-rendered byte-identical
(slide 2 prints the same "$25/39"), so `comparison/site/slides/slides.html` is unchanged.
The two checks pages also picked up two CSS rules from the shared `paper.css` (`.q-mini .q-for`,
`.ai-badge-line`), which had changed since their last render.

## Rebuilds and renders

- JR: `targets::tar_make()` (rebuilt `site_grid`, `site_grid_js`), `python3 py/run_export.py`
  (no change to `export/py/`), `quarto render site/repro.qmd`, `quarto render site/checks.qmd`,
  deck render.
- Comparison: `Rscript comparison/run.R`, `python3 comparison/py/bridge.py` (run twice, the
  second time after reverting C-09), `quarto render repro.qmd`, `quarto render materials.qmd`,
  deck render.
- BSZ: `quarto render site/checks.qmd`. The overview and explorer are hand-written; no pipeline
  change.

## Tests

- Comparison: 1024 expectations, 0 failed, 0 skipped (1016 before, plus 8 from the new nav test).
- BSZ: 117 tests, 778 expectations, 0 failed, 0 skipped.
- JR (with `RAUH_REPO_DIR`): 33 tests, 199 expectations, 0 failed, 0 skipped. Counted with a
  ListReporter in the scratchpad; `tests/count_tests.R` was not run, so
  `rjkdc-analysis/site/data/test-summary.csv` is unchanged.
- Link check: 0 broken.
- Comparison explorer tips (Playwright, Chrome): 48 end tips, max 3 lines at 390 px and 1280,
  no horizontal scroll, no page errors.
- Added lines: no em or en dashes, none of the private file names, no "side".

## For the author

- Footnote 1 on the root and the comparison explorer now gives −$38.98B twice: once in the new
  lead (C-05) and once in the pinned provenance sentence. Shortening either one means changing
  the pin.
- C-09 is left as is because of the three-line rule. Other ways to do it: shorten the existing
  f end tips to make room, or accept 4 lines on these two tips.
- The JR dial label "1 − WT/94.2" still has 94.2 typed in `rjkdc-analysis/R/site.R`. It could
  be read from `ss$baseline_revenue`, as the level's own value is. Not in this package.
