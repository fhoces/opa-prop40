# Review 3: California voters, run 001
Commit: 1fd9491 (content at main 820bada). Date: 2026-10-14. Pages read: `index.html` (root), `bsz-analysis/site/index.html`, `rjkdc-analysis/site/index.html`, the three explorers (`comparison/site/explorer/`, `bsz-analysis/site/explorer/`, `rjkdc-analysis/site/explorer/`, rendered, dials and sliders moved), the three reports (`*/site/repro.html`, rendered text), the two decks (`*/site/slides/slides.Rmd`, plus the title slide rendered), the three materials pages (`*/site/materials.html`), `README.md`, `bsz-analysis/README.md`, `rjkdc-analysis/README.md`, `comparison/README.md`, `docs/initiative/README.md` and the measure's text (to check "5% of net worth" and "five installments"). Screenshots taken: yes (phone 390 and laptop 1280 of the three overviews and the three explorers, full-page phone captures with the folds opened, the decks' title slides; all under the scratch directory, none in the repository). `check_links.py` printed nothing: no internal link is broken.

## Summary
- Counts: blocking 0, major 10, minor 17, suggestion 5
- The three to fix first: V-01, V-02, V-06
- Two sentences: the site told me that one group of economists says the tax collects about $100 billion and another says the state ends up $39 billion poorer, and, once I found the footnotes, that the two mostly differ on whether billionaires who leave are counted as gone for five years or for ever. I would come back for the explorers, which are the clearest thing here, but on the first screen I could not tell what "present value", "mean NPV" or the minus sign meant, which of the three BSZ numbers was the real one, or who built the site and whether they lean.

## What I understood in ten minutes

How the ten minutes went. Minutes 1 to 3 on the root: read the first paragraph twice, looked at the two big numbers, did not read the footnote on the phone (it is below the numbers, small and grey) and on the laptop lost it at "The common output (b)". Minute 4: opened "A common output definition", saw a formula with "(a)" and "(b)" and "H years", closed it. Minute 5: BSZ overview, first screen and the "What the model says" fold; the four-row table was the first thing that made sense. Minutes 6 to 7: RJKDC overview; the first paragraph was the best sentence on the site; the fold's seven-row table and its "Second, ..." sentence lost me and I gave up on it. Minute 8: the comparison explorer; the opening question helped; I moved the BSZ panel's horizon slider to "perpetuity" and the number went from $106.8B to $101.9B, which surprised me (I expected it to fall near −$39B; it does not, because every other BSZ setting keeps the yearly loss tiny, which I only understood from the bridge text later). Minute 9: the bridge; on the laptop the waterfall is readable and the summary names the three biggest bars; on the phone I saw the left half of it. Minute 10: BSZ explorer, clicked avoidance 20%: $94.2B. Stopped.

**Root.** Proposition 40 is a one-time 5% tax on California billionaires' net worth, paid over five years. Two teams estimated it. BSZ say about $104 billion of tax, or $106.8 billion after some income tax effects I did not follow; RJKDC say the state loses $38.9 billion. I took "−$38.9B" to mean the tax brings in nothing and costs money, and I took the disagreement to be about how many billionaires leave. What I got wrong (checked against the deep dive): the RJKDC authors say the tax does collect about $30 billion; the minus comes from subtracting the income tax that billionaires who leave would have paid in every future year, for ever, and the single biggest reason the two differ is five years versus for ever, with "treating a one-time tax as a permanent one" and "who has already left" the next two. I also took $106.8B to be BSZ's number; it is this site's construction, and BSZ's own headline is $103.8 billion, which they round to $100 billion. "Work in progress" I read as "the numbers may change"; the records say the numbers reproduce and what is unfinished is the author's own review and the credit questionnaire. I could not say who made the site or whether they lean: the only clue on the first screen is the "Open Policy Analysis" link; the author's name is in the footer.

**BSZ overview.** BSZ estimate about $100 billion; this site's "main estimate" is $106.8 billion because it adds income tax from people selling stock to pay and subtracts income tax lost to the few who leave, counted for five years. The site rebuilt the authors' spreadsheet and marks which inputs are facts and which are guesses. The footnote "The main estimate is not the authors' choice" made me trust the page: it says whose number is whose. What I got wrong: "base scenario" I guessed meant "the normal case"; it is the first row of the paper's Table 5, which the fold explains. I did not notice until later that "at 3%" is a discount rate the BSZ authors never state (the site picked the middle of the other team's range), which the fold does say.

