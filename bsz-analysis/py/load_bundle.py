"""Build data-raw/bundle.sqlite from the confidential author bundle.

Run from bsz-analysis/:

    python py/load_bundle.py                 # every table
    python py/load_bundle.py rtb_ca_cik      # only the named tables

Idempotent: each loader drops and recreates the one table it owns, so the
script can be re-run after the bundle changes. The inputs of query 4 onward
are located through the gitignored data-raw/private-paths.csv (one key per
input, schema in private-paths.example.csv), so no bundle file name appears
in this file for them. To add an input for a later
query, write one function `load_<table>(con, root)` and register it in
LOADERS at the bottom; nothing else changes.

Conventions shared by every loader:
  * strings and ISO dates are TEXT, money is REAL, ids are INTEGER;
  * leading and trailing spaces and tabs are trimmed, as readr::read_csv
    does by default (trim_ws = TRUE);
  * an empty cell becomes NULL (the bundle's CSVs write missing values as
    empty strings, not NA), so SQL aggregates skip it the way R's
    na.rm = TRUE does;
  * the database is a local build artifact and is gitignored (*.sqlite).
"""
import csv
import re
import sqlite3
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from bundle_paths import (  # noqa: E402
    bundle_dir, find_in_bundle, private_file, read_commented_csv, read_private_config,
    residency_overrides_path, sqlite_path,
)

BATCH = 100_000


def _text(v):
    # readr::read_csv trims leading and trailing spaces and tabs from every
    # field by default (trim_ws = TRUE); the RTB CSV has many source values
    # with a trailing space, so trimming here keeps text equal to R's.
    v = v.strip(" \t")
    return v if v != "" else None


def _real(v):
    v = v.strip(" \t")
    return float(v) if v != "" else None


# ---------------------------------------------------------------------------
# Forbes real-time billionaires, one row per (date, forbes_id)
# Source: rtb_all_combined.csv in the bundle (about 5.9M rows)
# ---------------------------------------------------------------------------
RTB_COLUMNS = [
    ("date", "TEXT", _text),
    ("forbes_id", "TEXT", _text),
    ("forbes_name", "TEXT", _text),
    ("state", "TEXT", _text),
    ("country_citizenship", "TEXT", _text),
    ("source", "TEXT", _text),
    ("industries", "TEXT", _text),
    ("forbes_worth", "REAL", _real),
    ("forbes_public_worth", "REAL", _real),
    ("forbes_private_worth", "REAL", _real),
]


def load_rtb_all_combined(con, root):
    path = find_in_bundle("rtb_all_combined.csv", root)
    names = [c[0] for c in RTB_COLUMNS]
    casts = [c[2] for c in RTB_COLUMNS]
    con.execute("DROP TABLE IF EXISTS rtb_all_combined")
    con.execute(
        "CREATE TABLE rtb_all_combined ("
        + ", ".join(f"{n} {t}" for n, t, _ in RTB_COLUMNS)
        + ")"
    )
    insert = (
        f"INSERT INTO rtb_all_combined ({', '.join(names)}) "
        f"VALUES ({', '.join('?' * len(names))})"
    )
    n = 0
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        if header != names:
            raise ValueError(f"Unexpected header in {path.name}: {header}")
        batch = []
        for row in reader:
            batch.append([cast(v) for cast, v in zip(casts, row)])
            if len(batch) >= BATCH:
                con.executemany(insert, batch)
                n += len(batch)
                batch = []
        con.executemany(insert, batch)
        n += len(batch)
    # Indexes after the load: building them once is faster than updating
    # them on every insert.
    con.execute("CREATE INDEX idx_rtb_all_combined_date ON rtb_all_combined (date)")
    con.execute("CREATE INDEX idx_rtb_all_combined_id ON rtb_all_combined (forbes_id)")
    return n


