# WP-3: Comparison report, materials page, deck, DISPUTES.md and the two READMEs
Owner: opus. Status: done.

## Changed
- `comparison/site/repro.qmd`:
  - Introduction (A-01, V-02): the BSZ sentence now ends at Table 5's printed figure. A new sentence follows: "Adding the income tax raised on assets sold to pay it, and subtracting the income tax lost to billionaires who leave over `r fmt_input("H", ...)`, gives this OPA's net total for the BSZ analysis, `r usd(eb$bsz_model)`."
  - "Versions and citations" (A-01): "Adding the income tax raised on assets sold to pay it and subtracting the income tax lost to leavers over `r fmt_input("H", ...)` gives this OPA's net total, **`r usd(eb$bsz_model)`**, not a figure BSZ print."
  - New closed fold after "Versions and citations", titled "When the output and the bridge were fixed" (E-19). It uses the plan's text with 2.73% from `r r_jr` (meta.csv). The plan's colon became a sentence break. The dates were checked against `PLAN.md` l.23, l.78 and decisions 9 to 13.
  - "The common output", the discount-rate paragraph (V-11): "the real discount rate net of the growth of the lost income tax" becomes "the interest rate minus the lost income tax's yearly growth (a real rate; chapter eqs. 13-14, PDF p.31)".
  - Conventions (E-05): the plan's sentence on the due date and "today's dollars" was added after the first sentence on present values.
  - Conventions (E-03, V-11): the plan's sentence would have repeated the sentence before it ("discounted at the rate dial's value"), so I merged the two. The passage now reads: "The lost income tax is a flat yearly amount, discounted at the rate dial's value, r. For a loss that grows, the same present value comes from discounting a flat loss at the interest rate minus the growth. The JR analysis draws that rate, r − g, the interest rate minus the lost tax's yearly growth (a real rate; chapter eqs. 14 and 18), so a flat loss at its rate is the chapter's growing loss. [unchanged sentence on note 3] The BSZ end's `r r3` is read the same way, as r − g, and is the middle of the same draw."
  - "One function, both ends" l.331 and "Step 2" l.493 (V-11, extension): "the discount rate net of the loss's growth" becomes "the interest rate minus the loss's yearly growth". Item 6 named only "The common output" and Conventions. These are the report's other two definitions of the same symbol, so I extended it to keep one wording on the page.
  - Seven quantities, step 5 (A-20, T6; A-23, T7): the quoted title is now "Share of billionaires' income tax lost". The BSZ rule follows T6: the movers in a take the same share of the income tax as of the wealth (`r pct(f_movers)`, 5%; BSZ PDF p.24), and named leavers take only their own income tax, small for their wealth (BSZ Table 4). The JR rule: `r pct(cf_f)` (45%), the middle of the 30% to 60% draw, is more than the `r pct(d_conf_jr, 1)` (28.6%) of wealth reported to have left, for the chapter's two reasons (PDF pp.31, 33). "set above the share of wealth that left" is gone. The two values are computed in the closed-form chunk just above, as `R/site.R` computes `d_conf_jr`, with a `stopifnot()` that f0 equals the draw's middle and is above `d_conf_jr`.
  - Seven quantities, step 6 (A-23, E-26, T7): the quoted titles are "Billionaires' yearly California income tax" and "How long the lost income tax is counted". "lost for `H` years" becomes "counted for `H` years" (extension, in E-26's sense).
  - Hoopes table and text (V-18): the header "Ours, one order" becomes "This OPA, one order" and "Our column" becomes "This OPA's column". The header "Our steps" in the same table became "This OPA's steps" (extension).
- `comparison/site/materials.qmd` (A-10): the bullet now opens "**Both readings of the March version's discount factor are right.** The GGSS response says the loss is magnified by a factor 67 (1/1.5%, Resp p.3); BSZ say 33 (1/3%, PDF p.22 fn.29)." The rest of the bullet is kept. Both quotes were checked in the PDFs.
- `comparison/site/slides/slides.Rmd`:
  - Slide `prop40` (A-19): "Among the reasons: "$25 billion in lost revenue", from "a study by Stanford University economists" (the JR analysis's March 2026 version). The September 2026 version puts the net present value at `r usd(rj_print)`." Both quotes were checked in `comparison/original-materials/sos-vig-2026-prop40-arguments.pdf`, p.2. The For side and the footnote are unchanged. The setup comment that cited "$25/39" was rewritten, and `stopifnot(round(abs(rj_march)) == 25)` ties the quoted figure to the contract's March mean (−24.77).
  - Deviation, slide `prop40`: the September figure uses `rj_print` (−$38.9B, the figure the version prints), not the plan's example `rj_main` (−$39.0B, this OPA's exact mean). The sentence attributes the figure to the version, and A-19 proposed −$38.9 billion.
  - l.685-686 and the `diff-horizon` heading (E-26): "(iii) How long is the lost income tax counted?"
  - l.686 and the `smaller` heading (E-27, T8): "(iv) The other inputs together".
  - Slide `hoopes` (V-18): "This OPA's bridge follows his order"; the table header is "This OPA, his order". l.676 ("Next, we analyze") is left as the plan says.
  - Slide `diff-loss-rest` (A-20, T6): the BSZ rule now says the movers in *a* take the same share of the income tax as of the wealth (`r pct(sup$alpha * sup$m)`; BSZ PDF p.24), and named leavers take only their own income tax (BSZ Table 4). The JR rule says "a flat `r pct(rj$f0)` of all billionaires' income tax". "no more than" is gone.
  - Slides `diff-loss-rest` and `common-output` (V-11): "the real rate net of the loss's growth" becomes "the interest rate minus the loss's yearly growth".
  - Slide `term-loss` (A-23): the typed row label is "Share of billionaires&#39; income tax lost".
