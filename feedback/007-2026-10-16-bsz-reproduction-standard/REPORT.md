# Review 007: the reproduction standard applied to the BSZ analysis, 2026-10-16

Written by an Opus implementer; saved by the orchestrating session. It applies to the BSZ analysis the standard first applied to the JR analysis in `feedback/006-2026-10-16-jr-author-mismatches/REPORT.md`, so that the two analyses are framed the same way.

## The standard, as given by the project's author

- Anything within Monte Carlo or sampling error of the printed value is a reproduction. Differences from the seed are seed variation.
- A small gap from a rounded or typed intermediate figure, which changes no printed result (0.1% or so), is a note on a rounded or typed input, not a failure.
- A difference between what the text, a README and the code say, where the code still gives the printed results, is a documentation note.
- The headline on every page says what the evidence shows. If the code and data reproduce the published results, the page says so first. The notes are counted separately, by kind, and kept for transparency.
- "Discrepancy", "does not reproduce" and "mismatch" are kept for a real, material failure to reproduce a printed number, stated with its size. A real failure is not relabelled as a match. No number changes.

Kinds: (a) rounding to the printed digit; (b) within simulation or sampling error; (c) a small numerical difference that is not rounding; (d) a documentation difference; (e) a genuine failure to reproduce a printed number.

## Verdict

The code reproduces the BSZ paper's published results from the authors' public workbook. No item is a failure to reproduce a printed number (kind e). The BSZ analysis is deterministic, so no item is seed variation (kind b).

Eight items are now reproduction notes about the authors' materials:

- one is rounding (a);
- two are small numerical differences from first-order formulas (c);
- five are documentation notes (d).

Four more items were errors in this OPA's own code or files, all fixed. They used to be listed among the findings about the paper and are now a separate group.

One part of the standard needed care. Table 5's two income tax loss cells (note 1) do not round to the printed digit. The workbook gives $0.196B and $0.515B, and the paper prints $0.19B and $0.51B. Each printed figure equals the workbook value cut at two decimals, so it is one unit lower in the last digit. The paper is not consistent about this: row 4's $0.5586B is printed as $0.56B, which is rounded. Row 2's printed figure is also what the May version printed (May workbook $0.194B).

Both cells are classed as (a), a rounding convention. The JR report gave 71.176 printed as 71.17 the same treatment. The gaps are $0.006B and $0.005B a year (3.3% and 1.0% of the printed cell). No other printed number is built on them. A new test pins the "cut, not rounded" explanation.

## Every flagged item: old label, kind and evidence, new label

