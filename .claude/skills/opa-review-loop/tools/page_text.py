#!/usr/bin/env python3
"""Print an HTML page as readable text: headings, paragraphs, lists, tables and footnotes kept;
scripts, styles and tags dropped. Static text only: numbers that a page fills by script are not
here (use screenshot.cjs --text for those).

    python3 .claude/skills/opa-review-loop/tools/page_text.py bsz-analysis/site/index.html
"""
import html
import re
import sys
from pathlib import Path


def page_text(src):
    s = re.sub(r"<!--.*?-->", "", src, flags=re.S)
    s = re.sub(r"<(script|style|noscript|svg)\b.*?</\1>", "", s, flags=re.S | re.I)
    title = re.search(r"<title>(.*?)</title>", s, flags=re.S | re.I)
    # block structure
    s = re.sub(r"<h([1-6])[^>]*>", lambda m: "\n\n" + "#" * int(m.group(1)) + " ", s, flags=re.I)
    s = re.sub(r"</h[1-6]>", "\n", s, flags=re.I)
    s = re.sub(r"<(p|div|section|article|header|footer|nav|aside|details|summary|figure|figcaption|blockquote|pre)\b[^>]*>", "\n", s, flags=re.I)
    s = re.sub(r"</(p|div|section|article|header|footer|nav|aside|details|figure|blockquote|pre)>", "\n", s, flags=re.I)
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    s = re.sub(r"<li[^>]*>", "\n- ", s, flags=re.I)
    s = re.sub(r"<tr[^>]*>", "\n| ", s, flags=re.I)
    s = re.sub(r"</t[dh]>", " | ", s, flags=re.I)
    s = re.sub(r"<sup[^>]*>", "^", s, flags=re.I)
    s = re.sub(r"</sup>", "", s, flags=re.I)
    s = re.sub(r"<a\b[^>]*href=\"([^\"]*)\"[^>]*>", lambda m: "[", s, flags=re.I)
    s = re.sub(r"</a>", "]", s, flags=re.I)
    s = re.sub(r"<img\b[^>]*alt=\"([^\"]*)\"[^>]*>", lambda m: f"(image: {m.group(1)})", s, flags=re.I)
    s = re.sub(r"<[^>]+>", " ", s)
    s = html.unescape(s)
    s = re.sub(r"[ \t\r\f\v]+", " ", s)
    s = re.sub(r" *\n *", "\n", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = s.replace("[ ]", "")
    out = s.strip() + "\n"
    if title:
        out = f"TITLE: {html.unescape(title.group(1).strip())}\n\n" + out
    return out


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for p in sys.argv[1:]:
        src = Path(p).read_text(encoding="utf-8", errors="replace")
        if len(sys.argv) > 2:
            print(f"\n===== {p} =====\n")
        sys.stdout.write(page_text(src))


if __name__ == "__main__":
    main()
