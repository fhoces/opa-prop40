# Review 2: outside policy experts, run 001
Commit: 1fd9491 (content at main 820bada). Date: 2026-10-14. Pages read: `index.html`, `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`; the three explorers rendered (`comparison/site/explorer/index.html`, `bsz-analysis/site/explorer/index.html`, `rjkdc-analysis/site/explorer/index.html`) plus their `grid.js` and `comparison-data.js` dial and slider data; the three reports rendered (`*/site/repro.html`) and their `.qmd`; the two decks (`*/site/slides/slides.Rmd`); the three materials pages rendered; `README.md`, `bsz-analysis/README.md`, `rjkdc-analysis/README.md`, `comparison/README.md`; `comparison/DISPUTES.md`, `rjkdc-analysis/MISMATCHES.md`, `bsz-analysis/VERIFY-AUGUST.md`, `AUDIT.md`, `PLAN.md`, `review/README.md`, the three `CREDIT.md`, `docs/initiative/README.md`; the labelled inputs (`bsz-analysis/site/data/inputs.csv`, `bsz-analysis/export/r/inputs.csv`, `rjkdc-analysis/export/r/inputs.csv`, `comparison/data/document-inputs.csv`, `comparison/export/r/inputs.csv`), the three `DATA-SOURCES.csv`, and the exports I checked claims against (`comparison/export/r/{ends,endpoints,bridge,loss,hoopes,meta,anchors}.csv`, `comparison/data/hoopes-fig2.csv`, `bsz-analysis/site/data/{tab5,tab5-vs-printed,leavers}.csv`, `*/export/r/outputs.csv`), and `comparison/R/model.R` for the function the pages name.

## Summary
- Counts: blocking 1, major 9, minor 18, suggestion 4
- The three to fix first: E-02, E-01, E-03
- Could I cite this OPA in a scoring memo as it stands? For the two reproductions, nearly: every headline traces to a file, a cell or a PDF page, the tests are named with their tolerances, and the two reproduction reports read like scoring memos. What stops me is the comparison layer's front door. The common output (b) is defined without the conventions a scorer needs (which date is "present", whose dollars, and that the five annual installments of the wealth tax enter undiscounted while the lost income tax over the same five years is discounted); the root page describes an explorer with three settings that the published explorer does not have; the one estimating function that produces every bridge number is explained only in code; and the same test suite is reported as 179, 214 and 389 expectations on three pages. One sentence on the RJKDC overview states a comparison backwards ("36 ... below the about 30"). A hearing opponent would find each of these in ten minutes. All are sentences to fix, not analyses to redo.

## Done well (keep)
- Every main estimate on every page is read from a data file, never retyped; the review ledgers and `test-site.R` files pin the pages to the pipelines. Keep this discipline.
- The two reproduction reports (`bsz-analysis/site/repro.qmd`, `rjkdc-analysis/site/repro.qmd`) derive the headline step by step with each input's page or cell, a notation table, and "Every input, by origin" with the four-kind taxonomy defined in plain words. The RJKDC report's "Internal identities" section labels identities as identities.
- The RJKDC explorer's dial descriptions are the model for the other two: what the input is, the source of each level, and which levels are the reproduction's own ("illustrative").
- Test claims carry tolerances where they matter: BSZ "All 28 cells match ... largest absolute difference 1.4e-16", RJKDC "printed rounding for deterministic figures, four Monte Carlo standard errors for simulated ones", comparison "R and Python agree ... largest difference 5.0e-13 (test-parity.R requires 1e-9)". I checked the 28-cell claim against `tab5-vs-printed.csv`: 26 match, rows 2 and 3 of the income tax loss do not, exactly as the page says.
- The Hoopes digitization is labelled as read off a chart with its tick fit (0.1) and reading uncertainty (0.6 per bar, 0.8 for the thin real-estate bar), and the script is named.
- `MISMATCHES.md` and `DISPUTES.md` are complete, sized and page-referenced; the exact-expectation versus seeded-run distinction is explained with its size (0.09, under one standard error) on the RJKDC report and explorer.
- Numbers I recomputed from the exports agree with the pages: E[1/r] = ln(3)/0.03 = 36.62; 0.45 x 4.55 x 36.62 = 74.98; 36 - 74.98 = -38.98; 28.4% = 1 - 67.51/94.304; 0.5% = 1 - 94.304/94.74; 12.58 = (1 - 35/94.304)/0.05; the loss table's present values and the Walczak and LAO nettings; 11! = 39,916,800 and 2^11 = 2,048.

