#!/usr/bin/env python3
"""Write the per-layer JSON files that Claude Code pushes to the review page's data store.

Run from the repo root after re-seeding:  python3 review/store_push.py review/bsz.json <out_dir>
One file per layer under <out_dir>/<layer id>.json holding every seeded field plus the
feedback list and the updated date, never the reviewer's state, understanding or missing
(those are written on the page). Also <out_dir>/chain.json for chains/<opa>. Claude Code
then sends one ArtifactData batch of `update` writes pinned to the versions it last read.
"""
import json
import sys
from pathlib import Path

NEVER_PUSH = {"state", "understanding", "missing"}


def main(ledger_path, out_dir):
    j = json.loads(Path(ledger_path).read_text())
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    chain = {k: v for k, v in j.items() if k != "layers"}
    chain["layerIds"] = [L["id"] for L in j["layers"]]
    (out / "chain.json").write_text(json.dumps(chain, ensure_ascii=False))
    for L in j["layers"]:
        d = {k: v for k, v in L.items() if k not in NEVER_PUSH}
        (out / f"{L['id']}.json").write_text(json.dumps(d, ensure_ascii=False))
    print(f"{out}: chain.json (chains/{j['opa']}) and {len(j['layers'])} layer files")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
