# The comparison of California Proposition 40: Open Materials

This folder is the comparison layer of [opa-prop40](https://fhoces.github.io/opa-prop40/), an Open Policy Analysis of
California's 2026 Proposition 40 (the Billionaire Tax Act). The [comparison overview](https://fhoces.github.io/opa-prop40/)
is the repository's front page, and this folder builds it. It puts the
[BSZ side](https://fhoces.github.io/opa-prop40/bsz-analysis/site/) and the
[RJKDC side](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/) on one common output and explains the gap
between their numbers one disputed input at a time. The aim is a transparent account of why the two
estimates differ, which anyone can check.

### [Review the code behind the $67.8 billion main estimate](https://claude.ai/artifact/6VZEezoAsCNACjmgPLEvah)

A layer-by-layer walk from the number on the overview page down to the two sides' export
contracts. Each layer is marked reviewed, lightly reviewed or not reviewed. Work in progress; the
record is also kept in [`review/`](../review/README.md).

<img align="right" width="340" src="site/assets/opa/opa-materials-wordmark.png" alt="Open Policy Analysis, Materials layer">

1 - **Open Output.** [The bridge](https://fhoces.github.io/opa-prop40/#the-bridge), an interactive waterfall on the
overview page from BSZ Table 5 row 1 to the NBER expected revenue, with switches for the output,
the step sizes and the loss horizon. Materials can be found in
[`site/index.template.html`](site/index.template.html) and [`R/site.R`](R/site.R).

2 - **Open Analysis.** An open policy report in the form of a
[dynamic document](https://fhoces.github.io/opa-prop40/comparison/site/repro.html), which derives the main
estimate and every step of the bridge from the exported files. Materials can be found in
[`site/repro.qmd`](site/repro.qmd).

3 - **Open Materials.** This folder, which stores all the code needed to rebuild the comparison
from the two sides' committed export contracts. A guide is the
[materials page](https://fhoces.github.io/opa-prop40/comparison/site/materials.html).

The [comparison overview](https://fhoces.github.io/opa-prop40/) links all three, and the
[BSZ overview](https://fhoces.github.io/opa-prop40/bsz-analysis/site/) and the
[RJKDC overview](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/) each side's own analysis.

This project follows the [Open Policy Analysis (OPA) Guidelines](https://www.bitss.org/opa/) of the
Berkeley Initiative for Transparency in the Social Sciences (BITSS). [`AUDIT.md`](../AUDIT.md) rates
each page against the Guidelines' nine steps.

<br clear="right">

## The reproduction

The reconciliation layer: puts the BSZ side (GGSS July 2026, BSZ August 2026) and the
RJKDC side (Rauh et al. SSRN March 2026, Jaros and Rauh NBER September 2026) on one common
output and one input-by-input bridge. It renders the site-root page, `../index.html`.

## What it reads (and nothing else)

- `../bsz-analysis/export/r/{inputs,outputs}.csv` and
  `../rjkdc-analysis/export/r/{inputs,outputs}.csv`: each side's export contract.
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
| `R/model.R` | `score_common()`, the one estimating function; exact Shapley over all orders; one sequential order; Rauh's analytic Monte Carlo expectations |
| `R/build.R` | every number the page shows, written to `export/r/*.csv` |
| `R/site.R` | renders `../index.html` and `../assets/comparison-data.js` from `site/index.template.html` |
| `site/repro.qmd`, `site/materials.qmd` | the reproduction report and the materials page (`quarto render` in `site/`) |
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
  [0.30, 0.60]) are read from the RJKDC contract (`rauh_mc_*`, `nber_mc_*` rows).
