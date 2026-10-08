"""Python twin of R/site_exports.R: the data behind the public OPA pages
(the explorer grid, the inputs table, the leavers, Table 5 against the
printed paper, and grid.js).

Nothing here changes a reproduced number: the grid is score_tab5_cell() at
every combination of the dial levels, the same function compute_tab5() uses.
py/run_export.py writes these to export/py/site/; R writes them to site/.
"""
import itertools
import json
import math

import pandas as pd

from compute_tab5 import score_tab5_cell

SITE_PV_RATE = 0.03
SITE_PV_YEARS = 5


def site_pv_factor(r=SITE_PV_RATE, H=SITE_PV_YEARS):
    return (1 - (1 + r) ** (-H)) / r


def site_dials():
    return [
        dict(key="avoidance", label="Avoidance and evasion", sym="α", origin="guesswork",
             desc="Share of listed wealth that escapes the tax. GGSS p.4: \"a relatively small "
                  "avoidance rate of 10%\", argued from enforcement, not estimated.",
             levels=[0, 0.05, 0.10, 0.15, 0.20, 0.30], default=3, fmt="pct"),
        dict(key="mobility_share", label="Share of avoidance that is leaving", sym="m",
             origin="guesswork",
             desc="Only this part costs income tax. BSZ PDF p.24: \"If we assume that half of "
                  "the 10% avoidance takes the form of mobility\".",
             levels=[0, 0.25, 0.50, 0.75, 1], default=3, fmt="pct"),
        dict(key="avoidance_small", label="Avoidance by the less visible billionaires",
             sym="αₛ", origin="guesswork",
             desc="Applies only when the Pareto-missing billionaires are counted. BSZ PDF p.25: "
                  "\"Assuming a higher evasion rate of 20%\".",
             levels=[0.10, 0.20, 0.30, 0.50], default=2, fmt="pct"),
        dict(key="sell_share", label="Share of the tax paid by selling assets", sym="s",
             origin="guesswork",
             desc="Sales realise capital gains, which raise extra CA income tax. BSZ PDF p.24: "
                  "\"paid one-third by selling assets\".",
             levels=[0, 1 / 3, 2 / 3, 1], default=2, fmt="frac3"),
        dict(key="pareto", label="Count billionaires Forbes misses", sym="P", origin="research",
             desc="Pareto extrapolation of the $1B-4.5B range (Table 5 rows 2 and 4). BSZ PDF "
                  "pp.24-25 and Appendix Figure A4.",
             levels=[0, 1], default=1, fmt="bool"),
        dict(key="leavers", label="Aggressive assumption on leavers", sym="L", origin="guesswork",
             desc="Page, Thiel, Hankey, Kalanick escape the tax; Brin, Zuckerberg, Fang leave "
                  "later (Table 5 rows 3 and 4). A legal judgment on residency, BSZ PDF p.26.",
             levels=[0, 1], default=1, fmt="bool"),
    ]


def site_named_rows():
    """The four Table 5 rows as dial settings (1-based level indices, as in R)."""
    return {
        "Base": [3, 3, 2, 2, 1, 1],
        "Missing billionaires": [3, 3, 2, 2, 2, 1],
        "Leavers": [3, 3, 2, 2, 1, 2],
        "Missing + leavers": [3, 3, 2, 2, 2, 2],
    }


SITE_OUTCOMES = [
    ("main_estimate", "Main estimate (net)", "$B"),
    ("wealth_tax_revenue", "Wealth tax revenue (one-time)", "$B"),
    ("extra_ca_inctax_sales", "Extra CA income tax from asset sales", "$B"),
    ("income_tax_loss_pv", "Income tax lost to leavers, present value (5 years at 3%)", "$B"),
    ("annual_ca_inctax_loss", "Income tax lost to leavers, per year", "$B/yr"),
    ("taxable_wealth", "Taxable wealth after avoidance", "$B"),
    ("wealth", "Wealth of CA billionaires", "$B"),
    ("n_billionaires", "Number of billionaires", "count"),
    ("avoidance_rate", "Overall avoidance rate", "share"),
]


