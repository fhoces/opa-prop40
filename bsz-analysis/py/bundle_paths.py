"""Where the phase-2 inputs and outputs live.

The author bundle is confidential (re-analysis permitted, no public sharing),
so it sits under the gitignored original-materials/ directory and never
reaches git. Everything built from it (the SQLite database, the CSV exports
under data-raw/sql-out/) is gitignored too.

Set BSZ_BUNDLE_DIR to point at a bundle somewhere else (for example the main
checkout's copy, from a git worktree).
"""
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


def sqlite_path():
    """The SQLite database that py/load_bundle.py builds (gitignored)."""
    return BSZ_DIR / "data-raw" / "bundle.sqlite"


def sql_out_dir(lang=None):
    """data-raw/sql-out/ (gitignored), or its py/ or r/ subdirectory."""
    out = BSZ_DIR / "data-raw" / "sql-out"
    return out / lang if lang else out


def public_workbook_path():
    """The public August workbook BSZ_MainTablesFigures.xlsx (phase 1's input)."""
    materials = os.environ.get("CAWTBSZ_MATERIALS", "")
    base = Path(materials) if materials else BSZ_DIR / "original-materials"
    return base / "BSZ_MainTablesFigures.xlsx"
