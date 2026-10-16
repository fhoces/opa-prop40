# Final review, run 003
Commit: 199be9284685dd07db973273b4a11fb616b60877. Packages: 8. One line: BSZ mobility stated in the comparison report, the JR authors' five inputs counted apart from this OPA's two, the JR zero floor's second ground and reason for a permanent loss, the A1 annualizing gap disclosed, test tolerances tightened to what the pages claim, the installment deferral charge disclosed, and the root's first screen balanced.

## Done
- **WP-1 (opus), comparison generator.**
  - Tips: the D, a, q, f, C, r and non-citizen tips now carry the reviewers' fixes. The f tip gives the 28.6% reason and is computed. The C tip gives the K = 500 reason, with its bounds read from the contract (A-03, A-05, A-06, A-07, A-11, V-08, V-09, V-10, V-17).
  - JR sources now lead with chapter pages, and the root table cites them as "chapter PDF p.N" (A-02).
  - `step_texts()` no longer says "what leavers paid" (A-17).
  - The equation note now gives the reason for order dependence, the unrounded −$38.98B, the order-free check described correctly, and nowrap amounts (E-02, V-05, V-06, V-07). The versions row (V-12) and the seeded-run gloss (E-21) are fixed.
  - Code comments now say `(r − g) ~ U` (carried over from run 002).
  - Five tips deviate from the plan's wording to stay within 25 words in the root table or 3 lines at 390 px. Each deviation is listed in `wp/WP-1.md`.
- **WP-2 (opus), comparison report, deck, materials, README, DISPUTES.**
  - Report:
    - Step 1 now states BSZ's mobility (A-16).
    - The introduction leads with the two inputs both lists share and gives the reason. A `stopifnot()` ties it to the exports (V-07).
    - New fold anchor `#order-free-check` (E-02).
    - The f and H joint effect is computed from `switchboard.csv`: −$39.6B at the BSZ values, −$56.7B at the JR values (E-11).
    - Conventions now describe installments, the deferral charge, the ODA and the valuation date (E-01, E-08).
    - A note under the Hoopes table (E-12).
    - Nowrap amounts in every table (V-05).
  - Deck: the order reason (V-07) and the f reason on `smaller` (A-06).
  - Materials: GGSS described by authorship, and the `supporting_*` / `rauh_*` columns explained (A-20). Plus the 15 arguments, the switchboard gloss and the three source documents (E-18, E-19, E-21).
  - README: the September floor (E-19).
  - DISPUTES rows 6 and 9: the chapter's p.33 phrase, the script comment and fn.32 (A-06, A-11).
- **WP-3 (opus), BSZ overview, explorer, dial texts, input table, materials.**
  - Overview: the byline names the main estimate (V-14), the JR reason for a permanent loss (V-16), the scope paragraph with the deferral charge and non-citizens (A-09, E-01), and the A1 exception in "What reproduces" (A-15).
  - Explorer: the Leavers key is stated as BSZ's aggressive assumption (A-12), and a fixed-inputs line is read from `grid.js` facts (E-10).
  - Dial texts: the α tip and description (A-05, V-20).
  - Input table: H and r rows, read from the pipeline (E-14).
  - Materials: the bundle sentence (A-19), the A1 bullet (A-15), and the `{targets}` gloss.
  - The coordinator added the same changes to the Python twin `bsz-analysis/py/site_exports.py`, which no package owned; parity passes.
- **WP-4 (opus), BSZ report, table display, deck, tests.**
  - Table 5 now prints counts without decimals and the loss to the cent. It uses BSZ's header and note, and "steady-state" is gone. Row labels are unchanged, because of the snapshot (A-14, E-13; Q10).
  - The A1 note is computed and lists 7.4%, 6.0% and 2.5% against the paper's 7.6%, 6.2% and 2.6%. An open mismatch item adds that the workbook's own Table 1 uses 44 years (A-15).
  - Wording: "payable" (E-01), "assumed to have left" (A-12), "this OPA's text" (V-22).
  - The sensitivity table is sorted by range (E-15).
  - The rate and years are read from the pipeline in the formula and the deck (E-17).
  - Deck subtitle: "A reproduction of the paper by ..." (V-23).
  - The nine loose tolerances are tightened to 1e-3 or 1e-2 (E-05).