def build_site_grid(inp):
    """Every cell of the dial grid, first dial slowest (R reverses
    expand.grid() twice to get itertools.product order)."""
    dials = site_dials()
    keys = [d["key"] for d in dials]
    rows = []
    for i, v in enumerate(itertools.product(*[d["levels"] for d in dials]), start=1):
        # Doubles, as in R: with Python ints, -(0 * 0) * C would lose the sign of zero.
        v = tuple(float(x) for x in v)
        out = score_tab5_cell(inp, avoidance=v[0], mobility_share=v[1], avoidance_small=v[2],
                              sell_share=v[3], pareto=v[4] == 1, leavers=v[5] == 1)
        loss_pv = out["annual_ca_inctax_loss"] * site_pv_factor()
        rows.append({"cell": i, **{k: float(x) for k, x in zip(keys, v)}, **out,
                     "income_tax_loss_pv": loss_pv,
                     "main_estimate": out["wealth_tax_revenue"] + out["extra_ca_inctax_sales"] + loss_pv})
    return pd.DataFrame(rows)


def _r_format_big(x):
    """R's format(x, big.mark = ",") for the workbook's whole-dollar totals."""
    return f"{int(x):,}" if float(x).is_integer() else f"{x:,.7g}"


def build_site_inputs(inp):
    rows = [
        ("τ", "Wealth tax rate", "5% one-time", "scenario",
         "The Act as written: 5%, payable 1%/yr over 5 years (GGSS p.1)."),
        ("W₀", "Wealth of CA billionaires, 1 Jul 2026", f"${_r_format_big(inp['W0'])} B", "data",
         "Forbes real-time list, 7/1/2026 (Tab5!C6; BSZ PDF p.24)."),
        ("n₀", "Number of CA billionaires, 1 Jul 2026", str(inp["n0"]), "data",
         "Forbes real-time list, 7/1/2026 (Tab5!B6)."),
        ("α", "Avoidance and evasion", "10%", "guesswork",
         "Asserted, argued from enforcement (GGSS p.4; BSZ PDF p.23). Explorer dial."),
        ("m", "Share of avoidance that is leaving", "50%", "guesswork",
         "Asserted (BSZ PDF p.24; Tab5 row 1 label). Explorer dial."),
        ("αₛ", "Avoidance, less visible billionaires", "20%", "guesswork",
         "Asserted (BSZ PDF p.25). Explorer dial."),
        ("s", "Share of the tax paid by selling assets", "1/3", "guesswork",
         "Asserted (BSZ PDF p.24). Explorer dial."),
        ("L", "Who left before 1 Jan 2026 (Table 5 rows 3 and 4)", "no one (row 1)", "guesswork",
         "A legal judgment on residency; rows 3-4 assume Page, Thiel, Hankey, Kalanick (BSZ PDF p.26). Explorer dial."),
        ("g", "Capital-gain share of a sale", "80%", "research",
         "BSZ's own estimate that CA billionaire wealth is 80% unrealized gains (PDF p.24)."),
        ("t_cg", "Top CA income tax rate on gains", "13.3%", "data",
         "California statute, top marginal rate (Tab5!G6)."),
        ("C", "CA income tax paid by billionaires, 2019-2025 average", "$%.2f B/yr" % inp["C"], "research",
         "BSZ's own FTB + Pareto estimate (Tab2!C14; Table 2 of the paper), reproduced in this pipeline."),
        ("b", "Pareto coefficient above $4.5B", "%.2f" % inp["pareto_b"], "research",
         "Estimated from Forbes 4/15/2026 (Pareto-missing sheet; BSZ PDF p.25)."),
        ("ΔW_P", "Wealth added by the Pareto extrapolation", "+%.1f%%" % (100 * inp["pct_wealth_increase"]),
         "research", "Pareto-missing!I23, derived from b."),
        ("Δn_P", "Billionaires added by the Pareto extrapolation", "+%.0f%%" % (100 * inp["pct_count_increase"]),
         "research", "Pareto-missing!J23, derived from b."),
        ("f_ph", "Share of added wealth in the $1B-1.1B phase-in", "%.1f%%" % (100 * inp["fraction_in_phasein"]),
         "derived", "Pareto-missing!I24, derived from b."),
        ("W_pre", "Wealth of pre-2026 leavers (Page, Thiel, Hankey, Kalanick)", "$%.1f B" % inp["W_pre"], "data",
         "Forbes 7/1/2026 values typed into Tab5!B20:B23."),
        ("L_lv", "Annual CA income tax of all seven named leavers", "$%.2f B/yr" % inp["leaver_loss"], "derived",
         "Top-3 company income tax from SEC data (Tab3 row 13) plus a wealth-proportional rate on the rest (Tab5!F19+F24)."),
        ("date", "Valuation date", "1 Jul 2026", "convention",
         "The Act values wealth at 31 Dec 2026; BSZ and GGSS estimate on the latest Forbes snapshot."),
    ]
    return pd.DataFrame(rows, columns=["symbol", "input", "value", "origin", "basis"])


