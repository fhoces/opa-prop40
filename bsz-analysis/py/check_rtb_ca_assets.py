"""Check query 11 (sql/11_rtb_ca_assets.sql) against the authors' outputs.

Run from bsz-analysis/, after py/run_sql.py and R/run_sql.R have exported
rtb_ca_assets, rtb_ticker_gvkey_na and rtb_ticker_gvkey_int:

    python py/check_rtb_ca_assets.py

Writes data-raw/sql-out/check_rtb_ca_assets.md (gitignored). Exit code 1 if
a check fails.

Answer keys (located through the gitignored data-raw/private-paths.csv): the
authors' seven California holdings files (key rtb_ca_asset_key_files, a path
template with {date}), compared row by row in their order; their two ticker
crosswalks (rtb_ticker_gvkey_na_key, rtb_ticker_gvkey_int_key), compared as
sets of rows; and their list of North American gvkeys (rtb_gvkey_na_key).
"""
import sqlite3
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, sqlite_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_rows, parity, read_csv_dicts, read_export, text, write_report,
)

TOL = 1e-9
DATES = ["2019_12_31", "2020_12_31", "2021_12_31", "2022_12_31", "2023_12_31",
         "2024_12_31", "2026_01_01"]
NUM = ["forbes_numberofshares", "forbes_currentvalue", "forbes_sharevalue",
       "forbes_exchangerate", "forbes_shareprice", "forbes_currentprice"]
TEXT = ["forbes_id", "forbes_exchange", "forbes_ticker", "forbes_date", "forbes_name",
        "forbes_companyname", "forbes_currencycode"]


def crosswalk_check(name, ours, key):
    o = Counter((text(r["forbes_ticker"]), text(r["gvkey"]), text(r["iid"])) for r in ours)
    k = Counter((text(r["forbes_ticker"]), text(r["gvkey"]), text(r["iid"])) for r in key)
    only_o, only_k = sum((o - k).values()), sum((k - o).values())
    return {"name": name, "ok": only_o == 0 and only_k == 0, "n": sum(o.values()),
            "maxdiff": float(only_o + only_k),
            "note": f"rows {sum(o.values())} vs {sum(k.values())}; only in ours {only_o}, "
                    f"only in key {only_k} (gvkey compared as text)"}


def main():
    ours = read_export("rtb_ca_assets")
    template = str(private_file("rtb_ca_asset_key_files"))
    checks = []
    for d in DATES:
        mine = [r for r in ours if r["snapshot"] == d.replace("_", "-")]
        key = read_csv_dicts(template.replace("{date}", d))
        checks.append(compare_rows(f"CA holdings {d.replace('_', '-')} vs the authors' file",
                                   mine, key, NUM, TEXT, TOL, rel=True))
    checks.append(crosswalk_check("North American ticker crosswalk vs the authors' file",
                                  read_export("rtb_ticker_gvkey_na"),
                                  read_csv_dicts(private_file("rtb_ticker_gvkey_na_key"))))
    checks.append(crosswalk_check("international ticker crosswalk vs the authors' file",
                                  read_export("rtb_ticker_gvkey_int"),
                                  read_csv_dicts(private_file("rtb_ticker_gvkey_int_key"))))
    con = sqlite3.connect(sqlite_path())
    mine = {g for (g,) in con.execute("SELECT gvkey FROM rtb_gvkey_na_list")}
    con.close()
    key = {ln.strip() for ln in private_file("rtb_gvkey_na_key").read_text().splitlines()
           if ln.strip()}
    checks.append({"name": "North American gvkey list vs the authors' list",
                   "ok": mine == key, "n": len(mine), "maxdiff": float(len(mine ^ key)),
                   "note": f"{len(mine)} vs {len(key)}; only in ours {len(mine - key)}, "
                           f"only in key {len(key - mine)}"})
    checks += parity(["rtb_ca_assets", "rtb_ticker_gvkey_na", "rtb_ticker_gvkey_int"])
    return write_report("Query 11 check report (sql/11_rtb_ca_assets.sql)", checks,
                        "check_rtb_ca_assets",
                        ["Max diff of the crosswalk and list rows is a count of rows that differ."],
                        "Numbers relative to max(1, |key|), tolerance 1e-9; text exactly.")


if __name__ == "__main__":
    sys.exit(main())
