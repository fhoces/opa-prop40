# comparison

The reconciliation layer: puts the supporting side (GGSS July 2026, BSZ August 2026) and the
opposing side (Rauh et al. SSRN March 2026, Jaros and Rauh NBER September 2026) on one common
output and one input-by-input bridge. It renders the site-root page, `../index.html`.

## What it reads (and nothing else)

- `../supporting-analysis/export/r/{inputs,outputs}.csv` and
  `../opposing-analysis/export/r/{inputs,outputs}.csv`: each side's export contract.
- `data/document-inputs.csv`: values neither contract carries, transcribed from the PDFs with
  their page (Rauh's Monte Carlo ranges, the NBER departure range, GGSS's non-citizen wealth,
  BSZ's 5-year horizon, Walczak, LAO, Hoopes's text figures).
- `data/hoopes-fig2.csv`: Hoopes (2026) Figure 2, read off the chart by
  `tools/digitize_hoopes_fig2.py` (the note prints no values).

## Common output

(a) gross one-time wealth tax revenue; (b) net fiscal effect = (a) + extra income tax from
assets sold to pay - present value of income tax lost to departures, over a horizon H (a dial).

## Code

| File | What |
|---|---|
| `R/contract.R` | read the contracts and document inputs |
| `R/model.R` | `score_common()`, the one scoring function; exact Shapley over all orders; one sequential order; Rauh's analytic Monte Carlo expectations |
| `R/build.R` | every number the page shows, written to `export/r/*.csv` |
| `R/site.R` | renders `../index.html` and `../assets/comparison-data.js` from `site/index.template.html` |
| `py/bridge.py` | Python twin of contract/model/build, writes `export/py/*.csv` |
| `run.R` | builds all three: `Rscript comparison/run.R` |

## Tests

`Rscript comparison/tests/testthat.R`: endpoints against the printed numbers (GGSS $100B and
$104B, BSZ Table 5 row 1, Rauh -24.7 and NBER -38.9), Shapley steps summing exactly to the
gap in every setting, Shapley against a brute-force average over orders, R vs Python parity to
1e-9, provenance of every transcribed input, and the page being exactly the generator's output
with every internal link resolving.

## Settled items (2026-09-23, see PLAN.md)

- Rauh's output (a) is the Monte Carlo's expected revenue (51.26 SSRN, 36 NBER), the only choice
  consistent with the -24.7 headline. The literature-calibrated 45.59, Table 9's 42 and the
  abstract's "about $40 billion" are exported as alternatives (`export/r/anchors.csv`).
- The Monte Carlo ranges (WT floor 35, C in [3.3, 5.8], r in [1.5%, 4.5%], NBER f in
  [0.30, 0.60]) are read from the opposing contract (`rauh_mc_*`, `nber_mc_*` rows).
