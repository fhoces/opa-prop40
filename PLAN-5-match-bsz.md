# Plan 5: bring the RJKDC analysis and the comparison up to BSZ's shape

Written 2026-10-14 after a review of the BSZ analysis (overview, explorer, report, slides,
repository, review chain). The BSZ analysis is the reference. Two agents implement this plan:
agent A does Part A (RJKDC), agent B does Part B (comparison). Part C lists the rules both
follow. Decisions taken with the author on 2026-10-14:

- The RJKDC headline is the NBER September 2026 number alone (mean NPV -38.9). The SSRN
  March 2026 estimate stays as a scenario in the explorer and as the comparison page's anchor.
- The comparison gets three layers with a report and a materials page, no slides.
- Both analyses get a review chain on the code review page, linked first in the README.
- The credit section stays on both overview pages with a blank table; the credit files are
  kept untouched.

## Lessons from the BSZ analysis (what "the same shape" means)

Each lesson names the BSZ file that shows it. Read that file before writing the matching one.

1. **One number up top, everywhere.** The overview (`bsz-analysis/site/index.html`, the
   `.headline` block after the header), the explorer header (`bsz-analysis/site/explorer/index.html`,
   `.headline` inside `<header>`), the README and the review page all show the same block: an
   uppercase label ("Main estimate¹, base scenario"), the value in 40px serif, one definition
   line starting "Defined as", and a footnote that says whose choice the number is. The overview
   and the explorer read the value from the generated data file (`explorer/grid.js`), never
   retyped.
2. **The title names the analysis.** "California Proposition 40, Analysis From Boll, Saez,
   Zucman (BSZ)" with the "Work in progress" pill. Eyebrow "Open Policy Analysis for:".
3. **Three cards with fixed wording.** Section title "Three layers to understand the analysis"
   with the `opa-all.png` icon. Cards: Open Output "Explore the main estimate and its
   assumptions →"; Open Analysis with a one-line lead and two subcards "The reproduction
   report →" and "Slides →"; Open Materials "Materials for computational reproduction →"
   (links the folder on GitHub). Each card has the matching layer icon on the right.
4. **Three folds below the cards.** "What the model says", "What reproduces", "How AI was used
   in this exercise, and what has been verified". The credit table shows two-dot meters only;
   the words not reviewed / lightly reviewed / reviewed appear only in the legend and in the
   paragraph under it.
