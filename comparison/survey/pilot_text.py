"""The survey as plain text, for simulated respondents: one file per arm, in the format the first
pilot used (feedback/008-2026-10-17-rct-pilot/00-materials).

Usage: python3 comparison/survey/pilot_text.py ITEMS.json OUT_DIR

Writes OUT_DIR/survey-control.txt and OUT_DIR/survey-treatment.txt from the same items and
rewrites as the mock (mock_forms.py) and the Apps Script builder (gas_build.py), so the text the
respondents read is the text the forms will carry. Questions are numbered across the whole form;
choices are numbered (1) to (4) only so a respondent can report them. In the treatment file the
comparison page is page 2 and each value carries its study's label, as in the treatment forms.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mock_forms as m  # noqa: E402

TITLE = "What are the actual quantities? Proposition 40, input by input"
PRIOR = {"title": "Before opening this survey, had you looked at news sources, web pages or academic studies "
                  "discussing estimates of Proposition 40, the Billionaire Wealth Tax Proposal in California?",
         "help": "", "choices": ["Yes", "No", "Not sure"], "required": True, "kind": 2}


def bar(x):
    return ("█" if x <= 0 else "░") * max(1, round(20 * abs(x) / abs(m.by_size[0][2])))


def treat_lines():
    """The comparison page as text: the same lines as the Apps Script builder's TREAT help text."""
    lines = [m.STUDIES_LEAD] + ["• " + s for s in m.STUDIES] + ["", m.INTRO[0], "", m.INTRO[1]]
    for i, (key, t, x, hi, lo) in enumerate(m.by_size, 1):
        lines += ["", f"{i}. {t}", f"{bar(x)} {m.amount(x)}"] + ([f"BSZ: {hi}.", f"JR: {lo}."] if hi else [])
    return lines + ["", m.NOTE, "", m.CLOSE]


def pages_of(items):
    """The pages as the mock lays them out: page 1 holds the two pre-treatment questions."""
    items = m.rewrite(items)
    expert = next(e for e in items if e["title"].startswith("Do you consider yourself an expert"))
    pages = [[]]
    for e in items:
        if e is expert or e["title"] == "Which field best describes your work?":
            continue
        if e["kind"] == 8:
            pages.append([e])
        else:
            pages[-1].append(e)
    pages[0] = pages[0] + [expert, PRIOR]
    return pages


def render(items, treated):
    out = [f"TITLE: {TITLE}", "", m.DESC, ""]
    pages = pages_of(items)
    n = 0
    k = 0

    def q(e):
        nonlocal n
        n += 1
        req = "(required)" if e.get("required") else "(optional)"
        title = e["title"]
        if title.endswith("(optional)") and req == "(optional)":
            req = ""
        out.append(f"Q{n}. {title} {req}".rstrip())
        if e.get("help"):
            out.append(f"   {e['help']}")
        if e["choices"]:
            for j, c in enumerate(e["choices"], 1):
                out.append(f"   ({j}) {m.study_label(c) if treated else c}")
        else:
            out.append("   [free text]")
        out.append("")

    for i, p in enumerate(pages):
        if i == 1 and treated:
            k += 1
            out += [f"=== Page {k}: How the two estimates differ ===", *treat_lines(), ""]
        k += 1
        head = p[0]["title"] if i > 0 and p[0]["kind"] == 8 else None
        out.append(f"=== Page {k}: {head} ===" if head else f"=== Page {k} ===")
        if head and p[0].get("help"):
            out.append(p[0]["help"])
        out.append("")
        for e in (p[1:] if head else p):
            if e["kind"] == 6:
                out += [f"--- {e['title']} ---", ""]
            elif e["kind"] == 8:
                continue
            else:
                q(e)
    out.append(f"=== After submitting ===\n{m.THANKS}\n")
    return "\n".join(out)


def main(items_path, out_dir):
    items = json.load(open(items_path))
    os.makedirs(out_dir, exist_ok=True)
    for arm, treated in (("control", False), ("treatment", True)):
        text = render(items, treated)
        assert "\u2014" not in text
        if not treated:
            assert "BSZ" not in text and " JR" not in text, "the control text names a study"
        with open(os.path.join(out_dir, f"survey-{arm}.txt"), "w") as f:
            f.write(text)
        print(arm, text.count("\nQ"), "questions", len(text.split()), "words")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
