# Final review, run 002
Commit: aff381ce99b01b57663935dd3e4ac3271bb12c60. Packages: 8. One line: the JR rate as r − g, corrected chapter citations and kind labels, BSZ's five years as an example, the September values in DISPUTES.md, BSZ Table 1 formats fixed, and the checks pages and decks tightened.

## Done
- WP-1 (opus): comparison generator and templates. The root and the explorer now say the chapter prints −$38.9B beside the exact −$39.0B. There are new tips for D, q, f, H, r, W and the non-citizens (A-03, A-04, A-05, A-28, E-07, E-13, E-14). The non-citizens kind is now "data vs guesswork" and the share lost "guesswork". The chapter citations in `build.R` are corrected (A-06). The equation note now says each term depends on the path's order and is not a total, with the two PV figures for scale (A-13, E-08, E-09). The conventions are corrected (E-11). The LAO row gives the LAO's bounds (E-02), and the screen-reader titles use the dial names (V-15). The equation's last term reads "(W, a, the minor switch)" (V-04). The tips carry no sources, per the author's tip rule.
- WP-2 (opus): comparison deck. The pseudo-eq slide now defines (b) and the dial path, and names the order-free top three, computed from the exports. The difference slides now quote BSZ fn.30, BSZ's five-year example, the JR not-return reason, the corrected sections and the growing perpetuity. The estimates box now says only the lost income tax is discounted. The smaller-steps slide now names the movers' proportional share and r − g. The opening, AI and "sent" slides are unchanged (Q1, Q4 to Q8).
- WP-3 (opus): BSZ Table 1 and Appendix Table A1. They now render Panel B in its own formats, with its columns in the heading: Table 1 shows 11.8 (million families), 0.41, 24.7, 9.1% and 144% / 322% / 17%, as PDF p.35 prints them. The panel data and snapshots are unchanged. The report and materials notes are rewritten to match. "Table 5's row 1, printed as $104 billion" replaces "BSZ's headline", with the digit read from the pipeline (A-16). The report also has the Laffer check value (A-17), the five-year example (A-07), "one of the largest disputes" (A-13) and the row L label in R and Python (A-03).
- WP-4 (opus): BSZ overview, explorer, deck, checks page. Changes: the face-value definition line (E-01), the credit fold's record (A-08), dagger marks on the two cells (A-09), the five-year example (A-07) and the 2025 `data_sec_all` duplicate explained (V-10). They also add "Other numbers the paper prints" (E-06), "(Table 5), net total¹" (A-12), the printed $104 billion on the deck (A-16) and "JR analysis" (A-18). The checks page now: puts the 0.2% ratio as the paper's own (A-22), states the record as six match, one close and three differ (E-27), says "copied ... on 15 October 2026" (E-26), uses 103.82 throughout (V-21), wraps both tables in scroll boxes (V-20) and adds the 31 December valuation date (V-02).
- WP-5 (opus): JR overview, explorer, dials and checks page. Everything now reads r − g, the real rate net of growth: the overview's "What the model says", item 3, the explorer header, the rate dial and the g dial (A-10, A-23). The q dial is labelled "Extra litigation weight on the revenue" with "1 (none extra)" (E-15). The grid extremes skip the pairing that double-counts litigation; Lowest is now −$793.2B, labelled not a JR result (V-17). The share-negative row reads "exact" (V-18). The checks page has the litigation note and the corrected two-input sentence (A-20), and the r − g row labels. The record summary is restated with the 85.3% note (E-27); scroll boxes added (V-20).
- WP-6 (opus): JR records, report and deck. MISMATCHES #3 is retitled and rewritten against the NBER README at 25e84dd (A-23), and #5 is corrected (A-24). In the report, the notation, Step 4, Steps 5 and 6 and "Which rate is drawn" now use r − g (A-10), and the five years are BSZ's example (A-07). Amounts print as −$38.9B (V-23). On the deck, the formula and the perpetuity slide now use r − g. Also changed: the three script headers (A-25) and the two DATA-SOURCES feeds cells (A-14).
- WP-7 (coordinator): `DISPUTES.md` now gives the September 2026 values first, with chapter pages, quotes and the two kind changes (A-26, E-30, A-04, A-05, A-06, A-07, A-10, A-28, E-07). The comparison report has the order-dependence qualifier and the generated Shapley top three. It also has the printed and the exact JR figure, r − g, the corrected conventions and the endpoint rounding. Six kinds are defined, and the JR / Neutral labels are in the transcribed-inputs fold. The materials page no longer says the bridge ends in March. In `document-inputs.csv` the Walczak rows are neutral and the horizon row cites the chapter.
- WP-8 (coordinator): READMEs and the audit: 10 disputed inputs, the dial-path bridge with a Shapley check, −$39.0B with the printed −$38.9B, the JR test count as a link, AUDIT evidence for steps 1, 2 and 7 (no level change).

