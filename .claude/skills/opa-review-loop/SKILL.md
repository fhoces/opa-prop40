---
name: opa-review-loop
description: Review-and-update loop for the Prop 40 OPA (the BSZ analysis, the RJKDC analysis, the comparison). Three reviewer agents read every public page from three audiences (the original authors, outside policy experts, California voters), a coordinator agent triages their findings into a plan, implementer agents carry it out, and the coordinator reviews the result. Repeatable with a chosen number of iterations, models and effort levels, in the cloud or on a local machine. Use for "run the review loop", "review the OPA from the three audiences", or /opa-review-loop.
argument-hint: "[--iterations N] [--review-model M] [--review-effort E] [--coord-model M] [--coord-effort E] [--impl-model M] [--impl-effort E] [--max-implementers N] [--ask] [--review-only] [--no-commit] [--push] [--focus \"text\"]"
---

# opa-review-loop

One iteration is: three reviews in parallel, one plan, implementation in parallel, one final
review, one commit. `--iterations N` repeats it N times. Each iteration reviews the pages as the
previous one left them and reads the previous final review, so the loop converges rather than
repeats.

You, the session running this skill, are the orchestrator. You spawn the agents, dispatch the
plan's work packages, run the checks and commit. The coordinator agent plans, implements the
packages it keeps for itself, and reviews at the end. It cannot spawn agents (subagents have no
Agent tool), which is why you dispatch the implementers from its plan.

## Arguments

Parse `$ARGUMENTS` as flags. On an unknown flag, stop and say so.

| Flag | Default | Meaning |
|---|---|---|
| `--iterations N` | 1 | review, plan, implement, final review, commit; N times |
| `--review-model M` | fable | model of the three reviewers (agents 1 to 3) |
| `--review-effort E` | xhigh | their effort |
| `--coord-model M` | fable | model of the coordinator (agent 4) |
| `--coord-effort E` | xhigh | its effort |
| `--impl-model M` | opus | model of the implementers |
| `--impl-effort E` | xhigh | their effort |
| `--max-implementers N` | 6 | implementers running at once; more packages run in batches |
| `--ask` | off | after the plan, put the coordinator's questions to the user before implementing (a person must be at the keyboard) |
| `--review-only` | off | stop after the plan: the reviews and the plan are written and committed, no page changes |
| `--no-commit` | off | leave every change uncommitted |
| `--push` | off locally; on when `CLAUDE_CODE_REMOTE` is `true` | push after each iteration's commit |
| `--focus "text"` | none | one extra instruction given verbatim to every reviewer (a page, a theme, a question) |

Models are whatever the Agent tool accepts (`fable`, `opus`, `sonnet`, `haiku`). Efforts are
`low`, `medium`, `high`, `xhigh`, `max`. Pass them as the Agent tool's `model` and `effort`
parameters: this skill is the explicit instruction to set the effort.

Examples:

```
/opa-review-loop
/opa-review-loop --iterations 2 --impl-model sonnet --impl-effort high
/opa-review-loop --review-only --focus "the comparison explorer only"
/opa-review-loop --ask --review-model opus --review-effort high
```

## Files

```
.claude/skills/opa-review-loop/
├── SKILL.md                     this file
├── CONTENT-MAP.md               every public page and file: source or generated, how to read, how to rebuild
├── personas/
│   ├── 01-original-authors.md   agent 1
│   ├── 02-policy-experts.md     agent 2
│   ├── 03-voters.md             agent 3
│   ├── 04-coordinator.md        agent 4: Part A the plan, Part B its own packages, Part C the final review
│   └── 05-implementer.md        rules for every implementer, and for the coordinator's own packages
└── tools/
    ├── new_run.py               creates the run directory and writes 00-run.md
    ├── page_text.py             an HTML page as readable text (static text only)
    ├── screenshot.cjs           a page at phone or desktop width, or its rendered text, with Playwright
    ├── check_links.py           internal links in md and html files that do not resolve
    └── needs_render.py          from the changed files, the local commands that rebuild generated pages
feedback/
├── README.md                    what this directory is
├── DECISIONS.md                 settled items (won't do, with reasons); reviewers do not re-raise them
└── NNN-YYYY-MM-DD/              one directory per iteration
    ├── 00-run.md                commit, arguments, tools available, checks, render needs
    ├── 00-links-before.txt      broken internal links before the run (the baseline)
    ├── 00-links-after.txt       after the run
    ├── 01-original-authors.md
    ├── 02-policy-experts.md
    ├── 03-voters.md
    ├── 04-plan.md
    ├── 05-final-review.md
    └── wp/WP-n.md               one report per work package
```

