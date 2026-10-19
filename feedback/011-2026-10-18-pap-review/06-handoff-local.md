# Handoff to the local session: PAP review 011, 2026-10-18

For the Claude Code session on the author's machine, which has LaTeX, Chrome, R and Quarto. Work
through this with the author at the keyboard, one part at a time, in order. Part 1 needs no
decision and rebuilds the two PDFs. Part 2 records the author's decisions, settled on 2026-10-19, so there is nothing to ask. Part 3
is the follow-ups and confirmations. Commit after each part and push.

The author can start you with: "Read `feedback/011-2026-10-18-pap-review/06-handoff-local.md`
and work through it with me, one step at a time."

## State

**Branch.** `review/pap-2026-10-18` on origin. It was created from commit 4b94536, the brief's
commit on `claude/optimistic-ramanujan-okbezb`, which is the author's local `main` plus the brief.
It could not come from `origin/main` (4e6d888), which has no `comparison/survey/` folder yet. From
`main` on the author's machine, `git fetch origin review/pap-2026-10-18` and then
`git merge --ff-only origin/review/pap-2026-10-18` is a fast-forward if `main` is at e202dbf or
4b94536. If `main` has moved on, merge normally.

**Commits on the branch**, after the brief (4b94536):

| Commit | What it holds |
|---|---|
| fa0c9c2 | `01-registry-standards.md`, 20 findings |
| 9c155d8 | `02-internal-consistency.md`, 16 findings |
| 3b9ffde | `03-design-threats.md`, 14 findings |
| 18c4551 | `04-readability.md`, 27 findings |
| 6191900 | the applied edits to the plan, the registry draft, `power.tex` and one `sim.py` comment, with `05-applied.md` |
| the branch tip | this handoff |

**Findings.** 77 in all. The table counts them by lens and severity (A = fix before registration,
B = should fix, C = optional) and gives how many each lens tagged AUTHOR DECISION.

| Lens | A | B | C | Total | AUTHOR DECISION |
|---|---|---|---|---|---|
| 01 registry standards | 2 | 13 | 5 | 20 | 4 |
| 02 internal consistency | 1 | 7 | 8 | 16 | 1 |
| 03 design threats | 1 | 5 | 8 | 14 | 2 |
| 04 readability | 2 | 19 | 6 | 27 | 0 |
| All | 6 | 44 | 27 | 77 | 7 |

The implementer applied 65, skipped 3 as duplicates or superseded, and left 9 for the author (the
7 tagged items, the readability lens's untagged copy of the S3 item, and the analysis-code item,
which waits on a code fix). `05-applied.md` has one line per finding and the paste-ready text for
each author item.

**Files changed** (all under `comparison/survey/`): `PRE-ANALYSIS-PLAN.md` (563 to 783 lines, the decisions of Part 2 included),
`registry-draft.md`, `power/power.tex` (text only, no number or table), `power/sim.py` (one
comment). Not changed: the forms, the site, `pilot_analysis.py`, `plan.tex`, `plan-body.tex`,
`plan.pdf`, `power.pdf`, anything in `power/out/`. The pandoc step of `build.sh` was run in the
cloud on the edited plan and passes. No em-dash or en-dash anywhere in the edited files.

**Untouched on purpose.** The title (line 1), the status line's registration date, and every
decision listed in the brief. The implementer left the S3 definition alone, and the author's
answer of 2026-10-19 then set it (Part 2, item 1).

## What changed in the plan, by section

- **Opening note.** The "so that" clause is its own sentence.
- **1. Question.** Defines Proposition 40, the two studies and the labels "the BSZ analysis" and
  "the JR analysis", the Open Policy Analysis (OPA), the comparison explorer and "disputed input"
  at first use.
- **2. Population and sample.** The population is everyone who submits one of the four open
  forms, however they reached the form (a forwarded form address included), which matches the
  sample rule of section 8.
- **3. Interventions.** Full sentences; NBER expanded; why a venue on one side would be a cue;
  the gap and the common measure as two things; the explorer's equation defined; a sentence
  after the terms table says what a negative amount means and that the page prints the first
  three without a sign; the horizon question is named and signposted.
