"""Python twin of R/compute_data_sec_agg.R: yearly aggregates of data_sec_all.

The computation is the shared query sql/02_data_sec_agg.sql, run verbatim in
an in-memory SQLite database (py/run_export.py reads the same table from
data-raw/workbook-py.sqlite instead). R/compute_data_sec_agg.R explains the
two filters: Ellison is excluded, and an exact re-paste of four 2025 rows at
the tail of August's sheet is dropped.
"""
from workbook_db import (
    ELLISON_FORBES_ID, memory_con, read_data_sec_agg_con, workbook_input_tables,
)


def compute_data_sec_agg(data_sec_all, exclude_ids=(ELLISON_FORBES_ID,), m_to_b=1000):
    if m_to_b != 1000:
        raise ValueError("sql/02_data_sec_agg.sql converts $ million to $ billion; m_to_b must be 1000")
    con = memory_con(workbook_input_tables(data_sec_all=data_sec_all, exclude_ids=exclude_ids),
                     ["02_data_sec_agg.sql"])
    try:
        return read_data_sec_agg_con(con)
    finally:
        con.close()
