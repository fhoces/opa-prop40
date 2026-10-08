"""Check query 5 (sql/05_forbes_ca_panel.sql) against its answer keys.

Run from bsz-analysis/, after py/run_sql.py and R/run_sql.R have exported
forbes_ca_2004_2025:

    python py/check_forbes_ca_panel.py

Writes data-raw/sql-out/check_forbes_ca_panel.md (gitignored). Exit code 1 if
a check fails.

Answer keys:
  * private: the authors' panel file and the same panel as a sheet of their
    private workbook (keys forbes_panel_key and private_sheets in the
    gitignored data-raw/private-paths.csv);
  * public: BSZ_MainTablesFigures.xlsx, sheet data_sec_all, whose 2019 to
    2025 rows carry year, forbes_id and forbes_worth.

Ties in worth have no defined order in the authors' sort beyond the order in
which their code stacked the sources, so both sides are put in one canonical
order (year, worth descending, id, name) before the row-by-row comparison.
The order itself is checked separately: the sequence of (year, worth) must be
the same.

Vintage gap: the authors' panel was built from year-end lists written before
an id was added to the residency override table's exclude list. Its rows for
excluded ids are counted as a vintage gap, not a failure (query 1 follows the
current rule, and so does the public data_sec_all).
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, public_workbook_path, sqlite_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_rows, num, parity, read_export, read_xlsx_dicts, text, write_report,
)

TOL = 1e-9
NUM = ["year", "forbes_worth", "forbes_private_worth", "forbes_public_worth"]
TEXT = ["forbes_name", "country_citizenship", "forbes_id", "state", "date"]


def canon(rows):
    def k(r):
        w = num(r["forbes_worth"])
        return (int(num(r["year"])), -(w if w is not None else 0.0),
                text(r["forbes_id"]) or "", text(r["forbes_name"]) or "",
                text(r["country_citizenship"]) or "")
    return sorted(rows, key=k)


def check_against(name, ours, key, excluded):
    gap = [r for r in key if int(num(r["year"])) >= 2019 and text(r["forbes_id"]) in excluded]
    key = [r for r in key if r not in gap]
    order_ok = ([(int(num(r["year"])), num(r["forbes_worth"])) for r in ours]
                == [(int(num(r["year"])), num(r["forbes_worth"])) for r in key])
    chk = compare_rows(name, canon(ours), canon(key), NUM, TEXT, TOL, rel=True)
    chk["note"] += (f"; vintage gap: {len(gap)} key rows of excluded ids in 2019+ set aside"
                    f"; (year, worth) order {'same' if order_ok else 'DIFFERENT'}")
    chk["ok"] = chk["ok"] and order_ok
    return chk


def check_public(ours, pub_wb_path):
    pub = read_xlsx_dicts(pub_wb_path, "data_sec_all", header_row=4)
    seen, rows = set(), []
    for r in pub:
        if r.get("year") is None or r.get("forbes_id") is None:
            continue
        k = (int(r["year"]), r["forbes_id"], r["forbes_worth"])
        if k in seen:  # the sheet repeats a few rows at its tail
            continue
        seen.add(k)
        rows.append(r)
    o = {(int(num(r["year"])), text(r["forbes_id"])): r for r in ours if int(num(r["year"])) >= 2019}
    p = {(int(r["year"]), r["forbes_id"]): r for r in rows}
    common = sorted(set(o) & set(p))
    maxd = max((abs(num(o[k]["forbes_worth"]) - num(p[k]["forbes_worth"])) for k in common),
               default=0.0)
    only_o, only_p = len(set(o) - set(p)), len(set(p) - set(o))
    ok = only_o == 0 and only_p == 0 and maxd <= 1e-6
    return {"name": "2019-2025 rows vs public data_sec_all", "ok": ok, "n": len(common),
            "maxdiff": maxd,
            "note": (f"(year, id) pairs {len(o)} vs {len(p)} (after dropping repeated rows); "
                     f"only in ours {only_o}, only in public {only_p}; forbes_worth compared")}, \
        sorted(set(o) - set(p)), sorted(set(p) - set(o))


def main():
    ours = read_export("forbes_ca_2004_2025")
    con = sqlite3.connect(sqlite_path())
    excluded = {r[0] for r in con.execute(
        "SELECT forbes_id FROM rtb_residency_overrides WHERE rule = 'exclude'")}
    con.close()
    checks = [
        check_against("panel vs the authors' panel file", ours,
                      read_xlsx_dicts(private_file("forbes_panel_key")), excluded),
        check_against("panel vs the private workbook sheet", ours,
                      read_xlsx_dicts(private_file("private_sheets"), "forbes_ca_2004_2025"),
                      excluded),
    ]
    pub, only_o, only_p = check_public(ours, public_workbook_path())
    checks.append(pub)
    checks += parity(["forbes_ca_2004_2025"])
    extra = ["## Public data_sec_all, (year, id) pairs on one side only", "",
             "Only in ours: " + (", ".join(f"{y} {i}" for y, i in only_o) or "none"), "",
             "Only in the public sheet: " + (", ".join(f"{y} {i}" for y, i in only_p) or "none"),
             ""]
    return write_report("Query 5 check report (sql/05_forbes_ca_panel.sql)", checks,
                        "check_forbes_ca_panel", extra,
                        "Numbers relative to max(1, |key|), tolerance 1e-9; text exactly.")


if __name__ == "__main__":
    sys.exit(main())
