# Code review ledgers

Work in progress. One ledger per OPA: the chain of code behind the headline number, top (the number on the page) to bottom (the raw data), with the reviewer's state per layer. The states are recorded during review sessions; see the review protocol in the opa-review skill.

The three states: reviewed means the reviewer knows what goes in, what comes out and the one idea. Lightly reviewed means the layer was looked at, with what is understood so far and what is still missing written down. Not reviewed means no review yet.

## BSZ: the main estimate

- Headline: Main estimate, Base scenario, $106.8B. wealth tax + extra income tax from selling assets - income tax lost to leavers (present value, 5 years at 3%)
- Where: https://fhoces.github.io/opa-prop40/bsz-analysis/site/explorer/
- Commit: 48e951c
- Seeded: 2026-10-14
- Headline verified by: python3: read grid.js, Base row index 788, main_estimate = wealth_tax_revenue + extra_ca_inctax_sales + annual_ca_inctax_loss x (1 - 1.03^-5)/0.03 = 106.795965
- Runs for a stranger: AUDIT.md step 8, level 2: .github/workflows/bsz-ci.yml rebuilds the pipeline on a clean runner; no one-click (Binder) yet.

Progress: 0 of 8 reviewed, 4 lightly reviewed, 4 not reviewed

| Layer | Where | Method | State | Missing | Feedback | Updated |
|---|---|---|---|---|---|---|
| 1. The number on the page | [bsz-analysis/site/explorer/index.html render(): pick the row, print the main estimate L485-L503](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/site/explorer/index.html#L485-L503) | plumbing: Display only. The definition under the headline number (lines 219-225) is the method; footnote 1 says it is this OPA's choice, not the authors'. | lightly reviewed |  |  | 2026-10-13 |
| 2. The grid file the page reads | [bsz-analysis/site/explorer/grid.js window.__GRID__ L1-L2](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/site/explorer/grid.js)<br>bsz-analysis/export/py/site/grid.js window.__GRID__ L1-L2 | plumbing: Plumbing. The R-written file is the committed one; the Python twin writes the same text to export/py/site/grid.js, and test-site.R checks the committed file is byte-identical to the exporter's output. | lightly reviewed | What object contains all the grid estimates? snap? |  | 2026-10-13 |
| 3. Writing the grid file | [bsz-analysis/R/site_exports.R site_grid_js_text(), write_site_grid_js() L160-L196](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/site_exports.R#L160-L196)<br>[bsz-analysis/py/site_exports.py site_grid_js_text() L181-L205](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/site_exports.py#L181-L205) | plumbing: Plumbing. | lightly reviewed |  |  | 2026-10-13 |
| 4. Building the grid and the present value | [bsz-analysis/R/site_exports.R site_pv_factor(), build_site_grid() L52-L94](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/site_exports.R#L52-L94)<br>[bsz-analysis/py/site_exports.py site_pv_factor(), build_site_grid() L17-L97](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/site_exports.py#L17-L97) | OPA's own definition: The sum is this OPA's definition (comment at lines 52-57; the deck). BSZ PDF p.27 gives the 5-year horizon; the 3% rate is the middle of the RJKDC report's 1.5-4.5% range. BSZ give no rate. | lightly reviewed |  |  | 2026-10-13 |
| 5. The estimating function | [bsz-analysis/R/compute_tab5.R score_tab5_cell() L80-L110](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/compute_tab5.R#L80-L110)<br>[bsz-analysis/py/compute_tab5.py score_tab5_cell() L72-L95](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/compute_tab5.py#L72-L95) | matches: Tab5!B6:H6 of the workbook and BSZ PDF p.24. Matches: test-compute.R asserts the R row equals Tab5!B6:H9 to 1e-4, and the Python twin equals the R export. | not reviewed |  |  | 2026-10-13 |
| 6. The fixed inputs the function needs | [bsz-analysis/R/compute_tab5.R tab5_scoring_inputs() L26-L76](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/compute_tab5.R#L26-L76)<br>[bsz-analysis/py/compute_tab5.py tab5_scoring_inputs() L17-L70](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/compute_tab5.py#L17-L70) | matches: Tab2!C14 (C), Tab3 (the top 4's own tax), Tab5 rows 18-29 (leavers). The residual rate is Tab5!F18/B18. | not reviewed |  |  | 2026-10-13 |
| 7. Constants and labelled inputs | [bsz-analysis/R/vintage.R .TAB5_CONST, tab5_const() L115-L147](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/vintage.R#L115-L147)<br>[bsz-analysis/py/vintage.py TAB5_CONST, tab5_const() L85-L112](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/vintage.py#L85-L112) | matches with caveat: Tab5!B6:C6 (Forbes real-time list, 1 Jul 2026). Caveat: retyped literals, checked only indirectly through the Tab5 test, not read from the cells. | not reviewed |  |  | 2026-10-13 |
| 8. The raw source: the workbook | [bsz-analysis/R/data_sheets.R extract_tab2(), extract_tab3() L118-L141](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/R/data_sheets.R#L118-L141)<br>[bsz-analysis/py/data_sheets.py extract_tab2(), extract_tab3() L120-L134](https://github.com/fhoces/opa-prop40/blob/48e951c/bsz-analysis/py/data_sheets.py#L120-L134) | plumbing: Tab2 rows 7-14, Tab3 rows 6-16. Plumbing: readxl / openpyxl with fixed column names. | not reviewed |  |  | 2026-10-13 |

### Layer 2, The grid file the page reads

Understood so far: it displays the output

Still missing: What object contains all the grid estimates? snap?

### Feedback

- 2026-10-13, layer 1, applied: not r or python code
- 2026-10-13, layer 2, applied: What object contains all the grid estimates? snap?
- 2026-10-13, layer 2, applied: this is not r or python
- 2026-10-13, layer 3, applied: comment right abouve the line that creates the output estimates
- 2026-10-13, layer 3, applied: You mentioned 9 outputs. Male clear if this are the main + those in the folded table and explain how to get the series for the main estimate only
- 2026-10-13, layer 4, applied: highlitght that score_tab5_cell is the key function here

Generated by review/render.py from the ledgers; do not edit by hand.
