# AUTHOR-COMPARISON: the author's answers of 2026-10-16, comparison share

Owner: opus implementer. Status: done (items 3, 7, 8, 9, 10, 11, 12, 13, 14, 15, 19, 20, 21, 22, 24,
and the coordinator's added items A and B). Nothing committed or pushed. Finished with
`comparison/site/slides/slides.Rmd`: the author's nine appendix slides can go in now (nothing was
added at the end of the appendix).

## Per item

**3. Badge on its own line (done, with one exception).** One shared rule in `assets/paper.css`
(`.ai-badge-line`, `.ai-badge-line .ai-badge`: 15px line, badge at 0.9em). The page-local rules on
the BSZ and JR overviews are gone, and the JR overview's `badge-line` class is now `ai-badge-line`
(the BSZ class), so both use one name. `rjkdc-analysis/tests/testthat/test-ai-badges.R` pins the new
class. The comparison overview gets no badge line: its credit answer for "Overview page" is
"Understood", and `comparison/tests/testthat/test-ai-badges.R` requires no badge there. The JR deck
keeps its own `badge-line` span in the subtitle, styled in the deck (deck sizes differ from the page).
The overviews are hand-written, so there was nothing to rebuild.

**7. AI slide (done).** "verification is trivial" became "verification is much easier". The last
sentence is now "Each analysis's pages carry a badge that says how far they have been reviewed."

**8. why-opa-6 (done).** "draw a third OPA in between the two" became "build a third OPA that bridges
the two, one input at a time".

