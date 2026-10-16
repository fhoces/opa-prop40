# Review 2: outside policy experts, run 003
Commit: 199be9284685dd07db973273b4a11fb616b60877. Date: 2026-10-16. Pages read: `index.html`, `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`; the three explorers rendered in headless Chrome (`comparison/site/explorer/index.html`, `bsz-analysis/site/explorer/index.html`, `rjkdc-analysis/site/explorer/index.html`); the three reports (`*/site/repro.html` rendered, `*/site/repro.qmd`); the three decks (`bsz-analysis/site/slides/slides.Rmd`, `rjkdc-analysis/site/slides/slides.Rmd`, `comparison/site/slides/slides.Rmd`); the three materials pages (rendered); `README.md`, `comparison/README.md`, `rjkdc-analysis/README.md`, `bsz-analysis/README.md` (tolerance and test sections); `comparison/DISPUTES.md`, `AUDIT.md`, `PLAN.md` (pre-specified output), `docs/initiative/` (the Act's text, §50301 and §50303-50304); `bsz-analysis/site/data/inputs.csv`, `grid.csv`, `rjkdc-analysis/export/r/inputs.csv`, `comparison/export/r/{inputs,dial_path,meta,ends,hoopes,switchboard}.csv`, `comparison/data/document-inputs.csv`, the three `DATA-SOURCES.csv`; the test files the pages cite; the JR chapter PDF (pp.5, 12-13, 19, 21, 34, 44), the BSZ PDF (pp.18, 22-24, 27, 39) and `NPV_dist_v8.R` from the pinned clone.

## Summary
- Counts: blocking 1, major 6, minor 13, suggestion 1
- The three to fix first: E-05, E-01, E-03
- Could I cite this OPA in a scoring memo as it stands? I could cite the comparison's arithmetic. I recomputed the dial path (the nine terms sum to the $145.78B gap), the Shapley values from `switchboard.csv` (they match the report's table to the cent), the 2.73% rate (0.03/ln 3) and the JR closed form (36.00 − 0.45 × 4.55 × 36.62 = −38.98). The comparison's tests use absolute 1e-9 bounds. What stops me is on the two analyses' pages and in three disclosures. First, the BSZ and JR pages state test tolerances the tests do not apply: several BSZ checks pass at 100% relative error, and the JR printed share negative passes anywhere from 43% to 128% (E-05). Second, every page says the wealth tax is counted at face value "although it is paid over five years", and none says the Act's installments carry a 7.5% annual deferral charge, above every discount rate on the site (E-01). Third, two origin labels contradict the OPA's own definition of "data": the JR base grown by a projected 7% to a date not yet reached, and BSZ's omission of the Act's real-estate exclusion (E-03). A hearing opponent would also find that the report ranks f and H by a Shapley average without saying that a $40B to $57B joint effect of the two is split between them (E-11), and that the JR overview counts two of this OPA's own dials when it says "six of the seven inputs are guesswork" (E-06).

## Done well (keep)
- The equation on the root and the explorer: each term reproduces with the Apply buttons, the terms add exactly, and `test-dial-path.R` and `test-site.R` (lines 404-432) check every path value in R, Python and `model.js` with `expect_lt(abs(...), 1e-9)`. These are absolute bounds, unlike E-05.
- The 2.73% derivation in the comparison report ("The derivation is short ... because 1/r curves upward"): complete, plainly worded, and pinned in `test-endpoints.R` lines 45-48.
- The exact Shapley over 2,048 subsets, checked against brute force. I recomputed the (b) values from `switchboard.csv`: q −45.00, f −32.62, H −32.33, D −23.63, a +11.35, all as printed.
- JR report Step 6: the seeded-run gap is sized in standard errors ("The gap, 0.09, is less than one Monte Carlo standard error (0.12)"), and the internal identities table. Both are exactly what a scoring reviewer asks for.
- JR mismatches cite file and line. I checked `NPV_dist_v8.R` lines 19, 21, 22 and 28 against the citations, and they match.
- BSZ report: "What 'reproduced' means here" (arithmetic, not inputs), the Step 5 dollar table, and Step 1's disclosure that the daily estimate ranged from $87B to $107B.
- BSZ deck: the tornado on `part-guess` is sorted by range.
- The root's versions table, including the LAO's three bounds; the Hoopes section's disclosure of his priors and of the Gamage acknowledgement.
- Numbers checked and right: BSZ 5% × 2,307 × 0.9 = 103.815, + 3.682 − 0.153 × 4.580 = 106.796; JR presets −100.5 (rate 1.5%), −9.5 (rate 4.5%), −48.2 with q = 0.5 (0.5 × 53.5 − 74.98); JR chain 100.906 − 28.854 = 72.05, minus 0.88 = 71.18, minus 12.03 = 59.15, × 0.5 = 29.57; the BSZ grid's extremes $157.8B and $63.2B.

