# Disputed inputs: Rauh et al. vs the supporting side

Crosswalk of the inputs on which the two sides disagree. This is the starting list for the
reconciliation page's bridge (one bridge step per row). Every page reference was checked against
text extracted from the PDF (PyMuPDF, per-page markers). Page numbers are **PDF pages**, not printed
folios. For Rauh and GGSS the two coincide. BSZ's folio runs two behind in the main text (PDF p.26 is
folio 24) and restarts in the appendices (PDF p.54 is folio 17).

## Documents and versions

| Short name | Document | Date | Where |
|---|---|---|---|
| Rauh | Rauh, Jaros, Kearney, Doran, Cosso, "The Net Present Value of the Billionaire Tax Act", Hoover expert report, SSRN 6340778 | 17 Mar 2026 | `opposing-analysis/original-materials/ssrn-6340778.pdf` |
| Resp | Galle, Gamage, Saez, Shanske, "Response to ... March 4, 2026" | 17 Mar 2026 | `supporting-analysis/original-materials/additional-documentation/responsetorauh26.pdf` |
| GGSS | Galle, Gamage, Saez, Shanske, "Expert Report on Proposition 40" | updated 20 Jul 2026 | `.../additional-documentation/galle-gamage-saez-shanskeCAbillionairetaxJuly26.pdf` |
| BSZ | Boll, Saez, Zucman, NBER WP 35218 | Aug 2026 revision | `supporting-analysis/original-materials/BSZ26CAbillionaires.pdf` |

**Vintage caveat.** Resp answers the **March 4** Rauh version; our Rauh PDF is dated **March 17**.
Resp's characterizations are therefore claims to check against our copy, not facts about it. The
one checked in detail is Resp's "78%" (row 5): the string does not appear in the March 17 text,
but the number follows from it (4.55 / 5.8 = 78.4%, which is how BSZ Aug p.11 fn.13 states it).
Rauh has not updated since March 17 (as of 2026-09-23); the supporting side has moved twice (GGSS
July, BSZ August). So two disputes that were open in March are settled on the supporting side by
August (rows 7 and 8).

## Kind labels

- **scenario**: a choice of which policy or world is being scored; neither data nor literature settles it.
- **data**: settled by observable facts (lists, filings, tax statistics).
- **research**: a parameter taken from published empirical work.
- **guesswork**: an assumption the authors assert without data or a study behind it (including legal judgments about unresolved questions).

## The table

