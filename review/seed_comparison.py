#!/usr/bin/env python3
"""Seed review/comparison.json: the chain of code behind the comparison's two main estimates.

The headline is the two analyses' main estimates, shown next to each other on the comparison
explorer: the BSZ analysis's net total over 5 years and the JR analysis's NBER (September
2026) mean NPV. Under the common output (b), the net fiscal effect, they are the bridge's two
ends, and the chain traces those two ends. The BSZ end is score_common() at the all-BSZ
inputs. The JR end is the exact expectation of the authors' September 2026 Monte Carlo, which
score_common() also returns at the all-JR inputs. (The JR main estimate as printed, -38.9, is
the authors' seeded run, which the JR pipeline reproduces; its own chain is the JR one.) The
layers are written by hand below, top (the numbers on the explorer) to bottom (the two
analyses' export contracts). Snippets are cut from the files at line ranges found from
markers, so re-running this script after a code edit refreshes them. Every number in the
prose is read from the exports, not typed. The user's fields (state, understanding, missing,
feedback) are kept from an existing comparison.json when present.

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


def function_span(path, first, header=None):
    """[a, b]: from the line containing `first` to the closing brace of the R function whose
    definition line contains `header` (default `first`): the first line after it that is
    exactly "}"."""
    header = header or first
    text = (ROOT / path).read_text(encoding="utf-8").splitlines()
    a = next(i for i, l in enumerate(text) if first in l)
    h = next(i for i, l in enumerate(text) if i >= a and header in l)
    b = next(i for i, l in enumerate(text) if i > h and l == "}")
    return [a + 1, b + 1]


def read_csv(rel):
    with open(ROOT / rel, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def pick(rows, key, col="value"):
    """One contract value, by the first column (as pick() in comparison/R/contract.R)."""
    k0 = list(rows[0])[0]
    hit = [r for r in rows if r[k0] == key]
    assert len(hit) == 1, key
    return float(hit[0][col])


def bridge_snippet(path):
    """comparison-data.js is one long line; show its shape, the headline and the bars of the view it carries."""
    s = (ROOT / path).read_text(encoding="utf-8")
    j = json.loads(s[s.index("{"):s.rindex("}") + 1])
    B = j["series"]["own"]["b"]["shapley"]
    H = j["headline"]
    S = j["sliders"]
    own = j["series"]["own"]
    lines = [s.splitlines()[0],
             "window.__BRIDGE__ = {",
             '  "headline": {' + ", ".join(f'"{k}": {v}' for k, v in H.items()) + "},",
             f'  "series": {{ {", ".join(j["series"])}: {{ {", ".join(own)}: '
             f'{{ {", ".join(own["b"])} }} }} }},   // each a list of bars',
             f'  "sliders": {{ {", ".join(S)} }}   // steps = {S["steps"]}, {len(S["inputs"])} inputs, '
             f'minor = {", ".join(S["minor"])}',
             "};",
             "",
             "// series.own.b.shapley (output (b), Shapley, each analysis's own horizon):"]
    for b in B:
        lines.append(f'//   {b["id"]:<22} {b["type"]:<6} {b["value"]:>12.6f}')
    return "\n".join(lines), B, H, S


def main():
    data_snip, B, H, SL = bridge_snippet("assets/comparison-data.js")
    bsz_end, nber_end = B[0]["value"], B[-1]["value"]
    assert B[0]["id"] == "bsz" and B[-1]["id"] == "nber"
    rj_main = H["rjkdc"]
    gap = bsz_end - nber_end

    def ends_csv(rel, out="b"):
        r = [x for x in read_csv(rel) if x["horizon_setting"] == "own" and x["output"] == out][0]
        return {k: float(v) for k, v in r.items() if k not in ("horizon_setting", "output")}
    eb = ends_csv("comparison/export/r/ends.csv")
    ea = ends_csv("comparison/export/r/ends.csv", "a")
    epy = ends_csv("comparison/export/py/ends.csv")
    assert abs(eb["bsz_model"] - bsz_end) < 1e-9 and abs(eb["rauh_own"] - nber_end) < 1e-9
    assert abs(epy["bsz_model"] - bsz_end) < 1e-9 and abs(epy["rauh_own"] - nber_end) < 1e-9
    assert abs(H["bsz"] - bsz_end) < 1e-12 and abs(H["rjkdc_end_b"] - nber_end) < 1e-12
    assert abs(eb["rauh_residual"]) < 1e-10      # the common function returns the JR end exactly
    bb = [x for x in read_csv("comparison/export/r/bridge.csv")
          if x["horizon_setting"] == "own" and x["output"] == "b"]
    n_steps = len(bb)
    steps_sum = sum(float(x["shapley"]) for x in bb)
    assert abs(steps_sum + gap) < 1e-9           # the steps alone close the gap
    big = sorted(bb, key=lambda x: float(x["shapley"]))[:3]
    big_txt = ", ".join(f'{x["step_id"]} {float(x["shapley"]):.3f}' for x in big)
    pos = [x for x in bb if float(x["shapley"]) > 0]
    pos_txt = ", ".join(f'{x["step_id"]} +{float(x["shapley"]):.3f}' for x in pos)
    meta = {x["key"]: float(x["value"]) for x in read_csv("comparison/export/r/meta.csv")}
    inp = {x["input"]: (float(x["supporting_value"]), float(x["rauh_value"]))
           for x in read_csv("comparison/export/r/inputs.csv")}
    sv = {k: v[0] for k, v in inp.items()}
    rv = {k: v[1] for k, v in inp.items()}
    si = read_csv("bsz-analysis/export/r/inputs.csv")
    oi = read_csv("rjkdc-analysis/export/r/inputs.csv")
    oo = read_csv("rjkdc-analysis/export/r/outputs.csv")
    docs = read_csv("comparison/data/document-inputs.csv")
    W0 = pick(si, "baseline_net_worth")
    W0_r = pick(oi, "baseline_net_worth")
    grow = pick(oi, "nber_growth_rate")
    ceiling = pick(oi, "nber_ceiling_hardcoded")
    R0_r = pick(oo, "nber_domestic_grown")
    q_r = pick(oi, "q_litigation_survival")
    fmin, fmax = pick(oi, "nber_mc_f_min"), pick(oi, "nber_mc_f_max")
    cmin, cmax = pick(oi, "rauh_mc_c_min"), pick(oi, "rauh_mc_c_max")
    rmin, rmax = pick(oi, "rauh_mc_r_min"), pick(oi, "rauh_mc_r_max")
    tau = pick(si, "tax_rate")
    alpha_s = pick(si, "avoidance_rate")
    noncit = pick(docs, "ggss_noncitizen_wealth")
    wt_bsz = tau * W0 * (1 - alpha_s)
    assert abs(wt_bsz - ea["bsz_model"]) < 1e-9
    assert abs(rv["W_core"] - W0_r * (1 + grow)) < 1e-9 and abs(meta["R0_rauh"] - R0_r) < 1e-9
    assert abs(R0_r * meta["S_rauh"] - ceiling) < 1e-9 and abs(ea["rauh_own"] - q_r * ceiling) < 1e-9
    assert abs(rv["f0"] - (fmin + fmax) / 2) < 1e-12 and abs(rv["C"] - (cmin + cmax) / 2) < 1e-12
    rne = function_span("comparison/R/model.R", "rauh_nber_expectation <- function")
    rne_py = find_lines("comparison/py/bridge.py", "def rauh_nber_expectation(", "expected_annuity(H, r_min, r_max)}")
    minor_txt = ", ".join(SL["minor"])
    n_dials = len(SL["inputs"]) - len(SL["minor"])
    pct = lambda v, d=1: f"{100 * v:.{d}f}%"

    def m(v, d=1):
        return ("−" if v < 0 else "") + f"${abs(v):.{d}f}B"

    def h(v):
        return "perpetuity" if v == float("inf") else f"{v:g} years"

    layers = [
        dict(
            n=1, name="The numbers on the explorer",
            what=("This layer is the explorer's own JavaScript, not R or Python. The R and Python "
                  "code starts at layer 3. The page loads the bridge's data file and prints the two "
                  "main estimates from its headline object. headline.bsz is the BSZ net total. "
                  "headline.rjkdc is the JR NBER mean NPV as the JR pipeline reproduces the "
                  "authors' seeded run. Below them sit two panels of dials, one per analysis, in "
                  "two boxes: the wealth tax collected and the income tax lost. Each dial has "
                  f"{SL['steps'] + 1} positions. Position 0 is the panel's own analysis's value and "
                  f"position {SL['steps']} the other analysis's. {n_dials} inputs have a dial each. "
                  f"The other {len(SL['minor'])} ({minor_txt}) share one on/off switch, which "
                  "expand() turns into positions. positions() reads a panel's dials. updatePanel() "
                  "calls model.js (window.ComparisonModel, a JavaScript copy of score_common() and "
                  "slider_inputs(), layer 6, "
                  "checked against R by test-site.R) and prints the panel's estimate and each dial's "
                  "value. drawBars() draws the two panels' estimates as two bars on a fixed scale. "
                  "With every dial at position 0 the two bars are the bridge's two ends. The BSZ end "
                  "is the same number as the BSZ main estimate. The JR end is the exact expectation "
                  "of the same Monte Carlo, a little below the seeded run. The static header carries "
                  "the two main estimates too, written by site.R (layer 3), so it reads the same with "
                  "JavaScript off."),
            inputs=("D = window.__BRIDGE__ from assets/comparison-data.js (D.headline; D.sliders: the "
                    "two input vectors, the number of steps, the horizon settings, one entry per input "
                    "and the minor inputs); M = model.js"),
            inputs_from=[dict(layer="comparison-2", what="window.__BRIDGE__: the headline object and the sliders object")],
            other_inputs="the dials' positions, set by the reader",
            outputs=(f"headline: '{m(H['bsz'])}' (BSZ main estimate) and '{m(rj_main)}' (JR main estimate); "
                     f"bars with every dial at 0: '{m(bsz_end)}' (BSZ panel) and '{m(nber_end)}' (JR panel)"),
            method_ref=("Display only. The definitions are the method: BSZ's net total is the wealth tax "
                        "plus extra income tax from asset sales minus 5 years of lost income tax. JR's is "
                        "the mean NPV in perpetuity. The footnote on the explorer says the common output "
                        "(b) puts both on one definition, of which the two bars at position 0 are the ends."),
            method_status="plumbing",
            r=loc(EXPLORER, "positions(), expand(), updatePanel(), drawBars(): read each panel's dials, call model.js, draw the two bars",
                  find_lines(EXPLORER, "function positions(panel)", "function renderPanels()"), language="javascript"),
            py=None,
            targets=None,
        ),
        dict(
            n=2, name="The bridge's data file",
            what=("A generated JavaScript data file, not R or Python, written by R only. The Python "
                  "twin writes the same numbers as CSV under comparison/export/py/. The file holds one "
                  "object, window.__BRIDGE__, with three parts. headline holds the two main estimates, "
                  "the printed JR number and the two ends under (b). series holds the bridge for the "
                  "explorer's one view, output (b) at each analysis's own horizon, in two ways of "
                  "sizing the steps (shapley, sequential). Each is a list of "
                  f"{len(B)} bars: the BSZ end, the {len(B) - 2} steps and the JR end. sliders holds "
                  "what model.js needs to estimate any mix of dials: the two input vectors, the number "
                  "of steps, the horizon settings, the inputs each dial moves with its two printed "
                  "values, and the minor inputs. The explorer reads headline and sliders. Output (a) and "
                  "the common horizons stay in the exports and the report."),
            inputs="nothing at run time; the file is written by the next layer",
            inputs_from=[dict(layer="comparison-3", what="the text of comparison-data.js, written as raw UTF-8 bytes")],
            other_inputs="",
            outputs=(f"headline.bsz = {H['bsz']:.6f}, headline.rjkdc = {rj_main:.6f}, "
                     f"headline.rjkdc_end_b = {H['rjkdc_end_b']:.6f}; series.own.b.shapley: "
                     f"bsz = {bsz_end:.6f}, nber = {nber_end:.6f}"),
            method_ref=("Plumbing. test-site.R checks that the committed file is byte-identical to what "
                        "render_site() writes, that the headline and the end bars equal ends.csv, and "
                        "that the sliders object matches step_inputs and the minor inputs."),
            method_status="plumbing",
            r=dict(path="assets/comparison-data.js", symbol="window.__BRIDGE__", lines=[1, 2],
                   language="javascript", url=f"{REPO}/blob/{LINK_REF}/assets/comparison-data.js",
                   snippet=data_snip),
            py=None,
            targets=None,
        ),
        dict(
            n=3, name="Writing the pages and the data file",
            what=("build_series() turns the exported tables into the bars of every view, in display "
                  "order. The BSZ end comes first (the 'bsz' bar, ends$bsz_model). Then come the "
                  "steps, dropping any that is zero both ways. The JR end comes last (the 'nber' bar, "
                  "ends$rauh_own). The common function returns both ends exactly, so no bar closes a "
                  "model difference. render_site() fills the two pages' tokens, including the two "
                  "main estimates: hl_bsz is ends$bsz_model on (b), and hl_rjkdc is the JR contract's "
                  "npv_mc_nber_mean, read from endpoints.csv. It then serializes the headline, "
                  "series$own$b and the sliders to JSON. write_site() writes index.html, the explorer "
                  "and the data file."),
            inputs="ex: the exported tables read back from comparison/export/r/ (ends, bridge, endpoints, inputs, meta, ...)",
            inputs_from=[dict(layer="comparison-4", what="ends (one row per horizon setting and output: bsz_model, rauh_model, rauh_own, rauh_residual), bridge (the step values) and endpoints (contract_value of rauh_nber_npv)")],
            other_inputs="the page templates comparison/site/index.template.html and explorer.template.html (prose and {{tokens}}); bridge_inputs() for the sliders object",
            outputs=(f"the 'bsz' bar = ends$bsz_model = {eb['bsz_model']:.6f}; the 'nber' bar = ends$rauh_own = "
                     f"{eb['rauh_own']:.6f}; tokens hl_bsz = {m(H['bsz'])}, hl_rjkdc = {m(rj_main)}, gap_b = {m(gap)}"),
            method_ref="Plumbing. The Python twin has no site writer; its export/py/ends.csv carries the same two ends (test-parity.R).",
            method_status="plumbing",
            r=loc("comparison/R/site.R", "build_series()", function_span("comparison/R/site.R", "build_series <- function(ex) {")),
            py=None,
            targets="comparison/run.R: write_site(root)",
        ),
        dict(
            n=4, name="The bridge's ends and steps",
            what=("build_all() estimates everything the pages show. It loops over the horizon settings: "
                  "each analysis's own horizon, then a common 5, 10, 20, 30 or 50 years or a "
                  "perpetuity. With a common horizon the horizon step is not a player. In each setting "
                  "it estimates score_common() at the all-BSZ inputs (v_sup, the BSZ end) and at the "
                  "all-JR inputs (v_rauh). It also computes the authors' own Monte Carlo mean at the "
                  "JR horizon (own_n, from rauh_nber_expectation()). For outputs (a) and (b) it then "
                  "runs the two decompositions of layer 5 and stores every coalition's value (the "
                  "switchboard). Each ends row records bsz_model, rauh_model, rauh_own and "
                  "rauh_residual = rauh_own - rauh_model. The residual is zero by construction, "
                  "because the script's own ceiling is an input; it is kept so the identity is tested."),
            inputs="bi: the two input vectors; nber_args: the JR Monte Carlo bounds (wt_min 0, wt_max, f, C and r ranges)",
            inputs_from=[dict(layer="comparison-5", what="the Shapley and one-order step values for each output and setting"),
                         dict(layer="comparison-6", what="score_common() at the two input vectors (v_sup, v_rauh) and rauh_nber_expectation() (own_n)"),
                         dict(layer="comparison-7", what="bi: sup and rauh, the two input vectors")],
            other_inputs="the horizon settings HORIZONS = 5, 10, 20, 30, 50 years and a perpetuity",
            outputs=(f"ends, own horizon, output (b): bsz_model {eb['bsz_model']:.3f}, rauh_model "
                     f"{eb['rauh_model']:.3f}, rauh_own {eb['rauh_own']:.3f}, rauh_residual "
                     f"{eb['rauh_residual']:.3f}; gap = {eb['bsz_model']:.3f} - ({eb['rauh_own']:.3f}) = {gap:.3f}; "
                     f"the {n_steps} Shapley steps sum to {steps_sum:.3f}"),
            method_ref=("This OPA's reconciliation (PLAN.md, the common output and decision 9; DISPUTES.md "
                        "for each input). Checks: test-shapley.R that the Shapley and the one-order steps "
                        "sum to rauh_model - bsz_model in every setting and output; test-endpoints.R that "
                        "rauh_model equals rauh_own and pins each end against the printed number; "
                        "test-site.R that the steps on (b) add up to the gap between the two ends."),
            method_status="opa_definition",
            r=loc("comparison/R/build.R", "build_all(): the ends and the bridge, for every horizon setting",
                  find_lines("comparison/R/build.R", "build_all <- function(k = read_contracts()) {",
                             "bridge <- do.call(rbind, bridge)")),
            py=loc("comparison/py/bridge.py", "build_all(): the same loop",
                   find_lines("comparison/py/bridge.py", "def build_all(k):", "bridge.sort(")),
            targets="comparison/run.R: write_exports(build_all(read_contracts(root)), ...)",
        ),
        dict(
            n=5, name="Splitting the gap into steps",
            what=(f"There are {n_steps} steps. Each switches one disputed input from the BSZ value to "
                  "the JR value of its September 2026 version. The share-lost step switches two "
                  "together: the leavers' ratio kappa and the flat share f0. Because inputs interact, "
                  "a step's size depends on when it is switched. shapley_bridge() averages each switch "
                  "over every order, exactly. It estimates the model at all "
                  f"2^{n_steps} = {2 ** n_steps:,} subsets of switched inputs (coalition_values()) "
                  "and weights each difference by how many orders produce it. sequential_bridge() "
                  "switches them in one order, Hoopes's (sequential_order()). Both sets of steps add "
                  "up to the model gap between the two input vectors. That gap is the whole gap "
                  "between the two ends, since the model returns both ends exactly."),
            inputs="sup, rauh (the two input vectors) and the list of steps",
            inputs_from=[dict(layer="comparison-6", what="score_common(): output (b) or (a) at any mix of the two input vectors"),
                         dict(layer="comparison-7", what="sup and rauh, the two input vectors")],
            other_inputs="step_inputs (which arguments each step switches) and sequential_order()",
            outputs=(f"output (b), own horizon: {n_steps} Shapley steps summing to {steps_sum:.3f} = "
                     f"-({gap:.3f}); the largest are {big_txt}; the positive ones are {pos_txt}"),
            method_ref=("Shapley value, the standard average-over-orders decomposition. test-shapley.R "
                        "checks the sum in every setting and compares with a brute-force average over orders."),
            method_status="matches",
            r=loc("comparison/R/model.R", "coalition_values(), shapley_bridge(), sequential_bridge()",
                  function_span("comparison/R/model.R", "coalition_values <- function", "sequential_bridge <- function")),
            py=loc("comparison/py/bridge.py", "coalition_values(), shapley_bridge(), sequential_bridge()",
                   find_lines("comparison/py/bridge.py", "def coalition_values(", "return out")),
            targets=None,
        ),
        dict(
            n=6, name="The estimating function and the JR end",
            what=("score_common() is the one function that estimates both analyses. R0 = tau x base x "
                  "(1 - real-estate share) is the revenue with no behaviour. S = 1 - d_conf is the "
                  "share of the base still taxed after the confirmed departures. The wealth tax is "
                  "WT = R0 x (1 - alpha) x S x q, where alpha is the avoidance allowance and q the "
                  "chance the Act survives litigation. The share of income tax lost is f = alpha m + "
                  "(1 - alpha m)(kappa d_conf + f0): the BSZ movers' share, then the leavers' own tax "
                  "on the departed base (kappa) and a flat share (f0). Output (b) is WT + X - PV, with "
                  "X the extra income tax from asset sales and PV = f x C x the expected annuity. "
                  f"At the all-BSZ inputs S = 1 and q = 1, so WT = {tau:g} x {W0:,.0f} x {1 - alpha_s:g} = "
                  f"{wt_bsz:.3f}, BSZ Table 5 row 1. Output (b) adds X = {meta['X_bsz']:.3f} and "
                  f"subtracts PV = {meta['PV_bsz_own']:.3f}, five years of lost income tax, giving "
                  f"{bsz_end:.3f}, the BSZ end. At the all-JR inputs R0 = {meta['R0_rauh']:.3f} and "
                  f"S = {meta['S_rauh']:.4f}, so R0 x S = {ceiling:g}, the authors' ceiling. Then WT = "
                  f"{q_r:g} x {ceiling:g} = {ea['rauh_own']:g}, f = f0 = {meta['f_rauh']:g} and C = "
                  f"{meta['C_rauh']:g}, so (b) = {ea['rauh_own']:g} - {meta['f_rauh']:g} x "
                  f"{meta['C_rauh']:g} x {meta['A_inf']:.3f} = {nber_end:.3f}, the JR end. "
                  f"rauh_nber_expectation() (model.R lines {rne[0]}-{rne[1]}, bridge.py lines "
                  f"{rne_py[0]}-{rne_py[1]}) computes the same mean straight from the Monte Carlo's "
                  f"ranges: the revenue uniform on [0, {ceiling:g}], the share lost on [{fmin:g}, {fmax:g}], "
                  f"the income tax C on [{cmin:g}, {cmax:g}] and r on [{pct(rmin)}, {pct(rmax)}], all "
                  "independent. This is the last layer that computes."),
            inputs="x: one input vector (sup at the BSZ end, rauh at the JR end); for rauh_nber_expectation(), the Monte Carlo bounds",
            inputs_from=[dict(layer="comparison-7", what=(
                f"sup: tau {sv.get('tau', tau):g}, W_core {sv['W_core']:g}, W_noncit {sv['W_noncit']:g}, "
                f"re {sv['re']:g}, d_conf {sv['d_conf']:g}, alpha {sv['alpha']:g}, q {sv['q']:g}, "
                f"kappa {sv['kappa']:.3f}, f0 {sv['f0']:g}, ...; rauh: W_core {rv['W_core']:.1f}, "
                f"d_conf {rv['d_conf']:.3f}, q {rv['q']:g}, f0 {rv['f0']:g}, C {rv['C']:g}, ..."))],
            other_inputs=(f"the Monte Carlo bounds wt_min = 0 (a literal in build.R), wt_max = {ceiling:g} "
                          "(contract row nber_ceiling_hardcoded), and the f, C and r ranges (contract rows "
                          "nber_mc_f_*, rauh_mc_c_*, rauh_mc_r_*)"),
            outputs=(f"score_common(sup)['b'] = {bsz_end:.6f}; score_common(rauh)['b'] = {eb['rauh_model']:.6f}; "
                     f"rauh_nber_expectation(...)['b'] = {nber_end:.6f}; gap {gap:.3f}"),
            method_ref=("BSZ PDF p.24 (90% x 5% x $2,307B) and Table 5 row 1, p.39; Jaros and Rauh NBER "
                        "c15504, the Monte Carlo in the authors' public repository (NPV_dist_v8.R). "
                        "test-endpoints.R checks both ends against the printed numbers (the JR one "
                        "within Monte Carlo error of the printed -38.9) and that the common function at "
                        "the all-JR inputs returns the authors' expectation exactly."),
            method_status="matches",
            r=loc("comparison/R/model.R", "score_common()",
                  function_span("comparison/R/model.R", "score_common <- function(x) {")),
            py=loc("comparison/py/bridge.py", "score_common()",
                   find_lines("comparison/py/bridge.py", "def score_common(x", '"annual_loss": f * x["C"]')),
            targets=None,
        ),
        dict(
            n=7, name="The two input vectors",
            what=("bridge_inputs() builds the two settings of every disputed input. Each value is read "
                  "from a contract row or a transcribed document input. The two share tau, m, g, t_cg "
                  f"and the discount-rate range. The BSZ base is the contract's {W0:,.0f}, split into "
                  f"{noncit:g} of non-US-citizen residents and {sv['W_core']:,.0f} of the rest. The BSZ "
                  f"analysis takes no departures (d_conf 0), no litigation discount (q 1), the "
                  f"{pct(alpha_s, 0)} avoidance allowance and a {h(sv['H'])} horizon. The JR values are "
                  f"those of its September 2026 version. The base is the 2025 Forbes list's "
                  f"{W0_r:,.1f} grown {pct(grow, 0)} to {rv['W_core']:,.1f}. The real-estate share is "
                  f"what the person-level file nets out ({rv['re']:.4f}). d_conf = 1 - {ceiling:g} / "
                  f"{R0_r:.3f} = {rv['d_conf']:.3f} brings the revenue down to the script's ceiling "
                  f"after seven departures. q is {q_r:g}, f0 and C are the midpoints of the Monte "
                  f"Carlo's ranges ({rv['f0']:g} and {rv['C']:g}) and the horizon is a {h(rv['H'])}."),
            inputs="k: the two contracts and the document inputs",
            inputs_from=[dict(layer="comparison-8", what="k$bsz, k$rjkdc (inputs and outputs tables) and k$docs, looked up row by row with pick()")],
            other_inputs="none",
            outputs=(f"sup: W_core {sv['W_core']:g}, W_noncit {sv['W_noncit']:g}, re {sv['re']:g}, "
                     f"d_conf {sv['d_conf']:g}, alpha {sv['alpha']:g}, q {sv['q']:g}, kappa {sv['kappa']:.3f}, "
                     f"f0 {sv['f0']:g}, C {sv['C']:.3f}, H {sv['H']:g}, s {sv['s']:.3f}; "
                     f"rauh: W_core {rv['W_core']:.1f}, W_noncit {rv['W_noncit']:g}, re {rv['re']:.4f}, "
                     f"d_conf {rv['d_conf']:.3f}, alpha {rv['alpha']:g}, q {rv['q']:g}, kappa {rv['kappa']:g}, "
                     f"f0 {rv['f0']:g}, C {rv['C']:g}, H {rv['H']:g}, s {rv['s']:g}"),
            method_ref="Each value's source and page is in comparison/export/r/inputs.csv (bridge_input_table()).",
            method_status="matches",
            r=loc("comparison/R/build.R", "bridge_inputs()",
                  function_span("comparison/R/build.R", "bridge_inputs <- function(k) {")),
            py=loc("comparison/py/bridge.py", "bridge_inputs()",
                   find_lines("comparison/py/bridge.py", "def bridge_inputs(k):", "return sup, rauh")),
            targets=None,
        ),
        dict(
            n=8, name="The raw source: the two export contracts",
            what=("The comparison reads exactly three kinds of file. The first is each analysis's "
                  "export contract (export/r/inputs.csv and outputs.csv, written by that analysis's "
                  "own pipeline for others to read). The second is the values transcribed from the "
                  "PDFs with their page (comparison/data/document-inputs.csv). The third is Hoopes's "
                  "digitized figure. pick() looks up one row and fails loudly if it is missing or "
                  "duplicated. The chain stops here: what is behind each contract row is each "
                  "analysis's own chain."),
            inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            inputs_from=[],
            other_inputs="bsz-analysis/export/r/{inputs,outputs}.csv, rjkdc-analysis/export/r/{inputs,outputs}.csv, comparison/data/*.csv",
            outputs=(f"for the two ends: BSZ baseline_net_worth {W0:g}, avoidance_rate {alpha_s:g}, tax_rate "
                     f"{tau:g}, tab5_row1 extra income tax and annual loss; JR baseline_net_worth {W0_r:g}, "
                     f"nber_growth_rate {grow:g}, nber_domestic_grown {R0_r:.3f}, nber_ceiling_hardcoded "
                     f"{ceiling:g}, q_litigation_survival {q_r:g}, nber_mc_f_min/max {fmin:g}/{fmax:g}, "
                     f"rauh_mc_c_min/max {cmin:g}/{cmax:g}, rauh_mc_r_min/max {rmin:g}/{rmax:g}, "
                     f"npv_mc_nber_mean {pick(oo, 'npv_mc_nber_mean'):.3f} (the JR main estimate); "
                     f"document inputs ggss_noncitizen_wealth {noncit:g}, bsz_loss_horizon "
                     f"{pick(docs, 'bsz_loss_horizon'):g}, rauh_loss_horizon {pick(docs, 'rauh_loss_horizon'):g}"),
            method_ref="Plumbing: base R read.csv / Python csv, no transformation.",
            method_status="plumbing",
            r=loc("comparison/R/contract.R", "read_contracts(), pick()",
                  function_span("comparison/R/contract.R", "read_contracts <- function", "pick <- function")),
            py=loc("comparison/py/bridge.py", "pick(), read_contracts()",
                   find_lines("comparison/py/bridge.py", "def pick(", '"hoopes": read_rows')),
            targets=None,
        ),
    ]

    HANDOFF_TOKENS = {
        (1, "comparison-2"): dict(tokens=["D", "__BRIDGE__", "headline", "sliders"], source_tokens=["__BRIDGE__", "headline", "sliders"]),
        (2, "comparison-3"): dict(tokens=["__BRIDGE__"], source_tokens=["build_series", "headline", "add"]),
        (3, "comparison-4"): dict(tokens=["ex", "en", "e", "bsz_model", "rauh_own"], source_tokens=["ends", "bsz_model", "rauh_own"]),
        (4, "comparison-5"): dict(tokens=["shapley_bridge", "sequential_bridge", "sh", "sq"], source_tokens=["shapley_bridge", "sequential_bridge", "phi", "out"]),
        (4, "comparison-6"): dict(tokens=["score_common", "v_sup", "v_rauh", "own_n"], source_tokens=["score_common", "rauh_nber_expectation", "WT", "e_wt"]),
        (4, "comparison-7"): dict(tokens=["sup", "rauh", "bi"], source_tokens=["bridge_inputs", "sup", "rauh"]),
        (5, "comparison-6"): dict(tokens=["score_common"], source_tokens=["score_common", "WT"]),
        (5, "comparison-7"): dict(tokens=["sup", "rauh"], source_tokens=["sup", "rauh"]),
        (6, "comparison-7"): dict(tokens=["x"], source_tokens=["sup", "rauh"]),
        (7, "comparison-8"): dict(tokens=["k", "pick"], source_tokens=["read_contracts", "pick"]),
    }
    for L in layers:
        for x in L["inputs_from"]:
            x.update(HANDOFF_TOKENS.get((L["n"], x["layer"]), dict(tokens=[], source_tokens=[])))

    # A few lines to check each layer by hand, after the chain's environment code has run
    # (ENVIRONMENT below). The values in the comments are filled from the exports (@name@).
    V = dict(bsz=f"{H['bsz']:.3f}", rj=f"{rj_main:.3f}", bend=f"{bsz_end:.3f}", nend=f"{nber_end:.3f}",
             gap=f"{gap:.3f}", ngap=f"{-gap:.3f}", wt=f"{wt_bsz:.3f}", X=f"{meta['X_bsz']:.3f}",
             PV=f"{meta['PV_bsz_own']:.3f}", R0r=f"{meta['R0_rauh']:.3f}", Sr=f"{meta['S_rauh']:.4f}",
             ceil=f"{ceiling:g}", wtr=f"{ea['rauh_own']:g}", fr=f"{meta['f_rauh']:g}",
             Cr=f"{meta['C_rauh']:g}", nst=str(n_steps), nco=f"{2 ** n_steps:,}",
             minor=", ".join(f'"{x}"' for x in SL["minor"]), nbars=str(len(B)))

    def fill(s):
        for k_, v_ in V.items():
            s = s.replace(f"@{k_}@", v_)
        assert "@" not in s, s
        return s

    INTERACTIVE = {
        1: dict(js="""// In the browser: open the explorer (comparison/site/explorer/), then paste this in the developer console.
