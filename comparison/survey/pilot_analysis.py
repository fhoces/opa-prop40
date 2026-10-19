"""The registered analysis of the Prop 40 survey experiment (comparison/survey/PRE-ANALYSIS-PLAN.md).

Usage:
  python3 comparison/survey/pilot_analysis.py --responses RESPONSES.csv OUT_DIR [options]
  python3 comparison/survey/pilot_analysis.py --form 3=f3.csv --form 4=f4.csv --form 5=f5.csv \
      --form 6=f6.csv [--draws draws.csv] OUT_DIR [options]
Options: --B 2000 (bootstrap draws), --seed 20261017, --ri 10000 (randomization-inference draws),
  --thresholds comparison/survey/power/out/thresholds.tex, --force-all (runs every staged tier
  whatever N; for testing the code on a pilot only, never a registered result).

Input. Either one canonical CSV (the pretests' responses.csv: entry, arm, q1_expert, q2_prior, the
five required and five optional answers coded BSZ, JR, equal, unsure or skipped, optin, support,
and, if known, timestamp, form and email), or the four experiment forms' response sheets exported
as CSV, one per form (form 3 explorer control, 4 explorer treatment, 5 share control, 6 share
treatment). The sheets are read by the exact question titles and choice labels of the registered
form copies (comparison/survey/plan/forms/*.json). Timestamps are read as Pacific time, the
time zone of the responses sheet and of the draw count's sheet. --draws is the draw count's sheet
exported as CSV (timestamp, entry, arm; comparison/survey/draws.gs).

What it does, in the plan's order: the sample and the rules of section 8 (the collection window,
email duplicates, bulk submissions); the attrition checks (counts with an exact binomial test, the
pre-treatment answers, submissions per draw) and Lee (2009) bounds when they show differential
attrition; H1 (section 6.1; randomization inference below 30 responses and the one-arm stratum
rule of section 7), its robustness estimates (pre-treatment answers and after-the-vote indicator,
no bulk removal, no burst hours); S1 and S2; the staged families of section 7 (S3, tier 1; the
cells and differences of tiers 2 to 4, H2 to H5 in tier 2b; the questions inside each half, tier
5), each adjusted with the Romano-Wolf step-down procedure of section 6.3, run only when N reaches
the threshold in the power appendix's out/thresholds.tex; the descriptives. Writes one CSV per
table to OUT_DIR and prints them. The two pre-experiment forms are not read here (section 8).
"""
import argparse
import json
import os
import re
import sys
from itertools import combinations
from math import comb

import numpy as np
import pandas as pd
from scipy import stats

HERE = os.path.dirname(os.path.abspath(__file__))
QUESTIONS = ["share_lost", "horizon", "income_level", "court", "moved_out"]
OPTIONAL = ["avoidance", "wealth_list", "noncitizens", "real_estate", "asset_sales"]
CODE = {"BSZ": 1, "JR": -1, "equal": 0, "unsure": 0}
FORMS = {3: ("explorer", "control"), 4: ("explorer", "treatment"),
         5: ("share", "control"), 6: ("share", "treatment")}
TZ = "America/Los_Angeles"
AFTER_VOTE = pd.Timestamp("2026-11-03 20:00", tz=TZ)      # section 9
CLOSE = pd.Timestamp("2026-11-04 23:59:59", tz=TZ)        # section 9
N_RI = 30                                                  # section 7: randomization inference below 30
LEE_MIN = 50                                               # section 8: bounds without a test below 50 per arm
BULK_MIN, BULK_SPAN = 3, pd.Timedelta(minutes=10)          # section 8, bulk rule
BURST_MIN = 5                                              # section 8, burst hours
ALPHA = 0.05
# section 5.1: in the control forms, which study's value choice A is
A_IS = {"share_lost": "JR", "horizon": "JR", "income_level": "JR", "court": "BSZ", "moved_out": "JR",
        "avoidance": "BSZ", "wealth_list": "BSZ", "noncitizens": "BSZ", "real_estate": "BSZ",
        "asset_sales": "BSZ"}