# ---------------------------------------------------------------------------
# forbes_id to SEC CIK, for the 2026-01-01 California list
# Source: rtb_ca_cik_2026_01_01.xlsx in the bundle (237 rows)
# ---------------------------------------------------------------------------
def load_rtb_ca_cik(con, root):
    import openpyxl

    path = find_in_bundle("rtb_ca_cik_2026_01_01.xlsx", root)
    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    rows = wb[wb.sheetnames[0]].iter_rows(values_only=True)
    header = list(next(rows))
    i_id, i_cik = header.index("forbes_id"), header.index("cik")
    out = []
    for r in rows:
        if r[i_id] in (None, ""):
            continue
        cik = r[i_cik]
        # The cik column is numeric with some blank (empty-string) cells.
        if cik in (None, ""):
            cik = None
        else:
            cik = int(float(cik))
        out.append((r[i_id], cik))
    wb.close()
    con.execute("DROP TABLE IF EXISTS rtb_ca_cik")
    con.execute("CREATE TABLE rtb_ca_cik (forbes_id TEXT, cik INTEGER)")
    con.executemany("INSERT INTO rtb_ca_cik VALUES (?, ?)", out)
    return len(out)


# ---------------------------------------------------------------------------
# Residency overrides: ids counted as CA residents whatever the Forbes state
# field says (rule = include), or never counted (rule = exclude).
# Source: data-raw/residency-overrides.csv, gitignored because its rows come
# from the confidential bundle; the schema is in residency-overrides.example.csv.
# ---------------------------------------------------------------------------
def load_rtb_residency_overrides(con, root):
    path = residency_overrides_path()
    if not path.exists():
        raise FileNotFoundError(
            f"{path} not found. It is gitignored; see "
            "data-raw/residency-overrides.example.csv for the schema."
        )
    out = []
    for r in read_commented_csv(path):
        fid, rule = (r.get("forbes_id") or "").strip(), (r.get("rule") or "").strip()
        if not fid:
            # A NULL id would make NOT IN (SELECT ...) exclude every row.
            raise ValueError(f"{path.name}: a row has no forbes_id")
        if rule not in ("include", "exclude"):
            raise ValueError(f"{path.name}: rule must be include or exclude, got {rule!r}")
        out.append((fid, rule, (r.get("note") or "").strip() or None))
    con.execute("DROP TABLE IF EXISTS rtb_residency_overrides")
    con.execute("CREATE TABLE rtb_residency_overrides (forbes_id TEXT, rule TEXT, note TEXT)")
    con.executemany("INSERT INTO rtb_residency_overrides VALUES (?, ?, ?)", out)
    return len(out)


def _int(v):
    # An id or a 0/1 flag. A value that is not a whole number is kept as a
    # float rather than silently truncated.
    v = v.strip(" \t")
    if v == "":
        return None
    x = float(v)
    return int(x) if x.is_integer() else x


def _create_and_insert(con, table, columns, rows):
    """Drop and recreate `table` with (name, type) columns; insert in batches."""
    con.execute(f"DROP TABLE IF EXISTS {table}")
    con.execute(f"CREATE TABLE {table} (" + ", ".join(f"{n} {t}" for n, t in columns) + ")")
    insert = (f"INSERT INTO {table} ({', '.join(n for n, _ in columns)}) "
              f"VALUES ({', '.join('?' * len(columns))})")
    n, batch = 0, []
    for r in rows:
        batch.append(r)
        if len(batch) >= BATCH:
            con.executemany(insert, batch)
            n += len(batch)
            batch = []
    con.executemany(insert, batch)
    return n + len(batch)


def _xlsx_rows(path, sheet=None):
    """Header and data rows of an xlsx sheet (the first one by default)."""
    import openpyxl

    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    ws = wb[sheet] if sheet else wb[wb.sheetnames[0]]
    rows = ws.iter_rows(values_only=True)
    header = list(next(rows))
    data = [list(r) for r in rows if any(v not in (None, "") for v in r)]
    wb.close()
    return header, data


# ---------------------------------------------------------------------------
# Form 4 filings as scraped from SEC EDGAR, one row per reported transaction
# Source: the authors' raw scrape, key form4_raw in data-raw/private-paths.csv
# (about 222k rows, 90 columns; some quoted fields hold line breaks, so the
# file has more lines than rows)
#
# Column types follow what readr::read_csv guesses for this file: the ids,
# flags and quantities listed below are numbers, the transaction date is an
# ISO date, everything else is text. Two renames, because the source names
# clash with SQL: Folder (the filing's accession number) becomes folder, and
# table (1 = non-derivative table, 2 = derivative table of the form) becomes
# table_num. row_num keeps the file order, which the de-duplication in
# sql/04_form4_clean.sql needs ("keep the first copy").
#
# Five multi-owner title columns (owner_title_6 to owner_title_10) are read by
# readr as logical, which turns their few text values into NA. They are
# loaded as text here; the difference cannot matter, because every one of
# them is empty on the single-owner filings the query keeps.
# ---------------------------------------------------------------------------
FORM4_INT = {
    "filer_cik", "document_type", "table", "num_owners", "single_owner",
} | {f"owner_{k}_{i}" for k in ("director", "officer", "ten_percent", "other")
     for i in range(1, 11)}
