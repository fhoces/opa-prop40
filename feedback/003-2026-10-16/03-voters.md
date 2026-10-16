# Review 3: California voters, run 003
Commit: 199be92. Date: 2026-10-16. Pages read: `index.html` (root), `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`, the three explorers (rendered, with "Walk the path", the four Apply buttons and the presets pressed), the two checks pages (`*/site/checks.html`), the three reports (`*/site/repro.html`, introductions, the comparison's bridge section, the JR Steps 1 to 6 and Section 5.2, plus the `.qmd` sources), the three decks (`comparison/site/slides/slides.Rmd` in full and its rendered text; the BSZ and JR decks' title and opening slides), the three materials pages (openings), `README.md`, the survey redirect page. Screenshots taken: yes, but not with `screenshot.cjs` (Playwright is not installed). I used headless Chrome: laptop captures at 1280 px of the three overviews (the root as a full page); phone captures at 390 px through an iframe of that width, for the three overviews and the three explorers. I also ran three probes through the same iframe: a 390 px overflow probe on 15 pages (page `scrollWidth` against `clientWidth`), a probe at 390 and 1280 px on 11 pages for a minus sign on a different line from its number, and button probes on the three explorers. All files are in the scratch directory, none in the repository. `check_links.py` printed nothing, so no internal link is broken.

Not re-raised: the items in `feedback/DECISIONS.md` and the 19 questions of `002-2026-10-15/04-plan.md` (among them the badge beside the authors' names, the residency date in the first sentence, "All these are empirical quantities", the survey audience, "yearly tax revenue", the deck's opening slides, the −$39.0B headline value, "sent to the authors"), and the run 002 do-later and carried-over items, except V-15, which I list because it is a trust signal.

## Summary
- Counts: blocking 0, major 4, minor 19, suggestion 2
- The three to fix first: V-16, V-07, V-06
- Two sentences: the site told me that one team of economists expects Proposition 40 to raise about $100 billion and the other expects it to leave California about $39 billion poorer. The gap comes mostly from how long lost income tax is counted, whether the courts let the tax stand, and whether some billionaires had already left. I would come back for the explorers, but I left unsure why the JR analysis counts the loss for ever (its own page gives only the BSZ objection) and which three differences matter most (the report and the deck give two different lists).

## What I understood in ten minutes

How the ten minutes went. Minutes 1 to 3: the root on the phone and the laptop, the first paragraph, the two big numbers and the "What separates the two numbers" equation. I added the equation up on my phone's calculator and got −$38.9B, not the −$39.0B it says (V-06). Minute 4: the BSZ overview's first screen and footnote 1. Minutes 5 and 6: the JR overview's first screen and its "What the model says" fold. Minutes 7 and 8: the comparison explorer. I pressed "Walk the path" nine times and the BSZ panel went $106.8B, $76.9B, $37.5B, $32.4B, $29.0B, −$36.4B, −$43.9B, −$46.1B, −$33.6B, −$39.0B, then the button read "Start over". The four Apply buttons gave $76.9B, $37.5B, −$43.9B, −$39.0B, matching the equation. Minute 9: the JR explorer's "Rate 1.5%" preset (−$100.5B, "not printed by the authors"). Minute 10: the root's "The differences" fold on the phone, where I gave up at the r row ("the JR draw of r − g") and the "Kind: scenario" labels.

**Root.** Proposition 40 would tax Californians worth $1 billion or more, once, at 5% of their net worth, paid over five years. The BSZ analysis says it raises money; the JR analysis says the state ends up about $39 billion poorer because billionaires who leave stop paying income tax for ever. On one definition the BSZ number is $106.8 billion and the JR number −$39.0 billion. The equation says the gap is mostly billionaires already gone ($29.9B), the chance the tax does not survive in court ($39.4B) and lost income tax ($81.3B), and the note says the sizes depend on an order I did not understand. What I got wrong, checked after: I read "Jaros and Rauh (September 2026) print −" at the end of one line and "$38.9B from one run" on the next as a dash and a positive number (V-05). I took "from one run" to mean their number came from one random scenario. It is the average of 100,000 simulated draws (V-02). The first paragraph gave me no BSZ number to set against the JR one (V-01). I did not learn when the measure applies (residency date), which is question 16 and not re-raised.