TITLES = {
    "q1_expert": "Do you consider yourself an expert in tax or fiscal policy?",
    "q2_prior": "Before opening this survey, had you looked at news sources, web pages or academic studies "
                "discussing estimates of Proposition 40, the Billionaire Wealth Tax Proposal in California?",
    "email": "Your email (optional)",
    "share_lost": "The share of billionaires' income tax lost when people leave: which is more credible?",
    "horizon": "How long the lost income tax is counted: which is more credible?",
    "income_level": "Billionaires' yearly California income tax: which is more credible?",
    "court": "Discounting the revenue for the chance that courts strike the tax down: which is more credible?",
    "moved_out": "Billionaires who moved out of California before the 1 January 2026 residency date: "
                 "which is more credible?",
    "optin": "The next 5 questions in total explain up to 3% of the difference between the two analyses. "
             "Answering them makes the survey on average 55% longer. Answering them is optional.",
    "avoidance": "Wealth that escapes the tax through avoidance and evasion, beyond moving away: "
                 "which is more credible?",
    "wealth_list": "The billionaires' wealth the tax applies to: which is more credible?",
    "noncitizens": "Non-US-citizen residents: which is more credible?",
    "real_estate": "Real-estate deduction: which is more credible?",
    "asset_sales": "Extra income tax from assets sold to pay the tax: which is more credible?",
    "support": "Do you support Proposition 40?",
}
SUPPORT = {1: "Yes, I support it", 2: "No, I oppose it", 3: "Undecided", 4: "I prefer not to say"}
# the three registered dimensions (section 6.2), as 0/1 indicators
DIMS = {"expert": lambda f: f["q1_expert"].isin(["Yes", "Somewhat"]).astype(int),
        "noprior": lambda f: (f["q2_prior"] == "No").astype(int),
        "explorer": lambda f: (f["entry"] == "explorer").astype(int)}


# ---------- input ----------
def pacific(s):
    """Sheet timestamps (no zone) as Pacific time. Daylight time ends at 02:00 on 1 November 2026,
    inside the window: an hour from 01:00 to 01:59 that night is ambiguous and is read as daylight time."""
    s = pd.to_datetime(s, errors="coerce")
    return s.dt.tz_localize(TZ, ambiguous=np.ones(len(s), bool), nonexistent="shift_forward") if s.dt.tz is None \
        else s.dt.tz_convert(TZ)



def label_codes():
    """Choice label -> code for each question, per arm, from the registered form copies. The control
    form's A/B mapping is derived by matching each choice's text with the treatment form's, and must
    agree with section 5.1."""
    forms = {arm: json.load(open(os.path.join(HERE, "plan", "forms", f"{arm}.json"), encoding="utf-8"))
             for arm in ("control", "treatment")}
    items = {arm: {it["title"]: it for it in forms[arm]["items"]} for arm in forms}
    codes = {"control": {}, "treatment": {}}
    for q in QUESTIONS + OPTIONAL:
        ct, tr = items["control"][TITLES[q]], items["treatment"][TITLES[q]]
        tmap = {}
        for c in tr["choices"]:
            m = re.match(r"(BSZ|JR): (.*)", c["label"])
            tmap[c["label"]] = m.group(1) if m else None
        body = {re.match(r"(BSZ|JR): (.*)", lab).group(2).lower(): s for lab, s in tmap.items() if s}
        cmap = {}
        for c in ct["choices"]:
            m = re.match(r"([AB])\. (.*)", c["label"])
            cmap[c["label"]] = body[m.group(2).lower()] if m else None
            if m and m.group(1) == "A":
                assert cmap[c["label"]] == A_IS[q], f"{q}: the form's choice A is not section 5.1's"
        for arm, mp in (("control", cmap), ("treatment", tmap)):
            for lab, s in mp.items():
                codes[arm][(q, lab)] = s if s else {"About equally credible": "equal", "Unsure": "unsure"}[lab]
    return codes


def load_forms(paths):
    """The four forms' sheet exports -> the canonical frame."""
    codes = label_codes()
    rows = []
    for form, path in sorted(paths.items()):
        entry, arm = FORMS[form]
        s = pd.read_csv(path, dtype=str, keep_default_na=False)
        missing = [k for k in TITLES if TITLES[k] not in s.columns] + ([] if "Timestamp" in s.columns else ["Timestamp"])
        if missing:
            raise SystemExit(f"form {form}: columns not found: {missing}")
        for i, r in s.iterrows():
            row = {"id": f"f{form}-{i + 1}", "form": form, "entry": entry, "arm": arm,
                   "timestamp": r["Timestamp"], "email": r[TITLES["email"]],
                   "q1_expert": r[TITLES["q1_expert"]], "q2_prior": r[TITLES["q2_prior"]],
                   "optin": r[TITLES["optin"]], "support": r[TITLES["support"]]}
            for q in QUESTIONS + OPTIONAL:
                v = r[TITLES[q]].strip()
                if v == "":
                    if q in QUESTIONS:
                        raise SystemExit(f"form {form}, row {i + 1}: required question {q} is empty")
                    row[q] = "skipped"
                elif (q, v) in codes[arm]:
                    row[q] = codes[arm][(q, v)]
                else:
                    raise SystemExit(f"form {form}, row {i + 1}: {q}: answer not on the form: {v!r}")
            rows.append(row)
    return pd.DataFrame(rows)


