# Run 005, implementation report

Implementer: one Fable agent at xhigh effort (author answer 2026-10-16). Base: main at d246430.
Nothing committed. The author's three uncommitted files (`.gitignore`, `bsz-analysis/py/run_export.py`,
`PLAN-3-learning-materials.md`) are untouched.

Status: 26 of 26 items done.

## Per item

Sources: `T` = `comparison/site/explorer.template.html`, `R` = `comparison/R/site.R`,
`S` = `comparison/tests/testthat/test-site.R`. Generated after the edits by `Rscript comparison/run.R`
and `python3 comparison/py/bridge.py`: `comparison/site/explorer/index.html`, `index.html`,
`assets/comparison-data.js`.

| # | Id | Status | What changed |
|---|---|---|---|
| 1 | U-01 | done | `R`, `tok$pseudo_eq_note_x`: "Each amount is what its dials change when they are moved to the JR values, term by term from left to right, as the Walk the path button does." |
| 2 | U-02 | done | `T`: `<p class="ap-now">The BSZ panel with these dials: <b id="now-apply">` after `{{apply_eq}}`, CSS `.ap-now`; `drawBars()` sets `now-apply` beside the sticky values. Audit at 1280: after one Apply press the line reads $76.9B inside the viewport. |
| 3 | U-03 | done | `T`, the `max-width: 860px` block: `body.pg-explorer .ap-btn { font-size: 13.5px; padding: 5px 10px }`, `a.info, a.fn-link { padding-block: 7px }` (the review's 6 px left the panel heads' marks at 22 px), `.q-copy { padding: 5px 10px }`; the `body.pg-explorer` prefix outranks `paper.css`'s `.q-copy`. Measured at 390: Apply 29 px, "more" 28, footnote marks 24 to 28, Copy link 28. |
| 4 | U-04 | done | `T`, same block: `.fold.notes p[id] { scroll-margin-top: 44px }` (covers `#fn-eq`, `#fn-1` and `#kinds`). Audit at 390 with the bar on: the footnote 2 and footnote 1 links land at top 44 px, bar bottom 31. |
| 5 | U-05 | done | `R`, `EXPLORER_BOXES$loss$more`: "... f also moves with D and a, so its end labels differ between the panels." 3.0 lines at 390. Closes C-09 of run 004. |
| 6 | U-06 | done | `T`, `updatePanel()`: `out.hidden = (p === 0 \|\| p === max) && txt !== "mixed"`. The minor switch keeps its "mixed" label (its two positions are both ends, and no end label carries "mixed"); `aria-valuetext` keeps the value. Audit: 0 of 24 thumb values visible at the start, D's middle stop shows "BSZ four, $333.6B". |
| 7 | U-07 | done | `T`, CSS after `.ap-btn:disabled`: the review's four rules. Audit at 1280: all six buttons at one top (391). At 390 the buttons of each wrapped row share a baseline (screenshot). |
| 8 | U-08 | done | `T`, `#apply-title`: "What separates the two numbers, step by step". |
| 9 | U-09 | done | `T`: both `<p class="panel-note">` dropped, the `.panel-note` CSS rule with them. `S` lines 39 and 44 re-anchored on `aria-label="The JR panel's sliders"`, plus a check that no `panel-note` is left. |
| 10 | U-10 | done | `T`: `id="fn-1"` on footnote 1; the four marks are `<sup><a class="fn-link" href="#fn-1">1</a></sup>`. The header's two marks sat inside `a.hl`, and a link cannot hold a link, so the header now has the root overview's structure: `<div class="hl">` with the name (holding the mark), `<a class="value" ... id="hl-bsz">` as the link, and the definition. The CSS `a.hl` rules became `a.value`. `S` line 484 already allowed the link. |
| 11 | U-11 | done | `T`: `id="kinds"` on the Kinds paragraph; the board lead ends "... for what it means and the <a class="fn-link" href="#kinds">kind</a> of each value." The existing handler opens the fold; audit: lands at top 412 with the bar at 31. |
| 12 | U-12 | done | `R`, `step_texts()`: `rjkdc_short = "7 moves"`. The data file (`rjkdc_text`) and the overview's table row ("7 moves. Seven publicly reported moves...") follow. At 390 the label is one line, 43 px wide in the 66 px column. |
| 13 | U-13 | done | `R`, `end_tips$avoidance["rjkdc"]`: the review's text. 3.0 lines, 25 words at 390. |
| 14 | U-14 | done | `R`, `end_tips$horizon["bsz"]`: "... $1 a year for 5 years is worth $4.6 at 3%." built from `fmt_input("H", h_bsz)`, `formatC(mv("A_5"), "f", 1)` and `tok$r_bsz`, with `stopifnot(abs(mv("A_5") - annuity(mv("r_bsz"), h_bsz)) < 1e-9)` at build time (A_5 = 4.5797, annuity(0.03, 5) = 4.5797). 3.0 lines at 390. `S` lines 413 to 416 ("the H dial's tips name no rate") now expect this one worked value and no other rate, and check A_5 against `annuity()`. |
| 15 | U-15 | done | `R`, `say()`: `sub("^([A-Z])", "\\L\\1", label, perl = TRUE)`. The spoken equation now reads "(D)", "(q)", "(H, f, C, r)", "(W, a, the minor switch)" on both pages (`index.html` changed by this line only, plus item 12's table cell). |
| 16 | U-16 | done | `R`, `tok$eq_fn_x`: "The JR panel's button walks it backwards, from the last term to the first." after the Walk sentence. The pin on the first four sentences is unchanged. |
| 17 | U-17 | done | `T`, `setWalk()`: "Next step (k of 9)" after each press, "Start over" at the end; `endWalk()` restores "Walk the path" (pinned, unchanged). Audit: the ten labels in order. |
| 18 | U-18 | done | `R`, `end_span()`: the ends lose `tabindex` and their own `aria-describedby`; `slider_row()` gets a 14th argument, `desc`, listing `<panel>-<id>-tip`, `-bsz-tip`, `-rjkdc-tip`. `S` lines 281 and 319 pin the three-id form; a new line checks no end has `tabindex`. Audit: the H slider's description text contains "BSZ:" and "JR:"; 30 tab stops from the first BSZ slider to the first Apply button (was 64). Touch and hover on the ends unchanged. |
| 19 | U-19 | done | `T`: `readHash()` before the first render, `writeHash()` at the end of `renderPanels()`. Form `#bsz=<12 digits>&rjkdc=<12 digits>`, one digit per slider in page order (`history.replaceState`). All dials at the start write no hash, so `#fn-eq` in the address is left alone; Reset clears a state hash. Audit: three dials moved, the hash reloaded, same positions and estimates ($76.6B, −$19.5B). |
| 20 | U-20 | done | `T`: `@media print { .sticky-result { display: none } }` and a `beforeprint` listener that opens both folds. Audit with print media: bar `display: none`, both folds open after the event. |
| 21 | U-21 | done | `T`: the conventions paragraph keeps its first two sentences and ends "The <a href="../repro.html#conventions">report's conventions</a> cover the face-value wealth tax, the Act's installments and deferral account, and the JR analysis's r − g rate." `comparison/site/repro.qmd` line 250: `[]{#conventions}` before "**Conventions.**" (the file's own pattern, as `[]{#the-discount-rate}`); `repro.html` re-rendered, one line changed. |
| 22 | U-22 | done | `T`: the second fold's summary is "Where the numbers come from: code, data and kinds". |
| 23 | U-23 | done | `T`: `body.pg-explorer .quantities h3 { ... 14.5px; 400; all-small-caps; 0.08em; var(--ink-3); margin: 0 0 14px }`. The selector outranks `paper.css`'s `body.pg h3` (the review's `.quantities h3` would not). The text is unchanged (pinned). |
| 24 | U-25 | done | `T`: `#board-title` is "The inputs". |
| 25 | header | done | `T`: the JR definition is "Net present value: the wealth tax minus the income tax lost for ever, in today's dollars." The printed −$38.9B sentence lives in footnote 1 only. No `test-site.R` pin held the header sentence. `{{nber_printed}}` and `{{nber_growth}}` are still filled (the root template uses them). |
| 26 | U-24 | done | `bsz-analysis/site/explorer/index.html` and `rjkdc-analysis/site/explorer/index.html` (hand-written sources per CONTENT-MAP, no generator): the footer takes the comparison explorer's form, "Comparison overview · BSZ analysis overview · JR analysis overview", with "the two analyses" as the comparison explorer says (the siblings said "both analyses"). Relative paths from `<analysis>/site/explorer/`. Their suites pin nothing in the footer; both pass. |

