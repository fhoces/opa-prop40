#!/usr/bin/env python3
"""Internal links in the repository's Markdown and HTML files whose target does not exist.

Checks relative and root-relative targets of [text](target), href="..." and src="...".
External links (http, https, mailto), template tokens ({{...}}, {{< ... >}}) and bare anchors
are skipped. Prints one line per broken link, `file: target`, sorted; prints nothing when all
resolve. Exit status is always 0: it reports, the caller decides.

    python3 .claude/skills/opa-review-loop/tools/check_links.py [paths...]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SKIP_DIRS = {".git", "node_modules", "_targets", "outputs", "original-materials", ".quarto",
             "_files", "rsconnect", "__pycache__", ".pytest_cache", "worktrees"}
EXTS = {".md", ".html", ".qmd", ".Rmd"}
MD_LINK = re.compile(r"(?<!\!)\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
MD_IMG = re.compile(r"!\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
ATTR = re.compile(r"(?:href|src)\s*=\s*\"([^\"]+)\"", re.I)
CODE_FENCE = re.compile(r"```.*?```|~~~.*?~~~", re.S)
INLINE_CODE = re.compile(r"`[^`\n]*`")


def targets(path, text):
    if path.suffix in {".md", ".qmd", ".Rmd"}:
        prose = CODE_FENCE.sub("", text)
        prose = INLINE_CODE.sub("", prose)
        found = MD_LINK.findall(prose) + MD_IMG.findall(prose) + ATTR.findall(prose)
    else:
        found = ATTR.findall(text)
    return found


def skip(t):
    t = t.strip()
    return (not t or t.startswith(("http://", "https://", "mailto:", "data:", "javascript:", "#", "tel:"))
            or "{{" in t or "{%" in t or t.startswith("<") or t == "/")


# A template's links are relative to the page it generates, not to the template itself.
TEMPLATE_BASE = {
    "comparison/site/index.template.html": ROOT,
    "comparison/site/explorer.template.html": ROOT / "comparison" / "site" / "explorer",
}


def resolve(path, t):
    t = t.split("#", 1)[0].split("?", 1)[0]
    if not t:
        return None
    if t.startswith("/"):
        return ROOT / t.lstrip("/")
    base = TEMPLATE_BASE.get(str(path.relative_to(ROOT)), path.parent)
    return (base / t).resolve()


def walk(paths):
    for p in paths:
        p = Path(p)
        if p.is_file():
            yield p
            continue
        for q in p.rglob("*"):
            if q.is_file() and q.suffix in EXTS and not (set(q.relative_to(ROOT).parts) & SKIP_DIRS) \
                    and not q.name.endswith("_files"):
                yield q


def main():
    paths = [Path(a).resolve() for a in sys.argv[1:]] or [ROOT]
    broken = set()
    for f in walk(paths):
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for t in targets(f, text):
            if skip(t):
                continue
            r = resolve(f, t)
            if r is None:
                continue
            if not r.exists():
                broken.add(f"{f.relative_to(ROOT)}: {t}")
    for line in sorted(broken):
        print(line)


if __name__ == "__main__":
    main()
