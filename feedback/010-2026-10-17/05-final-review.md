# Final review, run 010
Commit: 05859dd69399df3ee8322ba52de9ec967077b677. Packages: 7. One line: attribution fixes (the BSZ net total is this OPA's, the No campaign cites $25 billion, the JR analysis does project the base to 31 December), the BSZ notes on the current workbook only, the root table's departures split and share-lost rules on one base, the survey's wording on step titles and tips, and the JR share-below-zero caveat beside the number.

## Done
- **WP-1 (coordinator), comparison generator.**
  - Root first paragraph: BSZ is no longer the subject of the $106.8B, and the paragraph gains the revenue-use sentence (90% health care, 10% education and food assistance).
  - The one-measure sentence now includes the asset-sale income tax.
  - The BSZ card says "counted for 5 years (this OPA's reading of BSZ's example)".
  - The root's equation note says why the $81.34B loss term is larger than the gap between $75.0B and $0.7B. Every amount in it is computed.
  - End tips carry the reviewers' fixes, and each reason sits in the first sentence, which the root table keeps:
    - D: the BSZ 5% inside a, and the JR 28.6% of the wealth.
    - a: the JR third-party reporting reason.
    - f: both rules on one base, and "no more than" is gone.
    - W: $2,307B, and the Act's 7%.
    - q: "the wealth tax".
    - Non-citizens: the JR reason.
    - Real estate: "of the whole base".
    - H: "for ever".
  - The equation's last term reads "Other inputs together", and "that walk" is gone.
  - The Hoopes differences no longer say "we" or "ours".
- **WP-2 (opus), comparison titles and sources.**
  - The f, C and H step titles take the forms' wording in R and Python; the q title is unchanged (question 1).
  - Four JR source cells now cite the chapter's reasons: the Act's 7% and the VAR check, the 0.6% of the stayers' base, third-party reporting (p.24 first), and plain r − g.
- **WP-3 (opus), comparison report, materials page, deck, DISPUTES.md, READMEs.**
  - The report's introduction and "Versions and citations" credit the net total to this OPA.
  - New report folds:
    - "When the output and the bridge were fixed".
    - In Conventions: the due date (§50301(c)), and one definition of r for a flat yearly loss.
  - The materials page states the discount-factor readings correctly (A-10).
  - Deck slide 2 quotes the guide's "$25 billion" for the March version (A-19).
  - The headings (iii) and (iv) follow the new titles.
  - DISPUTES.md rows 3, 5, 6 and 10 are fixed. The comparison README and the root README are corrected (E-19, E-20, V-21).
- **WP-4 (opus), BSZ overview, explorer, site exports.**
  - Headline label "BSZ's benchmark ... plus its income tax effects", with a present-value gloss on both pages.
  - T1 added. The scope paragraph now says that only the JR analysis projects to 31 December.
  - The "cuts" wording is gone. "Net total" heads the scenario table.
  - The explorer standfirst gives the venue and the count ("Five of the six inputs").
  - The explorer's fixed-inputs line links the comparison explorer's H dial.
  - Gloss of the Pareto extrapolation. "Asserted" became "Set by the authors". The τ row gives the Act's payment terms.
- **WP-5 (opus), BSZ report, materials page, checks page, deck, README, VERIFY-AUGUST.md.**
  - The report subtitle names the data appendix.
  - Payment terms. "One unit lower in the last digit". The departures are now "one of the inputs the two analyses dispute".
  - The court discount is listed among the disputes. The JR reason for the horizon is in the report.
  - The checks page cites `shortrunseries` rows 15 to 272. "We" became "this OPA". The PDF is now a reference, not an input.
- **WP-6 (opus), JR overview, explorer, dials.**
  - T1 and T2 added. The "$36B" in the sign line is now the simulation's average. T5 credits the authors' own framing of the share below zero.
  - The chapter's term "publicly confirmed pre-snapshot departures" is given. The pinned commit is linked.
  - Glosses: Python twin, seeded run, Pareto fit, semi-elasticity.
  - Explorer: "(not a probability)" links the Notes paragraph and opens the fold.
  - Dials:
    - The rate tip gives the authors' reasons.
    - The f label reads "tied to revenue".
    - The growth dial is Δg.
    - The r − g wording is plain.
- **WP-7 (opus), JR report, deck, checks page, materials page, source manifest.**
  - T5 added. The reasons for the r − g band are given. "At 5% of the base, it is ..." replaces "the base is ...". Table 7 is now the subject of the moves sentence.
  - New fold "When the main estimate was chosen". "We" became "this OPA". The notation table gives Δg.
  - The deck uses the T5 wording and carries a {targets} gloss. The DATA-SOURCES row notes that the repository is public.
- **Author answers, applied before the rebuild (WP-1 report, "Author answers").**
  - Q5: BSZ note 2 dropped. Notes 3 to 8 are now 2 to 7 on every page, in the README, in VERIFY-AUGUST.md and in the root README. The test now pins seven.
  - Q3: the attribution in `rjkdc-analysis/NOTES.md` and `rjkdc-analysis/README.md` is neutral, and so is the local `feedback/006.../REPORT.md`.
- Every package touched only its own files. Two exceptions, both listed in the reports:
  - WP-3 extended V-11's plain r − g wording to two more report paragraphs and the comparison README.
  - WP-6 changed the JR overview's "seeded run" gloss and note 3's wording.
- `.gitignore`, `bsz-analysis/py/run_export.py` and `PLAN-3-learning-materials.md` show the same diffs as at the start of the run (1 line, and 26 added / 5 deleted).

## Partially done
- WP-5, item 10: the V-17 clause on the BSZ deck's step-5-loss slide did not fit at full length. The final review placed a short form (below).
- WP-3, slide `prop40`: the September sentence sat under the campaign screenshot. It was dropped, as the plan's fallback says (below). The slide now quotes only the March version's "$25 billion".

## Not done
- None.

## Fixed in the final review
- **Comparison deck:**
  - `prop40`: the September sentence is dropped, because it was hidden under the screenshot.
  - `diff-loss-rest`: "while the loss is counted for 5 years" and "on a loss counted for ever" (E-26).
  - `waterfall`: "the other inputs (W, a and the minor switch) into another" (E-27).
  - `disclosure`: "is this OPA's addition" (V-18).
- **Comparison report:** "the other inputs (W, a and the minor switch) into another" (E-27), and "checks that this OPA's do" (V-18).
- **`comparison/DISPUTES.md`:**
  - "Updated 2026-10-17".
  - "the Rauh PDF this OPA uses" and "that copy" (V-18).
  - Row 1's BSZ cell gives the Act's payment terms in place of "payable 1%/yr" (E-10).
- **`comparison/R/build.R`:**
  - The r source cell reads "(a real rate; chapter PDF p.32 ...)", so two parentheses no longer sit side by side.
  - The `dep_b` source now cites BSZ PDF p.24 first, so the root's D cell cites the page that states the 5% split (applied with the author answers).
- **`comparison/data/document-inputs.csv`:** the `common_discount_rate` source note says "the interest rate minus the loss's yearly growth (a real rate)", the last "real discount rate net" on the comparison pages (V-11).
- **BSZ deck, step-5-loss (V-17):** "counts them forever, assuming leavers do not come back (chapter PDF p.32)". It replaces the unquantified "That horizon is one of the largest differences between the two analyses". The box is back to three lines, as before the run. The longer form with the Act's cap ran past the Overview badge.
- **BSZ report:** Step 3 reads "payable at once or in five annual installments" (E-10).
- **BSZ materials page:** "this OPA's own source manifest" (V-18).
- **`bsz-analysis/tests/testthat/test-site.R` l.84:** the stale "cut" comment is replaced by note 1's wording. The assertion is unchanged.
- **JR report:** the input table prints the growth dial's symbol, Δg, in place of its key `g` (E-09, WP-6's note).
- **Deck fit, checked by eye** (Chrome print, rasterized and tiled):
  - Comparison, slides `prop40` (after the fix), `disclosure`, `pseudo-eq`, `diff-horizon`, `diff-loss-rest`, `smaller`, `hoopes` and `waterfall`: all fit.
  - BSZ, slides 3 and 6 (the tax in one line), step-5-loss (after the fix) and the reproduction slide (20): all fit.
  - JR, slides 3 (Deck Map), 5 (What is being estimated), 6 (The headline) and 19 (reproduction notes): all fit.
  - Page counts: comparison 48 printed pages for 47 slides, BSZ 24, JR 20.

