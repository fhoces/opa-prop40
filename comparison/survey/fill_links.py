"""Fill comparison/data/survey-links.csv from the Apps Script builder's execution log.

Usage: python3 comparison/survey/fill_links.py LOG.txt

LOG.txt is the text of the Execution log after buildExperiment ran (copy it from the Apps Script
editor). For each form the log holds three lines:

    exp: Prop 40 survey (explorer, control)
      edit: https://docs.google.com/forms/d/.../edit
      respond: https://docs.google.com/forms/d/e/.../viewform

The respond link of each form goes into the row of its entry point and arm. The site has two entry
points (explorer, share), so four rows. Every one of the four must be found; the script refuses to
write a partial file. The builder may still log landing forms (the landing panel was removed on
2026-10-17); they are ignored. Edit links are printed, not stored.
"""
import csv
import os
import re
import sys

ENTRIES = ("explorer", "share")
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LINKS = os.path.join(ROOT, "comparison", "data", "survey-links.csv")
PAT = re.compile(r"exp: Prop 40 survey \((landing|explorer|share), (control|treatment)\)\s*\n\s*edit: (\S+)\s*\n\s*respond: (\S+)")


def main(log_path):
    text = open(log_path).read()
    found = {(e, a): (edit, respond) for e, a, edit, respond in PAT.findall(text)}
    # landing forms in the log are matched by PAT and then left out here
    rows = [(e, a) for e in ENTRIES for a in ("control", "treatment")]
    missing = [r for r in rows if r not in found]
    if missing:
        raise SystemExit(f"the log lacks {len(missing)} of the {len(rows)} forms: {missing}")
    with open(LINKS, "w", newline="") as f:
        f.write("# entry,arm,url: the four experiment forms, filled from the builder's log by fill_links.py\n")
        w = csv.writer(f)
        w.writerow(["entry", "arm", "url"])
        for r in rows:
            w.writerow([r[0], r[1], found[r][1]])
    for r in rows:
        print(f"{r[0]:9s} {r[1]:10s} edit: {found[r][0]}")
    print(f"wrote {LINKS} with {len(rows)} rows")


if __name__ == "__main__":
    main(sys.argv[1])