**BSZ overview.** BSZ estimate about $100 billion of wealth tax; this site's main estimate is $106.8 billion because it adds the income tax effects, which is this site's choice. The first paragraph told me the site "reproduces that estimate", so I first read $106.8B as the BSZ number. Footnote 1 corrected me (V-14). The "What the model says" fold was clear: $103.8 billion of wealth tax, $3.68 billion of extra income tax from asset sales, $0.70 billion lost to leavers.

**JR overview.** The best first screen: "The loss decides the sign. The income tax lost for ever is worth about $75B today, against $36B of wealth tax collected once." What I got wrong: I took $36B to be what JR think the tax collects; the fold below says the chapter's own revenue figure is about $30B, and 36 is the average of the simulation's draw. What I never found on this page: why JR count the loss for ever. The only reason given about the horizon is the BSZ objection (V-16).

What I would tell a friend: "Two sets of economists looked at Prop 40. One says it raises about $100 billion; the other says the state loses about $39 billion, because billionaires who move away stop paying California income tax for ever. The gap is mostly how long you count that lost income tax, whether the courts let the tax stand, and whether some billionaires already left." What I would still be unsure about: why one side assumes the loss is permanent, and whether "billionaires already left" or "share of income tax lost" is the third big difference.

## Where the deep dive lost me

In reading order. Each entry: page, the sentence, why, the sentence that would have kept me.

1. Root, first paragraph: "(the chapter prints a mean of −$38.9B)". I had only met "NBER"; I did not know there was a chapter, and "mean" is a statistics word. Would have kept me: "(their paper prints an average of −$38.9B)" (V-02).
2. Root, JR definition line: "Jaros and Rauh (September 2026) print −$38.9B from one run." Read as one random scenario. Would have kept me: "Jaros and Rauh print −$38.9B, the average of one simulation of 100,000 random draws" (V-02).
3. Root, the equation: its rounded terms add to −$38.9B, and it ends "≈ −$39.0B". Would have kept me: "The amounts are rounded; unrounded they add up exactly to −$38.98B" (V-06).
4. Root, under the equation: "It is not a total, and its size depends on the order." No reason is given on this page or in the report's introduction. Would have kept me: "The inputs multiply each other, so a departure matters more when more wealth is left to tax" (V-07).
5. Comparison report, Introduction: two lists of "the three" (D, q, H, then q, f, H) in consecutive sentences (V-07).
6. Root, "The differences", r row: "Worth the same as the JR draw of r − g from 1.5% to 4.5%". I did not know what g is (V-08).
7. Root, "The differences", q row: "the accounting threshold for a tax more likely than not to stand" (V-09).
8. Root, "The differences": "Kind: scenario" and "Kind: research", defined nowhere on this page (V-11).
9. JR overview, "What the model says": "where r − g, the real discount rate net of the growth of the lost tax, is drawn between 1.5% and 4.5% and anchored on the S&P 500 dividend yield" (V-08).
10. JR overview, "What the model says": "Whether the income tax loss really lasts for ever is the main point the BSZ analysis ... disputes." I looked for the JR reason and found it only on the root's table and the comparison deck (V-16).
11. Comparison explorer, r dial: "Its weight within the JR draw: the JR explorer's Rate 1.5% and 4.5% settings." (V-17).
12. Comparison explorer, q dial JR end "50%", then the JR explorer's q dial at "1 (none extra)" for the same main estimate (V-18).
13. Comparison explorer: the heading "But what are the actual quantities?" is followed by no values (V-19).
14. JR report, Introduction: "$36B collected" and "its revenue of about $30B" two sentences apart (V-21).
15. BSZ deck, title slide: "An Open Policy Analysis of ..." / "by Jasper Boll, Emmanuel Saez and Gabriel Zucman (BSZ)". I took BSZ to be the deck's authors (V-23).

