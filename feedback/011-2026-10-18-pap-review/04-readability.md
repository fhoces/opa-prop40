# PAP review, 2026-10-18: readability

This review reads `comparison/survey/PRE-ANALYSIS-PLAN.md` (563 lines, branch `review/pap-2026-10-18`) as a careful reader outside economics would, against the author's editing rules. Line numbers refer to that file, and a quoted passage joins the file's wrapped lines with one space. No replacement changes a number, a symbol, a hypothesis or an estimator. The plan contains no em-dash and no en-dash (checked character by character: the file is pure ASCII), and no AUTHOR DECISION tag applies below.

1. **Section 1, lines 17 to 21. Severity A.** The plan never says what Proposition 40 is, who wrote the two studies, what "the comparison explorer" is, or what "the OPA" (lines 30 and 112) stands for. "BSZ" and "JR" are expanded only inside a parenthesis at line 40, and "disputed input" is not explained. A reader who has not used the site meets section 1 with no referents.

   Current: "The Proposition 40 survey asks respondents which of two proposed values of each disputed input they find more credible. The comparison explorer shows the same inputs, which study uses which value, and what each value does to the estimate. Most respondents will have seen that comparison on the site before they open the survey. This study asks whether restating it, with each value labelled by its study, at the moment respondents choose the input values changes the answers."

   New: "Proposition 40 is a California ballot measure. It would tax Californians worth $1 billion or more once, at 5% of their net worth. Two academic studies estimate what the tax is worth to the state: Boll, Saez and Zucman (the BSZ analysis) and Jaros and Rauh (the JR analysis). One finds that the tax raises money for the state and the other that it loses money. This project is an Open Policy Analysis (OPA) of the two. Its website puts both estimates on one measure and shows, on a page called the comparison explorer, which inputs explain the gap between them. The project's survey asks respondents which of two proposed values of each disputed input (an input on which the two analyses use different values) they find more credible. The comparison explorer shows the same inputs, which study uses which value, and what each value does to the estimate. Most respondents will have seen that comparison on the site before they open the survey. This study asks whether the answers change when the comparison is restated at the moment respondents choose the input values, with each value labelled by its study."

   The words "worth $1 billion or more once, at 5% of their net worth" are the form's own description (Appendix B). With this paragraph in place, "the OPA" at lines 30 and 112, "the site" at line 19 and "the overview page" at line 104 need no further change.

2. **Section 6.1, lines 259 to 263, and section 6.2, lines 281 to 285. Severity A.** The registered equation uses $T_i$, $E_{\mathrm{share},i}$, $\alpha$, $\beta$, $\gamma$ and $\varepsilon_i$ without defining them. $E_{\mathrm{share},i}$ appears nowhere in words. "OLS", "fixed effects" and "heteroskedasticity-robust" are undefined, and "robustness specification" is described here with two covariates and in section 9 (line 434) with a third. The heterogeneity equation adds $G_i$, $\delta$ and $\lambda$, with $G_i$ defined only as "the subgroup indicator".

   Current (line 259): "Estimated by OLS with entry-point fixed effects (the strata):"

   New: "H1 is estimated by ordinary least squares (OLS), a linear regression of the lean index on the treatment indicator and an indicator for the entry point (the stratum of section 4.2):"

   Current (lines 263 to 264): "H1 is $\beta = 0$. Standard errors are heteroskedasticity-robust (HC2). The test is at the 5% level. The robustness specification adds the two pre-treatment answers as indicators."

   New: "Here $T_i$ is 1 if respondent $i$ was drawn into the treatment arm and 0 if into control. $E_{\mathrm{share},i}$ is 1 if the response came through the `share` entry point and 0 if through `explorer`. $\alpha$, $\beta$ and $\gamma$ are coefficients to be estimated, and $\varepsilon_i$ is the error term. H1 is $\beta = 0$. Standard errors are heteroskedasticity-robust (HC2). Such standard errors allow the lean index to vary more in one arm or entry point than in another, and the HC2 variant corrects for small samples. The test is at the 5% level. A second estimate, reported for robustness, adds the two pre-treatment answers (expertise and prior exposure) as indicator variables and, as section 9 states, an indicator for responses submitted after the vote."

   Current (lines 280 to 281): "Each is one interaction coefficient, estimated in the H1 equation with the subgroup indicator and its interaction with T added:"

   New: "Each of H2 to H4 tests one interaction coefficient, estimated in the H1 equation with the subgroup indicator $G_i$ and its interaction with $T_i$ added:"

   Current (line 285): "The test is $\delta = 0$ against $\delta \neq 0$, with HC2 standard errors."

   New: "$G_i$ is the subgroup indicator defined under each hypothesis below, $\lambda$ is its coefficient, and $\delta$ is the difference between the treatment effect inside the subgroup ($G_i = 1$) and outside it ($G_i = 0$). The test is $\delta = 0$ against $\delta \neq 0$, with HC2 standard errors."

