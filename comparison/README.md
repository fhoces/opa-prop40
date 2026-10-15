# The comparison of California Proposition 40: Open Materials

This folder is the comparison layer of [opa-prop40](https://fhoces.github.io/opa-prop40/), an
[Open Policy Analysis](https://doi.org/10.1093/scipol/scaa067) of California's 2026 Proposition 40 (the Billionaire
Tax Act). The [comparison overview](https://fhoces.github.io/opa-prop40/) is the repository's front page, and this
folder builds it and the [comparison explorer](https://fhoces.github.io/opa-prop40/comparison/site/explorer/). It
puts the [BSZ analysis](https://fhoces.github.io/opa-prop40/bsz-analysis/site/) (August 2026) and the
[JR analysis](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/) (Jaros and Rauh, September 2026) on one
common output, the net fiscal effect, and explains the gap between their numbers one disputed input at a time. The aim is a transparent account of why the two
estimates differ, which anyone can check.

### [Review the code behind the two main estimates, $106.8 billion and -$38.9 billion](https://claude.ai/artifact/6VZEezoAsCNACjmgPLEvah)

($106.8 billion is this OPA's net total for the BSZ analysis, whose own headline is the wealth tax alone; -$38.9 billion is the JR analysis's own headline.)

A layer-by-layer walk from the two numbers on the explorer down to the two analyses' export
contracts. Each layer is marked reviewed, lightly reviewed or not reviewed. Work in progress; the
record is also kept in [`review/`](../review/README.md).

<img align="right" width="340" src="site/assets/opa/opa-materials-wordmark.png" alt="Open Policy Analysis, Materials layer">

1 - **Open Output.** [The explorer](https://fhoces.github.io/opa-prop40/comparison/site/explorer/): the two main
estimates on the net fiscal effect, in two panels of sliders, one per disputed input that moves the estimate
(three minor inputs share one switch), each with an explanation on hover; the step-by-step bridge and gross
revenue are in the report. Materials can be found in
[`site/explorer.template.html`](site/explorer.template.html) and [`R/site.R`](R/site.R).

2 - **Open Analysis.** An open policy report in the form of a
[dynamic document](https://fhoces.github.io/opa-prop40/comparison/site/repro.html), which derives the main
estimate and every step of the bridge from the exported files. Materials can be found in
[`site/repro.qmd`](site/repro.qmd).

3 - **Open Materials.** This folder, which stores all the code needed to rebuild the comparison
from the two analyses' committed export contracts (the two CSV files, `inputs.csv` and
`outputs.csv`, that each analysis's pipeline writes for the comparison to read). A guide is the
[materials page](https://fhoces.github.io/opa-prop40/comparison/site/materials.html).

The [comparison overview](https://fhoces.github.io/opa-prop40/) links all three, and the
[BSZ overview](https://fhoces.github.io/opa-prop40/bsz-analysis/site/) and the
[JR overview](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/) each analysis on its own.

This project follows the [Open Policy Analysis (OPA) framework](https://doi.org/10.1093/scipol/scaa067) (Hoces de la
Guardia, Grant and Miguel, 2021). [`AUDIT.md`](../AUDIT.md) rates
each page against the Guidelines' nine steps.

<br clear="right">

## The reproduction

The reconciliation layer: puts the BSZ analysis (Boll, Saez and Zucman, August 2026) and the
JR analysis (Jaros and Rauh, NBER, September 2026) on one common output and one
input-by-input bridge. The disputed inputs on the JR end are those of its March 2026
version, the one whose inputs the common function takes one by one (the September revision's
code and data are in the same public repository), and the September revision is the bridge's
last step. It
renders the site-root page, `../index.html`, and the explorer, `site/explorer/index.html`.

## What it reads (and nothing else)

- `../bsz-analysis/export/r/{inputs,outputs}.csv` and
  `../rjkdc-analysis/export/r/{inputs,outputs}.csv`: each analysis's export contract.
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
| `py/bridge.py` | Python twin of contract/model/build (the same computation written a second time in Python and checked against the R result), writes `export/py/*.csv` |
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
  abstract's "about $40 billion" are exported as alternatives (`export/r/anchors.csv`; an anchor is
  the published number an end of the bridge is checked against).
- The Monte Carlo ranges (WT floor 35, C in [3.3, 5.8], r in [1.5%, 4.5%], NBER f in
  [0.30, 0.60]) are read from the JR contract (`rauh_mc_*`, `nber_mc_*` rows).
