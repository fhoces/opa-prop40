# WP-7: JR report, deck, checks page, materials page and source manifest
Owner: opus. Status: done.

## Changed
- `rjkdc-analysis/site/repro.qmd`: "Sources and how they are read": T5 replaces "The share below zero sums up ... settings show." (A-13).
- `rjkdc-analysis/site/repro.qmd`: Step 4, the width of the band "is the authors' allowance for illiquidity, mean reversion in entrepreneurial returns and a baseline outflow of high earners of about 1% a year (PDF p.32), not an estimate, and the width is what moves the result" (A-15).
- `rjkdc-analysis/site/repro.qmd`: Step 4 and the notation table, r − g is "the interest rate minus the lost tax's yearly growth (a real rate)" (V-11).
- `rjkdc-analysis/site/repro.qmd`: Section 4 opening, "At 5% of the base, it is $X before anyone leaves and $Y at the valuation date." The 5% is read inline (`pct(100*inp("tax_rate"),0)`, as Section 4.1 does), not typed. The existing inline R is unchanged (E-11).
- `rjkdc-analysis/site/repro.qmd`: Section 4.3, "Table 7 lists Page, Brin, ... as having moved out between the initiative's filing and the 1 January 2026 residency date (PDF p.21)." (A-14).
- `rjkdc-analysis/site/repro.qmd`: a new collapsed callout, "When the main estimate was chosen", with the plan's text. It sits right after the "Sources and how they are read" callout, which is where the page first names the main estimate. This follows the BSZ report's "Why the total, and when this changed" fold. Its facts were checked against `PLAN.md`: the pre-specified output was fixed 2026-09-23 with both versions side by side and the March mean as anchor, and decisions 7 and 9 are dated 2026-10-14 (E-19).
- `rjkdc-analysis/site/repro.qmd`: "we build it" became "this report builds it", and "Our R port" became "This OPA's R port" three times (V-18).
- `rjkdc-analysis/site/repro.qmd`: in the notation table's typed `g` row, the explorer's further growth is now named "$\Delta g$" (E-09).
- `rjkdc-analysis/site/slides/slides.Rmd`: headline slide, "(the share of draws below zero, which moves with the ranges drawn, so not a probability; PDF p.35, ...)" (A-13).
- `rjkdc-analysis/site/slides/slides.Rmd`: "What is being estimated", r − g is "the interest rate minus the lost tax's yearly growth (a real rate)" (V-11).
- `rjkdc-analysis/site/slides/slides.Rmd`: reproduction-notes slide, "This OPA reproduces the code as shipped and records each note rather than fixing it." The verb form changed to agree with the new subject (V-18).
- `rjkdc-analysis/site/slides/slides.Rmd`: Deck Map (slide 3, counting xaringan's title slide), the `{targets}` gloss was added as its own sentence. It uses the report's wording: "`{targets}` is an R package that runs the pipeline's steps in order and records which outputs are current." (jargon).
- `rjkdc-analysis/site/checks.qmd`: the "We have sent ... We will update" sentence was replaced with the WP-5 change 9 sentence (V-18).
- `rjkdc-analysis/site/materials.qmd`: the intro has the same `{targets}` sentence, placed right after "an R `{targets}` pipeline with a Python twin." (jargon). The placement differs from the plan's literal one (inside "an R {targets} (...) pipeline"), which would have split the noun phrase. The words are the same sentence the report and the deck use.
- `rjkdc-analysis/DATA-SOURCES.csv`: the `status` cell of row 5 is now "available; public repository (MIT), the folder name is kept from the first download". No other cell changed (checked cell by cell). R reads the file with 10 columns and 5 rows, as before (E-18).

Acceptance: these strings are absent from the five files: "It is not a probability", "The base is \$", "is the authors' judgement, and the width", "Our R port", "we build it", "We reproduce", "We have sent", "We will update", "real discount rate net of the growth", "summary of the draws' ranges". "moved out between the initiative's filing" occurs only in the Table 7 sentence. There are no em or en dashes in the edited prose. `check_links.py` prints nothing, the same as the run's baseline. The deck fit was judged on the existing render (Chrome print, slides 3, 5, 6 and 19). Each slide has several lines free under the text that grew, so I expect the slides to fit. The fit must be confirmed on the new render.

## Needs a local render
- `rjkdc-analysis/site/repro.html`: `cd rjkdc-analysis && RAUH_REPO_DIR=<clone> quarto render site/repro.qmd` (after WP-6's `tar_make()`).
- `rjkdc-analysis/site/materials.html`: `cd rjkdc-analysis && quarto render site/materials.qmd`. It also picks up the CSV change, but see the first follow-up item below.
- `rjkdc-analysis/site/checks.html`: `cd rjkdc-analysis && quarto render site/checks.qmd` (it reads `grid.js`, so run it after WP-6). `test-site.R` then checks the rendered tables.
- `rjkdc-analysis/site/slides/slides.html`: `cd rjkdc-analysis/site/slides && RAUH_REPO_DIR=<clone> RSTUDIO_PANDOC=/Applications/Positron.app/Contents/Resources/app/quarto/bin/tools/aarch64 Rscript -e 'rmarkdown::render("slides.Rmd", quiet = TRUE)'`. Then print it with headless Chrome and check slides 3 (Deck Map), 5 (What is being estimated), 6 (The headline) and the reproduction-notes slide.

## Needs a follow-up (files outside the package)
- None required. E-09's symbol change is WP-6's (`R/site.R`, `sym = "Δg"`).

## Could not do
- `screenshot.cjs --text`: skipped. Playwright is not installed (run file), and the changed pages need a render that waits for WP-6.
- E-09 in the report's input table and the deck's dial table: no change was possible. Neither table types the symbol. The report's "input" column prints each dial's key from `site_dials()` (`g`, which WP-6 keeps, next to `rate`, `c`, `wt_lo`), and the deck's table prints labels only. Only the notation table typed it, and that row now says Δg.

## Noticed on the way (not changed)
- E-18 is not visible on the page. The materials page's Sources table (`materials.qmd` l.186) shows the columns `file` to `feeds` but not `status`, so the new note shows only in the CSV on GitHub. To make it visible, add `status` to that column list, or rename the folder as E-18 proposes.
- Other places still use economists' words for r − g: the report's Step 4 heading ("the discount rate net of growth") and Section 5.2's first bullet ("draw the 1.5% to 4.5% rate as r − g, the discount rate net of growth"). In the deck, the perpetuity slide's x-axis label says "discount rate net of growth, r − g, %". The explorer's dial label "Discount rate net of growth" is in WP-6's `site.R`.
- `materials.qmd` l.66: "Python twin" has no gloss. WP-6 glosses it on the JR overview: "(the same computation written again in Python and checked against the R result)".
- Deck, "What is being estimated": "(payable over five years)". WP-5 rewrites the matching BSZ wording as "payable at once or in five yearly installments", and the JR slide may want the same.
- Deck setup chunk, l.28: the code comment says "values we compare against". It is not shown on any slide.