3. **Status line, line 10, and section 9, line 430. Severity B.** "AEA RCT Registry" is never expanded. A reader outside economics does not know what AEA or RCT stand for.

   Current (line 10): "Status: the version registered on the AEA RCT Registry (trial 19997) on 2026-10-19, before the forms open."

   New: "Status: the version registered on the AEA RCT Registry (the American Economic Association's registry of randomized controlled trials) as trial 19997 on 2026-10-19, before the forms open."

   Line 430 then keeps "the AEA RCT Registry" (see finding 15 for its sentence).

4. **Labels used before or without a definition. Severity B.** Each line below uses a label that is defined later or never.

   - Line 79, "the horizon question" (also lines 160 and 244). Current: "since the horizon question no longer asks about it." New: "since the question on how long the lost income tax is counted (the horizon question, section 4.4) no longer asks about it."
   - Line 123, "the current survey" (also lines 147, 156 and 163). Current: "moved here from the end of the current survey)". New: "moved here from the end of the current survey, the version 1 forms that have been open since before the experiment)".
   - Line 157, "version 1". Current: "that of the current version 1." New: "that of the current survey (version 1)."
   - Lines 135 to 136, "the dials" (also line 487). Current: "The three are ordered by each input's effect on the estimate averaged over all orders of the dials, largest first." New: "The three are ordered by each input's effect on the estimate, averaged over every order in which the explorer's dials (the controls that switch each input between its two values) can be turned, largest first." At line 487, "on the dials" becomes "on the explorer's dials".
   - Line 185, "all ten interviewees" (also lines 187 and 192; interviews are introduced only at line 437). Current: "which all ten interviewees flagged". New: "which all ten interviewees of the first pretest (section 9) flagged".
   - Line 223, "the lean index" and "S1 and S2" before their definitions. Current: "Both score 0 in the lean index, and S1 and S2 report them separately." New: "Both score 0 in the lean index (section 5.2), and the secondary outcomes S1 and S2 (section 5.3) report them separately."
   - Lines 225 to 226, "the private Key tab of the responses sheet" and "version 1's order". Current: "In the control forms the private Key tab of the responses sheet gives which of A and B is the BSZ value in version 1's order." New: "In the control forms, a private tab named Key in the spreadsheet that collects the responses gives which of A and B is the BSZ value, in the choice order of the current survey (version 1)."
   - Line 302, "N" (defined at line 333). Current: "and is run only once N reaches that family's threshold (section 7)." New: "and is run only once the realized number of responses, N, reaches that family's threshold (section 7)."

5. **Statistical terms left unexplained. Severity B.** Each sentence below uses a term a reader outside economics cannot follow. The replacements keep every symbol and number.

   - Line 96, "stratum". Current: "Draws are independent, and each entry point is a stratum." New: "Draws are independent. Each entry point is a stratum: a group within which the draw is made, and which the analysis accounts for with its own indicator (section 6.1)."
   - Line 257, the expectation notation. After the sentence "**H1.** $E[\mathrm{Lean} \mid T = 1] - E[\mathrm{Lean} \mid T = 0] = 0$, against the two-sided alternative that it is not 0." add: "In words, the mean lean index in the treatment arm equals the mean in the control arm."
   - Line 273, "dimensions". Current: "The plan declares D = 3 candidate dimensions, all binary and recorded before treatment: entry point (H2), prior exposure (H3) and expertise (H4)." New: "The plan declares D = 3 candidate dimensions, that is, respondent characteristics along which the effect may differ. All are binary and recorded before treatment: entry point (H2), prior exposure (H3) and expertise (H4)."
   - Line 280, the binomial coefficient. Current: "($\binom{3}{1} = 3$ and H5)". New: "($\binom{3}{1} = 3$ one-dimension tests, one per dimension, and H5)".
   - Line 291, a dropped term with no reason. Current: "For H2, G is the entry-point indicator itself, so $\lambda G_i$ is dropped." New: "For H2, $G_i$ is the entry-point indicator itself, so $\lambda G_i$ is dropped, because it would duplicate $E_{\mathrm{share},i}$."
   - Lines 306 to 308, "saturated version" and "order". Current: "The $k$-way difference of effects is the coefficient on $T \times G_1 \times \dots \times G_k$ in the saturated version of the H1 equation, with HC2 standard errors. Each order is its own Romano-Wolf family over every combination of the three dimensions:" New: "The $k$-way difference of effects is the coefficient on $T \times G_1 \times \dots \times G_k$ in the saturated version of the H1 equation (the equation with the $k$ subgroup indicators, all their products, and the product of each with $T$ added), with HC2 standard errors. The order of an analysis is the number of dimensions it crosses. Each order is its own Romano-Wolf family over every combination of the three dimensions:"
   - Line 314, "prime". Current: "(decided 2026-10-17: asking it first would prime both arms)". New: "(decided 2026-10-17, because asking it first would put the vote in respondents' minds, in both arms, before they judged the values)".
   - Lines 333 to 334, "standardized effect", "SD" and "power". After the sentence ending "with 80% power." add: "A standardized effect is the effect divided by the standard deviation (SD) of the outcome in the control group. 80% power means an 80% chance of rejecting the null hypothesis when the true effect is of that size. The target of 0.5 SD is a medium effect by the usual convention."