- **WP-5 (opus, partly), JR overview, explorer, dial texts, checks page, README, site test.**
  - "Five inputs of the authors' simulation, and two settings this OPA adds" now appears on the card, figcaption, explorer, README and the computed test pin (A-10, E-06).
  - Plain r − g (V-08), the share-below-zero sentence (E-07), the JR reason for a permanent loss with "really" removed (V-16), and the scope paragraph (A-09, E-01).
  - The SD is now described as not tested (E-05), and "we" becomes "this OPA" (V-22).
  - The q = 0.5 setting is now this OPA's reading (A-13), and the floor tip cites fn.32 (A-11).
  - The q description cites the chapter (A-02), and the checks page has nowrap amounts (V-05).
- **WP-6 (opus), JR report, deck, MISMATCHES, materials, tests.**
  - Report:
    - Introduction: $36B against $30B explained (V-21).
    - "Seven dials", with the authors' five counted (A-10).
    - fn.32 added to Step 1 and Section 5.4 (A-11), and the chapter's term in Section 4.3 (A-04).
    - Footnote now points to row 10, and the identity reads C/(r − g) (E-16).
    - The JR reason for a permanent loss on the horizon bullet (V-16).
    - The share-below-zero sentence (E-07).
    - The tolerance sentence is computed: two deterministic rows differ from the print (E-05).
    - "Quadrature" and `{targets}` glossed (E-21).
    - A word joiner after the minus sign in `usdb()` (V-05).
  - Deck: three slides fitted.
  - MISMATCHES #5: quotes the script comment, and "could be hiding" is gone (A-11).
  - Materials: the test kinds are restated.
  - Tests: four expectations tightened (E-05).
- **WP-7 (coordinator), comparison templates.**
  - Root first screen:
    - "payable", the BSZ amount, "their paper prints an average" and "one simulation of 100,000 random draws" (E-01, V-01, V-02).
    - What OPA is, and the BSZ definition line (V-03, V-04).
    - The deferral charge (E-01).
  - The BSZ card no longer says "static" (A-01).
  - The six kinds are defined on the root (V-11), and footnote 1 no longer defines itself (V-13).
  - Glosses: Python twin, bridge, Monte Carlo (E-21).
  - Explorer:
    - Conventions with the date and installments (E-01, E-08).
    - The Kinds note no longer mentions "A vs B" (E-09).
    - The q note (V-18) and a pointer under the quantities heading (V-19).
- **WP-8 (coordinator), AUDIT.md.**
  - The bundle sentence (A-19).
  - 20 inputs, of which 3 scenario, confirmed against the rebuilt `bsz-analysis/site/data/inputs.csv` (E-14).
  - Three comparison documents (E-18).
  - Dated notes that the outputs were redefined after results: BSZ, JR and comparison step 1 (E-20). No level changes.
- Every package touched only its own files, apart from the Python twin noted under WP-3 and the generated outputs the rebuild writes. `.gitignore` (dated 2026-10-14 16:57), `bsz-analysis/py/run_export.py` (2026-10-14 16:57) and `PLAN-3-learning-materials.md` (2026-10-07) were not touched.

## Partially done
- **WP-5 item 14 (A-21).** The auto-mode classifier denied this edit, and it was not retried. The six `nber_*` rows of the JR export contract should get the provenance "public" instead of "author-shared". The change goes in `rjkdc-analysis/R/export.R` lines 45-56 and `rjkdc-analysis/py/run_export.py` lines 88-110, followed by a rebuild of both exports. `DATA-SOURCES.csv` row 5 records the source as a public MIT git clone, and no code reads the value. This is for the author.

## Not done
- None.

