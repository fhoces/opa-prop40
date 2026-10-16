# Comparison explorer: readability and user-experience review, run 005

Commit reviewed: d246430 (main, 2026-10-16). Page: `comparison/site/explorer/index.html` as built from
`comparison/site/explorer.template.html` by `comparison/R/site.R` (the working tree's three unrelated
modifications do not touch it). Read first: CONTENT-MAP.md, DECISIONS.md, the site conventions, the
confusion-log entries on this page, the run 003 reviews and the run 004 consistency review.

How the page was looked at. Static text with `page_text.py`. Rendered in headless Chrome through
Playwright (viewport emulation; plain `--window-size=390` keeps Chrome's minimum window width and
clips a wider layout, so those shots were discarded) at 320, 390 (touch) and 1280, in light and dark
mode and with print media. Every tip host opened and its line count measured at 390 and 1280. The
Apply buttons pressed in order and out of order, Reset, Walk the path on both panels, every dial at
each end, the middle stops, the minor switch, the footnote links with the sticky bar on, tap-to-show
and tap-to-hide, the "more" two-tap, keyboard arrows on a right-to-left dial, the tab order, the
accessibility tree, link targets (`check_links.py`), overflow and console errors.

## Three reader walks

**A policy analyst who has read neither analysis (desktop).** In ten seconds she has the question
(the title), the two verdicts (the standfirst), the two numbers and the equation. She reads "Each
amount is what its dials change when moved from left to right" and goes to the dials to reproduce the
first term: D to "JR seven" gives $76.9B. She moves q "from left to right" and nothing happens, because
on the BSZ panel q already sits at the right end (U-01). She finds Walk the path and presses it nine
times, which works. She hovers the share-lost ends and sees 50% on the BSZ panel and 45% on the JR
panel for the same JR rule (U-05). Every tip ends in "Kind: ..." and she cannot find what a kind is
without opening the last fold (U-11).

**An economist who has read both papers (desktop).** He accepts −$38.98B after footnote 1 and finds
the order dependence, the q-first counterfactual and the Shapley check in footnote 2. He presses the
Apply buttons under the panels and nothing on screen changes: the estimate they move is 800 px above
(U-02). He checks f: the two panels print different end values with no statement of the rule where
the label is (U-05). "Its 0 revenue floor" is the JR explorer's jargon (U-13). He wants to send a
colleague a setting and the URL carries none (U-19). The rate dial (2.73%, its reason, the worked
$36.6), the A(H, r) gloss and the mid-stop notes satisfy him.

**A journalist with ten minutes (phone).** Title, two numbers, the equation in three rows. The first
slider is 1,300 px down. She taps the superscript 2; the fold opens with its first line hidden under
the result bar (U-04). Walk the path works and she watches the BSZ number fall step by step. At the
Apply block the buttons are 17 px tall and hard to hit (U-03). She reads "JR seven" and "the minor
switch" without a gloss at the label (U-12). The survey button reads as the page's call to action.

## Findings

No blocking finding: the page can be used and nothing on it misreads a number.

### Major

**U-01. "moved from left to right" reads as the dial direction, wrong for four dials.**
Where: under the top equation, "Each amount is what its dials change when moved from left to right,
as the Walk the path button does." (`tok$pseudo_eq_note_x`, `comparison/R/site.R` line 832).
Experience: the board lead puts every dial's smaller value at the left end, so the line reads
literally; on the BSZ panel W, a, q and r start at the right end and the path moves them left.
Proposed: "Each amount is what its dials change when they are moved to the JR values, term by term
from left to right, as the Walk the path button does." Verify: `page_text.py`; `test-site.R` does
not pin this line.

**U-02. An Apply press shows no visible effect on a desktop.**
Where: the Apply block (`#apply`, template lines 375 to 379). At 1280×800 its top is at 1,662 px and
the BSZ panel's "With these sliders" value at 874 px, so after each press `#now-bsz` is outside the
viewport; only the button's text changes. Experience: a reader presses Apply, sees nothing move, and
doubts the button. Proposed: one live line under the buttons, after `{{apply_eq}}`:
`<p class="ap-now">The BSZ panel with these dials: <b id="now-apply">{{bsz_end_b}}</b></p>`, set in
`drawBars()` beside the sticky values (template line 659): `$("now-apply").textContent = money1(vb);`.
Verify: at 1280×800 scroll to `#apply`, press Apply, the line reads $76.9B inside the viewport.

