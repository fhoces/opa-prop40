# Reproduction notes

The pipeline reproduces the published results of both versions of the JR analysis from the
authors' own code, workbooks and data: the revenue chain, the income tax tables, the NPV and
break-even tables and both Monte Carlo summaries. A deterministic figure counts as reproduced when
it rounds to the printed digit, or when it differs only because the paper rounded or typed an
intermediate figure (0.1% or less in every case below). A simulated figure counts as reproduced
when it lies within four Monte Carlo standard errors of the printed value. Two runs of a Monte
Carlo with different seeds never give identical figures.

The ten notes below are kept for transparency. Each records a place where the authors' text, their
READMEs and their code describe the same step in different words or numbers. None of them is a
failure to reproduce a printed result. They are of three kinds, and each note states its kind
under its heading:

- **Rounded or typed inputs** (notes 4, 6 and 8): the paper prints, or the code uses, a rounded
  or typed value where a more precise one exists or no derivation is given. Every printed result
  built on the value reproduces.
- **Seed variation** (note 9): the printed Monte Carlo summary comes from a different run of the
  same code than the shipped seed gives. It lies within Monte Carlo error.
- **Documentation** (notes 1, 2, 3, 5, 7 and 10): the text, a README and the code describe one
  calculation differently (a typo, a formula written two ways, a stale cell reference). The code
  as shipped gives the printed results.

An earlier version of these pages called all ten "mismatches", one list on an equal footing, and
counted the rounding and seed differences as results that did not match. That overstated them,
and the notes were reclassified on 2026-10-16;
`feedback/006-2026-10-16-jr-author-mismatches/REPORT.md` gives each note's old and new label.

Notes 1, 2, 7, 8 and 9 concern only the authors' first version (Rauh, Jaros, Kearney, Doran and
Cosso, Hoover Institution, SSRN 6340778, March 2026), which the pipeline also reproduces. Notes 3
to 6 and 10 concern the NBER chapter (10 is in the first version too).

The notes come from reproducing Jaros and Rauh,
*The Net Present Value of the California Billionaire Tax Act* (NBER chapter c15504, Tax Policy and the Economy vol. 41, September 2026;
first version by Rauh, Jaros, Kearney, Doran and Cosso, March 2026). By design, we do not
"fix" the authors: we reproduce their code as run, record the note, and where it matters
expose the alternative reading as a parameter with both readings under test.

## 1. First version: eq. 22 prints the revenue ceiling as 67.1; the code and the rest of the text use 67.51

**Kind:** documentation.

**First-version paper**, p.20, eq. 22: `WT ~ U[$35B, $67.1B]`.
**Code**, `NPV_data/NPV_dist.R:31`: `wt_max <- 67.51`.

`$67.51B` is the confirmed-6-departures revenue ceiling used everywhere else in that version (p.11,
Table 9's "Only 6 Confirmed Departures" column); `$67.1B` appears nowhere else. We treat 67.51 as
the intended value (it is what the shipped, runnable code uses and what every other reference to
the ceiling states) and reproduce the code, not the typo.

## 2. First version: the text derives a growing perpetuity (`r-g`); the Monte Carlo code divides by plain `r`

**Kind:** documentation.

**First-version paper**, p.18, eq. 20: `NPV = WT - f * C / (r - g)` (eq. 18 on the same page is the plain-`r` form, `NPV = WT - f * C / r`), introduced with an explicit growth-rate
adjustment (Gordon Growth Model discussion, p.18-19).
**First-version paper**, p.20, eq. 24 and surrounding prose: switches notation to plain `r ~ U[0.015, 0.045]`
and states "NPV = WT - f * C / r" for the Sec 5.5 Monte Carlo.
**Code**, `NPV_data/NPV_dist.R:60`: `pv_lost <- annual_loss / r_discount` (plain `r`, no growth
term).

That version's prose is internally inconsistent (Sec 5.2 derives a growing-perpetuity formula,
Sec 5.5 silently drops the growth term); the code matches the *later* (Sec 5.5) plain-`r` reading.
`R/npv_mc.R:compute_npv_mc_ssrn()` reproduces the code (plain `r`).

## 3. The sentence after eq. 19 writes C/r where the draw is (r - g)

