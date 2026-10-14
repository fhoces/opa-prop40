# WP-6: The RJKDC report, deck, materials page, mismatches and script headers
Owner: opus. Status: done.

## Changed
- `rjkdc-analysis/site/repro.qmd`:
  - Subtitle (A-09, A-10, K1): "Jaros and Rauh (NBER, September 2026; first version by Rauh, Jaros, Kearney, Doran and Cosso, March 2026), reproduced ...".
  - "What is reproduced" (A-09, A-10, K1, V-10/KG): the chapter is now "Jaros and Rauh, *The Net Present Value of the California Billionaire Tax Act*, NBER chapter c15504 (22 September 2026; ...), the litigation-weighted revision of the first version by Rauh, Jaros, Kearney, Doran and Cosso (SSRN 6340778, March 2026; ...)". The NBER and SSRN glosses are added there, at their first prose use.
  - Same paragraph (A-13): "(PDF p.1)" becomes "(the Figure 3 note, PDF p.35; the text on p.1 says 85%)".
  - Step 4 (A-16, E-04, under Q1): "The range is **guesswork**" now goes on to say that the anchor is a published market yield, which is why the export contract and disputes row 2 say research, and that the width of the band is the authors' judgement and is what moves the result. Both rates come from `pct(100 * nb$rg_min)` and `pct(100 * nb$rg_max)`, not typed in.
  - Step 6 (E-18, KG): "exact value" becomes "exact expectation", glossed at first use. "seeded run" is glossed at first use: "a seeded run: one run of the random draws started from a fixed seed number, 2026, so it gives the same draws every time; its mean differs from the exact expectation by sampling error".
  - Section 4.3 (A-14, A-15): "The paper (eq. 4, p.22) and the authors' README print $72.06B, the difference of two figures each rounded to two decimals (100.91 − 28.85), and the script hard-codes 72 (mismatch 4): one unrounded value, its rounding and a round literal." The two figures are inline `num(nc$domestic_total_grown, 2)` and `num(nc$removed_departed_total, 2)`, not typed in.
  - Origins chunk (E-24): `first_only <- inputs$version == "ssrn"`. The four `rauh_mc_c_*` and `rauh_mc_r_*` rows now show in the main table with their contract labels. The comment line above it is updated to match ("version "ssrn""). The footnote now names the three rows that stay first-version only (`rauh_mc_wt_min`, `wt_central_scenario`, `brulhart_semi_elasticity`): "its revenue floor, its central scenario and the Swiss semi-elasticity as its workbook applies it".
