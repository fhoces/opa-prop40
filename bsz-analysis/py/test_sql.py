"""Phase 2, query 1 (sql/01_rtb_ca.sql) run through py/run_sql.py.

Local only: data-raw/bundle.sqlite is built from the confidential author
bundle, so every test skips when it is absent. Run either way:

    python -m pytest py/test_sql.py
    python py/test_sql.py          # without pytest
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import BSZ_DIR, sqlite_path  # noqa: E402
from run_sql import run_sql_file  # noqa: E402

SQL_FILE = BSZ_DIR / "sql" / "01_rtb_ca.sql"
EOY_DATES = ["2019-12-31", "2020-12-31", "2021-12-31", "2022-12-31",
             "2023-12-31", "2024-12-31", "2026-01-01"]

try:
    import pytest
except ImportError:  # plain-Python fallback below
    pytest = None


def _skip(reason):
    if pytest:
        pytest.skip(reason)
    raise _Skipped(reason)


class _Skipped(Exception):
    pass


def _connect():
    db = sqlite_path()
    if not db.exists():
        _skip("data-raw/bundle.sqlite absent (built from the confidential bundle)")
    con = sqlite3.connect(db)
    run_sql_file(con, SQL_FILE)
    return con


def test_year_end_lists():
    con = _connect()
    per_date = dict(con.execute(
        "SELECT date, COUNT(*) FROM rtb_ca_eoy GROUP BY date ORDER BY date"))
    con.close()
    assert list(per_date) == EOY_DATES
    # 240, as in the public workbook (data_sec_agg, n for 2025).
    assert per_date["2026-01-01"] == 240


def test_aggregate_and_industry():
    con = _connect()
    (n_agg,) = con.execute("SELECT COUNT(*) FROM rtb_ca_aggregate").fetchone()
    rows = con.execute("SELECT * FROM rtb_ca_2026_01_01_industry ORDER BY rowid").fetchall()
    ncol = len(con.execute("PRAGMA table_info(rtb_ca_2026_01_01_industry)").fetchall())
    con.close()
    assert n_agg >= 2209
    assert ncol == 6
    assert rows[-1][0] == "Total" and rows[-1][1] == 240


if __name__ == "__main__":
    pytest = None  # plain run: report skips here instead of raising pytest's
    failed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print(f"PASS {name}")
            except _Skipped as e:
                print(f"SKIP {name}: {e}")
            except AssertionError as e:
                failed += 1
                print(f"FAIL {name}: {e}")
    sys.exit(1 if failed else 0)