## Jargon ledger
| Term | Page (file) | Explained there? | A definition that would do |
|---|---|---|---|
| Shapley, "all orders", "one order" | `comparison/site/explorer/index.html` | yes (averaged over all 39,916,800 orders) | kept |
| Shapley | `index.html` ("Shapley averages over all orders as well as one order") | gloss only | "a step's effect averaged over every order the inputs could be switched in, so the steps add to the gap" |
| Shapley | `comparison/site/repro.qmd` | yes, in "The bridge" | kept |
| bridge, step | `index.html`, comparison explorer and report | yes | kept |
| residual | `comparison/export/r/ends.csv` column `rauh_residual`, `comparison/site/repro.qmd` | pages call it "model difference"; the CSV name is not glossed | "residual: the model difference, the common function at the RJKDC inputs minus that version's own Monte Carlo expectation" |
| anchor | `index.html` (Hoopes section), `comparison/README.md` ("Rauh anchor"), `comparison/site/materials.qmd` (`anchors.csv`), RJKDC explorer ("dividend-yield anchor") | no | "anchor: the published number an end of the bridge is checked against" (comparison); "the value a range is calibrated around" (RJKDC) |
| vintage | `index.html` ("The vintage gap"), `bsz-analysis/site/materials.qmd` ("workbook vintage"), `VERIFY-AUGUST.md` | no | "vintage: which dated version of a document or workbook (May or August 2026) a number comes from" |
| NPV, present value | `rjkdc-analysis/site/index.html`, explorer, report | yes (NPV = WT - f.C/r, "worth 22 to 67 dollars today") | kept |
| present value | `index.html`, `bsz-analysis/site/index.html` | used, not defined | "present value: what a stream of future amounts is worth today, discounting each year's amount at the rate r" |
| Monte Carlo, draw | `rjkdc-analysis/site/index.html` ("100,000 random draws of those inputs") | yes | kept |
| Monte Carlo | `index.html` ("averaged over the authors' Monte Carlo draws") | no definition on the root page | "a Monte Carlo: the authors draw each uncertain input at random many times and average the result" |
| exact expectation | RJKDC explorer ("a closed form, since the draws are independent uniforms") | yes | kept |
| exact expectation | `index.html`, comparison explorer footnote | used, not defined | "the exact average of the Monte Carlo, computed by formula rather than by drawing" |
| seeded run, seed | `rjkdc-analysis/site/index.html` ("authors' seeded run, reproduced"), RJKDC explorer, comparison pages | no (the report says "seed 2026" without saying what a seed is) | "seeded run: one run of the random draws started from a fixed seed number, so it gives the same 100,000 draws every time; its mean differs from the exact expectation by sampling error" |
| horizon | all comparison pages, BSZ explorer notes | yes | kept |
| perpetuity | RJKDC overview ("value that lost stream as a perpetuity") | not at first use; defined on the report | "perpetuity: a stream of the same amount every year for ever, worth 1/r times the yearly amount today" |
| elasticity, semi-elasticity | comparison explorer and report ("semi-elasticity"), RJKDC report (notation table) | RJKDC report yes; comparison pages no | "semi-elasticity: the percent of the tax base that leaves for each percentage point of tax" |
| export contract | comparison explorer notes, report, materials | yes | kept |
| export contract | `README.md` (root), `comparison/README.md` | used, not defined | "export contract: the two CSV files (inputs.csv, outputs.csv) each analysis's pipeline writes for the comparison to read" |
| twin (Python twin) | BSZ materials ("Every computation also has a Python twin in py/, with the same function names") | yes | kept |
| twin | `index.html`, comparison explorer, `README.md` | used, not defined | "Python twin: the same computation written a second time in Python, checked against the R result" |
| parity | materials pages ("test-parity.R") | yes | kept |
| grid, cell | BSZ and RJKDC overviews and explorers ("2,187 combinations ... Each cell holds") | yes | kept |
| dial, switch | BSZ and RJKDC explorers | by use | "dial: an input with a fixed set of levels; switch: a dial with two" |
| slider | comparison explorer | yes (five positions explained) | kept |
| `{targets}` | BSZ and RJKDC overviews ("built with {targets}") | no | "{targets}: the R package that runs the pipeline's steps in order and records which outputs are current" |
| pipeline | all pages | by use | "pipeline: the scripted sequence of steps from the authors' files to every number on these pages" |
| CI | `README.md` status table, `AUDIT.md`, `bsz-analysis/README.md` | no (the materials pages say "GitHub Actions" instead) | "CI: continuous integration, an automatic rebuild and test run on every change" |
| origin labels (data, research, guesswork, scenario, derived, convention) | comparison explorer, comparison and both reports | yes | kept |
| origin labels | BSZ explorer chips (GUESSWORK, RESEARCH), BSZ overview ("which of its inputs are data and which are guesses") | no | the four-line taxonomy already on the comparison explorer |
| compound kinds ("guesswork on data", "data vs guesswork", "scenario + guesswork", "guesswork + data") | comparison explorer bridge table, `index.html` disputed-inputs table, `DISPUTES.md` | no | "a compound kind reads BSZ's kind against RJKDC's, or the two kinds a step mixes" (see E-19) |
| the OPA layers (Open Output, Open Analysis, Open Materials) | every page's layer cards | yes on the decks ("What is an Open Policy Analysis?") and by the cards | kept; one line on each overview would help: "Open Output: the estimate and its dials; Open Analysis: how it is computed; Open Materials: what to run" |
| nominal | BSZ explorer caption, BSZ report | yes there; absent from the comparison pages | see E-02 |
| litigation weight, q | RJKDC overview, explorer, comparison explorer | yes | kept |
| Pareto, b, alpha | BSZ and RJKDC reports and decks | yes | kept |

