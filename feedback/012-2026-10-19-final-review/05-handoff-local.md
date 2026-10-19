# Final review 012: stopped early, handoff to the local session

The author ended the cloud session for budget before the four reviewers finished. No reviewer
wrote a report. This branch holds what exists, unverified, for the local session to check.

## What is on the branch

- `.claude/memory/project-map.md` and `lessons-for-opa-framework.md`: finished. The map shows how
  the pieces fit together. The lessons are for the opa-framework session. Add both to `MEMORY.md`.
- Partial edits, **not verified**. Read each diff before you keep it.
  - `comparison/survey/PRE-ANALYSIS-PLAN.md`, section 9 "How to launch": steps 1, 2, 6 and 7 are
    rewritten to match `fixPrior()`'s log. They add the hash in a second commit, attaching the new
    PDFs, opening forms 3 to 6, checking the Key tab, and closing the two old forms after Pages
    deploys. **main's abee5e8 also edits section 9, so expect a merge conflict.** Rebuild
    `plan.pdf` if any of this is kept.
  - `comparison/survey/fill_links.py`: it reads the "finished:" line, refuses duplicate copies and
    unfinished forms, and writes LF line endings. Test it on a real `fixPrior()` log before launch.
  - `comparison/survey/README.md` (new): a guide to the folder. Its `pilot_analysis.py` line
    predates abee5e8.
  - `README.md`, `AUDIT.md`, `.claude/skills/opa-review-loop/CONTENT-MAP.md`,
    `feedback/README.md`, `docs/initiative/README.md`: survey mentions and stale-claim fixes,
    half done.

## Not reviewed

The public pages of the three sites (stale text, anchors, phone layout) and the survey plumbing
checklist (forms against the builder, the live placeholder state, `draws.gs`, the registry draft
against the plan). The analysis code was done on main in abee5e8.

## How to finish

Merge `review/final-2026-10-19` into main. Resolve section 9 of the plan, review the diffs above,
keep or drop each, rebuild `plan.pdf`, then follow the plan's "How to launch".
