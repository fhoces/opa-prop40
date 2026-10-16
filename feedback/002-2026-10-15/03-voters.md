# Review 3: California voters, run 002
Commit: aff381c. Date: 2026-10-15. Pages read: `index.html` (root), `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`, the three explorers (rendered, with presets, "Walk the path" and the Apply buttons pressed), the two new checks pages (`bsz-analysis/site/checks.html`, `rjkdc-analysis/site/checks.html`), the three reports (`*/site/repro.html`, introductions and the sections changed since run 001, plus the `.qmd` sources), the three decks (`comparison/site/slides/slides.Rmd` in full, the rendered `slides.html` searched; the BSZ and JR decks' opening slides), the three materials pages, `README.md`, `comparison/DISPUTES.md` (row count), the comparison survey page. Screenshots taken: yes, but not with `screenshot.cjs` (Playwright is not installed). I used headless Chrome instead: laptop captures at 1280 px of the three overviews and the comparison explorer; phone captures at 390 px through an iframe of that width (headless Chrome will not lay out below 500 px on its own); and a 390 px overflow probe (page `scrollWidth` against `clientWidth`) on 14 pages. The explorers' text is the DOM after their scripts ran (`--dump-dom`). All files are in the scratch directory, none in the repository. `check_links.py` printed nothing, so no internal link is broken.

## Summary
- Counts: blocking 0, major 8, minor 19, suggestion 2
- The three to fix first: V-01, V-08, V-19
- Two sentences: the site told me that one team of economists expects the tax to bring in about $100 billion and the other expects it to leave the state about $39 billion poorer, mainly because they disagree on how long lost income tax counts, whether the courts uphold the tax, and whether some billionaires had already left. I would come back for the explorers and the new checks pages, but on the first screens the JR number changes between pages (−$39.0B and −$38.9B), and the yellow "AI generated" badge next to the authors' names made me wonder whether the papers themselves were written by AI.

## What I understood in ten minutes

How the ten minutes went. Minutes 1 to 3 on the root, laptop and phone: the first paragraph and the two big numbers, then the new "What separates the two numbers" equation, which is the most useful thing on the first screen. Minute 4: clicked "−$39.0B", landed on the JR overview, which says "−$38.9B", and spent a minute working out whether that was a different estimate. Minute 5: the JR overview's "The loss decides the sign" line. Minute 6: the BSZ overview's first screen and footnote 1. Minute 7: the BSZ "What the model says" table. Minutes 8 and 9: the comparison explorer; I pressed "Walk the path" nine times and the panel went $106.8B, $76.9B, $37.5B, $32.4B, $29.0B, −$36.4B, −$43.9B, −$46.1B, −$33.6B, −$39.0B, which matches the equation; the Apply buttons give the same four terms. Minute 10: the JR explorer's preset buttons; "Lowest NPV (−$807.0B)" stopped me.

**Root.** Proposition 40 taxes Californians worth $1 billion or more, once, at 5% of their net worth, paid over five years. BSZ say it raises money; this site puts their number at $106.8 billion once income tax effects are added. JR say the state ends up $39 billion poorer because billionaires who leave stop paying income tax for ever. The equation told me the gap is mostly three things: departures already made ($29.9B), the chance the courts strike the tax down ($39.4B) and lost income tax ($81.3B). What I got wrong, checked after: I read "$81.3B Lost income tax" as the JR analysis's lost income tax; the JR overview says that is about $75B, and $81.3B is a change along a path, not an amount anyone estimates (V-03). I also took "$39.0B" to be what JR print; they print $38.9B, and $39.0B is this site's exact recomputation (V-01). I did not learn when the measure applies (which date makes someone a Californian), which matters because one of the three big differences is who had already left (V-02).

**BSZ overview.** BSZ estimate about $100 billion; their Table 5 says $104 billion; this site rebuilds it as $103.8 billion and adds income tax effects to reach $106.8 billion, which is this site's number, not the authors'. The footnote says so clearly. What I got wrong: the badge "AI generated, partially reviewed" sits right after "Boll, Saez, Zucman (BSZ)", and I first read it as a label on their paper (V-08). Further down I met "250 California billionaires" and then "244 billionaires instead of 240" and could not tell which list was which (V-10).

**JR overview.** The best first screen of the three: "the state ends up poorer, because billionaires who leave take their income tax with them for ever", and "The income tax lost for ever is worth about $75B today, against $36B of wealth tax collected once". What I got wrong: the same badge after "Jaros and Rauh (JR)" (V-08), and I assumed −$38.9B and the root's −$39.0B were two different results until I found the root's footnote (V-01).

What I would tell a friend: "Two sets of economists looked at Prop 40. One says it raises about $100 billion; the other says the state loses about $39 billion because rich people who move away stop paying income tax for ever. This site shows the gap comes mostly from how long you count that lost income tax, whether the courts let the tax stand, and whether some billionaires already left." What I would still be unsure about: which date decides who already left, and how much of this site a person has checked.

## Where the deep dive lost me

In reading order. Each entry: page, the sentence, why, the sentence that would have kept me.

1. Root, first paragraph: "finds that it leaves the state $39.0B poorer". The JR overview, one click away, says −$38.9B. Would have kept me: "finds that it leaves the state about $39 billion poorer" (V-01).
2. Root, the equation: "$81.3B Lost income tax". The JR overview says the lost income tax is about $75B. Would have kept me: one line under the equation saying the amounts are changes, not totals (V-03).
3. Root, the equation: "The other three steps together (W, a, three minor inputs)". I counted five things. Would have kept me: "(W, a and the switch for three minor inputs)" (V-04).
4. Root, "The differences": "All these are empirical quantities." Two rows down, the years counted and the discount rate are labelled "scenario", which the explorer defines as "a choice of which world is estimated" (V-06).
5. BSZ overview, title: "Analysis From Boll, Saez, Zucman (BSZ) AI generated, partially reviewed". Read as a label on the paper (V-08).
6. BSZ overview, credit fold: "The author answered the roles once and applied the same answers to every object on all three pages". The root and JR pages say each object was answered separately on 2026-10-15 (V-09).
7. Comparison explorer, the f dial in the BSZ panel: the JR end reads "50%", while the tip, the root's table and the JR panel say 45% (V-12).
8. Comparison explorer, the r dial: "2.73%: the one rate worth the same as the JR analysis's random draw between 1.5% and 4.5%". I did not know what "worth the same as a random draw" means. The report's Introduction explains it well with numbers (36.6 against 33.3); the tip does not (V-13).
9. Comparison explorer, Notes: "All amounts are nominal billions of dollars." The headline says "in today's dollars" (V-16).
10. JR explorer, preset "Lowest NPV (−$807.0B)". The page's own q dial says the setting it uses counts litigation risk twice (V-17).
11. JR checks page, "Revenue multiplied by a chance of surviving in court of 0.50: −56.98". The JR explorer's preset of the same name gives −$48.2B (V-19).
12. Both checks pages on a phone: the Results table runs off the right edge (V-20).
13. Comparison deck, slide 2 ("California's Proposition 40", the first after the title): "[New York Times quote to come: ...]" (V-24).
14. Comparison deck, "Difference 1: who has already left?": "Dollars moved, on (b): −$29.9B, step 1 of the dial path." Neither "(b)" nor "the dial path" has been defined; both are now explained in the appendix (V-26).
15. Comparison deck, slide 2: the Against side's "$25 billion in lost revenue". A third number, from neither analysis I had just read about (V-27).

## What worked (keep)
- The root's "What separates the two numbers" equation, with "Walk the path" and the Apply buttons. I pressed them and every term came out as printed. This is the clearest new thing on the site.
- The JR overview's sentence "The loss decides the sign. The income tax lost for ever is worth about $75B today, against $36B of wealth tax collected once."
- The BSZ overview's footnote 1 and the report's "Not the authors' choice" note: they say plainly whose number is whose.
- The two checks pages. "All seven variations the BSZ papers print reproduce" and "We have sent this table to the original authors", with "Pending" in the authors' column, are the strongest trust signals on the site. The BSZ page's "What could not be checked" (revenue from $87.0 billion to $110.9 billion depending on the valuation date) is exactly what a voter needs to see.
- The comparison report's derivation of the 2.73% rate with real numbers (1/r averaged gives 36.6, against 33.3 at 3%, "because 1/r curves upward").
- The JR explorer's preset labels "Rate 1.5% scenario (PDF p.32), not printed by the authors".
- Every page has the same two-row navigation line, nothing breaks sideways on the overviews, explorers, reports or materials pages at 390 px, and no page tells me how to vote. The For and Against arguments on the comparison deck's slide 2 are both quoted from the official voter guide.

## Findings

### V-01. The JR main estimate is −$39.0B on the comparison pages and −$38.9B on the JR pages, and the root attributes $39.0B to JR  [major] [comparison]
- Where: `comparison/site/index.template.html` lines 305 (`{{nber_npv_abs}}`), 321 (`{{hl_rjkdc}}`) and 409 (`Main estimate, mean NPV: {{nber_npv}}`); generated `index.html` lines 305, 321, 336, 416; `comparison/site/explorer.template.html` lines 315 and 360; `comparison/site/repro.qmd` lines 114 and 156-158; `comparison/site/slides/slides.Rmd` slides "why-opa-2", "opa-comparison" and "pseudo-eq" (`rj_main`); against `rjkdc-analysis/site/index.html` line 249 and the JR explorer's headline. Phone and laptop.
- Now: root, first paragraph: "The JR analysis (Jaros and Rauh, NBER, September 2026) finds that it leaves the state $39.0B poorer"; root headline "JR main estimate −$39.0B", a link to the JR overview, whose headline reads "Main estimate, NBER September 2026 −$38.9B". The comparison report's introduction says "$38.9B poorer" in its first paragraph and "the JR analysis's mean net present value in perpetuity, −$39.0B (NBER, September 2026)" three paragraphs later.
- Problem: a reader clicks −$39.0B and lands on −$38.9B under the same name, "main estimate". The explanation (the paper prints −$38.9B from one seeded run; −$38.98B is the exact average) is in footnote 1 at the bottom of the root and in the explorer's Notes fold. "Finds that it leaves the state $39.0B poorer" and "(NBER, September 2026)" next to −$39.0B attribute to the authors a figure they never print. On a ballot question, two decimals of difference look like a careless page, not a choice.
- Proposed: keep the exact value as the comparison's JR end (the deck's setup chunk records it as an author decision of 2026-10-15), but stop presenting it as the authors' number. First paragraph: "finds that it leaves the state about $39 billion poorer". Headline sub-line, added under the JR number: "The authors print −$38.9B from one run of their simulation; this page uses the exact average, −$38.98B." Report introduction: "the JR analysis's mean net present value in perpetuity, −$38.9B as printed (NBER, September 2026), −$39.0B as computed exactly here". Alternatively print −$38.9B in the root's headline and keep −$39.0B for the bridge's end; the author decides which.
- Also on: the comparison explorer's sticky bar ("JR panel −$39.0B") and panel header; deck slides "why-opa-2" and "pseudo-eq".

