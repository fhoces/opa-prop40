#!/usr/bin/env python3
"""Seed review/bsz.json: the chain of code behind the BSZ main estimate ($106.8B).

The layers are written by hand below, top (the number on the page) to bottom (the raw
workbook). Snippets are cut from the files at the line ranges given, so re-running this
script after a code edit refreshes them. The user's fields (state, understanding, missing,
feedback) are kept from an existing bsz.json when present.

Run from the repo root:  python3 review/seed_bsz.py
"""
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "review" / "bsz.json"
REPO = "https://github.com/fhoces/opa-prop40"

COMMIT = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "--short", "HEAD"],
                        capture_output=True, text=True, check=True).stdout.strip()


def loc(path, symbol, lines, language=None):
    """One code location: repo-relative path, the function or object, [first, last] line."""
    p = ROOT / path
    text = p.read_text(encoding="utf-8").splitlines()
    a, b = lines
    snippet = "\n".join(text[a - 1:b])
    if len(snippet) > 2500:
        snippet = snippet[:2500] + "\n... (cut; open the file for the rest)"
    if language is None:
        language = {"R": "r", "py": "python", "js": "javascript", "html": "html"}.get(
            path.rsplit(".", 1)[-1], "text")
    return {"path": path, "symbol": symbol, "lines": [a, b], "language": language,
            "url": f"{REPO}/blob/{COMMIT}/{path}#L{a}-L{b}", "snippet": snippet}


def grid_snippet(path):
    """grid.js is one long line; show its shape and the Base row instead."""
    s = (ROOT / path).read_text(encoding="utf-8")
    j = json.loads(s[s.index("{"):s.rindex("}") + 1])
    sizes = [len(d["levels"]) for d in j["dials"]]
    i = 0
    for k, l in zip(sizes, j["named"]["Base"]):
        i = i * k + l
    lines = [s.splitlines()[0],
             "window.__GRID__ = {",
             f'  "dials": [{", ".join(d["key"] for d in j["dials"])}],   // levels per dial: {sizes}',
             f'  "keys": {json.dumps(j["keys"])},',
             f'  "named": {json.dumps(j["named"])},   // 0-based level index per dial',
             f'  "facts": {json.dumps(j["facts"])},',
             f'  "snap": [ ... {len(j["snap"])} rows, one per dial combination ... ]',
             "};",
             "",
             f"// snap[{i}] is the Base row (first dial slowest, as itertools.product):",
             f"// {json.dumps(dict(zip(j['keys'], j['snap'][i])))}"]
    return "\n".join(lines), i, dict(zip(j["keys"], j["snap"][i]))


