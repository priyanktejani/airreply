"""Draws the AirReply app icon, in the dark, dimensional style of the system's own icons (Photos, Files, Messages on a
flat charcoal ground): one glossy deep blue chat bubble with a white reply arrow, lifted by a soft shadow.

Writes the masters that flutter_launcher_icons turns into every platform's icon set, the Windows .ico (with every
size Windows asks for, which flutter_launcher_icons does not write) and the in-app logo:
  python3 tool/make_app_icon.py && dart run flutter_launcher_icons

Only Pillow is needed.
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

SIZE = 1024
SS = 2  # supersampling, for smooth edges
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'icon'

# The ground: one flat, neutral charcoal, as on the system's own dark icons (Play Store, Files, Photos).
INK = (0x1E, 0x1F, 0x21)
# The bubbles: the app's Ocean accent family, vivid on the dark.
BLUE_TOP = (0x4D, 0x9A, 0xFF)
BLUE_BOTTOM = (0x14, 0x47, 0xD9)
WHITE = (255, 255, 255)


# --- helpers -------------------------------------------------------------------------------------------------------


def blank(s, colour=(0, 0, 0, 0)):
    return Image.new('RGBA', (s, s), colour)


def mask(s):
    return Image.new('L', (s, s), 0)


def gradient(s, top, bottom, angle=0):
    """A linear gradient from [top] to [bottom], turned by [angle] degrees (0: top to bottom)."""
    g = Image.linear_gradient('L').resize((s, s), Image.BICUBIC)
    if angle:
        g = g.rotate(angle, resample=Image.BICUBIC, expand=False, fillcolor=None)
        # rotating leaves the corners empty: grow a little and crop back to the canvas
        big = Image.linear_gradient('L').resize((int(s * 1.5), int(s * 1.5)), Image.BICUBIC)
        big = big.rotate(angle, resample=Image.BICUBIC)
        o = int(s * 0.25)
        g = big.crop((o, o, o + s, o + s))
    return Image.composite(Image.new('RGBA', (s, s), (*bottom, 255)), Image.new('RGBA', (s, s), (*top, 255)), g)


def bubble(s, box, radius, tail, scale=1.0, cx=0.5, cy=0.5):
    """A chat bubble's shape: a rounded rectangle ([box] in unit coordinates) with a curved tail.

    [tail] is 'left' or 'right': the corner it leaves from, at the bottom.
    """
    m = mask(s)
    d = ImageDraw.Draw(m)

    def p(x, y):
        return ((cx + (x - 0.5) * scale) * s, (cy + (y - 0.5) * scale) * s)

    x0, y0, x1, y1 = box
    a, b = p(x0, y0), p(x1, y1)
    r = radius * scale * s
    d.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=r, fill=255)
    # the tail: a soft hook below the bottom corner
    w = x1 - x0
    h = y1 - y0
    if tail == 'left':
        pts = [p(x0 + w * 0.14, y1 - h * 0.30), p(x0 + w * 0.40, y1 - h * 0.05), p(x0 - w * 0.02, y1 + h * 0.20)]
    else:
        pts = [p(x1 - w * 0.14, y1 - h * 0.30), p(x1 - w * 0.40, y1 - h * 0.05), p(x1 + w * 0.02, y1 + h * 0.20)]
    d.polygon(pts, fill=255)
    # round the tail's tip by blurring and re-thresholding the shape a little
    m = m.filter(ImageFilter.GaussianBlur(s * 0.006)).point(lambda v: 255 if v > 127 else 0)
    return m


def arrow(s, scale=1.0, cx=0.5, cy=0.5, at=(0.50, 0.465), size=0.36):
    """The reply arrow: a head pointing left and a shaft that curves down, with round ends, as a mask."""
    m = mask(s)
    d = ImageDraw.Draw(m)
    ux, uy = at

    def p(x, y):
        # (x, y) in the arrow's own unit box, centred on [at]
        gx = ux + (x - 0.5) * size
        gy = uy + (y - 0.5) * size
        return ((cx + (gx - 0.5) * scale) * s, (cy + (gy - 0.5) * scale) * s)

    def k(v):
        return v * size * scale * s

    w = 0.21  # stroke
    yl = 0.40  # the shaft's height
    ar = 0.30  # the bend's radius
    acx = 0.52  # where the shaft starts to bend
    head = 0.26
    # shaft
    d.line([p(0.22, yl), p(acx, yl)], fill=255, width=round(k(w)))
    # bend: a quarter circle down to the right
    bx0, by0 = p(acx - ar - w / 2, yl - w / 2)
    bx1, by1 = p(acx + ar + w / 2, yl + 2 * ar + w / 2)
    d.arc((bx0, by0, bx1, by1), start=270, end=360, fill=255, width=round(k(w)))
    # round end at the bottom
    ex, ey = p(acx + ar, yl + ar)
    d.ellipse((ex - k(w / 2), ey - k(w / 2), ex + k(w / 2), ey + k(w / 2)), fill=255)
    # head
    d.polygon([p(0.02, yl), p(0.02 + head * 1.25, yl - head), p(0.02 + head * 1.25, yl + head)], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(s * 0.004)).point(lambda v: 255 if v > 110 else 0)
    return m


def shadow(img, shape, s, dy=0.022, blur=0.03, alpha=0.38):
    """A soft shadow under [shape], cast down a little."""
    sh = Image.new('RGBA', (s, s), (6, 20, 70, 0))
    layer = shape.point(lambda v: int(v * alpha))
    layer = ImageChops.offset(layer, 0, int(dy * s)).filter(ImageFilter.GaussianBlur(blur * s))
    sh.putalpha(layer)
    img.alpha_composite(sh)


def fill(img, shape, paint):
    """Paints [paint] (an RGBA image) through [shape]."""
    layer = paint.copy()
    layer.putalpha(ImageChops.multiply(paint.getchannel('A'), shape))
    img.alpha_composite(layer)


# --- the parts -----------------------------------------------------------------------------------------------------

ADAPTIVE = 0.96  # the bubble's scale on Android's adaptive layers

# The bubble, centred (its tail hangs below the bottom left corner).
FRONT = (0.20, 0.25, 0.80, 0.69)


def ground(img, s):
    """The dark ground, full bleed: flat charcoal; the depth is the bubbles' own."""
    img.alpha_composite(Image.new('RGBA', (s, s), (*INK, 255)))


