# opa-prop40: plan, phase 1 (repo skeleton + BSZ import + August re-verification)

Project: an Open Policy Analysis (OPA) of the two rival revenue analyses of California's 2026
Proposition 40 (the Billionaire Tax Act, a one-time 5% tax on net worth above $1bn).

- BSZ, supporting the measure: Boll, Saez & Zucman, NBER WP 35218, May 2026 revised August 2026, with
  an Excel workbook `BSZ_MainTablesFigures.xlsx`.
- RJKDC, opposing it: Rauh, Jaros, Kearney, Doran & Cosso, Hoover Institution, 17 March 2026
  (SSRN 6340778). PDF only.

The end state is one private repo: a full OPA for each side, plus a comparison layer that puts
both on one input-to-output chain. **Phase 1 covers only the steps below.** No Python twin, no
SQL files, no Rauh work and no website yet.

## Pre-specified output (fixed 2026-09-23, before any results)

Stated here, before any Rauh reproduction or reconciliation work, so the choice of output cannot
be tuned to the results (OPA step 1: fix the output first).

**Whose version is analysed: the strongest version of each side.** That means the anchor team's
latest estimate, plus their own later documents, with any correction they conceded applied. We do
not strengthen either side ourselves; our own improvements appear only on the reconciliation page,
credited to us.

- **BSZ side** reports **two estimates side by side**:
  1. GGSS expert report (updated 20 July 2026): $100B from static scoring with 10% avoidance, the
     number the campaign cites.
  2. BSZ NBER WP 35218 (August 2026, workbook): the $104B benchmark and the other rows of its
     Table 5.
  The conceded fix is already in both: the non-US-citizen residents are included (see
  `comparison/DISPUTES.md`, row 8).
- **RJKDC side** reports **two estimates side by side**, mirroring the BSZ side (decided
  2026-09-23):
  1. Rauh et al., SSRN 6340778 (17 March 2026): European-elasticity approach, about $40B in revenue,
     mean NPV −$24.7B. This is the anchor that `comparison/DISPUTES.md` is verified against.
  2. Jaros and Rauh, NBER version (September 2026): litigation-risk-weighted approach, about $30B,
     mean NPV −$38.9B. It differs from the SSRN version mainly in one input, the probability that the
     Act survives constitutional challenge, so it enters the bridge as one extra step.
  Both are replicated from the authors' public MIT repo (github.com/bjaros20/wealth_tax). The Hoover
  August 2026 brief repeats the SSRN numbers.
- **Other same-side work** enters as **credited alternative dials** on specific inputs, never merged
  into a side's headline. Current candidates: Walczak / California Tax Foundation (2026-04-22),
  RJKDC side.
- **Neutral material** feeds the reconciliation page only: LAO ballot analysis, and Hoopes, "Galle v
  Rauh" (SSRN 6428578).

**Deliverables: three pages.**

1. **Two full OPAs**, one per side, each shaped like
   `~/Desktop/sandbox/opa-ai-macro-econ-scenarios/index.html`. A landing page with OPA layer cards:
   - Open Output: an explorer with dials over a precomputed grid, the preferred estimate highlighted.
   - Open Analysis: a full reproduction report (sections in order, every equation and step
     explained) plus a teaching slide deck.
   - Open Materials: repo, tests, CSVs.
   Also "What the model says", "What reproduces" (mismatches listed) and a CRediT / AI-use section,
   with a footer link back to the overview.
2. **One reconciliation page**, built in this order:
   - **A common output definition first.** The two headlines answer different questions.
     BSZ/GGSS report one-time wealth tax revenue; Rauh reports an NPV net of permanently lost income
     tax. Proposed, to confirm before the bridge is built: report (a) gross one-time wealth tax
     revenue and (b) the net fiscal effect to the state (a, plus extra income tax from asset sales,
     minus the present value of lost income tax), with the loss horizon as an explicit dial, since
     that horizon is itself dispute 2.
   - **A bridge from Rauh to GGSS, with BSZ as a checkpoint.** One step per disputed input in
     `comparison/DISPUTES.md`, each labelled data / research / guesswork / scenario with
     provenance. Order dependence is handled by showing both orders or averaging over orders
     (Shapley). The Rauh anchor is the Monte Carlo mean (−$24.7B), not Table 9's central cell.
   - **The vintage gap stated:** Rauh March 2026 vs GGSS July / BSZ August 2026.

   **Confirmed by the user 2026-09-23, before any bridge numbers were computed:**
   - Output: BOTH (a) gross one-time wealth tax revenue and (b) the net fiscal effect, with the
     income-tax loss horizon as an explicit dial.
   - Direction: the bridge runs **GGSS to Rauh**, the same start and end as Hoopes (2026, SSRN
     6428578) Figure 2 (p.6), with BSZ as a checkpoint; step sizes are Shapley averages over orders,
     so the direction sets only the reading order. Rauh's NBER version enters as one extra step.
   - Prior comparison: Hoopes (2026) is cited as the existing comparison. His Figure 2 bars are
     digitized (labelled as read off the chart, since he prints no values) and shown beside our
     bridge, with every difference listed: exact step values, provenance labels, order dependence,
     vintage (he scores the earlier GGSS text: 213 billionaires, $2.18T, $109B to $99B, p.3 fn.1),
     his real-estate step is drawn near zero, which is consistent with his text: the ~$8B on p.4 is a
     cut in the taxable BASE, i.e. about $0.4B of revenue at 5% (corrected 2026-09-23; an earlier note
     here misread it as an inconsistency). His stated
     priors (p.2) and the acknowledgement to Gamage (p.1) are disclosed.
   - Layout: the reconciliation page is the **site root** (`index.html`, the kit's multi-OPA
     overview variant), linking to `bsz-analysis/site/` and `rjkdc-analysis/site/`.