**Kind:** documentation.

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:22,28`: draws
`rg_discount <- runif(n_sims, 0.015, 0.045)`, labelled `(r-g)`.
**Paper**, PDF p.35, eq. 18 draws `(r - g) ~ U[0.015, 0.045]`, after eqs. 13-14 (PDF p.31) derive
the growing perpetuity f·C/(r − g) and PDF p.32 calibrates (r − g) ≈ 0.015 from the dividend
yield; the sentence after eq. 19 then computes `NPV = WT - f * C / r`.
**NBER README** (`NBER_2026_litigation_weighted/README.md` at `25e84dd`): the row "Simulation
draws (100,000)" gives (r − g) ~ U[1.5%, 4.5%] for both versions, and the row "NPV formula" gives
NPV = WT − f·C / (r − g) for both. The repository's root README writes r ~ U[1.5%, 4.5%] for the
first version's `NPV_dist.R`, whose code divides by plain r (note 2). For the September
chapter the code, eq. 18 and the NBER README agree on (r − g); only the one sentence writes r.

## 4. NBER ceiling: one quantity at three roundings (72 in the script, 72.06 in the README and eq. 4, 72.05 in `final.csv`)

**Kind:** rounded or typed input.

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:19`: `wt_max <- 72` (a literal).
**NBER README** assumptions table: "$72.06B" (text).
**NBER chapter**, PDF pp.21-22 (eq. 4): the same 72.06 in the semi-elasticity formula; PDF pp.24, 33
and 34: "$72 billion" as the ceiling, and the central revenue of Table 10 as 0.5 x 72 = $36 billion.
**Our recomputation** from `final.csv` (`R/nber_final.R:compute_nber_ceiling()`,
`py/nber_final.py:compute_nber_ceiling()`): domestic total at 7% growth
(`sum(face_tax_5pct[panel=="domestic"])` = $100.9056B) minus the 7 `removed_departed` rows
($28.8541B) = **$72.0515B**.

The three numbers are one quantity at three roundings. The person-level data sum to 72.0515. The
72.06 is the difference of the two figures each rounded to two decimals first (100.91 - 28.85).
The 72 is the chapter's own round figure, and the script draws revenue up to it. The gaps are
$0.01B (0.01%) and $0.05B (0.07%). Every printed result reproduces with the round 72, and two need
it. Table 10 does: with 0.5 x 72.05 its 3% cell would print 23.8%, not the printed 23.7%. Eq. 4's
semi-elasticity does too: (100.9 - 72)/100.9/0.05 = 5.73, the printed value, while the 72.06 shown
in the equation gives 5.72. The pipeline rebuilds the ceiling from `final.csv` for the record and
uses the script's 72 for every result, as the authors do.

## 5. The litigation weight `q = 0.50` is carried by the revenue draw, not by a multiplier in the code

**Kind:** documentation.

**NBER README** assumptions table: "Litigation risk: Probability the Act survives constitutional
challenge, q = 0.50 (ASC 740-10 'more likely than not'), applied to the recognized base" - listed
as a defining feature of the litigation-weighted approach.
**Code**, `NPV_dist_v8.R:19`: `wt_min <- 0;    wt_max <- 72      # wealth-tax revenue ($B), embeds litigation range`.
The script's header, lines 5-6: `WT ~ U[$0B, $72B] wealth tax revenue (0 = Act struck down; 72 = ceiling after confirmed departures)`.
No `q` variable and no `* 0.5` anywhere in the file.

