# WP-3: The comparison explorer
Owner: opus. Status: done.

The template and the generated page carry the same edits. Where the template has a `{{token}}`, the generated page keeps the filled value. The bridge-table row (item 7) is changed in the generated page only, because the template has `{{bridge_rows}}` there. `diff <(sed 's/{{[a-z_0-9]*}}/TOKEN/g' comparison/site/explorer.template.html) comparison/site/explorer/index.html` shows only token lines, the slider, bridge-row and findings blocks, and the parity-note line.

## Changed
- `comparison/site/explorer.template.html` and `comparison/site/explorer/index.html`:
  - K2 (V-02, V-09), item 1: the two `.def` sublabels are now the K2 texts. The gloss line `<p class="def">Today's dollars (present value): ...</p>` goes after `.hl-pair`. `.headline .def` is now 15px. This page has no `.headline .fn` rule: its headline footnote is a `p.fn`, so `p.fn` now uses 13.5px and `var(--ink-2)` (was 12px, `--ink-3`). Shared-kit change.
  - K9 (V-14), item 2: the scroll hint for `.table-scroll` and `.chart-scroll`, and `#bridge-table td:first-child { min-width: 11em; }`.
  - Board lead (V-21, E-05), item 3: the second paragraph now uses the plan's wording ("One formula, used for both analyses, computes both"; the browser copy, with names and files under Notes and data). A new paragraph states the two non-obvious parts of the formula in words and links `../repro.html#the-two-ends`. That anchor exists in `comparison/site/repro.html`.
  - Bridge section (V-21), item 4: the paragraph now opens "The bridge uses the same formula."; the code names are gone from it. The Notes and data fold's first paragraph gains "The estimating function is `score_common()` in `comparison/R/model.R`, with a Python twin; the browser runs `model.js`, a copy of it."
  - E-11, item 5: added the Shapley-interaction sentence after "whatever the reading order."
  - A-02 (and KG for SSRN and NBER), item 6, the rev-note: "the last version whose inputs are published" becomes "SSRN, a preprint site), the version whose inputs the common function can take one by one". The September revision now reads "(Jaros and Rauh, NBER; its code and person-level file are in the same public repository)".
  - A-02, item 7, generated page only: the first cell of the `nber_step` bridge row now ends "(the steps before it reach the March 2026 version, whose inputs the common function takes one by one)". This is the same text WP-1 put in `comparison/R/site.R`; I checked it in the working tree.
  - E-02, item 8: a new `p.fn` "Conventions. ..." paragraph uses `{{nber_growth}}`, `{{r_min}}` and `{{r_max}}`. They are filled as "7%", "1.5%" and "4.5%" in the generated page.
  - V-23, item 9: the RJKDC panel header now reads "With these sliders −$39.0B (the model's exact average; the authors' published run gives −$38.9B)". The template keeps `{{nber_end_b}}` and `{{hl_rjkdc}}`.
  - E-19, item 10: the kinds legend gains the "A vs B" / "A + B" / "guesswork on data" sentence.
  - V-22, E-28, item 11: the script has a new `deadNote(id, x)` function:
    - Elasticity size, when the permanent rate is at its BSZ value (`dtau === 0`): "No effect until the permanent-rate slider above moves off its BSZ value."
    - Proportional loss, when `d_conf === 0 && dtau === 0`: "No effect until some billionaires leave in this panel (the departed slider or the permanent-rate slider)."
    - Any other inert case keeps the old text.
    - A live slider at positions 1 to 3 shows "A position between the two analyses' values: this OPA's construction, not a published number."
  - KG (V-10, E-18), item 12: the RJKDC panel note now glosses "Monte Carlo simulation", "exact expectation" and "seeded run" at their first use on the page, in the KG wording. The seed is 2026 and there are 100,000 draws, both checked in `rjkdc-analysis/R/npv_mc.R`.
  - KG (NBER): the gloss is at first use, in the standfirst: "(Jaros and Rauh, NBER, September 2026; NBER is the National Bureau of Economic Research, which circulates working papers)". That is why the rev-note does not repeat it.

