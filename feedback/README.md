# Feedback: the review loop's record

The numbered directories, `NNN-YYYY-MM-DD/` with a short suffix from 004 on, hold one review each,
in order. A loop run (`.claude/skills/opa-review-loop/`: 001, 002, 003 and 010) holds the three audience
reviews (the original authors, outside policy experts, California voters), the coordinator's plan,
one report per work package, the coordinator's final review, and `00-run.md` with the commit the
iteration started from, the arguments, the checks and the generated pages that still need a local
rebuild. The other directories are not loop runs: 004 (consistency of numbers and language) and
005 (the comparison explorer's readability) are focused reviews with their improvements; 006 holds
the seed-spread script behind JR note 9 and its report, and 007
applies the reproduction standard to the BSZ notes; 008 and 009 are the survey's two pretests with
simulated respondents; 011 is the review of the survey's pre-analysis plan and 012
the final review before launch; `credit-interview-2026-10-15` and `scenario-tests-2026-10-15` are
the author's own records.

`DECISIONS.md` lists the items the loop settled as "won't do", with the reason, so later
iterations do not raise them again. A review made in the cloud ends with a file for the local
session: the rebuilds to run, the questions to put to the author one at a time, and the
follow-ups. Its name is the last numbered file in the directory and `00-run.md` (or `00-brief.md`)
names it: `07-handoff-local.md` in run 001 (after `06-digest.md`), `06-handoff-local.md` in review
011, `05-handoff-local.md` in review 012, which stopped early.

Run the loop from a Claude Code session at the repository root:

```
/opa-review-loop                                    # one iteration, the defaults
/opa-review-loop --iterations 2                     # two
/opa-review-loop --review-only                      # reviews and plan, no page changes
/opa-review-loop --impl-model sonnet --impl-effort high
/opa-review-loop --ask                              # answer the coordinator's questions before implementation
```

In the cloud the container has no R and no Quarto, so edits to Quarto pages, decks and the
comparison templates wait for a local rebuild; `00-run.md` lists the commands. On a machine
with R and Quarto the loop rebuilds them in the run.