## What worked (keep)
- "Walk the path" and the Apply buttons: every press gave the value the equation prints, on a 390 px screen, and the button turns into "Start over" at the end.
- The new "For scale, the lost income tax itself is worth $75.0B today in the JR analysis and $0.7B in the BSZ analysis." It answered the question I had in run 002.
- The JR overview's "The loss decides the sign" line, and its fold's "Second, ..." paragraph reconciling 30 and 36.
- The comparison report's bridge sentence "The inputs interact, so a step's size depends on where the other dials stand when it moves. A departure matters more when the base is larger, for example." It is the clearest explanation of order on the site (V-07 asks to lift it).
- The deck's "The bridge shows where the $146B gap comes from. It cannot say which value of each input is right." This is a neutral, honest closing line.
- The BSZ checks page's "What could not be checked", now with "The measure values wealth on 31 December 2026".
- The JR explorer's share-negative row labelled "exact" and the "Litigation weight q = 0.5" preset's key line saying it raises the floor so the risk is not counted twice.
- No page scrolls sideways at 390 px; wide tables and code sit in their own scroll boxes. Every credit square has a spoken label (for example "Ideas and direction: author led conceptualization, supervision; Claude led methodology, project administration"). No page tells me how to vote.

## Findings

### V-01. The root's first paragraph gives the JR number and its reason, and neither for BSZ  [minor] [comparison]
- Where: `comparison/site/index.template.html` lines 302-306 (generated `index.html`); phone and laptop, first screen
- Now: "The BSZ analysis (Boll, Saez and Zucman, NBER, August 2026) finds that it raises money for the state. The JR analysis (Jaros and Rauh, NBER, September 2026) finds that it leaves the state about $39B poorer (the chapter prints a mean of −$38.9B), because billionaires who leave stop paying California income tax for ever."
- Problem: on a phone this paragraph is the whole first screen. One analysis gets an amount and a mechanism, the other a vague "raises money". A reader who stops here can remember only one number. It reads as if the page took the JR argument more seriously.
- Proposed: "The BSZ analysis (Boll, Saez and Zucman, NBER, August 2026) finds that it raises about $100 billion of wealth tax." If the author wants a BSZ reason clause to match the JR one, it should be taken from the BSZ abstract, not written by the loop.
- Also on: the comparison explorer's first paragraph is balanced ("raises money" / "loses money") and can stay.

### V-02. "The chapter prints a mean of" and "print −$38.9B from one run" on the root's first screen  [minor] [comparison]
- Where: `comparison/site/index.template.html` lines 305-306 and 323; `comparison/site/explorer.template.html` line 316
- Now: "(the chapter prints a mean of −$38.9B)"; "It is the exact average of the authors' model. Jaros and Rauh (September 2026) print −$38.9B from one run."; explorer: "which they print as −$38.9B from one run."
- Problem: "the chapter" has no referent on this page (the paragraph says "NBER"), and "mean" is a statistics word where "average" is used one line later. "From one run" reads as one random scenario, which undersells the authors' figure. It is the average of 100,000 draws in one seeded run of their simulation, as footnote 1 says. Not about which number the headline shows (question 14).
- Proposed: first paragraph "(their paper prints an average of −$38.9B)". Definition line: "It is the exact average of the authors' model. Jaros and Rauh print −$38.9B, the average of one simulation of 100,000 random draws." The explorer line the same way.

