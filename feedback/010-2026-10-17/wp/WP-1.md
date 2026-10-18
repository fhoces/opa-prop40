# WP-1: Comparison generator: the root's first screen, the table of differences, the tips and the equation's labels
Owner: coordinator. Status: done.

## Changed
- `comparison/site/index.template.html`:
  - First paragraph. BSZ is no longer the subject of the net total: "Adding the income tax raised on assets sold to pay it, and subtracting the income tax lost to billionaires who leave over {{h_bsz}}, gives this OPA's net total for the BSZ analysis, {{hl_bsz}}." (A-01, V-02)
  - T1 added after "payable over five years.", linking `docs/initiative/README.md` (V-03).
  - The one-measure sentence now includes "plus the income tax from assets sold to pay it" (E-01, V-28).
  - BSZ card: "lost income tax counted for {{h_bsz}} (this OPA's reading of BSZ's example)" (A-01).
- `comparison/R/site.R`:
  - `order_note()` (E-02, V-01). One generated sentence after "For scale" explains why the $81.34B term is larger than the gap between $75.0B and $0.7B. Avoidance moves last, so the share lost is 50%, not 45%, because it still holds the BSZ movers' 5%. Moving avoidance gives $8.33B back. Every amount comes from `score_common()` at the path states, with `stopifnot()` checks, and the sentence links the report's `#lost-income-tax-scale`.
  - `pseudo_eq_note_root`: "then the other three" becomes "then the other inputs".
  - `eq_terms()` (E-27, V-27): the last term is "Other inputs together (W, a, the minor switch)" on the explorer and in the Apply block. On the overview it is "Other inputs together: the wealth on the list, avoidance, and three smaller inputs", from a new `root_label` column guarded by a `stopifnot()` on the term's steps. The note reads "The D and q terms are single steps of the dial path", and "of the walk" becomes "of the path" (V-19).
  - `fmt_input()`: the perpetuity prints "for ever" (V-26). The JR H tip no longer repeats it: "JR: leavers are assumed not to return once ...".
  - End tips. Each changed tip's first sentence (the part the quantities table keeps) now carries the value's reason:
    - W, BSZ: worth $2,307B, or $2,157B without the non-US citizens (A-24).
    - W, JR: "grown 7%, the Act's growth figure" (A-11).
    - D, BSZ: "half of the 10% avoidance, 5% of the wealth, is people who moved in time". Both numbers are computed from `alpha` and `alpha × m` (A-21, E-23, V-23).
    - D, JR: "seven counted as moved in time, 28.6% of the wealth" (`d_conf_jr`).
    - a, JR: "none beyond the departures it counts, since US securities are third-party reported" (A-16).
    - q, JR: "the wealth tax is multiplied by the chance it survives in court" (A-22, V-25).
    - f, BSZ: "the share of wealth assumed to leave, except named leavers, who pay little income tax for their wealth". This is true on both panels; "no more than" is gone (A-20, E-25, V-24).
    - f, JR: "more than the 28.6% of wealth counted as gone, since income tax need not leave in step with wealth".
    - Non-citizens, JR: the reason in the first sentence (V-29).
    - Real estate, JR: "about 0.5% of the whole base" (A-17).
  - `step_texts()`, the share-lost cells: BSZ "the share of wealth assumed to leave, except named leavers, who take only their own tax"; JR "45% of all, more than the share of wealth counted as gone" (A-20).
  - `hoopes_differences()`: "ours", "our", "we" and "We could not trace" become "this OPA's" and "This OPA could not trace" (V-18).
- `comparison/site/explorer.template.html`: the script's H label "perpetuity" becomes "for ever" (V-26). The board lead reads "Each dial (a slider) moves one disputed input" (jargon).
- `comparison/tests/testthat/test-site.R` l.152: the last term's pin is now the per-page label. Every other check is kept.

## Checks (run in a scratch copy of the tree, so the repo's generated files are untouched)
- `Rscript comparison/run.R`, then `Rscript comparison/tests/testthat.R`: 1122 expectations, 0 failed. This includes the 25-word limit on every quantities cell and the label pins.
- Tip audit with playwright-core and Chrome, all tips forced open:
  - Comparison explorer: 80 tips, maximum 3 lines at 390 px and at 1280 px, none outside the viewport.
  - Page width 390/390 and 1280/1280, no page errors.
  - Two JR tips (D and a) were at 4 lines at 390 px. They were shortened: the D end lists the seven names without "of their moves", and the a end's second sentence reads "Its draws cover unreported moves."
- Screenshots of the root's equation (390 and 1280) and the explorer's equation and Apply block: the layout holds. At 1280, the root's last term label wraps to four short lines.
- Cell texts read from the rebuilt root:
  - W: 25 words, both ends.
  - D: BSZ "None named. Half of the 10% avoidance, 5% of the wealth, ...", JR "7 moves. Seven counted as moved in time, 28.6% of the wealth, ...".
  - f: BSZ "5%. The share of wealth assumed to leave, ...", JR "45%. More than the 28.6% of wealth counted as gone, since ...".
  - a, JR: "(chapter PDF p.24)", from WP-2's source.
- No em or en dashes in the added lines.

## Needs a local render
- `Rscript comparison/run.R && Rscript comparison/tests/testthat.R` (root `index.html`, the comparison explorer, `assets/comparison-data.js`).
- Then the comparison report, materials page and deck, which print `step_texts()`, `fmt_input()`, `eq_terms()` and `hoopes_differences()`.

