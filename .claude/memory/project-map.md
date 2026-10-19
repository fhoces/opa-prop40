---
name: project-map
description: How every piece of opa-prop40 fits together, from the two analyses' sources to the comparison site, the survey experiment and the review machinery; read before working across parts
metadata:
  type: project
---
# Project map: how the pieces of opa-prop40 fit together

Written 2026-10-19, the day the survey experiment launches. `.claude/skills/opa-review-loop/CONTENT-MAP.md`
lists every public file and its rebuild command; this note is the level above it: what feeds what,
and where a task starts. Paths are relative to the repository root.

## One paragraph

An Open Policy Analysis (OPA) of the two rival revenue analyses of California's Proposition 40, a
one-time 5% tax on Californians worth $1 billion or more. The BSZ analysis (Boll, Saez and Zucman,
NBER Working Paper 35218, August 2026) is reproduced cell by cell from the authors' workbook. The
JR analysis (Jaros and Rauh, NBER chapter c15504, September 2026; the folder keeps the old name
`rjkdc-analysis/`) is reproduced from the authors' public repository at a pinned commit. The
comparison puts both on one output definition, the net fiscal effect to the state, and walks from
the BSZ values to the JR values one disputed input at a time. Each of the three has an OPA site
with three layers (Open Output: an explorer; Open Analysis: a report and a deck; Open Materials:
the repository and a materials page), all built from one shared kit. A survey experiment asks
readers which of the two values of each disputed input is more credible and randomizes whether
the form names the studies. Everything is public at https://fhoces.github.io/opa-prop40/, served
by GitHub Pages from `main`.

## The chain from sources to pages

1. **Sources, never committed.** The BSZ workbook is fetched by URL and checked by SHA-256
   (`bsz-analysis/DATA-SOURCES.csv`; CI fetches it). The JR authors' repository `bjaros20/wealth_tax`
   is cloned at commit 25e84dd (`RAUH_REPO_DIR`). Values transcribed from the PDFs sit in
   `comparison/data/document-inputs.csv` with page numbers. The Act's text is the one PDF that is
   committed (`docs/initiative/`, a public record).
2. **Two reproductions.** `bsz-analysis/` and `rjkdc-analysis/` are each an R `{targets}` pipeline
   with a Python twin and a test suite that compares the two and compares both with the authors'
   printed results. The BSZ twin also has SQL. Each pipeline writes its site data (`site/data/*.csv`,
   `site/explorer/grid.js`, the precomputed grid the explorer reads) and its **export contract**,
   `export/r/{inputs,outputs}.csv`, the only files the comparison reads from it. Every input carries
   an origin label (data, research, guesswork, scenario, derived, convention) and a basis.
3. **The comparison.** `comparison/R/model.R` is the common estimating function (the JavaScript
   twin `comparison/site/explorer/model.js` is tested against it); `comparison/R/build.R` and
   `comparison/py/bridge.py` evaluate it at both analyses' inputs and along the dial path
   (`DIAL_PATH_ORDER`, nine steps, the equation's order), with a Shapley decomposition as an
   order-free check. Outputs: `comparison/export/{r,py}/{bridge,dial_path,inputs}.csv`.
   `comparison/DISPUTES.md` is the human record of the ten disputed inputs with both values and
   sources.
4. **The site generator.** `comparison/R/site.R` fills `comparison/site/index.template.html` and
   `explorer.template.html` with the exports and writes `index.html` (the site root), the comparison
   explorer, `assets/comparison-data.js`, and the survey share page
   `comparison/site/survey/index.html`. `Rscript comparison/run.R` runs steps 3 and 4. The dial
   texts (`slider_tips`), the equation's term names and the explorer's wording live in `site.R`; since
   run 010 they follow the survey's approved wording, and `mock_forms.py` reads the same export cells
   so the pages and the forms print the same numbers.
5. **The other pages.** Reports and materials pages are Quarto (`*/site/*.qmd`, rendered to `.html`
   next to them, numbers computed at render time); decks are xaringan (`*/site/slides/slides.Rmd`).
   The overviews and explorers of the two analyses are hand-written HTML that reads its headline
   from `grid.js`. Every page shares the kit's elements (headline block, layer cards, two-row nav
   line, footer, credit fold); the kit is `../opa-framework/template/` on the author's machine, and a
   change to a shared element goes to all three sites and back into the kit.
6. **Publication.** A push to `main` deploys Pages. Three CI workflows rebuild each part on a clean
   runner on every change to its folder; the comparison workflow also fails if the committed
   `index.html` is not what the generator writes.

## The survey experiment

- **Design.** Two arms (control: values labelled A and B, no comparison page; treatment: values
  labelled BSZ and JR, with the page "How the two estimates differ"), two entry points as strata
  (`explorer`: the buttons on the comparison explorer and the overview; `share`: the share page
  `comparison/site/survey/` that posts and emails carry). Google Forms cannot randomize, so the
  draw is `Math.random() < 0.5` in the browser at the click (`survey_draw_js()` in `site.R`) or at the
  share page's load. Six forms exist; forms 1 and 2 (a dropped `landing` entry point) are never
  opened, 3 and 4 are the explorer pair, 5 and 6 the share pair.
