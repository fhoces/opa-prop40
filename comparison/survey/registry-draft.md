# AEA RCT Registry: draft fields (not submitted)

Entered on 2026-10-17 as the private draft of trial 19997 (socialscienceregistry.org/trials/19997/edit),
with the dates 2026-10-19 (start) and 2026-12-31 (end), IRB "No", both PDFs attached to the analysis plan
(private), and a repository note under Docs & Materials (private). Not submitted.

Drafted 2026-10-17 from `comparison/survey/PRE-ANALYSIS-PLAN.md` for the author to review. Every field
below is a proposal; the registry's own labels may differ slightly. Nothing here has been submitted.

**Title.** Does making the comparison salient change how respondents judge disputed inputs? A
survey experiment on two estimates of California's Proposition 40

**Country.** United States

**Status.** In development (the forms are built and closed; collection starts at launch)

**Keywords.** Public finance; tax policy; wealth tax; open policy analysis; expert elicitation;
survey experiment

**JEL codes.** H24 (personal income and wealth taxes), H71 (state and local taxation), C93 (field
experiments), D83 (information and knowledge)

**Abstract.** Two academic analyses of California's Proposition 40, a one-time 5% tax on
billionaires' net worth, reach opposite conclusions: one finds that it raises money for the state,
the other that it loses money. An Open Policy Analysis of both puts them on one measure and shows
which inputs explain the gap. A short survey asks respondents which of two proposed values of each
disputed input they find more credible. This experiment randomizes, at the click on a survey link,
whether the respondent first sees a page that explains how the two estimates differ and labels each
value with its study. The main outcome is a lean index over the five required questions. The
OPA pages point readers to the comparison several times, so many respondents will have seen it
already. The study therefore mainly tests whether making the comparison salient when respondents
choose the input values changes the answers.

**Trial start date.** 2026-10-19 (the launch date).

**Trial end date.** 2026-12-31 (analysis done). Collection closes 4 November 2026 at 23:59 Pacific time.

**Intervention start date / end date.** 2026-10-19 / 2026-11-04.

**Primary outcomes (end points).** The lean index: for each respondent, the mean over the five
required input questions of +1 (the BSZ value chosen), -1 (the JR value chosen) and 0 (About
equally credible or Unsure).

**Primary outcomes explanation.** The five required questions are the share of billionaires'
income tax lost when people leave, how long the lost income tax is counted, billionaires' yearly
California income tax, discounting the revenue for the chance that courts strike the tax down, and
billionaires who moved out of California before the residency date. The index runs from -1 to +1.

**Secondary outcomes.** S1 the share of Unsure answers; S2 the share of About equally credible
answers; S3 each of the five questions separately.

**Experimental design (public).** Respondents reach the survey through one of two entry points:
a button on the comparison explorer or the project's overview, whose users have all seen the two
estimates, and a shared link that opens the survey directly, whose users may or may not have
seen them. Each entry point has a control form and a treatment form; the arm is drawn with
probability one half at the click. The treatment form adds one page after page 1 (the two opening
questions and the optional email), explaining how the two estimates differ and which inputs explain the gap, and labels
each value with its study. The control form is identical without that page and with the values
labelled A and B. Analysis: OLS of the lean index on the treatment indicator with entry-point fixed
effects and HC2 standard errors, two-sided test at 5%. Heterogeneity by entry point, prior exposure
and expertise, and the effect among experts without prior exposure, are secondary, adjusted with the Romano-Wolf step-down, and run only above
pre-registered sample-size thresholds.

**Experimental design details (hidden until the trial ends).** The full plan and its power
appendix are attached.

**Randomization method.** Randomization done by a computer: `Math.random() < 0.5` in the
respondent's browser at the click on a survey link, separately for each entry point.

**Randomization unit.** The individual respondent.

**Was the treatment clustered?** No.

**Planned number of clusters.** Not applicable (unclustered). Observations: 0 to 200. The number depends on whether the OPA's
launch gains traction on social media; none or very few responses are likely.

**Sample size by arm.** About half in each arm; not controlled.

**Minimum detectable effect size.** For the main test (two-sided, 5%, 80% power): with 100
responses the detectable effect is 0.56 standard deviations of the lean index, and with 200, the
top of the expected range, 0.40 (with the assumed index standard deviation of 0.5, a change of 0.20
in the mean index). Detecting 0.5 standard deviations needs 126 responses and 0.3 needs 349. The
power appendix gives the thresholds for every secondary analysis.

**IRB.** No IRB approval was obtained (the author's answer).

**Analysis plan documents to upload.** `comparison/survey/plan/plan.pdf` (the pre-analysis plan,
titled "Pre-analysis plan for a study of salience of study information and credibility assessment
of key assumptions and inputs") and `comparison/survey/power/power.pdf` (the appendix on power).

**Other.** Launch commit: the hash recorded in the plan's section 9 on launch day (filled in at
launch), in https://github.com/fhoces/opa-prop40.