**U-03. The Apply buttons are 17 px tall on a phone.**
Where: `.ap-btn` (template line 240: `font-size: 12px; padding: 0 5px`). Measured at 390: six
buttons 17 px tall, 39 to 58 px wide; the "more" links 14 px, "Copy link" 20 px, the superscript
links 12×6 px. WCAG 2.5.8 asks for 24 px; Apple for 44. Experience: a reader taps and misses, or
hits the operator sign. Proposed, inside the `@media (max-width: 860px)` block (line 258):
`.ap-btn { font-size: 13.5px; padding: 5px 10px; } a.info, a.fn-link { padding-block: 6px; }
.q-copy { padding: 5px 10px; }`. Verify: `getBoundingClientRect().height >= 24` for each at 390;
screenshot of the Apply block.

**U-04. The footnote link lands under the sticky result bar on a phone.**
Where: the superscript 2 (`a.fn-link`, two places) jumping to `#fn-eq`. Measured at 390 after
scrolling: the bar is on (31 px tall) and `#fn-eq` lands at top 0, so the first line "Move the BSZ
panel's dials to their far ends..." is hidden. Experience: the fold opens on a sentence that starts
mid-way; the reader scrolls back. Proposed, in the same media block: `.fold.notes p.fn[id] {
scroll-margin-top: 44px; }` (also covers U-10's `#fn-1`). Verify: tap the 2 at 390 and check
`document.getElementById("fn-eq").getBoundingClientRect().top >= 31`.

**U-05. The share-lost ends differ between the panels and nothing says why where they are shown.**
Where: f ends, BSZ panel "5%" and "50%", JR panel "6%" and "45%" (`fEnds()`: each end is its rule
at the panel's D and a). C-09 of run 004 is still open (its conditional fix was not applied).
Experience: a reader who saw 45% on the overview meets 50% here and doubts the page. Proposed: the
loss box's "more" tip (`EXPLORER_BOXES$loss$more`, `site.R` line 178): "f, C and A(H, r) multiply,
so one dial's effect depends on the others. f also moves with D and a, so its end labels differ
between the panels." Verify: tip audit, 3 lines or fewer at 390.

### Minor

**U-06. The thumb's value repeats the end label whenever a dial sits at an end.**
Where: every dial at the start, for example "Forbes 2026 BSZ" with "Forbes 2026" under the thumb next
to it; on the phone "None named" wraps to two lines beside a second "None named". 22 duplicates on
first view. Experience: clutter, and the end tags (BSZ, JR) get lost. Proposed: in `updatePanel()`
(template line 589), `out.hidden = (p === 0 || p === max);` so the thumb label shows only at a middle
stop; `aria-valuetext` keeps the value. Verify: screenshot of a panel at 390 and 1280 at the start
and at a middle stop.

**U-07. The Apply buttons sit at six different heights.**
Where: `pw-apply-1280.png` style view: Reset and Apply all at the row's top, the other four under
labels of two to four lines. Proposed CSS in the template: `.pseudo-eq.apply-eq, .apply-eq .eq-step
{ align-items: stretch; } .apply-eq .eq-step .op { align-self: flex-start; } .apply-eq .term .ap-btn
{ margin-top: auto; } .apply-eq .term b.ap-label { margin-bottom: 6px; }`. Verify: at 1280 all six
buttons share one `top`; at 390 the buttons of each wrapped row do.

**U-08. Two sections carry the same h2, "What separates the two numbers".**
Where: template lines 324 and 376; both regions are `aria-labelledby` that text. Experience: a reader
scrolling past the panels thinks the page repeated itself; a screen reader lists two regions with one
name. Proposed: line 376 becomes "What separates the two numbers, step by step"; the lead "Apply to
the BSZ panel, from left to right." stays. `test-site.R` pins the lead and the class, not the h2.
Verify: `page_text.py` shows two different headings.

**U-09. The panel notes repeat the panel head in two wordings.**
Where: "Starts at the BSZ analysis's net total, $106.8B." and "Starts at the JR analysis's main
estimate, −$39.0B." (template lines 347 and 369), under the dials, while each head already shows the
estimate twice. Proposed: drop both `<p class="panel-note">`; `test-site.R` lines 39 and 44 use the
JR note as an ordering anchor, so anchor them on `aria-label="The JR panel's sliders"` instead.
Verify: `Rscript comparison/tests/testthat.R` passes; screenshot shows no orphan line under the
minor fold.

**U-10. The footnote 1 marks are not links, while the 2 is.**
Where: `<sup>1</sup>` in the header (template lines 310 and 315) and the panel heads (341 and 363).
Experience: a reader taps the 1 and nothing happens. Proposed: `id="fn-1"` on footnote 1's paragraph
(line 392) and `<sup><a class="fn-link" href="#fn-1">1</a></sup>` in the four places; the existing
handler (line 732) opens the fold. Verify: tap a 1 at 390; the fold opens at footnote 1 below the
bar (with U-04).

**U-11. "Kind: ..." ends every end tip, and the kinds are defined only in the closed last fold.**
Where: the Kinds paragraph in "Notes and data" (template line 452) has no id and no link reaches it.
Experience: "Kind: guesswork on data" or "Kind: derived" in a tip, with no way to find the
definition. Proposed: `id="kinds"` on that paragraph and, in the board lead (line 334), "Tap or hover
over a symbol or an end for what it means and the <a class="fn-link" href="#kinds">kind</a> of each
value." Verify: the link opens the fold and lands on the paragraph.

**U-12. "JR seven" is a coinage at a dial end.**
Where: the D dial's right end (`step_texts()` `rjkdc_short`, `site.R` line 74); the data file and the
overview's quantities table print the same text. Experience: a reader who has not met "the seven"
reads a count without a noun. Proposed: "7 moves" (the end tip already says "seven publicly reported
moves"). Verify: the label fits the 66 px end column at 390 without wrapping; the overview's table
row reads "7 moves. Seven publicly reported moves...".

**U-13. "Its 0 revenue floor" in the a dial's JR end tip is JR-explorer jargon.**
Where: `end_tips$avoidance["rjkdc"]`, `site.R` line 467: "JR: none on top of the departures it counts.
Its 0 revenue floor and its share-lost range also allow for unreported moves. Kind: guesswork."
Proposed: "JR: none on top of the departures it counts. Its revenue draw (down to 0) and its
share-lost range allow for unreported moves. Kind: guesswork." Verify: tip audit, at most 3 lines at
390 (now 24 words at 3.0 lines; the proposal is 23).

**U-14. The BSZ end of the loss box has no worked value for A(H, r).**
Where: the r JR end gives "$1 a year for ever is worth $36.6"; the H and r BSZ ends give none. The
confusion log (2026-10-15) asked for the 5-year instance. Proposed: the H BSZ end tip (`site.R` line
484, now 12 words, two lines): "BSZ: about the payment period, treating the responses as temporary.
$1 a year for 5 years is worth $%s at 3%%. Kind: scenario." with `formatC(mv("A_5"), format = "f",
digits = 1)` (`export/r/meta.csv` row `A_5`, 4.58) and `tok$r_bsz` for the rate. Verify: tip audit at
390; the number equals `annuity(0.03, 5)` from `model.R`.

**U-15. The equation's spoken label lowercases the dial letters.**
Where: `say()` in `site.R` lines 757 to 758 applies `tolower()` to the whole label, so the
`aria-label` reads "minus $29.89B for billionaires already departed (d)" and "(h, f, c, r)",
"(w, a, the minor switch)". Experience: a screen reader user hears letters that match no dial.
Proposed: lowercase the first character only, `sub("^([A-Z])", "\\L\\1", label, perl = TRUE)`.
Verify: `grep -o 'aria-label="The BSZ estimate[^"]*"' comparison/site/explorer/index.html` shows
"(D)", "(q)", "(H, f, C, r)", "(W, a, the minor switch)".

**U-16. The JR panel's Walk the path runs the equation backwards and nothing says so.**
Where: footnote 2, "The Walk the path button in each panel does it for you." (`tok$eq_fn_x`, `site.R`
line 836); measured: the JR walk goes −$33.6B, −$46.1B, ... $106.8B, outlining the last term first.
Proposed: "The Walk the path button in each panel does it for you. The JR panel's button walks it
backwards, from the last term to the first." The test pins only the note's first four sentences
(lines 176 to 180). Verify: `page_text.py`.

**U-17. The walk gives no sense of progress for eight presses.**
Where: `setWalk()` (template line 709) keeps "Walk the path" until the last step, then "Start over".
Proposed: `walkButton(panel).textContent = k === NP ? "Start over" : "Next step (" + k + " of " + NP +
")"`; the initial label is unchanged (pinned, test line 182). Verify: one press shows "Next step
(1 of 9)"; nine show "Start over".

**U-18. Three tab stops per dial.**
Where: each `.sl-end.has-tip` has `tabindex="0"` (`end_span()`, `site.R` line 642); measured 64 Tab
presses from the first BSZ slider to the Apply block. Proposed, without removing a feature: give each
slider the three tips in its description, `aria-describedby="<panel>-<id>-tip <panel>-<id>-bsz-tip
<panel>-<id>-rjkdc-tip"` (`slider_row()`, line 658), so a screen reader hears both ends at the slider;
whether to drop the ends' `tabindex` is a question below. Verify: the accessibility tree's slider
description contains "BSZ:" and "JR:".

**U-19. The URL carries no state, so a setting cannot be shared or survive a reload.**
Where: no hash or query handling in the page script; the sibling explorers have none either.
Proposed: after every `renderPanels()` write the two panels' positions to the hash with
`history.replaceState` (as the overview's fold script does), and read them before the first render.
Verify: move three dials, reload, the dials and both estimates are unchanged; the shared link opens
the same.

**U-20. Printing: the sticky bar prints on every page once shown, and the two folds print closed.**
Where: `.sticky-result` is `position: fixed` with no print rule; `details.fold` closed. Proposed:
`@media print { .sticky-result { display: none; } }` and `window.addEventListener("beforeprint",
function () { document.querySelectorAll("details.fold").forEach(function (d) { d.open = true; }); });`.
Verify: Playwright `emulateMedia({ media: "print" })` at 800 px after scrolling: no bar, notes
visible.

**U-21. The conventions paragraph in the notes fold restates the report's conventions.**
Where: template lines 410 to 423 (installments, deferral account, r − g, mismatch 3), about 190
words. The rule allows footnotes; this is a choice, not a breach. Proposed: keep "Conventions. All
amounts are billions of dollars. Present values are as of the date the wealth tax is assessed, and
the first year of lost income tax is counted one year later." and replace the rest with "The
<a href="../repro.html#conventions">report's conventions</a> cover the face-value wealth tax, the
Act's installments and deferral account, and the JR analysis's r − g rate.", adding `{#conventions}`
to that paragraph in `repro.qmd` (it follows `#the-discount-rate` with no id). Verify:
`check_links.py`.

**U-22. Two folds both called "Notes".**
Where: "Notes on the two estimates and the conventions" and "Notes and data" (template lines 390
and 429). Proposed: the second becomes "Where the numbers come from: code, data and kinds". Verify:
`page_text.py`.

**U-23. "But what are the actual quantities?" is an h3 styled larger than the page's h2 kickers.**
Where: `#q-title` (17 px bold serif) against the 14.5 px small-caps h2s; the hierarchy reads inverted
in `pw-print.png` and at 390. The text is pinned (test line 530). Proposed: style it as a kicker in
the template, `.quantities h3 { font-size: 14.5px; font-weight: 400; font-variant-caps: all-small-caps;
letter-spacing: 0.08em; color: var(--ink-3); }`, or make it an h2 and update the pin. Verify:
screenshot at 1280.

**U-24. The footer differs from the sibling explorers'.**
Where: this footer links three overviews; the BSZ and JR explorers' footers link one each (their
own), and CONTENT-MAP rule 5 calls the footer a shared element. Proposed: one form on the three
explorers; this page's matches the root overview's. Which form is the author's choice (question
below). Verify: `grep -A4 "<footer" */site/explorer/index.html`.

**U-25. "Why are the results different?" repeats the title's question.**
Where: `#board-title` (template line 330), between the h1 "Why do the two analyses of Proposition 40
disagree?" and the equation's "What separates the two numbers". Proposed: "The inputs", the heading
the BSZ and JR explorers use for their dials; the lead sentence then explains the sliders. Not pinned.
Verify: `page_text.py`.

## Checked and fine

- Numbers and anchors: $106.8B in the header, panel head, chart and sticky bar; $106.80B and −$38.98B
  in the equation; −$39.0B everywhere else, with footnote 1 saying why (−$38.98B is the exact
  average, −$38.9B the printed run). The equation's terms add to the JR estimate; `[apply 1..4]`
  gave $76.9B, $37.5B, −$43.9B, −$39.0B, the walk the nine running values, and q moved first by hand
  gave $53.0B, consistent with footnote 2's −$53.75B.
- Behaviour: Apply buttons unlock left to right and lock right to left, with titles on hover; Reset
  and Apply all always work; every dial at its far end reproduces the other analysis's value in both
  panels; the minor switch reads "mixed" when one of its three dials moves; middle stops show the
  construction note and the D stop its Table 5 row 3 note; a hand move ends a walk.
- Touch: first tap shows, second hides, a tap elsewhere closes, one tip at a time; "more" shows its
  bubble on the first tap and follows the link on the second; the box headings' formula tips open on
  tap.
- Tips: 80 hosts, all at most 3 lines at 390 and 1280, none off screen; every dial has a symbol gloss
  and two end tips with a Kind label; A(H, r) is glossed on the box; the rate dial gives one rate
  (2.73%) with its reason and a worked $36.6; the D tip names the people; the f ends print
  percentages in plain words with the 28.6% to 45% instance.
- Layout: no overflow at 320, 390 or 1280; the equation wraps into three rows at 390 with each sign
  on its term's line; the chart's zero line and scale (−$40 to $120) stay fixed; the chart is sticky
  at 1280; dark mode renders; no console or page errors.
- Keyboard and screen readers: sliders have names ("wealth W wealth on the list"), descriptions
  (the symbol tip) and `aria-valuetext` with the position; arrow keys follow the visual direction on
  right-to-left dials; focus rings on dials, ends and buttons; the two estimates are `aria-live`.
- Navigation: two-row nav as on the siblings; all links resolve (`check_links.py` prints nothing);
  the report anchors `#the-main-estimate`, `#the-two-ends`, `#the-bridge`, `#order-free-check`,
  `#step-revenue`, `#step-loss`, the JR report's `#step-npv`, the JR materials' `#mismatches` and
  the overview's `#differences` and `#how-ai-was-used` exist; the credit footer is present; no
  badge, as the comparison's credit answer requires.
- First screen: at 1280 the title, both verdicts, both numbers and the equation are above the fold;
  at 390 the title, verdicts and both numbers are, with the equation's kicker at the fold.

## Questions for the author

1. U-18: should the dial ends stop being tab stops (one stop per dial, the two end tips read in the
   slider's description), or stay focusable so keyboard users can open an end tip?
2. The header's JR definition repeats the printed −$38.9B sentence that footnote 1 also carries
   (run 003 put it on the root's first screen). Keep both, or trim the header to the definition?
3. The equation says "the minor switch" and the dial says "Three minor inputs" (both your words in
   DECISIONS.md). Keep, or name the term "(W, a, the three minor inputs)"?
4. U-24: which footer form for the three explorers, the three-overview one here or the own-overview
   one on the BSZ and JR explorers?
