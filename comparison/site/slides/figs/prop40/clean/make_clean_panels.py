#!/usr/bin/env python3
"""Build the two campaign panels of the comparison deck's slide 2 (name: prop40).

Inputs, captured on 2026-10-18 with the highlight band already on the page:
  yes-page.png  yeson40.com/facts, the top of the page; yes-quote.png the "Keep hospitals" column
  no-page.png   votenoon40.org, the "Get the Facts" grid; no-quote.png the "$25 billion" card
Each panel: the page small with a thin rectangle round the quoted block (in the side's colour),
two fine lines from the rectangle to the enlarged block, framed in the same colour. The block sits
on the side the rectangle faces (right for Yes, left for No), so the lines cross as little of the
page as possible.
Run from this folder:  python3 make_clean_panels.py
"""
from PIL import Image, ImageDraw, ImageFilter

H = 560          # height of the enlarged block, in pixels
GAP = 90         # space between the page and the block, crossed by the two lines


def panel(page, box, quote, colour, out, zoom_left=False):
    pg, q = Image.open(page).convert("RGB"), Image.open(quote).convert("RGB")
    zw = round(q.width * H / q.height)
    zoom = q.resize((zw, H), Image.LANCZOS)
    s = min(H / pg.height, 1.0)
    tw, th = round(pg.width * s), round(pg.height * s)
    thumb = pg.resize((tw, th), Image.LANCZOS)
    pad = 24                                      # room for the shadow
    W, HH = tw + GAP + zw + 2 * pad, H + 2 * pad
    can = Image.new("RGBA", (W, HH), (255, 255, 255, 0))
    ty = pad + (H - th) // 2
    px = pad + zw + GAP if zoom_left else pad          # where the page sits
    zx = pad if zoom_left else pad + tw + GAP           # where the enlarged block sits
    # soft shadow under the enlarged block
    sh = Image.new("RGBA", (W, HH), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rectangle([zx + 4, pad + 8, zx + zw + 4, pad + H + 8], fill=(0, 0, 0, 60))
    can = Image.alpha_composite(can, sh.filter(ImageFilter.GaussianBlur(10)))
    can.paste(thumb, (px, ty))
    can.paste(zoom, (zx, pad))
    lines = Image.new("RGBA", (W, HH), (0, 0, 0, 0))
    x0, y0, x1, y1 = (px + box[0] * s, ty + box[1] * s, px + box[2] * s, ty + box[3] * s)
    faint = colour[:3] + (150,)
    dl = ImageDraw.Draw(lines)
    if zoom_left:   # the rectangle's left corners to the block's right edge, clear of the page
        dl.line([(x0, y0), (zx + zw - 1, pad)], fill=faint, width=3)
        dl.line([(x0, y1), (zx + zw - 1, pad + H - 1)], fill=faint, width=3)
    else:
        dl.line([(x1, y0), (zx, pad)], fill=faint, width=3)
        dl.line([(x1, y1), (zx, pad + H - 1)], fill=faint, width=3)
    can = Image.alpha_composite(can, lines)
    d = ImageDraw.Draw(can)
    d.rectangle([px, ty, px + tw - 1, ty + th - 1], outline=(200, 200, 200, 255), width=2)
    d.rectangle([x0, y0, x1, y1], outline=colour, width=5)
    d.rectangle([zx, pad, zx + zw - 1, pad + H - 1], outline=colour, width=5)
    can.save(out)


panel("yes-page.png", (414, 625, 792, 938), "yes-quote.png", (106, 47, 134, 255), "yes-panel.png")
panel("no-page.png", (90, 156, 403, 545), "no-quote.png", (31, 107, 59, 255), "no-panel.png", zoom_left=True)
