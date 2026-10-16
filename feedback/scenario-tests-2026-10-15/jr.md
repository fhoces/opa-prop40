# Scenario tests: the JR analysis, 2026-10-15

## Summary

I tested 10 combinations of assumptions for which Jaros and Rauh print an estimate: 6 from the
NBER September 2026 chapter and 4 from the first (SSRN, March 2026) version. Each was run through
the OPA's own R functions with the paper's settings. 7 are MATCH, 2 are CLOSE, 0 are MISMATCH and
1 is NOT REACHABLE. Every printed NPV, break-even share, revenue figure and income tax cell that
the OPA has a setting for reproduces at the paper's rounding. The two CLOSE results are already in
`MISMATCHES.md` (#4, #6 and #9), apart from one new small item: the chapter's semi-elasticity of
5.73 (eq. 4) does not follow from its own inputs, which give 5.72. The most important finding is
the NOT REACHABLE one. The chapter's "expanded departures" case (Table 8: about 42% of the base,
semi-elasticity 8.41) has no function or dial in the OPA. No grouping of the `final.csv` buckets
gives 42.05%, and the 41.5% in Appendix D is the first version's number. Only 2 of the 10
combinations can be reached with the public explorer's dials. The rest need the R code.

A premise note. The brief names "Table 9 (NPV by departure scenario)". In the NBER chapter, Table 9
is the income tax Monte Carlo. The NPV-by-scenario table exists only in the first version (its
Table 9). Both are tested below, each under its own version's numbering.

## Results

| id | Version, location | Assumptions | Printed | OPA | Gap | Verdict | Explorer |
|---|---|---|---|---|---|---|---|
| 1 | NBER, p.35 (PDF), eqs. 16-19 and text | WT ~ U[0, 72], f ~ U[0.30, 0.60], C ~ U[3.3, 5.8], (r-g) ~ U[1.5%, 4.5%], seed 2026, 100,000 draws | mean -38.9, median -35.3, sd 37.6, 85.2% negative, P5 -107.9, P95 15.9 ($B) | -38.886, -35.256, 37.623, 85.17%, -107.904, 15.908 | mean +0.014 (0.04%) | MATCH | Yes (shows the exact mean, -38.98) |
| 2 | NBER, Table 10 p.34 and the text below it | x* = WT(r-g)/C; WT = 36 (q = 0.5 times 72), C = 4.55, r-g = 1.5/3/4.5%; text: C = 3.3, C = 5.8, WT = 72 at 3% | 11.9, 23.7, 35.6; 32.7, 18.6, 47.5 (%) | 11.87, 23.74, 35.60; 32.73, 18.62, 47.47 | all within 0.04 points | MATCH | No |
| 3 | NBER, pp.22-23, eqs. 5-8 | q = 0.50 times the recognized base; with Zuckerberg; with the gray zone out | 29.6, 35.6, 28.4 ($B) | 29.575, 35.588, 28.403 | -0.025 (-0.09%) on the central | MATCH | No |
| 4 | NBER, pp.19-22, Table 7, eq. 4 | Seven publicly reported moves removed from the 7%-grown base | 100.9, 28.85, 72.06 ($B); 28.6%; eps 5.73 | 100.906, 28.854, 72.052; 28.60%; 5.719 | ceiling -0.009 (-0.01%); eps -0.011 (-0.19%) | CLOSE | No |
| 5 | NBER, Sec 5.1 pp.26-30, Table 9 | Pareto fit on six FTB thresholds; 212 drawn from the top K, K = 212, 300, 500, 1000; seed 42 | alpha 1.44; K=300: 4.61 (4.14-5.01); K=500: 3.31 (2.83-3.82); K=1000: 2.10 ($B) | 1.438; 4.609 (4.136-5.007); 3.308 (2.829-3.818); 2.099 | at most 0.004 | MATCH | No (the C dial offers only the 3.3 and 5.8 ends) |
| 6 | NBER, Table 8 p.25; Appendix D p.45 | Expanded departures: seven moves plus post-snapshot and reported leavers | about 42%, eps 8.41 (Table 8); 41.5% (App. D) | no function; nearest bucket set 41.76%, eps 8.35 | n/a | NOT REACHABLE | No |
| 7 | SSRN, Table 9 p.19 | Fixed WT and C per scenario, f = 1 - WT/94.2, r-g = 1.5/3/4.5% | 9 PV and 9 NPV cells, e.g. +5.2, -42.0, -208.0 ($B) | +5.18, -42.04, -208.00 | all 18 cells within 0.05 | MATCH | No |
| 8 | SSRN, Table 10 p.20 | Same three scenarios, x* = WT(r-g)/C | 9 cells, e.g. 30.7, 27.7, 18.1 (%) | 30.69, 27.69, 18.10 | all within 0.05 points | MATCH | No |
| 9 | SSRN, pp.10-14, eqs. 6-13, fn. 6 | Six confirmed, ten reported, Swiss eps 10.32, eps 12 and 13 | 67.51, 55.10, 45.59, 37.7, 33.0 ($B); eps 5.67, 8.30 | 67.511, 55.096, 45.593, 37.68, 32.97; 5.667, 8.302 | at most 0.03 | MATCH | No (values are dial levels, not outputs) |
| 10 | SSRN, p.20, eqs. 22-24 | WT ~ U[35, 67.51], f = 1 - WT/94.2, C ~ U[3.3, 5.8], r ~ U[1.5%, 4.5%], seed 2026 | mean -24.7, median -19.1, sd 38.4, 71% negative ($B) | -24.768, -19.100, 38.596, 71.02%; exact mean -24.707 | mean -0.068 (-0.28%); sd +0.196 (+0.51%) | CLOSE | Yes (shows the exact mean, -24.7) |

