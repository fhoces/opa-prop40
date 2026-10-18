# Review 2: outside policy experts, run 010
Commit: 05859dd. Date: 2026-10-17. Pages read: `index.html`, `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`; the three explorers rendered in headless Chrome with every tip and fold opened (`comparison/site/explorer/index.html`, `bsz-analysis/site/explorer/index.html`, `rjkdc-analysis/site/explorer/index.html`); the three reports rendered (`*/site/repro.html`) with their `.qmd`; the three decks (`comparison/site/slides/slides.Rmd`, `bsz-analysis/site/slides/slides.Rmd`, `rjkdc-analysis/site/slides/slides.Rmd`); the three materials pages rendered; the two checks pages (`bsz-analysis/site/checks.html`, `rjkdc-analysis/site/checks.html`, public but missing from CONTENT-MAP); `README.md`, `comparison/README.md`, `bsz-analysis/README.md` (top), `rjkdc-analysis/README.md` (top); `comparison/DISPUTES.md`, `AUDIT.md`, `docs/initiative/README.md` and the Act's text (§50301); the exports `comparison/export/r/{dial_path,ends,meta,inputs,endpoints}.csv`, `rjkdc-analysis/export/r/inputs.csv`; `comparison/R/model.R`, `build.R` (bridge inputs), parts of `site.R`; the comparison tests' tolerances; and, as the wording reference, `comparison/survey/mock_forms.py` with its texts evaluated from the exports.

## Summary
- Counts: blocking 1, major 7, minor 18, suggestion 2
- The three to fix first: E-01, E-02, E-24
- Could I cite this OPA in a scoring memo as it stands? As a reconciliation, nearly. Every number I traced reproduces from a named file. I recomputed the dial path from `score_common()` and it matches `dial_path.csv` to the cent. The test claims I checked are stated with their tolerances and the tests support them (`test-endpoints.R`, `test-parity.R`, the 600-mix `model.js` check in `test-site.R`). The method's order dependence and the Shapley interaction are disclosed with sizes. Five things stop me citing it. First, the root page's one-line definition of the common output leaves out the asset-sale income tax that its own headline includes (E-01). Second, the headline equation labels −$81.34B "Lost income tax", yet the two analyses' lost income tax differs by $74.3B. The $8.33B in between is BSZ's avoidance movers carried into the perpetuity, and the root page never says so (E-02). Third, the 3% rate is a plain discount rate on the BSZ pages and a rate net of growth (r − g) in the comparison (E-03). Fourth, the same input, who had left by 1 January, carries three different origin labels across the three OPAs (E-07). Fifth, the README says every output decision was fixed before results, while AUDIT.md records three changes made after results (E-19). Each fix is a wording or label change in a generator, and none moves a number.

## Done well (keep)
- The comparison report's account of the equation: "The equation's lost income tax term, $81.34B, is neither ... It ends above the JR analysis's $75.0B because the avoidance dial, a, has not moved yet" (`comparison/site/repro.qmd` line 664). Only the root page lacks it (E-02).
- Order dependence is shown with a number on every surface ("moved first, q would take −$53.75B instead of −$39.44B"). The Shapley table discloses the interaction it hides, with its size ("moving both changes the estimate by −$39.6B more than moving each alone (−$56.7B at the JR values)").
- The derivation of the JR rate, 1 / E[1/(r − g)] = 0.03 / ln(3) = 2.73%, with the convexity worked out (36.6 against 33.3), and a test (`test-endpoints.R` lines 45-48) that holds it.
- The exact expectation against the seeded run, with its size on the JR pages: "The gap, 0.09, is less than one Monte Carlo standard error (0.12)", and "0.79" standard errors in the identities table.
- "The share below zero ... is not a probability that the tax loses money" (JR overview and explorer).
- The BSZ report's "How far the guesses move the result" table, sorted by range. It is the only ordered sensitivity in the project (E-12 asks the JR analysis for one).
- Reproduction notes with a kind and a size for each, and the "Errors in this OPA, found and fixed" list on the BSZ materials page.
- The checks pages. Each lists the printed variations it reproduces and the settings no paper prints, marks the latter "Pending", and says they were sent to the authors.
- The Act's text is committed with its SHA-256. Every third-party source has a manifest row with a hash.
- C, W, the non-citizens, the real-estate deduction and the asset-sale tax are explained in the root table and the explorer tips in the same words as the survey forms (the forms section below lists only where they differ).

