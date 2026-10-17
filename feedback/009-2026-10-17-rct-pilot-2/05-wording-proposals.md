# Wording proposals for the comparison OPA after the survey pilot, 2026-10-17

Read-only review (Opus agent). No page was edited. The approved survey wording (`comparison/survey/mock_forms.py`,
rendered in `00-materials/survey-control.txt` and `survey-treatment.txt`) and the pilot's findings
(`feedback/008-2026-10-17-rct-pilot/03-interview-analysis.md` and `04-improvements.md`) were set against every
comparison surface: the explorer's tips and page text, the overview, the report, the deck and `comparison/DISPUTES.md`.

How to read an item. "Current" is quoted from the source file. "Proposed" replaces it. "Survey" is the approved
survey text it follows. Line numbers are from the working tree during this review. Two agents are editing
`comparison/R/site.R` and the explorer template, so find a line by its token name.

The pilot's wording rule: both values are the same kind of claim; each gives a reason or neither does; neither
argues against the other; no loaded words; shares on the same base; one assumption per value, with its source. The
site's own tip rules still hold. A tip runs at most three lines at 390 px, gives one reason per end and ends with
"Kind:". It names no source. No proposed tip is longer than the longest tip the explorer has now (the f symbol tip,
180 characters). Run the `explorer-tip-audit` skill after any tip change.

Nothing in `feedback/DECISIONS.md` is raised again. Item 23 reopens an author label from the site conventions
(2026-10-15) and says so.

## A. Explorer dial tips (`comparison/R/site.R`)

The overview's "The differences" table is built from these tips (`q_cell()` reads `end_tips`). Each change
therefore lands on both pages.

1. **f symbol tip** (`slider_tips$income_loss_share`, l.439). Minor.
   - Current: "The share of billionaires' income tax lost to leavers."
   - Proposed: "The share of all billionaires' income tax lost to leavers." (the rest unchanged; four characters longer)
   - Survey Q3: "45% of all the income tax that billionaires pay". In the pilot, 7 of 10 read "only the income tax of those who leave" as a different base.

2. **f end tips** (`end_tips$income_loss_share`, l.483 and l.486). Substantive.
   - Current BSZ: "The BSZ rule: only the leavers' own income tax is lost, with the movers from a assumed to pay a proportional share. Leavers in D add theirs, from tax filings."
   - Current JR: "The JR rule: %s of all billionaires' income tax, whoever leaves, from a draw set around the %s of wealth that left. It covers unreported moves too."
   - Proposed BSZ: "The BSZ rule: no more than the share of wealth that leaves, because the largest reported leavers pay little income tax for their wealth."
   - Proposed JR: "The JR rule: more than the %s of wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported."
   - Survey Q3: "more than the 29% of their wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported" against "the same as the 5% of their wealth assumed to leave, because the largest of the billionaires reported to have left pay little income tax for their wealth."
   - Why: each end becomes one rule against the same yardstick, the share of wealth. Six pilot respondents read "whoever leaves" as taxing those who stay. The mechanics (movers in a, leavers in D) stay in the symbol tip and the box's "more".

3. **D end tips** (`end_tips$confirmed_departures`, l.470 and l.471). Substantive.
   - Current BSZ: "BSZ: no named move counted, since press reports do not establish a residence change before 1 January. Half of a is people who left in time."
   - Current JR: "JR: seven publicly reported moves, by Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks."
   - Proposed BSZ: "BSZ: no one counted by name without evidence of a change of legal residence before 1 January. Half of a is people who moved in time."
   - Proposed JR: "JR: seven billionaires counted as having moved in time, on public reports of their moves: Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks."
   - Survey Q11: "seven billionaires (...) are counted as having moved in time, on public reports of their moves" against "with no one counted by name without evidence of a change of legal residence before the date."
   - Why: the BSZ end now argues against the JR value, and five pilot respondents repeated that rebuttal as their own reason (F5). Each end now states its own standard, and the JR end gains its reason.

