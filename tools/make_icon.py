#!/usr/bin/env python3
"""SuperSelf app icon — faithful clean redraw of the original concept:
blue gradient + white ring, with heart (health) + notepad (memo) + $ coin
(finance) inside. Rendered crisply via an index-mask at 4x supersample.
Opaque 1024x1024, no alpha."""

import math

from PIL import Image, ImageDraw, ImageFont

OUT = "SuperSelf/Assets.xcassets/AppIcon.appiconset/appicon.png"
F = 1024          # final size
S = 4             # supersample
W = F * S


def p(v):         # final-space value -> work-space
    return v * S


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


# ---- gradient background: light cyan top-right -> deep blue bottom-left
LIGHT = (96, 206, 247)
DARK = (28, 135, 222)
small = Image.new("RGB", (64, 64))
spx = small.load()
for y in range(64):
    for x in range(64):
        t = ((63 - x) + y) / (2 * 63)
        spx[x, y] = lerp(LIGHT, DARK, t)
grad = small.resize((W, W), Image.BICUBIC)
white = Image.new("RGB", (W, W), (255, 255, 255))

# ---- index mask: 255 = white, 0 = show gradient
idx = Image.new("L", (W, W), 0)
d = ImageDraw.Draw(idx)


def rrect(x0, y0, x1, y1, r, val):
    d.rounded_rectangle([p(x0), p(y0), p(x1), p(y1)], radius=p(r), fill=val)


def disc(cx, cy, rad, val):
    d.ellipse([p(cx - rad), p(cy - rad), p(cx + rad), p(cy + rad)], fill=val)


def heart(cx, cy, w, h, val):
    # smooth parametric heart curve (sampled densely, then filled)
    pts = []
    n = 720
    for i in range(n):
        t = math.pi * 2 * i / n
        hx = 16 * (math.sin(t) ** 3)
        hy = (13 * math.cos(t) - 5 * math.cos(2 * t)
              - 2 * math.cos(3 * t) - math.cos(4 * t))
        # normalize from the curve's native ~[-16,16] / [-17,12] range,
        # and recenter so the bounding box is centered on (cx, cy)
        px_ = cx + (hx / 16.0) * (w / 2.0)
        py_ = cy - (hy / 17.0) * (h / 2.0) + 0.147 * (h / 2.0)
        pts.append((p(px_), p(py_)))
    d.polygon(pts, fill=val)


WHITE, BG = 255, 0

# Layout is authored in the original coordinate space, then uniformly scaled
# up and recentered to fill the canvas now that the white ring is gone.
K = 1.34                 # scale factor
OCX, OCY = 528.0, 528.0  # original composition center
NCX, NCY = 512.0, 524.0  # target center on canvas


def sx(x):
    return NCX + (x - OCX) * K


def sy(y):
    return NCY + (y - OCY) * K


def sr(r):
    return r * K


def rr(x0, y0, x1, y1, r, val):
    rrect(sx(x0), sy(y0), sx(x1), sy(y1), sr(r), val)


def dc(cx, cy, rad, val):
    disc(sx(cx), sy(cy), sr(rad), val)


def ht(cx, cy, w, h, val):
    heart(sx(cx), sy(cy), w * K, h * K, val)


# notepad sheet + binding tabs
rr(440, 320, 712, 730, 30, WHITE)
rr(495, 288, 529, 360, 17, WHITE)
rr(619, 288, 653, 360, 17, WHITE)

# text lines (knockout)
rr(480, 398, 672, 428, 15, BG)
rr(480, 458, 628, 488, 15, BG)
rr(480, 518, 588, 548, 15, BG)

# heart with a gradient gap from the sheet
ht(372, 492, 250, 232, BG)
ht(372, 492, 222, 206, WHITE)

# dollar coin with gap ring, overlapping sheet bottom-right
dc(702, 632, 140, BG)
dc(702, 632, 116, WHITE)

# composite white vs gradient through the mask
icon = Image.composite(white, grad, idx)

# draw the "$" glyph as a knockout on top (gradient shows through)
def load_font(size):
    for path in (
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/Library/Fonts/Arial Bold.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()


font = load_font(int(p(150 * K)))
gly = ImageDraw.Draw(icon)
cx, cy = p(sx(702)), p(sy(632))
# center the glyph on the coin
bbox = gly.textbbox((0, 0), "$", font=font)
gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
gx = cx - gw / 2 - bbox[0]
gy = cy - gh / 2 - bbox[1]
# sample a representative gradient blue for the knockout
kn = grad.getpixel((int(cx), int(cy)))
gly.text((gx, gy), "$", font=font, fill=kn)

icon = icon.resize((F, F), Image.LANCZOS)
icon.save(OUT, "PNG")
print("wrote", OUT, icon.size, icon.mode)