## Findings

### E-01. The root page describes an explorer the site does not publish  [major] [comparison]
- Where: `index.html` lines 336-340 (the Open Output card), lines 391 and 397-400 ("A common output definition"); same lines in `comparison/site/index.template.html`; `comparison/README.md` lines 96-99.
- Now: "Its settings switch the output (net fiscal effect or gross revenue), how each step is sized (averaged over every order, or one order) and how long the lost income tax lasts." and "(a) is the secondary setting." and "It is therefore a setting on the explorer's bridge, not a fixed choice." README: "with settings for the output, the step sizes and the loss horizon".
- Problem: the rendered explorer has one setting, "How each bar is sized" (Shapley or one order). The horizon is a slider in each panel, not a bridge setting ("The bridge uses each analysis's own horizon"), and no gross revenue figure appears on the explorer at all; `comparison/site/materials.html` says `test-site.R` asserts "the explorer shows no gross revenue number". Output (a) now lives only in the report's second bridge table. A reader sent to the explorer for "(a)" or for a horizon setting on the bridge will not find either.
- Proposed: card text "The explorer: the two main estimates on one definition, the net fiscal effect, in two panels of sliders, one per disputed input, and the bridge between them, a waterfall with one bar per input. Its one setting sizes the bars, averaged over every order or in one order; the horizon is a slider in each panel. Gross revenue, output (a), is in the report." Line 391: "(a) is the secondary output, shown in the report." Lines 397-400: "It is therefore a slider on each explorer panel, not a fixed choice." Same edit in the template and `comparison/README.md`.
- Also on: `comparison/README.md` "Open Output" paragraph.

### E-02. Output (b) is defined without its discounting and dollar conventions  [major] [comparison]
- Where: `index.html` lines 393-396 (the definition block) and the headline footnote; `comparison/site/explorer/index.html` footnote 1 and "Two panels, one estimating function"; `comparison/site/repro.qmd` "The common output, and what each analysis reports".
- Now: "(b) net fiscal effect = (a) + extra income tax from assets sold to pay - present value of income tax lost to departures, over a horizon of H years. (a) gross revenue = one-time wealth tax collected."
- Problem: a scorer needs four things the definition does not say. (1) The valuation date of "present": the only statement is the RJKDC explorer's caption "present value at the time the tax is collected". (2) Whose dollars: nominal, 1 July 2026 Forbes values for the BSZ end (said only on the BSZ explorer caption, "Nominal dollars, 1 July 2026 Forbes wealth") and a base grown 7% to 31 December 2026 for the RJKDC end (said only in the revision slider note); the word "nominal" appears on no comparison page. (3) The wealth tax is "paid over five years" (every page's first sentence) with a deferral charge (`DISPUTES.md` row 1), yet (a) enters undiscounted while the lost income tax over the same five years is discounted at 1.5% to 4.5%. Both analyses do this, so the OPA follows them, but the definition should say so: the asymmetry is worth roughly $6B to $9B at the BSZ end (five equal installments of $20.8B discounted at 3% are about $98B if the first is paid at assessment and about $95B if a year later, not $103.8B) and it is not a bridge step. (4) The RJKDC code labels the 1.5% to 4.5% draw (r - g), not r (`MISMATCHES.md` 3); the comparison calls it "the discount rate, r" without the caveat.
- Proposed: add after the definition block: "Conventions. All amounts are nominal billions of dollars. The wealth tax is counted at its face value when assessed (the BSZ analysis values the base on 1 July 2026, the RJKDC analysis on 31 December 2026), undiscounted although the Act collects it in five annual installments; both analyses do this, so the comparison follows them. Present values are at the assessment date. Discounting uses the RJKDC analysis's 1.5% to 4.5% range, which its code labels (r - g) and its text r (see the RJKDC analysis's mismatch 3)."
- Also on: `comparison/site/explorer/index.html` footnote; `comparison/site/repro.qmd` "The common output".

### E-03. A comparison stated backwards on the RJKDC overview  [major] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` lines 359-360.
- Now: "Second, the Monte Carlo draws revenue with a mean of 36, the paper's litigation-discounted ceiling (0.5 x 72), below the "about 30" it prints as collectible."
- Problem: 36 is above 30, not below. The numbers on the page are right (36.00 and "about 30 (28.4 to 35.6)" in the table above the sentence); the sentence inverts their order.
- Proposed: "Second, the Monte Carlo draws revenue with a mean of 36, the paper's litigation-discounted ceiling (0.5 x 72), above the "about 30" it prints as collectible (0.5 x the $59.15B recognized base)."

