# OPA audit baseline, 2026-09-23

Scored against the BITSS OPA Guidelines (2019), nine steps, levels 0 to 3, baseline
`0412337`, updated through `f0e1997`. Level wording is quoted from the Guidelines. One vector per page, then the fixes
with the most credibility per unit of effort.

## The condition that governs every row: nothing is published yet

The repository `fhoces/opa-prop40` is **private** and GitHub Pages is **not enabled**
(`gh api repos/fhoces/opa-prop40/pages` returns 404). As things stand, no reader can see the
explorer, the reports, the code or the data. **Every step that requires sharing (1 to 5, and 8
at level 1 "through a trusted repository") is therefore Level 0 today**, and so is the headline
level. Step 9 alone holds (git plus a shared GitHub repository).

The vectors below are the levels the pages earn **once the repository is public and the sites
are served**. Nothing else needs to change for them to hold.

## BSZ OPA, the side supporting the measure (`bsz-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | "One table or graph is highlighted as the best reflection": the preferred-estimate box (Table 5 row 1, benchmark) in `site/explorer/index.html`, generated from `G.preferred` in `site/explorer/grid.js` | Level 2 needs "a sample output published pre-release". The output was fixed in `PLAN.md` (`b935d94`, "Pre-specified output") and pushed in `cf6d9a0` before any RJKDC result, but only to a private repo, and after this side's own reproduction (imported from May). Publish the spec before the next round's results |
| 2 | Input-output link | 3 | "An interactive tool allowing for adjusted inputs is provided, and its underlying code shares the same key sections of code behind the analysis section": the 6-dial explorer's grid is scored by `score_tab5_cell()` in `R/compute_tab5.R`, the function `compute_tab5()` itself uses for the reproduction (commit `87a75c6`; `test-site.R` asserts both call it) | None (top level) |
| 3 | Methodological accounts | 3 | "Code is clearly documented into a dynamic document": `site/repro.qmd` (knitr, folded code, every number computed) | None (top level) |
| 4 | Data | 3 | Analytic data in the repo (`site/data/*.csv`, `export/r/*.csv`; `outputs/` is generated and gitignored). The raw workbook is not redistributed, but `DATA-SOURCES.csv` gives the URL, date and SHA-256, and `site/materials.qmd` gives the download command | None. Note that the author-shared bundle is confidential and not used by anything published |
| 5 | Open report | 3 | "A dynamic document ... and include version control tracking": `site/repro.qmd` in git | None |
| 6 | File structure | 3 | Self-contained `bsz-analysis/` with `R/`, `tests/`, `site/`, `_targets.R`, `README.md` (refreshed `db8651a`) | None |
| 7 | Label inputs | 3 | 18 inputs in `site/data/inputs.csv`, each with an origin (data 4, research 5, guesswork 5, derived 2, scenario 1, convention 1) and a basis with page or cell references | None under the Guidelines' wording. The paper also asks that guesswork carry "analyst X and date Y"; the 5 guesswork rows do not |
| 8 | Reproducible code | 2 | "Possible to run regardless of software dependencies": `.github/workflows/bsz-ci.yml` rebuilds the pipeline from `DESCRIPTION` on a clean runner and runs the suite (green on `fad50f2`) | Level 3 needs "just one click": a Binder or Codespaces devcontainer. A lockfile (none exists) would also stop runner-vs-local package drift |
| 9 | Version control | 3 | Git plus the shared GitHub repository, all work committed | None |

## RJKDC OPA, the side opposing it (`rjkdc-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | Two preferred-estimate cards (SSRN Mar 2026, NBER Sept 2026) in `site/explorer/`, from `G.preferred`. The strongest-version policy fixes two estimates per side, so two cards is by design | Level 2: as for BSZ. The spec reached origin in `cf6d9a0` (14:55), before the first Rauh result commit (`35cb9b2`, 15:52), but only in a private repo |
| 2 | Input-output link | 3 | 7-dial explorer, 2,187 cells, scored by `npv_expectation()` and `npv_share_negative_exact()` in `R/npv_mc.R`, the functions behind the reproduction's `npv_mc_analytic_mean()` (`test-site.R` asserts both paths call them) | None (top level) |
| 3 | Methodological accounts | 3 | `site/repro.qmd`, dynamic document | None |
| 4 | Data | 3 | Analytic data: `export/{r,py}/*.csv`. Raw: the authors' public repo, pinned at `bjaros20/wealth_tax@25e84dd` and cloned by `.github/workflows/rjkdc-ci.yml` | None |
| 5 | Open report | 3 | `site/repro.qmd` in git; `MISMATCHES.md` (9 items) linked from the materials page | None |
| 6 | File structure | 3 | Self-contained `rjkdc-analysis/`, same layout as BSZ, with `README.md` | None |
| 7 | Label inputs | 3 | 20 inputs in `export/r/inputs.csv` (data 8, research 4, guesswork 6, derived 1, scenario 1), each with a code or workbook location and a page | Same gap as BSZ: guesswork rows name no analyst or date |
| 8 | Reproducible code | 2 | `rjkdc-ci.yml` rebuilds R and Python from scratch, runs parity; first run green (11m22s) | One click (Binder/devcontainer). The run needs `RAUH_REPO_DIR`; a devcontainer would set it |
| 9 | Version control | 3 | As BSZ | None |

