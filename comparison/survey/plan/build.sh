#!/bin/zsh
# Builds comparison/survey/plan/plan.pdf from comparison/survey/PRE-ANALYSIS-PLAN.md (the source of
# truth). pandoc turns the markdown into plan-body.tex; plan.tex wraps it in the same preamble as
# the power appendix; the two forms (Appendix B) are printed from forms/*.json and included; latexmk
# makes the PDF. Usage: zsh comparison/survey/plan/build.sh
set -e
ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
cd "$ROOT/comparison/survey/plan"
PANDOC=/Applications/quarto/bin/tools/aarch64/pandoc
"$PANDOC" -f markdown+pipe_tables -t latex --shift-heading-level-by=-1 --wrap=preserve --columns=72 \
  ../PRE-ANALYSIS-PLAN.md -o plan-body.tex
# Appendix B: the control and treatment forms, from their saved definitions (forms/*.json)
python3 forms/print_forms.py > /dev/null
for n in control treatment; do
  rm -f forms/$n.pdf
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
    --no-pdf-header-footer --print-to-pdf="$PWD/forms/$n.pdf" "file://$PWD/forms/$n.html" 2>/dev/null
  [ -s forms/$n.pdf ] || { echo "forms/$n.pdf not written"; exit 1; }
done
latexmk -pdf -interaction=nonstopmode plan.tex > build.log 2>&1 || { tail -30 build.log; exit 1; }
grep -o "Output written on plan.pdf ([0-9]* pages" plan.log
