# OPA audit baseline, 2026-09-23

Scored against the BITSS OPA Guidelines (2019), nine steps, levels 0 to 3, baseline
`8c904f5`, updated through `15b08d5`; the publication status and the BSZ step 1 evidence were updated
on 2026-10-08. Level wording is quoted from the Guidelines. One vector per page, then the fixes
with the most credibility per unit of effort.

## Publication

The repository `fhoces/opa-prop40` has been **public** since 2026-10-01, and GitHub Pages serves
the sites at https://fhoces.github.io/opa-prop40/. Readers can see the explorers, the reports,
the code and the data. The vectors below are the levels the pages earn today.

When this audit was first written, the repository was private and Pages was not enabled. Every
step that requires sharing (1 to 5, and 8 at level 1) was then Level 0, and so was the headline.

## BSZ OPA (`bsz-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | "One table or graph is highlighted as the best reflection": the main estimate in `site/explorer/index.html` (Table 5 row 1, base scenario: wealth tax plus extra income tax from sales minus income tax lost to leavers, present value over 5 years at 3%), shown as the headline number in the explorer's header with its definition, and a footnote that it is not the authors' choice. It replaced a preferred-estimate box (`c1c411c`, `b646791`) | Level 2 needs "a sample output published pre-release". The output was fixed in `PLAN.md` (`0b07ce7`, "Pre-specified output") and pushed in `9adcd2f` before any RJKDC result, but only to a private repo, and after this analysis's own reproduction (imported from May). Publish the spec before the next round's results |
| 2 | Input-output link | 3 | "An interactive tool allowing for adjusted inputs is provided, and its underlying code shares the same key sections of code behind the analysis section": the 6-dial explorer's grid is computed by `score_tab5_cell()` in `R/compute_tab5.R`, the function `compute_tab5()` itself uses for the reproduction (commit `6219268`; `test-site.R` asserts both call it) | None (top level) |
| 3 | Methodological accounts | 3 | "Code is clearly documented into a dynamic document": `site/repro.qmd` (knitr, folded code, every number computed) | None (top level) |
| 4 | Data | 3 | Analytic data in the repo (`site/data/*.csv`, `export/r/*.csv`; `outputs/` is generated and gitignored). The raw workbook is not redistributed, but `DATA-SOURCES.csv` gives the URL, date and SHA-256, and `site/materials.qmd` gives the download command | None. Note that the author-shared bundle is confidential and not used by anything published |
| 5 | Open report | 3 | "A dynamic document ... and include version control tracking": `site/repro.qmd` in git | None |
| 6 | File structure | 3 | Self-contained `bsz-analysis/` with `R/`, `tests/`, `site/`, `_targets.R`, `README.md` (refreshed `fedc0c7`) | None |
| 7 | Label inputs | 3 | 18 inputs in `site/data/inputs.csv`, each with an origin (data 4, research 5, guesswork 5, derived 2, scenario 1, convention 1) and a basis with page or cell references | None under the Guidelines' wording. The paper also asks that guesswork carry "analyst X and date Y"; the 5 guesswork rows do not |
| 8 | Reproducible code | 2 | "Possible to run regardless of software dependencies": `.github/workflows/bsz-ci.yml` rebuilds the pipeline from `DESCRIPTION` on a clean runner and runs the suite (green on `9dc34f9`) | Level 3 needs "just one click": a Binder or Codespaces devcontainer. A lockfile (none exists) would also stop runner-vs-local package drift |
| 9 | Version control | 3 | Git plus the shared GitHub repository, all work committed | None |

