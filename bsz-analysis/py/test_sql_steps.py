"""Phase 2, step 1, the queries after query 1 (sql/04_*.sql onward), run
through py/run_sql.py.

Local only: data-raw/bundle.sqlite is built from the confidential author
bundle, so every test skips when it is absent (or lacks the input tables).
Run either way:

    python -m pytest py/test_sql_steps.py
    python py/test_sql_steps.py          # without pytest
"""
import sqlite3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import BSZ_DIR, sqlite_path  # noqa: E402
from run_sql import run_sql_file  # noqa: E402

try:
    import pytest
except ImportError:  # plain-Python fallback below
    pytest = None


class _Skipped(Exception):
    pass


def _skip(reason):
    if pytest:
        pytest.skip(reason)
    raise _Skipped(reason)


def _connect(sql_name, needs):
    db = sqlite_path()
    if not db.exists():
        _skip("data-raw/bundle.sqlite absent (built from the confidential bundle)")
    con = sqlite3.connect(db)
    have = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type = 'table'")}
    lacking = [t for t in needs if t not in have]
    if lacking:
        con.close()
        _skip(f"input tables not loaded: {', '.join(lacking)} (python py/load_bundle.py)")
    run_sql_file(con, BSZ_DIR / "sql" / sql_name)
    return con


def test_form4_clean():
    con = _connect("04_form4_clean.sql",
                   ["form4_raw", "form4_forbes_cik", "form4_price_corrections"])
    (n,) = con.execute("SELECT COUNT(*) FROM form4_clean").fetchone()
    (n_found,) = con.execute(
        "SELECT COUNT(*) FROM form4_clean WHERE ownership_nature LIKE '%foundation%'").fetchone()
    (n_sale_not_s,) = con.execute(
        "SELECT COUNT(*) FROM form4_clean WHERE sale IS NOT NULL AND code <> 'S'").fetchone()
    cols = [r[1] for r in con.execute("PRAGMA table_info(form4_clean)")]
    con.close()
    assert n == 198_719          # the authors' clean file
    assert n_found == 0
    assert n_sale_not_s == 0
    assert len(cols) == 19       # 18 output columns plus row_num


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
