# AUTHOR-BSZ: the author's answers of 2026-10-16, BSZ share

Owner: opus implementer. Status: done (items 3, 4, 14, 18, 22, 23, 26). Nothing committed.

## Per item

**3. AI badge (done).** On the BSZ overview the badge left the title. It now sits on a line of
its own under it: `<p class="ai-badge-line">This OPA site: <a class="ai-badge ai-badge-yellow" ...>AI generated, partially reviewed</a></p>`.
Two page-local CSS rules (`.ai-badge-line`, `.ai-badge-line .ai-badge`) size it, because
`assets/paper.css` sets `.ai-badge` to 0.42em of its parent (sized for an h1). The badge text is
unchanged, so the existing check still passes. `tests/testthat/test-ai-badges.R` gets a new test:
the h1 holds no badge, and the page has the "This OPA site:" line. The BSZ deck has no badge
(its Slides answer is "Reviewed"), so nothing moved there.
Files: `bsz-analysis/site/index.html`, `bsz-analysis/tests/testthat/test-ai-badges.R`.

**4. Table A1, 43 years (done).** `build_tab_a1()` now annualizes over 43 years in every
vintage, as `TabA1!B18:G18` does in all three workbooks (`=(B16/B15)^(1/43)-1`). Table 1 stays at
44 for August, as `Tab1` does. The row now reproduces the paper: top .001% wealth 7.6% (was
7.4%), per family 6.2% (was 6.0%), AGI per family 2.6% (was 2.5%). Python twin changed the same
way. `test-tables.R` has a new per-cell check of the annualized row against the workbook (six
expectations, tolerance 1e-6). Snapshots `tab_a1_panel_b` re-taken for `august` and `september`.
The text that disclosed the gap now says the paper and workbook count 43 years where 1982 to 2026
is 44 years. The report computes the 44-year values from the panel's ratio row ("which would
give 7.4%, 6.0% and 2.5% where the paper prints 7.6%, 6.2% and 2.6%"), and its mismatch entry
is marked resolved. The overview and the materials page carry no digits and point to the report.
Files: `R/tables.R`, `py/tables.py`, `tests/testthat/test-tables.R`, `tests/snapshots/{august,september}/tab_a1_panel_b.rds`,
`site/repro.qmd`, `site/materials.qmd`, `site/index.html`.

**14. Statutory 5% rate is "data" (done, BSZ part).** `build_site_inputs()` (R) and its Python
twin label τ "data" (was "scenario"). The BSZ contract (`export/r/inputs.csv`, `tax_rate`)
already said "data", so the site table and the contract now agree. No page typed a count of
scenario inputs. The report's counts are computed at render.
Files: `R/site_exports.R`, `py/site_exports.py`; regenerated `site/data/inputs.csv`, `export/py/site/inputs.csv`.

**18. Table 5 row 1 label (done).** Row 1 reads "1. Benchmark: Forbes estimates as of 7/1/2026 +
10% evasion/avoidance (half due to mobility)" (BSZ PDF p.39, checked against the PDF text), in R
and Python. The note's sentence "In row 1, half of the 10% avoidance is billionaires who moved"
became "Row 1's label is BSZ's; rows 2 to 4 are shortened.", because rows 2 to 4 keep their
short labels. `tab5_panel` re-taken for `august` and `september`.
Files: `R/tables.R`, `py/tables.py`, `tests/snapshots/{august,september}/tab5_panel.rds`; regenerated `export/py/exhibits/tab5_panel.csv`.

**22. Residency date (done, BSZ part).** The overview's first sentence reads: "Proposition 40,
the Billionaire Tax Act, would tax people who lived in California on 1 January 2026 and are
worth $1 billion or more, once, at 5% of their net worth." The BSZ deck already gives the date
("on California residents on **1 January 2026**", slide "The tax, in one line").
File: `site/index.html`.

**23. Checks page tables generated (done).** `site/checks.qmd` now builds both tables in R
chunks when it renders. The explorer's rows come from `explorer/grid.js` (parsed, cell looked up
by dial levels). The printed August values come from `data/tab5-vs-printed.csv`. The May rows
come from `score_tab5_cell()` on the May workbook. The May printed values (98, 121, 84, 109,
May PDF p.34, checked) are the only typed numbers in the chunk. The labels are built from the
dial symbols and levels. The prose figures ($104, $103.8 and $106.8 billion, 5 years, 3%) are
inline R. The "copied ... on 15 October 2026" sentence is gone. In its place: "Both tables are
built when this page is rendered, from the explorer's data file ...".
Two values changed:
- "Add the 368 billionaires" now reads 370. 368 was the April list's count (617 - 249); the
  August grid adds 369.6.
- The base wealth tax prints 103.82, rounded with R's `round()` as the report does.
`test-site.R` has a new test. It checks the rendered `checks.html` against the grid recomputed
by `build_site_grid()`: all 11 rows of the second table, the four August rows and the four May
rows (May recomputed under `BSZ_VINTAGE=may`). It also checks that the qmd reads `grid.js` and
no longer says "copied".
Files: `site/checks.qmd`, `site/checks.html`, `tests/testthat/test-site.R`.

**26. Mirror on the BSZ deck (done, no change needed).** The deck has no badge (Slides are
"Reviewed"). It already gives the residency date. It shows neither the Table 5 row labels nor
the τ kind. Re-rendered: only the generated test count changed (721 to 778, run 2026-10-16).
Slide 20 checked as an image: no overflow.

## Rebuilds and tests

- `Rscript -e 'targets::tar_make()'` (twice, after the note fix), `python py/run_export.py`,
  `Rscript tools/py-parity.R`: 50 outputs, 53,863 numbers compared, 0 not matching.
- `Rscript tools/site-test-results.R`: 778 passed, 0 failed, 0 skipped, 117 test blocks
  (was 721 / 114). It rewrote `site/data/test-results.csv` and the README count block.
- `Rscript tests/testthat.R`: all files pass, no failures, no warnings.
- Rendered: `site/repro.qmd`, `site/materials.qmd`, `site/checks.qmd`, `site/slides/slides.Rmd`.
  `check_links.py`: no broken links. No em-dashes in added lines.
- `py/run_export.py` not edited (its diff is the author's own). `.gitignore` and
  `PLAN-3-learning-materials.md` not touched.

## For the comparison agent

- BSZ export contract (`export/r/*.csv`) unchanged. `tax_rate` was already "data" there.
- BSZ overview badge markup and first sentence are given above. The JR and comparison overviews
  could use the same `ai-badge-line` paragraph. A shared rule in `assets/paper.css` would be better
  than the page-local CSS used here (that file is outside this package).

## Noticed on the way (not changed)

- `tests/snapshots/september/` is stale for 11 snapshots unrelated to these items (for example
  `data_sec_agg_r`, `tab2_panel`, `fig1`). A full regenerate under `BSZ_VINTAGE=september`
  changed them. I restored them and replaced only `tab5_panel` and `tab_a1_panel_b`, after
  checking that each differs only by this change. Tests run on the default workbook only, so
  nothing fails today.
- The checks page's valuation-date figures ($92.5B, $87.0B, $110.9B) are still typed. They come
  from the workbook's daily series (`shortrunseries!A15:D272`), not the explorer, and could be
  read there the same way.
