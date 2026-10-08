"""Where the phase-2 inputs and outputs live.

The author bundle is confidential (re-analysis permitted, no public sharing),
so it sits under the gitignored original-materials/ directory and never
reaches git. Everything built from it (the SQLite database, the CSV exports
under data-raw/sql-out/) is gitignored too, and so are the two small private
files the code reads next to it:

  data-raw/residency-overrides.csv  the residency override table
  data-raw/private-paths.csv        where the answer-key files sit in the bundle

Their schemas are documented in the committed *.example.csv files.

Set BSZ_BUNDLE_DIR to point at a bundle somewhere else (for example the main
checkout's copy, from a git worktree).
"""
import csv
import os
from pathlib import Path

ENV_VAR = "BSZ_BUNDLE_DIR"

# bsz-analysis/, the directory that holds py/, sql/, R/ and data-raw/.
BSZ_DIR = Path(__file__).resolve().parent.parent

DEFAULT_BUNDLE_DIR = (
    BSZ_DIR / "original-materials" / "author-shared"
    / "2026-09-23_bsz-replication-code-data"
)


def bundle_dir(must_exist=True):
    """Root of the author bundle (BSZ_BUNDLE_DIR, else the default path)."""
    raw = os.environ.get(ENV_VAR, "")
    path = Path(raw) if raw else DEFAULT_BUNDLE_DIR
    if must_exist and not path.is_dir():
        raise FileNotFoundError(
            f"Author bundle not found at {path}. It is confidential and not in git; "
            f"place it there or set the {ENV_VAR} environment variable to its root."
        )
    return path


def find_in_bundle(basename, root=None):
    """The one file in the bundle with this name, wherever it sits."""
    root = root or bundle_dir()
    hits = sorted(root.rglob(basename))
    if len(hits) != 1:
        raise FileNotFoundError(
            f"Expected exactly one {basename} under {root}, found {len(hits)}."
        )
    return hits[0]


def sqlite_path():
    """The SQLite database that py/load_bundle.py builds (gitignored)."""
    return BSZ_DIR / "data-raw" / "bundle.sqlite"


def sql_out_dir(lang=None):
    """data-raw/sql-out/ (gitignored), or its py/ or r/ subdirectory."""
    out = BSZ_DIR / "data-raw" / "sql-out"
    return out / lang if lang else out


def residency_overrides_path():
    """The residency override table (gitignored; see the .example.csv)."""
    return BSZ_DIR / "data-raw" / "residency-overrides.csv"


def private_config_path(name):
    """A small gitignored config file in data-raw/ (schema in <name>.example.csv)."""
    return BSZ_DIR / "data-raw" / name


def read_private_config(name):
    """Rows of a gitignored data-raw/ config CSV, with a clear error when absent."""
    path = private_config_path(name)
    if not path.exists():
        example = name.replace(".csv", ".example.csv")
        raise FileNotFoundError(
            f"{path} not found. It is gitignored; see data-raw/{example} for the schema."
        )
    return read_commented_csv(path)


def read_commented_csv(path):
    """Rows of a small CSV as dicts, skipping lines that start with '#'."""
    with open(path, newline="", encoding="utf-8") as f:
        lines = [ln for ln in f if not ln.lstrip().startswith("#")]
    return list(csv.DictReader(lines))


def private_file(key):
    """An answer-key file in the bundle, by its key in data-raw/private-paths.csv."""
    cfg = BSZ_DIR / "data-raw" / "private-paths.csv"
    if not cfg.exists():
        raise FileNotFoundError(
            f"{cfg} not found. It is gitignored; see data-raw/private-paths.example.csv."
        )
    paths = {r["key"]: r["path"] for r in read_commented_csv(cfg)}
    if key not in paths:
        raise KeyError(f"No '{key}' entry in {cfg}")
    return bundle_dir() / paths[key]


def public_workbook_path():
    """The public August workbook BSZ_MainTablesFigures.xlsx (phase 1's input)."""
    materials = os.environ.get("CAWTBSZ_MATERIALS", "")
    base = Path(materials) if materials else BSZ_DIR / "original-materials"
    return base / "BSZ_MainTablesFigures.xlsx"
