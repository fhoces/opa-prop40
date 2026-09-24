# August re-verification

Report only. No computation code, test literal, or snapshot was changed to produce this
report; `git status --short` before writing it showed no modifications under `R/`, `tests/`,
or `_targets.R`. Generated 2026-09-23 by running the pipeline and test suite against the
default (August) vintage of `BSZ_MainTablesFigures.xlsx`
(SHA-256 `c236cc94...cb6ce`), compared against the May vintage
(SHA-256 `cffe04bd...b7b1a`) already verified clean (see PLAN.md step 5).

## 0. Resolution (step 4)

All 184 August failures classified below are fixed. Full-suite result, `Rscript`-sourcing
`R/*.R` then `testthat::test_dir("tests/testthat", reporter = testthat::ListReporter$new())`:

| Vintage | Pass | Fail | Error |
|---|---:|---:|---:|
| August (`BSZ_VINTAGE` unset / `august`) | 518 | 0 | 0 |
| May (`BSZ_VINTAGE=may`) | 503 | 3 | 0 |

These counts are as of this step; the suite has since grown to 561 expectations on August
(see README.md, counted through `tools/site-test-results.R`).

May's 3 failures are the same pre-existing snapshot factor-ORDER issue (`fig4`, `fig_a3`) noted
before this work started; left as-is per plan scope, not touched.

Every RC below required more than the row-shift/renamed-sheet description originally given
it turned out to need: in most cases (RC1, RC2, RC4/RC5/RC6) the columns also reshuffled
non-uniformly, or a formula genuinely changed, discovered by reading the actual Excel cell
formulas (`openpyxl`, `data_only=False`) rather than inferring from cached values. See each
commit message for the full derivation; this table is only an index.