Every package touched only its own files plus the generated outputs the rebuild writes (`git status` checked against the plan's Files lists). `.gitignore`, `bsz-analysis/py/run_export.py` and `PLAN-3-learning-materials.md` were not touched: their mtimes are 2026-10-14 and 2026-10-07. Departures from the plan's letter, each reported in its `wp/` file and each kept:
- WP-1 shortened tips to the author's tip rule and to the 25-word table cells.
- WP-2 moved text into `.small` and gave diff-horizon a wider right column so the slides fit.
- WP-4 wrote "year-by-year billionaire list": the sheet lists every billionaire in every year, not tax data.
- WP-5 cites p.24 rather than p.23 fn.24 (checked).
- WP-6 corrected the plan's own slip in mismatch 5: the 29.6 point estimate does not share a mean with the draw; q times 72 does.

## Partially done
- None.

## Not done
- None.

## Fixed in the final review
- Deck overflow, four slides, each checked as an image after the re-render (headless Chrome print, Ghostscript), nothing dropped:
  - Comparison `smaller`: the four bullets were tightened, and "5 years" is now read with `fmt_input()`.
  - BSZ `step-5-loss`: the title is now one line, "Step 5, part 2: the income tax leavers take". The box ends "one of the largest differences between the two analyses" (WP-4's note: "steps" read as the deck's own Steps).
  - BSZ `row-2`: the two figures are 2.1 in high instead of 2.9.
  - JR Sec 5.1: the figure is 2.9 in high instead of 3.6.
  - The three changed decks' neighbouring slides (BSZ 20, JR 13) also fit.
- Comparison explorer tips: WP-1's longer tips put five tips per panel at four lines on a 390 px screen. They were the D BSZ end, the r JR end, the r dial, the non-citizens JR end and the revenue box's "more". They are shortened, keeping each reason and the pinned "($1 a year for ever is worth $36.6). Kind: derived." Measured with playwright-core on all 80 tips: at most three lines at 390 and 1280. The start commit's explorer measures the same. The BSZ and JR explorers measure at most three lines too. The box tip's E-14 sentence was dropped (DECISIONS.md).
- JR checks page: the first-version row said 'Jump to "First version, March 2026"', a button the explorer does not have. It now says to set the lowest revenue to 35, the highest to 67.51 and the share lost to "1 - WT/94.2". "One-input settings" now reads "named settings" in two places, since one of them changes two inputs.
- JR report: the note WP-6 flagged (old line 216) now says the explorer adds two settings the authors' code does not have: a litigation multiplier on top of the draw, and growth on top of the drawn r − g (this OPA's illustration). Two other report changes:
  - "At $r$ = 1.5%" in Section 5.2 is now "At a rate of 1.5%".
  - The five remaining amounts written as "−38.9 \$B" print as −$38.9B (V-23).
