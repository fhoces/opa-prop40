# California Proposition 40: Open Materials

This repository is an Open Policy Analysis of the two rival revenue analyses of California's
2026 Proposition 40 (the Billionaire Tax Act, a one-time 5% tax on the whole net worth of Californians
worth $1 billion or more).
The [comparison overview](https://fhoces.github.io/opa-prop40/) puts the two analyses on one
output definition. Each analysis is reproduced in full and opens every input, every line of code
and every number behind its main estimate. The aim is a transparent and reproducible account of
both that anyone can check, and a shared basis for discussing the policy.

### Review the code behind each main estimate: [BSZ](https://claude.ai/artifact/6VZEezoAsCNACjmgPLEvah), [JR](https://claude.ai/artifact/MykX5F4qRYF9gzCAbxBQUL), [the comparison](https://claude.ai/artifact/RyHG9pVfrp3ZTxq2KJic4C)

A layer-by-layer walk from the number on each page down to its raw source, one chain per analysis.
Each layer is marked reviewed, lightly reviewed or not reviewed. Work in progress; the record is
also kept in [`review/`](review/README.md).

<img align="right" width="340" src="bsz-analysis/site/assets/opa/opa-materials-wordmark.png" alt="Open Policy Analysis, Materials layer">

1 - **[The BSZ analysis](bsz-analysis/README.md).** Boll, Saez and Zucman, NBER Working Paper 35218 (August 2026;
NBER is the National Bureau of Economic Research, which circulates working papers): a one-time
wealth tax of about $100 billion. This OPA's main estimate, $106.8 billion, adds the income tax
from assets sold to pay it and subtracts the income tax lost to leavers over 5 years (not the
authors' headline, which is the wealth tax alone). [Overview page](https://fhoces.github.io/opa-prop40/bsz-analysis/site/). Materials
can be found in [`bsz-analysis/`](bsz-analysis/).

2 - **[The JR analysis](rjkdc-analysis/README.md).** Jaros and Rauh, NBER chapter c15504 (Tax Policy and the Economy, vol. 41; September 2026), the
revision of the March 2026 version by Rauh, Jaros, Kearney, Doran and Cosso (SSRN 6340778; SSRN is a
preprint site): a net present value to the state of about -$39 billion, because billionaires who
leave take their income tax with them. [Overview page](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/).
Materials can be found in [`rjkdc-analysis/`](rjkdc-analysis/).

3 - **[The comparison](comparison/README.md).** One common output definition, both analyses estimated on it, and a bridge
that explains the gap one disputed input at a time. [Overview page](https://fhoces.github.io/opa-prop40/).
Materials can be found in [`comparison/`](comparison/).

**Decisions the comparison makes.** To put the two papers side by side, the comparison makes six
analytical decisions. Each is a choice of this OPA, not of either author team. The report's
[Decisions this comparison makes](https://fhoces.github.io/opa-prop40/comparison/site/repro.html#the-decisions)
gives each one with its numbers and its alternative.

1. One common output for both, the net fiscal effect: the wealth tax collected, plus the extra
   income tax from assets sold to pay it, minus the income tax lost to billionaires who leave.
2. The BSZ end adds these income tax effects to the BSZ headline, which is the wealth tax alone.
3. The JR end is the average of the authors' Monte Carlo simulation of 100,000 draws, the figure
   their abstract leads with. The draws themselves spread widely, and the report shows that spread.
   This sets aside the JR analysis's effort to report and assess the uncertainty in its estimate.
   The comparison uses the average to represent the two estimates as the policy debate uses them,
   one number on each side, as in the [voter guide's arguments](https://voterguide.sos.ca.gov/propositions/40/arguments-rebuttals.htm).
4. The rate at the JR end is the single rate worth the same as the authors' random draw of
   r - g (2.73%), not the 3% midpoint of the draw.
5. Litigation risk at the JR end is a 50% chance on the revenue ceiling. This keeps the average
   of the authors' revenue draw, from zero to the ceiling, but not its spread.
6. Each end keeps its own horizon for the lost income tax: 5 years for BSZ, for ever for JR.

The comparison pages also open a short survey, which is itself a registered experiment. It asks
respondents which of two proposed values of each disputed input, the BSZ analysis's or the JR
analysis's, they find more credible. Half of the respondents, drawn at random when they click a
survey link, first see the comparison restated with each value labelled by its study; the other
half do not. The analysis was fixed before any response in a pre-analysis plan,
[`comparison/survey/PRE-ANALYSIS-PLAN.md`](comparison/survey/PRE-ANALYSIS-PLAN.md) (as a PDF,
`comparison/survey/plan/plan.pdf`), registered on the AEA RCT Registry as trial 19997 on
2026-10-19, before the forms open. The plan's section 9 gives the collection window and what is
published afterwards.

This project follows the [Open Policy Analysis (OPA) framework](https://doi.org/10.1093/scipol/scaa067) (Hoces de la
Guardia, Grant and Miguel, 2021). [`AUDIT.md`](AUDIT.md) scores each page against the OPA
Guidelines' nine steps, and [`PLAN.md`](PLAN.md) records the plan, the output fixed before
results, and the dated decisions that changed it after results.

<br clear="right">

## Layout

```
opa-prop40/
├── index.html             site root: the comparison overview (generated by comparison/)
├── assets/                the root page's data file, the shared stylesheets and fonts, the OPA images
├── bsz-analysis/          BSZ reproduction (R, {targets}, Python and SQL twins) + its OPA site in site/
├── rjkdc-analysis/        JR reproduction (R, {targets}, Python twin) + its OPA site in site/
├── comparison/            common output definition, the dial-path bridge with a Shapley check, R and Python twins, its OPA site in site/, the survey experiment in survey/
├── review/                code-review ledgers: the chain behind each main estimate, layer by layer
├── feedback/              the review loop's record: one directory per run or review, and the settled items in DECISIONS.md
├── docs/initiative/       the measure's full text (a public record) and its README
├── .claude/               the review loop skill (skills/opa-review-loop/) and the notes for later Claude sessions (memory/)
├── .github/workflows/     CI, one workflow per part
├── PLAN.md                plan, pre-specified output, decisions
└── AUDIT.md               OPA Guidelines audit baseline
```

`{targets}` is the R package that runs a pipeline's steps in order and records which outputs are
current; a twin is the same computation written a second time in another language and checked
against the R result. Each analysis publishes an export contract (`<folder>/export/r/{inputs,outputs}.csv`: the two CSV
files the comparison reads), and `comparison/` reads only those contracts plus the values
transcribed in `comparison/data/document-inputs.csv`.

## Status

| Part | State | Tests | CI |
|---|---|---|---|
| `bsz-analysis/` | BSZ reproduced cell by cell; the published results reproduce, with 7 notes on how the paper's text, tables and workbook describe them (materials page); OPA site (explorer, report, slides, materials) | [materials page](https://fhoces.github.io/opa-prop40/bsz-analysis/site/materials.html#tests), which reads the test output | `bsz-ci.yml`, green |
| `rjkdc-analysis/` | JR reproduced from the authors' code, R and Python; the published results reproduce, with 10 notes on how text, README and code describe them (`NOTES.md`); OPA site | [materials page](https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/materials.html#tests), which reads the test output | `rjkdc-ci.yml`, green |
| `comparison/` | Comparison overview at the site root, explorer with two slider panels, report and materials page; 10 disputed inputs (`DISPUTES.md`), 8 explorer dials and a switch for 3 minor inputs | [materials page](https://fhoces.github.io/opa-prop40/comparison/site/materials.html#tests), which reads the test output | `comparison-ci.yml`, green |

CI is continuous integration: an automatic rebuild and test run on every change, in
`.github/workflows/`. Each materials page prints the count of test expectations from the last
recorded run, so the counts are not repeated here. Each part's README gives its rebuild and test commands. The site is served at
<https://fhoces.github.io/opa-prop40/> as work in progress. The CRediT / AI-use answers are in
each `site/credit/CREDIT.md`.

## Sources policy

Third-party PDFs, workbooks and anything extracted from them (CSV, `*.sqlite`) are never
committed to this repo. Each analysis's `DATA-SOURCES.csv` records the source URL and SHA-256 of
every file it depends on instead (columns explained in `bsz-analysis/DATA-SOURCES.md`). See
`bsz-analysis/DATA-SOURCES.csv`, `rjkdc-analysis/DATA-SOURCES.csv` and `comparison/DATA-SOURCES.csv`.
Single values transcribed from a document, each with its page (`comparison/data/document-inputs.csv`,
and `hoopes-fig2.csv`, digitized from one chart), are citations, not copies, and are committed. So
are the measure's own text (`docs/initiative/`, a public record) and this project's own PDFs (the
survey's pre-analysis plan and power appendix under `comparison/survey/`).
