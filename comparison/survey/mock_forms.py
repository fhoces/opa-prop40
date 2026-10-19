"""Mock previews of the survey's control and treatment forms (pre-analysis plan, section 4).

Usage: python3 comparison/survey/mock_forms.py ITEMS.json OUT_DIR

ITEMS.json is the live form's item list (title, help, choices), read from its public page. The
treatment page's numbers come from comparison/export/r/dial_path.csv and inputs.csv, the files the
explorer's walk reads, so nothing on the page is typed. Writes OUT_DIR/control.html and
OUT_DIR/treatment.html. These are previews only: the real forms are built in Google Forms.
"""
import csv
import html
import json
import os
import re
import sys
from fractions import Fraction

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EXP = os.path.join(ROOT, "comparison", "export", "r")


def read(name):
    with open(os.path.join(EXP, name), newline="") as f:
        return list(csv.DictReader(f))


steps = {r["step_id"]: float(r["change"]) for r in read("dial_path.csv")}
path = read("dial_path.csv")
high, low = float(path[0]["from"]), float(path[-1]["to"])
gap = high - low
inp = {r["input"]: r for r in read("inputs.csv")}


def v(name, side):
    return float(inp[name][side + "_value"])


def pct(x, d=0):
    return f"{100 * x:.{d}f}%"


def _csv(path, key, col="value"):
    with open(os.path.join(ROOT, path), newline="") as f:
        return float(next(r for r in csv.DictReader(f) if r[next(iter(r))] == key)[col])


# The old question on departures, avoidance and the share lost becomes three questions, so both
# choices of each answer the same thing (author, 2026-10-17): who moved out in time (group 3),
# avoidance and evasion by those who stay (group 4), and the share of income tax lost (group 1).
# BSZ's 10% allowance is half people moving away in time (BSZ PDF p.24); JR counts seven named moves.
_alpha = _csv("bsz-analysis/export/r/inputs.csv", "avoidance_rate")
_mob = _csv("bsz-analysis/export/r/inputs.csv", "mobility_share")
_jr_moved = 1 - _csv("rjkdc-analysis/export/r/inputs.csv", "nber_ceiling_hardcoded") / \
    _csv("rjkdc-analysis/export/r/outputs.csv", "nber_domestic_grown")
# Counts, lists and rates the question texts quote, read from the two analyses' exports (no typed number).
_rate = _csv("bsz-analysis/export/r/inputs.csv", "tax_rate")
_bsz_n = int(_csv("bsz-analysis/export/r/inputs.csv", "n_billionaires"))
_bsz_list = _csv("bsz-analysis/export/r/inputs.csv", "baseline_net_worth")
_jr_n = int(_csv("rjkdc-analysis/export/r/inputs.csv", "n_billionaires"))
_jr_growth = _csv("rjkdc-analysis/export/r/inputs.csv", "nber_growth_rate")
# The comparison page's equation: four terms, each a group of walk steps, in the walk's order. The
# lost income tax is a product of how long it is counted, the share lost and the yearly amount, so
# it stays one term: splitting it among its factors would depend on the order they are changed in.
H_B = f"{v('H', 'bsz'):.0f} years"
# The values in part 1 follow the share-lost question: a share no larger, or larger, than the share of
# wealth that leaves (pilot 008: the old "only the leavers' own income tax" was read three ways).
TERMS = [
    ("loss", "The income tax lost when billionaires leave: the share lost, how long it is counted, and "
     "billionaires' yearly income tax, together",
     ["income_loss_share", "income_level", "horizon", "discount_rate"],
     f"{pct(_alpha * _mob)} of all the income tax that billionaires pay is lost; counted for {H_B}; "
     f"${v('C', 'bsz'):.2f} billion a year",
     f"{pct(v('f0', 'jr'))} of all the income tax that billionaires pay is lost; counted for ever; "
     f"${v('C', 'jr'):.2f} billion a year"),
    ("court", "Discounting the revenue for court risk", ["litigation_survival"],
     "no discount", f"a {pct(v('q', 'jr'))} discount"),
    ("departed", "Billionaires who moved out in time", ["confirmed_departures"],
     f"no billionaire counted by name (its allowance for {pct(_alpha * _mob)} of the wealth moving away in time "
     "is in part 4)",
     "seven billionaires counted on public reports of their moves"),
    # the fourth term is one short line without values (author, 2026-10-17: it took too much space)
    ("other", "Other inputs together: the wealth on the list, avoidance, and three smaller inputs",
     ["base_list", "avoidance", "minor_inputs"], None, None),
]
SHORT = {"loss": "the income tax lost when billionaires leave", "court": "the chance the tax survives in court",
         "departed": "the billionaires counted as gone", "other": "three other inputs"}