One change outside the list, needed by item 14: `R`, `q_cell()`'s first-sentence cut recognised a
second sentence only when it starts with a capital letter, so the H dial's BSZ cell in the
overview's quantities table ran to 27 words with the new "$1 a year..." sentence. The cut (and the
source insertion) now also treat a sentence starting with "$" as a sentence; the table cell keeps
the first sentence (15 words) and the tip keeps the worked value.

## Rebuilt

- `Rscript comparison/run.R && python3 comparison/py/bridge.py`: `comparison/site/explorer/index.html`,
  `index.html` (the spoken equation's letters, the "7 moves" cell), `assets/comparison-data.js`
  (`rjkdc_text` of the departures dial).
- `cd comparison/site && quarto render repro.qmd`: `repro.html`, one line (the `conventions` span).
- The BSZ and JR explorers are hand-written and needed no rebuild.

## Tests and checks

1. `Rscript comparison/tests/testthat.R`: 1029 expectations, 0 failed, 0 skipped (the model.js
   parity and Apply-order tests ran with node).
2. `cd bsz-analysis && Rscript tests/testthat.R`: 778 expectations, 0 failures.
3. `RAUH_REPO_DIR=.../2026-09-23_wealth_tax-repo Rscript tests/testthat.R` from `rjkdc-analysis/`:
   191 expectations, 0 failures (one ggplot2 version warning, pre-existing).
4. `python3 .claude/skills/opa-review-loop/tools/check_links.py`: prints nothing.
5. Em-dashes on added lines: 0 (added lines grepped for the em-dash character).
6. Playwright audit (`scratchpad/impl-audit.cjs`, adapted from the reviewer's `ux-audit.cjs`,
   run from the scratchpad with its `playwright-core`): 37 checks, all pass. Tips: 80 hosts, max
   3.0 lines at 390 and at 1280, none off screen. No overflow at 320, 390 or 1280; no page or
   console errors. The mirror check (100 random settings, both panels) gives 0 mismatches.
   Screenshots: `impl-phone.png` (390, full page), `impl-desktop.png` (1280, full page),
   `impl-apply-390.png`, `impl-apply-1280.png`, `impl-panel-390.png`, `impl-panel-mid-1280.png`,
   `impl-320.png` in
   `/private/tmp/claude-502/-Users-fernando-Desktop-sandbox-opa-prop40/23414a84-28e1-42c3-98f3-b6ff11eabcef/scratchpad/`.
   Looked at: no overflow; the six Apply buttons on one line at 1280 and aligned within each
   wrapped row at 390; no thumb value at any end, the value at a middle stop; the trimmed header
   with the footnote marks; the two kickers; the fold titles; the footer.

## Could not do

Nothing.

## For the author to decide

- U-10 changed the header's structure (the value is the link, the name and the definition sit
  outside it), the same structure as the root overview's header. The whole block was the link
  before (author request 2026-10-15). If the name should stay clickable, the footnote mark cannot
  be a link there.
- U-19 keeps the state in the hash, so a click on a footnote mark replaces it with `#fn-eq` or
  `#fn-1` until the next dial move rewrites it. Harmless for a reload (the dials then start at
  the ends), but a copied link taken right after a footnote click carries no state. The sibling
  explorers still carry no state in the URL (the item said comparison only for now).
- U-12 renamed the dial end only. The long form "the JR seven: $614B on the BSZ list, $578B on
  the JR list" (`step_texts()`, used by `differences_rows`, which no template reads today) and the
  comment in `comparison/R/build.R` line 37 still say "the JR seven".
- U-24: the three explorers now say "the two analyses" in their footer (the comparison explorer's
  and the root's wording). The BSZ and JR overviews' footers say "both analyses" and link the
  other two pages in a sentence rather than a list; CONTENT-MAP rule 5 calls the footer a shared
  element, so those two pages could take the same list form.
- `DECISIONS.md` and `AUDIT.md` were not touched (records). The answers in `02-improvements.md`
  (one tab stop per dial, the header trimmed to the definition, three overviews in every
  explorer's footer) may belong in `DECISIONS.md`.
