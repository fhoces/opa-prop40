# Improvements from the consistency review (run 004)

From `01-consistency-review.md` (commit 80ddb60). One implementer applies all of them. Where the
review offered a choice, the choice is made here. Ids are the review's.

## Numbers

1. C-01 (blocking). `rjkdc-analysis/site/repro.qmd`, chunk `origins-count`: add `"guesswork on data"`
   to the factor levels (or build the levels from the origins present) so the count table prints
   26 rows' worth and matches its caption. Re-render the JR report.
2. C-02 (blocking). `AUDIT.md`, JR step 7: counts become data 9, research 4, guesswork 6, guesswork
   on data 1, derived 1, scenario 1, with the dated note the BSZ row has (the 7% growth rate became
   guesswork on data on 2026-10-16, author answer). Recount from the CSV, do not type.
3. C-03 (blocking). `AUDIT.md`, comparison step 4: four third-party documents, naming the voter guide
   (`comparison/DATA-SOURCES.csv` row 4), and add step 4 to the header line listing the steps
   updated on 2026-10-16.
4. C-04 (major). One wording for the BSZ headline on the three comparison surfaces: "about $100
   billion of wealth tax (its Table 5 prints {{bsz_printed}})" on the root template
   (`comparison/site/index.template.html`) and in the comparison report's introduction
   (`comparison/site/repro.qmd`), keeping the $104B generated. The BSZ pages stay as they are.
   Also C-10 item 3: the `<meta name="description">` of the BSZ overview and BSZ explorer say
   "about $100 billion", matching their visible text.
5. C-05 (major). Footnote 1 on the root and the comparison explorer (`comparison/R/site.R`): replace
   "The number each analysis's overview page leads with" with the report's formulation: the BSZ
   overview leads with $106.8B, this OPA's net total; the JR overview leads with the printed
   -$38.9B; this page uses the exact average of the same formula, -$38.98B, shown as -$39.0B. Every
   number from the exports.
6. C-06 (minor). `comparison/site/repro.qmd` introduction: "finds the state about $39B poorer (their
   paper prints an average of -$38.9B)", both numbers read from the exports, as the root does.
7. C-07 (minor). The asset-sale share prints "1/3" (not "33%") on the comparison explorer's minor
   inputs and the root's differences table, using the existing `fmt_input("s", ...)` formatter.
8. C-08 (minor). `comparison/DISPUTES.md` row 3: after "28.5% of the domestic base" add "(28.6% of
   the revenue, net of real estate, which is the share the explorer and the deck print)".
9. C-09 (minor). The f dial's end tips on the comparison explorer: add "shown at this panel's D and a"
   if the tip stays within three lines at 390 px (check with the tip audit); otherwise leave it.
10. C-10 (minor). Typed numbers: (a) the comparison deck's slide 2 "$25" becomes the March mean read
    from the exports (`anchors.csv` or `endpoints` `rauh_ssrn_npv`), rounded as now; (b) `date: today`
    on both checks pages (`bsz-analysis/site/checks.qmd`, `rjkdc-analysis/site/checks.qmd`);
    (c) see item 4 for the meta descriptions. The BSZ deck's study-brief figures stay typed: they
    are the paper's own, and the slide says so.

## Language

11. C-11 (major). The comparison nav line: "Prop 40 comparison:" on `comparison/site/repro.qmd` and
    `comparison/site/materials.qmd`, matching the generated pages; pin the prefix in the comparison
    `test-site.R` next to the other nav checks. Re-render both pages.
12. C-12 (major). `rjkdc-analysis/README.md`, Tests: four kinds, adding the site tests in the
    materials page's words.
13. C-13 (minor). Keep the equation label "Lost income tax (H, f, C, r)" (the author's wording). In
    the explorer's footnote 2 (`eq_note()` in `comparison/R/site.R`) say once that H is listed first
    because its step is the largest, and that the path moves f, C, H, r. Leave the report's two
    sentences as they are.
14. C-14 (minor). The BSZ overview's first sentence takes the root's form: "would tax, once, people
    who lived in California on 1 January 2026 and are worth $1 billion or more, at 5% of their net
    worth, payable over five years." Update the BSZ `test-site.R` pin if it holds the sentence.
15. C-15 (minor). The credit fold's lead sentence: the JR form on all three overviews. The BSZ
    page keeps its extra clause about the questionnaire (true until the object-by-object interview)
    and its "How the table was made" fold. The root gets the JR sentence with "comparison" for
    "JR analysis" (in `comparison/site/index.template.html`).
16. C-16 (minor). `rjkdc-analysis/site/slides/slides.Rmd` nav line: "JR analysis of California
    Proposition 40:", the pages' prefix.
17. C-17 (minor). "1 − WT/94.2" with the minus sign in `rjkdc-analysis/R/site.R` (the dial labels),
    flowing to the JR explorer, checks page and report. Mirror in the Python twin if it holds the
    label.
18. C-18 (minor). `comparison/DISPUTES.md` header: "Updated 2026-10-16."
19. C-19 (minor). One clause in the JR explorer's Notes (not the q dial's tip): the comparison
    explorer's q at the JR end, 50%, is this same half, with a link to the comparison explorer.

## Not changed

- C-20: cross-references checked and consistent.
- C-10 item 2 (the BSZ deck's study-brief figures): typed on purpose, labelled as the paper's own.
