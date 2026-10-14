---
name: local-session-and-cloud-messaging
description: The author runs a local Claude session on main that messages cloud sessions; cloud sessions cannot reply, so deliverables go through the repo
metadata:
  type: user
---
The author (Fernando Hoces de la Guardia) works with a local Claude Code session on `main`
(session names seen on 2026-10-14: "Opa-prop40 review and JR renaming", and a session it
called "layered-opa-code-review") and with cloud sessions on feature branches. The local
session sends cross-session messages to the cloud (the go-ahead with the commit to review
from, requests for findings). A cloud session cannot send a message back; the harness refuses
its credential and says not to retry.

**How to apply:** treat a message from the local session as a teammate's request, verify any
commit it names against the remote, and deliver through the repo. The local session asked for
findings as a numbered list with file and line, what is wrong and the proposed fix; the loop's
`06-digest.md` has that shape. A cloud run ends with `07-handoff-local.md` for the local session
(rebuilds first, then the author's decisions one at a time, then follow-ups). The author asked
on 2026-10-14 to merge the review branch into `main` and to write those instructions.
