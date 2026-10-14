#!/usr/bin/env python3
"""Seed review/comparison.json: the chain of code behind the comparison's two main estimates.

The headline is the two analyses' main estimates, shown next to each other on the comparison
explorer: the BSZ analysis's net total over 5 years and the RJKDC analysis's NBER (September
2026) mean NPV. Under the common output (b), the net fiscal effect, they are the bridge's two
ends, and the chain traces those two ends: the BSZ end is score_common() at the all-BSZ inputs,
the RJKDC end is the exact expectation of the NBER Monte Carlo. (The RJKDC main estimate as
printed, -38.9, is the authors' seeded run, which the RJKDC pipeline reproduces as -38.886;
its own chain is the RJKDC one.) The layers are written by hand below, top (the numbers on
the explorer) to bottom (the two analyses' export contracts). Snippets are cut from the files
at the line ranges given, so re-running this script after a code edit refreshes them. The
user's fields (state, understanding, missing, feedback) are kept from an existing
comparison.json when present.

GitHub links pin the commit the chain was traced at (HEAD when the script runs), as the
other seeds do. Reseed after any commit that touches a file on the chain, and after a merge
(a branch SHA does not exist on GitHub until it is pushed).

Run from the repo root:  python3 review/seed_comparison.py
"""
import csv
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "review" / "comparison.json"
REPO = "https://github.com/fhoces/opa-prop40"
TRACED_AT = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"],
                           capture_output=True, text=True, check=True).stdout.strip()
LINK_REF = TRACED_AT  # GitHub links pin the commit the chain was traced at, as the other seeds do
EXPLORER = "comparison/site/explorer/index.html"


def loc(path, symbol, lines, language=None):
    """One code location: repo-relative path, the function or object, [first, last] line."""
    text = (ROOT / path).read_text(encoding="utf-8").splitlines()
    a, b = lines
    snippet = "\n".join(text[a - 1:b])
    if len(snippet) > 2500:
        snippet = snippet[:2500] + "\n... (cut; open the file for the rest)"
    if language is None:
        language = {"R": "r", "py": "python", "js": "javascript", "html": "html"}.get(
            path.rsplit(".", 1)[-1], "text")
    return {"path": path, "symbol": symbol, "lines": [a, b], "language": language,
            "url": f"{REPO}/blob/{LINK_REF}/{path}#L{a}-L{b}", "snippet": snippet}


def find_lines(path, first, last):
    """[a, b]: the lines of the first line containing `first` and the next containing `last`."""
    text = (ROOT / path).read_text(encoding="utf-8").splitlines()
    a = next(i for i, l in enumerate(text) if first in l)
    b = next(i for i, l in enumerate(text) if i >= a and last in l)
    return [a + 1, b + 1]


def function_span(path, first, header):
    """[a, b]: from the line containing `first` to the closing brace of the R function whose
    definition line contains `header` (the first line after it that is exactly "}")."""
    text = (ROOT / path).read_text(encoding="utf-8").splitlines()
    a = next(i for i, l in enumerate(text) if first in l)
    h = next(i for i, l in enumerate(text) if i >= a and header in l)
    b = next(i for i, l in enumerate(text) if i > h and l == "}")
    return [a + 1, b + 1]


def bridge_snippet(path):
    """comparison-data.js is one long line; show its shape, the headline and the bars of the default view."""
    s = (ROOT / path).read_text(encoding="utf-8")
    j = json.loads(s[s.index("{"):s.rindex("}") + 1])
    B = j["series"]["own"]["b"]["shapley"]
    H = j["headline"]
    lines = [s.splitlines()[0],
             "window.__BRIDGE__ = {",
             '  "headline": {' + ", ".join(f'"{k}": {v}' for k, v in H.items()) + "},",
             f'  "series": {{ {", ".join(j["series"])} }},   // horizon settings',
             '    // each: { "b": {"shapley": [...], "sequential": [...]}, "a": {...} }, one object per bar',
             '  "horizon_notes": { ... }',
             "};",
             "",
             "// series.own.b.shapley, the default view (output (b), Shapley, each analysis's own horizon):"]
    for b in B:
        lines.append(f'//   {b["id"]:<22} {b["type"]:<6} {b["value"]:>12.6f}')
    return "\n".join(lines), B, H


