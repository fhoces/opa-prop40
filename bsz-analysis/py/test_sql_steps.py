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


def test_venture_monitor():
    con = _connect("06_venture_monitor.sql", ["vm_state_cells"])
    n = {t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
         for t in ("vm_annual_state", "vm_annual", "vm_quarterly_state", "vm_quarterly")}
    years = [y for (y,) in con.execute("SELECT year FROM vm_annual ORDER BY year")]
    (first,) = con.execute("SELECT MIN(year * 10 + quarter) FROM vm_quarterly").fetchone()
    (last,) = con.execute("SELECT MAX(year * 10 + quarter) FROM vm_quarterly").fetchone()
    con.close()
    # Row counts of the authors' four output files.
    assert n == {"vm_annual_state": 1098, "vm_annual": 21,
                 "vm_quarterly_state": 1830, "vm_quarterly": 34}
    assert years == list(range(2006, 2027))
    assert (first, last) == (20181, 20262)


FORM4_INPUTS = ["form4_raw", "form4_forbes_cik", "form4_price_corrections"]


def test_form4_compustat():
    con = _connect(["04_form4_clean.sql", "07_form4_gvkey_link.sql", "08_form4_compustat.sql"],
                   FORM4_INPUTS + ["comp_daily_snapshots", "form4_gvkey_fixes",
                                   "comp_daily_form4"])
    (n_link, n_linked) = con.execute(
        "SELECT COUNT(*), COUNT(gvkey) FROM form4_gvkey_link").fetchone()
    (n_list,) = con.execute("SELECT COUNT(*) FROM form4_gvkey_list").fetchone()
    (n, no_price, no_sec) = con.execute(
        "SELECT COUNT(*), SUM(prccd IS NULL), SUM(gvkey IS NULL) FROM form4_compustat").fetchone()
    con.close()
    assert (n_link, n_linked, n_list) == (276, 270, 262)
    # The authors' file: 198,654 trades, 165 without a price, 23 without a security.
    assert (n, no_price, no_sec) == (198_654, 165, 23)


def test_form4_annual():
    import form4_basis

    con = _connect(["04_form4_clean.sql", "07_form4_gvkey_link.sql", "08_form4_compustat.sql",
                    "09_form4_income.sql"],
                   FORM4_INPUTS + ["comp_daily_snapshots", "form4_gvkey_fixes",
                                   "comp_daily_form4", "form4_excluded_filings"])
    con.close()
    form4_basis.main()
    con = _connect("10_form4_annual.sql", [])
    n = {t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
         for t in ("form4_kg", "form4_annual_firm_individual", "form4_annual_individual",
                   "form4_annual", "form4_annual_top5")}
    (last,) = con.execute("SELECT year FROM form4_annual ORDER BY sort_key DESC, year DESC "
                          "LIMIT 1").fetchone()
    con.close()
    # Row counts of the authors' four yearly files.
    assert n == {"form4_kg": 156_378, "form4_annual_firm_individual": 2110,
                 "form4_annual_individual": 1619, "form4_annual": 24, "form4_annual_top5": 118}
    assert last == "Total"


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
