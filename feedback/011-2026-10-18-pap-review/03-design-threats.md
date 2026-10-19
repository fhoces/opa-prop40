# PAP review, 2026-10-18: design threats

This file reads `comparison/survey/PRE-ANALYSIS-PLAN.md` as a skeptical referee of the design. Before asserting anything about what happens in the browser, the mechanics were read in `comparison/R/site.R` (the survey buttons, the draw at the click and the share page), `comparison/survey/draws.gs`, `gas_build.py`, `mock_forms.py`, the two form copies in `comparison/survey/plan/forms/`, and the two pilot folders (008 and 009). The numbered list gives the threats the plan does not yet handle, most important first; a closing section lists the threats it already handles well, with where.

## Findings

### 1. Differential attrition is checked but has no registered consequence for H1

- **Where.** Section 8, "Attrition", lines 399 to 409.
- **Severity.** A. **AUTHOR DECISION** (adds an analysis).
- **The threat.** The treatment form puts a long page (Appendix A) between page 1 and the required questions (`treatment.json`, item 3, type 8 with the full page text as help); the control's page 2 is "The inputs" with one line of help (`control.json`, item 3). Google Forms records only submissions (line 399), so a treated respondent who quits on that page leaves no response. The plan registers three checks "reported whatever the result" (lines 400 to 401) and stops there. Two analysts who find a 60 to 40 split, or submissions per draw of 0.9 against 0.7, would treat H1 differently: one reports it as is, one trims or reweights.
- **Fix.** Add a new paragraph after line 409:

  > If the checks show differential attrition (within an entry point, the two arms' submissions per draw differ at the 5% level in a two-sided test of two proportions, or, when the count fails, the exact binomial test rejects at the 5% level), H1 is reported as registered and also with the trimming bounds of Lee (2009). Within each entry point, the arm with the higher submission rate $q_H$ is trimmed by the share $(q_H - q_L)/q_H$ of its responses, where $q_L$ is the other arm's rate, once from the top and once from the bottom of its lean-index distribution. The two trimmed estimates of the H1 equation bound the effect among respondents who would have submitted in either arm. When the count fails, the submission counts stand in for the rates, since the draw is even in expectation. The bounds are reported without a test when an arm has fewer than 50 responses in the entry point.

  If the author prefers no correction, the smallest text that still removes the ambiguity is (not an AUTHOR DECISION): "If the checks show differential attrition, no correction is applied. H1 is then read as the effect among respondents who complete the form they drew, and the submission rates by arm and entry point are reported beside it."

### 2. Without JavaScript, and for any program that reads the share page without running its script, the destination is always the share pair's control form

- **Where.** Section 8, "Links that skip the draw", lines 420 to 426; section 4.2, line 96.
- **Severity.** B.
- **The mechanism.** `survey_share_page()` writes the control form's address as a plain link, `'If nothing happens, <a href="%s">open it here</a>', esc(pair[1])` (`site.R`, line 1152), and the treatment form's address appears only inside the script, `'var L = ', jsonlite::toJSON(pair, ...)` (line 1157). Every survey button on the explorer and the overview has the share page as its standing `href`, `esc(if (has_share) SURVEY_SHARE_URL else pair[1])` (line 688), so a click without scripts from any entry point ends on that page. A crawler, a link scanner or a form-posting bot that reads the page without running the script finds one form address, the control form (form 5).
- **What the plan says.** Line 422 to 423 say the fallback "also opens one form", and line 425 that it "opens the share pair's control form". The plan does not say that every no-script path from every entry point ends there, that a bot reading the page finds only that address, or that these responses are a control-only addition to the `share` stratum rather than a random half. The bias is toward whatever those respondents answer, in one arm of one stratum.
- **Fix.** Replace, at lines 422 to 423, "The share page's fallback for browsers without JavaScript also opens one form. Neither group can be identified in the data." with:

  > Without JavaScript, every survey button and the share page itself lead to one form, the control form of the `share` pair (form 5): the share page's fallback link names that form, and the treatment form's address sits only inside the page's script. A program that reads the page without running the script, such as a crawler or a form-posting bot, finds the same one address. These responses are not a random half. They add control responses to the `share` stratum, with no draw. Neither group can be identified in the data.

  Replace, at lines 425 to 426, "A form with many submissions and few draws is the sign of a forwarded address." with:

  > Submissions above draws for one form are the sign of a forwarded address, of the no-script path or of a bot. For form 5 all three point the same way.

  Alternative for the author (AUTHOR DECISION, changes the site, not this fix): make the fallback a sentence that the survey needs JavaScript, with no form address anywhere in the page's HTML, so no-script visitors are lost rather than put into one arm.

### 3. Explorer visitors who open the button without a click event are recorded in the `share` stratum

- **Where.** Section 4.3, lines 102 to 105 and 112 to 115; H2, lines 287 to 289.
- **Severity.** B.
- **The mechanism.** The draw runs only in a `click` handler and a middle-button `auxclick` handler, `a.addEventListener("click", function () { drawSurvey(a); })` and `a.addEventListener("auxclick", function (e) { if (e.button === 1) drawSurvey(a); })` (`site.R`, lines 1134 to 1135). The anchor's standing `href` is the share page (line 688). "Open link in new tab" from the context menu, a long press on a phone, dragging the link to the tab bar, a click before the page's script has attached the handlers, or a browser that does not fire `auxclick`, all open the share page, which draws and records `entry = "share"` (line 1157). The site's own comment says so (lines 679 to 681): "A survey link opened without a click (no JavaScript, a long press, "Open in new tab") goes to the share page, which draws in its own stratum". The plan does not.
- **The effect.** H1 is untouched: the draw is fair within the form reached, and the fixed effect is for the stratum the response landed in. H2 is attenuated: the `share` stratum holds visitors who have seen the comparison, so the two strata differ less in exposure than lines 113 to 115 say.
- **Fix.** Add after line 115, after "some have seen the estimates and some have not.":

  > The `share` stratum also holds some visitors of the explorer and the overview. A survey button opened without a click event, through the context menu, a long press or a drag, goes to the share page, which draws and records in the `share` stratum. These visitors have seen the comparison. Their presence shrinks the difference that H2 looks for and does not touch H1.

### 4. The draw count counts clicks and script-running loads, not people, and "if the count fails" has no criterion

- **Where.** Section 8, item 3, lines 405 to 409.
- **Severity.** B.
- **The mechanism.** One request per draw: `navigator.sendBeacon(DRAWS_URL + "?entry=" + entry + "&arm=" + arm)` (`site.R`, line 1119), appended as one row by `record_()` (`draws.gs`, lines 32 to 50). A second click is a second draw and a second row. The share page draws on every load (lines 1157 to 1160), including a load by a link scanner or previewer that runs scripts. A browser setting or extension that blocks the request still opens the form: on the buttons the `href` is set before the beacon (line 1130, then 1131), and on the share page the beacon sits in a `try` before `location.replace` (lines 1159 to 1160). None of these depends on the arm, so the comparison of submissions per draw across arms stands, but the ratio is not a response rate, and nothing says when the count counts as failed, so two analysts could switch to the fallback at different points.
- **Fix.** Add after line 409:

  > Draws count clicks, not people. A respondent who clicks twice is two draws, a program that loads the share page and runs its script is a draw with no respondent, and a browser that blocks the request is a submission with no draw. None of these depends on the arm, so the comparison of the ratio across arms stands. The ratio itself is not a response rate. The count fails for an entry point, and the binomial test is then its only attrition check, if the Draws sheet recorded nothing on a day on which that entry point's forms received submissions, or if either of its forms has more submissions than draws (the sign of a forwarded address, below).

### 5. The prior-exposure question does not say whether the project's own pages count, so the "No" of H3 and H5 can include respondents who have seen the comparison

- **Where.** Section 4.4, lines 124 to 126; section 6.2, lines 292 to 293 and 296 to 301; section 7, lines 372 to 373.
- **Severity.** B.
- **The threat.** An `explorer` respondent arrives from a page that shows the comparison. The question asks about "news sources, web pages or academic studies discussing estimates of Proposition 40" (`control.json`, item 1). A respondent can read "web pages" as outside sources and answer "No" about the page they just left. The plan treats "No" as no exposure: H3 predicts a larger effect for G = 1, H5 calls the subgroup "closest to a first exposure" (line 301), and line 372 expects the subgroup to sit "mostly in the `share` stratum". None of these states what an `explorer` respondent who answers "No" is. The forms are fixed, so the question cannot change without an author decision; the rule and the report can.
- **Fix.** Add after line 293:

  > The answer is self-reported, and the question does not name the project's own pages. An `explorer` respondent who answers "No" has seen the comparison on the page and still counts as G = 1, by this rule. The cross-tabulation of the answer by entry point is reported with H3, so the reader sees how many such respondents there are.

### 6. The population (line 25) excludes responses that the sample rule (line 396) includes

- **Where.** Section 2, line 25; section 8, line 396.
- **Severity.** B.
- **The threat.** Line 25 defines the population as "Everyone who opens one of the project's survey links and submits the form". A person who opens a forwarded Google Forms address (line 421) or the no-script fallback (finding 2) did not open a project link, yet line 396 includes "Every response submitted to the four open forms". Section 8 is right, since the two cannot be told apart in the data; section 2 should say the same.
- **Fix.** Replace, at line 25, "Everyone who opens one of the project's survey links and submits the form during the collection window (section 9)." with:

  > Everyone who submits one of the four open forms (section 4.3) during the collection window (section 9), whether they reached the form through a project survey link or through a form address that someone forwarded (section 8).

### 7. The explorer grades the evidence behind each value, so the `explorer` stratum's control has seen the author's judgment, not only the studies' names

- **Where.** Section 10, "Neutrality" and "The sides can be told apart without labels", lines 481 to 488.
- **Severity.** C.
- **The threat.** Each dial end on the explorer names its study (the pilot's text rendering of the page, `feedback/009-2026-10-17-rct-pilot-2/00-materials/entry-explorer.txt`, lines 58 to 118), and each end's tip "ends with the kind of that analysis's value: data (settled by observable facts), research (a published estimate), guesswork (an assumption with no data or study behind it), guesswork on data, scenario and derived" (`comparison/site/explorer.template.html`, lines 471 to 476). These kinds are the author's grading of the evidence. The pilot analysis noted that for the yearly income tax the tips rate "BSZ's as research, JR's as guesswork" (`feedback/008-2026-10-17-rct-pilot/03-interview-analysis.md`, line 9). Every `explorer` respondent in both arms has seen them, so that stratum's control answers are not those of respondents who met the values without labels or grades. This does not bias H1 within the stratum; it changes what the control level means and what the treatment can add there.
- **Fix.** Add after line 487, after "Respondents from the explorer have also seen each value's study on the dials.":

  > The explorer's tips also grade the evidence behind each value (data, research, guesswork, scenario or derived), a judgment of this OPA's author. Respondents from the explorer in both arms have seen those grades, so the `explorer` stratum's control answers are not those of respondents who met the values without labels or grades.

### 8. Exposure during the survey, and between respondents, that the data cannot see

- **Where.** Section 10, "Prior exposure", lines 471 to 473; section 8, line 410.
- **Severity.** C.
- **The threat.** The form shows no link before Submit (lines 458 to 460), but the respondent's browser does: a control respondent can open the explorer in another tab while answering, and the explorer labels every value with its study. A treated respondent can describe the comparison page to a colleague who then takes the survey, and the public posts invite exactly this passing on. Neither leaves a trace. Both move the control arm toward the treatment.
- **Fix.** Add after line 473:

  > Exposure can also happen during the survey, or between respondents. A control respondent can open the explorer in another tab while answering, and a treated respondent can describe the comparison page to a colleague who then takes the survey. Neither is visible in the data. Both move the control arm toward the treatment and shrink the effect.

### 9. The bulk rule catches only bots that repeat identical answers, and a burst in one form has no registered consequence

- **Where.** Section 8, "Bulk and automated submissions", lines 411 to 417.
- **Severity.** C. **AUTHOR DECISION** (a new robustness check).
- **The threat.** The rule removes "three or more submissions to the same form within ten minutes, with identical answers to every choice question" (lines 413 to 415). A bot that varies its answers, or a group that passes one form's address around a forum, evades it. Line 416 to 417 say a burst "also shows in the per-arm count check" and stop: the plan says what it would see, not what it would do.
- **Fix.** Add after line 417:

  > A bot that varies its answers is not caught by this rule. As a robustness check, H1 is also reported without the submissions of every hour in which one form received five or more submissions while its pair's form received none. The hours and forms removed are reported.

### 10. The claim of no order effect rests on simulated respondents

- **Where.** Section 4.4, lines 157 to 159.
- **Severity.** C.
- **The threat.** The sentence presents the pilot's counts as evidence that the first-listed value does not gain from its place. The pilot's respondents were language-model agents (line 436 to 437), which says little about people. The JR value is listed first in four of the five required questions in both arms (`control.json`, items 5, 7, 9 and 15; `treatment.json`, items 6, 8, 10 and 16), so an order effect cannot bias H1, but it can move the level of each question's answers in S3. The plan should say that rather than lean on the pilot.
- **Fix.** Replace, at lines 157 to 159, "The simulated pilot (section 9) showed no sign that the first-listed value gains from its place: in the control forms the second-listed value won the share-lost question (21 to 9) and the court question (18 to 4)." with:

  > In the simulated pilot (section 9) the second-listed value won the share-lost question (21 to 9) and the court question (18 to 4) in the control forms, so its language-model respondents showed no sign of favouring the first-listed value. That says little about people. Because the order is the same in both arms, an order effect cannot bias H1. It can shift the level of each question's answers in S3.

### 11. The forms require no sign-in; the plan should say why

- **Where.** Section 8, "Duplicates", line 410.
- **Severity.** C.
- **The threat.** A referee asks why one person can submit twice. `gas_build.py` turns off the "Submit another response" link, `f.setShowLinkToRespondAgain(false)` (line 144), and never sets Google Forms' one-response limit, which requires a Google sign-in. The reason is sound (a sign-in deters respondents and records their accounts) but unstated.
- **Fix.** Append to line 410:

  > The forms do not require a Google sign-in, the only way Google Forms limits one account to one response, because a sign-in would deter respondents and record their accounts. The confirmation screen shows no "Submit another response" link.

### 12. Recruitment channels are not named in Limits

- **Where.** Section 10, "Who answers", lines 469 to 470.
- **Severity.** C.
- **The threat.** The limit says the results describe "people who take the survey". It does not say who is invited: the site's survey section says "The survey is primarily for economists and policy analysts" (`site.R`, lines 694 and 707), and the share link travels through the author's posts on LinkedIn and Bluesky (lines 518 to 519) and forwarded emails. A referee wants the channels named to judge who the self-selected sample is.
- **Fix.** Add after line 470:

  > Respondents are recruited through the project's own pages, which say the survey is primarily for economists and policy analysts, and through the author's posts on LinkedIn and Bluesky and the emails that pass the share link on. The sample is the author's network and whoever those posts reach.

### 13. The explorer's notes disclose that the page records "which form it drew"

- **Where.** Section 8, item 3, lines 405 to 406.
- **Severity.** C.
- **The threat.** When `draws_url` is set, the explorer's notes fold gets the sentence "This page records, without any identifying data, that a survey link was opened and which form it drew." (`site.R`, lines 713 to 715; placed at `comparison/site/explorer.template.html`, line 479). It tells a careful visitor that there is more than one form, before the draw. The disclosure is the same for both arms, so it cannot differ by arm, but the plan should record it, since it is part of what respondents can know.
- **Fix.** Add to item 3, after "(no identifier, no cookie).":

  > The explorer's notes disclose the count in one sentence ("This page records, without any identifying data, that a survey link was opened and which form it drew."). The sentence is shown before the draw and to both arms.

### 14. The opt-in to the five smaller inputs is a post-treatment choice that is not reported by arm

- **Where.** Section 5.3, lines 249 to 251.
- **Severity.** C.
- **The threat.** The opt-in question comes after the treatment page and the five required questions (`control.json`, item 17; `treatment.json`, item 18). Whether a respondent opts in is a sign of engagement that the treatment could move: in the second pilot 26% of controls and 34% of treated opted in (`feedback/009-2026-10-17-rct-pilot-2/analysis/descriptives.csv`). The plan reports the optional answers descriptively but not the share who opted in, by arm, which is the one number that puts those answers in context (the support question already has this at lines 314 to 315).
- **Fix.** Replace, at lines 250 to 251, "Their answers are reported descriptively." with:

  > Their answers are reported descriptively, with the share of each arm that opted in.

## Handled already

Threats a referee would raise that the plan already covers, with where:

- **What the design identifies.** I1 and I2 are delivered together and the plan says the design "cannot separate them" (line 91) and names the two channels (lines 474 to 476).
- **Demand effects of naming the studies.** Stated as a limit (lines 474 to 476), with the finding that the sides can be told apart without labels (lines 483 to 488) and that the control forms keep the rule of naming neither analysis while the treatment forms name both by design (lines 481 to 482).
- **Selection into the entry points.** The entry point is not randomized, it is a stratum with a fixed effect in every equation (lines 259 to 261, 289 to 291), and all `explorer` respondents have seen the comparison (lines 112 to 117, 471 to 473). The overview's own page shows both estimates and names both studies above the fold that holds its survey buttons (`comparison/site/index.template.html`, lines 295 to 321, 481 to 488), so the overview button belongs with `explorer`.
- **The draw.** The respondent sees nothing of either form before the draw (line 96); `Math.random() < 0.5` runs at the click (`site.R`, line 1129) or at the share page's load (line 1158). The share page replaces its own history entry, `location.replace(...)` (line 1160), so Back from the form does not land on the share page and does not redraw. The buttons open the form in a new tab (`target="_blank"`, line 687), so Back does nothing there either.
- **Forwarded form addresses.** Lines 420 to 426 and 518 to 522, with the data signature (many submissions, few draws). The Copy link button copies the share page's address, never a form's (`site.R`, lines 695 and 706).
- **Duplicates and one person in both arms.** Line 410; the "Submit another response" link is off (`gas_build.py`, line 144).
- **No link out before Submit.** Lines 458 to 460; the explorer and project links come only on the confirmation screen (`control.json` and `treatment.json`, `confirmation`).
- **Bulk submissions.** A fixed rule, the count removed reported, and H1 also reported with nothing removed (lines 411 to 417).
- **Attrition checks.** Three checks, including a denominator from the draw count (lines 399 to 409); only the consequence is missing (finding 1).
- **The vote inside the window.** An "after the vote" indicator in the robustness specification (lines 432 to 435).
- **No interim looks beyond counts.** Line 443.
- **The two earlier forms.** They close when the new forms open, and their responses are reported on their own (lines 396 to 398, 498 to 499).
- **External validity.** The results describe those who take the survey; randomization makes the arms comparable, not representative (lines 469 to 470); the registry abstract says the same (`registry-draft.md`, lines 23 to 32).
