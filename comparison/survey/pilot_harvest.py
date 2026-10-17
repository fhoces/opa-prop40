"""Harvest the simulated pilot (feedback/008-2026-10-17-rct-pilot) from the workflow journal.

Usage: python3 comparison/survey/pilot_harvest.py JOURNAL.jsonl OUT_DIR [SEED_OFFSET]

SEED_OFFSET (default 0) is the workflow's persona seed offset: the second pilot seeds respondent i
with i + 1 + 100, so its hundred personas differ from the first pilot's.

Writes OUT_DIR/pilot/personas.csv, responses.csv (one row per respondent, choices as the survey's
numbers and as BSZ/JR/equal/unsure codes), responses.json (everything, including free text), and
summary.md (counts by arm and entry point, the lean index by arm, opt-in and quit rates). Also picks
the ten respondents to interview, seeded, into OUT_DIR/interviews/sample.json.
"""
import csv
import json
import os
import random
import statistics
import sys

# Which choice number is the BSZ value in each required question, in the order the pilot's survey
# text numbers them (from the mock: A/B order of the live version 1; see mock_forms.py).
BSZ_CHOICE = {"q3": 2, "q5": 2, "q7": 2, "q9": 1, "q11": 2, "q14": 1, "q15": 1, "q16": 1, "q17": 1, "q18": 1}
REQUIRED = ["q3", "q5", "q7", "q9", "q11"]
OPTIONAL = ["q14", "q15", "q16", "q17", "q18"]
NAMES = {"q3": "share_lost", "q5": "horizon", "q7": "income_level", "q9": "court", "q11": "moved_out",
         "q14": "avoidance", "q15": "wealth_list", "q16": "noncitizens", "q17": "real_estate", "q18": "asset_sales"}


def code(q, v):
    if not v:
        return "skipped"
    if v == BSZ_CHOICE[q]:
        return "BSZ"
    if v == 3:
        return "equal"
    if v == 4:
        return "unsure"
    return "JR"


def lean(ans):
    return sum({"BSZ": 1, "JR": -1}.get(code(q, ans[q]), 0) for q in REQUIRED) / len(REQUIRED)


BACKGROUNDS = [
    'professor of public finance at a research university', 'labor economist at a think tank', 'tax lawyer in private practice',
    'legislative budget staffer in Sacramento', 'business journalist covering California', 'policy analyst at a progressive advocacy group',
    'policy analyst at a free-market think tank', 'PhD student in economics', 'software engineer with no economics training',
    'retired high-school teacher who votes in every election', 'small business owner in Fresno', 'venture capitalist in Palo Alto',
    'union research director', 'city council member in a mid-sized California city', 'wealth manager advising high-net-worth clients',
    'statistician at a state agency', 'political science professor', 'nurse who reads the news on her phone', 'accountant (CPA) with wealthy clients',
    'graduate student in public policy',
]
KNOWLEDGE = ['has never heard of Proposition 40', 'has heard of Proposition 40 from headlines only', 'has read news coverage of the two competing estimates',
             'has read at least one of the two studies (BSZ or JR)', 'knows the wealth-tax literature well (Saez, Zucman, Rauh, Brulhart)']
POLITICS = ['strongly progressive', 'liberal', 'moderate', 'conservative', 'libertarian']
WT_VIEW = ['favors wealth taxes', 'opposed to wealth taxes', 'undecided about wealth taxes']
ATTENTION = ['reads everything carefully', 'skims and answers quickly', 'reads the questions but skips long explanations']
AGE = ['late 20s', '30s', '40s', '50s', '60s', '70s']
PLACE = ['lives in California', 'lives in California', 'lives in California', 'lives outside California']
M32 = 0xFFFFFFFF


OFFSET = 0


def persona(i):
    """The workflow script's seeded persona generator, replicated bit for bit (32-bit LCG)."""
    s = ((i + 1 + OFFSET) * 2654435761 + 1013904223) & M32

    def r():
        nonlocal s
        s = (s * 1664525 + 1013904223) & M32
        return s / 4294967296

    pick = lambda a: a[int(r() * len(a))]
    return {"id": i + 1, "background": pick(BACKGROUNDS), "knowledge": pick(KNOWLEDGE), "politics": pick(POLITICS),
            "wt_view": pick(WT_VIEW), "attention": pick(ATTENTION), "age": pick(AGE), "place": pick(PLACE),
            "entry": ["landing", "explorer", "share"][int(r() * 3)], "arm": "treatment" if r() < 0.5 else "control"}


