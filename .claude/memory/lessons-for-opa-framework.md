---
name: lessons-for-opa-framework
description: What building the Prop 40 OPA taught about the OPA framework, the shared kit and the survey experiment; for the opa-framework session to fold into the template and the guidance
metadata:
  type: project
---
# Lessons for the opa-framework session

From opa-prop40, written 2026-10-19 at the launch of its survey experiment. Each lesson names
where the evidence sits in this repository. The opa-framework session decides what goes into the
kit (`template/`), what into the written guidance, and what stays a Prop 40 particular.

## On the OPA itself

1. **Fix the output before any result, in a file with a date, and log every later change under
   it.** `PLAN.md` did this on 2026-09-23 and then carried thirteen dated decisions. The audit
   (`AUDIT.md`) could then say for each step what was fixed before results and what moved after.
   The kit should ship a `PLAN.md` skeleton with "Pre-specified output" and "Decisions after the
   first build" sections.
2. **An export contract between layers.** Each analysis publishes `export/r/{inputs,outputs}.csv`
   and the comparison reads only those. It let the comparison be rebuilt on a clean runner from the
   committed contracts, and it made "never retype a number" enforceable: the survey's forms
   (`mock_forms.py`) and the pages read the same export cells.
3. **Twins and byte-for-byte checks beat prose assurances.** R and Python twins with parity
   tests on numbers; CI that fails if the committed site root is not the generator's output; tests
   that pin the literal strings a page must carry. Together they caught every hand edit to a
   generated page during ten review runs.
4. **Label every input with its origin** (data, research, guesswork, scenario, derived,
   convention) and a basis with page or cell. The labels became the explorer's tips and the
   survey's questions. The Guidelines ask that guesswork carry "analyst X and date Y"; the
   contract should have those two columns from the start.
5. **One output definition, then a path between the two estimates.** The dial path in the
   equation's order (each dial to its far end, pressing Apply left to right reproduces each term)
   explained the gap to readers better than Shapley values, which stayed as a check in the report.
   Decide the path's order by the equation, not by the page's layout (PLAN decision 13).
6. **Keep a content map.** `CONTENT-MAP.md` (every public file: source, generated, record or
   read-only, with its rebuild command) is what let reviewers and implementers work without
   breaking generated pages. A `needs_render.py` that maps changed sources to rebuild commands
   belongs with it.

## On the shared kit

7. **Shared elements need one owner.** The headline block, the layer cards, the two-row nav line
   ("this OPA's pages" then "also in this project"), the footer and the credit fold were edited on
   three sites and had to be kept identical by hand. The kit should render them from one partial,
   or a test should compare the three.
8. **Phones.** Wide tables (the bridge, the credit table) and the waterfall were the recurring
   phone findings. The kit needs a narrow-screen rule for tables (scroll hint and a minimum first
   column) and a horizontal-bar fallback for waterfalls.
9. **Say what is tested instead of a badge.** The "Work in progress" badge was replaced by one
   sentence in the credit fold stating what is tested and what is still being completed (DECISIONS,
   Q3). The kit's materials page should print the count of test expectations from the last run
   rather than a status word.
10. **Headline semantics on the page.** Each OPA's main estimate may not be the authors'
    headline (the BSZ net total is this OPA's construction). The headline block needs a one-line
    definition and a footnote slot for "not the authors' choice", and the comparison needs a place to
    state the common measure.
11. **Attribution words.** Reviewers from the authors' side objected to "we" and "ours" and to
    attributing this OPA's constructions to the authors. "This OPA" as the subject, and "the X
    analysis" never "side", should be in the kit's style sheet.

## On the survey experiment inside an OPA

12. **Google Forms cannot randomize; the page can.** The draw at the click within entry-point
    strata, a share page that keeps the draw for a copied link, and a one-row beacon as a draw count
    (`draws.gs`) gave a working field experiment with no server. Its known holes: a no-script
    visitor or a bot reading the HTML lands in one arm; a forwarded form address skips the draw.
    Document the signature of each in the data (submissions above draws) before launch.
13. **The entry point is a stratum, not a treatment.** Readers who reach the survey from the
    explorer have seen the comparison; a shared link reaches some who have not. Register the entry
    point as a fixed effect and a heterogeneity dimension, and say that the experiment tests
    salience, not first exposure.
14. **Simulated pilots with language-model personas find wording problems, not effect sizes.**
    Two pretests (`feedback/008`, `feedback/009`) caught a share stated on two different bases,
    "guesstimated", a rebuttal inside a value, and a false promise in the public post ("names
    neither analysis"). They say little about people; the plan says so.
15. **Review the plan from four lenses before registering it.** Registry standards, internal
    consistency against every source, design threats with the browser mechanics read in the code,
    and readability for a reader outside economics (`feedback/011`). The 77 findings included two
    that would have made the analysis ambiguous (what S3 tests; whether a regenerated appendix
    governs the thresholds) and one that two documents going to the registry contradicted each other
    on (when the email question is asked).
16. **Pin every value the analysis will need.** Time zone of the close, the "after the vote"
    timestamp, the bootstrap seed, the failure criterion of the draw count, the base categories of
    the covariates, the A/B to study mapping of the control form inside the plan rather than in a
    private tab. Two analysts must not be able to run two analyses.
17. **Write the analysis code with the plan, freeze it at the launch commit, and define the data
    ingest before launch.** The pilot script drifted from the plan within two days; nothing turned a
    Google Forms export into the analysis's input. Both are review 012 items.
18. **Power for an unknown N: a staged rule.** With 0 to 200 responses expected, one primary
    test runs at any N and each further family runs only above a pre-registered threshold computed
    by simulation under the registered multiple-testing procedure. Report the detectable effect at
    the expected N, not only the N needed for a conventional effect.

## On the process

19. **A review loop from three audiences, with a decisions log.** Original authors, outside
    experts and voters disagree about what matters; a coordinator triaging into work packages, and
    `DECISIONS.md` so the next run does not reopen settled items, converged in ten runs.
20. **Cloud sessions without the toolchain still work if the rules are written down.** Edit
    sources, mirror the two generated pages, list rebuilds, hand off through a file in the repo,
    fetch `origin/main` before branching, commit by path while agents edit. The repo's
    `.claude/memory/` notes carry these rules across sessions.
21. **One sentence, one clause.** The author's editing rules (no em dashes, define every label at
    first use, statements not questions, say why something is needed) made the plan readable to a
    registry referee and to a voter alike. Put them in the kit's style sheet.
22. **Disclose AI use per object.** The CRediT and AI-use tables per site and the plan's opening
    note ("drafted with the assistance of Claude Code ... only intended as a record") set reader
    expectations; the per-object credit interview is still an open item here.