Gaps are OPA minus printed. Page numbers are PDF pages.

## How to rerun

From the repo root:

```sh
export RAUH_REPO_DIR=$PWD/rjkdc-analysis/original-materials/author-shared/2026-09-23_wealth_tax-repo
Rscript feedback/scenario-tests-2026-10-15/jr-scenarios.R
```

The script sources `rjkdc-analysis/R/*.R`, calls the functions named below and prints one row per
printed number (printed, OPA, rounded OPA, gap, gap in %, and whether it matches at the printed
digit). It ran in about 30 seconds, including the full income tax sweep. `JR_SKIP_INCOME_MC=1`
reads the stored `income_tax_mc` target instead.

## 1. NBER: the headline Monte Carlo (MATCH)

**Where.** NBER, PDF p.35, eqs. 16-19 and the paragraph under Figure 3. Mean -$38.9B, median
-$35.3B, sd $37.6B, P5 -$107.9B, P95 $15.9B. The Figure 3 alt text gives 85.2% negative.

**Assumptions.** WT ~ U[0, 72], f ~ U[0.30, 0.60], C ~ U[3.3, 5.8], (r-g) ~ U[0.015, 0.045],
independent draws, 100,000 of them, seed 2026. These are the defaults of `compute_npv_mc_nber()`.
Explorer: the main setting (wt_lo 0, wt_hi 72, q 1, C 3.3 to 5.8, r 1.5% to 4.5%, f 0.30 to 0.60,
g 0).

**Calls.** `compute_npv_mc_nber()$summary`; `npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045,
f_mode = "nber", f_min = 0.30, f_max = 0.60)`; the grid cell `site_named()$nber` of
`compute_site_grid(rc)`.

**Result.** All six seeded statistics match at the printed digit. The simulation error of the mean
is $0.119B. The exact (closed-form) mean is -$38.98B. It differs from the seeded -$38.89B by 0.75
simulation errors, so the printed -38.9 is one draw from a model whose mean rounds to -39.0.

**Explorer.** Reachable. The explorer shows the exact mean, -$38.98B, and 85.3% negative, not the
seeded -38.9 and 85.2%. Its notes already say so.