def gloss(img, shape, s, strength=0.45):
    """Light on a glossy shape's top half, fading down."""
    fade = gradient(s, (255, 255, 255), (0, 0, 0)).getchannel('R').point(lambda v: int(max(0, v - 110) * strength * 1.75))
    top = ImageChops.multiply(shape, fade)
    fill(img, top, Image.new('RGBA', (s, s), (*WHITE, 255)))


def bubbles(img, s, scale=1.0, cy=0.5):
    """The bubble and its arrow, with their shadows."""
    front = bubble(s, FRONT, 0.15, 'left', scale=scale, cy=cy)

    # the deep blue bubble
    shadow(img, front, s, dy=0.02 * scale, blur=0.028 * scale, alpha=0.45)
    fill(img, front, gradient(s, BLUE_TOP, BLUE_BOTTOM))
    gloss(img, front, s, strength=0.30)
    # a fine bright rim on its top edge
    rim = ImageChops.subtract(front, ImageChops.offset(front, 0, int(0.006 * s)))
    fill(img, rim, Image.new('RGBA', (s, s), (*WHITE, 110)))

    # the reply arrow, white, with a whisper of shadow
    a = arrow(s, scale=scale, cy=cy)
    shadow(img, a, s, dy=0.008 * scale, blur=0.01 * scale, alpha=0.35)
    fill(img, a, gradient(s, WHITE, (0xE4, 0xEE, 0xFF)))


def silhouette(s, scale=1.0):
    """One colour (Android themed icons, the status bar): the bubble, the arrow cut out of it."""
    return ImageChops.subtract(bubble(s, FRONT, 0.15, 'left', scale=scale), arrow(s, scale=scale))


def _odd(v):
    n = int(v)
    return n if n % 2 else n + 1


# --- the outputs ---------------------------------------------------------------------------------------------------


def render(paint):
    s = SIZE * SS
    img = blank(s)
    paint(img, s)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def full_bleed(img, s):
    # iOS, the web, Windows, Linux and Android before adaptive icons: the system rounds the corners
    ground(img, s)
    bubbles(img, s, scale=1.1)


def foreground(img, s):
    # Android adaptive icons: flutter_launcher_icons insets this layer by 16% a side, and launchers show only its
    # middle two thirds (72 of 108dp) through their mask: at this scale the bubbles fill about 70% of a circular icon,
    # as the system's own do, and stay inside the 66dp safe zone
    bubbles(img, s, scale=ADAPTIVE)


def monochrome(img, s):
    # Android 13 themed icons: a single-colour silhouette
    shape = silhouette(s, scale=ADAPTIVE)
    layer = Image.new('RGBA', (s, s), (*WHITE, 0))
    layer.putalpha(shape)
    img.alpha_composite(layer)


def macos(img, s):
    # macOS icons sit on a rounded square inset in the canvas, with a soft shadow below
    inset, radius = 0.1, 0.225 * 0.8
    square = mask(s)
    ImageDraw.Draw(square).rounded_rectangle((inset * s, inset * s, (1 - inset) * s, (1 - inset) * s), radius=radius * s, fill=255)
    shadow(img, square, s, dy=0.012, blur=0.014, alpha=0.40)
    art = blank(s)
    ground(art, s)
    bubbles(art, s, scale=1.1 * 0.8)
    art.putalpha(ImageChops.multiply(art.getchannel('A'), square))
    img.alpha_composite(art)


def logo(img, s):
    # In the app (AppLogo): the bubble alone, on clear, so the app bar, splash and rail show it on their own ground;
    # only the app icon carries the charcoal plate
    bubbles(img, s, scale=1.5)


def tight(img):
    """[img] cropped to what it draws, centred on a square canvas (the logo sits beside the wordmark)."""
    box = img.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    art = img.crop(box)
    side = max(art.size)
    square = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    square.alpha_composite(art, ((side - art.width) // 2, (side - art.height) // 2))
    return square


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    full = render(full_bleed)
    full.convert('RGB').save(OUT / 'app_icon.png')
    render(foreground).save(OUT / 'app_icon_foreground.png')
    render(monochrome).save(OUT / 'app_icon_monochrome.png')
    render(macos).save(OUT / 'app_icon_macos.png')
    tight(render(logo)).resize((256, 256), Image.LANCZOS).save(OUT / 'app_logo.png')
    # Android's status-bar icon: the silhouette, white on clear, at each density (24dp)
    status = Image.new('RGBA', (SIZE * SS, SIZE * SS), (*WHITE, 0))
    status.putalpha(silhouette(SIZE * SS, scale=1.5))
    res = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    for folder, px in (('mdpi', 24), ('hdpi', 36), ('xhdpi', 48), ('xxhdpi', 72), ('xxxhdpi', 96)):
        status.resize((px, px), Image.LANCZOS).save(res / f'drawable-{folder}' / 'ic_stat_air_reply.png')
    windows = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    full.save(windows, sizes=[(n, n) for n in (16, 20, 24, 32, 40, 48, 64, 128, 256)])
    print('Wrote', *sorted(p.name for p in OUT.iterdir()))