**Decisions after the first build (user, 2026-09-23; no published number changed):**
1. Rauh output (a) defaults to the expected WT of each Monte Carlo: SSRN 51.26 (U[35, 67.51]),
   NBER 36 (U[0, 72]). These are the only choices consistent with the NPVs the bridge decomposes
   (residual 0). 45.59, 42 and "about 40" (SSRN) and "about 30" (NBER) stay visible as alternatives.
2. RJKDC explorer: q defaults to 1 (the code as shipped, MISMATCHES #5). The g dial keeps its
   non-zero levels 0.5% and 1%, labelled "(illustrative)" on the dial: they are this reproduction's,
   not the authors'.
3. Comparison-model calls accepted as disclosed: shared r range; non-citizens $150B (GGSS p.2 fn.1);
   the DISPUTES row 7 split; 10% avoidance as its own bridge step with no DISPUTES row; BSZ
   output (b) = 106.8 is our construction and labelled so.
4. The Rauh Monte Carlo input ranges (`rauh_mc_*`, `nber_mc_*`) live in the RJKDC export contract
   (`rjkdc-analysis/export/{r,py}/inputs.csv`, taken from the simulation functions' defaults),
   not in `comparison/data/document-inputs.csv`.
5. Naming (user, 2026-09-23): the two sides are called by their authors' initials, BSZ and
   RJKDC, in directory names (`bsz-analysis/`, `rjkdc-analysis/`), workflow names, CSV side keys
   (`bsz`, `rjkdc`, `neutral`), identifiers and prose. The words supporting and opposing appear
   only where a page explains which side is which.

**Same format as the previous OPA (user requirement 2026-09-23).** Every public surface (overview
page, interactive explorer, Quarto reproduction report, teaching deck, reproduction-materials links,
the OPA background image, the cross-link footer, the CRediT / AI-use table) is instantiated from the
shared kit at `~/Desktop/sandbox/opa-framework/template/`, which is extracted from
`opa-ai-macro-econ-scenarios`. The root reconciliation page uses the kit's multi-OPA overview variant.
Pages are not hand-built from scratch, and any departure from the kit goes back into the kit.

**Site layout (confirmed 2026-09-23):** the reconciliation page is the site root, linking to
`/bsz-analysis/` and `/rjkdc-analysis/`. **Blocker:** the root `.gitignore` ignores
`*.html` (only `README.html` is allowed back). This must be narrowed, for example to render
by-products only, before any site page is committed.

## Standing conventions (apply to all phases)

- **One git repo** at `~/Desktop/sandbox/opa-prop40`, no nested repos.
- **Sources are never committed.** Third-party PDFs, workbooks, SSRN files and anything
  extracted from them (CSV, `*.sqlite`) are gitignored. Each side's README records the source
  URL and SHA-256 instead. `.DS_Store` is already globally ignored; don't add it.
- **Every analysis runs in both R and Python** (later phases). Any step that manipulates a
  dataset of more than 1,000 rows goes through shared `.sql` files that both languages run
  verbatim. The files use the **SQLite** dialect and follow the house style of
  `~/Desktop/sandbox/courses/sql-industry-prep`, since the SQL is there to teach the user.
- **Commit messages**: no em-dash character anywhere. End each one with:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_019r1Nk1vkCPxkHmuokSVrx2
  ```
- **Shell**: zsh on macOS. cwd does NOT persist between Bash calls, so use absolute paths or
  `cd X && ...` in the same call. Quote `echo "==="`-style sentinels. Strip renv noise from
  Rscript output with `2>&1 | grep -vE "out-of-sync|renv|built under"`.

## Target layout after phase 1

```
opa-prop40/
├── README.md                  short: what the project is, layout, status, sources policy
├── PLAN.md                    this file
├── .gitignore                 root-level; see step 2
├── .github/workflows/bsz-ci.yml   R job: download the workbook, check SHA, tar_make, testthat
├── bsz-analysis/
│   ├── README.md, DESCRIPTION, _targets.R, report.qmd, R/, tests/, data-raw/, tools/
│   │                          (all from CAWT-BSZ, with history)
│   ├── sql/  py/  export/     empty placeholders with a one-line README each
│   ├── VERIFY-AUGUST.md       step 6 report
│   └── original-materials/    GITIGNORED
│       ├── BSZ26CAbillionaires.pdf          (August)
│       ├── BSZ_MainTablesFigures.xlsx       (August)
│       ├── additional-documentation/        (the six PDFs now in "additional documentation/")
│       └── may-2026/BSZ_MainTablesFigures.xlsx, BSZ26CAbillionaires.pdf   (from CAWT-BSZ)
├── rjkdc-analysis/
│   ├── README.md              placeholder: citation, SSRN URL, SHA-256, "phase 2"
│   └── original-materials/ssrn-6340778.pdf  GITIGNORED
└── comparison/README.md       placeholder
```

## Steps

1. **Stage the source files.** Move the files currently in `bsz-analysis/` and
   `rjkdc-analysis/` into the `original-materials/` folders above, renaming
   `additional documentation` to `additional-documentation`. Copy the May workbook and PDF from
   `~/Desktop/sandbox/CAWT-BSZ/original-materials/` into `bsz-analysis/original-materials/may-2026/`.
   Record the SHA-256 of every source file; they go in the READMEs.
   - May workbook: `cffe04bd...b7b1a`
   - August workbook: `c236cc94...cb6ce`

2. **`git init` and write the root `.gitignore`.** It must cover:
   - `**/original-materials/`, `*.sqlite`, `**/_targets/`
   - `.Rproj.user/`, `.Rhistory`, `.RData`, `*.Rproj`
   - quarto and render outputs
   - `__pycache__/`, `.pytest_cache/`

3. **Import CAWT-BSZ with history, minus the tracked binaries.** CAWT-BSZ's history TRACKS
   `original-materials/BSZ26CAbillionaires.pdf` and `original-materials/BSZ_MainTablesFigures.xlsx`,
   and they must not enter this repo's history.
   - Clone CAWT-BSZ to the scratchpad `/private/tmp/claude-502/-Users-fernando-Desktop-sandbox-opa-prop40/1ae2ecf0-51b8-494f-875e-fa154efbb874/scratchpad/cawt-filtered`.
     Never modify the original repo.
   - In the clone, run
     `git filter-branch --index-filter 'git rm -r --cached --ignore-unmatch original-materials' -- --all`,
     or use `git filter-repo` if it is installed.
   - Check with `git log --all --name-only | grep -iE '\.(pdf|xlsx)$'` that nothing is left.
   - Make an initial commit in opa-prop40 containing only `.gitignore` and `PLAN.md`. Then run
     `git subtree add --prefix=bsz-analysis <filtered-clone> main`. This needs
     `bsz-analysis/` to hold no TRACKED files; the gitignored `original-materials/` is fine.
     If subtree refuses because the directory exists, move `original-materials` out temporarily
     and back afterwards.
   - Confirm that `git log --oneline -- bsz-analysis | wc -l` shows the CAWT-BSZ commits.

4. **Make the workbook vintage selectable.**
   - The default path is `original-materials/BSZ_MainTablesFigures.xlsx` (August).
   - Setting the environment variable `BSZ_VINTAGE=may` points at `original-materials/may-2026/...`.
   - Implement this in the one place that defines the path (`_targets.R`'s `xlsx_path` and
     `R/`'s `xlsx_path_default()`). Keep it minimal, and make sure tests use the same helper.
   - Update the BSZ README:
     - Replace the "NOT redistributed" section with both vintages' SHA-256 and the fetch URL
       `https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx`.
     - Fix any wording that assumed the files were tracked.
   - Download that URL to the scratchpad and hash it, to confirm it now serves the August
     file. Report what it serves.
   - Add the three placeholder dirs and root/rjkdc/comparison READMEs. Commit.

5. **May baseline.** From `bsz-analysis/`, run
   `BSZ_VINTAGE=may Rscript -e 'targets::tar_make()'`, then the testthat suite.
   - It must be green, as it was in CAWT-BSZ. If it is not, the failure comes from the move
     (paths, working directory): fix it and commit.
   - Do NOT edit computation code in this step.
   - Report pass/fail counts.

6. **August re-verification: report only, no fixes.** Run `tar_make` and the tests with the
   August default. Write `bsz-analysis/VERIFY-AUGUST.md` containing:
   - Pipeline status: did every target build? Which errored, and with what message?
   - Per-derivation verification: for each `compute_*` / verify check, the number of cells
     compared, the number mismatched, and the largest absolute and relative error.
   - A classification of every mismatch group, with evidence. Each group is one of:
     - (a) **hard-coded row range or literal** that shifted (point to the R line);
     - (b) **formula logic changed** in the August workbook (quote the old and new Excel formula;
       read formulas with openpyxl without `data_only`, or with readxl);
     - (c) **input data change only** (should verify fine; if it shows as a mismatch, explain why);
     - (d) **snapshot test failure**. Expected, because the numbers changed. Do NOT regenerate
       snapshots.
   - Sheets new in August with no R code yet: `Fig9`, `2023-b-1__adjusted_gross_income`,
     `data_venturemonitor_annual`, `data_venturemonitor_quarterly`. Give a one-paragraph
     description of each, with its size and whether it has formulas.
   - Headline-number diff, May vs August, for Tab1-Tab5 and TabA1, taken from the workbooks'
     cached values: which cells moved and by how much.

   Commit the report.

7. **CI stub.** Add `.github/workflows/bsz-ci.yml`:
   - One job: ubuntu, `r-lib/actions/setup-r`, install the DESCRIPTION Imports, curl the
     workbook, check the August SHA-256, then run tar_make and testthat in `bsz-analysis/`.
   - Mark it clearly as expected to fail until the August fixes land, or skip snapshot tests
     under an env flag. Pick whichever is simpler and say which.
   - Nothing is pushed in phase 1; CI runs only after the main session creates the remote.

8. **Final safety check.** `git status --short` must be clean. Then
   `git log --all --name-only | grep -iE '\.(pdf|xlsx|sqlite)$'` must print nothing.

## Future: author-shared raw data

The user will ask both author teams (BSZ and Rauh et al.) for their raw data. Nothing has
arrived as of phase 1; phase 1 only prepares the slot.

- **(a) Folder and manifest convention.** Author-shared files go under
  `<side>/original-materials/author-shared/<YYYY-MM-DD>_<short-desc>/`, which sits under the
  already-gitignored `original-materials/`, so it and anything derived from it (CSVs,
  `*.sqlite`) are never committed. Every source file, whether public-downloaded, author-shared,
  or re-pulled, gets one row in the tracked `<side>/DATA-SOURCES.csv` manifest (columns: `file,
  side, provider, obtained_via, date_obtained, url_or_contact, sha256, terms, feeds, status`).
  See `bsz-analysis/DATA-SOURCES.md` for the full column definitions.
- **(b) One path-resolver per side.** A later pipeline reads every input through a single
  resolver function per side (the same role `xlsx_path_default()` plays now for `BSZ_VINTAGE`),
  so an author-shared file can replace a workbook-cached input at the exact stage it feeds
  without touching downstream code. This extends the vintage-switch idea: a future
  `BSZ_INPUTS=workbook|author` (or per-input equivalent) selects the source, and the resolver is
  the one place that knows the mapping from input name to file path, whatever its provenance.
  Keep the `BSZ_VINTAGE` switch built in phase 1 compatible with this: it is already a single
  resolver (`xlsx_path_default()` in `R/ingest_excel.R`, called from the one `xlsx_path`
  `tar_target`), not paths scattered across files, so extending it later means adding branches
  to that one function, not touching call sites.
- **(c) `export/inputs.csv` provenance column.** When the `export/inputs.csv` contract is built
  in a later phase, add a `provenance` column (`public` | `author-shared` | `derived`) alongside
  the existing data/research/guesswork label, sourced from each input's `DATA-SOURCES.csv` row.
- **(d) CI must not depend on author-shared data.** Author-shared files cannot be fetched by CI
  (they aren't public, and may be under restrictive terms). Any test that depends on one must
  skip cleanly (not fail) when the file is absent, so CI stays green regardless of what has or
  hasn't been shared yet.

## Out of scope for phase 1

- Creating a GitHub remote or pushing.
- Fixing August mismatches or regenerating snapshots.
- Python, SQL, Rauh, the comparison layer, and the website.
- Modifying `~/Desktop/sandbox/CAWT-BSZ` in any way.
