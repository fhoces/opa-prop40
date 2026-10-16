# WP-8: READMEs and the audit
Owner: coordinator. Status: done.

## Changed
- `README.md`: Layout line "the dial-path bridge with a Shapley check"; Status row "10 disputed inputs (`DISPUTES.md`), 8 explorer dials and a switch for 3 minor inputs" (A-27, E-29, V-29).
- `comparison/README.md`: the review heading and its note give −$39.0 billion, the figure the explorer and the comparison review chain show (`review/comparison.json` headline "$106.8B and −$39.0B"), with "Jaros and Rauh print −$38.9 billion from one seeded run" (A-01, E-04, E-29).
- `comparison/README.md`: "What it reads" no longer lists the Monte Carlo ranges under `document-inputs.csv` and says they come from the JR contract (PLAN decision 4); the rate is described as the draw of r − g; the `R/model.R` row names the dial path; the Tests paragraph names the dial-path check (E-29, A-10).
- `rjkdc-analysis/README.md`: the dated count "159 expectations in 29 test blocks" becomes a link to the materials page's live count (E-29).
- `AUDIT.md`: header dated for the 2026-10-15 evidence update. JR step 1: the SSRN estimate "stays in the pipeline and the report as the first version; the comparison uses the September 2026 version" (A-27). JR step 7: 22 inputs (data 10, research 4, guesswork 6, derived 1, scenario 1). Comparison step 1: JR −$39.0B (exact average; the chapter prints −$38.9B) and the dial-path equation. Comparison step 2: the dials' stops (five, three for departures, two for the list and the minor switch) and the report's bridge as the dial path with the Shapley check. Comparison step 7: 19 rows (scenario 3) and the two kind corrections. BSZ and JR step 1: the checks pages as robustness evidence (E-31). No level changes.

## Needs a local render
- none

## Needs a follow-up (files outside the package)
- None.

## Could not do
- Nothing.

## Noticed on the way (not changed)
- `rjkdc-analysis/site/checks.qmd` (WP-5's file), Results table, first-version row: "How to set it" says 'Explorer: Jump to "First version, March 2026"', but the JR explorer has no such button (`ORDER = [MAIN, "rate15", "rate45", "q50"]`; line 268 says the page does not show the first-version setting). The setting can be reached only by moving three dials (lowest revenue 35, highest 67.51, share lost "1 - WT/94.2"). For the final review.
- `.claude/skills/opa-review-loop/CONTENT-MAP.md` still says "the eight disputed inputs" (a loop file, listed under Do later).

## Checks
- Counts recomputed from the files: `DISPUTES.md` rows 1 to 10; `document-inputs.csv` 19 rows (data 7, guesswork 5, derived 4, scenario 3); `rjkdc-analysis/export/r/inputs.csv` 22 inputs (data 10, guesswork 6, research 4, scenario 1, derived 1).
- No "Shapley bridge", "8 disputed", "comparison page's anchor", "20 inputs in" or "18 rows in" left in `README.md` and `AUDIT.md`; no em or en dash in any added line; `check_links.py` reports no broken link.
