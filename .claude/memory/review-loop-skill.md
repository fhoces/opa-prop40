---
name: review-loop-skill
description: The repo has a reusable multi-audience review loop at .claude/skills/opa-review-loop; how it is built and why the orchestrator dispatches the implementers
metadata:
  type: project
---
The repo carries `.claude/skills/opa-review-loop/` (added 2026-10-14). Invoke it with
`/opa-review-loop` and flags for iterations, reviewer, coordinator and implementer models and
efforts, `--ask`, `--review-only`, `--no-commit`, `--push`, `--focus`. Defaults are fable xhigh
for the three reviewers and the coordinator, opus xhigh for the implementers. Each run writes
`feedback/NNN-YYYY-MM-DD/` (run record, three reviews, plan, package reports, final review,
digest) and appends won't-do items to `feedback/DECISIONS.md`.

**Why:** the author asked for a repeatable review from three audiences (original authors,
outside policy experts, California voters) with a coordinator that plans, fans out and reviews.
Subagents have no Agent tool, so the coordinator cannot fan out. The session running the skill
dispatches one implementer per work package from the coordinator's plan and continues the
coordinator by SendMessage for its own packages and the final review, which keeps its context.

**How to apply:** before any content edit in this repo read
`.claude/skills/opa-review-loop/CONTENT-MAP.md`. It lists every public page, source versus
generated, the rebuild commands and the prose style (no em or en dashes, "the BSZ analysis" and
"the RJKDC analysis", never "side"). Run the loop rather than ad hoc reviews. See
[[cloud-container-no-r-quarto]] and [[site-tests-pin-page-strings]].
