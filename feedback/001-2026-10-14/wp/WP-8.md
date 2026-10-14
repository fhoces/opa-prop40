# WP-8: The comparison report, materials page and the disputes record
Owner: opus. Status: done.

## Changed
- `comparison/site/repro.qmd`, Introduction: the first sentence is now K3 (V-03). The BSZ estimate is given as printed: "about \$100 billion of wealth tax (`$104B` in its Table 5 row 1, reproduced here as **`$103.8B`**), and **`$106.8B`** once the income tax the tax changes is added in" (A-01). The RJKDC citation follows K1: "Jaros and Rauh, NBER c15504, September 2026, revising the March 2026 version by Rauh, Jaros, Kearney, Doran and Cosso" (A-10). The RJKDC result is now in plain words: the tax would "collect about `$30B` by its own account but leave the state **`$38.9B`** poorer in today's dollars (a net present value of `−$38.9B`), because billionaires who leave stop paying California income tax for ever". After it come the KG "Today's dollars (present value)" line and the three inputs that separate the analyses most (V-01, V-10). An NBER gloss was added at first use (V-10). Every number is an R call. `$30B` reads `nber_headline_revenue` from `document-inputs.csv` through `pick(k$docs, ...)`. `$104B` uses `usd(..., 0)` rather than the plan's `money(...)`, because the page escapes every dollar sign in running text (setup comment).
- `comparison/site/repro.qmd`, "The two main estimates" paragraph: "the exact expectation of the Monte Carlo whose seeded run the authors print" becomes "Jaros and Rauh print `−$38.9B` from one seeded run of their Monte Carlo (a run of the random draws started from a fixed seed number, so it gives the same draws every time); the RJKDC end, `−$38.98B`, is its exact expectation, the average computed by formula" (E-18). I wrote "their Monte Carlo" and "Jaros and Rauh" instead of the plan's "the same Monte Carlo" and "The authors", because in this paragraph neither phrase points back to anything (the sentence before is about the BSZ end).
- `comparison/site/repro.qmd`, "How to read this report": a Python twin gloss at its first use in prose (V-10).
- `comparison/site/repro.qmd`, "The common output": a new **Conventions** paragraph (E-02). Two departures from the plan:
  - Placement: it comes after the horizon paragraph, not directly after the (a)/(b) list. The horizon paragraph finishes the definition of (b) and gives the rate range that "The discount-rate range is the one the RJKDC code draws" refers back to.
  - Wording: the 7% is read from `nber_growth_rate` in the RJKDC contract. The (r − g) sentence says the text "uses both (r − g) and the plain rate r". `rjkdc-analysis/MISMATCHES.md` item 3 records that eq. 18 draws (r − g) and the next sentence divides by plain r, so the plan's "its text r" was only half of it.
- `comparison/site/repro.qmd`, "The two ends, estimated on it": "where the inputs are published" becomes "the one whose inputs the common function can take one by one (the September version's code and person-level file are in the same public repository)" (A-02). The function is now described in seven numbered lines before the code fold (E-05). Each line has `model.R`'s formula as its comment writes it, the unit of each argument and the title of the bridge step that switches it. The list says which arguments both ends share (`tau`, `m`, `g`, `t_cg`, the rate range). "The table checks each end against the number its authors print." moved below the list, so it still introduces the table.
- `comparison/site/repro.qmd`, the no-output chunk after "The two main estimates": one `stopifnot` checks that the three largest Shapley steps on (b) are `one_time_as_permanent`, `confirmed_departures` and `horizon`. Those are the three the introduction names in words. The plan asked to read their titles from R where possible, but `top3b` is computed after the introduction, so the plain-words sentence is typed and this check guards it. It holds on the current `bridge.csv` (−33.6, −33.2, −27.1).
- `comparison/site/repro.qmd`, "The bridge, step by step": "where the inputs are published" becomes "the one whose inputs the common function takes one by one" (A-02).
- `comparison/site/repro.qmd`, "The disputed inputs": a GGSS gloss (KG wording), in the sentence just before the table. That table's source column is the first place GGSS appears on the rendered page (V-10).
- `comparison/site/repro.qmd`, "The Hoopes comparison": an SSRN gloss at first use (V-10). Under the table, a note says that the "Galle estimate" bar is clipped by the chart's frame at `$100B` (read from `hz`), and that its value is taken from the note's text (p.3). The reading uncertainty printed with it is the digitizer's default for every bar, not a measurement. `tools/digitize_hoopes_fig2.py` confirms both (E-13).
- `comparison/site/repro.qmd`, "What reproduces": "The bridge adds up" is replaced by "The code does what the method says. ... This is a check of the code, not a finding about the analyses." (E-10)
- `comparison/site/materials.qmd`, glosses (V-10, E-31):
  - Python twin, at its first prose use (the rebuild paragraph, on `PYTHON`).
  - NBER and GGSS, in the `test-endpoints.R` bullet.
  - Shapley value, in the `test-shapley.R` bullet.
  - anchor: the `anchors.csv` description now ends with the anchor gloss, in the plan's wording.
