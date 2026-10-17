# Pre-analysis plan: does seeing the comparison change how respondents judge the disputed inputs?

**A note on this document.** This pre-analysis plan was drafted with the assistance of Claude
Code. It is unclear whether the survey will draw any responses at all. The plan was written for
the optimistic case, in which enough people respond for a study to be conducted with the data, so
that the analysis is fixed before any response is seen. **At this point, it is the opinion of the
author that no human should spend much time reading this pre-analysis plan. It is only intended
as a record.**

Status: draft, 2026-10-16. Not registered. To be registered on the AEA RCT Registry before the
forms open. Structure follows the minimal elements of a clear hypothesis: population,
interventions, arms, outcomes, hypotheses (contrasts, tests, alternative, estimation, standard
errors), and heterogeneity stated separately and in full.

## 1. Question

The Proposition 40 survey asks respondents which of two proposed values of each disputed input
they find more credible. The comparison explorer shows the same inputs, which study uses which
value, and what each value does to the estimate. This study asks whether seeing that comparison
before answering changes the answers.

## 2. Population and sample

- **Population.** Everyone who opens one of the project's survey links and submits the form during the collection window (section 9). No one is screened out. Self-described experts and
  respondents without prior exposure are subgroups (section 6), not the sample. 
- **Unit of randomization.** The respondent, drawn at the click on a survey link (section 4.2).
- **Unit of analysis.** One submitted response.
- **Sample size.** Not controlled: it is whoever responds in the window. The author expects 50 to
  200 responses. The staged rule of section 7 decides which analyses run once the realized number
  is known, and section 7 gives the detectable effects for a range of sizes.

## 3. Interventions

Two manipulations, both delivered only in the treatment forms. Nothing is delivered to the control group: it is a pure control.

- **I1, the comparison page.** One page, "How the two estimates differ", shown after the opening
  questions and before the input questions. It opens with "Two academic studies" and gives each
  study on its own bullet with its month and its estimate (Boll, Saez and Zucman, BSZ; Jaros and
  Rauh, JR). Neither bullet names a venue: both are NBER papers, and a venue on one side only would
  be a prestige cue inside the treatment. It
  then gives the gap between them and the explorer's common measure. It then splits the gap into the four terms of the comparison explorer's equation,
  largest first. Each term has a bar, its amount in billions and its share of the gap, and, for
  the first three, the values each study uses. A sentence names the two largest terms and their
  combined share. A two-sentence note says why the lost income tax is one term (below) and that
  each amount depends on the order in which the inputs are changed. The full text is in Appendix A.
- **I2, the study labels.** In the input questions, each choice is labelled with its study ("BSZ:"
  or "JR:") instead of "A." or "B.". The choice text and order are otherwise unchanged.

The four terms, as generated at commit e345b64 (gap $145.8 billion):

| Term on the page | Amount | Share of the gap |
|---|---|---|
| The income tax lost when billionaires leave: the share lost, how long it is counted, and billionaires' yearly income tax, together | -$81.3 billion | 56% |
| Discounting the revenue for court risk | -$39.4 billion | 27% |
| Billionaires who moved out in time | -$29.9 billion | 21% |
| Other inputs together: the wealth on the list, avoidance, and three smaller inputs | +$4.9 billion | offsets 3% |

The shares add to 101% because of rounding. Each amount is the sum of the explorer's walk steps
in that term (`comparison/export/r/dial_path.csv`). The walk moves the inputs one after another
from the BSZ values to the JR values. The values come from `comparison/export/r/inputs.csv`.
`comparison/survey/mock_forms.py` and `gas_build.py` generate the page from those files, so no
number is typed. They also check that every walk step belongs to one term and that the terms add
up to the gap.

The page does not give one amount per survey question. The lost income tax is a product of the
share lost, how long it is counted and the yearly amount. A split among those three factors would
depend on the order in which they are changed, so it would misstate what any one of them does. The
page shows them as one term and says why. As a result, the terms do not match the survey questions
one to one. The first term covers three whole questions: the share lost, how long it is counted,
and the yearly income tax. The question on billionaires who moved out in time spans two terms.
The JR value (seven named moves) is the third term. The BSZ value (an allowance for unnamed
movers, half of the BSZ avoidance allowance) sits in the fourth. The optional avoidance and
wealth questions also sit inside the fourth term. Only the court question matches one
term. The small difference in
discount rates is inside the first term and is not named, since the horizon question no longer
asks about it.

