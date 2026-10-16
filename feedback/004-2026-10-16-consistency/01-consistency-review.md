# Consistency review, run 004

Commit: 80ddb60 (main, 2026-10-16). Scope: numbers and language across the three objects and within each.

Pages read (built HTML through `page_text.py`; the explorers and the three overviews rendered in headless Chrome with their script run, tips included): the root overview `index.html`, the BSZ and JR overviews, the three explorers, the three reports (`repro.html`, with the `.qmd` where a number's source mattered), the three materials pages, the two checks pages, the three decks (`slides.Rmd`), the four READMEs, `AUDIT.md`, `comparison/DISPUTES.md`, `rjkdc-analysis/MISMATCHES.md`, `feedback/DECISIONS.md` and run 003's `05-final-review.md` and `06-author-answers.md`. Also read: the three `test-site.R` files and `test-ai-badges.R` (to tell a typed number that is pinned from one that is not), the three export contracts' `inputs.csv`, `comparison/site/index.template.html` and `explorer.template.html` (to tell a token from a typed value), and `check_links.py` (0 broken links; every anchor a page or deck names exists).

Settled items in `DECISIONS.md` are not raised again (the two-decimal −$38.98B on the root, the origin label of the discount-rate range, the JR overview leading with the printed −$38.9B while the comparison uses the exact average, the "Rate 1.5%" preset names, CONTENT-MAP's "eight disputed inputs").

## Numbers

### C-01. The JR report's input-count table drops the "guesswork on data" row, so its counts add to 25 under a caption that says 26 [blocking]

- `rjkdc-analysis/site/repro.html`, section "Every input, by origin", the second table. Caption: "Rows of the table above (26), by origin. The last 7 rows are the explorer's dials." Rows: "data 10, research 3, guesswork 11, scenario 0, derived 1". Those add to 25.
- Source: `rjkdc-analysis/site/repro.qmd` lines 614-620, chunk `origins-count`: `table(factor(odf$origin, levels = c("data", "research", "guesswork", "scenario", "derived")))`. The row `nber_growth_rate`, relabelled "guesswork on data" on 2026-10-16 (author answer 13), falls outside the levels and is dropped from the count.
- Fix: add `"guesswork on data"` to the levels in that chunk (or build the levels from `unique(odf$origin)`), so the table prints "guesswork on data 1" and adds to 26. Re-render the report. The first table above it is right; only the count is wrong.

### C-02. `AUDIT.md` counts the JR contract's inputs as "data 10" and has no "guesswork on data" row [blocking]

- `AUDIT.md` line 41, JR step 7: "22 inputs in `export/r/inputs.csv` (data 10, research 4, guesswork 6, derived 1, scenario 1)".
- `rjkdc-analysis/export/r/inputs.csv` today: data 9, research 4, guesswork 6, guesswork on data 1 (`nber_growth_rate`), derived 1, scenario 1 (22 rows).
- `rjkdc-analysis/site/materials.html`, "Data files the site publishes": "every input: value, OPA label (data / research / guesswork / scenario / derived / guesswork on data)", which agrees with the CSV.
- What differs: the audit still counts the 7% growth rate as data. The same author answer (13) that changed the kind is already recorded in the comparison step 7 row of the audit ("because the JR base is the 2025 list grown by an assumed 7%"), so the file contradicts itself across the two tables.
- Fix: the CSV is right. Change the JR step 7 evidence to "(data 9, research 4, guesswork 6, guesswork on data 1, derived 1, scenario 1)" and add the dated note the BSZ row has ("the 7% growth rate became guesswork on data on 2026-10-16, author answer").

### C-03. `AUDIT.md` says the comparison uses three third-party documents; the materials page and the manifest say four [blocking]

- `AUDIT.md` line 58, comparison step 4: "Three third-party documents only the comparison uses: Hoopes and the LAO, in `comparison/DATA-SOURCES.csv`, and Walczak (California Tax Foundation, 2026-04-22), in `rjkdc-analysis/DATA-SOURCES.csv`, each with URL and SHA-256".
- `comparison/site/materials.html`, "Sources": "The comparison alone uses four documents. Three of them, Hoopes (2026), the LAO's ballot analysis and the arguments for and against in the Secretary of State's voter guide (quoted on the deck's second slide), are recorded in this manifest ... The fourth is Walczak".
- `comparison/DATA-SOURCES.csv` row 4: `original-materials/sos-vig-2026-prop40-arguments.pdf`, obtained 2026-10-16 (author answer 9).
- Fix: the materials page and the manifest are right (the voter guide row was added in ecf2e26). Update the audit's step 4 evidence to four documents, naming the voter guide, and add "step 4" to the header line that lists which steps were updated on 2026-10-16.

### C-04. BSZ's own headline is "about $100 billion" on six surfaces and "$104B" on two, with no bridge between them where it is $104B [major]

- "$100 billion": `bsz-analysis/site/index.html` first paragraph ("Boll, Saez and Zucman (BSZ) estimate it raises about $100 billion"); `bsz-analysis/site/explorer/index.html` ("put the one-time tax at about $100 billion of wealth tax"); `bsz-analysis/site/slides/slides.Rmd` study-brief ("The authors estimate **about $100 billion** (Table 5 prints $104 billion ...)"); `README.md` ("a one-time wealth tax of about $100 billion"); `comparison/site/slides/slides.Rmd` slide opa-bsz ("estimate the one-time tax at about $100 billion of wealth tax"); `rjkdc-analysis/site/slides/slides.Rmd` ("estimates it at about $100 billion").
- "$104B": `index.html` first paragraph, "The BSZ analysis (Boll, Saez and Zucman, NBER, August 2026) finds that it raises about $104B of wealth tax" (the token `{{bsz_printed}}` in `comparison/site/index.template.html` line 304); `comparison/site/repro.html` introduction, "The BSZ analysis estimates about $104B of wealth tax".
- What differs: both are the paper's figures (the abstract rounds Table 5's $104 billion to $100 billion), but the comparison object alone cites the headline as $104B on its overview and report and as $100 billion on its deck, and a reader going from the root to the BSZ overview meets $104B then $100 billion with no sentence joining them on the root. The root's own BSZ card already carries the bridge ("Table 5 row 1, wealth tax: $103.8B (the paper prints $104B)") and the BSZ overview's footnote 1 does too; the first paragraph does not.
- Fix: keep the BSZ pages' wording (the authors' headline is the abstract's "about $100 billion"; the BSZ report's introduction states the chain $100 billion, $104 billion, $103.8 billion). On the root template and the comparison report's introduction, write "about $100 billion of wealth tax (its Table 5 prints {{bsz_printed}})", keeping the token so the $104B stays generated. One wording on the three comparison surfaces.

