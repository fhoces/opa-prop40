# Sensitivity of the BSZ main estimate, 2026-10-15

This file checks how the BSZ main revenue estimate (Table 5 row 1, $103.82B, printed as $104B)
moves when the authors change an assumption, and whether the BSZ analysis moves the same way.
The two BSZ papers print seven such cases. All seven are in Table 5: rows 2 to 4 of the August
paper and rows 1 to 4 of the May paper. The May rows use an earlier valuation date (4/15/2026).
There is no paper in `september-2026/`, only a workbook. Neither paper prints a revenue figure
under any other assumption. That rules out another avoidance rate, another share of avoidance
that is leaving, another share paid by selling assets, and leaving out the phase-in,
non-citizens or real estate. So I took three more cases from the authors' public workbook,
labelled as workbook. They are the revenue on three other valuation dates in its daily 2026
series. That makes 10 cases. All 7 paper cases are a MATCH. The 3 workbook cases are NOT
REACHABLE. The BSZ analysis has no setting for the valuation date. The only other date it can
use is 4/15/2026, through the May workbook (`BSZ_VINTAGE=may`). The most important finding is
this gap. The valuation date moves the estimate as much as any assumption the paper varies,
from $87B (3/30/2026) to $111B (10/6/2026). The explorer has no dial for it. Three cases (S1
to S3) are reachable in the explorer, through its two switches. The explorer's four numeric
dials (α, m, αₛ, s) have no printed case to test against.

Sources: the August paper `bsz-analysis/original-materials/BSZ26CAbillionaires.pdf` (Table
5, PDF p.39), the May paper `original-materials/may-2026/BSZ26CAbillionaires.pdf` (Table 5,
PDF p.34; text p.21), and the default (2026-10-08) workbook `BSZ_MainTablesFigures.xlsx`,
sheet `shortrunseries`, rows 15 to 272. That series has one row per day from 1/1/2026 to
10/7/2026, with the number of billionaires, their wealth and the "wealth tax with 10%
evasion" (0.045 x wealth). Its 7/1/2026 row is $103.815B, the same as Table 5 row 1. I also
checked the Tab5slides-a and Tab5slides-b sheets. They repeat Table 5 rows 1 to 3 and add
no case.

Columns: "Change in paper" is the printed case minus the printed $104B. For workbook cases
it is minus the workbook's own 103.815. "Change in OPA" is the BSZ analysis's case minus
103.815. "Gap" is the BSZ analysis minus the printed value. MATCH means the BSZ analysis
rounds to the printed digits.

## Results

| id | Where | What changes from the main estimate | Printed | Change in paper | BSZ analysis | Change in OPA | Gap | Verdict | How reached |
|---|---|---|---|---|---|---|---|---|---|
| S1 | Aug paper, Table 5 row 2, p.39 | Adds the 368 billionaires Forbes misses ($1-4.5B, Pareto), at 20% avoidance, with the phase-in | 128 | +24 | 127.85 | +24.04 | -0.15 (-0.1%) | MATCH | Explorer: P switch on |
| S2 | Aug paper, Table 5 row 3, p.39 | Page, Thiel, Hankey, Kalanick escape the tax | 89 | -15 | 88.80 | -15.01 | -0.20 (-0.2%) | MATCH | Explorer: L switch on |
| S3 | Aug paper, Table 5 row 4, p.39 | Both S1 and S2 (two changes) | 115 | +11 | 114.82 | +11.00 | -0.18 (-0.2%) | MATCH | Explorer: P and L on |
| S4 | May paper, Table 5 row 1, p.34 | Valuation date 4/15/2026 ($2,182B, 249 billionaires) | 98 | -6 | 98.19 | -5.63 | +0.19 (+0.2%) | MATCH | R: `BSZ_VINTAGE=may` |
| S5 | May paper, Table 5 row 2, p.34 | 4/15/2026 and S1's change | 121 | +17 | 120.93 | +17.11 | -0.07 (-0.1%) | MATCH | R: May, `pareto = TRUE` |
| S6 | May paper, Table 5 row 3, p.34 | 4/15/2026 and S2's change | 84 | -20 | 83.94 | -19.87 | -0.06 (-0.1%) | MATCH | R: May, `leavers = TRUE` |
| S7 | May paper, Table 5 row 4, p.34 | 4/15/2026 and both | 109 | +5 | 108.55 | +4.73 | -0.45 (-0.4%) | MATCH | R: May, both on |
| S8 | Workbook, shortrunseries, 1/1/2026 | Valuation date 1/1/2026, the residency date ($2,054.8B) | 92.47 | -11.35 | none | none | none | NOT REACHABLE (no valuation-date setting) | none |
| S9 | Workbook, shortrunseries, 3/30/2026 | Valuation date at the 2026 low ($1,933.0B) | 86.99 | -16.83 | none | none | none | NOT REACHABLE (no valuation-date setting) | none |
| S10 | Workbook, shortrunseries, 10/6/2026 | Valuation date at the 2026 high to date ($2,463.3B) | 110.85 | +7.03 | none | none | none | NOT REACHABLE (no valuation-date setting) | none |

To rerun (from the repo root, with the August and May workbooks in
`bsz-analysis/original-materials/`):

```sh
Rscript feedback/scenario-tests-2026-10-15/bsz-sensitivity.R
```

