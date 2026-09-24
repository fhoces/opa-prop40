# OPA audit baseline, 2026-09-23

Scored against the BITSS OPA Guidelines (2019), nine steps, levels 0 to 3, as of commit
`0412337`. Level wording is quoted from the Guidelines. One vector per page, then the fixes
with the most credibility per unit of effort.

## The condition that governs every row: nothing is published yet

The repository `fhoces/opa-prop40` is **private** and GitHub Pages is **not enabled**
(`gh api repos/fhoces/opa-prop40/pages` returns 404). As things stand, no reader can see the
explorer, the reports, the code or the data. **Every step that requires sharing (1 to 5, and 8
at level 1 "through a trusted repository") is therefore Level 0 today**, and so is the headline
level. Step 9 alone holds (git plus a shared GitHub repository).

The vectors below are the levels the pages earn **once the repository is public and the sites
are served**. Nothing else needs to change for them to hold.

## Supporting OPA (`supporting-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | "One table or graph is highlighted as the best reflection": the preferred-estimate box (Table 5 row 1, benchmark) in `site/explorer/index.html`, generated from `G.preferred` in `site/explorer/grid.js` | Level 2 needs "a sample output published pre-release". The output was fixed in `PLAN.md` (`b935d94`, "Pre-specified output") and pushed in `cf6d9a0` before any opposing result, but only to a private repo, and after this side's own reproduction (imported from May). Publish the spec before the next round's results |
| 2 | Input-output link | 2 | "An interactive tool allowing for adjusted inputs": 6-dial explorer over a precomputed grid (`site/explorer/`) | Level 3 needs the tool to share "the same key sections of code". The grid comes from `score_tab5_cell()` (`R/site_exports.R:78`), a second implementation pinned by test to `compute_tab5()`. Make `compute_tab5()` call `score_tab5_cell()` so there is one scorer |
| 3 | Methodological accounts | 3 | "Code is clearly documented into a dynamic document": `site/repro.qmd` (knitr, folded code, every number computed) | None (top level) |
| 4 | Data | 3 | Analytic data in the repo (`site/data/*.csv`, `outputs/`). The raw workbook is not redistributed, but `DATA-SOURCES.csv` gives the URL, date and SHA-256, and `site/materials.qmd` gives the download command | None. Note that the author-shared bundle is confidential and not used by anything published |
| 5 | Open report | 3 | "A dynamic document ... and include version control tracking": `site/repro.qmd` in git | None |
| 6 | File structure | 3 | Self-contained `supporting-analysis/` with `R/`, `tests/`, `site/`, `_targets.R`, `README.md` | None. However, `README.md` is stale (says 506 tests and "CI not started"; now 558 and CI green) |
| 7 | Label inputs | 3 | 18 inputs in `site/data/inputs.csv`, each with an origin (data 4, research 5, guesswork 5, derived 2, scenario 1, convention 1) and a basis with page or cell references | None under the Guidelines' wording. The paper also asks that guesswork carry "analyst X and date Y"; the 5 guesswork rows do not |
| 8 | Reproducible code | 2 | "Possible to run regardless of software dependencies": `.github/workflows/ci.yml` rebuilds the pipeline from `DESCRIPTION` on a clean runner and runs the suite (green on `0412337`) | Level 3 needs "just one click": a Binder or Codespaces devcontainer. A lockfile (none exists) would also stop runner-vs-local package drift |
| 9 | Version control | 3 | Git plus the shared GitHub repository, all work committed | None |

## Opposing OPA (`opposing-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | Two preferred-estimate cards (SSRN Mar 2026, NBER Sept 2026) in `site/explorer/`, from `G.preferred`. The strongest-version policy fixes two estimates per side, so two cards is by design | Level 2: as for supporting. The spec reached origin in `cf6d9a0` (14:55), before the first Rauh result commit (`35cb9b2`, 15:52), but only in a private repo |
| 2 | Input-output link | 2 | 7-dial explorer, 2,187 cells | Level 3: the grid uses `cell_outcomes()` / `e_inv_rate()` (`R/site.R:130-172`), a closed-form second implementation. It takes its input ranges from `formals(compute_npv_mc_*)` (`R/site.R:52-53`), but computes outcomes without `npv_mc_analytic_mean()` (`R/npv_mc.R`). Route the grid through `npv_mc_analytic_mean()` |
| 3 | Methodological accounts | 3 | `site/repro.qmd`, dynamic document | None |
| 4 | Data | 3 | Analytic data: `export/{r,py}/*.csv`. Raw: the authors' public repo, pinned at `bjaros20/wealth_tax@25e84dd` and cloned by `.github/workflows/opposing-ci.yml` | None |
| 5 | Open report | 3 | `site/repro.qmd` in git; `MISMATCHES.md` (9 items) linked from the materials page | None |
| 6 | File structure | 3 | Self-contained `opposing-analysis/`, same layout as supporting, with `README.md` | None |
| 7 | Label inputs | 3 | 20 inputs in `export/r/inputs.csv` (data 8, research 4, guesswork 6, derived 1, scenario 1), each with a code or workbook location and a page | Same gap as supporting: guesswork rows name no analyst or date |
| 8 | Reproducible code | 2 | `opposing-ci.yml` rebuilds R and Python from scratch, runs parity; first run green (11m22s) | One click (Binder/devcontainer). The run needs `RAUH_REPO_DIR`; a devcontainer would set it |
| 9 | Version control | 3 | As supporting | None |