- JR overview: "At the draws' 1.5% to 4.5% values of r − g, a dollar a year for ever, growing, is worth 22 to 67 dollars today" (the pinned phrase is kept).
- JR deck: the perpetuity figure's x axis is "discount rate net of growth, r − g, %". "Only a few years (five is BSZ's example)" replaces "about five years".
- BSZ:
  - Checks page: "minus the present value of the income tax lost to leavers over five years (3% a year)" (E-01, WP-4's note).
  - Overview: the horizon paragraph's repeated Table 5 clause is removed.
  - Report: "the range from which the JR analysis draws its rate" (WP-3's note).
  - Deck: "244 counted for 2025, 240 real; the estimate uses the 1 July 2026 list" (V-10, WP-4's note).
- Comparison report: the loss letters now read "(H, f, C and r)", as the equation does (WP-1's note). The deck's setup comment says r − g.

## Needs a local render
From `00-run.md`: nothing left; every command `needs_render.py aff381c` listed was run in Phase 4. The final review's edits were rebuilt and rendered here:

```
Rscript comparison/run.R && python3 comparison/py/bridge.py && Rscript comparison/tests/testthat.R
cd comparison/site && quarto render repro.qmd
cd comparison/site/slides && RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis && quarto render site/checks.qmd && quarto render site/repro.qmd
cd bsz-analysis/site/slides && RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/checks.qmd && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd
cd rjkdc-analysis/site/slides && RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis && Rscript tests/testthat.R
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R
```

## Carried over to the next iteration
- `step_texts()` still gives the BSZ share-lost value as "what leavers paid" in the report's tables and the deck's smaller-steps table. At the benchmark these are the avoiders who move (rest of E-07).
- Code comments still describe the JR draw as `r ~ U[...]`: `comparison/R/model.R` lines 36-39 and 281, `comparison/R/build.R` lines 12-13. `bsz-analysis/R/site_exports.R` lines 85-86 still say "BSZ's horizon of about 5 years". `step_texts()` types "grown 7%". `rjkdc-analysis/R/pareto.R` line 4 cites first-version sections without saying so.
- The BSZ credit fold's first paragraph still calls the questionnaire "still being completed" while the next paragraph dates it 2026-10-01 (rest of V-09; needs the author's account of the BSZ re-interview).
- The JR explorer's preset names "Rate 1.5%" / "Rate 4.5%" and `SCEN` labels still say "Rate". The q dial's level-0 tip repeats its new description.
- The rest of E-14: the "Wealth tax collected" box formula does not show the non-citizens or the real-estate deduction. The sentence did not fit a three-line tip.
- From the plan's do-later list: E-10, E-26 (generate the checks tables in R), E-32, V-11 (the BSZ explorer's negative "lost" label), V-22, V-28, the rest of the jargon ledger, and CONTENT-MAP's "eight disputed inputs".
- Review ledgers: `comparison/R/site.R` and `rjkdc-analysis/R/site.R` moved lines. WP-5 lists two `review/seed_rjkdc.py` ranges that shift by one: [230, 273] becomes [231, 274], and [199, 227] becomes [200, 228]. Run `review-sync` for the comparison and JR chains after the commit.

## Questions for the author
- The plan's 19 questions (`04-plan.md`) are open, each with the assumption the run followed. Their short form:
  - Q1 "sent to the authors": wording kept.
  - Q2 the two 0-floor q rows: kept with a note.
  - Q3 the g dial and growth rows: kept, relabelled.
  - Q4 to Q8 (the deck's opening, placeholders, voter guide, AI slides): unchanged.
  - Q9 the yellow badge beside the original authors' names: unchanged. I still recommend moving it.
  - Q10 the conventions sentence on the root: not re-added.
  - Q11 "All these are empirical quantities": unchanged.
  - Q12 the survey audience: unchanged.
  - Q13 "yearly tax revenue": unchanged.
  - Q14 −$39.0B in the comparison headline: kept.
  - Q15 an LAO comparison sentence: not added.
  - Q16 the residency date in the first sentences: unchanged.
  - Q17 the equation's "BSZ estimate" label: unchanged.
  - Q18 the two kind changes: applied.
  - Q19 generated checks tables: not this round.
- New (WP-3), a number for the author: `build_tab_a1()` uses 44 years for the August annualized row; the workbook's `TabA1!B18:G18` still use `^(1/43)`. So Appendix Table A1 shows 7.4%, 6.0% and 2.5% where the paper prints 7.6%, 6.2% and 2.6%. Set 43 for August (reproduce the workbook as it is, disclose the inconsistency, re-snapshot `tab_a1_panel_b`), or keep 44 and disclose? `test-tables.R`'s relative tolerance hides the gap either way.
- New: the explorer's "Lowest in the grid" (−$793.2B) still combines this OPA's 1% growth illustration with the first version's f rule. Keep the button with its key line, or drop the two grid extremes on the JR explorer?

## Checks
- Comparison: after the final review's `site.R` edit, `Rscript comparison/run.R` and `python3 comparison/py/bridge.py` were run, then `Rscript comparison/tests/testthat.R`: 1014 expectations, 0 failed, 0 skipped.
- BSZ: `Rscript tests/testthat.R` after the overview edit: no failures.
- JR (`RAUH_REPO_DIR` set): `Rscript tests/testthat.R` after the overview edit, exit 0, no failures. One warning: ggplot2 built under R 4.4.3.
- Renders: the comparison report and deck, the BSZ checks page, report and deck, and the JR checks page, report and deck were re-rendered after the final review's edits, all exit 0.
- Decks as images:
  - The four overflowing slides now fit, and so do BSZ 20 and JR 13, which the edits touched.
  - A pixel scan of every page of the three decks shows no new content in the badge row. The pages it flags are slides with footnotes or full-height figures that the Phase 4 visual check passed.
- Tips (playwright-core, all tips forced open): comparison 80 tips, BSZ 23 and JR 21. All are at most three lines at 390 px and at 1280 px, with no page errors, and every page is 390 px wide on a phone.
- Links: `check_links.py` reports 0 broken links.
- Pinned strings: all three `test-site.R` suites pass. The comparison quantities table keeps every line within 25 words, with its reason.
- Style: no em or en dash in any added line of any source file in `git diff aff381c`.
- Generated pages are not hand-edited. `index.html`, the comparison explorer and `assets/comparison-data.js` equal the generator's output (`test-site.R`).
