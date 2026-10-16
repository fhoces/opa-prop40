#!/bin/zsh
# Screenshots of each OPA layer for the deck's appendix (the "layers" slides): the explorer
# (Open Output), the report (Open Analysis) and the materials page (Open Materials) of the BSZ
# analysis, the JR analysis and the comparison. Rerun after the pages change, then re-render the
# deck. Needs Google Chrome.
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
  shot $dir/materials.html $id-materials
done
echo "9 screenshots in $OUT"
