#!/usr/bin/env python3
"""Seed review/comparison.json: the chain of code behind the comparison's main estimate.

The main estimate is the gap on output (a), gross one-time wealth tax revenue, between the
bridge's two ends: BSZ Table 5 row 1 and the expected revenue in the NBER Monte Carlo of
Jaros and Rauh. The layers are written by hand below, top (the number on the root page) to
bottom (the two sides' export contracts). Snippets are cut from the files at the line ranges
given, so re-running this script after a code edit refreshes them. The user's fields (state,
understanding, missing, feedback) are kept from an existing comparison.json when present.

GitHub links pin the commit the chain was traced at (HEAD when the script runs), as the
other seeds do. Reseed after any commit that touches a file on the chain.

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


def bridge_snippet(path):
    """comparison-data.js is one long line; show its shape and the bars the headline reads."""
    s = (ROOT / path).read_text(encoding="utf-8")
    j = json.loads(s[s.index("{"):s.rindex("}") + 1])
    B = j["series"]["own"]["a"]["shapley"]
    ends = {b["id"]: b["value"] for b in B if b["type"] == "total"}
    lines = [s.splitlines()[0],
             "window.__BRIDGE__ = {",
             f'  "series": {{ {", ".join(j["series"])} }},   // horizon settings',
             '    // each: { "a": {"shapley": [...], "sequential": [...]}, "b": {...} }, one object per bar',
             '  "horizon_notes": { ... }',
             "};",
             "",
             "// series.own.a.shapley, the default view (output (a), Shapley, each side's own horizon):"]
    for b in B:
        lines.append(f'//   {b["id"]:<22} {b["type"]:<6} {b["value"]:>12.6f}')
    return "\n".join(lines), ends


def main():
    data_snip, ends = bridge_snippet("assets/comparison-data.js")
    bsz_end, nber_end = ends["bsz"], ends["nber"]
    gap = bsz_end - nber_end

    def ends_csv(rel):
        with open(ROOT / rel, newline="", encoding="utf-8") as f:
            r = [x for x in csv.DictReader(f) if x["horizon_setting"] == "own" and x["output"] == "a"][0]
        return {k: float(v) for k, v in r.items() if k not in ("horizon_setting", "output")}
    ea = ends_csv("comparison/export/r/ends.csv")
    assert abs(ea["bsz_model"] - bsz_end) < 1e-9 and abs(ea["nber_own"] - nber_end) < 1e-9

    layers = [
        dict(
            n=1, name="The number on the page",
            what=("This layer is the root page's own JavaScript, not R or Python; the R and Python "
                  "code starts at layer 3. The page loads the bridge's data file, takes the default "
                  "view (output (a), Shapley steps, each side's own horizon), finds its two end bars, "
                  "'bsz' (BSZ Table 5 row 1) and 'nber' (the NBER expected revenue), and prints their "
                  "difference as the main estimate, with the two ends in footnote 1. The static page "
                  "already carries the same three numbers, written by site.R (layer 3), so it reads "
                  "the same with JavaScript off."),
            inputs="D = window.__BRIDGE__ from assets/comparison-data.js; B = D.series.own.a.shapley",
            inputs_from=[dict(layer="comparison-2", what="window.__BRIDGE__: every bar of every view; the default view is series.own.a.shapley")],
            other_inputs="none",
            outputs=f"the text '${gap:.1f}B' (main estimate), '${bsz_end:.1f}B' and '${nber_end:.1f}B' (the two ends)",
            method_ref=("Display only. The definition under the number is the method: the gap on the "
                        "common output (a) between the bridge's two ends. Footnote 1 says neither side "
                        "reports it; it is this OPA's reconciliation."),
            method_status="plumbing",
            r=loc("index.html", "the headline script: read the two end bars, print the gap", [306, 320], language="javascript"),
            py=None,
            targets=None,
        ),
        dict(
            n=2, name="The bridge's data file",
            what=("A generated JavaScript data file, not R or Python, written by R only (the Python "
                  "twin writes the same numbers as CSV under comparison/export/py/). It holds one "
                  "object, window.__BRIDGE__. series has one entry per horizon setting (own, then a "
                  "common 5, 10, 20, 30, 50 years or a perpetuity), each with outputs a and b and two "
                  "ways of sizing the steps (shapley, sequential). Each is a list of bars: totals "
                  "(an estimate), steps (one disputed input) and model differences. The page does no "
                  "arithmetic beyond one subtraction."),
            inputs="nothing at run time; the file is written by the next layer",
            inputs_from=[dict(layer="comparison-3", what="the text of comparison-data.js, written as raw UTF-8 bytes")],
            other_inputs="",
            outputs=f"series.own.a.shapley: bsz = {bsz_end:.6f}, nber = {nber_end:.6f}",
            method_ref="Plumbing. test-site.R checks the committed file is byte-identical to what render_site() writes.",
            method_status="plumbing",
            r=dict(path="assets/comparison-data.js", symbol="window.__BRIDGE__", lines=[1, 2],
                   language="javascript", url=f"{REPO}/blob/{LINK_REF}/assets/comparison-data.js",
                   snippet=data_snip),
            py=None,
            targets=None,
        ),
        dict(
            n=3, name="Writing the page and the data file",
            what=("build_series() turns the exported tables into the bars of every view, in "
                  "display order: for output (a), the GGSS printed number, GGSS's rounding, BSZ row 1 "
                  "(the 'bsz' bar), the eleven steps, the model difference, Rauh SSRN, the NBER "
                  "revision and Rauh NBER (the 'nber' bar). render_site() fills the page's tokens, "
                  "including the main estimate (lines 133-138 of site.R: gap = bsz_model - nber_own), "
                  "and serializes the bars to JSON; write_site() writes both files."),
            inputs="ex: the eight exported tables read back from comparison/export/r/ (ends, bridge, endpoints, ...)",
            inputs_from=[dict(layer="comparison-4", what="ends (one row per horizon setting and output: bsz_model, rauh_own, nber_own, ...) and bridge (the step values)")],
            other_inputs="the page template comparison/site/index.template.html (prose and {{tokens}})",
            outputs=f"the 'bsz' bar = ends$bsz_model = {ea['bsz_model']:.6f}; the 'nber' bar = ends$nber_own = {ea['nber_own']:.6f}; token gap_main = ${gap:.1f}B",
            method_ref="Plumbing. The Python twin has no site writer; its export/py/ends.csv carries the same two numbers (test-parity.R).",
            method_status="plumbing",
            r=loc("comparison/R/site.R", "build_series()", [47, 95]),
            py=None,
            targets="comparison/run.R: write_site(root)",
        ),
        dict(
            n=4, name="The bridge's ends and steps",
            what=("build_all() estimates everything the page shows. For each horizon setting it "
                  "estimates the model at the all-BSZ inputs (the BSZ end), runs the two "
                  "decompositions of layer 5 for outputs (a) and (b), and computes the RJKDC report's "
                  "own expectations: the SSRN Monte Carlo and the NBER one. Each ends row records the "
                  "BSZ end, the model at all-RJKDC inputs, the two expectations, the model difference "
                  "(rauh_residual) and the NBER revision (nber_step)."),
            inputs="bi: the two input vectors; and the RJKDC Monte Carlo ranges (wt_min/max, f_min/max, c_min/max, r_min/max)",
            inputs_from=[dict(layer="comparison-5", what="the Shapley and one-order step values for each output and setting"),
                         dict(layer="comparison-6", what="score_common() at the all-BSZ inputs (v_sup) and rauh_nber_expectation() (own_n)"),
                         dict(layer="comparison-7", what="bi: sup and rauh, the two input vectors")],
            other_inputs="the horizon settings HORIZONS = 5, 10, 20, 30, 50 years and a perpetuity",
            outputs=(f"ends, own horizon, output (a): bsz_model {ea['bsz_model']:.3f}, rauh_own {ea['rauh_own']:.3f}, "
                     f"rauh_residual {ea['rauh_residual']:.6f}, nber_own {ea['nber_own']:.3f}, nber_step {ea['nber_step']:.3f}; "
                     f"gap = {ea['bsz_model']:.3f} - {ea['nber_own']:.3f} = {ea['bsz_model'] - ea['nber_own']:.3f}"),
            method_ref=("This OPA's reconciliation (PLAN.md, the common output; DISPUTES.md for each "
                        "input). Checks: test-endpoints.R pins each end against the printed number; "
                        "test-shapley.R that the steps sum to the gap."),
            method_status="opa_definition",
            r=loc("comparison/R/build.R", "build_all(): the ends and the bridge, for every horizon setting", [78, 131]),
            py=loc("comparison/py/bridge.py", "build_all(): the same loop", [191, 227]),
            targets="comparison/run.R: write_exports(build_all(read_contracts(root)), ...)",
        ),
        dict(
            n=5, name="Splitting the gap into steps",
            what=("Each step switches one disputed input from the BSZ value to the RJKDC value. "
                  "Because inputs interact, a step's size depends on when it is switched. "
                  "shapley_bridge() averages each switch over every order, exactly: it estimates "
                  "the model at all 2^11 = 2,048 subsets of switched inputs and weights each "
                  "difference by how many orders produce it. sequential_bridge() switches them in "
                  "one order, Hoopes's. Both sets of steps add up to the model gap, BSZ end to "
                  "all-RJKDC end."),
            inputs="sup, rauh (the two input vectors) and the list of steps",
            inputs_from=[dict(layer="comparison-6", what="score_common(): output (a) or (b) at any mix of the two input vectors"),
                         dict(layer="comparison-7", what="sup and rauh, the two input vectors")],
            other_inputs="step_inputs (which argument each step switches) and sequential_order()",
            outputs="output (a), own horizon: eleven Shapley steps summing to -52.560 (103.815 to 51.255); the largest is billionaires already departed, -21.293",
            method_ref=("Shapley value, the standard average-over-orders decomposition. test-shapley.R "
                        "checks the sum in every setting and compares with a brute-force average over orders."),
            method_status="matches",
            r=loc("comparison/R/model.R", "switch_inputs(), shapley_bridge(), sequential_bridge()", [87, 122]),
            py=loc("comparison/py/bridge.py", "switch_inputs(), shapley_bridge(), sequential_bridge()", [112, 147]),
            targets=None,
        ),
        dict(
            n=6, name="The estimating function and the NBER end",
            what=("score_common() is the one function that estimates both sides. Output (a) is "
                  "5% x base x (1 - real-estate share) x (1 - avoidance) x S, where S is the share "
                  "of the base still taxed after departures and the mobility response. At the "
                  "all-BSZ inputs S = 1, so (a) = 0.05 x 2,307 x 0.9 = 103.815, BSZ Table 5 row 1. "
                  "rauh_nber_expectation() (model.R lines 134-138, bridge.py lines 156-160) is the NBER "
                  "end: the revenue is drawn uniformly between "
                  "0 and 72, so its expectation is 36. This is the last layer that computes: the "
                  "difference of its two outputs is the main estimate."),
            inputs="x: one input vector (sup at the BSZ end); the NBER Monte Carlo bounds",
            inputs_from=[dict(layer="comparison-7", what="sup: tau 0.05, W_core 2157, W_noncit 150, re 0, alpha 0.10, d_conf 0, ...")],
            other_inputs="the NBER bounds wt_min = 0 (a literal in build.R) and wt_max = 72 (contract row nber_ceiling_hardcoded)",
            outputs=f"score_common(sup)['a'] = {bsz_end:.3f}; rauh_nber_expectation(...)['a'] = {nber_end:.1f}; difference {gap:.3f}",
            method_ref=("BSZ PDF p.24 (90% x 5% x $2,307B) and Table 5 row 1, p.39; Jaros and Rauh NBER "
                        "c15504, the Monte Carlo in the authors' public repository (NPV_dist_v8.R). "
                        "test-endpoints.R checks both ends against the printed numbers."),
            method_status="matches",
            r=loc("comparison/R/model.R", "score_common()", [32, 42]),
            py=loc("comparison/py/bridge.py", "score_common()", [76, 85]),
            targets=None,
        ),
        dict(
            n=7, name="The two input vectors",
            what=("bridge_inputs() builds the two settings of every disputed input, each value read "
                  "from a contract row or a transcribed document input. The BSZ base is the "
                  "contract's 2,307 split into 150 of non-US-citizen residents (GGSS p.2 fn.1) and "
                  "the rest; the RJKDC values come from the RJKDC contract's workbook sums and Monte "
                  "Carlo ranges."),
            inputs="k: the two contracts and the document inputs",
            inputs_from=[dict(layer="comparison-8", what="k$bsz, k$rjkdc (inputs and outputs tables) and k$docs, looked up row by row with pick()")],
            other_inputs="none",
            outputs="sup: W_core 2157, W_noncit 150, alpha 0.10, re 0, d_conf 0, dtau 0, ...; rauh: W_core 1894.8, W_noncit 0, alpha 0, dtau 0.05, ...",
            method_ref="Each value's source and page is in comparison/export/r/inputs.csv (bridge_input_table()).",
            method_status="matches",
            r=loc("comparison/R/build.R", "bridge_inputs()", [6, 35]),
            py=loc("comparison/py/bridge.py", "bridge_inputs()", [163, 187]),
            targets=None,
        ),
        dict(
            n=8, name="The raw source: the two export contracts",
            what=("The comparison reads exactly three kinds of file: each side's export contract "
                  "(export/r/inputs.csv and outputs.csv, written by that side's own pipeline for "
                  "others to read), the values transcribed from the PDFs with their page "
                  "(comparison/data/document-inputs.csv) and Hoopes's digitized figure. pick() "
                  "looks up one row and fails loudly if it is missing or duplicated. The chain stops "
                  "here: what is behind each contract row is each side's own chain."),
            inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            inputs_from=[],
            other_inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            outputs=("for the main estimate: BSZ baseline_net_worth 2307, avoidance_rate 0.1, tax_rate "
                     "0.05; RJKDC nber_ceiling_hardcoded 72; document input ggss_noncitizen_wealth 150"),
            method_ref="Plumbing: base R read.csv / Python csv, no transformation.",
            method_status="plumbing",
            r=loc("comparison/R/contract.R", "read_contracts(), pick()", [29, 47]),
            py=loc("comparison/py/bridge.py", "pick(), read_contracts()", [49, 63]),
            targets=None,
        ),
    ]

    HANDOFF_TOKENS = {
        (1, "comparison-2"): dict(tokens=["D", "__BRIDGE__", "series"], source_tokens=["__BRIDGE__", "series"]),
        (2, "comparison-3"): dict(tokens=["__BRIDGE__"], source_tokens=["build_series", "out", "add"]),
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
        1: dict(js="""// In the browser: open the root page (index.html), then paste this in the developer console.