D = window.__BRIDGE__
D.headline.bsz, D.headline.rjkdc            // @bsz@, @rj@: the two main estimates
D.headline.bsz_end_b, D.headline.rjkdc_end_b  // @bend@, @nend@: the two ends under (b)
D.sliders.minor                             // [@minor@]: the inputs behind the one switch
M = window.ComparisonModel                  // model.js
M.panelValue(D.sliders, "bsz", {}).value    // @bend@: the BSZ panel, every dial at 0
M.panelValue(D.sliders, "rjkdc", {}).value  // @nend@: the JR panel, every dial at 0
far = {}; D.sliders.inputs.forEach(x => far[x.id] = D.sliders.steps)
M.panelValue(D.sliders, "bsz", far).value   // @nend@: the BSZ panel with every dial at the far end"""),
        2: dict(r="""# Layer 2: read the committed data file back: the headline and the bars.
txt <- readLines("assets/comparison-data.js")[2]
D <- jsonlite::fromJSON(sub(";$", "", sub("^window.__BRIDGE__ = ", "", txt)), simplifyVector = FALSE)
names(D)                                          # headline, series, sliders
str(D$headline)                                   # bsz @bsz@, rjkdc @rj@, ...
B <- D$series$own$b$shapley                       # @nbars@ bars
vals <- setNames(vapply(B, function(b) b$value, 0), vapply(B, function(b) b$id, ""))
vals
vals[["bsz"]] - vals[["nber"]]                    # @gap@""",
                py="""# Layer 2: read the committed data file back: the headline and the bars.
import json
s = open("assets/comparison-data.js").read()
D = json.loads(s[s.index("{"):s.rindex("}") + 1])
list(D)                                           # headline, series, sliders
D["headline"]                                     # bsz @bsz@, rjkdc @rj@, ...
vals = {b["id"]: b["value"] for b in D["series"]["own"]["b"]["shapley"]}
vals                                              # @nbars@ bars
vals["bsz"] - vals["nber"]                        # @gap@"""),
        3: dict(r="""# Layer 3: the bars from the exported tables, and the pages' own output.
ex <- read_exports("comparison/export/r")
B <- build_series(ex)$own$b$shapley
setNames(vapply(B, function(b) b$value, 0), vapply(B, function(b) b$id, ""))
s <- render_site()
identical(s$js, paste0(paste(readLines("assets/comparison-data.js"), collapse = "\\n"), "\\n"))   # TRUE
regmatches(s$explorer, gregexpr('id="hl-(bsz|rjkdc)">[^<]+', s$explorer))[[1]]""",
                py="""# Layer 3: no Python twin writes the pages; the twin's ends.csv carries the same two ends.
import csv
ends = [r for r in csv.DictReader(open("comparison/export/py/ends.csv"))
        if r["horizon_setting"] == "own" and r["output"] == "b"][0]
float(ends["bsz_model"]), float(ends["rauh_own"])      # @bend@, @nend@
float(ends["bsz_model"]) - float(ends["rauh_own"])     # @gap@"""),
        4: dict(r="""# Layer 4: everything the pages show, rebuilt from the contracts.
res <- build_all(k)
eb <- res$ends[res$ends$horizon_setting == "own" & res$ends$output == "b", ]
eb                                                                     # rauh_residual 0
eb$bsz_model - eb$rauh_own                                             # @gap@
b <- res$bridge[res$bridge$horizon_setting == "own" & res$bridge$output == "b", ]
sum(b$shapley)                                                         # @ngap@: the steps alone""",
                py="""# Layer 4: everything the pages show, rebuilt from the contracts.
res = b.build_all(k)
eb = [e for e in res["ends"] if e["horizon_setting"] == "own" and e["output"] == "b"][0]
eb                                                                     # rauh_residual 0
eb["bsz_model"] - eb["rauh_own"]                                       # @gap@
steps = [r for r in res["bridge"] if r["horizon_setting"] == "own" and r["output"] == "b"]
sum(r["shapley"] for r in steps)                                       # @ngap@: the steps alone"""),
        5: dict(r="""# Layer 5: the @nst@ steps of output (b), two ways.
players <- bridge_steps()$step_id
sh <- shapley_bridge(bi$sup, bi$rauh, players, "b")                    # @nco@ coalitions
round(sh, 3)
sum(sh)                                                                # @ngap@
score_common(bi$rauh)[["b"]] - score_common(bi$sup)[["b"]]            # the same
round(sequential_bridge(bi$sup, bi$rauh, sequential_order(), "b"), 3)  # Hoopes's order""",
                py="""# Layer 5: the @nst@ steps of output (b), two ways.
sh = b.shapley_bridge(sup, rauh, b.IDS, "b")                           # @nco@ coalitions
{k_: round(v, 3) for k_, v in sh.items()}
sum(sh.values())                                                       # @ngap@
b.score_common(rauh)["b"] - b.score_common(sup)["b"]                   # the same
{k_: round(v, 3) for k_, v in b.sequential_bridge(sup, rauh, b.SEQUENTIAL, "b").items()}"""),
        6: dict(r="""# Layer 6: the two ends under (b), and the gap between them.
v <- score_common(bi$sup); v[c("a", "X", "PV", "b")]                   # @wt@, @X@, @PV@, @bend@
vr <- score_common(bi$rauh); vr[c("R0", "S", "a", "f", "b")]           # @R0r@, @Sr@, @wtr@, @fr@, @nend@
vr[["R0"]] * vr[["S"]]                                                 # @ceil@, the authors' ceiling
oi <- k$rjkdc$inputs
nber <- rauh_nber_expectation(wt_min = 0, wt_max = pick(oi, "nber_ceiling_hardcoded"),
  f_min = pick(oi, "nber_mc_f_min"), f_max = pick(oi, "nber_mc_f_max"),
  c_min = pick(oi, "rauh_mc_c_min"), c_max = pick(oi, "rauh_mc_c_max"),
  r_min = pick(oi, "rauh_mc_r_min"), r_max = pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = @wtr@, b = @nend@
vr[["b"]] - nber[["b"]]                                                # 0: the model returns the JR end
v[["b"]] - nber[["b"]]                                                 # @gap@""",
                py="""# Layer 6: the two ends under (b), and the gap between them.
v = b.score_common(sup); v["a"], v["X"], v["PV"], v["b"]              # @wt@, @X@, @PV@, @bend@
vr = b.score_common(rauh); vr["R0"], vr["S"], vr["a"], vr["f"], vr["b"]   # @R0r@, @Sr@, @wtr@, @fr@, @nend@
oi = k["rjkdc"]["inputs"]
nber = b.rauh_nber_expectation(0.0, b.pick(oi, "nber_ceiling_hardcoded"),
    b.pick(oi, "nber_mc_f_min"), b.pick(oi, "nber_mc_f_max"),
    b.pick(oi, "rauh_mc_c_min"), b.pick(oi, "rauh_mc_c_max"),
    b.pick(oi, "rauh_mc_r_min"), b.pick(oi, "rauh_mc_r_max"))
nber                                                                   # a = @wtr@, b = @nend@
vr["b"] - nber["b"]                                                    # 0: the model returns the JR end
v["b"] - nber["b"]                                                     # @gap@"""),
        7: dict(r="""# Layer 7: the two input vectors, next to each other.
str(bi$sup)
str(bi$rauh)
bridge_input_table(bi)[, c("step_id", "input", "supporting_value", "rauh_value")]""",
                py="""# Layer 7: the two input vectors, next to each other.
sup
rauh
{s: [(nm, sup[nm], rauh[nm]) for nm in i] for s, i in b.STEP_INPUTS.items()}"""),
        8: dict(r="""# Layer 8: the contracts and the rows the two ends read.
names(k)                                         # bsz, rjkdc, docs, hoopes
head(k$bsz$inputs[, c("input_id", "value", "label", "source")])
pick(k$bsz$inputs, "baseline_net_worth"); pick(k$bsz$inputs, "avoidance_rate"); pick(k$bsz$inputs, "tax_rate")
pick(k$rjkdc$inputs, "nber_ceiling_hardcoded"); pick(k$rjkdc$inputs, "q_litigation_survival")
pick(k$rjkdc$inputs, "nber_mc_f_min"); pick(k$rjkdc$inputs, "nber_mc_f_max")
pick(k$rjkdc$outputs, "npv_mc_nber_mean")       # @rj@, the JR main estimate
pick(k$docs, "ggss_noncitizen_wealth")""",
                py="""# Layer 8: the contracts and the rows the two ends read.
list(k)                                          # bsz, rjkdc, docs, hoopes
k["bsz"]["inputs"][:3]
b.pick(k["bsz"]["inputs"], "baseline_net_worth"), b.pick(k["bsz"]["inputs"], "avoidance_rate"), b.pick(k["bsz"]["inputs"], "tax_rate")
b.pick(k["rjkdc"]["inputs"], "nber_ceiling_hardcoded"), b.pick(k["rjkdc"]["inputs"], "q_litigation_survival")
b.pick(k["rjkdc"]["inputs"], "nber_mc_f_min"), b.pick(k["rjkdc"]["inputs"], "nber_mc_f_max")
b.pick(k["rjkdc"]["outputs"], "npv_mc_nber_mean")   # @rj@, the JR main estimate
b.pick(k["docs"], "ggss_noncitizen_wealth")"""),
    }
    for L in layers:
        L["interactive"] = {k_: fill(v_) for k_, v_ in INTERACTIVE[L["n"]].items()}

    ENVIRONMENT = dict(
        r=r"""# Environment for the comparison chain, R. In Positron open the opa-prop40 folder, then run this once.
# Needs nothing downloaded: the two analyses' export contracts are committed.
while (!dir.exists("comparison")) setwd("..")
invisible(lapply(list.files("comparison/R", pattern = "\\.R$", full.names = TRUE), source))   # every function on the chain
k  <- read_contracts()          # layer 8: the two contracts and the document inputs
bi <- bridge_inputs(k)          # layer 7: the two input vectors
cat("ready: BSZ base", bi$sup$W_core + bi$sup$W_noncit, "; JR base", bi$rauh$W_core, "\n")""",
        py="""# Environment for the comparison chain, Python. In Positron open the opa-prop40 folder, then run this once.
# Needs scipy (pip install scipy); nothing downloaded.
import os, sys
from pathlib import Path
os.chdir(next(p for p in [Path.cwd(), *Path.cwd().parents] if (p / "comparison").is_dir()))   # the repo root
sys.path.insert(0, "comparison/py")
import bridge as b                       # the Python twin: every function on the chain
k = b.read_contracts(os.getcwd())        # layer 8: the two contracts and the document inputs
sup, rauh = b.bridge_inputs(k)           # layer 7: the two input vectors
print("ready: BSZ base", sup["W_core"] + sup["W_noncit"], "; JR base", rauh["W_core"])""",
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
            "label": "BSZ main estimate and JR main estimate, on the common output (b)",
            "value": f"{m(H['bsz'])} and {m(rj_main)}",
            "computed": {"bsz": H["bsz"], "rjkdc": rj_main, "bsz_end_b": bsz_end, "rjkdc_end_b": nber_end},
            "definition": ("the two analyses' own main estimates, next to each other: BSZ's net total "
                           "(wealth tax + extra income tax from selling assets - income tax lost to "
                           "leavers, present value of 5 years) and JR's NBER September 2026 mean NPV "
                           "(perpetuity). Under the common output (b), the net fiscal effect, they are "
                           f"the bridge's two ends, {m(bsz_end)} and {m(nber_end)} (the exact expectation "
                           f"of the Monte Carlo whose seeded run is {m(rj_main, 3)}). The gap between the "
                           f"ends, {m(gap)}, is the sum of the bridge's {n_steps} steps"),
            "where": "https://fhoces.github.io/opa-prop40/comparison/site/explorer/",
        },
        "commit": LINK_REF,
        "seeded": today,
        "verified_by": (f"Rscript, layer 6 at {TRACED_AT}: score_common(bridge_inputs(read_contracts())$sup)[['b']] "
                        f"= {bsz_end:.3f}, the same at $rauh = {eb['rauh_model']:.3f}, and "
                        f"rauh_nber_expectation(0, {ceiling:g}, {fmin:g}, {fmax:g}, {cmin:g}, {cmax:g}, {rmin:g}, {rmax:g})[['b']] "
                        f"= {nber_end:.3f}; the same from export/r/ends.csv (bsz_model, rauh_own on (b)), from "
                        "export/py/ends.csv, and from the headline and the end bars in assets/comparison-data.js. "
                        f"The JR main estimate as shown, {m(rj_main, 3)}, is the JR contract row "
                        "npv_mc_nber_mean (the authors' seeded run), traced by the JR chain"),
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