4. **D symbol tip and the middle-stop note** (`slider_tips$confirmed_departures`, l.434; the page script in `comparison/site/explorer.template.html`, l.720). Minor.
   - Current tip: "Middle stop: BSZ Table 5 row 3, where Page, Thiel, Hankey and Kalanick left in time."
   - Current note: "The BSZ analysis's aggressive case (Table 5 row 3), four leavers."
   - Proposed tip: "Middle stop: a BSZ scenario (Table 5 row 3) counting Page, Thiel, Hankey and Kalanick as moved."
   - Proposed note: "A BSZ scenario (Table 5 row 3): four billionaires counted as having moved in time."
   - Survey Q11 dropped "aggressive scenario", which all 10 interviewees read against both analyses. The tip states the four moves as fact and the note calls them aggressive. Both now say "counted as".

5. **D's name and the revenue box lead** (`DIAL_NAMES$confirmed_departures`, l.224; `EXPLORER_BOXES$revenue$lead`, l.173). Minor.
   - Current: "wealth already gone"; "D the part already gone".
   - Proposed: "wealth counted as moved out"; "D the part counted as moved out in time".
   - Survey: the group heading "3. Billionaires who moved out in time", and the author's rule against "are gone". The symbol word "departed" (`DIAL_WORDS`) stays, an author choice of 2026-10-15.

6. **a symbol tip and BSZ end tip** (`slider_tips$avoidance`, l.435; `end_tips$avoidance`, l.473). Substantive.
   - Current tip: "The share of the tax lost to avoidance and evasion, including moves by people no one names (D holds the named ones)."
   - Current BSZ end: "BSZ: a small allowance, argued from enforcement rather than estimated. Half of it is moving away, which also costs income tax (f)."
   - Proposed tip: "The share of the wealth that escapes the tax through avoidance and evasion, including moves no one names (D holds the named ones)."
   - Proposed BSZ end: "BSZ: a small allowance argued from enforcement. Half is people who moved out in time, who also cost income tax (f); half is avoidance."
   - Survey Q14: "Wealth that escapes the tax through avoidance and evasion, beyond moving away" with "5%: a small allowance argued from enforcement."
   - Why: the survey splits the BSZ 10% into 5% moved out (Q11) and 5% avoidance (Q14), while the explorer shows 10% on a. Naming both halves lets a respondent who follows the survey's closing link find its two numbers. "rather than estimated" argues against the value, and "Kind: guesswork" already says it.

7. **q symbol tip** (`slider_tips$litigation_survival`, l.436). Substantive.
   - Current: "The chance that the tax survives a court challenge, applied to the revenue."
   - Proposed: "The chance that the tax survives a court challenge. Below 100%, it discounts the revenue for the chance courts strike the tax down."
   - Survey Q9: "Discounting the estimate for the chance that courts strike the tax down". The dial keeps its name and its 100% and 50% ends (author decision 2026-10-15). The tip keeps "revenue", which is correct (see item 42).

8. **q end tips** (`end_tips$litigation_survival`, l.478 and l.479). Substantive.
   - Current BSZ: "BSZ: collected in full; its expert report argues the Act was designed to stay clear of constitutional issues."
   - Current JR: "JR: half the revenue, the 'more likely than not' line an accounting rule (ASC 740-10) uses to judge whether a tax stands."
   - Proposed BSZ: "BSZ: no discount; the tax is assessed at face value, as written. The authors' expert report judges it drafted to stay clear of constitutional issues."
   - Proposed JR: "JR: a discount; the revenue is multiplied by the chance the tax survives, which the authors set at the 'more likely than not' threshold of ASC 740-10."
   - Survey Q9: "No discount: the tax is assessed at face value, as written." against "A discount: ... put at 50%."
   - Why: the survey dropped both reasons because 6 of 10 interviewees read "argues" as advocacy and "an accounting rule" as official. The tip rule needs one reason per end, so the two reasons get the same subject ("the authors") and the same kind of verb.

