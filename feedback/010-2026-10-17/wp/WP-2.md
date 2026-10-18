# WP-2: Comparison step titles and the report's source cells
Owner: opus. Status: done.

## Changed
- `comparison/R/model.R` l.84-86, `bridge_steps()$title` (A-23, E-26, T7): "Share of billionaire income tax lost" is now "Share of billionaires' income tax lost"; "Billionaires' annual CA income tax" is now "Billionaires' yearly California income tax"; "How long the income tax loss lasts" is now "How long the lost income tax is counted". No other title, step id, kind or row changed; the q title is unchanged.
- `comparison/R/model.R` l.24, header comment: "share of billionaire income tax lost:" is now "share of billionaires' income tax lost:". This is a comment, not a title. I changed it so the package's acceptance grep over `comparison/R` prints nothing.
- `comparison/py/bridge.py` l.104-106, `STEPS`: the same three titles, so R and Python match row for row.
- `comparison/R/build.R` l.93, `jr_source` of `W_core` (A-11): after "($2,027.4B at 7% growth" adds ", the average yearly growth of billionaire wealth that the Act's Section 1(w) states; a VAR(2) forecast gives $2,036.6B, PDF p.13". "chapter Sec. 3.2, PDF pp.12-13" still comes first.
- `comparison/R/build.R` l.95, `jr_source` of `re` (A-17): appends "; the chapter prints the deduction as $8.19B, 'only around 0.6%' of the stayers' base (PDF p.16); this OPA's 0.5% is of the whole grown base". "chapter Table 6, PDF p.17" still comes first.
- `comparison/R/build.R` l.99, `jr_source` of `alpha` (A-16): now "none: avoidance channels other than leaving are left out because US securities are third-party reported (chapter PDF p.24 fn.25); the baseline makes no avoidance assumption and corrects the list instead (chapter PDF p.19 fn.21)". The p.24 citation comes first.
- `comparison/R/build.R` l.105, `jr_source` of `r` (V-11): "the real rate net of the loss's growth" is now "the interest rate minus the loss's yearly growth (a real rate)".

Quotes checked against `rjkdc-analysis/original-materials/jaros-rauh-nber-c15504-2026-09.pdf`. Section 1(w) and $2,027.4B are on PDF p.12. $2,036.6B is on p.13. "only around 0.6%" of the stayers' base is on p.16 and Table 6 on p.17. Fn.21 on p.19 reads "Our baseline makes no avoidance assumption and corrects the underlying list". Fn.25 on p.24 gives third-party reporting of US securities as the reason the avoidance channel is excluded.

Acceptance, run without writing any generated file:
- `grep -rn` for the three old titles over `comparison/R` and `comparison/py` prints nothing.
- I imported `bridge.py` and ran `build_all()` in memory, so `comparison/export/py/` was not rewritten. It runs. Its `dial_path` titles carry the new f, C and H names. The 11 R titles equal the 11 Python titles row for row, which is what `test-dial-path.R` l.76 compares.
- Both R files parse. I sourced `contract.R`, `model.R` and `build.R` and called `bridge_input_table(bridge_inputs(read_contracts()))`. The first source each quantities cell cites (`QUANTITY_SOURCE_PATTERN` plus `quantity_source()`) is: W "chapter PDF pp.12-13" (unchanged), re "chapter PDF p.17" (unchanged), a "chapter PDF p.24" (was "NBER chapter Secs. 4-5"), r "chapter PDF p.32" (unchanged), C "chapter PDF pp.28-30" (unchanged; `jr_top_earners()` and the survey's `_K` still find K = 212 and K = 500).
- No em or en dash in any source cell.
- I did not run `check_links.py` or `screenshot.cjs`. The package changes no page or link, only code that generated pages print.

## Needs a local render
- `python3 comparison/py/bridge.py && Rscript comparison/run.R && Rscript comparison/tests/testthat.R`. This rewrites `comparison/export/r/` and `export/py/` (`bridge.csv`, `dial_path.csv`, `inputs.csv`), `assets/comparison-data.js` (which carries the titles) and the root `index.html`. In the root `index.html`, the a row's JR cell will cite "chapter PDF p.24" instead of "NBER chapter Secs. 4-5", unless WP-1's new tip already cites a page.
- `cd comparison/site && quarto render repro.qmd`: the disputed-inputs table prints the four new source cells, and the bridge and Shapley tables print the new titles.
- The comparison deck, `comparison/site/slides/slides.Rmd`, reads `dial_path.csv` and `bridge.csv` titles. Render it after the rebuild, as WP-3 already plans.

## Needs a follow-up (files outside the package)
- None beyond WP-3. WP-3 already covers every typed copy of the old titles and wording I found: `comparison/site/repro.qmd` l.386-396 (quoted titles), `comparison/site/slides/slides.Rmd` l.1093 (typed "Share of billionaire income tax lost"), l.853 and l.1035 ("real rate net of the loss's growth"), and `comparison/DISPUTES.md` l.54 (row 5 title "Billionaires' annual CA income tax").

## Could not do
- Nothing.

## Noticed on the way (not changed)
- `comparison/R/build.R` l.105: the plan's wording now leaves two parentheses side by side in the r cell, "(a real rate) (chapter PDF p.32 and eq. 18, ...". "(a real rate; chapter PDF p.32 ...)" would read better and would still cite p.32 first. I kept the plan's text.
- `comparison/R/site.R` l.548, a comment: "the JR draw is r - g, the real rate net of the lost tax's growth". This is only a comment, in WP-1's file.
- The acceptance grep in `04-plan.md` lacks `-r`. Against directories it prints only "Is a directory" errors, so I ran it with `-rn`.