## RJKDC OPA (`rjkdc-analysis/`)

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | One main estimate, updated 2026-10-14: the NBER September 2026 mean net present value, -$38.9 billion (Jaros and Rauh, PDF p.1), shown as the headline number on the overview (`site/index.html`) and in the explorer's header (`site/explorer/index.html`) with its definition and a footnote that it is the authors' own headline. Both pages read it from `explorer/grid.js` (`G.preferred`). The SSRN March 2026 estimate (-24.7) stays as a scenario in the explorer and as the comparison page's anchor. It replaced two side-by-side preferred-estimate cards | Level 2: as for BSZ. The spec reached origin in `9adcd2f` (14:55), before the first Rauh result commit (`59964ca`, 15:52), but only in a private repo |
| 2 | Input-output link | 3 | 7-dial explorer, 2,187 cells, computed by `npv_expectation()` and `npv_share_negative_exact()` in `R/npv_mc.R`, the functions behind the reproduction's `npv_mc_analytic_mean()` (`test-site.R` asserts both paths call them) | None (top level) |
| 3 | Methodological accounts | 3 | `site/repro.qmd`, dynamic document | None |
| 4 | Data | 3 | Analytic data: `export/{r,py}/*.csv`. Raw: the authors' public repo, pinned at `bjaros20/wealth_tax@25e84dd` and cloned by `.github/workflows/rjkdc-ci.yml` | None |
| 5 | Open report | 3 | `site/repro.qmd` in git; `MISMATCHES.md` (9 items) linked from the materials page | None |
| 6 | File structure | 3 | Self-contained `rjkdc-analysis/`, same layout as BSZ, with `README.md` | None |
| 7 | Label inputs | 3 | 20 inputs in `export/r/inputs.csv` (data 8, research 4, guesswork 6, derived 1, scenario 1), each with a code or workbook location and a page | Same gap as BSZ: guesswork rows name no analyst or date |
| 8 | Reproducible code | 2 | `rjkdc-ci.yml` rebuilds R and Python from scratch, runs parity; first run green (11m22s) | One click (Binder/devcontainer). The run needs `RAUH_REPO_DIR`; a devcontainer would set it |
| 9 | Version control | 3 | As BSZ | None |

## Reconciliation page (site root, `comparison/`)

Not a full OPA by design (it takes each analysis's contract as given), so steps 3 to 8 are
scored on the comparison layer itself. Updated 2026-10-14 for the BSZ-shaped root page, the
report and the materials page, then again the same day for the comparison explorer
(`comparison/site/explorer/`), output (b) first, and both analyses cited in their latest
version only.

| # | Step | Level | Evidence | What the next level needs |
|---|---|---|---|---|
| 1 | Unified output | 1 | "One table or graph is highlighted as the best reflection": the explorer (`comparison/site/explorer/index.html`) is now the unified output. Its header shows the two main estimates next to each other, BSZ $106.8B (net total, 5 years) and RJKDC -$38.9B (NBER September 2026 mean NPV), the root page repeats the same block, and the two-bar chart under them shows the bridge's two ends under the common output (b), the net fiscal effect, which is what both main estimates measure. One footnote states the two definitions and that (b) puts them on one. The values come from `comparison/R/site.R` (tokens) and `assets/comparison-data.js` (the explorer's script), never typed. The gap on (b) is explained one disputed input at a time in the explorer's bridge | Level 2: the common outputs and the bridge direction were fixed in `2c302eb`, after both reproductions had merged, though before any comparison number; putting (b) first and the two main estimates in the headline were chosen on 2026-10-14, after the results. Publish the spec before results next time |
| 2 | Input-output link | 3 | Interactive settings on the explorer: output ((b) by default, then (a)), method (Shapley / one order), horizon (own / 5 / 10 / 20 / 30 / 50 years / perpetuity). The horizon is a disputed input (DISPUTES row 2). The explorer's settings select precomputed views: every bar is a value `build_all()` wrote to `comparison/export/r/` by running the same `score_common()` the report derives step by step, serialized into `assets/comparison-data.js` by `site.R`. `test-site.R` asserts the data file and both pages are byte-identical to the generator's output, that the headline object and the first and last bars of the default view equal `ends.csv` on (b), and that the steps, the model difference and the September revision add up to the gap; `test-shapley.R` and `test-endpoints.R` assert the exported values are what `score_common()` returns | Met, with a caveat: one input dial (horizon), served from `build_all()` like the analyses' grids; more dials would strengthen it (e.g. r range, avoidance) |
| 3 | Methodological accounts | 3 | "Code is clearly documented into a dynamic document": `comparison/site/repro.qmd` (knitr) reads the exports, derives the main estimate step by step, and folds the R source and its Python twin under each exhibit | None (top level) |
| 4 | Data | 3 | Analytic data: `comparison/export/{r,py}/`, listed with rows and contents on `comparison/site/materials.html`. Inputs: the two analyses' committed export contracts, `comparison/data/document-inputs.csv` and `hoopes-fig2.csv` (digitized). The two third-party PDFs only the comparison uses are in `comparison/DATA-SOURCES.csv` with URL and SHA-256 | None |
| 5 | Open report | 3 | "A dynamic document ... and include version control tracking": `comparison/site/repro.qmd` in git, rendered to `repro.html`, plus `DISPUTES.md` | None |
| 6 | File structure | 3 | `comparison/` with `R/`, `py/`, `data/`, `export/`, `site/`, `tests/`, `README.md` (Open Materials top in the BSZ shape) | None |
| 7 | Label inputs | 3 | 18 rows in `document-inputs.csv`, each with a label (data 7, guesswork 5, derived 4, scenario 2), a source and a page; every bridge step carries a kind | Guesswork analyst/date, as above |
| 8 | Reproducible code | 2 | `Rscript comparison/run.R` rebuilds everything, the explorer included; 214 expectations (counted on the materials page when it renders); `.github/workflows/comparison-ci.yml` rebuilds R and Python on a clean runner and the suite checks the committed `index.html`, explorer and data file are the generator's output | One click (Binder/devcontainer); CI does not render the two Quarto pages |
| 9 | Version control | 3 | As above | None |

