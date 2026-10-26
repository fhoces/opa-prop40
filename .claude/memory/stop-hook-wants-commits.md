---
name: stop-hook-wants-commits
description: Cloud sessions on this repo have a stop hook that refuses an idle turn with uncommitted files; the local machine has no such hook. Either way, commit finished units by path while background agents are still editing
metadata:
  type: feedback
---
Cloud sessions on this repo (run 001, 2026-10-14) ran under a stop hook, `~/.claude/stop-hook-git-check.sh`
in the cloud container, that fires at every turn end and asks for a commit and push whenever the
tree has modified or untracked files. The author's local machine has no hooks configured at all
(checked 2026-10-26: no hooks in the settings cascade, no hook runs in any local transcript), so a
local session will not see the complaint.

**Why:** during a review-loop run several background agents edit disjoint files for many
minutes, and `git add -A` would snapshot half-made edits of packages still in progress.

**How to apply:** commit by explicit path, only the files of a package or review that has
reported done, and push after each such commit. Leave the in-progress files uncommitted and,
when the hook complains, say so in one line. Commit the run directory's setup files right after
creating them. Locally the same by-path discipline applies without the prompt.