6. **Section 6.3, lines 319 to 327. Severity B.** One sentence carries "family-wise error rate", "bootstrap distribution", "studentized statistic", "Holm" and "Bonferroni" with no explanation, and the bootstrap sentence is a fragment. The citation parenthesis is semicolon-joined.

   Current (line 321): "(Romano and Wolf 2005; the algorithm of Clarke, Romano and Wolf 2020)". New: "(Romano and Wolf 2005, computed with the algorithm of Clarke, Romano and Wolf 2020)".

   Current (lines 321 to 326): "The procedure controls the family-wise error rate over the bootstrap distribution of the largest studentized statistic in the family, so correlated tests cost less than under Holm or Bonferroni, and the five questions and the index are correlated. The statistics are the HC2 t-statistics of the registered equations. The bootstrap resamples respondents with replacement within each entry-point stratum, 2,000 draws, seed fixed before the data are seen."

   New: "The procedure keeps the chance of at least one false rejection in the family at 5% (the family-wise error rate). It does so by comparing each test statistic with the bootstrap distribution of the largest statistic in the family. Tests that move together therefore cost less than under the Holm or Bonferroni corrections, which treat every test as if it were independent. The five questions and the index are correlated, so the saving matters here. The statistics are the HC2 t-statistics of the registered equations. The bootstrap resamples respondents with replacement within each entry-point stratum. It uses 2,000 draws, with the random seed fixed before the data are seen, so that the draws are reproducible and not chosen after the results are known."

7. **Section 6.1, lines 266 to 267. Severity B.** "Within each answer type" is ambiguous. It can mean three families of five tests (one for the BSZ indicator, one for the JR indicator, one for the neutral indicator), which section 6.3 and Table 1 row 2 ("the five questions", 5 tests) suggest, or something else.

   Current: "The five S3 outcomes are adjusted with the Romano-Wolf step-down procedure within each answer type (section 6.3)."

   New: "The five S3 outcomes form one Romano-Wolf family of five tests for each answer type (the BSZ indicator, the JR indicator and the neutral indicator), adjusted with the step-down procedure of section 6.3."

   The author confirms that this is the intended reading before the replacement is applied. If a different family is meant, the sentence should state it in the same explicit form.

8. **Section 3, lines 51 to 58. Severity B.** The table's amounts carry signs (three negative, one positive) that the surrounding text never explains, and the introducing line is a fragment with a semicolon.

   Current (line 51): "The four terms, as generated at the launch commit (section 9; gap $145.8 billion):[^terms]"

   New: "The four terms, as generated at the launch commit (section 9), follow. The gap is $145.8 billion. A negative amount means that the term lowers the estimate as the inputs move from the BSZ values to the JR values, and a positive amount that it raises it.[^terms]"

9. **Section 3, lines 41 to 47. Severity B.** "The gap between them and the explorer's common measure" reads as a gap between two things. "Prestige cue" and "NBER" are unexplained, "the comparison explorer's equation" is never described, and "(below)" points nowhere in particular.

   Current (lines 41 to 42): "Neither bullet names a venue: both are NBER papers, and a venue on one side only would be a prestige cue inside the treatment."

   New: "Neither bullet names a venue. Both are working papers of the National Bureau of Economic Research (NBER). Naming a venue for one study only would signal that it is the more reputable one, and that signal would become part of the treatment."

   Current (line 43): "It then gives the gap between them and the explorer's common measure. It then splits the gap into the four terms of the comparison explorer's equation, largest first."

   New: "It then gives the gap between the two estimates and names the common measure on which the explorer puts both. Next it splits the gap into the four terms of the comparison explorer's equation (a sum, one term per group of inputs, that adds up to the gap), largest first."

   Current (lines 46 to 47): "A two-sentence note says why the lost income tax is one term (below) and that each amount depends on the order in which the inputs are changed."

   New: "A two-sentence note says why the lost income tax is one term (explained after the table below) and that each amount depends on the order in which the inputs are changed."