| # | Item | Old label and where | Kind found and evidence | New label and group |
|---|---|---|---|---|
| 1 | Table 5 income tax loss, rows 2 and 3 | "Two printed cells that differ from the workbook" (report). "The paper rounds differently from its own workbook" (materials, report). "Round differently" (deck). Counted among "Three differ" (overview, checks page). MISMATCH in feedback/scenario-tests-2026-10-15/bsz.md C2 | (a). site/data/tab5-vs-printed.csv: -0.196219 printed -0.19, and -0.515403 printed -0.51. Both equal the value cut at two decimals (new expectation in test-site.R). May workbook row 2: -0.194353, and the May paper (PDF p.34) prints -0.19. Row 4: -0.5586 printed -0.56 | Note 1, rounding |
| 2 | data_sec_all rows 1338 to 1341 repeated at 1342 to 1345 | "A data-entry error in the workbook" (report, materials). "Known issues, disclosed rather than fixed" (BSZ README). RC10 class (c) in VERIFY-AUGUST.md | (d). The workbook's own data_sec_agg and the paper (Appendix A, "240 billionaires") count 240. R/compute_data_sec_agg.R drops exact repeats, and test-compute.R matches the aggregate sheet. No printed number changes | Note 2, documentation |
| 3 | Tab5!H6 types the loss share as a literal 0.05 | "Readings the workbook leaves implicit" (report). "Two implicit readings" (materials) | (d). The row label, "10% evasion/avoidance (half due to mobility)", implies 0.10 x 0.5 = 0.05. Same value. The explorer uses the product | Note 3, documentation |
| 4 | Row 4 omits row 2's phase-in deduction | Same as item 3, plus a deck "Found" bullet | (d). The printed $115B reproduces with the omission (114.82). With the deduction it would be 112.84 (bsz-scenarios.R, C3). inp$row4_phasein_gap = $2.0B | Note 4, documentation |
| 5 | Appendix Table A1 annualizes 1982 to 2026 over 43 years | "Appendix Table A1 counts 43 years (resolved)" (report). Listed among the findings (materials) | (d). TabA1!B18:G18 uses 43 years and Tab1!C18:H18 uses 44. The paper prints the 43-year values. The report's tab-a1-years chunk holds the row to the workbook at 1e-6 | Note 5, documentation |
| 6 | Break-even of 25 years (100 for one fourth), PDF p.22 | "Three differ ... the 25-year break-even" (overview, checks). MISMATCH in bsz.md C6 | (d). 5% / 0.2% = 25 and 5% / (0.25 x 0.2%) = 100, from the ratio the text states. Table 5's inputs give C / W0 = 3.061 / 2,307 = 0.133%, so 37.7 and 150.7 years (bsz-scenarios.R). The printed figures reproduce from their stated input. The paper uses two different ratios | Note 6, documentation (see "For the author") |
| 7 | Revenue-maximising rate with de-concentration, 3.8% (PDF p.30) | "Three differ ... the revenue-maximising rate (the paper's first-order formula)" (overview, checks). "Close to the paper's 3.8%" (report). MISMATCH in bsz.md C9 | (c). 1/(1 + d + e) = 1/26 = 3.85%, printed 3.8%. The workbook's Figure 9 curve peaks at 3.904% (optimize), or 3.9% on its grid. Size 0.06 points. The text's "about 15%" is d x 1%; the curve gives 1 - 0.99^15 = 14.0% | Note 7, small numerical difference |
| 8 | A 1% permanent tax keeps 88% of its revenue (PDF pp.29-30) | "One is close" (overview, checks). CLOSE in bsz.md C8 | (c). 100% - 10% - 2% = 88%, the text's first-order sum. The workbook's curve gives 88.58%. Size 0.6 points | Note 8, small numerical difference |
| 9 | Display error in Tables 1 and A1 | Listed with the findings about the paper | This OPA's error, fixed 2026-10-15 | "Errors in this OPA, found and fixed" |
| 10 | Appendix Table A1 first used 44 years | Inside item 5's entry | This OPA's error, fixed | Same group |
| 11 | Malformed row in our own source manifest | Listed with the findings (materials) | This OPA's error, fixed 2026-09-23 | Same group |
| 12 | 184 test failures after the workbook update (VERIFY-AUGUST.md) | "Mismatched" cells and "Mismatch classification" | This OPA's own stale row positions and constants, all fixed (section 0). A new lead note says so. The record is otherwise unchanged | Same group |

Not changed:

- "What is not reproduced". The paper's Figure 8 and Appendix Figure A1 have no builder, and the raw data is taken as given. That is coverage, not a failure.
- The 620 against 617 billionaires (bsz.md C5). It was already explained and was never flagged.

How many items changed kind: all eight notes now carry a kind.

- Four (1, 6, 7 and 8) were counted as numbers that "differ" or are "close". They are now notes.
- One (2) moved from "a data-entry error" to documentation.
- Three (3, 4 and 5) keep their substance and gain a kind label.
- Four items (9 to 12) moved out of the findings about the paper into the group of this OPA's own fixed errors.

## Headline sentences, before and after

**BSZ overview, bsz-analysis/site/index.html, "Difference between this OPA and the original analysis"**

