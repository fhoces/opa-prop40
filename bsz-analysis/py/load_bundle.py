"""Build data-raw/bundle.sqlite from the confidential author bundle.

Run from bsz-analysis/:

    python py/load_bundle.py                 # every table
    python py/load_bundle.py rtb_ca_cik      # only the named tables

Idempotent: each loader drops and recreates the one table it owns, so the
script can be re-run after the bundle changes. To add an input for a later
query, write one function `load_<table>(con, root)` and register it in
LOADERS at the bottom; nothing else changes.

Conventions shared by every loader:
  * strings and ISO dates are TEXT, money is REAL, ids are INTEGER;
  * an empty cell becomes NULL (the bundle's CSVs write missing values as
    empty strings, not NA), so SQL aggregates skip it the way R's
    na.rm = TRUE does;
  * the database is a local build artifact and is gitignored (*.sqlite).
"""
import csv
import sqlite3
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import bundle_dir, sqlite_path  # noqa: E402

BATCH = 100_000


def _text(v):
    return v if v != "" else None


def _real(v):
    return float(v) if v != "" else None


# ---------------------------------------------------------------------------
# Forbes real-time billionaires, one row per (date, forbes_id)
# Source: Forbes_RTB/03_outdata/rtb_all_combined.csv (about 5.9M rows)
# ---------------------------------------------------------------------------
RTB_COLUMNS = [
    ("date", "TEXT", _text),
    ("forbes_id", "TEXT", _text),
    ("forbes_name", "TEXT", _text),
    ("state", "TEXT", _text),
    ("country_citizenship", "TEXT", _text),
    ("source", "TEXT", _text),
    ("industries", "TEXT", _text),
    ("forbes_worth", "REAL", _real),
    ("forbes_public_worth", "REAL", _real),
    ("forbes_private_worth", "REAL", _real),
]


def load_rtb_all_combined(con, root):
    path = root / "Forbes_RTB" / "03_outdata" / "rtb_all_combined.csv"
    names = [c[0] for c in RTB_COLUMNS]
    casts = [c[2] for c in RTB_COLUMNS]
    con.execute("DROP TABLE IF EXISTS rtb_all_combined")
    con.execute(
        "CREATE TABLE rtb_all_combined ("
        + ", ".join(f"{n} {t}" for n, t, _ in RTB_COLUMNS)
        + ")"
    )
    insert = (
        f"INSERT INTO rtb_all_combined ({', '.join(names)}) "
        f"VALUES ({', '.join('?' * len(names))})"
    )
    n = 0
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        if header != names:
            raise ValueError(f"Unexpected header in {path.name}: {header}")
        batch = []
        for row in reader:
            batch.append([cast(v) for cast, v in zip(casts, row)])
            if len(batch) >= BATCH:
                con.executemany(insert, batch)
                n += len(batch)
                batch = []
        con.executemany(insert, batch)
        n += len(batch)
    # Indexes after the load: building them once is faster than updating
    # them on every insert.
    con.execute("CREATE INDEX idx_rtb_all_combined_date ON rtb_all_combined (date)")
    con.execute("CREATE INDEX idx_rtb_all_combined_id ON rtb_all_combined (forbes_id)")
    return n


# ---------------------------------------------------------------------------
# forbes_id to SEC CIK, for the 2026-01-01 California list
# Source: Forms4/02_indata/rtb_ca_cik_2026_01_01.xlsx (237 rows)
# ---------------------------------------------------------------------------
def load_rtb_ca_cik(con, root):
    import openpyxl

    path = root / "Forms4" / "02_indata" / "rtb_ca_cik_2026_01_01.xlsx"
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    rows = wb[wb.sheetnames[0]].iter_rows(values_only=True)
    header = list(next(rows))
    i_id, i_cik = header.index("forbes_id"), header.index("cik")
    out = []
    for r in rows:
        if r[i_id] in (None, ""):
            continue
        cik = r[i_cik]
        # The cik column is numeric with some blank (empty-string) cells.
        if cik in (None, ""):
            cik = None
        else:
            cik = int(float(cik))
        out.append((r[i_id], cik))
    wb.close()
    con.execute("DROP TABLE IF EXISTS rtb_ca_cik")
    con.execute("CREATE TABLE rtb_ca_cik (forbes_id TEXT, cik INTEGER)")
    con.executemany("INSERT INTO rtb_ca_cik VALUES (?, ?)", out)
    return len(out)


# One entry per table. Later queries add their inputs here.
LOADERS = {
    "rtb_all_combined": load_rtb_all_combined,
    "rtb_ca_cik": load_rtb_ca_cik,
}


def main(argv):
    wanted = argv or list(LOADERS)
    unknown = [t for t in wanted if t not in LOADERS]
    if unknown:
        sys.exit(f"Unknown table(s): {', '.join(unknown)}. Known: {', '.join(LOADERS)}")
    root = bundle_dir()
    db = sqlite_path()
    db.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(db)
    # A rebuildable artifact: trade crash safety for load speed.
    con.execute("PRAGMA journal_mode = OFF")
    con.execute("PRAGMA synchronous = OFF")
    for table in wanted:
        t0 = time.time()
        with con:
            n = LOADERS[table](con, root)
        (check,) = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()
        if check != n:
            raise RuntimeError(f"{table}: inserted {n} rows but the table has {check}")
        print(f"{table}: {n:,} rows in {time.time() - t0:.1f} s")
    con.close()
    print(f"database: {db}")


if __name__ == "__main__":
    main(sys.argv[1:])