FORM4_REAL = {
    "shares_traded", "price_per_share", "shares_owned_after_transaction",
    "conversion_price",
}
FORM4_RENAME = {"Folder": "folder", "table": "table_num"}


def load_form4_raw(con, root):
    path = private_file("form4_raw")
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        if len(header) != 90 or header[:3] != ["filer_cik", "document_type", "Folder"]:
            raise ValueError(f"Unexpected header in {path.name}")
        casts, columns = [], [("row_num", "INTEGER")]
        for h in header:
            if h in FORM4_INT:
                casts.append(_int)
                columns.append((FORM4_RENAME.get(h, h), "INTEGER"))
            elif h in FORM4_REAL:
                casts.append(_real)
                columns.append((h, "REAL"))
            else:
                casts.append(_text)
                columns.append((FORM4_RENAME.get(h, h), "TEXT"))
        rows = ([i] + [c(v) for c, v in zip(casts, row)]
                for i, row in enumerate(reader, start=1))
        n = _create_and_insert(con, "form4_raw", columns, rows)
    return n


# ---------------------------------------------------------------------------
# forbes_id to SEC filer CIK for the California list the Form 4 scrape
# started from. Source: key form4_forbes_cik in data-raw/private-paths.csv
# (375 rows; the cik column is text, blank for ids without a filer CIK).
# ---------------------------------------------------------------------------
def load_form4_forbes_cik(con, root):
    header, data = _xlsx_rows(private_file("form4_forbes_cik"))
    i_id, i_cik = header.index("forbes_id"), header.index("cik")
    out = [(r[i_id], _int(str(r[i_cik])) if r[i_cik] not in (None, "") else None)
           for r in data if r[i_id] not in (None, "")]
    return _create_and_insert(con, "form4_forbes_cik",
                              [("forbes_id", "TEXT"), ("cik", "INTEGER")], out)


# ---------------------------------------------------------------------------
# Per-filing price corrections: filings whose reported price per share is off
# by a power of ten. Source: data-raw/form4-price-corrections.csv, gitignored
# because its rows come from the confidential bundle; schema in
# form4-price-corrections.example.csv.
# ---------------------------------------------------------------------------
def load_form4_price_corrections(con, root):
    out = []
    for r in read_private_config("form4-price-corrections.csv"):
        folder, sale = (r.get("folder") or "").strip(), (r.get("sale_text") or "").strip()
        price = (r.get("price_per_share") or "").strip()
        if not (folder and sale and price):
            raise ValueError("form4-price-corrections.csv: folder, sale_text and "
                             "price_per_share are all required")
        out.append((folder, sale, float(price), (r.get("note") or "").strip() or None))
    return _create_and_insert(
        con, "form4_price_corrections",
        [("folder", "TEXT"), ("sale_text", "TEXT"), ("price_per_share", "REAL"), ("note", "TEXT")],
        out)


def _load_csv(con, table, path, numeric, ints=(), rename=None):
    """Load a whole CSV: columns in `numeric` are REAL, in `ints` INTEGER,
    the rest TEXT (trimmed, empty to NULL); row_num keeps the file order."""
    rename = rename or {}
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        casts, columns = [], [("row_num", "INTEGER")]
        for h in header:
            name = rename.get(h, h)
            if h in ints:
                casts.append(_int)
                columns.append((name, "INTEGER"))
            elif h in numeric:
                casts.append(_real)
                columns.append((name, "REAL"))
            else:
                casts.append(_text)
                columns.append((name, "TEXT"))
        rows = ([i] + [c(v) for c, v in zip(casts, row)]
                for i, row in enumerate(reader, start=1))
        return _create_and_insert(con, table, columns, rows)