### V-02. When the measure applies is missing from all three first paragraphs  [minor] [all]
- Where: `comparison/site/index.template.html` line 300; `bsz-analysis/site/index.html` line 240; `rjkdc-analysis/site/index.html` line 234
- Now: "Proposition 40, the Billionaire Tax Act, would tax Californians worth $1 billion or more once, at 5% of their net worth, paid over five years." (root, JR); the BSZ overview drops "paid over five years".
- Problem: run 001 added the residency and valuation dates (K3); the shorter sentence that replaced it dropped them. Without "lived in California on 1 January 2026", the second-largest difference on the root ("Billionaires already departed") has no anchor; the date appears only inside the D dial's tip and on the BSZ checks page ("1 January (the residency date)"). The BSZ checks page also says "This OPA values wealth on 1 July 2026" without saying the measure's own valuation date is 31 December 2026, which the BSZ deck states ("wealth valued on 31 December 2026").
- Proposed: "Proposition 40, the Billionaire Tax Act, would tax people living in California on 1 January 2026 and worth $1 billion or more: once, at 5% of their net worth, paid over five years." The same sentence on all three overviews (shared kit). On the BSZ checks page: "The measure values wealth on 31 December 2026. The BSZ analysis uses the Forbes list of 1 July 2026, and this OPA follows it."