### V-03. The root names Open Policy Analysis but does not say what it is  [suggestion] [comparison]
- Where: `comparison/site/index.template.html`, end of the first paragraph
- Now: "This page puts both on one definition and shows which assumptions make the difference. It follows the Open Policy Analysis (OPA) framework."
- Problem: the BSZ and JR overviews say what the OPA does for the reader ("marks which inputs are data and which are guesses"). The root only names the framework and links a journal article.
- Proposed: "It follows the Open Policy Analysis (OPA) framework: every number, input and line of code behind both estimates is published, so anyone can check or change it." (The README's own wording: "opens every input, every line of code and every number".)

### V-04. The BSZ definition line on the root says "the income tax it changes"  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 318
- Now: "Net total: the wealth tax plus the income tax it changes, over 5 years, in today's dollars"
- Problem: "changes" does not say which way. The BSZ overview's line says it plainly (plus tax from asset sales, minus tax lost to leavers), and the JR line beside it says "minus the income tax lost for ever".
- Proposed: "Net total: the wealth tax, plus income tax from assets sold to pay it, minus income tax lost to leavers over 5 years, in today's dollars"

### V-05. A minus sign wraps onto a different line from its amount  [minor] [comparison] [JR]
- Where: `money()` in `comparison/R/site.R` lines 12-18 (the `{{nber_printed}}` token, `index.template.html` line 323, `explorer.template.html` line 316); `rjkdc-analysis/site/checks.qmd` line 32; the comparison report's tables; laptop and phone
- Now: measured in headless Chrome. At 1280 and at 390 px the root shows "Jaros and Rauh (September 2026) print −" with "$38.9B from one run." on the next line, and the comparison explorer shows "which they print as −" / "$38.9B". The JR checks page splits "−$38.89 billion" at both widths. In the comparison report at 1280, twelve cells of the table with columns "Step | DISPUTES row | Kind | BSZ value | JR value | Shapley | One order" show "−" above "$28.21B" (cells 66 px wide), and 22 amounts split at 390. The JR report splits "−$126.1B" and "−$24.7B" at 390.
- Problem: the sign is the whole point of the JR number. A dash at a line end followed by "$38.9B" reads as a positive amount, or as an em dash in the sentence.
- Proposed: keep the sign and the dollar sign together in `money()` (a word joiner, U+2060, after the sign) or wrap the amount in a no-wrap span, as the comparison deck's `usd()` already does (`comparison/site/slides/slides.Rmd` lines 50-52: "Wrapped so a line never breaks between the minus sign and the amount"). The same for the typed amount on the JR checks page and the JR report's `usdb()`.

### V-06. The equation's rounded terms add up to −$38.9B, and the equation ends "≈ −$39.0B"  [minor] [comparison]
- Where: the equation on the root, the explorer and the deck ("pseudo-eq"); its note, `order_note()` in `comparison/R/site.R` lines 744-749
- Now: "$106.8B − $29.9B − $39.4B − $81.3B + $4.9B ≈ −$39.0B"
- Problem: a reader who adds the five amounts gets −$38.9B, which is also the figure the authors print. So the equation seems to end at the authors' number, and the page's −$39.0B looks like a slip. The unrounded terms (`export/r/dial_path.csv`) do add to −$38.98B. Only the deck says why the sign is "≈": "The terms add up exactly; 'about equal' is only rounding."
- Proposed: add to the note on the root and the explorer: "The amounts are rounded to one decimal. Unrounded, they add up exactly to −$38.98B."

### V-07. "Its size depends on the order" has no reason, and the report and deck give two different lists of the three largest differences  [major] [comparison]
- Where: `comparison/site/repro.qmd` lines 121-125 (Introduction); `comparison/site/slides/slides.Rmd` slide "pseudo-eq" (the paragraph after the equation); the equation note on the root and the explorer (`order_note()`, `comparison/R/site.R` lines 744-749)
- Now: report: "On the explorer's path, three inputs separate the two most: how long the lost income tax is counted, the chance the tax survives a court challenge, and the wealth of billionaires who have already left. The sizes depend on the order the dials move in. Averaged over every order (...), the three largest are the chance it survives court (q), the share lost (f) and the years counted (H)." Deck (rendered): "The next three slides take the three largest steps on this path, *D*, *q* and *H*, in path order. The sizes depend on the order. Averaged over every order (...), the three largest are *q* (chance it survives court), *f* (share lost) and *H* (years counted)." Root: "It is not a total, and its size depends on the order."
- Problem: "Which assumptions make the difference?" is the question the comparison exists to answer. A voter gets two lists in consecutive sentences and no reason why an input's size could depend on order. The deck then gives its first "Difference" slide to the departed billionaires, an input that drops out of the order-free list. The reason exists, in the report's bridge section: "The inputs interact, so a step's size depends on where the other dials stand when it moves. A departure matters more when the base is larger, for example."
- Proposed: in the report's Introduction and on the deck's "pseudo-eq" slide, lead with what both lists share, then give the reason: "Two inputs are among the three largest in any order: how long the lost income tax is counted, and the chance the tax survives in court. The third depends on the order, because the inputs multiply each other: a departure matters more when more wealth is left to tax. In the explorer's order it is the billionaires already departed; averaged over every order it is the share of income tax lost." (Checked: path steps H −$65.4B, q −$39.4B, D −$29.9B; the deck's order-free three are q, f, H.) On the root and the explorer, after "its size depends on the order", add: "because the inputs multiply each other".

### V-08. "r − g" is never explained on the comparison pages, and the JR overview explains it in economists' words  [major] [comparison] [JR]
- Where: the r dial's JR end tip, `comparison/R/site.R` line 445, which also fills the root's "The differences" r row; the explorer's Notes ("Conventions"); `rjkdc-analysis/site/index.html` lines 449-455 ("What the model says")
- Now: root table: "r rate 2.73%. Worth the same as the JR draw of r − g from 1.5% to 4.5%, for a loss lasting for ever (NPV_dist_v8.R:22). Kind: derived." Explorer tip: "2.73%: worth the same as the JR draw of r − g from 1.5% to 4.5%, for a loss lasting for ever ($1 a year for ever is worth $36.6). Kind: derived." JR overview: "a loss that grows each year is worth 1/(r − g) times this year's amount today, where r − g, the real discount rate net of the growth of the lost tax, is drawn between 1.5% and 4.5% and anchored on the S&P 500 dividend yield (PDF pp.31-32)."
- Problem: on the root and the comparison explorer, g is never named, so a reader cannot tell what is subtracted from what. On the JR overview the definition is there but uses "real discount rate", "net of the growth" and "anchored on". This is the step the same page calls decisive ("The loss decides the sign").
- Proposed: comparison tip (the pinned ending kept): "2.73%: worth the same as the JR draw from 1.5% to 4.5% of r − g, the interest rate minus the lost tax's yearly growth ($1 a year for ever is worth $36.6). Kind: derived." The root's cell follows from the tip; check the 25-word limit. JR overview: "To put a loss that lasts for ever, and grows each year, into today's dollars, the authors divide this year's loss by a small rate: the interest rate minus the loss's yearly growth (r − g). Each run picks that rate between 1.5% and 4.5%; the low end is the S&P 500 dividend yield (PDF pp.31-32). At those ends, $1 a year for ever is worth 67 and 22 dollars today." (The 22-to-67 figures are already on the page, further down.)

### V-09. "The accounting threshold for a tax more likely than not to stand"  [minor] [comparison]
- Where: `comparison/R/site.R` line 427 (q dial, JR end tip), which also fills the root's "The differences" q row
- Now: "JR: the revenue weighted by 50%, the accounting threshold for a tax more likely than not to stand. Kind: guesswork."
- Problem: the phrase packs three ideas (an accounting rule, its "more likely than not" test, and the choice of 50%) into one noun phrase. The deck's litigation slide says it more plainly: "set at the 'more likely than not' threshold of an accounting rule (ASC 740-10 ...)".
- Proposed: "JR: half the revenue (50%), the 'more likely than not' line that an accounting rule uses for whether a tax will stand. Kind: guesswork."

### V-10. "The 28 are residents"  [minor] [comparison]
- Where: `comparison/R/site.R` line 452 (non-citizens dial, JR end tip); the root's "The differences" table
- Now: "JR: left out. The 28 are residents, but the chapter deems them too uncertain to collect from (treaties, apportionment). Kind: guesswork."
- Problem: "the 28" appears with no noun. A reader meets this number nowhere else on the page.
- Proposed: "JR: left out. The 28 non-citizen billionaires live in California, but the chapter deems them too uncertain to collect from (treaties, apportionment). Kind: guesswork." (`comparison/DISPUTES.md` row 8: "The 28 international billionaires, $146.3B".)

### V-11. Four of the six "Kind" labels in the root's table are not defined on the page  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 523 (the note under "The differences")
- Now: the table labels values "Kind: data", "Kind: research", "Kind: guesswork", "Kind: scenario", "Kind: guesswork on data" and "Kind: derived". The note under it defines only two: '"Guesswork on data" is a judgement applied to observed facts. "Derived" is a value computed from the analysis's own inputs ...'.
- Problem: "Kind: scenario" on the years counted and the BSZ rate tells a voter nothing, and the explorer's Notes fold has all six definitions. This is separate from question 11: it asks only for the definitions. The sources in the same table also read as code to a voter ("NPV_dist_v8.R:19").
- Proposed: put the explorer's six definitions under the table: "data (settled by observable facts), research (a published estimate), guesswork (asserted without data or a study behind it), guesswork on data (a judgement applied to observed facts), scenario (a choice of which world is estimated) and derived (computed from the analysis's own inputs)". For the sources: "the authors' code, NPV_dist_v8.R line 19", or one line under the table saying that ".R" sources are the authors' script files.

### V-12. The versions table says the March JR copy is "used here"  [minor] [comparison]
- Where: `comparison/R/site.R` line 792 (root, "Which document versions are used")
- Now: "Galle, Gamage, Saez, Shanske, response to Rauh | 17 Mar 2026 | answers Rauh's 4 Mar version, not the 17 Mar copy used here"
- Problem: the paragraph above the table says this site uses the latest versions, and the comparison uses the September chapter. "Used here" makes me think the comparison still rests on March.
- Proposed: "answers Rauh's 4 March version, not the 17 March version this project reproduces as the JR first version"

### V-13. Footnote 1 defines "main estimate" by itself  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 529; `comparison/site/explorer.template.html` line 388
- Now: "The main estimate on each analysis's overview page."
- Problem: the footnote is attached to "BSZ main estimate" and "JR main estimate", so it says "the main estimate is the main estimate". A voter wants to know why one number is "main" among the many settings.
- Proposed: "The one number each analysis's overview page leads with, out of the many settings each analysis can be run at." The rest of the footnote stays.

### V-14. The BSZ overview's first paragraph says the site "reproduces that estimate", then shows a different number  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html` lines 241-244; first screen, phone and laptop
- Now: "Boll, Saez and Zucman (BSZ) estimate it raises about $100 billion. This Open Policy Analysis (OPA) reproduces that estimate and marks which inputs are data and which are guesses." Then the headline: "$106.8B".
- Problem: a 10-minute reader takes $106.8B to be the reproduced BSZ number until footnote 1. The BSZ explorer's first paragraph already says it right: "This Open Policy Analysis (OPA) adds its income tax effects to get the main estimate."
- Proposed: "This Open Policy Analysis (OPA) reproduces that estimate, adds its income tax effects to get the main estimate below, and marks which inputs are data and which are guesses."

### V-15. The BSZ credit fold says the questionnaire is still being completed, then dates its answers  [minor] [BSZ]
- Where: `bsz-analysis/site/index.html`, "How AI was used in this exercise, and what has been verified"
- Now: "what is still being completed is the author's own review of each part, recorded in the last column below, and the author's questionnaire on who did what." Then: "The author gave these answers in a questionnaire on 2026-10-01".
- Problem: carried over from run 002 (rest of V-09), listed because it is the trust signal a voter reads: is the record done or not? The JR and comparison folds, answered on 2026-10-15, do not have the "still being completed" clause about the questionnaire.
- Proposed: needs the author's account of the BSZ re-interview. If it has not been run: "The BSZ answers are from a questionnaire on 2026-10-01 that gave one set of role answers for every object. An object-by-object interview, as for the JR analysis and the comparison, is still to come."

### V-16. The JR overview gives the BSZ objection to "for ever" but not the JR reason for it  [major] [JR] [BSZ]
- Where: `rjkdc-analysis/site/index.html` lines 449-487 ("What the model says"); `bsz-analysis/site/index.html` line 475; `rjkdc-analysis/site/repro.qmd` lines 466-469 (Section 5.2, "The horizon")
- Now: JR overview: "Whether the income tax loss really lasts for ever is the main point the BSZ analysis (Boll, Saez and Zucman) disputes." BSZ overview: "The JR analysis ... counts it forever; BSZ call treating the responses as permanent 'the main flaw in the scoring analysis of Rauh et al.' (PDF p.22, fn.29)." JR report: "Treating the loss as permanent is itself one of the disputed choices: the BSZ analysis argues the loss should be temporary and gives five years ..."
- Problem: the JR page says the loss decides the sign, then gives only the other side's objection to the assumption that drives it, with "really" adding doubt. A voter who reads only the two overviews sees the BSZ case against "for ever" twice and the JR case for it nowhere. That reads as a lean, though I do not think one is meant. The JR reason is on the root's table ("leavers are assumed not to return once the Act permanently lifts the intangible property tax cap") and on the comparison deck's horizon slide ("because the Act permanently removes the constitutional cap on intangible property taxes and lets the Legislature amend it by a two-thirds vote (chapter PDF p.32, Sec. 6)").
- Proposed: JR overview, after "billionaires who leave stop paying California income tax for ever": "The authors assume leavers do not come back, because the Act permanently lifts the constitutional cap on taxes on intangible property (chapter PDF p.32)." And: "Whether the income tax loss lasts for ever is the main point the BSZ analysis disputes." On the BSZ overview, after the BSZ quote: "The JR analysis assumes leavers do not return because the Act permanently lifts that cap (chapter PDF p.32)." The same sentence in the JR report's "The horizon" bullet. (The root's table cites "chapter Sec. 5.2" for the same reason and the deck cites "PDF p.32, Sec. 6"; the author should pick one citation.)

