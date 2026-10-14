# Final review, run 001
Commit: 8a369b0. Packages: 8. One line: attribution fixes (the NBER chapter's title and authors, BSZ's printed headline, Walczak's rows), the comparison's conventions and function in words, and plainer first screens on all three sites.

## Done
- WP-1 (coordinator): the three overviews and the comparison's generators. New first screens on every site: the measure's who/when/how, a site-nav line, the badge linked to the credit fold, an author line, larger definition and footnote text, the "Today's dollars" gloss; the root's first paragraph says what −$38.9B means and names the three largest bridge steps; the NBER chapter's title and authors fixed on the RJKDC overview; "36 below 30" corrected; $103.8B presented as the reproduction of the printed $104 billion; Walczak's rows no longer labelled RJKDC; the row 1, 5 and 6 source cells carry each value's reason (`build.R`, mirrored in `index.html`); conventions, scope ("What this OPA does not estimate") and the compound-kinds legend on the root; fold teasers; the credit sentence states the record.
- WP-2 (coordinator): the READMEs, the audit and the test counts. "$106.8 billion" labelled this OPA's choice, the Jaros and Rauh citation with the "California" title, "net worth above $1 billion" corrected, stale test counts replaced by links to the materials pages, the audit vector corrected, glosses for CI, {targets}, twin, export contract, anchor, NBER, SSRN.
- WP-3 (opus): the comparison explorer, template and page in step. Plain sublabels and gloss, the conventions footnote, the estimating function's two non-obvious parts in words with the code names moved to Notes and data, the Shapley-interaction sentence, the compound-kinds legend, "whose inputs the common function can take one by one" (and the `nber_step` row text matches `site.R` exactly), per-slider inert hints and the "between the two analyses' values" note, the "exact average / published run" pair in the RJKDC panel header, the scroll hint and a minimum width for the bridge table's first column.
- WP-4 (opus): the BSZ explorer. The standfirst's referent fixed, the printed $104 billion named, the origin taxonomy and "whose levels" note under the rack (with a true clause for the two yes/no switches), "Other levels: this OPA's." in the tooltips of the numeric dials, each dial's first sentence shown under its label, one name for the comparison overview, the kit sizes and scroll hint.
- WP-5 (opus): the RJKDC explorer and `R/site.R`. The author formula in the standfirst, "as printed" on the main setting's headline and a first table row for the printed seeded-run mean next to the exact expectations, the 85.2% page reference, the seeded-run gloss, the q dial's double-counting warning and "(OPA reading)" level labels, the discount-rate dial's explanation of its guesswork label against the contract's research label, plain words for "draw" and the U[...] notation (`grid.js` lags until the pipeline runs).
- WP-6 (opus): the RJKDC report, deck, materials page, mismatches and three script headers. Title and authors per K1 everywhere, the 85.2% reference, 72.06 traced to the paper's eq. 4 and to the two rounded figures, the rate range's guesswork label explained, the contract's C and r rows restored to the main origin table, seeded run and exact expectation glossed, "$B" and "billion" instead of "bn" on the deck, "tests passed" headers, first-version numbering labelled in the script headers.
- WP-7 (opus): the BSZ report, deck and materials page. The printed Table 5 digit read from the pipeline (`site_tab5_printed`, `tab5-vs-printed.csv`), never typed; the measure's dates in the introduction; the Laffer section's e = 10 attributed correctly; the "Appendix Figure A1" naming slip explained; the $3.2B and $3.06B averages told apart; "to 1e-12" for "exactly"; one name for the comparison overview.
- WP-8 (opus): the comparison report, materials page and `DISPUTES.md`. The introduction in plain words with every number an R call; conventions; the estimating function as seven numbered lines; a `stopifnot` guarding the three largest steps the introduction names; "the code does what the method says"; the clipped Hoopes bar noted; `loss.csv`'s netting column and the two unlisted GGSS documents explained on the materials page; the stale vintage caveat and the compound kinds in `DISPUTES.md`.

Every package touched only the files it owned (checked against `git diff --stat` per commit). Departures from the plan's letter, each reported and each correct: WP-3 moved the NBER gloss to the standfirst (first use) and placed Conventions after the footnote that introduces the definition; WP-4 excluded the two yes/no switches from "Other levels: this OPA's." because their "yes" is the authors' own Table 5 rows; WP-6 used the five-name form of the first version everywhere; WP-7 reads the printed digit from the pipeline rather than typing 104; WP-8 placed Conventions after the horizon paragraph and says the RJKDC text uses both (r − g) and r, which `MISMATCHES.md` item 3 confirms.

## Partially done
- None.

## Not done
- None.

## Fixed in the final review
- Comparison explorer (template and page): the E-11 sentence and the next one both said what "One order" shows; merged into one sentence.
- Root page (template and page) and comparison explorer (template and page): "the RJKDC analysis's mismatch 3" now links `rjkdc-analysis/site/materials.html#mismatches`.
- `comparison/DISPUTES.md`: "reconciliation page" twice became "comparison overview" (K6); "On the bridge it enters as extra steps after the SSRN anchor" became "as one step, the September 2026 revision", which is what the bridge has and what the new vintage caveat says.
- `comparison/site/materials.qmd`: "the RJKDC text anchor" (the calibration sense, right after the page defines anchor in the bridge sense) became "the rate the RJKDC text anchors its range on".
- RJKDC explorer: the outcomes table's caption now covers the new first row ("the first row is the authors' printed mean, from their seeded run").
- `rjkdc-analysis/R/site.R`: the f dial's level label "U[0.30, 0.60] (as coded)" became "0.30 to 0.60 (as coded)", the plain form V-26 asked for in the descriptions (`grid.js` lags with the rest of WP-5).
- BSZ overview "What reproduces" and BSZ materials page: the "Not reproduced" entry now says the pipeline's target named after Appendix Figure A1 builds the paper's Figure 1 Panel B (WP-7's follow-up to WP-1's file).

## Needs a local render
From `00-run.md` (`needs_render.py 8a369b0`), in this order:

```
cd bsz-analysis && quarto render site/materials.qmd
cd bsz-analysis && quarto render site/repro.qmd   # needs the pipeline outputs: the workbook in original-materials/, then Rscript -e 'targets::tar_make()'
Rscript -e 'rmarkdown::render("bsz-analysis/site/slides/slides.Rmd")'
Rscript comparison/run.R && Rscript comparison/tests/testthat.R
cd comparison/site && quarto render materials.qmd
cd comparison/site && quarto render repro.qmd
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> Rscript -e 'targets::tar_make()' && RAUH_REPO_DIR=<clone> Rscript tests/testthat.R
cd rjkdc-analysis && quarto render site/materials.qmd
cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd
Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'
```

What each rebuild does: `comparison/run.R` regenerates `index.html`, `comparison/site/explorer/index.html` and `assets/comparison-data.js` (the explorer's bridge-table cell and tooltip still read the old `nber_step` label from the data file until then) and `comparison/export/r/inputs.csv` and `loss.csv` (the changed source cells; `test-parity.R` fails until then). The hand-mirrored pages carry the same text as the templates and the two R sources, so the rebuild should reproduce them byte for byte; if it does not, the generator wins and the diff shows the slip. The RJKDC pipeline regenerates `grid.js` with the new dial texts (`test-site.R` fails on the byte-for-byte check until then); first confirm `R/site.R` parses: `Rscript -e 'invisible(parse("rjkdc-analysis/R/site.R"))'`. After the deck renders, check the RJKDC title slide and "The headline" slide, which each gained a line, and the BSZ deck's "study in brief" slide. After the comparison report renders, check the new `stopifnot` and the seven numbered lines; after the materials page, the `loss.csv` note's two figures.

## Carried over to the next iteration
- Naming sweep beyond the touched lines: "RJKDC report" remains in `bsz-analysis/site/repro.qmd` (three places) and `slides.Rmd` (two); "BSZ report" in `rjkdc-analysis/site/repro.qmd`, `slides.Rmd` and the RJKDC explorer; `bsz-analysis/R/site_exports.R` line 55 (a code comment). The style rule says "the BSZ analysis" and "the RJKDC analysis".
- Glossary terms still undefined at first use on the decks and materials pages (seeded run, exact expectation, Monte Carlo, {targets}, Python twin, continuous integration) and on the explorers (perpetuity, present value on the RJKDC explorer, "pp", "README", "mismatch 5"); "Monte Carlo", "perpetuity" and "mean net present value" in the comparison report's "The two main estimates"; the compound-kinds sentence in the comparison report's "Every input, by origin"; the "Vintage caveat" heading in `DISPUTES.md`.
- RJKDC explorer: off the main setting the headline reads "Main estimate¹, a setting the authors did not publish" (pre-existing; "This setting, which the authors did not publish" would be right); `.headline .sub` stays 12px; the chart's bar label "Main estimate (NBER)" against the table header "Main estimate (NBER, September 2026)"; the sub-line mixes "PDF p." and "p.".
- BSZ explorer: the links in footnote 1 have no colour rule; the ⓘ button of the dependent dial is disabled with its dial (pre-existing).
- BSZ report and deck: the reproduced 103.8 is still called "BSZ's headline" at `repro.qmd` line 898 and on the deck's "Base scenario" line (the printed digit could be added as in the introduction); the deck's "study in brief" note says the figures are "from its abstract" while the slide now also carries two table figures.
- RJKDC report: the sentence "The data and research inputs (the Forbes base, the FTB brackets, the Pareto fit) fix the scale" now sits above a table where the rate bounds are also research (the contract rows); Step 4 explains why, but the sentence could name them.
- Plan's do-later list: E-21 (a one-at-a-time table on the RJKDC report); V-14 (the waterfall as horizontal bars on phones, the credit table's column order); V-29 (the decks' Overview button); E-23 (`printed_page` for the NBER outputs in `R/export.R`); E-27 and A-03 (the `loss.csv` column and `side` label in `build.R`); A-14 (the 72.06 page in `outputs.csv`); E-22 (URLs for the five GGSS documents); the explorers' site-nav lines could link the comparison overview as the overviews' now do.
- Generated-file follow-ups for the author, from the reports: `rjkdc-analysis/export/r/inputs.csv` sources for the `rauh_mc_*` rows cite the first version's script and pages; `bsz-analysis/R/figures.R` line 204 titles the industry chart "Appendix Figure A1" (retitle it "Figure 1, Panel B" and drop the clause in the report); `review/seed_bsz.py` line references into `bsz-analysis/site/explorer/index.html` moved (the published ledger is pinned to an older commit and still correct).

## Questions for the author
- Q1 (A-16, E-04): the discount-rate range is guesswork on the RJKDC dial and in the report's Step 4, research in the export contract and `DISPUTES.md` row 2. This run explains the difference on the dial and in Step 4 and keeps both labels. Relabelling the dial changes the "six of the seven inputs are guesswork" count on three pages; relabelling the contract needs a pipeline rebuild. Which stands?
- Q2 (V-04): the author line now reads "OPA by Fernando Hoces de la Guardia. This site recommends no vote and favours neither analysis: it reproduces both analyses' arithmetic and shows where their assumptions differ." Add an affiliation or a funding statement?
- Q3 (V-05): the "Work in progress" badge now links the credit fold and says the numbers are final for the versions cited and the author's review and the credit interview are what is unfinished. Is that the right account?
- Q4 (A-06, E-26, V-20): the RJKDC and comparison credit tables stay blank with a sentence stating the 2026-10-01 record; render the matrices from `credit-answers.json` instead, or run the per-object interview?
- Q5 (A-25): citations keep "NBER Working Paper 35218, August 2026" and "NBER chapter c15504, 22 September 2026"; the NBER site was unreachable. Add "(Tax Policy and the Economy, vol. 41)" and confirm the BSZ revision month against the cover?
- Q6 (E-12): the scope paragraph names only what the OPA's own pages establish; administration and valuation costs and federal tax interactions are left out. Add them if either analysis addresses them.
- Q7 (V-18, main 8cc011f): the RJKDC overview's h1 names Jaros and Rauh (JR) while every other page and the keys say RJKDC; the byline explains the two names. Keep both, or rename throughout?
- Q8: the generated files that lag (above) and the two hand-mirrored pages: run the rebuilds and confirm byte-for-byte reproduction.
- Q9 (A-27): a dated line for `PLAN.md`'s "Decisions after the first build": "2026-10-07: BSZ main estimate changed to the net total (this OPA's construction); 2026-10-14: RJKDC main estimate is the NBER mean NPV; the SSRN estimate stays as a scenario and the bridge's anchor."
- Q10 (E-22): URLs for the five GGSS documents in `bsz-analysis/DATA-SOURCES.csv`.
- Q11 (V-11): the watermark icon behind the section heading (the kit's design).
- Q12 (V-14): the waterfall and the credit tables on phones (a kit change).

## Checks
- Links: `check_links.py` reported 0 broken internal links before the run and 0 after (`00-links-before.txt`, `00-links-after.txt`; the orchestrator excluded `feedback/` from the scan so the plan's quoted snippets are not read as links); re-run after the final-review fixes: 0.
- Tests and renders: R and Quarto are not in the container, so `Rscript comparison/run.R`, the three test suites and every Quarto and rmarkdown render were skipped (`00-run.md`). Known failures on the committed tree until the author rebuilds: the comparison suite's generator and parity checks, the RJKDC suite's `grid.js` byte-for-byte check.
- Pinned strings: every string the three `test-site.R` files pin on the overviews and the root page is present after the edits (BSZ 24, RJKDC 16, root 7, checked by script); the comparison explorer keeps the pinned bridge sentence and contains no gross-revenue figure or `data-out=`; the RJKDC explorer keeps `var MAIN = "nber";`, `var ORDER = [MAIN];` and `drawBars(i);`; `R/site.R` keeps its seven `origin = "..."` lines unchanged.
- Generated pages: `index.html` and `comparison/site/explorer/index.html` differ from their templates only on token lines and generated blocks; neither contains `{{`.
- Renders: `screenshot.cjs --text` renders the three overviews and the three explorers without errors; phone (390) and desktop (1280) captures of the three overviews and the comparison explorer were looked at; no page scrolls sideways at 390.
- Style: no em or en dash in any added line of the 29 content files changed.
- Tool changes by the orchestrator in this run: `check_links.py` (skip `feedback/`) and `needs_render.py` (one line per command).