| RC | What | Commit |
|---|---|---|
| RC10 | `compute_data_sec_agg` dedupes an accidentally re-pasted 4-row block in August's `data_sec_all` (n 244 -> 240, matching the workbook's own cache and the paper's stated count) | `009e539` |
| RC1 | `compute_shortrunseries`: vintage-keyed column-letter lookup (`R/vintage.R`'s `srs_col()`); August dropped the "CA wealth, US citizens only" column entirely, falling back to the all-CA-billionaires total | `0b27883` |
| RC2 | `compute_billionaires_ca_inctax`: `bci_row()` row-offset helper (+1 for rows 16-143, +2 for rows >=144); August also folds the passthrough-entity tax into row 15 for 2021-2023, changed the sales gross-up rate 11%->9.5%, and changed the private-wealth passthrough/private-C weights 71.8/61 -> 93/116 (adding a new "property tax on passthrough" term) | `0b27883` |
| RC3 | `compute_tab5`: vintage-keyed benchmark n/wealth and per-leaver wealth constants (`.TAB5_CONST` in `R/vintage.R`) | `09b46ab` |
| RC8 | Laffer-curve sheet renamed/relocated May `Fig8` -> August `Fig9`; `fig8_laffer_sheet()` resolves it | `09b46ab` |
| Ellison test | August's `data_sec_all` has zero `larry-ellison` rows in any year (verified: 0/1345), so with/without-Ellison aggregates are now asserted byte-identical for August, not "+60" | `09b46ab` |
| RC9a/b/c/d | `rtb_2026_industry` n_max (14->15), `data_sec_agg` 2025 literal, `list_sheets` count (36->40), `shortrunseries` E6/K6 cell reference | `68efbc0` |
| RC4/RC5/RC6 (Tab1) | `build_tab1`: CA GDP -> CA AGI denominator (`longrunseries!AT` -> `!AY`/`!BA`+deflator), new "2026 (July 1st)" row, Panel B redefined top .0002%->.001% with 2025->2026 endpoint (now reading already-real `!BT`/`!BA` columns) | `f2b1ba5` |
| RC4/RC5/RC6 (TabA1) | `build_tab_a1`: same three changes mirrored for the US-billionaires table (new AGI columns `!AV`, new 2026 row, `!AM*5` / `!G*!BQ` percentile widening) | `e72a9eb` |
| RC7 | `build_tab2` test: top-4 block column position (F:H -> H:J after 2 new "Total taxes" columns); also fixed a genuine average-row ratio formula change (May: mean-of-parts over 7yr; August: `AVERAGE(J7:J12)`, direct ratio average over 6yr) | `be32f9b` |
| fig2 columns | `build_fig2`: `longrunseries` columns AZ->BJ, BE->BP, AV->BF, AW->BG (sheet grew 80->96 columns) | `c0a37ed` |
| fig3/fig4/fig_a2 literals | Downstream figure "sanity check" literals updated to August's (correct, RC1/RC2-fixed) 2025 values | `c0a37ed` |
| Snapshots | Moved to `tests/snapshots/<vintage>/`; August baseline regenerated only after every Excel-comparison test passed | `0c2ada7` |

**Did August add the 24 non-US-citizen CA billionaires the GGSS response promised?** Yes, in
substance. The paper's own Methodological Appendix A (p.54) states: "Forbes lists 237 CA
residents on Jan 1 2026 ($2277bn), 25 of them non-US citizens ($132bn), all included" and
p.5 says "We include both US and non-US citizens" - so the 237-resident base already
contains non-citizens; the response's "24" and the paper's "25" differ by one person,
immaterial. No dedicated citizenship-flag column exists anywhere in the workbook
(`data_sec_all`, `rtb_2026_industry`, or any Forbes-list sheet) to independently cross-tabulate
the exact 25, so this rests on the PDF text, not a spreadsheet check. What IS independently
verified from the data (via the RC10 investigation above): August's `data_sec_all`, deduped,
has exactly 240 unique 2025 rows, reconciling exactly with 237 - 1 (Ellison, who has zero rows
in `data_sec_all` at all, any year) + 4 (Daniela Amodei, Kim Kardashian, Laurene Powell Jobs,
Oprah Winfrey - all four found in `data_sec_all` at year 2025, combined wealth $22.72B, matching
the paper's stated "+$22.8bn" for these NA-state-coded additions) = 240, matching both the
workbook's own `data_sec_agg` cache and the paper's stated count. No code changed for this item.

## 1. Pipeline status

`Rscript -e 'targets::tar_make()'` with the August default: **every target built. No target
errored.** 21 warnings were emitted, all `ggplot2` "removed N rows containing missing/
non-finite values" warnings from `fig2`, `fig3`, `fig4`, and `fig_a2` (`.png`/`.pdf` renders),
plus one "NAs introduced by coercion" warning inside `compute_billionaires_ca_inctax`. These
trace to the same root causes classified in section 3 below (RC1/RC2/RC4): the hardcoded
2018-2025 year window no longer covers the new August rows, so some derived series now contain
gaps where a stale row index landed on a blank or text cell.

`report_html` and `report_pdf` both built successfully (the Quarto report renders with whatever
numbers `tar_make()` produced, right or wrong - it does not re-verify against Excel).

## 2. Per-derivation verification

518 expectations across 93 `test_that()` blocks. **334 passed, 184 failed, 0 errored, 0
skipped.** (May baseline for comparison: 506 expectations, 503 passed, 3 failed - see PLAN.md
step 5.)

Every block that compares R output to Excel-cached values, with cells compared / mismatched:

| Test | Cells compared | Mismatched | Class |
|---|---:|---:|---|
| `compute_shortrunseries matches Excel formula cells` | 63 | 57 | (a) RC1 |
| `compute_billionaires_ca_inctax matches Excel formula cells` | 53 | 46 | (a) RC2 |
| `build_tab1 panel A reproduces Tab1 sheet 2022-2025 + growth row` | 10 | 8 | (a)/(b) RC4+RC5 |
| `compute_tab5 matches the 4-scenario Excel Tab5 to 1e-3` | 8 | 7 | (a) RC3 |
| `build_tab5 reproduces Tab5 sheet` | 7 | 7 | (a) RC3 (downstream) |
| `build_tab1 panel B reproduces Tab1 sheet 1982+2025...` | 6 | 6 | (a) RC5 (downstream) |
| `build_tab_a1 panel B reproduces TabA1 sheet 1982 vs 2025` | 6 | 6 | (b) RC6 |
| `compute_fig8_laffer matches Excel Fig8 columns A-E` | 6 | 5 | (a) RC8 |
| `build_tab2 reproduces Tab2 sheet 2019-2025 + average row` | 6 | 5 | (a) RC7 |
| `build_tab_a1 panel A reproduces TabA1 sheet 2022-2025 + growth row` | 4 | 4 | (a) RC5 |
| `compute_data_sec_agg matches Excel data_sec_agg for shared columns` | 31 | 2 | (c) RC10 |
| `build_fig2 returns a patchwork object spanning 1982-2025` | 8 | 2 | (a) RC1 (downstream) |
| `extract_rtb_2026_industry returns the first industry block` | 5 | 2 | (a) RC9a |
| `fig2 / fig3 / fig_a3 data matches snapshot` (3 tests) | 6 | 6 | (d) |
| `extract_data_sec_agg covers years 2019-2025 with no summary rows` | 5 | 1 | (a) RC9b |
| `list_sheets returns the 36 sheets in the BSZ workbook` | 5 | 1 | (a) RC9c |
| `build_fig3 returns a 2-panel patchwork over 2019-2025` | 4 | 1 | (a) RC2 (downstream) |
| `build_fig4 returns a stacked area chart with 4 tax components` | 4 | 1 | (a) RC2 (downstream) |
| `extract_shortrunseries returns the raw wide series` | 3 | 1 | (a) RC9d |
| `build_fig_a2 returns 2-series share-of-CA-inctax line chart` | 3 | 1 | (a) RC2 (downstream) |
| `fig_a1 data matches snapshot` | 3 | 1 | (d) |
| `compute_data_sec_agg excludes Ellison from every year` | 1 | 1 | (c) RC10 |
| 14 further single-expectation `*_r matches snapshot` / `tab* panel matches snapshot` / `fig* data matches snapshot` blocks | 14 | 14 | (d) |
| all other blocks (compute_top4taxes, build_tab3, build_tab4, pareto tests, figure-renders-non-empty tests, ingest_excel helper tests, verify.R self-tests, ...) | 220 | 0 | pass |

Largest absolute / relative errors, by cluster (see section 3 for the R-line evidence behind
each):

- **RC1** (`compute_shortrunseries`): most mismatched cells are `NA` (the stale row index reads
  a blank cell), or land on a completely unrelated value once the sheet layout shifted - e.g.
  `panel$cum_growth_from_2019[3]` R=0.476 vs. cell read 365 (off by 364, because the index now
  reads a wealth figure in $B, not a growth ratio). Not a small-tolerance miss; the extraction
  itself is pointed at the wrong cell.
- **RC2** (`compute_billionaires_ca_inctax`): same pattern, `NA`s and cross-column garbage once
  the 5 new August rows shift every fixed block down.
- **RC3** (`compute_tab5`): genuine magnitude errors from stale constants, e.g. scenario 1
  wealth R=2182 vs. Excel=2307 (diff -125, i.e. -5.4%); scenario 2 wealth R=2797 vs. Excel=2957
  (diff -160, -5.4%); wealth_tax_revenue off by $4.9-6.9B per scenario (average diff 5.92).
- **RC7** (`build_tab2`): cross-column garbage from the 2-column insertion, e.g.
  `top4_ca_inctax_per_wealth` R=0.000177 vs. cell read 184 (off by -184 - the cell now holds
  "Company wealth" from the shifted layout, not a tax/wealth ratio).
- **RC8** (`compute_fig8_laffer`): not a numeric error at all - `Types not compatible: double is
  not character` / `... is not logical`, because `Fig8` in August is a completely different
  sheet (see RC8 below); the extraction returns text/blank columns, not numbers.

## 3. Mismatch classification, with evidence

### RC1 - hardcoded `2018:2025` year window in `compute_shortrunseries` (class a)

`R/compute_shortrunseries.R:245` - `yrs <- 2018:2025` - and the panel builder's row literals
at `R/compute_shortrunseries.R:43-45` (`xls_cells_col(srs, "B", 7:13)`, etc.), plus
`tests/testthat/test-compute.R:187` - `rows_panel <- 6:13   # year 2018..2025`.

August's `shortrunseries` sheet grew from 26x40 to 28x57. It inserts a new row 14
(`2026, 2026-07-01, 2307, 2191.65`) and an extra "2026 (feb 1)" estimate row at row 16,
between the old panel (rows 6-13) and the old summary/growth block (which used to start at row
14). Every hardcoded row 14+ reference in the R and test code now reads the wrong cell (blank,
a different year's summary, or a completely different field). This one root cause accounts for
57 of the 184 failures, plus the downstream `build_fig2`/`build_fig3`/`build_fig4`/
`build_fig_a2` and `shortrunseries_r matches snapshot` failures (these builders consume
`shortrunseries_r`, which is wrong for the same reason).

### RC2 - hardcoded row blocks in `compute_billionaires_ca_inctax` (class a)

`R/compute_billionaires_ca_inctax.R:9-16` (block comment documenting the four hardcoded row
ranges: panel 6-55, memo1 58-72, memo2 76-105, all-taxes 110-153) and the year-column map at
`R/compute_billionaires_ca_inctax.R:26-36` (`C..I` fixed to 2019-2025).

August's `billionairesCAinctax` sheet grew from 164 to 169 rows (+5). The extra rows shift
every block boundary past `55`/`72`/`105`/`153`. Accounts for 46 failures plus the downstream
`billionaires_ca_inctax_r matches snapshot` failure and part of the `build_tab2` cascade (Tab2
reads `billionaires_ca_inctax_r$method1`).

### RC3 - stale hardcoded benchmark constants in `compute_tab5` (class a)

`R/compute_tab5.R:8-9` - default arguments `baseline_n = 249, baseline_wealth = 2182` - plus
the hardcoded top-4 and leaver wealth breakouts at lines 43-48 and 61-63 (`page_wealth_B <-
276`, etc.), none of which are parameterized by vintage or read dynamically from the workbook.

August's `Tab5` row 6 label changed from *"Benchmark: Forbes estimates as of 4/15/2026"* to
*"Benchmark: Forbes estimates as of 7/1/2026"*, with `n_billionaires` 249→250 and `wealth`
2182→2307 (a genuine benchmark-date update, itself class (c) - the underlying number
legitimately moved). But `_targets.R` calls `compute_tab5(pareto_missing_r, tab2, tab3)` with no
override, so `baseline_n`/`baseline_wealth` stay pinned at the May values regardless of which
workbook vintage is loaded. `Tab5`'s own sheet dimensions are unchanged (still 30x10 in both
vintages) - this is purely a stale-literal bug in the R re-derivation, not a workbook layout
change. Downstream: `build_tab5`, `tab5_r matches snapshot`, `tab5 panel matches snapshot`.

### RC4 - Tab1/TabA1 column F/G redefined from CA GDP to CA AGI (class b)

Quoted Excel formulas (`openpyxl`, formulas not cached values):

- `Tab1!F6`: May `=shortrunseries!E10` → August `=shortrunseries!K10`
- `Tab1!G6`: May `=longrunseries!AT48` → August `=longrunseries!AY48`

Column headers: May `Tab1!F5` = *"California GDP"*, `G5` = *"Billionaire wealth/CA GDP"` →
August `F5` = *"California annual total AGI"*, `G5` = *"Billionaire wealth/CA AGI"*. This is
backed by the new `2023-b-1__adjusted_gross_income` sheet (see section 4) - the authors
replaced the GDP denominator with Adjusted Gross Income throughout Tab1/TabA1. `longrunseries`
grew from 80 to 96 columns to make room for the new AGI series, which is why column `AT` (old
GDP) became `AY` (new AGI is inserted earlier in the sheet). `R/tables.R:426`
(`ca_gdp <- ... longrunseries$AT[48:51]`) still computes the old GDP-based figure, so
`build_tab1`'s `ca_gdp_b`/`wealth_per_gdp` columns are off by ~1000x from the new AGI-based
cached values (e.g. R=2.58 vs. Excel=1898 - R is computing GDP correctly but comparing it to a
cell that's no longer GDP). TabA1 shows the same pattern (`TabA1!F5`/`G5` are brand new AGI
columns that didn't exist at all in May).

### RC5 - inserted "2026" row shifts Tab1/TabA1 Panel A + B block positions (class a)

`R/tables.R:104-107` (`build_tab_a1`, hardcodes `shortrunseries rows 10:13 = years 2022:2025`)
and the equivalent fixed-row logic in `build_tab1`'s panel A/growth-row assembly.

Both `Tab1` and `TabA1` grew by exactly 1 row in August: a new `"2026 (July 1st)"` row is
inserted between the 2025 row and the `"Growth during 2023-2025"` summary row (Tab1 row 10→11;
TabA1 row 10→11), which in turn pushes Panel B's header/data down by one row each (Tab1 row
12→13; TabA1 row 12→13). Any hardcoded absolute row number for the growth row or for Panel B's
start now points one row too high, landing on the new 2026 data or on text (hence the
`"Types not compatible: double is not character"` errors in the Panel B tests - the code reads
a row-label text cell instead of a numeric cell).

### RC6 - TabA1 Panel B redefines the percentile and base year (class b)

Section headers (quoted verbatim):

- May: *"B. Long-term real wealth growth of US billionaire class=top .0002% richest (real 2025
  $)"*
- August: *"B. Long-term real wealth growth of US billionaire class=top .001% richest (real
  2025 $)"* (row-level data uses **2026**, not 2025, as the current-year endpoint: row label
  reads `"2026"`, and the notes cell explains *"top .001% ... using the Forbes 400 annual data
  ... for the top .0002% covered by Forbes along with a Pareto extrapolation to cover the top
  .001%"*)

August's Panel B extrapolates one order of magnitude further into the tail (top .001% instead
of top .0002%) and rolls the current-year endpoint from 2025 to 2026. `build_tab_a1`
(`R/tables.R:123-148`) still computes the old .0002%-vs-2025 definition from fixed
`longrunseries` rows 8/51, which is both a formula-logic change (percentile threshold) and,
separately, RC5's row shift (Panel B's own row 8/51 references may now be off by the shortened
2025 endpoint compared to Excel's own new 2026 endpoint). Tab1 Panel B shows the identical
percentile/year change (May "top .0002% richest ... 2025 $" → August "top .001% richest ...
2026 $").

### RC7 - Tab2 gains two new columns mid-sheet (class a, with new content noted)

`tests/testthat/test-tables.R:59-66` hardcodes `range = "B7:H14"` and reads columns
`xl$E, xl$F, xl$G` for the top-4 block. May's `Tab2` had columns B-D (all-billionaire block),
blank E, F-H (top-4 block). August inserts two new columns *"Total taxes paid"* / *"Total
taxes /wealth"* right after column D, pushing the old F/G/H (top-4: company wealth, CA inctax,
CA inctax/wealth) to H/I/J, with new total-tax columns for the top-4 block at K/L. `xl$E` in
August is now *"Total taxes paid"* (all-billionaire block), not the old blank spacer, and
`xl$F/G` are similarly shifted - hence `top4_company_wealth_b` (R) landing next to a completely
different Excel column. `build_tab2` (`R/tables.R:21-58`) does not compute the new
total-taxes columns at all; that is new content in August, not yet mirrored in R (out of scope
to add in phase 1, per plan step 6).

### RC8 - `Fig8` renamed/repurposed; the Laffer curve moved to `Fig9` (class a)

`tests/testthat/test-compute.R:67` - `read_sheet("Fig8", range = "A11:E211")`.

August's `Fig8` sheet (31x9) is titled *"Figure 8: Value of Venture Capital Deals in California
(as % of total US VC Deals)"` - entirely new content, backed by the new
`data_venturemonitor_annual`/`data_venturemonitor_quarterly` sheets (section 4). The Laffer
curve that used to live at `Fig8` (223x5, `"Figure 8: Laffer Curve"`) is now at the new `Fig9`
sheet, byte-for-byte the same layout: `Fig9!B8:E8` parameter defaults (10, 0.002, 2000, 15)
match `R/compute_pareto.R:143-146`'s hardcoded defaults exactly, and `Fig9!A10:E211` is the
same 201-row Laffer table headed `tax rate | mechanical tax revenue | wealth tax base | actual
tax revenue | long-run tax revenue`. The fix (not made in this phase) is a one-line sheet-name
change from `"Fig8"` to `"Fig9"` in the test; `R/compute_pareto.R` itself needs no change since
it never reads the sheet name directly, only these comment-documented defaults, which still
match.

### RC9 - smaller hardcoded literals (class a)

- **RC9a** `extract_rtb_2026_industry`, `R/data_sheets.R:101-112`, hardcodes `n_max = 14`.
  `rtb_2026_industry` grew from 35 to 37 rows; the "Total" row that used to be the 14th data row
  is now further down, so the truncated read ends on "Energy" instead of "Total".
- **RC9b** `tests/testthat/test-data_sheets.R` (`extract_data_sec_agg covers years 2019-2025
  with no summary rows`) hardcodes an expected 2025 `forbes_worth` of `2051.66` (May's cached
  value); August's underlying `data_sec_all` aggregate for 2025 is ~2055 (a legitimate input
  update, but the test's literal wasn't refreshed).
- **RC9c** `tests/testthat/test-ingest_excel.R` (`list_sheets returns the 36 sheets in the BSZ
  workbook`) hardcodes `36`; August has 40 sheets (the 4 new ones in section 4).
- **RC9d** `extract_shortrunseries returns the raw wide series` hardcodes cell `E6 = 173.8`;
  this is a direct consequence of RC1 (shortrunseries row layout shifted), not an independent
  bug.

### RC10 - genuine input-data change inside the workbook itself (class c)

- `compute_data_sec_agg matches Excel data_sec_agg for shared columns`: R's re-derivation from
  the raw `data_sec_all` list gives `n=244` California billionaires for 2025; the workbook's
  own pre-aggregated `data_sec_agg` sheet cache still shows `n=240`. This is not an R bug - R
  correctly recomputes from the (updated) raw list; the workbook's own cached aggregate sheet
  disagrees with its own raw list by 4 people, which looks like an August update to
  `data_sec_all` that wasn't propagated to the `data_sec_agg` cache inside the workbook. Worth
  flagging to the authors; nothing to fix on our side.
- `compute_data_sec_agg excludes Ellison from every year`: the test's hardcoded tolerance
  (`tests/testthat/test-compute.R:84`, `+ 60   # Ellison ~ $68B in 2019`) no longer holds; the
  gap between "with Ellison" and "without Ellison" aggregates for 2019 shrank in the August
  data. Likely reflects a revised 2019 wealth estimate for Ellison in `data_sec_all`; the
  hardcoded threshold in the test is what's stale (also listable under class (a), since the
  failure mechanism is literally a hardcoded literal in test code - noted here because the
  underlying cause is a genuine data revision, not a layout shift).

