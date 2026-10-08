"""Run a shared .sql file against data-raw/bundle.sqlite and export tables.

Run from bsz-analysis/:

    python py/run_sql.py sql/01_rtb_ca.sql \\
        --export rtb_ca_eoy rtb_ca_2026_01_01_industry rtb_ca_aggregate

The file is executed verbatim with sqlite3.Connection.executescript. Each
table named after --export is written to data-raw/sql-out/py/<table>.csv
(gitignored: the rows come from the confidential bundle).

Determinism: rows are sorted by the table's key from EXPORT_ORDER (the same
keys as R/run_sql.R); a table with no entry is sorted by all its columns.
Floats are written with repr(), the shortest text that reads back as the
same double. NULL is written as an empty field.
"""
import argparse
import csv
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import sqlite_path, sql_out_dir  # noqa: E402

# Keep in step with .EXPORT_ORDER in R/run_sql.R.
EXPORT_ORDER = {
    "rtb_ca_eoy": "date, forbes_worth DESC, forbes_id",
    "rtb_ca_2026_01_01_industry": "(industries = 'Total'), fraction_forbes_worth DESC, industries",
    "rtb_ca_aggregate": "date",
}


def run_sql_file(con, sql_file):
    con.executescript(Path(sql_file).read_text(encoding="utf-8"))
    con.commit()


def _fmt(v):
    if v is None:
        return ""
    if isinstance(v, float):
        return repr(v)
    return str(v)


def export_table(con, table, out_dir):
    cols = [r[1] for r in con.execute(f"PRAGMA table_info({table})")]
    if not cols:
        raise ValueError(f"No table named {table} in the database")
    order = EXPORT_ORDER.get(table, ", ".join(str(i + 1) for i in range(len(cols))))
    rows = con.execute(f"SELECT * FROM {table} ORDER BY {order}").fetchall()
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{table}.csv"
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(cols)
        for r in rows:
            w.writerow([_fmt(v) for v in r])
    return path, len(rows)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("sql_file")
    p.add_argument("--export", nargs="*", default=[], metavar="TABLE")
    p.add_argument("--db", default=None, help="SQLite file (default data-raw/bundle.sqlite)")
    p.add_argument("--out", default=None, help="export directory (default data-raw/sql-out/py)")
    a = p.parse_args(argv)
    db = Path(a.db) if a.db else sqlite_path()
    if not db.exists():
        sys.exit(f"{db} not found. Build it first: python py/load_bundle.py")
    out_dir = Path(a.out) if a.out else sql_out_dir("py")
    con = sqlite3.connect(db)
    run_sql_file(con, a.sql_file)
    for table in a.export:
        path, n = export_table(con, table, out_dir)
        print(f"{table}: {n:,} rows -> {path}")
    con.close()


if __name__ == "__main__":
    main()
