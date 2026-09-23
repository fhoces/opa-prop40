# opa-prop40: plan, phase 1 (repo skeleton + BSZ import + August re-verification)

Project: an Open Policy Analysis (OPA) of the two rival revenue analyses of California's 2026
Proposition 40 (the Billionaire Tax Act, a one-time 5% tax on net worth above $1bn).

- Supporting: Boll, Saez & Zucman (BSZ), NBER WP 35218, May 2026 revised August 2026, with
  an Excel workbook `BSZ_MainTablesFigures.xlsx`.
- Opposing: Rauh, Jaros, Kearney, Doran & Cosso, Hoover Institution, 17 March 2026
  (SSRN 6340778). PDF only.

The end state is one private repo: a full OPA for each side, plus a comparison layer that puts
both on one input-to-output chain. **Phase 1 covers only the steps below.** No Python twin, no
SQL files, no Rauh work and no website yet.

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
├── .github/workflows/ci.yml   R job: download the workbook, check SHA, tar_make, testthat
├── supporting-analysis/
│   ├── README.md, DESCRIPTION, _targets.R, report.qmd, R/, tests/, data-raw/, tools/
│   │                          (all from CAWT-BSZ, with history)
│   ├── sql/  py/  export/     empty placeholders with a one-line README each
│   ├── VERIFY-AUGUST.md       step 6 report
│   └── original-materials/    GITIGNORED
│       ├── BSZ26CAbillionaires.pdf          (August)
│       ├── BSZ_MainTablesFigures.xlsx       (August)
│       ├── additional-documentation/        (the six PDFs now in "additional documentation/")
│       └── may-2026/BSZ_MainTablesFigures.xlsx, BSZ26CAbillionaires.pdf   (from CAWT-BSZ)
├── opposing-analysis/
│   ├── README.md              placeholder: citation, SSRN URL, SHA-256, "phase 2"
│   └── original-materials/ssrn-6340778.pdf  GITIGNORED
└── comparison/README.md       placeholder
```

## Steps

1. **Stage the source files.** Move the files currently in `supporting-analysis/` and
   `opposing-analysis/` into the `original-materials/` folders above, renaming
   `additional documentation` to `additional-documentation`. Copy the May workbook and PDF from
   `~/Desktop/sandbox/CAWT-BSZ/original-materials/` into `supporting-analysis/original-materials/may-2026/`.
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
     `git subtree add --prefix=supporting-analysis <filtered-clone> main`. This needs
     `supporting-analysis/` to hold no TRACKED files; the gitignored `original-materials/` is fine.
     If subtree refuses because the directory exists, move `original-materials` out temporarily
     and back afterwards.
   - Confirm that `git log --oneline -- supporting-analysis | wc -l` shows the CAWT-BSZ commits.

4. **Make the workbook vintage selectable.**
   - The default path is `original-materials/BSZ_MainTablesFigures.xlsx` (August).
   - Setting the environment variable `BSZ_VINTAGE=may` points at `original-materials/may-2026/...`.
   - Implement this in the one place that defines the path (`_targets.R`'s `xlsx_path` and
     `R/`'s `xlsx_path_default()`). Keep it minimal, and make sure tests use the same helper.
   - Update the supporting README:
     - Replace the "NOT redistributed" section with both vintages' SHA-256 and the fetch URL
       `https://eml.berkeley.edu/~saez/BSZ_MainTablesFigures.xlsx`.
     - Fix any wording that assumed the files were tracked.
   - Download that URL to the scratchpad and hash it, to confirm it now serves the August
     file. Report what it serves.
   - Add the three placeholder dirs and root/opposing/comparison READMEs. Commit.

5. **May baseline.** From `supporting-analysis/`, run
   `BSZ_VINTAGE=may Rscript -e 'targets::tar_make()'`, then the testthat suite.
   - It must be green, as it was in CAWT-BSZ. If it is not, the failure comes from the move
     (paths, working directory): fix it and commit.
   - Do NOT edit computation code in this step.
   - Report pass/fail counts.

6. **August re-verification: report only, no fixes.** Run `tar_make` and the tests with the
   August default. Write `supporting-analysis/VERIFY-AUGUST.md` containing:
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

7. **CI stub.** Add `.github/workflows/ci.yml`:
   - One job: ubuntu, `r-lib/actions/setup-r`, install the DESCRIPTION Imports, curl the
     workbook, check the August SHA-256, then run tar_make and testthat in `supporting-analysis/`.
   - Mark it clearly as expected to fail until the August fixes land, or skip snapshot tests
     under an env flag. Pick whichever is simpler and say which.
   - Nothing is pushed in phase 1; CI runs only after the main session creates the remote.

8. **Final safety check.** `git status --short` must be clean. Then
   `git log --all --name-only | grep -iE '\.(pdf|xlsx|sqlite)$'` must print nothing.

## Out of scope for phase 1

- Creating a GitHub remote or pushing.
- Fixing August mismatches or regenerating snapshots.
- Python, SQL, Rauh, the comparison layer, and the website.
- Modifying `~/Desktop/sandbox/CAWT-BSZ` in any way.