def prepare(d):
    d = d.copy()
    if "support" in d and pd.api.types.is_numeric_dtype(d["support"]):
        d["support"] = d["support"].map(SUPPORT)
    for c in ("timestamp", "email", "form"):
        if c not in d:
            d[c] = np.nan
    has_ts = d["timestamp"].notna().any() and (d["timestamp"].astype(str).str.strip() != "").any()
    d["ts"] = pacific(d["timestamp"]) if has_ts else pd.NaT
    if has_ts and d["ts"].isna().any():
        raise SystemExit("a timestamp could not be read")
    if d["form"].isna().all():
        d["form"] = [{v: k for k, v in FORMS.items()}.get((e, a), np.nan) for e, a in zip(d["entry"], d["arm"])]
    for c in ("support", "optin"):
        if c in d:
            d[c] = d[c].replace("", np.nan)
    d["T"] = (d["arm"] == "treatment").astype(int)
    d["E_share"] = (d["entry"] == "share").astype(int)
    for q in QUESTIONS:
        d["y_" + q] = d[q].map(CODE)
    d["lean"] = d[["y_" + q for q in QUESTIONS]].mean(axis=1)
    d["unsure"] = d[QUESTIONS].eq("unsure").mean(axis=1)
    d["equal"] = d[QUESTIONS].eq("equal").mean(axis=1)
    em = d["email"].fillna("").astype(str).str.strip().str.lower()
    d["email_norm"] = em
    d["gives_email"] = (em != "").astype(int)
    if "leaves_email" in d and not has_ts:
        d["gives_email"] = d["leaves_email"].astype(str).str.lower().eq("true").astype(int)
    for g, fn in DIMS.items():
        d["G_" + g] = fn(d)
    return d, has_ts


def apply_rules(d, has_ts, log):
    """Section 8: the sample (forms 3 to 6, inside the window), email duplicates, bulk submissions.
    Returns the analysis sample and the sample with no bulk removal."""
    n0 = len(d)
    out = d[d["entry"].isin(["explorer", "share"])]
    log.append(("sample: not one of forms 3 to 6 (excluded)", n0 - len(out)))
    if has_ts:
        late = out["ts"] > CLOSE
        log.append(("sample: submitted after the close (excluded)", int(late.sum())))
        out = out[~late]
    # duplicates by email: the earliest by timestamp (or file order) is kept
    order = out.sort_values("ts", kind="stable") if has_ts else out
    dup = order["email_norm"].ne("") & order.duplicated("email_norm", keep="first")
    log.append(("duplicates by email (removed)", int(dup.sum())))
    out = order[~dup].sort_index()
    nobulk = out.copy()
    if has_ts:
        choice = ["q1_expert", "q2_prior", "optin", "support"] + QUESTIONS + OPTIONAL
        drop = []
        for form, s in out.groupby("form"):
            for _, g in s.sort_values("ts").groupby([s[c].astype(str) for c in choice], sort=False):
                ts, idx, i = g["ts"].tolist(), g.index.tolist(), 0
                while i < len(ts):
                    j = i
                    while j + 1 < len(ts) and ts[j + 1] - ts[i] <= BULK_SPAN:
                        j += 1
                    if j - i + 1 >= BULK_MIN:
                        drop += idx[i + 1:j + 1]       # the first is kept
                        i = j + 1
                    else:
                        i += 1
            log.append((f"bulk rule: form {int(form)} (removed)", int(sum(x in s.index for x in drop))))
        out = out.drop(index=drop)
    else:
        log.append(("bulk rule", "not applied: no timestamps"))
    return out, nobulk


