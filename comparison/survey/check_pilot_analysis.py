"""Checks of pilot_analysis.py on the paths the pretests' data cannot reach.

Usage: python3 comparison/survey/check_pilot_analysis.py

Rebuilds the second pretest's explorer and share respondents as the four forms' sheet exports (the
exact question titles and choice labels of plan/forms/*.json, timestamps in Pacific time), adds
one case for each rule of section 8 (a duplicate email, a bulk burst, a burst hour, a response
after the vote, one after the close) and a draw log, runs the analysis on them, and checks the
result against the canonical file. Then runs it on fewer than 30 responses with a one-arm stratum.
Exits non-zero on the first failed check.
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np
import pandas as pd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import pilot_analysis as pa  # noqa: E402

PILOT = os.path.join(ROOT, "feedback", "009-2026-10-17-rct-pilot-2", "pilot", "responses.csv")
rng = np.random.default_rng(1)


def check(cond, msg):
    print(("ok   " if cond else "FAIL ") + msg)
    if not cond:
        sys.exit(1)


forms = {arm: json.load(open(os.path.join(HERE, "plan", "forms", f"{arm}.json"), encoding="utf-8"))
         for arm in ("control", "treatment")}
codes = pa.label_codes()
to_label = {arm: {} for arm in forms}
for (arm, mp) in codes.items():
    for (q, lab), code in mp.items():
        to_label[arm][(q, code)] = lab
p = pd.read_csv(PILOT)
p = p[p["entry"].isin(["explorer", "share"])].reset_index(drop=True)
start = pd.Timestamp("2026-10-20 09:00")


def sheet_row(r, arm, ts, email=""):
    """One pilot respondent as a row of the form's response sheet."""
    row = {"Timestamp": ts.strftime("%m/%d/%Y %H:%M:%S")}
    for it in forms[arm]["items"]:
        if it["type"] in (6, 8):
            continue
        row.setdefault(it["title"], "")
    row[pa.TITLES["q1_expert"]], row[pa.TITLES["q2_prior"]] = r["q1_expert"], r["q2_prior"]
    row[pa.TITLES["email"]] = email
    row[pa.TITLES["optin"]] = r["optin"]
    row[pa.TITLES["support"]] = pa.SUPPORT[int(r["support"])]
    for q in pa.QUESTIONS + pa.OPTIONAL:
        row[pa.TITLES[q]] = "" if r[q] == "skipped" else to_label[arm][(q, r[q])]
    return row


rows = {f: [] for f in pa.FORMS}
for i, r in p.iterrows():
    form = {v: k for k, v in pa.FORMS.items()}[(r["entry"], r["arm"])]
    ts = start + pd.Timedelta(hours=4 * i, minutes=int(rng.integers(0, 60)))
    rows[form].append(sheet_row(r, r["arm"], ts, email=f"Person{i}@Example.org " if i % 9 == 0 else ""))
n_base = len(p)
# a duplicate email, later, in the other arm's form of the same entry point: removed
r0 = p.iloc[0]
other = {v: k for k, v in pa.FORMS.items()}[(r0["entry"], "treatment" if r0["arm"] == "control" else "control")]
rows[other].append(sheet_row(r0, pa.FORMS[other][1], start + pd.Timedelta(days=9), email=" person0@example.org"))
# a bulk burst: four identical submissions to form 4 within five minutes: three removed
rb = p[p["arm"] == "treatment"].iloc[3]
for k in range(4):
    rows[4].append(sheet_row(rb, "treatment", pd.Timestamp("2026-10-25 03:01") + pd.Timedelta(minutes=k)))
# a burst hour: five varied submissions to form 6, none to form 5 that hour
for k, (_, rr) in enumerate(p[p["arm"] == "treatment"].head(5).iterrows()):
    rows[6].append(sheet_row(rr, "treatment", pd.Timestamp("2026-10-27 04:05") + pd.Timedelta(minutes=9 * k)))
# after the vote (kept, flagged) and after the close (excluded)
rows[3].append(sheet_row(p[p["arm"] == "control"].iloc[1], "control", pd.Timestamp("2026-11-03 21:30")))
rows[3].append(sheet_row(p[p["arm"] == "control"].iloc[2], "control", pd.Timestamp("2026-11-05 08:00")))