# ---- grid.js ---------------------------------------------------------------

def _json_number(x):
    """A number as jsonlite::toJSON(digits = NA) writes it: up to 15
    significant digits, a whole number without a decimal point, and -0 for a
    negative zero (the leavers' loss is -0 when no one leaves)."""
    x = float(x)
    if x == 0 and math.copysign(1.0, x) < 0:
        return "-0"   # jsonlite keeps the sign of a negative zero
    if x.is_integer() and abs(x) < 1e15:
        return str(int(x))
    return "%.15g" % x


def _json(v):
    """A compact JSON writer matching jsonlite's output (auto_unbox = TRUE:
    a length-one vector is written as a scalar, so callers pass scalars)."""
    if isinstance(v, dict):
        return "{" + ",".join(json.dumps(k, ensure_ascii=False) + ":" + _json(x) for k, x in v.items()) + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ",".join(_json(x) for x in v) + "]"
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, bool):
        return "true" if v else "false"
    return _json_number(v)


def _r_round(x, digits):
    """R's round(x, digits) for the grid values. Python's round() picks the
    nearer decimal of the exact binary value, as R 4's algorithm does."""
    return round(float(x), digits)


def site_grid_js_text(grid, inp):
    dials = site_dials()
    keys = [k for k, _, _ in SITE_OUTCOMES]
    snap = [[_r_round(v, 6) for v in row] for row in grid[keys].itertuples(index=False)]
    payload = {
        "source": "Generated by write_site_grid_js() in R/site_exports.R from the targets pipeline "
                  f"(BSZ workbook, {inp['vintage']} vintage). Do not edit.",
        "vintage": inp["vintage"],
        "dials": [{k: d[k] for k in ("key", "label", "sym", "origin", "desc", "levels", "fmt")} for d in dials],
        "outcomes": [lab for _, lab, _ in SITE_OUTCOMES],
        "keys": keys,
        "units": [u for _, _, u in SITE_OUTCOMES],
        "named": {k: [i - 1 for i in v] for k, v in site_named_rows().items()},
        "preferred": "Base",
        "facts": {"W0": inp["W0"], "n0": inp["n0"], "C": _r_round(inp["C"], 6),
                  "pv_rate": SITE_PV_RATE, "pv_years": SITE_PV_YEARS,
                  "row4_phasein_gap": _r_round(inp["row4_phasein_gap"], 6)},
        "snap": snap,
    }
    return ("/* Generated file: do not edit. See R/site_exports.R. */\n"
            "window.__GRID__ = " + _json(payload) + ";\n")


# ---- Table 5 as printed in the paper ---------------------------------------

TAB5_COLUMNS = ["n_billionaires", "wealth", "taxable_wealth", "avoidance_rate",
                "wealth_tax_revenue", "extra_ca_inctax_sales", "annual_ca_inctax_loss"]


def bsz_tab5_printed():
    printed = [250, 2307, 2076, 10.0, 104, 3.7, -0.15,
               620, 2957, 2597, 12.2, 128, 4.5, -0.19,
               250, 2307, 1776, 23.0, 89, 3.1, -0.51,
               620, 2957, 2296, 22.4, 115, 4.1, -0.56]
    return pd.DataFrame({
        "column": TAB5_COLUMNS * 4,
        "row": [r for r in range(1, 5) for _ in range(7)],
        "printed": [float(p) for p in printed],
        "digits": [0, 0, 0, 1, 0, 1, 2] * 4,
        "scale": [1, 1, 1, 100, 1, 1, 1] * 4,
    })


def compare_tab5_printed(tab5_r):
    p = bsz_tab5_printed()
    p["reproduced"] = [float(tab5_r[c].iloc[r - 1]) * sc for c, r, sc in zip(p["column"], p["row"], p["scale"])]
    p["matches_printed"] = [_r_round(x, d) == pr for x, d, pr in zip(p["reproduced"], p["digits"], p["printed"])]
    return p
