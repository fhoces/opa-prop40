"""Check query 4 (sql/04_form4_clean.sql) against the authors' clean Form 4 file.

Run from bsz-analysis/, after py/run_sql.py and R/run_sql.R have exported
form4_clean:

    python py/check_form4_clean.py

Writes data-raw/sql-out/check_form4_clean.md (gitignored). Exit code 1 if a
check fails.

The answer key is the authors' own clean output (located through the
gitignored data-raw/private-paths.csv, key form4_clean_key). The rows have no
natural key, so the two files are compared row by row in file order, which
the query keeps through row_num.

One known difference is classed as a vintage gap rather than a failure: a row
whose forbes_id is NULL in ours but set in the key, because the filer CIK is
not on the CIK crosswalk in the bundle, which no longer maps it. The report
counts these rows and the filers involved.
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, sqlite_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_rows, parity, read_csv_dicts, read_export, text, write_report,
)

TOL = 1e-9  # relative: the key is a CSV written by readr with full precision
NUM = ["table_num", "shares_traded", "price_per_share", "year", "sale", "purchase"]
TEXT = ["folder", "issuer_name", "issuer_cik", "issuer_symbol", "security_title",
        "transaction_date", "code", "type", "ownership_nature", "owner_name_1",
        "owner_cik_1"]
RENAME = {"folder": "Folder", "table_num": "table"}


def main():
    ours = read_export("form4_clean")
    key = read_csv_dicts(private_file("form4_clean_key"))
    checks = [compare_rows("form4_clean vs the authors' clean file", ours, key,
                           NUM, TEXT, TOL, RENAME, rel=True)]

    # forbes_id on its own, separating the crosswalk vintage gap.
    con = sqlite3.connect(sqlite_path())
    ciks = {str(c).zfill(10) for (c,) in con.execute(
        "SELECT cik FROM form4_forbes_cik WHERE cik IS NOT NULL")}
    con.close()
    gap_rows, gap_filers, other = 0, set(), 0
    for o, k in zip(ours, key):
        a, b = text(o["forbes_id"]), text(k["forbes_id"])
        if a == b:
            continue
        if a is None and b is not None and o["owner_cik_1"] not in ciks:
            gap_rows += 1
            gap_filers.add(o["owner_cik_1"])
        else:
            other += 1
    checks.append({
        "name": "forbes_id vs the authors' clean file", "ok": other == 0,
        "n": min(len(ours), len(key)), "maxdiff": float(other),
        "note": (f"unexplained mismatches {other}; vintage gap (filer CIK not on the "
                 f"bundled crosswalk, set in the key) {gap_rows} rows, "
                 f"{len(gap_filers)} filer(s)")})
    checks += parity(["form4_clean"])

    extra = ["## Notes", "",
             "Numbers are compared relative to max(1, |key|), tolerance 1e-9; text exactly",
             "(missing values on both sides count as equal).", "",
             "Max diff of the forbes_id row is the count of unexplained mismatches."]
    return write_report("Query 4 check report (sql/04_form4_clean.sql)", checks,
                        "check_form4_clean", extra)


if __name__ == "__main__":
    sys.exit(main())
