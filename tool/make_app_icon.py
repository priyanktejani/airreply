"""Draws the AirReply app icon: the in-app logo's mark (lib/core/widgets/app_logo.dart), a deep-green reply arrow on a
glowing brand-green circle, on the app's deep navy (lib/core/theme/app_palette.dart).

Writes the masters that flutter_launcher_icons turns into every platform's icon set, and the Windows .ico (with every
size Windows asks for, which flutter_launcher_icons does not write):
  python3 tool/make_app_icon.py && dart run flutter_launcher_icons
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

NAVY = (0x0F, 0x17, 0x2A, 255)  # the icon's ground
GREEN = (0x3D, 0xDC, 0x97, 255)  # the bubble: AppPalette.dark.accent
DEEP = (0x04, 0x26, 0x1A, 255)  # the arrow: AppPalette.dark.accentInk
SIZE = 1024
SS = 4  # supersampling, for smooth edges
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'icon'


def glyph(draw, s, scale=1.0, bubble=GREEN, arrow=DEEP, cx=0.5, cy=0.5):
    """The mark: a circle with a reply arrow cut into it, in unit coordinates around (cx, cy), scaled by [scale]."""

    def p(x, y):
        return ((cx + (x - 0.5) * scale) * s, (cy + (y - 0.5) * scale) * s)

    def d(v):
        return v * scale * s

    r = RADIUS
    x, y = p(0.5, 0.5)
    draw.ellipse((x - d(r), y - d(r), x + d(r), y + d(r)), fill=bubble)

    # Reply arrow (as Icons.reply_rounded): head pointing left, shaft running right then curving down.
    w = 0.052
    yl = 0.455
    ar = 0.095
    acx = 0.555
    draw.line([p(0.42, yl), p(acx, yl)], fill=arrow, width=round(d(w)))
    bx0, by0 = p(acx - ar - w / 2, yl + ar - ar - w / 2)
    bx1, by1 = p(acx + ar + w / 2, yl + ar + ar + w / 2)
    draw.arc((bx0, by0, bx1, by1), start=270, end=360, fill=arrow, width=round(d(w)))
    ex, ey = p(acx + ar, yl + ar)
    draw.ellipse((ex - d(w / 2), ey - d(w / 2), ex + d(w / 2), ey + d(w / 2)), fill=arrow)
    draw.polygon([p(0.335, yl), p(0.445, yl - 0.08), p(0.445, yl + 0.08)], fill=arrow)


RADIUS = 0.30


def glow(img, s, scale, cy=0.5):
    """The logo's soft green glow around the circle, under it."""
    layer = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    r = RADIUS * 1.08 * scale * s
    x, y = 0.5 * s, cy * s
    ImageDraw.Draw(layer).ellipse((x - r, y - r, x + r, y + r), fill=(*GREEN[:3], 120))
    img.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.06 * s)))


def render(paint, transparent=False):
    s = SIZE * SS
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0) if transparent else NAVY)
    paint(img, ImageDraw.Draw(img), s)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def full_bleed(img, draw, s):
    glow(img, s, 0.92)
    glyph(draw, s, scale=0.92)


def foreground(img, draw, s):
    # Android adaptive icons: flutter_launcher_icons insets this layer by 16% a side, which keeps the mark inside
    # the masked safe zone at the same size as the full-bleed icon.
    glyph(draw, s, scale=0.92)


def monochrome(img, draw, s):
    # Android 13 themed icons: a single-colour silhouette, the arrow cut out of the circle.
    glyph(draw, s, scale=0.92, bubble=(255, 255, 255, 255), arrow=(0, 0, 0, 0))


def macos(img, draw, s):
    # macOS icons sit on a rounded square inset in the canvas, with a soft shadow below.
    inset, radius = 0.1, 0.225 * 0.8
    shadow = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (inset * s, (inset + 0.012) * s, (1 - inset) * s, (1 - inset + 0.012) * s),
        radius=radius * s,
        fill=(0, 0, 0, 90),
    )
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(0.012 * s)))
    draw.rounded_rectangle((inset * s, inset * s, (1 - inset) * s, (1 - inset) * s), radius=radius * s, fill=NAVY)
    glow(img, s, 0.92 * 0.8)
    glyph(draw, s, scale=0.92 * 0.8)


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    render(full_bleed).convert('RGB').save(OUT / 'app_icon.png')
    render(foreground, transparent=True).save(OUT / 'app_icon_foreground.png')
    render(monochrome, transparent=True).save(OUT / 'app_icon_monochrome.png')
    render(macos, transparent=True).save(OUT / 'app_icon_macos.png')
    windows = Path(__file__).resolve().parent.parent / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    render(full_bleed).save(windows, sizes=[(n, n) for n in (16, 20, 24, 32, 40, 48, 64, 128, 256)])
    print('Wrote', *sorted(p.name for p in OUT.iterdir()))