- `comparison/site/materials.qmd`, under the data files table (E-27): `loss.csv`'s `net_at_rauh_revenue_perpetuity` nets each loss against the March 2026 expected revenue (`$51.3B`). The last column of the overview's loss table (linked as `../../index.html#neutral-material`) nets against the September 2026 expected revenue (`$36.0B`), which `R/site.R` computes from `ends.csv`. Both numbers are R calls on `ends.csv`.
- `comparison/site/materials.qmd`, Sources (E-22): the GGSS expert report (20 July 2026) and the GGSS response to Rauh (17 March 2026) are listed in `bsz-analysis/DATA-SOURCES.csv` (linked), which records no URL for them. I checked rows 6 and 10 of that file.
- `comparison/site/materials.qmd`, setup chunk: `usd()` moved there from the "What the checks found" chunk so the new note can use it. The definition and the output are unchanged.
- `comparison/DISPUTES.md`, "Vintage caveat": the sentence "Rauh has not updated since March 17 ..." is replaced with the plan's text (A-24). The table rows are untouched.
- `comparison/DISPUTES.md`, "Kind labels": a fifth bullet, **compound kinds**, gives the "A vs B", "A + B" and "guesswork on data" readings (E-19). It spells "judgment", as the file already does.
- `comparison/DISPUTES.md`: at "the Rauh anchor", the anchor gloss in the bridge sense, "the published number an end of the bridge is checked against" (E-31).

Acceptance checks:
- `grep "inputs are published\|has not updated since"` on `repro.qmd` and `DISPUTES.md` finds nothing.
- `grep "The bridge adds up"` finds nothing.
- "Conventions" occurs exactly once in `repro.qmd`.
- "A vs B" is in `DISPUTES.md`.
- `repro.qmd` has no `103.8` or `36.0` typed as text.
- `check_links.py` reports no broken link in the three files.
- `git diff --stat` on the three files shows only them changed; `repro.html` and `materials.html` are not edited.
- `screenshot.cjs` was not run: no page a browser renders was changed (the sources are `.qmd` and `.md`).

## Needs a local render
- `comparison/site/repro.qmd`: `cd comparison/site && quarto render repro.qmd`. After rendering, check four things:
  - The introduction prints `$104B`, `$103.8B`, `$106.8B`, `$30B`, `$38.9B` and `−$38.9B`.
  - The new `stopifnot` passes.
  - The seven function lines render as a numbered list.
  - The Hoopes note prints `$100B`.
- `comparison/site/materials.qmd`: `cd comparison/site && quarto render materials.qmd`. After rendering, check that the `loss.csv` note prints `$51.3B` and `$36.0B`.
- `comparison/DISPUTES.md`: none.

## Needs a follow-up (files outside the package)
- None required by this package. The sister texts of A-02 (`comparison/R/site.R`, the two comparison templates and their generated pages, `comparison/README.md`) already carry the new wording from the other packages.

## Could not do
- Rendering: the container has no R or Quarto, so `repro.html` and `materials.html` show the old text until the author renders.

## Noticed on the way (not changed)
- `comparison/site/repro.qmd`, "Every input, by origin", says "Each bridge step carries one of these kinds". Five steps carry compound kinds (E-19 on this page). Suggest adding after it: "A compound kind such as "data vs guesswork" reads the BSZ value's kind against the RJKDC value's; "A + B" means one value rests on both; "guesswork on data" means a judgement applied to observed facts."
- `comparison/site/repro.qmd`: "Monte Carlo", "perpetuity" and "mean net present value" are first used in "The two main estimates" without a gloss. Item 7 did not list them; the KG wordings exist.
- `comparison/site/materials.qmd`, "What the checks found": "The first is the RJKDC text anchor" uses anchor in the calibration sense, right after the page defines it in the bridge sense. Suggest "The first is the rate the RJKDC text anchors its range on".
- `comparison/site/materials.qmd`, introduction: "the reconciliation of the BSZ analysis and the RJKDC analysis" (K6 wording, though not a link).
- `comparison/DISPUTES.md`:
  - "reconciliation page" appears at lines 4 and 81 (K6).
  - The "Vintage caveat" heading is not glossed (KG "vintage"; E-31 did not flag it here).
  - In "The second RJKDC estimate", "On the bridge it enters as extra steps after the SSRN anchor" now disagrees with the caveat's "enters the bridge as its last step": the bridge has one "September 2026 revision" step. Suggest "On the bridge it enters as one step, the September 2026 revision, after the SSRN anchor."
- `rjkdc-analysis/MISMATCHES.md` lines 5 to 6 still say "Jaros and Rauh, with Kearney, Doran and Cosso (NBER chapter c15504, ...)". That is A-10, WP-6's file.
