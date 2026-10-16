# WP-3: BSZ report, its table display code and materials page
Owner: opus. Status: done.

## Changed
- `bsz-analysis/R/tables.R`, `build_tab_a1()` render block (A-15): display only. Panel A's year rows and its growth row, and Panel B's level, ratio and annualized rows, now each get their own `gt::fmt_*(rows = ...)` formats. Panel B's columns are listed in its row-group label. Panel A's AGI columns move to col4/col5, so the one blank header sits at the end. Headers are "#, Wealth, Growth, US AGI, Wealth / US AGI" (blank for May, which has no AGI columns). The ratio row reads "Ratio <cur_label> to 1982" and the 2026 row reads "2026 (July 1st)" as printed. The source note takes its percentile and dollar year from `pctile_label` and `cur_label`.
- `bsz-analysis/R/tables.R`, `build_tab1()` render block (A-15): the same row-wise formats. Panel B's columns go in its heading. col6/col7 read "CA AGI" and "Wealth / CA AGI" for August, and "CA GDP" and "Wealth / CA GDP" for May. The ratio row label and the note's years, percentile and dollar year follow the vintage.
- Checked (read only): I rebuilt both gt objects from the stored targets with `tar_read`. The `panel_a` and `panel_b` attributes are `identical()` to the stored `tab1_gt` and `tab_a1_gt`, so no snapshot changes. The May vintage builds too, with GDP labels.
- Checked every displayed cell against the PDF (Table 1 p.35, Appendix Table A1 p.49). All Table 1 cells match the printed digits, or round to them where we show one more decimal (37.4% against 37%, 2,290.6 against 2,291). All A1 cells match except three in the annualized row; see "Noticed".
- `bsz-analysis/site/repro.qmd` (A-15): the note under Table 1 now describes the table as it will render. It says the values match the workbook (true for Table 1), that Panel B lists its columns in its heading, and that A1 has the same layout. The "Display labels" entry under What reproduces became "A display error in Tables 1 and A1 (ours)": wrong headers and formats plus the May labels, fixed on 15 October 2026, tested values unchanged. The sentence about snapshots changing is gone, because they do not change.
- `bsz-analysis/site/repro.qmd` Step 3 and "Every input, by origin" (A-16): "BSZ's headline" became "Table 5's row 1, printed as `r usd(wt_printed, 0)` and reproduced here as `r usd(t5$wealth_tax_revenue[1])`". The printed digit comes from `site_tab5_printed`, not typed.
- `bsz-analysis/site/repro.qmd` Laffer section (A-17): "uses as a check, 10.32; its first version preferred 12 to 13".
- `bsz-analysis/site/repro.qmd` Step 5 and The main estimate (A-07, A-13, E-08): five years is now given as BSZ's example (quote checked on PDF p.27), and Table 5 takes no stand. "One of the largest disputes", with a link to `../../comparison/site/repro.html#the-bridge` (the anchor exists) for each dispute's size in dollars. "For 5 years (BSZ's example; this OPA's reading of it)". I split the plan's semicolon into two sentences and dropped "and Table 5 does not say for how many years", which would have repeated the next sentence.
- `bsz-analysis/site/materials.qmd` (A-15): the bullet now says the display put Panel B's values under Panel A's headers and formats and kept the May labels, fixed 2026-10-15.
- `bsz-analysis/R/site_exports.R` and `bsz-analysis/py/site_exports.py` (A-03): identical strings, "no named leaver (row 1); the 5% who move are part of α". In the R comment, "the 1.5% to 4.5% range the JR analysis draws".
- Acceptance: both R files parse, the Python file parses, no old string remains, no em or en dash in added lines, `check_links.py` reports nothing (baseline also empty). No test pins the changed prose. `site/data/inputs.csv` is not checked byte for byte. The export contract (`export/*/inputs.csv`) does not carry the L row, so the comparison is unaffected.

## Needs a local render
- `cd bsz-analysis && Rscript -e 'targets::tar_make()'`: rebuilds `tab1_gt`, `tab_a1_gt` and `site/data/inputs.csv`.
- `cd bsz-analysis && python py/run_export.py`: regenerates `export/py/site/inputs.csv`, which holds the L row. Run only, the file is the author's.
- `cd bsz-analysis/site && quarto render repro.qmd && quarto render materials.qmd`.
- `cd bsz-analysis && Rscript tests/testthat.R`: no snapshot should change.

## Needs a follow-up (files outside the package)
- None required for this package.

## Could not do
- Nothing.

## Noticed on the way (not changed)
- **A1's annualized row differs from the workbook and the paper (a number, for the author).** `build_tab_a1()` uses `n_years = 44` for August. The workbook's `TabA1!B18:G18` use `^(1/43)`, which was not updated when the endpoint moved to 2026; Tab1 uses 44. So we show 7.4%, 6.0% and 2.5% where the paper prints 7.6%, 6.2% and 2.6% (wealth, wealth per family, AGI); the other three round alike. `test-tables.R`'s A1 Panel B check passes anyway: `expect_equal`'s tolerance is relative over the whole column, so the small annualized value gets lost next to the counts. Options: set 43 for August in `R/tables.R` and `py/tables.py`, the project's "reproduce the workbook as it is" rule, and disclose it as a workbook inconsistency (re-snapshot `tab_a1_panel_b`); or keep 44 and disclose. Either way the test should check the ratio and annualized rows with an absolute tolerance. The new report text does not claim A1 matches the workbook; it says so only of Table 1.
- The plan's sample heading said "families (thousands)". The column is a count of families (118 and 225; the paper says "the richest 225 families in California"), so the heading says "# families in the top .001%".
- `R/site_exports.R` lines 85-86 still say "over BSZ's horizon of about 5 years (PDF p.27)", the framing A-07 corrects. Suggested: "over 5 years (BSZ's example, PDF p.27; this OPA's reading of it)".
- `repro.qmd` line ~596 still says "the 1.5% to 4.5% range the JR analysis uses". This range has been misread as "many rates" twice before (CLAUDE.md log 2026-10-07 and 2026-10-15). "Draws" would match the comment.
- The paper's own A1 Panel B heading says "(real 2025 $)" while its columns say 2026 $; ours says 2026.
- `bsz-analysis/report.qmd`, the older pipeline report, still calls Table 1's denominator "CA GDP" (lines 128, 136, 189).
- Panel A's percentages keep one decimal, as before (37.4% against the printed 37%).
