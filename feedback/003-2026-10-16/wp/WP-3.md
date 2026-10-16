# WP-3: BSZ overview, explorer, dial texts and input table, materials page
Owner: opus. Status: done.

## Changed
- `bsz-analysis/site/index.html`: the byline now says the OPA "reproduces that estimate, adds its income tax effects to get the main estimate below, and marks which inputs are data and which are guesses" (V-14, item 1).
- `bsz-analysis/site/index.html`: "What the model says", after "(PDF p.22, fn.29).", S-JR-REASON in its BSZ form, word for word (V-16, item 2). Checked against JR PDF p.32 ("the constitutional cap on intangible property taxation has been permanently removed, §50310 permits a change to any part of the Act by a two-thirds vote").
- `bsz-analysis/site/index.html`: the "What this OPA does not estimate" paragraph is S-SCOPE word for word, with the `../../docs/initiative/README.md` link kept (A-09, E-01, item 3). BSZ PDF p.23 checked ("Our companion website shows how the scoring has evolved on a daily basis").
- `bsz-analysis/site/index.html`: "What reproduces", row "Tables 1 to 4 and A1, ...": the cell now ends "Figures are checked for structure and anchor values. One exception: Appendix Table A1's annualized growth row. This reproduction annualizes over 44 years (1982 to 2026), the workbook and the paper over 43, so three of its cells print lower than the paper (see the report)". No final period, as in the other cells. No result digits typed (A-15, item 4).
- `bsz-analysis/site/explorer/index.html`: the "Leavers" scenario key now reads "assumes four billionaires (Page, Thiel, Hankey, Kalanick) left before 1 January 2026 and escape the tax, which BSZ call an aggressive assumption. Three more leave later, taking their income tax (Table 5 row 3)." BSZ PDF p.26 checked (A-12, item 5).
- `bsz-analysis/site/explorer/index.html`: under "The inputs", a new `<p class="small" id="fixed-inputs">` filled by the page script from `G.facts` (C to two decimals, `pv_years`, `pv_rate` as a percent). Rendered in headless Chrome against the current `grid.js`: "Fixed in every setting: billionaires' yearly California income tax, $3.06 billion (BSZ Table 2), and the yearly loss counted for 5 years (this OPA's reading of BSZ's example) at 3%. The other fixed inputs are in the report's table of every input." The last five words link to `../repro.html#every-input-by-origin` (E-10, item 6). One deviation from the plan's wording: I placed "(this OPA's reading of BSZ's example)" after "5 years" and before "at 3%". In the plan's order the parenthesis followed "at 3%", which would credit the 3% rate to BSZ's example. The rate is this OPA's choice, and BSZ give no rate (BSZ PDF p.27).
- `bsz-analysis/R/site_exports.R`: the α tip at the authors' level is now "BSZ: 10%, covering every behavioural response, moves included. Their expert report argues enforcement keeps it small (GGSS p.4)." That is 20 words with " Kind: guesswork." added, under the 31-word limit (A-05, item 7).
- `bsz-analysis/R/site_exports.R`: the α description now ends "escapes the tax (a on the comparison explorer)." (V-20, item 7).
- `bsz-analysis/R/site_exports.R`: `build_site_inputs()` has two new rows after `date`. The first is `H`, "Years the yearly income tax loss is counted (main estimate only)", value `sprintf("%d years", as.integer(site_pv_years))`, scenario. The second is `r`, "Discount rate for that loss (main estimate only)", value `sprintf("%g%%", 100 * site_pv_rate)`, scenario. Both basis texts are as in the plan. The values come from the constants behind `site_pv_factor()` and are not typed. I evaluated it with a mock input: 20 rows, values "5 years" and "3%", origins data 4, research 5, guesswork 5, derived 2, scenario 3, convention 1 (E-14, item 8).
- `bsz-analysis/R/site_exports.R`: the function header comment now names the two inputs the main estimate adds. The main-estimate comment now says "the 5 years of BSZ's example" instead of "BSZ's horizon of about 5 years" (item 8, carried over from run 002).
- `bsz-analysis/site/materials.qmd`: the bundle sentence is replaced with the plan's text: the bundle is confidential, the SQL in `sql/` rebuilds the workbook's data sheets from it and checks them against the public workbook, and none of its contents is committed or shown (A-19, item 9).
- `bsz-analysis/site/materials.qmd`: "What the checks found" has a new bullet, "An annualizing gap in Appendix Table A1", with the plan's text (A-15, item 10).
- `bsz-analysis/site/materials.qmd`: `{targets}` is glossed at first use as "(an R package that runs the pipeline's steps in order and records which outputs are current)" (E-21, item 11).
- `bsz-analysis/tests/testthat/test-site.R`: not changed (item 12). No pin depends on the α tip, the α description or the number of input rows. The landing-page prose test still finds all its strings, because none of the pinned lines moved.

Checks run. Every old string is gone. S-JR-REASON, S-SCOPE and the V-14 sentence are present word for word in the overview's text. The five files have no em or en dashes. `check_links.py` prints nothing (no broken link). The explorer renders in headless Chrome without a script error, and the headline still reads $106.8B. I did not run `screenshot.cjs` because Playwright is not installed (00-run.md); I used Chrome `--dump-dom` instead.