def load(journal):
    """'started' records carry the label and agent id; 'result' records carry the answers and agent id."""
    recs = []
    for line in open(journal):
        try:
            recs.append(json.loads(line))
        except ValueError:
            pass
    labels = {r["agentId"]: r["label"] for r in recs if isinstance(r, dict) and r.get("type") == "started"}
    rows = {}
    for rec in recs:
        if not (isinstance(rec, dict) and rec.get("type") == "result"):
            continue
        a, lab = rec.get("result"), labels.get(rec.get("agentId"), "")
        if not (isinstance(a, dict) and "q3" in a and lab.startswith("r")):
            continue
        rid, path = lab.split(" ", 1)
        p = persona(int(rid[1:]) - 1)
        assert path == f"{p['entry']}/{p['arm']}", (lab, p)
        rows[p["id"]] = {"persona": p, "answers": a}
    return list(rows.values())


def main(journal, out):
    data = load(journal)
    if not data:
        raise SystemExit("no respondent records found in the journal")
    os.makedirs(os.path.join(out, "pilot"), exist_ok=True)
    os.makedirs(os.path.join(out, "interviews"), exist_ok=True)
    data.sort(key=lambda r: r["persona"]["id"])
    with open(os.path.join(out, "pilot", "responses.json"), "w") as f:
        json.dump(data, f, indent=1)
    pk = ["id", "background", "knowledge", "politics", "wt_view", "attention", "age", "place", "entry", "arm"]
    with open(os.path.join(out, "pilot", "personas.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(pk)
        for r in data:
            w.writerow([r["persona"][k] for k in pk])
    cols = ["id", "entry", "arm", "q1_expert", "q2_prior"]
    for q in REQUIRED + OPTIONAL:
        cols += [f"{NAMES[q]}_n", f"{NAMES[q]}"]
    cols += ["lean", "optin", "leaves_email", "support", "minutes", "quit_early"]
    with open(os.path.join(out, "pilot", "responses.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for r in data:
            a, p = r["answers"], r["persona"]
            row = [p["id"], p["entry"], p["arm"], a["q1_expert"], a["q2_prior"]]
            for q in REQUIRED + OPTIONAL:
                row += [a[q], code(q, a[q])]
            row += [round(lean(a), 2), a["q13_optin"], a["q21_leaves_email"], a["q22_support"],
                    a["minutes_taken"], a["quit_early"]]
            w.writerow(row)
    # summary
    by = lambda key: {k: [r for r in data if r["persona"][key] == k] for k in sorted({r["persona"][key] for r in data})}
    L = []
    L.append(f"# Pilot summary: {len(data)} simulated respondents\n")
    L.append("| Arm | n | mean lean | SD | unsure share | opt-in | quit early | mean minutes |")
    L.append("|---|---|---|---|---|---|---|---|")
    for arm, rs in by("arm").items():
        leans = [lean(r["answers"]) for r in rs]
        uns = statistics.mean(sum(code(q, r["answers"][q]) == "unsure" for q in REQUIRED) / 5 for r in rs)
        L.append(f"| {arm} | {len(rs)} | {statistics.mean(leans):.2f} | {statistics.pstdev(leans):.2f} | {uns:.2f} | "
                 f"{statistics.mean(r['answers']['q13_optin'].startswith('Yes') for r in rs):.2f} | "
                 f"{sum(r['answers']['quit_early'] for r in rs)} | {statistics.mean(r['answers']['minutes_taken'] for r in rs):.1f} |")
    L.append("\n| Entry | n | treatment | mean lean (T) | mean lean (C) |")
    L.append("|---|---|---|---|---|")
    for e, rs in by("entry").items():
        t = [lean(r["answers"]) for r in rs if r["persona"]["arm"] == "treatment"]
        c = [lean(r["answers"]) for r in rs if r["persona"]["arm"] == "control"]
        L.append(f"| {e} | {len(rs)} | {len(t)} | {statistics.mean(t) if t else float('nan'):.2f} | {statistics.mean(c) if c else float('nan'):.2f} |")
    L.append("\n| Question | BSZ | JR | equal | unsure | skipped |")
    L.append("|---|---|---|---|---|---|")
    for q in REQUIRED + OPTIONAL:
        cs = [code(q, r["answers"][q]) for r in data]
        L.append(f"| {NAMES[q]} | " + " | ".join(str(cs.count(k)) for k in ("BSZ", "JR", "equal", "unsure", "skipped")) + " |")
    with open(os.path.join(out, "pilot", "summary.md"), "w") as f:
        f.write("\n".join(L) + "\n")
    # interview sample: ten respondents, seeded, stratified by arm (5 and 5)
    rnd = random.Random(20261017)
    sample = []
    for arm in ("treatment", "control"):
        pool = [r["persona"]["id"] for r in data if r["persona"]["arm"] == arm]
        sample += rnd.sample(pool, min(5, len(pool)))
    with open(os.path.join(out, "interviews", "sample.json"), "w") as f:
        json.dump(sorted(sample), f)
    print("\n".join(L))
    print("interview sample:", sorted(sample))


if __name__ == "__main__":
    if len(sys.argv) > 3:
        OFFSET = int(sys.argv[3])
    main(sys.argv[1], sys.argv[2])