assert sorted(s for r in TERMS for s in r[2]) == sorted(steps), "every walk step belongs to one term"
rows = [(key, t, sum(steps[s] for s in ss), hi, lo) for key, t, ss, hi, lo in TERMS]
assert abs(sum(r[2] for r in rows) + gap) < 1e-6, "the terms add up to the gap"
by_size = sorted(rows, key=lambda r: -abs(r[2]))
top2 = by_size[:2]


def money(x, sign=True):
    s = f"${abs(x):,.1f} billion"
    return ("+" if x > 0 else "\u2212") + s if sign else s


def amount(x):
    if x <= 0:
        return f"{money(-x, False)}, {pct(-x / gap)} of the gap"
    return f"{money(x)}, offsetting {pct(x / gap)} of the gap"


# The two studies on separate bullets, called academic studies (author, 2026-10-17). No venue on
# either: both are NBER papers, and "NBER" on one side only was a prestige cue (review 008, F12).
STUDIES_LEAD = "Two academic studies estimate what Proposition 40 is worth to California:"
STUDIES = [f"Boll, Saez and Zucman (BSZ, August 2026): {money(high)}.",
           f"Jaros and Rauh (JR, September 2026): {money(low)}."]
INTRO = [
    f"The gap is {money(gap, False)}. Both are on one measure: the wealth tax collected, plus the extra "
    "income tax from assets sold to pay it, minus the income tax lost when people leave.",
    f"Two parts explain {pct(-(top2[0][2] + top2[1][2]) / gap)} of the gap: {SHORT[top2[0][0]]}, and "
    f"{SHORT[top2[1][0]]}. Below, how much of the gap each part explains, with each study's values for the "
    "first three.",
]
# Two short sentences in place of the old note on the explorer's equation, which the pilot's treated
# respondents skipped or misread (review 008, F8).
NOTE = ("The income tax lost is shown as one amount because its three inputs multiply each other. For the "
        "same reason, each amount depends on the order in which the inputs are changed.")
CLOSE = "The questions that follow ask which study's value of each input you find more credible."
# The control forms' inputs section help, set after launch (plan, deviations, 2026-10-19): the author found that
# control respondents met the input questions with no context. It names no study, value or sign; the treatment
# page already states the same measure, so the treatment forms keep the source form's one line.
CONTROL_INPUTS = ("Estimates of what Proposition 40 is worth to California add up three things: the wealth tax "
                  "collected, the extra income tax from assets sold to pay it, and the income tax lost when "
                  "billionaires leave the state. Each question below is one input to that sum, such as the share of "
                  "income tax lost when billionaires leave, or the chance that the tax survives in court. Two values "
                  "have been proposed for each input. Pick the one you find more credible. If neither stands out, "
                  "say they are about equally credible or that you can't judge it.")


def treatment_page():
    top = abs(by_size[0][2])
    li = []
    for key, t, x, hi, lo in by_size:
        cls = " class='up'" if x > 0 else ""
        li.append(f"<li><div class='rt'><b>{html.escape(t)}</b></div>"
                  f"<div class='bar'><span{cls} style='width:{65 * abs(x) / top:.1f}%'></span>"
                  f"<em>{html.escape(amount(x))}</em></div>"
                  + (f"<div class='vals'>BSZ: {html.escape(hi)}.<br>JR: {html.escape(lo)}.</div>" if hi else "")
                  + "</li>")
    return f"""
<div class="card head2"><h2>How the two estimates differ</h2></div>
<div class="card">
<p>{html.escape(STUDIES_LEAD)}</p>
<ul>{''.join(f"<li>{html.escape(s)}</li>" for s in STUDIES)}</ul>
<p>{html.escape(INTRO[0])}</p>
<p>{html.escape(INTRO[1])}</p>
<ol class="rows">{''.join(li)}</ol>
<p class="note">{html.escape(NOTE)}</p>
<p>{html.escape(CLOSE)}</p>
</div>"""


