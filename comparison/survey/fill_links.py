"""Fill comparison/data/survey-links.csv from the Apps Script builder's execution log.

Usage: python3 comparison/survey/fill_links.py LOG.txt [--out PATH]   (default: comparison/data/survey-links.csv)

LOG.txt is the text of the Execution log (copy it from the Apps Script editor) after fixPrior()
ran, which logs every existing form, or after buildExperiment() ran, which logs only the forms it
built in that run (a finished form is skipped with "exists, skipped" and no links). For each form
the log holds three lines, and fixPrior() adds a fourth:

    exp: Prop 40 survey (explorer, control)
      edit: https://docs.google.com/forms/d/.../edit
      respond: https://docs.google.com/forms/d/e/.../viewform
      finished: true; items: 44; prior question: current

The respond link of each form goes into the row of its entry point and arm. The site has two entry
points (explorer, share), so four rows. Every one of the four must be found, once, and finished where
the log says: the script refuses to write a partial file, a file with a form that has two copies (a
half-built copy beside the finished one: trash it and run fixPrior() again) or an unfinished form.
The builder may still log landing forms (the landing panel was removed on 2026-10-17); they are
ignored. Edit links are printed, not stored. The file's lines end in LF, like the repository's.
"""
import csv
import os
import re
import sys

ENTRIES = ("explorer", "share")
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LINKS = os.path.join(ROOT, "comparison", "data", "survey-links.csv")
PAT = re.compile(r"exp: Prop 40 survey \((landing|explorer|share), (control|treatment)\)\s*\n\s*edit: (\S+)\s*\n\s*respond: (\S+)"
                 r"(?:\s*\n\s*finished: (true|false))?")


def main(log_path, out=LINKS):
    text = open(log_path).read()
    copies = {}   # (entry, arm) -> {respond link: (edit link, finished flag or "")}
    for e, a, edit, respond, finished in PAT.findall(text):
        copies.setdefault((e, a), {})[respond] = (edit, finished)
    # landing forms in the log are matched by PAT and then left out here
    rows = [(e, a) for e in ENTRIES for a in ("control", "treatment")]
    missing = [r for r in rows if r not in copies]
    if missing:
        raise SystemExit(f"the log lacks {len(missing)} of the {len(rows)} forms: {missing}")
    bad = []
    for r in rows:
        if len(copies[r]) > 1:
            bad.append(f"{r}: {len(copies[r])} copies in the log ({', '.join(copies[r])}); trash the unfinished one and run fixPrior() again")
        elif next(iter(copies[r].values()))[1] == "false":
            bad.append(f"{r}: the log says it is not finished")
    if bad:
        raise SystemExit("refusing to write the file:\n  " + "\n  ".join(bad))
    found = {r: (v[0], respond) for r in rows for respond, v in copies[r].items()}
    with open(out, "w", newline="") as f:
        f.write("# entry,arm,url: the four experiment forms, filled from the builder's log by fill_links.py\n")
        w = csv.writer(f, lineterminator="\n")
        w.writerow(["entry", "arm", "url"])
        for r in rows:
            w.writerow([r[0], r[1], found[r][1]])
    for r in rows:
        print(f"{r[0]:9s} {r[1]:10s} edit: {found[r][0]}")
    print(f"wrote {out} with {len(rows)} rows")


if __name__ == "__main__":
    a = sys.argv[1:]
    main(a[0], a[a.index("--out") + 1] if "--out" in a else LINKS)
