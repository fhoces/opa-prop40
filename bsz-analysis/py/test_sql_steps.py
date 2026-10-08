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


def _connect(sql_names, needs):
    """Run the named .sql files in order (a string for one file)."""
    if isinstance(sql_names, str):
        sql_names = [sql_names]
    db = sqlite_path()
    if not db.exists():
        _skip("data-raw/bundle.sqlite absent (built from the confidential bundle)")
    con = sqlite3.connect(db)
    have = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type = 'table'")}
    lacking = [t for t in needs if t not in have]
    if lacking:
        con.close()
        _skip(f"input tables not loaded: {', '.join(lacking)} (python py/load_bundle.py)")
    for name in sql_names:
        run_sql_file(con, BSZ_DIR / "sql" / name)
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


# Rows per year of the authors' panel, 2004 to 2018.
PANEL_0418 = [66, 98, 94, 93, 86, 88, 87, 93, 92, 97, 96, 98, 97, 102, 102]


def test_forbes_ca_panel():
    con = _connect(["01_rtb_ca.sql", "05_forbes_ca_panel.sql"],
                   ["rtb_all_combined", "rtb_ca_cik", "rtb_residency_overrides",
                    "forbes400_raw", "forbes_global_9724", "forbes_global_8810",
                    "forbes_name_ids"])
    per_year = dict(con.execute(
        "SELECT year, COUNT(*) FROM forbes_ca_2004_2025 GROUP BY year ORDER BY year"))
    eoy = [n for (n,) in con.execute(
        "SELECT COUNT(*) FROM rtb_ca_eoy GROUP BY date ORDER BY date")]
    con.close()
    assert list(per_year) == list(range(2004, 2026))
    assert [per_year[y] for y in range(2004, 2019)] == PANEL_0418
    assert [per_year[y] for y in range(2019, 2026)] == eoy


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
