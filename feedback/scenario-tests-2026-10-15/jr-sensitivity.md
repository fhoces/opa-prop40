# Sensitivity of the JR main estimate, 2026-10-15

## Summary

The main estimate is the NBER chapter's mean NPV, -$38.9B (PDF p.35). The OPA's exact mean is
-$38.98B, and its seeded run gives -$38.89B. I searched both papers, appendices first, and the
authors' public repo for a net estimate reported under assumptions other than the main ones. Only
5 cases exist, not 10. The NBER chapter prints no net estimate besides the main one. Its Table 10
and the text after it give break-even shares, and its Appendices B and D give revenue, not NPV.
Four cases are in the first (SSRN) version: its Monte Carlo and the three departure scenarios of
its Table 9. One more is in the repo: a 2% tax rate scenario. 4 cases are MATCH, 0 CLOSE, 0
MISMATCH and 1 NOT REACHABLE. The most important finding is that none of the 5 changes one
assumption at a time from the main estimate. The first-version Monte Carlo changes two inputs
(the revenue range and the rule for f). Each Table 9 scenario fixes four inputs at points. So the
papers give no printed check on how the main estimate moves with one input. The explorer's
one-input settings ("Rate 1.5%", "Rate 4.5%", "Litigation weight q = 0.5") have no printed
counterpart. Only case 1 can be reached with the explorer's dials.

## Results

Changes from main are the case minus the main estimate: printed minus -38.9, and OPA minus the
OPA's exact -38.98. Gaps are OPA minus printed. $B throughout.

| Case | Source, location | What changes from the main estimate | Printed | OPA | Change from main (paper / OPA) | Gap | Verdict | Reached through |
|---|---|---|---|---|---|---|---|---|
| 1 | Paper, SSRN p.20, eqs. 22-24 | WT U[0, 72] to U[35, 67.51]; f U[0.30, 0.60] to f = 1 - WT/94.2 | -24.7 | exact -24.707; seeded -24.768 | +14.2 / +14.27 | -0.007 (exact) | MATCH | Explorer dials |
| 2 | Paper, SSRN Table 9 p.19, "Only 6 Confirmed" | WT fixed 67.51, C fixed 3.3, f = 0.283, r-g fixed at 1.5 / 3.0 / 4.5% | +5.2 / +36.3 / +46.7 | +5.18 / +36.34 / +46.73 | +44.1, +75.2, +85.6 / +44.16, +75.32, +85.71 | at most 0.04 | MATCH | R only |
| 3 | Paper, SSRN Table 9 p.19, "Central" | WT fixed 42.0, C fixed 4.55, f = 0.554, r-g fixed at 1.5 / 3.0 / 4.5% | -126.1 / -42.0 / -14.0 | -126.09 / -42.04 / -14.03 | -87.2, -3.1, +24.9 / -87.11, -3.07, +24.95 | at most 0.05 | MATCH | R only |
| 4 | Paper, SSRN Table 9 p.19, "Literature Calibrated" | WT fixed 35.0, C fixed 5.8, f = 0.628, r-g fixed at 1.5 / 3.0 / 4.5% | -208.0 / -86.5 / -46.0 | -208.00 / -86.50 / -46.00 | -169.1, -47.6, -7.1 / -169.02, -47.52, -7.02 | under 0.01 | MATCH | R only |
| 5 | Repo, `NPV_plots/npv_decomposition_2pct.pdf` (script `NPV_data/npv_decomposition_2pct.R`) | Tax rate 5% to 2%, with WT fixed 16.8, f fixed 0.554, C fixed 4.55, r-g fixed 3% | -67.2 | none (hand-built inputs give -67.22) | -28.3 / n/a | n/a | NOT REACHABLE (no wealth tax rate setting) | Neither |

## How to rerun

From the repo root:

```sh
export RAUH_REPO_DIR=$PWD/rjkdc-analysis/original-materials/author-shared/2026-09-23_wealth_tax-repo
Rscript feedback/scenario-tests-2026-10-15/jr-sensitivity.R
```

The script reads the explorer's own grid (`rjkdc-analysis/site/explorer/grid.js`) for the main
estimate and case 1, and calls `rjkdc-analysis/R/` functions for the rest. It runs in a few
seconds.

## The main estimate

NBER, PDF p.35. WT ~ U[0, 72], f ~ U[0.30, 0.60], C ~ U[3.3, 5.8], (r-g) ~ U[1.5%, 4.5%], 100,000
draws, seed 2026. Printed mean -$38.9B. Explorer main setting: wt_lo 0, wt_hi 72, q 1, C 3.3 to
5.8, rate 1.5% to 4.5%, f 0.30 to 0.60, g 0. It shows the exact mean, -$38.98B.
`compute_npv_mc_nber()` gives the seeded -$38.89B. Both are checked in the earlier file,
`jr.md`, combination 1.

## Case 1. First version's Monte Carlo (MATCH)

**Where.** SSRN, PDF p.20, eqs. 22-24 and the text below. Mean NPV -$24.7B.

**What changes.** Two inputs. The revenue draw moves from U[0, 72] to U[35, 67.51]. The share of
income tax lost is no longer drawn on its own: f = 1 - WT/94.2, so it moves with revenue. C, the
rate range and the plain-r formula are unchanged.

