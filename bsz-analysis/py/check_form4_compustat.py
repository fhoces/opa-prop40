"""Check queries 7 and 8 (sql/07_form4_gvkey_link.sql, sql/08_form4_compustat.sql).

Run from bsz-analysis/, after py/run_sql.py and R/run_sql.R have exported
form4_gvkey_link and form4_compustat:

    python py/check_form4_compustat.py

Writes data-raw/sql-out/check_form4_compustat.md (gitignored). Exit code 1 if
a check fails.

Answer keys (located through the gitignored data-raw/private-paths.csv):
  * the list of gvkeys the authors kept from the daily price file (key
    form4_gvkey_list_key), against query 7's form4_gvkey_list;
  * the authors' Form 4 file with prices (key form4_compustat_key), against
    query 8's form4_compustat, row by row in the authors' order.

The Forbes id carries query 4's vintage gap (rows of one filer whose CIK the
bundled crosswalk no longer maps); it is counted separately, as there.
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, sqlite_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_rows, parity, read_export, read_xlsx_dicts, text, write_report,
)

TOL = 1e-9
NUM = ["issuer_cik", "table_num", "shares_traded", "price_per_share", "year", "sale",
       "purchase", "gvkey", "prccd", "cshoc", "adrrc", "ajexdi"]
TEXT = ["folder", "issuer_name", "issuer_symbol", "security_title", "transaction_date",
        "code", "type", "ownership_nature", "owner_name_1", "owner_cik_1", "iid", "tic",
        "curcdd", "comp_datadate"]
RENAME = {"folder": "Folder", "table_num": "table"}


def main():
    con = sqlite3.connect(sqlite_path())
    ours_list = {g for (g,) in con.execute("SELECT gvkey_text FROM form4_gvkey_list")}
    ciks = {str(c).zfill(10) for (c,) in con.execute(
        "SELECT cik FROM form4_forbes_cik WHERE cik IS NOT NULL")}
    con.close()
    key_list = {ln.strip() for ln in
                private_file("form4_gvkey_list_key").read_text().splitlines() if ln.strip()}
    checks = [{"name": "gvkey list vs the authors' list", "ok": ours_list == key_list,
               "n": len(ours_list), "maxdiff": float(len(ours_list ^ key_list)),
               "note": f"{len(ours_list)} vs {len(key_list)} gvkeys; "
                       f"only in ours {len(ours_list - key_list)}, "
                       f"only in key {len(key_list - ours_list)}"}]

    ours = read_export("form4_compustat")
    key = read_xlsx_dicts(private_file("form4_compustat_key"))
    checks.append(compare_rows("form4_compustat vs the authors' file", ours, key,
                               NUM, TEXT, TOL, RENAME, rel=True))
    gap_rows, other = 0, 0
    for o, k in zip(ours, key):
        a, b = text(o["forbes_id"]), text(k["forbes_id"])
        if a == b:
            continue
        if a is None and b is not None and o["owner_cik_1"] not in ciks:
            gap_rows += 1
        else:
            other += 1
    checks.append({"name": "forbes_id vs the authors' file", "ok": other == 0,
                   "n": min(len(ours), len(key)), "maxdiff": float(other),
                   "note": f"unexplained mismatches {other}; query 4's crosswalk vintage "
                           f"gap {gap_rows} rows"})
    checks += parity(["form4_gvkey_link", "form4_compustat"])
    return write_report("Queries 7 and 8 check report (Form 4 to daily prices)", checks,
                        "check_form4_compustat",
                        ["Max diff of the gvkey-list and forbes_id rows is a count of "
                         "mismatches."],
                        "Numbers relative to max(1, |key|), tolerance 1e-9; text exactly.")


if __name__ == "__main__":
    sys.exit(main())