- Before: "This OPA rebuilds Table 5 and most of the paper's tables and figures in R, with a Python twin and a test suite. It sorts every input by origin ..."
- After: "This OPA rebuilds Table 5 and most of the paper's tables and figures in R, with a Python twin and a test suite. The code reproduces the paper's published results from the authors' public workbook (see What reproduces). It sorts every input by origin ..."

**BSZ overview, "What reproduces" fold**

- Before: the fold opened on the table, with no headline.
- After, new lead: "The code reproduces the paper's published results from the authors' public workbook. The notes after the table record where the paper rounds or derives a figure differently from the workbook. None is a failure to reproduce a printed result."
- Table 5 row, before: "All 28 cells match the workbook's cached values. 26 round to the digit the paper prints; the other 2, the income tax loss in rows 2 and 3, are printed as $0.19B and $0.51B where the workbook gives $0.20B and $0.52B"
- Table 5 row, after: "Reproduces. All 28 cells match the workbook's cached values. 26 round to the digit the paper prints; the other 2 ... are printed as $0.19B and $0.51B where the workbook gives $0.20B and $0.52B. The paper cuts these two at the second decimal instead of rounding them (note 1)"
- Other numbers row, before: "Of ten, six match and one is close. Three differ: a Table 5 loss cell (the paper's rounding, above), the revenue-maximising rate (the paper's first-order formula), and the 25-year break-even on PDF p.22, which uses the paper's 2023-2025 ratio of income tax to wealth, 0.2%, where Table 5's inputs give 0.13% and about 38 years."
- Other numbers row, after: "All ten reproduce from the inputs the paper states. Six round to the printed digit, and one is the Table 5 loss cell above. Two come from first-order formulas in the text: the revenue-maximising rate of 3.8%, where the workbook's own curve peaks at 3.9% (note 7), and the 88% of revenue a 1% permanent tax keeps, where the curve gives 88.6% (note 8). The 25-year break-even on PDF p.22 uses the text's ratio of income tax to wealth, 0.2%; Table 5's inputs give 0.13% and about 38 years (note 6)."
- Closing line, before: "Every finding is in the report."
- Closing line, after: a definition of "Match" and "reproduces", then "Along the way this OPA kept eight notes on where the paper's text, its tables and the workbook describe the same step differently. None is a failure to reproduce a printed result. One is rounding, two are small numerical differences and five are documentation notes."

**BSZ report, bsz-analysis/site/repro.qmd, introduction**

- Before: "All 28 cells of Table 5 match the workbook, and 26 match the digit the paper prints."
- After: "The code reproduces the paper's published results. All 28 cells of Table 5 match the workbook, and 26 round to the digit the paper prints. The paper prints the other 2 cut rather than rounded (see Reproduction notes)."

**BSZ report, "What reproduces" subsection**

- Before: heading "Mismatches found, and how each was resolved", then "Checking the paper and its workbook found the following." The first item was "A data-entry error in the workbook."
- After: heading "Reproduction notes". The old anchor #mismatches-found-and-how-each-was-resolved stays as its id. Text: "The code reproduces the paper's published results from the authors' workbook. Checking the paper against the workbook left eight notes, kept for transparency. ... None is a failure to reproduce a printed result. By kind: one rounding, two small numerical differences from first-order formulas and five documentation notes." The counts are read from materials.qmd when the report renders.
- Table 5 paragraph, before: "... so the paper rounds these two cells differently from its own workbook. Both are a cent of a billion; neither changes an argument."
- Table 5 paragraph, after: "Each printed figure is the workbook's value cut at the second decimal rather than rounded, less than a cent of a billion a year (note 1 ...). No other printed number is built on them."
- Laffer curve, before: "... revenue then peaks at 3.9%, close to the paper's 1/(1+d+e) = 3.8%."
- Laffer curve, after: "... revenue then peaks at 3.9%. The paper prints the first-order formula 1/(1+d+e) = 1/26 = 3.8%, the optimum once (1-τ)^d is replaced by e^(-dτ) (note 7 ...)."