**OPA.** Explorer dials: "Lowest revenue" to 35, "Highest revenue" to 67.51, "Share of the income
tax base that leaves" to 1 - WT/94.2, the rest at the main setting. The explorer shows the exact
mean, -$24.707B. The seeded run, `compute_npv_mc_ssrn()`, gives -$24.768B (simulation error
$0.122B).

**Verdict.** MATCH on the exact mean. The seeded value prints as -24.8, a gap already recorded
in `MISMATCHES.md` #9. The paper moves the estimate by +14.2, the OPA by +14.27.

## Case 2. First version's Table 9, "Only 6 Confirmed Departures" (MATCH)

**Where.** SSRN, Table 9, PDF p.19, first column pair. NPV +$5.2B, +$36.3B, +$46.7B at
(r-g) = 1.5%, 3.0%, 4.5%.

**What changes.** No draws. WT is fixed at 67.51, the revenue after six moves. C is fixed at its
low end, 3.3. f = 1 - 67.51/94.2 = 0.283. The rate is fixed at each of the three values.

**OPA.** The explorer cannot set this. It has the C, rate and f levels (3.3 only, 1.5% or 4.5%
only, 0.283 fixed), but no setting fixes WT at one value. Its revenue dials stop at a lowest of
45.59 and start at a highest of 55.10. R: `compute_npv_table9()`, whose defaults are the paper's
scenarios.

**Verdict.** MATCH in all three cells.

## Case 3. First version's Table 9, "Central Scenario" (MATCH)

**Where.** SSRN, Table 9, PDF p.19, second column pair. NPV -$126.1B, -$42.0B, -$14.0B.

**What changes.** WT fixed at 42.0, a typed value with no derivation (`MISMATCHES.md` #8). C
fixed at 4.55. f = 1 - 42.0/94.2 = 0.554. The rate fixed at each of the three values.

**OPA.** Not reachable with the dials, for the same reason as case 2. R:
`compute_npv_table9()`.

**Verdict.** MATCH in all three cells. At 3% this cell is -$42.0B, close to the main estimate's
-$38.9B. The two agree by coincidence, not because the assumptions agree: the central cell fixes
WT at 42 and f at 0.554, while the main estimate draws WT around a mean of 36 and f around 0.45.

## Case 4. First version's Table 9, "Literature Calibrated Departures" (MATCH)

**Where.** SSRN, Table 9, PDF p.19, third column pair. NPV -$208.0B, -$86.5B, -$46.0B.

**What changes.** WT fixed at 35.0, C fixed at its high end, 5.8. f = 1 - 35/94.2 = 0.628. The
rate fixed at each value.

**OPA.** Not reachable with the dials (WT cannot be a point; the lowest revenue dial's 35 is a
range floor, not a fixed value). R: `compute_npv_table9()`.

**Verdict.** MATCH in all three cells.

## Case 5. Repo: a 2% tax rate with departures sunk (NOT REACHABLE)

**Where.** The authors' public repo, `NPV_plots/npv_decomposition_2pct.pdf`, made by
`NPV_data/npv_decomposition_2pct.R` (dated June 2026, after the first version; not in either
paper). The plot prints NPV -$42.0B at the 5% rate and -$67.2B at a 2% rate.

**What changes.** The wealth tax rate falls from 5% to 2%. The script keeps the departures
already made: f is fixed at 0.554, so revenue is (1 - 0.554) x 2% x 1,884 = $16.8B. C is fixed at
4.55 and r-g at 3%. Its 5% bar is case 3's 3% cell (-$42.0B).

**OPA.** No setting. The OPA has no wealth tax rate input, and the f dial can be fixed only at
0.283. Feeding hand-computed inputs to `compute_npv_table9()` (a 2% baseline of 37.68 and
WT = 16.8, so that its f = 1 - WT/baseline equals 0.554) gives -$67.22B. That shows the
arithmetic is the same NPV formula. It is not an OPA setting, so the verdict stays NOT
REACHABLE. The missing setting is the wealth tax rate.

## Searched and left out

- **NBER chapter.** Table 10 and the text on PDF p.34 give break-even shares, not NPVs. Among
  them, "at the $72 billion revenue ceiling ... 47.5 percent" is also a break-even share.
  Appendix B (PDF pp.42-43) gives revenue under the Lucas departure counts ($52.89B and $4.82B).
  Appendix D (PDF pp.45-47) gives revenue and a $37 to $46 billion revenue gap. None is a net
  estimate.
- **SSRN version.** Table 10 (break-even shares) and the revenue chain are not net estimates.
- **Repo plots that print only a share of negative draws, not a net estimate.** These were left
  out under the brief's rule. `npv_distribution_1.5to5.pdf` (88.8% negative),
  `npv_distribution_1.5to7.pdf` (61%) and `npv_distribution_3to7.pdf` (46.2%) vary the rate range,
  but on an earlier parameter set (WT ~ U[44, 66], C ~ U[4.9, 5.8]) that neither paper uses.
  `npv_distribution_2pct_sunk.pdf` (99.6% negative) is the 2% case as a Monte Carlo; its mean is
  printed only to the console, not saved. `npv_vs_rate_2pct.pdf` draws NPV against the tax rate
  but labels no values. The other `npv_distribution*.pdf` files are earlier runs of the first
  version's Monte Carlo. If the author wants the share-negative figures tested too, the R
  functions can reach the rate-range ones. The explorer cannot, because its rate dial has no 4%,
  7% or 3% to 7% level.
- **Horizon.** Both versions use a perpetuity. Neither prints an NPV at a finite horizon.
