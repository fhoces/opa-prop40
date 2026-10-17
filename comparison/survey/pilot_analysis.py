"""Analysis of a simulated pilot of the Prop 40 survey experiment, following the pre-analysis plan
(comparison/survey/PRE-ANALYSIS-PLAN.md): the lean index, H1 by OLS with entry-point fixed effects
and HC2 standard errors, the secondary outcomes, the five questions with the Romano-Wolf step-down
adjustment, the three heterogeneity dimensions, and the balance and attrition checks.

Usage: python3 comparison/survey/pilot_analysis.py RESPONSES.csv OUT_DIR [B] [SEED]

RESPONSES.csv is pilot_harvest.py's responses.csv. Writes CSV tables to OUT_DIR (one per table,
fixed column names) and prints them. The R twin lives in the pilot's report.qmd; it recomputes
every table and compares. B is the number of bootstrap draws (default 2000), SEED the bootstrap seed.
"""
import os
import sys

import numpy as np
import pandas as pd
from scipy import stats

QUESTIONS = ["share_lost", "horizon", "income_level", "court", "moved_out"]
OPTIONAL = ["avoidance", "wealth_list", "noncitizens", "real_estate", "asset_sales"]
CODE = {"BSZ": 1, "JR": -1, "equal": 0, "unsure": 0, "skipped": 0}


def design(d, extra=None):
    """Treatment, entry-point fixed effects (landing is the base), and optional extra columns."""
    X = pd.DataFrame({"const": 1.0, "T": d["T"].astype(float),
                      "E_explorer": (d["entry"] == "explorer").astype(float),
                      "E_share": (d["entry"] == "share").astype(float)})
    if extra is not None:
        for k, v in extra.items():
            X[k] = v.astype(float)
    return X


def ols_hc2(y, X):
    """OLS with HC2 standard errors. Returns (coef, se) as Series indexed by X's columns."""
    Xm, yv = X.to_numpy(), np.asarray(y, float)
    if np.linalg.matrix_rank(Xm) < Xm.shape[1]:
        raise np.linalg.LinAlgError("rank deficient design")
    XtX_inv = np.linalg.inv(Xm.T @ Xm)
    b = XtX_inv @ Xm.T @ yv
    e = yv - Xm @ b
    h = np.einsum("ij,jk,ik->i", Xm, XtX_inv, Xm)          # leverage
    if np.any(h >= 1 - 1e-10):
        raise np.linalg.LinAlgError("an observation with leverage 1")
    meat = (Xm * (e ** 2 / (1 - h))[:, None]).T @ Xm
    V = XtX_inv @ meat @ XtX_inv
    return pd.Series(b, X.columns), pd.Series(np.sqrt(np.diag(V)), X.columns)


def t_and_p(b, se, n, k):
    t = b / se
    return t, 2 * stats.t.sf(abs(t), df=n - k)


def romano_wolf(d, outcomes, coef, B, seed, extra_fn=None):
    """Romano-Wolf step-down adjusted p-values for one coefficient across a family of outcomes
    (Romano and Wolf 2005; the algorithm of Clarke, Romano and Wolf 2020). Studentized statistics
    from the HC2 fit; a pairs bootstrap that resamples respondents within each entry-point stratum.
    outcomes: list of (name, y Series). extra_fn(frame) gives extra design columns, if any."""
    rng = np.random.default_rng(seed)
    names = [o[0] for o in outcomes]
    X = design(d, extra_fn(d) if extra_fn else None)
    k = X.shape[1]
    t_obs = {}
    for name, y in outcomes:
        b, se = ols_hc2(y, X)
        t_obs[name] = b[coef] / se[coef]
    # bootstrap: centered studentized statistics, stratified by entry point
    strata = [np.flatnonzero((d["entry"] == e).to_numpy()) for e in sorted(d["entry"].unique())]
    tb = np.zeros((B, len(names)))
    ys = {name: np.asarray(y, float) for name, y in outcomes}
    b_obs = {name: ols_hc2(y, X)[0][coef] for name, y in outcomes}
    r = 0
    while r < B:
        idx = np.concatenate([rng.choice(s, size=len(s), replace=True) for s in strata])
        db = d.iloc[idx].reset_index(drop=True)
        Xb = design(db, extra_fn(db) if extra_fn else None)
        try:
            for j, name in enumerate(names):
                b, se = ols_hc2(ys[name][idx], Xb)
                tb[r, j] = (b[coef] - b_obs[name]) / se[coef]
        except np.linalg.LinAlgError:
            continue                                        # a degenerate resample: draw again
        r += 1
    # step-down over |t|
    order = sorted(range(len(names)), key=lambda j: -abs(t_obs[names[j]]))
    p_adj = {}
    prev = 0.0
    for step, j in enumerate(order):
        rest = order[step:]
        maxstat = np.max(np.abs(tb[:, rest]), axis=1)
        p = (1 + np.sum(maxstat >= abs(t_obs[names[j]]))) / (B + 1)
        p = max(p, prev)                                    # monotone
        p_adj[names[j]] = p
        prev = p
    return pd.Series(t_obs), pd.Series(p_adj)