10. **Section 10, lines 483 to 486. Severity B.** The parenthesis "(a gap of 0.68 between the personas who favour and oppose them, against 0.71)" does not say which number belongs to which arm, and the sentence runs over four clauses.

    Current: "In the simulated pretest, the persona's view of wealth taxes predicted the lean index as strongly in the control forms as in the treatment forms (a gap of 0.68 between the personas who favour and oppose them, against 0.71), because a value's content shows which side it helps."

    New: "In the simulated pretest, each persona's view of wealth taxes predicted its lean index as strongly in the control forms as in the treatment forms. On average, the lean index of the personas who favour wealth taxes and that of the personas who oppose them differed by 0.68 in the control forms and by 0.71 in the treatment forms. The reason is that a value's content shows which side it helps."

    The sentence order suggests that 0.68 is the control figure and 0.71 the treatment figure. The author confirms this before the replacement is applied.

11. **Section 8, lines 396 to 426. Severity B.** Several entries are fragments, "it" at line 408 has two possible referents, "share it" at line 424 does not say what is shared, and "the share pair's control form" is an undefined label.

    - Current (lines 396 to 398): "**Sample.** Every response submitted to the four open forms (3 to 6) in the window. Excluded: test responses made before launch (deleted from the sheet), and responses to the two current forms, which predate the experiment and are reported on their own." New: "**Sample.** The sample is every response submitted to the four open forms (3 to 6) in the window. Two kinds of response are excluded: test responses made before launch (deleted from the sheet), and responses to the two current forms, which predate the experiment and are reported on their own."
    - Current (lines 402 to 403): "Within each entry point, the number of submissions per arm against an even split (exact binomial test)." New: "Within each entry point, the number of submissions per arm is compared with an even split (exact binomial test)."
    - Current (line 404): "The two pre-treatment answers compared across arms (chi-squared tests)." New: "The two pre-treatment answers are compared across arms (chi-squared tests)."
    - Current (line 405): "A count of draws. Each click on a survey link sends one request," New: "A count of draws is kept. Each click on a survey link sends one request,"
    - Current (lines 408 to 409): "With 100 submissions it detects only a split of about 60 to 40, and a respondent who quits on the comparison page leaves no other trace." New: "With 100 submissions the binomial test detects only a split of about 60 to 40. A respondent who quits on the comparison page leaves no other trace."
    - Current (lines 423 to 425): "The Copy link button copies the share page's address, not a form's address (the public posts no longer ask readers to share it, section 11), and the fallback opens the share pair's control form." New: "The Copy link button copies the share page's address, not a form's address. The public posts no longer ask readers to pass on the project link rather than the form's address (section 11). The fallback for browsers without JavaScript opens the control form of the `share` entry point (form 5)."

12. **Section 9, lines 430 to 433. Severity B.** Two fragments, a sentence that promises a launch commit "here" but gives none, and "count" used as a verb where a reader expects a noun.

    - Current (line 430): "**Registration.** On the AEA RCT Registry, before the four forms open." New: "**Registration.** The plan is registered on the AEA RCT Registry before the four forms open."
    - Current (line 431): "The launch commit is recorded here." New: "The launch commit is recorded here at launch: [commit hash]." The author fills in the hash at step 5 of "How to launch".
    - Current (lines 432 to 433): "**Close.** 4 November 2026. Responses submitted after it are not part of this analysis. Responses submitted after the vote of 3 November 2026 and before the close count." New: "**Close.** Collection closes on 4 November 2026. Responses submitted after the close are not part of this analysis. Responses submitted after the vote of 3 November 2026 and before the close are included."

13. **Section 11, lines 498 to 516. Severity B.** Two paragraphs are single sentences of ten and four semicolon-joined items. The S4 item, dated 2026-10-18, sits in the list of decisions "settled on 2026-10-17". At line 514 "It stays descriptive (section 5)" has an unclear referent and points to a section that does not mention the email.

    Current (lines 498 to 504): the paragraph beginning "All of the open decisions were settled on 2026-10-17:" and ending "kept after treatment (section 6.2)."

    New:

    "The decisions that were open in earlier drafts were settled on 2026-10-17. Each is listed with the section that records it.

    - The two current forms close when the new forms open.
    - The overview page's survey button sends to the `explorer` pair of forms.
    - The value texts were revised after the pretest (section 4.4).
    - The treatment page was fixed (Appendix A).
    - The bulk-submission rule, the draw count and the links that skip the draw were set (section 8).
    - The close date and the treatment of post-vote responses were set (section 9).
    - The Romano-Wolf adjustment was adopted (section 6.3).
    - The two neutral answers are kept as they are (section 5.1).
    - The public post was edited before posting (section 10).
    - The support question is kept after treatment (section 6.2)."

    Current (lines 506 to 511): the paragraph beginning "Later on 2026-10-17, before launch, the author made four more decisions:".

    New:

    "Later on 2026-10-17, before launch, the author made four more decisions.

    - The `landing` entry point and its panel are dropped, so forms 1 and 2 are never opened and the experiment is framed as a test of salience (sections 1 and 4.3).
    - The expected number of responses is 0 to 200 (section 2).
    - The expert respondents without prior exposure form a registered subgroup (section 6.2).
    - The share link keeps opening a form, so that some respondents may not have seen the estimates."

    Current (lines 513 to 514): "On 2026-10-18, before launch, the author moved the email question from the closing page to page 1, after the two pre-treatment questions (section 4.4). It stays descriptive (section 5)."

    New: "On 2026-10-18, before launch, the author moved the email question from the closing page to page 1, after the two pre-treatment questions (section 4.4). Whether a respondent gives an email stays a descriptive variable, not a registered dimension (sections 6.2 and 8). Also on 2026-10-18, the author dropped the former secondary outcome S4 (the mean absolute lean index)."

    The S4 sentence moves here from the 2026-10-17 list, where its date did not fit. Nothing about the decision changes.