CSS = """
body{margin:0;background:#f0ebf8;font:15px/1.45 Roboto,Arial,sans-serif;color:#202124}
.wrap{max-width:720px;margin:0 auto;padding:16px}
.mock{background:#fff3cd;border:1px solid #e0c46c;border-radius:8px;padding:8px 12px;margin-bottom:12px;font-size:13px}
.card{background:#fff;border:1px solid #dadce0;border-radius:8px;padding:20px 24px;margin-bottom:12px}
.top{border-top:10px solid #673ab7}.head2{background:#673ab7;color:#fff;border:0;padding:10px 24px}
.head2 h2{margin:0;font-size:17px;font-weight:500}
h1{font-size:26px;font-weight:400;margin:0 0 12px}
.desc{white-space:pre-line}.q{font-size:16px;margin-bottom:10px}.req{color:#d93025}
label{display:block;margin:8px 0}input[type=radio]{margin-right:10px}
.help{font-size:13px;color:#5f6368;margin:-4px 0 10px}
.text{border-bottom:1px solid #dadce0;color:#70757a;padding:6px 0;width:60%}
.pg{font-size:12px;color:#5f6368;margin:18px 0 6px}
.rows{padding-left:20px}.rows li{margin:14px 0}.bar{display:flex;align-items:center;gap:8px;margin:4px 0}
.bar span{display:block;height:14px;background:#673ab7;border-radius:3px;flex:none;min-width:3px}
.bar em{font-style:normal;font-size:14px}\n.bar span.up{background:#b39ddb}
.note{font-size:13px;color:#5f6368}.vals{font-size:13px;margin-top:2px}.sub{font-size:13px;color:#5f6368}
.nw{white-space:nowrap}.grp{background:#ede7f6;border-left:4px solid #673ab7;padding:12px 24px}.new{background:#e6f4ea;border-left:4px solid #34a853}
"""


# Which study each choice belongs to, read from its own text (the values are public on the explorer).
# The first line matches the live form's texts, the second the texts that replace them.
BSZ_MARK = ["$2,307 billion", "nobody is counted", "100%:", "No discount:", "$3.06 billion", "5 years", "Taxed:", "None:", "One third",
            "the same as the 5%", "an allowance for billionaires", "argued from enforcement", "No deduction:",
            "Counted:"]
assert all("discount" not in v for v in HORIZON.values()) if "HORIZON" in globals() else True


def study_label(c):
    if not (c.startswith("A. ") or c.startswith("B. ")):
        return c
    side = "BSZ" if any(m in c for m in BSZ_MARK) else "JR"
    return f"{side}: {c[3:]}"


def q_html(e, new=False, labelled=False):
    star = ' <span class="req">*</span>' if e.get("required") else ""
    cls = "card new" if new else "card"
    h = f'<div class="{cls}"><div class="q">{html.escape(e["title"])}{star}</div>'
    if e.get("help"):
        h += f'<div class="help">{html.escape(e["help"])}</div>'
    if e["choices"]:
        h += "".join(f"<label><input type=radio disabled>{html.escape(study_label(c) if labelled else c)}</label>"
                     for c in e["choices"])
    else:
        h += '<div class="text">Your answer</div>'
    return h + "</div>"


HORIZON_OLD = "How long the lost income tax is counted, and the rate that discounts it (judged together): which is more credible?"
# "Departures", not "responses": no respondent has been told what responded to what (review 008, F19).
HORIZON = {"title": "How long the lost income tax is counted: which is more credible?",
           "A": "A. For ever: billionaires who leave are assumed not to return.",
           "B": f"B. {H_B}, about the payment period, treating the departures as temporary."}