## Needs a local render
Nothing outstanding. After the Part C edits I ran:
```
Rscript comparison/run.R && Rscript comparison/tests/testthat.R          # 1122 expectations, 0 failed
cd comparison/site && quarto render repro.qmd && quarto render materials.qmd
cd comparison/site/slides && RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis && quarto render site/repro.qmd && quarto render site/materials.qmd
cd bsz-analysis/site/slides && RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis && Rscript tests/testthat.R                              # every file passes
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R   # passes, one ggplot2 version warning
```
The comparison and BSZ decks were rendered a second time after the two slide fixes.

## Carried over to the next iteration
- From the plan's "Do later":
  - E-12, a sorted one-at-a-time table in the JR report.
  - V-20, alt text on about 30 figures.
  - E-04, a pipeline target for the 2026 valuation-date range.
  - A-08, the Table 5 title and row 3 label, which need a re-baseline commit (author: not this round).
- From the packages' notes:
  - JR explorer: r − g is still "discount rate net of growth" in the dial label, the headline definition, the two rate preset keys and the checks rows. The lowest-revenue tip's "semi-elasticity" has no gloss.
  - JR report and deck: the Step 4 heading and Section 5.2 still say "the discount rate net of growth"; the deck's perpetuity axis label too. "Python twin" has no gloss on the JR materials page.
  - The JR materials page's Sources table does not show the `status` column, so E-18's note is visible only in the CSV.
  - BSZ explorer: "base scenario" still appears without "benchmark" in the headline label, the chart title and the table caption.
  - BSZ: the deck and a code comment say "the August workbook" without the data appendix date. VERIFY-AUGUST.md section 3 (RC10, 2026-09-23) still reads as if the current workbook had the repeated rows.
  - `comparison/R/site.R`: the dead token `hz_words`, plus run 003's four (`dconf_sept`, `ceiling_literal`, `ceiling_file`, `domestic_grown`).
  - The root's equation at 1280 px: the last term's label wraps to four short lines.