# ---------- estimation ----------
def ols_hc2(y, X):
    Xm, yv = np.asarray(X, float), np.asarray(y, float)
    if np.linalg.matrix_rank(Xm) < Xm.shape[1]:
        raise np.linalg.LinAlgError("rank deficient design")
    XtX_inv = np.linalg.inv(Xm.T @ Xm)
    b = XtX_inv @ Xm.T @ yv
    e = yv - Xm @ b
    h = np.einsum("ij,jk,ik->i", Xm, XtX_inv, Xm)
    if np.any(h >= 1 - 1e-10):
        raise np.linalg.LinAlgError("an observation with leverage 1")
    V = XtX_inv @ ((Xm * (e ** 2 / (1 - h))[:, None]).T @ Xm) @ XtX_inv
    return b, np.sqrt(np.diag(V))


def term(f, t):
    """A design column: a product of base columns (T, E for E_share, or a dimension name)."""
    v = np.ones(len(f))
    for x in t.split("*"):
        v = v * (f["T"] if x == "T" else f["E_share"] if x == "E" else f["G_" + x]).to_numpy()
    return v


def fit(f, y, terms, coef):
    """OLS with HC2 of y on a constant and the terms; E is dropped when constant in f. Returns
    (b, se, n, k) for the coefficient coef."""
    if f["T"].nunique() < 2:
        raise np.linalg.LinAlgError("one arm only")
    terms = [t for t in terms if not (t == "E" and f["E_share"].nunique() < 2)]
    X = np.column_stack([np.ones(len(f))] + [term(f, t) for t in terms])
    b, se = ols_hc2(f[y], X)
    j = 1 + terms.index(coef)
    return b[j], se[j], len(f), X.shape[1]


class Test:
    """One registered test: outcome y, regressors, the coefficient tested, and the subsample
    (dimension -> value) it is estimated on."""
    def __init__(self, name, y, terms, coef, cell=None):
        self.name, self.y, self.terms, self.coef, self.cell = name, y, terms, coef, cell or {}

    def run(self, f):
        for g, v in self.cell.items():
            f = f[f["G_" + g] == v]
        return fit(f, self.y, self.terms, self.coef)


def p_t(b, se, n, k):
    t = b / se
    return t, 2 * stats.t.sf(abs(t), df=n - k)


def romano_wolf(d, tests, B, rng):
    """Romano-Wolf step-down adjusted p-values (Clarke, Romano and Wolf 2020): studentized HC2
    statistics, a pairs bootstrap that resamples respondents within each entry-point stratum."""
    obs = [t.run(d) for t in tests]
    b_obs = np.array([o[0] for o in obs])
    t_obs = np.array([o[0] / o[1] for o in obs])
    strata = [np.flatnonzero((d["entry"] == e).to_numpy()) for e in sorted(d["entry"].unique())]
    tb, r, tries = np.zeros((B, len(tests))), 0, 0
    while r < B:
        tries += 1
        if tries > 20 * B:
            raise np.linalg.LinAlgError("too many degenerate resamples")
        idx = np.concatenate([rng.choice(s, size=len(s), replace=True) for s in strata])
        db = d.iloc[idx].reset_index(drop=True)
        try:
            for j, t in enumerate(tests):
                b, se, _, _ = t.run(db)
                tb[r, j] = (b - b_obs[j]) / se
        except np.linalg.LinAlgError:
            continue
        r += 1
    order = np.argsort(-np.abs(t_obs))
    p_adj, prev = np.zeros(len(tests)), 0.0
    for step, j in enumerate(order):
        p = (1 + np.sum(np.max(np.abs(tb[:, order[step:]]), axis=1) >= abs(t_obs[j]))) / (B + 1)
        prev = max(prev, p)
        p_adj[j] = prev
    rows = []
    for t, (b, se, n, k), pa in zip(tests, obs, p_adj):
        tt, p = p_t(b, se, n, k)
        rows.append({"test": t.name, "coef": b, "se_hc2": se, "t": tt, "p": p, "p_romano_wolf": pa, "n": n})
    return pd.DataFrame(rows), tries - B


def h1_sample(d, log):
    """Section 7: a stratum with responses in one arm only is dropped."""
    keep = [e for e, s in d.groupby("entry") if s["T"].nunique() == 2]
    dropped = d[~d["entry"].isin(keep)]
    log.append(("H1: responses in strata with one arm only (dropped)", len(dropped)))
    return d[d["entry"].isin(keep)]