## 4. Arms and assignment

### 4.1 Arms

| Arm | I1 | I2 |
|---|---|---|
| Control (T = 0) | no | no |
| Treatment (T = 1) | yes | yes |

I1 and I2 are delivered together. The design measures their joint effect and cannot separate them.

### 4.2 Assignment

Google Forms cannot randomize inside a form, so the draw happens at the click. Each survey link
opens its entry point's control form or treatment form with probability 1/2, drawn in the browser (`Math.random() < 0.5`). The respondent sees nothing of either form before the draw. Draws are independent, and each entry point is a stratum.

### 4.3 Entry points and forms

Six forms: three entry points, two arms each. The form a response lands in records its entry point and its arm. Respondents see neither label.

| Entry point | Who arrives there | Control | Treatment |
|------|------------------|------|------|
| `landing` | the explorer's landing panel, "Take the survey first" | form 1 | form 2 |
| `explorer` | the survey button lower on the explorer page, and the overview page's survey button | form 3 | form 4 |
| `share` | the copied share link (`comparison/site/survey/`), including links already sent by email | form 5 | form 6 |

The landing panel is shown to every visitor of the explorer, once per browser, before the results. It is not randomized.

### 4.4 Page order (all six forms)

1. Description, then two pre-treatment questions:
   - "Do you consider yourself an expert in tax or fiscal policy?" (Yes / Somewhat / No; moved here
     from the end of the current survey)
   - "Before opening this survey, had you looked at news sources, web pages or academic studies
     discussing estimates of Proposition 40, the Billionaire Wealth Tax Proposal in California?"
     (Yes / No / Not sure; new)
2. I1 (treatment forms only).
3. The five required input questions, in three groups under plain section headings, in the order
   of the treatment page's first three terms (`GROUPS`, `regroup()` and `split_bundle()` in
   `mock_forms.py`):
   - "1. The income tax lost when billionaires leave": "The share of billionaires' income tax lost
     when people leave: which is more credible?", then how long the lost income tax is counted,
     then billionaires' yearly income tax. The three are ordered by each input's effect on the
     estimate averaged over all orders of the dials, largest first.
   - "2. The chance the tax survives in court": the court question.
   - "3. Billionaires who moved out in time": "Billionaires who moved out of California before
     the 1 January 2026 residency date: which is more credible?" It spans two of the page's terms
     (section 3).

   Then the opt-in to the five smaller inputs, whose page ("Five smaller inputs (optional)")
   follows: wealth that escapes the tax through avoidance and evasion, the wealth the tax applies
   to, non-citizen residents, the real-estate deduction, and the extra income tax from assets sold
   to pay the tax.

   The current survey bundles departures, avoidance and the share lost into one question. In all
   six forms that question becomes three: the share lost and moved out in time (required), and
   avoidance (optional), so both choices of each answer the same thing. The wealth question moves
   from the required questions to the optional page. I2 applies to all ten input questions in the
   treatment forms.
4. The closing page, "Anything else (optional)": missing inputs, optional email, and support for
   Proposition 40. Every question on it is optional.

The question order and the three headings are the same in both arms, so they are not part of the
treatment. They differ from the current survey's order. All six forms use one fixed choice order
within each question, that of the current version 1. The simulated pilot (section 9) showed no
sign that the first-listed value gains from its place: in the control forms the second-listed
value won the share-lost question (21 to 9) and the court question (18 to 4). The horizon question drops the
discount rate (author, 2026-10-16): "How long the lost income tax is counted: which is more
credible?", with the choices "For ever: billionaires who leave are assumed not to return." and "5
years, about the payment period, treating the departures as temporary." ("departures" replaced
"responses" on 2026-10-17, a word no respondent had been given a meaning for). The current survey's
"Which field best describes your work?" is dropped (author, 2026-10-16).

**Wording of the values (2026-10-17, after the simulated pilot; approved by the author the same
day).** In every input question the two values are the same kind of claim. Each gives a
reason, or neither does. Neither value argues against the other. The texts are generated by
`mock_forms.py` (`SHARE`, `DEPARTED`, `AVOID`, `INCOME`, `COURT`, `WEALTH`, `NONCIT`, `REAL`,
`ASSET`), with every number read from the exports. What changed, and why:

- The share lost now states both values on the same base, "of all the income tax that
  billionaires pay" (`comparison/DISPUTES.md`, row 6): 45%, more than the 29% of wealth reported
  to have left, against 5%, the same as the 5% of wealth assumed to leave. Each comes with its
  analysis's own reason. The old pair ("45% of
  all billionaires' income tax, whoever leaves" against "5%, only the income tax of those who
  leave") was read in three ways in the pilot: as a count of leavers, as shares of two different
  bases, and as losing the tax of those who stay. A respondent who accepts one analysis's count
  and the other's rule can now answer.
- The court question now asks whether to bring a court-risk discount into the estimate at all,
  "Discounting the revenue for the chance that courts strike the tax down": no discount, the
  tax assessed at face value, against the wealth tax collected multiplied by the chance the tax
  survives, put at 50%. The discount applies to the wealth tax collected, not to the whole
  estimate (JR chapter, PDF p.33; the comparison applies q to the wealth tax only). It
  drops "guesstimated", which all ten interviewees flagged, and neither value sounds careless. The question on billionaires who moved in time gives each value its own
  standard for counting a move. It no longer contains a rebuttal of the other value, or the third
  value (the "aggressive scenario") that interviewees read against both sides.
- The yearly income tax gives each value one assumption with its source, in the same words: the
  JR value names its two counts of top earners (212 and 500, read from the export's source note),
  the BSZ value the study of top wealth holders. The old JR value carried a range and its two
  bounds and the BSZ value one line ("halved"). The pilot split 30 to 3
  on it, and six of ten interviewees named the difference in length.
- Four of the five optional questions give both values the same form ("Taxed" and "Not taxed",
  "Counted" and "Not counted"). In the pilot the bare JR values ("None.", "Not counted.") drew
  0 or 1 choices each. The avoidance question keeps its pilot text ("5%: a small allowance argued
  from enforcement." against "None."), the author's choice. The BSZ wealth total now says how much of it is the non-US citizens asked
  about next.
- The description no longer promises "the reason given for each" value, says "most of these are
  empirical quantities", and says 5 to 10 minutes (careful readers took a median of 14 in the
  pilot). It ends with a sentence of motivation: the answers help get closer to agreeing on common
  facts for policy discussions. The opt-in says that the next five questions explain up to a stated
  share of the difference between the analyses (the net of the five dial-path steps over the gap,
  the explorer's "other" term) and make the survey a stated share longer (the optional section's words over the main
  part's), and that answering them is optional. The email question is "Your email (optional)":
  nothing is verified. After submitting, every form shows the same confirmation: thanks, the
  motivation sentence, and the address of the comparison explorer.

## 5. Outcomes

### 5.1 Coding of one answer

For respondent $i$ and required question $k$ ($k = 1$ to $5$, in the order the forms ask them: the share
of billionaires' income tax lost; how long the lost income tax is counted; billionaires' yearly
income tax; the chance the tax survives in court; billionaires who moved out in time):

- $y_{ik} = +1$ if the answer is the BSZ value,
- $y_{ik} = -1$ if the answer is the JR value,
- $y_{ik} = 0$ if the answer is "About equally credible" or "Unsure".

In the treatment forms the label gives the study. In the control forms the private Key tab of the
responses sheet gives which of A and B is the BSZ value in version 1's order. All five questions
are required, so no value is missing. The avoidance and wealth questions are now optional (section
4.4), so they are not among the five. In the share-lost question both values are shares of
the same total, the income tax billionaires pay, each shown with its analysis's reason.

### 5.2 Primary outcome

**The lean index**, $\mathrm{Lean}_i = (y_{i1} + y_{i2} + y_{i3} + y_{i4} + y_{i5}) / 5$. It runs from $-1$ (the JR value
on all five) to +1 (the BSZ value on all five). The primary outcome is the index, not any one of its
inputs.

### 5.3 Secondary outcomes

- S1. The share of the five questions answered "Unsure".
- S2. The share answered "About equally credible".
- S3. Each of the five $y_{ik}$, reported as three indicators (BSZ value, JR value, neutral answer).
- S4. The mean of $|\mathrm{Lean}_i|$, how far each respondent is from neutral, estimated with the H1
  equation. H1 is zero if naming the studies moves supporters of
  the tax toward the BSZ values and opponents toward the JR values by the same amount. S4 is not.
  The simulated pilot showed no such split ($|\mathrm{Lean}|$ 0.34 in control, 0.33 in treatment), so this
  is a check, not a prediction. Support for Proposition 40 is asked after the treatment, so it
  cannot split the sample for this test (section 6.2).

In the simulated pilot, "About equally credible" was 2% of the required answers and "Unsure" 45%.
The reasons given with "Unsure" on the horizon and court questions often said that neither value
was right ("100% is too high, but 50% is a guess"). S1 therefore mixes not knowing with rejecting
both values. The author keeps the two answers as they are (2026-10-17); the reasons given with
"Unsure" are reported alongside S1.

The five optional smaller-input questions, avoidance and the wealth base among them, are excluded from every
registered outcome, because only respondents who opt in answer them. Their answers are reported
descriptively.

## 6. Hypotheses and estimation

### 6.1 Main hypothesis (primary)

**H1.** $E[\mathrm{Lean} \mid T = 1] - E[\mathrm{Lean} \mid T = 0] = 0$, against the two-sided alternative that it is not 0.

Estimated by OLS with entry-point fixed effects (the strata):

$$\mathrm{Lean}_i = \alpha + \beta\, T_i + \gamma_{\mathrm{explorer}} E_{\mathrm{explorer},i} + \gamma_{\mathrm{share}} E_{\mathrm{share},i} + \varepsilon_i$$

H1 is $\beta = 0$. Standard errors are heteroskedasticity-robust (HC2). The test is at the 5% level. The
robustness specification adds the two pre-treatment answers as indicators.

Secondary outcomes S1 to S3 are estimated with the same equation. The five S3 outcomes are adjusted
with the Romano-Wolf step-down procedure within each answer type (section 6.3).

### 6.2 Heterogeneity (all secondary)

Every heterogeneity test below is secondary. None changes the conclusion on H1.

The plan declares D = 3 candidate dimensions, all binary and recorded before treatment: entry
point (H2), prior exposure (H3) and expertise (H4). Whether a respondent gives an email is asked
after treatment, so it is descriptive and is not one of the three. No other dimension is used
unless it is registered before the data are seen, and adding one enlarges every family below.

H2 to H4 are the one-dimension analyses. They form one family of $\binom{3}{1} = 3$ tests, adjusted
together with the Romano-Wolf procedure. Each is one interaction coefficient, estimated in the H1 equation
with the subgroup indicator and its interaction with T added:

$$\mathrm{Lean}_i = \alpha + \beta\, T_i + \delta\,(T_i \times G_i) + \lambda\, G_i + \gamma_{\mathrm{explorer}} E_{\mathrm{explorer},i} + \gamma_{\mathrm{share}} E_{\mathrm{share},i} + \varepsilon_i$$

The test is $\delta = 0$ against $\delta \neq 0$, with HC2 standard errors.

- **H2, entry point.** $G_i = 1$ if the response came through the `explorer` button, 0 if through
  `landing` or `share`. Prediction: the effect is smaller in absolute value for `explorer`, whose
  respondents have just seen the comparison on the page. The entry point is not randomized:
  differences in levels between entry points describe who arrives where. Within each entry point,
  T is randomized. For H2, the entry-point fixed effects already contain G.
- **H3, prior exposure.** $G_i = 1$ if the answer to the prior-exposure question is "No", 0 if "Yes" or
  "Not sure". Prediction: the effect is larger in absolute value for G = 1.
- **H4, expertise.** $G_i = 1$ if the answer to the expertise question is "Yes" or "Somewhat", 0 if
  "No". No direction is predicted.

Analyses that cross two or three dimensions are staged secondary analyses (section 7). Crossing $k$
dimensions gives $2^k$ cells. The $k$-way difference of effects is the coefficient on
$T \times G_1 \times \dots \times G_k$ in the saturated version of the H1 equation, with HC2 standard errors. Each order is its own
Romano-Wolf family over every combination of the three dimensions: $\binom{3}{2} = 3$ two-way differences, and
one three-way difference. The effects inside the cells form their own families: 6 for one
dimension (3 dimensions x 2 halves), 12 for two (3 pairs x 4 cells), and 8 for three.

Both subgroup questions are asked before the treatment page, so treatment cannot change them.
Support for Proposition 40 stays on the closing page, after treatment, and is not used for any
registered test (decided 2026-10-17: asking it first would prime both arms). It is optional, so
the share who answer it is reported by arm alongside its descriptive results.

### 6.3 Multiple testing

Every family of secondary tests (the five questions of S3, the one-dimension interactions, the
two-way and three-way differences, the effects inside cells) is adjusted with the Romano-Wolf
step-down procedure (Romano and Wolf 2005; the algorithm of Clarke, Romano and Wolf 2020). The
procedure controls the family-wise error rate over the bootstrap distribution of the largest
studentized statistic in the family, so correlated tests cost less than under Holm or Bonferroni,
and the five questions and the index are correlated. The statistics are the HC2 t-statistics of
the registered equations. The bootstrap resamples respondents with replacement within each
entry-point stratum, 2,000 draws, seed fixed before the data are seen. The power appendix states
the thresholds under this procedure and the Bonferroni bound they sit below.

## 7. Power and staged analyses

The number of responses is unknown: it may be a few dozen or a few hundred. The plan therefore
has one main hypothesis with one outcome (H1, the lean index), tested whatever the number of
responses. Further analyses are run only once the realized number of responses N reaches the
threshold at which each can detect a standardized effect of 0.5 SD with 80% power. The thresholds, their formulas and
simulations of the registered estimator are in the power appendix,
`comparison/survey/power/power.pdf` (built from `power.tex` and `sim.py`, which generates every
number in it).

Summary (the appendix's Table 1): responses needed for 80% power against an effect of 0.3 SD,
equal shares, the Romano-Wolf step-down within each family. "RW" is the simulated Romano-Wolf
threshold; "Bound" is the closed-form Bonferroni bound it sits below. A dagger marks a family
whose tests are nearly independent, where the simulation found no threshold below the bound and
the bound is used. For the five questions, column A is 0.3 SD on a question and column B is the
smaller question-level effect (about 0.18 SD) that goes with 0.3 SD on the index. For
heterogeneity, column A is the effect inside each cell and column B is the highest-order
difference of effects. Each family covers every combination of the three dimensions.

| | Analysis | A: tests | A: RW | A: bound | B: tests | B: RW | B: bound |
|--|--------------------------|-----|------|------|-----|------|------|
| 1 | Main hypothesis H1, the lean index | 1 | 349 | | | | |
| 2 | H1 by outcome, each of the five questions | 5 | 410 | 520 | 5 | 1,130 | 1,433 |
| 3 | Heterogeneity, one dimension at a time (3 combinations, 2 cells each) | 6 | 890 | 1,077 | 3 | 1,862 (dagger) | 1,862 |
| 4 | Heterogeneity, two dimensions at a time (3 combinations, 4 cells each) | 12 | 1,960 | 2,443 | 3 | 7,445 (dagger) | 7,445 |
| 5 | Heterogeneity, three dimensions at a time (1 combination, 8 cells) | 8 | 3,670 | 4,547 | 1 | 22,326 | |

Staged rule (the appendix's Table 4), at the registered target of 0.5 SD with equal shares. The
Romano-Wolf threshold governs; the bound is given for reference.

| Tier | Analysis | Tests | Responses needed (RW) | Bound |
|----|--------------------------------|----|----------------|---------|
| 0 | H1, the lean index | 1 | always run; detects 0.5 SD from 126 | |
| 1 | Each of the five questions | 5 | 150 (about 390 for an effect matching 0.5 SD on the index) | 187 (479) |
| 2a | One dimension at a time: the effect inside each half (expertise, prior exposure, entry point; email descriptively) | 6 | 320 (540 if one half holds a quarter) | 388 (776) |
| 2b | One dimension at a time: the difference between the halves (H2 to H4) | 3 | 660 (880 if one half holds a quarter) | 671 (894) |
| 3a | Two dimensions at a time: the effect inside each of four cells | 12 | 690 | 880 |
| 3b | Two dimensions at a time: the two-way difference | 3 | 2,681 (dagger) | 2,681 |
| 4a | Three dimensions: the effect inside each of eight cells | 8 | 1,290 | 1,637 |
| 4b | Three dimensions: the three-way difference (one test) | 1 | 8,038 | |
| 5 | Each question inside each half, one dimension at a time | 30 | 390 (about 1,010 for an effect matching 0.5 SD on the index) | 509 (1,302) |

Heterogeneity is unlocked one order at a time. Two-dimension analyses are run only if the
one-dimension analyses of the same kind are run, and three-dimension analyses only if the
two-dimension ones are. Each added dimension multiplies the responses a difference of effects
needs by about four, because the cells halve in size and the difference adds cells.

The rule uses only N and the realized shares of pre-treatment subgroups at the close, so it does
not depend on the results. An analysis below its threshold is reported as "not run: below its
threshold". The table's numbers come from the appendix (`out/summary.tex` and `out/thresholds.tex`); if the
appendix is regenerated, it governs. The appendix's simulations use 199 bootstrap draws inside each
simulated sample, fewer than the registered 2,000, so its thresholds lean high.

In the lean index's own units, with the simulated index SD of about 0.5 (an assumption, not a
measurement), 0.5 SD is a change of 0.25 in the mean index. That is, for example, 125 one-step
answer moves per 100 treated respondents (a step is neutral to a study's value, or the other value
to neutral), or a quarter of treated respondents moving all five answers one step. 0.4 SD is 0.20
(100 moves per 100, or 20% moving all five answers). 0.3 SD is 0.15 (75 moves per 100, or 15%).
0.2 SD is 0.10 (50 moves per 100, or 10%). 0.1 SD is 0.05 (25 moves per 100, or 5%). The
appendix's Table 3 and Figure 1 give these, with the responses H1 needs at each size.

## 8. Checks, attrition and exclusions

- **Sample.** Every response submitted to the six forms in the window. Excluded: test responses
  made before launch (deleted from the sheet), and responses to the two current forms, which
  predate the experiment and are reported on their own.
- **Attrition.** Google Forms records only submitted responses. If the comparison page makes people
  quit, the treated respondents would differ from the controls. Checks, reported whatever the
  result:
  1. Within each entry point, the number of submissions per arm against an even split (exact
     binomial test).
  2. The two pre-treatment answers compared across arms (chi-squared tests).
  3. A count of draws. Each click on a survey link sends one request, at the draw, carrying only
     the entry point and the arm (no identifier, no cookie). The registered attrition check is
     submissions divided by draws, by arm and entry point. The binomial test above is the
     fallback if the count fails. With 100 submissions it detects only a split of about 60 to
     40, and a respondent who quits on the comparison page leaves no other trace.
- **Duplicates.** Of responses with the same email, only the first is kept. Anonymous duplicates cannot be detected. One person can land in both arms, which shrinks any measured effect.
- **Bulk and automated submissions.** Google Forms does not screen out automated submissions. A
  bot that posts to one form's address skips the draw at the click, so it fills one arm only. That
  would bias the estimate, not only add noise. The rule is fixed before launch. Three or more
  submissions to the same form within ten minutes, with identical answers to every choice
  question, count as one submission, and only the first is kept. The number removed per form is
  reported. H1 is also reported with no response removed. A burst in one arm also shows in the
  per-arm count check above.
- **Respondents who give an email.** Their answers are also reported separately, as the survey
  promises. The registered analysis uses all responses.
- **Links that skip the draw.** The share page sends the
  browser to the form's own address, which a respondent can copy and forward. Everyone who opens a
  forwarded form address lands in one arm. The share page's fallback for browsers without
  JavaScript also opens one form. Neither group can be identified in the data. The share post and
  the Copy link button ask people to share the project link, not the form's address, and the
  fallback opens the share pair's control form. A form with many submissions and few draws is
  the sign of a forwarded address.

## 9. Timeline, registration and priors

- **Registration.** On the AEA RCT Registry, before the six forms open.
- **Launch.** The forms open together with the site change. The launch commit is recorded here.
- **Close.** 4 November 2026. Responses submitted after it are not part of this analysis.
  Responses submitted after the vote of 3 November 2026 and before the close count. The time of
  submission is recorded, and an indicator for "after the vote" is a covariate in the robustness
  specification of H1, reported alongside the main estimate.
- **Pretest.** On 2026-10-17, 100 simulated respondents (language-model agents given personas,
  entry paths and arms) took mock versions of the six forms, and ten of them were interviewed
  (`feedback/008-2026-10-17-rct-pilot/`). The pretest tested wording and comprehension only. Its
  answers are not data for this study. The question texts were revised after it (section 4.4).
- **No interim analysis.** Before the close, only response counts per form are looked at.
- **Priors.** No forecasts of the effect are collected.
- **Deviations.** Any change after registration is logged at the end of this file with its date
  and reason.

**How to launch.**

1. Run the Apps Script that `comparison/survey/gas_build.py` writes. It builds the six forms,
   named "exp: Prop 40 survey (<entry>, <arm>)". Each form takes about 110 seconds and a run
   stops at six minutes, so a run builds three forms; before running again, move the half-built
   fourth form to the trash (the builder skips any form whose name exists), then run again.
2. Paste each form's respondent link into `comparison/data/survey-links.csv`, in the row of its
   entry point and arm (`python3 comparison/survey/fill_links.py LOG.txt` does it from the
   execution log). Delete the comment line about placeholders.
2b. The thank-you screen after Submit carries the two short links (tinyurl.com/prop40-explorer and
   tinyurl.com/prop40-opa); `fixEnding()` sets it in forms built before 2026-10-17 afternoon. No link
   sits before Submit: a control respondent could open it, go Back and change answers.
3. Deploy `comparison/survey/draws.gs` as a web app (execute as me, anyone can access), as its
   header says. Paste its URL into `comparison/data/survey-config.csv` as `draws_url`.
4. Rebuild with `Rscript comparison/run.R`, then run `Rscript comparison/tests/testthat.R`.
5. Commit, and record the commit under "Launch" above.
6. Register on the AEA RCT Registry. Then push: the push puts the six forms' links on the site.

## 10. Limits

- **Who answers.** The results describe people who take the survey, not experts in general. The
  randomization makes the two arms comparable, not representative.
- **Prior exposure.** Many respondents will have seen the overviews or the explorer before the
  survey, which shrinks the effect. H2 and H3 are there to show it.
- **A bundled treatment.** I1 adds how much of the gap each of four groups of inputs explains. I2
  adds which study holds each value. Naming the studies may move answers through views of the authors or of the tax, not only
  through the numbers. H1 measures the two together.
- **Terms and questions differ.** The page's four terms do not match the five questions one to one
  (section 3). Only for the court question does the page give that input's own amount. A
  question-level effect (S3) therefore cannot be read as a response to that question's amount on
  the page.
- **Neutrality.** The control forms keep the survey's rule of naming neither analysis. The treatment
  forms name both, by design.
- **The sides can be told apart without labels.** In the simulated pretest, the persona's view of
  wealth taxes predicted the lean index as strongly in the control forms as in the treatment forms
  (a gap of 0.68 between the personas who favour and oppose them, against 0.71), because a value's
  content shows which side it helps. Respondents from the explorer have also seen each value's
  study on the dials. The labels may therefore add less than their presence suggests, which
  shrinks the effect that H1 can find.
- **What the entry texts promised.** The drafts of the public post that carries the share link
  said the survey "names neither analysis", which is false for the treatment forms; in the
  pretest, ten of the eighteen simulated respondents who came by that link to a treatment form
  noticed the contradiction. The drafts were edited on 2026-10-17, before posting: no promise
  about naming, "5 to 10 minutes", and a request to pass on the project link rather than the
  form's address.

## 11. Decisions taken

All of the open decisions were settled on 2026-10-17: the two current forms close when the six
forms open; the overview's survey button sends to the `explorer` pair; the value texts revised
after the pretest (section 4.4); the treatment page (Appendix A); the bulk-submission rule, the
draw count and the links that skip the draw (section 8); the secondary outcome S4 (section 5.3);
the close date and the post-vote responses (section 9); the expected number of responses, 50 to
200 (section 2); the Romano-Wolf adjustment (section 6.3); the two neutral answers, kept as they
are (section 5.1); the public post, edited before posting (section 10); and the support question,
kept after treatment (section 6.2).

## Appendix A. Treatment page text

Generated by `python3 comparison/survey/gas_build.py ITEMS.json SOURCE_FORM_ID` (the Apps Script
that builds the forms) and previewed by `python3 comparison/survey/mock_forms.py ITEMS.json
OUT_DIR`. The text comes from `STUDIES_LEAD`, `STUDIES`, `INTRO`, `TERMS`, `NOTE` and `CLOSE` in
`mock_forms.py`. The page has a title, a lead sentence ("Two academic studies estimate what
Proposition 40 is worth to California:") with one bullet per study, its month and its estimate,
two paragraphs (the gap and the common measure; the two largest terms and their share), the four
terms of section 3 with the BSZ and JR values of the first three, a two-sentence note (why the
lost income tax is one term, and that each amount depends on the order in which the inputs are
changed), and one closing sentence. The registered version will include the full text as
generated at the registered commit.
