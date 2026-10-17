# Improvements after the pilot (Opus interviewer, max effort, round 3), 2026-10-17

Saved by the orchestrator from the agent's reply. Four files were edited: `comparison/survey/mock_forms.py`, `comparison/survey/gas_build.py`, `comparison/survey/PRE-ANALYSIS-PLAN.md` and `feedback/005-2026-10-16-explorer-ux/03-landing-survey-plan.md`. Nothing is committed.

`power.tex` and `sim.py` are unchanged. The five required questions stay, K stays 5 and no number in the appendix changes, so nothing needed rebuilding.

Every number in the new texts is read from the exports. A few facts are still typed: the $1 billion threshold, the dates, the seven names, "about half" in the yearly income tax question, and "5 to 10 minutes".

## Changes

The rule applied throughout: in every input question both values are the same kind of claim. Each gives a reason, or neither does. Neither argues against the other.

**1. Share lost (Q3).** `mock_forms.py`: a new `SHARE` dict. `split_bundle()` now builds the question from it instead of cutting it out of the old bundled question.
- Old A: "45% of all billionaires' income tax, whoever leaves."
- Old B: "5%, only the income tax of those who leave."
- New A: "More than the share of wealth that leaves: 45% of billionaires' income tax, against the 29% of their wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported."
- New B: "No more than the share of wealth that leaves: 5% of billionaires' income tax when 5% of their wealth leaves, because the largest of the billionaires reported to have left pay little income tax for their wealth."
- Evidence, old text: the old pair had no stable meaning (F1). When answering, 5 of 10 interviewees read the 5% as a count of leavers. In the interviews, 7 of 10 read it as a share of the leavers' own tax, a different base from A. Six respondents read the 45% as counting the tax of people who stay.
- Evidence, review's rewrite: in the follow-up, all ten interviewees chose its BSZ value, eight of them changing their answer. They called its JR reason a "plug" or a "cushion", and #56 still read "whatever share of them leaves" as taxing those who stay.
- Basis for the new pair: it states the actual dispute (DISPUTES.md row 6). Each side gets its authors' own reason. For JR: "not the same object", and departures "not publicly documented" (JR chapter, PDF p.31). For BSZ: the largest leavers pay about 0.04% to 0.07% of their wealth in income tax (BSZ Table 4).
- A respondent who accepts one analysis's count and the other's rule can now answer.
- This version is untested.

**2. Moved out in time (Q11).** `DEPARTED`.
- Old A: "About 29% of the wealth: seven billionaires with publicly reported moves (...) are counted as having moved in time."
- Old B: "...an allowance for billionaires who managed to move in time. No named billionaire is counted, because press reports do not by themselves establish a change of legal residence. Counting four of them (...) is treated as an aggressive scenario."
- New A: "About 29% of the wealth: seven billionaires (...) are counted as having moved in time, on public reports of their moves."
- New B: "5% of the wealth: an allowance for billionaires who moved in time, with no one counted by name without evidence of a change of legal residence before the date."
- Evidence, old text: F5. All 10 interviewees flagged "aggressive scenario" and read it against both sides. Five respondents repeated B's rebuttal as their own reason (#12, #29, #46, #64, #85).
- Evidence, review's F5 text: 8 of 10 found its B "better argued" and A "a list with no reason". Now each value states its own standard of evidence and does not mention the other's.

**3. Court (Q9).** A new `COURT` entry in `REWRITE`.
- Old A: "100%: the tax is collected in full, as written."
- Old B: "50%: a guesstimated likelihood that the tax will not survive court litigation; it is as likely to fail as to stand."
- New A: "100%: the tax survives and is collected in full, as written."
- New B: "50%: the tax is as likely to be struck down as to survive."
- Evidence, old text: F4. All 10 interviewees flagged "guesstimated". 10 of the 18 reasons given with Unsure on Q9 cite the "guess" label.
- Evidence, review's F4 text: it tilted the other way. 6 of 10 read "an accounting rule" as official and "argued to have been drafted" as advocacy. So neither side gives a reason now.

**4. Yearly income tax (Q7).** `INCOME`.
- Old A: "$4.55 billion a year: the middle of a range from California tax data. The top, $5.8 billion, assumes ... 212 highest earners. The bottom, $3.3 billion, assumes ... top 500 tax filers."
- Old B: "$3.06 billion a year: the income tax paid by California's highest earners, halved, because research finds the wealthiest people have about half the income of the highest earners."
- New A: "$4.55 billion a year: from California tax data, taking the billionaires to be among the state's highest earners."
- New B: "$3.06 billion a year: from California tax data, taking the billionaires to have about half the income of the state's highest earners."
- Evidence: the review missed this one. The pilot split 30 JR to 3 BSZ, with 65 Unsure. Six interviewees named the gap in length. The round-2 balanced version still read as fuller on the JR side to all 10, and "halved" read as an arbitrary cut.
- Now each value has one assumption, in the same words, with no range on one side and no "halved" on the other. The explorer's tips rate the two values the other way round: BSZ's as research, JR's as guesswork.