def h1_row(name, f, y="lean", terms=("T", "E"), extra=(), rng=None, R=0):
    terms = list(terms) + list(extra)
    b, se, n, k = fit(f, y, terms, "T")
    t, p = p_t(b, se, n, k)
    crit = stats.t.ppf(0.975, n - k)
    row = {"estimate": name, "n": n, "n_treated": int(f["T"].sum()), "mean_control": f.loc[f["T"] == 0, y].mean(),
           "coef_T": b, "se_hc2": se, "ci_low": b - crit * se, "ci_high": b + crit * se, "t": t,
           "p": p, "p_method": "t distribution"}
    if R and n < N_RI:
        row["p"], row["p_method"], row["ri_failed"] = ri_pvalue(f, y, terms, t, rng, R)
        row["p_method"] = f"randomization inference ({R:,} re-assignments)"
    return row


def safe_row(name, f, **kw):
    """h1_row, or a row saying why the estimate cannot be computed (too few responses, one arm)."""
    try:
        return h1_row(name, f, **kw)
    except np.linalg.LinAlgError as err:
        return {"estimate": name, "n": len(f), "p_method": f"not estimable: {err}"}


def ri_pvalue(f, y, terms, t_obs, rng, R):
    """Section 7: T re-assigned within strata, each stratum's number treated kept; the HC2 t of beta."""
    f = f.reset_index(drop=True)
    groups = [np.flatnonzero((f["entry"] == e).to_numpy()) for e in f["entry"].unique()]
    hits, failed = 0, 0
    for _ in range(R):
        g = f.copy()
        Tn = g["T"].to_numpy().copy()
        for idx in groups:
            Tn[idx] = rng.permutation(Tn[idx])
        g["T"] = Tn
        try:
            b, se, _, _ = fit(g, y, terms, "T")
        except np.linalg.LinAlgError:
            failed += 1
            continue
        hits += abs(b / se) >= abs(t_obs) - 1e-12
    return hits / (R - failed), "", failed


# ---------- attrition ----------
def attrition(d, draws, log):
    rows, flagged = [], {}
    for e, s in d.groupby("entry"):
        nt, nc = int(s["T"].sum()), int((1 - s["T"]).sum())
        row = {"entry": e, "submissions_control": nc, "submissions_treatment": nt,
               "p_binomial": stats.binomtest(nt, nt + nc, 0.5).pvalue}
        count_ok, why = draws is not None, "no draw count" if draws is None else ""
        if draws is not None:
            de = draws[draws["entry"] == e]
            dc, dt = int((de["arm"] == "control").sum()), int((de["arm"] == "treatment").sum())
            row.update(draws_control=dc, draws_treatment=dt)
            if nc > dc or nt > dt:
                count_ok, why = False, "a form has more submissions than draws"
            elif "ts" in s and s["ts"].notna().all() and len(s):
                sub_days = set(s["ts"].dt.date)
                draw_days = set(de["ts"].dt.date)
                if sub_days - draw_days:
                    count_ok, why = False, "a day with submissions and no draw"
            if count_ok and dc > 0 and dt > 0:
                p1, p2 = nc / dc, nt / dt
                pp = (nc + nt) / (dc + dt)
                z = (p2 - p1) / np.sqrt(pp * (1 - pp) * (1 / dc + 1 / dt)) if 0 < pp < 1 else 0.0
                row.update(rate_control=p1, rate_treatment=p2, p_two_proportions=2 * stats.norm.sf(abs(z)))
        row["count_ok"], row["count_failure"] = count_ok, why
        differential = row.get("p_two_proportions", 1.0) < ALPHA if count_ok else row["p_binomial"] < ALPHA
        row["differential_attrition"] = bool(differential)
        flagged[e] = (row.get("rate_control", nc) if count_ok else nc, row.get("rate_treatment", nt) if count_ok else nt)
        rows.append(row)
    return pd.DataFrame(rows), flagged