The script sources `bsz-analysis/R/*.R` and builds the inputs from each workbook with
`tab5_scoring_inputs()`. It calls `score_tab5_cell()`, the function the reproduction and the
explorer share. It reads S1 to S3 from `site/explorer/grid.js` and stops if they differ from
the R values. It writes no file.

## S1. Adding the billionaires Forbes misses

- **Where.** August paper, Table 5 row 2 (p.39); text p.25: "increase wealth tax revenue
  by over $24 billion to $128 billion".
- **Change.** The 4/15/2026 Pareto tail adds 368 billionaires and $615B, which is 28% more
  wealth. They avoid at 20%, not 10%. The phase-in for wealth between $1B and $1.1B is
  deducted.
- **BSZ analysis.** Explorer dial "Count billionaires Forbes misses" (P) set to on, with the
  other dials at their defaults. That is the "Missing billionaires" named row. Revenue is
  127.85 (+24.04). MATCH.

## S2. Aggressive leavers

- **Where.** August paper, Table 5 row 3 (p.39); text p.26: "falls from $104 billion down
  to $89 billion".
- **Change.** Page, Thiel, Hankey and Kalanick, with $333.6B, are taken out of the base.
  Brin, Zuckerberg and Fang still pay. Their later departure changes only the income tax
  loss, not the revenue.
- **BSZ analysis.** Explorer dial "Aggressive assumption on leavers" (L) set to on (named
  row "Leavers"). Revenue is 88.80 (-15.01). MATCH.

## S3. Both changes

- **Where.** August paper, Table 5 row 4 (p.39); text p.27: "the wealth tax scoring is $115
  billion".
- **Change.** S1 and S2 together. Following the workbook, this row does not deduct the
  phase-in. With the deduction it would be 112.84.
- **BSZ analysis.** Explorer dials P and L both on (named row "Missing + leavers"). Revenue
  is 114.82 (+11.00). MATCH.

## S4. Valuation date 4/15/2026 (May paper benchmark)

- **Where.** May paper, Table 5 row 1 (PDF p.34); text p.21: "Using the April 15 wealth
  value ... of $2.18 trillion, the wealth tax scores at $98 billion (=90%*5%*$2182
  billion)".
- **Change.** Forbes wealth on 4/15/2026 ($2,182B, 249 billionaires) instead of 7/1/2026
  ($2,307B, 250). The other assumptions are unchanged.
- **BSZ analysis.** No explorer dial. In R: `Sys.setenv(BSZ_VINTAGE = "may")`, build the
  inputs from the May workbook, then `score_tab5_cell(inp)`. Revenue is 98.19 (-5.63).
  MATCH. Note that the October workbook's daily series has 4/15/2026 at $2,185.3B and
  98.34, because Forbes revised that day's data after May. Both round to 98.

## S5. 4/15/2026 and the missing billionaires

- **Where.** May paper, Table 5 row 2 (p.34); text p.22: "by over $20 billion to $121
  billion".
- **Change.** S4's date and S1's change.
- **BSZ analysis.** R, May workbook, `score_tab5_cell(inp, pareto = TRUE)`. Revenue is
  120.93. MATCH.

## S6. 4/15/2026 and aggressive leavers

- **Where.** May paper, Table 5 row 3 (p.34).
- **Change.** S4's date and S2's change.
- **BSZ analysis.** R, May workbook, `score_tab5_cell(inp, leavers = TRUE)`. Revenue is
  83.94. MATCH.

## S7. 4/15/2026 and both

- **Where.** May paper, Table 5 row 4 (p.34); text p.23: "the wealth tax scoring is $109
  billion".
- **Change.** S4's date with S1 and S2.
- **BSZ analysis.** R, May workbook, `score_tab5_cell(inp, pareto = TRUE, leavers =
  TRUE)`. Revenue is 108.55. MATCH.

## S8 to S10. Other valuation dates (workbook, not paper)

- **Where.** The authors' public workbook, sheet `shortrunseries`, columns A to D of rows 15
  to 272. These hold the daily series behind the paper's tracker. The August paper (p.24)
  gives only the wealth at these dates: "from $2.05 trillion to $2.3 trillion" between 1/1
  and 7/1, and "a low of $1.93 trillion to a high of $2.35 trillion" up to July. It prints
  no revenue for them. The workbook prints the revenue.
- **Change.** The valuation date, so the Forbes wealth, is 1/1/2026 ($2,054.8B, revenue
  92.47), 3/30/2026 (the 2026 low, $1,933.0B, revenue 86.99) or 10/6/2026 (the high to date,
  $2,463.3B, revenue 110.85). The last day in the series, 10/7/2026, gives 110.52. The tax
  itself uses wealth on 12/31/2026, so the date is a real unknown of the estimate.
- **BSZ analysis.** NOT REACHABLE. The missing setting is the valuation date: the wealth W0
  is the constant `tab5_const("baseline_wealth")` in `R/vintage.R`, which is 2,307 for
  August and 2,182 for May. No dial or argument changes it. If W0 is replaced by hand in the
  inputs list (`by_hand()` in the script), `score_tab5_cell()` gives 92.47, 86.99 and 110.85.
  That is exactly the workbook, because revenue at the defaults is 0.9 x 5% x W0. So the
  only missing piece is an input for the date or the wealth.