**5. Horizon (Q5).** `HORIZON`. Old B "...treating the responses as temporary." becomes "...treating the departures as temporary." The "5 years" is now generated from the export. Evidence: F19, and #98. The pilot split this question evenly (33 to 31), so nothing else changed.

**6. Avoidance (Q14).** `AVOID`. Old: "5%: a small allowance argued from enforcement." against "None." New: "5% of the wealth escapes the tax this way." against "None of the wealth escapes the tax this way." Evidence: F14. The bare "None." drew 0 of the 34 who opted in.

**7. Wealth base, non-citizens, real estate, asset sales (Q15 to Q18).** New `WEALTH`, `NONCIT`, `REAL` and `ASSET` entries in `REWRITE`.
- Q15 A gains ", or $2,157 billion without the non-US citizens asked about next" (F18). Four explorer-path respondents had noticed the explorer's $2,157B.
- Q16 B, "Left out of the base.", becomes "Not taxed: the wealth of California billionaires who are not US citizens is left out of the base." A becomes "Taxed: the $150 billion of wealth ...".
- Q17 becomes "No deduction: directly held real estate stays in the base." against "A deduction: directly held real estate, about 0.5% of the base, is taken out of it."
- Q18 becomes "Counted: one third of the tax is paid by selling assets, and the gains on them are taxed." against "Not counted: no extra income tax from selling assets is included."
- Evidence: F14. In the pilot the JR values drew 0, 0, 1, 0 and 0 picks on Q14 to Q18.

**8. Description.** A `DESC` constant, now also set on the real forms.
- Old: "Each question shows one input, two values that have been proposed for it, and the reason given for each. ... These are empirical quantities: their values should not depend on ... It takes about 5 minutes."
- New: "Each question shows one input and two values that have been proposed for it. ... Most of these are empirical quantities, and none should depend on whether one supports or opposes a wealth tax. ... It takes 5 to 10 minutes."
- Evidence: F14 and F15. Careful readers took a median of 14 minutes, skimmers 4 to 6. Respondents #64, #71 and #98 said the 5 minutes was wrong, and several notes doubted the "empirical" line.
- The builder never set the description before. It now calls `setDescription`, guarded because the test stand-in for Google Forms lacked that method.

**9. Opt-in (Q13).** `OPTIN`. Old: "...have only a small, second-order effect on the estimate." New: "The last five inputs move the estimate only a little. Would you like to assess them anyway?" Evidence: F17. The gate itself stays: 66% skipped, as designed.

**10. Email (Q21).** `EMAIL`. Old title: "Verify your identity with your email." New title: "Your email (optional)". New help: "If you leave one, your answers are also reported in a separate analysis of the respondents who gave an email." Evidence: F16, and #54 and #56.

