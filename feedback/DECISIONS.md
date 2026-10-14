# Decisions

Items the review loop settled. A reviewer does not raise one again unless the page changed;
the coordinator appends and never deletes.

| Date | Run | Item | Decision | Reason |
|---|---|---|---|---|
| 2026-10-14 | 001 | A-26: decompose the September 2026 revision step into three labelled steps (growth, seventh departure and litigation weight, independent f draw) | won't do | New analysis: three new inputs of the common function; for the author |
| 2026-10-14 | 001 | A-27: record the switch of the main estimates (BSZ net total, 7 October; RJKDC NBER mean, 14 October) in `PLAN.md`'s "kept current" section | won't do | `PLAN.md` is a record the loop does not edit; a dated line is suggested in `001-2026-10-14/04-plan.md`, question 9 |
| 2026-10-14 | 001 | E-14: print the RJKDC row of the root page's common-output table to one decimal (−$39.0B) instead of −$38.98B | won't do | `comparison/tests/testthat/test-site.R` pins the two-decimal value on the root page; the paragraph under the table says which value is exact |
| 2026-10-14 | 001 | E-20: state on the BSZ explorer what the 3% rate does to the main estimate (the loss at 1.5% and at 4.5%) | won't do | No generator writes those two numbers, so no page may type them; a `meta.csv` row would allow it (for the author) |
| 2026-10-14 | 001 | V-07: retitle the root page from "Reconciliation of the Two Analyses" | won't do | The title is PLAN-5 Part B item 1; the first paragraph now says what the page does |
| 2026-10-14 | 001 | V-11: move the watermark icon out from behind "Three layers to understand the analysis" | won't do | The kit's design (`.section-title-icon`); the author decides whether the kit moves it |
| 2026-10-14 | 001 | A-14 (half): number the RJKDC overview's chapter mismatches | not a defect | They are numbered 3 to 6 by `<ol start="3">`; the reviewer's text extraction dropped the numbering |
| 2026-10-14 | 001 | A-04 (half): rename the bridge step "One-time tax estimated as a permanent 5 pp rate" | won't do | The title names the RJKDC choice in neutral words and the tests and exports carry it; the RJKDC reason is in the step's source cell instead |