def rewrite(items):
    """The six experiment forms' changes to the live questions (author, 2026-10-16 and 17)."""
    out, extra, wealth, avoid = [], [], None, None
    skip_why = False
    for e in items:
        if skip_why:
            skip_why = False
            if e["title"] == "Why? (optional)":
                continue
        if e["title"] == HORIZON_OLD:
            e = dict(e, title=HORIZON["title"],
                     choices=[HORIZON[c[0]] if c[:3] in ("A. ", "B. ") else c for c in e["choices"]])
        if e["title"] in REWRITE:
            e = swap_values(e)
        if e["title"] == EMAIL_OLD:
            e = dict(e, title=EMAIL["title"], help=EMAIL["help"])
        if e["title"].startswith("Who has already left"):
            departed, avoid, share, why = split_bundle(e)
            out.append(departed)
            avoid = dict(avoid, required=False)       # joins the optional page (author, 2026-10-17)
            extra = [share, why]                     # appended after the old question's Why?, as the Apps Script does
            continue
        if e["title"] == WEALTH_TITLE:               # moves to the optional page, without its own Why?
            wealth = dict(e, required=False)
            skip_why = True
            continue
        if e["title"] == OPTIN_OLD:
            e = dict(e, title=OPTIN["title"], choices=[OPTIN["choices"].get(c, c) for c in e["choices"]])
        if e["title"] == CLOSE_PAGE_OLD:
            e = dict(e, title=CLOSE_PAGE)
        if e["title"] == SUPPORT_TITLE:
            e = dict(e, required=False)
        if e["title"] == SMALL_PAGE_OLD:
            out += [dict(e, title=SMALL_PAGE), avoid, wealth]
            continue
        out.append(e)
        if extra and e["title"] == "Why? (optional)":
            out += extra
            extra = []
    assert sum(e["title"] == HORIZON["title"] for e in out) == 1 and wealth is not None and avoid is not None
    # "Unsure" replaces "I can't judge this one" in every question (author, 2026-10-17)
    out = [dict(e, choices=[UNSURE[1] if c == UNSURE[0] else c for c in e["choices"]]) for e in out]
    # the email question moves to page 1, after the two pre-treatment questions (author, 2026-10-18); put
    # first here, it counts in the main part for the opt-in, and build() places it on page 1
    email = next(e for e in out if e["title"] == EMAIL["title"])
    out = [email] + [e for e in out if e is not email]
    x, y, z = optin_numbers(out)
    OPTIN["title"] = OPTIN_T.format(x=x, y=y, z=z)
    out = [dict(e, title=OPTIN["title"]) if e["title"] == OPTIN_T else e for e in out]
    return regroup(out)


UNSURE = ("I can't judge this one", "Unsure")


# Wording rule for every input question (pilot 008, 2026-10-17): the two values are the same kind of
# claim, with a reason on both sides or on neither, and neither value argues against the other.
#
# The share lost asks how the income tax lost compares with the wealth that leaves (comparison/DISPUTES.md
# row 6), each value with its own example and its own reason. The old pair ("45% of all billionaires'
# income tax, whoever leaves" against "5%, only the income tax of those who leave") was read as a count of
# leavers, as two different bases and as a tax on those who stay. The review's rewrite moved nine of ten
# interviewees to one side, its JR reason read as a plug.
SHARE_TITLE = "The share of billionaires' income tax lost when people leave: which is more credible?"
SHARE = {
    "jr": (f"{pct(v('f0', 'jr'))} of all the income tax that billionaires pay: more than the {pct(_jr_moved)} of "
           "their wealth reported to have left, because income tax need not leave in step with wealth and some "
           "moves go unreported."),
    "bsz": (f"{pct(_alpha * _mob)} of all the income tax that billionaires pay: the same as the {pct(_alpha * _mob)} "
            "of their wealth assumed to leave, because the largest of the billionaires reported to have left pay "
            "little income tax for their wealth."),
}
# Each value states its own standard for counting a move. The old BSZ value argued against the JR one and
# added a third value (the "aggressive scenario"), which the ten interviewees read against both sides.
DEPARTED_TITLE = ("Billionaires who moved out of California before the 1 January 2026 residency date: "
                  "which is more credible?")