**BSZ materials page, bsz-analysis/site/materials.qmd, "What the checks found"**

- Before: no headline, just a list opening "A data-entry error in the workbook".
- After: "The code reproduces the paper's published results from the authors' public workbook: Table 5, the other tables and figures it builds, every variation of Table 5 the paper prints, and the other numbers checked on the checks page." The section then gives, in order: the definition of "reproduced"; "The eight notes below are kept for transparency ... None is a failure to reproduce a printed result"; the three kinds with their note numbers; one sentence on the old labels, citing this report's path; the eight numbered notes, each opening with its kind (figures computed at render from the workbook, including the May workbook for note 1); "Errors in this OPA, found and fixed"; "Not reproduced".
- The heading and its anchor #what-the-checks-found are unchanged.

**BSZ checks page, bsz-analysis/site/checks.qmd**

- Before: "checks ten other numbers the paper prints. Six match and one is close. Three differ: ..."
- After: "checks ten other numbers the paper prints. All ten reproduce from the inputs the paper states. Six round to the printed digit. ... None is a failure to reproduce a printed result."
- The 3.9%, 88.6%, 0.13% and 38 years are now computed when the page renders. The page's own headline ("All seven variations the BSZ papers print reproduce at the paper's rounding") was already a reproduction statement and is unchanged.

**BSZ deck, bsz-analysis/site/slides/slides.Rmd, slide repro-checks**

- Before: the title was "Checked, found, and not checked". A "Found." block had three bullets, the last "two printed Table 5 cells round differently from the workbook". The deck map said "Tests, mismatches found, and what is not checked".
- After: the title is "Checked, reproduced, and not checked". The block now reads "Reproduces. The code reproduces the paper's published results. Eight notes are kept for transparency (materials page); none is a failure to reproduce. Three of them:". The last bullet is now "two printed Table 5 cells are the workbook's value cut, not rounded, at the last digit". The deck map says "Tests, the notes kept, and what is not checked". The count is read from materials.qmd.

**BSZ README, bsz-analysis/README.md, "Status, in plain English"**

- Before: "Known issues, disclosed rather than fixed: the workbook repeats rows 1338 to 1341 ... and Tables 1 and A1 still carry May wording in their labels over August values." The second half was stale, because the labels were fixed on 2026-10-15.
- After: "The code reproduces the paper's published results. Eight notes are kept for transparency, each with its kind (one rounding, two small numerical differences, five documentation), on the materials page. None is a failure to reproduce a printed result. ... The labels of Tables 1 and A1, which kept the May wording, were fixed on 2026-10-15."

**Comparison deck, comparison/site/slides/slides.Rmd, slide opa-bsz**

- Before: "What reproduces. All 28 cells of Table 5 match the workbook, and 26 round to the digit the paper prints. Every variation the paper prints reproduces (7 of 7)."
- After: "What reproduces. The authors' workbook and this code reproduce the published results. Eight notes on where the paper's text, tables and workbook describe a step differently are kept for transparency; none is a failure to reproduce. Every variation the paper prints reproduces (7 of 7)."
- The count is read from bsz-analysis/site/materials.qmd, as the JR slide reads MISMATCHES.md.

**Root README.md**

- Before: "BSZ reproduced cell by cell; OPA site (explorer, report, slides, materials)"
- After: "BSZ reproduced cell by cell; the published results reproduce, with 8 notes on how the paper's text, tables and workbook describe them (materials page); OPA site (explorer, report, slides, materials)"

**Other records**

