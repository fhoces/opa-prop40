# Author answers, 2026-10-16

The author's answers to the open questions of runs 002 and 003 (`002-2026-10-15/04-plan.md`, Q1 to
Q19, and `003-2026-10-16/04-plan.md`, Q1 to Q13), given in the session that ran the loop. Where an
answer keeps the plan's assumption, nothing changes. Ids: `R2-Qn` is run 002's question n, `R3-Qn`
run 003's.

## Changes

| # | Item | Answer | Owner |
|---|---|---|---|
| 1 | A-21 (run 003, blocked) | Relabel the six JR contract rows from "author-shared" to "public" in `rjkdc-analysis/R/export.R` and `rjkdc-analysis/py/run_export.py`. | JR |
| 2 | R2-Q2 JR checks page q rows | Replace the two rows with the 0 floor (q = 0.75, q = 0.50) by the explorer's paired setting (floor 35, q = 0.5, about -$48.2B). | JR |
| 3 | R2-Q9 AI badge | Move the badge off the authors' names: a line of its own ("This OPA site: AI generated, partially reviewed") on the three overviews, and in the JR deck's subtitle. Update `test-ai-badges.R`. | each |
| 4 | R3-Q1 Table A1 | Set the August annualized row back to 43 years, reproducing the paper's and workbook's 7.6%. Disclose that 1982 to 2026 is 44 years (7.4%). Add a per-row expectation for that row. Re-snapshot. Update the report, overview and materials text that disclosed the gap. | BSZ |
| 5 | Comparison deck slide 2 | Replace the `.quote-box` placeholder with the NYT quote below. | DONE in def8da5 |
| 6 | Comparison deck slide 2 | "paid over five years" becomes "payable over five years". | DONE in def8da5 |
| 7 | R2-Q7 AI slide | "trivial" becomes "much easier"; the badge claim becomes "each analysis's pages carry a badge" (no claim that every component does). | comparison |
| 8 | R3-Q13 why-opa-6 | "draw a third OPA in between the two" becomes "build a third OPA that bridges the two, one input at a time". | comparison |
| 9 | R2-Q6 voter guide | Find the Secretary of State's Official Voter Information Guide for 3 Nov 2026, Prop 40. Check each quote on slide 2 against it, put the URL and page numbers in the footnote, and add a `DATA-SOURCES.csv` row. If a quote does not match, report it, do not change it. | comparison |
| 10 | Headline -$39.0B | Stays. Add the closed-form expectation to the comparison report (`comparison/site/repro.qmd`, the open-analysis section near "The draws are independent, so the expectation is the inputs at their means"): E[NPV] = E[WT] - E[f] x E[C] x E[1/(r - g)], with each number filled in from the pipeline (36 - 0.45 x 4.55 x 36.6 = -38.98), and one sentence that the printed -38.9 is one seeded run of the same draws. | comparison |
| 11 | R2-Q11 | "All these are empirical quantities" becomes "Most of these are empirical quantities; H and r are scenario choices." Update the `test-site.R` pin. | comparison |
| 12 | R3-Q3 real estate | The real-estate step's kind becomes "guesswork vs data" (BSZ end guesswork). | comparison |
| 13 | R3-Q4 JR base | The JR base (2025 list grown by an assumed 7%) and `nber_growth_rate` become "guesswork on data". If the kind vocabulary is a closed list, use the closest existing kind and report the choice. | JR contract, then comparison |
| 14 | R3-Q5 5% rate | "data" on both: the BSZ input table and the JR contract. | BSZ, comparison |
| 15 | R3-Q6 JR printed results | In `comparison/data/document-inputs.csv`, the JR printed results ($30B NBER, $40B SSRN) become "derived". Update the counts in `AUDIT.md` and the READMEs. | comparison |
| 16 | R3-Q7 SD test | Add one expectation to `rjkdc-analysis/tests/testthat/test-npv-mc.R`: the seeded SD against the printed 37.6, tolerance 0.34 absolute. The JR pages then say the SD is tested. | JR |
| 17 | R3-Q8 Pareto test | Record the 39.0% (p.27) vs 38.8% (p.28) vs 34.75% (unrescaled discrete share) in the JR MISMATCHES file; test 34.75% tightly, with the chapter's 39.0% noted. | JR |
| 18 | R3-Q10 Table 5 | Row 1 uses BSZ's own label: "Forbes estimates as of 7/1/2026 + 10% evasion/avoidance (half due to mobility)". Re-snapshot `tab5_panel`. | BSZ |
| 19 | R3-Q11 CSV names | Rename the comparison contract's `supporting_*` and `rauh_*` columns to `bsz_*` and `jr_*`, in R, Python, tests and pages. | comparison |
| 20 | R2-Q13 C dial | The C dial's label "yearly tax revenue" becomes "yearly income tax". | comparison (and JR explorer if the same label is there) |
| 21 | R2-Q10 root scope | Add one sentence to the comparison root stating what both numbers measure (wealth tax collected at face value minus the present value of income tax lost), with a link to the report's definition. Do not imply the wealth tax is discounted. | comparison |
| 22 | R2-Q16 residency date | Put the residency date (1 January 2026) back into the first sentence of the three overviews. | each |
| 23 | R2-Q19 checks tables | Generate the BSZ and JR checks pages' tables from each explorer's grid in an R chunk, and pin them in each `test-site.R`. | BSZ, JR |
| 24 | R2-Q12 survey | The survey buttons' line says the survey is "primarily for economists and policy analysts". | comparison (and wherever the buttons appear) |
| 25 | JR explorer | Remove the "Lowest in the grid" button. | JR |
| 26 | Mirror | Mirror the shared-text changes (badge line, residency date, labels) on the BSZ and JR decks where they apply. | BSZ, JR |

NYT quote for slide 2 (The New York Times Magazine, 14 October 2026,
https://www.nytimes.com/2026/10/14/magazine/california-billionaires-tax.html):

> Control of Congress is the biggest issue at stake in November's elections. A close second might
> be the fight over a ballot initiative in California, Proposition 40, that seeks to impose a
> wealth tax on the state's roughly 250 billionaires.

## Unchanged (the plan's assumption stands)

R2-Q1 "have been sent" stays. R2-Q3 the g dial stays, relabelled. R2-Q4 why-opa-4 unchanged.
R2-Q5 slide why-opa-3's two placeholders stay visible. R2-Q8 "three OPAs in about a week"
unchanged. R2-Q14 the -$39.0B headline stays. R2-Q15 no LAO sentence on the root. R2-Q17 no
footnote on the equation label. R2-Q18 the two run-002 kind changes are confirmed. R3-Q2 the JR C
label stays. R3-Q9 the deferral charge stays in words, unsized. R3-Q12 a BSZ object-by-object
credit interview is scheduled for later.