9. **C end tips** (`end_tips$income_level`, l.489 and l.490). Substantive.
   - Current BSZ: "BSZ: from tax data, since top wealth holders earn about half of what top earners do."
   - Current JR: "JR: the middle of $%s billion to $%s billion, both estimated from tax data. The floor's pool of 500 filers is the authors' judgement."
   - Proposed BSZ: "BSZ: from California tax data, taking billionaires to have about half the income of the state's highest earners, as a study of top wealth holders finds."
   - Proposed JR: "JR: from California tax data, taking billionaires to be among the state's %s to %s highest earners: the middle of $%s billion to $%s billion."
   - Survey Q7: "from California tax data, taking the billionaires to be among the state's 212 to 500 highest earners" against "from California tax data, taking the billionaires to have about half the income of the state's highest earners, as a study of top wealth holders finds."
   - Why: now the JR end carries a remark against its own value and no reason, and the BSZ end a reason. The pilot split this question 30 to 3 on length and on "halved". Read 212 and 500 from the export's source note, as `_K` in `mock_forms.py` does.

10. **H BSZ end tip** (`end_tips$horizon`, l.498). Minor.
    - Current: "BSZ: about the payment period, treating the responses as temporary."
    - Proposed: "BSZ: about the payment period, treating the departures as temporary."
    - Survey Q5: "5 years, about the payment period, treating the departures as temporary." (F19: no reader has been told what "responses" respond to.)

11. **W JR end tip** (`end_tips$base_list`, l.464). Minor.
    - Current: "JR: the 2025 list, %s billionaires, grown %s to the 31 December 2026 valuation date: %s."
    - Proposed: "JR: the Forbes list of 2025, %s California billionaires, grown %s to the 31 December 2026 valuation date: %s."
    - Survey Q15: "The Forbes list of 2025: 212 California billionaires" against "The Forbes list of 1 July 2026: 250 California billionaires". The two ends get the same form.

12. **Non-citizens end tips** (`end_tips$noncitizens`, l.513 and l.514). Minor.
    - Current BSZ: "BSZ: taxed like any other California resident."
    - Current JR: "JR: left out. The 28 non-citizen billionaires live in California, but the chapter deems them too uncertain to collect from (treaties, apportionment)."
    - Proposed BSZ: "BSZ: taxed. The non-citizen billionaires are in the base, like any other California resident."
    - Proposed JR: "JR: not taxed. The 28 non-citizen billionaires are left out of the base, since the chapter judges collecting from them too uncertain (treaties, apportionment)."
    - Survey Q16: "Taxed: ... is in the base." against "Not taxed: ... is left out of the base." The same lead words. "but ... deems" sets a fact against the JR choice.

13. **Real-estate tips** (`slider_tips$real_estate`, l.447; `end_tips$real_estate`, l.516 and l.517; `end_tips$minor_inputs`, l.511). Minor.
    - Current: "The share of the base deducted for directly held homes."; "BSZ: no deduction."; "JR: nets out directly held real estate, about 0.5% of the base."; "homes deducted".
    - Proposed: "The share of the base deducted for directly held real estate."; "BSZ: no deduction. Directly held real estate stays in the base."; "JR: a deduction. Directly held real estate, about 0.5% of the base, is taken out of it."; "real estate deducted".
    - Survey Q17: "No deduction: directly held real estate stays in the base." against "A deduction: directly held real estate, about 0.5% of the base, is taken out of it." The explorer now says "homes" twice and "real estate" once.

14. **Asset-sale end tips** (`end_tips$asset_sales`, l.519 and l.520). Minor.
    - Current BSZ: "BSZ: one third, an assumption (BSZ p.24: "paid one-third by selling assets")."
    - Current JR: "JR: does not count this extra income tax."
    - Proposed BSZ: "BSZ: counted. One third of the tax is paid by selling assets, and the gains on them are taxed."
    - Proposed JR: "JR: not counted. No extra income tax from selling assets is included."
    - Survey Q18: "Counted: one third of the tax is paid by selling assets, and the gains on them are taxed." against "Not counted: no extra income tax from selling assets is included." "an assumption" repeats the Kind label on one end only. The page reference breaks the no-sources tip rule; the overview's table adds the source itself.

## B. Explorer page text (`comparison/site/explorer.template.html`, `comparison/R/site.R`)