### V-03. "Lost income tax −$81.3B" reads as an amount, and the JR overview gives a different one  [major] [comparison]
- Where: the pseudo-equation, generated by `eq_terms()` in `comparison/R/site.R` lines 113-138 and placed by `{{pseudo_eq}}` / `{{pseudo_eq_note_root}}` (`comparison/site/index.template.html` lines 330-331; `index.html` 330-336); the same equation in `comparison/site/explorer.template.html` lines 324-325 and the deck's "pseudo-eq" slide; against `rjkdc-analysis/site/index.html` line 254
- Now: "− $81.3B Lost income tax" on the root; the JR overview: "The income tax lost for ever is worth about $75B today".
- Problem: next to "$106.8B BSZ estimate" and "−$39.0B JR estimate", which are amounts, a voter reads each term as an amount too: "the lost income tax is $81.3 billion". It is the change from moving four dials, which includes the 5% of movers the BSZ avoidance allowance adds while it is still in place, so it is larger than the JR analysis's own $75B. The caption ("Each term is what its group changes") is the right idea but comes after the numbers and does not say "not a total".
- Proposed: keep the term names (author wording) and add one line under the equation, before the walk instructions: "Each amount is how much that group of inputs changes the estimate when moved in this order, not a total. For scale, the JR analysis's own lost income tax is about $75 billion; the BSZ analysis's is $0.7 billion." (The two figures should be read from the export, not typed.)
- Also on: the explorer and the deck's "pseudo-eq" slide.