## Jargon ledger
| Term | Page (file) | Explained there? | A definition that would do |
|---|---|---|---|
| "order-free check" | `index.html` line 339; comparison explorer line 332 | partly, and mis-stated (E-02) | "the Shapley average: each input's step averaged over every order the dials could move in" |
| "seeded run" | `index.html` footnote 1; comparison explorer footnote 1 | no (carried over from run 002's do-later list) | "one run of the random draws started from a fixed number, so it gives the same draws every time" |
| "Python twin" | `index.html`, Open Materials card | no (carried over) | "the same computation written again in Python and checked against the R result" |
| Kind labels "data", "research", "guesswork", "scenario" | `index.html`, the differences table | no; the note under the table defines only "guesswork on data" and "derived" | the explorer's own "Kinds" paragraph, one line each |
| "Monte Carlo" | comparison explorer footnote 1 ("averaged over the authors' Monte Carlo draws") | no | "a simulation that draws the uncertain inputs at random many times and averages the results" (the comparison deck's own gloss) |
| "Its weight within the JR draw" | comparison explorer, r dial tip (`comparison/R/site.R` line 403) | no | "How much the rate alone moves the JR estimate: the JR explorer's Rate 1.5% and Rate 4.5% settings" |
| "switchboard" | comparison materials, the `test-site.R` bullet | defined only further down, in the data-files table | "the common function's value for every on/off mix of the 11 disputed inputs" |
| "semi-elasticity" | JR explorer, the 35 floor's tip ("a semi-elasticity of 12 to 13") | no | "the percent of the tax base lost per percentage point of tax rate" |
| "mismatch 3", "mismatch 5" | JR explorer tips and notes | no (linked; carried over) | "one of nine places where the authors' text, READMEs and code disagree, listed on the materials page" |
| `{targets}` | JR report intro, JR deck Deck Map, BSZ materials | no on those pages (the root README defines it) | "the R package that runs the pipeline's steps in order and records which outputs are current" |
| "quadrature" | JR report, Internal identities table ("Share negative: quadrature vs seeded MC") | no | "computed exactly by numerical integration, not by random draws" |
| "gt and ggplot2 objects" | BSZ report, "How to read this report" | no | "the R packages that draw the tables and the figures" |
| "bridges the two estimates" | `index.html`, Hoopes section | partly | "a sequence of steps from one main estimate to the other, one disputed input at a time" |
| "Pareto extrapolation" | BSZ explorer, the Missing billionaires preset | partly (a "more" link) | "assuming the number of fortunes keeps the shape seen above $4.5B down to $1B" |
| "steady-state" | BSZ report, Table 5 note | no, and it contradicts the paper (E-13) | drop it; the paper says "annual temporary" |
| A(H, r), "minor switch", "export contract", "r − g", "perpetuity", "Shapley", "ASC 740-10", "phase-in" | comparison explorer and report; BSZ explorer; JR report | yes | (keep) |

## Findings

### E-01. The face-value convention omits the Act's 7.5% deferral charge on installments  [major] [all]
- Where: `comparison/site/index.template.html` line 326 and `index.html` line 326; `comparison/site/repro.qmd` lines 132 and 236-240; `comparison/site/explorer.template.html` lines 400-402 and the generated explorer line 601; `bsz-analysis/site/repro.qmd` lines 139 and 527; `bsz-analysis/site/slides/slides.Rmd` lines 200 and 254.
- Now: root: "Both analyses count the wealth tax at face value, although it is paid over five years." Report: "undiscounted although the Act collects it in five yearly installments; both analyses do this, so the comparison follows them." BSZ report: "paid 1% a year over five years".
- Problem: the Act (§50301(c), `docs/initiative/`, printed page 11, PDF p.12) gives each taxpayer an option: pay at once with the 2026 return, or "pay annually in five equal installments ... with each subsequent annual installment payment also being subject to an annual nondeductible deferral charge of 7.5 percent of the remaining unpaid balance". §50304 adds an Optional Deferral Account that defers tax on illiquid assets. The JR chapter names both options (PDF p.5); neither analysis counts the charge, and no page of this OPA mentions either provision (grep for "deferral" finds only `DISPUTES.md` row 1). The omission matters because the charge exceeds every discount rate on the site. By my calculation from §50301(c), at 3% an installment stream with the charge is worth about 1.085 times face value. If every taxpayer chose installments, face value would understate the present value by about $8.8B at the BSZ end and $3.1B at the JR end. The pages present face value as neutral ("although it is paid over five years"), when it is a lower bound whose size depends on an unknown take-up. "The Act collects it in five yearly installments" is also wrong as stated: installments are an option.
- Proposed: in the conventions paragraph of the report and the explorer: "The wealth tax is counted at face value, as both analyses do. The Act lets a taxpayer pay at once or in five yearly installments; each later installment carries a deferral charge of 7.5% a year on the unpaid balance (§50301(c)), more than any discount rate used here, so face value is a lower bound on what installments are worth today. An Optional Deferral Account (§50304) can delay tax on illiquid assets. Neither analysis models either provision, and this OPA does not estimate them." On the root, replace "although it is paid over five years" with "although it can be paid in five yearly installments, which carry a deferral charge (see the report's conventions)". If a number is wanted, export it from the generator (a `meta.csv` row); do not type it.
- Also on: `rjkdc-analysis/site/index.html` first paragraph ("paid over five years"); the BSZ report's notation table ("payable 1%/yr over 5 years").

### E-02. "The order-free check gives each input's size in any order" mis-describes the Shapley average  [minor] [comparison]
- Where: `comparison/R/site.R` lines 748-749, generated into `index.html` line 339 and `comparison/site/explorer/index.html` line 332.
- Now: "The report's order-free check gives each input's size in any order."
- Problem: the Shapley average gives each input's step averaged over every order, not its size in any order. The sentence after it on the same page says the size depends on the order, so the two sentences read as contradictory. The report itself says it right: "Averaged over every order (the order-free check ...)". The link goes to `#the-bridge`, the top of the section, while the fold has its own id, `#the-shapley-check` (`repro.qmd` line 557).
- Proposed: "The report's order-free check averages each input's step over every order the dials could move in." Point the link at `repro.html#the-shapley-check`.

### E-03. Three origin labels contradict the OPA's own definition of "data"  [major] [comparison, JR, BSZ]
- Where: `comparison/R/model.R` line 92 (kinds "data" for `base_list` and `real_estate`), shown in the root's differences table, the explorer's W and real-estate tips, the report's bridge, Shapley and disputed-inputs tables; `rjkdc-analysis/R/export.R` line 45 (`nber_growth_rate`, "data"); `bsz-analysis/R/site_exports.R` line 133 (τ, "scenario").
- Now: root and explorer, W: "JR: the 2025 list, 212 billionaires, grown 7% to the 31 December 2026 valuation date: $2,027B. Kind: data." Real estate: "BSZ: no deduction. Kind: data." JR export: "nber_growth_rate | data | Growth applied to the Jan-1-2026 snapshot to the Dec-31-2026 valuation date | 0.07".
- Problem: the explorer defines data as "settled by observable facts". (1) The JR base is a projection to a date that has not arrived. The chapter calls the 7% "a simple 7% growth rate ... which the Act states is the average annual growth rate of billionaire wealth since the 1980s" and checks it with a VAR(2) whose 95% interval is $1,770.6B to $2,302.6B (JR PDF pp.12-13, p.44). An assumed growth rate applied to observed lists is "guesswork on data" in the OPA's own taxonomy. (2) BSZ's "no deduction" is not an observed fact. The Act excludes directly held real property from net worth (§50303(c)(4)), BSZ's own text says so (BSZ PDF p.18), and the scoring simply does not deduct it. That is a simplification, like the JR analysis's omission of the asset-sale tax, which the same table labels "guesswork". (3) The same statutory 5% rate is "scenario" in the BSZ input table and "data" in the JR contract. The W step is small (−$2.2B on the path), but these labels are the OPA's central claim about each analysis, and a reader will check them first.
- Proposed: W, "data (BSZ) vs guesswork on data (JR: the 2025 list grown by an assumed 7% to 31 December 2026; the chapter's VAR check gives $1,770.6B to $2,302.6B)". Real estate, "guesswork (BSZ: the Act's exclusion of directly held real property, §50303(c)(4), is not deducted) vs data (JR)". One label for τ on both sides (scenario: "the Act as written"). Relabel `nber_growth_rate` in the JR contract.
- Also on: `comparison/DISPUTES.md` row 7 ("data (list membership, valuation date)"); `AUDIT.md` step 7 evidence for the comparison and JR.

### E-04. "1,916 settings the authors did not publish" counts 720 duplicate rows  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` line 287.
- Now: "for every combination of six inputs: the four rows of the paper's Table 5 plus 1,916 settings the authors did not publish."
- Problem: `site/data/grid.csv` has 1,920 rows, but "Avoidance by the less visible billionaires" varies over four levels in the 960 rows where the missing billionaires are not counted, and the explorer says it "applies only when they are counted". I grouped those 240 settings across their four αₛ levels in `grid.csv`, and every group has identical outcomes. There are 1,200 distinct settings, so 1,196 the authors did not publish.
- Proposed: "for every combination of six inputs: 1,200 settings, of which the four rows of the paper's Table 5 are the authors' own." Better, read the count from the grid by script (the headline is already read that way).

### E-05. The pages state test tolerances the tests do not apply  [blocking] [BSZ, JR]
- Where: `bsz-analysis/site/index.html` lines 496-499 and `bsz-analysis/README.md` lines 351-361; `rjkdc-analysis/site/index.html` lines 432, 515 and 529-530; `rjkdc-analysis/site/materials.qmd` lines 105-106; `rjkdc-analysis/site/repro.qmd` lines 438 and 633-635.
- Now: BSZ overview: "Every formula cell the pipeline re-derives matches the workbook's cached value within the tolerances the README lists (1e-4 for Table 5; 1e-3 to 1e-2 for the formula sheets ...)". JR overview: "mean, median, SD (standard deviation) and share negative within Monte Carlo error" and "'Match' means the reproduced value rounds to the printed digit ... and lies within four Monte Carlo standard errors for simulated ones. The test suite holds every comparison". JR report: "Every figure reproduces from the authors' own code to within the tolerances in `tests/testthat/` (printed rounding for deterministic figures, four Monte Carlo standard errors for simulated ones)."
- Problem: `testthat::expect_equal()` treats `tolerance` as relative unless `scale = 1` is passed. The JR suite's own `test-site.R` lines 33-48 pass `scale = 1` for exactly this reason. Without it:
  - BSZ: `test-tables.R` line 64 (Table 1 Panel B, AGI per family), lines 130-134 (Table 3's wealth rows) and lines 253-254 (Appendix Table A1) use `tolerance = 1`, and `test-compute.R` line 382 (`top4taxes`, average wealth) does too. Each passes at up to 100% relative error. Lines 63, 252 and 383 use `1e-1` (10%). The README lists 1e-4 to 1e-2 for `top4taxes_r`.
  - JR: `test-npv-mc.R` line 16, `expect_equal(s$pct_negative, 85.2, tolerance = 0.5)`, passes any share from about 42.6% to 127.8%. Line 7 (`71`, `tolerance = 1`) passes anything from 0 to 142. Four standard errors of the share are about 0.45 points. No expectation compares the seeded SD with the printed 37.6: the string occurs in no test file. `test-pareto.R` lines 12 and 16 hold 38.8% and 39.0% at 10% and 20% relative. `test-income-tax-mc.R` holds Table 9 at ±0.01, twice the printed rounding the report claims ("the tests hold this at the printed rounding").
  - The JR report's tolerance sentence sits above a table in which two deterministic rows do not round to the printed digit (94.30 against 94.20; 72.05 against 72.06). The tests pin the workbook values, not the print (`test-revenue-chain.R` line 12, `test-nber-final.R` line 24).
  - The numbers shown are right (85.17 against 85.2, 37.62 against 37.6). The claim that the suite holds them at the stated tolerance is what fails.
- Proposed: either (a) add `scale = 1` where an absolute band is meant (85.2 ± 0.5 points; 71 ± 1 point), set the `tolerance = 1` and `1e-1` checks to the README's values, and add an SD expectation at four standard errors (rerun both suites; the materials pages' counts follow), or (b) restate each page's claim to what the tests apply. For the JR report: "Every figure reproduces the authors' own code and workbook (`tests/testthat/`). Against the printed digits, eight of the ten rows round to the print; the two that do not are mismatches 4 and 6."
- Also on: `rjkdc-analysis/site/materials.qmd` mismatch 9 ("median and %negative match exactly"; held at 100% relative).

### E-06. "The seven inputs of the authors' simulation" includes two of this OPA's own dials  [major] [JR]
- Where: `rjkdc-analysis/site/index.html` lines 285, 429 and 484.
- Now: "Move the seven inputs of the authors' simulation"; "all 2,187 settings of the seven Monte Carlo inputs"; "Third, of the seven inputs that move the answer, six are guesswork."
- Problem: the authors' Monte Carlo has four draws and five explorer dials: the revenue floor and ceiling, C, r − g and f (`NPV_dist_v8.R` lines 19-22). The "Extra litigation weight" q and the "Further growth" g are this OPA's additions. The explorer calls g "This OPA's illustration, not the authors'", and the q dial notes "The script has no separate multiplier". At the main estimate they sit at 1 and 0. Counting them as guesswork double-counts two judgements already inside the revenue floor (litigation) and r − g (growth). So "six of seven are guesswork" overstates the guesswork attributed to the JR analysis. On the authors' own inputs it is four of five.
- Proposed: line 285: "Move the five inputs of the authors' simulation, and two this OPA adds, and watch ..."; line 429: "all 2,187 settings of seven inputs, five of them the authors' Monte Carlo ranges"; line 484: "Third, of the five inputs of the authors' simulation, four are guesswork; the explorer adds two more of this OPA's own (an extra litigation weight and extra growth)."
- Also on: `rjkdc-analysis/site/explorer/index.html` line 185 ("Six of the seven inputs below are guesswork"); `rjkdc-analysis/README.md` line 19 ("the seven inputs behind it"); the JR deck's `seven-inputs` slide (accurate as "move the answer", but the box should say which two are this OPA's).

### E-07. "85.2% of outcomes below zero" is shown with no word on what it measures  [major] [JR]
- Where: `rjkdc-analysis/site/index.html` line 464; the JR explorer header (script at line 527, "85.2% of draws fall below zero"); `rjkdc-analysis/site/repro.qmd` line 110; JR deck line 208.
- Now: "Share of outcomes below zero, as printed (85% in the text, p.1; 85.2% in the Figure 3 note, p.35) | 85.2%".
- Problem: the share comes from independent uniform draws over ranges the report itself labels guesswork ("The range is guesswork ... the width is what moves the result"). It describes how wide the guessed ranges are, not a probability that the tax loses money, and the explorer's own presets show it: 100.0% with r − g fixed at 1.5%, 63.2% at 4.5%. Cited in a hearing, "85% of outcomes negative" will be read as an 85% chance of a loss. The brief's check, that the Monte Carlo's distributions are stated with their consequences, fails here: the consequence for this statistic is not stated.
- Proposed: one sentence under the overview table and in the explorer's notes: "The share below zero summarises the authors' uniform, independent draws over ranges that are themselves guesswork. It is not a probability that the tax loses money: with the rate fixed at 1.5% it is 100%, at 4.5% it is 63.2% (the explorer's settings)." Read the two values from `grid.js`.

### E-08. "Today's dollars" is never dated, and the conventions use a different phrase  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` line 400 and `comparison/site/repro.qmd` line 234; the headline boxes on `index.html` and the explorer.
- Now: boxes: "in today's dollars"; root: "Today's dollars (present value): what income tax lost in future years is worth now." Conventions: "All amounts are billions of dollars at the assessment date."
- Problem: "now" and "at the assessment date" are different dates, and the two analyses value their bases six months apart (1 July and 31 December 2026). A scoring reader needs the date to which the lost income tax is discounted and when the first year's loss falls (the annuity factor 4.58 counts five end-of-year losses).
- Proposed: in the conventions: "Present values are as of the valuation date; the first year's lost income tax is counted one year later." Use "in today's dollars" only with a pointer to that sentence.

### E-09. The explorer's "A vs B" note describes a label the explorer no longer prints  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` line 441 (and the generated explorer).
- Now: "'A vs B' reads the BSZ value's kind against the JR value's."
- Problem: each slider end now prints its own kind ("Kind: data", "Kind: guesswork"). No tip on the explorer contains "vs" (I grepped the generated page), so the sentence explains nothing a reader can find there. The report's tables do use "A vs B", and the note is correct there.
- Proposed: on the explorer: "Each end's tip ends with the kind of that analysis's value."

### E-10. The BSZ explorer never states the yearly income tax its loss rows rest on  [minor] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html`, "The inputs" and the outcomes table.
- Now: "Income tax lost to leavers, per year | −$0.15B"; the six dials; no line for the fixed inputs.
- Problem: three outcome rows depend on fixed inputs a cold reader never sees on the page: C = $3.06B a year (Table 2), the 80% gain share and the 13.3% rate on gains, and the 5 years at 3%. The headline names only the last. `grid.js` already carries `facts` (C, `pv_rate`, `pv_years`).
- Proposed: under "The inputs", generated from `grid.js` facts and `inputs.csv`: "Fixed in every setting: billionaires' yearly California income tax, $3.06B (BSZ Table 2, research); 80% of each sale is taxable gain (research); 13.3% top rate on gains (data); losses counted 5 years at 3% (this OPA's scenario)."

### E-11. The report ranks f and H by a Shapley average without disclosing the joint effect it splits between them  [major] [comparison]
- Where: `comparison/site/repro.qmd` lines 120-126 (introduction) and the fold `#the-shapley-check` (from line 557, "Reading the (b) table"); the comparison deck's `pseudo-eq` slide, lines 541-543.
- Now: "Averaged over every order ..., the three largest are the chance it survives court (q), the share lost (f) and the years counted (H)." And: "The horizon is ... −$32.3B averaged over orders, because a perpetuity multiplies whatever annual loss the other inputs imply."
- Problem: from `switchboard.csv` (output b, own horizons), moving f and H together from the BSZ values changes the estimate by $39.6B more than moving each alone (v(f,H) − v(f) − v(H) + v(∅) = −39.61). At the JR values the same second difference is −$56.7B. The Shapley average gives half of that joint effect to each input. That is why f is −$32.6B averaged over orders but −$5.0B on the path. The report says the inputs interact, but never says that the largest single quantity in the gap belongs to neither input alone. A reader therefore takes "f is the second-largest driver" as a fact about f. That is a method choice with an undisclosed effect.
- Proposed: a generated sentence in the Shapley fold (export the value to `meta.csv` from `switchboard.csv`): "The Shapley average splits each interaction equally between the inputs that create it. The largest is between the share lost and the years counted: at the BSZ values, moving both changes the estimate by $X more than moving each alone. Half of it sits in each one's Shapley value." Add "the two share a large joint effect" after the introduction's ranking.

### E-12. The Hoopes table's "Ours" column is on output (a), which the table does not say  [minor] [comparison]
- Where: `comparison/site/repro.qmd` lines 712-728 (the table) and `comparison/R/build.R` lines 237-256 (`hoopes.csv`).
- Now: column "Ours, one order": "Confirmed departures | −$17.0B ± 0.6 | −$26.0B"; "Additional behavioral response | ... | −$29.0B".
- Problem: the revenue rows are the one-order steps on output (a). The chain starts at $103.8B (the wealth tax), not the $106.8B main estimate, and ends at the JR (b) value through the "Income tax loss" row. The (b) Shapley table two sections earlier has a "One order" column for the same order, with different values (departures −$28.21B; residency −$13.03B against −$12.6B here). A reader comparing the two sees one order giving two sizes.
- Proposed: a line under the table: "Our column follows Hoopes's construction: the revenue steps are on output (a), from the BSZ wealth tax ($103.8B), and the last row adds the JR analysis's whole income tax loss. The (b) table above reads the same order on the net fiscal effect."

### E-13. The reproduced Table 5 drops the digit the text discusses, and its note calls the loss "steady-state"  [minor] [BSZ]
- Where: `bsz-analysis/R/tables.R` lines 312-321.
- Now: the reproduced table prints "Annual CA inctax loss ($B)" as −0.2, −0.2, −0.5, −0.6 and "# CA billionaires" as 250.0, 619.6. The note says: "Annual CA inctax loss is the steady-state revenue forgone from billionaires leaving California."
- Problem: the paper prints −0.15, −0.19, −0.51 and −0.56 and counts of 250 and 620 (BSZ PDF p.39). One decimal makes rows 1 and 2 identical, and the paragraph under the table then discusses the second decimal ("printed -0.19, workbook -0.196"). The paper's column header is "Annual temporary CA income tax loss from leavers". "Steady-state" says the opposite, and it is the JR reading of the dispute.
- Proposed: in `build_tab5()`, two decimals for `annual_ca_inctax_loss`, none for `n_billionaires`. Note: "Annual CA income tax loss is the yearly income tax of leavers, which BSZ call temporary (the paper's column header)."

### E-14. The BSZ input table omits the two inputs this OPA added to the main estimate  [major] [BSZ]
- Where: `bsz-analysis/R/site_exports.R` (input rows from line 133), rendered as `site/data/inputs.csv` and the report's "Every input, by origin".
- Now: "Of the 18 inputs, 5 are guesswork, and they are exactly the explorer's 5 guesswork dials." The origin counts list "scenario | 1" (τ only).
- Problem: the main estimate ($106.8B) uses two inputs no row lists: the 5-year horizon (this OPA's reading of BSZ's example) and the 3% rate (this OPA's scenario; "BSZ give no rate"). The comparison labels both "scenario". A reader who uses the table to check "every input" of the main estimate will not find them.
- Proposed: two rows, "H | Years the income tax loss is counted | 5 | scenario | This OPA's reading of BSZ's example ('If they last say only 5 years', PDF p.27); used for the main estimate only" and "r | Discount rate for that loss | 3% | scenario | This OPA's choice, the middle of the JR range; BSZ give no rate". Then: "Of the 20 inputs ...", and "the inputs of the one-time estimate, plus the two this OPA adds for the main estimate".
- Also on: `AUDIT.md` BSZ step 7 ("18 inputs").

### E-15. Sort the report's sensitivity table by how far each guess moves the estimate  [suggestion] [BSZ]
- Where: `bsz-analysis/site/repro.qmd`, "How far the guesses move the result" (line 798 on).
- Now: rows in dial order: avoidance (81.5 to 119.4), share leaving (106.1 to 107.5), less visible avoidance (no effect), selling (103.1 to 114.2), missing billionaires (106.8 to 131.5), leavers (89.6 to 106.8).
- Problem: an analyst reads such a table for order of importance. The deck's tornado already sorts by range.
- Proposed: sort the rows by the width of the main-estimate range, as the deck does, and say so in the lead sentence.

### E-16. JR report footnote 2 cites a DISPUTES row and label that have changed  [minor] [JR]
- Where: `rjkdc-analysis/site/repro.qmd` lines 193-196; also line 670.
- Now: "The pipeline's input file ... and the comparison's [disputes row 2] label the range research, because of its published anchor."
- Problem: the rate is now `DISPUTES.md` row 10, labelled "scenario (BSZ) vs derived from the authors' draw (JR)". Row 2 is the horizon. Only the JR contract still says research. Line 670 labels an identity "NPV = WT - x* C/r", the plain-r form that mismatch 3 flags.
- Proposed: "The pipeline's input file labels the range research, because of its published anchor; the comparison, which uses one rate worth the same as the draw, labels that rate derived ([disputes row 10])." Line 670: "NPV = WT − x* C/(r − g)".

### E-17. The BSZ deck retypes the 3% rate and 5 years, and a comment describes a method the comparison dropped  [minor] [BSZ]
- Where: `bsz-analysis/site/slides/slides.Rmd` lines 473-479 and 526.
- Now: `f5 <- ann(0.03)`; `pv5 <- (1 - 1.03^(-5)) / 0.03`; comment: "The comparison overview averages over that range instead (comparison/R/model.R); the two agree to within $0.01B, checked here."
- Problem: `grid.js` and `grid.csv` already carry `pv_rate`, `pv_years`, `income_tax_loss_pv` and `main_estimate`. A change of rate in the pipeline would leave the tornado and the bottom-line slide on 3%, and the `stopifnot` would not catch it, because it uses the same typed factor. The comparison has used one 3% rate at the BSZ end since 15 October (DECISIONS), so the comment is stale. `bsz-analysis/site/repro.qmd` line 600 types the same factor in the displayed formula.
- Proposed: read the rate and years from `grid.js` facts (or use `grid.csv$main_estimate` directly), and drop the comment's second sentence.

### E-18. The Walczak report is used only by the comparison but recorded in the JR manifest  [minor] [comparison]
- Where: `comparison/site/materials.qmd`, "Sources"; `AUDIT.md`, comparison step 4.
- Now: "The two documents only the comparison uses are recorded in the manifest ..." (Hoopes and the LAO). AUDIT: "The two third-party PDFs only the comparison uses are in `comparison/DATA-SOURCES.csv`".
- Problem: `comparison/data/document-inputs.csv` rows 10-11 transcribe Walczak (California Tax Foundation, 22 Apr 2026), and the comparison report shows them. The PDF's manifest row is in `rjkdc-analysis/DATA-SOURCES.csv`, whose own "feeds" cell says "transcribed in comparison/data/document-inputs.csv; no dial". A reader tracing the comparison's sources from its materials page does not find it.
- Proposed: move the Walczak row to `comparison/DATA-SOURCES.csv`, or say "three documents; Walczak's is listed in the JR manifest".

### E-19. Two comparison records carry stale facts  [minor] [comparison]
- Where: `comparison/README.md`, "Settled items", second bullet; `comparison/site/materials.qmd`, the data-files table.
- Now: README: "The Monte Carlo ranges (WT floor 35, C in [3.3, 5.8], r - g in [1.5%, 4.5%], NBER f in [0.30, 0.60])". Materials: "inputs.csv | 15 | 7 | the disputed inputs: one row per bridge step".
- Problem: the September draw's floor is 0 (`NPV_dist_v8.R` line 19); 35 is the March floor. `inputs.csv` has one row per argument of `score_common()`: 15 rows for 11 Shapley steps and 9 dial-path steps.
- Proposed: "WT in [0, 72] (the March version's floor was 35)"; "one row per argument of the common function (15), grouped by bridge step".

### E-20. AUDIT step 1 does not record that two main estimates were redefined after results  [minor] [all]
- Where: `AUDIT.md`, BSZ step 1 and the comparison's step 1.
- Now: BSZ: "The output was fixed in `PLAN.md` (`0b07ce7`, 'Pre-specified output') and pushed in `9adcd2f` before any JR result".
- Problem: the BSZ report says the pre-specified output "named the wealth tax. The switch to the total was made on 7 October 2026". The comparison's rate became a dial and the equation's order changed on 15 October (DECISIONS rows 41-44). Level 2 turns on whether the output was fixed before results. The evidence column reads as if the current output were the pre-specified one. The level (1) does not change.
- Proposed: add to each step 1 row: "The current main estimate (the net total) replaced the pre-specified wealth tax on 7 October 2026, after results" (BSZ); "the rate dial and the equation's order were set on 15 October 2026" (comparison).

### E-21. Fourteen terms are used without a definition where a reader meets them  [minor] [all]
- Where: the jargon ledger above.
- Now: for example, the comparison explorer's r tip: "Its weight within the JR draw: the JR explorer's Rate 1.5% and 4.5% settings."; the JR report: "Share negative: quadrature vs seeded MC (points)".
- Problem: each term is defined on another page or nowhere. Four are carried over from run 002's do-later list (seeded run, Python twin, mismatch numbers, `{targets}`). The r tip, "quadrature" and the root's kind labels are new or still open.
- Proposed: the one-line definitions in the ledger's last column, at first use on each page. The r tip: "How much the rate alone moves the JR estimate: the JR explorer's Rate 1.5% and Rate 4.5% settings."