| # | Dispute | Rauh value (page) | Supporting value (page) | Kind | Verified |
|---|---|---|---|---|---|
| 1 | **Which policy is scored for the behavioral response.** One-time 5% vs a recurring 5%/yr | Semi-elasticity applied to a 5.00 pp rate change, so a one-time 5% is treated like a 5 pp permanent rate: p.11 eq.7-8, p.13 eq.10, p.14 eq.13. Rauh concedes the literature comes from recurring annual taxes but argues a one-time tax with interstate mobility "may plausibly generate a larger short-run response" (p.14). Defends the framing in §6, "Is This Truly a One-Time Tax?" (p.21): a constitutional amendment with no sunset | One-time 5%, payable 1%/yr over 5 years plus a deferral charge (Resp p.1, GGSS p.1). Responses should be temporary under rational expectations (Resp pp.1-3; BSZ p.22 and fn.29, "the main flaw in the scoring analysis of Rauh et al."). BSZ scores a permanent tax only as a separate exercise (p.27, §IV.B) | scenario + guesswork (expected future taxes) | Y |
| 2 | **Horizon asymmetry.** Income tax lost for ever vs wealth tax collected once | NPV = WT − f·C/(r−g) (p.18 eq.18-20). (r−g) ∈ {1.5, 3.0, 4.5}% (p.19), anchored at 1.5% from the S&P dividend yield (p.18) and corroborated by an implied yield of 1.3-2.3% (p.18). Table 9 (p.19). At 1.5%, 1/0.015 = 67 | Losses are "annual temporary" (BSZ Table 5 header, p.39) and should last about the 5 payment years (BSZ p.27). Resp p.3: "magnified by a factor 67" (1/0.015). BSZ p.22 fn.29: "a factor 33 (using their central discount rate 3.0%)". Both are right about different parts of Rauh: 1.5% is the text's anchor, 3.0% is the Monte Carlo's mean r | scenario (duration) + research (discount rate) | Y |
| 3 | **Tax base already departed.** Who counts as having left before 1 Jan 2026 | 6 confirmed pre-snapshot departures, $536.4B, 28.3% of the base: p.6 Table 3, p.11 Table 6 (Page, Brin, Thiel, Hankey, Spielberg, Sacks). WT falls $94.20B → $67.51B (p.11). Expanded 10 departures including Zuckerberg (post-snapshot), $785.4B, 41.4%, WT $55.10B (p.12 Table 7). Central WT $42.0B, range $35-46B (p.14, p.19). Argues the 1 Jan date is constitutionally vulnerable (pp.12-13) | Benchmark taxes all 1 Jan 2026 residents (BSZ p.23). The aggressive row assumes Page, Thiel, Hankey and Kalanick left: WT $104B → $89B (BSZ p.26, Table 5 row 3, p.39). Zuckerberg and Brin "very likely" still residents (BSZ p.26). Paper moves are not legal residence changes (Resp pp.3-4; GGSS p.5, "very unlikely in most cases") | guesswork (legal judgment on residency), resting on data (who announced what) | Y |
| 4 | **Size of the mobility semi-elasticity** | ε_lit = 0.24 × 43 = 10.32 from Brülhart et al. 2022 (p.13-14 eq.12). Preferred 12-13, "plausible and conservative" (p.14). Implied by observed departures: 5.67 (p.11 eq.8) and 8.30 (p.13 eq.11) | BSZ uses e = 10, "same semi-elasticity calibration as in Rauh et al." (p.28, p.48), but only for a **permanent** tax, where the revenue-maximizing rate is 1/e ≈ 10% (BSZ p.28; Resp p.3 fn.1). So the sides agree on e ≈ 10 for a permanent tax. The live dispute is Rauh's 12-13 and applying e to a one-time tax (row 1) | research (10.32) + guesswork (12-13 uplift) | Y |
| 5 | **Billionaires' annual CA income tax** | C = $3.3 / 4.55 / 5.8B (p.15-17; Table 8 p.17; Table 9 p.19). 5.76 is the Pareto upper bound, assuming billionaires are the top 212 earners (p.15). 3.3 is the K≈500 dispersion draw (p.16-17). 4.55 is their midpoint, = 0.24% of $1,894.8B | About $3B/yr average over 2019-2025, 0.2% of wealth in 2023-25, 0.26% average 2019-25 (BSZ p.11). Top wealth holders' income is 50% of top earners' (Balkir et al. 2025; SCF), BSZ p.11 and p.55. BSZ p.11 fn.13 puts Rauh's central at 78.4% of top earners' income (= 4.55/5.8) | research (supporting: Balkir 50%) vs guesswork (Rauh: midpoint of two model bounds) | Y (78% derived, not quoted; see caveat) |
| 6 | **Is the income tax lost proportional to the wealth lost?** | f = 1 − WT/94.20 is used as the lost share of the **income tax** base (p.19; Monte Carlo p.20), so income tax lost scales with wealth departed. Page + Brin + Zuckerberg are ~90% of departed wealth (Tables 6-7) | The top 4 (Page, Brin, Zuckerberg, Huang) pay $0.27B/yr on company wealth, 2019-25, = 0.07% of wealth (BSZ Table 4, p.38; GGSS p.9). Resp p.5: Page + Brin + Zuckerberg paid $269M in 2025, 0.04% of wealth; $222M/yr average 2019-25. With leavers valued from SEC data, BSZ's aggressive scenario loses $0.51B/yr (p.26) | data (SEC filings) vs guesswork (proportionality) | Partial: $0.27B and 0.07% verified in BSZ Aug; Resp's $269M / $222M figures for the top 3 are not restated in the Aug text; check against the workbook `top4taxes` sheet |
| 7 | **Base definition** | 212 billionaires, $1,894.8B, 2025 Forbes list (p.4-5, Table 2). Removes Ellison, Houston, Snyder; adds Sacks (p.4-5). Deducts directly held residential real estate, $8.19B among stayers (p.8, Table 5). Real-estate-free baseline WT $94.20B (p.5, p.10) | **Ellison now excluded by BSZ too** (p.5 fn.3; p.54; p.54 fn.40, "Rauh et al. 2026 also choose to exclude Larry Ellison"). GGSS removed him relative to the Feb 16 version (GGSS p.2 fn.1). BSZ: 240 billionaires, $2,055B at 1 Jan 2026, adding Amodei, Kardashian, Powell Jobs, Winfrey (+$22.8B) (p.54); 250 and $2,307B at 1 Jul 2026 (p.24, Table 5 p.39). Scoring = 90% × 5% × $2,307B = $104B (p.24), with no separate real-estate deduction | data (list membership, valuation date) | Y. The March dispute over Ellison is closed in the strongest version; what remains is Houston, Snyder, Sacks, the 4 added names, non-citizens (row 8), valuation date, and the real-estate deduction |
| 8 | **The 24-25 non-US-citizen residents** | Omitted: Rauh starts from Forbes' CA-residence field (p.4), which Resp p.6 fn.5 says covers residence only for US and Chinese residents | Resp p.6: both sides omitted 24 people, $110B, "an omission we will correct in our next iteration". **Corrected by August:** BSZ includes 25 non-US citizens, $132B at 1 Jan 2026 (p.54; "We include both US and non-US citizens", p.5). GGSS July: 24 people, about $150B (p.2 fn.1) | data | Y. Conceded fix applied on the supporting side; Rauh still omits them |

## Rauh's headline: where −$24.7B comes from (open item, resolved)

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

So eq.22's "67.1" is a typo for 67.51. The headline is an average over the Monte Carlo's draws of
WT and C, not a preferred scenario, and its preferred-WT point (≈$40-42B) sits inside that range.
For the bridge, the Rauh anchor to use is the Monte Carlo mean (−$24.7B). Table 9's central cell
(−$126.1B) is a separate, more pessimistic reading.

## Not yet in the table

- The pro side's headline counts wealth tax revenue only (GGSS $100B; BSZ $104B benchmark), while
  Rauh's is an NPV net of lost income tax. The reconciliation page first puts both on a common
  output definition (see PLAN.md, "Pre-specified output").
- Control-weighted valuation (Rauh §2.5 and App. A; GGSS p.8): both sides score economic ownership,
  so it is not a live input, only a motive for pre-snapshot departures (row 3).
- Extra CA income tax from asset sales to pay the tax: +$3.7B in BSZ's benchmark (Table 5, p.39),
  absent from Rauh.
- Missing small billionaires: BSZ Pareto row, $128B (Table 5 row 2), absent from Rauh.
- Third-party sources: Hoopes (SSRN 6428578), Walczak / CalTax (2026-04-22), LAO; see the
  manifests. These enter as credited alternative dials, not as rows here.