## 2. NBER: break-even departure shares (MATCH)

**Where.** NBER, Table 10, PDF p.34: 11.9%, 23.7%, 35.6% at (r-g) = 1.5%, 3.0%, 4.5%. The text
under it: 32.7% at C = $3.3B, 18.6% at C = $5.8B, and 47.5% at the $72B ceiling, all at 3%.

**Assumptions.** x* = WT(r-g)/C (eq. 15). WT = 36, the litigation weight q = 0.5 applied to the
72 ceiling. C = 4.55, the midpoint of 3.3 and 5.8.

**Calls.** `compute_npv_table10(scenarios = list(central = list(label = "Central", WT = 36, C =
4.55)))` for the table row. The same with `r_values = 0.03` and WT, C set to (36, 3.3), (36, 5.8)
and (72, 4.55) for the text.

**Result.** All six cells match at the printed digit. One check on the 72: with WT = 0.5 times the
ceiling rebuilt from `final.csv` (72.05), the 3% cell becomes 23.75%, which would print as 23.8%.
So Table 10 uses the script's round 72, not the rebuilt value (MISMATCHES #4).

**Explorer.** Not reachable. The explorer has no break-even output, and WT cannot be fixed at a
point.

## 3. NBER: collectible revenue with the litigation weight q (MATCH)

**Where.** NBER, PDF pp.22-23. Collectible base $71.17B (p.22). Recognized base $59.15B (eq. 5).
E[R] = 0.50 x 59.15 = $29.6B (eqs. 6 and 8). Keeping Zuckerberg: $35.6B (eq. 7). Moving the seven
ambiguous names and Koum, Hastings and Fang out: $28.4B (p.23).

**Assumptions.** q = 0.50 as a multiplier. Recognized base = stayers plus ambiguous rows in
`final.csv` at the 7%-grown vintage. Zuckerberg excluded (central) or included (upper).

**Calls.** `compute_nber_collectible(extract_nber_final(), q = 0.50)`.

**Result.** 29.6, 35.6, 28.4, 59.15, 58.06 and 1.09 all match. One intermediate does not: the
collectible base is 71.176, which rounds to 71.18, while the paper prints 71.17. The gap is $0.006B.
It looks like truncation in the paper. The headline estimates are unaffected. This is not in
`MISMATCHES.md`; the report prints the OPA's 71.18 beside "printed $71.17B" without comment.

**Explorer.** Not reachable. The explorer's "expected wealth tax collected" is q times the mean of
the revenue draw (36 at the main setting), not this point estimate.

## 4. NBER: seven publicly reported moves (CLOSE)

**Where.** NBER, PDF pp.19-22. Grown face value $100.9B (p.19). Table 7 total tax avoided $28.85B
(p.21). Revenue after seven moves $72.06B (pp.21-22). Eq. 4: (100.9 - 72.06)/100.9 = 28.6%, and
28.6%/5% = 5.73 (p.22). Pre-filing departures $0.88B (p.22).

**Assumptions.** Seven moves removed (Page, Brin, Thiel, Hankey, Spielberg, Kalanick, Sacks), net
worth grown 7% to 31 December 2026, real estate excluded, 5% rate.

**Calls.** `compute_nber_ceiling(extract_nber_final())`; the semi-elasticity as
`(1 - ceiling_recomputed / domestic_total_grown) / 0.05`, the same line as the report's
`semi-elasticity` chunk.

**Result.** 100.9, 28.85, 0.88 and 28.6% match. The ceiling is 72.05 against 72.06: already
`MISMATCHES.md` #4 (rounding of two rounded figures). The semi-elasticity is 5.72 against 5.73.
This one is the paper's arithmetic: its own rounded inputs give (100.9 - 72.06)/100.9/0.05 = 5.717,
and 28.6/5 = 5.72. I am fairly sure 5.73 is a slip in the chapter. It is not in `MISMATCHES.md`.
The report (Section 4.3) shows 5.72 next to "printed 5.73" without saying why.

