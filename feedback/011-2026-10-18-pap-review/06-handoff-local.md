# Handoff to the local session: PAP review 011, 2026-10-18

For the Claude Code session on the author's machine, which has LaTeX, Chrome, R and Quarto. Work
through this with the author at the keyboard, one part at a time, in order. Part 1 needs no
decision and rebuilds the two PDFs. Part 2 is the author's decisions, asked one at a time. Part 3
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

**Files changed** (all under `comparison/survey/`): `PRE-ANALYSIS-PLAN.md` (563 to 740 lines),
`registry-draft.md`, `power/power.tex` (text only, no number or table), `power/sim.py` (one
comment). Not changed: the forms, the site, `pilot_analysis.py`, `plan.tex`, `plan-body.tex`,
`plan.pdf`, `power.pdf`, anything in `power/out/`. The pandoc step of `build.sh` was run in the
cloud on the edited plan and passes. No em-dash or en-dash anywhere in the edited files.

**Untouched on purpose.** The title (line 1), the status line's registration date, the S3
definition (section 5.3 and 6.1), and every decision listed in the brief.

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
  optional answers are reported with the share of each arm that opted in. S3's text is unchanged.
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
  rate; the count's failure criterion. If the checks show differential attrition, no correction
  is applied and the submission rates are reported beside H1 (the fallback sentence; see Part 2,
  item 2). Emails compared after trimming and lower-casing, earliest kept; why the forms require
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

## Part 2: the author's decisions, one at a time

Each item gives the finding, the options and a recommendation. The paste-ready text for every
option is in `05-applied.md`, section "For the author".

1. **What S3 tests** (01-1 and 02-1, severity A, both AUTHOR DECISION; 04-7 is the same issue).
   The plan's section 5.3 defines S3 as "three indicators (BSZ value, JR value, neutral answer)"
   and section 6.1 adjusts "within each answer type", which reads as fifteen tests in three
   families. The power appendix (`sim.py` line 284, `out/thresholds.tex` row 1), the registry
   draft ("each of the five questions separately"), `pilot_analysis.py` and the plan's own section
   6.3 ("the five questions of S3") all treat S3 as one family of five tests on the coded answer
   $y_{ik}$. The tier-1 threshold of 150 responses was simulated for five tests. Options: (a) five
   tests on $y_{ik}$, one Romano-Wolf family, with the three answer shares reported descriptively
   by arm; (b) fifteen indicator tests in three families, which needs tier 1 re-simulated before
   registration. Recommendation: (a). It is what every other document and the code implement,
   and the "three indicators" wording looks like a residue of the per-question multinomial
   outcomes dropped on 2026-10-18. Apply the three replacements in `05-applied.md` (two in the
   plan, one in the registry draft).
2. **Differential attrition** (03-1, severity A, and 01-9, both AUTHOR DECISION). The attrition
   checks are reported but had no registered consequence. The implementer applied the
   non-decision fallback: no correction, H1 read as the effect among respondents who complete the
   form they drew, submission rates reported beside it. Options: keep the fallback; or replace it
   with Lee (2009) trimming bounds, computed within each entry point when the arms' submission
   rates differ at the 5% level, reported without a test below 50 responses per arm.
   Recommendation: add the bounds. Quitting on the comparison page is the one way the treatment
   can bias H1, the bounds are the standard pre-specified answer, and they cost one paragraph and
   one standard routine. With few responses they will be wide, which is itself the honest
   report. Keeping the fallback is defensible if the author wants the plan minimal.
3. **Very small samples** (01-8, severity B, AUTHOR DECISION). H1 is "tested whatever the number
   of responses", but the appendix verified the test's level only from 30 responses, and a
   stratum with responses in one arm only is not covered. Options: adopt the rule (drop a
   one-arm stratum from the H1 equation and report the count; below 30 responses, take the
   p-value from randomization inference, 10,000 re-draws of T within strata, and report the HC2
   estimate and interval as well); or leave as is. Recommendation: adopt. The expected range of 0
   to 200 makes fewer than 30 responses likely, the stratum rule is mechanical, and
   randomization inference is exact under the null at any N.
4. **Bots that vary their answers** (03-9, severity C, AUTHOR DECISION). The bulk rule catches
   only identical bursts. Options: add a robustness report of H1 without the submissions of any
   hour in which one form received five or more while its pair received none, with the hours and
   forms reported; or decline, since the bulk rule and the per-arm count check exist.
   Recommendation: add it. It is cheap, pre-specified and reported, not a change to H1.
