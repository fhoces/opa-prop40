# PAP review, 2026-10-18: what was applied

The implementer applied every finding of the four reviews that was not tagged AUTHOR DECISION to `comparison/survey/PRE-ANALYSIS-PLAN.md`, to `comparison/survey/registry-draft.md` where the registry text says the same thing, and, for three text-only appendix fixes that change no number, to `comparison/survey/power/power.tex` and one comment in `comparison/survey/power/sim.py`. The pandoc check of the plan (`markdown+pipe_tables` to LaTeX, as `build.sh` runs it) passes, with the five pipe tables, the footnote and all math intact. The em-dash and en-dash check finds no hit in any of the four files touched, and the only non-ASCII character in the plan is the Unicode minus sign in Appendix A, which the page generator writes (finding 04-27).

Of the 77 findings, 65 were applied (one of them, 04-3, in part), 3 were skipped as duplicates or superseded, and 9 are for the author.

## Values chosen

Concrete values the plan did not give and an untagged fix needed. Each is the reviewer's proposal; the author can change them before registration.

- Close time: 23:59 Pacific time on 4 November 2026, when the four forms stop accepting responses (section 9, "Close"; also the registry draft's "Trial end date" field). From 01-10.
- "After the vote": a submission timestamp after 20:00 Pacific time on 3 November 2026, when California's polls close (section 9, "Close"). From 01-10.
- Romano-Wolf seed: 20261017, the seed of the second pretest's analysis (`feedback/009-2026-10-17-rct-pilot-2/analysis/settings.csv`), set once in the analysis script before the first family is drawn (section 6.3). From 01-7.
- Failure criterion of the draw count: the count fails for an entry point if it recorded no draw on a day on which that entry point's forms received submissions, or if either of its forms has more submissions than draws (section 8, "Attrition"). From 03-4.
- Base categories of the robustness specification: "No" for expertise (indicators for "Yes" and "Somewhat") and "No" for prior exposure (indicators for "Yes" and "Not sure"); the after-the-vote indicator is dropped if every response was submitted before the vote (section 6.1). From 01-3.
- Launch commit: a placeholder "[commit hash, filled in at launch]" now sits in section 9, "Launch", to be filled at step 6 of "How to launch"; the registry draft's "Other" field refers to it (from 02-3, 01-19 and 04-12).

## Files changed

- `comparison/survey/PRE-ANALYSIS-PLAN.md`: 65 findings applied across sections 1 to 11 and the appendix framings; the title, the status line, the S3 definition and every author decision are untouched; the file grows from 563 to 739 lines.
- `comparison/survey/registry-draft.md`: close time added to the trial end date, the minimum detectable effect field rewritten with the detectable effects at 100 and 200 responses, the attached plan named by its title, and the "Other" field no longer names the non-existent commit df3a50c.
- `comparison/survey/power/power.tex`: text only, no number or table changed; the email question is now described as asked on page 1 before treatment (two passages), and the tier-5 bullet names 390 as the threshold and about 1,070 as the index-matching reading (verified against `out/macros.tex`: `\NStarQHalfRW` = 390, `\NStarQHalfEffRW` = 1,070). The local session rebuilds `power.pdf`.
- `comparison/survey/power/sim.py`: one comment (the email question is asked before treatment but is not a registered dimension); no code changed, the file still parses.

Not changed: the forms, the site, `pilot_analysis.py`, `plan.tex`, `plan-body.tex`, `plan.pdf`, `power.pdf`, anything in `power/out/`.

## Findings, one line each

### 01, registry standards

- 01-1: for the author. AUTHOR DECISION on what S3 tests (one family of five tests on the coded answer, or three families of indicator tests); lines 241 and 266-267 and the registry draft's S3 field are untouched.
- 01-2: applied. Section 7: the staged rule now says `sim.py` is rerun once at the close with the realized shares (its constants `P_EXPL` and `SHARES0`), the regenerated `out/thresholds.tex` is committed with the shares, the registered appendix governs until then, and any other regeneration is a logged deviation.
- 01-3: applied. Section 6.1: the robustness specification now names its indicator variables, their base categories and the after-the-vote indicator of section 9, dropped if no response comes after the vote; also covers 02-7.
- 01-4: applied. Section 6.2: the estimator of the effect inside a cell (the H1 equation on the cell's responses, HC2, the entry-point indicator dropped when constant) and the tier-5 family of 30 tests are stated; combined with 02-4 without repetition.
- 01-5: applied. Section 6.1 says S1 and S2 are one test each, unadjusted, run at any N with H1, with H1's minimum detectable effect in their own units; the tier-0 row of Table 4 reads "H1, the lean index, with S1 and S2".
- 01-6: applied. Section 7: a paragraph after the 2b note says what is done between 150 and about 400 responses for tier 1 and between 390 and about 1,070 for tier 5; `power.tex` lines 445-447 now name 390 as tier 5's threshold and 1,070 as the index-matching reading (needs the `power.pdf` rebuild).
- 01-7: applied. Section 6.3 gives the seed 20261017 (see "Values chosen").
- 01-8: for the author. AUTHOR DECISION: a rule for very small samples (dropping single-arm strata, randomization inference below 30 responses).
- 01-9: skipped. Duplicate of 03-1 (the same Lee-bounds proposal); the non-decision fallback sentence of 03-1 is applied.
- 01-10: applied. Section 9, "Close": the close time and the "after the vote" timestamp (see "Values chosen"); the registry draft's trial end date carries the close time.
- 01-11: applied. Section 5.1 now gives the A/B to BSZ/JR mapping of the control forms in the plan itself (verified against `control.json`: A is the JR value in four required questions, the BSZ value in the court question and in all five optional questions); the Key tab is mentioned as carrying the same mapping.
- 01-12: applied. Registry draft's minimum detectable effect field gives 0.56 SD at 100 and 0.40 SD at 200 responses; section 7 adds the 0.79, 0.56 and 0.40 figures (verified against `out/macros.tex`).
- 01-13: applied to `power.tex` (lines 155-156 and the Email paragraph) and the `sim.py` comment: the email question is asked on page 1, before treatment, and is descriptive because it is not a registered dimension; the same edit covers 02-2. Needs the `power.pdf` rebuild.
- 01-14: applied. Section 9: an "Ethics" bullet after "Registration" (no IRB review, anonymity unless an email is given, the forms do not say that two versions exist, nothing false in either version). Author to confirm the email is used for nothing else.
- 01-15: for the author. The script named (`pilot_analysis.py`) does not yet match the plan (it still computes S4 and its design matrix is rank deficient without the dropped `landing` entry point), so no "Analysis code" bullet was added; fix the script first, then add the bullet (text below).
- 01-16: applied. Section 6.1: the t distribution with N minus the number of regressors degrees of freedom (what `pilot_analysis.py` and `sim.py` use), the intention-to-treat reading, and what is reported for H1.
- 01-17: applied. Section 6.2: the predicted sign of the interaction for H2 (opposite to beta, smaller than 2|beta|) and for H3 (same sign as beta), both tests staying two-sided.
- 01-18: applied. Section 8: emails compared after trimming spaces and lower-casing, the earliest by timestamp kept; the bulk rule's ten minutes is one span containing all the timestamps.
- 01-19: applied. Section 9: the registration bullet names trial 19997 and the two attached PDFs, the launch bullet records the hash on launch day and in the registry's "Other" field, a "Report" bullet gives 31 December 2026; the registry draft's "Other" field no longer names df3a50c. Combined with 02-3.
- 01-20: for the author. AUTHOR DECISION: a data-availability statement (publishing the responses without the email column and free text, and the draw count).

### 02, internal consistency

- 02-1: for the author. AUTHOR DECISION, the same S3 issue as 01-1; nothing changed at lines 241 and 266-267.
- 02-2: applied to `power.tex` and the `sim.py` comment (see 01-13); no number changed, `power.pdf` needs a text-only rebuild.
- 02-3: applied. Section 9, "Launch", and the registry draft's "Other" field; combined with 01-19 (and 04-12's placeholder).
- 02-4: applied. Section 6.3 lists the families as the appendix does (the three-way difference is a single test, the tier-5 family of 30 is named); section 6.2 introduces the tier-5 family once, in the cell-estimator paragraph of 01-4.
- 02-5: applied. Section 4.3's table names the overview's two survey buttons; H2's G is defined by the form the response landed in; section 8 states that a button opened without a click event goes to the share page and that the entry point in the data is the form, not the button, with the `site.R` function names.
- 02-6: applied. Section 4.4 now names the form title, the page "The inputs" and its line, the "Why? (optional)" boxes after each required question and at the end of the optional page, and the opt-in as a required question with its two choices (verified against both form copies).
- 02-7: skipped. Duplicate of 01-3, applied with 01-3's fuller text.
- 02-8: applied. Section 11: the S4 clause moved out of the 2026-10-17 list into the 2026-10-18 paragraph, with "the secondary outcomes are S1 to S3 (section 5.3)"; combined with 04-13's reformatting.
- 02-9: applied. Every pretest reference now says "the first pretest" (all quoted numbers are from it) or "the second pretest", and section 9's "Pretest" bullet defines both names; combined with 04-14.
- 02-10: applied. Section 3: the signs stay in the table and a sentence after it says what a negative amount means and that the page prints the first three without a sign; the table's introducing fragment is rewritten (combined with 04-8).
- 02-11: applied. Section 4.4: "Its first paragraph ends with a sentence of motivation".
- 02-12: applied. Section 4.4: the opt-in's share is the net of the three walk steps that hold the five inputs (the list, avoidance, the three minor inputs as one step) over the gap, as `mock_forms.py` computes it.
- 02-13: applied. Section 9, step 1 of "How to launch": run the builder again; it trashes a half-built copy and rebuilds it, and skips a finished form (as `gas_build.py` does).
- 02-14: applied. Section 5.1: "discounting the revenue for court risk".
- 02-15: applied. Registry draft: the attached plan is named by its title.
- 02-16: applied. Section 9: the second pretest ran the analysis "as it stood on 2026-10-17, which still included the later-dropped secondary outcome S4". The `pilot_analysis.py` and `report.qmd` part is for the author.

### 03, design threats

- 03-1: for the author (Lee bounds); fallback sentence applied. AUTHOR DECISION on adding trimming bounds; the non-decision sentence ("If the checks show differential attrition, no correction is applied. H1 is then read as the effect among respondents who complete the form they drew, and the submission rates by arm and entry point are reported beside it.") sits after the attrition checks in section 8.
- 03-2: applied. Section 8, "Links that skip the draw": without JavaScript every button and the share page lead to form 5, a program that reads the page without scripts finds only that address, these responses add control responses to the `share` stratum with no draw, and the data signature covers forwarded addresses, the no-script path and bots. The alternative (a site change to the no-script fallback) is for the author.
- 03-3: applied. Section 4.3: a paragraph says the `share` stratum holds explorer and overview visitors who opened a button without a click event, that they have seen the comparison, and that this shrinks H2's difference without touching H1.
- 03-4: applied. Section 8: draws count clicks, not people; the ratio is not a response rate; the failure criterion of the count (see "Values chosen").
- 03-5: applied. Section 6.2, H3: the answer is self-reported, an `explorer` respondent who answers "No" still counts as G = 1, and the cross-tabulation of the answer by entry point is reported with H3.
- 03-6: applied. Section 2: the population is everyone who submits one of the four open forms, however they reached it.
- 03-7: applied. Section 10, "The sides can be told apart without labels": the explorer's tips grade the evidence behind each value, which both arms of the `explorer` stratum have seen.
- 03-8: applied. Section 10, "Prior exposure": exposure during the survey (another tab) and between respondents (a treated respondent describing the page), both invisible in the data and both shrinking the effect.
- 03-9: for the author. AUTHOR DECISION: a robustness check that drops the submissions of any hour in which one form received five or more while its pair received none.
- 03-10: applied. Section 4.4: the first pretest's counts are presented as evidence about language-model respondents only, with the point that an order effect cannot bias H1 but can shift S3 levels.
- 03-11: applied. Section 8, "Duplicates": why the forms require no Google sign-in, and that the confirmation screen has no "Submit another response" link.
- 03-12: applied. Section 10, "Who answers": the recruitment channels (the project's pages, LinkedIn and Bluesky posts, forwarded emails).
- 03-13: applied. Section 8, item 3: the explorer's notes disclose the draw count in one quoted sentence, shown before the draw and to both arms.
- 03-14: applied. Section 5.3: the optional answers are reported with the share of each arm that opted in.

### 04, readability

- 04-1: applied. Section 1 rewritten: what Proposition 40 is, the two studies and the labels "the BSZ analysis" and "the JR analysis", the OPA, the comparison explorer and "disputed input" are defined at first use.
- 04-2: applied. Section 6.1 defines OLS, every symbol of the H1 equation and the HC2 standard errors; section 6.2 defines G_i, lambda and delta. The robustness sentence is 01-3's fuller version.
- 04-3: applied in part. The expansion of "AEA RCT Registry" sits in section 9's "Registration" bullet; line 10 (the status line) was left as the orchestrator instructed.
- 04-4: applied. All eight labels are defined or signposted at first use (the horizon question, the current survey and version 1, the dials, the interviewees, the lean index and S1 and S2, the Key tab, N).
- 04-5: applied. All eight statistical terms explained (stratum, the expectation, dimensions, the binomial coefficient, the dropped term, saturated version and order, prime, standardized effect, SD and power). "In the control group" matches the appendix's definition of sigma.
- 04-6: applied. Section 6.3: the Romano-Wolf paragraph explained in short sentences, the citation parenthesis without a semicolon, the bootstrap sentence a full sentence (with 01-7's seed).
- 04-7: for the author: same issue as 01-1 and 02-1 (the S3 family); the sentence at lines 266-267 was not changed.
- 04-8: applied. Section 3: the table's introducing line is two sentences and the signs are explained after the table (combined with 02-10).
- 04-9: applied. Section 3: the venue sentence, the gap and common measure sentence, the explorer's equation and "(below)" rewritten.
- 04-10: applied. Section 10: the 0.68 (control) and 0.71 (treatment) gaps each assigned to its arm, in three sentences (verified against `feedback/008-2026-10-17-rct-pilot/03-interview-analysis.md`).
- 04-11: applied. Section 8: the Sample bullet and the three checks are full sentences, "it" has one referent, "share it" is spelled out; the fallback sentence is covered by 03-2's text.
- 04-12: applied. Section 9: Registration and Close are full sentences, the Launch bullet carries the placeholder for the hash (combined with 02-3 and 01-19).
- 04-13: applied. Section 11: the two long paragraphs are bullet lists, the S4 decision sits in the 2026-10-18 paragraph, and "It stays descriptive (section 5)" now names the email and points to sections 6.2 and 8.
- 04-14: applied. One name for the pretests ("the first pretest", "the second pretest"), the bracketed ones filled in from 02-9's checks; combined with 02-9.
- 04-15: applied. Section 4.4: the court bullet split in two, the symbol q named, "JR chapter" is "the JR analysis's chapter".
- 04-16: applied. Section 4.4: the opt-in sentence split into three statements, with 02-12's corrected count of the walk steps.
- 04-17: applied. All seven compressed phrases unpacked; the "30 to 3" is 30 for the JR value and 3 for the BSZ value (from the first pretest's analysis note, Q7); the "count and rule" reading is the reviewer's, for the author to confirm.
- 04-18: applied. Section 7: the two table introductions are full sentences, "other halves equal" is spelled out, the "step" definition is its own sentence, "lean high" is "err on the high side".
- 04-19: applied. All eight colon-joined clauses split (the line 157-159 one through 03-10's rewrite).
- 04-20: applied. All eleven semicolon-joined clauses split; the line 382-383 one through 01-2's text and the line 452-454 one through 02-13's text.
- 04-21: applied. All seven fragments are full sentences.
- 04-22: skipped. Superseded by 04-20's change to the same sentence, as the finding itself allows.
- 04-23: for the author. The title is the author's choice of 2026-10-18 and was left as it is.
- 04-24: applied. Opening note: the "so that" clause is its own sentence.
- 04-25: applied. Section 8 (why a person in both arms shrinks the effect) and section 10 ("show how much").
- 04-26: applied. "How to launch" renumbered 1 to 7, "Google Apps Script program"; the Launch bullet refers to step 6.
- 04-27: applied. The plan's Appendix A wrote "-$39.0 billion" with a hyphen-minus; `mock_forms.py` line 96 (`money()`) writes the Unicode minus sign U+2212 and `treatment.json` carries it, so the generated text has the minus sign and the plan differed from its source. The plan now carries U+2212. For the rebuild: `plan.tex` runs pdflatex with `inputenc` (utf8) and `textcomp`, whose `ts1enc.dfu` maps U+2212 to `\textminus`; if the build rejects the character, the author decides between keeping the hyphen in the plan and adding a `\DeclareUnicodeCharacter{2212}{\textminus}` to `plan.tex`.

## For the author

Each item repeats a "for the author" line with the text the author could paste.

- 01-1, 02-1 and 04-7 (the S3 definition; AUTHOR DECISION). Decide what S3 tests. Reading (a), which the appendix, `sim.py`, the registry draft and `pilot_analysis.py` support: replace line "S3. Each of the five $y_{ik}$, reported as three indicators (BSZ value, JR value, neutral answer)." with "S3. Each of the five $y_{ik}$, coded as in section 5.1, as the outcome of the H1 equation. For each question, the shares of the three answers (the BSZ value, the JR value, a neutral answer) are also reported by arm, descriptively." and replace "The five S3 outcomes are adjusted with the Romano-Wolf step-down procedure within each answer type (section 6.3)." with "For S3 the outcome is $y_{ik}$. The five S3 tests form one family, adjusted with the Romano-Wolf step-down procedure (section 6.3)."; in `registry-draft.md` replace "S3 each of the five questions separately." with "S3 each of the five questions separately, coded +1, -1 and 0 as the index's inputs." Reading (b), three families of five indicator tests, needs tier 1 of the appendix re-simulated with fifteen tests before registration.
- 01-8 (very small samples; AUTHOR DECISION). Add after "with 80% power." in section 7: "H1 is estimated whenever at least one entry-point stratum has responses in both arms. A stratum with responses in one arm only is dropped from the H1 equation, and the count dropped is reported. Below 30 responses, the smallest N at which the appendix verified the test's level, the p-value of H1 comes from randomization inference, re-drawing T within each stratum 10,000 times, in place of the HC2 t-test. The estimate and its HC2 confidence interval are reported as well."
- 01-9 and 03-1 (differential attrition; AUTHOR DECISION). The fallback sentence is in section 8. To add Lee bounds instead, replace it with: "If the checks show differential attrition (within an entry point, the two arms' submissions per draw differ at the 5% level in a two-sided test of two proportions, or, when the count fails, the exact binomial test rejects at the 5% level), H1 is reported as registered and also with the trimming bounds of Lee (2009). Within each entry point, the arm with the higher submission rate $q_H$ is trimmed by the share $(q_H - q_L)/q_H$ of its responses, where $q_L$ is the other arm's rate, once from the top and once from the bottom of its lean-index distribution. The two trimmed estimates of the H1 equation bound the effect among respondents who would have submitted in either arm. When the count fails, the submission counts stand in for the rates, since the draw is even in expectation. The bounds are reported without a test when an arm has fewer than 50 responses in the entry point."
- 01-15 (name the analysis code). First make `comparison/survey/pilot_analysis.py` match the plan: remove S4 (`abs_lean`), make the entry-point fixed effect a single `E_share` indicator (the current `const`, `E_explorer`, `E_share` design is rank deficient with two entry points), and add H5, the cell and tier-5 families, the staged rule, and the deduplication and bulk rules of section 8. Then add after the "Pretest" bullet of section 9: "- **Analysis code.** `comparison/survey/pilot_analysis.py` runs this plan's analysis. Its version at the launch commit is the registered one. A later change is a deviation and is logged."
- 01-20 (data availability; AUTHOR DECISION). Add to section 9: "- **Data.** After the close, the responses, with the email column and the free-text answers removed, and the draw count are published in the repository with the analysis." Decide whether the free-text answers can be published after a review for identifying detail.
- 02-16 (the pilot analysis still computes S4). Remove the S4 line from `pilot_analysis.py` (the `("S4_abs_lean", d["abs_lean"])` entry and its comment) and from `feedback/009-2026-10-17-rct-pilot-2/report.qmd`, or leave the pilot outputs as a record. The plan now says the second pretest's analysis "still included the later-dropped secondary outcome S4".
- 03-2, alternative (the no-script fallback; AUTHOR DECISION, a site change). Make the share page's fallback a sentence that the survey needs JavaScript, with no form address anywhere in the page's HTML, so that no-script visitors are lost rather than put into one arm. The plan's section 8 would then drop "The share page's fallback link names that form" and say that without JavaScript no form opens.
- 03-9 (bots that vary their answers; AUTHOR DECISION). Add after "per-arm count check above." in section 8: "A bot that varies its answers is not caught by this rule. As a robustness check, H1 is also reported without the submissions of every hour in which one form received five or more submissions while its pair's form received none. The hours and forms removed are reported."
- 04-23 (the title). The reviewer's alternative, if the author wants one: "# Pre-analysis plan: a survey experiment on the salience of study information when respondents judge the credibility of disputed inputs". The title is the author's choice of 2026-10-18; `plan.tex` line 20 and the registry draft's "Analysis plan documents" field would change with it.
- Confirmations asked by the reviewers, not decisions: that the email is used for nothing else (01-14, Ethics bullet); that "one analysis's count of the wealth that left but the other analysis's rule for which income tax is lost" is the intended meaning (04-17, section 4.4); and that the status line (line 10) may carry the expansion "the American Economic Association's registry of randomized controlled trials" (04-3), which was placed in section 9 instead because line 10 was to be left as it is.
