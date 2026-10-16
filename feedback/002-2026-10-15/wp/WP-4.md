# WP-4: BSZ overview, explorer, deck and checks page
Owner: opus. Status: done.

## Changed
- `bsz-analysis/site/index.html`:
  - Definition line under the headline (E-01): "counted over 5 years in today's dollars (present value at 3% a year)" is now "counted over 5 years (present value at 3% a year). The wealth tax is counted at face value." The "More in the report" link is kept.
  - Credit fold, "How the table was made" (A-08, E-05, V-09): "every object on all three pages" is now "every object of the BSZ analysis", followed by the new sentence "The JR analysis and the comparison were answered object by object on 2026-10-15."
  - Scenario table (A-09): a dagger (`<sup>&dagger;</sup>`) after the $0.20B and $0.52B cells. Under the table, inside the existing footnote paragraph: "† The paper prints a digit lower; see What reproduces", linked to `#what-reproduces` (the fold script opens the fold). No number typed.
  - Horizon paragraph (A-07): the plan's sentence, with the quote "If they last say only 5 years" (PDF p.27) and "the main estimate's five years are this OPA's reading of that example". "The JR analysis (...) counts it forever; BSZ call ..." and the rest of the paragraph are kept. Straight quotes, as in the rest of the paragraph.
  - What reproduces, workbook row (E-06, V-10): now "Four 2025 rows of the workbook's year-by-year billionaire list (`data_sec_all`) appear twice, giving 244 billionaires for 2025 instead of 240; the estimate itself uses the 1 July 2026 Forbes list of 250. The pipeline drops the repeat. No published number changes". One deviation from the plan's text: I wrote "year-by-year billionaire list" instead of "SEC tax data sheet". `sql/02_data_sec_agg.sql` describes the sheet as listing "every California billionaire in every year". It is not a tax data sheet, and the old row already called it "the billionaire list". Checked against `repro.qmd` lines 1002-1006.
  - What reproduces, new row after the variations row (E-06): "Other numbers the paper prints | Of ten, six match and one is close. Three differ: ..." as in the plan, linked to checks.html. Checked against `feedback/scenario-tests-2026-10-15/bsz.md`: six MATCH (C1, C3, C4, C5, C7, C10), one CLOSE (C8), three MISMATCH (C2, C6, C9).
- `bsz-analysis/site/explorer/index.html`:
  - Definition line (E-01): the same edit as the overview, with the same sentence.
  - Notes, Horizon (A-07): "BSZ argue the losses should be temporary and give 5 years, the payment period, as an example (PDF p.27); Table 5 takes no stand on how long they last."
  - Headline name for rows 2 to 4 (A-12): `name + " scenario (Table 5), net total¹"`, using the same escape as the base-row line above it. Inline script checked with `node --check`.
- `bsz-analysis/site/slides/slides.Rmd`:
  - Line 74 note (A-16): "from its abstract, Table 2 and Table 5."
  - Line 210 (A-16): "Base scenario: **$`r bn(wt_printed, 0)` billion as printed** ($`r bn(t5$wealth_tax_revenue[1])` billion reproduced)." The printed digit comes from `wt_printed`, which the setup chunk reads from `tab5-vs-printed.csv`.
  - Line 252 (A-16): "That is Table 5's row 1: **$`r ...` billion reproduced (printed $`r bn(wt_printed, 0)` billion), once**".
  - Step 5, part 2 box (A-07, A-13, A-18): the plan's sentence. "[JR report]" is now "[JR analysis]", with "(Jaros and Rauh, September 2026; first version by Rauh, Jaros, Kearney, Doran and Cosso)". The ending is now "That horizon is one of the largest steps between the two."
  - Bottom-line box (A-07, A-18): "over BSZ's horizon of about 5 years" is now "over a horizon of about 5 years (BSZ's example)", and "[JR report]" is now "[JR analysis]". I dropped "BSZ's" before "horizon" because the plan's "(BSZ's example)" would otherwise repeat it, and because A-07 says the five years are an example, not BSZ's horizon.
  - Chunk comment line 471 (A-18): "JR report's" is now "JR analysis's".