### Where I departed from the plan's letter (please review)
1. **NBER gloss.** The plan puts it in the rev-note. I moved it to the standfirst, where the term first appears (implementer rule 5). The wording matches WP-1's root page.
2. **Placement of "Conventions".** I put it after the footnote block's second paragraph ("The net fiscal effect puts both on one definition ..."), not between footnote 1 and that paragraph. It describes the conventions of the definition that paragraph introduces.
3. **The inert-slider hints.** Each specific text shows only when the slider it names is the cause. Elasticity is also inert when the confirmed departures exceed the elasticity floor. Example: BSZ panel with Departed at 28.4% and Permanent-rate at 1.25 pp. There, "until the permanent-rate slider moves" would be false, so the old general text stays. I tested this in the browser.
4. **Monte Carlo gloss.** The package lists only "exact expectation" and "seeded run". I added the KG "Monte Carlo simulation" gloss in the same note, because the seeded-run gloss refers to "those random draws". The panel note is the first place the page says "Monte Carlo".

## Needs a local render
- `comparison/site/explorer/index.html`: run `Rscript comparison/run.R && Rscript comparison/tests/testthat.R`. The generator must reproduce the hand-edited page byte for byte (CI checks this). The same run also regenerates `assets/comparison-data.js`.
  - Until then, with JavaScript on, the old `nber_step` label from the data file still shows in two places: the bridge table's first cell and the waterfall tooltip. Both read "the earlier version whose inputs are published".
  - The reason: `table()` writes `b.label` from the data file into `c[0]`. The static HTML already has the new text, and `grep` of both HTML files finds 0 "inputs are published".

## Needs a follow-up (files outside the package)
- `assets/comparison-data.js` (generated): the `nber_step` label changes only when the rebuild above runs. Do not hand-edit it.

## Could not do
- Nothing.

## Checks run
- `grep -c "inputs are published"` finds 0 in both files.
- The pinned sentence "The BSZ end is\n    <b>$106.8B</b> and the RJKDC end <b>−$39.0B</b>, a gap of <b>$145.8B</b>." is unchanged.
- No `$103.8B`, `$36.0B`, `$67.8B` or `data-out=`.
- No em or en dashes. Tags are balanced in both files.
- `check_links.py`: no broken link outside the plan file's quoted examples.
- `screenshot.cjs comparison/site/explorer/index.html --text` renders with no errors and shows "Conventions." and the new hints.
- Playwright slider walk:
  - BSZ panel at start: elasticity and proportional loss show their specific texts.
  - Non-citizens at position 2 shows the "between" note.
  - Departed at 28.4% clears the proportional-loss hint.
  - Permanent-rate at 1.25 pp with departures in: elasticity falls back to the general text.
  - RJKDC panel with Permanent-rate at its BSZ value: elasticity shows its specific text.
  - No page errors.
- At 390px, both scroll hints show, the page has no horizontal scroll (scrollWidth 390), and the bridge table's first column is 137.5px.

## Noticed on the way (not changed)
- The bridge's first paragraph still says "Each bar between the two ends is the effect of moving one assumption all the way from the BSZ value to the RJKDC value". E-11 quotes this sentence. The new Shapley sentence qualifies it two paragraphs later but does not change it.
- "perpetuity" is used throughout the explorer (board lead, horizon slider title, rev-note, footnote 1) without the KG gloss. "pp" is used on the sliders ("5 pp") before the table note explains it. Neither is in this package's item 12.
- "the RJKDC analysis's mismatch 3" (here and in WP-1's root Conventions paragraph) has no link. `rjkdc-analysis/MISMATCHES.md` or the RJKDC materials page would let a reader find it.
- Plan wordings that read slightly repetitive in place:
  - "One formula, used for both analyses, computes both".
  - Notes and data: "with a Python twin" is followed by "A Python twin reproduces them".
- The `.board-lead code` CSS rule is now unused. It is harmless and left alone.
- The new gloss `<p class="def">` under the headline gets the browser's default bottom margin. It looks fine at 1280px and 390px.