# ---------------------------------------------------------------------------
# Forbes 400 lists, 1982 to 2025, one row per person and year
# Source: key forbes400 in data-raw/private-paths.csv (about 17k rows).
# Wealth is in $ million, except two years noted in sql/05_forbes_ca_panel.sql.
# forbes_id is filled from 2010 on.
# ---------------------------------------------------------------------------
def load_forbes400_raw(con, root):
    return _load_csv(
        con, "forbes400_raw", private_file("forbes400"),
        numeric={"id", "birthday_day", "birthday_month", "birthday_year", "wealth",
                 "imputed_birth_year_0", "imputed_birth_year_1"},
        ints={"year"})


# ---------------------------------------------------------------------------
# Forbes global billionaire lists, 1997 to 2024 (the March list each year)
# Source: key forbes_global_1997_2024 in data-raw/private-paths.csv (about
# 35k rows). net_worth is text such as "2.5 B" ($ billion).
# ---------------------------------------------------------------------------
def load_forbes_global_9724(con, root):
    return _load_csv(
        con, "forbes_global_9724", private_file("forbes_global_1997_2024"),
        numeric={"rank", "age"}, ints={"year", "month"})


# ---------------------------------------------------------------------------
# Forbes global billionaire lists, 1988 to 2010, a Stata file
# Source: key forbes_global_1988_2010 in data-raw/private-paths.csv (about
# 11k rows). Only the four columns the queries use are loaded: year, name,
# ccitiz (country of citizenship) and worth ($ billion). Stata has no missing
# string, so text is kept as stored (haven::read_dta does not trim or turn
# "" into NA either); the file has no empty or padded values in these columns.
# ---------------------------------------------------------------------------
def load_forbes_global_8810(con, root):
    import pandas as pd

    d = pd.read_stata(private_file("forbes_global_1988_2010"), convert_categoricals=False)
    rows = ((i, int(r.year), r.name, r.ccitiz, None if pd.isna(r.worth) else float(r.worth))
            for i, r in enumerate(d[["year", "name", "ccitiz", "worth"]].itertuples(index=False),
                                  start=1))
    return _create_and_insert(
        con, "forbes_global_8810",
        [("row_num", "INTEGER"), ("year", "INTEGER"), ("name", "TEXT"), ("ccitiz", "TEXT"),
         ("worth", "REAL")], rows)


# ---------------------------------------------------------------------------
# Name and id fixes for the Forbes panel: which Forbes id a list name belongs
# to (by stage of the merge), and ids that Forbes renamed over time.
# Source: data-raw/forbes-name-ids.csv, gitignored because its rows come from
# the confidential bundle; schema in forbes-name-ids.example.csv.
# ---------------------------------------------------------------------------
FORBES_NAME_STAGES = {"forbes400_2004_2009", "global_foreign", "global_2004_us", "rename_id"}


def load_forbes_name_ids(con, root):
    out, seen = [], set()
    for r in read_private_config("forbes-name-ids.csv"):
        stage, match, fid = (r.get(k) or "" for k in ("stage", "match", "forbes_id"))
        if stage not in FORBES_NAME_STAGES or not match or not fid:
            raise ValueError(f"forbes-name-ids.csv: bad row {r}")
        if (stage, match) in seen:
            # One id per name and stage, so the LEFT JOIN cannot duplicate rows.
            raise ValueError(f"forbes-name-ids.csv: {stage} lists {match!r} twice")
        seen.add((stage, match))
        out.append((stage, match, fid))
    return _create_and_insert(
        con, "forbes_name_ids", [("stage", "TEXT"), ("match", "TEXT"), ("forbes_id", "TEXT")], out)


# ---------------------------------------------------------------------------
# PitchBook-NVCA Venture Monitor, one workbook per quarter, sheet "Deals by
# State" (later "Deals x State" or "Deals x state"): venture deals per US
# state and year, year to date as of the quarter, as two side-by-side blocks,
# deal count (#) and deal value ($ million).
# Source: key venture_monitor_files in data-raw/private-paths.csv, a path
# template with {year} and {quarter} placeholders.
#
# This loader is the lesson of query 6: the workbooks drift. The sheet name
# changes, the header row moves (row 6, then row 7), the first year shown
# moves (2006, later a rolling 11 years), the current year's header can be a
# number or text with a star ("2019*"), and the two blocks swap places (value
# first until 2019, count first from 2020). Instead of one reader per layout,
# the loader finds each piece:
#   * the sheet: the one whose name, lowercased with " x " read as " by ",
#     is "deals by state";
#   * the header row: the first row with a year in it;
#   * the blocks: runs of adjacent year columns (there must be two, of equal
#     length);
#   * which block is which: the title above it says "($M)" or "value" for
#     dollars, "(#)" or "count" for deals;
#   * the state: the column just left of the first block.
# Every cell of the two blocks becomes one row (state, measure, year, value),
# so the reshaping happens in SQL. An Excel error cell (such as #REF!) is
# loaded as NULL, as readxl reads it as NA. Workbooks without such a sheet
# (the earliest ones, which the query does not use) are skipped and counted.
# ---------------------------------------------------------------------------
_YEAR_HDR = re.compile(r"^\s*(\d{4})")