- `bsz-analysis/site/checks.qmd`:
  - Both results tables are wrapped in `::: {.table-scroll}` (V-20). `repro.css`, which the page already loads, has `.table-scroll { overflow-x: auto }`, so no CSS was added.
  - What could not be checked (V-02): added "The measure values wealth on 31 December 2026 (BSZ PDF p.23); the BSZ analysis uses the 1 July list, and this OPA follows it." Checked against the PDF, p.23: "The actual wealth tax will be based on December 31, 2026 wealth".
  - Who ran these checks (A-22, E-27): the plan's text ("Six match and one is close. Three differ: ..."). The sources are checked against the PDF: p.2 (abstract) and p.11 give "0.2% of their wealth per year in the last 3 years 2023-2025 (Table 2)", and p.22 gives "it would take 25 years".
  - Above the second table (E-27, V-11): "The income tax lost per year is negative, as Table 5 prints it." `tab5-vs-printed.csv` stores the printed loss as -0.15.
  - Last sentence (E-26): now "The values were copied from the explorer's data file, `site/explorer/grid.js`, which the pipeline writes, on 15 October 2026."
  - Rounding (V-21): `grid.js` stores the base revenue as 103.815, and half away from zero gives 103.82. The second table printed 103.81 in five rows that all carry this same `grid.js` value: the reference row, m = 0, m = 1, s = 0 and s = 1. All five now print 103.82. The plan named only the reference row, but leaving the other four would recreate V-21 inside the second table. I recomputed every cell of the second table from `grid.js` with this rule, and every other cell already matched. The first table's values also follow this rule (127.854978 gives 127.85, 88.80255 gives 88.80).

## Acceptance
- All 25 strings that `bsz-analysis/tests/testthat/test-site.R` pins in the landing-page test are still in `index.html`. I rebuilt them in Python from `site/data/tab5.csv`, `tab5-vs-printed.csv` and `grid.csv`, without running R.
- None of the listed old strings remain in the four files: "argue it should last about as long", "on all three pages", "BSZ argue about 5", "JR report", "biggest dispute", "One of them differs", "The values are read from".
- No em or en dash among the 63 added lines.
- `check_links.py`: no broken links (empty output, as in `00-links-before.txt`).
- The tag-balance check passes on both HTML pages, and `page_text.py` shows the new overview text in place.
- `screenshot.cjs`: skipped, because Playwright is not installed.

## Needs a local render
- `bsz-analysis/site/checks.qmd`: `cd bsz-analysis && quarto render site/checks.qmd`. After the render, check the page width at 390 px; the scroll box has not been measured.
- `bsz-analysis/site/slides/slides.Rmd`: `Rscript -e 'rmarkdown::render("bsz-analysis/site/slides/slides.Rmd")'`. Check the "Step 5, part 2" slide (`step-5-loss`) for overflow. Its highlight box gained about one line, and the slide already holds a table and an equation. Also check the "The tax, in one line" slide, where the right column's item 1 is one line longer.
- `index.html` and `explorer/index.html` are hand-written sources and need no render.

## Needs a follow-up (files outside the package)
- None required by this package.

## Could not do
- Browser rendering checks (`screenshot.cjs --text`, the 390 px width of `checks.html`): Playwright is not installed. Per the rules, I did not run Quarto or R.

## Noticed on the way (not changed)
- `bsz-analysis/site/checks.qmd`, paragraph above the second table: "minus the income tax lost to leavers over five years in today's dollars (3% a year)" has the same E-01 problem as the two definition lines I changed. Suggested: "minus the income tax lost to leavers over five years (present value at 3% a year). The wealth tax is counted at face value."
- `bsz-analysis/site/index.html`, credit fold, first paragraph: "what is still being completed is ... and the author's questionnaire on who did what" still conflicts with the next paragraph, where the questionnaire was already given on 2026-10-01. This is the second half of V-09. Suggested, if the BSZ re-interview is still to come: "... and the object-by-object questionnaire for the BSZ analysis, which the JR analysis and the comparison had on 2026-10-15."
- `bsz-analysis/site/slides/slides.Rmd`, slide "Checked, found, and not checked": "a block of 4 rows pasted twice in the workbook's billionaire list (244 counted, 240 real)" has the V-10 ambiguity, and the overview row now resolves it. Suggested: "(244 counted for 2025, 240 real; the estimate uses the 1 July list of 250)".
- The deck's new ending, "That horizon is one of the largest steps between the two", sits on a slide titled "Step 5, part 2", so "steps" can read as the deck's own Steps 1 to 5. Suggested: "one of the largest differences between the two analyses", or "one of the largest steps on the comparison's path".
- `index.html`, horizon paragraph: the kept opening "The yearly income tax loss has no end date in Table 5." now repeats the new clause "Table 5 itself takes no stand on how long they last". One of the two could go.
- Spelling: the plan's "revenue-maximising" (now on the overview and the checks page) is British. The BSZ report uses "maximizes", while the overview uses "coloured". The pages mix US and British spelling.