### V-17. "Its weight within the JR draw" in the r dial's tip  [minor] [comparison]
- Where: `comparison/R/site.R` line 403 (`slider_tips`, discount_rate)
- Now: "r, discount rate. The discount rate that turns a yearly loss into today's dollars. Its weight within the JR draw: the JR explorer's Rate 1.5% and 4.5% settings."
- Problem: the second sentence has no verb, and "weight" reads as a statistical weight. I think it means "to see how much the rate matters inside the JR draw, use these two settings".
- Proposed: "To see how much the rate matters inside the JR draw, use the JR explorer's Rate 1.5% and Rate 4.5% settings."

### V-18. The JR litigation weight is 50% on the comparison and "1 (none extra)" on the JR explorer  [minor] [comparison] [JR]
- Where: the comparison explorer's q dial (JR end "50%") and the root's q row; the JR explorer's "Extra litigation weight on the revenue q", which sits at "1 (none extra)" at the main estimate
- Now: comparison: "JR: the revenue weighted by 50% ..."; JR explorer: "1 (none extra) The script. Its 0 revenue floor already halves the mean revenue (36 = 0.5 × 72)."
- Problem: going from one explorer to the other, I saw two values for the same input of the same main estimate. The JR explorer explains its side. The comparison does not say that the JR explorer gets the same half through the revenue draw's 0 floor.
- Proposed: in the q dial's "more" on the comparison explorer (to keep the tip at three lines): "On the JR explorer the same half comes from the revenue draw's 0 floor (36 = 0.5 × 72), so its q dial reads 1 there."

