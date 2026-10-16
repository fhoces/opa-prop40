# Scenario tests of the BSZ analysis, 2026-10-15

This file tests ten combinations of assumptions for which the BSZ paper prints an estimate.
Six are a MATCH, one is CLOSE, three are a MISMATCH and none is NOT REACHABLE. None of the
three mismatches is a bug in the BSZ analysis. In each case the BSZ analysis gives the same
value as the authors' workbook. The paper either prints a value that differs from its own
workbook (C2) or uses a shortcut in its text (C6, C9). The most important finding is C6. The
paper says that if every billionaire left, it would take 25 years for the lost income tax
to equal the wealth tax. That figure assumes billionaires pay 0.2% of their wealth in income
tax each year. Table 5, and therefore the BSZ analysis, assumes $3.06 billion a year on
$2,307 billion of wealth, which is 0.13%. On those inputs the break-even is 38 years, not 25.
The public explorer can reach only the three Table 5 rows tested here (C1 to C3). Every other
combination needs the R code. The paper prints no revenue figure at another avoidance rate,
another horizon or a discount rate. So the explorer's other dial settings and the $106.8
billion main estimate (5 years at 3%) have no printed figure to test against.

Source: `bsz-analysis/original-materials/BSZ26CAbillionaires.pdf`, the August 2026 revision
(NBER WP 35218, "May 2026, Revised August 2026"). Page numbers are PDF pages. The default
workbook is the August paper with the data appendix of 2026-10-08. `VERIFY-AUGUST.md` says the
PDF did not change between the two August appendices. C4 uses the May 2026 PDF and workbook
(`BSZ_VINTAGE=may`), because the August paper no longer prints the May figures.

Verdicts: MATCH means the BSZ analysis's value rounds to the printed digits. CLOSE means the
gap is under 2% and has a stated reason. A combination gets the worst verdict among its
cells. The sections below list every cell.

## Results