## Reconciliation page (site root, `comparison/`)

Not a full OPA by design (it takes each side's contract as given), so steps 3 to 8 are scored
on the comparison layer itself.

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | Common outputs (a) gross revenue and (b) net fiscal effect, with one bridge highlighted (Shapley, each side's own horizon) on `index.html`; the Rauh (a) default was settled in `PLAN.md` ("Decisions after the first build") | Level 2: the output and bridge direction were fixed in `d9532a2` (16:26), after both side reproductions had merged (15:56 onward), though before any comparison number. Publish the spec before results next time |
| 2 | Input-output link | 2 | Interactive toggles on `index.html`: output (a/b), method (Shapley / one order), horizon (own / 5 / 10 / 20 years) | Level 3: the page reads `assets/comparison-data.js`, written by `comparison/run.R` from the same `build_all()` the tests run, so the code is shared. What keeps this at 2 is that the toggles pick among precomputed settings rather than adjusting inputs. Add input dials (e.g. r range, avoidance) over a grid from `build_all()` |
| 3 | Methodological accounts | 2 | Annotated R and Python in `comparison/R`, `comparison/py`; `comparison/README.md`, `DISPUTES.md` | Level 3: a dynamic document for the comparison; `index.html` is generated from a template, not a notebook |
| 4 | Data | 2 | Analytic data: `comparison/export/{r,py}/`. Inputs: `comparison/data/document-inputs.csv`, `hoopes-fig2.csv` (digitized) | Level 3 is met in substance through the sides' raw data; say so on the page |
| 5 | Open report | 2 | `index.html` plus `DISPUTES.md`, version-controlled | Level 3: as step 3 |
| 6 | File structure | 3 | `comparison/` with `R/`, `py/`, `data/`, `export/`, `tests/`, `README.md` | None. The root `README.md` is out of date: it describes the opposing side as "SSRN 6340778. PDF only", before the NBER version and the authors' repo were added |
| 7 | Label inputs | 3 | 18 rows in `document-inputs.csv`, each with a label (data 7, guesswork 5, derived 4, scenario 2), a source and a page | Guesswork analyst/date, as above |
| 8 | Reproducible code | 2 | `Rscript comparison/run.R` rebuilds everything; 172 tests | No CI workflow covers `comparison/` yet (only `ci.yml` and `opposing-ci.yml` exist). Add one, then one click |
| 9 | Version control | 3 | As above | None |

## Headline

- **Today: Level 0** on every page, because nothing is public.
- **On publication: Level 1** for all three pages (the minimum across steps; step 1 sets it
  everywhere). Vectors: supporting `1-2-3-3-3-3-3-2-3`, opposing `1-2-3-3-3-3-3-2-3`,
  reconciliation `1-2-2-2-2-3-3-2-3`.

## Best credibility per unit of effort

1. **Make the repository public and turn on Pages.** One setting takes every page from 0 to its
   vector above. The prerequisite is a sweep of what is tracked: the author-shared bundles and
   `original-materials/` must stay out, and `DATA-SOURCES.csv` records their terms.
2. **One scorer per side (step 2 to Level 3).** The explorer grid should call the analysis
   functions, not re-implement them: `compute_tab5()` via `score_tab5_cell()` (supporting), and
   the grid via `npv_mc_analytic_mean()` (opposing). The existing pin tests become redundant
   rather than load-bearing.
3. **Step 1 to Level 2 for the next round.** It cannot be met retroactively for this round. For
   any update, publish the output spec (the `PLAN.md` section) to the public repo before
   computing. Meanwhile, state on each landing page when the output was fixed relative to the
   results (the commit times above), which is honest and costs a sentence.

Smaller: add `analyst` and `date` columns to the guesswork rows (the paper's standard for
guesswork); add a CI workflow for `comparison/`; refresh the supporting and root READMEs.
