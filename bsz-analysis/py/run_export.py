"""Run the BSZ step 2 in Python (the public workbook to every number the R
pipeline exports) and write export/py/.

Run from bsz-analysis/ (about 10 s):

    python py/run_export.py

The Python twin of `Rscript -e 'targets::tar_make()'`, without the gt and
ggplot rendering. It reads the public workbook with openpyxl, loads
data_sec_all and the FTB table into data-raw/workbook-py.sqlite (gitignored)
and runs the shared queries sql/02_data_sec_agg.sql and sql/03_ftb_b4a.sql
there, then computes the rest with pandas and numpy.

Output, mirroring what R writes:
  export/py/inputs.csv, outputs.csv   the export contract (R: export/r/)
  export/py/site/*.csv, grid.js       the site data (R: site/data/, site/explorer/grid.js)
  export/py/exhibits/*.csv            every computed table, the data behind
                                      each table and figure (R: the snapshots
                                      in tests/snapshots/<vintage>/*.rds)

tests/testthat/test-py-parity.R compares each file with its R counterpart and
tools/py-parity.R writes the per-output maximum differences to
export/py/parity.csv.

Exhibit file names: one CSV per data frame. A snapshot that is a list of data
frames gives <name>__<element>.csv; a list of numbers gives one key,value CSV
whose keys are the names R's unlist() gives (for example
"top5_public_b.brin"); a two-panel figure gives <name>_panel_1.csv and
<name>_panel_2.csv. Missing values are written as NA.
"""
import csv
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
import data_sheets as ds  # noqa: E402
import figures as fg  # noqa: E402
import tables as tb  # noqa: E402
from compute_billionaires_ca_inctax import compute_billionaires_ca_inctax  # noqa: E402
from compute_pareto import compute_fig8_laffer, compute_pareto_missing, compute_pareto_summary  # noqa: E402
from compute_shortrunseries import compute_shortrunseries  # noqa: E402
from compute_tab5 import compute_tab5, tab5_scoring_inputs  # noqa: E402
from compute_top4taxes import compute_top4taxes  # noqa: E402
from export_contract import export_contract_inputs, export_contract_outputs  # noqa: E402
from ingest_excel import project_root, xlsx_path_default  # noqa: E402
from site_exports import (  # noqa: E402
    build_site_grid, build_site_inputs, compare_tab5_printed, site_grid_js_text,
)
from workbook_db import build_workbook_db, read_data_sec_agg, read_ftb_b4a  # noqa: E402


def _cell(v):
    if v is None:
        return "NA"
    if isinstance(v, (bool, np.bool_)):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    if isinstance(v, (float, np.floating)):
        return "NA" if math.isnan(v) else repr(float(v))
    return str(v)