### V-04. "The other three steps together (W, a, three minor inputs)" lists five things  [minor] [comparison]
- Where: `comparison/R/site.R` line 130 (`The other %s steps together (%s)`) and line 136; the equation on the root, the explorer and the deck
- Now: "The other three steps together (W, a, three minor inputs)"; and the loss term reads "(H, f, C, r)" while the note under it says "(f, C, H and r)".
- Problem: I counted W, a and three inputs and got five steps, not three. The two orders of the loss letters made me check whether they were different groups.
- Proposed: "The other three steps together (W, a and the minor-inputs switch)"; one order for the loss letters in the term and in the note.

### V-05. Root footnote 1 calls both numbers "each analysis's own" and then says one is not  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 527; `index.html` line 558; `comparison/site/explorer.template.html` line 388
- Now: "Each analysis's own main estimate. The BSZ number is this OPA's net total over 5 years at 3% ... BSZ's own headline is the wealth tax alone."
- Problem: the first sentence says the authors chose the number; the second says this OPA built it. The explorer's version adds "defined its own way" and "the net total is this OPA's choice", which is clearer but still opens with "own".
- Proposed: "The main estimate of each analysis's overview page. The BSZ number is this OPA's net total ...; BSZ's own headline is the wealth tax alone. The JR number is the authors' mean net present value ..."