def lee_bounds(d, rates):
    """Section 8: within each entry point the arm with the higher rate is trimmed by (qH - qL)/qH,
    from the top and from the bottom of its lean index; the H1 equation on the trimmed samples."""
    lo_parts, hi_parts, shares = [], [], {}
    for e, s in d.groupby("entry"):
        qc, qt = rates[e]
        high = "treatment" if qt > qc else "control"
        qh, ql = max(qc, qt), min(qc, qt)
        p = (qh - ql) / qh if qh > 0 else 0.0
        shares[e] = (high, p)
        h = s[s["arm"] == high].sort_values(["lean", "id"], kind="stable")
        k = int(round(p * len(h)))
        rest = s[s["arm"] != high]
        top_cut, bottom_cut = h.iloc[:len(h) - k], h.iloc[k:]
        # trimming the treated arm's top lowers the effect; trimming the control arm's bottom lowers it
        lo_parts.append(pd.concat([rest, top_cut if high == "treatment" else bottom_cut]))
        hi_parts.append(pd.concat([rest, bottom_cut if high == "treatment" else top_cut]))
    rows = []
    for name, parts in (("lower bound", lo_parts), ("upper bound", hi_parts)):
        f = pd.concat(parts)
        b, se, n, k = fit(f, "lean", ["T", "E"], "T")
        small = min(f.groupby(["entry", "arm"]).size()) < LEE_MIN
        rows.append({"bound": name, "coef_T": b, "se_hc2": np.nan if small else se, "n": n,
                     "tested": not small, "trimmed": "; ".join(f"{e}: {a} arm, {p:.1%}" for e, (a, p) in shares.items())})
    return pd.DataFrame(rows)


def burst_sample(d, log):
    """Section 8: without every clock hour (Pacific) in which one form had five or more submissions
    while its pair's form had none."""
    hour = d["ts"].dt.floor("h")
    drop = pd.Series(False, index=d.index)
    removed = []
    for e, s in d.groupby("entry"):
        for h, sh in s.groupby(hour[s.index]):
            counts = sh["arm"].value_counts()
            for arm in ("control", "treatment"):
                other = "treatment" if arm == "control" else "control"
                if counts.get(arm, 0) >= BURST_MIN and counts.get(other, 0) == 0:
                    drop[sh.index[sh["arm"] == arm]] = True
                    removed.append(f"{h:%Y-%m-%d %H}:00 {e} {arm} ({counts[arm]})")
    log.append(("burst hours removed (robustness only)", "; ".join(removed) or "none"))
    return d[~drop]


# ---------- the staged rule ----------
def read_thresholds(path):
    """Tier -> N* at the registered target (first N* column) from the power appendix's table."""
    out = {}
    for line in open(path, encoding="utf-8"):
        cells = [c.strip() for c in line.split("&")]
        if len(cells) >= 4 and re.fullmatch(r"\d[ab]?", cells[0]):
            out[cells[0]] = int(re.sub(r"[^\d]", "", re.sub(r"\$.*?\$", "", cells[3])))
    return out


def families(d):
    """The staged families of section 7, as lists of tests."""
    dims = list(DIMS)
    fam = {"1": [Test(q, "y_" + q, ["T", "E"], "T") for q in QUESTIONS]}
    fam["2a"] = [Test(f"{g}={v}", "lean", ["T", "E"], "T", {g: v}) for g in dims for v in (1, 0)]
    fam["2b"] = [Test(f"H{2 + i}: T x {g}", "lean", ["T", "T*" + g] + ([] if g == "explorer" else [g, "E"]) +
                      (["E"] if g == "explorer" else []), "T*" + g) for i, g in enumerate(["explorer", "noprior", "expert"])]
    fam["2b"].append(Test("H5: experts without prior exposure", "lean", ["T", "E"], "T", {"expert": 1, "noprior": 1}))
    fam["3a"] = [Test(f"{g1}={v1}, {g2}={v2}", "lean", ["T", "E"], "T", {g1: v1, g2: v2})
                 for g1, g2 in combinations(dims, 2) for v1 in (1, 0) for v2 in (1, 0)]

    def saturated(gs):
        terms = ["T"]
        for r in range(1, len(gs) + 1):
            for c in combinations(gs, r):
                terms += ["*".join(c), "T*" + "*".join(c)]
        return terms + ([] if "explorer" in gs else ["E"])
    fam["3b"] = [Test(f"T x {g1} x {g2}", "lean", saturated([g1, g2]), "T*" + g1 + "*" + g2)
                 for g1, g2 in combinations(dims, 2)]
    fam["4a"] = [Test(", ".join(f"{g}={v}" for g, v in zip(dims, vs)), "lean", ["T", "E"], "T", dict(zip(dims, vs)))
                 for vs in [(a, b, c) for a in (1, 0) for b in (1, 0) for c in (1, 0)]]
    fam["4b"] = [Test("T x " + " x ".join(dims), "lean", saturated(dims), "T*" + "*".join(dims))]
    fam["5"] = [Test(f"{q} | {g}={v}", "y_" + q, ["T", "E"], "T", {g: v}) for q in QUESTIONS for g in dims for v in (1, 0)]
    sizes = {"1": 5, "2a": 6, "2b": 4, "3a": 12, "3b": 3, "4a": 8, "4b": 1, "5": 30}
    assert all(len(fam[k]) == v for k, v in sizes.items()) and sizes["3a"] == comb(3, 2) * 4
    return fam


