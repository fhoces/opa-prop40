# opposing-analysis

Open Policy Analysis replication of the opposing side's revenue and net-present-value estimates
for California's Proposition 40 (Billionaire Tax Act):

> Rauh, J., Jaros, B., Kearney, G., Doran, J., & Cosso, M. (2026, March 17). *The Net Present
> Value of the Billionaire Tax Act: An Assessment of the Fiscal Effects of California's Proposed
> Wealth Tax*. Hoover Institution Expert Report. SSRN 6340778.
> https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6340778

> Jaros, B., & Rauh, J. (2026, September). NBER Working Paper c15504 (litigation-risk-weighted
> revision). https://www.nber.org/system/files/chapters/c15504/c15504.pdf

Both versions are reproduced from the authors' own public MIT-licensed materials:
[github.com/bjaros20/wealth_tax](https://github.com/bjaros20/wealth_tax), pinned at
`25e84ddbb67fe0293a64cd9108ed4d35d8ae37ab`. See `DATA-SOURCES.csv` for the full source manifest.

## What this reproduces

| Section | What | R | Python |
|---|---|---|---|
| Sec 5.1.1 (p.15) | Pareto tail fit, alpha = 1.44 | `R/pareto.R` | `py/pareto.py` |
| Sec 5.1.2 (p.17, Table 8) | Income-tax Monte Carlo | `R/income_tax_mc.R` | `py/income_tax_mc.py` |
| Sec 4 (pp.10-14) | Revenue chain 94.20 -> 67.51 -> 55.10, literature-calibrated 45.59 | `R/revenue_chain.R` | `py/revenue_chain.py` |
| Sec 5.2-5.4 (pp.18-20, Tables 9-10) | NPV by departure scenario, break-even fraction | `R/npv_tables.R` | `py/npv_tables.py` |
| Sec 5.5 (p.20) + NBER Sec 5.4 | NPV Monte Carlo, both versions, plus a seed-free analytic mean | `R/npv_mc.R` | `py/npv_mc.py` |
| NBER bridge (final.csv) | Domestic/international totals, ceiling rebuilt from person-level data | `R/nber_final.R` | `py/nber_final.py` |

Both versions of the paper share Sec 4 and Sec 5.1 (revenue chain, Pareto fit, income-tax MC);
the NBER version differs in its NPV Monte Carlo (litigation-risk range, independent departure
fraction `f`, a 7%-grown and 240-person-level `final.csv` base) - see `MISMATCHES.md` for exactly
where the two diverge from each other and from their own documentation.

## How to run

From `opposing-analysis/`, with the authors' repo available (see below):

```sh
export RAUH_REPO_DIR=/absolute/path/to/wealth_tax   # or use the default relative location
Rscript -e 'targets::tar_make()'
Rscript tests/testthat.R
/opt/anaconda3/bin/python3 py/run_export.py
```

`RAUH_REPO_DIR` is the single resolver (`R/rauh_repo.R`, `py/rauh_repo.py`) for the authors' repo.
Default: `original-materials/author-shared/2026-09-23_wealth_tax-repo` (gitignored, not
redistributed - see `DATA-SOURCES.csv`). Set the env var to point elsewhere (e.g. a fresh clone
in CI) without touching any other file.

## Tests (`tests/testthat/`)

159 expectations in 29 test blocks, 0 failed (2026-09-23, with `RAUH_REPO_DIR` set). Count them
through `Rscript tests/testthat.R`, which sources `R/` first; calling `testthat::test_dir()`
directly skips that setup and reports spurious errors. `.github/workflows/opposing-ci.yml`
clones the authors' repo at the pinned SHA, rebuilds R and Python, and runs the suite on every
push touching `opposing-analysis/`.

Three kinds, per file:

1. **Vs. the paper's printed number**, at printed rounding (deterministic figures) or within
   `4 * sd / sqrt(n)` Monte Carlo error (simulated figures - see each test file for why that
   tolerance).
2. **Vs. the authors' own scripts**, run unmodified from a scratch copy (tempdir, plot/csv paths
   redirected, no logic changed - `tests/testthat/helper-author-scripts.R`). These skip cleanly
   (not fail) when `RAUH_REPO_DIR` is unavailable, per the brief and per
   `PLAN.md`'s "CI must not depend on author-shared data" rule.
3. **Parity between `export/r/` and `export/py/`** (`test-parity.R`): deterministic steps to
   1e-6, Monte-Carlo-derived outputs within a documented tolerance (numpy cannot share R's RNG
   stream, so these are independent simulations of the same algorithm, not a bit-for-bit replay).

## Python twin (`py/`)

Mirrors every R step. Two intentional, documented scope reductions from the R side (both numpy
cannot avoid and don't affect correctness of the comparison):

- **Not RNG-bit-parity with R.** Only the R side is checked against the authors' own script's
  exact RNG stream (test kind 2 above); the Python side is an independent Monte Carlo of the same
  algorithm, compared to R within Monte Carlo error.
- **Income-tax MC uses `n_sims = 20,000` and only Table 8's seven printed `K` values** (not the
  full 37-point sweep), documented in `py/income_tax_mc.py`: the vectorized without-replacement
  draw materializes an `(n_sims, K)` array, and 100,000 x 2,000 is too large to keep the sweep
  cheap in pure numpy.

## Exports (`export/r/`, `export/py/`)

`inputs.csv` (`input_id, version, description, value, unit, label, provenance, source, page`) and
`outputs.csv` (`output_id, version, value, unit, printed_value, printed_page, abs_diff`), one row
per key figure cited in this README's table above. `label` follows the OPA input taxonomy (data /
research / guesswork / scenario); see `MISMATCHES.md` #8 for why Table 9's Central Scenario WT is
labelled `scenario` rather than `data` or `research`. The inputs also carry the Monte Carlo
draw ranges (`rauh_mc_*`, `nber_mc_*`), taken from the simulation functions' own defaults, which
`../comparison/` reads from here.

## The OPA site (`site/`)

`site/index.html` (landing), `site/explorer/` (7 dials, 2,187 precomputed cells; `grid.js` is
written by the `site_grid_js` target), `site/repro.qmd` (the reproduction report),
`site/slides/`, and `site/materials.qmd`. Render the two Quarto pages from `opposing-analysis/`
with `quarto render site/repro.qmd && quarto render site/materials.qmd`.

## What reproduces, what doesn't

Every headline number in the table above reproduces from the authors' own code to within the
tolerances documented in `tests/testthat/`. `MISMATCHES.md` lists nine discrepancies found along
the way - between the paper's prose and its own code, between the paper and the NBER README, and
one case (mismatch #9) where the paper's *printed* Monte Carlo summary doesn't exactly reproduce
even from the authors' own unmodified script. The gap is within Monte Carlo error, and the
printed mean equals the model's exact (closed-form) expectation, -$24.707B, while the shipped
seed-2026 run gives -$24.77B.
We do not fix any of these; the pipeline reproduces the code as shipped and records where it
disagrees with the surrounding text.