### Class (d) - snapshot failures (expected, not regenerated)

20 snapshot-test failures across `fig1`-`fig4`, `fig_a1`-`fig_a3`, `data_sec_agg_r`, `tab5_r`,
`billionaires_ca_inctax_r`, `shortrunseries_r`, `tab1`/`tab2`/`tab5`/`tab_a1` panels: every one
of these targets consumes values that changed for one of the reasons above (RC1-RC7, RC10), so
byte-for-byte snapshot comparison fails by design. Per plan scope, `tests/snapshot_regenerate.R`
was **not** run and no `.rds` file under `tests/snapshots/` was touched.

## 4. Sheets new in August with no R code yet

- **`Fig9`** (now read by the pipeline through `fig8_laffer_sheet()`, see RC8; 223 rows x 5 cols, 1,004 of 1,025 non-empty cells are formulas). Not new content
  - this is the May `Fig8` "Laffer Curve" sheet, relocated verbatim (same parameter defaults,
  same 201-row tax-rate/revenue table). See RC8.
- **`2023-b-1__adjusted_gross_income`** (77 rows x 14 cols, 148 of 535 non-empty cells are
  formulas). A time series of US Adjusted Gross Income statistics by tax year (1949-2025+),
  columns `Taxable Year, Returns, AGI, Taxable Income, Total Tax Liability, consistent year`.
  This is the source feeding the new GDP→AGI denominator swap in Tab1/TabA1 (RC4).