**Explorer.** Not reachable as an output. The 72 appears only as a dial level.

## 5. NBER: income tax Monte Carlo (MATCH)

**Where.** NBER, Sec 5.1, PDF pp.26-30. alpha = 1.44, R^2 = 0.999 (p.26). Top-212 share 39.0%
(p.27) and 38.8% (p.28) for the same formula S(212, 4729). Table 9 (p.30): K = 212 mean 5.76;
K = 300 mean 4.61 (P5 4.14, P95 5.01); K = 500 mean 3.31 (P5 2.83, P95 3.82); K = 1000 mean 2.10.

**Assumptions.** OLS Pareto fit on six cumulative filer counts. 4,729 filers in the $10M+ bracket,
$11.1B of tax, rescaled to the continuous share, scaled to FY 2024-25 by 130/97.4. 212 billionaires
drawn without replacement from the top K, 100,000 draws per K, one seed (42) over the whole sweep.

**Calls.** `compute_pareto_fit()`; `compute_pareto_income_schedule(pf)`;
`compute_income_tax_mc(sched$tax_by_rank)` (the full 37-point sweep, so the seed stream matches).

**Result.** All eight Table 9 cells match at the printed digit. The simulation error of each mean
is under $0.001B. The share is 38.85%, which matches the 38.8% on p.28 but not the 39.0% on p.27.
With alpha rounded to 1.44 it is 38.72%. Neither gives 39.0. The chapter prints two values for one
formula, and the OPA reproduces the second. Not in `MISMATCHES.md`; minor.

**Explorer.** Not reachable. The C dial offers only the two ends of the range (3.3 and 5.8), not
Table 9's rows.

## 6. NBER: expanded departures (NOT REACHABLE)

**Where.** NBER, Table 8, PDF p.25: "CA expanded departures, observed, about 42%, eps = 8.41". The
text says this count incorporates "post-snapshot and reported departures" and "matches the Swiss
baseline of 41.1 percent almost exactly". Appendix D (p.45) gives 41.5% for "the expanded
reported-departure scenario", and p.38 repeats "approximately 42 percent".

**Assumptions.** Not stated in the chapter. The OPA has no function, target or dial for an NBER
expanded-departure set. The missing piece is the list of who counts as an expanded departure at
the grown vintage.

**What I tried.** I summed `final.csv` buckets (OPA data, no new code) for six candidate sets. As a
share of the grown tax base: seven moves plus Zuckerberg, 40.51% (eps 8.10); plus Koum, Hastings
and Fang, 41.76% (8.35); plus the pre-filing three, 42.63% (8.53); plus the ambiguous seven too,
43.70% (8.74). Shares of net worth instead of tax base move each by about 0.1 points. None gives
42.05% (= 8.41 x 5). The Appendix D figure, 41.5%, equals the first version's 41.51% (its eq. 9,
ten departures against 94.20), and Appendix D's 28.3% for confirmed departures is also the first
version's number. So Appendix D appears to carry first-version figures, while Table 8 uses a
different set. I am not sure which set gives 8.41.

**Explorer.** Not reachable.

## 7. First version: NPV by departure scenario (MATCH)

**Where.** SSRN, Table 9, PDF p.19. Three scenarios by three rates, PV(lost PIT) and NPV in each
cell. Also f = 28.3%, 55.4%, 62.8% (p.19).

**Assumptions.** Six confirmed (WT 67.51, C 3.3), central (WT 42.0, C 4.55), literature calibrated
(WT 35.0, C 5.8). f = 1 - WT/94.2. NPV = WT - f C/r at r = 1.5%, 3.0%, 4.5%. No randomness.

