# Review 3: California voters, run 010
Commit: 05859dd. Date: 2026-10-17. Pages read: the three overviews (`index.html`, `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`); the three explorers rendered (the comparison explorer with its landing panel, then skipped, the H dial moved to perpetuity on the BSZ panel, all tips read from the page; the BSZ explorer's Leavers preset; the JR explorer's dials, tips and outcome table); the three reports (`*/site/repro.html` prose and the `.qmd` sources for line numbers); the three decks (rendered `slides.html` source, and `slides.Rmd`); the three materials pages; the two checks pages; the survey share page; the four READMEs; `comparison/DISPUTES.md` (opening and table); and, as the reference for the survey section, `comparison/survey/mock_forms.py` (TERMS, SHORT, INTRO, NOTE, SHARE, DEPARTED, AVOID, COURT, HORIZON, INCOME, WEALTH, NONCIT, REAL, ASSET, GROUPS, DESC) with `comparison/survey/PRE-ANALYSIS-PLAN.md` sections 3 and 4. Screenshots taken: yes. Playwright is not installed as a module here, so I installed `playwright-core` 1.56.1 in the scratch directory and ran `screenshot.cjs` through a shim that launches the installed Chrome. Phone (390) and laptop (1280) captures of the three overviews and the three explorers, the comparison explorer with and without its landing panel, and the root's equation block on the phone. A probe through the same browser on 15 pages at 390 and 1280 found no page wider than its viewport and no page errors. `check_links.py` printed nothing (0 broken links). All files are in the scratch directory; none is in the repository.