### C-05. The root and the comparison explorer call −$39.0B "the number each analysis's overview page leads with"; the JR overview leads with −$38.9B [major]

- `index.html` footnote 1 and `comparison/site/explorer/index.html` footnote 1 (both from `comparison/R/site.R`): "The number each analysis's overview page leads with, out of the many settings each analysis can be run at ... The JR number is the authors' mean net present value in perpetuity. The paper prints −$38.9B ... The exact average of the same formula is −$38.98B, used throughout this page".
- `rjkdc-analysis/site/index.html` headline block: "Main estimate, NBER September 2026: −$38.9B"; `rjkdc-analysis/README.md`: "Review the code behind the -$38.9 billion main estimate"; `AUDIT.md` JR step 1: "-$38.9 billion ... shown as the headline number on the overview".
- `comparison/site/repro.html`, "Introduction", gets it right: "the JR analysis's mean net present value in perpetuity, −$38.9B as printed (NBER, September 2026) and −$39.0B as computed exactly here".
- What differs: the footnote's first clause is false for the JR analysis. The split (JR site prints the authors' number, the comparison uses the exact average) is settled; the sentence describing it is not accurate.
- Fix: in `site.R`'s footnote text, replace the first clause with the report's formulation: "The BSZ overview leads with $106.8B, this OPA's net total. The JR overview leads with the printed −$38.9B; this page uses the exact average of the same formula, −$38.98B, shown as −$39.0B." Rebuild with `Rscript comparison/run.R` (the comparison `test-site.R` checks the generated pages).

### C-06. The comparison's three surfaces state the JR loss three ways in their opening sentence [minor]