| id | Paper location | Assumptions | Printed | BSZ analysis | Gap | Verdict | Explorer |
|---|---|---|---|---|---|---|---|
| C1 | Table 5 row 1, p.39; text p.24 | Forbes 7/1/2026; 10% avoidance, half of it leaving; 1/3 of tax paid by selling assets | $104B revenue; $3.7B extra; -$0.15B/yr | 103.82; 3.68; -0.153 | -0.18 (-0.2%) | MATCH | Yes ("Base") |
| C2 | Table 5 row 2, p.39; text p.25 | C1 plus the billionaires Forbes misses ($1-4.5B), 20% avoidance for them, phase-in deducted | $128B revenue (+$24B); 12.2%; $4.5B; -$0.19B/yr | 127.85 (+24.04); 12.20%; 4.53; -0.196 | revenue -0.15 (-0.1%); loss -0.006 (-3.3%) | MISMATCH (loss cell only; paper's rounding) | Yes ("Missing billionaires") |
| C3 | Table 5 row 4, p.39; text p.27 | C2 plus the aggressive leavers; no phase-in deduction | $115B; $2,296B taxable; 22.4%; $4.1B; -$0.56B/yr | 114.82; 2,296.3; 22.35%; 4.07; -0.559 | -0.18 (-0.2%) | MATCH | Yes ("Missing + leavers") |
| C4 | May paper, Table 5 row 3, May PDF p.34 | Forbes 4/15/2026 (May workbook); 10% avoidance; Page, Thiel, Hankey, Kalanick escape; Brin, Zuckerberg, Fang leave later | $84B; $1,679B taxable; 23.1%; $3.0B; -$0.53B/yr | 83.94; 1,678.9; 23.06%; 2.98; -0.528 | -0.06 (-0.1%) | MATCH | No (explorer is August only) |
| C5 | Text p.24-25 and Table 5 notes, p.39 | Pareto tail with b averaged above $4.5B, extended down to $1B (4/15/2026 list) | b = 4.48; 617 billionaires; +368; +$615B; +28%; +148%; 208 in ($1B, $1.5B) | 4.479; 617.1; 368.1; 615.1; 28.2%; 147.8%; 207.9 | +0.08 billionaires (0.0%) | MATCH | No (only the switch that adds them) |
| C6 | Text p.22 | All billionaires (or one-fourth) leave after 1 Jan 2026, so all pay the tax; loss lasts until it equals the revenue | 25 years (all); 100 years (one-fourth) | 37.7; 150.7 | +12.7 years (+51%) | MISMATCH (the paper's text uses 0.2%; Table 5 implies 0.13%) | No |
| C7 | Footnote 29, p.22 | A permanent yearly loss discounted at 3% | factor 33 | 33.33 | +0.33 (1.0%) | MATCH | No (horizon fixed at 5 years) |
| C8 | Text p.29-30; Figure 9, p.48 | Permanent 1% wealth tax on top of the 0.2% income tax; e = 10 | keeps 88% of mechanical revenue; under 10% lost to mobility | 88.6%; 9.5% | +0.6 points (0.7%) | CLOSE (paper's linear shortcut) | No |
| C9 | Text p.28-30 | Revenue-maximising rates: mobility only (e = 10), then with de-concentration (d = 15) | 10%; 3.8%; base -15% at 1% | 10.0%; 3.9%; base -14.0% | +0.1 points (2.6%) on 3.8% | MISMATCH (paper's first-order formula) | No |
| C10 | Text p.29, footnote 37 | e = 500; remove the 0.2% income tax | billionaires x2.7 | 2.718 | +0.02 (0.7%) | MATCH | No |

To rerun everything (from the repo root, with the three workbooks in `bsz-analysis/original-materials/`):

```sh
Rscript feedback/scenario-tests-2026-10-15/bsz-scenarios.R
```

The script sources `bsz-analysis/R/*.R` and builds the inputs straight from the workbook. It
calls `compute_pareto_missing()`, `compute_pareto_summary()`, `tab5_scoring_inputs()`,
`score_tab5_cell()`, `site_pv_factor()` and `compute_fig8_laffer()`. It does not read the
targets store, so a stale store cannot change its results. It writes no file. It also looks
up the Table 5 rows in the explorer's `site/explorer/grid.js` and prints them. Those values
are the same as the R values in C1 to C3.

## C1. Table 5 row 1, the benchmark

- **Paper.** Table 5 row 1 (p.39, "All amounts in nominal $ billions"). The wealth tax
  revenue is $104B, the total of the one-time tax over its 5 years, undiscounted. Extra CA
  income tax from asset sales is $3.7B. The yearly CA income tax loss from leavers is
  -$0.15B. Text p.24: "=90%*5%*$2307 billion".
- **Assumptions to dials.** α (avoidance) = 10%. m (share of avoidance that is leaving) =
  50%. s (share paid by selling) = 1/3. P (missing billionaires) = off. L (aggressive
  leavers) = off. Gains share = 80% and CA rate = 13.3% are fixed inputs.
- **Call.** `score_tab5_cell(inp)` with all defaults.
- **Result.** 103.815, 3.682, -0.1531. All three round to the printed figures. MATCH.
- **Explorer.** Yes, the "Base" named row (grid cell revenue 103.81).

## C2. Table 5 row 2, adding the billionaires Forbes misses

- **Paper.** Table 5 row 2 (p.39) prints $128B revenue, a 12.2% avoidance rate, $4.5B extra
  income tax and -$0.19B a year. Text p.25: "increase wealth tax revenue by over $24 billion
  to $128 billion. The income tax loss of the 5% of leavers would correspondingly increase
  to $0.19 billion."
- **Assumptions.** As C1 plus P = on. Avoidance for the added billionaires (αₛ) = 20%. The
  phase-in deduction for wealth between $1B and $1.1B is applied.
- **Call.** `score_tab5_cell(inp, pareto = TRUE)`.
- **Result.** Revenue is 127.855, which is +24.04 over C1. The avoidance rate is 12.199%
  and extra income tax is 4.535. These match. The loss is -0.1962, which rounds to -0.20,
  not -0.19 (gap 0.006, 3.3%). Verdict: MISMATCH on the loss cell only.
- **Cause.** The paper's rounding. The workbook's own cached cell (Tab5 row 7) is -0.1962,
  and the BSZ analysis reproduces it. The paper prints -0.19 in both the table and the
  text. Sure (the workbook cell is checked by the test suite at 1e-4). The report already
  discloses this (`site/repro.qmd`, "Two printed cells that differ from the workbook"), and
  so does `site/data/tab5-vs-printed.csv`. The same holds for row 3's loss (-0.5154, printed
  -0.51). It is not an OPA bug.
- **Explorer.** Yes, the "Missing billionaires" named row.

## C3. Table 5 row 4, missing billionaires and aggressive leavers

- **Paper.** Table 5 row 4 (p.39) prints $115B revenue, $2,296B taxable wealth, a 22.4%
  avoidance rate, $4.1B extra and -$0.56B a year. Text p.27: "the wealth tax scoring is
  $115 billion ... The annual income tax loss is $0.56 billion".
- **Assumptions.** P = on and L = on. Page, Thiel, Hankey and Kalanick escape the tax.
  Brin, Zuckerberg and Fang pay, then leave.
- **Call.** `score_tab5_cell(inp, pareto = TRUE, leavers = TRUE)`.
- **Result.** 114.817; 2,296.33; 22.35%; 4.072; -0.5586. All match. MATCH.
- **Code path note.** This row tests the workbook's quirk that row 4 does not subtract the
  phase-in deduction that row 2 subtracts. The BSZ analysis keeps that literal behaviour.
  With the deduction, revenue would be 112.84, printed as 113. The printed 115 confirms the
  BSZ analysis follows what the authors did.
- **Text claim, p.27.** "If they last say only 5 years ... those losses are likely to be
  smaller than the California income tax on realized capital gains due to sales". The BSZ
  analysis confirms this for all four rows. The undiscounted five-year loss against the
  extra income tax is: 0.77 vs 3.68; 0.98 vs 4.53; 2.58 vs 3.15; 2.79 vs 4.07.
- **Explorer.** Yes, the "Missing + leavers" named row.

## C4. May paper, Table 5 row 3, aggressive leavers (May vintage)

- **Paper.** `original-materials/may-2026/BSZ26CAbillionaires.pdf`, Table 5 row 3 (PDF
  p.34, Forbes estimates as of 4/15/2026). It prints 249 billionaires and $2,182B wealth.
  Taxable wealth is $1,679B, the avoidance rate 23.1% and revenue $84B. Extra income tax is
  $3.0B and the yearly loss -$0.53B. The August paper replaced these figures with 7/1/2026
  ones, so this scenario exists only in the May version.
- **Assumptions.** As August row 3: α = 10%, m = 50%, P off, L on. Inputs come from the
  May workbook (n0 = 249, W0 = $2,182B, C = $3.032B a year, wealth of the pre-2026 leavers
  $316.6B).
- **Call.** `Sys.setenv(BSZ_VINTAGE = "may")`, then build the inputs from the May workbook,
  then `score_tab5_cell(inp, leavers = TRUE)`. See `inputs_for("may")` in the script.
- **Result.** 1,678.85; 23.06%; 83.94; 2.977; -0.5279. All match. MATCH.
- **Explorer.** No. The explorer's grid is built from the August workbook only.

## C5. The Pareto extrapolation of missing billionaires

- **Paper.** Text p.24-25 (based on the 4/15/2026 list). Above $4.5B, b is 4.48 on
  average. At $1B, b is "almost 9". There "should be around 617 California billionaires
  (instead of the 249 listed by Forbes), i.e. 368 more". They "would add about $615 billion
  in wealth, 28% more". "The majority (208 out of 368) of missing billionaires are in the
  range ($1b, $1.5b)". Table 5 notes, p.39: "The total number of billionaires increases by
  148% but total billionaire wealth increases by only 28%."
- **Assumptions.** Pareto b is the mean of the empirical b at thresholds of $4.5B and up.
  The count is extended from the $4.5B anchor (89 billionaires) down to $1B.
- **Calls.** `compute_pareto_missing(extract_pareto_missing())` and
  `compute_pareto_summary()`. The 208 is `projected_density[1] - actual_density[1]`.
- **Result.** b = 4.479; Forbes b at $1B = 8.76; 617.08 billionaires; 368.08 extra;
  $615.1B extra; +28.2%; +147.8%; 207.9 in the first bracket. All match. MATCH.
- **Note.** Table 5 prints 620 billionaires in rows 2 and 4, not 617. Both are right.
  Table 5 applies the 4/15 increase of 147.8% to the 7/1 count of 250 (250 x 2.478 = 619.6).
- **Explorer.** No. The P switch turns the result on, but the explorer shows none of
  these counts. They are in the report and in `site/data/pareto-summary.csv`.

## C6. Years for the lost income tax to equal the wealth tax

- **Paper.** Text p.22: "even if one-fourth of all billionaires left, it would take 100
  years for the income tax loss to match the revenue from the wealth tax. In the extreme
  case where all billionaires left, it would take 25 years". The previous sentence gives
  the ratio: billionaires "pay about 0.2% of their wealth in California income taxes". The
  arithmetic is 5% / 0.2% = 25 and 5% / (0.25 x 0.2%) = 100.
- **Assumptions.** The leavers go after 1 January 2026, so everyone pays the tax: revenue
  at α = 0, which is 5% x $2,307B = $115.35B. The yearly loss is the whole CA income tax of
  billionaires (α = 100%, m = 100%), or one fourth of it (α = 25%, m = 100%).
- **Calls.**
  `score_tab5_cell(inp, avoidance = 0)[["wealth_tax_revenue"]]` divided by
  `-score_tab5_cell(inp, avoidance = 1, mobility_share = 1)[["annual_ca_inctax_loss"]]`,
  and the same with `avoidance = 0.25`.
- **Result.** 115.35 / 3.061 = 37.7 years, and 150.7 years for one fourth. The gap is +51%.
  MISMATCH.
- **Cause.** The paper uses two different income-tax-to-wealth ratios. The text on p.21-22
  uses 0.2% of wealth (Table 2's recent years: 0.21% in 2023 and 2025). Table 5 uses $3.06B
  a year, the 2019-2025 average in dollars, against July 2026 wealth of $2,307B. That is
  0.133% of wealth. The BSZ analysis follows Table 5, so its loss per dollar of departing
  wealth is about two thirds of the ratio the text uses. This is not an OPA bug. Sure: the
  paper's 25 and 100 come out exactly from 0.2%, and the OPA's 37.7 comes out exactly from
  3.061 / 2,307. It is worth knowing for the comparison. The 0.2% in the text would give a
  loss about 1.5 times as large as Table 5's in any scenario where someone leaves. The
  BSZ analysis has no setting to switch between the two ratios.
- **Explorer.** No. α stops at 30%, and the explorer shows no break-even years.

## C7. Footnote 29: a permanent loss is magnified by a factor of 33

- **Paper.** Footnote 29, p.22: "the income tax loss is magnified by a factor 33 (using
  their central discount rate 3.0%)". That is the present value of $1 a year for ever at 3%.
- **Assumptions.** Horizon = for ever, discount rate = 3%.
- **Call.** `site_pv_factor(0.03, Inf)`, the same function the main estimate uses with
  H = 5.
- **Result.** 33.33. MATCH. For reference, the BSZ analysis's own horizon (5 years at 3%)
  gives 4.58.
- **Explorer.** No. The horizon and the rate are fixed at 5 years and 3%. The explorer's
  main estimate has no printed counterpart in the paper.

## C8. A permanent 1% wealth tax keeps 88% of its mechanical revenue

- **Paper.** Text p.29-30: "a 1% permanent wealth tax reduces the wealth tax base by 10%
  ... mobility responses mechanically reduce wealth tax revenue by 10% and an additional 2%
  is lost due to loss of income tax. On net, a 1% wealth tax collects 88% of the projected
  revenue absent mobility responses." Figure 9 note, p.48: "of less than 10% for mobility".
- **Assumptions.** e = 10, current CA income tax τ0 = 0.2% of wealth, base $2,000B (the
  workbook's Fig9 inputs). The wealth tax is 1% on top of τ0, so the total rate is 1.2%.
- **Call.** `compute_fig8_laffer()`. Take actual revenue at a rate of 1.2%, subtract the
  current income tax (0.002 x 2,000), and divide by the mechanical 1% x 2,000.
- **Result.** 17.716 / 20 = 88.6%, which would print as 89%. Wealth tax revenue lost to
  mobility is 1 - exp(-0.1) = 9.5%, under 10%. CLOSE (gap 0.6 points, 0.7%).
- **Cause.** The paper adds up the first-order effects (1 - 10% - 2%). The workbook's curve,
  which the BSZ analysis reproduces, uses the exact exponential base exp(-e x 1%). Sure.
- **Explorer.** No. The explorer covers only the one-time tax. The permanent-tax curve is
  only in the R code (target `fig8_laffer_r`, figure `fig8`).

## C9. Revenue-maximising rates of a permanent tax

- **Paper.** Text p.28-29: with mobility only, the rate that maximises revenue is "τ=1/e=10%
  per year", so "9.8%" on top of the income tax. Text p.30: with de-concentration as well,
  "τ=1/(1+d+e)=1/26=3.8%". And "with a 1% annual permanent wealth tax, the de-concentration
  effect reduces the wealth tax base by about 15%".
- **Assumptions.** e = 10, d = 15, τ0 = 0.2%.
- **Calls.** `compute_fig8_laffer()`, then `which.max()` of `actual_tax_revenue` and of
  `long_run_tax_revenue` on its 0.1-point grid. Also `1 - 0.99^15`, and `optimize()` on
  τ exp(-eτ)(1-τ)^d for the exact optimum.
- **Result.** Mobility only: 10.0%. MATCH. With de-concentration: 3.9% on the grid, and
  3.904% exactly, against the printed 3.8% (gap 0.1 points, 2.6%). Base lost at 1%: 14.0%
  against "about 15%". Verdict: MISMATCH on the 3.8%.
- **Cause.** The paper uses a first-order formula. 1/(1+d+e) is the optimum after
  replacing (1-τ)^d by exp(-dτ). The exact maximum of the workbook's own Fig9 curve, which
  the BSZ analysis reproduces at 1e-6, is 3.9%. Likewise, "about 15%" is d x 1%, while
  the curve's factor is 1 - 0.99^15 = 14%. Sure. It is not an OPA bug, and the gap does not
  change the paper's argument.
- **Explorer.** No.

## C10. With e = 500, removing the income tax multiplies billionaires by 2.7

- **Paper.** Text p.29: "if e=500, then exempting California billionaires from California
  income tax entirely, would increase the number of California billionaires by a factor
  2.7". Footnote 37: Z = Z0 exp(-eτ), so with τ = 0.2% and e = 500, Z = Z0/2.7.
- **Assumptions.** e = 500, τ0 = 0.2%. Compare the base at a tax rate of 0 with the base at
  the current rate.
- **Call.** `compute_fig8_laffer(semi_elasticity_mobility = 500)`. Divide
  `wealth_tax_base` at rate 0 by 2,000.
- **Result.** 2.718. MATCH.
- **Explorer.** No.

## What this test did not cover

- The paper prints no revenue at an avoidance rate other than 10% (listed) and 20% (missing
  billionaires). It also prints none for another share of avoidance that is leaving or
  another share paid by selling assets. The explorer's other dial levels cannot be tested
  against the paper.
- The paper prints no present value of the one-time tax over a horizon. The $106.8 billion
  main estimate (5 years at 3%) is the BSZ analysis's own definition. C7 tests only the
  discount function it uses.
- The 21% fall in the base from an estate-tax analogy (text p.21) is not tied to any
  revenue figure, so there is nothing to reproduce.