Not re-raised: the items in `feedback/DECISIONS.md` (among them the root title, the byline and funding line, the dropped WIP badge, the explorer's little-text rule, which is why every explorer proposal below is a tip, a footnote or a link), the run 002 and 003 author answers in `003-2026-10-16/06-author-answers.md` (the −$39.0B headline beside the printed −$38.9B, the g dial, "have been sent", the why-opa-3 placeholders, "Most of these are empirical quantities"), and the f end labels that differ between the comparison explorer's panels (consistency 004 C-09, explorer UX 005 U-05), except where the survey forms make it new (V-24). The survey forms themselves are out of scope; section "Where the pages differ from the survey forms" quotes them only as the reference.

## Summary
- Counts: blocking 0, major 3, minor 23, suggestion 3
- The three to fix first: V-23, V-01, V-10
- Two sentences: the site told me that one team of economists expects Proposition 40 to raise about $100 billion (or $106.8 billion with its income tax effects) and the other expects the state to end up about $39 billion poorer, mostly because of how long lost income tax is counted, whether courts let the tax stand, and how many billionaires had already left. I would come back for the comparison explorer, but its "Lost income tax" term is bigger than the whole loss the same page reports, and the root's table told me BSZ count nobody as gone when the survey and the explorer's tips say they allow 5% of the wealth for movers.

## What I understood in ten minutes

How the ten minutes went. Minutes 1 to 3: the root on the phone (the first screen is all text; the two big numbers start just below it) and on the laptop, then the equation. Minute 4: the BSZ overview's first screen and footnote 1. Minutes 5 and 6: the JR overview's first screen and its "What the model says" fold. Minute 7: the comparison explorer, where a box blurred the page and asked me to take a survey first; I pressed "Skip to the results". Minute 8: I moved the BSZ panel's "years" dial to perpetuity, expecting a big drop because the equation calls lost income tax the largest term; the panel went from $106.8B to $102.4B. Minute 9: the Apply buttons, which gave the equation's amounts. Minute 10: the root's "The differences" fold, the D, a and f rows; I gave up at the f row's "No more than the share of wealth that leaves".

**Root.** Proposition 40 would tax, once, people who lived in California on 1 January 2026 and are worth $1 billion or more, at 5% of their net worth, payable over five years. The BSZ analysis says it raises about $100 billion, or $106.8 billion counting income tax effects over 5 years; the JR analysis says the state ends up about $39 billion poorer because the income tax lost to leavers is counted for ever. The equation splits the $145.8 billion gap into billionaires who already left (−$29.89B), the court risk (−$39.44B), lost income tax (−$81.34B) and the rest (+$4.89B). What I got wrong, checked after: I thought −$81.34B was the JR analysis's lost income tax, then read "the lost income tax itself is worth $75.0B today in the JR analysis" and assumed I had misread one of them (V-01). I read "Both numbers measure the same thing" as both analyses agreeing on what to count; they agree on the definition and disagree on the inputs, and the sentence leaves out the asset-sale income tax the explorer includes (V-28). I did not learn what the money is for (V-03). Who made it: only the footer names a person, "using agentic coding tools"; unlike the other two overviews, the root has no AI line near the top (V-04). Whose side: none stated; the table note says the values "should not depend on whether one supports or opposes a wealth tax".

**BSZ overview.** BSZ estimate about $100 billion; this site's main estimate is $106.8B because it adds income tax effects, which is this site's choice. The label right above the number says "base scenario (the authors' main case, row 1 of their Table 5)", so for a moment I took $106.8B to be what row 1 prints; footnote 1 put me right ($104 billion printed, $103.8 billion here) (V-07). "Present value at 3% a year" meant nothing to me until the JR overview defined it (V-08). The "What the model says" fold was clear: $103.8B of wealth tax, $3.68B of extra income tax from sales, $0.70B lost to leavers.

**JR overview.** The clearest first screen: "The loss decides the sign. The income tax lost for ever is worth about $75B today, against $36B of wealth tax collected once", and the gloss "Today's dollars (present value): what money received or lost in future years is worth now". The fold's plain explanation of r − g ("divide this year's loss by a small rate: the interest rate minus the loss's yearly growth") worked. What I got wrong: in the fold's table I read "Share of outcomes below zero ... 85.2%" as an 85% chance the tax loses money; the paragraph under the table corrected me. The JR explorer prints the same 85.2% on its first screen without that correction (V-10).

What I would tell a friend: "Two sets of economists looked at Prop 40. One says it raises about $100 billion; the other says the state loses about $39 billion, because billionaires who move away stop paying California income tax for ever and because courts may strike the tax down. The gap is mostly how long you count the lost income tax, whether you discount for the court risk, and how many billionaires already left." What I would still be unsure about: whether the BSZ analysis allows for anyone leaving at all (the root says "None named"), and why moving the years to "for ever" barely moves the BSZ number when the equation says it is the biggest piece.

## Where the deep dive lost me

In reading order. Each entry: page, the sentence, why, the sentence that would have kept me.

1. Root, equation note: "For scale, the lost income tax itself is worth $75.0B today in the JR analysis and $0.7B in the BSZ analysis." The term above it is −$81.34B, more than the whole JR loss. Would have kept me: the report's own sentence, "It ends above the JR analysis's $75.0B because the avoidance dial, a, has not moved yet" (V-01).
2. Root, "The differences", D row: "None named. No one counted by name without evidence of a change of legal residence before 1 January." I concluded BSZ assume no one left. Would have kept me: "None named; half of a, 5% of the wealth, allows for billionaires who moved in time" (V-23).
3. Root, "The differences", q row: "100%. No discount". I read 100% as BSZ saying the tax is certain to survive in court (V-25).
4. Root, "The differences", f row: "5%. No more than the share of wealth that leaves." 5% of what? (V-24).
5. Comparison explorer, landing panel: "Before you see why, we invite you to judge which of two proposed values for each key input is more credible." Who is "we", and am I the person this survey is for? The buttons further down say it is primarily for economists and policy analysts (V-09).
6. Comparison explorer, H dial moved to perpetuity on the BSZ panel: $106.8B became $102.4B. The equation had led me to expect most of the gap (V-01).
7. JR explorer, first screen: "As printed (PDF p.1, p.35): 85.2% of draws fall below zero." (V-10).
8. JR explorer, the share-lost dial's first button: "1 − WT/94.2" (V-12).
9. BSZ report, the leavers scenario: "Whether any of these people has actually changed legal residence is a legal judgment, and the most important guesswork in the whole dispute". The comparison says the court discount and the years counted are larger (V-15).
10. BSZ report and deck: "payable 1% a year over five years". I wondered whether the rate was 1% or 5% (V-16).
11. Comparison deck, "What separates the two numbers": "The D and q terms are those two steps of that walk." Which walk? (V-19).
12. Comparison report, the Hoopes section: "Our column follows Hoopes's construction", "We could not trace his figure". Who is "we"? (V-18).

## What worked (keep)
- The comparison report's explanation of the loss term: "The equation's lost income tax term, $81.34B, is neither. It is the change along the path, from $2.0B to $83.3B. It ends above the JR analysis's $75.0B because the avoidance dial, a, has not moved yet." It answers the question the root raises; it only needs to be where the question is.
- The comparison explorer's end tips: each gives a reason for both analyses and a Kind, for example "BSZ: a small allowance argued from enforcement. Half is people who moved out in time, who also cost income tax (f); half is avoidance."
- The JR overview's r − g paragraph in plain words, with "$1 a year for ever, growing, is worth 22 to 67 dollars today", and the caveat "It is not a probability that the tax loses money".
- The comparison deck's "Net present value: all gains minus all losses, each future dollar of lost income tax converted to its value today", and its first slide's "with the revenue mainly for health care".
- The BSZ checks page's valuation-date paragraph: $92.5 billion on 1 January, $87.0 billion at the year's low, $110.9 billion at its high so far. It shows a voter how much the base alone moves.
- The six kinds defined under the root's table, and "A kind says what evidence is behind a value, not whether the quantity itself can be observed."
- The BSZ deck's title slide now reads "A reproduction of the paper by Jasper Boll, Emmanuel Saez and Gabriel Zucman", and both overviews give the JR reason for counting the loss for ever.
- No page scrolls sideways at 390 px, no internal link is broken, and no page tells me how to vote. "The bridge shows where the $146B gap comes from. It cannot say which value of each input is right" is a neutral closing line.

## Findings

### V-01. The "Lost income tax" term is larger than the whole lost income tax the same note reports, and the years dial alone barely moves the BSZ panel  [major] [comparison]
- Where: `comparison/R/site.R` lines 925-933 (`order_note()`, the root's note under the equation; generated `index.html`); the comparison explorer's equation and its footnote 2 (`tok$eq_fn_x`, site.R lines 940-945); phone and laptop
- Now: root: "− $81.34B Lost income tax ... For scale, the lost income tax itself is worth $75.0B today in the JR analysis and $0.7B in the BSZ analysis." Explorer: "− $81.34B Lost income tax (H, f, C, r)", and the BSZ panel's H dial moved alone to perpetuity gives "With these sliders $102.4B".
- Problem: a reader who subtracts gets $74.3B and cannot see where the other $7B comes from, so one of the two numbers looks wrong. On the explorer, the dial the equation makes the biggest moves the BSZ number by only $4.4B. Both are the interaction the note mentions, but its only example is about departures ("a departure matters more when more wealth is left to tax"). The explanation exists in `comparison/site/repro.qmd` ("The explorer's equation"): until a moves, the share lost is 50% instead of 45%, because it still holds the BSZ movers' 5%.
- Proposed: root, after the "For scale" sentence: "The equation's term is larger than that difference because the avoidance dial moves last: until it does, the share lost is 50% instead of 45%, and moving avoidance gives part of it back." Explorer (a tip or the footnote, not page text): in the loss box's "more", "Alone, H moves the BSZ panel only a little, because the BSZ yearly loss is small ($0.15B a year); it matters once f and C are at the JR values." Check the three-sentence limit on footnote 2 before adding there.
- Also on: the survey treatment page shows the same −$81.3 billion term (out of scope; noted for the author).

### V-02. "Net of the income tax it adds and loses" on the root's first screen  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 305 (generated `index.html` line 305); first screen, phone and laptop
- Now: "finds that it raises about $100 billion of wealth tax (its Table 5 prints $104B), or $106.8B net of the income tax it adds and loses over 5 years."
- Problem: "net of" usually means "minus", and here the number is higher than the gross. I could not tell which income tax is added and which lost until the definition line below.
- Proposed: "or $106.8B once the income tax it raises (on assets sold to pay it) and the income tax it loses (to billionaires who leave) over 5 years are counted."
- Also on: `comparison/site/repro.qmd` line 130 (the report's Introduction).

### V-03. No overview says what the revenue is for  [minor] [all]
- Where: the first sentence of `comparison/site/index.template.html` line 302, `bsz-analysis/site/index.html` line 241, `rjkdc-analysis/site/index.html` (first paragraph)
- Now: "Proposition 40, the Billionaire Tax Act, would tax, once, people who lived in California on 1 January 2026 and are worth $1 billion or more, at 5% of their net worth, payable over five years."
- Problem: "What would it do?" is the first question a voter asks, and the pages answer only who pays. The comparison deck's first slide says "with the revenue mainly for health care"; the Act puts 90% in a Billionaire Tax Health Account and 10% in an Education and Food Assistance Account (Act Sec. 5, Government Code §16355(b), PDF p.8 of `docs/initiative/25-0024A1-billionaire-tax-act.pdf`). This is a fact of the measure, not an argument for it.
- Proposed: end the sentence "... payable over five years. The Act sends 90% of the revenue to health care and 10% to education and food assistance (Sec. 5)." The same on the three overviews (shared text, so all three).

### V-04. The root has no AI line near the top, and "This OPA site" on the other two overviews describes only the overview page  [minor] [all]
- Where: `bsz-analysis/site/index.html` line 239, `rjkdc-analysis/site/index.html` line 233, `comparison/site/index.template.html` (no badge line); `*/tests/testthat/test-ai-badges.R`
- Now: BSZ and JR overviews: "This OPA site: AI generated, partially reviewed". Root: no line. The JR report's title badge says "AI generated, not reviewed yet", the JR and comparison READMEs too, and the comparison report too.
- Problem: the badge follows each object's own answer, so the root (reviewed) has none and the JR overview (partially reviewed) says "This OPA site". A voter reads "This OPA site" as the whole JR site, then finds its report "not reviewed yet"; and a voter who reads only the root sees no AI disclosure until the credit fold far below. Trust, not economics.
- Proposed: for the author, since the wording was the author's (run 003 answers, item 3). Either "This page: AI generated, partially reviewed" (the level the badge test ties it to; `test-ai-badges.R` pins the words "This OPA site", so the test changes too), or one site-level line on all three overviews giving the lowest level among that site's objects, the root included.

### V-05. On a phone, the root's first screen is one 17-line paragraph  [suggestion] [comparison]
- Where: `comparison/site/index.template.html` lines 302-311; phone (390 px)
- Problem: the two headline numbers start below the first screen; a reader who gives the page one screen gets the numbers only inside a long sentence. The BSZ and JR overviews' first paragraphs are shorter.
- Proposed: move the last two sentences ("This page puts both on one definition ... the kind of evidence behind it.") below the headline block, or cut them to "This page puts both on one definition and shows which assumptions make the difference."

### V-06. Disclosures about who wrote each source are not stated by one rule  [suggestion] [all]
- Where: `comparison/site/repro.qmd` line 885 ("Gamage is a GGSS co-author", about Hoopes); `comparison/site/materials.qmd` line 105 ("by some of the experts who drafted the initiative, GGSS p.1"); the JR documents named "Hoover Institution" or "Hoover expert report" (`comparison/DISPUTES.md` line 20, the JR report's appendix)
- Problem: a voter weighing trust learns about Hoopes's tie to a GGSS author in the report and about GGSS's role in drafting the measure only in a parenthesis on a materials page, and nothing about what the JR documents disclose. I did not check what the JR chapter itself discloses. Uneven disclosure can read as a lean even when none is meant.
- Proposed: for the author. One sentence per document on each overview's citation, each quoting the document's own disclosure (or none on any page). Not an argument for or against the measure.

### V-07. The BSZ headline label places $106.8B in "row 1 of their Table 5"  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` line 252; also the BSZ explorer's label "Main estimate¹, base scenario"
- Now: "Main estimate¹, base scenario (the authors' main case, row 1 of their Table 5)" above "$106.8B".
- Problem: row 1 of Table 5 prints $104 billion; the label reads as if it printed $106.8B. Footnote 1 corrects it, one line later.
- Proposed: "Main estimate¹: this OPA's net total for the base scenario (the authors' main case, row 1 of their Table 5)".

### V-08. "Present value" is defined on the JR overview but not on the BSZ overview  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` line 256
- Now: "counted over 5 years (present value at 3% a year)". The JR overview: "Today's dollars (present value): what money received or lost in future years is worth now."
- Problem: the BSZ reader meets the term with no gloss. The root's gloss was removed on 2026-10-16 (commit 28f9444), so I propose nothing there.
- Proposed: "counted over 5 years and converted to today's dollars at 3% a year (present value: what money lost in future years is worth now)."

### V-09. The explorer's landing panel does not say who the survey is for, or who "we" is  [minor] [comparison]
- Where: `comparison/R/site.R` lines 1054-1060 (`LANDING`, pinned in `comparison/tests/testthat/test-site.R`); the comparison explorer's first screen on a first visit, phone and laptop
- Now: "Before you look at the results. Two analyses of Proposition 40 reach very different numbers. Before you see why, we invite you to judge which of two proposed values for each key input is more credible. It takes 5 to 10 minutes."
- Problem: a voter who clicks "Explorer" on the root gets a blurred page and a survey invitation first. The survey button further down and on the root says "The survey is primarily for economists and policy analysts"; the panel does not, and "we" is not named anywhere on the page.
- Proposed: for the author, since the panel is part of the pre-analysis plan (section 4.3). Add the audience line the other buttons carry: "The survey is primarily for economists and policy analysts." and replace "we invite you" with "this project invites you".

### V-10. The JR explorer's first screen prints the 85.2% share below zero without its caveat  [major] [JR]
- Where: `rjkdc-analysis/site/explorer/index.html` line 542 (the line under the headline); the caveat is in the closed Notes fold, lines 233-235; phone and laptop, first screen
- Now: "As printed (PDF p.1, p.35): 85.2% of draws fall below zero. This page's exact average: −38.98 (why)."
- Problem: a voter reads this as "an 85% chance the tax loses money". The overview, the report and the Notes say it is not a probability: it moves with ranges that are themselves guesswork. On this screen nothing says so.
- Proposed (a link, not page text): "85.2% of draws fall below zero (not a probability: why)", the link opening the Notes paragraph "The share below zero sums up ...". The outcome table's row "Share of outcomes with NPV below zero, exact (%)" could carry the same link.

### V-11. The JR explorer still defines r − g in economists' words  [minor] [JR]
- Where: `rjkdc-analysis/R/site.R` line 105 (the rate dial's `desc`, written to `grid.js`)
- Now: "The authors draw r − g, the real discount rate net of the growth of the lost tax: $1 a year for ever, growing, is worth 1/(r − g) today."
- Problem: the JR overview and the comparison tip now say it plainly ("the interest rate minus the loss's yearly growth, r − g"); the explorer, where a voter moves the dial, keeps "real discount rate net of the growth".
- Proposed: "The authors draw r − g, the interest rate minus the lost tax's yearly growth: $1 a year for ever, growing, is worth 1/(r − g) today."
- Also on: `rjkdc-analysis/site/repro.qmd` (Step 4 and the symbols table), the JR deck's "What is being estimated" slide, the comparison report's "The common output" and "Conventions", `comparison/DISPUTES.md` rows 2 and 10.

### V-12. A formula as a button label on the JR explorer  [minor] [JR]
- Where: `rjkdc-analysis/R/site.R` line 126 (`labels = c("1 − WT/94.2", ...)`)
- Now: the share-lost dial's buttons read "1 − WT/94.2", "0.30 to 0.60", "0.283 fixed". The first button's tip says "First version: income tax is lost in proportion to wealth lost, so f moves with the revenue draw."
- Problem: a voter cannot read "1 − WT/94.2" as a choice; the meaning is only in the tip.
- Proposed: label "tied to revenue (first version)", with the formula kept in the tip.
- Also on: the JR deck's "The seven inputs that move the answer" table and the JR checks page's first variation.

### V-13. The BSZ explorer cannot count the loss for longer and does not say where to  [suggestion] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html` line 235 (the fixed-inputs line)
- Now: "Fixed in every setting: ... and the yearly loss counted for 5 years (this OPA's reading of BSZ's example) at 3%."
- Problem: the horizon is the dispute a voter has just read about. On this explorer it is fixed, and the line points only to the report's table.
- Proposed: add a link: "To count the loss for longer, use the H dial on the comparison explorer."

### V-14. The BSZ explorer cites "BSZ, 2026"; the JR explorer cites venue and month  [minor] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html` line 211
- Now: "Boll, Saez and Zucman (BSZ, 2026) put the one-time tax at about $100 billion of wealth tax." JR explorer: "Jaros and Rauh (JR, NBER, September 2026) find ..."
- Problem: side by side, one analysis gets a venue and a date and the other does not; the overviews give both ("NBER, August 2026").
- Proposed: "Boll, Saez and Zucman (BSZ, NBER, August 2026) put ..."

### V-15. The BSZ report calls the departures "the most important guesswork in the whole dispute"  [minor] [BSZ]
- Where: `bsz-analysis/site/repro.qmd` line 723 (the leavers scenario) and line 1009 (the headline of "Every input, by origin")
- Now: "Whether any of these people has actually changed legal residence is a legal judgment, and the most important guesswork in the whole dispute (comparison/DISPUTES.md, row 3)." And: "The disputes with the JR analysis are mostly about inputs this table labels guesswork or scenario: who has left (disputes row 3), how long losses last, and whether a one-time tax triggers permanent departures."
- Problem: the comparison, which measures the disputes, puts the departures third on the explorer's path (−$29.9B, after −$81.3B and −$39.4B) and outside the three largest averaged over every order on the net fiscal effect (q, f, H). The second sentence's list leaves out the court discount, the second largest term, because BSZ have no such input. A voter who reads both pages gets two rankings. I think line 723 means "the most important guesswork among the BSZ inputs".
- Proposed: line 723: "... is a legal judgment, and one of the largest disputes between the two analyses (comparison/DISPUTES.md, row 3)." Line 1009: add "and whether to discount the revenue for the chance the courts strike the tax down, which the BSZ analysis does not do".

### V-16. "Payable 1% a year over five years"  [minor] [BSZ]
- Where: `bsz-analysis/site/repro.qmd` line 140; `bsz-analysis/site/slides/slides.Rmd` line 206
- Now: report: "valued on 31 December 2026 and payable 1% a year over five years". Deck: "payable 1% a year over **five years**".
- Problem: "1% a year" can be read as the tax rate. The overviews say "payable over five years", and the Act lets the tax be paid at once or in five yearly installments with a 7.5% deferral charge (the comparison report: §50301(c)).
- Proposed: "payable at once or in five yearly installments".

### V-17. The BSZ report and deck give the BSZ case on the horizon, and not the JR reason  [minor] [BSZ]
- Where: `bsz-analysis/site/repro.qmd` line 593; `bsz-analysis/site/slides/slides.Rmd` line 340 (slide "step-5-loss")
- Now: report: "The JR analysis (...) counts the loss forever. That difference in horizon is one of the largest disputes between the two analyses". Deck: "counts them forever. That horizon is one of the largest differences".
- Problem: both overviews now give the JR reason; the BSZ report and deck give BSZ's argument for five years and only the bare fact that JR count for ever.
- Proposed: add after "counts the loss forever": "because it assumes leavers do not come back once the Act permanently lifts the constitutional cap on taxes on intangible property (chapter PDF p.32)." The same clause on the deck slide, if it fits.

### V-18. "We", "our" and "ours" with no one named  [minor] [all]
- Where: `bsz-analysis/site/repro.qmd` lines 496 ("We build the base scenario"), 732 ("We list this"), 775 ("agree with ours"), 1062 ("We read it as"); `rjkdc-analysis/site/repro.qmd` lines 164 ("we build it"), 224, 557, 835 ("Our R port"); `comparison/site/repro.qmd` line 872 ("Our column") and `comparison/R/site.R` lines 312, 329, 332 ("ours is", "Ours is", "we split it", "Ours moves"); `comparison/site/slides/slides.Rmd` lines 676 ("Next, we analyze") and 896 ("Ours follows"); `rjkdc-analysis/site/slides/slides.Rmd` line 462 ("We reproduce the code as shipped"); `bsz-analysis/site/checks.qmd` lines 197-198 and `rjkdc-analysis/site/checks.qmd` lines 196-197 ("We have sent this table ... We will update"); `comparison/R/site.R` line 1056 (the landing panel, V-09)
- Problem: the rest of the site says "this OPA" and "the author". "We" leaves a voter unsure whether a team, the original authors or the AI speaks. Carried over from run 003 (V-22), which named only some lines. Quotations from the papers ("we round", "we estimate") stay.
- Proposed: "this OPA" ("This OPA builds the base scenario", "This OPA's R port", "This OPA's column follows Hoopes's construction", "This OPA has sent this table to the original authors").

### V-19. "Those two steps of that walk" on the comparison deck  [minor] [comparison]
- Where: `comparison/R/site.R` line 146 (`eq_terms()` note, printed on the deck's "pseudo-eq" slide and in the report's "The explorer's equation")
- Now: "The D and q terms are those two steps of that walk."
- Problem: on the slide the path is called "the dial path"; "that walk" has nothing before it to point to.
- Proposed: "The D and q terms are single steps of the dial path."

### V-20. Report and deck figures have no alt text  [minor] [all]
- Where: `bsz-analysis/site/repro.html` (14 images with no `alt`; 13 of them have no caption either), `rjkdc-analysis/site/repro.html` (3), `comparison/site/repro.html` (2); the BSZ and JR decks' 5 chart images each (`slides.html`); the comparison deck, 1
- Problem: a screen reader announces an image with no description. The overviews' layer icons have empty alt with text beside them, which is fine; the report charts carry content.
- Proposed: a `fig-alt` on each figure chunk in the three `repro.qmd` and the two decks, saying what the chart shows (for example "Total wealth of California billionaires at the end of each year from 2019 to 2025 and on 1 July 2026"), with any value it names read from the data the chart uses.

### V-21. The repository's front page keeps "the income tax it changes"  [minor] [all]
- Where: `README.md` lines 20-21
- Now: "This OPA's main estimate, $106.8 billion, nets it of the income tax it changes"
- Problem: run 003 (V-04) replaced this phrase on the root page because "changes" does not say which way; the README, which the deck's layer slides send readers to, keeps it.
- Proposed: "This OPA's main estimate, $106.8 billion, adds the income tax from assets sold to pay it and subtracts the income tax lost to leavers over 5 years".

## Where the pages differ from the survey forms

The reference is `comparison/survey/mock_forms.py` as it stands at 05859dd (values filled from the exports). The forms are not to change; each finding proposes a change to an OPA page.

### V-22. The court term is "Chance the tax does not survive litigation" on the pages and "Discounting the revenue for court risk" in the forms  [minor] [comparison]
- Where: the step title in `comparison/R/model.R` line 83 and `comparison/py/bridge.py` line 103, which `eq_terms()` uses for the equation on the root, the explorer, the deck's "pseudo-eq" slide and the report's bridge tables
- Now: "− $39.44B Chance the tax does not survive litigation (q)". The same deck slide's agenda: "(ii) Is the revenue discounted for court risk?"; `comparison/DISPUTES.md` row 9: "Whether to discount the revenue for the chance the Act is struck down".
- Form: TERMS: "Discounting the revenue for court risk" (no discount / a 50% discount); GROUPS: "2. Discounting the revenue for court risk"; COURT title: "Discounting the revenue for the chance that courts strike the tax down: which is more credible?"
- Problem: a dollar amount next to "Chance the tax does not survive" reads as if the chance were $39.44B. The forms, the deck's own agenda and DISPUTES.md name the choice, which is clearer. A treated respondent sent from the form's closing page to the explorer meets a different name for the same term.
- Proposed: step title "Discounting the revenue for court risk" (with "(q)" on the explorer). The exports and the Python twin carry the title, so the rebuild and parity tests follow.

### V-23. The root's table says BSZ count no departures; the forms say BSZ allow 5% of the wealth for movers  [major] [comparison]
- Where: the root's "The differences" table, row "D departed / a avoidance / f share lost" (cells built by `q_cell()` in `comparison/R/site.R` lines 580-600 from the end tips at lines 498-503, cut to `QUANTITY_WORDS` = 25, line 221); the explorer's D end labels ("None named", "7 moves", `site.R` line 77)
- Now: BSZ: "D departed None named. No one counted by name without evidence of a change of legal residence before 1 January (BSZ PDF p.23). Kind: guesswork on data." "a avoidance 10.0%. A small allowance argued from enforcement (GGSS p.4). Kind: guesswork." JR: "D departed 7 moves. Seven counted as having moved in time, on public reports of their moves (chapter PDF p.21)."
- Form: DEPARTED BSZ: "5% of the wealth: an allowance for billionaires who moved in time, with no one counted by name without evidence of a change of legal residence before the date." DEPARTED JR: "About 29% of the wealth: seven billionaires (Page, Thiel, Hankey, Kalanick, Brin, Spielberg and Sacks) are counted as having moved in time, on public reports of their moves." AVOID: "Wealth that escapes the tax through avoidance and evasion, beyond moving away: ... 5%: a small allowance argued from enforcement." / "None." The treatment page's departed term: "no billionaire counted by name (its allowance for 5% of the wealth moving away in time is in part 4)".
- Problem: from the root a voter learns that BSZ assume nobody left and apply 10% for avoidance. The forms, the explorer's tips ("Half of a is people who moved in time") and the deck ("Its 10% avoidance already counts 5% of billionaires who left in time") say half of the 10% is people who moved. The 25-word cut keeps only each tip's first sentence, which drops exactly that. The JR cell gives a count, "7 moves", where the forms give the share of wealth, so the two sides are not on one scale. This misstates what one analysis assumes about departures.
- Proposed: put the split in the first sentence of each tip, so the cut keeps it. BSZ D: "None named; half of a, 5% of the wealth, allows for movers. No one is counted by name without evidence of a change of legal residence before 1 January." BSZ a: "Half moved out in time, half a small allowance for avoidance argued from enforcement." JR D: "Seven moves, 28.6% of the wealth, counted as having moved in time, on public reports." Check each against the three-line tip rule at 390 px and the 25-word cell.

### V-24. The share lost: the pages do not say what the 5% and 45% are shares of  [minor] [comparison]
- Where: the root's f cells (`q_cell()` from the tips at `comparison/R/site.R` lines 517-521); the comparison explorer's f ends
- Now: root: "f share lost 5%. No more than the share of wealth that leaves (BSZ PDF p.24). Kind: guesswork." / "45%. More than the 28.6% of wealth reported to have left (chapter PDF p.31). Kind: guesswork." The BSZ panel's f ends read "5% BSZ" and "50% JR"; the JR panel's "6% BSZ" and "45% JR".
- Form: SHARE: "45% of all the income tax that billionaires pay: more than the 29% of their wealth reported to have left, because income tax need not leave in step with wealth and some moves go unreported." / "5% of all the income tax that billionaires pay: the same as the 5% of their wealth assumed to leave, because the largest of the billionaires reported to have left pay little income tax for their wealth."
- Problem: "5%" of what? The forms say "of all the income tax that billionaires pay" and give a reason on both sides; the root drops both reasons (the tips keep them). A respondent who answered 45% in the form then sees 50% at the BSZ panel's JR end, explained only behind the box's "more" (settled as a label difference in 004 C-09 and 005 U-05; new here only because the forms print 45%).
- Proposed: tips' first sentences "The BSZ rule: 5% of all billionaires' income tax, the same share as the wealth assumed to leave." and "The JR rule: 45% of all billionaires' income tax, more than the 28.6% of wealth reported to have left." The BSZ panel's JR end tip: "45% of all billionaires' income tax, plus the BSZ movers' 5% while a stays at 10%."

### V-25. The court dial reads "chance it survives court: 100%" for BSZ; the forms say "No discount"  [minor] [comparison]
- Where: `comparison/R/site.R` line 236 (`DIAL_NAMES`, "chance it survives court") and the q ends; the root's q cells (tips at lines 509-510)
- Now: explorer: "q chance it survives court 50% JR 100% BSZ". Root: "100%. No discount; the tax is assessed at face value, as written (GGSS p.11)." / "50%. A discount; the revenue is multiplied by the chance the tax survives (chapter PDF pp.19-20)."
- Form: COURT: "No discount: the tax is assessed at face value, as written." / "A discount: the wealth tax collected is multiplied by the chance the tax survives in court, put at 50%." (The form's comment: q applies to the wealth tax, not the whole estimate.)
- Problem: "100%" under "chance it survives court" reads as BSZ claiming the tax is certain to survive, which no page quotes them saying. "The revenue is multiplied" can be read as the whole estimate; the deck and the report say the lost income tax is not scaled by q.
- Proposed: BSZ end label "100% (no discount)"; JR tip "A discount: the wealth tax collected is multiplied by the chance the tax survives in court."

### V-26. "Perpetuity" where the forms say "for ever"  [minor] [comparison]
- Where: `comparison/R/site.R` line 43 (`H = if (is.infinite(v)) "perpetuity"`), which prints the H dial's JR end and the root's bold value
- Now: explorer: "H years counted 5 years BSZ perpetuity JR". Root: "H years perpetuity. For ever, since leavers are assumed not to return ...".
- Form: HORIZON: "How long the lost income tax is counted: which is more credible? A. For ever: billionaires who leave are assumed not to return. B. 5 years, about the payment period, treating the departures as temporary."
- Problem: "perpetuity" is a finance word; the tip after it has to translate it. The forms and the tips say "for ever".
- Proposed: "for ever" as the printed value. `comparison/tests/testthat/test-endpoints.R` contains "perpetuity"; check whether it pins this string.

### V-27. The other two equation terms: "Lost income tax" and "The other three steps together"  [minor] [comparison]
- Where: `eq_terms()`, `comparison/R/site.R` lines 141-143 ("The other ... steps together" is pinned in `comparison/tests/testthat/test-site.R` line 152); the root shows them without symbols
- Now: root: "− $81.34B Lost income tax" and "+ $4.89B The other three steps together". Explorer: "(H, f, C, r)" and "(W, a, the minor switch)". The root's note: "then the other three."
- Form: TERMS: "The income tax lost when billionaires leave: the share lost, how long it is counted, and billionaires' yearly income tax, together"; "Other inputs together: the wealth on the list, avoidance, and three smaller inputs".
- Problem: on the root a voter cannot tell which inputs "the other three steps" are, and the term covers five inputs, not three. The forms name them in words.
- Proposed: root labels "Income tax lost when billionaires leave" and "Other inputs together (the wealth on the list, avoidance and three smaller inputs)"; the explorer keeps its symbols after them.

### V-28. The root's one-measure sentence leaves out the asset-sale income tax that the explorer and the forms include  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 330
- Now: root: "Both numbers measure the same thing: the wealth tax collected, counted at face value, minus the present value of the income tax lost". Explorer: "the net fiscal effect: the wealth tax collected, plus extra income tax from asset sales, minus the income tax lost to people who leave."
- Form: INTRO: "Both are on one measure: the wealth tax collected, plus the extra income tax from assets sold to pay it, minus the income tax lost when people leave."
- Problem: the BSZ definition line just above includes the asset-sale tax, so the root's "same thing" sentence and its own headline disagree, and the explorer defines the measure differently from the page that links to it. The sentence follows the author's run 002 answer (item 21), so this is for the author.
- Proposed: "Both numbers measure the same thing: the wealth tax collected, counted at face value, plus the extra income tax from assets sold to pay it, minus the present value of the income tax lost when people leave."

### V-29. The root's non-citizen cells give a reason for BSZ and none for JR  [minor] [comparison]
- Where: the root's "Non-citizens" cells (tips at `comparison/R/site.R` lines 549-550, cut by `q_cell()`)
- Now: BSZ: "Non-citizens $150B. Taxed (GGSS 20 Jul 2026 p.2). The non-citizen billionaires are in the base, like any other California resident. Kind: data." JR: "Non-citizens $0B. Not taxed (chapter PDF pp.17-18). Kind: guesswork."
- Form: NONCIT: "Taxed: the $150 billion of wealth of California billionaires who are not US citizens is in the base." / "Not taxed: the wealth of California billionaires who are not US citizens is left out of the base." The forms' rule (mock_forms.py, above SHARE): "a reason on both sides or on neither".
- Problem: the JR tip has a reason ("too uncertain (treaties, apportionment)"), but the 25-word cut drops it, while the shorter BSZ tip keeps its own. On the one table a voter is asked to judge, one side looks argued and the other bare.
- Proposed: shorten the JR tip so its reason survives the cut: "Not taxed: the 28 non-citizens are left out, as too uncertain to collect from (treaties, apportionment)." Or drop the reason from both cells, as the forms do.