DEPARTED = {
    "jr": (f"About {pct(_jr_moved)} of the wealth: seven billionaires (Page, Thiel, Hankey, Kalanick, Brin, "
           "Spielberg and Sacks) are counted as having moved in time, on public reports of their moves."),
    "bsz": (f"{pct(_alpha * _mob)} of the wealth: an allowance for billionaires who moved in time, with no one "
            "counted by name without evidence of a change of legal residence before the date."),
}
AVOID_TITLE = "Wealth that escapes the tax through avoidance and evasion, beyond moving away: which is more credible?"
AVOID = {"bsz": f"{pct(_alpha * (1 - _mob))}: a small allowance argued from enforcement.",   # pilot text kept (author, 2026-10-17)
         "jr": "None."}
# the closing page is optional throughout (author, 2026-10-17)
CLOSE_PAGE_OLD, CLOSE_PAGE = "Anything else, and two last questions about you", "Anything else (optional)"
SUPPORT_TITLE = "Do you support Proposition 40?"
# the wealth question joins the optional page (author, 2026-10-17)
WEALTH_TITLE = "The billionaires' wealth the tax applies to: which is more credible?"
SMALL_PAGE_OLD, SMALL_PAGE = "Three smaller inputs (optional)", "Five smaller inputs (optional)"
OPTIN_OLD = ("The last three inputs have only a small, second-order effect on the estimate. "
             "Would you like to assess them anyway?")
# no "second-order" (review 008, F17)
# The opt-in states what the five smaller inputs explain and what they cost (author, 2026-10-17).
# The share of the gap: the net of the five dial-path steps (base list, avoidance and the three minor
# inputs) over the gap, the explorer's "other" term (author's choice over the absolute sum, 14%). "Longer":
# the optional section's words over the words up to the opt-in question, to the nearest 5%,
# filled in by rewrite().
SMALL_STEPS = ["base_list", "avoidance", "minor_inputs"]
SMALL_UPTO = abs(sum(steps[k] for k in SMALL_STEPS)) / gap
OPTIN_T = ("The next {x} questions in total explain up to {y} of the difference between the two analyses. "
           "Answering them makes the survey on average {z} longer. Answering them is optional.")
OPTIN = {"title": OPTIN_T, "choices": {"Yes, show me the three": "Yes, show me the five"}}


def optin_numbers(out):
    """(questions, share of the gap, share longer) for the opt-in: the optional section is the items between
    the small-inputs page and the closing page; the main part is everything before the opt-in question."""
    words = lambda e: len((e["title"] + " " + e.get("help", "") + " " + " ".join(e["choices"])).split())
    titles = [e["title"] for e in out]
    i_opt, i_small, i_close = (titles.index(t) for t in (OPTIN["title"], SMALL_PAGE, CLOSE_PAGE))
    small_items = out[i_small + 1:i_close]
    x = sum(e["kind"] == 2 for e in small_items)
    main, small = sum(map(words, out[:i_opt])), sum(map(words, small_items))
    return x, pct(SMALL_UPTO), f"{5 * round(100 * small / main / 5)}%"
# Nothing is verified: the old title "Verify your identity with your email." promised a check (review 008, F16).
EMAIL_OLD = "Verify your identity with your email."
EMAIL = {"title": "Your email (optional)",
         "help": "If you leave one, your answers are also reported in a separate analysis of the respondents who "
                 "gave an email."}
# The form's description. No "reason given for each", since some values carry none (F14), and "most",
# since some inputs are scenario or scope choices (F15). Careful readers took 14 minutes in the pilot.
MINUTES = (5, 10)   # the main part, as the description says it
DESC = ("Proposition 40 would tax Californians worth $1 billion or more once, at " + pct(_rate) + " of their net "
        "worth. Estimates of what it is worth to the state depend on a handful of inputs. Each question shows one "
        "input and two values that have been proposed for it. Tell us which value you find more credible. Your "
        "answers will help us get closer to agreeing on common facts to inform important policy discussions.\n\n"
        "Most of these are empirical quantities, and none should depend on whether one supports or opposes a "
        f"wealth tax.\n\nIt takes {MINUTES[0]} to {MINUTES[1]} minutes. Answers are anonymous unless you leave an "
        "email.")


