# Content map: what the Prop 40 OPA publishes, and where each piece lives

For reviewers (what to read, in what order, with which tool) and implementers (where an edit
goes, and what has to be rebuilt afterwards). Paths are relative to the repository root.

## The project in one paragraph

An Open Policy Analysis (OPA) of the two rival revenue analyses of California's 2026
Proposition 40, the Billionaire Tax Act (a one-time 5% tax on the whole net worth of Californians
worth $1 billion or more).
The BSZ analysis (Boll, Saez and Zucman, NBER Working Paper 35218, August 2026, with the
Galle, Gamage, Saez and Shanske expert report of July 2026) estimates about $100 billion. The
JR analysis (Jaros and Rauh, NBER chapter c15504, September 2026, revising the SSRN March 2026
version by Rauh, Jaros, Kearney, Doran and Cosso) estimates a net present value to the state of about
-$39 billion. Each analysis is reproduced in full and published as an OPA site with three
layers: Open Output (an explorer over a precomputed grid, the main estimate highlighted), Open
Analysis (a reproduction report and a slide deck) and Open Materials (the repository). A third
site, the comparison, puts both on one common output definition and bridges the gap one
disputed input at a time. `PLAN.md` fixed the output definition before any comparison result;
`AUDIT.md` scores every page against the OPA Guidelines' nine steps.

Live site (rebuilt from `main`, may lag the working tree): https://fhoces.github.io/opa-prop40/
with `bsz-analysis/site/`, `rjkdc-analysis/site/` and `comparison/site/explorer/` under it.
Review the files in the working tree, not the live site.

## Reading order for a reviewer

1. The three overviews: `index.html` (the comparison, the site root), `bsz-analysis/site/index.html`,
   `rjkdc-analysis/site/index.html`.
2. The three explorers: `comparison/site/explorer/index.html`, `bsz-analysis/site/explorer/index.html`,
   `rjkdc-analysis/site/explorer/index.html`. Their headline numbers and panels are filled by
   JavaScript from a data file, so read them rendered (see "How to read a page").
3. The three reports: `*/site/repro.html` rendered (the numbers are computed at render time and
   appear only there); `*/site/repro.qmd` for the source text and the code folds.
4. The two decks: `bsz-analysis/site/slides/slides.Rmd`, `rjkdc-analysis/site/slides/slides.Rmd`
   (the `.html` next to each is the rendered deck).