- **`data_venturemonitor_annual`** (32 rows x 24 cols, 42 of 201 non-empty cells are formulas).
  Annual venture-capital equity investment counts and dollar values, California vs. rest-of-US,
  from Pitchbook Venture Monitor, 2006-2026 (2026 partial through Q2). Feeds the new `Fig8`
  (RC8).
- **`data_venturemonitor_quarterly`** (38 rows x 10 cols, 68 of 353 non-empty cells are
  formulas). Same Pitchbook series at quarterly granularity, 2018Q1-2026 partial. Also feeds
  the new `Fig8`.

## 5. Headline-number diff, May vs. August (cached values)

- **Tab1** (Wealth Growth of CA Billionaires): 2025 row - `n_billionaires` 239→240,
  `wealth_b` 2051.66→2054.82 (+0.15%). A new `"2026 (July 1st)"` row was added:
  n=250, wealth=$2307B. Column F/G redefined GDP→AGI (RC4): 2025 `F` 4250.5 (CA GDP)
  → 2230.3 (CA AGI); `G` (wealth/denominator) 0.483→0.921. Panel B redefined
  top .0002%→top .001%, 2025→2026 endpoint (RC6): "wealth per family" 1982 $0.95B→$0.41B (now a
  wider percentile with smaller average wealth), 2025/2026 $28.4B→$10.2B, growth-factor
  30x→25x.