## Headline

- **Level 1** for all three pages (the minimum across steps; step 1 sets it everywhere).
  Before the repository went public on 2026-10-01, every page was Level 0. Vectors: BSZ `1-3-3-3-3-3-3-2-3`, RJKDC `1-3-3-3-3-3-3-2-3`,
  reconciliation `1-3-2-2-2-3-3-2-3`.

## Best credibility per unit of effort

1. **Make the repository public and turn on Pages.** Done 2026-10-01, which took every page from
   Level 0 to its vector above. The pre-publication sweep (2026-09-23) of the tree and the full history found no
   paper, workbook or author-shared file ever committed (`original-materials/` is ignored), no
   credentials, and no author email. The one blocker it found, two RPubs claim URLs with tokens in
   `rsconnect/*.dcf` (untracked in `7cceb73`), was cleared on 2026-09-24 by removing those files
   from the whole history with `git filter-repo` and force-pushing; every commit from the CAWT-BSZ
   import onward has a new SHA (timestamps unchanged), and the SHAs cited in this file were updated
   to match. `**/rsconnect/` stays in `.gitignore`. GitHub keeps unreferenced old commits until its
   own garbage collection, but both claim links are already used: checked 2026-09-24, each one
   redirects to its claimed document (1436128 in the BITSS RPubs account, 1436129 in `fhoces`), so
   a leftover copy of a token cannot claim anything.
2. **One estimating function per analysis (step 2 to Level 3).** Done 2026-09-23: each explorer grid now calls the
   analysis's own functions (BSZ `6219268`; RJKDC `e899ae9`), with grids and
   exports byte-identical before and after.
3. **Step 1 to Level 2 for the next round.** It cannot be met retroactively for this round. For
   any update, publish the output spec (the `PLAN.md` section) to the public repo before
   computing. Meanwhile, state on each landing page when the output was fixed relative to the
   results (the commit times above), which is honest and costs a sentence.

Smaller: add `analyst` and `date` columns to the guesswork rows (the paper's standard for
guesswork); (done since: a CI workflow for `comparison/`, refreshed READMEs).