**RJKDC overview.** Clear in one sentence: the state ends up poorer because billionaires who leave take their income tax with them for ever. The number, −$38.9B, is an average over many random runs of the authors' model. What confused me: five names in the title but "Jaros and Rauh" in the text; a formula in the headline's definition line; and in the fold, two revenue numbers for one analysis ("about 30" and "36.00") joined by a sentence that says 36 is "below" 30. What made me trust it: the plain list of where the authors' own code disagrees with their own text (the mismatches), and "No other person has verified this work, and the original authors have not reviewed it." What I got wrong: I assumed the authors' $30 billion was what their headline uses; the deep dive says the simulation behind the headline uses $36 billion on average.

## Where the deep dive lost me

In reading order. Each entry: page, the sentence, why, the sentence that would have kept me.

1. Root, first paragraph: "finds a net present value of −$38.9B once income tax lost to billionaires who leave is netted out." Lost on "net present value" and on what the minus means. Would have kept me: "finds that the state ends up $38.9 billion poorer in today's dollars: the tax collects about $30 billion, but billionaires who leave stop paying California income tax for ever, and that lost stream is worth more." (V-01)
2. Root, headline block: "Net total, present value 5 years at 3%" and "NBER September 2026 mean NPV". None of these words is defined on the page. Would have kept me: a one-line gloss under the two numbers, "Present value: what dollars received or lost in future years are worth today." (V-02)
3. Root, footnote 1: "The common output (b), the net fiscal effect, puts both on one definition, and the explorer walks from one to the other." "(b)" points to a list I had not seen (it is inside a fold further down). Would have kept me: "One shared definition, which this site calls the net fiscal effect (explained under 'A common output definition' below), puts both on the same footing; the explorer walks from one to the other."
4. Root, footnote 1: "with the 5 years discounted over the RJKDC analysis's 1.5% to 4.5% rate range instead of at 3%." I do not know what "discounted over a rate range" does. Would have kept me: "(a discount rate turns future dollars into today's dollars; the BSZ page uses one rate, 3%, and the comparison uses the RJKDC analysis's range of rates; both give $106.8B)."
5. Root, "A common output definition": "(b) net fiscal effect = (a) + extra income tax from assets sold to pay − present value of income tax lost to departures, over a horizon of H years." Readable only after the explorer. Would have kept me: a words-first version before the formula: "Net fiscal effect: the wealth tax collected, plus the extra income tax from people selling stock to pay it, minus the income tax lost to people who leave, counted for some number of years (the two analyses disagree on how many)."
6. RJKDC overview, headline definition: "(NPV = WT − f·C / r), averaged over the authors' Monte Carlo draws." The formula and "Monte Carlo draws" mean nothing to me on a first screen. Would have kept me: "averaged over 100,000 random runs of the authors' model (a 'Monte Carlo')" and the formula moved to the fold. (V-17, V-19)
7. RJKDC overview, "What the model says": "Second, the Monte Carlo draws revenue with a mean of 36, the paper's litigation-discounted ceiling (0.5 × 72), below the 'about 30' it prints as collectible." 36 is not below 30, and I could not tell which revenue figure the headline uses. Would have kept me: see V-16.
8. RJKDC overview, "What reproduces": "all 21 cells round to the printed digit, replaying the authors' random-number (RNG) stream" and "within Monte Carlo error". Deep-dive wording is fine here, but one line would have helped: "(the reproduction matches the paper to within the randomness of its own simulation)."
9. Comparison explorer, panels: "September 2026 revision: Not an input of the common function: see the note under the panels." I did not know what "the common function" was. Would have kept me: "This one is a switch, not a slider: it adds the authors' September 2026 changes, which the shared formula cannot take as inputs (note below)."
10. Comparison explorer, bridge: "The default bars are Shapley values: each step's effect averaged over all 39,916,800 orders in which the inputs could be moved". I understood this only on the second read, after the sentence before it ("a departure matters more when the base is larger"), which should come first. Would have kept me: "Because the steps interact, each bar's size depends on the order you take them in. The default averages each step over every possible order (a 'Shapley value'), so the bars always add up to the gap."
11. Comparison explorer, slider notes: "No effect while the other sliders stay where they are." Which other sliders? Would have kept me: "No effect until the 'Permanent-rate' slider moves." (V-22)
12. Comparison report, "Introduction": "The RJKDC end is −$38.98B, the exact expectation of the Monte Carlo whose seeded run the authors print." Lost on "exact expectation" and "seeded run"; Step 2 of "The two main estimates" explains it well ("The authors print −$38.9B from one seeded run of the same Monte Carlo"), so the introduction could borrow that sentence.
13. BSZ report, Table 1: the "Growth during 2023-2025" row prints "1", "3", "0" where percentages belong, and the text says "some of the pipeline's display labels are wrong". Honest, and it says so, but a first-time reader sees a broken table before reading the note. Would have kept me: the note placed above the table, or the row formatted.
14. BSZ deck, "Step 5, part 1": the table with "α(1−m)" and "αm" column headers. The words next to them ("Under-valued or hidden", "Owner moves out of California") carry the meaning; the symbols could be dropped from the deck.
15. RJKDC deck, "What is being estimated": "The whole argument is a race between a one-time sum and a perpetuity." This kept me; it belongs on the RJKDC overview's first screen too.
16. RJKDC materials, "Tests" table: columns "tests | expectations | passed | failed | skipped" with rows like "2 | 25 | 2 | 0 | 0". Read as "2 of 25 passed" until the sentence below. (V-30)
17. `README.md`: "a one-time 5% tax on net worth above $1 billion". Read as "only the part above $1 billion is taxed"; the measure taxes the whole net worth of anyone at $1 billion or more. (V-31)

