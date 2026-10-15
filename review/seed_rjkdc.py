#!/usr/bin/env python3
"""Seed review/rjkdc.json: the chain of code behind the JR main estimate (-$38.9B).

The main estimate is the NBER September 2026 mean net present value (Jaros and Rauh, NBER
chapter c15504, PDF p.1 and p.35), printed -38.9; the pipeline's seeded rerun gives -38.886.
The layers are written by hand below, top (the number on the page) to bottom (the authors'
pinned public repository). Snippets are cut from the files at the line ranges given, so
re-running this script after a code edit refreshes them (check the ranges first). The user's
fields (state, understanding, missing, feedback) are kept from an existing rjkdc.json.

Run from the repo root:  python3 review/seed_rjkdc.py
"""
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "review" / "rjkdc.json"
REPO = "https://github.com/fhoces/opa-prop40"
SIDE = "rjkdc-analysis"
RAUH_SHA = "25e84ddbb67fe0293a64cd9108ed4d35d8ae37ab"
RAUH_URL = f"https://github.com/bjaros20/wealth_tax/blob/{RAUH_SHA}"

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


def rauh_loc(relpath, symbol, lines):
    """A location in the authors' public repository at the pinned SHA (read from the local clone)."""
    import os
    sys.path.insert(0, str(ROOT / SIDE / "py"))
    from rauh_repo import DEFAULT_RAUH_REPO_DIR       # the same default both twins use
    base = Path(os.environ.get("RAUH_REPO_DIR", ROOT / SIDE / DEFAULT_RAUH_REPO_DIR))
    text = (base / relpath).read_text(encoding="utf-8").splitlines()
    a, b = lines
    return {"path": f"bjaros20/wealth_tax@25e84dd/{relpath}", "symbol": symbol, "lines": [a, b],
            "language": "r", "url": f"{RAUH_URL}/{relpath}#L{a}-L{b}",
            "snippet": "\n".join(text[a - 1:b])}


def grid_parts():
    s = (ROOT / SIDE / "site" / "explorer" / "grid.js").read_text(encoding="utf-8")
    j = json.loads(s[s.index("{"):s.rindex("}") + 1])
    sizes = [len(d["levels"]) for d in j["dials"]]
    i = 0
    for k, l in zip(sizes, j["named"]["nber"]):
        i = i * k + l
    pref = {p["key"]: p for p in j["preferred"]}
    return j, i, pref


def headlines():
    import csv
    with open(ROOT / SIDE / "site" / "data" / "headlines.csv", newline="") as f:
        return {(r["version"], r["quantity"]): r for r in csv.DictReader(f)}