**9. Voter guide (done; every quote matches).** Source: California Secretary of State, Official
Voter Information Guide, general election of 3 November 2026, Proposition 40, arguments and
rebuttals, guide pp.56-57 (https://voterguide.sos.ca.gov/propositions/40/arguments-rebuttals.htm;
PDF https://vig.cdn.sos.ca.gov/2026/general/pdf/prop40-arg-rebuttals.pdf). Checked against the PDF:
- "about $100 billion": argument in favor, p.56 ("It will raise about $100 billion"). Match.
- "pay their fair share": in favor, p.56 ("make billionaires finally pay their fair share in taxes";
  heading "BILLIONAIRES SHOULD PAY THEIR FAIR SHARE"). Match.
- "poorly designed tax scheme": argument against, p.57. Match.
- "$25 billion in lost revenue": against, p.57 (heading in capitals, "PROP. 40 WILL COST CALIFORNIA
  $25 BILLION IN LOST REVENUE"; also the rebuttal on p.56). Match, up to the guide's capitals.
- "without voter approval": against, p.57 ("power to amend the measure, without voter approval").
  Match.
- Paraphrases: over a million lose coverage, about 200 billionaires, hospitals and ERs open (p.56);
  drives companies and wealthy residents out, taxes retirement accounts for the first time, the
  Legislature may amend the measure (p.57). All match.
Worth knowing: the guide attributes the $25 billion to "a study by Stanford University economists"
(p.57), that is the Rauh et al. March version (headline about -$24.7B), not the JR September version.
Changes: the slide 2 footnote now names the pages and links the guide (quote box untouched); a row in
`comparison/DATA-SOURCES.csv` (URL, date 2026-10-16, SHA-256 `5110c8fa...`); the PDF saved as
`comparison/original-materials/sos-vig-2026-prop40-arguments.pdf` (gitignored, like the LAO file);
the materials page's Sources paragraph now counts four documents, three in the manifest.

**10. Closed form in the report (done).** After "The draws are independent ..." in
`comparison/site/repro.qmd`, an R chunk recomputes each mean from the JR contract (as
`rauh_nber_expectation()` does) and stops if it disagrees with `ends.csv`; then a gloss of the
symbols, a display line and the seeded-run sentence. Rendered:
"E[NPV] = E[WT] - E[f] x E[C] x E[1/(r - g)] = 36 - 0.45 x 4.55 x 36.62 = -38.98" (with proper
minus and times signs), then "The -$38.9B that the authors print is the average of one seeded run
of the same draws, so it differs from this mean by simulation noise." One departure from the
answer's text: E[1/(r - g)] prints as 36.62, not 36.6, because 36 - 0.45 x 4.55 x 36.6 = -38.94;
at two decimals the line is arithmetic a reader can check. Values checked: (0 + 72)/2 = 36;
(0.30 + 0.60)/2 = 0.45; (3.3 + 5.8)/2 = 4.55; ln(3)/0.03 = 36.62. A `.display-line` rule was added
to `comparison/site/repro.css`.

**11. "Most of these" (done).** Both copies in `comparison/R/site.R` (the overview's table and the
explorer's survey section) read "Most of these are empirical quantities; H and r are scenario
choices." The `test-site.R` pin follows.

**12. Real estate (done).** The step's kind is "guesswork vs data" in `bridge_steps()`
(`R/model.R`) and `STEPS` (`py/bridge.py`). The BSZ end's tip now ends "Kind: guesswork.".

**13. JR base (done, comparison side).** The Forbes-source step (`base_list`) is now
"data vs guesswork on data": the BSZ end is the 1 July 2026 list, the JR end the 2025 list grown by
the assumed 7%. "guesswork on data" is already in the pages' kind list and the tests' closed lists,
so no new kind was needed. DISPUTES.md row 7's Kind cell gives both new kinds with the reason.

**14. 5% rate (nothing to change on the comparison).** The comparison shows no kind for the tax
rate (it is shared by both ends, not a step). AUDIT.md's BSZ line now has the BSZ input counts after
the BSZ change (data 5, scenario 2) and says the rate is data in both.

**15. JR printed results (done).** `rauh_headline_revenue` ($40B) and `nber_headline_revenue`
($30B) are "derived" in `comparison/data/document-inputs.csv`. AUDIT.md now says data 7,
guesswork 3, derived 6, scenario 3. No README states these counts.

**19. Column names (done).** In the comparison's exports: `inputs.csv` `supporting_value`,
`supporting_source`, `rauh_value`, `rauh_source` became `bsz_value`, `bsz_source`, `jr_value`,
`jr_source`; `ends.csv` `rauh_model`, `rauh_own`, `rauh_residual` became `jr_model`, `jr_own`,
`jr_residual` (`bsz_model` was already right). Changed in `R/build.R`, `R/model.R`, `R/site.R`,
`py/bridge.py`, the four test files that read them, `repro.qmd`, `materials.qmd` (its sentence on
which column is which now covers both files) and `slides.Rmd`. DISPUTES.md and the READMEs never
named these columns. The analyses' own contract ids (`rauh_mc_*`, the endpoint id `rauh_nber_npv`)
and the directory names are unchanged.

**20. C dial label (done).** "yearly tax revenue" became "yearly income tax" (`DIAL_WORDS` in
`R/site.R`). The JR explorer already says income tax.

**21. Root scope sentence (done).** In the line under the headline, "Both analyses count the wealth
tax at face value." became "Both numbers measure the same thing: the wealth tax collected, counted
at face value, minus the present value of the income tax lost (the report's definition)", linking
`comparison/site/repro.html#the-common-output`. Only the income tax loss is called a present value.
The next sentence now says "the wealth tax" instead of "it", so it cannot be read as the income tax.

**22. Residency date (done, comparison root).** The first sentence now matches the JR overview's:
"would tax, once, people who lived in California on 1 January 2026 and are worth $1 billion or more,
at 5% of their net worth, payable over five years."

**24. Survey audience (done).** The share line under the large button (overview and explorer) now
opens "The survey is primarily for economists and policy analysts." The two small buttons at the top
of the overview's differences fold get the same sentence beside them (`.q-mini .q-for` in
`assets/paper.css`). The pinned "Share this survey with ..." text is unchanged.

**A. Exact "=" in the equation (done).** `R/site.R`: the last operator is "=", every amount (both ends
and the four terms) prints to two decimals: $106.80B - $29.89B - $39.44B - $81.34B + $4.89B =
-$38.98B, on the overview, the explorer and the deck's equation slide. A `stopifnot()` in
`render_site()` checks that the two-decimal terms add exactly to the two-decimal JR end. The
aria-label says "equals"; the note under both equations now says "The amounts are rounded to two
decimals and add up exactly to the JR estimate, -$38.98B" (the old "rounded to one decimal.
Unrounded, they add up exactly to ..." is gone). The deck's 'The terms add up exactly; "about equal"
is only rounding.' became "At two decimals the terms add up exactly." The explorer's script does not
recompute the equation's amounts (it only marks terms during the walk and the Apply presses), so "="
holds at every dial setting. The Apply-button test now compares the presses with the printed terms at
two decimals. Headlines keep $106.8B and -$39.0B.

**B. Counts on opa-bsz and opa-jr (done).** The deck's setup now reads the JR mismatch count from
`rjkdc-analysis/MISMATCHES.md` (as the JR pages do) and each checks page's settings count from its
rendered table (rows under "Settings the paper(s) does/do not print", less the reference row). The
slides now read "Ten settings" (BSZ), "ten mismatches" and "Nine settings" (JR). Still typed on those
two slides: "All 28 cells", "26 round", "7 of 7", "4 of 4".

**C.** Nothing added to the appendix.

## Files changed

`assets/paper.css`, `index.html` (generated), `assets/comparison-data.js` (generated),
`README.md` (9 to 10 mismatches), `AUDIT.md` (10 items; document-input counts; bridge kinds; BSZ
input counts), `comparison/R/{build,model,site}.R`, `comparison/py/bridge.py`,
`comparison/data/document-inputs.csv`, `comparison/DATA-SOURCES.csv`, `comparison/DISPUTES.md`,
`comparison/site/index.template.html`, `comparison/site/explorer/index.html` (generated),
`comparison/site/repro.qmd`, `repro.css`, `repro.html`, `materials.qmd`, `materials.html`,
`comparison/site/slides/slides.Rmd`, `slides.html`, `comparison/export/{r,py}/*` (regenerated),
`comparison/tests/testthat/test-{site,shapley,endpoints,dial-path}.R`, `bsz-analysis/site/index.html`
and `rjkdc-analysis/site/index.html` (local badge CSS removed), `rjkdc-analysis/tests/testthat/test-ai-badges.R`.
Not touched: `bsz-analysis/py/run_export.py`, `.gitignore`, `PLAN-3-learning-materials.md`, slide 2's
quote box, slide 13, `comparison/site/credit/`. Untracked `comparison/site/slides/figs/` and
`screenshots.sh` are not mine.

## Tests and renders

- `Rscript comparison/run.R`, `python3 comparison/py/bridge.py`: ran clean.
- `Rscript comparison/tests/testthat.R`: 1016 expectations, 0 failed, 0 skipped (was 1012).
- `quarto render repro.qmd` and `materials.qmd` (from `comparison/site/`): rendered.
- The deck rendered with the Positron pandoc; slides 2, 8, 12, 14, 15, 16, 17 and 23 printed in
  headless Chrome and read as images: no overflow.
- BSZ suite (`bsz-analysis`, `Rscript tests/testthat.R`): all pass, no failures.
- JR suite (with `RAUH_REPO_DIR`): all pass, no failures (one ggplot2 version warning, pre-existing).
- `check_links.py`: no broken links. No em dashes in added lines.
- BSZ, JR and root overviews screenshotted at 1000 px: the badge lines match; the root's first
  sentence and scope sentence read as intended.

## Needs a follow-up

- `review/seed_comparison.py` reads `ends.csv` by the old names (`rauh_model`, `rauh_own`, lines
  124-127, 164, 251), and `review/comparison.json` quotes them. The next `review-sync` reseed fails
  until the seeder uses `jr_model` and `jr_own`. Left alone because `review/` is outside this package.
- JR deck: its subtitle span keeps the class `badge-line`; rename it to `ai-badge-line` only if the
  deck should share the page rule (the sizes differ).
