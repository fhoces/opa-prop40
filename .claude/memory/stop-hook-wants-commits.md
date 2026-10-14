---
name: stop-hook-wants-commits
description: The author's stop hook refuses an idle turn with uncommitted files; commit finished units by path while background agents are still editing
metadata:
  type: feedback
---
The author's `~/.claude/stop-hook-git-check.sh` fires at every turn end and asks for a commit
and push whenever the tree has modified or untracked files.

**Why:** during a review-loop run several background agents edit disjoint files for many
minutes, and `git add -A` would snapshot half-made edits of packages still in progress.

**How to apply:** commit by explicit path, only the files of a package or review that has
reported done, and push after each such commit. Leave the in-progress files uncommitted and
say so in one line when the hook complains. Commit the run directory's setup files right after
creating them.