def _year_of(v):
    if isinstance(v, (int, float)) and not isinstance(v, bool) and 1990 < v < 2100:
        return int(v)
    if isinstance(v, str):
        m = _YEAR_HDR.match(v)
        return int(m.group(1)) if m else None
    return None


def _measure_of(title):
    t = (title or "").lower()
    if "($m)" in t or "value" in t or "capital" in t:
        return "value"
    if "(#)" in t or "count" in t:
        return "count"
    raise ValueError(f"Cannot tell count from value in block title {title!r}")


def _vm_cells(path):
    import openpyxl

    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    sheets = [s for s in wb.sheetnames if s.lower().replace(" x ", " by ") == "deals by state"]
    if len(sheets) != 1:
        wb.close()
        return None
    rows = [list(r) for r in wb[sheets[0]].iter_rows(values_only=True)]
    wb.close()
    hr = next(i for i, r in enumerate(rows) if any(_year_of(v) for v in r))
    header = rows[hr]
    cols = [j for j, v in enumerate(header) if _year_of(v)]
    blocks = []
    for j in cols:
        if blocks and j == blocks[-1][-1] + 1:
            blocks[-1].append(j)
        else:
            blocks.append([j])
    if len(blocks) != 2 or len(blocks[0]) != len(blocks[1]):
        raise ValueError(f"{path.name}: expected two equal blocks of year columns")
    titles = rows[hr - 1]
    measures = []
    for b in blocks:
        t = [titles[j] for j in range(0, b[0] + 1) if j < len(titles) and titles[j] is not None]
        measures.append(_measure_of(t[-1] if t else None))
    if sorted(measures) != ["count", "value"]:
        raise ValueError(f"{path.name}: block titles give {measures}")
    state_col = blocks[0][0] - 1
    out, n_err = [], 0
    for i, r in enumerate(rows[hr + 1:], start=hr + 2):
        if all(v in (None, "") for v in r):
            continue
        state = r[state_col] if state_col < len(r) else None
        state = state.strip() if isinstance(state, str) else state
        for b, m in zip(blocks, measures):
            for j in b:
                v = r[j] if j < len(r) else None
                if isinstance(v, str):
                    if v.startswith("#"):
                        n_err += 1
                        v = None
                    else:
                        raise ValueError(f"{path.name}: text {v!r} in a number cell")
                out.append((i, state, m, str(header[j]).strip(), _year_of(header[j]),
                            None if v is None else float(v)))
    return out, n_err


def load_vm_state_cells(con, root):
    template = str(private_file("venture_monitor_files"))
    pattern = re.compile(re.escape(template).replace(r"\{year\}", r"(\d{4})")
                         .replace(r"\{quarter\}", r"(\d)") + "$")
    folder = Path(template).parent
    found = []
    for p in sorted(folder.iterdir()):
        m = pattern.match(str(p))
        if m:
            found.append((int(m.group(1)), int(m.group(2)), p))
    rows, skipped, errors = [], 0, 0
    for year, quarter, p in found:
        got = _vm_cells(p)
        if got is None:
            skipped += 1
            continue
        cells, n_err = got
        errors += n_err
        rows += [(year, quarter) + c for c in cells]
    print(f"  venture monitor: {len(found)} workbooks, {skipped} without a state sheet, "
          f"{errors} error cell(s) read as NULL")
    return _create_and_insert(
        con, "vm_state_cells",
        [("file_year", "INTEGER"), ("file_quarter", "INTEGER"), ("sheet_row", "INTEGER"),
         ("state", "TEXT"), ("measure", "TEXT"), ("header", "TEXT"), ("year", "INTEGER"),
         ("value", "REAL")], rows)