**11. Treatment page.** `STUDIES`, `INTRO`, `TERMS`, `NOTE`.
- "Jaros and Rauh (JR, NBER, September 2026)" becomes "(JR, September 2026)". This is F12: both analyses are NBER papers, so naming the venue on one side only was a prestige cue.
- "...and the values each study uses." becomes "...with each study's values for the first three." This is F8.
- The part 1 values now match the new Q3: BSZ "a share of income tax lost no larger than the share of wealth that leaves (5%); counted for 5 years; $3.06 billion a year"; JR "a share of income tax lost larger than the share of wealth that left (45%); counted for ever; $4.55 billion a year".
- Part 3 now reads "JR: seven billionaires counted on public reports of their moves" and "BSZ: no billionaire counted by name (...)".
- The three-sentence note becomes: "The income tax lost is shown as one amount because its three inputs multiply each other. For the same reason, each amount depends on the order in which the inputs are changed."
- Evidence on the page: all 5 treated interviewees restated the 56% and the 27%. The note on order was skipped or garbled (#35, #56, #85).
- One sentence on order is kept rather than dropped as F8 proposed. The court amount is $39.4B here but $53.75B if the court input is moved first.

**12. `gas_build.py`.** One generic `CHOICES` map, built from `mock_forms.REWRITE`, replaces the income-only map. The builder also sets the email title and help and the description.

**13. `PRE-ANALYSIS-PLAN.md`.** The author's capitals note on bots and the close-date sentence are untouched. Changes by section:
- Section 3 (I1): the bullets without a venue, the shorter note.
- Section 4.4: the wording rule and each change above with its evidence. Also the "departures" fix, and a sentence that the pilot showed no primacy effect: in control the second-listed value won Q3 (21 to 9) and Q9 (18 to 4).
- Section 5.1: in the share-lost question, y codes the rule chosen.
- Section 5.3: "Proposed (agent, awaiting the author): S4, mean |Lean|". Also a note that "About equally credible" was 2% of answers and that Unsure mixes not knowing with rejecting both values.
- Section 8: two "Proposed (agent, awaiting the author)" items. One counts draws for attrition (F6). The other covers links that skip the draw (F10, F21).
- Section 9: a "Pretest" entry saying the pilot is not data for this study.
- Section 10: two new limits. The sides can be told apart without labels: persona views predicted the lean equally in both arms (a gap of 0.68 in control against 0.71 in treatment). And the share post's promise.
- Section 11: open decisions 7 to 12.
- Appendix A: updated to the new page.

**14. The 005 plan.**
- A header line saying what the pre-analysis plan supersedes, and what still stands: B1 read as `entry,arm,url`, B3 and B5.
- The panel text is now: "Before you see why, we invite you to judge which of two proposed values for each key input is more credible. It takes 5 to 10 minutes." The audience line moves above the buttons.
- Evidence: F9. About 20 of the 33 landing respondents read "compared with the values the two analyses use" as a quiz with right answers.

**Left unchanged on purpose:** the choice order (F13: the pilot showed no primacy effect, and the author chose one fixed order); the five required questions; "About equally credible" (an author decision, section 11 item 8).

## Proposals not implemented (outside the agent's files)

1. **Public post (Google Doc).** Replace from the third sentence on with: "Boll, Saez and Zucman estimate that it raises about $104 billion in wealth tax alone, before its effects on income tax. Jaros and Rauh find that it leaves the state $39 billion poorer, because billionaires who leave stop paying California income tax. [...] If you work in tax policy, public finance or a related field, I am collecting expert views on the inputs the two analyses disagree on. It takes 5 to 10 minutes: fhoces.github.io/opa-prop40/comparison/site/survey. If you pass it on, please share this link rather than the address of the form it opens." This covers F3, F20, F10 and the time.
2. **Explorer button** (`comparison/R/site.R` and the explorer template). Change "Take the survey: what do you think these values are?" to "Take the survey: which values are more credible?" (F22). In the pilot, #3 and #23 expected to type their own numbers. Under it, add: "To share the survey, use Copy link: it keeps the random draw." The pins in `test-site.R` change with it.
3. **Landing panel, live text.** Put the 005 plan's new B3 text into the panel's tokens and their `test-site.R` pins.
4. **Share page fallback** (`survey_share_page()` in `site.R`). Today the no-script link is `urls[1]`, form version 1. Once `survey-links.csv` reads `entry,arm,url`, the link should be the `share,control` row, and the script should draw only between that pair (F21).
5. **Draw count** (F6). Right after the arm is drawn, in the explorer's survey-button handler and in the share page's script, add `try { navigator.sendBeacon(DRAWS_URL + "?entry=" + entry + "&arm=" + arm); } catch (e) {}`. `DRAWS_URL` would sit in a one-row config CSV. In the Apps Script project, a `doGet(e)` would append `[new Date(), e.parameter.entry, e.parameter.arm]` to a "Draws" tab, deployed to run as the author with access for anyone. Add one sentence to the explorer's notes: "This page records, without any identifying data, that a survey link was opened and which form it drew." The analysis text is already in section 8 as a proposal.
6. **Test stand-in.** Add `f.setDescription = () => f;` to `makeForm` in `fakeforms.js`, so the test covers the description. (Done by the orchestrator.)
7. **A fresh simulated pass before launch.** Use new agents, not the ten already primed. Put the guide's question 8 (even-handed wording) and question 10 (the made-up case) to the new Q3, Q7, Q9 and Q11, which nobody has seen. A rewrite that splits most respondents one way should be checked for whether their reasons cite the content or the wording.

## Questions only the author can answer

1. Approve the revised values (section 11 item 7). Q3 now measures a rule, not the BSZ analysis's 5%. Would each analysis's authors accept the reason given in their name in Q3?
2. Keep "About equally credible" (2% use), drop it, or add "Neither value seems right"?
3. Can the public post still be edited, and was the share link already emailed with "names neither analysis"?
4. Adopt the draw count? It needs a deployed web app.
5. Ask support for Proposition 40 before the comparison page? It would allow a polarization test, at the cost of priming both arms.
6. Do responses after the 3 November vote count, and should the vote date be recorded? Plus the close-date wording proposed in section 9.
7. The open items from before: the expected N, the bots note, the overview button's pair of forms, and the two current forms.
8. Use "5 to 10 minutes" everywhere: the description, the panel and the post?

## Test output

`same order apart from the treatment page: true`. The syntax check printed "syntax ok", and the builder made six forms.