B = window.__BRIDGE__.series.own.a.shapley
end = id => B.find(b => b.id === id).value
end("bsz"), end("nber")            // 103.815, 36
end("bsz") - end("nber")           // 67.815, printed as $67.8B
B.map(b => b.id)                   // the bars, in display order"""),
        2: dict(r="""# Layer 2: read the committed data file back and find the two end bars.
txt <- readLines("assets/comparison-data.js")[2]
D <- jsonlite::fromJSON(sub(";$", "", sub("^window.__BRIDGE__ = ", "", txt)), simplifyVector = FALSE)
names(D$series)                                   # own, common_5, ..., common_Inf
B <- D$series$own$a$shapley
vals <- setNames(vapply(B, function(b) b$value, 0), vapply(B, function(b) b$id, ""))
vals
vals[["bsz"]] - vals[["nber"]]                    # 67.815""",
                py="""# Layer 2: read the committed data file back and find the two end bars.
import json
s = open("assets/comparison-data.js").read()
D = json.loads(s[s.index("{"):s.rindex("}") + 1])
list(D["series"])                                 # own, common_5, ..., common_Inf
vals = {b["id"]: b["value"] for b in D["series"]["own"]["a"]["shapley"]}
vals
vals["bsz"] - vals["nber"]                        # 67.815"""),
        3: dict(r="""# Layer 3: the bars from the exported tables, and the page's own output.
ex <- read_exports("comparison/export/r")
B <- build_series(ex, "Model difference")$own$a$shapley
vapply(B, function(b) b$value, 0)
s <- render_site()
identical(s$js, paste0(paste(readLines("assets/comparison-data.js"), collapse = "\\n"), "\\n"))   # TRUE
regmatches(s$html, regexpr('id="hl-main">[^<]+', s$html))""",
                py="""# Layer 3: no Python twin writes the page; the twin's ends.csv carries the same two numbers.
import csv
ends = [r for r in csv.DictReader(open("comparison/export/py/ends.csv"))
        if r["horizon_setting"] == "own" and r["output"] == "a"][0]
float(ends["bsz_model"]), float(ends["nber_own"])
float(ends["bsz_model"]) - float(ends["nber_own"])   # 67.815"""),
        4: dict(r="""# Layer 4: everything the page shows, rebuilt from the contracts.
res <- build_all(k)
ea <- res$ends[res$ends$horizon_setting == "own" & res$ends$output == "a", ]
ea
ea$bsz_model - ea$nber_own                                             # 67.815
b <- res$bridge[res$bridge$horizon_setting == "own" & res$bridge$output == "a", ]
sum(b$shapley) + ea$rauh_residual + ea$nber_step                       # -67.815""",
                py="""# Layer 4: everything the page shows, rebuilt from the contracts.
res = b.build_all(k)
ea = [e for e in res["ends"] if e["horizon_setting"] == "own" and e["output"] == "a"][0]
ea
ea["bsz_model"] - ea["nber_own"]                                       # 67.815
steps = [r for r in res["bridge"] if r["horizon_setting"] == "own" and r["output"] == "a"]
sum(r["shapley"] for r in steps) + ea["rauh_residual"] + ea["nber_step"]   # -67.815"""),
        5: dict(r="""# Layer 5: the eleven steps of output (a), two ways.
players <- bridge_steps()$step_id
sh <- shapley_bridge(bi$sup, bi$rauh, players, "a")
round(sh, 3)
sum(sh)                                                                # -52.560
score_common(bi$rauh)[["a"]] - score_common(bi$sup)[["a"]]            # the same
round(sequential_bridge(bi$sup, bi$rauh, sequential_order(), "a"), 3)  # Hoopes's order""",
                py="""# Layer 5: the eleven steps of output (a), two ways.
sh = b.shapley_bridge(sup, rauh, b.IDS, "a")
{k_: round(v, 3) for k_, v in sh.items()}
sum(sh.values())                                                       # -52.560
b.score_common(rauh)["a"] - b.score_common(sup)["a"]                   # the same
{k_: round(v, 3) for k_, v in b.sequential_bridge(sup, rauh, b.SEQUENTIAL, "a").items()}"""),
        6: dict(r="""# Layer 6: the two ends, and the main estimate as their difference.
v <- score_common(bi$sup); v[c("a", "R0", "S")]                        # 103.815
0.05 * 2307 * (1 - 0.10)                                               # the same by hand
oi <- k$rjkdc$inputs
nber <- rauh_nber_expectation(wt_min = 0, wt_max = pick(oi, "nber_ceiling_hardcoded"),
  f_min = pick(oi, "nber_mc_f_min"), f_max = pick(oi, "nber_mc_f_max"),
  c_min = pick(oi, "rauh_mc_c_min"), c_max = pick(oi, "rauh_mc_c_max"),
  r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = 36
v[["a"]] - nber[["a"]]                                                 # 67.815: the main estimate""",
                py="""# Layer 6: the two ends, and the main estimate as their difference.
v = b.score_common(sup); v["a"], v["R0"], v["S"]                       # 103.815
0.05 * 2307 * (1 - 0.10)                                               # the same by hand
oi = k["rjkdc"]["inputs"]
nber = b.rauh_nber_expectation(0.0, b.pick(oi, "nber_ceiling_hardcoded"),
    b.pick(oi, "nber_mc_f_min"), b.pick(oi, "nber_mc_f_max"),
    b.pick(oi, "rauh_mc_c_min"), b.pick(oi, "rauh_mc_c_max"),
    b.pick(oi, "rauh_mc_r_min"), b.pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = 36
v["a"] - nber["a"]                                                     # 67.815: the main estimate"""),
        7: dict(r="""# Layer 7: the two input vectors, side by side.
str(bi$sup)
str(bi$rauh)
bridge_input_table(bi)[, c("step_id", "input", "supporting_value", "rauh_value")]""",
                py="""# Layer 7: the two input vectors, side by side.
sup
rauh
{s: (sup[i[0]], rauh[i[0]]) for s, i in b.STEP_INPUTS.items()}"""),
        8: dict(r="""# Layer 8: the contracts and the rows the main estimate reads.
names(k)                                         # bsz, rjkdc, docs, hoopes
head(k$bsz$inputs[, c("input_id", "value", "label", "source")])
pick(k$bsz$inputs, "baseline_net_worth"); pick(k$bsz$inputs, "avoidance_rate"); pick(k$bsz$inputs, "tax_rate")
pick(k$rjkdc$inputs, "nber_ceiling_hardcoded")
pick(k$docs, "ggss_noncitizen_wealth")""",
                py="""# Layer 8: the contracts and the rows the main estimate reads.
list(k)                                          # bsz, rjkdc, docs, hoopes
k["bsz"]["inputs"][:3]
b.pick(k["bsz"]["inputs"], "baseline_net_worth"), b.pick(k["bsz"]["inputs"], "avoidance_rate"), b.pick(k["bsz"]["inputs"], "tax_rate")
b.pick(k["rjkdc"]["inputs"], "nber_ceiling_hardcoded")
b.pick(k["docs"], "ggss_noncitizen_wealth")"""),
    }
    for L in layers:
        L["interactive"] = INTERACTIVE[L["n"]]

    ENVIRONMENT = dict(
        r=r"""# Environment for the comparison chain, R. In Positron open the opa-prop40 folder, then run this once.
# Needs nothing downloaded: the two sides' export contracts are committed.
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
        "title": "The comparison: the main estimate",
        "headline": {
            "label": "Main estimate, the gap on the common output",
            "value": f"${gap:.1f}B",
            "computed": gap,
            "definition": ("the difference between the two sides' gross one-time wealth tax revenue "
                           "once both are estimated on one definition, explained one disputed input "
                           "at a time: BSZ Table 5 row 1 minus the NBER expected revenue"),
            "where": "https://fhoces.github.io/opa-prop40/",
        },
        "commit": LINK_REF,
        "seeded": today,
        "verified_by": (f"Rscript, layer 6 at {TRACED_AT}: score_common(bridge_inputs(read_contracts())$sup)[['a']] "
                        f"- rauh_nber_expectation(0, 72, 0.30, 0.60, ...)[['a']] = 103.815 - 36 = "
                        f"{gap:.3f}; the same from export/r/ends.csv (bsz_model - nber_own), from "
                        "export/py/ends.csv, and from the two bars in assets/comparison-data.js"),
        "runs_for_a_stranger": ("AUDIT.md step 8, level 2: .github/workflows/comparison-ci.yml rebuilds "
                                "the comparison in R and Python on a clean runner; no one-click (Binder) yet."),
        "environment": ENVIRONMENT,
        "layers": layers,
    }
    OUT.write_text(json.dumps(chain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(layers)} layers traced at {TRACED_AT}, links to {LINK_REF}, main estimate {gap}")


if __name__ == "__main__":
    sys.exit(main())