14. **One name for the pretests. Severity B.** The same events are called "the simulated pilot" (lines 157, 166, 243), "the pilot" (lines 175, 177, 191, 194, 195, 200), "the pretest" (lines 436, 439, 491, 500) and "the simulated pretest" (line 483). Section 9 names two pretests, and the text does not always say which one a number comes from. Use "pretest", the word of section 9, throughout, and say "first" or "second" where a number comes from one of them.

    - Line 157: "The simulated pilot (section 9)" becomes "The [first or second] pretest (section 9)".
    - Line 166: "after the simulated pilot" becomes "after the first pretest".
    - Line 175: "in the pilot" becomes "in the first pretest".
    - Line 191: "The pilot split 30 to 3 on it" becomes "The first pretest split 30 to 3 on it" (see also finding 17).
    - Line 194: "In the pilot" becomes "In the first pretest".
    - Line 195: "keeps its pilot text" becomes "keeps its first-pretest text".
    - Lines 199 to 200: "in the pilot" becomes "in the [first or second] pretest".
    - Line 243: "In the simulated pilot" becomes "In the [first or second] pretest".
    - Line 483: "In the simulated pretest" becomes "In the [first or second] pretest".

    Lines 166, 175, 191, 194 and 195 concern the wording that the first pretest tested, so "first" is certain there. The author fills in the bracketed ones.

15. **Section 4.4, lines 180 to 187. Severity B.** The court-question bullet also describes the moved-out question, carries a colon-joined definition, an undefined symbol "q", and the only bare "JR" in the plan's prose ("JR chapter").

    Current: "- The court question now asks whether to bring a court-risk discount into the estimate at all, "Discounting the revenue for the chance that courts strike the tax down": no discount, the tax assessed at face value, against the wealth tax collected multiplied by the chance the tax survives, put at 50%. The discount applies to the wealth tax collected, not to the whole estimate (JR chapter, PDF p.33; the comparison applies q to the wealth tax only). It drops "guesstimated", which all ten interviewees flagged, and neither value sounds careless. The question on billionaires who moved in time gives each value its own standard for counting a move. It no longer contains a rebuttal of the other value, or the third value (the "aggressive scenario") that interviewees read against both sides."

    New (two bullets):

    "- The court question now asks whether to bring a court-risk discount into the estimate at all. Its title is "Discounting the revenue for the chance that courts strike the tax down". The two values are no discount, with the tax assessed at face value, against the wealth tax collected multiplied by the chance the tax survives, put at 50%. The discount applies to the wealth tax collected, not to the whole estimate (the JR analysis's chapter, PDF p.33). The comparison explorer likewise applies that chance (its symbol q) to the wealth tax only. The question drops "guesstimated", which all ten interviewees of the first pretest (section 9) flagged, and neither value sounds careless.
    - The question on billionaires who moved out in time gives each value its own standard for counting a move. It no longer contains a rebuttal of the other value, or the third value (the "aggressive scenario") that interviewees read against both sides."

16. **Section 4.4, lines 198 to 206, the opt-in sentence. Severity B.** One sentence carries three statements and two compressed parentheses ("the net of the five dial-path steps over the gap", "the optional section's words over the main part's").

    Current: "The opt-in says that the next five questions explain up to a stated share of the difference between the analyses (the net of the five dial-path steps over the gap, the explorer's "other" term) and make the survey a stated share longer (the optional section's words over the main part's), and that answering them is optional."

    New: "The opt-in says three things. First, the next five questions explain up to a stated share of the difference between the analyses. That share is the net effect of the five inputs' steps on the explorer's dial path, divided by the gap, and it is the explorer's "other" term. Second, answering them makes the survey a stated share longer. That share is the number of words in the optional section divided by the number of words in the main part. Third, answering them is optional."