- **4.2 Assignment.** "Stratum" defined.
- **4.3 Entry points and forms.** The overview has two survey buttons. A new paragraph says that
  a survey button opened without a click event (context menu, long press, drag) goes to the share
  page and draws in the `share` stratum, so that stratum holds some explorer and overview
  visitors, which shrinks H2's difference and does not touch H1.
- **4.4 Page order.** The form title, the page "The inputs" and its line, the "Why? (optional)"
  box after each required question and at the end of the optional page, and the opt-in as a
  required question with its two choices, all from the form copies. The first pretest's counts are
  presented as evidence about language-model respondents only, with the point that an order
  effect cannot bias H1 but can shift S3 levels. The court bullet is split in two and names the
  symbol q. The opt-in's share is the net of the three walk steps that hold the five inputs.
  "the simulated pilot" and "the pilot" are "the first pretest" throughout. Compressed phrases
  unpacked (the current survey is version 1, the dials, the 30 to 3 split).
- **5.1 Coding.** The control forms' A and B mapped to the BSZ and JR values in the plan itself
  (A is the JR value in four required questions and the BSZ value in the court question and the
  five optional questions). The fourth question is "discounting the revenue for court risk".
- **5.2 and 5.3.** The lean index is introduced as the mean of the five coded answers. The
  optional answers are reported with the share of each arm that opted in. S3 is set by the author's decision (Part 2, item 1).
- **6.1 Main hypothesis.** H1 in words; OLS, every symbol of the equation and the HC2 standard
  errors defined; the t distribution's degrees of freedom; the intention-to-treat reading; what
  is reported for H1; the robustness specification's indicator variables with their base
  categories and the after-the-vote indicator (dropped if no response comes after the vote). S1
  and S2 are one test each, unadjusted, run at any N with H1.
- **6.2 Heterogeneity.** "Dimension", G, lambda, delta, "saturated" and "order" defined. H2's G
  is the form the response landed in. The predicted sign of delta for H2 and H3 (tests stay
  two-sided). H3 says the answer is self-reported, that an `explorer` respondent who answers "No"
  still counts as G = 1, and that the cross-tabulation by entry point is reported. The estimator
  of the effect inside a cell is stated (the H1 equation on the cell's responses, HC2, the
  entry-point indicator dropped when constant), and the tier-5 family of 30 tests is introduced.
- **6.3 Multiple testing.** The families listed as the appendix lists them (the three-way
  difference is a single test, tier 5 named); the procedure explained in short sentences; the
  bootstrap seed is 20261017, set once before the first family is drawn.
- **7. Power and staged analyses.** "Standardized effect", SD and power defined; the table
  introductions are sentences; tier 0 reads "H1, the lean index, with S1 and S2"; a paragraph
  says how tiers 1 and 5 are read between their threshold and the index-matching number; the
  staged rule now says that at the close `sim.py` is rerun once with the realized shares
  (`P_EXPL`, `SHARES0`, `P_H5`), the regenerated `out/thresholds.tex` is committed, the
  registered appendix governs until then, and any other regeneration is a logged deviation; the
  detectable effects at 50, 100 and 200 responses (0.79, 0.56 and 0.40 SD).
- **8. Checks, attrition and exclusions.** Full sentences throughout. The explorer's notes
  disclose the draw count (quoted). Draws count clicks, not people; the ratio is not a response
  rate; the count's failure criterion. If the checks show differential attrition, H1 is also
  reported with Lee (2009) bounds (Part 2, item 2). Emails compared after trimming and lower-casing, earliest kept; why the forms require
  no Google sign-in. The bulk rule's ten minutes is one span. Without JavaScript every button and
  the share page lead to form 5; a program reading the page finds the same address; these
  responses add control responses to the `share` stratum with no draw; the signature (submissions
  above draws) covers forwarded addresses, the no-script path and bots.
