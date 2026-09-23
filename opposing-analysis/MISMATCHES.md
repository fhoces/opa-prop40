# Mismatches

One numbered item per code/paper or doc/code discrepancy found while reproducing Rauh, Jaros,
Kearney, Doran & Cosso (SSRN 6340778) and Jaros & Rauh (NBER, Sept 2026). Per the brief, we do not
"fix" the authors: we reproduce their code as run, record the discrepancy, and where it matters
expose the alternative reading as a parameter with both sides under test.

## 1. Eq. 22's printed WT upper bound (67.1) vs. the code's literal (67.51)

**Paper**, p.20, eq. 22: `WT ~ U[$35B, $67.1B]`.
**Code**, `NPV_data/NPV_dist.R:31`: `wt_max <- 67.51`.

`$67.51B` is the confirmed-6-departures revenue ceiling used everywhere else in the paper (p.11,
Table 9's "Only 6 Confirmed Departures" column); `$67.1B` appears nowhere else. We treat 67.51 as
the intended value (it is what the shipped, runnable code uses and what every other reference to
the ceiling states) and reproduce the code, not the typo.

## 2. NPV formula: growing perpetuity (eq. 18/20, `r-g`) vs. plain-`r` code (Sec 5.5)

**Paper**, p.18, eq. 18/20: `NPV = WT - f * C / (r - g)`, introduced with an explicit growth-rate
adjustment (Gordon Growth Model discussion, p.18-19).
**Paper**, p.20, eq. 24 and surrounding prose: switches notation to plain `r ~ U[0.015, 0.045]`
and states "NPV = WT - f * C / r" for the Sec 5.5 Monte Carlo.
**Code**, `NPV_data/NPV_dist.R:60`: `pv_lost <- annual_loss / r_discount` (plain `r`, no growth
term).

The paper's own prose is internally inconsistent (Sec 5.2 derives a growing-perpetuity formula,
Sec 5.5 silently drops the growth term); the code matches the *later* (Sec 5.5) plain-`r` reading.
`R/npv_mc.R:compute_npv_mc_ssrn()` reproduces the code (plain `r`).