- `rjkdc-analysis/site/slides/slides.Rmd`:
  - Title (A-09): "The Net Present Value of the California Billionaire Tax Act".
  - Subtitle (A-10, K1): "(Jaros and Rauh, NBER, September 2026; first version by Rauh, Jaros, Kearney, Doran and Cosso)".
  - Title-slide intro (A-10): "by Jaros and Rauh (NBER, September 2026), revising the first version by Rauh, Jaros, Kearney, Doran and Cosso (RJKDC)".
  - Headline slide (A-10, A-13): "Jaros and Rauh, litigation-weighted (the first version, March 2026, was by Rauh, Jaros, Kearney, Doran and Cosso)". The outcomes line now ends "(PDF p.35, Figure 3 note; 85% in the text, p.1)".
  - V-28: a `usdb()` helper is added to the setup chunk, as specified. Headline, range, first-version footnote and K = 500 box now use `usdb()` (−$38.9B, $28.4B to $35.6B, −$24.7B, $3.34B). The prose now reads "$100 billion", "$29.6 billion, range $28.4 to $35.6 billion", "$5.80 billion" a year, "$36 billion ... $C$ = $4.55 billion", and the slide title "From $94 billion to about $30 billion". The sentence "(Amounts in this deck are in billions of dollars, "bn".)" is removed. `num()` is kept for figures without a unit, and "approximately 30 billion" is kept as the paper's quote. I checked that xaringan's math protection runs after knitting, so a "$" followed by a digit never closes a math span (the BSZ deck's "$`r bn(...)` billion" lines render that way).
- `rjkdc-analysis/site/materials.qmd`:
  - Intro (A-10, K1): "the RJKDC analysis (Jaros and Rauh, NBER chapter c15504, September 2026; first version by Rauh, Jaros, Kearney, Doran and Cosso, March 2026)".
  - Tests table (V-30): `col.names = c("file", "tests", "expectations", "tests passed", "tests failed", "tests skipped")`, and the summary line now reads "... `r tot["passed"]` tests passed, ...".
- `rjkdc-analysis/MISMATCHES.md`:
  - Preamble (A-09, A-10): "reproducing Jaros and Rauh, *The Net Present Value of the California Billionaire Tax Act* (NBER chapter c15504, September 2026; first version by Rauh, Jaros, Kearney, Doran and Cosso, March 2026)".
  - Item 4 (A-14): new line "**NBER chapter**, PDF p.22 (eq. 4): the same 72.06 in the semi-elasticity formula."
  - Item 4 (A-15): new sentence "The 72.06 is the difference of the two figures as rounded to two decimals (100.91 − 28.85); the person-level sum is 72.0515." The heading is unchanged (`test-site.R` counts the headings).
- `rjkdc-analysis/R/income_tax_mc.R`, `R/npv_tables.R`, `R/revenue_chain.R` (A-21): comment lines 1, 1-2 and 1-2 now give the first version's numbering, labelled as such. In `income_tax_mc.R` the chapter's numbering is added (Table 9, p.30); in `npv_tables.R`, the chapter's break-even table (Table 10, p.34). Line counts are unchanged and no code line changed (`git diff -U0` shows only `#` lines). I checked the materials page's `describe()` against the new headers in Python: it takes "Income-tax Monte Carlo (first version numbering: Sec 5.1.2, Table 8, p.17; in the chapter Table 9, p.30).", "First version numbering: Sec 5.2-5.4, Table 9 (...) and Table 10 (..., p.34)." and "First version numbering: Sec 4, the revenue chain ... (March 2026 version pp.10-14)."

Departures from the plan's wording:
- (a) Both subtitles say "first version by Rauh, Jaros, Kearney, Doran and Cosso" instead of "first version with Kearney, Doran and Cosso". The plan's own acceptance check needs `grep "with Kearney"` to come back empty, and the five-name form is K1's.
- (b) Step 4 links "disputes row 2" the way the report already does elsewhere, instead of writing "DISPUTES row 2". It also glosses "export contract" (KG wording), because the term is new on that page.
- (c) MISMATCHES item 4 says "PDF p.22 (eq. 4)", matching the file's existing "**NBER chapter**, PDF pp.18-19 (...)" form.
- (d) The numbers in the report's new text are inline R, not typed in (rule 3).

Acceptance checks:
- `grep "with Kearney"` over the four sources: empty.
- "California Billionaire Tax Act": 1 in each of repro.qmd, slides.Rmd and MISMATCHES.md.
- `grep " bn\b" slides.Rmd`: empty.
- `grep 'grepl("^rauh_mc_"' repro.qmd`: empty.
- "first version numbering": found in all three R files, and each still starts with `#`.
- No em or en dashes were added.
- `check_links.py` shows no new broken link in these files.
- Not run: `screenshot.cjs`. I changed no rendered page, and the sources cannot be rendered here.

## Needs a local render
- `rjkdc-analysis/site/repro.html`: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd`
- `rjkdc-analysis/site/materials.html`: `cd rjkdc-analysis && quarto render site/materials.qmd`. This also picks up the MISMATCHES.md edits and the three script headers.
- `rjkdc-analysis/site/slides/slides.html`: `Rscript -e 'rmarkdown::render("rjkdc-analysis/site/slides/slides.Rmd")'`. After rendering, check two slides that each gained about a line:
  - the title slide: the intro paragraph should not run into the credit line;
  - "The headline": the blue box should clear the footnote.
- The comment-only R changes do not need `tar_make()`.

## Needs a follow-up (files outside the package)
- `rjkdc-analysis/export/r/inputs.csv` (generated by `R/export.R`, for the author): rows `rauh_mc_c_min`, `rauh_mc_c_max`, `rauh_mc_r_min` and `rauh_mc_r_max` are version "both" and now appear in the report's main origin table. Their `source`/`page` still cite the first version's script and pages ("NPV_dist.R:47; paper eq.24 (S&P 500 dividend yield anchor p.18 ...)", page 20). Giving the chapter's references (`NPV_dist_v8.R`, eq. 18, PDF p.32 for the anchor) would match the A-21 fix.
- `rjkdc-analysis/export/r/outputs.csv` (generated, for the author; A-14): `nber_ceiling` has `printed_page` NA. The report now cites eq. 4, p.22, while its typed `page_nber` vector gives "21" for `nber_ceiling`. Both may hold (Table 7, p.21; eq. 4, p.22), but the author should pick the page the export records.

## Could not do
- Nothing in the package was left undone.

## Noticed on the way (not changed)
- `slides.Rmd`: the slide title "The Monte Carlo behind −38.9 (Sec 5.4)" and the headline slide's "Reproduced: −38.89 ... and −38.98" print dollar figures without a unit. V-28 named only "bn", so `num()` stays there.
- KG terms appear unglossed on the deck and the materials page. Item 6 named only the report. The terms are:
  - deck: "seeded run", "exact expectation" (headline slide), "NBER chapter", "SSRN 6340778", "Monte Carlo";
  - materials page: "NBER chapter c15504", "{targets}", "Python twin", "continuous-integration".
- The RJKDC report (Introduction, 4.5, 5.2) and deck (slides "What is being estimated" and "The perpetuity multiplier") call the other analysis "the BSZ report". K6 renames only "RJKDC report" on the BSZ pages.
- `MISMATCHES.md` uses " - " as a dash in prose in items 4, 5 and 7 ("rebuild -", "listed - as", "`D24` ... - and"). Item 4 still says "the README's prose (72.06)" and "the README's rounding", although the new line records that the chapter prints 72.06 too.
- In repro.qmd's "Every input, by origin", the sentence "The data and research inputs (the Forbes base, the FTB brackets, the Pareto fit) fix the *scale*" now sits above a table where the discount-rate bounds are also "research" (the contract rows). Step 4 explains why, but the author may want this sentence to name them.