- Review ledgers: run `review-sync` for the bsz, rjkdc and comparison chains after the commit. `site_exports.R`, `site.R`, `build.R`, `model.R` and the reports moved lines, and `review/bsz.json` quotes "Main estimate (net)".
- The loop's own file, `CONTENT-MAP.md`: "eight disputed inputs" should be ten, and the two checks pages are missing.
- Still open from run 003: the JR presets "Rate 1.5%" and "Rate 4.5%".

## Questions for the author
- Run 010's six questions were answered:
  - Q1: keep the court label.
  - Q2: no kind changes.
  - Q3: neutral attribution.
  - Q4: no Table 5 re-baseline this round.
  - Q5: drop BSZ note 2.
  - Q6: no disclosure sentences.
  - All six are recorded in `feedback/DECISIONS.md`.
- New: I was wrong that `feedback/006-2026-10-16-jr-author-mismatches/REPORT.md` is tracked. It is not, and neither is `feedback/007-2026-10-16-bsz-reproduction-standard/REPORT.md`: `.git/info/exclude` keeps both out of the repository. The edit to the 006 report is therefore local only. Two public pages still cite these files, which a reader cannot open: `rjkdc-analysis/NOTES.md` cites the 006 report and seed script, and `bsz-analysis/site/materials.qmd` cites the 007 report. Drop the two pointers, or commit the reports?
- New: the folder name `006-2026-10-16-jr-author-mismatches` stays. Rename it if it reads as an attribution.

## Checks
- Tests, after the Part C edits:
  - Comparison: 1122 expectations, 0 failed.
  - BSZ: every file passes (ai-badges, compute, data_sheets, figures, ingest_excel, py-parity, site, snapshots, sql, tables, verify), including the notes test that now pins seven.
  - JR (`RAUH_REPO_DIR` set): every file passes, with one package-version warning.
- Renders: the comparison report, materials page and deck; the BSZ report, materials page and deck; the JR report. All exit 0. The orchestrator's Phase 4 rendered the rest.
- Links: `check_links.py` prints nothing, identical to `00-links-before.txt`.
- Tips (WP-1, playwright-core with Chrome, all tips forced open):
  - Comparison explorer: 80 tips, at most 3 lines at 390 px and 1280 px, none outside the viewport, no page errors.
  - JR explorer: 21 tips, at most 3 lines (WP-6).
- Decks: the slides listed under "Fixed in the final review" fit.
- Style: the sweep over all tracked pages and sources finds none of these old phrases:
  - "no more than the share", "How long the income tax loss lasts", "annual CA income tax", "billionaire income tax lost"
  - "adds and loses", "income tax it changes", "cut rather than", "appear twice", "eight notes"
  - "real discount rate net", "One of the JR authors", "$25/39", "lowers the JR end", "The other three steps"
  - "most important guesswork", "payable 1%", "Asserted,", "not yet reported to the authors", "the revenue is multiplied", "that walk"
- No em or en dashes in the added lines.