- `index.html` first paragraph: "finds that it leaves the state about $39B poorer (their paper prints an average of −$38.9B)".
- `comparison/site/repro.html` introduction: "The JR analysis finds the state $38.9B poorer in today's dollars".
- `comparison/site/slides/slides.Rmd` slide why-opa-2: "the JR analysis, at `r usd(rj_main)`" (−$39.0B, the exact average).
- What differs: the report's introduction uses the printed value and the rest of the report uses −$38.98B, as the root and deck do. The root's form says both.
- Fix: the root's form. In `comparison/site/repro.qmd` line 126, "finds the state about $39B poorer (their paper prints an average of −$38.9B)", with the $39B read from the exports as the deck does.

### C-07. The asset-sale share is "33%" on the comparison explorer and root, "1/3" in the comparison report, the BSZ explorer and the BSZ report [minor]

- `comparison/site/explorer/index.html` minor-inputs fold: "Asset sales ... 33%"; `index.html` differences table: "Asset sales 33%. One third, an assumption (BSZ p.24 ...)".
- `comparison/site/repro.html` bridge and Shapley tables: "Three minor inputs ... $150B; 0.0%; 1/3" and "Extra income tax from selling assets to pay ... 1/3 ... 0%"; `bsz-analysis/site/explorer/index.html` dial s: "none, 1/3, 2/3, all"; `bsz-analysis/site/repro.html` notation table: "s ... 1/3".
- Fix: one form. The BSZ pages and the paper say one third, so "1/3" on the comparison explorer's end label and the root's table (the explorer's `fmt_input("s", ...)` in `comparison/R/site.R` already prints "1/3" on the deck's two-ends slide, so the formatter exists).

### C-08. The share of the base already departed is "28.5%" in DISPUTES.md and "28.6%" on the comparison explorer, the root and the comparison deck [minor]

- `comparison/DISPUTES.md` row 3: "$577.7B grown 7% to 31 Dec 2026, 28.5% of the domestic base (Table 7, PDF p.21). Revenue falls from $100.9B to $72.06B, a semi-elasticity of 28.6% / 5.00 = 5.73".
- `comparison/site/explorer/index.html` f tip (both panels) and `index.html` f row: "from a draw set around the 28.6% of wealth that left"; `comparison/site/slides/slides.Rmd` slide diff-departed: `pct(dshare(rj), 1)` (28.6%, D over the base net of real estate).
- What differs: 577.7 / 2,027.4 = 28.5% (share of the grown list); (100.9 − 72.06) / 100.9 = 28.6% (share of the face-value revenue, which nets out real estate). Both are in the chapter. The DISPUTES row gives both without saying they are different denominators.
- Fix: in DISPUTES.md row 3, after "28.5% of the domestic base", add "(28.6% of the revenue, net of real estate, which is the share the explorer and the deck print)". No page changes.

### C-09. The f dial's two end labels differ between the two explorer panels, and the root's table prints a third pair [minor]

- `comparison/site/explorer/index.html`, BSZ panel, f: ends "5% BSZ" and "50% JR"; JR panel, f: ends "6% BSZ" and "45% JR". `index.html` differences table: "f share lost 5%" (BSZ) and "45%" (JR).
- What differs: the end values move with D and a, as the loss-box tip says ("f also moves with D and a") and the f tip says ("Both ends include the movers in a ... and the BSZ end also the leavers in D"). A reader comparing the panels sees 50% against 45% for the same JR rule.
- Fix: no number is wrong. Add half a sentence to the f end tips, "shown at this panel's D and a", so the 50% and the 6% are explained where they appear. If that takes a tip past three lines at 390 px, leave it and rely on the box tip.

### C-10. Typed numbers that the pipeline does not write (drift risk, all currently right) [minor]