## Jargon ledger
| Term | Page (file) | Explained there? | A definition that would do |
|---|---|---|---|
| present value | `bsz-analysis/site/index.html` line 256 ("present value at 3% a year") | No | What a stream of future amounts is worth at the start, at the stated yearly rate |
| today's dollars | `index.html` headline blocks; comparison explorer header | No date given (E-05) | Value at the date the tax is due, as the report's Conventions define it |
| Python twin | `bsz-analysis/site/index.html` and `rjkdc-analysis/site/index.html`, Open Materials card | No (the root page defines it) | The same computation written again in Python and checked against the R result |
| Pareto extrapolation | `bsz-analysis/site/explorer/index.html`, "Missing billionaires" description | No | Fitting the shape of the Forbes list above $4.5B and extending it down to $1B to count the fortunes Forbes misses |
| seeded run | `rjkdc-analysis/site/explorer/index.html`, Notes | No (the JR overview's footnote 1 defines it) | A simulation started from a fixed random number, so it gives the same draws each time |
| grid | `rjkdc-analysis/site/explorer/index.html`, "Highest in the grid" | No | The precomputed set of every combination of the dials' settings |
| semi-elasticity | `rjkdc-analysis/site/index.html`, What reproduces, last row | No | The percentage of the tax base lost per percentage point of tax rate |
| Pareto fit | `rjkdc-analysis/site/index.html`, What reproduces ("Pareto fit and Table 9") | No | A straight line through the log counts of top filers against log income, used to estimate what the top 212 earn |
| {targets} | `rjkdc-analysis/site/materials.html` ("an R {targets} pipeline"); JR deck slide 3 | No (the BSZ materials page and root README define it) | The R package that runs the pipeline's steps in order and records which outputs are current |
| dial / slider | `comparison/site/explorer/index.html`, "The inputs" | Partly: the paragraph says "Each slider" then "Every dial" | "Each dial (a slider) moves one disputed input" |
| the minor switch | comparison explorer equation, "(W, a, the minor switch)" | Not at first use; the switch appears further down | One on-off switch that moves the three smallest inputs together |
| base (used for revenue) | `rjkdc-analysis/site/repro.qmd` line 269, "The base is $94.30B" | Misused (E-11) | The base is wealth ($1,894.8B); $94.30B is 5% of it |
| discount rate (r) | comparison explorer r tip | Defined, but differently at the two ends (E-03) | "The rate net of the lost tax's growth (r − g) that turns a yearly loss into a present value" |
| guesswork | root page, BSZ report, JR report | Yes, three different definitions (E-13) | One shared gloss |
| Shapley, all orders, one order | `comparison/site/repro.html` | Yes, at the end of The bridge | Keep |
| bridge | `index.html`, Hoopes fold | Yes | Keep |
| perpetuity | `index.html` table, H row | Yes ("For ever") | Keep |
| export contract | comparison explorer, notes | Yes | Keep |
| Monte Carlo, draw | `rjkdc-analysis/site/index.html` headline | Yes | Keep |
| exact expectation | `rjkdc-analysis/site/index.html` | Yes ("a number that does not depend on the seed") | Keep |
| vintage | `bsz-analysis/site/materials.html` | Yes | Keep |
| anchor | `comparison/site/materials.html` | Yes | Keep |
| quadrature | `rjkdc-analysis/site/repro.html` | Yes ("exact integration") | Keep |
| ASC 740-10 | `rjkdc-analysis/site/repro.html` 4.2 | Yes | Keep |
| phase-in | `bsz-analysis/site/explorer/index.html` notes | Yes | Keep |
| CI | `README.md` | Yes | Keep |
| origin labels (kinds) | root page, explorer notes | Yes | Keep, but unify (E-13) |

## Findings

### E-01. The root page's definition of the common output omits the asset-sale income tax  [blocking] [comparison]
- Where: `index.html` line 330 (source `comparison/site/index.template.html` line 330)
- Now: "Both numbers measure the same thing: the wealth tax collected, counted at face value, minus the present value of the income tax lost (the report's definition)."
- Problem: the report's output (b) is "the one-time wealth tax collected, plus extra income tax from assets sold to pay the tax, minus the present value of income tax lost" (`comparison/site/repro.qmd`, The common output). The BSZ headline block two lines above includes that term ("plus income tax from assets sold to pay it"), and it is $3.68B of the $106.8B. The sentence presents itself as the report's definition but is a different one. The explorer's lead and the deck (slides 18 and 20) state it correctly.
- Proposed: "Both numbers measure the same thing, the report's net fiscal effect: the wealth tax collected, counted at face value, plus the income tax from assets sold to pay it, minus the present value of the income tax lost." Edit the template and hand-mirror `index.html`. Check `comparison/tests/testthat/test-site.R` for a pin on this sentence first.
- Also on: none found (I checked the explorer, report, deck and READMEs).

### E-02. The equation's "Lost income tax" term is $8.33B larger than the difference in lost income tax, and the root page does not say why  [major] [comparison]
- Where: `index.html` lines 338-343 (generated by `comparison/R/site.R` lines 925-933, `order_note()`)
- Now: the equation term "−$81.34B Lost income tax", then "For scale, the lost income tax itself is worth $75.0B today in the JR analysis and $0.7B in the BSZ analysis."
- Problem: a reader subtracts $75.0B − $0.7B = $74.3B and finds $7B missing. I recomputed the path from `score_common()` with the inputs of `comparison/export/r/inputs.csv`. After the D step the loss is worth $1.97B. After the four loss dials it is $83.31B, because a is still at 10%, so f = 0.05 + 0.45 = 0.50. The a step then returns $8.33B of loss (83.31 − 74.98), plus $4.00B of wealth tax and $0.14B of asset-sale tax, which makes its +$12.47B. So $8.33B of the "Lost income tax" term is BSZ's movers (α·m = 5%) valued at the JR income level for ever, and the "other three" term hides that refund. The report says this (line 664), but the root page, which a scoring reader quotes, says only "For scale".
- Proposed: replace the root's last sentence with a generated one in the report's words: "The lost income tax term, $81.34B, is larger than the difference between the two analyses' lost income tax ($75.0B against $0.7B), because when its dials move a is still at BSZ's 10%: the share lost is then 50%, not 45%. The a step returns $8.33B of it." Every amount should come from `score_common()` at the path's states in `site.R`. None of them may be typed. In the explorer, add the same point to footnote 2 or to the "Lost income tax (H, f, C, r)" term's hover tip, not as page text.
- Also on: the survey's treatment page shows the same $81.3B beside "5% ... counted for 5 years; $3.06 billion a year" and "45% ... counted for ever; $4.55 billion a year" (`mock_forms.py` TERMS). The forms are out of scope; this note is for the author's record only.

### E-03. The 3% rate is a plain discount rate on the BSZ pages and a rate net of growth in the comparison  [major] [BSZ, comparison]
- Where: `bsz-analysis/site/index.html` line 256; `bsz-analysis/site/explorer/index.html` lines 270-271; `bsz-analysis/site/repro.qmd` line 601 and the input table (`bsz-analysis/R/site_exports.R` line 183); `bsz-analysis/site/slides/slides.Rmd` line 510; the comparison explorer's r tip (`comparison/R/site.R` line 462 and lines 538-541); `index.html` line 543 (`site.R` line 631)
- Now: BSZ overview: "counted over 5 years (present value at 3% a year)". BSZ explorer: "5 years at 3% a year, the middle of the JR analysis's 1.5% to 4.5% range (BSZ give no rate)". Comparison explorer: "r, discount rate. The discount rate that turns a yearly loss into today's dollars", with its JR end at "worth the same as the JR draw (1.5% to 4.5%) of r − g". Root: "H and r are scenario choices."
- Problem: the JR range is not a discount-rate range. It is r − g, "the real rate net of the loss's growth" (comparison report, Conventions, line 250: "a flat loss at that rate is the chapter's growing loss. ... The BSZ end's 3% is the middle of the same draw"). So the comparison reads BSZ's 3% as r − g, a loss that grows at g discounted at 3% + g. The BSZ pages instead call it the rate at which a flat $0.15B a year is discounted, and none says whether the rate is real or nominal. At 5 years the number does not change, but the parameter has two definitions, and the dial is named for one concept at one end and another at the other. The root's "H and r are scenario choices" also contradicts the same table's r row at the JR end, "Kind: derived".
- Proposed: name the dial "rate net of growth (r − g)" in the comparison (dial label, tip, root row "r rate"). Then say once on each BSZ page that states the rate: "3%, read as a real rate net of the loss's growth (r − g), the middle of the JR draw; BSZ give no rate." Change the root's subtitle to "H is a scenario choice, and r is a scenario at the BSZ end and derived at the JR end." Check the explorer-tip line limits and the `test-site.R` pins before editing.
- Also on: the comparison deck slide 32 ("at the rate r") and slide 24 ("Discount rate").

### E-04. The valuation-date range ($87.0B to $110.9B in 2026) sits on the checks page only, typed, with no cell reference  [major] [BSZ]
- Where: `bsz-analysis/site/checks.qmd` lines 150-155; `bsz-analysis/site/index.html` line 488 (scope paragraph)
- Now: checks page: "It is $92.5 billion on 1 January (the residency date), $87.0 billion at the year's low on 30 March, and $110.9 billion at its high so far on 6 October." Overview: "Neither predicts the Forbes base on the 31 December 2026 valuation date."
- Problem: this is the revenue volatility an analyst puts next to the headline. A $24B swing within 2026 is as large as the D step, yet the overview names the gap without its size. The three figures are typed into the `.qmd` prose. The run-003 package note found their source to be `shortrunseries!A15:D272` of the workbook (`feedback/003-2026-10-16/wp/AUTHOR-BSZ.md`), and the page does not cite it. Under the content map's rule 4, no page should type them.
- Proposed: add a pipeline target that reads the daily series and exports the low, the high and the 1 January value with their dates. Then print the range in the overview's scope paragraph: "In the authors' own daily series the wealth tax ranges from $87.0B (30 March) to $110.9B (6 October) over 2026 (workbook sheet shortrunseries); see the checks page." Use the same sentence on the checks page, with the cell range cited. Until a target exists, the author should at least add the cell reference to the checks page.
- Also on: the JR overview's identical scope paragraph (`rjkdc-analysis/site/index.html`, "What this OPA does not estimate") could link to the same range.

### E-05. "Today's dollars" has no date, and whether amounts are real or nominal is not stated  [minor] [all]
- Where: `comparison/site/index.template.html` lines 322 and 327; the comparison explorer header; `rjkdc-analysis/site/index.html` headline ("Today's dollars (present value): what money received or lost in future years is worth now"); `comparison/site/repro.qmd` line 250
- Now: headline blocks say "in today's dollars". The report's Conventions say "Present values are as of the date the wealth tax is assessed, and the first year of lost income tax is counted one year later."
- Problem: "today" reads as October 2026, but the Conventions date is the assessment date, which no page gives as a calendar date. The Act makes the tax "due at the same time as the annual income taxes" for tax year 2026, at once or in five installments (§50301(c), Act p.11). The JR rate is a real rate. Nothing says whether the wealth tax's face value and the lost income tax are in the same (real) dollars.
- Proposed: in the report's Conventions, give the date ("the date the 2026 tax is due, with the 2026 income tax return (§50301(c))") and the units ("amounts in dollars of that date; the rate is real, net of the loss's growth"). Have the headline blocks' "today's dollars" link to that paragraph.
- Also on: BSZ overview line 256; BSZ explorer header.

### E-06. "Total (main estimate)" heads a column of four scenarios  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` line 463; the BSZ explorer's outcome row "Main estimate (net)" across all scenario columns (`bsz-analysis/R/site_exports.R` line 95)
- Now: "Total (main estimate)²" over rows Base, Missing billionaires, Leavers, Missing + leavers. In the explorer, "Main estimate (net) $106.8B $106.8B $131.5B $89.6B $116.3B".
- Problem: only row 1 is the main estimate. A reader can quote $131.5B as "the main estimate under missing billionaires". The report's own table gets this right ("Base (main estimate)").
- Proposed: column header "Net total²", with row 1 labelled "Base (1), the main estimate". Explorer row label "Net total". `test-site.R` may pin the label.

### E-07. One input, who had left by 1 January, carries three origin labels across the three OPAs  [major] [all]
- Where: `rjkdc-analysis/R/export.R` line 50 (`nber_ceiling_hardcoded`, "data") and `rjkdc-analysis/R/site.R` lines 70-75 (the explorer's "Highest revenue the draw can pick", origin "data"); `bsz-analysis/site/data/inputs.csv` row L ("guesswork", "A legal judgment on residency"); `comparison/R/model.R` line 96 (D, "guesswork on data")
- Now: JR explorer tip: "The NBER script: removes seven publicly reported moves, with net worth grown 7% to 31 December 2026 (PDF p.21). Kind: data." JR report: "The one labelled data, the revenue ceiling, rests on a legal judgement about who counts as having left (disputes row 3)."
- Problem: the ceiling is the 2025 base grown by the 7% that the same contract labels "guesswork on data" (row `nber_growth_rate`), less the seven moves, which the comparison labels "guesswork on data" and the BSZ OPA "guesswork". The JR report itself says the "data" label is wrong. A reader comparing the explorers sees the JR revenue's top as "data" and the comparison's JR base as a judgement.
- Proposed: label `nber_ceiling_hardcoded` and the wt_hi dial "guesswork on data" (a judgement, who left plus the 7% growth, applied to observed net worths). Rebuild the exports and the explorer. Then the JR report's line 587 sentence and its input counts (data 10 → 9, guesswork on data 1 → 2 on the JR report; AUDIT.md JR step 7) follow from the pipeline. For the BSZ OPA's L row, the author can decide whether "guesswork on data" fits as well. The comparison already uses it for the same people.
- Also on: the JR deck slide 18 table, which reads the same dial list.

### E-08. The BSZ explorer's grid bounds have no stated reason  [minor] [BSZ]
- Where: `bsz-analysis/R/site_exports.R` line 19 (`site_other_level_tip()`), the α and αₛ dials
- Now: every added level says "Added by this OPA to show the range. BSZ use 10%." The α levels run 0% to 30%, the αₛ levels 10% to 50%.
- Problem: a scoring reader asks whether 30% is a plausible high case and why it stops there. The tip says only that the OPA added it.
- Proposed: one clause from the grid's own numbers on the top level's tip, for example "30%: above the 23.0% overall avoidance rate of Table 5 row 3", with the 23.0% read from `tab5.csv`. If no reason exists, say "an illustrative bound".

### E-09. The JR explorer reuses g for a second growth rate  [minor] [JR]
- Where: `rjkdc-analysis/R/site.R` lines 129-133
- Now: "Further growth of the lost income tax, g ... the loss becomes f·C/(r − g − this g)."
- Problem: "r − g − this g" uses one symbol for two quantities on the page where r − g is the central parameter.
- Proposed: symbol "Δg" and "the loss becomes f·C/(r − g − Δg)", in the dial, the deck table and the report's input table (row `g`).

### E-10. The BSZ OPA says the tax is "payable 1% a year over five years"; the Act makes that an option with a deferral charge  [minor] [BSZ]
- Where: `bsz-analysis/site/repro.qmd` line 140; `bsz-analysis/site/slides/slides.Rmd` line 206; the input table's τ row (`bsz-analysis/R/site_exports.R` line 136: "5%, payable 1%/yr over 5 years (GGSS p.1)")
- Now: "valued on 31 December 2026 and payable 1% a year over five years."
- Problem: §50301(c) lets the taxpayer "pay any tax due under this Part along with any income tax owed for the 2026 tax year; or ... pay annually in five equal installments ... subject to an annual nondeductible deferral charge of 7.5 percent of the remaining unpaid balance". The root page and the comparison report already say this. The BSZ pages describe a fixed schedule, which bears on the timing of collections.
- Proposed: "payable at once with the 2026 income tax, or in five yearly installments with a deferral charge of 7.5% a year on the unpaid balance (§50301(c))". The τ row can keep GGSS as the source of the 5% and cite the Act for payment.

### E-11. The JR report calls the revenue "the base"  [minor] [JR]
- Where: `rjkdc-analysis/site/repro.qmd` line 269
- Now: "This section builds the revenue. The base is $94.30B before anyone leaves and grows to $100.91B by the valuation date."
- Problem: everywhere else the base is wealth ($1,894.8B for the 212). $94.30B is 5% of it, net of real estate. A reader switching between pages meets two meanings.
- Proposed: "This section builds the revenue. At 5% of the base, it is $94.30B before anyone leaves and $100.91B at the valuation date."

### E-12. No JR page ranks the inputs by effect  [minor] [JR]
- Where: `rjkdc-analysis/site/repro.qmd`, "Every input, by origin"; JR deck slide 18
- Now: "The explorer shows how far each one moves the estimate" (overview). The deck slide lists the seven dials without effects.
- Problem: the BSZ report has a sorted one-at-a-time table. The JR pages have the numbers only unsorted, on the checks page: r − g fixed at 1.5% −100.50 and at 4.5% −9.50; C at 3.3 −18.38 and at 5.8 −59.58; the floor at 35 −21.48; f at 0.283 −11.21. A reader cannot see at a glance that the rate band moves the result most.
- Proposed: the BSZ report's table shape (input, origin, values tried, mean NPV range), read from `grid.js` as the checks page does, sorted by range, in the JR report's "Every input, by origin". It can mark the two OPA dials.

### E-13. The kinds are defined three ways across the three OPAs  [minor] [all]
- Where: `index.html` line 209 region (Kinds); `bsz-analysis/site/repro.qmd` "Every input, by origin"; `rjkdc-analysis/site/repro.qmd` "Every input, by origin"; `comparison/data/document-inputs.csv` (LAO row)
- Now: guesswork is "an assumption with no data or study behind it" (comparison), "set by assumption; argued for, but not measured" (BSZ), "set by assumption. Some are bounded by evidence, but no dataset or estimate pins the value itself" (JR). Data is "settled by observable facts", "read off a public source, and in principle re-collectable from it" and "read off a public dataset or the authors' own person-level file, and recomputable from it". BSZ adds "convention" and has no "guesswork on data". The LAO's "less than $1 billion per year" is labelled guesswork.
- Problem: the labels are the OPA's core claim about evidence, and the same word means slightly different things on each site. An official fiscal estimate (the LAO's) labelled "guesswork" will read as a judgement on the LAO.
- Proposed: one glossary in the shared kit (rule 5 of the content map), used verbatim on the three reports and the root page. Relabel the LAO and Walczak rows "research" (published estimates), or explain why not.

### E-14. A public deck slide carries placeholder text  [minor] [comparison]
- Where: `comparison/site/slides/slides.Rmd` lines 231 and 237 (slide 5, "How do we move from many analyses to one?"); present in the rendered `slides.html`
- Now: "[Text for the left figure, to come]" and "[Text for the right figure, to come]"
- Problem: the slide is live on the published deck.
- Proposed: the author writes the two lines, or the slide is hidden until then.

### E-15. "Three OPAs in about a week of work" has no stated basis  [suggestion] [comparison]
- Where: `comparison/site/slides/slides.Rmd` line 483
- Now: "This project created **three OPAs in about a week** of work."
- Problem: the repository's history has commits on 12 days between 2026-05-26 and 2026-10-17. The claim may be right as working time, but a reader cannot check it.
- Proposed: state the basis, for example "commits on 12 days between May and October 2026", or the author's own estimate of hours.

### E-16. The BSZ materials page and report name the "August 2026 workbook" but not which file  [minor] [BSZ]
- Where: `bsz-analysis/site/materials.qmd` lines 69-70; `bsz-analysis/site/repro.qmd` line 4
- Now: "The default workbook vintage ... is August 2026; BSZ_VINTAGE=may switches every vintage-dependent path". Report subtitle: "reproduced step by step from the authors' August 2026 workbook".
- Problem: the numbers come from the file downloaded 2026-10-14, whose data appendix was updated 2026-10-08 (DATA-SOURCES.csv row 1). The September copy is still selectable with `BSZ_VINTAGE=september`. The README says this, but the two pages a reader uses do not.
- Proposed: materials: "The default workbook is the August 2026 paper revision with the data appendix of 2026-10-08 (SHA-256 below); BSZ_VINTAGE=september selects the appendix of 2026-09-04 and BSZ_VINTAGE=may the May version." Report subtitle: "... from the authors' workbook (August 2026 revision, data appendix of 8 October 2026)".

### E-17. The comparison materials page lags its sources  [minor] [comparison]
- Where: `comparison/site/materials.html`, Scripts table
- Now: "R/site.R 991"
- Problem: `comparison/R/site.R` has 1,161 lines since the survey commits of 2026-10-17. The table is computed at render, so the page needs a render, and its test count (1,029) may lag too.
- Proposed: re-render `materials.qmd` (and `repro.qmd`) in Phase 4.

### E-18. A public MIT clone is filed under "author-shared" in the JR manifest  [minor] [JR]
- Where: `rjkdc-analysis/DATA-SOURCES.csv` (row for `original-materials/author-shared/2026-09-23_wealth_tax-repo/`), shown on `rjkdc-analysis/site/materials.html`, Sources
- Now: "original-materials/author-shared/2026-09-23_wealth_tax-repo/ ... git-clone ... MIT"
- Problem: the folder name says author-shared, while the row, the overview and the README say the repository is public under MIT. Run 003's A-21 made the contract rows "public" for the same reason.
- Proposed: for the author, rename the local folder (for example `original-materials/wealth_tax-repo/`) in the manifest and in `RAUH_REPO_DIR`'s documented default, or add "public repository; folder name kept from the first download" to the row.

### E-19. The README says every output decision came before results; AUDIT.md records three that came after  [major] [all]
- Where: `README.md` lines 37-38; `AUDIT.md` step 1 rows (BSZ "replaced the pre-specified wealth tax on 2026-10-07, after results"; JR "became the main estimate on 2026-10-14, after results"; comparison "The rate dial and the equation's order were set on 2026-10-15, after results"); `comparison/site/repro.qmd` and `rjkdc-analysis/site/repro.qmd` (no such note)
- Now: "[`PLAN.md`](PLAN.md) records the plan and every decision that fixed the output before results."
- Problem: the self-audit contradicts the front page. Only the BSZ report says when its output changed (folded note "Why the total, and when this changed"). AUDIT.md's own fix 3, "state on each landing page when the output was fixed relative to the results ... costs a sentence", is not done on the JR or comparison pages. A pre-specification claim is the first thing a scoring reader checks.
- Proposed: README: "`PLAN.md` records the plan, the output fixed before results, and the dated decisions that changed it after results." Add a folded note like the BSZ one to the JR report ("The project's pre-specified output named the March 2026 version; the September 2026 version became the main estimate on 14 October 2026, after results, because the pages follow each analysis's latest version") and to the comparison report (the rate dial and the equation's order, 15 October). `PLAN.md` is a record and stays as it is.

### E-20. The comparison README calls the 3% a transcription and leaves the rate out of the common output  [minor] [comparison]
- Where: `comparison/README.md` lines 67 and 75
- Now: "`data/document-inputs.csv`: values neither contract carries, transcribed from the PDFs with their page (... the 3% rate at the BSZ end ...)" and "(b) net fiscal effect = (a) + extra income tax from assets sold to pay - present value of income tax lost to departures, over a horizon H (a dial)."
- Problem: the 3% is this OPA's scenario, not a PDF value (its own row says "Comparison choice, author decisions 2026-10-15"), and r is a dial too.
- Proposed: "(..., the 3% rate this OPA sets at the BSZ end, ...)" and "... over a horizon H at a rate r (both dials)".

### E-21. The BSZ README calls the paper PDF a required input  [minor] [BSZ]
- Where: `bsz-analysis/README.md` line 57
- Now: "Paper PDF | `original-materials/BSZ26CAbillionaires.pdf` | **Required input. NOT redistributed in this repo**"
- Problem: `DATA-SOURCES.csv` says the PDF is "reference only (quoting in report.qmd, README); not read by any tar_target". A reader preparing a rerun would fetch a file the pipeline never reads.
- Proposed: "Reference only (quoted in the report); not read by the pipeline. NOT redistributed."

### E-22. DISPUTES row 10's effect of the rate is from another order, and "lowers the JR end" is wrong  [minor] [comparison]
- Where: `comparison/DISPUTES.md` line 104
- Now: "Moving it from 3% to 2.73% lowers the JR end by about $6.7B, to the authors' exact mean, −$38.98B."
- Problem: −$6.73B is the rate's step in Hoopes's order (the report's "One order" column). On the explorer's path, which every page now uses, it is −$7.48B. The JR end is fixed. What moves is the estimate on the way to it.
- Proposed: "On the explorer's path the rate step is −$7.48B (−$6.73B in Hoopes's order); it is the last loss-box step before W, a and the minor switch."

## Findings: page wording against the survey forms

The forms' texts below were evaluated from `comparison/survey/mock_forms.py` with the current exports. The forms are not to change. Each finding proposes a page edit.

### E-23. The root table gives BSZ "None named" for departures and the whole 10% as avoidance; the forms split it 5% and 5%  [major] [comparison]
- Where: `index.html`, "The differences" table, rows D and a (built by `comparison/R/site.R`, the tips at lines 495-505 and the table function from line 633)
- Now: "D departed None named. No one counted by name without evidence of a change of legal residence before 1 January (BSZ PDF p.23). Kind: guesswork on data." and "a avoidance 10.0%. A small allowance argued from enforcement (GGSS p.4). Kind: guesswork." For JR: "D departed 7 moves. Seven counted as having moved in time, on public reports of their moves (chapter PDF p.21)."
- Form: DEPARTED, BSZ: "5% of the wealth: an allowance for billionaires who moved in time, with no one counted by name without evidence of a change of legal residence before the date." JR: "About 29% of the wealth: seven billionaires (Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks) are counted as having moved in time, on public reports of their moves." AVOID ("Wealth that escapes the tax through avoidance and evasion, beyond moving away"), BSZ: "5%: a small allowance argued from enforcement." JR: "None."
- Problem: the root table reads as if BSZ allows for no departures and puts 10% into "a small allowance argued from enforcement". The form, like BSZ PDF p.24, gives BSZ's departures as 5% of the wealth and the avoidance by those who stay as the other 5%. A survey respondent who opens the overview afterwards (the thank-you screen links to it) sees different BSZ values for the same two questions. The JR row also lacks the share of wealth (about 29%) that makes the two values comparable. The explorer's tips already state the split ("Half of a is people who moved in time"; "Half is people who moved out in time ... half is avoidance"). The root table drops it, and the explorer's a dial defines a as "including moves no one names", while the form's avoidance excludes moving away.
- Proposed: root rows, in the forms' words. D, BSZ: "None named; an allowance of 5% of the wealth for billionaires who moved in time, inside a (BSZ PDF p.24)." D, JR: "7 moves, about 29% of the wealth: seven counted as having moved in time, on public reports of their moves (chapter PDF p.21)." The 29% should be read from the contract as `mock_forms.py` does (1 − 72 / 100.906). a, BSZ: "10.0%: 5% billionaires moving away in time and 5% avoidance and evasion by those who stay, argued from enforcement (GGSS p.4; BSZ PDF p.24)." The `test-site.R` pins on the table's strings need checking first.

### E-24. The q term is titled by its complement and differs from the forms' name  [major] [comparison]
- Where: `comparison/R/model.R` line 83 (`bridge_steps()` title), which feeds `index.html` line 338, the explorer's equation and Apply list (`comparison/site/explorer/index.html` lines 415 and 656), the report's bridge tables and `dial_path.csv`; the root q row (`comparison/R/site.R` line 510)
- Now: "Chance the tax does not survive litigation (q)", next to the dial "q, chance it survives court". Root q row, JR: "A discount; the revenue is multiplied by the chance the tax survives."
- Form: TERMS and GROUPS: "Discounting the revenue for court risk". Question: "Discounting the revenue for the chance that courts strike the tax down: which is more credible?" JR value: "A discount: the wealth tax collected is multiplied by the chance the tax survives in court, put at 50%." BSZ value: "No discount: the tax is assessed at face value, as written."
- Problem: "(q)" sits after a title naming 1 − q, on the same page as a dial that defines q as the chance of surviving. A reader can take q for the chance of being struck down. The comparison deck's own slide 22 heading already uses the forms' framing ("(ii) Is the revenue discounted for court risk?"), so the deck and the equation it shows disagree. The root row's "the revenue" also leaves open whether the lost income tax is discounted. The form says "the wealth tax collected", and the deck says the lost income tax is not scaled by q.
- Proposed: title "Discounting the revenue for court risk (q)" in `bridge_steps()` and wherever the equation prints it. Root q row, JR: "A discount: the wealth tax collected is multiplied by the chance the tax survives in court, 50% (chapter PDF pp.19-20)." DECISIONS A-04 notes that step titles are carried by the tests and exports, so the rename includes `test-site.R`, `test-dial-path.R` and the Python twin's titles.

### E-25. "Share lost" has no base on the root page, and its BSZ reason differs from the form's  [minor] [comparison]
- Where: `index.html`, f row (from `comparison/R/site.R` lines 511-520); the explorer's f end labels (`comparison/site/explorer/index.html`, f dial in both panels)
- Now: root: "f share lost 5%. No more than the share of wealth that leaves (BSZ PDF p.24)." JR: "45%. More than the 28.6% of wealth reported to have left (chapter PDF p.31)." In the explorer, the BSZ panel's f dial ends at "50% JR" and the JR panel's at "6% BSZ".
- Form: SHARE_TITLE: "The share of billionaires' income tax lost when people leave". BSZ: "5% of all the income tax that billionaires pay: the same as the 5% of their wealth assumed to leave, because the largest of the billionaires reported to have left pay little income tax for their wealth." JR: "45% of all the income tax that billionaires pay: more than the 29% of their wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported."
- Problem: "share lost" does not say of what. The form's "of all the income tax that billionaires pay" removes the ambiguity that the pilot found (the old wording was "read three ways", `mock_forms.py` comment above SHARE). At the main estimate the BSZ share is the same as the wealth share, not "no more than" it. In the explorer, the end labels "JR 50%" and "BSZ 6%" are values neither analysis uses. They are the rule's result at the panel's other settings (the box tip says so: "f also moves with D and a").
- Proposed: root label "f share of billionaires' income tax lost". BSZ value: "5% of all the income tax billionaires pay, the same as the 5% of wealth assumed to leave (BSZ PDF p.24)". Keep the JR value with its reason as in the form. On the explorer's f dial, name the ends "BSZ rule" and "JR rule" rather than "BSZ" and "JR", since the printed value is the rule at the panel's settings.

### E-26. The horizon step is titled as a fact about the loss; the forms and the explorer call it a counting choice  [minor] [comparison]
- Where: `comparison/R/model.R` line 86 (`bridge_steps()`), shown in `comparison/site/repro.qmd` (bridge tables; line 396 in the Shapley text) and the deck
- Now: "How long the income tax loss lasts"
- Form: "How long the lost income tax is counted: which is more credible?" A: "For ever: billionaires who leave are assumed not to return." B: "5 years, about the payment period, treating the departures as temporary." The explorer's dial already says "H, years counted".
- Problem: the input's kind is "scenario". "Lasts" reads as an empirical duration claim, and the deck heading "(iii) For how long is the income tax lost?" does the same.
- Proposed: title "How long the lost income tax is counted", and deck heading "(iii) How long is the lost income tax counted?". Same test caveat as E-24.

### E-27. "The other three steps together" counts dials, not inputs, and collides with "Three minor inputs"  [minor] [comparison]
- Where: `index.html` line 340; `comparison/site/explorer/index.html` lines 417 and 658; comparison deck slide 25 "(iv) The other three steps"
- Now: "+$4.89B The other three steps together (W, a, the minor switch)"
- Form: TERMS: "Other inputs together: the wealth on the list, avoidance, and three smaller inputs". The opt-in counts them as five ("Yes, show me the five").
- Problem: the term moves five inputs, three of them inside a switch that the same explorer calls "Three minor inputs". "The other three" next to "Three minor inputs" invites reading them as the same three.
- Proposed: "The other inputs together (W, a and the three minor inputs)", or the form's "Other inputs together: the wealth on the list, avoidance, and three smaller inputs".

### E-28. Where the forms say less than the pages (no page change)  [suggestion] [comparison]
- Where: `mock_forms.py` TERMS and NOTE; STUDIES
- Now (forms): "The income tax lost when billionaires leave: the share lost, how long it is counted, and billionaires' yearly income tax, together" and "its three inputs multiply each other". The equation's term also includes the rate step (−$7.48B), which the explorer names: "Lost income tax (H, f, C, r)". STUDIES: "Boll, Saez and Zucman (BSZ, August 2026): +$106.8 billion."
- Problem: the pages are the fuller statement here. They name four loss dials, and they say $106.8B is this OPA's net total, not BSZ's headline. A treated respondent who follows the thank-you link sees four inputs where the form said three.
- Proposed: none on the pages. For the author's record only, since the forms are out of scope.