def _template_files(key, field, digits):
    """Files matching a private-paths template with one {field} placeholder."""
    template = str(private_file(key))
    pattern = re.compile(re.escape(template).replace(r"\{" + field + r"\}", rf"(\d{{{digits}}})") + "$")
    hits = []
    for p in sorted(Path(template).parent.iterdir()):
        m = pattern.match(str(p))
        if m:
            hits.append((m.group(1), p))
    return hits


def _text_asis(v):
    # base R's read.csv() keeps text as written (no trimming); empty to NULL.
    return v if v != "" else None


# ---------------------------------------------------------------------------
# Compustat North America daily securities, one snapshot file per year (one
# trading day in January, 2004 to 2026), every listed security that day.
# Source: key comp_daily_snapshots in data-raw/private-paths.csv, a path
# template with a {date} placeholder (8 digits). Only the columns the link
# step uses are loaded. snap_order numbers the files from the newest (1) to
# the oldest, the order in which the authors stack them; the link step keeps
# the values of the last row in that order, i.e. the oldest snapshot.
# ---------------------------------------------------------------------------
SNAP_COLS = [("tic", "TEXT"), ("datadate", "TEXT"), ("conm", "TEXT"), ("cik", "INTEGER"),
             ("cusip", "TEXT"), ("gvkey", "INTEGER"), ("iid", "TEXT"), ("curcdd", "TEXT")]


def load_comp_daily_snapshots(con, root):
    files = sorted(_template_files("comp_daily_snapshots", "date", 8), reverse=True)
    if not files:
        raise FileNotFoundError("no Compustat snapshot files matched the template")

    def rows():
        for order, (_, p) in enumerate(files, start=1):
            with open(p, newline="", encoding="utf-8", errors="replace") as f:
                reader = csv.reader(f)
                header = next(reader)
                idx = [header.index(c) for c, _ in SNAP_COLS]
                for i, r in enumerate(reader, start=1):
                    yield [order, i] + [
                        (_int(r[j]) if t == "INTEGER" else _text_asis(r[j]))
                        for j, (_, t) in zip(idx, SNAP_COLS)]

    print(f"  Compustat snapshots: {len(files)} files")
    return _create_and_insert(con, "comp_daily_snapshots",
                              [("snap_order", "INTEGER"), ("row_num", "INTEGER")] + SNAP_COLS,
                              rows())


# ---------------------------------------------------------------------------
# Issuer to Compustat security fixes for the Form 4 link step.
# Source: data-raw/form4-gvkey-fixes.csv, gitignored because its rows come
# from the confidential bundle; schema in form4-gvkey-fixes.example.csv.
# ---------------------------------------------------------------------------
def load_form4_gvkey_fixes(con, root):
    out, seen = [], set()
    for r in read_private_config("form4-gvkey-fixes.csv"):
        stage = r.get("stage") or ""
        if stage not in ("cik_match", "manual"):
            raise ValueError(f"form4-gvkey-fixes.csv: bad stage {stage!r}")
        key = (stage, int(r["issuer_cik"]))
        if key in seen:
            raise ValueError(f"form4-gvkey-fixes.csv: {key} listed twice")
        seen.add(key)
        out.append((stage, int(r["issuer_cik"]), int(r["gvkey"]), r["iid"], r.get("note") or None))
    return _create_and_insert(
        con, "form4_gvkey_fixes",
        [("stage", "TEXT"), ("issuer_cik", "INTEGER"), ("gvkey", "INTEGER"), ("iid", "TEXT"),
         ("note", "TEXT")], out)


# ---------------------------------------------------------------------------
# Compustat North America daily securities, every trading day since mid-2003
# Source: key comp_daily_prices in data-raw/private-paths.csv. The file holds
# about 11 GB of text (it may be a zip archive with one CSV inside; both are
# read as a stream). Loading it whole would make a database of several GB, so
# this loader keeps only the securities the Form 4 link step found: the
# gvkeys in table form4_gvkey_list, which sql/07_form4_gvkey_link.sql writes.
# Run that query first. This is the same filter the authors apply right after
# reading the file. The gvkey is the last field of each line and never quoted,
# so a line is parsed in full only when its gvkey is on the list.
# ---------------------------------------------------------------------------
DAILY_TYPES = {"cik": "TEXT", "exchg": "REAL", "adrrc": "REAL", "ajexdi": "REAL",
               "cshoc": "REAL", "dvi": "REAL", "prccd": "REAL", "gvkey": "INTEGER"}