def write_csv(df, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(list(df.columns))
        for row in df.itertuples(index=False):
            w.writerow([_cell(v) for v in row])
    return path


def write_exhibit(name, obj, out_dir):
    """One CSV per data frame, following the file-name rules in the docstring."""
    written = []
    if isinstance(obj, pd.DataFrame):
        written.append(write_csv(obj, out_dir / f"{name}.csv"))
    elif isinstance(obj, list):
        for i, df in enumerate(obj, start=1):
            written += write_exhibit(f"{name}_panel_{i}", df, out_dir)
    elif isinstance(obj, dict) and not any(isinstance(v, (pd.DataFrame, dict, list)) for v in obj.values()):
        kv = pd.DataFrame({"key": list(obj.keys()), "value": [float(v) for v in obj.values()]})
        written.append(write_csv(kv, out_dir / f"{name}.csv"))
    elif isinstance(obj, dict):
        for k, v in obj.items():
            written += write_exhibit(f"{name}__{k}", v, out_dir)
    else:
        raise TypeError(f"{name}: cannot write {type(obj)}")
    return written


def run(out_dir=None, db=None):
    root = project_root()
    out_dir = Path(out_dir or root / "export" / "py")
    xlsx = xlsx_path_default()
    if not xlsx.exists():
        sys.exit(f"{xlsx} not found (the public workbook; see bsz-analysis/README.md)")

    # Inputs (R: the extract_* targets).
    data_sec_all = ds.extract_data_sec_all()
    data_sec_top4 = ds.extract_data_sec_top4()
    pareto_raw = ds.extract_pareto_missing()
    tab2 = ds.extract_tab2()
    tab3 = ds.extract_tab3()
    longrunseries = ds.extract_longrunseries()
    shortrunseries = ds.extract_shortrunseries()
    data_dina = ds.extract_data_dina()
    bci = ds.extract_billionaires_ca_inctax()
    ftb_raw = ds.extract_ftb_b4a()

    # The shared SQL step (R: targets workbook_db, ftb_b4a_sql, data_sec_agg_r).
    db = build_workbook_db(data_sec_all, ftb_raw, path=db)
    data_sec_agg_r = read_data_sec_agg(db)
    ftb_b4a_sql = read_ftb_b4a(db)

    # Computations (R: the *_r targets).
    pareto_missing_r = compute_pareto_missing(pareto_raw)
    pareto_summary = compute_pareto_summary(pareto_missing_r)
    tab5_r = compute_tab5(pareto_missing_r, tab2, tab3)
    fig8_laffer_r = compute_fig8_laffer()
    bci_r = compute_billionaires_ca_inctax(data_sec_agg_r, bci, ftb_b4a_sql)
    srs_r = compute_shortrunseries(data_sec_agg_r, data_sec_top4, bci_r, shortrunseries)
    top4taxes_r = compute_top4taxes(data_sec_top4)

    exhibits = {
        "data_sec_agg_r": data_sec_agg_r,
        "pareto_missing_r": pareto_missing_r,
        "pareto_summary": pareto_summary,
        "tab5_r": tab5_r,
        "fig8_laffer_r": fig8_laffer_r,
        "billionaires_ca_inctax_r": bci_r,
        "shortrunseries_r": srs_r,
        "top4taxes_r": top4taxes_r,
    }
    t1 = tb.build_tab1(data_sec_agg_r, srs_r, longrunseries, shortrunseries)
    ta1 = tb.build_tab_a1(shortrunseries, longrunseries)
    exhibits.update({
        "tab1_panel_a": t1["panel_a"], "tab1_panel_b": t1["panel_b"],
        "tab2_panel": tb.build_tab2(data_sec_agg_r, bci_r, data_sec_top4)["panel"],
        "tab3_panel": tb.build_tab3(data_sec_top4)["panel"],
        "tab4_panel": tb.build_tab4(data_sec_top4)["panel"],
        "tab5_panel": tb.build_tab5(tab5_r)["panel"],
        "tab_a1_panel_a": ta1["panel_a"], "tab_a1_panel_b": ta1["panel_b"],
        "fig1": fg.build_fig1(srs_r),
        "fig2": fg.build_fig2(longrunseries),
        "fig3": fg.build_fig3(srs_r),
        "fig4": fg.build_fig4(bci_r),
        "fig5": fg.build_fig5(data_sec_top4),
        "fig6": fg.build_fig6(top4taxes_r),
        "fig7": fg.build_fig7(top4taxes_r, data_dina),
        "fig8": fg.build_fig8(fig8_laffer_r),
        "fig_a1": fg.build_fig_a1(),
        "fig_a2": fg.build_fig_a2(srs_r),
        "fig_a3": fg.build_fig_a3(bci_r),
        "fig_a4": fg.build_fig_a4(pareto_missing_r),
    })

    # Site exports and the contract (R: site_* and export_* targets).
    inp = tab5_scoring_inputs(pareto_missing_r, tab2, tab3)
    grid = build_site_grid(inp)
    printed = compare_tab5_printed(tab5_r)
    site_dir = out_dir / "site"
    pareto_cols = ["threshold_b", "n_above_threshold_emp", "wealth_above_threshold",
                   "pareto_b_emp", "n_above_threshold_proj", "pareto_b_proj"]
    files = [
        write_csv(grid, site_dir / "grid.csv"),
        write_csv(build_site_inputs(inp), site_dir / "inputs.csv"),
        write_csv(tab5_r, site_dir / "tab5.csv"),
        write_csv(inp["leavers"], site_dir / "leavers.csv"),
        write_csv(printed, site_dir / "tab5-vs-printed.csv"),
        write_csv(pareto_missing_r[pareto_cols], site_dir / "pareto.csv"),
        write_csv(pd.DataFrame([pareto_summary]), site_dir / "pareto-summary.csv"),
        write_csv(export_contract_inputs(inp), out_dir / "inputs.csv"),
        write_csv(export_contract_outputs(printed), out_dir / "outputs.csv"),
    ]
    js = site_dir / "grid.js"
    js.write_bytes(site_grid_js_text(grid, inp).encode("utf-8"))
    files.append(js)

    ex_dir = out_dir / "exhibits"
    for old in ex_dir.glob("*.csv") if ex_dir.exists() else []:
        old.unlink()
    for name, obj in exhibits.items():
        files += write_exhibit(name, obj, ex_dir)

    print(f"database: {db}")
    print(f"wrote {len(files)} files under {out_dir}")
    return files


if __name__ == "__main__":
    run()