def main():
    base_snip, base_idx, base_row = grid_snippet("bsz-analysis/site/explorer/grid.js")
    main_est = base_row["main_estimate"]

    layers = [
        dict(
            n=1, name="The number on the page",
            what=("This layer is the explorer page's own JavaScript, not R or Python; the R and "
                  "Python twins start at layer 3. The page reads the precomputed grid, finds the "
                  "row for the dial setting on screen (the Base scenario when nothing is touched), "
                  "and prints the main estimate as the headline number in the page header, with its "
                  "definition under it. Footnote 1 says the main estimate is this OPA's choice, "
                  "not the authors'."),
            inputs="G = window.__GRID__ from grid.js (G.snap holds every setting) and the six dial positions, Base = [2, 2, 1, 1, 0, 0]",
            inputs_from=[dict(layer="bsz-2", what="G = window.__GRID__: the precomputed grid; G.snap has one row per dial setting")],
            other_inputs="the six dial positions on screen, Base = [2, 2, 1, 1, 0, 0]",
            outputs=f"the text 'main estimate ${main_est:.1f}B' and the nine-row outcome table",
            method_ref="Display only. The definition under the headline number (lines 219-225) is the method; footnote 1 says it is this OPA's choice, not the authors'.",
            method_status="plumbing",
            r=loc("bsz-analysis/site/explorer/index.html", "render(): pick the row, print the main estimate", [485, 503], language="javascript"),
            py=None,
            targets=None,
        ),
        dict(
            n=2, name="The grid file the page reads",
            what=("A generated JavaScript data file, not R or Python: the R pipeline writes the "
                  "committed copy and the Python twin writes its own under export/py/. It holds "
                  "one object, window.__GRID__. Its snap field holds all "
                  "the grid estimates: one entry per combination of the six dials (6 x 5 x 4 x 4 "
                  "x 2 x 2 = 1,920 entries), each a list of nine numbers in the order of keys, "
                  "rounded to six decimals. named gives the position of the four Table 5 rows "
                  "(Base = snap[788]). The page does no arithmetic beyond picking an entry."),
            inputs="nothing at run time; the file is written by the next layer",
            inputs_from=[dict(layer="bsz-3", what="the text of grid.js, written as raw UTF-8 bytes")],
            other_inputs="",
            outputs=f"row {base_idx} (Base): {json.dumps(base_row)}",
            method_ref="Plumbing. The R-written file is the committed one; the Python twin writes the same text to export/py/site/grid.js, and test-site.R checks the committed file is byte-identical to the exporter's output.",
            method_status="plumbing",
            r=dict(path="bsz-analysis/site/explorer/grid.js", symbol="window.__GRID__", lines=[1, 2],
                   language="javascript", url=f"{REPO}/blob/{COMMIT}/bsz-analysis/site/explorer/grid.js",
                   snippet=base_snip),
            py=dict(path="bsz-analysis/export/py/site/grid.js", symbol="window.__GRID__", lines=[1, 2],
                    language="javascript", url=None,
                    snippet="(gitignored; written by py/run_export.py, same shape as the R file)"),
            targets="_targets.R:154 site_grid_js",
        ),
        dict(
            n=3, name="Writing the grid file",
            what=("Turns the grid table into the JavaScript text: the dial definitions, the "
                  "outcome keys, the four named Table 5 rows as 0-based indices, a few facts "
                  "(W0, n0, C, the discount rate and horizon), and the rounded rows. The nine "
                  "outcomes per row are the main estimate first, then the eight rows of the "
                  "explorer's outcome table (the folded table under the bars). The series of "
                  "the main estimate alone is column 0 of snap: grid$main_estimate in R, "
                  "grid['main_estimate'] in Python."),
            inputs="the grid table (1,920 rows) and the fixed inputs list",
            inputs_from=[dict(layer="bsz-4", what="the grid table: 1,920 rows, one per dial combination, nine outcomes each"),
                         dict(layer="bsz-6", what="inp: the fixed inputs list (W0, n0, C, the Pareto summary, the leavers)")],
            other_inputs="the dial definitions and outcome labels (site_dials(), site_outcomes())",
            outputs="the text of grid.js, written as raw UTF-8 bytes",
            method_ref="Plumbing.",
            method_status="plumbing",
            r=loc("bsz-analysis/R/site_exports.R", "site_grid_js_text(), write_site_grid_js()", [160, 196]),
            py=loc("bsz-analysis/py/site_exports.py", "site_grid_js_text()", [181, 205]),
            targets="_targets.R:154 site_grid_js",
        ),
        dict(
            n=4, name="Building the grid and the present value",
            what=("The key function here is score_tab5_cell(), defined in layer 5: it does all "
                  "the estimating, and this layer only drives it. The loop goes over every dial "
                  "combination, calls score_tab5_cell() at each, "
                  "discounts the yearly income tax lost to leavers over 5 years at 3% a year "
                  "(factor 4.5797), and adds the three pieces: wealth tax + extra income tax "
                  "from sales + the (negative) present value of the loss. That sum is the "
                  "main estimate."),
            inputs="the fixed inputs list and the six dials' level values",
            inputs_from=[dict(layer="bsz-5", what="seven outcomes for one dial setting: n, wealth, taxable wealth, avoidance rate, revenue, extra income tax, yearly loss"),
                         dict(layer="bsz-6", what="inp: the fixed inputs list (W0, n0, C, the Pareto summary, the leavers)")],
            other_inputs="the six dials' level values; the discount rate 3% and horizon 5 years (site_pv_rate, site_pv_years)",
            outputs=(f"one row per combination; Base: 103.815 + 3.681972 + (-0.153068 x 4.5797) "
                     f"= {main_est:.6f}"),
            method_ref=("The sum is this OPA's definition (comment at lines 52-57; the deck). BSZ "
                        "PDF p.27 gives the 5-year horizon; the 3% rate is the middle of the "
                        "JR report's 1.5-4.5% range. BSZ give no rate."),
            method_status="opa_definition",
            r=loc("bsz-analysis/R/site_exports.R", "site_pv_factor(), build_site_grid()", [52, 94]),
            py=loc("bsz-analysis/py/site_exports.py", "site_pv_factor(), build_site_grid()", [17, 97]),
            targets="_targets.R:144 site_grid",
        ),
        dict(
            n=5, name="The estimating function",
            what=("One setting of every guesswork input in, seven outcomes out. Taxable wealth "
                  "= (1 - avoidance) x W0; revenue = 5% of that; extra income tax = revenue x "
                  "share sold x gain share x 13.3%; yearly loss = -(avoidance x mobility share) "
                  "x C. The Pareto and leaver switches add their rows' terms."),
            inputs="inp (W0 = 2307, C = 3.0614, ...) and the dials: avoidance 0.10, mobility 0.50, sell 1/3, pareto off, leavers off",
            inputs_from=[dict(layer="bsz-6", what="inp: the fixed inputs list (W0, n0, C, the Pareto summary, the leavers)")],
            other_inputs="the dials: avoidance 0.10, mobility 0.50, avoidance_small 0.20, sell 1/3, pareto off, leavers off; and the defaults tax_rate 0.05, phasein_rate 0.025, gains_share 0.80, ca_cg_rate 0.133",
            outputs="Base: taxable 2076.3, revenue 103.815, extra 3.681972, yearly loss -0.153068",
            method_ref=("Tab5!B6:H6 of the workbook and BSZ PDF p.24. Matches: test-compute.R "
                        "asserts the R row equals Tab5!B6:H9 to 1e-4, and the Python twin equals "
                        "the R export."),
            method_status="matches",
            r=loc("bsz-analysis/R/compute_tab5.R", "score_tab5_cell()", [80, 110]),
            py=loc("bsz-analysis/py/compute_tab5.py", "score_tab5_cell()", [72, 95]),
            targets="_targets.R:53 tab5_r (the reproduction); _targets.R:144 site_grid (the explorer)",
        ),
        dict(
            n=6, name="The fixed inputs the function needs",
            what=("Gathers everything the estimating function reads that is not a dial: W0 "
                  "and n0 from the constants, C (the 2019-2025 average income tax of CA "
                  "billionaires) from Table 2, the residual tax rate per dollar of wealth, the "
                  "Pareto summary, and the seven named leavers with their yearly tax."),
            inputs="three pipeline targets: pareto_missing_r, tab2, tab3",
            inputs_from=[dict(layer="bsz-7", what="the constants: W0 = 2307, n0 = 250, the seven leavers' wealth and private-company shares"),
                         dict(layer="bsz-8", what="tab2 and tab3: the workbook's Table 2 and Table 3 as typed tables")],
            other_inputs="pareto_missing_r, the Pareto fit of the missed billionaires (another pipeline target, not on this chain)",
            outputs="a named list; for the Base row only W0 = 2307, n0 = 250 and C = 3.061364 matter",
            method_ref="Tab2!C14 (C), Tab3 (the top 4's own tax), Tab5 rows 18-29 (leavers). The residual rate is Tab5!F18/B18.",
            method_status="matches",
            r=loc("bsz-analysis/R/compute_tab5.R", "tab5_scoring_inputs()", [26, 76]),
            py=loc("bsz-analysis/py/compute_tab5.py", "tab5_scoring_inputs()", [17, 70]),
            targets="_targets.R:143 site_scoring_inputs",
        ),
        dict(
            n=7, name="Constants and labelled inputs",
            what=("The handful of numbers the authors typed into the workbook from Forbes, kept "
                  "in code because they differ between the May and August workbooks: W0 = "
                  "2307, n0 = 250, and the seven leavers' wealth. site/data/inputs.csv labels "
                  "every input of the estimate with its origin (data, research, guesswork)."),
            inputs="the BSZ_VINTAGE environment variable (default august)",
            inputs_from=[],
            other_inputs="the BSZ_VINTAGE environment variable (default august)",
            outputs="the literals; August: baseline_wealth 2307, baseline_n 250",
            method_ref=("Tab5!B6:C6 (Forbes real-time list, 1 Jul 2026). Caveat: retyped "
                        "literals, checked only indirectly through the Tab5 test, not read from "
                        "the cells."),
            method_status="matches_with_caveat",
            r=loc("bsz-analysis/R/vintage.R", ".TAB5_CONST, tab5_const()", [115, 147]),
            py=loc("bsz-analysis/py/vintage.py", "TAB5_CONST, tab5_const()", [85, 112]),
            targets=None,
        ),
        dict(
            n=8, name="The raw source: the workbook",
            what=("The public workbook BSZ_MainTablesFigures.xlsx (August 2026; SHA-256 in "
                  "DATA-SOURCES.csv), read sheet by sheet into tables. The chain stops here: "
                  "the Forbes snapshot behind Tab5!B6:C6 is not in the repo, and the "
                  "confidential author bundle only feeds the data sheets, not this number."),
            inputs="original-materials/BSZ_MainTablesFigures.xlsx (not redistributed; download command on the materials page)",
            inputs_from=[],
            other_inputs="original-materials/BSZ_MainTablesFigures.xlsx (not redistributed; download command on the materials page)",
            outputs="tab2 (8 rows) and tab3 (11 rows) as typed tables",
            method_ref="Tab2 rows 7-14, Tab3 rows 6-16. Plumbing: readxl / openpyxl with fixed column names.",
            method_status="plumbing",
            r=loc("bsz-analysis/R/data_sheets.R", "extract_tab2(), extract_tab3()", [118, 141]),
            py=loc("bsz-analysis/py/data_sheets.py", "extract_tab2(), extract_tab3()", [120, 134]),
            targets="_targets.R:12 xlsx_path; :26 tab2; :27 tab3",
        ),
    ]

    # Names to colour in the code: for each handoff (receiving layer, source layer), the
    # identifiers in the receiver's code and in the source's code. Both twins use the same names.
    HANDOFF_TOKENS = {
        (1, "bsz-2"): dict(tokens=["G", "snap"], source_tokens=["__GRID__", "snap"]),
        (2, "bsz-3"): dict(tokens=["__GRID__"], source_tokens=["site_grid_js_text", "json", "payload", "_json"]),
        (3, "bsz-4"): dict(tokens=["grid"], source_tokens=["rows", "build_site_grid"]),
        (3, "bsz-6"): dict(tokens=["inp"], source_tokens=["tab5_scoring_inputs"]),
        (4, "bsz-5"): dict(tokens=["out", "score_tab5_cell"], source_tokens=["score_tab5_cell", "n_billionaires", "wealth", "taxable_wealth", "avoidance_rate", "wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss"]),
        (4, "bsz-6"): dict(tokens=["inp"], source_tokens=["tab5_scoring_inputs"]),
        (5, "bsz-6"): dict(tokens=["inp"], source_tokens=["tab5_scoring_inputs"]),
        (6, "bsz-7"): dict(tokens=["tab5_const", "W0", "n0"], source_tokens=[".TAB5_CONST", "TAB5_CONST", "tab5_const", "baseline_n", "baseline_wealth"]),
        (6, "bsz-8"): dict(tokens=["tab2", "tab3"], source_tokens=["extract_tab2", "extract_tab3"]),
    }
    for L in layers:
        for x in L["inputs_from"]:
            x.update(HANDOFF_TOKENS.get((L["n"], x["layer"]), dict(tokens=[], source_tokens=[])))

    # A few lines to check each layer by hand in Positron, after the chain's environment
    # code has been run (see ENVIRONMENT below). Keys: r, py, or js (browser console).
    INTERACTIVE = {
        1: dict(js="""// In the browser: open the BSZ explorer, then paste this in the developer console.
G = window.__GRID__
i = 788                                   // the Base row (named.Base = [2, 2, 1, 1, 0, 0])
Object.fromEntries(G.keys.map((k, j) => [k, G.snap[i][j]]))
G.snap.length                             // 1920 settings"""),
        2: dict(r="""# Layer 2: read the committed grid.js back and look at the Base row.
txt <- readLines("site/explorer/grid.js")[2]
G   <- jsonlite::fromJSON(sub(";$", "", sub("^window.__GRID__ = ", "", txt)))
G$keys
G$named$Base                 # 0-based level per dial
dim(G$snap)                  # 1920 settings x 9 outcomes
setNames(G$snap[789, ], G$keys)   # row 788 (0-based) is the Base scenario""",
                py="""# Layer 2: read the committed grid.js back and look at the Base row.
import json
s = open("site/explorer/grid.js").read()
G = json.loads(s[s.index("{"):s.rindex("}") + 1])
G["keys"]
G["named"]["Base"]           # 0-based level per dial
len(G["snap"])               # 1920 settings
dict(zip(G["keys"], G["snap"][788]))   # the Base scenario"""),
        3: dict(r="""# Layer 3: the text that becomes grid.js, from the grid table and the fixed inputs.
txt <- site_grid_js_text(grid, inp)
cat(substr(txt, 1, 400))
nchar(txt)
identical(txt, paste0(readLines("site/explorer/grid.js"), "\n", collapse = ""))  # matches the committed file""",
                py="""# Layer 3: the text that becomes grid.js, from the grid table and the fixed inputs.
txt = site_grid_js_text(grid, inp)
print(txt[:400])
len(txt)
txt == open("site/explorer/grid.js").read()   # matches the committed (R-written) file"""),
        4: dict(r="""# Layer 4: the grid, and the main estimate assembled from its three pieces.
grid <- build_site_grid(inp)
dim(grid)                                  # 1920 rows
site_pv_factor()                           # 4.5797: 5 years at 3%
base <- grid[grid$cell == 789, ]           # the Base scenario
base[, c("wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss", "main_estimate")]
with(base, wealth_tax_revenue + extra_ca_inctax_sales + annual_ca_inctax_loss * site_pv_factor())""",
                py="""# Layer 4: the grid, and the main estimate assembled from its three pieces.
grid = build_site_grid(inp)
grid.shape                                 # (1920, 25)
site_pv_factor()                           # 4.5797: 5 years at 3%
base = grid[grid["cell"] == 789].iloc[0]   # the Base scenario
base[["wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss", "main_estimate"]]
base["wealth_tax_revenue"] + base["extra_ca_inctax_sales"] + base["annual_ca_inctax_loss"] * site_pv_factor()"""),
        5: dict(r="""# Layer 5: the estimating function at the Base setting, then with one dial moved.
score_tab5_cell(inp)                              # revenue 103.815, extra 3.682, yearly loss -0.153
score_tab5_cell(inp, avoidance = 0.20)            # more avoidance: less revenue, more leaver loss
score_tab5_cell(inp, pareto = TRUE, leavers = TRUE)   # Table 5 row 4
0.05 * (1 - 0.10) * inp$W0                         # the revenue line by hand""",
                py="""# Layer 5: the estimating function at the Base setting, then with one dial moved.
score_tab5_cell(inp)                              # revenue 103.815, extra 3.682, yearly loss -0.153
score_tab5_cell(inp, avoidance=0.20)              # more avoidance: less revenue, more leaver loss
score_tab5_cell(inp, pareto=True, leavers=True)   # Table 5 row 4
0.05 * (1 - 0.10) * inp["W0"]                     # the revenue line by hand"""),
        6: dict(r="""# Layer 6: the fixed inputs list, built from the pipeline's tables.
inp <- tab5_scoring_inputs(pareto_missing_r, tab2, tab3)
names(inp)
inp[c("W0", "n0", "C", "resid_rate", "W_pre", "leaver_loss")]
inp$leavers
tab2[grepl("average", tab2$year), c("year", "ca_inctax_estimated")]   # where C comes from""",
                py="""# Layer 6: the fixed inputs list, built from the pipeline's tables.
inp = tab5_scoring_inputs(pareto_missing_r, tab2, tab3)
list(inp)
{k: inp[k] for k in ("W0", "n0", "C", "resid_rate", "W_pre", "leaver_loss")}
inp["leavers"]
tab2[tab2["year"].str.contains("average")][["year", "ca_inctax_estimated"]]   # where C comes from"""),
        7: dict(r="""# Layer 7: the constants that differ between the two workbooks.
bsz_vintage()
tab5_const("baseline_wealth"); tab5_const("baseline_n")
str(.TAB5_CONST$august)
str(.TAB5_CONST$may)
read.csv("site/data/inputs.csv")[, c("symbol", "input", "value", "origin")]""",
                py="""# Layer 7: the constants that differ between the two workbooks.
bsz_vintage()
tab5_const("baseline_wealth"), tab5_const("baseline_n")
TAB5_CONST["august"]
TAB5_CONST["may"]
import pandas as pd; pd.read_csv("site/data/inputs.csv")[["symbol", "input", "value", "origin"]]"""),
        8: dict(r="""# Layer 8: the workbook and the two sheets this chain reads.
xlsx_path_default()
tab2 <- extract_tab2(); tab2
tab3 <- extract_tab3(); tab3
readxl::read_excel(xlsx_path_default(), sheet = "Tab5", range = "A5:H9")   # the printed Table 5 rows""",
                py="""# Layer 8: the workbook and the two sheets this chain reads.
xlsx_path_default()
tab2 = extract_tab2(); tab2
tab3 = extract_tab3(); tab3
import pandas as pd; pd.read_excel(xlsx_path_default(), sheet_name="Tab5", header=None, skiprows=4, nrows=5, usecols="A:H")"""),
    }
    for L in layers:
        L["interactive"] = INTERACTIVE[L["n"]]

    ENVIRONMENT = dict(
        r=r"""# Environment for the BSZ chain, R. In Positron open the opa-prop40 folder, then run this once.
# Needs the pipeline run once (Rscript -e 'targets::tar_make()' in bsz-analysis/) and the workbook in place.
if (basename(getwd()) != "bsz-analysis") setwd("bsz-analysis")
library(targets)
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))   # every function on the chain
tab2 <- tar_read(tab2); tab3 <- tar_read(tab3)                  # layer 8: the workbook's tables
pareto_missing_r <- tar_read(pareto_missing_r)                   # the Pareto fit (off the chain)
inp  <- tar_read(site_scoring_inputs)                            # layer 6: the fixed inputs list
grid <- tar_read(site_grid)                                      # layer 4: the grid table
cat("ready:", nrow(grid), "grid rows; W0 =", inp$W0, "\n")""",
        py="""# Environment for the BSZ chain, Python. In Positron open the opa-prop40 folder, then run this once.
# Needs the workbook in place (same as R); nothing precomputed is required.
import os, sys
if os.path.basename(os.getcwd()) != "bsz-analysis": os.chdir("bsz-analysis")
sys.path.insert(0, "py")
from data_sheets import extract_tab2, extract_tab3, extract_pareto_missing      # layer 8
from ingest_excel import xlsx_path_default
from vintage import TAB5_CONST, tab5_const, bsz_vintage                          # layer 7
from compute_pareto import compute_pareto_missing
from compute_tab5 import tab5_scoring_inputs, score_tab5_cell, compute_tab5      # layers 6, 5
from site_exports import build_site_grid, site_pv_factor, site_grid_js_text      # layers 4, 3
tab2, tab3 = extract_tab2(), extract_tab3()
pareto_missing_r = compute_pareto_missing(extract_pareto_missing())
inp = tab5_scoring_inputs(pareto_missing_r, tab2, tab3)
grid = build_site_grid(inp)
print("ready:", len(grid), "grid rows; W0 =", inp["W0"])""",
    )

    # keep the user's fields from a previous seed
    old = {}
    if OUT.exists():
        for L in json.loads(OUT.read_text()).get("layers", []):
            old[L["id"]] = L
    today = date.today().isoformat()
    for L in layers:
        L["id"] = f"bsz-{L['n']}"
        prev = old.get(L["id"], {})
        L["state"] = prev.get("state", "not_reviewed")
        L["understanding"] = prev.get("understanding", "")
        L["missing"] = prev.get("missing", "")
        L["feedback"] = prev.get("feedback", [])
        L["updated"] = prev.get("updated", today)

    chain = {
        "opa": "bsz",
        "title": "BSZ: the main estimate",
        "headline": {
            "label": "Main estimate, Base scenario",
            "value": f"${main_est:.1f}B",
            "computed": main_est,
            "definition": ("wealth tax + extra income tax from selling assets - income tax lost "
                           "to leavers (present value, 5 years at 3%)"),
            "where": "https://fhoces.github.io/opa-prop40/bsz-analysis/site/explorer/",
        },
        "commit": COMMIT,
        "seeded": today,
        "verified_by": ("python3: read grid.js, Base row index 788, main_estimate = "
                        "wealth_tax_revenue + extra_ca_inctax_sales + annual_ca_inctax_loss "
                        "x (1 - 1.03^-5)/0.03 = 106.795965"),
        "runs_for_a_stranger": ("AUDIT.md step 8, level 2: .github/workflows/bsz-ci.yml rebuilds "
                                "the pipeline on a clean runner; no one-click (Binder) yet."),
        "environment": ENVIRONMENT,
        "layers": layers,
    }
    OUT.write_text(json.dumps(chain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(layers)} layers at {COMMIT}, main estimate {main_est}")


if __name__ == "__main__":
    sys.exit(main())
