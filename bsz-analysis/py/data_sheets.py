"""Python twin of R/data_sheets.R: the rectangular sheets with a header row,
read into pandas data frames, and the positional ones (ingest_excel.read_sheet).

read_rectangular() reproduces readxl::read_excel(range = cell_limits(...),
col_types = ...) as R/data_sheets.R calls it:
  * the header row (skip + 1) gives the column names unless `names` is given,
    in which case that row is skipped and the data start one row lower;
  * n_max data rows (all rows to the end of the sheet when n_max is None);
  * "numeric" columns: numbers as floats, numeric-looking text parsed (readxl
    coerces it with a warning), anything else NaN;
  * "text" columns: text trimmed of surrounding white space (readxl's
    trim_ws = TRUE default), an empty cell None, a number written the way
    readxl writes it (an integer without ".0");
  * rows kept where every key column is non-missing, or, with no key
    columns, where any cell is non-missing.
"""
import math

import numpy as np
import pandas as pd

from excel_cells import to_num
from ingest_excel import read_sheet, sheet_grid, xlsx_path_default
from vintage import bsz_vintage


def _to_text(v):
    if v is None:
        return None
    if isinstance(v, bool):
        return "TRUE" if v else "FALSE"
    if isinstance(v, (int, float)):
        f = float(v)
        return str(int(f)) if f.is_integer() else repr(f)
    s = str(v).strip()
    return s if s != "" else None


def _is_missing(v):
    return v is None or (isinstance(v, float) and math.isnan(v))


def read_rectangular(sheet, path=None, skip=3, col_types=None, n_max=None,
                     key_cols=None, names=None):
    if not col_types:
        raise ValueError("read_rectangular requires explicit col_types (clips width).")
    grid = sheet_grid(str(path or xlsx_path_default()), sheet)
    n_cols = len(col_types)

    def cells(row_1based):
        r = grid[row_1based - 1] if row_1based - 1 < len(grid) else ()
        return [r[j] if j < len(r) else None for j in range(n_cols)]

    if names is None:
        header_row = skip + 1
        col_names = [_to_text(v) or "" for v in cells(header_row)]
        first = header_row + 1
    else:
        col_names = list(names)
        first = skip + 2
    last = first + n_max - 1 if n_max is not None else len(grid)

    conv = {"numeric": to_num, "text": _to_text}
    rows = [[conv[t](v) for t, v in zip(col_types, cells(i))] for i in range(first, last + 1)]
    df = pd.DataFrame(rows, columns=col_names)
    for j, t in enumerate(col_types):
        if t == "numeric":
            df.iloc[:, j] = df.iloc[:, j].astype(float)
    if key_cols:
        keep = np.ones(len(df), dtype=bool)
        for k in key_cols:
            keep &= ~df[k].map(_is_missing).to_numpy()
    else:
        keep = ~df.apply(lambda r: all(_is_missing(v) for v in r), axis=1).to_numpy()
    return df.loc[keep].reset_index(drop=True)


def extract_data_sec_codebook(path=None):
    out = read_rectangular("data_sec_codebook", path=path, skip=3,
                           col_types=["text", "text", "text"])
    out.columns = ["variable", "definition", "data_source"]
    out.loc[out["data_source"] == "\\", "data_source"] = None
    return out


def extract_data_sec_top4(path=None):
    # Data rows 5-120 (per-billionaire-year + per-year totals); the Walczak
    # comparison block below is ignored, as in R.
    ct = ["text", "text"] + ["numeric"] * 22 + ["text"] + ["numeric"] * 11
    out = read_rectangular("data_sec_top4", path=path, skip=3, col_types=ct,
                           key_cols=["year", "forbes_id"], n_max=116)
    out["year"] = out["year"].astype(float).astype(int)
    out["end_cyear"] = pd.to_datetime(out["end_cyear"], errors="coerce").dt.date
    return out


def extract_data_sec_all(path=None):
    ct = ["numeric", "text"] + ["numeric"] * 29
    out = read_rectangular("data_sec_all", path=path, skip=3, col_types=ct,
                           key_cols=["year", "forbes_id"])
    out["year"] = out["year"].astype(int)
    return out


def extract_data_sec_agg(path=None):
    ct = ["text", "numeric"] + ["numeric"] * 33
    out = read_rectangular("data_sec_agg", path=path, skip=3, col_types=ct,
                           key_cols=["year"], n_max=7)
    out["year"] = out["year"].astype(float).astype(int)
    return out


def extract_rtb_2026_industry(path=None):
    n_max = 14 if bsz_vintage() == "may" else 15
    return read_rectangular("rtb_2026_industry", path=path, skip=3,
                            col_types=["text"] + ["numeric"] * 7,
                            key_cols=["industries"], n_max=n_max)


def extract_tab2(path=None):
    nm = ["year", "ca_billionaires_wealth", "ca_inctax_estimated",
          "ca_inctax_per_wealth", "gap_1",
          "top4_company_wealth", "top4_ca_inctax",
          "top4_ca_inctax_per_wealth", "gap_2", "gap_3"]
    return read_rectangular("Tab2", path=path, skip=5,
                            col_types=["text"] + ["numeric"] * 9, names=nm, n_max=8)


def extract_tab3(path=None):
    nm = ["metric", "page", "brin", "zuckerberg", "huang", "all_top4",
          "gap_1", "gap_2", "gap_3"]
    return read_rectangular("Tab3", path=path, skip=4,
                            col_types=["text"] + ["numeric"] * 8, names=nm, n_max=11)


def extract_longrunseries(path=None):
    return read_sheet("longrunseries", path=path)


def extract_shortrunseries(path=None):
    return read_sheet("shortrunseries", path=path)


def extract_data_dina(path=None):
    return read_sheet("data_dina", path=path)


def extract_data_sec_propublica(path=None):
    return read_sheet("data_sec_propublica", path=path)


def extract_billionaires_ca_inctax(path=None):
    return read_sheet("billionairesCAinctax", path=path)


def extract_ftb_b4a(path=None):
    return read_sheet("2023-b-4a__adjusted_gross_incom", path=path)


def extract_pareto_missing(path=None):
    nm = ["threshold_b", "n_above_threshold_emp", "wealth_above_threshold",
          "pareto_b_emp", "wealth_in_bracket", "actual_density",
          "avg_wealth_in_bracket_emp", "n_above_threshold_proj",
          "projected_wealth_in_bracket", "projected_density",
          "avg_wealth_in_bracket_proj", "pareto_b_proj"]
    return read_rectangular("Pareto-missing", path=path, skip=3,
                            col_types=["numeric"] * len(nm), names=nm,
                            key_cols=["threshold_b"], n_max=17)
