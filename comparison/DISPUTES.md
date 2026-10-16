# Disputed inputs: the JR analysis vs the BSZ analysis

**Updated 2026-10-15.** The bridge and the explorer use the September 2026 version of the JR
analysis (Jaros and Rauh, NBER chapter c15504) since 2026-10-14. The table below gives that
version's value first and the March 2026 version's (Rauh et al., SSRN 6340778) after it, where
the two differ. The section on the −$24.7B headline is kept as the record of the March version.

Crosswalk of the inputs on which the two analyses disagree. This is the starting list for the
comparison overview's bridge (one bridge step per row). Every page reference was checked against
text extracted from the PDF (PyMuPDF, per-page markers). Page numbers are **PDF pages**, not printed
folios. For Rauh and GGSS the two coincide. The JR chapter's folio runs one behind (PDF p.21 is
folio 20). BSZ's folio runs two behind in the main text (PDF p.26 is folio 24) and restarts in the
appendices (PDF p.54 is folio 17).

## Documents and versions

| Short name | Document | Date | Where |
|---|---|---|---|
| JR | Jaros and Rauh, "The Net Present Value of the California Billionaire Tax Act", NBER chapter c15504, Tax Policy and the Economy vol. 41 | 22 Sep 2026 | `rjkdc-analysis/original-materials/jaros-rauh-nber-c15504-2026-09.pdf` |
| Rauh | Rauh, Jaros, Kearney, Doran, Cosso, "The Net Present Value of the Billionaire Tax Act", Hoover expert report, SSRN 6340778 (the JR analysis's first version) | 17 Mar 2026 | `rjkdc-analysis/original-materials/ssrn-6340778.pdf` |
| Resp | Galle, Gamage, Saez, Shanske, "Response to ... March 4, 2026" | 17 Mar 2026 | `bsz-analysis/original-materials/additional-documentation/responsetorauh26.pdf` |
| GGSS | Galle, Gamage, Saez, Shanske, "Expert Report on Proposition 40" | updated 20 Jul 2026 | `.../additional-documentation/galle-gamage-saez-shanskeCAbillionairetaxJuly26.pdf` |
| BSZ | Boll, Saez, Zucman, NBER WP 35218 | Aug 2026 revision | `bsz-analysis/original-materials/BSZ26CAbillionaires.pdf` |

**Vintage caveat.** Resp answers the **March 4** Rauh version; our Rauh PDF is dated **March 17**.
Resp's characterizations are therefore claims to check against our copy, not facts about it. The
one checked in detail is Resp's "78%" (row 5): the string does not appear in the March 17 text,
but the number follows from it (4.55 / 5.8 = 78.4%, which is how BSZ Aug p.11 fn.13 states it).
The table's JR column gives the September 2026 chapter (JR) first, because the bridge and the
explorer use its values, and the March 17 version (Rauh) after it where they differ. Rows 1 and
4 are disputes with the March version only. The BSZ analysis moved twice (GGSS July, BSZ
August), so two disputes that were open in March are settled on the BSZ analysis by August
(rows 7 and 8).

## Kind labels

- **scenario**: a choice of which policy or world is being estimated; neither data nor literature settles it.
- **data**: settled by observable facts (lists, filings, tax statistics).
- **research**: a parameter taken from published empirical work.
- **guesswork**: an assumption the authors assert without data or a study behind it (including legal judgments about unresolved questions).
- **derived**: a value computed from the analysis's own inputs, not a separate assumption (row 10: the one rate worth the same as the JR draw of r − g).
- **compound kinds**: "A vs B" reads the BSZ value's kind against the JR value's; "A + B" means one value rests on both; "guesswork on data" means a judgment applied to observed facts.

## The table

| # | Dispute | JR value: September 2026 (JR), then March 2026 (Rauh) (page) | BSZ value (page) | Kind | Verified |
|---|---|---|---|---|---|
| 1 | **Which policy the behavioral response is estimated for** (March 2026 version only; not a bridge step). One-time 5% vs a recurring 5%/yr | **Rauh:** semi-elasticity applied to a 5.00 pp rate change, so a one-time 5% is treated like a 5 pp permanent rate: p.11 eq.7-8, p.13 eq.10, p.14 eq.13. Rauh concedes the literature comes from recurring annual taxes but argues a one-time tax with interstate mobility "may plausibly generate a larger short-run response" (p.14). Defends the framing in §6, "Is This Truly a One-Time Tax?" (p.21): a constitutional amendment with no sunset. **JR:** predicts no departures from an elasticity; it keeps the one-time question for the horizon (row 2, Sec. 6, PDF p.36 on) | One-time 5%, payable 1%/yr over 5 years plus a deferral charge (Resp p.1, GGSS p.1). Responses should be temporary under rational expectations (Resp pp.1-3; BSZ p.22 and fn.29, "the main flaw in the scoring analysis of Rauh et al."). BSZ estimates a permanent tax only as a separate exercise (p.27, §IV.B) | scenario + guesswork (expected future taxes) | Y |
| 2 | **Horizon asymmetry.** Income tax lost for ever vs wealth tax collected once | **JR:** NPV = WT − f·C/(r − g), a growing perpetuity (Sec. 5.2, eqs. 13-14, PDF pp.30-31). r − g, the real discount rate net of the growth of the lost tax, is calibrated to the S&P 500 dividend yield, "(r − g) ≈ 0.015" (PDF p.32), and drawn as (r − g) ~ U[0.015, 0.045] (eq. 18, PDF p.35; `NPV_dist_v8.R:28`, `rg_discount`). Departed billionaires are assumed not to return, because "the constitutional cap on intangible property taxation has been permanently removed", §50310 lets a two-thirds vote of the Legislature change any part of the Act, and the spending it funds is open-ended (PDF p.32; Sec. 6, "Is This Truly a One-Time Tax?", PDF p.36 on). One sentence after eq. 19 writes C/r (JR mismatch 3). **Rauh:** NPV = WT − f·C/(r−g) (p.18 eq.19-20; eq.18 is the plain-r form; the Monte Carlo headline uses eq.18's plain r). (r−g) ∈ {1.5, 3.0, 4.5}% (p.19), anchored at 1.5% from the S&P dividend yield (p.18) and corroborated by an implied yield of 1.3-2.3% (p.18). Table 9 (p.19). At 1.5%, 1/0.015 = 67 | Losses are "annual temporary" (BSZ Table 5 header, p.39). BSZ argue the losses should be temporary and give five years, the payment period, as an example ("If they last say only 5 years", p.27); Table 5 itself "does not take a stand on how long the annual income tax losses will last" (p.27). The comparison's five years are this OPA's reading of that example. Resp p.3: "magnified by a factor 67" (1/0.015). BSZ p.22 fn.29: "a factor 33 (using their central discount rate 3.0%)". Both are right about different parts of the March version: 1.5% is the text's anchor, 3.0% is the Monte Carlo's mean rate | scenario (duration). The discount rate is row 10 | Y (September values checked 2026-10-15) |
| 3 | **Tax base already departed.** Who counts as having left before 1 Jan 2026 | **JR:** seven publicly confirmed pre-snapshot departures (Page, Brin, Thiel, Hankey, Spielberg, Kalanick, Sacks), $539.9B of the $1,894.8B 2025 base, $577.7B grown 7% to 31 Dec 2026, 28.5% of the domestic base (Table 7, PDF p.21). Revenue falls from $100.9B to $72.06B, a semi-elasticity of 28.6% / 5.00 = 5.73 (eq. 4, PDF p.22); the script's ceiling is the literal 72 (JR mismatch 4). For the point estimate only, three pre-filing departures remove $0.88B more and Zuckerberg is left out of the recognized base (eq. 5, PDF p.22). **Rauh:** 6 confirmed pre-snapshot departures, $536.4B, 28.3% of the base: p.6 Table 3, p.11 Table 6 (Page, Brin, Thiel, Hankey, Spielberg, Sacks). WT falls $94.20B → $67.51B (p.11). Expanded 10 departures including Zuckerberg (post-snapshot), $785.4B, 41.4%, WT $55.10B (p.12 Table 7). Central WT $42.0B, range $35-46B (p.14, p.19). Argues the 1 Jan date is constitutionally vulnerable (pp.12-13) | Benchmark taxes all 1 Jan 2026 residents (BSZ p.23). No named leaver is removed: the press reports "do not include sufficient information to establish that they successfully changed residence before the January 1st, 2026 cut-off" (p.23 fn.30). The benchmark's 10% avoidance already counts 5% of billionaires who left in time (p.24). The aggressive row assumes Page, Thiel, Hankey and Kalanick left: WT $104B → $89B (BSZ p.26, Table 5 row 3, p.39). Zuckerberg and Brin "very likely" still residents (BSZ p.26). Paper moves are not legal residence changes (Resp pp.3-4; GGSS p.5, "very unlikely in most cases") | guesswork (legal judgment on residency), resting on data (who announced what) | Y (September values checked 2026-10-15) |
| 4 | **Size of the mobility semi-elasticity** (March 2026 version only; not a bridge step) | **Rauh:** ε_lit = 0.24 × 43 = 10.32 from Brülhart et al. 2022 (p.13-14 eq.12). Preferred 12-13, "plausible and conservative" (p.14). Implied by observed departures: 5.67 (p.11 eq.8) and 8.30 (p.13 eq.11). **JR:** uses 10.32 only to validate its observed 5.73 (Sec. 4.5, PDF p.24); the headline predicts no departures from an elasticity | BSZ uses e = 10, "same semi-elasticity calibration as in Rauh et al." (p.28, p.48), but only for a **permanent** tax, where the revenue-maximizing rate is 1/e ≈ 10% (BSZ p.28; Resp p.3 fn.1). So the analyses agree on e ≈ 10 for a permanent tax. The live dispute in March was Rauh's 12-13 and applying e to a one-time tax (row 1) | research (10.32) + guesswork (12-13 uplift) | Y |
| 5 | **Billionaires' annual CA income tax** | **JR:** unchanged from March: C ~ U[$3.3B, $5.8B] (Sec. 5.1, PDF pp.26-30; Table 9, PDF p.30; eq. 17, PDF p.35). The $3.3B floor is the K = 500 dispersion draw, "a reasonable lower bound" (PDF p.28). **Rauh:** C = $3.3 / 4.55 / 5.8B (p.15-17; Table 8 p.17; Table 9 p.19). 5.76 is the Pareto upper bound, assuming billionaires are the top 212 earners (p.15). 3.3 is the K≈500 dispersion draw (p.16-17). 4.55 is their midpoint, = 0.24% of $1,894.8B | About $3B/yr average over 2019-2025, 0.2% of wealth in 2023-25, 0.26% average 2019-25 (BSZ p.11). Top wealth holders' income is 50% of top earners' (Balkir et al. 2025; SCF), BSZ p.11 and p.55. BSZ p.11 fn.13 puts Rauh's central at 78.4% of top earners' income (= 4.55/5.8) | research (BSZ: Balkir 50%) vs guesswork (JR: midpoint of two model bounds) | Y (78% derived, not quoted; see caveat) |
| 6 | **Is the income tax lost proportional to the wealth lost?** | **JR:** no. The share lost is drawn as f ~ U[0.30, 0.60] independently of the revenue, "centered conservatively around the observed wealth-base departure fraction", because "the fraction of the wealth tax base that departs is not the same object as the fraction of income tax payments lost" (PDF p.31; eq. 19, PDF p.35). **Rauh:** f = 1 − WT/94.20 is used as the lost share of the **income tax** base (p.19; Monte Carlo p.20), so income tax lost scales with wealth departed. Page + Brin + Zuckerberg are ~90% of departed wealth (Tables 6-7) | The top 4 (Page, Brin, Zuckerberg, Huang) pay $0.27B/yr on company wealth, 2019-25, = 0.07% of wealth (BSZ Table 4, p.38; GGSS p.9). Resp p.5: Page + Brin + Zuckerberg paid $269M in 2025, 0.04% of wealth; $222M/yr average 2019-25. With leavers valued from SEC data, BSZ's aggressive scenario loses $0.51B/yr (p.26). At the benchmark no named leaver is removed, and the lost income tax is the 5% of billionaires who move under the avoidance allowance, assumed to pay income tax in proportion to their wealth (p.24): a proportionality assumption too | guesswork (BSZ: the movers pay in proportion to their wealth; JR: a flat share drawn by judgement). The named leavers' own tax under the BSZ rule rests on data (SEC filings) | Partial: $0.27B and 0.07% verified in BSZ Aug; Resp's $269M / $222M figures for the top 3 are not restated in the Aug text; check against the workbook `top4taxes` sheet. September values checked 2026-10-15 |
| 7 | **Base definition** | **JR:** the same 212-person 2025 Forbes list, grown 7% to the 31 Dec 2026 valuation date: $94.2B of face-value revenue becomes about $100.9B (Sec. 3.2, PDF pp.12-13). Directly held residential real estate deducted, $8.19B among stayers (Table 6, PDF p.17). **Rauh:** 212 billionaires, $1,894.8B, 2025 Forbes list (p.4-5, Table 2). Removes Ellison, Houston, Snyder; adds Sacks (p.4-5). Deducts directly held residential real estate, $8.19B among stayers (p.8, Table 5). Real-estate-free baseline WT $94.20B (p.5, p.10) | **Ellison now excluded by BSZ too** (p.5 fn.3; p.54; p.54 fn.40, "Rauh et al. 2026 also choose to exclude Larry Ellison"). GGSS removed him relative to the Feb 16 version (GGSS p.2 fn.1). BSZ: 240 billionaires, $2,055B at 1 Jan 2026, adding Amodei, Kardashian, Powell Jobs, Winfrey (+$22.8B) (p.54); 250 and $2,307B at 1 Jul 2026 (p.24, Table 5 p.39). Estimate = 90% × 5% × $2,307B = $104B (p.24), with no separate real-estate deduction | data (list membership, valuation date) | Y. The March dispute over Ellison is closed in the strongest version; what remains is Houston, Snyder, Sacks, the 4 added names, non-citizens (row 8), valuation date, and the real-estate deduction |
| 8 | **The 24-28 non-US-citizen residents** | **JR:** excluded as too uncertain to collect. The 28 international billionaires, $146.3B, "could be included in the base", but collecting from them needs the Act to survive, federal treaty obligations not to preempt it, and the Act's worldwide apportionment to hold, which §50306(b)(6) lets a court reduce "potentially to zero"; "therefore we exclude from the base entirely" (Sec. 3.5, PDF pp.17-18). **Rauh:** omitted: Rauh starts from Forbes' CA-residence field (p.4), which Resp p.6 fn.5 says covers residence only for US and Chinese residents | Resp p.6: both analyses omitted 24 people, $110B, "an omission we will correct in our next iteration". **Corrected by August:** BSZ includes 25 non-US citizens, $132B at 1 Jan 2026 (p.54; "We include both US and non-US citizens", p.5). GGSS July: 24 people, about $150B (p.2 fn.1) | data vs guesswork (JR: a legal judgement on collectibility) | Y. Conceded fix applied on the BSZ analysis. The September version names the 28 and gives its reason (checked 2026-10-15) |
| 9 | **Chance the Act survives litigation** (September 2026 version only) | **JR:** q = 0.50, the ASC 740-10 "more likely than not" threshold, applied to the recognized base (NBER README assumptions table; chapter Secs. 4.2 and 4.4, PDF pp.19-23, eqs. 3 and 6). The Monte Carlo draws WT ~ U[0, 72] (0 = Act struck down; 72 = ceiling), whose mean equals 0.5 x 72; the script has no separate q (`NPV_dist_v8.R:19`; JR mismatch 5) | The Act as written, collected in full: neither BSZ nor GGSS discounts the revenue for litigation risk (BSZ Table 5, PDF p.39; GGSS p.4). GGSS, under "Constitutionality Issues": "The billionaire tax was carefully designed to stay clear of constitutional issues" (GGSS p.11) | guesswork (legal judgment) | Y |
| 10 | **Discount rate for the lost income tax** (a bridge step since 2026-10-15) | **JR:** the Monte Carlo draws r − g, the real discount rate net of the growth of the lost tax, uniformly between 1.5% and 4.5%, and averages the present value (eq. 18, PDF p.35; `NPV_dist_v8.R:28`, `rg_discount`; the 1.5% anchor is the dividend yield, PDF p.32). A perpetuity averaged over that draw is worth E[1/(r − g)] = ln(3)/0.03 = 36.6, more than 1/0.03 = 33.3 at the middle rate, because 1/r is convex. So the draw is worth the same as one rate of 1 / E[1/(r − g)] = 0.03 / ln(3) = 2.73%, the comparison's JR value (computed from the JR contract's `rauh_mc_r_min` and `rauh_mc_r_max` in `comparison/R/build.R`). With it the common function returns the authors' exact mean, -$38.98B | No rate: the BSZ analysis counts 5 years of lost income tax without discounting a perpetuity (BSZ p.27, Table 5 p.39). This OPA uses 3% for that 5-year loss, the rate of the BSZ overview and the middle of the JR range (`comparison/data/document-inputs.csv`, `common_discount_rate`) | scenario (BSZ) vs derived from the authors' draw (JR) | Y |

## Rauh's headline: where −$24.7B comes from (the March 2026 version, kept as history)

The −$24.7B is **not** a Table 9 cell. Table 9's central column at (r−g) = 1.5% reads −$126.1B
(p.19). The headline is the **mean of the Monte Carlo** in §5.5 (p.20):
WT ~ U[$35B, $67.1B], C ~ U[$3.3B, $5.8B], r ~ U[0.015, 0.045], f = 1 − WT/94.20,
NPV = WT − f·C/r. Two things differ from Table 9: the discount term is **C/r, not C/(r−g)**, and
r is drawn over the whole 1.5-4.5% band (mean 3%).

Reproduced here with 10 million draws:

| WT upper bound | mean NPV | median | sd | share negative |
|---|---:|---:|---:|---:|
| 67.1 (as printed in eq.22) | −25.25 | −19.57 | 38.28 | 71.7% |
| **67.51** (the text's ceiling, p.11) | **−24.68** | **−19.04** | **38.41** | **71.0%** |
| Rauh reports (p.20) | −24.7 | −19.1 | 38.4 | 71% |

So eq.22's "67.1" is a typo for 67.51. The authors' own code confirms it: `NPV_data/NPV_dist.R:31` sets `wt_max <- 67.51` and line 60 divides by the plain discount rate r (`annual_loss / r_discount`), even though the replication README labels that draw "(r − g)" (repo github.com/bjaros20/wealth_tax at 25e84dd). The headline is an average over the Monte Carlo's draws of
WT and C, not a preferred scenario, and its preferred-WT point (≈$40-42B) sits inside that range.
Until 2026-10-14 the bridge was anchored on this mean (an anchor: the published number an end
of the bridge is checked against). Since then the bridge ends at the September 2026 version's
exact mean (−$38.98B), and the March mean is kept here as history. Table 9's central cell
(−$126.1B) is a separate, more pessimistic reading of the March version.

## The second JR estimate (NBER, Sept 2026)

Jaros and Rauh, NBER chapter c15504 (Tax Policy and the Economy, vol. 41), cover dated 22 Sept 2026: about $30B in revenue (range $28-36B),
mean NPV −$38.9B, 85% of draws negative (abstract, PDF p.1; restated p.3). The simulation reproduces
exactly from `NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R` (mean −38.9, median −35.3, 85.2%
negative). Compared with SSRN, it keeps the same 212-person base, grows it 7% to the 31 Dec 2026
valuation date, removes **7** confirmed departures (SSRN's 6 plus Travis Kalanick, $3.5B), applies a
litigation-survival probability q = 0.50, drops Zuckerberg from the central base, and draws the
departure fraction f ~ U[0.30, 0.60] independently of WT.

Since 2026-10-14 the bridge and the explorer use this version's values directly (author
decision: always the latest analysis). What that changes in the table above: row 9 is added
for the litigation weight; rows 1 and 4 (the one-time tax read as a permanent rate, and the size
of the elasticity) are disputes with the March version only, because the September headline
predicts no departures from an elasticity, so they are not bridge steps; row 6 becomes the
share of income tax lost (the BSZ leavers' own tax on the departed base against the JR flat
draw of 30% to 60%); row 3 counts seven departures at the grown vintage. The common function
returns this version's expectation exactly. Since 2026-10-15 the discount rate is its own step
(row 10): 3% at the BSZ end, and at the JR end the one rate worth the same as the authors' draw
of r − g between 1.5% and 4.5%, 2.73%. Moving it from 3% to 2.73% lowers the JR end by about
$6.7B, to the authors' exact mean, −$38.98B.

## Handled outside the table

- BSZ's headline counts wealth tax revenue only (GGSS $100B; BSZ $104B benchmark), while
  the JR analysis's is an NPV net of lost income tax. The comparison overview first puts both on
  a common output definition (see PLAN.md, "Pre-specified output").
- Control-weighted valuation (Rauh §2.5 and App. A; GGSS p.8): both analyses value economic ownership,
  so it is not a live input, only a motive for pre-snapshot departures (row 3).
- Extra CA income tax from asset sales to pay the tax: +$3.7B in BSZ's benchmark (Table 5, p.39),
  absent from the JR analysis. It is a bridge step with no row here, as is the BSZ 10%
  avoidance allowance.
- Missing small billionaires: BSZ Pareto row, $128B (Table 5 row 2). The JR chapter gives
  Pareto-imputed billionaires a collection probability of zero, because the tax authority
  cannot assess a liability it cannot attribute to a person; its Appendix F estimates about 111
  extra returns holding $134 billion (PDF p.21, fn.23).
- Third-party sources: Hoopes (SSRN 6428578), Walczak / CalTax (2026-04-22), LAO; see the
  manifests. They are transcribed in `comparison/data/document-inputs.csv` for reference; none
  is a dial or a row here.