### E-04. The discount-rate range carries two origin labels  [major] [RJKDC]
- Where: `rjkdc-analysis/export/r/inputs.csv` rows `rauh_mc_r_min`, `rauh_mc_r_max` (label "research"); `rjkdc-analysis/site/explorer/index.html` dial "Discount rate drawn, r" (GUESSWORK); `rjkdc-analysis/site/repro.qmd` Step 4 ("The range is guesswork") and the "Inputs by origin" table (dial row `rate`, guesswork); `comparison/DISPUTES.md` row 2 ("research (discount rate)").
- Now: contract and DISPUTES say research; explorer and report say guesswork.
- Problem: the same input, the same value (1.5% to 4.5%), two origins on pages that cite each other. The OPA's own argument ("six of the seven inputs are guesswork") depends on the count.
- Proposed: pick one and say why. The S&P 500 dividend-yield anchor is a published figure, the width of the band is the authors' choice; "research (anchor) + guesswork (range)" in the contract, with the explorer chip and the report's Step 4 reading the same, would be honest and consistent.
- Also on: see E-24 (the contract rows for C and r are filtered out of the report's origin table).

### E-05. The one estimating function is explained only in code  [major] [comparison]
- Where: `comparison/site/repro.qmd` "The two ends, estimated on it" and "The two main estimates" (the function appears only inside the "R or Python code" folds); `comparison/site/explorer/index.html` "Two panels, one estimating function".
- Now: "That function, score_common(), computes both analyses: every disputed input is one of its arguments, and it returns the net fiscal effect."
- Problem: every bridge number comes from eight lines of arithmetic that no page states in words. The two non-obvious ones are S = 1 - (d_conf + max(d_conf, eps x dtau))/2, which represents the RJKDC revenue as the midpoint of a uniform between the confirmed-departures ceiling and the elasticity floor (so "Permanent-rate" and "Elasticity size" act only through that floor, which is why the explorer has to print "No effect while the other sliders stay where they are"), and f = alpha m + kappa (1 - S)(1 - alpha m), which combines the BSZ movers' share with the RJKDC proportional loss. `comparison/R/model.R` lines 1-24 already contain the prose needed, as a comment. A colleague landing on the report cannot check a step without reading R.
- Proposed: lift the `model.R` comment block into the report under "The two ends" as a numbered list: R0 (no-behaviour revenue), S (share of the base still taxed: the mean of the RJKDC uniform between the confirmed-departure ceiling and the elasticity floor), WT = output (a), X (asset-sale income tax), f (share of billionaire income tax lost), PV = f x C x E[annuity(r, H)], and (b) = WT + X - PV, each with the argument name the slider table uses, its unit and the step it belongs to. Repeat the two-line version of S and f on the explorer under "Two panels".

### E-06. BSZ explorer dials do not say whose levels they are, and the origin chips are undefined  [major] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html` lines 231 (legend: "the value the authors use") and 355-366 (the tooltip: `dial.desc` plus "The authors use: 10% (guesswork)"); `bsz-analysis/site/explorer/grid.js` dial descriptions; `bsz-analysis/site/index.html` ("marks which of its inputs are data and which are guesses").
- Now: the tooltip for avoidance reads "Share of listed wealth that escapes the tax. GGSS p.4: 'a relatively small avoidance rate of 10%', argued from enforcement, not estimated. The authors use: 10% (guesswork)." The levels 0, 5, 15, 20, 30% have no stated origin; the chip "GUESSWORK" and "RESEARCH" are defined nowhere on the BSZ site's explorer or overview.
- Problem: the brief's test for a dial is what the input is, why these levels, whose value each level is. The first is met, the other two are not. The RJKDC explorer meets all three ("Source of the other two levels: the authors' first version"). The origin taxonomy is defined on the comparison explorer and both reports but not on the page that paints the chips.
- Proposed: one line under the rack legend: "Levels other than the authors' are this OPA's, chosen to bracket the authors' value; the explorer holds every combination. Origins follow the OPA taxonomy: data (settled by observable facts), research (a published estimate), guesswork (asserted without data or a study behind it), scenario (which world is estimated)." In each tooltip, "Other levels: this OPA's."

### E-07. The RJKDC explorer prints two values for the main setting  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/explorer/index.html` lines 360-362 (`npvOf` returns `printed_npv` only at the main setting) and 418-422; the outcomes table below it.
- Now: headline "Main estimate, NBER September 2026: -$38.9B ... Seeded rerun of the authors' script: -38.89; exact expectation of this setting: -38.98." Table: "Mean NPV to the state ($B): This setting -39.0, NBER Sept 2026 -39.0."
- Problem: at the main setting the box shows the printed seeded value and the table the exact expectation; move any dial and the box switches to the exact expectation. The sub-line explains it, but the box and the table are ten lines apart with different numbers for the same setting.
- Proposed: add a first row to the outcomes table, "Mean NPV, as printed (seeded run): -38.9 | -38.9", so the table carries both, and label the box "as printed" at the main setting.

### E-08. Three test counts for one suite, and two for another  [blocking] [all]
- Where: `README.md` lines 62-64 (Status table: BSZ "561 expectations", comparison "179 expectations"); `AUDIT.md` line 290 (reconciliation step 8, "214 expectations (counted on the materials page when it renders)"); `comparison/site/materials.html` ("389 expectations passed, 0 failed, in 32 test blocks"); `bsz-analysis/site/materials.html` and `bsz-analysis/README.md` (719).
- Now: the comparison suite is 179 (README), 214 (AUDIT) and 389 (materials page); the BSZ suite is 561 (README) and 719 (materials page, report, BSZ README).
- Problem: a count is a claim about what was tested. At most one of the three can be current; the generated materials page is the one rendered from a run (2026-10-14), so the README and AUDIT figures are unsupported as they stand. `VERIFY-AUGUST.md`'s "has since grown to 561" is a dated record and is fine.
- Proposed: in `README.md` and `AUDIT.md`, either read the counts from `site/data/test-results.csv` and `test-summary.csv` as the materials pages do, or replace the numbers with "see the materials page" and a date. If the numbers stay, make them 719, 159 and 389 with the run date.
- Also on: `AUDIT.md` reconciliation step 8.

### E-09. The audit's headline vector contradicts its own table  [major] [all]
- Where: `AUDIT.md` lines 296-297 and the reconciliation table at lines 281-291.
- Now: "Vectors: BSZ 1-3-3-3-3-3-3-2-3, RJKDC 1-3-3-3-3-3-3-2-3, reconciliation 1-3-2-2-2-3-3-2-3."
- Problem: the reconciliation table scores steps 3, 4 and 5 at Level 3 ("None (top level)", "None", "None"), so its vector is 1-3-3-3-3-3-3-2-3. The headline level (1) is unaffected; the evidence line is wrong. The table was updated 2026-10-14 and the vector was not.
- Proposed: "reconciliation 1-3-3-3-3-3-3-2-3", and a note that the three vectors are now identical.

### E-10. The Shapley identity is listed as a reproduced result  [minor] [comparison]
- Where: `comparison/site/repro.qmd` line 552 ("What reproduces", second bullet); `comparison/site/explorer/index.html` line 537.
- Now: "The bridge adds up. In every horizon setting and for both outputs, the Shapley steps sum exactly to the distance between the two model ends (test-shapley.R), and they match a brute-force average over orders."
- Problem: that the Shapley values sum to the total is the efficiency property of the method, an identity; the test checks the code, not the analyses. Listed beside "Both ends" it reads as a finding.
- Proposed: "The code does what the method says. Shapley values sum to the gap by construction; test-shapley.R checks that ours do in every setting and that they equal a brute-force average over orders." Move it to a "Checks of the code" line, or into the materials page.

### E-11. A Shapley bar carries interaction shares; the explorer calls it the effect of moving one assumption  [minor] [comparison]
- Where: `comparison/site/explorer/index.html`, "The bridge" paragraph ("Each bar between the two ends is the effect of moving one assumption all the way from the BSZ value to the RJKDC value") and "What a step adds depends on which other inputs have already moved".
- Problem: order dependence is disclosed well, and the one-order view shows it. What is not said is that a Shapley bar is an average that includes a share of every interaction the input takes part in, so "-$33.6B for Permanent-rate" is not the effect of that assumption on its own (first in the order it is -$11.1B as the page shows elsewhere). One sentence closes the gap.
- Proposed: after "The default bars are Shapley values": "Because the inputs interact, a Shapley bar is an average that includes each input's share of those interactions; it is not the effect of moving that input alone, which 'One order' shows for one sequence."

### E-12. Silences an expert will notice, with no "out of scope" statement  [major] [all]
- Where: `index.html`, `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html` (no section says what the OPA does not cover); `docs/initiative/README.md` is linked from no page (grep: the only mentions of the initiative's text are in the skill files).
- Now: silence on: the timing of collections (five installments, the deferral charge in the Act; E-02); interaction with federal tax (the asset-sale step counts the 13.3% state rate only; forced realizations also create federal liability and the state tax is partly deductible, neither of which either analysis models); valuation and administration (the measure's own valuation rules, the FTB's cost); revenue volatility (GGSS p.4 fn.8's "$87 billion to $107 billion" daily range is quoted only in the BSZ report's Step 1); litigation risk on the BSZ side (present only as the RJKDC analysis's q); the measure's own text (committed in `docs/initiative/` and never linked).
- Problem: the brief asks that silence be flagged, not that new analysis be added. A scorer will ask each of these and should be told in one place that the OPA follows the two analyses' scope and where each question is addressed.
- Proposed: a short "What this OPA does not estimate" paragraph on each overview, before the credit section: "Both analyses, and so this OPA, take the measure's 5% rate, five annual installments and 1 January 2026 residency date as written (full text: docs/initiative/) and count the wealth tax at face value. Neither models federal tax interactions, valuation or administration costs, or the day-to-day volatility of the Forbes base (GGSS p.4 fn.8: $87B to $107B between January and July 2026). The RJKDC analysis alone weights for litigation risk (q); the BSZ analysis alone adds the income tax from forced asset sales. These are out of scope here."

### E-13. The Hoopes "Galle estimate" bar has an uncertainty on one page and none on another  [minor] [comparison]
- Where: `index.html` Hoopes table, first row; `comparison/site/repro.html` same table; `comparison/data/hoopes-fig2.csv` row `galle_estimate` (uncertainty 0.6, note "top clipped by the axis frame at 100; value from p.3 text").
- Now: overview "Galle estimate | $100B | $100B"; report "Galle estimate | $100.0B +/- 0.6 | $100.0B".
- Problem: the same CSV row prints with and without its reading uncertainty, and neither page says the bar's top is clipped and the value is taken from the text.
- Proposed: print "$100B (from the text; the bar is clipped by the frame)" on both, or "+/- 0.6" on both.

### E-14. Mixed significant digits in the common-output table  [minor] [comparison]
- Where: `index.html` lines 429-433 ("The two analyses on the common output"); `comparison/site/repro.html` same table.
- Now: "(b) net fiscal effect: $106.8B | -$38.98B; (a) gross revenue: $103.8B | $36.0B".
- Problem: one decimal for the BSZ row and two for the RJKDC row in the same column. The explorer and the headline footnote use "-$39.0B" and give -38.98 in the text.
- Proposed: one decimal in the table (-$39.0B), with "-$38.98B exact" kept in the paragraph below it; or two decimals for both rows.

### E-15. "Within a stated tolerance" without the tolerance  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` "What reproduces" (row "Tables 1 to 4 and A1 ..."); `bsz-analysis/site/materials.html` "Tests" ("they check that the explorer reproduces Table 5 exactly").
- Now: "Every formula cell the pipeline re-derives matches the workbook's cached value within a stated tolerance."
- Problem: the tolerances are stated only in `bsz-analysis/README.md` ("tab5_r 1e-4; billionaires_ca_inctax_r 1e-3 / 1e-2; ..."). The explorer test uses 1e-12 (`tests/testthat/test-site.R` lines 34, 58-61), so "exactly" is fair but a number is better.
- Proposed: "within the tolerances listed in the README (1e-4 for Table 5, 1e-3 to 1e-2 for the formula sheets, where the workbook rounds to cents)"; materials page: "reproduces Table 5 to 1e-12".

### E-16. Two footnotes numbered 1 on the BSZ overview  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html`, the headline block footnote and the Table 5 "Total (main estimate)^1" footnote.
- Now: both read "The main estimate is not the authors' choice: BSZ's headline is the wealth tax alone ..." (the second with the definition prepended).
- Proposed: number the table's note 2, or point the table's superscript at the first footnote.

### E-17. The q dial can count litigation risk twice, and no setting reproduces the README's mechanism  [major] [RJKDC]
- Where: `rjkdc-analysis/site/explorer/index.html` dial "Litigation survival, applied to revenue" (text from `rjkdc-analysis/R/site.R` line 77).
- Now: "Probability the Act survives constitutional challenge, as a multiplier on revenue collected (the mechanism the NBER README states). The script has no such multiplier, so the main estimate uses 1. The script instead puts q into the 0 lower bound (mismatch 5)."
- Problem: with the revenue floor left at "0 (as coded)", setting q = 0.50 gives E[WT] = 18, half the paper's $36B: the risk is in the draw and in the multiplier. The README's mechanism is q times the recognized base (0.5 x 59.15 = 29.57), and no combination of the wt_lo and wt_hi levels gives 59.15, so the dial labelled "the mechanism the NBER README states" cannot produce the README's number. The dial should say what it does and does not do.
- Proposed: add: "With the floor at 0 the draw already carries the litigation risk, so q below 1 counts it twice; to read q as the README does, set the floor and ceiling to the same value. The README's own figure, 0.5 x the $59.15B recognized base = $29.57B, is not a level of this grid."

### E-18. "Seeded run" and "seed" undefined at first use  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` ("Mean NPV, authors' seeded run, reproduced: -38.89"); `rjkdc-analysis/site/explorer/index.html` ("the paper prints one seeded run of 100,000 draws"); `index.html` headline footnote ("the authors' seeded run gives -$38.9B").
- Proposed: at first use on each page: "seeded run: one run of the random draws started from a fixed seed number (2026), so it gives the same draws every time".

### E-19. Compound kinds are outside the taxonomy the page defines  [minor] [comparison]
- Where: `comparison/site/explorer/index.html` bridge table, Kind column and the sentence "Kinds follow the OPA input taxonomy: data ..., research ..., guesswork ... and scenario ..."; `index.html` disputed-inputs table; `comparison/DISPUTES.md` "Kind" column.
- Now: "guesswork on data", "scenario + guesswork", "research + guesswork", "data vs guesswork", "research vs guesswork", "guesswork + data".
- Problem: the legend defines four kinds; six rows use compounds whose grammar differs ("on", "+", "vs") and is not explained. A reader cannot tell whether "data vs guesswork" means the two analyses' values have different origins or the step mixes two.
- Proposed: one legend line: "'A vs B' reads the BSZ value's kind against the RJKDC value's; 'A + B' means one value rests on both; 'guesswork on data' means a judgment applied to observed facts."

### E-20. The BSZ main estimate is discounted two ways; the effect of the 3% choice is never shown  [suggestion] [BSZ]
- Where: `bsz-analysis/site/index.html` headline ("present value, 5 years at 3%"); `index.html` and `comparison/site/explorer/index.html` footnotes ("with the 5 years discounted over the RJKDC analysis's 1.5% to 4.5% rate range instead of at 3%"); `bsz-analysis/site/explorer/index.html` "Notes and data: Horizon".
- Problem: the choice of 3% (the midpoint) is justified and the two conventions are disclosed, but no page says what the rate does to the main estimate. From `loss.csv` and `meta.csv`: the five-year loss is $0.70B at 3% and $0.70B over the range (A_5 = 4.58); at 1.5% it is $0.73B, at 4.5% $0.67B. The deck checks the two agree to $0.01B inside a hidden `stopifnot`.
- Proposed: in the BSZ explorer's Horizon note: "At 1.5% the five-year loss is $0.73B and at 4.5% $0.67B, so the rate moves the main estimate by less than $0.1B; the horizon, not the rate, is what matters."

### E-21. No page ranks the RJKDC inputs by how far they move the result  [suggestion] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` ("the explorer shows how far each one moves it"); `rjkdc-analysis/site/repro.qmd` "Every input, by origin".
- Problem: the BSZ report has "How far the guesses move the result" (one-at-a-time ranges) and the BSZ deck a tornado; the comparison explorer names its three largest steps. The RJKDC pages say six of seven inputs are guesswork but never order them.
- Proposed: the same one-at-a-time table on the RJKDC report (each dial at its three levels with the others at the NBER setting), read from `grid.js`, and the one-line ranking on the overview.

### E-22. Five sources in the BSZ manifest have no URL  [minor] [BSZ]
- Where: `bsz-analysis/DATA-SOURCES.csv` rows 5-10 (`url_or_contact` = "not recorded (source URL unknown; obtained directly by user)"): the GGSS July 2026 expert report, the controlling-shares note, the legal memo, the Props 41-42 note, the response to Rauh, the Saez presentation.
- Problem: the comparison's bridge cites two of them as the source of inputs ("GGSS 20 Jul 2026 p.2 fn.1" for the $150B non-citizens; "GGSS response to Rauh, 17 Mar 2026, pp.1-3" for the "none applied" step), and `DISPUTES.md` cites all of them by page. A reader cannot obtain them from the manifest.
- Proposed: record the URLs (the GGSS report and response are public), or "available from the author on request" with a contact, and say on the comparison materials page that these two documents are listed in the BSZ manifest.

### E-23. The RJKDC contract's NBER outputs carry no page; the report types the pages in  [minor] [RJKDC]
- Where: `rjkdc-analysis/export/r/outputs.csv` rows `nber_domestic_grown`, `nber_ceiling`, `nber_international`, `npv_mc_nber_*` (`printed_page` NA); `rjkdc-analysis/site/repro.qmd` lines 568-572 (`page_nber <- c(revenue_baseline = "19", ...)`, "typed, like the printed values"); `rjkdc-analysis/site/materials.html` ("outputs.csv: every headline figure: reproduced value, printed value, page, absolute difference").
- Problem: the materials page promises a page per output; six NBER rows have none, and the report patches them with a typed vector. Also `revenue_baseline` is page 10 in the contract (the first version's PDF) and page 19 in the report (the chapter's PDF), with no column saying which PDF.
- Proposed: fill `printed_page` for the NBER rows in `R/export.R`, add a `printed_doc` column (ssrn / nber), and drop `page_nber` from the report.

### E-24. The report's origin table drops the contract's C and r ranges  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/repro.qmd` line 532 (`first_only <- inputs$version == "ssrn" | grepl("^rauh_mc_", inputs$input_id)`).
- Problem: `rauh_mc_c_min`, `rauh_mc_c_max`, `rauh_mc_r_min`, `rauh_mc_r_max` are version "both" in the contract and feed the NBER Monte Carlo (the report's Steps 3 and 4), but the pattern sends them to the appendix as first-version rows; they return only as explorer dial rows with a different label for r (E-04). The counts under the table ("data 9, research 1, guesswork 9") are therefore counts of a mixed list.
- Proposed: filter on `version == "ssrn"` only, and let the four rows appear with their contract labels.

### E-25. The NBER chapter's author list differs between pages  [minor] [all]
- Where: `index.html` line 288 ("latest version Jaros and Rauh, NBER, September 2026"); `rjkdc-analysis/site/index.html` line 229 ("Jaros and Rauh, with Kearney, Doran and Cosso, The Net Present Value of the Billionaire Tax Act (NBER chapter c15504)"); `rjkdc-analysis/README.md` ("Jaros, B., & Rauh, J. (2026, September)"); `rjkdc-analysis/DATA-SOURCES.csv` ("Jaros, Rauh (NBER)"); the RJKDC deck ("Jaros and Rauh, with Kearney, Doran and Cosso ... litigation-weighted").
- Problem: a scorer cites the chapter by its authors. Two pages give two, three give five, and none says which is the chapter's own byline.
- Proposed: state once, on the RJKDC overview, the chapter's byline as printed on its cover (p.1) and use it everywhere; if the chapter lists two authors, say "Jaros and Rauh (NBER c15504, September 2026); the March 2026 version was by Rauh, Jaros, Kearney, Doran and Cosso".

### E-26. "The credit interview has not been run" beside a filled-in CREDIT.md  [minor] [comparison] [RJKDC]
- Where: `index.html` line 620 ("The credit interview has not been run for the comparison yet."); `rjkdc-analysis/site/index.html` line 450 ("... for this analysis yet."); `comparison/site/credit/CREDIT.md` and `rjkdc-analysis/site/credit/CREDIT.md` (dated 2026-10-01, full matrices: "The author answered the 14 roles once, for the BSZ Explorer, and asked for the same answers to be applied to every object on all three pages").
- Problem: the overview tables render empty while the linked records are complete; a reader cannot tell which is true. (The CREDIT.md files are read-only by decision; the finding is for the author.)
- Proposed: either render the CREDIT.md matrices on the two overviews with the sentence "answered once for the BSZ explorer and applied to every object; verification answered per object", or change the CREDIT.md status line to say the matrices are carried over pending an interview.

### E-27. Walczak and LAO rows: whose dollars and whose horizon  [minor] [comparison]
- Where: `index.html` "Neutral material and credited alternative dials" table and its note ("Present values use the same r range as the bridge. The last column puts each loss against the RJKDC analysis's expected revenue (September 2026), $36.0B, in perpetuity").
- Problem: `loss.csv` computes `net_at_rauh_revenue_perpetuity` against `ea$rauh_own` = $51.26B (the March version's expected revenue: 51.26 - 5.61 = 45.65 for BSZ row 1), while the page prints $30.4B for the same row (36.0 - 5.6). The page's numbers are right for the September revenue the note names, but the exported column does not match the page's column, and the materials page lists `loss.csv` as what the page quotes.
- Proposed: either add a `net_at_nber_revenue_perpetuity` column to `loss.csv` and read it, or rename the existing column and state on the materials page which revenue it nets against.

### E-28. Explorer intermediate slider positions print values without a kind  [suggestion] [comparison]
- Where: `comparison/site/explorer/index.html` slider rows (positions 1 to 3 are "three evenly spaced steps between them").
- Problem: the end positions carry the analyses' sources; a position such as 2.5 pp or $75B of non-citizens is a construction of this OPA with no source, which is said once in the panel introduction but not where the value is printed.
- Proposed: when a slider is at positions 1 to 3, print "(between the two analyses' values)" under the current value, as the BSZ explorer prints "a setting the authors did not publish" in its headline.

### E-29. BSZ deck's "study in brief" figures sit beside different values elsewhere  [suggestion] [BSZ]
- Where: `bsz-analysis/site/slides/slides.Rmd` lines 57-71 ("They pay about 0.2% of their wealth a year in California income tax ($3.2 billion a year), 2.4% of the state's income tax revenue over 2023 to 2025").
- Problem: the deck says these are the abstract's own figures and that every later number is the pipeline's, which is fair; but C = $3.06B (the 2019-2025 average) is the input every other page uses, and the deck does not say the $3.2B is the 2023-2025 average on the same table.
- Proposed: "($3.2 billion a year over 2023 to 2025; the 2019 to 2025 average the estimate uses is $3.06 billion, Table 2)".

### E-30. The CI acronym and the "{targets}" name are used without a gloss  [minor] [all]
- Where: `README.md` Status table ("CI" column), `AUDIT.md` ("CI must not depend", step 8), `bsz-analysis/README.md`; `bsz-analysis/site/index.html` and `rjkdc-analysis/site/index.html` ("built with {targets}").
- Proposed: the ledger's definitions, once per page at first use; the materials pages' "GitHub Actions rebuilds ... on every push" wording is the right model.

### E-31. "Vintage" and "anchor" undefined where first used  [minor] [all]
- Where: `index.html` section "The vintage gap" (the word is the heading); `bsz-analysis/site/materials.html` ("The default workbook vintage is August 2026"); `comparison/README.md` and `DISPUTES.md` ("the Rauh anchor"); `comparison/site/materials.html` (`anchors.csv`); `rjkdc-analysis/site/explorer/index.html` ("dividend-yield anchor").
- Proposed: the ledger's definitions at first use on each page.

### E-32. The root README's Status table is stale on three counts  [minor] [all]
- Where: `README.md` lines 60-64.
- Now: BSZ "561 expectations", comparison "179 expectations"; comparison "Comparison overview at the site root, explorer, report and materials page; 8 disputed inputs".
- Problem: E-08 covers the counts. The description does not mention the two slider panels that the AUDIT and the explorer now lead with.
- Proposed: fold into E-08's fix, and read the counts from the test-summary files.

## Also noted, no change asked
- The seeded mean -38.886 is printed as -38.89 on the RJKDC overview table, -38.9 in the headline and -38.886 on the comparison report; all are the same number at different precision and each page says which it is.
- The BSZ explorer's "Highest total ($157.8B)" and "Lowest total ($63.2B)" presets are the grid's extremes and say so.
- `DISPUTES.md` row 3 and the RJKDC f dial use 94.2 and give 28.3%; the bridge uses 94.304 and gives 28.4%; the root page explains the difference in a note. Good.