def main():
    j, nber_idx, pref = grid_parts()
    hl = headlines()
    nber = pref["nber"]
    mc_row = hl[("nber", "mc_mean_npv")]
    exact = float(hl[("nber", "analytic_mean_npv")]["reproduced"])
    mc_mean = float(mc_row["reproduced"])
    pv_lost = float(hl[("nber", "pv_lost")]["reproduced"])
    e_wt = float(hl[("nber", "mc_expected_revenue")]["reproduced"])
    printed = float(mc_row["printed"])
    snap = dict(zip(["mean_npv", "pct_negative", "wt_collected", "pv_lost"], j["snap"][nber_idx]))

    grid_snip = "\n".join([
        (ROOT / SIDE / "site" / "explorer" / "grid.js").read_text(encoding="utf-8").splitlines()[0],
        "   (targets: site_grid_js) ... */",
        "window.__GRID__ = {",
        f'  "dials": [{", ".join(d["key"] for d in j["dials"])}],   // 3 levels each: 3^7 = {len(j["snap"])} settings',
        f'  "outcomes": {json.dumps(j["outcomes"])},',
        f'  "named": {json.dumps(j["named"])},   // 0-based level index per dial',
        '  "preferred": [',
        f'    {json.dumps(pref["ssrn"])},',
        f'    {json.dumps(nber)}',
        '  ],',
        f'  "snap": [ ... {len(j["snap"])} rows ... ]   // snap[{nber_idx}] = {json.dumps(j["snap"][nber_idx])} (the NBER setting)',
        "};",
        "",
        "// site/data/headlines.csv, the row the number comes from:",
    ] + ["// " + l for l in (ROOT / SIDE / "site" / "data" / "headlines.csv").read_text(encoding="utf-8").splitlines()
         if l.startswith('"version"') or l.startswith('"nber","mc_mean_npv"')])

    layers = [
        dict(
            n=1, name="The number on the page",
            what=("This layer is the pages' own JavaScript, not R or Python; the R code starts at "
                  "layer 3. The overview page reads the explorer's grid file and prints the NBER "
                  "entry of its preferred list as the headline: the printed mean NPV, -38.9, as "
                  "'-$38.9B'. The explorer does the same when its dials sit at the NBER setting; at "
                  "any other setting it prints the grid's exact expectation for that setting "
                  "instead, and a small line under the number says which of the two it shows."),
            inputs="G = window.__GRID__ from grid.js: G.preferred (the authors' two settings) and G.snap (every setting)",
            inputs_from=[dict(layer="rjkdc-2", what="G = window.__GRID__: G.preferred holds the printed and rerun means of the two versions")],
            other_inputs="the dial positions on screen; the page opens on the NBER setting [0, 2, 0, 0, 0, 1, 0]",
            outputs=f"the text '−${abs(nber['printed_npv']):.1f}B' under 'Main estimate, NBER September 2026'",
            method_ref=("Display only. The definition under the number is the method: NPV = WT - f.C/r, "
                        "averaged over the authors' Monte Carlo draws. Footnote 1 says it is the "
                        "authors' own headline (NBER PDF p.1)."),
            method_status="plumbing",
            r=loc(f"{SIDE}/site/index.html", "the headline block and its script", [256, 283], language="html"),
            py=None,
            targets=None,
        ),
        dict(
            n=2, name="The data files the page reads",
            what=("Two generated files. grid.js is one JavaScript object, window.__GRID__: the seven "
                  "dials, the four outcomes, the two named settings, a preferred list with each "
                  "version's printed numbers and the seeded rerun, and snap, one row of four outcomes "
                  "for each of the 2,187 dial combinations. site/data/headlines.csv is the table the "
                  "preferred list is copied from: one row per printed number, with the reproduced "
                  "value beside it."),
            inputs="nothing at run time; both files are written by the next two layers",
            inputs_from=[dict(layer="rjkdc-3", what="the text of grid.js"),
                         dict(layer="rjkdc-4", what="headlines.csv, one row per printed number of either version")],
            other_inputs="",
            outputs=(f"preferred nber: printed_npv {nber['printed_npv']}, mc_npv {nber['mc_npv']}; "
                     f"headlines.csv nber mc_mean_npv reproduced {mc_mean}; snap[{nber_idx}] mean_npv {snap['mean_npv']}"),
            method_ref=("Plumbing. test-site.R regenerates both files and checks the committed copies "
                        "are identical to the exporter's output."),
            method_status="plumbing",
            r=dict(path=f"{SIDE}/site/explorer/grid.js", symbol="window.__GRID__; site/data/headlines.csv", lines=[1, 4],
                   language="javascript", url=f"{REPO}/blob/{COMMIT}/{SIDE}/site/explorer/grid.js",
                   snippet=grid_snip),
            py=None,
            targets="_targets.R:73 site_grid_js; :70 site_headlines_csv",
        ),
        dict(
            n=3, name="Writing the grid file",
            what=("Turns the grid table and the headline table into the text of grid.js. The "
                  "preferred list is built here: for each version it copies the printed mean, page "
                  "and share negative from the headline table, and the seeded rerun's mean rounded "
                  "to three decimals (mc_npv = -38.886). The snap rows are the grid's four outcomes "
                  "rounded to three decimals. No Python twin writes this file."),
            inputs="the grid table (2,187 rows), the revenue chain (for the dial labels) and the headline table",
            inputs_from=[dict(layer="rjkdc-4", what="site_headlines: the headline table"),
                         dict(layer="rjkdc-6", what="site_grid: one row per dial combination, the exact expectation in mean_npv")],
            other_inputs="the dial definitions and the two named settings (site_dials(), site_named())",
            outputs="the text of grid.js, written to site/explorer/grid.js",
            method_ref="Plumbing.",
            method_status="plumbing",
            r=loc(f"{SIDE}/R/site.R", "site_grid_payload(), write_site_grid_js()", [219, 261]),
            py=None,
            targets="_targets.R:73 site_grid_js",
        ),
        dict(
            n=4, name="The headline table",
            what=("One row per number either paper prints, beside the pipeline's value for it. The "
                  "NBER mean NPV row takes the printed -38.9 (typed from PDF p.1 and p.35, with "
                  "its page), the seeded Monte Carlo's mean (layer 5) as 'reproduced', and the "
                  "grid's exact expectation for the NBER setting (layer 6) as 'grid_exact'. The "
                  "Python twin builds the same rows in export/py/outputs.csv."),
            inputs="the two Monte Carlo summaries, the two exact means, the grid, the revenue chain and the NBER collectible revenue",
            inputs_from=[dict(layer="rjkdc-5", what="npv_mc_nber_summary: the seeded run's mean, median, SD and share negative"),
                         dict(layer="rjkdc-6", what="npv_mc_nber_analytic_mean and the grid's NBER cell: the exact expectation")],
            other_inputs="the printed values and pages, typed in this function (checked by test-site.R and test-npv-mc.R)",
            outputs=f"nber, mc_mean_npv: printed {printed}, reproduced {mc_mean}, grid_exact {exact}",
            method_ref=("The printed values are transcriptions (NBER PDF p.1 and p.35); every other "
                        "column is computed. test-npv-mc.R checks the reproduced mean against the "
                        "printed one within four Monte Carlo standard errors."),
            method_status="matches",
            r=loc(f"{SIDE}/R/site.R", "compute_site_headlines()", [188, 216]),
            py=loc(f"{SIDE}/py/run_export.py", "build_outputs()", [115, 148]),
            targets="_targets.R:66 site_headlines",
        ),
        dict(
            n=5, name="The seeded Monte Carlo (the printed number)",
            what=("The authors' NBER script, ported line by line. It sets the seed 2026, draws four "
                  "inputs 100,000 times in a fixed order (revenue WT on [0, 72], the departure share "
                  "f on [0.30, 0.60], the annual income tax C on [3.3, 5.8], the discount rate on "
                  "[0.015, 0.045]), computes NPV = WT - f.C/r for each draw and averages. Because R's "
                  "random stream and the draw order are the authors', the mean is theirs to machine "
                  "precision: -38.886, printed -38.9. This is the last layer that computes the "
                  "headline. The Python twin runs the same algorithm on numpy's random stream, so "
                  "its mean differs within Monte Carlo error."),
            inputs="the draw ranges, as the function's defaults",
            inputs_from=[dict(layer="rjkdc-7", what="the draw ranges: WT 0 to 72, f 0.30 to 0.60, C 3.3 to 5.8, r 0.015 to 0.045")],
            other_inputs="seed 2026, n_sims 100,000",
            outputs=f"summary$mean = {mc_mean:.6f} (printed {printed}); median, SD and share negative beside it",
            method_ref=("NBER PDF p.35 (eq. 16) and the authors' NPV_dist_v8.R. Matches: "
                        "test-npv-mc.R runs the authors' script unmodified and checks every one of the "
                        "100,000 NPVs equals ours to 1e-9, and checks the mean against the printed "
                        "-38.9 within four Monte Carlo standard errors."),
            method_status="matches",
            r=loc(f"{SIDE}/R/npv_mc.R", "compute_npv_mc_nber(), npv_mc_summary()", [42, 72]),
            py=loc(f"{SIDE}/py/npv_mc.py", "compute_npv_mc_nber(), npv_mc_summary()", [24, 46]),
            targets="_targets.R:37 npv_mc_nber; :39 npv_mc_nber_summary",
        ),
        dict(
            n=6, name="The exact expectation (the explorer's cells)",
            what=("The four draws are independent, so the average NPV has a closed form: "
                  "E[WT] - E[f] x E[C] x E[1/r], with E[1/r] = ln(0.045/0.015)/0.03 = 36.62. At the "
                  "NBER ranges that is 36 - 0.45 x 4.55 x 36.62 = 36 - 74.98 = -38.98. The explorer's "
                  "2,187 cells all come from this function, so moving a dial needs no new random "
                  "draw. The headline itself is the seeded run (layer 5); this layer is the "
                  "cross-check beside it and the value the explorer shows away from the authors' "
                  "settings."),
            inputs="the same draw ranges as layer 5",
            inputs_from=[dict(layer="rjkdc-7", what="the draw ranges: WT 0 to 72, f 0.30 to 0.60, C 3.3 to 5.8, r 0.015 to 0.045")],
            other_inputs="f_spec = list(mode = 'uniform', lo = 0.30, hi = 0.60); q = 1 and g = 0 as coded",
            outputs=f"mean_npv = {exact:.6f}, wt_collected = {e_wt}, pv_lost = {pv_lost:.6f}",
            method_ref=("Expectation of a product of independent variables is the product of their "
                        "expectations; E[1/r] for r uniform on [a, b] is ln(b/a)/(b - a). test-site.R "
                        "checks the grid cell equals npv_mc_analytic_mean() to 1e-12 and a brute-force "
                        "Monte Carlo of 2 million draws at an off-preferred cell."),
            method_status="matches",
            r=loc(f"{SIDE}/R/npv_mc.R", "npv_e_inv_rate(), npv_expectation()", [82, 106]),
            py=loc(f"{SIDE}/py/npv_mc.py", "npv_mc_analytic_mean()", [49, 58]),
            targets="_targets.R:45 npv_mc_nber_analytic_mean; :65 site_grid",
        ),
        dict(
            n=7, name="The draw ranges and the revenue ceiling",
            what=("Where the four ranges come from. The top of the revenue draw, 72, is a literal in "
                  "the authors' script: revenue if the Act survives, after removing seven confirmed "
                  "departures. The pipeline rebuilds it from the NBER person-level file final.csv: "
                  "5% of each domestic billionaire's grown wealth, summed, minus the seven who left, "
                  "gives 72.05 (mismatch 4: 72 in the script, 72.06 in the README). The 0 bottom is "
                  "the Act struck down. The f, C and r ranges are the script's literals; C's ends "
                  "are the two income tax Monte Carlo bounds of Table 8."),
            inputs="final.csv from the authors' repository",
            inputs_from=[dict(layer="rjkdc-8", what="the authors' repository: NPV_dist_v8.R (the literals) and final.csv (240 rows)")],
            other_inputs="the C range 3.3 to 5.8 from Table 8 (target income_tax_table8, off this chain)",
            outputs="ceiling_recomputed = 72.051 ($B), 212 domestic rows, 7 removed departures",
            method_ref=("NBER PDF pp.22-23 and the NBER README. Matches with a caveat: the Monte "
                        "Carlo uses the script's 72, not the recomputed 72.05 (MISMATCHES.md 4); "
                        "test-nber-final.R checks both numbers."),
            method_status="matches_with_caveat",
            r=loc(f"{SIDE}/R/nber_final.R", "extract_nber_final(), compute_nber_ceiling()", [8, 52]),
            py=loc(f"{SIDE}/py/nber_final.py", "extract_nber_final(), compute_nber_ceiling()", [5, 40]),
            targets="_targets.R:31 nber_final_csv; :32 nber_final; :33 nber_ceiling",
        ),
        dict(
            n=8, name="The raw source: the authors' repository",
            what=("The authors' public, MIT-licensed repository github.com/bjaros20/wealth_tax, "
                  "pinned at commit 25e84dd and not redistributed here. The NBER script "
                  "NPV_dist_v8.R holds the draw ranges and the draw order that layer 5 copies; "
                  "final.csv holds the person-level wealth behind the 72. Both twins find the "
                  "repository through one resolver and the RAUH_REPO_DIR environment variable; the "
                  "CI workflow clones it at the pinned commit. The chain stops here."),
            inputs="RAUH_REPO_DIR (default: the gitignored local clone the README describes)",
            inputs_from=[],
            other_inputs="RAUH_REPO_DIR (default: the gitignored local clone the README describes)",
            outputs="NPV_dist_v8.R lines 14-31 (seed, ranges, draws, NPV); final.csv",
            method_ref=("Plumbing. Raw source at a pinned commit (DATA-SOURCES.csv gives its SHA-256 "
                        "hashes); .github/workflows/rjkdc-ci.yml checks out exactly that commit."),
            method_status="plumbing",
            r=rauh_loc("NBER_2026_litigation_weighted/NPV_data/NPV_dist_v8.R", "the authors' NBER Monte Carlo script", [14, 31]),
            py=loc(f"{SIDE}/py/rauh_repo.py", "rauh_repo_dir(), rauh_nber_final_csv()", [1, 25]),
            targets="_targets.R:31 nber_final_csv (R resolver: R/rauh_repo.R)",
        ),
    ]

    # Names to colour in the code: for each handoff (receiving layer, source layer), the
    # identifiers in the receiver's code and in the source's code.
    HANDOFF_TOKENS = {
        (1, "rjkdc-2"): dict(tokens=["G", "preferred", "printed_npv"], source_tokens=["__GRID__", "preferred", "printed_npv"]),
        (2, "rjkdc-3"): dict(tokens=["__GRID__", "preferred"], source_tokens=["write_site_grid_js", "site_grid_payload", "pref"]),
        (2, "rjkdc-4"): dict(tokens=["mc_mean_npv"], source_tokens=["compute_site_headlines", "mc_mean_npv"]),
        (3, "rjkdc-4"): dict(tokens=["site_headlines", "hl"], source_tokens=["compute_site_headlines"]),
        (3, "rjkdc-6"): dict(tokens=["site_grid"], source_tokens=["npv_expectation"]),
        (4, "rjkdc-5"): dict(tokens=["npv_mc_nber_summary"], source_tokens=["npv_mc_summary", "summary", "mean"]),
        (4, "rjkdc-6"): dict(tokens=["npv_mc_nber_analytic_mean", "site_grid"], source_tokens=["npv_expectation", "mean_npv"]),
        (5, "rjkdc-7"): dict(tokens=["wt_max", "wt_min", "f_min", "f_max", "c_min", "c_max", "rg_min", "rg_max"], source_tokens=["ceiling_recomputed", "compute_nber_ceiling"]),
        (6, "rjkdc-7"): dict(tokens=["wt_min", "wt_max", "c_min", "c_max", "rate_min", "rate_max"], source_tokens=["ceiling_recomputed", "compute_nber_ceiling"]),
        (7, "rjkdc-8"): dict(tokens=["path", "rauh_nber_final_csv"], source_tokens=["wt_max", "rauh_repo_dir", "rauh_nber_final_csv"]),
    }
    for L in layers:
        for x in L["inputs_from"]:
            x.update(HANDOFF_TOKENS.get((L["n"], x["layer"]), dict(tokens=[], source_tokens=[])))

    # A few lines to check each layer by hand in Positron, after the chain's environment
    # code has been run (see ENVIRONMENT below). Keys: r, py, or js (browser console).
    # Every snippet below was run end to end from the repo root on the commit this seeds.
    INTERACTIVE = {
        1: dict(js="""// In the browser: open the JR overview (or the explorer), then paste this in the developer console.
G = window.__GRID__
G.preferred.find(p => p.key === "nber")          // printed_npv -38.9, mc_npv -38.886
document.querySelector(".headline .value").textContent   // the number on the page
G.snap.length                                    // 2187 settings"""),
        2: dict(r=r"""# Layer 2: read the committed grid.js and headlines.csv back.
txt <- readLines("site/explorer/grid.js")[4]
G   <- jsonlite::fromJSON(sub(";$", "", sub("^window.__GRID__ = ", "", txt)))
G$preferred                                   # one row per version: printed and rerun means
G$named$nber                                  # 0-based level per dial
dim(G$snap)                                   # 2187 settings x 4 outcomes
hl_csv <- read.csv("site/data/headlines.csv")
hl_csv[hl_csv$version == "nber" & hl_csv$quantity == "mc_mean_npv", ]""",
                py=r"""# Layer 2: read the committed grid.js and headlines.csv back.
import json, pandas as pd
s = open("site/explorer/grid.js").read()
G = json.loads(s[s.index("{"):s.rindex("}") + 1])
G["preferred"]                                # one entry per version: printed and rerun means
G["named"]["nber"]                            # 0-based level per dial
len(G["snap"])                                # 2187 settings
hl_csv = pd.read_csv("site/data/headlines.csv")
hl_csv[(hl_csv.version == "nber") & (hl_csv.quantity == "mc_mean_npv")]"""),
        3: dict(r=r"""# Layer 3: the payload that becomes grid.js, then the file itself, rewritten to a temp path.
payload <- site_grid_payload(grid, rc, hl)
str(payload$preferred[[2]])                   # the NBER entry: printed_npv -38.9, mc_npv -38.886
tmp <- tempfile(fileext = ".js")
write_site_grid_js(grid, rc, hl, path = tmp)
identical(readLines(tmp), readLines("site/explorer/grid.js"))   # TRUE: matches the committed file"""),
        4: dict(r=r"""# Layer 4: the headline table, rebuilt from its inputs.
hl2 <- compute_site_headlines(grid, tar_read(npv_mc_ssrn_summary), tar_read(npv_mc_nber_summary),
                              tar_read(npv_mc_ssrn_analytic_mean), tar_read(npv_mc_nber_analytic_mean),
                              rc, tar_read(nber_collectible))
hl2[hl2$version == "nber", c("quantity", "printed", "reproduced", "grid_exact")]
identical(hl2, hl)                            # TRUE: same as the stored target""",
                py=r"""# Layer 4: the Python twin's export of the same numbers (written by py/run_export.py).
import pandas as pd
out = pd.read_csv("export/py/outputs.csv")
out[out.version == "nber"][["output_id", "value", "printed_value", "abs_diff"]]"""),
        5: dict(r=r"""# Layer 5: the seeded Monte Carlo. This returns the headline: mean -38.886, printed -38.9.
mcn <- compute_npv_mc_nber()
mcn$summary                                   # mean -38.886, median -35.26, sd 37.62, 85.2% negative
mean(mcn$draws$npv)
head(mcn$draws)                               # the first draws: wt, f, c_income, rg_discount, npv
with(mcn$draws[1, ], wt - f * c_income / rg_discount)   # one draw's NPV by hand""",
                py=r"""# Layer 5: the Python twin of the seeded Monte Carlo (numpy's random stream, not R's).
mcn = compute_npv_mc_nber()
mcn["summary"]                                # mean -39.14 on numpy's stream (R's stream gives -38.886)
se = mcn["summary"]["sd"] / mcn["summary"]["n"] ** 0.5
(mcn["summary"]["mean"] - npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode="nber", f_min=0.30, f_max=0.60)) / se   # gap to the exact mean, in standard errors"""),
        6: dict(r=r"""# Layer 6: the exact expectation, piece by piece.
npv_e_inv_rate(0.015, 0.045)                  # E[1/r] = ln(3)/0.03 = 36.62
0.45 * 4.55 * npv_e_inv_rate(0.015, 0.045)    # E[f] E[C] E[1/r] = 74.98, the loss
npv_expectation(0, 72, 3.3, 5.8, 0.015, 0.045, list(mode = "uniform", lo = 0.30, hi = 0.60))
npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode = "nber", f_min = 0.30, f_max = 0.60)
site_grid_cell(grid, as.list(site_named()$nber))   # the explorer's NBER cell: the same -38.98""",
                py=r"""# Layer 6: the exact expectation in the Python twin.
import math
math.log(0.045 / 0.015) / 0.03                # E[1/r] = 36.62
npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, f_mode="nber", f_min=0.30, f_max=0.60)   # -38.98
36 - 0.45 * 4.55 * math.log(3) / 0.03         # the same by hand"""),
        7: dict(r=r"""# Layer 7: the ceiling rebuilt from final.csv, beside the script's literal 72.
nfinal <- extract_nber_final()
table(nfinal$panel)                           # 212 domestic, 28 international
nc <- compute_nber_ceiling(nfinal)
nc[c("domestic_total_grown", "removed_departed_total", "ceiling_recomputed")]   # 100.91 - 28.85 = 72.05
nc$removed_names                              # the seven confirmed departures
unlist(formals(compute_npv_mc_nber)[c("wt_min", "wt_max", "f_min", "f_max", "c_min", "c_max", "rg_min", "rg_max")])""",
                py=r"""# Layer 7: the ceiling rebuilt from final.csv, beside the script's literal 72.
rows = extract_nber_final(rauh_nber_final_csv())
len(rows)                                     # 240 rows
nc = compute_nber_ceiling(rows)
{k: nc[k] for k in ("domestic_total_grown", "removed_departed_total", "ceiling_recomputed")}
nc["removed_names"]                           # the seven confirmed departures"""),
        8: dict(r=r"""# Layer 8: the authors' repository, pinned at 25e84dd.
rauh_repo_dir(); rauh_available()
system2("git", c("-C", rauh_repo_dir(), "rev-parse", "HEAD"), stdout = TRUE)   # 25e84ddb...
cat(readLines(rauh_npv_dist_v8_script())[14:31], sep = "\n")   # seed, ranges, draws, NPV
env <- run_author_script(rauh_npv_dist_v8_script())   # the authors' script, unmodified, in a scratch copy
mean(env$npv)                                 # -38.886, the same as layer 5""",
                py=r"""# Layer 8: the authors' repository, pinned at 25e84dd.
import subprocess
rauh_repo_dir(), rauh_available()
subprocess.run(["git", "-C", rauh_repo_dir(), "rev-parse", "HEAD"], capture_output=True, text=True).stdout
print("".join(open(rauh_path("NBER_2026_litigation_weighted", "NPV_data", "NPV_dist_v8.R")).readlines()[13:31]))"""),
    }
    for L in layers:
        L["interactive"] = INTERACTIVE[L["n"]]

    ENVIRONMENT = dict(
        r=r"""# Environment for the JR chain, R. In Positron open the opa-prop40 folder, then run this once.
# Needs the pipeline run once (Rscript -e 'targets::tar_make()' in rjkdc-analysis/) and the authors'
# repository (github.com/bjaros20/wealth_tax at 25e84dd) where RAUH_REPO_DIR points (README, "How to run").
if (basename(getwd()) != "rjkdc-analysis") setwd("rjkdc-analysis")
library(targets)
invisible(lapply(list.files("R", pattern = "\\.R$", full.names = TRUE), source))   # every function on the chain
Sys.setenv(RAUH_REPO_DIR = normalizePath(rauh_repo_dir()))       # absolute, so the scratch copy in layer 8 finds it
source("tests/testthat/helper-author-scripts.R")                 # run_author_script(), layer 8
rc   <- tar_read(revenue_chain)                                   # the dial labels need it
grid <- tar_read(site_grid)                                       # layer 6: the 2,187 exact cells
hl   <- tar_read(site_headlines)                                  # layer 4: the headline table
cat("ready:", nrow(grid), "grid rows; NBER mean as printed:",
    hl$printed[hl$version == "nber" & hl$quantity == "mc_mean_npv"], "\n")""",
        py=r"""# Environment for the JR chain, Python. In Positron open the opa-prop40 folder, then run this once.
# Needs the authors' repository where RAUH_REPO_DIR points (README, "How to run"); nothing precomputed.
import os, sys
if os.path.basename(os.getcwd()) != "rjkdc-analysis": os.chdir("rjkdc-analysis")
sys.path.insert(0, "py")
from rauh_repo import rauh_repo_dir, rauh_available, rauh_path, rauh_nber_final_csv   # layer 8
from nber_final import extract_nber_final, compute_nber_ceiling                        # layer 7
from npv_mc import compute_npv_mc_nber, npv_mc_summary, npv_mc_analytic_mean           # layers 5, 6
print("ready: authors' repository available:", rauh_available())""",
    )

    # keep the user's fields from a previous seed
    old = {}
    if OUT.exists():
        for L in json.loads(OUT.read_text()).get("layers", []):
            old[L["id"]] = L
    today = date.today().isoformat()
    for L in layers:
        L["id"] = f"rjkdc-{L['n']}"
        prev = old.get(L["id"], {})
        L["state"] = prev.get("state", "not_reviewed")
        L["understanding"] = prev.get("understanding", "")
        L["missing"] = prev.get("missing", "")
        L["feedback"] = prev.get("feedback", [])
        L["updated"] = prev.get("updated", today)

    chain = {
        "opa": "rjkdc",
        "title": "JR: the main estimate",
        "headline": {
            "label": "Main estimate, NBER September 2026",
            "value": f"−${abs(nber['printed_npv']):.1f}B",
            "computed": mc_mean,
            "definition": ("the one-time wealth tax revenue minus the present value of California "
                           "income tax lost for ever to billionaires who leave (NPV = WT - f.C / r), "
                           "averaged over the authors' Monte Carlo draws"),
            "where": "https://fhoces.github.io/opa-prop40/rjkdc-analysis/site/",
        },
        "commit": COMMIT,
        "seeded": today,
        "verified_by": ("Rscript, from rjkdc-analysis/ after sourcing R/: "
                        "compute_npv_mc_nber()$summary$mean = -38.886348 (printed -38.9, NBER PDF p.1); "
                        "the exact expectation npv_mc_analytic_mean(0, 72, 3.3, 5.8, 0.015, 0.045, "
                        "f_mode = 'nber', f_min = 0.30, f_max = 0.60) = -38.980289"),
        "runs_for_a_stranger": ("AUDIT.md step 8, level 2: .github/workflows/rjkdc-ci.yml clones the "
                                "authors' repository at 25e84dd and rebuilds R and Python on a clean "
                                "runner; no one-click (Binder) yet."),
        "environment": ENVIRONMENT,
        "layers": layers,
    }
    OUT.write_text(json.dumps(chain, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(layers)} layers at {COMMIT}, "
          f"headline {nber['printed_npv']} (seeded rerun {mc_mean}, exact {exact})")


if __name__ == "__main__":
    sys.exit(main())