5. The three materials pages: `*/site/materials.html` rendered, `*/site/materials.qmd` source.
6. The READMEs: `README.md`, `bsz-analysis/README.md`, `rjkdc-analysis/README.md`, `comparison/README.md`.
7. The records: `comparison/DISPUTES.md` (the eight disputed inputs), `rjkdc-analysis/MISMATCHES.md`
   (where the reproduction and the authors' numbers differ), `bsz-analysis/VERIFY-AUGUST.md`,
   `AUDIT.md`, `PLAN.md` (the pre-specified output and every decision), `review/README.md`
   (the code review ledgers), `*/site/credit/CREDIT.md` (the CRediT and AI-use answers),
   `docs/initiative/README.md` (the ballot measure).
8. The labelled inputs: `bsz-analysis/site/data/inputs.csv`, `rjkdc-analysis/export/r/inputs.csv`,
   `comparison/data/document-inputs.csv`, `comparison/export/r/inputs.csv`; and the source
   manifests `*/DATA-SOURCES.csv`.

Code is there to verify a claim (`grep` a number across the tree, read the function a page
names), not to review for its own sake.

## How to read a page

- `python3 .claude/skills/opa-review-loop/tools/page_text.py <file.html>`: the static text of
  a page, headings and footnotes kept, scripts and styles dropped. Right for the overviews,
  the reports and the materials pages.
- `node .claude/skills/opa-review-loop/tools/screenshot.cjs <file.html> --text`: the text as a
  browser renders it, after the page's JavaScript has run. Needed for the explorers and the
  headline blocks, which read their numbers from `grid.js` or `comparison-data.js`.
- `node .claude/skills/opa-review-loop/tools/screenshot.cjs <file.html> --out <png> --width 390`
  (phone) or `--width 1280` (desktop), `--full` for the whole page: a screenshot to look at
  with the Read tool. Needs Playwright; the script says so and exits if it is missing.
- The decks are xaringan (remark.js) slides: read the `.Rmd`; `---` separates slides.
- Quarto reports: the `.qmd` has the prose and the code; the `.html` has the numbers.

## Every public file, and whether it is a source

Legend. Source: edit it directly. Generated: never edit by hand; edit its source and rebuild
with the command given. Record: the author's own record, read for context, not edited by the
loop. Read-only: kept untouched by decision (PLAN-5).

### Cross-cutting

| File | Kind | Notes |
|---|---|---|
| `README.md` | source | the repository's front page on GitHub |
| `index.html` | generated | the comparison overview and the site root; from `comparison/site/index.template.html` by `comparison/R/site.R`; rebuild `Rscript comparison/run.R` |
| `assets/comparison-data.js` | generated | the numbers the root page and the comparison explorer read; same rebuild |
| `assets/opa/*.png` | source | the OPA layer images |
| `PLAN.md` | record | the pre-specified output and the decisions; only its "kept current" sections change, dated |
| `PLAN-2-*.md`, `PLAN-4-*.md`, `PLAN-5-*.md` | record | phase plans; PLAN-5 defines the shared page shape |
| `AUDIT.md` | source | the OPA Guidelines audit; update the evidence when a change moves a step |
| `docs/initiative/` | record | the measure's text (PDF) and a README |
| `review/*.json`, `review/README.md` | record | code review ledgers; `README.md` is rendered by `python3 review/render.py`; the loop does not edit them |
| `feedback/` | this loop | one directory per run |
| `.github/workflows/*.yml` | source | CI; the comparison workflow checks that the committed generated pages equal the generator's output |

### The BSZ analysis, `bsz-analysis/`

| File | Kind | Notes |
|---|---|---|
| `README.md` | source | the lines between `<!-- include:_raw-sources.md -->` and `<!-- /include -->` are a copy of `_raw-sources.md`: edit the partial and run `tools/sync-readme.sh` |
| `site/index.html` | source | the overview; hand-written HTML; the headline value is read from `site/explorer/grid.js` by script, never retyped |
| `site/explorer/index.html` | source | the explorer, hand-written HTML and JavaScript over `grid.js` |
| `site/explorer/grid.js` | generated | by `R/site_exports.R` inside the `{targets}` pipeline; `tests/testthat/test-site.R` checks the committed file byte for byte |
| `site/repro.qmd` | source | the reproduction report; rendered to `site/repro.html` by `quarto render site/repro.qmd` from `bsz-analysis/`, which needs the pipeline's outputs (the workbook in `original-materials/`, then `targets::tar_make()`) |
| `site/repro.html` | generated | the rendered report |
| `site/materials.qmd` | source | the materials page; `quarto render site/materials.qmd` |
| `site/materials.html` | generated | |
| `site/slides/slides.Rmd` | source | the deck (xaringan); `Rscript -e 'rmarkdown::render("bsz-analysis/site/slides/slides.Rmd")'` |
| `site/slides/slides.html` | generated | |
| `site/data/*.csv` | generated | the explorer's and the overview's tables |
| `site/credit/CREDIT.md`, `site/credit/credit-answers.json` | read-only | the author's questionnaire answers |
| `VERIFY-AUGUST.md`, `DATA-SOURCES.csv`, `DATA-SOURCES.md`, `_raw-sources.md` | source | records of the reproduction and of every source file |
| `export/r/*.csv`, `export/py/**` | generated | the export contract the comparison reads |
| `R/`, `py/`, `sql/`, `tests/`, `_targets.R` | code | the reproduction; not a content edit |

### The JR analysis, `rjkdc-analysis/`

Same shape as BSZ: `README.md` (source, no include block), `site/index.html` and
`site/explorer/index.html` (source), `site/explorer/grid.js` and `site/data/*.csv` (generated
by `R/site.R`), `site/repro.qmd` and `site/materials.qmd` (source; `quarto render site/repro.qmd`
from `rjkdc-analysis/`; the report needs `RAUH_REPO_DIR` set to a clone of the authors'
repository at the pinned commit), `site/slides/slides.Rmd` (source), `site/credit/` (read-only),
`MISMATCHES.md` and `DATA-SOURCES.csv` (source), `export/` (generated), `R/`, `py/`, `tests/` (code).

### The comparison, `comparison/`

| File | Kind | Notes |
|---|---|---|
| `README.md` | source | |
| `site/index.template.html` | source | the root page's template: prose plus `{{tokens}}` that `R/site.R` fills; its output is `index.html` at the root |
| `site/explorer.template.html` | source | the comparison explorer's template; output `site/explorer/index.html` |
| `site/explorer/index.html` | generated | `Rscript comparison/run.R`; `tests/testthat/test-site.R` checks it equals the generator's output |
| `site/explorer/model.js` | source | the estimating function in JavaScript; `test-site.R` checks it against R on a sample of slider mixes (needs `node`) |
| `site/repro.qmd`, `site/materials.qmd` | source | `quarto render repro.qmd` and `quarto render materials.qmd` from `comparison/site/` |
| `site/repro.html`, `site/materials.html` | generated | |
| `site/credit/CREDIT.md` | read-only | |
| `DISPUTES.md` | source | the eight disputed inputs, each with both analyses' values and sources |
| `data/document-inputs.csv` | source | values transcribed from the PDFs, with page; `data/hoopes-fig2.csv` digitized from a chart |
| `DATA-SOURCES.csv` | source | |
| `export/r/*.csv`, `export/py/*.csv` | generated | by `R/build.R` and `py/bridge.py` |
| `R/`, `py/`, `tests/`, `run.R` | code | |

## Rules for an edit

1. A source file: edit it. A generated file: edit its source. A record or a read-only file:
   leave it; if a finding needs it changed, say so in the report for the author.
2. The comparison's generated pages (`index.html`, `comparison/site/explorer/index.html`) when
   R is not available: edit the template, then make the identical edit in the generated file,
   keeping the filled values where the template has `{{tokens}}`, so the published page and
   the template agree. The author's `Rscript comparison/run.R` must then reproduce the file
   byte for byte; `needs_render.py` lists it.
3. A Quarto page or a deck when Quarto or R is not available: edit the `.qmd` or `.Rmd` only.
   Do not hand-edit the rendered `.html`; the next render overwrites it. The rendered page lags
   until the author renders; `needs_render.py` lists it.
4. Never retype a number a page reads from a data file, and never change a number anywhere
   without the generator that produces it. A wrong number is a finding for the author, not an
   edit.
5. A shared element (the headline block, the three layer cards, the site-nav line, the footer,
   the README top, the credit fold: see `PLAN-5-match-bsz.md`, "Lessons from the BSZ
   analysis") is the same on all three sites. A wording change to one goes to all three, and
   the report notes it as a change to the shared kit.
6. Prose style: plain sentences, no em dashes or en dashes in prose (commas, colons and
   parentheses instead; the minus sign in a formula stays as the page has it); "the BSZ
   analysis" and "the JR analysis", never "side"; "supporting" and "opposing" only where a
   page explains which analysis is which; the authors by their initials as the pages do;
   numbers as the pages print them ($106.8B in a headline block, $106.8 billion in prose);
   dates as `2026-10-14` in records and "September 2026" in prose; the spelling the page
   already uses.
7. HTML pages: the hand-written ones use the page's own markup for footnotes, tables and
   folds; copy it. No new frameworks, fonts or external scripts.

## Rebuild and test commands (local machine)

```
Rscript comparison/run.R                       # root index.html, comparison explorer, data file, exports
Rscript comparison/tests/testthat.R            # comparison suite (needs node for the model.js parity test)
cd comparison/site && quarto render repro.qmd && quarto render materials.qmd
cd bsz-analysis && Rscript -e 'targets::tar_make()' && Rscript tests/testthat.R   # needs the workbook in original-materials/
cd bsz-analysis && quarto render site/repro.qmd && quarto render site/materials.qmd
Rscript -e 'rmarkdown::render("bsz-analysis/site/slides/slides.Rmd")'
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript -e 'targets::tar_make()' && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R
cd rjkdc-analysis && quarto render site/repro.qmd && quarto render site/materials.qmd
Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'
bsz-analysis/tools/sync-readme.sh              # after editing bsz-analysis/_raw-sources.md
python3 review/render.py                       # after editing review/*.json
python3 .claude/skills/opa-review-loop/tools/check_links.py
```