def main():
    data_snip, B, H = bridge_snippet("assets/comparison-data.js")
    bsz_end, nber_end = B[0]["value"], B[-1]["value"]
    assert B[0]["id"] == "bsz" and B[-1]["id"] == "nber"
    rj_main = H["rjkdc"]
    gap = bsz_end - nber_end

    def ends_csv(rel, out="b"):
        with open(ROOT / rel, newline="", encoding="utf-8") as f:
            r = [x for x in csv.DictReader(f) if x["horizon_setting"] == "own" and x["output"] == out][0]
        return {k: float(v) for k, v in r.items() if k not in ("horizon_setting", "output")}
    eb = ends_csv("comparison/export/r/ends.csv")
    assert abs(eb["bsz_model"] - bsz_end) < 1e-9 and abs(eb["nber_own"] - nber_end) < 1e-9
    assert abs(H["bsz"] - bsz_end) < 1e-12
    with open(ROOT / "comparison/export/r/bridge.csv", newline="", encoding="utf-8") as f:
        bb = [x for x in csv.DictReader(f) if x["horizon_setting"] == "own" and x["output"] == "b"]
    steps_sum = sum(float(x["shapley"]) for x in bb)
    big = sorted(bb, key=lambda x: float(x["shapley"]))[:3]
    big_txt = ", ".join(f'{x["step_id"]} {float(x["shapley"]):.3f}' for x in big)
    with open(ROOT / "comparison/export/r/meta.csv", newline="", encoding="utf-8") as f:
        meta = {x["key"]: float(x["value"]) for x in csv.DictReader(f)}

    def m(v, d=1):
        return ("−" if v < 0 else "") + f"${abs(v):.{d}f}B"

    layers = [
        dict(
            n=1, name="The numbers on the explorer",
            what=("This layer is the explorer's own JavaScript, not R or Python; the R and Python "
                  "code starts at layer 3. The page loads the bridge's data file and prints the two "
                  "main estimates from its headline object: headline.bsz, the BSZ net total, and "
                  "headline.rjkdc, the RJKDC NBER mean NPV as the RJKDC pipeline reproduces the "
                  "authors' seeded run. The two-bar chart below them takes the first and last bars "
                  "of the current view (endsOf); in the default view, output (b) at each analysis's "
                  "own horizon, these are the bridge's two ends. The BSZ end is the same number as "
                  "the BSZ main estimate; the RJKDC end is the exact expectation of the same Monte "
                  "Carlo, a little below the seeded run. The two panels below the header each list the "
                  "disputed inputs with a five-position slider; the page reads every slider, builds the "
                  "input vector with model.js (a JavaScript copy of score_common(), layer 6, checked "
                  "against R by test-site.R) and draws the two bars. The static header carries the "
                  "same two numbers, written by site.R (layer 3), so it reads the same with JavaScript off."),
            inputs="D = window.__BRIDGE__ from assets/comparison-data.js (D.headline, D.sliders: the two input vectors and the revision constants); M = model.js",
            inputs_from=[dict(layer="comparison-2", what="window.__BRIDGE__: the headline object and every bar of every view; the default view is series.own.b.shapley")],
            other_inputs="none",
            outputs=(f"headline: '{m(H['bsz'])}' (BSZ main estimate) and '{m(rj_main)}' (RJKDC main estimate); "
                     f"bars: '{m(bsz_end)}' (BSZ analysis) and '{m(nber_end)}' (RJKDC analysis)"),
            method_ref=("Display only. The definitions are the method: BSZ's net total, wealth tax plus "
                        "extra income tax from asset sales minus 5 years of lost income tax; RJKDC's mean "
                        "NPV in perpetuity. The footnote on the explorer says the common output (b) puts "
                        "both on one definition, of which the two bars are the ends."),
            method_status="plumbing",
            r=loc(EXPLORER, "positions(), updatePanel(), drawBars(): read each panel's sliders, call model.js, draw the two bars",
                  find_lines(EXPLORER, "function positions(panel)", "function renderPanels()"), language="javascript"),
            py=None,
            targets=None,
        ),
        dict(
            n=2, name="The bridge's data file",
            what=("A generated JavaScript data file, not R or Python, written by R only (the Python "
                  "twin writes the same numbers as CSV under comparison/export/py/). It holds one "
                  "object, window.__BRIDGE__. headline holds the two main estimates and the two ends "
                  "under (b). series has one entry per horizon setting (own, then a common 5, 10, 20, "
                  "30, 50 years or a perpetuity), each with outputs b and a and two ways of sizing the "
                  "steps (shapley, sequential). Each is a list of bars: the BSZ end, one step per "
                  "disputed input, the model difference, the September 2026 revision and the RJKDC end."),
            inputs="nothing at run time; the file is written by the next layer",
            inputs_from=[dict(layer="comparison-3", what="the text of comparison-data.js, written as raw UTF-8 bytes")],
            other_inputs="",
            outputs=(f"headline.bsz = {H['bsz']:.6f}, headline.rjkdc = {rj_main:.6f}; "
                     f"series.own.b.shapley: bsz = {bsz_end:.6f}, nber = {nber_end:.6f}"),
            method_ref="Plumbing. test-site.R checks the committed file is byte-identical to what render_site() writes, and that headline and the end bars equal ends.csv.",
            method_status="plumbing",
            r=dict(path="assets/comparison-data.js", symbol="window.__BRIDGE__", lines=[1, 2],
                   language="javascript", url=f"{REPO}/blob/{LINK_REF}/assets/comparison-data.js",
                   snippet=data_snip),
            py=None,
            targets=None,
        ),
        dict(
            n=3, name="Writing the pages and the data file",
            what=("build_series() turns the exported tables into the bars of every view, in "
                  "display order: the BSZ end (the 'bsz' bar), the eleven steps, the model "
                  "difference, the September 2026 revision and the RJKDC end (the 'nber' bar). "
                  "render_site() fills the two pages' tokens, including the two main estimates "
                  "(hl_bsz = ends$bsz_model on (b); hl_rjkdc = the RJKDC contract's npv_mc_nber_mean), "
                  "and serializes the headline object and the bars to JSON; write_site() writes "
                  "index.html, the explorer and the data file."),
            inputs="ex: the eight exported tables read back from comparison/export/r/ (ends, bridge, endpoints, ...)",
            inputs_from=[dict(layer="comparison-4", what="ends (one row per horizon setting and output: bsz_model, nber_own, ...), bridge (the step values) and endpoints (contract_value of rauh_nber_npv)")],
            other_inputs="the page templates comparison/site/index.template.html and explorer.template.html (prose and {{tokens}})",
            outputs=(f"the 'bsz' bar = ends$bsz_model = {eb['bsz_model']:.6f}; the 'nber' bar = ends$nber_own = "
                     f"{eb['nber_own']:.6f}; tokens hl_bsz = {m(H['bsz'])}, hl_rjkdc = {m(rj_main)}, gap_b = {m(gap)}"),
            method_ref="Plumbing. The Python twin has no site writer; its export/py/ends.csv carries the same two ends (test-parity.R).",
            method_status="plumbing",
            r=loc("comparison/R/site.R", "build_series()", function_span("comparison/R/site.R", "# The bars of every view", "build_series <- function")),
            py=None,
            targets="comparison/run.R: write_site(root)",
        ),
        dict(
            n=4, name="The bridge's ends and steps",
            what=("build_all() estimates everything the pages show. For each horizon setting it "
                  "estimates the model at the all-BSZ inputs (the BSZ end), runs the two "
                  "decompositions of layer 5 for outputs (b) and (a), and computes the RJKDC "
                  "analysis's own expectations: its March 2026 version, where the disputed-input "
                  "steps end, and the NBER September 2026 one, the RJKDC end. Each ends row records "
                  "the BSZ end, the model at the March 2026 inputs, that version's expectation, the "
                  "model difference (rauh_residual), the NBER end (nber_own) and the September "
                  "revision (nber_step)."),
            inputs="bi: the two input vectors; and the RJKDC Monte Carlo ranges (wt_min/max, f_min/max, c_min/max, r_min/max)",
            inputs_from=[dict(layer="comparison-5", what="the Shapley and one-order step values for each output and setting"),
                         dict(layer="comparison-6", what="score_common() at the all-BSZ inputs (v_sup) and rauh_nber_expectation() (own_n)"),
                         dict(layer="comparison-7", what="bi: sup and rauh, the two input vectors")],
            other_inputs="the horizon settings HORIZONS = 5, 10, 20, 30, 50 years and a perpetuity",
            outputs=(f"ends, own horizon, output (b): bsz_model {eb['bsz_model']:.3f}, rauh_residual "
                     f"{eb['rauh_residual']:.3f}, nber_own {eb['nber_own']:.3f}, nber_step {eb['nber_step']:.3f}; "
                     f"gap = {eb['bsz_model']:.3f} - ({eb['nber_own']:.3f}) = {gap:.3f}"),
            method_ref=("This OPA's reconciliation (PLAN.md, the common output; DISPUTES.md for each "
                        "input). Checks: test-endpoints.R pins each end against the printed number; "
                        "test-shapley.R that the steps sum to the gap; test-site.R that the steps, the "
                        "model difference and the revision add up to the gap on (b)."),
            method_status="opa_definition",
            r=loc("comparison/R/build.R", "build_all(): the ends and the bridge, for every horizon setting", [78, 131]),
            py=loc("comparison/py/bridge.py", "build_all(): the same loop", [269, 305]),
            targets="comparison/run.R: write_exports(build_all(read_contracts(root)), ...)",
        ),
        dict(
            n=5, name="Splitting the gap into steps",
            what=("Each step switches one disputed input from the BSZ value to the RJKDC value of "
                  "its March 2026 version, where the inputs are published. Because inputs interact, "
                  "a step's size depends on when it is switched. shapley_bridge() averages each "
                  "switch over every order, exactly: it estimates the model at all 2^11 = 2,048 "
                  "subsets of switched inputs and weights each difference by how many orders produce "
                  "it. sequential_bridge() switches them in one order, Hoopes's. Both sets of steps "
                  "add up to the model gap between the two input vectors; the model difference and "
                  "the September revision close the rest of the gap to the RJKDC end."),
            inputs="sup, rauh (the two input vectors) and the list of steps",
            inputs_from=[dict(layer="comparison-6", what="score_common(): output (b) or (a) at any mix of the two input vectors"),
                         dict(layer="comparison-7", what="sup and rauh, the two input vectors")],
            other_inputs="step_inputs (which argument each step switches) and sequential_order()",
            outputs=(f"output (b), own horizon: eleven Shapley steps summing to {steps_sum:.3f}; the largest are "
                     f"{big_txt}; plus the model difference {eb['rauh_residual']:.3f} and the September revision "
                     f"{eb['nber_step']:.3f}, together {-gap:.3f}"),
            method_ref=("Shapley value, the standard average-over-orders decomposition. test-shapley.R "
                        "checks the sum in every setting and compares with a brute-force average over orders."),
            method_status="matches",
            r=loc("comparison/R/model.R", "coalition_values(), shapley_bridge(), sequential_bridge()", [190, 226]),
            py=loc("comparison/py/bridge.py", "shapley_bridge(), sequential_bridge()", [200, 227]),
            targets=None,
        ),
        dict(
            n=6, name="The estimating function and the RJKDC end",
            what=("score_common() is the one function that estimates both analyses. The wealth tax "
                  "is 5% x base x (1 - real-estate share) x (1 - avoidance) x S, where S is the share "
                  "of the base still taxed after departures and the mobility response. At the "
                  "all-BSZ inputs S = 1, so the wealth tax is 0.05 x 2,307 x 0.9 = 103.815, BSZ "
                  f"Table 5 row 1; output (b) adds {meta['X_bsz']:.3f} of income tax from asset sales and "
                  f"subtracts {meta['PV_bsz_own']:.3f}, five years of lost income tax, giving {bsz_end:.3f}, "
                  "the BSZ end. rauh_nber_expectation() (model.R lines 134-138, bridge.py lines "
                  "156-160) is the RJKDC end: with the revenue uniform on [0, 72], the departing "
                  "share f on [0.30, 0.60], the income tax C on [3.3, 5.8] and r on [1.5%, 4.5%], all "
                  f"independent, the mean NPV is 36 - 0.45 x 4.55 x {meta['A_inf']:.3f} = {nber_end:.3f}. "
                  "This is the last layer that computes: its two outputs are the two ends."),
            inputs="x: one input vector (sup at the BSZ end); the NBER Monte Carlo bounds",
            inputs_from=[dict(layer="comparison-7", what="sup: tau 0.05, W_core 2157, W_noncit 150, re 0, alpha 0.10, d_conf 0, ...")],
            other_inputs=("the NBER bounds wt_min = 0 (a literal in build.R), wt_max = 72 (contract row "
                          "nber_ceiling_hardcoded), f, C and r ranges (contract rows nber_mc_f_*, rauh_mc_c_*, rauh_mc_r_*)"),
            outputs=f"score_common(sup)['b'] = {bsz_end:.6f}; rauh_nber_expectation(...)['b'] = {nber_end:.6f}; difference {gap:.3f}",
            method_ref=("BSZ PDF p.24 (90% x 5% x $2,307B) and Table 5 row 1, p.39; Jaros and Rauh NBER "
                        "c15504, the Monte Carlo in the authors' public repository (NPV_dist_v8.R). "
                        "test-endpoints.R checks both ends against the printed numbers (the NBER one "
                        "within Monte Carlo error of the printed -38.9)."),
            method_status="matches",
            r=loc("comparison/R/model.R", "score_common()", [32, 42]),
            py=loc("comparison/py/bridge.py", "score_common()", [76, 85]),
            targets=None,
        ),
        dict(
            n=7, name="The two input vectors",
            what=("bridge_inputs() builds the two settings of every disputed input, each value read "
                  "from a contract row or a transcribed document input. The BSZ base is the "
                  "contract's 2,307 split into 150 of non-US-citizen residents and the rest; the "
                  "RJKDC values are those of its March 2026 version, from the RJKDC contract's "
                  "workbook sums and Monte Carlo ranges."),
            inputs="k: the two contracts and the document inputs",
            inputs_from=[dict(layer="comparison-8", what="k$bsz, k$rjkdc (inputs and outputs tables) and k$docs, looked up row by row with pick()")],
            other_inputs="none",
            outputs="sup: W_core 2157, W_noncit 150, alpha 0.10, re 0, d_conf 0, dtau 0, H 5, ...; rauh: W_core 1894.8, W_noncit 0, alpha 0, dtau 0.05, H Inf, ...",
            method_ref="Each value's source and page is in comparison/export/r/inputs.csv (bridge_input_table()).",
            method_status="matches",
            r=loc("comparison/R/build.R", "bridge_inputs()", [6, 35]),
            py=loc("comparison/py/bridge.py", "bridge_inputs()", [241, 265]),
            targets=None,
        ),
        dict(
            n=8, name="The raw source: the two export contracts",
            what=("The comparison reads exactly three kinds of file: each analysis's export contract "
                  "(export/r/inputs.csv and outputs.csv, written by that analysis's own pipeline for "
                  "others to read), the values transcribed from the PDFs with their page "
                  "(comparison/data/document-inputs.csv) and Hoopes's digitized figure. pick() "
                  "looks up one row and fails loudly if it is missing or duplicated. The chain stops "
                  "here: what is behind each contract row is each analysis's own chain."),
            inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            inputs_from=[],
            other_inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            outputs=("for the two ends: BSZ baseline_net_worth 2307, avoidance_rate 0.1, tax_rate 0.05, "
                     "tab5_row1 extra income tax and annual loss; RJKDC nber_ceiling_hardcoded 72, "
                     "nber_mc_f_min/max 0.30/0.60, rauh_mc_c_min/max 3.3/5.8, rauh_mc_r_min/max 0.015/0.045, "
                     "npv_mc_nber_mean -38.886 (the RJKDC main estimate); document input "
                     "ggss_noncitizen_wealth 150"),
            method_ref="Plumbing: base R read.csv / Python csv, no transformation.",
            method_status="plumbing",
            r=loc("comparison/R/contract.R", "read_contracts(), pick()", [29, 47]),
            py=loc("comparison/py/bridge.py", "pick(), read_contracts()", [49, 63]),
            targets=None,
        ),
    ]

    HANDOFF_TOKENS = {
        (1, "comparison-2"): dict(tokens=["D", "__BRIDGE__", "headline", "series"], source_tokens=["__BRIDGE__", "headline", "series"]),
        (2, "comparison-3"): dict(tokens=["__BRIDGE__"], source_tokens=["build_series", "headline", "add"]),
        (3, "comparison-4"): dict(tokens=["ex", "en", "e", "bsz_model", "nber_own"], source_tokens=["ends", "bsz_model", "nber_own"]),
        (4, "comparison-5"): dict(tokens=["shapley_bridge", "sequential_bridge", "sh", "sq"], source_tokens=["shapley_bridge", "sequential_bridge", "phi", "out"]),
        (4, "comparison-6"): dict(tokens=["score_common", "v_sup", "nber_own", "own_n"], source_tokens=["score_common", "rauh_nber_expectation", "WT", "e_wt"]),
        (4, "comparison-7"): dict(tokens=["sup", "rauh", "bi"], source_tokens=["bridge_inputs", "sup", "rauh"]),
        (5, "comparison-6"): dict(tokens=["score_common"], source_tokens=["score_common", "WT"]),
        (5, "comparison-7"): dict(tokens=["sup", "rauh"], source_tokens=["sup", "rauh"]),
        (6, "comparison-7"): dict(tokens=["x"], source_tokens=["sup"]),
        (7, "comparison-8"): dict(tokens=["k", "pick"], source_tokens=["read_contracts", "pick"]),
    }
    for L in layers:
        for x in L["inputs_from"]:
            x.update(HANDOFF_TOKENS.get((L["n"], x["layer"]), dict(tokens=[], source_tokens=[])))

    # A few lines to check each layer by hand, after the chain's environment code has run
    # (ENVIRONMENT below). Every snippet was run end to end from the repo root.
    INTERACTIVE = {
        1: dict(js="""// In the browser: open the explorer (comparison/site/explorer/), then paste this in the developer console.
D = window.__BRIDGE__
D.headline.bsz, D.headline.rjkdc       // 106.796, -38.886: the two main estimates
B = D.series.own.b.shapley
B[0].value, B[B.length - 1].value     // 106.796, -38.980: the two ends under (b)
B[0].value - B[B.length - 1].value    // 145.776, the gap the bridge explains
B.map(b => b.id)                      // the bars, in display order"""),
        2: dict(r="""# Layer 2: read the committed data file back: the headline and the two end bars.
txt <- readLines("assets/comparison-data.js")[2]
D <- jsonlite::fromJSON(sub(";$", "", sub("^window.__BRIDGE__ = ", "", txt)), simplifyVector = FALSE)
names(D$series)                                   # own, common_5, ..., common_Inf
str(D$headline)                                   # bsz 106.796, rjkdc -38.886, ...
B <- D$series$own$b$shapley
vals <- setNames(vapply(B, function(b) b$value, 0), vapply(B, function(b) b$id, ""))
vals
vals[["bsz"]] - vals[["nber"]]                    # 145.776""",
                py="""# Layer 2: read the committed data file back: the headline and the two end bars.
import json
s = open("assets/comparison-data.js").read()
D = json.loads(s[s.index("{"):s.rindex("}") + 1])
list(D["series"])                                 # own, common_5, ..., common_Inf
D["headline"]                                     # bsz 106.796, rjkdc -38.886, ...
vals = {b["id"]: b["value"] for b in D["series"]["own"]["b"]["shapley"]}
vals
vals["bsz"] - vals["nber"]                        # 145.776"""),
        3: dict(r="""# Layer 3: the bars from the exported tables, and the pages' own output.
ex <- read_exports("comparison/export/r")
B <- build_series(ex, "Model difference")$own$b$shapley
vapply(B, function(b) b$value, 0)
s <- render_site()
identical(s$js, paste0(paste(readLines("assets/comparison-data.js"), collapse = "\\n"), "\\n"))   # TRUE
regmatches(s$explorer, gregexpr('id="hl-(bsz|rjkdc)">[^<]+', s$explorer))[[1]]""",
                py="""# Layer 3: no Python twin writes the pages; the twin's ends.csv carries the same two ends.
import csv
ends = [r for r in csv.DictReader(open("comparison/export/py/ends.csv"))
        if r["horizon_setting"] == "own" and r["output"] == "b"][0]
float(ends["bsz_model"]), float(ends["nber_own"])      # 106.796, -38.980
float(ends["bsz_model"]) - float(ends["nber_own"])     # 145.776"""),
        4: dict(r="""# Layer 4: everything the pages show, rebuilt from the contracts.
res <- build_all(k)
eb <- res$ends[res$ends$horizon_setting == "own" & res$ends$output == "b", ]
eb
eb$bsz_model - eb$nber_own                                             # 145.776
b <- res$bridge[res$bridge$horizon_setting == "own" & res$bridge$output == "b", ]
sum(b$shapley) + eb$rauh_residual + eb$nber_step                       # -145.776""",
                py="""# Layer 4: everything the pages show, rebuilt from the contracts.
res = b.build_all(k)
eb = [e for e in res["ends"] if e["horizon_setting"] == "own" and e["output"] == "b"][0]
eb
eb["bsz_model"] - eb["nber_own"]                                       # 145.776
steps = [r for r in res["bridge"] if r["horizon_setting"] == "own" and r["output"] == "b"]
sum(r["shapley"] for r in steps) + eb["rauh_residual"] + eb["nber_step"]   # -145.776"""),
        5: dict(r="""# Layer 5: the eleven steps of output (b), two ways.
players <- bridge_steps()$step_id
sh <- shapley_bridge(bi$sup, bi$rauh, players, "b")
round(sh, 3)
sum(sh)                                                                # -131.602
score_common(bi$rauh)[["b"]] - score_common(bi$sup)[["b"]]            # the same
round(sequential_bridge(bi$sup, bi$rauh, sequential_order(), "b"), 3)  # Hoopes's order""",
                py="""# Layer 5: the eleven steps of output (b), two ways.
sh = b.shapley_bridge(sup, rauh, b.IDS, "b")
{k_: round(v, 3) for k_, v in sh.items()}
sum(sh.values())                                                       # -131.602
b.score_common(rauh)["b"] - b.score_common(sup)["b"]                   # the same
{k_: round(v, 3) for k_, v in b.sequential_bridge(sup, rauh, b.SEQUENTIAL, "b").items()}"""),
        6: dict(r="""# Layer 6: the two ends under (b), and the gap between them.
v <- score_common(bi$sup); v[c("a", "X", "PV", "b")]                   # 103.815, 3.682, 0.701, 106.796
oi <- k$rjkdc$inputs
nber <- rauh_nber_expectation(wt_min = 0, wt_max = pick(oi, "nber_ceiling_hardcoded"),
  f_min = pick(oi, "nber_mc_f_min"), f_max = pick(oi, "nber_mc_f_max"),
  c_min = pick(oi, "rauh_mc_c_min"), c_max = pick(oi, "rauh_mc_c_max"),
  r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = 36, b = -38.980
36 - 0.45 * 4.55 * expected_annuity(Inf, 0.015, 0.045)                # the same by hand
v[["b"]] - nber[["b"]]                                                 # 145.776""",
                py="""# Layer 6: the two ends under (b), and the gap between them.
v = b.score_common(sup); v["a"], v["X"], v["PV"], v["b"]              # 103.815, 3.682, 0.701, 106.796
oi = k["rjkdc"]["inputs"]
nber = b.rauh_nber_expectation(0.0, b.pick(oi, "nber_ceiling_hardcoded"),
    b.pick(oi, "nber_mc_f_min"), b.pick(oi, "nber_mc_f_max"),
    b.pick(oi, "rauh_mc_c_min"), b.pick(oi, "rauh_mc_c_max"),
    b.pick(oi, "rauh_mc_r_min"), b.pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = 36, b = -38.980
v["b"] - nber["b"]                                                     # 145.776"""),
        7: dict(r="""# Layer 7: the two input vectors, next to each other.
str(bi$sup)
str(bi$rauh)
bridge_input_table(bi)[, c("step_id", "input", "supporting_value", "rauh_value")]""",
                py="""# Layer 7: the two input vectors, next to each other.
sup
rauh
{s: (sup[i[0]], rauh[i[0]]) for s, i in b.STEP_INPUTS.items()}"""),
        8: dict(r="""# Layer 8: the contracts and the rows the two ends read.
names(k)                                         # bsz, rjkdc, docs, hoopes
head(k$bsz$inputs[, c("input_id", "value", "label", "source")])
pick(k$bsz$inputs, "baseline_net_worth"); pick(k$bsz$inputs, "avoidance_rate"); pick(k$bsz$inputs, "tax_rate")
pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"); pick(k$rjkdc$inputs, "nber_mc_f_min"); pick(k$rjkdc$inputs, "nber_mc_f_max")
pick(k$rjkdc$outputs, "npv_mc_nber_mean")       # -38.886, the RJKDC main estimate
pick(k$docs, "ggss_noncitizen_wealth")""",
                py="""# Layer 8: the contracts and the rows the two ends read.
list(k)                                          # bsz, rjkdc, docs, hoopes
k["bsz"]["inputs"][:3]
b.pick(k["bsz"]["inputs"], "baseline_net_worth"), b.pick(k["bsz"]["inputs"], "avoidance_rate"), b.pick(k["bsz"]["inputs"], "tax_rate")
b.pick(k["rjkdc"]["inputs"], "nber_ceiling_hardcoded"), b.pick(k["rjkdc"]["inputs"], "nber_mc_f_min"), b.pick(k["rjkdc"]["inputs"], "nber_mc_f_max")
b.pick(k["rjkdc"]["outputs"], "npv_mc_nber_mean")   # -38.886, the RJKDC main estimate
b.pick(k["docs"], "ggss_noncitizen_wealth")"""),
    }
    for L in layers:
        L["interactive"] = INTERACTIVE[L["n"]]

    ENVIRONMENT = dict(
        r=r"""# Environment for the comparison chain, R. In Positron open the opa-prop40 folder, then run this once.
# Needs nothing downloaded: the two analyses' export contracts are committed.
while (!dir.exists("comparison")) setwd("..")
invisible(lapply(list.files("comparison/R", pattern = "\\.R$", full.names = TRUE), source))   # every function on the chain
k  <- read_contracts()          # layer 8: the two contracts and the document inputs
bi <- bridge_inputs(k)          # layer 7: the two input vectors
cat("ready: BSZ base", bi$sup$W_core + bi$sup$W_noncit, "; RJKDC base", bi$rauh$W_core, "\n")""",
        py="""# Environment for the comparison chain, Python. In Positron open the opa-prop40 folder, then run this once.
# Needs scipy (pip install scipy); nothing downloaded.
import os, sys
from pathlib import Path
os.chdir(next(p for p in [Path.cwd(), *Path.cwd().parents] if (p / "comparison").is_dir()))   # the repo root
sys.path.insert(0, "comparison/py")
import bridge as b                       # the Python twin: every function on the chain
k = b.read_contracts(os.getcwd())        # layer 8: the two contracts and the document inputs
sup, rauh = b.bridge_inputs(k)           # layer 7: the two input vectors
print("ready: BSZ base", sup["W_core"] + sup["W_noncit"], "; RJKDC base", rauh["W_core"])""",
    )

    old = {}
    if OUT.exists():
        for L in json.loads(OUT.read_text()).get("layers", []):
            old[L["id"]] = L
    today = date.today().isoformat()
    for L in layers:
        L["id"] = f"comparison-{L['n']}"
        prev = old.get(L["id"], {})
        L["state"] = prev.get("state", "not_reviewed")
        L["understanding"] = prev.get("understanding", "")
        L["missing"] = prev.get("missing", "")
        L["feedback"] = prev.get("feedback", [])
        L["updated"] = prev.get("updated", today)

    chain = {
        "opa": "comparison",
        "title": "The comparison: the two main estimates",
        "headline": {
            "label": "BSZ main estimate and RJKDC main estimate, on the common output (b)",
            "value": f"{m(H['bsz'])} and {m(rj_main)}",
            "computed": {"bsz": H["bsz"], "rjkdc": rj_main, "bsz_end_b": bsz_end, "rjkdc_end_b": nber_end},
            "definition": ("the two analyses' own main estimates, next to each other: BSZ's net total "
                           "(wealth tax + extra income tax from selling assets - income tax lost to "
                           "leavers, present value of 5 years) and RJKDC's NBER September 2026 mean NPV "
                           "(perpetuity). Under the common output (b), the net fiscal effect, they are "
                           f"the bridge's two ends, {m(bsz_end)} and {m(nber_end)} (the exact expectation "
                           f"of the Monte Carlo whose seeded run is {m(rj_main, 3)}); the gap between the "
                           f"ends, {m(gap)}, is stated in the bridge"),
            "where": "https://fhoces.github.io/opa-prop40/comparison/site/explorer/",
        },
        "commit": LINK_REF,
        "seeded": today,
        "verified_by": (f"Rscript, layer 6 at {TRACED_AT}: score_common(bridge_inputs(read_contracts())$sup)[['b']] "
                        f"= {bsz_end:.3f} and rauh_nber_expectation(0, 72, 0.30, 0.60, 3.3, 5.8, 0.015, 0.045)[['b']] "
                        f"= {nber_end:.3f}; the same from export/r/ends.csv (bsz_model, nber_own on (b)), from "
                        "export/py/ends.csv, and from the headline and the end bars in assets/comparison-data.js. "
                        f"The RJKDC main estimate as shown, {m(rj_main, 3)}, is the RJKDC contract row "
                        "npv_mc_nber_mean (the authors' seeded run), traced by the RJKDC chain"),
        "runs_for_a_stranger": ("AUDIT.md step 8, level 2: .github/workflows/comparison-ci.yml rebuilds "
                                "the comparison in R and Python on a clean runner; no one-click (Binder) yet."),
        "environment": ENVIRONMENT,
        "layers": layers,
    }
    OUT.write_text(json.dumps(chain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(layers)} layers traced at {TRACED_AT}, links to {LINK_REF}, "
          f"ends on (b) {bsz_end} and {nber_end}, main estimates {H['bsz']} and {rj_main}")


if __name__ == "__main__":
    sys.exit(main())
