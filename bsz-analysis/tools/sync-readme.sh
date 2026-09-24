#!/usr/bin/env bash
# Inline _raw-sources.md into README.md between sentinel markers.
#
# Source of truth: _raw-sources.md.
# Quarto picks it up via {{< include _raw-sources.md >}} at render time.
# GitHub renders README.md statically and cannot resolve Quarto shortcodes,
# so we keep a literal copy of the partial between markers and re-inline it
# here whenever _raw-sources.md changes.
#
# Usage:  tools/sync-readme.sh
# Errors if either sentinel is missing in README.md.
set -euo pipefail

cd "$(dirname "$0")/.."

partial=_raw-sources.md
readme=README.md
start='<!-- include:_raw-sources.md -->'
end='<!-- /include -->'

[ -f "$partial" ] || { echo "missing $partial" >&2; exit 1; }
[ -f "$readme"  ] || { echo "missing $readme"  >&2; exit 1; }
grep -qF "$start" "$readme" || { echo "missing sentinel '$start' in $readme" >&2; exit 1; }
grep -qF "$end"   "$readme" || { echo "missing sentinel '$end' in $readme"   >&2; exit 1; }

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v partial="$partial" -v start="$start" -v end="$end" '
  function inline_partial(    line) {
    while ((getline line < partial) > 0) print line
    close(partial)
  }
  $0 == start { print; inline_partial(); inside = 1; next }
  $0 == end   { print; inside = 0; next }
  inside      { next }
              { print }
' "$readme" > "$tmp"

mv "$tmp" "$readme"
echo "synced: $readme <- $partial"
