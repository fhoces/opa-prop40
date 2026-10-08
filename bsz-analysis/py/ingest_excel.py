"""Python twin of R/ingest_excel.R: where the workbook is, and positional sheet
reads.

read_sheet() mirrors R's read_sheet(): the whole sheet (or a range) with
columns named by Excel letter and rows numbered as in the sheet, so
df.at[16, "G"] is cell G16, as df$G[16] is in R. Values are kept raw (str,
float, None) and converted to numbers only when a cell is read
(excel_cells.to_num), the way the R side reads character cells and calls
as.numeric() on them.

Two details of readxl that this reproduces:
  * a date-formatted cell read into a text column becomes its Excel serial
    number (for example 43465 for 2018-12-31); openpyxl returns a datetime,
    which excel_serial() turns back into the serial;
  * readxl keeps the stored text of a number (17 significant digits) and R's
    as.numeric() parses it; openpyxl parses it with Python's float(), which
    is correctly rounded. The two can differ by a few units in the last
    place (about 1e-16 of the value), which the parity test allows.
"""
import builtins
import datetime
import os
from functools import lru_cache
from pathlib import Path

import openpyxl
import pandas as pd

from vintage import bsz_vintage

# bsz-analysis/, the directory holding R/, py/, sql/ and original-materials/.
BSZ_DIR = Path(__file__).resolve().parent.parent

EXCEL_EPOCH = datetime.datetime(1899, 12, 30)


def project_root():
    root = os.environ.get("CAWTBSZ_ROOT", "")
    return Path(root) if root else BSZ_DIR


def materials_dir():
    d = os.environ.get("CAWTBSZ_MATERIALS", "")
    return Path(d) if d else project_root() / "original-materials"


def xlsx_path_default():
    if bsz_vintage() == "may":
        return materials_dir() / "may-2026" / "BSZ_MainTablesFigures.xlsx"
    return materials_dir() / "BSZ_MainTablesFigures.xlsx"


def excel_col_letters(n):
    out = []
    for i in range(1, n + 1):
        x, s = i, ""
        while x > 0:
            r = (x - 1) % 26
            s = chr(65 + r) + s
            x = (x - 1) // 26
        out.append(s)
    return out


def excel_serial(v):
    """A datetime as the Excel serial number readxl reports in a text column."""
    delta = v - EXCEL_EPOCH
    return delta.days + delta.seconds / 86400 + delta.microseconds / 86400e6


@lru_cache(maxsize=4)
def _workbook(path):
    # data_only: the cached values of formula cells, as readxl reads them.
    return openpyxl.load_workbook(path, data_only=True, read_only=True)


@lru_cache(maxsize=64)
def sheet_grid(path, sheet):
    """All rows of a sheet as a tuple of tuples (0-based), padded to one width."""
    ws = _workbook(str(path))[sheet]
    rows = []
    for row in ws.iter_rows(values_only=True):
        rows.append(tuple(excel_serial(v) if isinstance(v, datetime.datetime) else v
                          for v in row))
    # readxl drops trailing empty rows and columns.
    while rows and all(v is None for v in rows[-1]):
        rows.pop()
    width = 0
    for r in rows:
        for j in range(len(r) - 1, -1, -1):
            if r[j] is not None:
                width = max(width, j + 1)
                break
    return tuple(tuple(r[:width]) + (None,) * (width - len(r[:width])) for r in rows)


def list_sheets(path=None):
    return list(_workbook(str(path or xlsx_path_default())).sheetnames)


def read_sheet(sheet, path=None, range=None):
    """Positional dump of a sheet. `range` is (first_row, first_col, last_row,
    last_col), 1-based and inclusive, like cellranger::cell_limits(ul, lr).
    (The parameter keeps readxl's name, so the loop uses builtins.range.)"""
    grid = sheet_grid(str(path or xlsx_path_default()), sheet)
    if range is None:
        r1, c1 = 1, 1
        r2 = len(grid)
        c2 = len(grid[0]) if grid else 0
    else:
        r1, c1, r2, c2 = range
    data = []
    for i in builtins.range(r1, r2 + 1):
        row = grid[i - 1] if i - 1 < len(grid) else ()
        data.append([row[j - 1] if j - 1 < len(row) else None
                     for j in builtins.range(c1, c2 + 1)])
    df = pd.DataFrame(data, columns=excel_col_letters(c2 - c1 + 1), dtype=object)
    df.index = builtins.range(1, len(df) + 1)
    return df

