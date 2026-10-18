# WP-4: BSZ overview, explorer and the site exports
Owner: opus. Status: done.

## Changed
- `bsz-analysis/site/index.html`: first paragraph gets T1, the 90% health care / 10% education and food assistance sentence, linking `../../docs/initiative/README.md` (V-03).
- `bsz-analysis/site/index.html`: headline label now "Main estimate<sup>1</sup>, base scenario (BSZ's benchmark, row 1 of their Table 5, plus its income tax effects)" (A-02, V-07).
- `bsz-analysis/site/index.html`: headline definition now "counted over 5 years and converted to today's dollars at 3% a year (present value: what money lost in future years is worth now)" (V-08, jargon: present value).
- `bsz-analysis/site/index.html`: Open Materials card glosses "its Python twin (the same computation written again in Python and checked against the R result)", the root's wording (jargon: Python twin).
- `bsz-analysis/site/index.html`: "What the model says" now reads "... Zucman (2026), which they call the benchmark, with its income tax effects added." (A-02, V-02).
- `bsz-analysis/site/index.html`: scenario table header "Total (main estimate)<sup>2</sup>" becomes "Net total<sup>2</sup>". Row 1 becomes "Base (1), the main estimate" (E-06).
- `bsz-analysis/site/index.html`: scope paragraph "What this OPA does not estimate" gets T2: only the JR analysis projects the base to 31 December 2026, the 7% from the Act's findings, the forecast check (chapter PDF pp.12-13) (A-11).
- `bsz-analysis/site/index.html`: "What reproduces", Table 5 row gets T4. The two pinned substrings stay ("printed as $0.19B and $0.51B", "workbook gives $0.20B and $0.52B"). "The paper cuts these two" is gone (A-04).
- `bsz-analysis/site/index.html`: "What reproduces", workbook row gets T3: the 2026-09-04 copy repeated the rows, and the 2026-10-08 update this OPA reads lists each once (A-03).
- `bsz-analysis/site/index.html`: the match definition now reads "or the paper prints it one unit lower in the last digit (note 1)" (A-04).
- `bsz-analysis/site/explorer/index.html`: standfirst "Boll, Saez and Zucman (BSZ, NBER, August 2026)" (V-14). "Most inputs are guesswork." becomes "Five of the six inputs below are guesswork." (A-05). The sentence is static HTML, so it is typed. Checked against `grid.js`: five dials are guesswork and `pareto` is research.
- `bsz-analysis/site/explorer/index.html`: headline definition changed exactly as on the overview (V-08).
- `bsz-analysis/site/explorer/index.html`: the fixed-inputs line (script) ends "To count the loss for longer, use the H dial of the [comparison explorer](../../../comparison/site/explorer/)." The link has class `more`, like the report link before it (V-13).
- `bsz-analysis/site/explorer/index.html`: scenario key. "Base" now reads "Table 5 row 1, BSZ's benchmark: ..." and shows as the preset button's title (A-02). "Missing billionaires" now reads "estimated by extending the shape of the list above $4.5B down to $1B (a Pareto extrapolation)" (jargon: Pareto extrapolation).
- `bsz-analysis/R/site_exports.R` l.95 and `bsz-analysis/py/site_exports.py` l.103: outcome label "Main estimate (net)" becomes "Net total" (E-06).
- `bsz-analysis/R/site_exports.R` l.136 and `py/site_exports.py` l.143: τ basis now reads "The Act as written: 5% (GGSS p.1), payable at once with the 2026 income tax or in five yearly installments with a 7.5% deferral charge (§50301(c))." (E-10).
- `bsz-analysis/R/site_exports.R` l.143-149 and `py/site_exports.py` l.149-155: "Asserted, argued from enforcement" becomes "Set by the authors, argued from enforcement". The three plain "Asserted (" become "Set by the authors (" (A-07).

Checks run:
- Both exporters parse (`Rscript` parse, Python `ast`). The six changed strings are identical in R and Python, and the line counts did not change.
- All the `test-site.R` pins on the overview are still present after whitespace collapse: the 28/26/2 cells, the two printed/workbook substrings, eight notes, the kind counts, the break-even and Laffer figures, every table value, $103.8 billion and $106.8 billion.
- These strings are gone from the four files: "Asserted", "Most inputs are guesswork", "BSZ, 2026)", "Total (main estimate)", "cuts these two", "appear twice", "payable 1%/yr", "cut rather than rounded", "Main estimate (net)". No em or en dashes.
- `check_links.py` prints nothing, as in `00-links-before.txt`.
- `screenshot.cjs` exits 2 because Playwright is missing. I rendered both pages with headless Chrome (`--dump-dom`) instead.
  - The scripts run on both pages.
  - The overview headline fills $106.8B and $103.8 billion from `grid.js`.
  - On the explorer, the fixed-inputs line, the scenario key and the Base button title show the new text.
  - The explorer's outcome table still says "Main estimate (net)" until `grid.js` is regenerated.

## Needs a local render
- `bsz-analysis/site/explorer/grid.js`, `bsz-analysis/site/data/inputs.csv`, and `export/py/site/grid.js` and `inputs.csv`: `cd bsz-analysis && Rscript -e 'targets::tar_make()' && python py/run_export.py && Rscript tests/testthat.R`. Without this, `test-site.R`'s byte-for-byte `grid.js` test fails, because the label is now "Net total".
- `bsz-analysis/site/repro.html`: `cd bsz-analysis && quarto render site/repro.qmd`. The "Every input, by origin" table reads `inputs.csv`, which has the new τ, α, m, αₛ and s basis text.
- The two hand-written pages need no render.

## Needs a follow-up (files outside the package)
- `bsz-analysis/tests/testthat/test-site.R` l.84-85: the comment says "Each is the workbook's value cut at the second decimal, not rounded". It could say "Each is printed one unit lower in the last digit than the workbook's value rounded (reproduction note 1; row 4 of the same column is rounded)". The `trunc()` assertion still holds numerically, so no test change is needed.
- `review/bsz.json`: the ledger quotes `R/site_exports.R` text, including "Main estimate (net)". Reseed the bsz chain (`review-sync`) after the commit. Line ranges are unchanged: the replacements kept every line in place.

## Could not do
- Playwright `screenshot.cjs --text`: Playwright is not installed. Headless Chrome was used instead (above).

## Noticed on the way (not changed)
- `bsz-analysis/site/explorer/index.html` keeps "base scenario" without BSZ's word "benchmark" in three places: l.541 (the headline label "Main estimate¹, base scenario"), l.242 (the chart title) and l.254 (the table caption "The shaded column is the base scenario."). A-02 lists them, but the plan names only the scenario key for the explorer.
- `comparison/DISPUTES.md` l.50 describes BSZ's framing as "One-time 5%, payable 1%/yr over 5 years plus a deferral charge (Resp p.1, GGSS p.1)". This is close to the τ wording replaced here, and it cites the authors' response, so it may be intended.
