# Mismatches

Mismatches 1, 2, 7, 8 and 9 concern only the authors' first version (Rauh, Jaros, Kearney, Doran and Cosso, Hoover Institution, SSRN 6340778, March 2026), which the pipeline also reproduces. Mismatches 3 to 6 and 10 concern the NBER chapter (10 is in the first version too).

One numbered item per code/paper or doc/code discrepancy found while reproducing Jaros and Rauh,
*The Net Present Value of the California Billionaire Tax Act* (NBER chapter c15504, Tax Policy and the Economy vol. 41, September 2026;
first version by Rauh, Jaros, Kearney, Doran and Cosso, March 2026). By design, we do not
"fix" the authors: we reproduce their code as run, record the discrepancy, and where it matters
expose the alternative reading as a parameter with both readings under test.

## 1. First version: the printed WT upper bound (67.1) vs. the code's literal (67.51)

**First-version paper**, p.20, eq. 22: `WT ~ U[$35B, $67.1B]`.
**Code**, `NPV_data/NPV_dist.R:31`: `wt_max <- 67.51`.

`$67.51B` is the confirmed-6-departures revenue ceiling used everywhere else in that version (p.11,
Table 9's "Only 6 Confirmed Departures" column); `$67.1B` appears nowhere else. We treat 67.51 as
the intended value (it is what the shipped, runnable code uses and what every other reference to
the ceiling states) and reproduce the code, not the typo.

## 2. First version: growing perpetuity in the text (`r-g`) vs. plain-`r` code

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

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:22,28`: draws
`rg_discount <- runif(n_sims, 0.015, 0.045)`, labelled `(r-g)`.
**Paper**, PDF p.35, eq. 18 draws `(r - g) ~ U[0.015, 0.045]`, after eqs. 13-14 (PDF p.31) derive
the growing perpetuity f·C/(r − g) and PDF p.32 calibrates (r − g) ≈ 0.015 from the dividend
yield; the sentence after eq. 19 then computes `NPV = WT - f * C / r`.
**NBER README** (`NBER_2026_litigation_weighted/README.md` at `25e84dd`): the row "Simulation
draws (100,000)" gives (r − g) ~ U[1.5%, 4.5%] for both versions, and the row "NPV formula" gives
NPV = WT − f·C / (r − g) for both. The repository's root README writes r ~ U[1.5%, 4.5%] for the
first version's `NPV_dist.R`, whose code divides by plain r (mismatch #2). For the September
chapter the code, eq. 18 and the NBER README agree on (r − g); only the one sentence writes r.

## 4. NBER ceiling: hard-coded 72 vs. 72.05/72.06 derivable from `final.csv`

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:19`: `wt_max <- 72` (a literal).
**NBER README** assumptions table: "$72.06B" (text).
**NBER chapter**, PDF p.22 (eq. 4): the same 72.06 in the semi-elasticity formula.
**Our recomputation** from `final.csv` (`R/nber_final.R:compute_nber_ceiling()`,
`py/nber_final.py:compute_nber_ceiling()`): domestic total at 7% growth
(`sum(face_tax_5pct[panel=="domestic"])` = $100.9056B) minus the 7 `removed_departed` rows
($28.8541B) = **$72.0515B**.

Three different numbers for the same quantity: the script's literal (72), the README's prose
(72.06), and the value the underlying person-level data actually sums to (72.05). The 72.06 is the
difference of the two figures as rounded to two decimals (100.91 − 28.85); the person-level sum is
72.0515. We rebuild the
ceiling from `final.csv` by design rather than trusting either the script's literal or the
README's rounding, and flag that the shipped NPV_dist_v8.R does not itself perform this rebuild -
it uses the hard-coded 72.

## 5. `q = 0.50` litigation-survival weight has no explicit multiplier in the code

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

## 6. Baseline revenue: the workbook's precise 94.30 vs. the printed 94.20

**Workbook**, `CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!C5`
(`=SUM(Calculations_Preferred!O3:O214)/$M$2`) = **94.30426206**.
**First-version paper**, p.10 (Sec 4.1): "the wealth tax would generate **$94.20** billion in revenue."
**NBER chapter**, PDF pp.18-19 (Sec 4.1, eq. 2): the same **$94.20B**. Its own person-level file
at the grown vintage, `final.csv`, sums to $100.906B, which is exactly 1.07 x 94.304: the
chapter's data also give 94.30.
**Workbook**, `Summary_Preferred!C8` = **94.2** (typed literal, feeds `F8`'s literature-calibrated
formula, p.14 eq.13) and `NPV_calculations_5.2.xlsx!B5` = **94.2** (typed literal, feeds every
Table 9/10 scenario's `f = 1 - WT/baseline`, p.19-20).

The first version's prose rounds 94.30 to 94.20 in one place (p.10) and then every *downstream*
calculation (literature calibration, Table 9, Table 10) is built from the rounded 94.2 literal,
not from the workbook's own more precise C5. `R/revenue_chain.R:compute_revenue_chain()` reports
both `baseline_precise` (94.30, from the per-row sum) and `baseline_literal` (94.2, the value
actually used downstream) so the discrepancy is visible rather than silently propagated.

## 7. First version: `Summary_Expanded!D23:D24` reads from the wrong sheet (stale copy-paste)

**Workbook**, `Summary_Expanded!D23`:
`=SUMIF(Calculations_Preferred!F3:F214,"N",Calculations_Preferred!D3:D214)` - and `D24` the same
pattern with column `L`. Both reference **`Calculations_Preferred`** (the 6-departure scenario)
even though every other formula on this sheet (including the revenue figure that actually matters,
`F5`) correctly references `Calculations_Expanded` (the 10-departure scenario). This looks like a
copy-paste artifact from building `Summary_Expanded` off a copy of `Summary_Preferred`. It does
not affect any number this pipeline reproduces (`F5` = $55.10B is correctly sourced), only the
"Stayers" net-worth memo cells (`C22:D25`), which we do not use.

## 8. First version: the Table 9 central scenario (WT=$42.0B) has no derivation

**Workbook**, `NPV_calculations_5.2.xlsx!B12`: `42` (typed literal, no formula).
**First-version paper**, p.19: "The Central Scenario uses a revenue estimate of $42.0 billion and a midpoint
income tax estimate (C = $4.55 billion)."

Every other WT figure in that version traces to a computation (94.20 -> 67.51 -> 55.10 baseline
chain, or 45.59 via the literature semi-elasticity). $42.0B does not: it is not the average of any
two chain values (e.g. (67.51+35)/2 = 51.3, not 42), not the preferred-estimate midpoint stated on
p.14 ((35+46)/2 = 40.5, close but not equal), and not linked to any semi-elasticity via the eq.
12-13 formula used elsewhere. We treat it as a freestanding scenario input (labelled `scenario` in
`export/{r,py}/inputs.csv`, not `data` or `research`) and do not attempt to re-derive it.

## 9. First version: the printed Monte Carlo summary (mean -$24.7B, sd $38.4B) does not exactly reproduce

Running the authors' own unmodified `NPV_data/NPV_dist.R` from a scratch copy (seed 2026,
n=100,000, `wt_max <- 67.51` as shipped) gives **mean -$24.8B, median -$19.1B, sd $38.6B, 71.0%
negative** on this machine/R version - matching our R port to 1e-9 (`tests/testthat/test-npv-mc.R`)
but off by ~$0.1-0.2B from the paper's printed mean/sd (median and %negative match exactly). We
checked whether the eq. 22 typo (mismatch #1, 67.1 vs 67.51) explains the gap by re-running with
`wt_max <- 67.1`: it does not - that moves the mean *further* from the printed value (to -$25.3B).
The gap is within Monte Carlo error for one run (our tolerance: `4 * sd / sqrt(n)` =~ $0.5B).
A fixed seed gives the same draw on every run, so repeated runs cannot show whether the gap is
systematic. What does explain the printed mean: the draws are independent uniforms, so the
expectation has a closed form, E[WT] - (1 - E[WT]/94.2) x E[C] x E[1/r], with
E[1/r] = ln(0.045/0.015)/0.03. That gives **-$24.707B**, which rounds to the printed -$24.7B
(re-verified by the main session, 2026-09-23). So the printed mean matches the model's exact
expectation, while the shipped seed-2026 run gives -$24.77B. The printed sd ($38.4B vs $38.6B)
remains unexplained; a different run or code state is the likeliest source. The NBER
version's printed summary (mean -$38.9B, median -$35.3B, 85.2% negative), by contrast, reproduces
from `NPV_dist_v8.R` to within Monte Carlo noise with no directional gap.

## 10. The top 212's share of bracket tax is printed as 39.0% and as 38.8% for one formula

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
