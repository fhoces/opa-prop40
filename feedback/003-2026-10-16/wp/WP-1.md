# WP-1: Comparison generator: tips, sources, the equation note, the versions table
Owner: opus. Status: done (with wording deviations where the plan's text broke a limit, listed below).

## Changed
- `comparison/R/site.R`:
  - Item 1 (A-03), D, BSZ end: "BSZ: no named move counted, since press reports do not establish a residence change before 1 January. Half of a is people who left in time." Deviation: "a residence change" in place of "a change of residence". With the plan's wording the root's D line ran to 26 words (limit 25).
  - Item 2 (A-05), a symbol tip: the plan's text, as given.
  - Item 3 (A-11), a, JR end: the plan's text, as given. The root's quantities table shows only its first sentence. The second sentence would take the line to 28 words, and the 25-word fallback drops it. The explorer tip has both sentences.
  - Item 4 (V-09), q, JR end: "JR: half the revenue, the 'more likely than not' line an accounting rule (ASC 740-10) uses to judge whether a tax stands." Deviation: "half the revenue" in place of "the revenue weighted by one half", and "stands" in place of "will stand". With the plan's wording, every fallback of the root line ran to 29 or 31 words. Now it is 25.
  - Item 5 (A-06), f, JR end: "The JR rule: 45% of all billionaires' income tax, whoever leaves, from a draw set around the 28.6% of wealth that left. It covers unreported moves too." Deviation: the plan's text measured 4 lines at 390 px. It was also one 29-word sentence, which no root fallback could fit. The new first sentence carries the reason into the root line (25 words). The "30% to 60%" range left the tip. It is still in the report's source cell.
    - 45% comes from `bi0`.
    - 28.6% is computed as `1 - nber_ceiling_hardcoded / nber_domestic_grown` = 0.28646. `export/r/inputs.csv` has no `d_conf` row, so `tok$dconf_sept` had been printing "%". That token is unused, and it now reads the same value.
    - Confirmed: 28.6 percent is on JR PDF p.31.
  - Item 5, f symbol tip: the clause moved in as planned ("Both ends include the movers in a (at the JR end, this OPA's addition), and the BSZ end also the leavers in D."). Deviation: the first sentence became "The share of billionaires' income tax lost to leavers." With "California loses to people leaving" kept, the tip ran to 4 lines.
  - Item 6 (A-07), C, JR end: the plan's text, as given. $3.3 and $5.8 are now read from `rauh_mc_c_min` and `rauh_mc_c_max`, no longer typed. The kind is unchanged.
  - Item 7 (V-17, E-21), r symbol tip: "To see how much it matters inside the JR draw, use the JR explorer's Rate 1.5% and 4.5% settings." Deviation: "it" in place of "the rate", and one "Rate". The plan's text measured 4 lines. The two rates come from the `r_min` and `r_max` tokens. The pinned first sentence is kept.
  - Item 8 (V-08), r, JR end: "2.73%: worth the same as the JR draw (1.5% to 4.5%) of r − g, the interest rate minus the lost tax's growth ($1 a year for ever is worth $36.6)." Deviation: the range is in parentheses and "yearly" is dropped. With the plan's wording the root line ran to 30 words. Now the line without parentheses is 25 words and keeps the gloss of g. The pinned ending "($1 a year for ever is worth $36.6). Kind: derived." is kept.
  - Item 9 (V-10), non-citizens, JR end: the plan's text, as given. The root line drops "(treaties, apportionment)" to fit in 25 words.
  - Item 10 (A-17): `step_texts()` BSZ value is now "the movers' proportional share, plus named leavers' own tax".
  - Item 11 (E-02, V-05, V-06, V-07): `order_note()` has the plan's new text. The sum is `money(eb$bsz_model + sum(dp$change), 2)`, which prints −$38.98B and is read, not typed. All three amounts are wrapped in `<span style="white-space:nowrap">`. The link goes to `#order-free-check` on both pages. `eq_note()` takes the new href as a fourth argument. That anchor is already in `comparison/site/repro.qmd`, from WP-2.
  - Item 12 (V-12): the versions row now reads "...not the 17 Mar version this project reproduces as the JR first version".
  - Item 13 (E-21): `jr_fn` appends "A seeded run starts the random draws from a fixed number, so it gives the same draws every time." It comes after the pinned two sentences and their links.
  - Item 14 (A-02), the source pattern:
    - `QUANTITY_SOURCE_PATTERN` now matches a chapter place with its PDF page ("chapter Table 7, PDF p.21", "chapter eq. 3, PDF pp.19-20", "chapter PDF p.32"). It also still matches a bare section, table or equation, the script line and the README.
    - A new `quantity_source()` cuts a chapter hit to "chapter PDF p.N" (3 words, the same form as "BSZ PDF p.N").
    - Root JR lines now cite: W pp.12-13, D p.21, f p.31, q pp.19-20, C pp.28-30, r p.32, real estate p.17. Two side effects: H now cites pp.30-32 (was "chapter Sec. 5.2"), and non-citizens cites pp.17-18 (was "NBER chapter Sec. 3.5").
- `comparison/R/build.R`:
  - Item 14 (A-02, A-06, A-07, A-11): the JR sources W_core, re, dep_j, q, own, f0, C and r lead with the chapter page, as planned.
  - Deviation in f0: "(chapter PDF p.31 and p.33; ...)" in place of "pp.31, 33". The root line cites p.31 (where the 28.6% reason is) in 3 words, which the f line needs to stay at 25.
  - Item 15: the header comment now has the draw as `(r - g) ~ U[r_min, r_max]`. ASCII is used, because the file is ASCII.
- `comparison/R/model.R`: item 15, comments only. Lines 38 and 281 now read `(r - g) ~ U[...]`.
- `comparison/tests/testthat/test-site.R`: not changed. No pin broke (lines 159, 162-166, 382, 386 and 467 all still hold).

Checks run:
- Chapter pages checked in the JR PDF:
  - fn.32 is on PDF p.34, so the plan is right and A-11's "p.33" is wrong.
  - eq. 3 is on p.19 (q = 0.50 "as our central estimate" runs on to p.20). Eqs. 18 and 19 are on p.35.
  - Table 6 is on p.17, Table 7 on p.21, Table 9 on p.30.
  - "reasonable lower bound" is on p.28 and $2,027.4B on p.12.
  - `NPV_dist_v8.R` line 20 is the f draw.
- Scratch render (exports and both pages written only under the scratchpad, `wp1root/`):
  - `test-site.R`: 701 expectations, 0 failed.
  - Every root quantities line is at most 25 words.
  - The pages contain no "shapley", no em dashes, no page errors and no horizontal overflow at 390 or 1280.
  - All 72 explorer tips are at most 3 lines at 390 px and at 1280 px (Chrome, playwright-core).
  - Three changed tips exceed the plan's 31-word proxy but measure 3 lines: the f symbol tip (35 words), the r symbol tip (33) and the r JR end (33).
- Grep: the old strings of items 1 to 12 are gone from `site.R` and `build.R`. There are no em or en dashes in the three files, and no other source keeps the old wording.

## Needs a local render
- `Rscript comparison/run.R`: rebuilds `export/r/inputs.csv` (new source cells), `index.html`, `comparison/site/explorer/index.html` and `assets/comparison-data.js`. Then run `Rscript comparison/tests/testthat.R`.
- `cd comparison/site && quarto render repro.qmd`: the disputed-inputs, bridge and Shapley tables read `step_texts()` and the new JR sources.
- `Rscript -e 'rmarkdown::render("comparison/site/slides/slides.Rmd")'`: the deck's `smaller` table reads `step_texts()` (A-17).
- Then the explorer-tip audit at 390 px. My scratch measurement is above, but it used the templates as they stood at 04:09, while another package was still editing them.

## Needs a follow-up (files outside the package)
- None for this package's wording. No other source keeps the old strings.

## Could not do
- The plan's exact wording for items 1, 4, 5, 7 and 8, and the f symbol tip. Each broke either the 25-word root line (a test fails) or the 3-line tip limit. The nearest wording that fits is used, and each deviation is listed above.

## Noticed on the way (not changed)
- Shared scratchpad. `scratchpad/root/` (a repo copy last written 2026-10-15 23:19) already existed, and my first setup command put symlinks into it. I removed the 11 nested links I had added. Eleven files had been replaced by links, and I restored them from commit 199be92: `assets/paper.css`, `assets/paper.scss`, `assets/paper-slides.css`, `comparison/site/{explorer.template.html,index.template.html,materials.html,materials.qmd,repro.css,repro.html,repro.qmd}` and `comparison/site/explorer/model.js`. Those 11 may differ slightly from the copy's earlier content, which was a working state about 30 minutes before 199be92. The repository itself was not touched. My own check ran in `scratchpad/wp1root/`.
- The plan read 28.6% from a `d_conf` row of `export/r/inputs.csv`, but no such row exists. `tok$dconf_sept`, `tok$ceiling_literal`, `tok$ceiling_file` and `tok$domestic_grown` are filled but used by neither template.
- The root's a (JR) line keeps only "None on top of the departures it counts". To show the unreported-moves sentence there as well, the 25-word limit or the a source ("NBER chapter Secs. 4-5") would have to change. That is the author's call.
