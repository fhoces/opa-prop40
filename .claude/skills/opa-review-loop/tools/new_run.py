#!/usr/bin/env python3
"""Create the next run directory under feedback/ and write its 00-run.md. Prints the directory.

    RUN=$(python3 .claude/skills/opa-review-loop/tools/new_run.py --args "--iterations 2")
"""
import argparse
import datetime
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]  # tools/ -> opa-review-loop/ -> skills/ -> .claude/ -> ROOT


def sh(*cmd):
    try:
        return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, check=False).stdout.strip()
    except OSError:
        return ""


def playwright_available():
    candidates = []
    try:
        candidates.append(Path(sh("npm", "root", "-g")) / "playwright")
    except Exception:
        pass
    candidates.append(Path("/opt/node-tools/node_modules/playwright"))
    candidates.append(ROOT / "node_modules" / "playwright")
    return any(c.exists() for c in candidates if str(c))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--args", default="", help="the raw arguments the loop was called with")
    a = ap.parse_args()

    feedback = ROOT / "feedback"
    feedback.mkdir(exist_ok=True)
    nums = [int(m.group(1)) for p in feedback.iterdir() if p.is_dir()
            for m in [re.match(r"^(\d{3})-", p.name)] if m]
    n = max(nums, default=0) + 1
    today = datetime.date.today().isoformat()
    run = feedback / f"{n:03d}-{today}"
    run.mkdir()
    (run / "wp").mkdir()

    commit = sh("git", "rev-parse", "HEAD")
    branch = sh("git", "rev-parse", "--abbrev-ref", "HEAD")
    dirty = sh("git", "status", "--short")
    tools = {
        "Rscript": bool(shutil.which("Rscript")),
        "quarto": bool(shutil.which("quarto")),
        "node": bool(shutil.which("node")),
        "python3": True,
        "Playwright (node module)": playwright_available(),
    }
    remote = os.environ.get("CLAUDE_CODE_REMOTE", "") == "true"

    lines = [
        f"# Run {n:03d}, {today}",
        "",
        f"- Branch: `{branch}`",
        f"- Start commit: `{commit}`",
        f"- Arguments: `{a.args or '(defaults)'}`",
        f"- Environment: {'cloud (CLAUDE_CODE_REMOTE=true)' if remote else 'local'}",
        "- Tools: " + ", ".join(f"{k} {'yes' if v else 'no'}" for k, v in tools.items()),
        "- Working tree at start: " + ("clean" if not dirty else "modified files present (see below)"),
    ]
    if dirty:
        lines += ["", "```", dirty, "```"]
    lines += ["", "## Checks", "", "(appended by the orchestrator in Phase 4)", "",
              "## Needs a local render", "", "(appended by the orchestrator in Phase 4)", ""]
    (run / "00-run.md").write_text("\n".join(lines), encoding="utf-8")
    print(run)


if __name__ == "__main__":
    main()
