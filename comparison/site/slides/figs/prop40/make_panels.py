#!/usr/bin/env python3
"""Build the two campaign panels of the deck's slide 2 (name: prop40) from the author's screenshots.

Each panel holds the campaign page small (top right), the area the author circled in red zoomed
in (bottom, full width), and a red line from the circle to the zoom. The slide sets each
argument's text in the empty top left of its panel. Screenshots taken by the author on
2026-10-16: yes-site.png (yeson40, "Facts on Prop 40"), no-site.png (noon40, updated
8 October 2026). Run from this folder:  python3 make_panels.py
"""
from PIL import Image, ImageDraw

W = 1000          # panel width in pixels
RED = (220, 38, 38, 255)


def panel(site, thumb_box, circle, crop, out):
    """site: screenshot file; thumb_box: (width, height) of the small page; circle: (x, y, ry), the
    centre of the author's circle on the screenshot and its half height; crop: (left, top, right,
    bottom) of the zoom."""
    im = Image.open(site).convert("RGBA")
    s = min(thumb_box[0] / im.width, thumb_box[1] / im.height)
    thumb = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    z = im.crop(crop)
    zoom = z.resize((W, round(z.height * W / z.width)), Image.LANCZOS)
    gap = 60
    H = thumb.height + gap + zoom.height
    can = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    tx = W - thumb.width
    can.paste(thumb, (tx, 0))
    can.paste(zoom, (0, thumb.height + gap))
    d = ImageDraw.Draw(can)
    d.rectangle([tx, 0, W - 1, thumb.height - 1], outline=(150, 150, 150, 255), width=2)
    d.rectangle([0, thumb.height + gap, W - 1, H - 1], outline=RED, width=6)
    # a line from the bottom of the author's circle on the small page to the zoom's top edge,
    # above the same spot of the circled text
    cx, cy = tx + circle[0] * s, (circle[1] + circle[2]) * s
    zx = (circle[0] - crop[0]) * W / (crop[2] - crop[0])
    d.line([(cx, cy), (min(max(zx, 40), W - 40), thumb.height + gap)], fill=RED, width=6)
    can.save(out)


panel("yes-site.png", (300, 300), (1480, 1515, 50), (880, 1495, 1612, 1612), "yes-panel.png")
panel("no-site.png", (420, 230), (1390, 310, 80), (750, 225, 1760, 418), "no-panel.png")