**Calls.** `compute_npv_table9()` (defaults are the paper's scenarios).

**Result.** All 18 cells and the three f values match at the printed digit. The largest gap is
$0.045B (central at 3%). The 94.2 here is the rounded literal, as `MISMATCHES.md` #6 records, and
the 42.0 central revenue has no derivation (#8).

**Explorer.** Not reachable. WT cannot be fixed at a single value: the lowest-revenue dial stops at
45.59 and the highest starts at 55.10, so the draw always has a range.

## 8. First version: break-even departure shares (MATCH)

**Where.** SSRN, Table 10, PDF p.20. Nine cells from 9.1% to 92.1%.

**Assumptions.** The three Table 9 scenarios, x* = WT r / C.

**Calls.** `compute_npv_table10()`.

**Result.** All nine cells match at the printed digit; the largest gap is 0.05 points.

**Explorer.** Not reachable (no break-even output).

## 9. First version: the revenue chain (MATCH)

**Where.** SSRN, PDF pp.10-14. Baseline $94.20B (p.10). Six confirmed departures $67.51B (p.11).
Ten reported departures $55.10B (pp.12-13). Literature calibrated $45.59B (eq. 13, p.14).
Semi-elasticities 5.67 (eq. 8) and 8.30 (eq. 11). Footnote 6: semi-elasticities 12 and 13 give
$37.7B and $33.0B.

**Assumptions.** Person-level workbook rows, 5% of net worth less residential real estate, rows
marked as movers removed. Literature case: (1 - 0.05 x eps) x 94.2.

**Calls.** `compute_revenue_chain(extract_calculations_preferred(),
extract_calculations_expanded())`, and the same with `brulhart_semi_elasticity = 12` and `13` for
footnote 6.

**Result.** 67.51, 55.10, 45.59, 37.7, 33.0, 5.67 and 8.30 all match. The baseline sums to 94.30,
not 94.20: already `MISMATCHES.md` #6.

**Explorer.** Not reachable as outputs. 45.59, 55.10 and 67.51 appear as dial levels.

## 10. First version: the Monte Carlo (CLOSE)

**Where.** SSRN, PDF p.20, eqs. 22-24. Mean -$24.7B, median -$19.1B, sd $38.4B, 71% negative.

**Assumptions.** WT ~ U[35, 67.51] (the code's bound; eq. 22 prints 67.1), C ~ U[3.3, 5.8],
r ~ U[0.015, 0.045], f = 1 - WT/94.2, plain r, seed 2026. The defaults of `compute_npv_mc_ssrn()`.

**Calls.** `compute_npv_mc_ssrn()$summary`; `compute_npv_mc_ssrn(wt_max = 67.1)$summary`;
`npv_mc_analytic_mean(35, 67.51, 3.3, 5.8, 0.015, 0.045, f_mode = "ssrn", baseline_revenue = 94.2)`.

**Result.** Median and share negative match. The seeded mean is -24.77 (prints as -24.8) and the
sd is 38.60 (prints as 38.6). The mean gap is 0.56 simulation errors ($0.122B each). The exact mean,
-24.707, matches the printed -24.7. With the printed bound 67.1 the mean moves away (-25.34). All of
this is already `MISMATCHES.md` #9. The sd gap remains unexplained there and here.

**Explorer.** Reachable with the dials (wt_lo 35, wt_hi 67.51, q 1, C 3.3 to 5.8, r 1.5% to 4.5%,
f = 1 - WT/94.2, g 0). The explorer shows the exact mean, -$24.7B. It does not offer this setting
in "Jump to a setting".

## What the brief listed that the paper does not print

- **Horizons.** Both versions treat the income tax loss as a perpetuity. Neither prints an NPV at a
  finite horizon, so there is nothing to test.
- **Fixed-rate NPVs in the NBER chapter.** The chapter presents (r-g) of 1.5%, 3.0% and 4.5%
  (p.32) but prints NPVs at fixed rates only in the first version (combination 7). The explorer's
  "Rate 1.5%", "Rate 4.5%" and "q = 0.5" settings therefore have no printed NBER number to check.