def load_comp_daily_form4(con, root):
    import io
    import zipfile

    try:
        wanted = {g for (g,) in con.execute("SELECT gvkey_text FROM form4_gvkey_list")}
    except sqlite3.OperationalError:
        raise RuntimeError("table form4_gvkey_list missing: run "
                           "py/run_sql.py sql/07_form4_gvkey_link.sql first") from None
    path = private_file("comp_daily_prices")
    if zipfile.is_zipfile(path):
        z = zipfile.ZipFile(path)
        members = z.infolist()
        if len(members) != 1:
            raise ValueError(f"{path.name}: expected one file in the archive")
        stream = io.TextIOWrapper(z.open(members[0]), encoding="utf-8", errors="replace",
                                  newline="")
    else:
        stream = open(path, newline="", encoding="utf-8", errors="replace")
    with stream:
        header = next(csv.reader([stream.readline()]))
        if header[-1] != "gvkey":
            raise ValueError(f"{path.name}: gvkey is not the last column")
        columns = [("row_num", "INTEGER")] + [(c, DAILY_TYPES.get(c, "TEXT")) for c in header]
        casts = [(_int if t == "INTEGER" else _real if t == "REAL" else _text)
                 for _, t in columns[1:]]

        def rows():
            seen = 0
            for i, line in enumerate(stream, start=1):
                g = line.rstrip("\r\n").rsplit(",", 1)[-1]
                if g not in wanted:
                    continue
                r = next(csv.reader([line]))
                seen += 1
                yield [i] + [c(v) for c, v in zip(casts, r)]
            print(f"  Compustat daily: {i:,} lines read, {seen:,} kept")

        n = _create_and_insert(con, "comp_daily_form4", columns, rows())
    con.execute("CREATE INDEX idx_comp_daily_form4 ON comp_daily_form4 (gvkey, iid, datadate)")
    return n


# One entry per table. Later queries add their inputs here.
LOADERS = {
    "rtb_all_combined": load_rtb_all_combined,
    "rtb_ca_cik": load_rtb_ca_cik,
    "rtb_residency_overrides": load_rtb_residency_overrides,
    "form4_raw": load_form4_raw,
    "form4_forbes_cik": load_form4_forbes_cik,
    "form4_price_corrections": load_form4_price_corrections,
    "forbes400_raw": load_forbes400_raw,
    "forbes_global_9724": load_forbes_global_9724,
    "forbes_global_8810": load_forbes_global_8810,
    "forbes_name_ids": load_forbes_name_ids,
    "vm_state_cells": load_vm_state_cells,
    "comp_daily_snapshots": load_comp_daily_snapshots,
    "form4_gvkey_fixes": load_form4_gvkey_fixes,
    # Needs table form4_gvkey_list (sql/07_form4_gvkey_link.sql), so it is
    # loaded only when named: python py/load_bundle.py comp_daily_form4
    "comp_daily_form4": load_comp_daily_form4,
}

# Loaded by a bare `python py/load_bundle.py` (every table but the ones that
# depend on a query's output).
DEFAULT_TABLES = [t for t in LOADERS if t != "comp_daily_form4"]


def main(argv):
    wanted = argv or DEFAULT_TABLES
    unknown = [t for t in wanted if t not in LOADERS]
    if unknown:
        sys.exit(f"Unknown table(s): {', '.join(unknown)}. Known: {', '.join(LOADERS)}")
    root = bundle_dir()
    db = sqlite_path()
    db.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(db)
    # A rebuildable artifact: trade crash safety for load speed.
    con.execute("PRAGMA journal_mode = OFF")
    con.execute("PRAGMA synchronous = OFF")
    for table in wanted:
        t0 = time.time()
        with con:
            n = LOADERS[table](con, root)
        (check,) = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()
        if check != n:
            raise RuntimeError(f"{table}: inserted {n} rows but the table has {check}")
        print(f"{table}: {n:,} rows in {time.time() - t0:.1f} s")
    con.close()
    print(f"database: {db}")


if __name__ == "__main__":
    main(sys.argv[1:])