15. **The venue on one analysis only** (template l.371 and l.373, the standfirst; l.415 and l.436, the panel captions). Minor.
    - Current: "(Boll, Saez and Zucman, August 2026)" and "(Jaros and Rauh, NBER, September 2026)".
    - Proposed: "(Boll, Saez and Zucman, NBER, August 2026)" in both places, as the overview's first paragraph prints it.
    - Survey treatment page: "Jaros and Rauh (JR, September 2026)", with no venue on either (F12: NBER on one side only read as a prestige cue). The pages may name the venue, but on both analyses or neither.

16. **The BSZ headline definition** (template l.385). Minor.
    - Current: "Over 5 years: the wealth tax, net of the income tax it adds and loses."
    - Proposed: the overview's definition, "Net total: the wealth tax, plus income tax from assets sold to pay it, minus income tax lost to leavers over 5 years, in today's dollars".
    - Survey treatment page: "Both are on one measure: the wealth tax collected, plus the extra income tax from assets sold to pay it, minus the income tax lost when people leave." The JR definition beside it ends "in today's dollars". The BSZ one has a different form and no "in today's dollars".

17. **The "actual quantities" subtitle** (`q_table()`, l.591, and `tok$quantity_survey_x`, l.627; pinned by `comparison/tests/testthat/test-site.R`, l.556). Minor.
    - Current: "Most of these are empirical quantities; H and r are scenario choices. Their values should not depend on whether one supports or opposes a wealth tax. An expert should be able to appraise each value from more to less credible."
    - Proposed: "Most of these are empirical quantities, and none should depend on whether one supports or opposes a wealth tax. H and r are scenario choices. An expert should be able to judge which of the two values is more credible."
    - Survey description: "Most of these are empirical quantities, and none should depend on whether one supports or opposes a wealth tax." and "Tell us which value you find more credible." The survey asks for a choice between two values, not a ranking.

18. **The survey share line** (`survey_button`, l.623). Minor.
    - Current: "Share this survey with people you think have expertise in this area, to learn what they think these values are."
    - Proposed: "Share this survey with people you think have expertise in this area, to learn which values they find more credible."
    - Survey: "Tell us which value you find more credible." The button above it already reads "which values are more credible?" (`SURVEY_LABEL`). The line under it still invites people to give their own values, as #3 and #23 expected to in the pilot (F22).

## C. Kind labels

The survey says "Most of these are empirical quantities". On the explorer, eight of the eleven values carry "guesswork" or "guesswork on data". The two statements answer different questions: whether the quantity could be observed, and what evidence backs this value. The pages do not say so.

19. **Say what a kind measures** (explorer notes, `#kinds`, template l.512 to 516; overview `comparison/site/index.template.html` l.530 to 535; `comparison/DISPUTES.md`, "Kind labels"). Minor.
    - Current: "<b>guesswork</b> (asserted without data or a study behind it)"
    - Proposed: "<b>guesswork</b> (an assumption with no data or study behind it)". Add at the end of each Kinds note: "A kind says what evidence is behind a value, not whether the quantity itself can be observed."
    - Survey description: "Most of these are empirical quantities". "asserted" reads close to the "guesstimated" the pilot flagged (10 of 10). DISPUTES.md already words it "an assumption the authors assert".

20. **q's BSZ kind** (`bridge_steps()$kind`, `comparison/R/model.R` l.96, mirrored in `comparison/py/bridge.py` l.103; DISPUTES.md row 9; the deck's slide (ii)). Substantive.
    - Current: "guesswork" at both ends.
    - Proposed: "scenario vs guesswork". The BSZ value is the Act as written, a choice of what to estimate. The JR value is a legal judgement.
    - Survey Q9: "No discount: the tax is assessed at face value, as written." Under the survey's framing the BSZ end is a choice of whether to discount, which the pages define as a scenario ("a choice of which world is estimated"). `test-site.R` l.615 accepts "scenario".