5. **Explorer header.** A `site-nav` line ("<analysis>: Open Output (here) · Open Analysis: Report
   and Slides · Open Materials · Overview"), then a flex header: title and standfirst on the
   left, the headline block on the right with the faded layer icon above it. On narrow screens
   the block stacks under the standfirst and the icon goes back behind the title. The headline
   label changes with the dial setting ("Main estimate¹, <scenario>"); the value is the current
   cell's. The footnote under the bars keeps only the "whose choice" sentence.
6. **Footer on every page.** "Part of opa-prop40, an Open Policy Analysis of both analyses of
   California Proposition 40 (the Billionaire Tax Act). <Analysis> overview." then
   "OPA done by Fernando Hoces de la Guardia, using agentic coding tools" (link to the
   overview's `#how-ai-was-used`).
7. **README top** (`bsz-analysis/README.md`, everything above "## The reproduction"): H1
   "<Analysis> of California Proposition 40: Open Materials"; an intro paragraph whose first link
   opens the analysis's overview page and whose second sentence links the comparison overview; a
   `###` heading that is the review page link ("Review the code behind the <number>") with a
   one-sentence gloss and a link to `review/`; the Materials layer image with the wordmark
   floated right (`site/assets/opa/opa-materials-wordmark.png`, copy it from BSZ); "1 -", "2 -",
   "3 -" paragraphs for Open Output, Open Analysis, Open Materials, each with its live link and
   "Materials can be found in" its folder; a sentence linking the analysis overview and the
   comparison overview; the OPA Guidelines sentence linking `AUDIT.md`; `<br clear="right">`.
   The rest of the old README follows under "## The reproduction".
8. **The report** (`bsz-analysis/site/repro.qmd`): title "Prop 40, <analysis>: the reproduction";
   never retypes a number (reads the pipeline's outputs); each exhibit has a fold showing the R
   code and the Python twin (the fold mechanism is in the setup chunk, lines 37-125); the
   headline number is derived step by step in its own section.
9. **Materials page** (`bsz-analysis/site/materials.qmd`): sections "Rebuild everything",
   "Tests", "Scripts", "Data files the site publishes", "Sources", "What the checks found".
10. **Slides** (`bsz-analysis/site/slides/slides.Rmd`): xaringan, every number read from the
    pipeline's CSVs, a "Deck Map" slide, parts. The RJKDC deck already follows this; only its
    card wording changes. The comparison gets no deck.
11. **Review chain** (`review/seed_bsz.py`, `review/bsz.json`): six to eight layers from the
    number on the page down to the raw source, each with `what`, `inputs_from` (with `tokens`
    and `source_tokens` for code colouring), `other_inputs`, `outputs` with the value at HEAD,
    `method_ref`, `method_status`, `r` and `py` locations (`loc()` reads the snippet from disk),
    `targets`, an `interactive` snippet per language, and a chain-level `environment` {r, py}.
    The last compute layer must reproduce the headline, and the seed script states the command
    that confirmed it. The chain doc's `opa` field is `rjkdc` or `comparison` (the page's nav
    map uses those keys). `python3 review/render.py` regenerates `review/README.md`.
12. **Verification labels.** Not reviewed, lightly reviewed, reviewed. Nothing says "understood"
    any more except dated amendment notes.
13. **Language rules.** No em-dashes anywhere (pages, qmd, README, commit messages). Repo
    coinages get a gloss at first use ("export contract", "targets", "dial"). Short sentences.

## Part A: the RJKDC analysis (agent A, works in the main working tree)

Headline: NBER September 2026 mean NPV, printed -38.9, reproduction -38.886
(`site/explorer/grid.js` `preferred[key=="nber"]`, `site/data/headlines.csv`). Label
"Main estimate¹, NBER September 2026". Definition: "Defined as the one-time wealth tax
revenue minus the present value of California income tax lost for ever to billionaires who
leave (NPV = WT − f·C / r), averaged over the authors' Monte Carlo draws." Footnote 1: the
authors' latest version (Jaros and Rauh, NBER c15504); their first version (Rauh et al., SSRN,
March 2026) put it at -24.7 and remains a scenario in the explorer and the anchor of the
comparison page.

1. **Overview** `rjkdc-analysis/site/index.html`: title "California Proposition 40, Analysis
   From Rauh, Jaros, Kearney, Doran, Cosso (RJKDC)"; headline block after the header reading
   both numbers from `explorer/grid.js` (copy the BSZ script, adapt the keys); section title
   "Three layers to understand the analysis"; card wording per lesson 3 (the RJKDC card texts
   can keep their own descriptions under the new headers); "What the model says" reworded so
   the NBER number is the main estimate and the SSRN one the earlier version (the "two
   estimates side by side" sentence goes); credit table blank per Part C; meters only.
2. **Explorer** `rjkdc-analysis/site/explorer/index.html`: header per lesson 5 with the
   headline block (NBER preferred cell by default; label follows the selected preset: "Main
   estimate¹, NBER September 2026", "SSRN March 2026 (the earlier version)", "a setting the
   authors did not publish"); the two preferred cards stay below as "Both versions, side by
   side" or fold into the outcomes table, agent's call, but the page opens on the NBER setting;
   footnote per the headline; footer per lesson 6; `site-nav` per lesson 5. Keep
   `test-site.R` green (it pins the preferred cells, the dial origins and every typed number
   on the landing page: update its expectations where the wording changes, never loosen the
   numeric checks).
3. **Report** `site/repro.qmd`: title "Prop 40, RJKDC analysis: the reproduction"; a short section
   at the top that derives the headline (-38.9) step by step from the pipeline's targets, the
   way BSZ's Table 5 section does; keep the rest. Re-render `repro.html` and `materials.html`
   (quarto 1.9 is installed; the targets store is in `_targets/`).
4. **Materials page** `site/materials.qmd`: section names per lesson 9 (keep the mismatches
   section at the end as "What the checks found").
5. **README** `rjkdc-analysis/README.md`: top per lesson 7; the review link points at the
   review page (https://claude.ai/artifact/6VZEezoAsCNACjmgPLEvah) and names the chain
   ("Review the code behind the -$38.9 billion main estimate"); copy the wordmark image into
   `rjkdc-analysis/site/assets/opa/`.
6. **Review chain**: write `review/seed_rjkdc.py` from `review/seed_bsz.py`, trace at HEAD
   from the number on the overview page down to the authors' pinned repository files (six to
   eight layers; expected shape: the page's script, `grid.js` and `headlines.csv`,
   `write_site_grid_js()` / `compute_site_headlines()`, the analytic mean in `R/npv_mc.R`
   (`npv_expectation()`), the NBER inputs (`compute_nber_ceiling()`, `final.csv`, the Monte
   Carlo ranges), the authors' repository at `25e84dd`). Python twins from `py/`. Run it, check
   the last compute layer returns -38.886, then seed the store: `ArtifactData` `set` on
   `chains/rjkdc` and `layers/rjkdc-1` ... from the files `review/store_push.py` writes (new
   docs, no `if_version`). If `ArtifactData` is unavailable, leave the push files under
   `review/push-rjkdc/` and say so.
7. **AUDIT.md**: update only the RJKDC section (step 1 now has one unified output).
8. Run `Rscript -e 'testthat::test_dir("rjkdc-analysis/tests/testthat")'` from the analysis's
   folder as its CI does (`.github/workflows/rjkdc-ci.yml` shows the exact commands), fix what
   breaks, commit in small commits with the attribution lines, do not push.

## Part B: the comparison (agent B, works in a git worktree)

The comparison's site is the repository root: `index.html` is generated from
`comparison/site/index.template.html` by `comparison/R/site.R` (`{{tokens}}`), and
`comparison/tests/testthat/test-site.R` asserts the page is byte-identical to the generator's
output, has no `{{`, no em-dashes, shows the key numbers, and every relative link resolves.
Edit the template, run `Rscript comparison/run.R`, never edit `index.html` by hand.

Headline: the gap on the common output (a), gross one-time wealth tax revenue, between the
two analyses: from BSZ Table 5 row 1 to the NBER expected revenue (the two ends of the bridge;
values in `comparison/export/r/ends.csv` and `endpoints.csv`, keep what the page already
calls the bridge's ends). Label "Main estimate¹, the gap on the common output". Value: the
gap in $B. Definition: "Defined as the difference between the two analyses' gross one-time wealth
tax revenue once both are scored on one definition, explained one disputed input at a time."
Footnote 1: neither analysis reports this number; it is this OPA's reconciliation, with the two end
values and their sources.

1. **Overview** (`comparison/site/index.template.html`): title "California Proposition 40,
   Reconciliation of the Two Analyses"; eyebrow "Open Policy Analysis for:"; headline block
   with tokens filled by `site.R`; the "Three layers to understand the analysis" cards: Open
   Output "Explore the main estimate and its assumptions →" linking the bridge section on this
   page (`#the-bridge`, the interactive waterfall keeps its dials); Open Analysis with one
   subcard "The reproduction report →" (`comparison/site/repro.html`) and no slides subcard;
   Open Materials "Materials for computational reproduction →" linking
   `https://github.com/fhoces/opa-prop40/tree/main/comparison`. The existing sections (common
   output definition, two analyses, the bridge, Hoopes, vintage gap, disputed inputs, neutral
   material, the two full analyses) stay on the page below the cards, the bridge first; the
   AI section becomes the credit fold with a blank table per Part C. Footer per lesson 6
   ("Comparison overview" is this page, so the footer links the two analyses' overviews instead).
2. **Report** `comparison/site/repro.qmd` rendered to `comparison/site/repro.html`: title
   "Prop 40, the comparison: the reproduction"; reads `comparison/export/r/*.csv` and the two
   contracts, never retypes; sections: the common output definition and what each analysis
   reports; the two endpoints scored on it; the bridge step by step (exact Shapley over all
   orders, one sequential order, with the step values); which of Rauh's revenue numbers is
   output (a); the disputed inputs table; the Hoopes comparison; every input by origin; what
   reproduces; reproducing this document. Folds with the R function source and the Python twin
   per exhibit (copy the fold mechanism from `bsz-analysis/site/repro.qmd`, adapting the paths
   to `comparison/R` and `comparison/py`). Needs `repro.css` (copy BSZ's).
3. **Materials page** `comparison/site/materials.qmd` -> `materials.html`: sections per
   lesson 9 (rebuild: `Rscript comparison/run.R`; tests; scripts; CSVs under `export/`;
   sources from `DATA-SOURCES.csv`; what the checks found: `DISPUTES.md`).
4. **README** `comparison/README.md`: top per lesson 7 with the review link ("Review the code
   behind the <gap> main estimate"); keep the current content below "## The reproduction".
   Copy the wordmark image to `comparison/site/assets/opa/` (create the folder; the root
   `assets/opa/` holds the page's icons).
5. **Review chain**: `review/seed_comparison.py`, traced from the number on the root page down
   to the two analyses' export contracts (expected shape: the page's script reading
   `assets/comparison-data.js`; `comparison/R/site.R` writing it; `R/build.R`; `R/model.R`
   `score_common()` and the Shapley steps; `R/contract.R` reading the contracts; the two
   `export/r/{inputs,outputs}.csv` files). Python twin `py/bridge.py`. Run, confirm the last
   compute layer reproduces the headline, seed `chains/comparison` and `layers/comparison-n`
   as in Part A.6.
6. **AUDIT.md**: update only the "Reconciliation page" section.
7. Run `Rscript comparison/tests/testthat.R` and `python3 comparison/py/bridge.py`, fix what
   breaks (the link test will fail until the new pages exist), commit in small commits with
   the attribution lines on the worktree branch, do not push. Do not touch files outside
   `comparison/`, `index.html`, `assets/`, `review/seed_comparison.py`,
   `review/comparison.json` and the AUDIT section.

## Part C: rules for both agents

- Nothing from the confidential author bundles in any page, ledger, snippet or store doc.
  Only public code and public numbers.
- No em-dashes in anything written, including commit messages. Use commas, colons or two
  sentences.
- Credit section: keep the heading, the explanation paragraph and the legend; the table lists
  the objects with empty cells and one line under it: "The credit interview has not been run
  for this analysis yet." Do not edit `site/credit/CREDIT.md` or `credit-answers.json`.
- Do not edit the root `README.md`, `review/README.md` (regenerated after the merge), the
  BSZ folder, or the other agent's folder.
- Commit messages end with the two attribution lines given in the agent brief. Do not push.
- Verify in the way the CI does: the analysis's test suite, a headless Chrome screenshot of each
  changed page at 1280px and at 390px (an iframe host; see `~/.claude/lessons/web-html.md`),
  and a link check of every relative link in the changed pages and READMEs.
- Report back: the commits, what each page shows now, the test result, the layers seeded (with
  the headline reproduced and the command that showed it), and anything left undone.

## Round 2 (2026-10-14, second feedback list, applies to all three analyses)

Decisions from the author's list, in their order:

1. Every "Open Policy Analysis" link points to the academic paper: Hoces de la Guardia, Grant
   and Miguel (2021), "A framework for open policy analysis", Science and Public Policy,
   https://doi.org/10.1093/scipol/scaa067. No link to the BITSS page or the tinyurl remains.
2. The root README opens like `bsz-analysis/README.md`: intro paragraph, the code review link
   first, the layer image on the right, then the three parts of the project as numbered
   components, each linking its subfolder and its live overview page.
3. The reconciliation page's headline block shows the two main estimates side by side,
   $106.8B (BSZ, net total) and -$38.9B (RJKDC, NBER September 2026), not the gap. The gap
   stays inside the bridge. The comparison review chain's headline follows.
4. The RJKDC explorer gets the BSZ outcomes chart: two horizontal bars, "This setting" and
   "Main estimate" (the NBER setting), values printed at the end of each bar, drawn by the
   same SVG approach as `bsz-analysis/site/explorer/index.html` (the `bars` SVG and the
   `drawBars` code). It sits above the outcomes table.
5. The comparison centres on the common output (b), the net fiscal effect: the bridge opens on
   it, the ends and the steps are stated on it, the review chain traces it. Output (a) stays
   as the secondary setting.
6. The comparison gets its own explorer page, `comparison/site/explorer/index.html`, in the
   BSZ explorer's layout: site-nav line, flex header with the headline block (the two main
   estimates), the bridge with its dials, the two-bar chart of the two ends under output (b),
   the footer. `assets/comparison-data.js` stays where it is (the explorer reads it with a
   relative path). The root page's Open Output card links to the explorer; the bridge section
   on the root page goes (the fold's text moves to the explorer or the report).
7. The word "side" or "sides" is never used for the BSZ or RJKDC work. Wording: "the BSZ
   analysis", "the RJKDC analysis", "BSZ analysis overview", "the two analyses". Sweep every
   page, explorer, report, slide deck, README, AUDIT.md, the review ledgers and the review page.

Split: agent A does item 4 (RJKDC explorer and its tests) in the main working tree; agent B
does items 3, 5 and 6 (comparison) in a worktree; the root README (item 2), the links (item 1)
and the sweep (item 7) are done after the merge, except that each agent already writes its own
new text without "side" and with the paper link.
