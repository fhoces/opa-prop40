# JR analysis of California Proposition 40: Open Materials [![AI generated, not reviewed yet](https://img.shields.io/badge/AI_generated-not_reviewed_yet-red)](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/#how-ai-was-used)

This folder is the JR analysis of [opa-prop40](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/), an Open Policy Analysis of California's
2026 Proposition 40 (the Billionaire Tax Act). The [comparison overview](https://fhoces.github.io/opa-prop40/)
sets this analysis next to the BSZ analysis. This folder reproduces the net present value estimate
of Jaros and Rauh (NBER chapter c15504, Tax Policy and the Economy vol. 41, September 2026), the revision of the first version by Rauh, Jaros, Kearney, Doran and Cosso (SSRN 6340778, March 2026), and opens every input, every line of code and every number behind it. The aim is
a transparent and reproducible analysis that anyone can check, and a shared basis for discussing
the policy.

### [Review the code behind the -$38.9 billion main estimate](https://claude.ai/artifact/MykX5F4qRYF9gzCAbxBQUL)

A layer-by-layer walk from the number on the page down to the authors' pinned repository. Each
layer is marked reviewed, lightly reviewed or not reviewed. Work in progress; the record is also
kept in [`review/`](../review/README.md).

<img align="right" width="340" src="site/assets/opa/opa-materials-wordmark.png" alt="Open Policy Analysis, Materials layer">

1 - **Open Output.** [An interactive explorer](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/explorer/) that shows the main estimate and
lets you move the authors' five inputs and two settings this OPA adds. Materials can be found in [`site/explorer/`](site/explorer/).

2 - **Open Analysis.** An open policy report in the form of a [dynamic document](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/repro.html),
which details all data, code and assumptions in the analysis, and [slides](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/slides/slides.html)
that present the estimate step by step. Materials can be found in [`site/repro.qmd`](site/repro.qmd)
and [`site/slides/`](site/slides/).

3 - **Open Materials.** This folder, which stores all the code needed to replicate the analysis in
full. The authors' papers and repository are not redistributed: see [how to run](#how-to-run) and
`DATA-SOURCES.csv`.

The [JR overview page](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/) links all three. The [comparison overview](https://fhoces.github.io/opa-prop40/)
compares this analysis with the BSZ analysis.

This project follows the [Open Policy Analysis (OPA) framework](https://doi.org/10.1093/scipol/scaa067) (Hoces de la
Guardia, Grant and Miguel, 2021). [`AUDIT.md`](../AUDIT.md) scores
each page against the Guidelines' nine steps.

<br clear="right">

## The reproduction

Open Policy Analysis replication of the JR revenue and net-present-value estimates
for California's Proposition 40 (Billionaire Tax Act):

> Jaros, B., & Rauh, J. (2026, September). *The Net Present Value of the California Billionaire Tax Act*.
> NBER chapter c15504, in *Tax Policy and the Economy*, vol. 41 (University of Chicago Press).
> https://www.nber.org/system/files/chapters/c15504/c15504.pdf

Everything is reproduced from the authors' own public MIT-licensed materials:
[github.com/bjaros20/wealth_tax](https://github.com/bjaros20/wealth_tax), pinned at
`25e84ddbb67fe0293a64cd9108ed4d35d8ae37ab`. See `DATA-SOURCES.csv` for the full source manifest.[^first]

[^first]: The pipeline also reproduces the authors' first version: Rauh, Jaros, Kearney, Doran and
Cosso, Hoover Institution, SSRN 6340778, March 2026. It shares the chapter's Pareto fit and income
tax Monte Carlo. Its own parts are the revenue chain 94.20 -> 67.51 -> 55.10 and the
literature-calibrated 45.59 (its pp.10-14, `R/revenue_chain.R`), NPV by departure scenario and its
break-even table (its Tables 9 and 10, pp.19-20, `R/npv_tables.R`) and its Monte Carlo (its Sec 5.5,
p.20, `R/npv_mc.R`), each with a Python twin. The report's appendix presents it; the pages do not.

## What this reproduces

| Section | What | R | Python |
|---|---|---|---|
| Sec 4.1 (pp.18-19) | Baseline revenue, 94.30 in the authors' workbook (printed 94.20) | `R/revenue_chain.R` | `py/revenue_chain.py` |
| Secs 4.1 and 4.3 (pp.19-21, `final.csv`) | Base grown to the valuation date, domestic/international totals, ceiling rebuilt from person-level data | `R/nber_final.R` | `py/nber_final.py` |
| Sec 4.4 (pp.22-23) | Collectible revenue, 29.6 (range 28.4 to 35.6) | `R/site.R` (`compute_nber_collectible()`) | |
| Sec 5.1 (pp.26-27) | Pareto tail fit, alpha = 1.44 | `R/pareto.R` | `py/pareto.py` |
| Sec 5.1 (p.30, Table 9) | Income-tax Monte Carlo | `R/income_tax_mc.R` | `py/income_tax_mc.py` |
| Sec 5.3 (p.34, Table 10) | Break-even departure fraction | `R/npv_tables.R` | `py/npv_tables.py` |
| Sec 5.4 (p.35) | NPV Monte Carlo, plus a seed-free analytic mean | `R/npv_mc.R` | `py/npv_mc.py` |

The Monte Carlo draws revenue from 0 to the 72 ceiling, an income tax range from Table 9, a rate
range and an independent departure fraction `f`, on a 7%-grown, 240-row person-level `final.csv`
base. `NOTES.md` keeps the reproduction notes: where the text, the README and the code
describe a step differently.

## How to run

From `rjkdc-analysis/`, with the authors' repo available (see below):

```sh
export RAUH_REPO_DIR=/absolute/path/to/wealth_tax   # or use the default relative location
Rscript -e 'targets::tar_make()'
Rscript tests/testthat.R
python3 py/run_export.py
```

`RAUH_REPO_DIR` is the single resolver (`R/rauh_repo.R`, `py/rauh_repo.py`) for the authors' repo.
Default: `original-materials/author-shared/2026-09-23_wealth_tax-repo` (gitignored, not
redistributed - see `DATA-SOURCES.csv`). Set the env var to point elsewhere (e.g. a fresh clone
in CI) without touching any other file.

## Tests (`tests/testthat/`)

The [materials page](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/materials.html#tests)
prints the current count of tests and expectations, read from the last recorded run, so the
count is not repeated here. Run them through `Rscript tests/testthat.R`, which sources `R/` first; calling `testthat::test_dir()`
directly skips that setup and reports spurious errors. `.github/workflows/rjkdc-ci.yml`
clones the authors' repo at the pinned SHA, rebuilds R and Python, and runs the suite on every
push touching `rjkdc-analysis/`.

Four kinds, per file:

1. **Vs. the paper's printed number**, at printed rounding (deterministic figures) or within
   `4 * sd / sqrt(n)` Monte Carlo error (simulated figures - see each test file for why that
   tolerance).
2. **Vs. the authors' own scripts**, run unmodified from a scratch copy (tempdir, plot/csv paths
   redirected, no logic changed - `tests/testthat/helper-author-scripts.R`). These skip cleanly
   (not fail) when `RAUH_REPO_DIR` is unavailable, by design and per
   `PLAN.md`'s "CI must not depend on author-shared data" rule.
3. **Parity between `export/r/` and `export/py/`** (`test-parity.R`): deterministic steps to
   1e-6, Monte-Carlo-derived outputs within a documented tolerance (numpy cannot share R's RNG
   stream, so these are independent simulations of the same algorithm, not a bit-for-bit replay).
4. **The site** (`test-site.R`): the explorer's `grid.js` and `site/data/headlines.csv` must be
   byte-identical to the exporter's output; grid cells must equal the pipeline's analytic means and
   brute-force Monte Carlo; the printed-value transcription must agree with the pipeline; every
   number typed into the landing page must still match its source.

## Python twin (`py/`)

Mirrors every R step. Two intentional, documented scope reductions from the R side (both numpy
cannot avoid and don't affect correctness of the comparison):

- **Not RNG-bit-parity with R.** Only the R side is checked against the authors' own script's
  exact RNG stream (test kind 2 above); the Python side is an independent Monte Carlo of the same
  algorithm, compared to R within Monte Carlo error.
- **Income-tax MC uses `n_sims = 20,000` and only Table 9's seven printed `K` values** (not the
  full 37-point sweep), documented in `py/income_tax_mc.py`: the vectorized without-replacement
  draw materializes an `(n_sims, K)` array, and 100,000 x 2,000 is too large to keep the sweep
  cheap in pure numpy.

## Exports (`export/r/`, `export/py/`)

`inputs.csv` (`input_id, version, description, value, unit, label, provenance, source, page`) and
`outputs.csv` (`output_id, version, value, unit, printed_value, printed_page, abs_diff`), one row
per key figure cited in this README's table above. `label` follows the OPA input taxonomy (data /
research / guesswork / scenario), plus `derived` for a value computed from other rows and
`guesswork on data` for the 7% growth that moves the 2025 list to the valuation date.[^scenario]
`provenance` is `public` on every row: the authors' repository is public under an MIT licence.
The inputs also carry the Monte Carlo
draw ranges (`rauh_mc_*`, `nber_mc_*`), taken from the simulation functions' own defaults, which
`../comparison/` reads from here.

[^scenario]: The one `scenario` row, the first version's Table 9 central revenue, is explained in
`NOTES.md`, note 8.

## The OPA site (`site/`)

`site/index.html` (landing), `site/explorer/` (7 dials, 2,187 precomputed cells; `grid.js` is
written by the `site_grid_js` target), `site/repro.qmd` (the reproduction report),
`site/slides/`, and `site/materials.qmd`. Render the two Quarto pages from `rjkdc-analysis/`
with `quarto render site/repro.qmd && quarto render site/materials.qmd`.

## What reproduces

The code reproduces the published results of both versions: every headline number in the table
above, within the tolerances documented in `tests/testthat/`. A deterministic figure reproduces
when it rounds to the printed digit, or differs only because the paper rounded or typed an
intermediate figure (0.1% or less). A simulated figure reproduces when it lies within four Monte
Carlo standard errors of the printed value.

`NOTES.md` keeps ten notes, for transparency, on where the text, the READMEs and the code
describe the same step differently. None is a failure to reproduce a printed result. Each states
its kind: three rounded or typed inputs (notes 4, 6 and 8), one seed variation (note 9) and six
documentation notes (1, 2, 3, 5, 7 and 10). Five concern the chapter (one of them, note 10, is in
the first version too).[^mm] We do not fix any of these; the pipeline reproduces the code as
shipped and records the note. The notes were reclassified on 2026-10-16: the earlier list, then
called mismatches, counted rounding and seed differences as results that did not match, which
overstated them.

[^mm]: The other five concern only the first version. One of them (note 9) is seed variation: the
*printed* Monte Carlo summary is not the one the shipped seed gives, but it is within Monte Carlo
error of it, and the printed mean and SD equal the model's exact (closed-form) values at the printed
digit (-$24.707B and $38.423B), while the shipped seed-2026 run gives -$24.77B and $38.60B.