- **Tab2** (CA Income Tax Paid): 2025 `ca_inctax_b` 4.14→4.35 (+5.0%); average row
  1.230→1.232 wealth (~flat), CA-inctax average 3.032→3.061 (+1.0%). New columns
  "Total taxes paid"/"Total taxes/wealth" added (RC7): 2025 total taxes paid = $25.2B
  vs. CA-income-tax-only $4.35B (total taxes are ~5.8x CA income tax alone).
- **Tab3** (CA Income Tax, Top 4 on Company Wealth): **byte-for-byte identical** in May and
  August (all 22x9 cells match exactly). No change.
- **Tab4** (Wealth/Income/Taxes of Top 4): essentially unchanged - 31 of 34 rows identical;
  row 27 ("Total taxes paid") gained 3 previously-blank column values (J/K/L =
  8.38/7.50/15.88) and row 30 ("Total taxes/Gain in wealth") gained one previously-blank
  value (J = 0.00259). All previously-populated cells unchanged.
- **Tab5** (Scoring the One-Time 5% Wealth Tax): benchmark date rolled 4/15/2026→7/1/2026;
  scenario 1: n 249→250, wealth $2182B→$2307B (+5.7%), wealth_tax_revenue $98.2B→$103.8B
  (+5.7%); scenario 4 (both adjustments combined): wealth_tax_revenue $108.5B→$114.8B (+5.8%).
  All 4 scenarios move by roughly the same ~5.4-5.8% (consistent with the wealth benchmark
  update being the dominant driver, not a rate or methodology change).
- **TabA1** (Wealth Growth of US Billionaires): 2025 row unchanged (938 billionaires,
  $8189B) - May's 2025 figures are preserved as historical data in August. A new
  `"2026 (July 1st)"` row added: 982 billionaires, $8825.95B (+7.8% over 2025). New AGI
  columns F/G added (previously blank). Panel B redefined the same way as Tab1 (RC6):
  top .0002%→top .001%, 2025→2026 endpoint; wealth-per-family 1982 $1.09B→$0.42B, 2025/2026
  $16.9B→$5.4B, growth-factor 27.2x→13.1x (the wider percentile roughly halves the growth
  multiple because it now includes many more, less-extreme fortunes at the base year).