- AUDIT.md, BSZ step 5: the evidence adds "the reproduction notes (8, each with its kind) on the materials page and in the report".
- bsz-analysis/VERIFY-AUGUST.md: a new lead paragraph says its failures were this OPA's own tests against a changed workbook. All were fixed, and none is a failure of the paper to reproduce. It adds that RC10 is note 2.
- .claude/skills/opa-review-loop/CONTENT-MAP.md: one line says where the BSZ notes live.
- The comparison overview, report and materials page were not changed. Their only claim about the BSZ reproduction, "The BSZ end matches the number its authors print, up to rounding", stands.

## Files changed, rebuilds, tests

Source files edited:

- In bsz-analysis/: site/index.html, site/materials.qmd, site/repro.qmd, site/checks.qmd, site/slides/slides.Rmd, README.md, VERIFY-AUGUST.md and tests/testthat/test-site.R.
- Elsewhere: comparison/site/slides/slides.Rmd, README.md, AUDIT.md and .claude/skills/opa-review-loop/CONTENT-MAP.md.

The JR changes already in the shared files were left as they were. .gitignore, bsz-analysis/py/run_export.py and PLAN-3-learning-materials.md were not touched.

New tests in bsz-analysis/tests/testthat/test-site.R:

- The two Table 5 cells off the printed digit equal the workbook values cut at two decimals.
- The materials page lists eight notes, numbered 1 to 8, each with a kind. Its by-kind list agrees with the items. The overview's "eight notes" and its kind counts agree with them.
- The overview's 0.13%, 38 years, 3.9% and 88.6% are recomputed from the workbook.

No pipeline code under R/ changed, so tar_make was not needed. Rebuilt:

- bsz-analysis/site/data/test-results.csv and the README test-count block (Rscript tools/site-test-results.R).
- checks.html, materials.html and repro.html, with quarto.
- The BSZ deck and the comparison deck.
- The comparison exports, with Rscript comparison/run.R && python3 comparison/py/bridge.py. The root index.html and assets/comparison-data.js came out unchanged, and no comparison .qmd changed.

Verification (implementer):

- BSZ suite: 794 expectations passed, 0 failed, 0 skipped, in 119 blocks.
- Comparison suite: 1,029 expectations, 0 failed, 0 skipped.
- JR suite, with the authors' repository: 35 tests, 210 expectations, 0 failed, 0 skipped.
- check_links.py printed nothing.
- No em-dashes on added lines, in the sources or in the rendered pages.
- Screenshots of the BSZ deck's repro-checks slide and deck map, and the comparison deck's opa-bsz slide: all three fit.

Privacy: nothing from the private notes or the author bundle was used. The four names in note 2 were already on the public report.

## For the project's author to decide

1. **Note 6, the 25-year break-even, is the most substantive note.** The printed 25 and 100 years reproduce exactly from the 0.2% ratio the text states, so it is classed as documentation, not a failure. But Table 5's own inputs give about 38 years, 51% longer. You may prefer to treat a figure that only reproduces from a ratio Table 5 does not use as kind (e). If so, the overview, the checks page and the materials page each need one sentence changed. It matters for the comparison, because the JR analysis disputes how long the loss lasts.
2. **Note 1 is classed as rounding (a)**, a "cut, not rounded" convention. Row 2's figure may instead be the May figure kept in the August revision. If you prefer (c), only the kind word changes.
3. **The old scenario record still uses the old labels.** feedback/scenario-tests-2026-10-15/bsz.md is a dated record and still says MATCH, CLOSE and MISMATCH, and the checks page links to it. Should it get one line at the top pointing to the new classification?
4. **Should the BSZ notes get their own file**, as the JR analysis keeps MISMATCHES.md? For now the materials page's "What the checks found" is the single list.
5. **Should notes 2 and 4 go to the BSZ authors?** Note 2 is the repeated rows; the README says it is not yet reported. Note 4 is row 4's missing phase-in deduction.
6. **The old anchor is kept.** #mismatches-found-and-how-each-was-resolved is now the id of the renamed "Reproduction notes" heading, so old links still work. Should it get a new id?
