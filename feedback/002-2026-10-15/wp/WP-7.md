# WP-7: Comparison report, materials page, DISPUTES and the transcribed inputs
Owner: coordinator. Status: done.

## Changed
- `comparison/DISPUTES.md`: retitled "Disputed inputs: the JR analysis vs the BSZ analysis"; a dated note (2026-10-15) at the top; the JR chapter added to the documents table; the vintage caveat rewritten (September values first, March after; no "last step"); column "JR value: September 2026 (JR), then March 2026 (Rauh)"; rows 1 and 4 marked March-only (A-26, E-30).
- `comparison/DISPUTES.md` row 2: the September growing perpetuity, the r − g calibration and draw, and the JR reason for a permanent loss (PDF p.32, Sec. 6) (A-04, A-10); the BSZ cell in the agreed form of the five-year example, "does not take a stand" quoted (A-07).
- `comparison/DISPUTES.md` row 3: the seven September departures, $577.7B grown, 28.5% (Table 7, PDF p.21), 100.9 to 72.06 and 5.73 (eq. 4, PDF p.22); the BSZ cell now says no named leaver is removed (fn.30 quoted) and the 10% avoidance counts the 5% who left (A-26, A-03).
- `comparison/DISPUTES.md` rows 5 and 6: C unchanged with chapter pages; f drawn independently with both PDF p.31 quotes; row 6's BSZ cell adds the benchmark's proportionality assumption and the kind becomes guesswork (A-26, E-07).
- `comparison/DISPUTES.md` row 8: the chapter's Sec. 3.5 reason quoted, kind "data vs guesswork" (A-05). Row 9: "chapter Secs. 4.2 and 4.4, PDF pp.19-23, eqs. 3 and 6" (A-06) and the GGSS "Constitutionality Issues" quote (A-28). Row 10: the draw is r − g (A-10).
- `comparison/DISPUTES.md`, the −$24.7B section kept and labelled as history, with the anchor sentence rewritten; "Handled outside the table": the chapter's zero collection probability for Pareto-imputed billionaires (PDF p.21, fn.23), asset sales and avoidance named as bridge steps with no row, third parties "none is a dial or a row here".
- `comparison/site/repro.qmd` introduction: "On the explorer's path, three inputs ..." plus a generated sentence naming the three largest Shapley steps (computed in the setup chunk from `bridge.csv`: q, f, H) (A-13, E-08).
- `comparison/site/repro.qmd` "The two main estimates": the JR figure as printed (−$38.9B, NBER) and as computed exactly here (−$39.0B); "the ones each analysis's overview page shows", the BSZ total labelled this OPA's construction (A-01, E-04, V-05).
- `comparison/site/repro.qmd` common output: "The BSZ analysis" / "The JR analysis" for "report" (A-18); the horizon paragraph in the agreed form, with the JR reason (A-07, A-04); the rate paragraph says the JR draw is r − g (eqs. 13-14, 18) and that 2.73% matches the draw only for a loss that lasts for ever (A-10, E-13); Conventions rewritten as WP-1's explorer note ("billions of dollars at the assessment date", the flat loss, r − g, mismatch 3, "the BSZ end's 3% is the middle of the same draw") (E-11, V-16, A-23).
- `comparison/site/repro.qmd`: endpoint fold "The BSZ differences are rounding ... The JR difference is the sampling error of the authors' one seeded run" (E-16); Step 2 names the drawn rate r − g; "On this path, three of them ..." in the bridge section; the rate step "(r − g)" (A-10, A-13).
- `comparison/site/repro.qmd` "Every input, by origin": derived, guesswork on data and "A vs B" defined (E-17); the transcribed-inputs fold shows BSZ, JR and Neutral instead of the raw side keys (A-14, E-18).
- `comparison/site/materials.qmd`: line 106, the March version is "still checked by the code" and the bridge ends at September; the GGSS sentence no longer names the removed "permanent 5 pp rate" step; the litigation bullet says the README lists both q and the uniform draw (as A-24); "its range of r − g"; the `R/model.R` script row names the dial path (A-26).
- `comparison/data/document-inputs.csv`: Walczak rows' side `neutral` and the description names Walczak as a third party, without "(credited alternative dial)"; `rauh_loss_horizon` cites the chapter's Sec. 5.2, eqs. 13-14, page 31; `bsz_loss_horizon` describes five years as BSZ's example; `common_discount_rate` says the JR draw is (r - g) (A-14, E-18, A-07, A-10).

## Needs a local render
- `comparison/site/repro.qmd`: `cd comparison/site && quarto render repro.qmd` (after `Rscript comparison/run.R`, because it reads the exports and WP-1's `site.R`)
- `comparison/site/materials.qmd`: `cd comparison/site && quarto render materials.qmd`
- `comparison/data/document-inputs.csv` feeds `comparison/run.R` and `test-sources.R`: covered by WP-1's rebuild and the comparison suite.

## Needs a follow-up (files outside the package)
- None. The kinds in DISPUTES rows 6 and 8 ("guesswork ...", "data vs guesswork ...") are written to match WP-1's planned `bridge_steps()` kinds; the final review checks them against the edited `model.R`.

## Could not do
- Nothing.

## Noticed on the way (not changed)
- The chapter's own roadmap (PDF p.18) calls Sec. 4.3 "litigation-weighted revenue estimates", while the heading of Sec. 4.3 is "Confirmed Pre-Snapshot Departures". The pages now cite the headings. Not a defect of this OPA.

## Checks
- `knitr::purl()` of `repro.qmd` parses; the three Shapley names come out as q, f and H (litigation −45.0, share lost −32.6, horizon −32.3 in `bridge.csv`).
- `document-inputs.csv` parses: 19 rows, 10 fields each, labels unchanged; `DISPUTES.md` keeps "| N | " for rows 2, 3, 5 to 10 (`test-shapley.R` looks for them).
- Every added chapter page reference checked against the PDF's extracted text (PDF pp.17-18, 19, 21-22, 23, 24, 28, 30-32, 35); BSZ p.23 fn.30 and p.27; GGSS p.11.
- No old string left ("Every difference is a rounding", "BSZ report says", "nominal billions", "credited alternative dial", "enters the bridge as its last step", "chapter Sec. 4.3", "Rauh anchor to use"); no em or en dash in any added line; `check_links.py` reports no broken link.