### V-06. "All these are empirical quantities" sits above two inputs the same table calls scenarios  [minor] [comparison]
- Where: `comparison/R/site.R` lines 516 and 543 (the `q-sub` paragraph); `index.html` line 532; the explorer's "But what are the actual quantities?"
- Now: "All these are empirical quantities. Their values should not depend on whether one supports or opposes a wealth tax. An expert should be able to appraise each value from more to less credible."
- Problem: the table below labels H (years) and r (BSZ's 3%) "scenario", which the explorer's Kinds note defines as "a choice of which world is estimated", and q is "a legal judgement" on the deck. A careful reader sees the page contradict itself one row later.
- Proposed: "Most of these are empirical quantities: their values should not depend on whether one supports or opposes a wealth tax. The years counted and the discount rate are choices of which question to answer (scenarios)." The author should confirm which rows the survey asks about.

### V-07. The survey does not say who should take it  [minor] [comparison]
- Where: `comparison/R/site.R` lines 535-553; `index.html` lines 531 and 547-548; the comparison explorer's "But what are the actual quantities?"
- Now: "Take the survey" (above the table) and "Take the survey: what do you think these values are?" / "Share this survey with people you think have expertise in this area".
- Problem: a voter who reads the table is invited to take a survey, and only the share line hints that it is for people with expertise. I did not know whether my answers were wanted.
- Proposed: "Survey for experts: what do you think these values are?" on both buttons, or one line: "The survey asks economists and tax experts for their own values. Anyone may look at it." (The author should state the intended audience; the project notes call it an expert survey.)

### V-08. The "AI generated" badge sits right after the original authors' names and the JR paper's title  [major] [BSZ, JR]
- Where: `bsz-analysis/site/index.html` line 238; `rjkdc-analysis/site/index.html` line 232; `rjkdc-analysis/site/slides/slides.Rmd` line 2 (the deck title is the JR paper's own title, "The Net Present Value of the California Billionaire Tax Act", followed by the badge); `assets/paper.css` (the badge style)
- Now: "California Proposition 40, Analysis From Jaros and Rauh (JR) [AI generated, partially reviewed]"; the JR deck: "The Net Present Value of the California Billionaire Tax Act [AI generated, partially reviewed]".
- Problem: the badge's subject is the OPA page, but it is placed so that it reads as a label on the analysis named just before it. A voter can take away "the Jaros and Rauh paper was AI generated", which is false and unfair to the authors. It also contradicts the credit fold on the same page: "This work was a collaboration between the author and Claude Code ..., not an AI working alone." On the reports ("the reproduction") and the comparison deck the badge follows this site's own title, so there it reads correctly.
- Proposed: say whose work the badge describes, and take it out of the sentence that names the authors. For example a line of its own under the h1: "This OPA site: built with AI tools, partially reviewed by its author", linking to the credit fold. On the JR deck, put the badge on the subtitle line ("Teaching deck: ..."), not after the paper's title. A shared-kit change (the badge and `test-ai-badges.R` in each suite).
- Also on: the BSZ report's title is fine ("the reproduction"); check the README badges with the same rule.

### V-09. The BSZ credit fold describes a record that the other two pages say was replaced  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` lines 338-352
- Now: "what is still being completed is the author's own review of each part ... and the author's questionnaire on who did what." Then: "The author gave these answers in a questionnaire on 2026-10-01 ... The author answered the roles once and applied the same answers to every object on all three pages".
- Problem: the root and the JR overview say the author answered every object separately on 2026-10-15, and the comparison's CREDIT.md says the new answers replace the 2026-10-01 record. So "on all three pages" is no longer true, and within the BSZ fold the questionnaire is both "still being completed" and already given.
- Proposed: "The BSZ answers are from a questionnaire on 2026-10-01, in which one set of role answers was applied to every object of the BSZ analysis. The JR analysis and the comparison were answered object by object on 2026-10-15; the same interview for the BSZ analysis is still to come." (I think that is the state of things; the author should confirm.)

### V-10. 250 billionaires, then "244 billionaires instead of 240", on one page  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` lines 496-497 ("What reproduces"), against "What the model says" ("250 California billionaires on 1 July 2026")
- Now: "Four rows of the billionaire list appear twice, giving 244 billionaires instead of 240."
- Problem: the estimate uses 250 billionaires; the reproduction table then talks about 240 and 244 without saying which list.
- Proposed: I think the 240 is the workbook's 1 January 2026 list (`comparison/DISPUTES.md` row 7 gives "240 billionaires, $2,055B at 1 Jan 2026"). If so: "Four rows of the workbook's 1 January 2026 list appear twice, giving 244 billionaires instead of 240 (the 1 July list behind the estimate has 250)."

### V-11. The yearly income tax lost is $0.15B on the overview and −$0.15B on the explorer and the checks page  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` line 457 and its table ("Income tax lost, per year": "$0.15B"); the BSZ explorer's outcome table ("Income tax lost to leavers, per year": "−$0.15B", label from `bsz-analysis/R/site_exports.R` line 99); `bsz-analysis/site/checks.qmd` line 108 ("Income tax lost per year": "−0.15")
- Problem: a quantity named "lost" with a minus sign reads as a double negative ("minus a loss" is a gain), and the overview prints it positive.
- Proposed: one convention for the row "Income tax lost": positive amounts, with the minus only where it is subtracted in a total.

### V-12. The f dial's end labels change from one panel to the other  [minor] [comparison]
- Where: the comparison explorer, the "share lost f" dial; labels computed in the page script from `assets/comparison-data.js`
- Now: BSZ panel: left end "5%" (BSZ), right end "50%" (JR). JR panel: left end "6%" (BSZ), right end "45%" (JR). The JR tip in both: "45% of all billionaires' income tax, whoever leaves ..., plus movers from a". The root's table: "f share lost 5%" and "45%".
- Problem: I read "50%" as a different JR value. The reason is in the tip ("plus movers from a") and in the "more" fold ("f also moves with D and a"), but the end label itself shows a number neither analysis states.
- Proposed: keep the computed value but say why at the end: JR end "50% (45% + 5% movers from a)" in the BSZ panel; or one sentence in the dial's tip: "In this panel the ends include the other dials' current values: here the JR end is 45% plus the 5% who move under the BSZ avoidance allowance." (I think the 5% is a = 10% times m = one half; the author should check the wording.)

### V-13. "The one rate worth the same as the JR analysis's random draw" is not a plain sentence  [minor] [comparison]
- Where: the comparison explorer's r dial, JR end tip; the root's differences table ("r rate 2.73%. The one rate worth the same as the JR analysis's random draw between 1.5% and 4.5%"); the deck's "smaller" slide
- Now: "2.73%: the one rate worth the same as the JR analysis's random draw between 1.5% and 4.5% ($1 a year for ever is worth $36.6). Kind: derived."
- Problem: I did not know that JR use a different rate in each simulated run, so "worth the same as a random draw" meant nothing to me. The report says it in plain words ("The JR analysis draws the rate at random ... and averages the results. That draw is worth the same as one rate, 2.73%").
- Proposed: "JR do not use one rate: each of their 100,000 runs picks a rate between 1.5% and 4.5%. Averaged over the runs, $1 a year for ever is worth $36.6 today, which is what one rate of 2.73% gives. Kind: derived." (Three lines on a laptop; the range sentence can go in "more" on a phone.)

### V-14. One dial, four names, and "yearly tax revenue" is ambiguous  [minor] [comparison]
- Where: `comparison/R/site.R` line 180 (`income_level = "yearly tax revenue"`) against line 208 (`income_level = "yearly income tax"`); the root's differences table ("C yearly tax revenue"); the explorer's dial header ("Income tax level"); the deck ("Yearly income tax")
- Problem: on a page about a wealth tax, "yearly tax revenue" can be read as the wealth tax's yearly revenue. The tip says what it is ("C, yearly income tax"), but the big word on the dial and the row label in the table do not.
- Proposed: "yearly income tax" as the dial's word and in the table, matching the tip.

### V-15. The avoidance dial's screen-reader name is "No avoidance"  [minor] [comparison]
- Where: `comparison/R/site.R` line 51 (`avoidance = "No avoidance"`) used at line 607 as the dial's hidden title (`<span class="sr">`), in both panels
- Now: a screen reader announces the slider as "avoidance a No avoidance", while the BSZ value is 10% avoidance. The code's own comment at line 204 says "No avoidance" is the JR end of the a dial, not the dial.
- Problem: a reader who listens to the page hears a name that contradicts the BSZ value. The other hidden titles ("Departed wealth", "Litigation", "Forbes source") are step names too, but only this one reads as a value.
- Proposed: use `DIAL_NAMES` (line 205: "avoidance share" and so on) for the hidden titles.

### V-16. "Nominal billions of dollars" next to "today's dollars"  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` line 400 ("Conventions. All amounts are nominal billions of dollars."); the same sentence in `comparison/site/repro.qmd`, "The common output"
- Problem: the headline says "in today's dollars"; the conventions say "nominal". I did not know whether these were two different units.
- Proposed: I think it means not adjusted for inflation, with future losses discounted to the end of 2026. If so: "All amounts are billions of dollars, not adjusted for inflation. 'Today's dollars' means the value at the assessment date (end of 2026) of money received or lost later."

### V-17. The JR explorer's "Lowest NPV (−$807.0B)" button uses a setting the page itself warns against  [major] [JR]
- Where: `rjkdc-analysis/site/explorer/index.html` lines 375-403 (the "Highest NPV" and "Lowest NPV" buttons, taken from the grid's extremes)
- Now: pressing "Lowest NPV (−$807.0B)" sets the revenue floor to 0, the ceiling to 55.10, q to 0.50, C to 5.8, r to 1.5%, f to "1 - WT/94.2" and the growth g to 1.0%. The headline then reads "This setting (not published by the authors) −$807.0B".
- Problem: the q dial's own level text says "With the 0 floor it counts litigation risk twice, so pair it with the 35 or 45.59 floor", and the g dial says 1.0% is "This OPA's illustration". The button combines both with the first version's rules. A voter sees a −$807 billion figure on the JR analysis's page, one click from the main estimate, and could repeat it as something the JR model shows. The BSZ explorer's extremes ($157.8B and $63.2B) have no such problem.
- Proposed: compute the extremes over settings the page treats as valid (no q below 1 with the 0 floor), or drop the two buttons on this explorer, or label the button and the headline: "Lowest in the grid (−$807.0B): combines this OPA's illustrative growth rate with a litigation weight the q dial says counts twice. Not a JR result."

### V-18. 85.3% beside the printed 85.2%, with no label  [minor] [JR]
- Where: the JR explorer's outcomes table, row "Share of outcomes with NPV below zero (%)" (85.3 in "This setting" and "Main estimate"), against its headline "As printed (PDF p.1, p.35): 85.2% of draws fall below zero"; `rjkdc-analysis/site/checks.qmd` line 103 (85.3%)
- Problem: the NPV rows say which is printed and which exact; the share row does not, so the main-estimate column contradicts the headline above it.
- Proposed: "Share of outcomes with NPV below zero, exact (%)", and a printed row as for the NPV, or a note: "85.2% as printed, from the seeded run".

### V-19. The JR checks page's litigation rows count litigation risk twice, and differ from the explorer's preset of the same name  [major] [JR]
- Where: `rjkdc-analysis/site/checks.qmd` lines 106-107 ("Settings the papers do not print") and line 63 ("What could not be checked")
- Now: "Revenue multiplied by a chance of surviving in court of 0.50 | −56.98 | 99.5% | Pending" and "... 0.75 | −47.98"; and "The explorer offers 'Rate 1.5%', 'Rate 4.5%' and 'Litigation weight q = 0.5', each of which changes one input from the main estimate."
- Problem: the JR overview says the main estimate's revenue draw from 0 to 72 already has the mean of 0.5 × 72, and the explorer's q dial says the 0 floor with q below 1 "counts litigation risk twice". The checks rows apply q on top of that floor (36 × 0.5 = 18, so −38.98 − 18 = −56.98). The explorer's preset "Litigation weight q = 0.5" raises the floor to 35 and gives −$48.2B, so it changes two inputs, not one. A voter reading "chance of surviving in court of 0.50" sees −57, while the main estimate already assumes that chance. The page says the table was sent to the original authors.
- Proposed: either run the two rows with the floor at 35, as the explorer's preset does, and say so ("with the revenue floor raised to 35, so the risk is not counted twice"), or keep the rows and add under them: "With the 0 floor the draw already halves the revenue (0.5 × 72), so these two rows count the risk of the Act being struck down twice; they test the arithmetic, not a plausible setting." And in "What could not be checked": "'Litigation weight q = 0.5' changes two inputs (q and the revenue floor)".

### V-20. Both checks pages scroll sideways on a phone, and the Results tables lose their last columns  [major] [BSZ, JR]
- Where: `bsz-analysis/site/checks.qmd` lines 47-57 and `rjkdc-analysis/site/checks.qmd` lines 48-55 (the Results tables); phone
- Now: measured at 390 px, the BSZ page is 468 px wide and the JR page 474 px (every other page in the project measures 390). On the JR phone capture the "Result" column is cut to "Resul" and "Cannot be set" to "Canno", and "How to set it" is off screen. Long first cells wrap one or two words a line ("Revenue / drawn from / $35B to / $67.51B, ...").
- Problem: the "Result" column ("Match") is the point of the page, and it is the one a phone reader cannot see; the whole page also moves sideways under the thumb.
- Proposed: wrap both tables in the scroll box the overviews use, with the "Scroll sideways for the rest" hint, or put "Result" second and drop "How to set it" below 600 px.

### V-21. The same revenue is 103.82 and 103.81 on the BSZ checks page  [minor] [BSZ]
- Where: `bsz-analysis/site/checks.qmd` line 49 (103.82) and lines 108-116 (103.81)
- Problem: the main-assumptions revenue appears in both tables, a cent apart. The record behind it gives 103.815, so both are rounding, but a reader checking numbers sees two values for one figure.
- Proposed: the same rounding in both tables (both read from one value, not two files).

### V-22. The checks pages are not in the navigation line  [suggestion] [BSZ, JR]
- Where: the site-nav line on every BSZ and JR page; the checks pages are linked only from the overviews' credit fold and "What reproduces", and from the comparison deck
- Proposed: add "Checks" after "Open Materials (guide)" on the two analyses' pages. A shared-kit change.

### V-23. The JR report writes amounts as "−38.9 $B" and "75 $B"  [minor] [JR]
- Where: `rjkdc-analysis/site/repro.qmd` lines 85-88 and 108-114 (the Introduction)
- Now: "a mean net present value of −38.9 $B (PDF p.1) ... worth about 75 $B today, against 36 $B collected"
- Problem: every other page writes −$38.9B; "36 $B" reads as a typo on the report's first screen.
- Proposed: "−$38.9B", "$75B", "$36B" in prose; "$B" stays as the unit in table headers.

### V-24. The comparison deck shows placeholders on its first slides  [major] [comparison]
- Where: `comparison/site/slides/slides.Rmd` line 138 (slide 2, "prop40") and lines 174 and 180 (slide 5, "why-opa-3"); present in the rendered `slides.html`
- Now: "[New York Times quote to come: the exact sentence calling the measure a close second most important issue in the election, with its date and link]"; "[Text for the left figure, to come]"; "[Text for the right figure, to come]"
- Problem: the deck is linked from the root's first screen ("Open Analysis: Report and Slides"). A voter who opens it sees an unfinished note on slide 2, the first after the title, and two empty captions on slide 5, which undercuts the deck's own point about reliability on slide 12 ("The challenges of AI for OPA").
- Proposed: hide the quote box and the "why-opa-3" slide (`exclude: true`) until the text exists, or fill them.

### V-25. "Alternative facts" in a slide title  [minor] [comparison]
- Where: `comparison/site/slides/slides.Rmd` line 187 (slide 6, "why-opa-4")
- Now: "How do we move from alternative facts¹ to one common estimate?", with the footnote "What Manski calls dueling certitudes".
- Problem: to most voters "alternative facts" is a political catchphrase from 2017, so the title reads as a jab, and the footnote's source uses a different term. It does not favour either analysis, but it is the one place where the site's tone stops being neutral.
- Proposed: "How do we move from dueling certitudes¹ to one common estimate?" or "from two confident numbers to one common estimate?"

### V-26. After the restructure, the deck's main slides use terms defined only in the appendix  [major] [comparison]
- Where: `comparison/site/slides/slides.Rmd` lines 518 ("pseudo-eq": "Move the BSZ panel's dials ..."), 562, 570, 599 and 642 ("Dollars moved, on (b): ..., step N of the dial path"), 657 ("Step on the path, (b)"), 673 ("It moves little on the path"); the definitions are on the appendix slides "common-output" (output (b)) and "one-at-a-time" (the dial path)
- Now: "Dollars moved, on (b): −$29.9B, step 1 of the dial path." and "*D* moves first on the path, while *q* is still 1, so that share of the revenue is lost in full."
- Problem: a reader going front to back meets "(b)", "the dial path", "on the path" and "the BSZ panel" before any slide says what they are; the slide that defines them now comes after "Appendix". The "Difference" slides are the ones a voter most needs.
- Proposed: on the "pseudo-eq" slide, two sentences before the equation: "Both numbers are on one measure, the net fiscal effect: the wealth tax, plus income tax from assets sold to pay it, minus income tax lost to people who leave. The equation moves the explorer's dials one at a time from the BSZ values to the JR values, in the order shown; each amount is what one move changes." Then on the "Difference" slides: "Dollars moved: −$29.9B, the first move in that order", without "(b)".

### V-27. Slide 2's "$25 billion in lost revenue" is a third number with no source in the deck  [suggestion] [comparison]
- Where: `comparison/site/slides/slides.Rmd` line 135
- Problem: the next slides compare $106.8B and −$39.0B; the Against quote's $25 billion matches neither, and a voter will ask where it comes from.
- Proposed: a footnote saying which document, if any, the campaign figure comes from, or that neither analysis on this site prints it (the author should check before saying either).

### V-28. The three materials pages count tests under different headers  [minor] [all]
- Where: `bsz-analysis/site/materials.qmd` line 83 and the comparison's materials page ("file | blocks | passed | failed | skipped"); `rjkdc-analysis/site/materials.qmd` line 95 ("file | tests | expectations | tests passed | tests failed | tests skipped")
- Problem: on the BSZ and comparison pages "passed" counts expectations (216 for 9 blocks); on the JR page "tests passed" counts tests (2 of 25 expectations). Run 001's V-30 fixed the JR table; the other two now read differently.
- Proposed: the same five columns on all three: "file | test blocks | expectations | passed | failed | skipped", with "passed" counting expectations everywhere, or a one-line note under each table saying what is counted.

### V-29. The README counts 8 disputed inputs; DISPUTES.md has 10 rows and the site nine steps  [minor] [comparison]
- Where: `README.md` line 68 (Status table: "8 disputed inputs (`DISPUTES.md`)"); `comparison/DISPUTES.md` rows 1 to 10; the root's "The report gives all nine steps"
- Problem: a reader comparing the README with the site sees three counts. The README's Layout line also calls the comparison a "Shapley bridge", while the site now uses the dial path and keeps Shapley as a check.
- Proposed: "the disputed inputs (`DISPUTES.md`, ten rows)" or drop the count; "common output definition, dial-path bridge with a Shapley check".