def share_words(x):
    """One third, one half: the share of the tax paid by selling assets, in words."""
    fr = Fraction(x).limit_denominator(12)
    words = {Fraction(1, 3): "one third", Fraction(1, 2): "one half", Fraction(1, 4): "one quarter"}
    assert abs(float(fr) - x) < 1e-9 and fr in words, x
    return words[fr]


# The two values of these questions replace the live form's, in the same A/B order (the Key tab). Both
# are the same kind of claim; where one side gave a reason and the other none, neither does now.
INCOME_TITLE = "Billionaires' yearly California income tax: which is more credible?"
# The JR range's two counts of top earners (K = 212 at the top, K = 500 at the floor) come from the
# export's source note for the input, so they follow the pipeline.
_K = sorted(int(k) for k in re.findall(r"K = (\d+)", inp["C"]["jr_source"]))
assert len(_K) == 2, inp["C"]["jr_source"]
INCOME = {   # one assumption each with its source, no range on one side and "halved" on the other (pilot: 30 JR, 3 BSZ)
    "jr": (f"${v('C', 'jr'):.2f} billion a year: from California tax data, taking the billionaires to be among "
           f"the state's {_K[0]} to {_K[1]} highest earners."),
    "bsz": (f"${v('C', 'bsz'):.2f} billion a year: from California tax data, taking the billionaires to have about "
            "half the income of the state's highest earners, as a study of top wealth holders finds."),
}
COURT_TITLE = "The chance the tax survives a court challenge: which is more credible?"
# The question is whether to bring a court-risk discount into the estimate at all (author, 2026-10-17):
# one analysis assesses the tax at face value, the other multiplies by the chance it survives. No
# "guesstimated" (all ten interviewees flagged it), and neither side sounds careless.
COURT = {
    "title": "Discounting the revenue for the chance that courts strike the tax down: which is more credible?",
    "bsz": "No discount: the tax is assessed at face value, as written.",
    "jr": (f"A discount: the wealth tax collected is multiplied by the chance the tax survives in court, put "
           f"at {pct(v('q', 'jr'))}."),   # q applies to the wealth tax, not the whole estimate (JR chapter p.33)
}
WEALTH = {   # the BSZ list's total includes the non-US citizens of the next question (F18)
    "bsz": (f"The Forbes list of 1 July 2026: {_bsz_n} California billionaires worth ${_bsz_list:,.0f} billion, "
            f"or ${v('W_core', 'bsz'):,.0f} billion without the non-US citizens asked about next."),
    "jr": (f"The Forbes list of 2025: {_jr_n} California billionaires, grown {pct(_jr_growth)} to the "
           f"31 December 2026 valuation date: ${v('W_core', 'jr'):,.0f} billion."),
}
assert abs(v("W_core", "bsz") + v("W_noncit", "bsz") - _bsz_list) < 1e-6, "the two BSZ totals agree"
NONCIT = {
    "bsz": (f"Taxed: the ${v('W_noncit', 'bsz'):,.0f} billion of wealth of California billionaires who are not "
            "US citizens is in the base."),
    "jr": "Not taxed: the wealth of California billionaires who are not US citizens is left out of the base.",
}
REAL = {
    "bsz": "No deduction: directly held real estate stays in the base.",
    "jr": f"A deduction: directly held real estate, about {pct(v('re', 'jr'), 1)} of the base, is taken out of it.",
}
ASSET = {
    "bsz": (f"Counted: {share_words(v('s', 'bsz'))} of the tax is paid by selling assets, and the gains on them "
            "are taxed."),
    "jr": "Not counted: no extra income tax from selling assets is included.",
}
# title: (a phrase only the live BSZ value contains, the new values)
REWRITE = {
    INCOME_TITLE: (f"${v('C', 'bsz'):.2f}", INCOME),
    COURT_TITLE: (pct(v("q", "bsz")), COURT),
    WEALTH_TITLE: ("1 July 2026", WEALTH),
    "Non-US-citizen residents: which is more credible?": ("Taxed", NONCIT),
    "Real-estate deduction: which is more credible?": ("None", REAL),
    "Extra income tax from assets sold to pay the tax: which is more credible?": ("One third", ASSET),
}