## What worked (keep)
- The RJKDC overview's first paragraph: "argues the state ends up poorer, because billionaires who leave take their income tax with them for ever." The one sentence a voter needs about that analysis.
- The comparison explorer's opening: "Why do the two analyses of Proposition 40 disagree?" and its first two sentences. Better than the root's title.
- The labels data / research / guesswork / scenario on every dial and bridge step, and the orange GUESSWORK badges on the BSZ explorer. A voter can see at once which inputs are facts and which are choices.
- "The main estimate is not the authors' choice: BSZ's headline is the wealth tax alone, $103.8 billion." Saying whose number is whose builds trust; it only needs to be larger and earlier (V-06, V-09).
- The BSZ "What the model says" table and the five-step build in the report and the deck, with the worked example "selling $100 of stock bought for $20 gives an $80 taxable gain".
- The RJKDC deck's "At r = 1.5%, losing one dollar a year for ever costs as much as losing 67 dollars today", and the overview's "a dollar a year for ever is worth 22 to 67 dollars today".
- The AI-use and human-verification table on the BSZ site, and the sentence "No other person has verified this work, and the original authors have not reviewed it." Exactly what a reader wants to know.
- Quoting Hoopes's own disclosures (his priors; his thanks to Gamage, a GGSS co-author).
- The explorers respond instantly, with "Jump to a scenario" presets, "Reset" buttons, and "the value the authors use" marked; the comparison panel's "With these sliders" line updates as you move a slider.
- Every internal link resolves; the explorers, reports and materials pages share one nav line and one footer; no page tells me how to vote, and both analyses get the same "guesswork" treatment.

## Findings

