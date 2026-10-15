# Credit interview handoff (2026-10-15)

The author is re-running the CRediT questionnaire (the `credit` skill, FULL version: 14 roles
plus human verification per object, four AskUserQuestion rounds per object) for the JR and
comparison OPAs. Every answer comes from the author; never fill a cell from history.

Contributors: Fernando Hoces de la Guardia (human); Claude Code (Opus, Sonnet) (AI).
Objects, for each of the two OPAs: Explorer, Report, Slides, Repository, Overview page
(the author asked for Repository and Overview page to be separate).

Progress, in this folder:
- `jr-answers.json`: Explorer, Report, Slides, Repository complete (15 answers each).
  Left: Overview page.
- `comparison-answers.json`: nothing answered yet. Left: all five objects.
- One answer to confirm with the author: JR Slides, Funding acquisition = "AI lead" (every other
  object has N/A).

Answer values: Human only, Human lead, Equal, AI lead, AI only, N/A; verification: No human
review, Lightly checked, Understood, Not applicable. The author types "equal" or "NA" under
Other; record them as Equal and N/A.

When an OPA is complete:
1. Replace `rjkdc-analysis/site/credit/credit-answers.json` (or `comparison/site/credit/...`) with
   the new answers (version full, date 2026-10-15, the five objects), and regenerate that
   folder's CREDIT.md as the skill describes.
2. Rebuild the credit table on that OPA's overview page ("How AI was used in this exercise, and
   what has been verified" fold): rjkdc-analysis/site/index.html is hand-maintained; the
   comparison's lives in comparison/site/index.template.html / comparison/R/site.R and is
   rebuilt with `Rscript comparison/run.R`. Squares sort author-led, shared, Claude-led; colours
   --credit-h / --credit-ai (assets/paper.css). Check the site tests pin no old values
   (comparison/tests/testthat/test-site.R, rjkdc-analysis/tests).
3. Commit by path only (another session works on the site in parallel), no em-dashes, and push
   after the author says so.

Files this handoff owns: `*/site/credit/*`, the credit fold on the JR and comparison overview
pages, and this folder. The other session will not edit them.

## Status: complete (2026-10-15)

All ten objects answered. Confirmed with the author: Funding acquisition and Resources are N/A on
JR Slides, JR Repository, and the comparison Report, Slides and Repository. The comparison Explorer
and Overview page keep Resources = AI lead, stated in a sentence on the page (Resources is in none of
the three groups). Both CREDIT.md files and both overview tables are rebuilt from these answers.