21. **C's JR kind** (`bridge_steps()$kind`, model.R l.97; DISPUTES.md row 5). Substantive.
    - Current: "research vs guesswork".
    - Proposed: "research vs guesswork on data".
    - Survey Q7: both values "from California tax data, taking the billionaires to ...". The JR bounds are fits to California's top-earner tax data, with a judgement on which earners the billionaires are. That is the pages' own definition of guesswork on data. The pilot interviewer noted that the tips rate the two values the other way round from the pilot's 30 to 3 split. The author decides; the label is also in DISPUTES.md and in the deck's (iii) table.

## D. Shared step labels and table cells

`bridge_steps()$title` (model.R l.77 to 88, mirrored in `py/bridge.py` l.99 to 109) names the equation's terms on the explorer and the overview, the Apply block, the report's tables and the deck. `step_texts()` (site.R l.59 to 88) fills three report tables and two deck tables.

22. **D's step title** (model.R l.81, bridge.py l.101). Minor.
    - Current: "Billionaires already departed"
    - Proposed: "Billionaires who moved out in time"
    - Survey: the group heading "3. Billionaires who moved out in time". The overview note pinned by `test-site.R` l.201 ("the departed wealth") need not change.

23. **q's term label** (model.R l.83, bridge.py l.103). Substantive; it reopens an author label.
    - Current: "Chance the tax does not survive litigation"
    - Proposed: "Discount for the chance courts strike the tax down"
    - Survey Q9: "Discounting the estimate for the chance that courts strike the tax down". The current label is the author's choice of 2026-10-15 (site conventions, "Term label"), made before today's reframing. Ask before changing. The dial keeps "survives" and its 100% and 50% ends either way.

24. **Share-lost cells** (`step_texts()`, l.63 and l.64). Substantive.
    - Current BSZ: "the movers' proportional share, plus named leavers' own tax"; current JR: `sprintf("%s of all", ...)`, printed "45% of all".
    - Proposed BSZ: "no more than the share of wealth that leaves (the movers' proportional share, plus named leavers' own tax)"; proposed JR: "45% of all, more than the share of wealth that left".
    - Survey Q3: both values as a share of "all the income tax that billionaires pay", each set against the share of wealth that leaves.
    - Why: the cells pair a rule on the leavers' own tax with a share of all tax, the pair the pilot found read three ways (F1). They print in the report's bridge, Shapley and disputed-inputs tables and in the deck's (iii) table.

25. **Departures cells** (`step_texts()`, l.70 and l.71). Minor.
    - Current BSZ: "no named leaver"; current JR: "seven moves: %s on the BSZ list, %s on the JR list".
    - Proposed BSZ: "none counted by name"; proposed JR: "seven counted by name: %s on the BSZ list, %s on the JR list".
    - Survey Q11 states both values as who is counted ("are counted as having moved in time"; "no one counted by name"). The same noun at both ends. The dial's end labels ("None named", "7 moves", review 005 U-12) stay.

## E. Overview (`comparison/site/index.template.html`)

The overview's differences table reads the explorer's end tips, so items 1 to 14 apply there too.

26. **The first paragraph** (l.303 to 307). Substantive.
    - Current: "finds that it raises about {{bsz_round_words}} of wealth tax (its Table 5 prints {{bsz_printed}}). The JR analysis (...) finds that it leaves the state about {{nber_npv_round}} poorer (their paper prints an average of {{nber_printed}}), because billionaires who leave stop paying California income tax for ever."
    - Proposed: "finds that it raises about {{bsz_round_words}} of wealth tax (its Table 5 prints {{bsz_printed}}), or {{hl_bsz}} net of the income tax it adds and loses over five years. The JR analysis (...) finds that it leaves the state about {{nber_npv_round}} poorer, net of the income tax lost for ever (their paper prints an average of {{nber_printed}})."
    - Survey treatment page: both estimates "on one measure", with no reason given for either.
    - Why: the paragraph gives the BSZ figure gross and the JR figure net, and only the JR figure gets a "because". The added clause is 13 words and the removed one 12, so the byline does not grow.