## Needs a follow-up (files outside the package)
- `comparison/R/build.R` (WP-2's file), `bsz_source` of `dep_b`. The root's BSZ D cell now states the 5% split but cites the first page in this source, BSZ PDF p.23, which names no leaver and does not give the split; p.24 gives it.
  - Now: "benchmark taxes all 1 Jan 2026 residents (BSZ PDF p.23); row 3, ...".
  - Change to: "the movers are inside the avoidance allowance, half of the 10%, 5% of the wealth (BSZ PDF p.24); the benchmark taxes all 1 Jan 2026 residents and names no leaver (BSZ PDF p.23 fn.30); row 3, ...".
  - The cell stays at 24 words. I will apply this in the final review if WP-2 has not.
- `comparison/site/repro.qmd` (WP-3): keep the anchor `#lost-income-tax-scale`. The root's new sentence links it.

## Could not do
- None.

## Noticed on the way (not changed)
- The equation still prints "Chance the tax does not survive litigation" with "(q)" after it (question 1).
- `hz_words` in `site.R` (ends "and a perpetuity") fills `tok$hz_words`, which neither template uses: a dead token, like the four run 003 listed.
- The series labels in `build_series()` keep "(perpetuity)" for the horizon settings. They are data labels for the report's chart.

## Author answers
Applied after the six implementers finished, before the Phase 4 rebuild. Nothing was rendered and no suite was run.

- **Q1 (court label) and Q2 (kind labels):** no change, as assumed.
- **Q4 (Table 5 re-baseline) and Q6 (disclosures):** no change, as assumed.
- **Q5, BSZ note 2 dropped** (current-workbook-only rule). Notes 3 to 8 are now 2 to 7.
  - `bsz-analysis/site/materials.qmd`: item 2 removed and items renumbered; "The seven notes below"; kinds "notes 6 and 7" (small numerical difference) and "notes 2, 3, 4 and 5" (documentation). The history paragraph now says "notes 5 to 7" and adds one sentence: the note on the 2026-09-04 copy's repeated rows was dropped on 2026-10-17 because the notes cover the current workbook only. "(note 5)" in "Errors in this OPA" becomes "(note 4)".
  - `bsz-analysis/site/repro.qmd`: item 2 removed and the notes section renumbered. The 2025-count paragraph ends with "and the workbook's own aggregate gives the same" (no note reference). "note 7" becomes "note 6" (Laffer); "(note 5)" in the errors list becomes "(note 4)".
  - `bsz-analysis/site/index.html`: the workbook row is now "Reproduces the paper's count of 240 billionaires for 2025. The estimate itself uses the 1 July 2026 Forbes list of 250". Notes 5, 6, 7 and 8 become 4, 5, 6 and 7. "<strong>seven notes</strong>"; "four are documentation notes".
  - `bsz-analysis/site/checks.qmd`: "(notes 1, 5, 6 and 7)".
  - `bsz-analysis/site/slides/slides.Rmd`: the repeated-rows bullet under "Three of them" is replaced by the A1 note ("Appendix Table A1 annualizes 1982 to 2026 over 43 years, where the workbook's own Table 1 uses 44"). That slide missing the A1 gap was a run 003 carried-over item. The note count is computed from the materials page.
  - `bsz-analysis/README.md`: "Seven notes ... four documentation". The repeated-rows sentence now says the notes cover the current workbook only, and that `compute_data_sec_agg.R` still de-duplicates the 2026-09-04 copy.
  - `bsz-analysis/VERIFY-AUGUST.md` l.7: RC10 is no longer among the notes (dropped 2026-10-17).
  - `README.md` (root) l.67: "with 7 notes".
  - `bsz-analysis/tests/testthat/test-site.R`: `expect_equal(length(no), 7L)` with a dated comment; the comment "notes 6 to 8" becomes "notes 5 to 7". Every other count on the pages and in the comparison deck is computed from the materials page's list.
- **Q3, neutral attribution:**
  - `rjkdc-analysis/NOTES.md`: "One of the JR authors pointed out that this overstated them. The notes were reclassified" becomes "That overstated them, and the notes were reclassified".
  - `feedback/006-2026-10-16-jr-author-mismatches/REPORT.md`: the title becomes "the "mismatches" count on the JR pages, corrected"; "What was raised ... One of the JR authors ... objected" becomes "What was found: The JR overview's "What reproduces" table overstated how far the results differ from the paper"; "supports the author on all five points" becomes "supports all five points"; "The author is right about the seed" becomes "The point about the seed is right"; "reply to the JR author" becomes "send the reclassification table to the JR authors".
  - `rjkdc-analysis/README.md` l.166-168 carried the same attribution and is made neutral the same way: "The notes were reclassified on 2026-10-16: the earlier list ... which overstated them".
  - Left for the author: the folder name `feedback/006-2026-10-16-jr-author-mismatches/`. NOTES.md links it twice, so renaming it means moving the folder and updating those links.
- **WP-1 follow-up, `comparison/R/build.R` l.80:** `dep_b`'s `bsz_source` now leads with "the movers are inside the avoidance allowance, half of the 10%, 5% of the wealth (BSZ PDF p.24); the benchmark taxes all 1 Jan 2026 residents and names no leaver (BSZ PDF p.23 fn.30); ...". The root's BSZ D cell then cites p.24 and stays at 24 words.