- `comparison/site/slides/slides.Rmd` line 182, slide prop40: "$25/`r round(abs(rj_main))` billion in lost revenue (the JR analysis, March/September versions)". The 25 is typed (the March mean, −24.7, rounded); the 39 is computed. `ex$endpoints` carries the March value (`epv("rauh_ssrn_npv")` or the `anchors.csv` row), so it can be read.
- `bsz-analysis/site/slides/slides.Rmd` slide study-brief: "$3.2 billion a year over 2023 to 2025", "2.4% of the state's income tax revenue", "nearly $1 trillion in business wealth, about 40% of the total, taxed at 0.04% of wealth", "multiplied by 25". The slide says they are the paper's own figures from the abstract and tables, and the deck's note says every number "from the Deck Map onward" is computed. The report's Table 2 and Table 4 hold the series these are summarised from; the slide could read them from the pipeline's exports as the other slides do, or keep them typed and labelled as the paper's own, which it already does. Low priority.
- `bsz-analysis/site/checks.qmd` line 4: `date: 2026-10-15`, typed; the JR checks page has `date: 2026-10-16` and every other Quarto page has `date: today`. The BSZ page was re-rendered on 2026-10-16 (its tables are now built from `grid.js`), so "Published October 15, 2026" understates the render. Fix: `date: today` on both checks pages.
- `bsz-analysis/site/index.html` and `bsz-analysis/site/explorer/index.html` `<meta name="description">`: "the $104 billion estimate" and "BSZ's $104 billion estimate", while the visible text on both pages says "about $100 billion" (C-04). Not pinned by `test-site.R`. Fix with C-04, one wording.
- For the record, the typed numbers on the three overviews that are pinned by a test and so are not a drift risk: the BSZ overview's $103.8, $2,307, 250, the four Table 5 rows, "1,916 settings", "28 cells", "26 round", the two mis-rounded cells and $106.8 (`bsz-analysis/tests/testthat/test-site.R`, "every number typed into the landing page matches the pipeline"); the JR overview's −38.9, 85.2%, −38.89, −38.98, 36.00, 74.98, "about 30 (28.4 to 35.6)", the revenue chain, "22 to 67 dollars", 2,187, alpha 1.44 and "ten mismatches" (`rjkdc-analysis/tests/testthat/test-site.R`). The root's and the comparison explorer's numbers are tokens filled by `comparison/R/site.R`, including the $145.8B gap and "all nine steps".

## Language

### C-11. The comparison's navigation line has two prefixes: "Prop 40 comparison:" on the generated pages and "Comparison of the two analyses of California Proposition 40:" on the Quarto pages [major]

- `index.html` and `comparison/site/explorer/index.html` (rendered): "Prop 40 comparison: Overview (here) · Open Output: Explorer · Open Analysis: Report and Slides · Open Materials" (commit 3b6ef55, "a shorter nav line").
- `comparison/site/repro.html` and `comparison/site/materials.html`: "Comparison of the two analyses of California Proposition 40: Overview · Open Output: Explorer · Open Analysis: Report (here) and Slides · Open Materials".
- The BSZ and JR objects are consistent across all their pages ("BSZ analysis of California Proposition 40:", "JR analysis of California Proposition 40:").
- What differs: the nav line is a shared element (CONTENT-MAP rule 5), and within the comparison it changes wording between the overview and the report it links to. The comparison `test-site.R` does not pin the prefix.
- Fix: the generated pages carry the author's shorter form (3b6ef55), so change the two `.qmd` nav lines (`comparison/site/repro.qmd`, `comparison/site/materials.qmd`) to "Prop 40 comparison:", re-render both, and pin the prefix in `test-site.R` next to the other nav checks.

### C-12. The JR README says the tests come in three kinds; the JR materials page says four [major]

- `rjkdc-analysis/README.md`, "Tests": "Three kinds, per file: 1. Vs. the paper's printed number ... 2. Vs. the authors' own scripts ... 3. Parity between export/r/ and export/py/".
- `rjkdc-analysis/site/materials.html`, "Tests": "They come in four kinds: Against the paper's printed number ...; Against the authors' own scripts ...; Parity ...; The site (test-site.R): the explorer's grid.js and site/data/headlines.csv must be byte-identical ...".
- Fix: the materials page is right (`test-site.R` is a fourth kind and holds 73 of the 199 expectations). Add the fourth kind to the README's list, in the materials page's words.

### C-13. The loss box's dials are listed in two orders within the comparison report, and the explorer's term label uses the one the path does not follow [minor]

