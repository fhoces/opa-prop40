"""Python twin of R/excel_cells.R: single cells, row slices and column slices
of a positional sheet (ingest_excel.read_sheet()).

R reads the cells as character and calls suppressWarnings(as.numeric(v)):
text that is not a number becomes NA. to_num() does the same with NaN.
"""
import math
import re

import numpy as np

_ADDR = re.compile(r"^([A-Z]+)([0-9]+)$")


def split_addr(addr):
    m = _ADDR.match(addr)
    if not m:
        raise ValueError(f"Not a cell address: {addr}")
    return m.group(1), int(m.group(2))


def to_num(v):
    """R's suppressWarnings(as.numeric(v)) for one workbook value."""
    if v is None or isinstance(v, bool):
        return math.nan
    if isinstance(v, (int, float)):
        return float(v)
    s = str(v).strip()
    if "_" in s:  # float() reads "1_000"; as.numeric() does not
        return math.nan
    try:
        # as.numeric() ignores leading and trailing white space, like float().
        return float(s)
    except ValueError:
        return math.nan


def to_num_vec(values):
    return np.array([to_num(v) for v in values], dtype=float)


def xls_cell(df, addr):
    col, row = split_addr(addr)
    if col not in df.columns or row not in df.index:
        return math.nan
    return to_num(df.at[row, col])


def xls_cells_row(df, cols, row):
    return np.array([xls_cell(df, f"{c}{row}") for c in cols], dtype=float)


def xls_cells_col(df, col, rows):
    return np.array([xls_cell(df, f"{col}{r}") for r in rows], dtype=float)


def col_num(df, col, rows):
    """suppressWarnings(as.numeric(df[[col]][rows])), the slice idiom of
    R/tables.R and R/figures.R."""
    return xls_cells_col(df, col, rows)