- `comparison/DISPUTES.md`:
  - Row 3 (A-09): "Zuckerberg "extremely likely" and Brin "very likely" still residents (BSZ p.26)." Checked in the BSZ PDF, p.26.
  - Section "The second JR estimate" (E-22): "With every other input at the JR value, moving it from 3% to 2.73% lowers the estimate by about $6.7B, from about −$32.3B to the authors' exact mean, −$38.98B. On the explorer's path, where it moves before W, a and the minor switch, the step is −$7.48B." Checked: `bridge.csv` sequential −6.730, `dial_path.csv` step 6 −7.478, and `score_common()` at the JR inputs with r = 3% gives −32.25.
  - Rows 2 and 10 (V-11): "the interest rate minus the lost tax's yearly growth (a real rate)".
  - Row 5 title (T7): "**Billionaires' yearly California income tax**".
  - Row 6 and l.99 (T6, BSZ rule, in DISPUTES's citation style "p.24" and "Table 4"): the movers take the same share of the income tax as of the wealth, and named leavers take only their own income tax, which is small for their wealth. "no more than" is gone.
- `comparison/README.md`:
  - E-20: the `document-inputs.csv` line is now "transcribed from the PDFs with their page, or set by this OPA where its row says so (..., the 3% rate this OPA sets at the BSZ end, ...)". The common output now ends "over a horizon H at a rate r (both dials)".
  - l.56 (V-11, needed for the acceptance grep "real discount rate net"): "the real discount rate net of the loss's growth" becomes "the interest rate minus the loss's yearly growth (a real rate)".
- `README.md`:
  - V-21: "adds the income tax from assets sold to pay it and subtracts the income tax lost to leavers over 5 years".
  - E-19: "records the plan, the output fixed before results, and the dated decisions that changed it after results."

## Checks run
- Acceptance greps (Python, whitespace-normalized): every old phrase is absent from the six files. "no more than" is absent everywhere. Every new phrase is present. No em or en dash was added.
- `check_links.py`: empty report, the same as `00-links-before.txt` (no broken links).
- Parse check: knitr::purl plus `parse()` on every chunk and every inline `r` expression of `repro.qmd` (167), `slides.Rmd` (93) and `materials.qmd` (19). All parse.
- The new expressions, evaluated against the committed exports, print 5%, 45%, 28.6%, 2.73% and "5 years". The deck's March check passes (−24.77 rounds to 25), and `rj_print` prints −$38.9B.
- Screenshot check skipped: Playwright is missing (`00-run.md`), and only sources changed.

## Needs a local render
- `comparison/site/repro.qmd`, `comparison/site/materials.qmd`: `cd comparison/site && quarto render repro.qmd && quarto render materials.qmd`, after WP-1 and WP-2's rebuild. The fold's quoted titles (T7) match the tables only once WP-2's `bridge_steps()` titles land.
- `comparison/site/slides/slides.Rmd`: `cd comparison/site/slides && RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'`. Then print-check `prop40`, `diff-horizon`, `diff-loss-rest`, `smaller` and `hoopes`. `prop40` is the main risk: the "Against" text is about twice as long, inside a 57%-wide box laid over the campaign image. If it overflows, drop the September sentence (the plan's fallback). The `stopifnot()` keeps the deck from rendering with the quote out of step with the contract.
- `comparison/DISPUTES.md`, `comparison/README.md`, `README.md`: none.

## Needs a follow-up (files outside the package)
- None required.

## Could not do
- Nothing. The deck fit check is left to the orchestrator's render, as instructed.

## Noticed on the way (not changed)
- `comparison/site/repro.qmd`, Introduction, Open Output bullet: "...into one term, and the other three steps into another." This is E-27's wording in lower case, so the acceptance grep misses it. Suggested: "and the other inputs (W, a and the minor switch) into another."
- `comparison/site/slides/slides.Rmd`, slide `waterfall`: "and the other three into another." Same suggestion.
- `comparison/site/slides/slides.Rmd`, slide `diff-loss-rest`: "while the loss lasts 5 years" and "on a loss that lasts for ever". Both keep E-26's "lasts". Suggested: "while the loss is counted for 5 years" and "on a loss counted for ever".
- `comparison/site/repro.qmd`, "What reproduces": "`test-shapley.R` checks that ours do" (V-18). Suggested: "that this OPA's do".
- `comparison/site/slides/slides.Rmd`, slide `disclosure`: "is our addition" (V-18). Suggested: "is this OPA's addition".
- `comparison/DISPUTES.md` l.3: "Updated 2026-10-16." is now stale. l.25-26 say "our Rauh PDF" and "our copy" (V-18, a record).
- `comparison/DISPUTES.md`: −32.25 is exact, so "about −$32.3B" matches `PLAN.md` decision 11. R's `sprintf("%.1f")` would print −32.2.
