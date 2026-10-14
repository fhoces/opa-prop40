#!/usr/bin/env python3
"""Merge the reviewer's fields from the artifact's data store into a ledger JSON.

Claude Code downloads the store's layer docs with the ArtifactData tool (action list,
out_dir) and then runs:  python3 review/pull_store.py <store_dir>/layers review/bsz.json
Only state, understanding, missing, feedback and updated are copied; the chain text and
snippets stay as seeded from the code.
"""
import json
import sys
from pathlib import Path

USER_FIELDS = ["state", "understanding", "missing", "feedback", "updated"]


def main(store_dir, ledger_path):
    ledger = json.loads(Path(ledger_path).read_text())
    changed = 0
    for L in ledger["layers"]:
        doc = Path(store_dir) / f"{L['id']}.json"
        if not doc.exists():
            continue
        d = json.loads(doc.read_text())
        for f in USER_FIELDS:
            if f in d and d[f] != L.get(f):
                L[f] = d[f]
                changed += 1
    Path(ledger_path).write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n")
    print(f"{ledger_path}: {changed} fields updated from {store_dir}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
