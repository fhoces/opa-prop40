"""Python twin of comparison/R/{contract,model,build}.R.

Reads the same three kinds of file (each side's export/r contract, comparison/data/
document-inputs.csv, comparison/data/hoopes-fig2.csv), scores both sides with the same
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
    S = 1 - (x["d_conf"] + max(x["d_conf"], x["eps"] * x["dtau"])) / 2
    WT = R0 * (1 - x["alpha"]) * S
    X = WT * x["s"] * x["g"] * x["t_cg"]
    f = x["alpha"] * x["m"] + x["kappa"] * (1 - S) * (1 - x["alpha"] * x["m"])
    A = expected_annuity(x["H"], x["r_min"], x["r_max"])
    PV = f * x["C"] * A
    return {"a": WT, "b": WT + X - PV, "R0": R0, "S": S, "X": X, "f": f,
            "annual_loss": f * x["C"], "annuity": A, "PV": PV}


STEPS = [
    ("noncitizens", "8", "Non-US-citizen residents", "data"),
    ("base_list", "7", "Base list and valuation date", "data"),
    ("real_estate", "7", "Real-estate deduction", "data"),
    ("confirmed_departures", "3", "Billionaires already departed", "guesswork on data"),
    ("avoidance", "(not a row)", "Avoidance and evasion allowance", "guesswork"),
    ("one_time_as_permanent", "1", "One-time tax scored as a permanent 5 pp rate", "scenario + guesswork"),
    ("elasticity_size", "4", "Size of the mobility semi-elasticity", "research + guesswork"),
    ("income_proportional", "6", "Lost income tax proportional to lost wealth", "data vs guesswork"),
    ("income_level", "5", "Billionaires' annual CA income tax", "research vs guesswork"),
    ("horizon", "2", "How long the income tax loss lasts", "scenario"),
    ("asset_sales", "(not a row)", "Extra income tax from selling assets to pay", "guesswork"),
]
IDS = [s[0] for s in STEPS]
STEP_INPUTS = {"noncitizens": ["W_noncit"], "base_list": ["W_core"], "real_estate": ["re"],
               "confirmed_departures": ["d_conf"], "avoidance": ["alpha"],
               "one_time_as_permanent": ["dtau"], "elasticity_size": ["eps"],
               "income_proportional": ["kappa"], "income_level": ["C"], "horizon": ["H"],
               "asset_sales": ["s"]}
SEQUENTIAL = ["noncitizens", "base_list", "confirmed_departures", "avoidance",
              "one_time_as_permanent", "elasticity_size", "real_estate", "asset_sales",
              "income_proportional", "income_level", "horizon"]


def switch_inputs(sup: dict, rauh: dict, on) -> dict:
    x = dict(sup)
    for st in on:
        for nm in STEP_INPUTS[st]:
            x[nm] = rauh[nm]
    return x


def shapley_bridge(sup, rauh, players, output):
    n = len(players)
    v = {}
    for mask in range(2 ** n):
        on = [players[i] for i in range(n) if mask & (1 << i)]
        v[mask] = score_common(switch_inputs(sup, rauh, on))[output]
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


def rauh_ssrn_expectation(wt_min, wt_max, baseline, c_min, c_max, r_min, r_max, H=math.inf):
    e_wt = (wt_min + wt_max) / 2
    return {"a": e_wt, "b": e_wt - (1 - e_wt / baseline) * (c_min + c_max) / 2 *
            expected_annuity(H, r_min, r_max)}


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
    base_r = pick(oi, "baseline_net_worth")
    R0_r = pick(oo, "revenue_baseline")
    conf6 = pick(oo, "revenue_confirmed6")
    wt_min = pick(oi, "rauh_mc_wt_min")
    shared = {"tau": tau, "m": pick(si, "mobility_share"), "g": pick(si, "gains_share"),
              "t_cg": pick(si, "ca_cg_rate"),
              "r_min": pick(oi, "rauh_mc_r_min"), "r_max": pick(oi, "rauh_mc_r_max")}
    sup = dict(shared, W_noncit=noncit, W_core=W0 - noncit, re=0.0, d_conf=0.0,
               alpha=pick(si, "avoidance_rate"), dtau=0.0,
               eps=pick(si, "semi_elasticity_permanent"), kappa=kappa_s, C=C_sup,
               H=pick(d, "bsz_loss_horizon"), s=pick(si, "sell_share"))
    rauh = dict(shared, W_noncit=0.0, W_core=base_r, re=1 - R0_r / (tau * base_r),
                d_conf=1 - conf6 / R0_r, alpha=0.0, dtau=tau, eps=(1 - wt_min / R0_r) / tau,
                kappa=1.0, C=(pick(oi, "rauh_mc_c_min") + pick(oi, "rauh_mc_c_max")) / 2,
                H=pick(d, "rauh_loss_horizon"), s=0.0)
    return sup, rauh


def build_all(k):
    sup, rauh = bridge_inputs(k)
    so, oo, d = k["bsz"]["outputs"], k["rjkdc"]["outputs"], k["docs"]
    oi = k["rjkdc"]["inputs"]
    ggss_printed = pick(so, "ggss_headline", "printed_value")
    ra = dict(wt_min=pick(oi, "rauh_mc_wt_min"), wt_max=pick(oo, "revenue_confirmed6", "printed_value"),
              baseline=pick(oo, "revenue_baseline", "printed_value"),
              c_min=pick(oi, "rauh_mc_c_min"), c_max=pick(oi, "rauh_mc_c_max"),
              r_min=pick(oi, "rauh_mc_r_min"), r_max=pick(oi, "rauh_mc_r_max"))
    na = dict(wt_min=0.0, wt_max=pick(k["rjkdc"]["inputs"], "nber_ceiling_hardcoded"),
              f_min=pick(oi, "nber_mc_f_min"), f_max=pick(oi, "nber_mc_f_max"),
              c_min=ra["c_min"], c_max=ra["c_max"], r_min=ra["r_min"], r_max=ra["r_max"])

    settings = ["own"] + [f"common_{'Inf' if math.isinf(h) else h}" for h in HORIZONS]
    bridge, ends = [], []
    for st in settings:
        s2, r2, players = dict(sup), dict(rauh), list(IDS)
        if st != "own":
            H = math.inf if st.endswith("Inf") else float(st.split("_")[1])
            s2["H"] = r2["H"] = H
            players = [p for p in IDS if p != "horizon"]
        v_sup, v_rauh = score_common(s2), score_common(r2)
        own_r = rauh_ssrn_expectation(**ra, H=r2["H"])
        own_n = rauh_nber_expectation(**na, H=r2["H"])
        for out in ("a", "b"):
            sh = shapley_bridge(s2, r2, players, out)
            sq = sequential_bridge(s2, r2, [p for p in SEQUENTIAL if p in players], out)
            for sid, row, title, kind in STEPS:
                bridge.append({"step_id": sid, "horizon_setting": st, "output": out,
                               "shapley": sh.get(sid, 0.0), "sequential": sq.get(sid, 0.0),
                               "sequential_rank": SEQUENTIAL.index(sid) + 1,
                               "disputes_row": row, "title": title, "kind": kind})
            ends.append({"horizon_setting": st, "output": out,
                         "bsz_model": v_sup[out], "rauh_model": v_rauh[out],
                         "rauh_own": own_r[out], "rauh_residual": own_r[out] - v_rauh[out],
                         "nber_own": own_n[out], "nber_step": own_n[out] - own_r[out]})
    bridge.sort(key=lambda r: (r["horizon_setting"], r["output"], IDS.index(r["step_id"])))
    ea = [e for e in ends if e["horizon_setting"] == "own" and e["output"] == "a"][0]
    eb = [e for e in ends if e["horizon_setting"] == "own" and e["output"] == "b"][0]

    endpoints = []
    vals = [("ggss_headline", ggss_printed, pick(so, "ggss_headline", "printed_value")),
            ("ggss_scoring", ea["bsz_model"], pick(so, "ggss_scoring", "printed_value")),
            ("bsz_tab5_row1", ea["bsz_model"], pick(so, "tab5_row1_wealth_tax_revenue", "printed_value")),
            ("bsz_net_constructed", eb["bsz_model"], math.nan),
            ("rauh_ssrn_revenue_mc", ea["rauh_own"], math.nan),
            ("rauh_ssrn_npv", eb["rauh_own"], pick(oo, "npv_mc_ssrn_mean", "printed_value")),
            ("rauh_nber_revenue_mc", ea["nber_own"], math.nan),
            ("rauh_nber_npv", eb["nber_own"], pick(oo, "npv_mc_nber_mean", "printed_value"))]
    for eid, v, p in vals:
        endpoints.append({"endpoint_id": eid, "value": v, "printed_value": p,
                          "abs_diff_printed": abs(v - p)})

    anchors = [{"anchor_id": a, "value": v, "residual_vs_model": v - ea["rauh_model"]} for a, v in [
        ("mc_expected", ea["rauh_own"]),
        ("literature_calibrated", pick(oo, "revenue_literature_calibrated", "printed_value")),
        ("table9_central", pick(k["rjkdc"]["inputs"], "wt_central_scenario")),
        ("preferred_about_40", pick(d, "rauh_headline_revenue"))]]

    A5 = expected_annuity(5, sup["r_min"], sup["r_max"])
    Ainf = expected_annuity(math.inf, sup["r_min"], sup["r_max"])
    cmid = (ra["c_min"] + ra["c_max"]) / 2
    loss = []
    for sid, al in [("bsz_row1", -pick(so, "tab5_row1_annual_ca_inctax_loss")),
                    ("bsz_row3", -pick(so, "tab5_row3_annual_ca_inctax_loss")),
                    ("lao_upper", pick(d, "lao_loss_upper")),
                    ("rauh_ssrn", (1 - ea["rauh_own"] / ra["baseline"]) * cmid),
                    ("rauh_nber", (na["f_min"] + na["f_max"]) / 2 * cmid),
                    ("walczak_low", pick(d, "walczak_loss_low")),
                    ("walczak_high", pick(d, "walczak_loss_high"))]:
        loss.append({"source_id": sid, "annual_loss": al, "pv_5yr": al * A5,
                     "pv_perpetuity": al * Ainf,
                     "net_at_rauh_revenue_perpetuity": ea["rauh_own"] - al * Ainf})

    hz = {r["step_id"]: r for r in k["hoopes"]}
    sqa = {r["step_id"]: r["sequential"] for r in bridge
           if r["horizon_setting"] == "own" and r["output"] == "a"}
    ours = [("galle_estimate", ggss_printed),
            ("ggss_rounding", ea["bsz_model"] - ggss_printed),
            ("residency_correction", sqa["noncitizens"] + sqa["base_list"]),
            ("confirmed_departures", sqa["confirmed_departures"]),
            ("additional_movers", math.nan),
            ("additional_behavioral_response",
             sqa["avoidance"] + sqa["one_time_as_permanent"] + sqa["elasticity_size"]),
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
            "loss": loss, "hoopes": hoopes, "meta": meta}


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