def swap_values(e):
    """The two values are replaced in the same A/B order; a "title" key in the entry renames the question."""
    mark, new = REWRITE[e["title"]]
    vals = {k: new[k] for k in ("bsz", "jr")}
    out = [c[:3] + vals["bsz" if mark in c else "jr"] if c[:3] in ("A. ", "B. ") else c for c in e["choices"]]
    assert sorted(c[3:] for c in out if c[:3] in ("A. ", "B. ")) == sorted(vals.values()), e["title"]
    return dict(e, title=new.get("title", e["title"]), choices=out)


def split_bundle(e):
    """The old bundled question becomes three, each in the bundle's A/B order (here A is the JR value)."""
    a_side = "jr" if "seven billionaires" in next(c for c in e["choices"] if c.startswith("A. ")) else "bsz"
    b_side = "bsz" if a_side == "jr" else "jr"
    tail = [c for c in e["choices"] if c[:3] not in ("A. ", "B. ")]
    departed = dict(e, title=DEPARTED_TITLE,
                    choices=["A. " + DEPARTED[a_side], "B. " + DEPARTED[b_side]] + tail)
    share = dict(e, title=SHARE_TITLE, choices=["A. " + SHARE[a_side], "B. " + SHARE[b_side]] + tail)
    # A/B mixed across questions: here A is the BSZ value
    avoid = dict(e, title=AVOID_TITLE, choices=["A. " + AVOID["bsz"], "B. " + AVOID["jr"]] + tail)
    why = {"kind": 1, "title": "Why? (optional)", "help": "", "choices": [], "required": False}
    return departed, avoid, share, why


# The required questions in the order of the comparison page's four terms, each group under a plain
# heading (the same in both arms); within a group, by each input's effect averaged over all orders.
GROUPS = [
    ("1. The income tax lost when billionaires leave",
     ["The share of billionaires' income tax lost", "How long the lost income tax is counted",
      "Billionaires' yearly California income tax"]),
    ("2. Discounting the revenue for court risk", ["Discounting the revenue for the chance that courts"]),
    ("3. Billionaires who moved out in time", ["Billionaires who moved out of California"]),
]


def regroup(items):
    start = next(i for i, e in enumerate(items) if e["kind"] == 8 and e["title"] == "The inputs") + 1
    end = next(i for i, e in enumerate(items) if i > start and e["choices"] and not e["choices"][0][:3] in ("A. ", "B. "))
    block = items[start:end]
    pairs = {}
    for i, e in enumerate(block):
        if e["choices"]:
            pairs[e["title"]] = [e] + ([block[i + 1]] if i + 1 < len(block) and not block[i + 1]["choices"] else [])
    new = []
    for head, prefixes in GROUPS:
        new.append({"kind": 6, "title": head, "help": "", "choices": []})
        for pre in prefixes:
            hit = [k for k in pairs if k.startswith(pre)]
            assert len(hit) == 1, (pre, hit)
            new += pairs.pop(hit[0])
    assert not pairs, list(pairs)
    return items[:start] + new + items[end:]


# Shown after the form is submitted (the author, 2026-10-17).
EXPLORER_URL = "https://fhoces.github.io/opa-prop40/comparison/site/explorer/"
OVERVIEW_URL = "https://fhoces.github.io/opa-prop40/"
# Short links (TinyURL, made 2026-10-17, redirect to the two addresses above). The confirmation screen is
# plain text, so the links are addresses that Forms makes clickable; they sit after Submit, where a
# control respondent can no longer go back and change answers (author's choice, 2026-10-17).
SHORT = {"explorer": "tinyurl.com/prop40-explorer", "overview": "tinyurl.com/prop40-opa"}
THANKS = ("Thank you for taking the time to answer. All these answers will help us get closer to agreeing on "
          "common facts to inform important policy discussions.\n\nSee how the two estimates compare: "
          + SHORT["explorer"] + "\nAbout the project: " + SHORT["overview"])


