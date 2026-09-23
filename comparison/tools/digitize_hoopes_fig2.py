"""Digitize Hoopes (2026), "Galle v Rauh", SSRN 6428578, Figure 2 (PDF p.6).

The note prints no values for its waterfall, so every number here is READ OFF THE
CHART. Method:
  1. Rasterize PDF p.6 at 300 dpi with Ghostscript.
  2. Locate the seven y-axis tick marks (100, 80, ..., -20) as darkness-weighted
     centroids in the column just left of the axis frame, and fit value = a + b*row
     by least squares (residual reported).
  3. For each bar, average colour saturation over 41 columns at the bar's centre
     and find the rows where saturation crosses half its peak (sub-pixel). The
     embedded chart is a low-resolution bitmap, so edges are soft (~3 px); the
     half-maximum crossing is the edge estimate.
  4. Step size = the bar's own top-to-bottom span. Reading uncertainty per step is
     the tick-fit residual plus 1.5 px of edge blur on each edge.

Usage: python digitize_hoopes_fig2.py <path-to-ssrn-6428578.pdf> <out.csv>
The PDF is third-party and gitignored (comparison/original-materials/); the output
CSV is committed as comparison/data/hoopes-fig2.csv.
"""
import csv, subprocess, sys, tempfile, os
import numpy as np
from PIL import Image

pdf, out = sys.argv[1], sys.argv[2]
tmp = os.path.join(tempfile.mkdtemp(), "p6.png")
subprocess.run(["gs", "-q", "-dNOPAUSE", "-dBATCH", "-sDEVICE=png16m", "-r300",
                "-dFirstPage=6", "-dLastPage=6", f"-sOutputFile={tmp}", pdf], check=True)
im = np.asarray(Image.open(tmp).convert("RGB")).astype(float)
gray = im.mean(axis=2)
sat = im.max(axis=2) - im.min(axis=2)

# ---- y axis ------------------------------------------------------------------
TICK_COL, Y0, Y1 = 405, 920, 1760
col = gray[Y0:Y1, TICK_COL]
groups, cur = [], []
for i, v in enumerate(col):
    if v < 215:
        cur.append((Y0 + i, 255 - v))
    elif cur:
        groups.append(cur); cur = []
tick_rows = [sum(y * w for y, w in g) / sum(w for _, w in g) for g in groups]
tick_vals = [100, 80, 60, 40, 20, 0, -20]
assert len(tick_rows) == 7, tick_rows
b, a = np.polyfit(tick_rows, tick_vals, 1)
fit_resid = float(np.abs(np.array(tick_vals) - (a + b * np.array(tick_rows))).max())
px_per_b = 1 / abs(b)
val = lambda row: a + b * row

# ---- bars (centre x in 300-dpi pixels) -----------------------------------------
bars = [("galle_estimate", "Galle estimate", 591),
        ("residency_correction", "Residency correction", 835),
        ("confirmed_departures", "Confirmed departures", 1079),
        ("additional_movers", "Additional movers", 1323),
        ("additional_behavioral_response", "Additional behavioral response", 1568),
        ("real_estate_exclusion", "Real estate exclusion", 1812),
        ("income_tax_loss", "Income tax loss", 2056)]

def edges(x, lo, hi):
    s = sat[lo:hi, x - 20:x + 21].mean(axis=1)
    half = s.max() / 2
    idx = np.where(s > half)[0]
    runs, cur = [], [idx[0]]
    for i in idx[1:]:
        if i - cur[-1] <= 2: cur.append(i)
        else: runs.append(cur); cur = [i]
    runs.append(cur)
    r = max(runs, key=len)
    def cross(i0, i1):
        return i0 + (half - s[i0]) / (s[i1] - s[i0]) * (i1 - i0)
    return lo + cross(r[0] - 1, r[0]), lo + cross(r[-1] + 1, r[-1])

rows = []
for key, label, x in bars:
    # The real-estate "bar" is a thin line at ~48; search only around it so the
    # blue zero line (row ~1539) is not picked up instead.
    lo, hi = (1230, 1275) if key == "real_estate_exclusion" else (900, 1760)
    top, bot = edges(x, lo, hi)
    v_top, v_bot = val(top), val(bot)
    note = ""
    if key == "galle_estimate":
        # The bar runs into the axis frame at 100, so its top is clipped; the
        # half-maximum crossing sits ~0.5 below the frame. Hoopes's text (p.3) and
        # Figure 1 (p.2) put it at $100B.
        v_top, note = 100.0, "top clipped by the axis frame at 100; value from p.3 text"
    if key == "residency_correction":
        v_top, note = 100.0, "starts at the Galle bar's top (100); its own top edge is merged with the axis frame"
    unc = fit_resid + 2 * 1.5 / px_per_b
    if key == "galle_estimate":
        v_bot = 0.0
    if key == "real_estate_exclusion":
        # Drawn as a line only ~2 px tall before blur, i.e. at the resolution
        # limit: its own half-maximum edges overstate it. Take the waterfall's
        # continuity instead: it starts where the behavioral bar ends and ends
        # where the income-tax bar starts. Wider uncertainty.
        v_top, v_bot = rows[-1]["end"], None
        unc, note = 0.8, "thin line at the blur limit; start/end from the neighbouring bars' edges"
    if key == "income_tax_loss" and rows[-1]["end"] is None:
        rows[-1]["end"] = round(v_top, 2)
        rows[-1]["delta"] = round(v_top - rows[-1]["start"], 2)
    rows.append(dict(step_id=key, step_label=label,
                     start=round(v_top, 2), end=None if v_bot is None else round(v_bot, 2),
                     delta=None if v_bot is None else (round(v_bot - v_top, 2) if key != "galle_estimate" else round(v_top, 2)),
                     uncertainty=round(unc, 2), note=note))

with open(out, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys()) + ["px_per_billion", "tick_fit_max_resid", "source"])
    w.writeheader()
    for r in rows:
        r.update(px_per_billion=round(px_per_b, 3), tick_fit_max_resid=round(fit_resid, 3),
                 source="Hoopes SSRN 6428578 Figure 2, PDF p.6; read off the chart, the note prints no values")
        w.writerow(r)
print(f"px per $B {px_per_b:.3f}; tick fit max residual ${fit_resid:.3f}B")
for r in rows:
    print(r["step_id"], r["start"], r["end"], r["delta"], "+/-", r["uncertainty"])