27. **The two analysis cards** (l.405 and l.413). Minor.
    - Current BSZ: "The Forbes list on 1 July 2026, less a 10% allowance for avoidance and evasion, half of it billionaires who moved away."
    - Current JR: "Person-by-person base, observed departures, a litigation weight, lost income tax for ever."
    - Proposed BSZ: "The Forbes list of 1 July 2026, a 10% allowance for avoidance and evasion (half of it people who moved out in time), no court discount, lost income tax for 5 years."
    - Proposed JR: "The Forbes list of 2025 grown to the valuation date, seven reported moves, a court discount, lost income tax for ever."
    - Survey: one value per input, in parallel (Q15, Q11, Q9, Q5). "observed departures" is the JR chapter's own framing; the survey says "on public reports of their moves". Both cards now name the same four inputs in the same order.

## F. Report (`comparison/site/repro.qmd`, `comparison/R/build.R`)

28. **The introduction's first paragraph** (repro.qmd l.127 to 133). Substantive. Same issue as item 26.
    - Current: "estimates about `r bsz_round_words` of wealth tax (...). The JR analysis finds the state about ... poorer in today's dollars (...), because billionaires who leave stop paying California income tax for ever."
    - Proposed: after the BSZ parenthesis, add ", or `r usd(eb$bsz_model)` net of the income tax it adds and loses over five years". Replace the "because" clause with "net of the income tax lost for ever".
    - Survey treatment page: "Both are on one measure".

29. **"aggressive" and "whoever leaves" in the seven quantities** (repro.qmd l.370 and l.391). Minor.
    - Current: "the BSZ analysis's aggressive scenario (Table 5 row 3)"; "a flat share `f0` is lost whoever leaves (...). At the aggressive stop".
    - Proposed: "the BSZ analysis's Table 5 row 3 scenario, which counts four named billionaires as having moved in time"; "a flat share `f0` of all billionaires' income tax is lost, set above the share of wealth that left (...). At the middle stop".
    - Survey: Q11 dropped "aggressive scenario". Q3 dropped "whoever leaves", which pilot respondents read as taxing those who stay.

30. **f defined as "the share of the income tax base that leaves"** (repro.qmd l.330 and l.489). Minor.
    - Current: "f the share of the income tax base that leaves"; "the share of the income tax base that leaves".
    - Proposed: "f the share of all billionaires' income tax that is lost"; "the share of all billionaires' income tax that is lost".
    - Survey Q3: "of all the income tax that billionaires pay". "base that leaves" is a third wording for f in the same report (step 5 says "share of billionaire income tax lost").