def main(path, out, B=2000, seed=20261017):
    os.makedirs(out, exist_ok=True)
    d = pd.read_csv(path)
    d["T"] = (d["arm"] == "treatment").astype(int)
    for q in QUESTIONS + OPTIONAL:
        d["y_" + q] = d[q].map(CODE).fillna(0)
    d["lean"] = d[["y_" + q for q in QUESTIONS]].mean(axis=1)
    d["abs_lean"] = d["lean"].abs()
    d["unsure"] = d[QUESTIONS].eq("unsure").mean(axis=1)
    d["equal"] = d[QUESTIONS].eq("equal").mean(axis=1)
    n, X = len(d), design(d)
    tables = {}

    # 1. counts by entry point and arm, with the exact binomial test of an even split
    rows = []
    for e in sorted(d["entry"].unique()):
        s = d[d["entry"] == e]
        nt = int(s["T"].sum())
        rows.append({"entry": e, "n": len(s), "treatment": nt, "control": len(s) - nt,
                     "p_binomial": stats.binomtest(nt, len(s), 0.5).pvalue})
    tables["counts"] = pd.DataFrame(rows)

    # 2. balance: the two pre-treatment answers by arm (chi-squared)
    rows = []
    for q in ["q1_expert", "q2_prior"]:
        ct = pd.crosstab(d[q], d["arm"])
        chi2, p, dof, _ = stats.chi2_contingency(ct)
        rows.append({"question": q, "chi2": chi2, "df": dof, "p": p})
    tables["balance"] = pd.DataFrame(rows)

    # 3. H1 and the secondary outcomes S1, S2, S4: the coefficient on T
    rows = []
    for name, y in [("H1_lean", d["lean"]), ("S1_unsure", d["unsure"]), ("S2_equal", d["equal"]),
                    ("S4_abs_lean", d["abs_lean"])]:
        b, se = ols_hc2(y, X)
        t, p = t_and_p(b["T"], se["T"], n, X.shape[1])
        rows.append({"outcome": name, "mean_control": y[d["T"] == 0].mean(), "mean_treatment": y[d["T"] == 1].mean(),
                     "coef_T": b["T"], "se_hc2": se["T"], "t": t, "p": p, "n": n})
    tables["h1"] = pd.DataFrame(rows)

    # 4. S3: each question, Romano-Wolf over the five
    outcomes = [(q, d["y_" + q]) for q in QUESTIONS]
    t_obs, p_rw = romano_wolf(d, outcomes, "T", B, seed)
    rows = []
    for q, y in outcomes:
        b, se = ols_hc2(y, X)
        t, p = t_and_p(b["T"], se["T"], n, X.shape[1])
        rows.append({"question": q, "bsz_share_control": (d.loc[d["T"] == 0, q] == "BSZ").mean(),
                     "bsz_share_treatment": (d.loc[d["T"] == 1, q] == "BSZ").mean(),
                     "jr_share_control": (d.loc[d["T"] == 0, q] == "JR").mean(),
                     "jr_share_treatment": (d.loc[d["T"] == 1, q] == "JR").mean(),
                     "coef_T": b["T"], "se_hc2": se["T"], "t": t, "p": p, "p_romano_wolf": p_rw[q]})
    tables["s3"] = pd.DataFrame(rows)

    # 5. heterogeneity H2 to H4: the interaction coefficient, Romano-Wolf over the three
    dims = {"H2_entry_explorer": lambda f: (f["entry"] == "explorer").astype(int),
            "H3_no_prior": lambda f: (f["q2_prior"] == "No").astype(int),
            "H4_expert": lambda f: f["q1_expert"].isin(["Yes", "Somewhat"]).astype(int)}

    def extra_of(h, g, f):
        """G and T x G; for the entry point, G is already a fixed effect, so only T x G is added."""
        return {"TxG": f["T"] * g(f)} if h.startswith("H2") else {"G": g(f), "TxG": f["T"] * g(f)}
    rows = []
    for h, g in dims.items():
        G = g(d)
        Xh = design(d, extra_of(h, g, d))
        b, se = ols_hc2(d["lean"], Xh)
        t, p = t_and_p(b["TxG"], se["TxG"], n, Xh.shape[1])
        rows.append({"dimension": h, "share_G1": G.mean(), "coef_TxG": b["TxG"], "se_hc2": se["TxG"], "t": t, "p": p,
                     "effect_G0": b["T"], "effect_G1": b["T"] + b["TxG"]})
    het = pd.DataFrame(rows)
    # Romano-Wolf across the three dimensions: each has its own design, so bootstrap jointly
    rng = np.random.default_rng(seed + 1)
    strata = [np.flatnonzero((d["entry"] == e).to_numpy()) for e in sorted(d["entry"].unique())]
    tb = np.zeros((B, len(dims)))
    t_obs = het["t"].to_numpy()
    b_obs = het["coef_TxG"].to_numpy()
    r = 0
    while r < B:
        idx = np.concatenate([rng.choice(s, size=len(s), replace=True) for s in strata])
        db = d.iloc[idx].reset_index(drop=True)
        try:
            for j, (h, g) in enumerate(dims.items()):
                Xb = design(db, extra_of(h, g, db))
                b, se = ols_hc2(db["lean"], Xb)
                tb[r, j] = (b["TxG"] - b_obs[j]) / se["TxG"]
        except np.linalg.LinAlgError:
            continue
        r += 1
    order = np.argsort(-np.abs(t_obs))
    p_adj = np.zeros(len(dims))
    prev = 0.0
    for step, j in enumerate(order):
        rest = order[step:]
        p = (1 + np.sum(np.max(np.abs(tb[:, rest]), axis=1) >= abs(t_obs[j]))) / (B + 1)
        prev = max(p, prev)
        p_adj[j] = prev
    het["p_romano_wolf"] = p_adj
    tables["heterogeneity"] = het

    # 6. descriptives: opt-in, email, support, minutes, quit, the optional questions
    rows = []
    for arm in ["control", "treatment"]:
        s = d[d["arm"] == arm]
        rows.append({"arm": arm, "n": len(s), "optin": s["optin"].astype(str).str.startswith("Yes").mean(),
                     "leaves_email": s["leaves_email"].astype(str).str.lower().eq("true").mean(),
                     "support_yes": (s["support"] == 1).mean(), "support_no": (s["support"] == 2).mean(),
                     "minutes_median": s["minutes"].median(), "quit_early": s["quit_early"].astype(str).str.lower().eq("true").sum()})
    tables["descriptives"] = pd.DataFrame(rows)
    rows = []
    for q in OPTIONAL:
        s = d[d[q] != "skipped"]
        rows.append({"question": q, "answered": len(s), "BSZ": (s[q] == "BSZ").sum(), "JR": (s[q] == "JR").sum(),
                     "equal": (s[q] == "equal").sum(), "unsure": (s[q] == "unsure").sum()})
    tables["optional"] = pd.DataFrame(rows)

    for name, t in tables.items():
        t.to_csv(os.path.join(out, f"{name}.csv"), index=False)
        print(f"\n== {name}")
        print(t.to_string(index=False))
    pd.DataFrame({"B": [B], "seed": [seed], "n": [n]}).to_csv(os.path.join(out, "settings.csv"), index=False)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 2000,
         int(sys.argv[4]) if len(sys.argv) > 4 else 20261017)
