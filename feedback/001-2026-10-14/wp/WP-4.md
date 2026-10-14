# WP-4: The BSZ explorer
Owner: opus. Status: done.

## Changed
- `bsz-analysis/site/explorer/index.html`: standfirst now reads "estimate about $100 billion of wealth tax ($104 billion in their Table 5). Add the income tax the tax changes and the total is this site's **main estimate**." (V-24, V-06, A-01)
- `bsz-analysis/site/explorer/index.html`: headline `.def` replaced with the K2 BSZ explorer text ("Defined as the wealth tax, plus the extra income tax from assets sold to pay it, minus the income tax lost to billionaires who leave, counted over 5 years in today's dollars (present value at 3% a year)."); `.headline .def` 13.5px to 15px (K2, V-02, V-09). This also covers KG "present value" for this page.
- `bsz-analysis/site/explorer/index.html`: footnote rule `p.fn` 12px `--ink-3` to 13.5px `--ink-2` (K2, V-09). The page has no `.headline .fn`; its footnote 1 is the `p.fn` under the bars, so the K2 `.fn` sizes went there.
- `bsz-analysis/site/explorer/index.html`: footnote 1 now says "about $100 billion in the abstract and $104 billion in Table 5 (reproduced here as <span id="pref-wt">)" and links "the RJKDC analysis" and "the comparison overview" (A-01, V-06, V-08, K6). The `pref-wt` span and its script are unchanged; it still prints $103.8 billion from `grid.js`.
- `bsz-analysis/site/explorer/index.html`: a `<p class="small">` under the rack legend with the E-06 text on whose levels these are and the four origin definitions (E-06). Added `p.small` CSS (12.5px, `--ink-2`, the page's style for `.dial .desc` and the scenario key) because the page had no `.small` rule. **Deviation from the plan's wording:** I added "the two yes/no switches instead turn on the authors' own Table 5 scenarios (rows 2 to 4)". Without it the sentence is false for the Pareto and leavers switches: their "yes" level is the authors' own Table 5 rows 2 to 4 (`grid.js` `named`: "Missing billionaires" has pareto = 1, "Leavers" has leavers = 1), not a level this OPA chose.
- `bsz-analysis/site/explorer/index.html`: the tooltip now has a line "Other levels: this OPA's." after "The authors use: ..." (E-06). It appears only on the four dials with numeric levels (avoidance, share leaving, share sold, less visible billionaires), **not on the two yes/no switches**, for the same reason as above. The string appears once in the file, so the acceptance count is 1.
- `bsz-analysis/site/explorer/index.html`: under each dial's label, a `div.desc` with the first sentence of `dial.desc` (cut at the first ". "). It uses the page's existing `.dial .desc` rule (12.5px, `--ink-2`), which was defined but unused. The full text stays in the tip (V-25).
- `bsz-analysis/site/explorer/index.html`: in Notes and data, "RJKDC report" became "RJKDC analysis" twice and "comparison OPA" became "comparison overview" (K6, V-08).
- `bsz-analysis/site/explorer/index.html`: K9 scroll hint on `.table-scroll` (the page has no `.chart-scroll`) (V-14).
- Shared kit: K2 (headline `.def` and footnote sizes) and K9 (scroll hint) are applied on this page.

Acceptance:
- The grep for "that is the <strong>main estimate", "other analyses" and "comparison OPA" finds nothing.
- `grep -c "Other levels: this OPA"` is 1.
- No "RJKDC report" is left on the page, and there are no em or en dashes in the added lines.
- The rendered text (`screenshot.cjs --text`) shows a description under each of the six dials. The headline is unchanged: "MAIN ESTIMATE¹, BASE SCENARIO $106.8B". The footnote prints "$103.8 billion" from the grid.
- With a tooltip opened by `--click`: avoidance shows "The authors use: 10% (guesswork) / Other levels: this OPA's.", and the Pareto switch shows "The authors use: no (research)" with no "Other levels" line.
- Screenshots at 390px (full page, outcome table open) and 1280px look right. The scroll hint shows above the table on the phone. The header still fits with the longer `.def` at 15px.
- `check_links.py` reports no new broken link; the only broken links before and after are in `feedback/`. The tags balance.
- `git diff --stat` for my file shows only `bsz-analysis/site/explorer/index.html` (36+, 12-). Other files in `git status` belong to other packages.

## Needs a local render
- none (hand-written HTML; no generator, and `grid.js` is untouched)

## Needs a follow-up (files outside the package)
- `review/seed_bsz.py` line 79 to 81: this file's line numbers moved. If the seed is re-run at a new commit, change `method_ref` "(lines 219-225)" to "(lines 225-232)" and `loc(..., [485, 503], ...)` to `[509, 527]`. The published `review/bsz.json` is pinned to commit d505360 and is still correct as it stands.

## Could not do
- Nothing. The two deviations above, the switch clause in the note and the tooltip line left off the two switches, keep the plan's sentences true; the coordinator may prefer another wording.

## Noticed on the way (not changed)
- The links inside footnote 1 (`p.fn a`) have no rule and render in the browser's default blue with an underline. `.standfirst a` and `.note a` use `--series-1`. This was already the case before this package.
- The ⓘ button of "Avoidance by the less visible billionaires" is disabled while the Pareto switch is off, because `render()` disables every button in that row, the info button included. Its tip then opens only on mouse hover, not on tap or keyboard. Already the case before.
- The Pareto switch's tip says "The authors use: no (research)". The authors also use "yes" (Table 5 rows 2 and 4); "no" is only the base row's value. The orange "the value the authors use" mark has the same base-row reading. The new note under the rack now says so in words.
- `.preferred` and `.preferred p.fn` CSS (lines 93 to 101) style no element on the page (dead CSS).
- `bsz-analysis/R/site_exports.R` line 55 has a code comment, not page text, saying "the RJKDC report uses".
