"""Check queries 9 and 10 and the basis step against the authors' outputs.

Run from bsz-analysis/, after the Python run (py/form4_basis.py, then
py/run_sql.py sql/10_form4_annual.sql --export ...) and the R run
(Rscript R/form4_basis.R, then Rscript R/run_sql.R ... --export ...):

    python py/check_form4_annual.py

Writes data-raw/sql-out/check_form4_annual.md (gitignored). Exit code 1 if a
check fails.

Public landing: the sheet data_sec_all of BSZ_MainTablesFigures.xlsx carries
eight of these columns for every California billionaire and year 2019 to 2025
(purchase, sale, kg, kg_long, kg_short, option_profit, kg_taxable, donation).
form4_annual_individual summed by Forbes id and year (0 for a person with no
Form 4 activity) is compared with it, after dropping the sheet's repeated
rows.

Answer keys: the authors' four yearly Form 4 files (keys
form4_annual_firm_individual_key, form4_annual_individual_key,
form4_annual_key and form4_annual_top5_key in the gitignored
data-raw/private-paths.csv), and the same tables as sheets of their private
workbook (key private_sheets). Every value is rounded to two decimals on both
sides, so numbers must agree to 1e-6.

The Forbes id carries query 4's vintage gap (one filer whose CIK the bundled
crosswalk no longer maps); those rows are counted separately. A private
sheet can be longer than the file it was written from: writing a shorter
table over an existing sheet leaves the old sheet's last rows in place. When
the sheet's first rows have the same keys, in the same order, as the file,
the rows after them are set aside as such a stale tail and counted in the
report. R vs Python parity covers the basis step's two tables as well as the
four outputs.
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, public_workbook_path, sqlite_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_keyed, num, parity, read_export, read_xlsx_dicts, text, write_report,
)

TOL = 1e-6
FIRM_NUM = ["shares_purchased", "purchase", "shares_sold", "sale", "shares_donated", "donation",
            "shares_option", "option_profit", "kg", "kg_short", "kg_long", "total_basis"]
IND_NUM = ["purchase", "sale", "kg", "kg_long", "kg_short", "option_profit", "kg_taxable",
           "donation", "total_basis"]
TABLES = ["form4_kg", "form4_basis_held", "form4_annual_firm_individual",
          "form4_annual_individual", "form4_annual", "form4_annual_top5"]


def gap_split(name, ours, key, keys, ciks):
    """forbes_id: unexplained mismatches vs rows of filers missing from the crosswalk."""
    k = {tuple(text(r[c]) for c in keys): r for r in key}
    gap = other = 0
    for r in ours:
        kr = k.get(tuple(text(r[c]) for c in keys))
        if kr is None:
            continue
        a, b = text(r["forbes_id"]), text(kr["forbes_id"])
        if a == b:
            continue
        if a is None and b is not None and text(r["owner_cik_1"]) not in ciks:
            gap += 1
        else:
            other += 1
    return {"name": f"{name}: forbes_id", "ok": other == 0, "n": len(ours),
            "maxdiff": float(other),
            "note": f"unexplained mismatches {other}; query 4's crosswalk vintage gap {gap} rows"}


PUBLIC_COLS = ["purchase", "sale", "kg", "kg_long", "kg_short", "option_profit",
               "kg_taxable", "donation"]


def check_public(ind):
    sums = {}
    for r in ind:
        if text(r["forbes_id"]) is None:
            continue
        k = (r["forbes_id"], int(num(r["year"])))
        acc = sums.setdefault(k, {c: 0.0 for c in PUBLIC_COLS})
        for c in PUBLIC_COLS:
            acc[c] += num(r[c])
    seen, off, maxd, n_active = set(), {c: 0 for c in PUBLIC_COLS}, 0.0, 0
    for r in read_xlsx_dicts(public_workbook_path(), "data_sec_all", header_row=4):
        if r.get("year") is None or r.get("forbes_id") is None:
            continue
        k = (r["forbes_id"], int(r["year"]), r["forbes_worth"])
        if k in seen:  # the sheet repeats a few rows at its tail
            continue
        seen.add(k)
        o = sums.get(k[:2])
        n_active += o is not None
        for c in PUBLIC_COLS:
            d = abs((o[c] if o else 0.0) - (num(r[c]) or 0.0))
            maxd = max(maxd, d)
            off[c] += d > 0.005 + 1e-9
    bad = {c: v for c, v in off.items() if v}
    return {"name": "person-year sums vs public data_sec_all (8 columns)", "ok": not bad,
            "n": len(seen), "maxdiff": maxd,
            "note": (f"{len(seen)} public rows, {n_active} with Form 4 activity; cells off "
                     "(> 0.005): " + (", ".join(f"{c} {v}" for c, v in bad.items()) or "none"))}


def main():
    con = sqlite3.connect(sqlite_path())
    ciks = {str(c).zfill(10) for (c,) in con.execute(
        "SELECT cik FROM form4_forbes_cik WHERE cik IS NOT NULL")}
    con.close()
    specs = [
        ("form4_annual_firm_individual", "form4_annual_firm_individual_key",
         "form4_annual_firm_individual", ["owner_cik_1", "issuer_cik", "year"], FIRM_NUM,
         ["issuer_symbol"]),
        ("form4_annual_individual", "form4_annual_individual_key", "form4_annual_individual",
         ["owner_cik_1", "year"], IND_NUM, []),
        ("form4_annual", "form4_annual_key", "form4_annual", ["year"], IND_NUM, []),
        ("form4_annual_top5", "form4_annual_top5_key", "form4_annual_top5",
         ["owner_cik_1", "year", "forbes_id"], IND_NUM, []),
    ]
    checks = []
    for table, file_key, sheet, keys, nums, texts in specs:
        ours = read_export(table)
        file_rows = read_xlsx_dicts(private_file(file_key))
        sheet_rows = read_xlsx_dicts(private_file("private_sheets"), sheet)
        tail = 0
        kf = [tuple(text(r[c]) for c in keys) for r in file_rows]
        if (len(sheet_rows) > len(file_rows)
                and [tuple(text(r[c]) for c in keys) for r in sheet_rows[:len(kf)]] == kf):
            tail = len(sheet_rows) - len(file_rows)
            sheet_rows = sheet_rows[:len(kf)]
        for label, key in (("the authors' file", file_rows), ("the private sheet", sheet_rows)):
            chk = compare_keyed(f"{table} vs {label}", ours, key, keys, nums, texts, TOL)
            if label == "the private sheet" and tail:
                chk["note"] += f"; stale tail of {tail} row(s) after the file's rows set aside"
            checks.append(chk)
            if "owner_cik_1" in keys and table != "form4_annual_top5":
                checks.append(gap_split(f"{table} vs {label}", ours, key, keys, ciks))
    checks.append(check_public(read_export("form4_annual_individual")))
    checks += parity(TABLES)
    extra = ["Max diff of the forbes_id rows is the count of unexplained mismatches.", ""]
    return write_report("Queries 9 and 10 check report (Form 4 yearly sums)", checks,
                        "check_form4_annual", extra,
                        "Numbers absolute, tolerance 1e-6 (both sides are rounded to 2 decimals).")


if __name__ == "__main__":
    sys.exit(main())
