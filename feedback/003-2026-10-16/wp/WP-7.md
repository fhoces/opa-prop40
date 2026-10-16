# WP-7: The comparison's two templates: the root's first screen, footnotes, conventions and notes
Owner: coordinator. Status: done.

## Changed
- `comparison/site/index.template.html`:
  - First sentence: "paid over five years" is now "payable over five years" (E-01).
  - First paragraph: "finds that it raises money for the state" is now "finds that it raises about {{bsz_printed}} of wealth tax" (V-01). "(the chapter prints a mean of {{nber_printed}})" is now "(their paper prints an average of {{nber_printed}})", with the amount in a nowrap span (V-02, V-05).
  - OPA sentence: "It follows the ... (OPA) framework" now goes on: "the result, the method and the materials each have their own page, and every input is marked by the kind of evidence behind it" (V-03).
  - BSZ definition line: "the income tax it changes" is replaced by "Net total: the wealth tax, plus income tax from assets sold to pay it, minus income tax lost to leavers over 5 years, in today's dollars" (V-04).
  - JR definition line: "print {{nber_printed}} from one run" is now "print {{nber_printed}}, the average of one simulation of 100,000 random draws", with the amount in a nowrap span (V-02, V-05).
  - "Today's dollars" line: the face-value sentence now says the Act lets the tax be paid in five yearly installments, each later one with a 7.5% yearly deferral charge on the unpaid balance, which neither analysis counts (E-01). No conventions sentence or initiative link is added (run 002 Q10).
  - Open Materials card: "Python twin" is glossed (E-21).
  - BSZ sub-card: "Static estimation on the Forbes list with a 10% avoidance allowance" is replaced by "The Forbes list on 1 July 2026, less a 10% allowance for avoidance and evasion, half of it billionaires who moved away" (A-01).
  - Hoopes fold: "bridges the two estimates step by step" is glossed as "a sequence of steps from one main estimate to the other, one input at a time" (E-21).
  - "The differences" note: it now defines all six kinds, worded as on the explorer and keeping the derived-rate clause, and says that a source ending in .R is a script in the authors' repository (V-11).
  - Footnote 1: "The main estimate on each analysis's overview page" is now "The number each analysis's overview page leads with, out of the many settings each analysis can be run at" (V-13).
- `comparison/site/explorer.template.html`:
  - JR definition line: same change as on the root (V-02, V-05).
  - Quantities section: a line between the pinned heading and `{{quantity_survey_x}}`: "Each dial's two ends above give both analyses' values. The overview's table of differences sets them side by side with their sources." It links to `../../../index.html#differences` (V-19). The pinned "All these are empirical quantities" text is untouched (run 002 Q11).
  - Footnote 1: the same V-13 wording, keeping ", each defined its own way" (V-13).
  - Footnote 1: "Monte Carlo draws" is glossed (E-21).
  - Notes fold, new paragraph: the JR explorer's litigation dial reads 1 because its revenue draw from 0 already halves the mean, and this explorer applies the same half as q = 50% of the ceiling (V-18). This matches `score_common()` in `comparison/R/model.R`, where WT = R0 (1 − alpha) S q.
  - Conventions: "at the assessment date" now says that present values are as of the date the wealth tax is assessed and that the first year of lost income tax is counted one year later (E-08). The paragraph also adds the installment option with its 7.5% charge (§50301(c)) and the Optional Deferral Account (§50304), which neither analysis counts and which this OPA does not estimate (E-01).
  - Kinds paragraph: it now opens "Each end's tip ends with the kind of that analysis's value", and the "A vs B" sentence is gone (E-09).

## Needs a local render
- `index.html`, `comparison/site/explorer/index.html`: run `Rscript comparison/run.R`, then `Rscript comparison/tests/testthat.R`.

## Needs a follow-up (files outside the package)
- None.

## Could not do
- None.

## Noticed on the way (not changed)
- Checked against `comparison/tests/testthat/*.R`: no pin covers any string changed here, and the q-title heading and the "All these are empirical quantities" text are intact. The new link `../../../index.html#differences` points at the overview's fold id `differences`, and the root's hash script opens that fold on arrival.
- No em or en dash, no "Shapley" and no "disputed inputs" in any added line (checked on the git diff of both templates).
- The explorer's JR definition line is a few words longer. The author's limit of about 150 words before the first slider should be checked on the rendered page.