## Needs a local render
- `bsz-analysis/site/explorer/grid.js` and `bsz-analysis/site/data/inputs.csv`: `cd bsz-analysis && Rscript -e 'targets::tar_make()'`. This writes the new α tip and description into `grid.js` and the H and r rows into `inputs.csv`.
- `bsz-analysis/site/materials.html`: `cd bsz-analysis && quarto render site/materials.qmd`. The inputs.csv row count in the data-files table becomes 20.
- `bsz-analysis/site/repro.html`: re-render after `tar_make()`. "Every input, by origin" then shows 20 inputs, 3 of them scenario, and the computed counts update themselves. WP-4 owns the report's wording about the new rows.
- `bsz-analysis/site/index.html` and `bsz-analysis/site/explorer/index.html` are hand-written. They need no render.
- Then `cd bsz-analysis && Rscript tests/testthat.R`. This passes only after the Python follow-up below.

## Needs a follow-up (files outside the package)
- `bsz-analysis/py/site_exports.py` (the Python twin). `test-py-parity.R` compares the text of `site/data/inputs.csv` and the `grid.js` metadata (dials, tips, descriptions) with `export/py/`. It also requires `grid.js` to be byte-identical. It will fail after the R rebuild unless the twin makes the same changes:
  1. Line 44: the `desc` becomes `"The share of the wealth on the Forbes list that escapes the tax (a on the comparison explorer)."`
  2. Lines 47-49: the avoidance `why` becomes `"BSZ: 10%, covering every behavioural response, moves included. Their expert report argues enforcement keeps it small (GGSS p.4)."`
  3. In `build_site_inputs()`, after the `("date", ...)` tuple, add two tuples:
     `("H", "Years the yearly income tax loss is counted (main estimate only)", f"{int(SITE_PV_YEARS)} years", "scenario", "This OPA's reading of BSZ's example ('If they last say only 5 years', PDF p.27); Table 5 gives no horizon."),`
     `("r", "Discount rate for that loss (main estimate only)", "%g%%" % (100 * SITE_PV_RATE), "scenario", "This OPA's choice, the middle of the JR analysis's 1.5% to 4.5% range; BSZ give no rate."),`
     (Python prints "5 years" and "3%", the same as R.)
  4. Then rerun `python py/run_export.py` from `bsz-analysis/` to rebuild `export/py/`. This runs the script, it does not edit it. Note that the working tree has uncommitted changes to `run_export.py` that this loop did not make.
- `AUDIT.md`: the BSZ step 7 counts ("18 inputs") become 20, with scenario 3 (WP-8 owns this, per E-14).
- `bsz-analysis/site/repro.qmd`: the "scenario" definition ("a choice about which policy is being estimated") does not fit H and r, which are choices about how to count the loss (WP-4 owns this, per E-14).

## Could not do
- Nothing.

## Noticed on the way (not changed)
- On the explorer, the new fixed-inputs line ends with a link to the same report section as the paragraph just above it ("Every input, by origin lists them all"). The two links are redundant. The author may want to merge the two paragraphs.
- The α tip no longer cites BSZ PDF p.23, where the "all dimensions of behavioral responses" wording comes from. A-05 had proposed keeping "(BSZ PDF p.23)" after "moves included", and the plan's text drops it.
- The overview's scenario table (`What the model says`) still carries typed values ($127.9B, $4.5B and so on). `test-site.R` pins them through `b1()`/`b2()`, so they are safe. This is just a note that they are typed and not read from `grid.js` like the headline.

## Addendum: the Python twin (added to WP-3 by the coordinator)
- `bsz-analysis/py/site_exports.py`: made the same three changes as in `R/site_exports.R`. The α `desc` now ends "(a on the comparison explorer).". The α tip at the authors' level is "BSZ: 10%, covering every behavioural response, moves included. Their expert report argues enforcement keeps it small (GGSS p.4).". `build_site_inputs()` has the `H` and `r` rows after `date`, with values from `SITE_PV_YEARS` and `SITE_PV_RATE` ("5 years", "3%") and the same labels and basis texts as R. This supersedes the "Needs a follow-up" item for this file above.
- I ran `python3 py/run_export.py` (exit 0, "wrote 50 files"). Only two generated files changed: `bsz-analysis/export/py/site/grid.js` and `bsz-analysis/export/py/site/inputs.csv`. The orchestrator should commit them with the rebuild. `run_export.py` was not edited. Its uncommitted changes, which differ from HEAD only in comments, are the author's.
- Parity checked before the rebuild. `tar_make` has not run (`site/data/inputs.csv` still has 18 rows), and I did not run it. Instead, I sourced `R/` as `tests/testthat.R` does, built R's `grid.js` text and `inputs.csv` from the workbook into the scratchpad, and compared them with `export/py/site/`. `grid.js` is byte-identical. `inputs.csv` matches cell for cell, 20 rows; the bytes differ only because R quotes every field, the same as for the committed pair. `test-py-parity.R` should pass once the orchestrator runs `tar_make()`. I did not run the test suite because the R side is not rebuilt yet.