### V-19. "But what are the actual quantities?" is followed by no quantities  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` lines 380-383 (`{{quantity_survey_x}}`); the heading is pinned by `comparison/tests/testthat/test-site.R` line 516
- Now: the heading, then "All these are empirical quantities ..." and the survey button. No values follow.
- Problem: a heading in the form of a question promises an answer, and the explorer gives a survey link instead. On the root the same section has the table. This is separate from questions 11 and 12.
- Proposed: keep the pinned heading and add one line under it: "Each dial's two ends above give both analyses' values; the overview's table of differences sets them side by side with their sources", linking to `index.html#the-differences`.

### V-20. The same BSZ avoidance input is α on the BSZ explorer and a on the comparison explorer  [minor] [BSZ] [comparison]
- Where: the BSZ explorer ("Avoidance and evasion α"); the comparison explorer ("avoidance a avoidance share")
- Problem: a reader moving between the two explorers meets two letters for one 10% input. The other shared inputs keep their letters (D, q, f, C, H, r).
- Proposed: one symbol on both pages, or "(a on the comparison explorer)" in the BSZ dial's "more".

### V-21. The JR report's Introduction gives $36B and "about $30B" for the revenue without connecting them  [minor] [JR]
- Where: `rjkdc-analysis/site/repro.qmd` lines 86-91
- Now: "At the authors' discount rates that lost stream is worth about $75B today, against $36B collected. This report rebuilds that number step by step. The chapter sets its revenue of about $30B against the $104B benchmark of the BSZ analysis (PDF p.3)."
- Problem: two revenue figures for one analysis, two sentences apart. The JR overview reconciles them ("That draw averages 36 (0.5 × 72, p.33), above the 30 the paper calls collectible"). The report does not, here or in Step 1.
- Proposed: "... against $36B, the average revenue in the authors' simulation (half of 72). The chapter's own revenue estimate is lower, about $30B, and it sets that against the $104B benchmark of the BSZ analysis (PDF p.3)."