31. **A source cell and an anchor label** (`bridge_input_table()`, `bsz_source` of dep_b, build.R l.80; the anchors' label, l.220). Minor. Both print in the report's tables.
    - Current: "the aggressive row 3 (Page, Thiel, Hankey, Kalanick, BSZ export pre2026_leavers_wealth) is the dial's middle stop"; "BSZ Table 5 row 3 (aggressive leavers)".
    - Proposed: "row 3, which BSZ label 'Aggressive assumptions for reported leavers' (Page, Thiel, Hankey, Kalanick, BSZ export pre2026_leavers_wealth), is the dial's middle stop"; "BSZ Table 5 row 3 (four reported leavers counted)".
    - Why: a source cell may quote BSZ's own label (Table 5, PDF p.39), but in quotation marks, not in this OPA's voice. Survey Q11 drops the word.

## G. Slides (`comparison/site/slides/slides.Rmd`)

32. **(i) title** (l.677 and l.693). Minor.
    - Current: "(i) Who has already left?"
    - Proposed: "(i) Who moved out in time?"
    - Survey: the group heading "3. Billionaires who moved out in time".

33. **(i) claim cells** (`claims-dep`, l.705 and l.706). Substantive.
    - Current BSZ: "Press reports do not establish that any named mover changed residence in time (BSZ PDF p.23 fn.30). ... Its aggressive scenario (Table 5 row 3) assumes four named billionaires left: Page, Thiel, Hankey and Kalanick."
    - Current JR: "<b>Seven publicly reported moves</b> (...) are taken out of the base before the tax".
    - Proposed BSZ: "No one is counted by name without evidence of a change of legal residence before 1 January (BSZ PDF p.23 fn.30). ... Its Table 5 row 3 scenario counts four named billionaires as having moved in time: Page, Thiel, Hankey and Kalanick."
    - Proposed JR: "<b>Seven billionaires are counted as having moved in time</b>, on public reports of their moves (...), and taken out of the base before the tax".
    - Survey Q11, as in item 3. The BSZ cell answers the JR value, and the JR cell states no standard.

34. **(ii) title and claim cells** (l.678 and l.732; `claims-lit`, l.736 and l.737). Substantive.
    - Current title: "(ii) Will the tax survive in court?"
    - Current: "The expert report argues the Act was designed to stay clear of constitutional issues (GGSS p.11)." against "The chance the Act survives a court challenge, set at the &quot;more likely than not&quot; threshold of an accounting rule (ASC 740-10; ...)".
    - Proposed title: "(ii) Is the revenue discounted for court risk?"
    - Proposed: lead the cells with "<b>No discount (<i>q</i> = 100%).</b>" and "<b>A discount (<i>q</i> = 50%).</b>". Then "The authors' expert report judges the Act drafted to stay clear of constitutional issues (GGSS p.11)." and "The revenue is multiplied by the chance the Act survives a court challenge, which the authors set at the &quot;more likely than not&quot; threshold of ASC 740-10 (...)".
    - Survey Q9: "No discount: the tax is assessed at face value, as written." against "A discount: ... put at 50%." The verbs follow item 8, and the slide's "Kind of claim" follows item 20.

35. **(iii) BSZ cell** (`claims-hz`, l.775). Minor.
    - Current: "since a one-time tax should cause a temporary response (BSZ PDF p.22)"
    - Proposed: "since a one-time tax should cause only temporary departures (BSZ PDF p.22)"
    - Survey Q5: "treating the departures as temporary" (F19).

36. **The share-lost bullet** (`diff-loss-rest`, l.839 to 844). Substantive.
    - Current: "at its benchmark the BSZ analysis counts the avoiders who move (...), each taking a proportional share of the income tax (BSZ PDF p.24), plus named leavers' tax from filings. The JR analysis takes a flat ... of all billionaires' income tax, ... set around the ... of wealth that left, to cover unreported moves (chapter PDF pp.31, 33)."
    - Proposed: "the BSZ analysis loses no more of billionaires' income tax than the share of their wealth that leaves. The avoiders who move take a proportional share, and named leavers add their own tax from filings, which is small for their wealth (BSZ PDF p.24, Table 4). The JR analysis loses a flat `r pct(rj$f0)` of it, more than the `r pct(vr[["d_conf"]], 1)` of wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported (chapter PDF pp.31, 33)."
    - Survey Q3. Now only the JR value has a reason, and the two are stated on different bases.

37. **The yearly-income-tax bullet** (l.847 and l.848). Substantive.
    - Current: "BSZ take the 2019 to 2025 average from tax statistics and research. JR take the middle of a range whose floor is the authors' judgement."
    - Proposed: "Both start from California tax data on the highest earners. BSZ take billionaires to have about half their income, as a study of top wealth holders finds. JR take them to be among the 212 to 500 highest earners and use the middle of the range."
    - Survey Q7, as in item 9. The JR sentence critiques its own value, while the BSZ sentence names sources. Read 212 and 500 from the export, as `mock_forms.py` does.

38. **"share already departed" in the wealth-tax formula** (`term-wealth`, l.1045 and l.1060). Minor.
    - Current: "(1 &minus; share already departed)"
    - Proposed: "(1 &minus; share that moved out in time)"
    - Survey: "Billionaires who moved out in time". The same change as item 22.

## H. `comparison/DISPUTES.md`

DISPUTES.md quotes each analysis. The proposals keep each analysis's own words, in quotation marks, and change only this OPA's voice.

39. **Row 3 and "The second JR estimate"** (row 3; the section's second paragraph). Minor.
    - Current: "**Tax base already departed.**"; "seven publicly confirmed pre-snapshot departures"; "The aggressive row assumes Page, Thiel, Hankey and Kalanick left"; "removes **7** confirmed departures".
    - Proposed: "**Billionaires who moved out before 1 January 2026.**"; 'seven "publicly confirmed pre-snapshot departures" (the chapter's words)'; 'Table 5 row 3 ("Aggressive assumptions for reported leavers", BSZ's label) counts Page, Thiel, Hankey and Kalanick as having moved'; 'removes **7** departures it calls "publicly confirmed"'.
    - Survey Q11: "counted as having moved in time, on public reports of their moves". The author's survey rules ban "confirmed". In DISPUTES.md it should read as the JR analysis's word, not this OPA's.

40. **Row 6 and its summary sentence** (row 6, BSZ column; "The second JR estimate", third paragraph). Minor.
    - Current: "BSZ's aggressive scenario loses $0.51B/yr"; "row 6 becomes the share of income tax lost (the BSZ leavers' own tax on the departed base against the JR flat draw of 30% to 60%)".
    - Proposed: "BSZ's Table 5 row 3 scenario loses $0.51B/yr"; "row 6 becomes the share of all billionaires' income tax lost: under the BSZ rule no more than the share of wealth that leaves, under the JR rule a flat draw of 30% to 60%, above the 28.6% of wealth that left".
    - Survey Q3: both values as shares of all billionaires' income tax, set against the share of wealth. Row 6's title already asks the survey's question.

41. **Row 9 title** (row 9). Minor.
    - Current: "**Chance the Act survives litigation** (September 2026 version only)"
    - Proposed: "**Whether to discount the revenue for the chance the Act is struck down** (September 2026 version only)"
    - Survey Q9's title. The row's BSZ column already uses the discount framing ("neither BSZ nor GGSS discounts the revenue for litigation risk"). Its kind follows item 20.

## I. The survey itself (not a comparison page; found while aligning)

42. **Q9's JR value discounts "the estimate"** (`COURT`, `comparison/survey/mock_forms.py` l.359 to 362). Substantive.
    - Current: "Discounting the estimate for the chance that courts strike the tax down"; "A discount: the estimate is multiplied by the chance the tax survives in court, put at 50%."
    - Proposed: "Discounting the revenue for the chance that courts strike the tax down"; "A discount: the wealth tax collected is multiplied by the chance the tax survives in court, put at 50%."
    - Why: only the wealth tax collected is multiplied by q. The JR chapter says "The income tax loss is not conditioned on q" (PDF p.33), and `score_common()` applies q to `WT` only, never to `PV`. The comparison pages say "applied to the revenue". As written, Q9 misstates the JR value. `GROUPS` matches the title by its prefix ("Discounting the estimate for the chance that courts"), so change both together.

43. **The treatment page, parts 2 and 3** (`TERMS`, mock_forms.py l.75 to 80; `GROUPS`, l.425). Minor.
    - Current: "The chance the tax survives a court challenge" with "BSZ: 100%." and "JR: 50%."; "Billionaires counted as having already left"; the group heading "2. The chance the tax survives in court".
    - Proposed: "Discounting the revenue for court risk" with "BSZ: no discount." and "JR: a 50% discount."; "Billionaires who moved out in time"; "2. Discounting the revenue for court risk".
    - Why: a treated respondent reads the survival framing on page 2 and the discount framing in Q9, and "already left" before "moved out in time".

## What to do first

1. Items 2 and 24: put the share lost on one base everywhere. It is the pilot's main finding (F1). The explorer, the overview's table, the report and the deck still print the pair the pilot found read three ways. The share-lost dial also sits in the equation's largest term.
2. Items 26 and 28: the first paragraph of the overview and of the report. Every reader meets it first. It gives the two estimates on different measures, with a reason for one of them only.
3. Items 3, 4 and 33: the departures. The BSZ end rebuts the JR value, the middle stop is called "aggressive", and the deck repeats both. The pilot showed respondents adopting that rebuttal (F5).

Item 42 also belongs before the forms go live, because Q9 now misstates the JR value.