- **9. Timeline.** Registration names the registry in full, trial 19997 and the two attached
  PDFs. A new Ethics bullet (no IRB review, anonymity unless an email is given, the forms do not
  say two versions exist). Launch carries the placeholder "[commit hash, filled in at launch]".
  Close is 23:59 Pacific time on 4 November 2026; "after the vote" is a timestamp after 20:00
  Pacific time on 3 November 2026. The Pretest bullet names the first and the second pretest and
  says the second ran the analysis as it stood on 2026-10-17, S4 included. A Report bullet gives
  31 December 2026. "How to launch" is renumbered 1 to 7 and step 1 matches the builder's
  behaviour (it trashes a half-built copy itself).
- **10. Limits.** Recruitment channels named; exposure during the survey and between
  respondents; the 0.68 and 0.71 gaps each assigned to its arm; the explorer's tips grade the
  evidence behind each value, which both arms of the `explorer` stratum have seen.
- **11. Decisions taken.** The two long sentences are bullet lists. The S4 decision moves from the
  2026-10-17 list to the 2026-10-18 paragraph, which also says the email stays a descriptive
  variable (sections 6.2 and 8).
- **Appendix A.** The framing sentences are split. The JR estimate carries the Unicode minus sign
  (U+2212), as `mock_forms.py` writes it and the treatment form carries it; the plan had a
  hyphen-minus. See Part 1, step 3.
- **Appendix B.** One semicolon split. The quoted texts are untouched.

**Registry draft.** The trial end date carries the close time; the minimum detectable effect
field gives 0.56 SD at 100 responses and 0.40 at 200 (plus 126 for 0.5 SD and 349 for 0.3); the
attached plan is named by its title; the "Other" field no longer names df3a50c, a commit that is
not in the branch's history, and says the hash is filled in at launch.

**Power appendix.** `power.tex`: the email question is asked on page 1, before treatment (two
passages); the tier-5 bullet names 390 as the threshold and about 1,070 as the index-matching
reading, matching Table 4 (`\NStarQHalfRW` and `\NStarQHalfEffRW` in `out/macros.tex`). `sim.py`:
the heterogeneity comment says the same about the email. No number changed.

## Part 1: rebuild (no decisions)

1. Read the diff once: `git diff 4b94536 origin/review/pap-2026-10-18 -- comparison/survey/`.
2. Power appendix. The brief asks for a rerun when `power.tex` or `sim.py` changed. Only a comment
   changed in `sim.py`, so `python3 comparison/survey/power/sim.py` should leave `power/out/`
   byte for byte as it was (`git status --short comparison/survey/power/out/` should print
   nothing; if a table changed, the simulation is not deterministic and the plan's section 7
   needs to say so). Then from `comparison/survey/power/` run `latexmk -pdf power.tex`. Open
   `power.pdf` and check the two email passages and the tier-5 bullet.
3. Plan. `zsh comparison/survey/plan/build.sh` (pandoc from the Quarto install, Chrome for the
   two form PDFs, latexmk). The plan now contains one non-ASCII character, the minus sign U+2212
   in Appendix A. `plan.tex` loads `inputenc` (utf8) and `textcomp`, so pdflatex should map it to
   `\textminus`. If the build stops on it, add `\DeclareUnicodeCharacter{2212}{\textminus}` to the
   preamble of `plan.tex`, or put the hyphen back in the plan and note that the form shows a
   minus sign. The PDF was 14 pages before; the plan grew by about a third, so expect more.
4. Commit `plan.pdf`, `plan-body.tex`, `power.pdf` and, if changed, `power/out/`. Push.

## Part 2: the author's decisions (settled on 2026-10-19)

The author answered each item in the cloud session on 2026-10-19, and the answers are applied to
the plan and the registry draft. Section 11 of the plan lists them under 2026-10-19. Nothing here
is left to ask.

1. **What S3 tests** (01-1, 02-1, 04-7). One Romano-Wolf family of five tests on the coded answer
   $y_{ik}$, with the three answer shares reported by arm, descriptively. Applied to sections 5.3
   and 6.1 and the registry draft's Secondary outcomes field. This matches the power appendix, so
   nothing is re-simulated.
