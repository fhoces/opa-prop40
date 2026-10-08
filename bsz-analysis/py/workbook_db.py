"""Python twin of R/workbook_db.R: the public workbook's two large input sheets
in SQLite, for the shared queries sql/02_data_sec_agg.sql and
sql/03_ftb_b4a.sql.

Run from bsz-analysis/ to build the database on its own:

    python py/workbook_db.py            # writes data-raw/workbook-py.sqlite

py/run_export.py does the same as its first step. The Python file is
workbook-py.sqlite, not R's workbook.sqlite: the R file is a targets file
target, and rewriting it from Python would make the next tar_make() rebuild.
Both files are gitignored (*.sqlite) and hold the same tables.

Each query file runs verbatim with sqlite3.Connection.executescript, as
py/run_sql.py runs query 1. The input tables are written with pandas
DataFrame.to_sql: int columns become INTEGER, floats REAL, text TEXT, and a
missing value NULL, which is what RSQLite's dbWriteTable() writes from R.
"""
import sqlite3
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from data_sheets import extract_data_sec_all, extract_ftb_b4a  # noqa: E402
from excel_cells import to_num_vec  # noqa: E402
from ingest_excel import project_root  # noqa: E402

ELLISON_FORBES_ID = "larry-ellison"
WORKBOOK_SQL_FILES = ("02_data_sec_agg.sql", "03_ftb_b4a.sql")


def workbook_db_path():
    return project_root() / "data-raw" / "workbook-py.sqlite"


def workbook_sql_file(name):
    return project_root() / "sql" / name


def run_sql_file(con, sql_file):
    con.executescript(Path(sql_file).read_text(encoding="utf-8"))
    con.commit()


def workbook_input_tables(data_sec_all=None, ftb_b4a=None, exclude_ids=(ELLISON_FORBES_ID,)):
    """The input tables as data frames (R: workbook_input_tables())."""
    out = {}
    if data_sec_all is not None:
        d = data_sec_all.copy()
        d["year"] = d["year"].astype(int)
        d.insert(0, "row_num", np.arange(1, len(d) + 1))
        out["data_sec_all"] = d
        out["data_sec_agg_exclude"] = pd.DataFrame({"forbes_id": pd.Series(list(exclude_ids), dtype=object)})
    if ftb_b4a is not None:
        year = to_num_vec(ftb_b4a["A"])
        f = pd.DataFrame({
            "row_num": np.asarray(ftb_b4a.index, dtype=int),
            "taxable_year": year,
            "agic": [None if v is None else str(v) for v in ftb_b4a["C"]],
            "all_returns": to_num_vec(ftb_b4a["D"]),
            "ca_agi": to_num_vec(ftb_b4a["H"]),
            "taxable_income": to_num_vec(ftb_b4a["J"]),
            "total_tax": to_num_vec(ftb_b4a["K"]),
        })
        f = f[~np.isnan(year)].copy()
        f["taxable_year"] = f["taxable_year"].astype(int)
        out["ftb_b4a"] = f.reset_index(drop=True)
    return out


def write_workbook_tables(con, tables):
    for name, df in tables.items():
        df.to_sql(name, con, if_exists="replace", index=False)
    con.commit()


def build_workbook_db(data_sec_all, ftb_b4a, path=None):
    """Write the inputs, run both queries, return the path."""
    path = Path(path or workbook_db_path())
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    con = sqlite3.connect(path)
    try:
        write_workbook_tables(con, workbook_input_tables(data_sec_all, ftb_b4a))
        for f in WORKBOOK_SQL_FILES:
            run_sql_file(con, workbook_sql_file(f))
    finally:
        con.close()
    return path


def memory_con(tables, sql_files):
    """An in-memory database holding `tables`, with `sql_files` already run."""
    con = sqlite3.connect(":memory:")
    write_workbook_tables(con, tables)
    for f in sql_files:
        run_sql_file(con, workbook_sql_file(f))
    return con


# ---- query 2: data_sec_agg ----------------------------------------------------

def read_data_sec_agg_con(con):
    out = pd.read_sql_query("SELECT * FROM data_sec_agg ORDER BY year", con)
    out["year"] = out["year"].astype(int)
    out["n"] = out["n"].astype(int)
    return out


def read_data_sec_agg(db=None):
    con = sqlite3.connect(f"file:{db or workbook_db_path()}?mode=ro", uri=True)
    try:
        return read_data_sec_agg_con(con)
    finally:
        con.close()


# ---- query 3: the FTB table ---------------------------------------------------

def read_ftb_b4a_con(con):
    return {
        "year": pd.read_sql_query("SELECT * FROM ftb_b4a_year ORDER BY taxable_year", con),
        "top": pd.read_sql_query("SELECT * FROM ftb_b4a_top ORDER BY taxable_year, row_num", con),
    }


def read_ftb_b4a(db=None):
    con = sqlite3.connect(f"file:{db or workbook_db_path()}?mode=ro", uri=True)
    try:
        return read_ftb_b4a_con(con)
    finally:
        con.close()


def query_ftb_b4a(ftb_b4a):
    """The raw positional sheet through query 3, in memory."""
    con = memory_con(workbook_input_tables(ftb_b4a=ftb_b4a), ["03_ftb_b4a.sql"])
    try:
        return read_ftb_b4a_con(con)
    finally:
        con.close()


if __name__ == "__main__":
    p = build_workbook_db(extract_data_sec_all(), extract_ftb_b4a())
    print(f"wrote {p}")