- **The forms.** `comparison/survey/gas_build.py` writes the Apps Script that builds them;
  `comparison/survey/mock_forms.py` holds every question's wording and the treatment page's text,
  generated from the comparison exports (no typed number). `comparison/survey/plan/forms/{control,
  treatment}.json` are exact copies of the live forms and the reference wording for every page that
  names an input. The forms are live and are not edited after launch.
- **The plan.** `comparison/survey/PRE-ANALYSIS-PLAN.md` is the source of truth (registered on the
  AEA RCT Registry, trial 19997). `zsh comparison/survey/plan/build.sh` turns it into `plan.pdf`
  through pandoc, `plan.tex` and the two forms' PDFs (`print_forms.py`, Chrome). The power appendix
  is `comparison/survey/power/power.tex` with every number from `sim.py` (`out/*.tex`, `latexmk`).
  `registry-draft.md` mirrors the plan in the registry's fields. Section 9 of the plan holds the
  launch sequence; section 11 the dated decisions; the two pretests with language-model respondents
  are `feedback/008-2026-10-17-rct-pilot/` and `feedback/009-2026-10-17-rct-pilot-2/`.
- **The wiring at launch.** `comparison/data/survey-links.csv` (four rows, entry and arm, filled by
  `fill_links.py` from the builder's log) and `survey-config.csv` (`draws_url`, the Apps Script web
  app `draws.gs` that appends one row per draw: timestamp, entry, arm). `Rscript comparison/run.R`
  then puts the links and the draw beacon on the pages. Until the real links are pushed the file
  holds placeholders (the two old forms), which is what the live site shows on launch day.
- **After the close** (4 November 2026, 23:59 Pacific). `comparison/survey/pilot_analysis.py` is the
  analysis code (being brought in line with the plan in review 012). `sim.py` is rerun once with the
  realized subgroup shares to set the staged thresholds. The responses are published without the
  email column and the free text.

## The quality machinery

- **Tests.** Each part's `tests/testthat/` suite: reproduction against the authors' numbers, R
  versus Python parity (numbers only), and `test-site.R`, which pins literal strings on the pages
  and checks generated files byte for byte. Grep the suite before editing a sentence on a page.
- **Records.** `PLAN.md` fixed the output definition before any result and logs every later
  decision with its date. `AUDIT.md` scores each page against the OPA Guidelines' nine steps.
  `review/*.json` (rendered to `review/README.md`) are the code-review ledgers, one chain per main
  estimate. `feedback/DECISIONS.md` lists what the review loop settled as won't do.
- **The review loop.** `.claude/skills/opa-review-loop/` (`/opa-review-loop`): three reviewers (the
  original authors, outside policy experts, California voters), a coordinator, implementers, a
  final review; one directory per run under `feedback/NNN-date/`. Reviews 011 (the plan, four
  lenses) and 012 (the final review) use the same folder scheme without the loop.
- **Tools.** `tools/page_text.py` (static text of a page), `tools/screenshot.cjs` (rendered text
  and screenshots through Playwright), `tools/check_links.py` (internal links), `tools/needs_render.py
  <commit>` (which generated pages the changes since that commit require rebuilding).

## How the author and the sessions work

The author runs a local Claude Code session on `main` with R, Quarto, LaTeX and Chrome, and cloud
sessions on branches. The cloud has no R or Quarto: it edits sources, hand-mirrors the two
comparison generated pages, and leaves a handoff file in the run's folder; the local session merges
the branch (fast-forward) and rebuilds. The author's local `main` is often ahead of `origin/main`
until pushed, so a cloud session fetches `origin/main` before branching and checks CI on `main`
through the GitHub tools. Commits go by path (a stop hook refuses idle turns with uncommitted
files), never `git add -A` while agents edit. Prose rules everywhere: no em or en dash, short
sentences, "the BSZ analysis" and "the JR analysis", JR in prose and rjkdc only in paths and keys.

## Where a task starts

| Task | Start here |
|---|---|
| A number on a page looks wrong | the export that feeds it (`*/export/r/`, `comparison/export/r/`), then the pipeline; never the page |
| A dial's text or the equation's wording | `comparison/R/site.R` (`slider_tips`, the term names), then `Rscript comparison/run.R`, then the pinned strings in `comparison/tests/testthat/test-site.R` |
| An overview or explorer sentence of an analysis | `*/site/index.html` or `*/site/explorer/index.html` (hand-written) |
| A report or materials sentence | the `.qmd`; the author renders |
| A deck slide | `*/site/slides/slides.Rmd`; the author renders |
| The survey's wording | not editable after launch; a finding for the author; the plan's deviations log |
| The plan | `comparison/survey/PRE-ANALYSIS-PLAN.md`, then `build.sh`; a change after registration is a logged deviation |
| A new disputed input | `comparison/DISPUTES.md`, `comparison/R/model.R`, both exports, the explorer, the tests |
| What was already decided | `feedback/DECISIONS.md`, `PLAN.md` "Decisions after the first build", the plan's section 11 |