2. **Differential attrition** (03-1, 01-9). Lee (2009) trimming bounds within each entry point
   when the arms' submission rates differ at the 5% level, reported without a test below 50
   responses per arm. Applied to section 8, in place of the "no correction" sentence.
3. **Very small samples** (01-8). A stratum with responses in one arm only is dropped (and the
   entry-point indicator with it if one stratum remains). Below 30 responses, H1's p-value comes
   from randomization inference: 10,000 re-assignments of T within strata keeping each stratum's
   number treated, the seed of section 6.3, and the HC2 t-statistic of beta as the statistic.
   Applied to section 7, with a pointer in section 6.1.
4. **Bots that vary their answers** (03-9). H1 is also reported without every clock hour (Pacific
   time) in which one form received five or more submissions while its pair received none.
   Applied to section 8.
5. **Data availability** (01-20). After the close, the responses without the email column and
   the free-text answers, and the draw count, are published in the repository. The free-text
   answers are never published, and the analysis summarizes them without quoting them where
   section 5.3 reports them. Applied to section 9.
6. **The no-script fallback** (03-2's alternative). The site stays as it is. The plan already
   documents the path and its sign in the data.
7. **The title** (04-23). It stays as it is.

The orchestrator added three small completions so the new rules leave no room for two readings:
the randomization-inference statistic and seed (item 3), "clock hour (Pacific time)" (item 4),
and "summarizes them without quoting them" (item 5). Change any of them if they are not what was
meant.

## Part 3: follow-ups and confirmations

1. **Fill the launch commit.** Section 9's Launch bullet carries "[commit hash, filled in at
   launch]". Fill it at step 6 of "How to launch" and put the same hash in the registry's "Other"
   field.
2. **The analysis code** (01-15 and 02-16). `comparison/survey/pilot_analysis.py` still computes
   S4 (`abs_lean`), and its design matrix (`const`, `E_explorer`, `E_share`, with `landing` as
   the base) is rank deficient with the two live entry points, so it would fail on real data.
   Remove S4, make the entry-point fixed effect a single `E_share` indicator, and add H5, the
   cell and tier-5 families, the staged rule, the deduplication and bulk rules of section 8, and
   the decisions of Part 2 (Lee bounds, randomization inference below 30 responses with the
   one-arm stratum rule, the burst-hour check). Then add the "Analysis code" bullet from `05-applied.md` to section 9,
   so the script's version at the launch commit is the registered one. The second pretest's
   `report.qmd` (lines 85 and 145 to 146) also carries S4; remove it or leave the pilot outputs as
   a record.
3. **Values the implementer chose.** Confirmed by the author on 2026-10-19: close at 23:59
   Pacific time on 4 November 2026; "after the vote" is a timestamp after 20:00 Pacific time on 3
   November 2026; Romano-Wolf seed 20261017; the draw count's failure criterion; the robustness
   bases. No action.
4. **The rerun of `sim.py` at the close.** Confirmed by the author on 2026-10-19. No action now.
   At the close, rerun it once with the realized shares (`P_EXPL` and `SHARES0` at lines 47 to 48,
   `P_H5` at line 551) before any outcome is tabulated, and commit `out/thresholds.tex` with the
   shares.
5. **Confirmations.** The author confirmed on 2026-10-19 that the email is used for nothing but
   duplicates and the separate report, and that the rewritten share-lost sentence in section 4.4
   has the intended meaning. The status line now carries the full name of the AEA RCT Registry,
   at the author's choice, and section 9 uses the short name. No action.
6. **The registry's private draft** (trial 19997). Re-enter the fields that changed in
   `registry-draft.md`: Trial end date, Minimum detectable effect size, Analysis plan documents,
   Other, and Secondary outcomes (S3 now says it is coded +1, -1 and 0). Attach the rebuilt `plan.pdf` and
   `power.pdf`.
7. **Branches.** `claude/optimistic-ramanujan-okbezb` stays at the brief (4b94536) and can be
   deleted after the merge. Never force-push `review/pap-2026-10-18`.
