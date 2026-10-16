# WP-1: Comparison generator, model labels and the two templates
Owner: opus. Status: done (all 20 changes; several tip texts reworded from the plan's, see "Departures from the plan's wording").

## Changed
- `comparison/site/index.template.html`:
  - First paragraph: "leaves the state about {{nber_npv_round}} poorer (the chapter prints a mean of {{nber_printed}})" (A-01, V-01).
  - JR card definition: "... in today's dollars. It is the exact average of the authors' model. Jaros and Rauh (September 2026) print {{nber_printed}} from one run." (A-01, E-04, V-01)
  - "Today's dollars" line: "what income tax lost in future years is worth now. Both analyses count the wealth tax at face value, although it is paid over five years." (E-01)
  - Figure caption: "the test suite checks that each step is the change from moving one dial, in R and in the browser (the steps add up to the gap by construction)." (E-23)
  - Footnote 1 opens "The main estimate on each analysis's overview page." (V-05)
- `comparison/site/explorer.template.html`:
  - JR headline definition: "... in today's dollars. This is the exact average of the authors' model, which they print as {{nber_printed}} from one run." (A-01, V-01)
  - JR panel source line: "The JR analysis's main estimate<sup>1</sup>, the exact average of the authors' model (Jaros and Rauh, NBER, September 2026)". (A-01, E-04)
  - Footnote 1 opens "The main estimate on each analysis's overview page, each defined its own way." (V-05)
  - Conventions paragraph replaced with the plan's text ("billions of dollars at the assessment date", flat yearly loss, the JR rate is r − g, chapter eqs. 14 and 18, mismatch 3 link kept, "The BSZ end's {{r_bsz}} is the middle of the same draw"). (E-11, V-16, A-10, A-23)
- `comparison/R/site.R`:
  - Tokens: `nber_npv_round` (whole billions) and `nber_printed` (the chapter's −$38.9B from the endpoints export); the now unused `nber_npv_abs` removed. (A-01)
  - `step_texts()` departures: BSZ "no named leaver" / "None named". (A-03)
  - `slider_tips`: D middle stop "BSZ Table 5 row 3, where Page, Thiel, Hankey and Kalanick left in time" (A-03, jargon ledger); f "Both ends include the movers in a, and the BSZ end also the leavers in D" (V-12); r: pinned first sentence plus "Within the JR draw itself, the JR explorer's Rate 1.5% and Rate 4.5% settings show how much the rate matters." (E-12; both setting names exist in `rjkdc-analysis/R/site.R` `site_named_labels()`).
  - `end_tips`: W BSZ "250 California billionaires, of whom the US citizens hold $2,157B. The $150B of non-US citizens is a separate dial." and W JR with `n_rauh` and `tok$nber_growth` instead of the typed 212 and 7% (E-14); D BSZ (A-03); q BSZ "collected in full; its expert report argues the Act was designed to stay clear of constitutional issues" (A-28); f BSZ and JR rules (E-07); H JR "for ever, since leavers are assumed not to return once the Act permanently lifts the intangible property tax cap" (A-04); r JR "for a loss that lasts for ever, worth the same as the JR draw from 1.5% to 4.5%. Each run draws r − g, the rate net of the loss's growth ($1 a year for ever is worth $36.6)" (A-10, E-13, V-13; pinned ending kept); non-citizens JR "left out. The chapter counts 28 international billionaires as residents but too uncertain to collect from (treaty preemption, the Act's apportionment clause)" (A-05).
  - `EXPLORER_BOXES$revenue$more`: "+ The minor inputs add the non-citizens to W and take the real-estate deduction out of it." (E-14)
  - `eq_terms()`: the last term names "the minor switch" (label "The other three steps together (W, a, the minor switch)"), and the note lists the loss letters in the label's order "(H, f, C and r)" and the rest "(W, a and the minor switch)". (V-04)
  - New `order_note()` appended to both equation notes: "Each amount is what its group changes when the dials move in this order. It is not a total, and its size depends on the order. The report's order-free check gives each input's size in any order. For scale, the lost income tax itself is worth $75.0B today in the JR analysis and $0.7B in the BSZ analysis." Both amounts are `score_common()[["PV"]]` at the two ends; the link goes to the report's `#the-bridge`. (A-13, E-08, E-09, V-03)
  - LAO versions row: "no point estimate. It puts the wealth tax at tens of billions of dollars over several years, the ongoing income tax loss at under $1 billion a year (from `lao_loss_upper`), and administration costs at tens of millions a year (pp.2-3)". Checked against the LAO PDF pp.2-3. (E-02)
  - `hoopes_differences()` "Order and labels": "data, research, guesswork, scenario or derived ("A vs B" reads the BSZ value's kind against the JR value's)". (E-17)
  - `step_row()`: the hidden screen-reader title is `DIAL_NAMES[[id]]` ("avoidance share", not "No avoidance"). No test pinned the old titles. (V-15)
- `comparison/R/model.R`: kinds, non-citizens "data vs guesswork", share lost "guesswork" (A-05, E-07); the −38.980 comment says the printed −38.9 differs by the seeded run's sampling error (E-16).
- `comparison/py/bridge.py`: the same two kinds in `STEPS` (A-05, E-07).
- `comparison/R/build.R`: source cells: non-citizens JR "excluded as too uncertain to collect: ... (treaty preemption and the Act's apportionment clause, §50306(b); ...; NBER chapter Sec. 3.5, PDF pp.17-18)" (A-05); horizon JR "perpetuity: departed billionaires are assumed not to return (chapter Sec. 5.2, eqs. 13-14, PDF pp.30-32)" (A-04, A-06); rate JR "(r − g) ~ U[1.5%, 4.5%], the real rate net of the loss's growth (...; chapter eq. 18, PDF p.35, anchored at p.32): 1 / E[1/(r − g)]" (A-10); litigation BSZ "+ GGSS argue the Act was designed to stay clear of constitutional issues (GGSS p.11, section Constitutionality Issues, pp.11-13)" (A-28); share-lost BSZ "at the benchmark, the movers among the avoiders, who take a proportional share of the income tax with them (BSZ PDF p.24); with departures, ..." (E-07); Walczak `side` "walczak (third party)" (A-14; no reader of the old label outside `loss.csv`). `§` and `−` are written as R escapes so the file stays ASCII, as it was.
- `comparison/tests/testthat/test-site.R`: lines 138 and 164-165 follow V-04 ("W, a, the minor switch"; "(H, f, C and r)"; "(W, a and the minor switch)").

## Departures from the plan's wording (each for a stated reason)
- Tips carry no source citation. The author's tip rules of 2026-10-15 (memory `site-conventions.md`: "no sources ... in tips", "about 25 words"). The root's quantities table still prints a source on each line, cut from the source cells I changed in `build.R`: D BSZ "(BSZ PDF p.23)", q BSZ "(GGSS p.11)", f BSZ "(BSZ PDF p.24)", H JR "(chapter Sec. 5.2)", non-citizens JR "(NBER chapter Sec. 3.5)". That is why the share-lost BSZ source now leads with the p.24 part, and the GGSS cite is written "GGSS p.11, ..., pp.11-13": `QUANTITY_SOURCE_PATTERN` takes the first match and reads no GGSS page range.
- The plan's texts for D BSZ, H JR, f BSZ and W BSZ ran over 25 words in every `q_cell()` fallback, which fails `test-site.R` line 577. I shortened them until the shortest fallback fits (all quantities-table lines are now 14 to 25 words, the reason kept in each).
- D BSZ: "since press reports do not show a timely change of residence" (fn.30: the press reports "do not include sufficient information to establish that they successfully changed residence before the January 1st, 2026 cut-off"). The second sentence reads "Half its avoidance allowance (a) is people who left in time", with no 10% or 5% typed into the tip.
- f BSZ: "assumed to pay a proportional share", not "in proportion to their wealth". BSZ PDF p.24 says the 5% who relocate take "a corresponding 5% of the total California individual income tax paid by billionaires", which is a proportional share, not stated per dollar of wealth. "Leavers in D add theirs, from tax filings." f JR: the range is a comma clause, not parentheses, so the table line keeps "the middle of a 30% to 60% guess"; the second sentence is "The movers from a are this OPA's addition."
- r JR: reordered so the table line keeps the range and the perpetuity condition: "2.73%. For a loss that lasts for ever, worth the same as the JR draw from 1.5% to 4.5% (NPV_dist_v8.R:22). Kind: derived."
- H JR: "the intangible property tax cap", one word under the limit. The chapter PDF p.32 reads "the constitutional cap on intangible property taxation has been permanently removed".
- Root equation note: the old "Each term is what its group changes." is replaced by `order_note()`'s first sentence, not kept beside it.
- Semicolons split into sentences in the root JR definition and the LAO cell. The q BSZ tip keeps the plan's semicolon, so its reason stays in the first sentence the table falls back to.

## Verification
- On a scratch copy of the repository (`OPA_PROP40_ROOT` pointed at it; the shared tree was not rebuilt), `Rscript comparison/run.R` then `Rscript comparison/tests/testthat.R`: 1014 expectations, 0 failed, 0 skipped.
- Every export CSV compared cell by cell with the committed one: no numeric cell changed. Text changed in `bridge.csv` (kinds), `inputs.csv` (5 source cells) and `loss.csv` (Walczak side).
- Plan acceptance: both parse checks pass. None of the eight old strings is left in the seven files. The new strings are present. The `shapley` count in `site.R` is unchanged (3) and 0 in the templates. No em or en dash added. `check_links.py` reports nothing, on the templates and on the regenerated scratch pages.
- Page references re-checked against text extracted from the PDFs: BSZ p.23 fn.30 and p.24; JR chapter Sec. 3.5 pp.17-18, Sec. 5.2 from p.30, eqs. 13-14 p.31, the reason for not returning on p.32, eq. 18 p.35; GGSS p.11; LAO pp.2-3.
- `screenshot.cjs` was not run: Playwright is missing (00-run.md).

## Needs a local render
- `Rscript comparison/run.R`, then `python3 comparison/py/bridge.py`, then `Rscript comparison/tests/testthat.R`. These regenerate `index.html`, `comparison/site/explorer/index.html`, `assets/comparison-data.js` and `comparison/export/{r,py}/`.
- `cd comparison/site && quarto render repro.qmd`: the report reads `step_texts()` ("no named leaver"), `bridge_steps()` kinds, the new source cells, `hoopes_differences()` and `loss.csv`.
- The comparison deck (`comparison/site/slides/slides.Rmd`, WP-2's file). Its pseudo-eq slide prints `eq_terms()` labels and note, which now read "(W, a, the minor switch)" and "(H, f, C and r)". Its smaller-steps slide prints `bridge_steps()` kinds.

## Needs a follow-up (files outside the package)
- Run the `explorer-tip-audit` skill after the render (Playwright was missing here). These end tips are now longer than the 25-word rule: r JR (42 words, 195 characters), D BSZ (32, 180), f BSZ (32, 175), non-citizens JR (25, 179), W BSZ (29, 164) and f JR (29, 159). The f slider tip is 29 words and the r slider tip 34. The longest tip before this package was 147 characters.
- `comparison/site/repro.qmd` line 159 (WP-7, optional): "It adds up the four steps of the loss box (f, C, H and r) into one term". The term's label and the note now read (H, f, C, r) (V-04: one order for the loss letters). Line 472 lists the path order (f, C, H and r) and is correct as it stands.

## Could not do
- Nothing in the package. The tip-line check needs a browser (above).

## Noticed on the way (not changed)
- `step_texts()` in `comparison/R/site.R` still gives the BSZ share-lost value as "what leavers paid" in the report's dial-path and disputed-inputs tables. E-07 lists this; the package does not change it.
- Code comments in `comparison/R/model.R` (lines 36-39, 281) and `comparison/R/build.R` (lines 12-13) still describe the JR draw as `r ~ U[r_min, r_max]`, not r − g (A-10 family; comments only).
- `step_texts()` still types "grown 7%" for the JR Forbes list (`out$rjkdc`). It sits outside `render_site()`, so `tok$nber_growth` is not in reach there.