## Reconciliation page (site root, `comparison/`)

Not a full OPA by design (it takes each side's contract as given), so steps 3 to 8 are scored
on the comparison layer itself.

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | Common outputs (a) gross revenue and (b) net fiscal effect, with one bridge highlighted (Shapley, each side's own horizon) on `index.html`; the Rauh (a) default was settled in `PLAN.md` ("Decisions after the first build") | Level 2: the output and bridge direction were fixed in `d9532a2` (16:26), after both side reproductions had merged (15:56 onward), though before any comparison number. Publish the spec before results next time |
| 2 | Input-output link | 2 | Interactive toggles on `index.html`: output (a/b), method (Shapley / one order), horizon (own / 5 / 10 / 20 / 30 / 50 years / perpetuity) | Level 3: the page reads `assets/comparison-data.js`, written by `comparison/run.R` from the same `build_all()` the tests run, so the code is shared. What keeps this at 2 is that the toggles pick among precomputed settings rather than adjusting inputs. Add input dials (e.g. r range, avoidance) over a grid from `build_all()` |
| 3 | Methodological accounts | 2 | Annotated R and Python in `comparison/R`, `comparison/py`; `comparison/README.md`, `DISPUTES.md` | Level 3: a dynamic document for the comparison; `index.html` is generated from a template, not a notebook |
| 4 | Data | 2 | Analytic data: `comparison/export/{r,py}/`. Inputs: `comparison/data/document-inputs.csv`, `hoopes-fig2.csv` (digitized) | Level 3 is met in substance through the sides' raw data; say so on the page |
| 5 | Open report | 2 | `index.html` plus `DISPUTES.md`, version-controlled | Level 3: as step 3 |
| 6 | File structure | 3 | `comparison/` with `R/`, `py/`, `data/`, `export/`, `tests/`, `README.md` | None (the root `README.md` was refreshed in `db8651a`) |
| 7 | Label inputs | 3 | 18 rows in `document-inputs.csv`, each with a label (data 7, guesswork 5, derived 4, scenario 2), a source and a page | Guesswork analyst/date, as above |
| 8 | Reproducible code | 2 | `Rscript comparison/run.R` rebuilds everything; 172 tests; `.github/workflows/comparison-ci.yml` rebuilds R and Python on a clean runner and checks the committed `index.html` is the generator's output | One click (Binder/devcontainer) |
| 9 | Version control | 3 | As above | None |

## Headline

- **Today: Level 0** on every page, because nothing is public.
- **On publication: Level 1** for all three pages (the minimum across steps; step 1 sets it
  everywhere). Vectors: BSZ `1-3-3-3-3-3-3-2-3`, RJKDC `1-3-3-3-3-3-3-2-3`,
  reconciliation `1-2-2-2-2-3-3-2-3`.

## Best credibility per unit of effort

1. **Make the repository public and turn on Pages.** One setting takes every page from 0 to its
   vector above. The pre-publication sweep (2026-09-23) of the tree and the full history found no
   paper, workbook or author-shared file ever committed (`original-materials/` is ignored), no
   credentials, and no author email. One blocker: two RPubs claim URLs with tokens in
   `rsconnect/*.dcf`, untracked in `eb0b709` but still in history; purge them (or retire the
   tokens on RPubs) before going public.
2. **One scorer per side (step 2 to Level 3).** Done 2026-09-23: each explorer grid now calls the
   analysis's own functions (BSZ `87a75c6`; RJKDC `817dcf8`), with grids and
   exports byte-identical before and after.
3. **Step 1 to Level 2 for the next round.** It cannot be met retroactively for this round. For
   any update, publish the output spec (the `PLAN.md` section) to the public repo before
   computing. Meanwhile, state on each landing page when the output was fixed relative to the
   results (the commit times above), which is honest and costs a sentence.

Smaller: add `analyst` and `date` columns to the guesswork rows (the paper's standard for
guesswork); (done since: a CI workflow for `comparison/`, refreshed READMEs).
