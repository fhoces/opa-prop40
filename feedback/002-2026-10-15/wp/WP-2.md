# WP-2: The comparison deck
Owner: opus. Status: done.

## Changed
- `comparison/site/slides/slides.Rmd`, slide opa-comparison: the common output is now glossed ("the net fiscal effect (the wealth tax, plus income tax from asset sales, minus the present value of income tax lost)") (E-01). "What reproduces" now says each bridge step is the change from moving one explorer dial, in R and in the browser, and that the steps add up by construction (E-23).
- Same file, slide pseudo-eq: a two-sentence intro above the equation defines output (b) and the dial path (E-20, V-26). The paragraph after it now says "the three largest steps on this path", then "The sizes depend on the order." It also names the three largest by the order-free check, computed inline from `ex$bridge` (own horizon, output b, `shapley`), largest first. The text is a symbol plus `DIAL_NAMES`: *q* (chance it survives court), *f* (share lost) and *H* (years counted) (A-13, E-08).
- Same file, slide diff-departed, BSZ cell: "No named departure is removed", with the fn.30 sentence and "Its 10% avoidance already counts 5% of billionaires who left in time (BSZ PDF p.24)". Both percentages are `pct(sup$alpha, 0)` and `pct(sup$alpha * sup$m, 0)` (A-03).
- Same file, slide diff-litigation: the JR cite is now "chapter Secs. 4.2 and 4.4, PDF pp.19-23, eqs. 3 and 6" (A-06). The BSZ cell gets the GGSS p.11 sentence (A-28).
- Same file, slide diff-horizon: the BSZ cell now gives five years as BSZ's example and as this OPA's reading (A-07). The JR cell now gives the not-return reason (p.32, Sec. 6) and the growing perpetuity 1/(r &minus; g), Sec. 5.2, eqs. 13-14, pp.30-31 (A-04, A-06, A-10).
- Same file, slide smaller: the share-lost bullet now names the BSZ benchmark movers and the proportionality assumption (p.24), plus named leavers from filings (E-07). The discount-rate bullet now says "draw of r &minus; g (the real rate net of the loss's growth)" (A-10).
- Same file, slide next: the dial-path bullet now matches opa-comparison (E-23). Shapley gets a gloss (E-20).
- Same file, slide estimates, blue box: only the lost income tax is discounted, and the wealth tax is at face value. "One analysis says" became "On the common definition, the BSZ analysis's inputs give a gain of about ... and the JR analysis's a loss of about ..." (A-02, E-01).
- Same file, slide common-output: "5 years for the BSZ analysis (this OPA's reading of BSZ's example, PDF p.27)" (A-07). "The JR analysis draws r &minus; g, the real rate net of the loss's growth, at random between" (A-10).
- Same file, slide term-loss: "draws r &minus; g between" (A-10). The symbol r in "worth 1/r at the rate r" stays.

Where the text differs from the plan's wording, and why:
- The plan's semicolons became separate sentences (estimates box, diff-departed, diff-horizon BSZ cell, opa-comparison, next).
- pseudo-eq: the plan said "each amount is what one move changes". It now says "Each amount is what its dials change", because the loss term and the last term each group several moves.
- smaller: the plan said "the half of its 10% avoidance who move". It now says "the avoiders who move (`r pct(sup$m, 0)` of its `r pct(sup$alpha, 0)` avoidance allowance)", so no number is typed.
- Fitting the slides. With the plan's text, pseudo-eq overflowed by about 95 px (the list of claim kinds fell off the slide), and diff-horizon's box ran past the bottom edge. Fixes made, all in this file:
  - pseudo-eq: the intro is in `.small`.
  - pseudo-eq: the note under the equation loses its first sentence, "Move the BSZ panel's dials to their far ends, term by term from left to right.", which the intro now says.
  - pseudo-eq: the five claim kinds are one small paragraph instead of a list, with the same words.
  - diff-horizon: "Table 5 itself takes no stand" became "Table 5 takes no stand".
  - diff-horizon: the slide got `class: wide-right` and a small `{css}` chunk on the slide (bottom columns 36% / 60%), so the dollars box takes fewer lines.
- diff-departed: "assumes four of them left" became "assumes four named billionaires left". After the inserted sentence, "them" read as four of the 5%.
- diff-horizon JR cell: the bold label prints "Perpetuity." (from `fmt_input("H", rj$H)`, kept as the plan says), not the plan's "For ever.".

Checks:
- Every page reference was checked in the PDFs: BSZ pp.22, 23 fn.30, 24 and 27; GGSS July 2026 p.11; chapter Sec. 4.2 (p.19, eq. 3), Sec. 4.4 (pp.22-23, eq. 6), Sec. 5.2 (pp.30-32, eqs. 13-14 on p.31), and the not-return passage on p.32 citing Sec. 6.
- The acceptance greps pass. None of the seven old strings remains. `git diff aff381c` has no hunk in lines 1 to 420. Every new number is inline R. No en or em dash was added. `check_links.py` exits 0 with no output.
- The deck was rendered in an isolated copy under the scratchpad, using the committed `comparison/R/*.R` and the current exports through symlinks. Nothing in the tree was written. The render passes its `stopifnot` ties and gives 31 slides. I printed it to PDF in headless Chrome and read all ten changed slides at 80 dpi. All fit, the lowest at row 551 of 568 (diff-horizon); pseudo-eq ends at row 505. The committed deck was rendered the same way for comparison. `screenshot.cjs` was skipped because Playwright is missing (00-run.md).

## Needs a local render
- `comparison/site/slides/slides.Rmd`: after `Rscript comparison/run.R`, run `RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("comparison/site/slides/slides.Rmd")'`. Then look at pseudo-eq (slide 17) once WP-1's new equation labels and note are in. My check used the committed R, and the slide has about 30 px to spare.

## Needs a follow-up (files outside the package)
- None.

## Could not do
- None.

## Noticed on the way (not changed)
- Slide smaller, table: the BSZ value of *f* prints "what leavers paid" (`step_texts()` in `comparison/R/site.R`, WP-1's file). E-07 notes the same label on the report. At the benchmark these are the avoiders who move, assumed to pay in proportion to wealth.
- Setup chunk comment, line 61: "the authors' draw between r_lo and r_hi" still says r, not r &minus; g. It is a code comment inside lines 1 to 420, which this package must not touch.
- Slide smaller, share-lost bullet: "while the loss still lasts 5 years" types the BSZ horizon. This was already there.
- A-13 also suggested putting the share lost's order-free size next to its path step on slide smaller. It is not in the plan, so I did not add it.
