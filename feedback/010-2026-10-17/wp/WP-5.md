# WP-5: BSZ report, materials page, checks page, deck, README and VERIFY-AUGUST.md
Owner: opus. Status: partially done (all items except the deck half of item 10's V-17 clause, which does not fit).

## Changed
- `bsz-analysis/site/repro.qmd`:
  - subtitle now names "BSZ, NBER, August 2026" and "the authors' workbook (August 2026 revision, data appendix of 8 October 2026)" (E-16).
  - Introduction: "payable 1% a year over five years" became "payable at once with the 2026 income tax or in five yearly installments, each later one with a deferral charge of 7.5% a year on the unpaid balance (§50301(c))" (E-10, V-16).
  - Introduction match sentence: "The paper prints the other 2 cut rather than rounded" became "... one unit lower in the last digit" (A-04, T4).
  - Table 1 paragraph: the repeated rows are now in the 2026-09-04 copy, and the 2026-10-08 update lists each once. The workbook's aggregate, the paper and the pipeline count 240 (A-03).
  - Step 5: the JR reason was added after "counts the loss forever" (", because it assumes leavers do not come back once the Act permanently lifts the constitutional cap on taxes on intangible property (chapter PDF p.32)") (V-17). The source is checked against DISPUTES.md row 2.
  - Leavers scenario: "the most important guesswork in the whole dispute" became "one of the inputs the two analyses dispute" (A-06, V-15).
  - "Table 5, reproduced": "agree with ours" became "agree with this OPA's". "cut at the second decimal rather than rounded" became the T4 note 1 sentence, keeping "less than a cent of a billion a year" (A-04, V-18).
  - "Every input, by origin": "how long losses last" became "how long the lost income tax is counted", plus the court-discount sentence with "(disputes row 9)". Row 9 is checked: it is the litigation discount (V-15).
  - Note 1: T4 sentence. Note 2: T3, verbatim (A-04, A-03).
  - V-18: "We build" became "This OPA builds", "We list this" became "This OPA lists this", and "We read it as" became "This OPA reads it as".
- `bsz-analysis/site/materials.qmd`:
  - The default workbook is now "the August 2026 revision with the data appendix of 2026-10-08 (SHA-256 below)", and the page names `BSZ_VINTAGE=september` and `=may` (E-16). I kept the existing gloss of "vintage" (the dated version of the workbook a number comes from), because the page and the env var still use the word.
  - The compute_data_sec_agg.R role now reads "drops rows repeated in the 2026-09-04 copy".
  - Match definition: "or when the paper prints it one unit lower in the last digit (note 1)".
  - Note 1: T4 sentence. The computed gap from the workbook value and the May evidence are kept (A-04).
  - Note 2: T3, with the page's `link()` markup (A-03).
- `bsz-analysis/site/checks.qmd`:
  - Source cited after the three valuation-date figures: "(the workbook's `shortrunseries` sheet, rows 15 to 272, column D)" (E-04). I checked it in the 2026-10-08 workbook: row 15 is 1 Jan 2026, D = 92.4669, and row 272 is 7 Oct.
  - "prints cut rather than rounded" became "prints one unit lower in the last digit" (A-04).
  - "We have sent ... We will update" became "The author of this OPA has sent this table to the original authors, asking them to test whether they obtain the same results. Their responses will be posted here." (V-18).
- `bsz-analysis/site/slides/slides.Rmd`:
  - Slide 3: "payable at once or in **five yearly installments**" (E-10, V-16).
  - Reproduction slide, two bullets: the 2026-09-04 copy wording (A-03) and "one unit lower in the last digit than the workbook's rounded value" (A-04).
- `bsz-analysis/README.md`:
  - Paper PDF row: "Reference only (quoted in the report); not read by the pipeline. **NOT redistributed in this repo**" (E-21).
  - Status paragraph: T3's facts in the README's words. "(not yet reported to the authors)" is gone (A-03).
- `bsz-analysis/VERIFY-AUGUST.md`:
  - Line 7: the RC10 rows were "listed twice, in the 2026-09-04 copy of the workbook only".
  - RC10 table row: the repeat is now placed in the 2026-09-04 copy, and "the 2026-10-08 update lists each row once" was added.
  - The plan's line was added to the "Data appendix update of 2026-10-08" section (A-03).
  - Facts checked with openpyxl: the September `data_sec_all` repeats Sijbrandij, Rihanna, Preston-Werner and Stephens at 1342-1345 (year, person and wealth equal). October has 1,348 rows, and rows 1338-1341 are now other people.

Acceptance:
- None of the listed phrases remains in the six files. Quotations are untouched.
- No em or en dashes.
- `check_links.py` reports nothing, the same as `00-links-before.txt`.
- The eight-note list and its "n. **Kind.**" lines are unchanged in form. No test asserts a removed string. Only a comment in `tests/testthat/test-site.R` l.84 still says "cut".
- Deck fit: I patched a scratch copy of the rendered `slides.html` with the new text, printed it with headless Chrome and rasterized it. Slide 3 and the reproduction slide fit. Step-5-loss: see "Could not do".
- `screenshot.cjs` was not run: Playwright is not installed here. Also, none of the changed files is an HTML page.

## Needs a local render
- `bsz-analysis/site/repro.qmd`: `cd bsz-analysis && quarto render site/repro.qmd`
- `bsz-analysis/site/materials.qmd`: `cd bsz-analysis && quarto render site/materials.qmd`
- `bsz-analysis/site/checks.qmd`: `cd bsz-analysis && quarto render site/checks.qmd` (`needs_render.py` does not list this file)
- `bsz-analysis/site/slides/slides.Rmd`: `cd bsz-analysis/site/slides && RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'`
- Then `Rscript tests/testthat.R` from `bsz-analysis/`.
- README.md and VERIFY-AUGUST.md need no render.

## Needs a follow-up (files outside the package)
- `bsz-analysis/tests/testthat/test-site.R` l.84-85, comment only: "Each is the workbook's value cut at the second decimal, not rounded" could read "Each printed figure is one unit lower in the last digit than the workbook's value rounded (row 4 of the same column is rounded)". The assertion uses `trunc()` and still holds, so nothing fails.

## Could not do
- Item 10, the V-17 clause on the deck's step-5-loss slide. The plan says "if the slide still fits", and it does not.
  - The highlight box already ends just above the Overview badge. With the clause, it wraps to a fourth line and its border runs to the slide's bottom edge (measured in the printed PDF: border to row 1060 of 1064, against 1034 before).
  - Even the shortest version of the reason adds that fourth line, because the third line is already full.
  - Making room means cutting something else on the slide, which the package does not list. One example is the JR authors' parenthetical, the deck's only attribution of the JR analysis.
  - Left for the coordinator. Options: a cut elsewhere on the slide, splitting the box, or leaving the reason to the report, which now has it.

## Noticed on the way (not changed)
- `bsz-analysis/site/repro.qmd` l.533 (Step 3) still says "payable in five annual installments". This matches the new intro, but it omits the option to pay at once.
- `bsz-analysis/site/slides/slides.Rmd` l.187 and `repro.qmd` l.122 (code-fold comment) still say "the authors' August 2026 workbook" / "the August workbook" without the data-appendix date.
- `bsz-analysis/site/materials.qmd` l.287: "A malformed row in our own source manifest". This is a "we/our" that V-18 did not list.
- `bsz-analysis/VERIFY-AUGUST.md` section 3, "RC10" (l.322-330), is the 2026-09-23 record. It still says the August `data_sec_all` disagrees with its aggregate and is "worth flagging to the authors". Its new header line and table row now say that this applied to the 2026-09-04 copy only.
- `.claude/skills/opa-review-loop/CONTENT-MAP.md` calls `comparison/DISPUTES.md` "the eight disputed inputs". The table now has ten rows.
