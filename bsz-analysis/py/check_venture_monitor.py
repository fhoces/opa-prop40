"""Check query 6 (sql/06_venture_monitor.sql) against its answer keys.

Run from bsz-analysis/, after py/run_sql.py and R/run_sql.R have exported
the four tables:

    python py/check_venture_monitor.py

Writes data-raw/sql-out/check_venture_monitor.md (gitignored). Exit code 1 if
a check fails.

Answer keys:
  * private: the authors' four output files (keys vm_annual_state_key,
    vm_annual_key, vm_quarterly_state_key and vm_quarterly_key in the
    gitignored data-raw/private-paths.csv);
  * public: BSZ_MainTablesFigures.xlsx, sheets data_venturemonitor_annual and
    data_venturemonitor_quarterly (header on row 4), which also carry the
    California shares share_count_ca = count_ca / tot_count and
    share_value_ca = value_ca / tot_value. Rows of the public workbook may be
    printed.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import private_file, public_workbook_path  # noqa: E402
from check_common import (  # noqa: E402
    compare_keyed, num, parity, read_export, read_xlsx_dicts, write_report,
)

TOL = 1e-9  # relative to max(1, |key|)
SUMS = ["tot_count", "count_ca", "count_rest_us", "tot_value", "value_ca", "value_rest_us"]
TABLES = ["vm_annual_state", "vm_annual", "vm_quarterly_state", "vm_quarterly"]


def with_shares(rows):
    out = []
    for r in rows:
        r = dict(r)
        r["share_count_ca"] = num(r["count_ca"]) / num(r["tot_count"])
        r["share_value_ca"] = num(r["value_ca"]) / num(r["tot_value"])
        out.append(r)
    return out


def main():
    ours = {t: read_export(t) for t in TABLES}
    checks = [
        compare_keyed("annual by state vs the authors' file", ours["vm_annual_state"],
                      read_xlsx_dicts(private_file("vm_annual_state_key")), ["state", "year"],
                      ["deal_count", "deal_value"], [], TOL, rel=True),
        compare_keyed("annual totals vs the authors' file", ours["vm_annual"],
                      read_xlsx_dicts(private_file("vm_annual_key")), ["year"],
                      SUMS, [], TOL, rel=True),
        compare_keyed("quarterly by state vs the authors' file", ours["vm_quarterly_state"],
                      read_xlsx_dicts(private_file("vm_quarterly_state_key")),
                      ["state", "year", "quarter"], ["deal_count", "deal_value"], [], TOL,
                      rel=True),
        compare_keyed("quarterly totals vs the authors' file", ours["vm_quarterly"],
                      read_xlsx_dicts(private_file("vm_quarterly_key")), ["year", "quarter"],
                      SUMS, [], TOL, rel=True),
    ]
    pub = public_workbook_path()
    pub_a = [r for r in read_xlsx_dicts(pub, "data_venturemonitor_annual", header_row=4)
             if isinstance(r.get("year"), (int, float))]
    pub_q = [r for r in read_xlsx_dicts(pub, "data_venturemonitor_quarterly", header_row=4)
             if isinstance(r.get("year"), (int, float))]
    shares = ["share_count_ca", "share_value_ca"]
    checks += [
        compare_keyed("annual totals and CA shares vs public data_venturemonitor_annual",
                      with_shares(ours["vm_annual"]), pub_a, ["year"], SUMS + shares, [],
                      TOL, rel=True),
        compare_keyed("quarterly totals and CA shares vs public data_venturemonitor_quarterly",
                      with_shares(ours["vm_quarterly"]), pub_q, ["year", "quarter"],
                      SUMS + shares, [], TOL, rel=True),
    ]
    checks += parity(TABLES)
    extra = []
    for c in checks:
        if c.get("only_ours") or c.get("only_key"):
            extra += [f"## {c['name']}: keys on one side only", "",
                      f"Only in ours: {len(c['only_ours'])}; only in the key: {len(c['only_key'])}",
                      ""]
    return write_report("Query 6 check report (sql/06_venture_monitor.sql)", checks,
                        "check_venture_monitor", extra,
                        "Numbers relative to max(1, |key|), tolerance 1e-9.")


if __name__ == "__main__":
    sys.exit(main())
