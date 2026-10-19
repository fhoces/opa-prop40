"""Prints the control and treatment forms for the pre-analysis plan's Appendix B.

Usage: python3 comparison/survey/plan/forms/print_forms.py

control.json and treatment.json are each form's own definition, read from Google Forms' preview of
form 3 (explorer, control) and form 4 (explorer, treatment) on 2026-10-18: FB_PUBLIC_LOAD_DATA_[1]
reduced to the title, description, confirmation message and items (id, type, title, help text,
required flag, choices with their page jumps, and each page break's next page). Forms 5 and 6 carry
the same text. This script writes control.html and treatment.html beside them, laid out page by
page as a respondent meets them; build.sh prints both to PDF and the plan includes them.
"""
import html
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
FORMS = [("control", "B.1", "The control form (forms 3 and 5)"),
         ("treatment", "B.2", "The treatment form (forms 4 and 6)")]

CSS = """
@page { size: letter; margin: 0.75in 0.8in 1in 0.8in; }
body { font-family: Helvetica, Arial, sans-serif; font-size: 10.5pt; color: #202124; margin: 0; }
h1 { font-size: 13pt; margin: 0 0 4px; }
.src { font-size: 8.5pt; color: #5f6368; margin: 0 0 14px; }
.page { font-size: 8.5pt; font-weight: bold; letter-spacing: .05em; text-transform: uppercase;
        color: #5f6368; margin: 18px 0 6px; border-top: 2px solid #673ab7; padding-top: 6px; }
.card { border: 1px solid #dadce0; border-radius: 6px; padding: 10px 14px; margin: 0 0 8px;
        break-inside: avoid; }
.head { border-top: 8px solid #673ab7; }
.title { font-size: 15pt; margin: 0 0 6px; }
.ptitle { font-weight: bold; font-size: 11.5pt; margin: 0 0 4px; }
.text { white-space: pre-wrap; margin: 0; line-height: 1.4; }
.q { margin: 0 0 6px; line-height: 1.35; }
.req { color: #d93025; }
.help { font-size: 9.5pt; color: #5f6368; margin: -2px 0 6px; white-space: pre-wrap; }
.choice { margin: 4px 0 4px 0; padding-left: 22px; text-indent: -22px; line-height: 1.35; }
.choice::before { content: "\\25CB"; display: inline-block; width: 22px; text-indent: 0; }
.jump { color: #5f6368; font-size: 9pt; }
.line { border-bottom: 1px dotted #80868b; width: 50%; height: 16px; color: #80868b; font-size: 9pt; }
.box { border-bottom: 1px dotted #80868b; width: 100%; height: 30px; color: #80868b; font-size: 9pt; }
.section { font-weight: bold; font-size: 11pt; background: #f1ecfa; }
.end { margin-top: 18px; }
.keep { break-inside: avoid; }
"""


def esc(s):
    return html.escape(s or "")


def render(form, label, heading):
    items = form["items"]
    titles = {it["id"]: it["title"] for it in items if it["type"] == 8}
    n_pages = 1 + sum(it["type"] == 8 for it in items)
    out = [f"<!doctype html><html><head><meta charset='utf-8'><style>{CSS}</style></head><body>",
           f"<h1>Appendix {label}. {esc(heading)}</h1>",
           "<p class='src'>Printed from the form's own definition as Google Forms served it in "
           "preview on 18 October 2026. Each page of the form starts at a purple rule. "
           "Respondents see the text exactly as below, one page at a time.</p>",
           f"<div class='page'>Page 1 of {n_pages}</div>",
           f"<div class='card head'><p class='title'>{esc(form['title'])}</p>"
           f"<p class='text'>{esc(form['description'])}</p>"
           "<p class='help' style='margin-top:8px'><span class='req'>*</span> Indicates required question</p></div>"]
    page = 1
    # a page label, a page's title card and a section heading are held back and printed in one
    # unbreakable block with the next question, so none is left alone at the foot of a sheet
    hold = []
    for it in items:
        t = it["type"]
        if t == 8:
            page += 1
            hold.append(f"<div class='page'>Page {page} of {n_pages}</div>")
            hold.append(f"<div class='card'><p class='ptitle'>{esc(it['title'])}</p>"
                        + (f"<p class='text'>{esc(it['help'])}</p>" if it.get("help") else "") + "</div>")
            continue
        if t == 6:
            hold.append(f"<div class='card section'>{esc(it['title'])}</div>")
            continue
        star = " <span class='req'>*</span>" if it.get("required") else ""
        body = [f"<p class='q'>{esc(it['title'])}{star}</p>"]
        if it.get("help"):
            body.append(f"<p class='help'>{esc(it['help'])}</p>")
        if t == 2:
            for c in it["choices"]:
                jump = (f" <span class='jump'>(goes to the page “{esc(titles[c['goto']])}”)</span>"
                        if "goto" in c else "")
                body.append(f"<div class='choice'>{esc(c['label'])}{jump}</div>")
        elif t == 0:
            body.append("<div class='line'>Your answer</div>")
        elif t == 1:
            body.append("<div class='box'>Your answer</div>")
        else:
            raise ValueError(f"item type {t} not handled: {it['title']}")
        card = "<div class='card'>" + "".join(body) + "</div>"
        # the treatment page is long: it keeps only its label, and the page after it starts fresh
        if len(hold) > 1 and len("".join(hold)) > 1500:
            out.append("<div class='keep'>" + hold[0] + hold[1] + "</div>")
            hold = hold[2:]
        out.append("<div class='keep'>" + "".join(hold) + card + "</div>")
        hold = []
    out.append("<div class='page end'>After Submit: the confirmation message</div>"
               f"<div class='card'><p class='text'>{esc(form['confirmation'])}</p></div>")
    out.append("</body></html>")
    return "\n".join(out)


for name, label, heading in FORMS:
    with open(os.path.join(HERE, f"{name}.json"), encoding="utf-8") as f:
        form = json.load(f)
    with open(os.path.join(HERE, f"{name}.html"), "w", encoding="utf-8") as f:
        f.write(render(form, label, heading))
    print(f"wrote {name}.html")