## 3. NBER's `rg_discount` draw reuses the SSRN plain-`r` range for an `(r-g)` quantity

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:22,28`: draws
`rg_discount <- runif(n_sims, 0.015, 0.045)`, i.e. explicitly labelled `(r-g)`.
**NBER README** assumptions table lists the same `[1.5%, 4.5%]` range for `(r - g)` under the
litigation-weighted approach, and the *identical* range for plain `r` under the SSRN approach (see
mismatch #2). Numerically the two papers draw from the same interval for two different discount
concepts (one nets out growth, one doesn't); neither README nor either paper's text says why the
same calibration should apply to both.

## 4. NBER ceiling: hard-coded 72 vs. 72.05/72.06 derivable from `final.csv`

**Code**, `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R:19`: `wt_max <- 72` (a literal).
**NBER README** assumptions table: "$72.06B" (text).
**Our recomputation** from `final.csv` (`R/nber_final.R:compute_nber_ceiling()`,
`py/nber_final.py:compute_nber_ceiling()`): domestic total at 7% growth
(`sum(face_tax_5pct[panel=="domestic"])` = $100.9056B) minus the 7 `removed_departed` rows
($28.8541B) = **$72.0515B**.

Three different numbers for the same quantity: the script's literal (72), the README's prose
(72.06), and the value the underlying person-level data actually sums to (72.05). We rebuild the
ceiling from `final.csv` per the brief rather than trusting either the script's literal or the
README's rounding, and flag that the shipped NPV_dist_v8.R does not itself perform this rebuild -
it uses the hard-coded 72.

## 5. `q = 0.50` litigation-survival weight has no explicit multiplier in the code

**NBER README** assumptions table: "Litigation risk: Probability the Act survives constitutional
challenge, q = 0.50 (ASC 740-10 'more likely than not'), applied to the recognized base" - listed
as a defining feature of the litigation-weighted approach.
**Code**, `NPV_dist_v8.R:19`: `wt_min <- 0; wt_max <- 72`. No `q` variable and no `* 0.5` anywhere
in the file.

The only place a 0.5 could be hiding is that `E[U(0, 72)] = 36 = 0.5 * 72`, i.e. drawing `WT`
uniformly from 0 to the ceiling has the *same expected value* as multiplying the ceiling by 0.5.
But that is not what the README describes ("applied to the recognized base," i.e. a discrete
survive/strike-down weighting of a fixed recognized amount), and a uniform draw over the full
range is a materially different distributional assumption from a Bernoulli(q) weight on a point
estimate (the uniform draw also puts positive probability on values between 0 and 72 that a
true two-state litigation model would not produce). We reproduce the code as shipped
(`wt ~ U[0, 72]`) and flag that it does not implement the README's own stated mechanism.

## 6. Baseline revenue: workbook's precise 94.30 vs. the literal 94.2 used downstream

**Workbook**, `CA_Billionaires_Revenues_and_Migration_final.xlsx!Summary_Preferred!C5`
(`=SUM(Calculations_Preferred!O3:O214)/$M$2`) = **94.30426206**.
**Paper**, p.10 (Sec 4.1): "the wealth tax would generate **$94.20** billion in revenue."
**Workbook**, `Summary_Preferred!C8` = **94.2** (typed literal, feeds `F8`'s literature-calibrated
formula, p.14 eq.13) and `NPV_calculations_5.2.xlsx!B5` = **94.2** (typed literal, feeds every
Table 9/10 scenario's `f = 1 - WT/baseline`, p.19-20).

The paper's prose rounds 94.30 to 94.20 in one place (p.10) and then every *downstream*
calculation (literature calibration, Table 9, Table 10) is built from the rounded 94.2 literal,
not from the workbook's own more precise C5. `R/revenue_chain.R:compute_revenue_chain()` reports
both `baseline_precise` (94.30, from the per-row sum) and `baseline_literal` (94.2, the value
actually used downstream) so the discrepancy is visible rather than silently propagated.

## 7. `Summary_Expanded!D23:D24` reads from the wrong sheet (stale copy-paste)

**Workbook**, `Summary_Expanded!D23`:
`=SUMIF(Calculations_Preferred!F3:F214,"N",Calculations_Preferred!D3:D214)` - and `D24` the same
pattern with column `L`. Both reference **`Calculations_Preferred`** (the 6-departure scenario)
even though every other formula on this sheet (including the revenue figure that actually matters,
`F5`) correctly references `Calculations_Expanded` (the 10-departure scenario). This looks like a
copy-paste artifact from building `Summary_Expanded` off a copy of `Summary_Preferred`. It does
not affect any number this pipeline reproduces (`F5` = $55.10B is correctly sourced), only the
"Stayers" net-worth memo cells (`C22:D25`), which we do not use.

## 8. Table 9's Central Scenario (WT=$42.0B) has no derivation

**Workbook**, `NPV_calculations_5.2.xlsx!B12`: `42` (typed literal, no formula).
**Paper**, p.19: "The Central Scenario uses a revenue estimate of $42.0 billion and a midpoint
income tax estimate (C = $4.55 billion)."

Every other WT figure in the paper traces to a computation (94.20 -> 67.51 -> 55.10 baseline
chain, or 45.59 via the literature semi-elasticity). $42.0B does not: it is not the average of any
two chain values (e.g. (67.51+35)/2 = 51.3, not 42), not the preferred-estimate midpoint stated on
p.14 ((35+46)/2 = 40.5, close but not equal), and not linked to any semi-elasticity via the eq.
12-13 formula used elsewhere. We treat it as a freestanding scenario input (labelled `scenario` in
`export/{r,py}/inputs.csv`, not `data` or `research`) and do not attempt to re-derive it.

## 9. SSRN Sec 5.5 printed summary (mean -$24.7B, sd $38.4B) does not exactly reproduce

Running the authors' own unmodified `NPV_data/NPV_dist.R` from a scratch copy (seed 2026,
n=100,000, `wt_max <- 67.51` as shipped) gives **mean -$24.8B, median -$19.1B, sd $38.6B, 71.0%
negative** on this machine/R version - matching our R port to 1e-9 (`tests/testthat/test-npv-mc.R`)
but off by ~$0.1-0.2B from the paper's printed mean/sd (median and %negative match exactly). We
checked whether the eq. 22 typo (mismatch #1, 67.1 vs 67.51) explains the gap by re-running with
`wt_max <- 67.1`: it does not - that moves the mean *further* from the printed value (to -$25.3B).
The gap is well within Monte Carlo error for a single run (our tolerance: `4 * sd / sqrt(n)` =~
$0.5B) but is systematic in one direction across repeated runs on this machine, suggesting the
paper's printed summary was drafted from a slightly different run (different R/RNG version, or
before a late code edit) rather than regenerated from the exact script now in the repo. The NBER
version's printed summary (mean -$38.9B, median -$35.3B, 85.2% negative), by contrast, reproduces
from `NPV_dist_v8.R` to within Monte Carlo noise with no directional gap.