### V-01. The minus sign and "for ever" are not explained where the number first appears  [major] [comparison]
- Where: `comparison/site/index.template.html` lines 283-291 (generated `index.html` lines 283-291), the first paragraph; phone and laptop
- Now: "The RJKDC analysis (Rauh, Jaros, Kearney, Doran and Cosso; latest version Jaros and Rauh, NBER, September 2026) finds a net present value of −$38.9B once income tax lost to billionaires who leave is netted out."
- Problem: a reader who gives the page one minute reads "−$38.9B" as "the tax collects nothing and costs money". The paragraph does not say that the RJKDC authors also expect the tax to collect money (they print about $30 billion), nor that the lost income tax is counted for ever, nor that five years versus for ever is the main reason the two numbers differ. All three facts are on the page, in footnote 1 (12px grey, below the numbers) and in the folds.
- Proposed: "The RJKDC analysis (Rauh, Jaros, Kearney, Doran and Cosso; latest version Jaros and Rauh, NBER, September 2026) finds that the tax would collect about $30 billion but leave the state $38.9 billion poorer in today's dollars, because billionaires who leave stop paying California income tax for ever. The biggest single difference between the two: the BSZ analysis counts that lost income tax for about five years, the RJKDC analysis for ever." (I think "about $30 billion" is the authors' printed figure; the simulation behind their headline uses $36 billion, as the RJKDC overview says.)
- Also on: `comparison/site/repro.qmd`, "Introduction" (same wording); the comparison explorer's intro already says "for ever" but not that the tax collects anything.

### V-02. The headline sublabels are jargon, and "present value" is defined nowhere on the first screen  [major] [all]
- Where: `comparison/site/index.template.html` lines 302 and 307 (`index.html` 302, 307); `comparison/site/explorer.template.html` lines 302 and 307 (generated explorer 302, 307); `bsz-analysis/site/index.html` line 246; `rjkdc-analysis/site/index.html` line 244; both explorers' headline blocks
- Now: "Net total, present value 5 years at 3%" and "NBER September 2026 mean NPV"
- Problem: a voter does not know "present value", "NPV", "mean" (as an average), "NBER" or what "5 years at 3%" does. These two lines are the only words next to the two big numbers, so the numbers stay opaque.
- Proposed: BSZ: "Wealth tax plus the income tax it changes, counted over 5 years, in today's dollars"; RJKDC: "Wealth tax minus the income tax lost for ever, in today's dollars (Jaros and Rauh, September 2026, average of their model's runs)". And one shared line under the two numbers, on every page that shows them: "Today's dollars (present value): what money received or lost in future years is worth now."
- Also on: the BSZ overview's "(present value, 5 years at 3%)" and the RJKDC overview's "minus the present value of ... averaged over the authors' Monte Carlo draws" need the same gloss. A shared-kit change (headline block).

### V-03. What the measure does: who is taxed, on what date, and when they pay are missing from every overview  [major] [all]
- Where: `comparison/site/index.template.html` line 283 (`index.html` 283); `bsz-analysis/site/index.html` line 230; `rjkdc-analysis/site/index.html` line 226
- Now: "Proposition 40, the Billionaire Tax Act, would tax California's billionaires once, at 5% of their net worth, paid over five years."
- Problem: correct but incomplete for a voter asking "to whom, when". It does not say who counts (people resident in California on 1 January 2026 with a net worth of $1 billion or more), when wealth is valued (31 December 2026) or how it is paid (five equal yearly installments). The BSZ deck has all three facts ("on California residents on 1 January 2026", "wealth valued on 31 December 2026", "paid 1% a year over five years"), and the measure's text confirms "5 percent of the net worth" and "five equal installments". Without the residency date, the whole "who has already left" dispute makes no sense.
- Proposed: "Proposition 40, the Billionaire Tax Act, would tax people who lived in California on 1 January 2026 and are worth $1 billion or more: once, at 5% of their whole net worth as valued on 31 December 2026, paid in five equal yearly installments."
- Also on: the comparison report's introduction, the BSZ report's introduction ("paid 1% a year over five years" is there; the dates are not).

### V-04. Who made this site, paid for it, and whether it leans is nowhere on a first screen  [major] [all]
- Where: all three overviews; the only author line is the footer "OPA done by Fernando Hoces de la Guardia, using agentic coding tools" and the "How AI was used" fold
- Now: no sentence about affiliation, funding, or whether the site recommends a vote
- Problem: a voter arriving from a news story asks "whose side is this?" before reading a number. The site does not lean (I looked), but it never says so, and the author's name and affiliation are in the smallest text on the page. The OPA framework link is the only trust signal above the fold.
- Proposed (for the author, who knows the facts): one line under the title or above the footer on all three overviews, for example "By [name], [affiliation]. This site was not funded by either campaign, does not recommend a vote, and takes no side: it reproduces both analyses' arithmetic and shows where their assumptions differ." A shared-kit change.

### V-05. "Work in progress" is a badge with no explanation  [major] [all]
- Where: `comparison/site/index.template.html` line 281 (`index.html` 281); `bsz-analysis/site/index.html` line 228; `rjkdc-analysis/site/index.html` line 224: `<span class="wip">Work in progress</span>`
- Now: the badge has no title, link or sentence
- Problem: I read it as "these numbers may change", which undercuts everything below it. The records say the opposite: the numbers reproduce and are tested; what is unfinished is the author's own review of the code and the credit questionnaire (two of three sites say "The credit interview has not been run ... yet").
- Proposed: link the badge to the "How AI was used ... and what has been verified" fold and give it a title, and add one sentence under the title: "Work in progress: the numbers are final for the versions cited; what is still being completed is the author's review of each part, recorded under 'what has been verified' below." (The author should confirm what exactly is unfinished.) A shared-kit change.

### V-06. Three numbers for the BSZ estimate, with the reconciling sentence in a 12px footnote  [major] [BSZ]
- Where: `bsz-analysis/site/index.html` lines 230-233 ("estimate it at about $100 billion"), 244-250 (headline "$106.8B" and footnote); `comparison/site/index.template.html` lines 285-287 ("$103.8B of wealth tax, and $106.8B net"); `bsz-analysis/site/explorer/index.html` intro ("about $100 billion in wealth tax")
- Now: the BSZ overview says "about $100 billion" in the paragraph and "$106.8B" in the headline; the root says "$103.8B ... and $106.8B"; the deck says "$104 billion"; the footnote says "BSZ's own headline is the wealth tax alone, $103.8 billion."
- Problem: a 10-minute reader cannot tell which is "the" BSZ number or why the site's number is bigger than the authors'. The footnote that resolves it is the smallest, lightest text on the page and, on a phone, below the numbers.
- Proposed: put the reconciliation in the headline's definition line, above the footnote: "The authors' own headline is about $100 billion (exactly $103.8 billion of wealth tax). This site adds the income tax the tax changes: $106.8 billion." And in the root's first paragraph: "estimates $103.8B of wealth tax (the authors round it to $100 billion); this site's main estimate adds the income tax the tax changes, $106.8B."
- Also on: the comparison explorer header (same footnote), the BSZ explorer intro (V-24).

### V-07. "Reconciliation" in the root title reads as "they agree now"  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 281 (`index.html` 281) and `<title>`
- Now: "California Proposition 40, Reconciliation of the Two Analyses"
- Problem: to a non-economist "reconciliation" means the two have been brought into agreement. The explorer's heading says what the page does.
- Proposed: "California Proposition 40: Why the Two Analyses Disagree", or keep the title and open the paragraph with the explorer's question.

### V-08. One page, five names  [minor] [all]
- Where: `bsz-analysis/site/index.html` line 452 ("reconciliation page"); `bsz-analysis/site/explorer/index.html` line 268 ("comparison OPA"); `bsz-analysis/site/index.html` line 250 and the explorers ("other analyses"); `rjkdc-analysis/site/index.html` ("comparison overview"); the comparison explorer nav ("Overview")
- Now: the root page is linked as "reconciliation page", "comparison OPA", "other analyses", "comparison overview" and "Overview"
- Problem: I did not realise these were the same page until the third visit.
- Proposed: one name everywhere, "the comparison overview" (matching the RJKDC overview and the explorer nav). A shared-kit change.

### V-09. The sentences that explain the numbers are 12px grey  [minor] [all]
- Where: `bsz-analysis/site/index.html` line 83 (`.headline .fn { font-size: 12px; color: var(--ink-3) }`) and line 350; same rule on the root and the explorers; the `.def` line is 13.5px
- Now: footnote 1 on each headline block, and the "Defined as" line, are the smallest and lightest text on the page
- Problem: these carry the one thing a voter needs (whose number, what it counts). On a phone they sit below the numbers at 12px grey.
- Proposed: 14px and `--ink-2` for `.headline .fn`, 15px for `.def`; or move the key sentence into the definition line (V-06). A shared-kit change.

### V-10. Abbreviations and terms used before they are explained  [minor] [all]
- Where: root first paragraph (NBER, WP, SSRN in the folds), root folds (GGSS, LAO, pp, Shapley, CRediT), BSZ headline ("base scenario"), RJKDC headline and fold (NPV, Monte Carlo, NBER), the comparison explorer ("DISPUTES row", "pp")
- Now: "NBER WP 35218", "GGSS", "LAO (neutral context)", "base scenario", "mean NPV"
- Problem: each page is entered cold from a search; the term is often explained on another page or lower down.
- Proposed: expand on first use on each page: "NBER (the National Bureau of Economic Research, which circulates working papers)", "SSRN (a preprint site)", "GGSS (the Galle, Gamage, Saez and Shanske expert report that supports the measure)", "the LAO (the Legislative Analyst's Office, the state's nonpartisan fiscal adviser)", "base scenario (the authors' main case, row 1 of their Table 5)", "mean NPV (the average net present value over the model's runs)".

### V-11. The watermark icon sits behind the words of "Three layers to understand the analysis"  [suggestion] [all]
- Where: `bsz-analysis/site/index.html` lines 85-90 (`.section-title-icon`, opacity 0.14, centred behind the h2) and 267-270; same on the root and RJKDC; laptop width
- Now: at 1280px the icon overlaps "understand"; on a phone it sits behind "to"
- Problem: it reads as a rendering glitch rather than a design.
- Proposed: place the icon above or beside the heading, not behind it. A shared-kit change.

### V-12. The root's eight folds are headings with no hint of what is inside  [suggestion] [comparison]
- Where: `comparison/site/index.template.html` lines 384-594 (`index.html` 384-594), the `<details>` folds
- Now: "A common output definition", "The vintage gap", "Neutral material and credited alternative dials", ...
- Problem: on a phone the folds are a wall of eight headings; a 10-minute reader has no way to pick one. The BSZ and RJKDC overviews have three folds and are fine.
- Proposed: a one-line teaser under each summary, for example "The vintage gap: the documents were written months apart; which version each number comes from."

### V-13. "Neutral material and credited alternative dials" is project jargon  [minor] [comparison]
- Where: `comparison/site/index.template.html` line 519 (`index.html` 554)
- Now: "Neutral material and credited alternative dials"
- Problem: "credited alternative dials" means nothing outside this project.
- Proposed: "Other estimates of the yearly income tax loss (the Legislative Analyst, the California Tax Foundation), for scale".

### V-14. Wide tables and the bridge chart scroll sideways on a phone with no hint, and the bridge table's first column wraps one word per line  [major] [comparison]
- Where: `comparison/site/explorer.template.html` (generated explorer lines 558 and 575-576: `svg.waterfall` with `min-width: 640px` inside `.chart-scroll`, and `#bridge-table` at 668px inside `.table-scroll`); root folds (the "Analysis" table 494px, Hoopes 509px, disputed inputs 609px, loss table 725px, credit table 402px); BSZ credit table 438px; RJKDC credit table 395px; phone width (measured at 390px, viewport 358px inside the gutters)
- Now: each sits in an `overflow-x: auto` box; the page itself does not scroll sideways (good), but nothing says "scroll"; on the first screenful of the bridge a phone shows the BSZ bar through "Proportional loss" and nothing after, and the table shows "Non-US-citizen residents" wrapped over three lines with the Step and Running total columns off-screen; the credit table's "Human verification" column, the one a voter wants, is cut at "HUMA VER" on the BSZ phone view
- Problem: a phone reader does not discover that the bars for the horizon, the revision and the RJKDC end, or the step values, exist.
- Proposed: a short line above each scrolling box, "Scroll sideways for the rest"; at phone width draw the waterfall as horizontal bars (one row per step, label left, value right) so it fits; give the bridge table's first column a `min-width` of about 11em so names do not wrap word by word, and on phones show only Step, Kind, Step $B and Running total. For the credit tables, let the "Human verification" column come first or stack the table on phones.
- Also on: `comparison/site/index.template.html` folds; `bsz-analysis/site/index.html` and `rjkdc-analysis/site/index.html` credit tables. A shared-kit change for the credit table.

### V-15. The overviews have no site-nav line  [suggestion] [all]
- Where: the three overviews' headers; compare the explorers, reports and materials pages, which open with "BSZ analysis of California Proposition 40: Open Output (here) · Open Analysis: Report and Slides · Open Materials · Overview"
- Now: from an overview, the other two sites are reachable only from the footer
- Problem: navigation is the same on every page except the three a voter lands on.
- Proposed: the same one-line nav at the top of each overview, with "Overview (here)", plus links to the other two overviews. A shared-kit change.

### V-16. A sentence that says 36 is below 30, and two revenue figures for one analysis  [major] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` lines 359-360, in "What the model says"; and the table above it ("Wealth tax revenue, the paper's headline: about 30 (28.4 to 35.6)" and "Mean revenue in the Monte Carlo's draw: 36.00")
- Now: "Second, the Monte Carlo draws revenue with a mean of 36, the paper's litigation-discounted ceiling (0.5 × 72), below the "about 30" it prints as collectible."
- Problem: as written, 36 is "below" 30. I think it means that the simulation behind the headline uses an average revenue of $36 billion, which is higher than the "about $30 billion" the paper prints as the collectible amount, and that the two are different things. A voter cannot work that out, and sees two revenue numbers for one analysis with no reconciliation.
- Proposed: "Second, the paper says the tax would collect about $30 billion. The simulation behind the headline uses more: it draws revenue anywhere between $0 and $72 billion (the most the tax could collect if it survives in court), an average of $36 billion. So the headline rests on a revenue figure above the one the paper prints." Say "I think it means" to the author if the intent differs.
- Also on: `rjkdc-analysis/site/repro.qmd`, Section 4.4 last paragraph ("The Monte Carlo does not use this point estimate"), which is clear; the overview could reuse it.

### V-17. "averaged over the authors' Monte Carlo draws" on the first screen  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` line 246; `rjkdc-analysis/site/explorer/index.html` line 196
- Now: "averaged over the authors' Monte Carlo draws."
- Problem: "Monte Carlo" and "draws" are explained only in the fold ("100,000 random draws of those inputs").
- Proposed: "averaged over 100,000 random runs of the authors' model (a 'Monte Carlo' simulation)."

### V-18. Five names in the title, two authors in the text  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` line 224 (title) and lines 227-229 ("reproduces that estimate from Jaros and Rauh, with Kearney, Doran and Cosso"); root first paragraph ("latest version Jaros and Rauh")
- Now: no sentence says why
- Problem: a reader wonders whether three authors dropped out or whether these are two papers. The explanation is in the root's "The vintage gap" fold.
- Proposed: one sentence in the RJKDC intro: "The first version (March 2026) had five authors, Rauh, Jaros, Kearney, Doran and Cosso; the September 2026 revision this site reproduces is by Jaros and Rauh. This site keeps the five-letter name for both."

### V-19. A formula in the headline's definition line  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/index.html` lines 244-246; `rjkdc-analysis/site/explorer/index.html` lines 194-196
- Now: "Defined as the one-time wealth tax revenue minus the present value of California income tax lost for ever to billionaires who leave (NPV = WT − f·C / r), averaged over the authors' Monte Carlo draws."
- Problem: the words before the parenthesis already say it; the formula on the first screen signals "not for you".
- Proposed: drop "(NPV = WT − f·C / r)" from the headline line on the overview; keep it in the explorer and the fold, where it is explained symbol by symbol.

### V-20. The credit and human-verification table is empty on two of the three sites  [major] [RJKDC] [comparison]
- Where: `rjkdc-analysis/site/index.html` line 450 and `comparison/site/index.template.html` line 580 (`index.html` 620): "The credit interview has not been run for this analysis yet." under an empty five-row (RJKDC) and four-row (comparison) grid; `*/site/credit/credit-answers.json` are read-only
- Now: an empty grid, a legend for squares and dots that do not appear, and the "Human verification" column blank
- Problem: the deep-dive question "what has a person checked and what has not" has no answer on the RJKDC site and the comparison, which is exactly where a voter would want it (the comparison is the site root). The BSZ table shows how good this is when filled.
- Proposed (for the author; the answers are read-only): run the questionnaire for the RJKDC analysis and the comparison. Until then, replace the empty grid with the one-line note and a date ("Not yet filled in as of October 2026"), so the page does not show an unexplained blank table.

### V-21. Code names in the explorer's body text  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` lines 325-330 and 408-412 (generated explorer 325-330, 526-530); the bridge table note ("comparison/export/r/inputs.csv", "the DISPUTES row")
- Now: "That function, score_common(), computes both analyses ... Your browser does the arithmetic with model.js, a copy of the function the pipeline uses (comparison/R/model.R)."
- Problem: file and function names in the voter-facing paragraphs read as "for programmers"; the "Notes and data" fold at the bottom already holds this.
- Proposed: in the body, "one formula, used for both analyses"; move `score_common()`, `model.js` and the paths into "Notes and data".

### V-22. "No effect while the other sliders stay where they are" does not say which slider unlocks it  [minor] [comparison]
- Where: `comparison/site/explorer.template.html` line 629 (generated explorer 766); shown under "Elasticity size" and "Proportional loss" in the BSZ panel
- Now: "No effect while the other sliders stay where they are."
- Problem: the BSZ explorer's equivalent hint names the switch ("Switch on 'Count billionaires Forbes misses' above to use this."); this one does not. From `score_common()`: the elasticity enters only once "Permanent-rate" is above "none applied"; the proportional-loss factor enters only once some billionaires leave in the panel ("Departed" above 0% or "Permanent-rate" applied).
- Proposed: "No effect until the 'Permanent-rate' slider moves." for elasticity size; "No effect until some billionaires leave in this panel ('Departed' or 'Permanent-rate')." for proportional loss.

### V-23. −$38.9B and −$39.0B side by side with the explanation two paragraphs down  [minor] [comparison]
- Where: `comparison/site/explorer.template.html`, the RJKDC panel header ("RJKDC: −$38.9B" and "With these sliders −$39.0B"), the bars ("RJKDC panel −$39.0B") and the panel note ("Every slider starts at the RJKDC value, so the panel starts at −$38.98B, the exact expectation ... Their seeded run ... gives −$38.9B")
- Now: the two numbers sit six lines apart before the note explains them
- Problem: a 10-minute reader sees a mismatch and stops trusting the slider.
- Proposed: in the panel header line: "With these sliders −$39.0B (the model's exact average; the authors' published run gives −$38.9B)".
- Also on: the root's footnote 1 and the bridge's RJKDC end (same pair).

### V-24. "that is the main estimate" has no clear referent  [minor] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html`, the intro paragraph under "How much would the one-time billionaire tax raise, net?"
- Now: "Boll, Saez and Zucman (BSZ, 2026) estimate about $100 billion in wealth tax. Net of the income tax it changes, that is the main estimate."
- Problem: "that" seems to point at $100 billion, but the main estimate is $106.8B.
- Proposed: "Boll, Saez and Zucman (BSZ, 2026) estimate about $100 billion of wealth tax. Add the income tax the tax changes and the total, $106.8 billion, is this site's main estimate."

### V-25. The BSZ dials' plain-language descriptions are hidden behind the info button  [minor] [BSZ]
- Where: `bsz-analysis/site/explorer/index.html` lines 342-392 (the `.tip` built from `dial.desc`); the descriptions live in `grid.js` (generated by `R/site_exports.R`)
- Now: labels alone: "Share of avoidance that is leaving", "Avoidance by the less visible billionaires", "Aggressive assumption on leavers"; the good descriptions ("Only this part costs income tax", "Page, Thiel, Hankey, Kalanick escape the tax; Brin, Zuckerberg, Fang leave later") appear only on tapping ⓘ
- Problem: the RJKDC explorer prints its descriptions under each dial and is easier to use; here a voter sees six cryptic labels.
- Proposed: print the first sentence of each description under the dial, as the RJKDC explorer does, and keep the source reference in the tip.

### V-26. "draw" and the symbols in the RJKDC dial names  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/explorer/index.html`, the dial labels (from `grid.js`, generated by `R/site.R`): "Revenue, low end of the draw ($B) wt_lo", "Discount rate drawn, r", "Share of the income tax base that leaves, f"; the descriptions cite "mismatch 5", "U[3.3, 5.8]", "PDF p.21"
- Now: "draw" is used in the statistical sense without saying so
- Problem: a voter reads "draw" as a tie or a sketch; "U[3.3, 5.8]" is notation.
- Proposed: "Revenue: the lowest value the model's random pick can take ($B)" and "the highest value ..."; "Discount rate: the range the model picks from"; replace "U[3.3, 5.8]" with "anywhere between 3.3 and 5.8" in the descriptions, keeping the symbol in grey after the name.

### V-27. "NBER, Sept 2026" as a column name in the outcomes table  [suggestion] [RJKDC]
- Where: `rjkdc-analysis/site/explorer/index.html`, "Outcomes for this setting" table header
- Now: "This setting | NBER, Sept 2026"
- Proposed: "This setting | Main estimate (as published, September 2026)".

### V-28. The RJKDC deck prints "bn" where every other page prints "$B"  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/slides/slides.Rmd` line 175 ("estimates it at about 100 bn. (Amounts in this deck are in billions of dollars, "bn".)") and the `num()` helper used throughout the deck ("−38.9 bn")
- Now: "bn" in the deck, "$B" on the overview, explorer and report, "$103.8 billion" in the BSZ deck
- Problem: three unit styles for one number across one site.
- Proposed: "$B" in the deck's tables and "$38.9 billion" in its prose, as the pages do.

### V-29. The decks on a phone  [suggestion] [BSZ] [RJKDC]
- Where: `*/site/slides/slides.html` at 390px: the slide renders 390px wide with about 9px text, and the "← Overview" button covers the slide's lower-left corner
- Proposed: on the overview's "Slides" card, add "(best on a laptop)"; move the Overview button into the grey margin below the slide.

### V-30. The RJKDC materials "Tests" table reads as "2 of 25 passed"  [minor] [RJKDC]
- Where: `rjkdc-analysis/site/materials.qmd`, the "Tests" table (rendered `materials.html`: columns "tests | expectations | passed | failed | skipped", rows like "test-income-tax-mc.R | 2 | 25 | 2 | 0 | 0")
- Now: "passed" counts tests, next to a column that counts expectations
- Proposed: head the columns "tests | expectations | tests passed | tests failed | skipped", or count expectations passed as the BSZ page does.

### V-31. "a one-time 5% tax on net worth above $1 billion" can be read as taxing only the excess  [major] [all]
- Where: `README.md` line 4
- Now: "(the Billionaire Tax Act, a one-time 5% tax on net worth above $1 billion)"
- Problem: a reader can take this to mean the 5% applies only to the part of a fortune above $1 billion. The measure's text taxes "5 percent of the net worth" of anyone at $1 billion or more (with a phase-in between $1.0 and $1.1 billion, which the BSZ report's "Missing billionaires" step uses). For a voter that is the difference between a tax on a billionaire's whole fortune and a tax on a sliver of it. The overviews say "5% of their net worth", which is right; the README is the repository's front page and the first thing a GitHub visitor reads.
- Proposed: "(the Billionaire Tax Act, a one-time 5% tax on the whole net worth of Californians worth $1 billion or more)".
- Also on: `.claude/skills/opa-review-loop/CONTENT-MAP.md` line 9 (not public; same phrase).

### V-32. Test counts disagree between the README and the materials pages  [minor] [all]
- Where: `README.md` lines 61-63 ("561 expectations", "159 expectations", "179 expectations"); `bsz-analysis/site/materials.html` and `repro.html` ("719 expectations passed", run 2026-10-07); `comparison/site/materials.html` ("389 expectations passed")
- Now: 561 against 719 for BSZ; 179 against 389 for the comparison; RJKDC agrees (159)
- Problem: the deep-dive check "do the numbers agree from page to page" fails on the first trust signal a reader checks, the test counts.
- Proposed (for the author): read the counts in the README from the same CSVs the materials pages read (`bsz-analysis/site/data/test-results.csv`, the comparison's test output), or drop the counts from the README and link to the materials pages.
