# WP-8: AUDIT.md evidence
Owner: coordinator. Status: done (one count to confirm after WP-3's rebuild).

## Changed
- `AUDIT.md` header: the dated line now ends "and the evidence of steps 1, 4 and 7 on 2026-10-16 (review loop run 003)".
- BSZ step 1 (E-20): the evidence adds "The current main estimate, the net total, replaced the pre-specified wealth tax on 2026-10-07, after results (`PLAN.md` decision 6)".
- BSZ step 4 (A-19): the "What the next level needs" cell now says the bundle is confidential, the SQL rebuilds the workbook's data sheets from it and checks them against the public workbook, and none of its contents is committed or shown. It replaces "not used by anything published".
- BSZ step 7 (E-14): "18 inputs (... scenario 1 ...)" is now "20 inputs (data 4, research 5, guesswork 5, derived 2, scenario 3, convention 1)". The new note says two scenario rows were added on 2026-10-16: the 5 years and the 3% rate that the main estimate adds.
- JR step 1 (E-20, for consistency): the evidence adds "The September version became the main estimate on 2026-10-14, after results (`PLAN.md` decision 7)".
- Comparison step 1 (E-20): the evidence adds "The rate dial and the equation's order were set on 2026-10-15, after results (`PLAN.md` decisions 12 and 13)".
- Comparison step 4 (E-18): three third-party documents are now listed. Hoopes and the LAO are in `comparison/DATA-SOURCES.csv`, and Walczak (California Tax Foundation, 2026-04-22) is in `rjkdc-analysis/DATA-SOURCES.csv`, each with URL and SHA-256. I checked the Walczak row: it has both.
- No level changes. The vectors and the headline are unchanged.

## Needs a local render
- None.

## Needs a follow-up (files outside the package)
- None. The step 7 count assumes WP-3 adds exactly the H and r rows, both labelled scenario. Confirm in Part C against `bsz-analysis/site/data/inputs.csv` after `targets::tar_make()`.

## Could not do
- None.

## Noticed on the way (not changed)
- The comparison's step 7 counts (19 rows in `document-inputs.csv`) and the JR's (22 inputs) do not change this round: every kind change is a question for the author (Q2 to Q6).