with tempfile.TemporaryDirectory() as tmp:
    args = []
    for f, rr in rows.items():
        path = os.path.join(tmp, f"form{f}.csv")
        pd.DataFrame(rr).to_csv(path, index=False)
        args += ["--form", f"{f}={path}"]
    # draws: one per submission plus 20% extra, and form 6 (share treatment) short of its submissions
    allr = [(f, pd.Timestamp(r["Timestamp"])) for f, rr in rows.items() for r in rr]
    dr = []
    for f, ts in allr:
        entry, arm = pa.FORMS[f]
        if f == 6 and rng.random() < 0.5:
            continue
        dr.append({"timestamp": (ts - pd.Timedelta(minutes=3)).strftime("%Y-%m-%d %H:%M:%S"), "entry": entry, "arm": arm})
        if rng.random() < 0.2:
            dr.append({"timestamp": (ts - pd.Timedelta(minutes=5)).strftime("%Y-%m-%d %H:%M:%S"), "entry": entry, "arm": arm})
    pd.DataFrame(dr).to_csv(os.path.join(tmp, "draws.csv"), index=False)
    out = os.path.join(tmp, "out")
    res = subprocess.run([sys.executable, os.path.join(HERE, "pilot_analysis.py"), out, *args,
                          "--draws", os.path.join(tmp, "draws.csv"), "--B", "199", "--ri", "500"],
                         capture_output=True, text=True)
    check(res.returncode == 0, "the analysis runs on the four sheet exports" + ("" if res.returncode == 0 else "\n" + res.stderr[-2000:]))
    log = pd.read_csv(os.path.join(out, "log.csv")).set_index("step")["value"]
    check(log["duplicates by email (removed)"] == "1", "the later duplicate email is removed (trimmed, lower-cased)")
    check(log["bulk rule: form 4 (removed)"] == "3", "the bulk burst keeps the first of four")
    check(log["sample: submitted after the close (excluded)"] == "1", "the response after the close is excluded")
    check("share treatment (5)" in log["burst hours removed (robustness only)"], "the burst hour is found")
    check(int(log["N, the analysis sample"]) == n_base + 1 + 1 + 5, "N = pilot + bulk first + after-vote + burst")
    h1 = pd.read_csv(os.path.join(out, "h1.csv"))
    check("after the vote" in h1["estimate"].iloc[1], "the robustness estimate carries the after-the-vote indicator")
    check(set(h1["estimate"]) >= {"robustness: no bulk removal", "robustness: without burst hours"}, "both robustness rows")
    att = pd.read_csv(os.path.join(out, "attrition.csv")).set_index("entry")
    check(not att.loc["share", "count_ok"] and "more submissions than draws" in att.loc["share", "count_failure"],
          "form 6 above its draws fails the share count")
    check(bool(att.loc["explorer", "count_ok"]), "the explorer count passes")
    # the coded answers from the sheets equal the canonical coding, respondent by respondent
    sheets = pa.load_forms({f: os.path.join(tmp, f"form{f}.csv") for f in rows})
    ok = True
    for f in pa.FORMS:
        canon = p[(p["entry"] == pa.FORMS[f][0]) & (p["arm"] == pa.FORMS[f][1])].reset_index(drop=True)
        got = sheets[sheets["form"] == f].reset_index(drop=True).head(len(canon))
        ok &= bool((canon[pa.QUESTIONS + pa.OPTIONAL].to_numpy() == got[pa.QUESTIONS + pa.OPTIONAL].to_numpy()).all())
    check(ok, "every answer read from the sheets matches the pretest's coding (A/B mapped as in section 5.1)")

    # fewer than 30 responses, one stratum with one arm: randomization inference, the stratum dropped
    small = pd.concat([p[(p["entry"] == "explorer")].head(20), p[(p["entry"] == "share") & (p["arm"] == "control")].head(6)])
    sp = os.path.join(tmp, "small.csv")
    small.to_csv(sp, index=False)
    res = subprocess.run([sys.executable, os.path.join(HERE, "pilot_analysis.py"), os.path.join(tmp, "small"),
                          "--responses", sp, "--ri", "2000"], capture_output=True, text=True)
    check(res.returncode == 0, "the analysis runs on 26 responses")
    h1 = pd.read_csv(os.path.join(tmp, "small", "h1.csv"))
    log = pd.read_csv(os.path.join(tmp, "small", "log.csv")).set_index("step")["value"]
    check(log["H1: responses in strata with one arm only (dropped)"] == "6", "the one-arm share stratum is dropped")
    check(h1["p_method"].iloc[0].startswith("randomization inference") and h1["n"].iloc[0] == 20,
          "H1 on 20 responses uses randomization inference")
# Lee bounds (section 8): explorer control submits at 60% of the treated arm's rate
f, _ = pa.prepare(p)
lb = pa.lee_bounds(f, {"explorer": (0.6, 1.0), "share": (0.8, 0.8)}).set_index("bound")
b_reg = pa.fit(f, "lean", ["T", "E"], "T")[0]
n_trim = int(round(0.4 * (f[(f.entry == "explorer") & (f.arm == "treatment")].shape[0])))
check(lb.loc["lower bound", "n"] == len(f) - n_trim and "explorer: treatment arm, 40.0%" in lb.loc["lower bound", "trimmed"],
      "Lee bounds trim 40% of the explorer treated arm, nothing in share")
check(lb.loc["lower bound", "coef_T"] <= b_reg <= lb.loc["upper bound", "coef_T"], "the Lee bounds bracket the estimate")
check(not lb["tested"].any(), "arms under 50 responses: bounds reported without a test")
print("all checks passed")
