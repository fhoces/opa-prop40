# Global inbox

Lessons that are not about this project. A session on the user's own machine moves them into
global memory and clears them here.

## 2026-10-14 from opa-prop40

- Subagents spawned with the Agent tool have no Agent tool themselves. A "coordinator fans out
  to workers" design must put the fan-out in the orchestrating session: the coordinator writes a
  plan with disjoint file ownership per package, the orchestrator spawns one worker per package,
  and the coordinator is continued by SendMessage for its own packages and the final review so it
  keeps its context across phases.
- A cloud session cannot send cross-session messages, even when it receives them. Put anything a
  local session needs in the repo (a digest file, a handoff file) and say in the reply that the
  message could not be sent.
- In the cloud container, Playwright lives at `/opt/node-tools/node_modules/playwright` and must
  be loaded with CommonJS `require`; an ESM `import` of that path fails. Headless Chromium works
  for screenshots of local html and for `document.body.innerText`, which is the only way to
  review text a page fills by script.
- When a stop hook demands a commit at every turn end while background agents are still editing,
  commit finished units by explicit path and leave the rest; `git add -A` snapshots half-made
  edits.
- When a generator (R, Quarto) cannot run in the environment, edit the source and make the
  identical edit in the generated page, keeping filled values, then list the exact rebuild
  commands from the changed files so the next machine reproduces the page byte for byte. Say
  which test suites will fail until then.
- Parallel reviewer agents should write to disjoint output files in a run directory, and a
  one-line digest with file, line, defect and fix is what a peer session can use directly.
