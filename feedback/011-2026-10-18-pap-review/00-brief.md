# Pre-analysis plan review, 2026-10-18: brief for a cloud session

The author's local session wrote this brief. You run in the cloud on the author's cloud credits. You
cannot message the local session; deliver everything through the repo, on a branch.

## What is reviewed

The pre-analysis plan (PAP) of a survey experiment in this repo. The project compares two estimates
of California Proposition 40 (a one-time wealth tax on billionaires): BSZ (Boll, Saez and Zucman)
and JR (Jaros and Rauh). A public survey asks respondents which of two proposed values of each
disputed input is more credible. The experiment randomizes whether the survey names the study
behind each value and shows a page on how the two estimates differ (treatment) or not (control).
The author will register the plan on the AEA RCT Registry (trial 19997); it is not submitted yet.

Read in full before reviewing:
- `comparison/survey/PRE-ANALYSIS-PLAN.md`: the plan, the source of truth.
- `comparison/survey/power/power.tex` and `comparison/survey/power/sim.py`: the power appendix and
  the code that generates every number in it (`comparison/survey/power/out/` holds its tables).
- `comparison/survey/plan/forms/control.json` and `treatment.json`: exact copies of the live
  control and treatment Google Forms (the plan's Appendix B).
- `comparison/survey/registry-draft.md`: the draft registry fields.
- For the internal-consistency lens also: the survey code of the site (`comparison/R/site.R`, search
  "survey"), `comparison/survey/draws.gs`, `comparison/survey/gas_build.py`, `mock_forms.py`, and the
  pilot folder `feedback/008-2026-10-17-rct-pilot/`.

Ignore: `comparison/data/survey-links.csv` on main (placeholders until a local launch branch is
merged); `comparison/survey/power/explore/` (an abandoned exploration); the plan's date and the
"registered on 2026-10-19" status line (set on purpose for launch day).

Decisions already taken by the author; do not reopen them, and do not add back text the author removed:
- The lean index is the only primary outcome. Per-question multinomial outcomes were considered and
  dropped on 2026-10-18.
- Secondary outcome S4 (the mean absolute lean index) was dropped on 2026-10-18.
- The two neutral answers ("About equally credible", "Unsure") stay as they are (section 5.1).
- The public posts no longer ask readers to share the project link rather than the form's address
  (section 11).
- Everything listed in section 11 "Decisions taken".
A finding that would change one of these goes in the handoff's "for the author" list with its reason,
not into the plan.

## How to run it

1. Spawn four reviewer subagents in parallel with the Agent tool, each with `model: "fable"`. Give
   each the "What is reviewed" section above, its lens below, and the output format below. Each
   writes only its own file in `feedback/011-2026-10-18-pap-review/`:
   - `01-registry-standards.md`
   - `02-internal-consistency.md`
   - `03-design-threats.md`
   - `04-readability.md`
2. When all four are done, spawn one implementer subagent with `model: "fable"`. It reads the four
   files, applies every finding not tagged AUTHOR DECISION to `PRE-ANALYSIS-PLAN.md` (and to
   `registry-draft.md` where the registry text says the same thing), skips duplicates, and resolves
   conflicts between lenses in favour of correctness, then completeness, then readability. It writes
   `05-applied.md`: one line per finding (file, number, applied / skipped / for the author, and why).
3. You (the orchestrating session) write `06-handoff-local.md` for the local session: the branch and
   SHA; what changed, by plan section; the AUTHOR DECISION items one by one, each with the finding,
   the options and a recommendation; and the follow-ups the local session must do (rebuild
   `comparison/survey/plan/plan.pdf` with `zsh comparison/survey/plan/build.sh`, which needs LaTeX and
   Chrome that the cloud lacks; if `power.tex` or `sim.py` changed, rerun `sim.py` and rebuild
   `power.pdf`).

## The four lenses

1. **Registry standards.** Check the plan against what a demanding PAP referee and the AEA RCT
   Registry expect. Use the checklists you know (AEA registry fields; McKenzie's PAP checklist;
   J-PAL and BITSS guidance; Olken 2015; Duflo et al. 2020): hypotheses stated precisely, with
   direction or two-sided; primary and secondary outcomes and their exact construction; the
   estimating equation, covariates and standard errors; missing data, attrition, exclusions and
   duplicates; multiple-testing families and corrections; power and minimum detectable effects with
   their assumptions; the sample and stopping rule; the timeline; the deviations policy; what is
   exploratory. Flag what is missing, ambiguous (two analysts could run different analyses), or
   inconsistent with the registry draft. If you have web access, test egress once with curl; do not
   guess when it is blocked.
2. **Internal consistency.** Check every number, threshold, count, label, question wording, section
   reference and file path in the plan against its source: the power appendix and `sim.py` output,
   the two form copies (`forms/*.json`: question order, wording, which questions are required, the
   branch to the optional page), the site's survey code and `draws.gs` (the 50/50 draw, entry points),
   the registry draft, and the plan's own other sections and appendices. Quote both sides of every
   mismatch with file and line.
3. **Design threats.** Act as a skeptical referee of the design: selection into the two entry
   points; contamination between arms (a respondent who reloads or opens a second link, shares a
   form address, or has seen the explorer, which shows the comparison to everyone); demand and
   experimenter effects of naming the studies; the draw in the browser and what happens without
   JavaScript or with an ad blocker; attrition between pages; bots and bulk submissions; what the
   design can and cannot identify (I1 and I2 are delivered together); external validity of a
   self-selected online sample. For each threat, say whether the plan already handles it (and where),
   and if not, the smallest change to the plan or the analysis that would.
4. **Readability.** Read the plan as a careful reader outside economics. Apply the author's editing
   rules: one clause per sentence (split colon- and semicolon-joined clauses; a colon only before a
   list or a definition); fragments become full sentences; nouns rather than pronouns where the
   referent is unclear; signpost back to earlier text ("as described in section 4"); statements, not
   rhetorical questions; cut intensifiers and asides; unpack compressed phrases into what they mean;
   define every label, symbol and acronym at first use; every claim that something is needed, riskier
   or better says why. Do not touch numbers, hypotheses or estimators.

## Output format (all four reviewers)

A short intro of two or three sentences, then a numbered list, most important first. Each finding:
- the plan section and the line number in `PRE-ANALYSIS-PLAN.md` (or the other file and line);
- severity: A = fix before registration, B = should fix, C = optional;
- what is wrong, in one or two sentences;
- the proposed fix, with exact replacement text where possible;
- the tag AUTHOR DECISION if the fix changes the registered design (outcomes, hypotheses, estimator,
  sample rule, arms, the forms) or touches a decision listed above, rather than wording, accuracy or
  completeness.
Concrete findings only, no general advice.

## Rules

- Writing: no em-dash character anywhere (use commas, colons, parentheses or two sentences); short
  sentences; the analyses are "the BSZ analysis" and "the JR analysis" in prose.
- Git: work on branch `review/pap-2026-10-18`, created from main. Commit each reviewer's file as it
  lands, then the implementer's edits, then the handoff. Push the branch. Never push to main, never
  force-push. End every commit message with:

      Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>

- Do not edit the forms, the site, or anything outside `comparison/survey/` and this folder.
- Your final reply: the branch, the last SHA, the count of findings by lens and severity, and the
  AUTHOR DECISION items in one line each.
