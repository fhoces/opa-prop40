#!/bin/zsh
# Screenshots of each OPA layer for the deck's appendix (the "layers" slides): the explorer
# (Open Output), the report (Open Analysis) and the folder's README on GitHub (Open Materials) of
# the BSZ analysis, the JR analysis and the comparison. Rerun after the pages change (the READMEs
# after a push), then re-render the deck. Needs Google Chrome and Python with Pillow.
# The three code review shots (*-review.png) are not retaken here: the review pages are claude.ai
# artifacts (one per OPA; the URLs are in the three READMEs) that read their record from the
# artifact's store. They were taken on 2026-10-16 from a local copy of the page fed the live record,
# at layer 5 of each chain.
set -e
ROOT=${0:A:h:h:h:h}
OUT=$ROOT/comparison/site/slides/figs/layers
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p $OUT

shot() {  # shot <page, relative to the repo root> <png name>
  rm -f $OUT/$2.png
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size=1280,800 \
    --force-device-scale-factor=1 --virtual-time-budget=10000 \
    --screenshot=$OUT/$2.png "file://$ROOT/$1" 2>/dev/null
  [ -s $OUT/$2.png ] || { echo "no screenshot: $1" >&2; exit 1 }
}

for side in bsz:bsz-analysis/site jr:rjkdc-analysis/site cmp:comparison/site; do
  id=${side%%:*}; dir=${side#*:}
  shot $dir/explorer/index.html $id-output
  shot $dir/repro.html $id-analysis
done
for side in bsz:bsz-analysis jr:rjkdc-analysis cmp:comparison; do
  id=${side%%:*}; dir=${side#*:}
  rm -f $OUT/$id-readme.png
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --window-size=1280,800 \
    --force-device-scale-factor=1 --virtual-time-budget=15000 --user-data-dir=$(mktemp -d) \
    --screenshot=$OUT/$id-readme.png "https://github.com/fhoces/opa-prop40/blob/main/$dir/README.md" 2>/dev/null
  # keep the rendered README, not GitHub's menus and file tree
  python3 -c "from PIL import Image; import sys; Image.open(sys.argv[1]).crop((322, 180, 1280, 800)).save(sys.argv[1])" $OUT/$id-readme.png
done
echo "9 screenshots in $OUT (the 3 code review shots are kept as they are)"