def build(items, treated):
    items = rewrite(items)
    title = "What are the actual quantities? Proposition 40, input by input"
    desc = DESC
    expert = next(e for e in items if e["title"].startswith("Do you consider yourself an expert"))
    prior = {"title": "Before opening this survey, had you looked at news sources, web pages or academic studies discussing estimates of Proposition 40, the Billionaire Wealth Tax Proposal in California?",
             "help": "", "choices": ["Yes", "No", "Not sure"], "required": True}
    pages = [[]]
    for e in items:
        if e is expert or e["title"] in ("Which field best describes your work?", EMAIL["title"]):
            continue
        if e["kind"] == 8:
            pages.append([e])
        else:
            pages[-1].append(e)
    # page 1: the two pre-treatment questions, then the email (author, 2026-10-18); the field question is
    # dropped (plan, section 4.4)
    email = next(e for e in items if e["title"] == EMAIL["title"])
    pages[0] = pages[0] + [("new", expert), ("new", prior), ("new", email)]
    out = [f"<div class='card top'><h1>{html.escape(title)}</h1><div class='desc'>{html.escape(desc)}</div></div>"]
    n = len(pages) + (1 if treated else 0)
    k = 1

    def pg():
        nonlocal k
        out.append(f"<div class='pg'>Page {k} of {n}</div>")
        k += 1

    for i, p in enumerate(pages):
        if i == 1 and treated:
            pg()
            out.append(treatment_page())
        pg()
        for e in p:
            if isinstance(e, tuple):
                out.append(q_html(e[1], new=True))
            elif e["kind"] == 6:
                out.append(f"<div class='card grp'><b>{html.escape(e['title'])}</b></div>")
            elif e["kind"] == 8:
                out.append(f"<div class='card head2'><h2>{html.escape(e['title'])}</h2></div>")
                hp = CONTROL_INPUTS if e["title"] == "The inputs" and not treated else e["help"]
                if hp:
                    out.append(f"<div class='card'>{html.escape(hp)}</div>")
            else:
                out.append(q_html(e, labelled=treated))
    thanks = html.escape(THANKS)
    for short in SHORT.values():
        thanks = thanks.replace(short, f"<a href='https://{short}'>{short}</a>")
    out.append(f"<div class='card head2'><h2>After submitting</h2></div><div class='card desc'>{thanks}</div>")
    arm = "Treatment" if treated else "Control"
    banner = (f"<div class='mock'><b>Mock preview: {arm.lower()} form.</b> Not a live form. Green cards are new or "
              "moved questions (pre-analysis plan, section 4.4)."
              + (" The purple page 2 and the BSZ/JR labels on the choices are the treatment." if treated else " The treatment form adds one page after page 1.")
              + " Respondents see neither label.</div>")
    if treated:
        for e in items:
            labs = [study_label(c)[:3] for c in e["choices"] if c[:3] in ("A. ", "B. ")]
            assert labs in ([], ["BSZ", "JR:"], ["JR:", "BSZ"]), (e["title"], labs)
    return (f"<!doctype html><html lang=en><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'>"
            f"<title>Survey mock: {arm}</title><style>{CSS}</style></head><body><div class=wrap>{banner}{''.join(out)}</div></body></html>")


if __name__ == "__main__":
    items = json.load(open(sys.argv[1]))
    os.makedirs(sys.argv[2], exist_ok=True)
    for name, t in (("control", False), ("treatment", True)):
        with open(os.path.join(sys.argv[2], name + ".html"), "w") as f:
            f.write(build(items, t))
    print(f"gap {gap:.1f}; rows by size: " + "; ".join(f"{r[0]} {r[2]:.1f}" for r in by_size))