The script's comment says the draw "embeds litigation range": `E[U(0, 72)] = 36 = 0.5 * 72`, i.e. drawing `WT`
uniformly from 0 to the ceiling has the *same expected value* as multiplying the ceiling by 0.5.
The README states q = 0.50 for the point estimate (0.50 × 59.15 = 29.6, eqs. 6-8) and a uniform
draw from 0 (struck down) to 72 for the simulation; the draw and q applied to the 72 ceiling
(the chapter's central estimate, PDF p.33) share a mean, 36, but not a distribution. The code has no
separate q. We reproduce the code as shipped (wt ~ U[0, 72]). The chapter also grounds the 0 floor
in unreported departures (fn.32, PDF p.34).

## 6. Baseline revenue: the paper types 94.20 and builds on it; the workbook's own sum is 94.30

**Kind:** rounded or typed input.

**Workbook**, `CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!C5`
(`=SUM(Calculations_Preferred!O3:O214)/$M$2`) = **94.30426206**.
**Workbook**, `Summary_Preferred!C8` = **94.2** (typed literal, feeds `F8`'s literature-calibrated
formula, p.14 eq.13) and `NPV_calculations_5.2.xlsx!B5` = **94.2** (typed literal, feeds every
Table 9/10 scenario's `f = 1 - WT/baseline`, p.19-20).
**First-version paper**, p.10 (Sec 4.1): "the wealth tax would generate **$94.20** billion in revenue."
**NBER chapter**, PDF pp.18-19 (Sec 4.1, eq. 2): the same **$94.20B**. It then grows the baseline
7% to "approximately $100.9 billion" (PDF p.13), which is 1.07 x 94.30 (100.91); 1.07 x 94.20 would
be 100.79. Its person-level file at the grown vintage, `final.csv`, sums to $100.906B, exactly
1.07 x 94.304.

The printed 94.20 is not a rounding of the workbook's sum, which rounds to 94.30. It is a value
typed into two cells, and the first version builds every later number on it: the literature
calibration, Table 9, Table 10 and the Monte Carlo's `f = 1 - WT/94.2`. The pipeline reproduces
every one of those printed numbers with the typed 94.2. The two baselines differ by $0.10B (0.1%).
The shared materials do not show where 94.20 comes from: the workbook's only committed version
sums to 94.30. The NBER chapter's ceiling and Monte Carlo come from `final.csv`, which agrees with
94.30; its Appendix B repeats the first version's calculations on 94.20.
`R/revenue_chain.R:compute_revenue_chain()` reports both `baseline_precise` (94.30, from the
per-row sum) and `baseline_literal` (94.2, the value used downstream).

## 7. First version: two memo cells, `Summary_Expanded!D23:D24`, read from the wrong sheet (stale copy-paste)

**Kind:** documentation.

**Workbook**, `Summary_Expanded!D23`:
`=SUMIF(Calculations_Preferred!F3:F214,"N",Calculations_Preferred!D3:D214)` - and `D24` the same
pattern with column `L`. Both reference **`Calculations_Preferred`** (the 6-departure scenario)
even though every other formula on this sheet (including the revenue figure that actually matters,
`F5`) correctly references `Calculations_Expanded` (the 10-departure scenario). This looks like a
copy-paste artifact from building `Summary_Expanded` off a copy of `Summary_Preferred`. It does
not affect any number this pipeline reproduces (`F5` = $55.10B is correctly sourced), only the
"Stayers" net-worth memo cells (`C22:D25`), which we do not use.

## 8. First version: the Table 9 central scenario (WT = $42.0B) is a typed input with no derivation

**Kind:** rounded or typed input.

**Workbook**, `NPV_calculations_5.2.xlsx!B12`: `42` (typed literal, no formula).
**First-version paper**, p.19: "The Central Scenario uses a revenue estimate of $42.0 billion and a midpoint
income tax estimate (C = $4.55 billion)."

Every other WT figure in that version traces to a computation (94.20 -> 67.51 -> 55.10 baseline
chain, or 45.59 via the literature semi-elasticity). $42.0B does not: it is not the average of any
two chain values (e.g. (67.51+35)/2 = 51.3, not 42), not the preferred-estimate midpoint stated on
p.14 ((35+46)/2 = 40.5, close but not equal), and not linked to any semi-elasticity via the eq.
12-13 formula used elsewhere. We treat it as a freestanding scenario input (labelled `scenario` in
`export/{r,py}/inputs.csv`, not `data` or `research`) and do not attempt to re-derive it.

## 9. First version: the printed Monte Carlo summary comes from a different run of the same code

**Kind:** seed variation.

**First-version paper**, p.20: mean -$24.7B, median -$19.1B, sd $38.4B, 71% negative.
Running the authors' own unmodified `NPV_data/NPV_dist.R` from a scratch copy (seed 2026,
n=100,000, `wt_max <- 67.51` as shipped) gives **mean -$24.77B, median -$19.10B, sd $38.60B, 71.0%
negative**, matching our R port to 1e-9 (`tests/testthat/test-npv-mc.R`). The median and share
negative round to the printed digits. The mean and sd are $0.07B and $0.2B away.

Both gaps are within Monte Carlo error. Over 100,000 draws the standard error of the mean is about
$0.12B and that of the sd about $0.10B, so the gaps are about 0.6 and 1.9 standard errors, inside
the four-standard-error tolerance the tests use. The draws are independent uniforms, so the model's
exact mean and sd have closed forms (`npv_mc_analytic_mean()`, `npv_mc_analytic_sd()` in
`R/npv_mc.R`): **-$24.707B** and **$38.423B**. Both round to the printed digits. So the printed
summary is what the same code gives on a run with a different seed or random-number state: across
400 seeds, about one in twenty gives all four printed values
(`feedback/006-2026-10-16-jr-author-mismatches/seed-spread.R`). The shipped seed, 2026, gives the
figures above. The eq. 22 typo (note 1, 67.1 vs 67.51) does not explain the gap: with
`wt_max <- 67.1` the mean moves to -$25.3B. The NBER version's printed summary (mean -$38.9B,
median -$35.3B, sd $37.6B, 85.2% negative) reproduces from `NPV_dist_v8.R` with the shipped seed.

## 10. The top 212's share of bracket tax is printed as 39.0% and as 38.8% for one formula

**Kind:** documentation.

**NBER chapter**, PDF p.27, after eq. 10: "For the top 212 of 4,729 filers, this implies a 39.0%
share of bracket tax liability, or approximately $4.3 billion in Tax Year 2023."
**NBER chapter**, PDF p.28: "the continuous Pareto share S(212, 4,729) = (212/4,729)^((α−1)/α) =
38.8% of bracket tax liability."
**First-version paper**: the same two sentences, p.15 (after eq. 16, 39.0%) and p.16 (38.8%).
**Code**, `NPV_data/monte_carlo_sim.R:68-70`: computes the continuous share,
`(212 / 4729)^((alpha - 1) / alpha)` = 38.85% at the fitted alpha of 1.4379, and the share of the
top 212 in the rank-implied schedule before rescaling, 34.75%, then rescales the schedule so the
top 212 hold the continuous share.

The text prints one formula with two values. The code's continuous share rounds to 38.8%, and
no step of the code gives 39.0% (the formula at the rounded alpha of 1.44 gives 38.7%). The
$4.3 billion follows from 38.8% as well (0.3885 x 11.1 = 4.31). The income tax draws use the
rescaled schedule, so no number downstream changes. `tests/testthat/test-pareto.R` holds the
continuous share against the printed 38.8% and the unrescaled share against 34.75%; the printed
39.0% is recorded here, not tested.