17. **Compressed phrases in sections 3 and 4. Severity B.** Each phrase below says less than the reader needs.

    - Lines 75 to 76. Current: "The BSZ value (an allowance for unnamed movers, half of the BSZ avoidance allowance) sits in the fourth." New: "The BSZ value (an allowance for unnamed movers, which is half of the BSZ analysis's allowance for avoidance) sits in the fourth term, together with the rest of that allowance."
    - Lines 115 to 117. Current: "For this reason the experiment mainly tests the salience of that information when respondents choose the input values, not their first exposure to it." New: "For this reason the experiment mainly tests salience, that is, whether bringing that information back to mind at the moment respondents choose the input values changes the answers, and not the effect of a first exposure to it."
    - Lines 147 to 149. Current: "In all the forms that question becomes three: the share lost and moved out in time (required), and avoidance (optional), so both choices of each answer the same thing." New: "In all the forms that question becomes three: the share lost and moved out in time (both required), and avoidance (optional). The two values offered in each of the three then concern one and the same input."
    - Lines 162 to 163. Current: "("departures" replaced "responses" on 2026-10-17, a word no respondent had been given a meaning for)". New: "("departures" replaced "responses" on 2026-10-17, because no respondent had been given a meaning for "responses")".
    - Lines 178 to 179. Current: "A respondent who accepts one analysis's count and the other's rule can now answer." New: "A respondent who accepts one analysis's count of the wealth that left but the other analysis's rule for which income tax is lost can now answer." The author confirms that this is the intended meaning.
    - Lines 190 to 192. Current: "The old JR value carried a range and its two bounds and the BSZ value one line ("halved"). The pilot split 30 to 3 on it, and six of ten interviewees named the difference in length." New: "The old JR value carried a range and its two bounds, and the old BSZ value was one line ("halved"). In the first pretest 30 respondents chose the [JR or BSZ] value and 3 the other, and six of ten interviewees named the difference in length as a reason." The author fills in which value drew 30.
    - Lines 196 to 197. Current: "The BSZ wealth total now says how much of it is the non-US citizens asked about next." New: "The BSZ value of the wealth total now says how much of that total belongs to the non-US citizens asked about in the next question."

18. **Section 7, lines 339 to 341, 356 to 357 and 386 to 389. Severity B.** The two table introductions are fragments, "other halves equal" is compressed, and the definition of a "step" sits inside a parenthesis in the middle of an example.

    - Current (lines 339 to 341): "Summary (the appendix's Table 1): responses needed for 80% power against an effect of 0.3 SD, the two entry points at 60% (`explorer`) and 40% (`share`) and other halves equal, the Romano-Wolf step-down within each family. "RW" is the simulated Romano-Wolf threshold; "Bound" is the closed-form Bonferroni bound it sits below." New: "The table below summarizes the appendix's Table 1. It gives the responses needed for 80% power against an effect of 0.3 SD, with the Romano-Wolf step-down applied within each family. It assumes that 60% of responses come through `explorer` and 40% through `share`, and that expertise and prior exposure each split the responses in half. "RW" is the simulated Romano-Wolf threshold. "Bound" is the closed-form Bonferroni bound, which the RW threshold sits below."
    - Current (lines 356 to 357): "Staged rule (the appendix's Table 4), at the registered target of 0.5 SD with the same shares. The Romano-Wolf threshold governs; the bound is given for reference." New: "The staged rule follows (the appendix's Table 4). It is set at the registered target of 0.5 SD, with the same shares. The Romano-Wolf threshold governs. The bound is given for reference."
    - Current (lines 383 to 384): "so its thresholds lean high." New: "so its thresholds err on the high side." ("Lean" is also the name of the index.)
    - Current (lines 387 to 389): "That is, for example, 125 one-step answer moves per 100 treated respondents (a step is neutral to a study's value, or the other value to neutral), or a quarter of treated respondents moving all five answers one step." New: "That is, for example, 125 one-step answer moves per 100 treated respondents, or a quarter of treated respondents moving all five answers one step. A step takes one answer from neutral to a study's value, or from the other study's value to neutral."

