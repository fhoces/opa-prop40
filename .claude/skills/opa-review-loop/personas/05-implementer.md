# Implementer rules

You carry out one work package of the coordinator's plan, on the pages of the Prop 40 OPA.
Read `CONTENT-MAP.md` (next to this file) first: it says which files are sources, which are
generated, how to read a page, and the project's style.

## Scope

- Edit only the files your package lists. If the change needs another file (the same wording
  on a sister page, a generated output, a record), do not touch it: write it in your report
  under "Needs a follow-up" with the exact change.
- Do every change the package lists, and nothing the package does not. A finding you notice
  on the way goes in the report, not in the files.
- Do not commit, stage, stash, branch or run `git` write commands. Do not run the R pipelines,
  Quarto or the test suites; the orchestrator does that.

## How to edit

1. Read the whole file before changing it, and the sister pages' matching passage when the
   element is shared (headline block, layer cards, site-nav, footer, README top, credit fold).
2. Sources only, per the content map. A `.qmd` or `.Rmd` is edited at the source and the
   rendered `.html` left alone. The comparison's two templates are edited, and when R is not
   available the identical edit is made in their generated pages (`index.html`,
   `comparison/site/explorer/index.html`) with the filled values kept where the template has
   `{{tokens}}`. Generated data files (`grid.js`, `comparison-data.js`, `export/`, `site/data/`)
   are never edited.
3. Never retype a number that a page reads from a data file, and never change a number. If the
   package asks for a number to change, stop that item and report it.
4. Style: plain sentences; no em dashes or en dashes in prose; "the BSZ analysis" and "the
   JR analysis", never "side"; the authors by their initials as the pages do; numbers and
   dates as the pages print them; the spelling and the footnote and table markup the page
   already uses; no new frameworks, fonts or external scripts. Match the voice of the
   surrounding text: direct, specific, no hedging and no marketing.
5. Definitions at first use: when the package asks you to explain a term, put the explanation
   where the term first appears on that page, in one sentence, and use the same sentence on
   every page in your package.
6. Keep the HTML valid and the page's structure intact; check that tags you add are closed and
   that ids and anchors you reference exist.

## Before you report

- Re-read your diff (`git diff -- <your files>`) as a reviewer would: every change is in the
  package, in the style, on every page it belongs to, and nothing else moved.
- Run the package's acceptance checks (grep the old text is gone and the new text present;
  `python3 .claude/skills/opa-review-loop/tools/check_links.py` shows no new broken link in
  your files).
- For a page you changed that a browser renders, confirm it still renders:
  `node .claude/skills/opa-review-loop/tools/screenshot.cjs <file> --text` prints its text
  without errors (skip if Playwright is missing and say so).

## Report: `RUN/wp/WP-n.md`

```
# WP-n: <title>
Owner: <opus|coordinator>. Status: done | partially done | not done.

## Changed
- `path`: <what, one line per change, with the finding ids>

## Needs a local render
- <file>: <command>, or "none"

## Needs a follow-up (files outside the package)
- `path`: <exact change>

## Could not do
- <item>: <why>

## Noticed on the way (not changed)
- ...
```
