"""Python twin of comparison/R/{contract,model,build}.R.

Reads the same three kinds of file (each analysis's export/r contract, comparison/data/
document-inputs.csv, comparison/data/hoopes-fig2.csv), estimates both analyses with the same
common function, and writes comparison/export/py/*.csv in the same layout as the R side.
comparison/tests/testthat/test-parity.R compares the two export directories.

Run from anywhere inside the repo:  python comparison/py/bridge.py
"""
from __future__ import annotations

import csv
import math
import os
import sys

from scipy.integrate import quad

HORIZONS = [5, 10, 20, 30, 50, math.inf]


# ---- contracts -----------------------------------------------------------------
def repo_root() -> str:
    env = os.environ.get("OPA_PROP40_ROOT")
    if env:
        return env
    d = os.path.abspath(os.getcwd())
    while True:
        if all(os.path.isdir(os.path.join(d, x)) for x in
               ("comparison", "bsz-analysis", "rjkdc-analysis")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            raise SystemExit("cannot find the opa-prop40 root; set OPA_PROP40_ROOT")
        d = parent


def read_rows(path: str) -> list[dict]:
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def num(v: str) -> float:
    if v in ("", "NA"):
        return math.nan
    return float(v)  # "Inf" parses to inf


def pick(rows: list[dict], key_value: str, col: str = "value") -> float:
    key = list(rows[0].keys())[0]
    hit = [r for r in rows if r[key] == key_value]
    if len(hit) != 1:
        raise KeyError(f"expected exactly one row '{key_value}', found {len(hit)}")
    return num(hit[0][col])


def read_contracts(root: str) -> dict:
    side = lambda s: {"inputs": read_rows(os.path.join(root, s, "export", "r", "inputs.csv")),
                      "outputs": read_rows(os.path.join(root, s, "export", "r", "outputs.csv"))}
    return {"bsz": side("bsz-analysis"),
            "rjkdc": side("rjkdc-analysis"),
            "docs": read_rows(os.path.join(root, "comparison", "data", "document-inputs.csv")),
            "hoopes": read_rows(os.path.join(root, "comparison", "data", "hoopes-fig2.csv"))}


# ---- model ---------------------------------------------------------------------
def expected_annuity(H: float, r_min: float, r_max: float) -> float:
    if math.isinf(H):
        return math.log(r_max / r_min) / (r_max - r_min)
    if H == 0:
        return 0.0
    val, _ = quad(lambda r: (1 - (1 + r) ** (-H)) / r, r_min, r_max, epsabs=0, epsrel=1e-12)
    return val / (r_max - r_min)


def score_common(x: dict) -> dict:
    R0 = x["tau"] * (x["W_core"] + x["W_noncit"]) * (1 - x["re"])
    S = 1 - x["d_conf"]
    WT = R0 * (1 - x["alpha"]) * S * x["q"]
    X = WT * x["s"] * x["g"] * x["t_cg"]
    f = x["alpha"] * x["m"] + (1 - x["alpha"] * x["m"]) * (x["kappa"] * x["d_conf"] + x["f0"])
    A = expected_annuity(x["H"], x["r_min"], x["r_max"])
    PV = f * x["C"] * A
    return {"a": WT, "b": WT + X - PV, "R0": R0, "S": S, "X": X, "f": f,
            "annual_loss": f * x["C"], "annuity": A, "PV": PV}


STEPS = [
    ("noncitizens", "8", "Non-US-citizen residents", "data"),
    ("base_list", "7", "Forbes source: which list and valuation date", "data"),
    ("real_estate", "7", "Real-estate deduction", "data"),
    ("confirmed_departures", "3", "Billionaires already departed", "guesswork on data"),
    ("avoidance", "(not a row)", "Avoidance and evasion allowance", "guesswork"),
    ("litigation_survival", "9", "Chance the tax survives litigation", "guesswork"),
    ("income_loss_share", "6", "Share of billionaire income tax lost", "data vs guesswork"),
    ("income_level", "5", "Billionaires' annual CA income tax", "research vs guesswork"),
    ("horizon", "2", "How long the income tax loss lasts", "scenario"),
    ("asset_sales", "(not a row)", "Extra income tax from selling assets to pay", "guesswork"),
]
IDS = [s[0] for s in STEPS]
STEP_INPUTS = {"noncitizens": ["W_noncit"], "base_list": ["W_core"], "real_estate": ["re"],
               "confirmed_departures": ["d_conf"], "avoidance": ["alpha"],
               "litigation_survival": ["q"], "income_loss_share": ["kappa", "f0"],
               "income_level": ["C"], "horizon": ["H"],
               "asset_sales": ["s"]}
SEQUENTIAL = ["noncitizens", "base_list", "confirmed_departures", "avoidance",
              "litigation_survival", "real_estate", "asset_sales", "income_loss_share",
              "income_level", "horizon"]


def switch_inputs(sup: dict, rauh: dict, on) -> dict:
    x = dict(sup)
    for st in on:
        for nm in STEP_INPUTS[st]:
            x[nm] = rauh[nm]
    return x


# ---- the explorer's sliders (twin of slider_inputs() etc. in R/model.R) ---------------
# Positions 0 to 4 per input, 0 = the panel's own analysis's value, 4 = the other's: linear in
# the parameter for numeric inputs, the five settings 5/10/20/50 years/perpetuity for the
# horizon; a step with two inputs moves both.
SLIDER_STEPS = 4
SLIDER_HORIZONS = [5, 10, 20, 50, math.inf]


def slider_inputs(frm: dict, to: dict, positions: dict) -> dict:
    x = dict(frm)
    for st in IDS:
        p = positions.get(st, 0)
        assert p in range(SLIDER_STEPS + 1)
        t = p / SLIDER_STEPS
        for nm in STEP_INPUTS[st]:
            if nm == "H":
                lad = SLIDER_HORIZONS if frm["H"] <= to["H"] else SLIDER_HORIZONS[::-1]
                assert lad[0] == frm["H"] and lad[-1] == to["H"]
                x["H"] = lad[p]
            else:
                x[nm] = (1 - t) * frm[nm] + t * to[nm]
    return x


def slider_value(sup, rauh, panel, positions):
    frm, to = (sup, rauh) if panel == "bsz" else (rauh, sup)
    return score_common(slider_inputs(frm, to, positions))["b"]


def slider_sample(sup, rauh, n=300, seed=20261014):
    """Per panel: all at 0, all at the far end, then n - 2 Park-Miller draws (same as R)."""
    state = [seed]

    def draw(k):
        state[0] = (16807 * state[0]) % 2147483647
        return state[0] % k

    rows = []
    for panel in ("bsz", "rjkdc"):
        for i in range(1, n + 1):
            if i == 1:
                pos = [0] * len(IDS)
            elif i == 2:
                pos = [SLIDER_STEPS] * len(IDS)
            else:
                pos = [draw(SLIDER_STEPS + 1) for _ in IDS]
            p = dict(zip(IDS, pos))
            rows.append({"panel": panel, "draw": i, **p,
                         "value": slider_value(sup, rauh, panel, p)})
    return rows


def coalition_values(sup, rauh, players, output):
    """v[mask]: score_common() with the players whose bit is set (bit i = players[i]) at the
    JR value and the rest at the BSZ value. The explorer's switchboard reads these."""
    n = len(players)
    v = []
    for mask in range(2 ** n):
        on = [players[i] for i in range(n) if mask & (1 << i)]
        v.append(score_common(switch_inputs(sup, rauh, on))[output])
    return v


def shapley_bridge(sup, rauh, players, output, v=None):
    n = len(players)
    if v is None:
        v = coalition_values(sup, rauh, players, output)
    phi = []
    for i in range(n):
        bit = 1 << i
        tot = 0.0
        for mask in range(2 ** n):
            if mask & bit:
                continue
            size = bin(mask).count("1")
            w = math.factorial(size) * math.factorial(n - size - 1) / math.factorial(n)
            tot += w * (v[mask | bit] - v[mask])
        phi.append(tot)
    return dict(zip(players, phi))


def sequential_bridge(sup, rauh, order, output):
    prev = score_common(sup)[output]
    out = {}
    for k in range(len(order)):
        cur = score_common(switch_inputs(sup, rauh, order[:k + 1]))[output]
        out[order[k]] = cur - prev
        prev = cur
    return out


def rauh_nber_expectation(wt_min, wt_max, f_min, f_max, c_min, c_max, r_min, r_max, H=math.inf):
    e_wt = (wt_min + wt_max) / 2
    return {"a": e_wt, "b": e_wt - (f_min + f_max) / 2 * (c_min + c_max) / 2 *
            expected_annuity(H, r_min, r_max)}


# ---- build ---------------------------------------------------------------------
def bridge_inputs(k):
    si, so = k["bsz"]["inputs"], k["bsz"]["outputs"]
    oi, oo = k["rjkdc"]["inputs"], k["rjkdc"]["outputs"]
    d = k["docs"]
    W0 = pick(si, "baseline_net_worth")
    noncit = pick(d, "ggss_noncitizen_wealth")
    C_sup = pick(si, "ca_inctax_billionaires")
    kappa_s = (pick(si, "leavers_annual_inctax") / pick(si, "leavers_wealth")) / (C_sup / W0)
    tau = pick(oi, "tax_rate")
    assert abs(tau - pick(si, "tax_rate")) < 1e-12
    base_r = pick(oi, "baseline_net_worth") * (1 + pick(oi, "nber_growth_rate"))
    R0_r = pick(oo, "nber_domestic_grown")
    ceiling = pick(oi, "nber_ceiling_hardcoded")
    shared = {"tau": tau, "m": pick(si, "mobility_share"), "g": pick(si, "gains_share"),
              "t_cg": pick(si, "ca_cg_rate"),
              "r_min": pick(oi, "rauh_mc_r_min"), "r_max": pick(oi, "rauh_mc_r_max")}
    sup = dict(shared, W_noncit=noncit, W_core=W0 - noncit, re=0.0, d_conf=0.0,
               alpha=pick(si, "avoidance_rate"), q=1.0,
               kappa=kappa_s, f0=0.0, C=C_sup,
               H=pick(d, "bsz_loss_horizon"), s=pick(si, "sell_share"))
    rauh = dict(shared, W_noncit=0.0, W_core=base_r, re=1 - R0_r / (tau * base_r),
                d_conf=1 - ceiling / R0_r, alpha=0.0, q=pick(oi, "q_litigation_survival"),
                kappa=0.0, f0=(pick(oi, "nber_mc_f_min") + pick(oi, "nber_mc_f_max")) / 2,
                C=(pick(oi, "rauh_mc_c_min") + pick(oi, "rauh_mc_c_max")) / 2,
                H=pick(d, "rauh_loss_horizon"), s=0.0)
    return sup, rauh


def build_all(k):
    sup, rauh = bridge_inputs(k)
    so, oo, d = k["bsz"]["outputs"], k["rjkdc"]["outputs"], k["docs"]
    oi = k["rjkdc"]["inputs"]
    ggss_printed = pick(so, "ggss_headline", "printed_value")
    # The JR analysis's own Monte Carlo (NPV_dist_v8.R), as the authors ship it.
    na = dict(wt_min=0.0, wt_max=pick(oi, "nber_ceiling_hardcoded"),
              f_min=pick(oi, "nber_mc_f_min"), f_max=pick(oi, "nber_mc_f_max"),
              c_min=pick(oi, "rauh_mc_c_min"), c_max=pick(oi, "rauh_mc_c_max"),
              r_min=pick(oi, "rauh_mc_r_min"), r_max=pick(oi, "rauh_mc_r_max"))

    settings = ["own"] + [f"common_{'Inf' if math.isinf(h) else h}" for h in HORIZONS]
    bridge, ends, board = [], [], []
    for st in settings:
        s2, r2, players = dict(sup), dict(rauh), list(IDS)
        if st != "own":
            H = math.inf if st.endswith("Inf") else float(st.split("_")[1])
            s2["H"] = r2["H"] = H
            players = [p for p in IDS if p != "horizon"]
        v_sup, v_rauh = score_common(s2), score_common(r2)
        own_n = rauh_nber_expectation(**na, H=r2["H"])
        # bit i of a switchboard mask = input i in the bridge's order (IDS); with a common
        # horizon the horizon is not a player, so only masks with its bit off are listed
        full_bit = [1 << IDS.index(p) for p in players]
        for out in ("a", "b"):
            v = coalition_values(s2, r2, players, out)
            sh = shapley_bridge(s2, r2, players, out, v=v)
            for m, val in enumerate(v):
                board.append({"output": out, "horizon_setting": st,
                              "mask": sum(b for i, b in enumerate(full_bit) if m & (1 << i)),
                              "value": val})
            sq = sequential_bridge(s2, r2, [p for p in SEQUENTIAL if p in players], out)
            for sid, row, title, kind in STEPS:
                bridge.append({"step_id": sid, "horizon_setting": st, "output": out,
                               "shapley": sh.get(sid, 0.0), "sequential": sq.get(sid, 0.0),
                               "sequential_rank": SEQUENTIAL.index(sid) + 1,
                               "disputes_row": row, "title": title, "kind": kind})
            ends.append({"horizon_setting": st, "output": out,
                         "bsz_model": v_sup[out], "rauh_model": v_rauh[out],
                         "rauh_own": own_n[out], "rauh_residual": own_n[out] - v_rauh[out]})
    bridge.sort(key=lambda r: (r["horizon_setting"], r["output"], IDS.index(r["step_id"])))
    board.sort(key=lambda r: (r["output"], settings.index(r["horizon_setting"]), r["mask"]))
    ea = [e for e in ends if e["horizon_setting"] == "own" and e["output"] == "a"][0]
    eb = [e for e in ends if e["horizon_setting"] == "own" and e["output"] == "b"][0]

    endpoints = []
    vals = [("ggss_headline", ea["bsz_model"] + (ggss_printed - ea["bsz_model"]),
             pick(so, "ggss_headline", "printed_value")),
            ("ggss_scoring", ea["bsz_model"], pick(so, "ggss_scoring", "printed_value")),
            ("bsz_tab5_row1", ea["bsz_model"], pick(so, "tab5_row1_wealth_tax_revenue", "printed_value")),
            ("bsz_net_constructed", eb["bsz_model"], math.nan),
            ("rauh_nber_revenue_mc", ea["rauh_own"], math.nan),
            ("rauh_nber_npv", eb["rauh_own"], pick(oo, "npv_mc_nber_mean", "printed_value"))]
    for eid, v, p in vals:
        endpoints.append({"endpoint_id": eid, "value": v, "printed_value": p,
                          "abs_diff_printed": abs(v - p)})

    anchors = [{"anchor_id": a, "value": v, "residual_vs_model": v - ea["rauh_model"]} for a, v in [
        ("mc_expected", ea["rauh_own"]),
        ("preferred_about_30", pick(d, "nber_headline_revenue"))]]

    A5 = expected_annuity(5, sup["r_min"], sup["r_max"])
    Ainf = expected_annuity(math.inf, sup["r_min"], sup["r_max"])
    loss = []
    for sid, al in [("bsz_row1", -pick(so, "tab5_row1_annual_ca_inctax_loss")),
                    ("bsz_row3", -pick(so, "tab5_row3_annual_ca_inctax_loss")),
                    ("lao_upper", pick(d, "lao_loss_upper")),
                    ("rauh_nber", (na["f_min"] + na["f_max"]) / 2 * (na["c_min"] + na["c_max"]) / 2),
                    ("walczak_low", pick(d, "walczak_loss_low")),
                    ("walczak_high", pick(d, "walczak_loss_high"))]:
        loss.append({"source_id": sid, "annual_loss": al, "pv_5yr": al * A5,
                     "pv_perpetuity": al * Ainf,
                     "net_at_nber_revenue_perpetuity": ea["rauh_own"] - al * Ainf})

    hz = {r["step_id"]: r for r in k["hoopes"]}
    sqa = {r["step_id"]: r["sequential"] for r in bridge
           if r["horizon_setting"] == "own" and r["output"] == "a"}
    ours = [("galle_estimate", ggss_printed),
            ("ggss_rounding", ea["bsz_model"] - ggss_printed),
            ("residency_correction", sqa["noncitizens"] + sqa["base_list"]),
            ("confirmed_departures", sqa["confirmed_departures"]),
            ("additional_movers", math.nan),
            ("additional_behavioral_response",
             sqa["avoidance"] + sqa["litigation_survival"]),
            ("real_estate_exclusion", sqa["real_estate"]),
            ("rauh_rounding", ea["rauh_residual"]),
            ("income_tax_loss", eb["rauh_own"] - ea["rauh_own"])]
    hoopes = [{"step_id": sid, "ours": v,
               "hoopes": num(hz[sid]["delta"]) if sid in hz else math.nan,
               "hoopes_uncertainty": num(hz[sid]["uncertainty"]) if sid in hz else math.nan}
              for sid, v in ours]

    s_r = score_common(rauh)
    meta = [{"key": "A_5", "value": A5}, {"key": "A_inf", "value": Ainf},
            {"key": "kappa_bsz", "value": sup["kappa"]},
            {"key": "R0_rauh", "value": s_r["R0"]}, {"key": "S_rauh", "value": s_r["S"]},
            {"key": "X_bsz", "value": score_common(sup)["X"]},
            {"key": "PV_bsz_own", "value": score_common(sup)["PV"]},
            {"key": "f_rauh", "value": s_r["f"]}, {"key": "C_rauh", "value": rauh["C"]}]
    return {"bridge": bridge, "ends": ends, "endpoints": endpoints, "anchors": anchors,
            "loss": loss, "hoopes": hoopes, "meta": meta, "switchboard": board,
            "slider_sample": slider_sample(sup, rauh)}


def fmt(v):
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, float):
        if math.isnan(v):
            return "NA"
        if math.isinf(v):
            return "Inf" if v > 0 else "-Inf"
        return repr(v)
    return v


def write_exports(res, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    for name, rows in res.items():
        with open(os.path.join(out_dir, f"{name}.csv"), "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=list(rows[0].keys()), quoting=csv.QUOTE_NONNUMERIC)
            w.writeheader()
            for r in rows:
                w.writerow({k: fmt(v) for k, v in r.items()})


if __name__ == "__main__":
    root = repo_root()
    res = build_all(read_contracts(root))
    write_exports(res, os.path.join(root, "comparison", "export", "py"))
    print("wrote comparison/export/py/")