19. **Colon-joined clauses. Severity B.** A colon joins two clauses at each line below (the plan's other colons introduce lists, definitions or quotations and are fine).

    - Line 29. Current: "**Sample size.** Not controlled: it is whoever responds in the window." New: "**Sample size.** The sample size is not controlled. It is whoever responds in the window."
    - Line 36. Current: "Nothing is delivered to the control group: it is a pure control." New: "Nothing is delivered to the control group, which makes it a pure control."
    - Lines 157 to 159. Current: "The simulated pilot (section 9) showed no sign that the first-listed value gains from its place: in the control forms the second-listed value won the share-lost question (21 to 9) and the court question (18 to 4)." New: "The [first or second] pretest (section 9) showed no sign that the first-listed value gains from its place. In its control forms the second-listed value won the share-lost question (21 to 9) and the court question (18 to 4)."
    - Lines 188 to 190. Current: "The yearly income tax gives each value one assumption with its source, in the same words: the JR value names its two counts of top earners (212 and 500, read from the export's source note), the BSZ value the study of top wealth holders." New: "The yearly income tax gives each value one assumption with its source, in the same words. The JR value names its two counts of top earners (212 and 500, read from the export's source note). The BSZ value names the study of top wealth holders."
    - Lines 289 to 290. Current: "The entry point is not randomized: differences in levels between entry points describe who arrives where." New: "The entry point is not randomized. Differences in levels between entry points therefore describe who arrives where."
    - Line 331. Current: "The number of responses is unknown: the expected range is 0 to 200 (section 2)." New: "The number of responses is unknown. The expected range is 0 to 200 (section 2)."
    - Lines 459 to 460. Current: "No link sits before Submit: a control respondent could open it, go Back and change answers." New: "No link sits before Submit, because a control respondent could open it, go Back and change answers."
    - Line 465. Current: "Then push: the push puts the four forms' links on the site." New: "Then push. The push puts the four forms' links on the site."

20. **Semicolon-joined clauses. Severity B.** A semicolon joins two clauses at each line below. (The semicolons inside the short parentheses at lines 122, 126 and 128, and the list inside the parenthesis at lines 212 to 214, separate list items rather than clauses; changing them is optional.)

    - Lines 40 to 41. Current: "(Boll, Saez and Zucman, BSZ; Jaros and Rauh, JR)". New: "(Boll, Saez and Zucman, the BSZ analysis, and Jaros and Rauh, the JR analysis)".
    - Lines 166 to 167. Current: "**Wording of the values (2026-10-17, after the simulated pilot; approved by the author the same day).**" New: "**Wording of the values (revised 2026-10-17, after the first pretest, and approved by the author the same day).**"
    - Lines 246 to 247. Current: "The author keeps the two answers as they are (2026-10-17); the reasons given with "Unsure" are reported alongside S1." New: "The author keeps the two answers as they are (2026-10-17). The reasons given with "Unsure" are reported alongside S1."
    - Lines 372 to 373. Current: "Explorer respondents have all seen the comparison, so the subgroup will sit mostly in the `share` stratum; the rule is applied at the realized shares." New: "Explorer respondents have all seen the comparison, so the subgroup will sit mostly in the `share` stratum. The rule is applied at the realized shares."
    - Lines 382 to 383. Current: "The table's numbers come from the appendix (`out/summary.tex` and `out/thresholds.tex`); if the appendix is regenerated, it governs." New: "The table's numbers come from the appendix (`out/summary.tex` and `out/thresholds.tex`). If the appendix is regenerated, the regenerated appendix governs."
    - Lines 441 to 442. Current: "ran the revised forms through this plan's analysis (`feedback/009-2026-10-17-rct-pilot-2/`); its answers are not data either." New: "ran the revised forms through this plan's analysis (`feedback/009-2026-10-17-rct-pilot-2/`). Its answers are not data either."
    - Lines 452 to 454. Current: "Each form takes about 110 seconds and a run stops at six minutes, so a run builds three forms; before running again, move the half-built fourth form to the trash (the builder skips any form whose name exists), then run again." New: "Each form takes about 110 seconds and a run stops at six minutes, so a run builds three forms. Before running again, move the half-built fourth form to the trash, because the builder skips any form whose name exists. Then run again."
    - Lines 458 to 459. Current: "The thank-you screen after Submit carries the two short links (tinyurl.com/prop40-explorer and tinyurl.com/prop40-opa); `fixEnding()` sets it in forms built before 2026-10-17 afternoon." New: "The thank-you screen after Submit carries the two short links (tinyurl.com/prop40-explorer and tinyurl.com/prop40-opa). `fixEnding()` adds them to forms built before the afternoon of 2026-10-17."
    - Lines 490 to 491. Current: "which is false for the treatment forms; in the pretest, ten of the eighteen simulated respondents who came by that link to a treatment form noticed the contradiction." New: "which is false for the treatment forms. In the pretest, ten of the eighteen simulated respondents who came by that link to a treatment form noticed the contradiction."
    - Line 531. Current: "(the gap and the common measure; the two largest terms and their share)". New: "(one on the gap and the common measure, one on the two largest terms and their share)".
    - Lines 562 to 563. Current: "carry the same text as forms 3 and 4; only Google's internal item ids differ." New: "carry the same text as forms 3 and 4. Only Google's internal item ids differ."

21. **Fragments. Severity B.** Each line below is a sentence without a main verb (fragments covered by findings 11, 12 and 18 are not repeated).

    - Line 11. Current: "Structure follows the minimal elements of a clear hypothesis:" New: "The structure follows the minimal elements of a clear hypothesis:"
    - Line 36. Current: "Two manipulations, both delivered only in the treatment forms." New: "There are two manipulations. Both are delivered only in the treatment forms."
    - Lines 38 to 39. Current: "**I1, the comparison page.** One page, "How the two estimates differ", shown after the opening questions and before the input questions." New: "**I1, the comparison page.** This is one page, titled "How the two estimates differ", shown after the opening questions and before the input questions."
    - Line 100. Current: "Four forms: two entry points, two arms each." New: "There are four forms: one control form and one treatment form for each of two entry points."
    - Lines 142 to 145. Current: "Then the opt-in to the five smaller inputs, whose page ("Five smaller inputs (optional)") follows: wealth that escapes the tax through avoidance and evasion, the wealth the tax applies to, non-citizen residents, the real-estate deduction, and the extra income tax from assets sold to pay the tax." New: "Then comes the opt-in to the five smaller inputs. Their page ("Five smaller inputs (optional)") follows it and asks about wealth that escapes the tax through avoidance and evasion, the wealth the tax applies to, non-citizen residents, the real-estate deduction, and the extra income tax from assets sold to pay the tax."
    - Line 233. Current: "**The lean index**, $\mathrm{Lean}_i = (y_{i1} + y_{i2} + y_{i3} + y_{i4} + y_{i5}) / 5$. It runs from" New: "**The lean index.** For respondent $i$, $\mathrm{Lean}_i = (y_{i1} + y_{i2} + y_{i3} + y_{i4} + y_{i5}) / 5$, the mean of the five coded answers of section 5.1. It runs from"
    - Lines 526 to 528. Current: "Generated by `python3 comparison/survey/gas_build.py ITEMS.json SOURCE_FORM_ID` (the Apps Script that builds the forms) and previewed by `python3 comparison/survey/mock_forms.py ITEMS.json OUT_DIR`." New: "The page is generated by `python3 comparison/survey/gas_build.py ITEMS.json SOURCE_FORM_ID` (the Apps Script that builds the forms) and previewed by `python3 comparison/survey/mock_forms.py ITEMS.json OUT_DIR`."

22. **Appendix A framing, lines 529 to 534. Severity C.** One sentence lists six parts of the page with nested parentheses.

    Current: "The page has a title, a lead sentence ("Two academic studies estimate what Proposition 40 is worth to California:") with one bullet per study, its month and its estimate, two paragraphs (the gap and the common measure; the two largest terms and their share), the four terms of section 3 with the BSZ and JR values of the first three, a two-sentence note (why the lost income tax is one term, and that each amount depends on the order in which the inputs are changed), and one closing sentence."

    New:

    "The page has six parts.

    - A title.
    - A lead sentence ("Two academic studies estimate what Proposition 40 is worth to California:") with one bullet per study, giving its month and its estimate.
    - Two paragraphs, one on the gap and the common measure and one on the two largest terms and their share.
    - The four terms of section 3, with the BSZ and JR values of the first three.
    - A two-sentence note, on why the lost income tax is one term and on each amount depending on the order in which the inputs are changed.
    - One closing sentence."

    If finding 20's change to line 531 is applied instead, this one can be skipped.

23. **Title, line 1. Severity C.** "Salience of study information and credibility assessment of key assumptions and inputs" is a chain of nouns.

    Current: "# Pre-analysis plan for a study of salience of study information and credibility assessment of key assumptions and inputs"

    New: "# Pre-analysis plan: a survey experiment on the salience of study information when respondents judge the credibility of disputed inputs"

24. **Opening note, lines 4 to 6. Severity C.** The "so that" clause can attach to "the optimistic case" or to "was written".

    Current: "The plan was written for the optimistic case, in which enough people respond for a study to be conducted with the data, so that the analysis is fixed before any response is seen."

    New: "The plan was written for the optimistic case, in which enough people respond for a study to be conducted with the data. It was written now so that the analysis is fixed before any response is seen."

25. **Claims without a reason. Severity C.**

    - Line 410. Current: "One person can land in both arms, which shrinks any measured effect." New: "One person can land in both arms, which shrinks any measured effect, because that person's answers then appear on both sides of the comparison."
    - Line 473. Current: "H2 and H3 are there to show it." New: "H2 and H3 are there to show how much."

26. **"How to launch", lines 450 to 465. Severity C.** The steps run 1, 2, 2b, 3, 4, 5, 6, and "Apps Script" is a product name a reader may not know. Renumber the steps 1 to 7 (2b becomes 3, and the later steps move up by one), and at line 450 change "Run the Apps Script that `comparison/survey/gas_build.py` writes." to "Run the Google Apps Script program that `comparison/survey/gas_build.py` writes." The cross-reference at line 464 ("record the commit under "Launch" above") is unaffected.

27. **Appendix A, line 541. Severity C, outside the readability lens.** Not a rewrite request: the quoted page text must match its source. The plan writes the JR estimate as "-$39.0 billion" with a hyphen-minus (U+002D), while the live treatment form's page text (`comparison/survey/plan/forms/treatment.json`) writes "−$39.0 billion" with the Unicode minus sign (U+2212). Either the generator writes a hyphen and the form builder converts it, or the plan's copy is not byte-identical with the form. The author checks which text is canonical before registration. No readability change is proposed to the quoted text.