### V-22. "We" with no one named  [minor] [JR] [BSZ]
- Where: `rjkdc-analysis/site/index.html` lines 388, 533, 535 ("We do not redistribute them", "Along the way we found nine mismatches", "We reproduce the code as shipped"); `rjkdc-analysis/site/repro.qmd` line 132 ("We follow that order") and the "printed values we compare against" sentence; `bsz-analysis/site/repro.qmd` lines 194 ("Everything else is ours") and 727
- Problem: elsewhere the pages say "this OPA" and "the author", and the credit fold says one author worked with Claude Code. "We" leaves me unsure whether a team, the original authors or the AI is speaking.
- Proposed: "this OPA" ("Along the way this OPA found nine mismatches"; "Everything else is this OPA's text").

### V-23. The BSZ deck's title slide reads as if BSZ made the deck  [major] [BSZ]
- Where: `bsz-analysis/site/slides/slides.Rmd` lines 2-3 (the title slide)
- Now: title "An Open Policy Analysis of “California Billionaires: Wealth, Taxes, and Wealth Tax Revenue Estimates”", subtitle "by Jasper Boll, Emmanuel Saez and Gabriel Zucman (BSZ)". No other line on the slide.
- Problem: on a title slide, "by" names the deck's authors. A reader takes Boll, Saez and Zucman to have made this reproduction, which they did not. That risks attributing this site's choices to them, such as the $106.8B net total ("this OPA's choice, not the authors'"). The comparison deck has an author line, and the JR deck's subtitle says "Teaching deck: JR's fiscal estimate ...". This is separate from question 9, which is about the badge.
- Proposed: subtitle "A reproduction of the paper by Jasper Boll, Emmanuel Saez and Gabriel Zucman (BSZ, NBER, August 2026)". If the author wants it, add an author line as on the comparison deck (the overviews carry no author line by decision; the decks are not covered by it).

### V-24. "Draw a third OPA in between the two" suggests a middle number  [minor] [comparison]
- Where: `comparison/site/slides/slides.Rmd` lines 214-218 (slide "why-opa-6")
- Now: "Once we can thoroughly appraise each policy analysis, we can understand their differences and draw a third OPA in between the two. This lays the foundations for resolving the differences and moving closer to a common reality."
- Problem: "in between" reads as a compromise estimate somewhere between $106.8B and −$39.0B. The comparison computes no such number, and the deck's own "next" slide says the bridge "cannot say which value of each input is right". I think the slide means a third OPA that connects the two.
- Proposed: "... and build a third OPA that bridges the two, one input at a time."

### V-25. The overviews and explorers carry no date  [suggestion] [all]
- Where: the six overview and explorer pages (the reports and checks pages say "Published October 15, 2026")
- Problem: the analyses were revised in August and September, and the BSZ workbook in October. A voter reading in late October cannot tell how current the numbers on the first screen are.
- Proposed: a generated "Last rebuilt on 2026-10-16" line in each page's footer, written by the build (a shared-kit change).