- `comparison/site/repro.qmd` line 169 (rendered "Introduction"): "It adds up the four steps of the loss box (H, f, C and r) into one term".
- `comparison/site/repro.qmd` line 514 (rendered "The bridge, step by step"): "That order is D, then q, then the four loss-box dials (f, C, H and r), then W, a and the minor switch". The bridge table moves f, C, H, r in that order, as `DECISIONS.md` (2026-10-15, "the equation's order") records.
- `comparison/site/explorer/index.html` and `index.html` equation term: "Lost income tax (H, f, C, r)"; explorer footnote 2: "the four loss-box dials of the walk added up (H, f, C and r)". `comparison/site/slides/slides.Rmd` slide pseudo-eq: "(iii) For how long is the income tax lost? Then f, C and r" (H first by exposition).
- Fix: the path order is f, C, H, r (the loss box's own order on the explorer). Write it that way in the report's introduction (line 169) and in the equation label and footnote 2 (`eq_terms()` in `comparison/R/site.R`), unless the author wants H first in the label because its step is the largest; then say so once in footnote 2 ("H listed first because its step is the largest; the path moves f, C, H, r").

### C-14. The three overviews' first sentence differs in the shared clause [minor]

- `index.html` and `rjkdc-analysis/site/index.html`: "would tax, once, people who lived in California on 1 January 2026 and are worth $1 billion or more, at 5% of their net worth, payable over five years."
- `bsz-analysis/site/index.html`: "would tax people who lived in California on 1 January 2026 and are worth $1 billion or more, once, at 5% of their net worth." No "payable over five years".
- Fix: author answer 22 restored the residency date on all three and answer 26 asked for the shared text to be mirrored. Put the root's sentence on the BSZ overview.

### C-15. The credit fold opens with different lead sentences on the three overviews [minor]

- `bsz-analysis/site/index.html`: "The numbers on this page reproduce and are tested; what is still being completed is the author's own review of each part, recorded in the last column below, and the author's questionnaire on who did what. The author and Claude Code built this together. The table shows who led each object ... How the table was made [fold] This work was a collaboration ...".
- `rjkdc-analysis/site/index.html`: "The numbers on this page reproduce and are tested; what is still being completed is the author's own review of each part, recorded in the last column below. This work was a collaboration ...".
- `index.html`: no lead sentence; a subtitle "who did what, and what a person has checked", then "This work was a collaboration ...".
- What differs: decision Q3 (2026-10-14) made the credit fold's first sentence "state directly what is tested and what is still being completed" on the three overviews; the root has none, and the BSZ page keeps a "How the table was made" fold the other two do not have.
- Fix: the JR form on all three (the BSZ sentence's extra clause about the questionnaire stays true until the object-by-object interview, R3-Q12, so keep it there). The root gets the JR sentence with "comparison" for "JR analysis".

### C-16. The JR deck's nav line names the object differently from the BSZ deck's [minor]

- `rjkdc-analysis/site/slides/slides.Rmd` line 143: "Part of an Open Policy Analysis of the JR analysis (Jaros and Rauh, 2026) of California Proposition 40: Open Output (the explorer) · Open Analysis: Report and Slides (here) · Open Materials · Overview".
- `bsz-analysis/site/slides/slides.Rmd` line 165: "BSZ analysis of California Proposition 40: Open Output (the explorer) · ...".
- Fix: "JR analysis of California Proposition 40:", the pages' prefix.

### C-17. The JR explorer's f dial label and the checks page write the minus as a hyphen [minor]

- `rjkdc-analysis/site/explorer/index.html` dial f, first stop: "1 - WT/94.2"; `rjkdc-analysis/site/checks.html` results table: "set ... the share lost to “1 - WT/94.2”" (read from `grid.js`, so one source); `rjkdc-analysis/site/repro.html` inputs table: "1 - WT/94.2".
- Every other formula on these pages uses the minus sign ("r − g", "NPV = WT − f·C / (r − g)").
- Fix: "1 − WT/94.2" in `rjkdc-analysis/R/site.R` (the dial labels), which flows to the explorer, the checks page and the report's dial rows. The JR `test-site.R` compares the checks page with `grid.js`, so one change keeps them equal.

### C-18. DISPUTES.md is headed "Updated 2026-10-15" but row 7 carries a 2026-10-16 change [minor]

- `comparison/DISPUTES.md` line 3: "**Updated 2026-10-15.**"; row 7, Kind: "data vs guesswork on data (the JR base is the 2025 list grown by an assumed 7%; author answer 2026-10-16)"; the real-estate kind "guesswork vs data" also changed on 2026-10-16 (author answer 12).
- Fix: "Updated 2026-10-16."

### C-19. The JR overview's and JR explorer's wording for q differs from the comparison's, with no cross-reference [minor]

- `rjkdc-analysis/site/explorer/index.html` dial q: "Extra litigation weight on the revenue ... Multiplies the revenue again, on top of the draw's 0 floor, which already halves its mean"; its main-estimate stop is "1 (none extra)".
- `comparison/site/explorer/index.html` dial q: "litigation, chance it survives court", JR end "50%"; its notes fold already explains the link: "The JR explorer's litigation dial reads 1 at the main estimate, because there the revenue draw from 0 to the ceiling already halves the mean revenue. This explorer applies the same half as q = 50% of the ceiling."
- `rjkdc-analysis/site/index.html`, "What this OPA does not estimate": "The JR analysis alone weights the revenue by the chance the Act survives in court."
- What differs: the comparison explains the two dials' relation; the JR explorer's q dial does not mention that the comparison's q is 50% at the JR end. A reader arriving from the comparison finds q at 1.
- Fix: one clause in the JR q dial's description or the explorer's Notes ("the comparison explorer's q, 50%, is this same half"), with the link.

## Cross-references

### C-20. Cross-references checked and found consistent (no action)

- Root and explorer, "The report's order-free check" points at `comparison/site/repro.html#order-free-check`, whose fold is titled "An order-free check: the Shapley average". Present.
- Root and explorer, "The report gives all nine steps": the report's bridge table has nine steps (D, q, f, C, H, r, W, a, the minor switch) and says "The nine steps"; the count is `et$n_words`, generated.
- Comparison deck: no slide is referred to by number; the term slides are linked by name (`#diff-departed`, `#diff-litigation`, `#diff-horizon`, `#diff-loss-rest`, `#smaller`), the contents slides by anchor, and the layer slides by anchor. The counts on the opa-bsz, opa-jr and verification slides are read from the checks pages, `MISMATCHES.md` and `review/*.json`: "Ten settings" (BSZ) and "Nine settings" (JR) sent to the authors match the checks pages ("ten such changes", "nine such changes"); "7 of 7 match" and "4 of 4 match; 1 more cannot be set" match the overviews ("All seven variations match", "All four printed variations match").
- Tense: the checks pages, the overviews and the comparison deck all say the settings "have been sent" (R2-Q1 kept); no page says "will be sent" or "copied on" (the BSZ `test-site.R` forbids "copied").
- Versions and dates: August 2026 BSZ revision (May the earlier), NBER September 2026 chapter (SSRN March the earlier), 1 July 2026 valuation for BSZ, 31 December 2026 for the Act and the JR growth, 1 January 2026 residency, 15 April 2026 for the May workbook, agree on every page read. Table A1's 43 years is stated the same way on the BSZ overview, report and materials page (43 as the paper, 44 would give 7.4%, 6.0%, 2.5%).
- Test counts: BSZ 778 expectations in 117 blocks (report, materials page, README); JR 199 expectations in 33 tests (materials page; the README defers to it); comparison 1016 in 53 blocks (materials page; the README defers to it). The JR materials page's "for the SD, four standard errors of an SD" matches `test-npv-mc.R` line 24-25 (tolerance 0.34, author answer 16).
- Badges: `test-ai-badges.R` in each folder ties every badge to `credit-answers.json`; the four badge texts found ("AI generated, partially reviewed" on the BSZ overview, report, README, the JR overview and deck; "AI generated, not reviewed yet" on the JR report and README and the comparison report and README) match the credit levels, and the root overview and the BSZ and comparison decks carry none, as their "Reviewed/Understood" answers require.
- Mismatch counts: ten, five in the September chapter (3, 4, 5, 6, 10), five in the March version (1, 2, 7, 8, 9), the same on the JR overview, report, materials page, README, deck and `MISMATCHES.md`.
- Disputed inputs: DISPUTES.md has ten rows; rows 1 and 4 are marked "not a bridge step"; the root README's "10 disputed inputs ... 8 explorer dials and a switch for 3 minor inputs" and the report's nine steps agree.

## Counts

- Blocking: 3 (C-01, C-02, C-03).
- Major: 4 (C-04, C-05, C-11, C-12).
- Minor: 12 (C-06 to C-10, C-13 to C-19).
- Checked and consistent: C-20 (no action).