5. **Data availability** (01-20, severity C, AUTHOR DECISION). The plan has no statement.
   Options: publish the responses without the email column and the free-text answers, plus the
   draw count, in the repository with the analysis; the same with the free text after a review
   for identifying detail; or no statement. Recommendation: the first, with the free text decided
   after the close, once the author has read it. The free text is the only place identifying
   detail can appear.
6. **The no-script fallback** (03-2's alternative, AUTHOR DECISION, a site change). Without
   JavaScript, every survey button and the share page lead to the `share` pair's control form,
   and a program reading the page finds that one address. The plan now documents this and its
   signature (form 5 with submissions above draws). Options: keep the site as it is; or make the
   fallback a sentence that the survey needs JavaScript, with no form address in the page's HTML,
   so that no-script visitors are lost rather than put into one arm. Recommendation: keep for
   launch. The plan documents the path, the site's tests pin page strings, and no-script humans
   are few. Revisit only if form 5 shows the signature during the window.
7. **The title** (04-23, severity C). "Salience of study information and credibility assessment
   of key assumptions and inputs" is a chain of nouns. Options: keep; or the reviewer's
   "Pre-analysis plan: a survey experiment on the salience of study information when respondents
   judge the credibility of disputed inputs". Recommendation: keep. It is the author's choice of
   2026-10-18, and `plan.tex` line 20 and the registry draft name it. If changed, change all
   three.

## Part 3: follow-ups and confirmations

1. **Fill the launch commit.** Section 9's Launch bullet carries "[commit hash, filled in at
   launch]". Fill it at step 6 of "How to launch" and put the same hash in the registry's "Other"
   field.
2. **The analysis code** (01-15 and 02-16). `comparison/survey/pilot_analysis.py` still computes
   S4 (`abs_lean`), and its design matrix (`const`, `E_explorer`, `E_share`, with `landing` as
   the base) is rank deficient with the two live entry points, so it would fail on real data.
   Remove S4, make the entry-point fixed effect a single `E_share` indicator, and add H5, the
   cell and tier-5 families, the staged rule, the deduplication and bulk rules of section 8, and
   the decisions of Part 2. Then add the "Analysis code" bullet from `05-applied.md` to section 9,
   so the script's version at the launch commit is the registered one. The second pretest's
   `report.qmd` (lines 85 and 145 to 146) also carries S4; remove it or leave the pilot outputs as
   a record.
3. **Values the implementer chose** where the plan gave none. Each is the reviewer's proposal;
   change any before registration: close at 23:59 Pacific time on 4 November 2026 (section 9 and
   the registry draft); "after the vote" is a timestamp after 20:00 Pacific time on 3 November
   2026, when California's polls close (section 9); Romano-Wolf seed 20261017 (section 6.3); the
   draw count fails for an entry point if it recorded no draw on a day with submissions for that
   entry point, or if a form has more submissions than draws (section 8); the robustness
   specification's bases are "No" for expertise and "No" for prior exposure, with the
   after-the-vote indicator dropped if no response comes after the vote (section 6.1).
4. **A commitment to confirm.** Section 7 now says that at the close `sim.py` is rerun once with
   the realized shares and the regenerated `out/thresholds.tex` is committed. This spells out what
   `power.tex` already said ("At the close all rows are recomputed at the realized shares"). The
   constants are `P_EXPL` and `SHARES0` (line 47 to 48) and `P_H5` (line 551). Confirm, or cut
   the sentence and let the registered thresholds govern throughout.
5. **Confirmations the reviewers asked for.** That the email is used for nothing but duplicates
   and the separate report (Ethics bullet, section 9). That "one analysis's count of the wealth
   that left but the other analysis's rule for which income tax is lost" is the intended meaning
   of the share-lost sentence (section 4.4). Whether the status line may carry the expansion of
   "AEA RCT Registry" (it was placed in section 9 because the brief said to leave line 10 alone).
6. **The registry's private draft** (trial 19997). Re-enter the fields that changed in
   `registry-draft.md`: Trial end date, Minimum detectable effect size, Analysis plan documents,
   Other, and Secondary outcomes if Part 2 item 1 changes S3. Attach the rebuilt `plan.pdf` and
   `power.pdf`.
7. **Branches.** `claude/optimistic-ramanujan-okbezb` stays at the brief (4b94536) and can be
   deleted after the merge. Never force-push `review/pap-2026-10-18`.
