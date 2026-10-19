# Final review before launch, 2026-10-19

- Branch: `review/final-2026-10-19`, from `origin/main` at 85f2006 (the author's rebuild of plan.pdf
  and power.pdf after review 011).
- Environment: cloud (no R, no Quarto; Python 3 with numpy, pandas and scipy; Node with Playwright;
  pandoc). Generated pages cannot be rebuilt here: edits go to sources, the two comparison pages
  are hand-mirrored, and `needs_render.py` lists what the author rebuilds.
- Instruction (author, 2026-10-19): one final review of the whole project before launch; fix small
  issues without asking; list the big ones, where the author decides; write a map of how the pieces
  fit together for later sessions, and the lessons for the opa-framework session.
- Four reviewers in parallel (Fable), one file each in this folder:
  `01-survey-plumbing.md`, `02-public-pages.md`, `03-records-and-repo.md`, `04-analysis-code.md`.
  Then the orchestrator's `05-summary.md` (what was fixed, what the author decides, what the local
  session rebuilds). The project map goes to `.claude/memory/project-map.md`, the lessons to
  `.claude/memory/lessons-for-opa-framework.md`.
- CI on `main` at the start: comparison CI green on e202dbf and 5658cac, running on 85f2006; Pages
  deployed 85f2006 at 04:50 UTC, so the live site now carries the survey buttons with the
  placeholder links of `comparison/data/survey-links.csv`.