## Procedure, one iteration

Use absolute paths in every prompt. `ROOT` is `git rev-parse --show-toplevel`; `RUN` is the
run directory; `START` is the commit the iteration starts from.

### Phase 0: set up

1. `cd ROOT`. Note the branch. `git status --short`: if files are modified, continue, but it is
   recorded in `00-run.md` and you tell the user at the end (the reviews then describe a tree
   that is not a commit).
2. `RUN=$(python3 .claude/skills/opa-review-loop/tools/new_run.py --args "<the raw arguments>")`.
   It creates `feedback/NNN-YYYY-MM-DD/` with `wp/`, writes `00-run.md` (commit, date,
   arguments, whether `Rscript`, `quarto`, `node` and Playwright are available) and prints the
   directory. `START=$(git rev-parse HEAD)`.
3. `python3 .claude/skills/opa-review-loop/tools/check_links.py > RUN/00-links-before.txt`.

### Phase 1: the three reviews, in parallel

Spawn three agents in one message, `subagent_type: general-purpose`, `model: <review-model>`,
`effort: <review-effort>`, `run_in_background: true`. Then wait for the three completion
notifications; do nothing else in the repository meanwhile. The prompt for reviewer N (brief
`personas/0N-<name>.md`, output `RUN/0N-<name>.md`):

> You are reviewer N of the opa-review-loop. Repository root: ROOT. Run directory: RUN.
> Read, in this order: `ROOT/.claude/skills/opa-review-loop/personas/0N-<name>.md` (your
> brief), `ROOT/.claude/skills/opa-review-loop/CONTENT-MAP.md` (what to review and the helper
> scripts), `ROOT/feedback/DECISIONS.md` if it exists (settled items: do not re-raise one
> unless the page changed), and the most recent `ROOT/feedback/*/05-final-review.md` if any
> (what the last iteration changed). Then review as the brief says and write your findings to
> `RUN/0N-<name>.md` in the brief's format. Do not edit any other file. [Focus: <text>]
> When done, reply in five lines: the counts by severity, then the three findings you would
> fix first.

### Phase 2: the plan

Spawn the coordinator, `subagent_type: general-purpose`, `model: <coord-model>`,
`effort: <coord-effort>`, `run_in_background: false`. Keep its agent id: Phases 3 and 5
continue it with SendMessage.

> You are the coordinator of the opa-review-loop. Repository root: ROOT. Run directory: RUN.
> The iteration started from commit START. Read
> `ROOT/.claude/skills/opa-review-loop/personas/04-coordinator.md` and do Part A: read the
> three reviews in RUN, triage them, and write `RUN/04-plan.md` in the format Part A gives.
> Reply with the number of work packages, which ones you kept for yourself, and every question
> you listed with the assumption you will proceed under.

Then:

- `--review-only`: go to Phase 6 and commit the run directory only.
- `--ask`, and the plan lists questions: put them to the user with AskUserQuestion (at most
  four per call; the coordinator's assumption is the recommended option). Then SendMessage the
  coordinator: "The author answered: <answers>. Revise `RUN/04-plan.md` accordingly and reply
  'plan revised'." Wait for the reply.
- otherwise the plan's assumptions stand. Say so in the final report.

### Phase 3: implementation, in parallel

Read `RUN/04-plan.md`. Each `### WP-n` section has an `Owner` (opus or coordinator) and a
`Files` list. In one message:

- for each package with `Owner: opus`, up to `--max-implementers` at once, spawn an
  implementer: `subagent_type: general-purpose`, `model: <impl-model>`,
  `effort: <impl-effort>`, `run_in_background: true`:

  > You are an implementer in the opa-review-loop. Repository root: ROOT. Run directory: RUN.
  > Your package: WP-n. Read `ROOT/.claude/skills/opa-review-loop/personas/05-implementer.md`
  > (your rules), `ROOT/.claude/skills/opa-review-loop/CONTENT-MAP.md`, then the section
  > `### WP-n` of `RUN/04-plan.md` and the findings it cites in `RUN/01-*.md`, `RUN/02-*.md`
  > and `RUN/03-*.md`. Do the package. Edit only the files it lists. Write your report to
  > `RUN/wp/WP-n.md`. Do not commit. Reply in three lines: the files changed, what needs a
  > local render, anything you could not do.

- if any package has `Owner: coordinator`, SendMessage the coordinator: "Implement WP-x and
  WP-y yourself now, per Part B of your brief. Write `RUN/wp/WP-x.md` and `RUN/wp/WP-y.md`.
  Reply 'packages done' with one line per package." It works alongside the implementers.

Wait for every completion notification. When a batch finishes and packages remain, start the
next batch. Do not edit the repository yourself during this phase.

### Phase 4: checks

Run from ROOT and append the results to `RUN/00-run.md` under `## Checks`:

1. `python3 .claude/skills/opa-review-loop/tools/check_links.py > RUN/00-links-after.txt`, then
   `diff RUN/00-links-before.txt RUN/00-links-after.txt`. Links broken after but not before are
   this run's: list them.
2. `python3 .claude/skills/opa-review-loop/tools/needs_render.py START`: from the files changed
   since START, the local commands that rebuild the generated pages. Append its output under
   `## Needs a local render`.
3. If `Rscript` is on PATH: `Rscript comparison/run.R`, then `Rscript comparison/tests/testthat.R`.
   If `quarto` is on PATH: render every changed `.qmd` from its analysis directory
   (`cd rjkdc-analysis && quarto render site/repro.qmd`; the comparison's from
   `comparison/site/`). If R and the xaringan package are present:
   `Rscript -e 'rmarkdown::render("<deck>.Rmd")'` for every changed deck. Run
   `cd bsz-analysis && Rscript tests/testthat.R` only if `bsz-analysis/original-materials/`
   holds the workbook, and the RJKDC suite only if `RAUH_REPO_DIR` is set. Record what ran,
   what passed, what was skipped and why. A failure goes to the coordinator in Phase 5; do not
   fix it yourself.
4. Without R or Quarto (the cloud container has neither), skip step 3 and record that.

### Phase 5: the final review

SendMessage the coordinator:

> All packages are done. Do Part C of your brief: review `git diff START` (the working tree),
> the reports in `RUN/wp/`, and `## Checks` in `RUN/00-run.md`. Fix small things yourself.
> Write `RUN/05-final-review.md` and update `ROOT/feedback/DECISIONS.md`. Reply 'final review
> written' with a one-paragraph summary.

Wait for the reply.

### Phase 6: commit

Unless `--no-commit`: `git add -A`, then commit with the message
`Review loop run NNN: <the final review's one-line summary>`, plus any attribution lines the
session's own instructions require. With `--review-only` the message is
`Review loop run NNN: reviews and plan only`. Push if `--push` or `CLAUDE_CODE_REMOTE` is
`true`: `git push -u origin <branch>`, retrying on network errors.

### The next iteration

Repeat Phases 0 to 6; each iteration has its own run directory. Iteration k's reviewers read
iteration k-1's final review and `DECISIONS.md`, so they check what changed and look further
instead of raising the same points.

## The final report to the user

One message after the last iteration, with:

- per iteration: the run directory and the commit; the findings by severity per reviewer; the
  packages done, partially done and not done (from `05-final-review.md`);
- the coordinator's questions and the assumptions used, or the answers given under `--ask`;
- the generated pages that need a local rebuild, with the exact commands from
  `## Needs a local render`, when the run could not render them;
- the check results (links, tests), including any failure the coordinator could not fix.

## Notes

- Subagents cannot spawn subagents. The coordinator plans, implements its own packages and
  reviews; the orchestrator dispatches. That is the only departure from "agent 4 fans out the
  work".
- The cloud container has Python, Node and a Playwright Chromium, but no R and no Quarto. Edits
  to `.qmd`, `.Rmd` and the comparison templates are made at the source, and the committed
  rendered pages lag until the author rebuilds locally; `needs_render.py` lists the commands.
  On a machine with R and Quarto, Phase 4 rebuilds them inside the run.
- Reviewers never edit the pages. Implementers never commit. The coordinator may make small
  fixes in Phase 5. Only the orchestrator commits.
- Cost, with the defaults: three xhigh reviews of about 70,000 words of pages, one xhigh
  coordinator that continues through implementation and review, and one xhigh implementer per
  package (typically 4 to 8). `--review-only` shows the plan before paying for implementation.