PREREQ = {"3a": "2a", "3b": "2b", "4a": "3a", "4b": "3b"}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("--responses")
    ap.add_argument("--form", action="append", default=[])
    ap.add_argument("--draws")
    ap.add_argument("--B", type=int, default=2000)
    ap.add_argument("--seed", type=int, default=20261017)
    ap.add_argument("--ri", type=int, default=10000)
    ap.add_argument("--thresholds", default=os.path.join(HERE, "power", "out", "thresholds.tex"))
    ap.add_argument("--force-all", action="store_true")
    a = ap.parse_args()
    if bool(a.responses) == bool(a.form):
        sys.exit("give either --responses or the --form exports")
    os.makedirs(a.out, exist_ok=True)
    raw = pd.read_csv(a.responses) if a.responses else load_forms({int(k): v for k, v in (x.split("=", 1) for x in a.form)})
    d, has_ts = prepare(raw)
    draws = None
    if a.draws:
        draws = pd.read_csv(a.draws)
        draws["ts"] = pacific(draws["timestamp"])
        draws = draws[draws["entry"].isin(["explorer", "share"]) & (draws["ts"] <= CLOSE)]
    rng = np.random.default_rng(a.seed)       # set once, before the first draw (section 6.3)
    log, tables = [], {}
    d, nobulk = apply_rules(d, has_ts, log)
    N = len(d)
    log.append(("N, the analysis sample", N))

    # checks (section 8)
    tables["counts"] = d.groupby(["entry", "arm"]).size().unstack(fill_value=0).reset_index()
    att, rates = attrition(d, draws, log)
    tables["attrition"] = att
    rows = []
    for q in ["q1_expert", "q2_prior"]:
        ct = pd.crosstab(d[q], d["arm"])
        chi2, p, dof, _ = stats.chi2_contingency(ct) if ct.shape[0] > 1 and ct.shape[1] > 1 else (np.nan, np.nan, 0, None)
        rows.append({"question": q, "chi2": chi2, "df": dof, "p": p})
    tables["balance"] = pd.DataFrame(rows)

    # H1 (section 6.1) and its robustness estimates
    f = h1_sample(d, log)
    rows = [safe_row("H1, as registered", f, rng=rng, R=a.ri)]
    rob = f.copy()
    extra = []
    for c, v in (("q1_expert", "Yes"), ("q1_expert", "Somewhat"), ("q2_prior", "Yes"), ("q2_prior", "Not sure")):
        rob[f"G_{c}_{v}"] = (rob[c] == v).astype(int)
        extra.append(f"{c}_{v}")
    if has_ts and (rob["ts"] > AFTER_VOTE).any():
        rob["G_after_vote"] = (rob["ts"] > AFTER_VOTE).astype(int)
        extra.append("after_vote")
    rows.append(safe_row("robustness: pre-treatment answers" + (", after the vote" if "after_vote" in extra else ""),
                       rob, extra=extra))
    if has_ts:
        rows.append(safe_row("robustness: no bulk removal", h1_sample(nobulk, [])))
        rows.append(safe_row("robustness: without burst hours", h1_sample(burst_sample(d, log), [])))
    for e in sorted(d["entry"].unique()):
        log.append((f"H1 sample, {e}: control / treatment",
                    f"{int((f.loc[f.entry == e, 'T'] == 0).sum())} / {int(f.loc[f.entry == e, 'T'].sum())}"))
    h1 = pd.DataFrame(rows)
    sd0 = f.loc[f["T"] == 0, "lean"].std()
    h1 = h1.reindex(columns=list(h1.columns) + ([] if "se_hc2" in h1 else ["se_hc2"]))
    h1["mde_index_units"] = (stats.norm.ppf(0.975) + stats.norm.ppf(0.8)) * h1["se_hc2"]
    h1["mde_sd_units"] = h1["mde_index_units"] / sd0
    tables["h1"] = h1
    if att["differential_attrition"].any():
        tables["lee_bounds"] = lee_bounds(f, rates)
    log.append(("Lee bounds", "reported: differential attrition" if att["differential_attrition"].any()
                else "not required: no differential attrition"))

    # S1, S2 (one test each, any N)
    tables["s1_s2"] = pd.DataFrame([dict(safe_row(name, f, y=y), outcome=name) for name, y in
                                    (("S1, share Unsure", "unsure"), ("S2, share About equally credible", "equal"))])

    # the staged families (section 7)
    thr = read_thresholds(a.thresholds)
    fam, ran, status = families(f), set(), []
    for tier in ["1", "2a", "2b", "3a", "3b", "4a", "4b", "5"]:
        need = thr[tier]
        if tier in PREREQ and PREREQ[tier] not in ran and not a.force_all:
            status.append({"tier": tier, "tests": len(fam[tier]), "threshold": need, "N": N,
                           "status": f"not run: tier {PREREQ[tier]} was not run"})
            continue
        if N < need and not a.force_all:
            status.append({"tier": tier, "tests": len(fam[tier]), "threshold": need, "N": N,
                           "status": "not run: below its threshold"})
            continue
        try:
            if len(fam[tier]) == 1:
                b, se, n, k = fam[tier][0].run(f)
                t, p = p_t(b, se, n, k)
                res, redrawn = pd.DataFrame([{"test": fam[tier][0].name, "coef": b, "se_hc2": se, "t": t, "p": p, "n": n}]), 0
            else:
                res, redrawn = romano_wolf(f, fam[tier], a.B, rng)
            tables["tier_" + tier] = res
            ran.add(tier)
            st = "run" if N >= need else "FORCED (below threshold; not a registered result)"
            status.append({"tier": tier, "tests": len(fam[tier]), "threshold": need, "N": N, "status": st,
                           "degenerate_resamples_redrawn": redrawn})
        except np.linalg.LinAlgError as err:
            status.append({"tier": tier, "tests": len(fam[tier]), "threshold": need, "N": N,
                           "status": f"not estimable: {err}"})
    tables["staged_rule"] = pd.DataFrame(status)

    # descriptives
    rows = []
    for q in QUESTIONS:
        for arm, s in f.groupby("arm"):
            rows.append({"question": q, "arm": arm, "BSZ": (s[q] == "BSZ").mean(), "JR": (s[q] == "JR").mean(),
                         "equal": (s[q] == "equal").mean(), "unsure": (s[q] == "unsure").mean()})
    tables["s3_answer_shares"] = pd.DataFrame(rows)
    rows = []
    for arm, s in d.groupby("arm"):
        r = {"arm": arm, "n": len(s), "opted_in": s["optin"].astype(str).str.startswith("Yes").mean(),
             "gives_email": s["gives_email"].mean(),
             "answered_support": s["support"].notna().mean() if s["support"].dtype == object else np.nan}
        for lab in SUPPORT.values():
            r[lab] = (s["support"] == lab).mean()
        rows.append(r)
    tables["descriptives"] = pd.DataFrame(rows)
    rows = []
    for q in OPTIONAL:
        for arm, s in d.groupby("arm"):
            a_ = s[s[q] != "skipped"]
            rows.append({"question": q, "arm": arm, "answered": len(a_), "BSZ": (a_[q] == "BSZ").sum(),
                         "JR": (a_[q] == "JR").sum(), "equal": (a_[q] == "equal").sum(), "unsure": (a_[q] == "unsure").sum()})
    tables["optional"] = pd.DataFrame(rows)
    tables["prior_by_entry"] = pd.crosstab(d["q2_prior"], d["entry"]).reset_index()
    em = f[f["gives_email"] == 1]
    tables["email_respondents"] = pd.DataFrame([safe_row("H1 among respondents who give an email (descriptive)", em)])
    tables["log"] = pd.DataFrame(log, columns=["step", "value"])

    for name, t in tables.items():
        t.to_csv(os.path.join(a.out, f"{name}.csv"), index=False)
        print(f"\n== {name}")
        print(t.to_string(index=False))
    pd.DataFrame({"B": [a.B], "seed": [a.seed], "ri": [a.ri], "N": [N], "force_all": [a.force_all]}).to_csv(
        os.path.join(a.out, "settings.csv"), index=False)


if __name__ == "__main__":
    main()