## Fixed in the final review
- Deck overflows. Each slide was re-rendered, printed with headless Chrome, rasterized with Ghostscript and read as an image. Nothing was dropped.
  - Comparison `smaller` (slide 21):
    - A `tight-table` slide class sets the table to 72% with 2 px padding.
    - The first note is reworded. This also removes "counts what the leavers paid", the A-17 wording that remained in the prose.
    - The slide now ends well above the badge.
  - BSZ bottom line (slide 17): the explorer sentence moves into the highlight box. "About 5 years ... 3%" now reads `facts$pv_years` and `facts$pv_rate` (E-17), and the slide fits.
  - BSZ tornado (slide 18): `fig.height` goes from 3.0 to 2.6, and the explorer sentence joins the caption. It fits.
  - JR perpetuity (slide 13): it fitted already. It now also gives the JR reason for counting the loss for ever ("because the Act permanently lifts the cap on taxing intangible property (PDF p.32)"), next to BSZ's objection, because V-16 had missed this page. It still fits.
  - JR slide 2, the deck map: "seven inputs" is now "seven dials (the authors' five inputs and two settings this OPA adds)" (A-10, missed by WP-6). It fits.
- JR overview figcaption: "the test suite holds every comparison with the printed digits" now says "except the SD" (E-05, WP-5's note).
- JR explorer notes: "The litigation dial reads the README's q" becomes "the chapter's q (PDF pp.19-20)" (A-02 consistency).
- BSZ report: "collected once (in five annual installments)" becomes "payable in five annual installments" (E-01, WP-4's note). Re-rendered.
- Code comments that called the q = 0.5 setting the paper's (PDF p.33): `rjkdc-analysis/R/site.R` above `site_named()` and the JR explorer's script header now say this OPA's reading of PDF pp.19-20. The line count is unchanged.

## Needs a local render
All the commands in `00-run.md` were run in Phase 4. The final review ran these again:
```
cd comparison/site/slides && RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis/site/slides && RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd rjkdc-analysis/site/slides && RAUH_REPO_DIR=<clone> RSTUDIO_PANDOC=... Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'
cd bsz-analysis && quarto render site/repro.qmd
cd bsz-analysis && Rscript tests/testthat.R
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R   # and test-site.R again after the comment edits
```
Nothing is left to render. After the commit, A-21 needs `tar_make()`, the JR Python export and `Rscript comparison/run.R` once the author approves it.

## Carried over to the next iteration
- From the packages' notes, not changed:
  - Remaining "we", "our" and "ours" in the BSZ and JR reports, the JR deck's mismatches slide and `MISMATCHES.md` (V-22 named only some lines).
  - The BSZ report and deck still type "5 years at 3%" in prose. `pv_r` and `pv_H` now exist in the report's setup for this.
  - Table 5's "Extra CA inctax from sales" header abbreviation.
  - The BSZ deck's "Checked, found, and not checked" slide does not list the A1 gap.
  - The BSZ explorer's new fixed-inputs line repeats the link of the paragraph above it.
  - The α tip dropped "BSZ PDF p.23".
  - The root's a (JR) line shows only the tip's first sentence, because of the 25-word limit.
  - `comparison/README.md` says the Monte Carlo ranges are "read from the JR contract". The 0 floor is a literal.
  - Dead tokens in `comparison/R/site.R` (`dconf_sept`, `ceiling_literal`, `ceiling_file`, `domestic_grown`).
  - The JR deck slide title "The seven inputs that move the answer" (its box now separates the two settings).
- Still open from run 002:
  - Its E-10, E-26, E-32, V-11, V-22, V-28.
  - The JR explorer's preset names "Rate 1.5%" and "Rate 4.5%". The comparison's r tip now names them, so rename both together.
  - `rjkdc-analysis/R/pareto.R` line 4.
  - CONTENT-MAP's "eight disputed inputs".
- E-11's interaction value as an export (`meta.csv`), so the root and the explorer can cite it.
- V-25: a build-written date in every footer (shared kit).
- Review ledgers: run `review-sync` for the comparison, BSZ and JR chains after the commit, since `site.R`, `site_exports.R`, `tables.R` and the reports moved lines.

## Questions for the author
- The 19 questions of run 002 stay open, with the same assumptions. Nothing this run did reverses them.
- The 13 new questions of `04-plan.md`, each with the assumption this run followed:
  1. (A-15) Should Appendix Table A1 use 43 years or 44? Assumption: 44 stays, the gap is disclosed, and the tests are unchanged. WP-4 found that the workbook's own Table 1 annualizes over 44, so the workbook disagrees with itself.
  2. (A-07) Should the JR C range be relabelled from "guesswork"? Assumption: unchanged; the tip states the K = 500 reason.
  3. (A-08, E-03) Should the real-estate kind change? Assumption: unchanged.
  4. (E-03) Should the kind of the JR base grown by 7% change? Assumption: unchanged.
  5. (E-03) Should the 5% rate get one label across both analyses? Assumption: unchanged.
  6. (A-18) Should the JR printed results stop being labelled guesswork? Assumption: unchanged.
  7. (E-05) Should a test compare the SD with the printed 37.6? Assumption: none added; the pages say the SD is not tested.
  8. (E-05) `test-pareto.R` line 16 holds 34.75% against the printed 39.0% at 20% relative tolerance, and the chapter prints the same formula as 39.0% and 38.8%. Assumption: unchanged.
  9. (E-01) Should the deferral charge's effect be quantified? Assumption: disclosed only.
  10. (A-14) Should the Table 5 row 1 label be re-baselined? Assumption: no; the table note carries it.
  11. (A-20) Should the CSV columns be renamed? Assumption: no; the materials page explains them.
  12. (V-15) Is an object-by-object BSZ credit interview planned? Assumption: the fold is unchanged.
  13. (V-24) Should the deck's "a third OPA in between the two" be reworded? Assumption: unchanged.
- New:
  - A-21 needs your approval of the provenance edit described under "Partially done".
  - The comparison deck's `prop40` slide, part of your opening text, still says "paid over five years". The Act makes installments optional. Change it to "payable over five years", as on the root and the JR overview?

## Checks
- Tests:
  - BSZ: `Rscript tests/testthat.R` after the final review's report and deck edits passes every file (snapshots and py-parity included).
  - JR (`RAUH_REPO_DIR` set): the full suite passes. `test-site.R` was run again after the comment edits: 9 tests, 0 failed.
  - Comparison: 1014 expectations, 0 failed, from the orchestrator's Phase 4 run after all packages. The final review did not change the comparison generator or templates after that run.
- Renders: all three decks were re-rendered (exit 0) and the BSZ report re-rendered (exit 0). The orchestrator's Phase 4 renders cover the rest.
- Decks as images: comparison slide 21, BSZ slides 17 and 18, and JR slides 2 and 13 all fit after the fixes. The orchestrator found every other slide fit. Page counts are unchanged (32, 24, 20).
- Tips (playwright-core with Chrome, all tips forced open, lines counted from the text's line boxes):
  - Comparison: 80 tips. BSZ: 23. JR: 21.
  - Every tip is at most 3 lines at 390 px and at 1280 px, and none leaves the viewport.
  - No page is wider than the viewport (390/390, 1280/1280), and there are no page errors.
- Links: `check_links.py` prints nothing (0 broken). The new anchors exist: `#order-free-check`, `#appendix-table-a1-us-billionaires`, `#every-input-by-origin` and `#differences`.
- Style: none of the 579 added source lines has an em or en dash. "Shapley" and "disputed inputs" are absent from the root, and "Shapley" from the comparison explorer. No old wording is left (checked: "seven inputs", "six are guesswork", "steady-state", "could be hiding", "what leavers paid", "Static estimation", "from one run", "prints a mean", "in support of the measure"). The two exceptions are the JR deck's slide title and the author's `prop40` slide, both listed above.
- AUDIT.md: BSZ step 7 matches the rebuilt `inputs.csv` (20 rows: data 4, research 5, guesswork 5, scenario 3, derived 2, convention 1).
