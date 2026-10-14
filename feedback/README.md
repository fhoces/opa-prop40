# Feedback: the review loop's record

One directory per iteration of the review loop (`.claude/skills/opa-review-loop/`), numbered in
order: `NNN-YYYY-MM-DD/`. Each holds the three audience reviews (the original authors, outside
policy experts, California voters), the coordinator's plan, one report per work package, the
coordinator's final review, and `00-run.md` with the commit the iteration started from, the
arguments, the checks and the generated pages that still need a local rebuild.

`DECISIONS.md` lists the items the loop settled as "won't do", with the reason, so later
iterations do not raise them again.

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
