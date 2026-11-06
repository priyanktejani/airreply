"""Draws the AirReply app icon, in the dark, dimensional style of the system's own icons (Photos, Files, Messages on a
white ground, as iOS and Android require an opaque one): one glossy deep blue chat bubble with a white reply arrow,
lifted by a soft shadow. Where a system takes clear icons (iOS's dark appearance, Windows, Linux) it is the bubble alone.

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

# The ground, where a platform needs one (iOS and Android icons are opaque): plain white, so the blue bubble is the mark.
GROUND = (0xFF, 0xFF, 0xFF)
# The dark icon's ground, for people who choose it (Settings → Appearance → App icon): a flat charcoal.
DARK_GROUND = (0x1E, 0x1F, 0x21)
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


def ground(img, s, colour=GROUND):
    """The ground, full bleed: plain white (or [colour]); the depth is the bubble's own."""
    img.alpha_composite(Image.new('RGBA', (s, s), (*colour, 255)))


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
#
# Each platform's own icon rules:
#   Android  adaptive icon: two 108dp layers; launchers show the middle 72dp through their mask, and anything outside
#            the central 66dp circle may be cut. The foreground and the themed (monochrome) layer are drawn on that
#            whole 108dp canvas (flutter_launcher_icons with adaptive_icon_foreground_inset: 0), the bubble 43dp wide.
#            The background is a colour. Notification icon: 24dp, white on clear, a vector (written below).
#   Play     512 x 512, square, opaque: the store rounds it.
#   iOS      1024 x 1024, opaque, square corners (the system rounds them); iOS 18 also takes a dark variant (the glyph on
#            clear) and a tinted one (grayscale, which the system tints).
#   macOS    1024 canvas: an 824-point rounded square, 100 points in from each side, corner radius 185, a soft shadow.
#   Web      192 and 512, used as "any" and "maskable": maskable icons are cut to the central 80%, so the glyph stays
#            well inside it.
#   Windows  .ico with 16 to 256 pixels in one file; Linux a shaped PNG. Both keep transparent corners.

# The bubble's width, as a share of each canvas.
BUBBLE = FRONT[2] - FRONT[0]  # at scale 1
ANDROID_LAYER = 43 / 108  # 43dp of the 108dp layer: well inside the 66dp safe zone, as the system's own glyphs
APPLE = 0.62  # iOS, the web and Play: Apple's and Google's grids put the main shape at about 60% of the square


def render(paint):
    s = SIZE * SS
    img = blank(s)
    paint(img, s)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def full_bleed(img, s):
    # iOS, Play, the web and Android before adaptive icons: opaque and square; the system rounds the corners
    ground(img, s)
    bubbles(img, s, scale=APPLE / BUBBLE)


def full_bleed_dark(img, s):
    # the dark icon, where it is chosen: iOS's alternate icon (opaque and square, as the light one)
    ground(img, s, DARK_GROUND)
    bubbles(img, s, scale=APPLE / BUBBLE)


def foreground(img, s):
    # Android adaptive icon foreground, on the whole 108dp layer
    bubbles(img, s, scale=ANDROID_LAYER / BUBBLE)


def monochrome(img, s):
    # Android 13 themed icons: the same shape in one colour, on the same grid
    layer = Image.new('RGBA', (s, s), (*WHITE, 0))
    layer.putalpha(silhouette(s, scale=ANDROID_LAYER / BUBBLE))
    img.alpha_composite(layer)


def ios_dark(img, s):
    # iOS 18 dark appearance: the glyph alone on clear; the system lays it on its own dark ground
    bubbles(img, s, scale=APPLE / BUBBLE)


def ios_tinted(img, s):
    # iOS 18 tinted appearance: grayscale, light where the tint shows; the arrow stays dark
    shape = bubble(s, FRONT, 0.15, 'left', scale=APPLE / BUBBLE)
    light = gradient(s, (255, 255, 255), (200, 200, 200))
    fill(img, ImageChops.subtract(shape, arrow(s, scale=APPLE / BUBBLE)), light)


def macos(img, s):
    # Apple's macOS template: an 824-point rounded square on the 1024 canvas, a shadow beneath
    inset, radius = 100 / 1024, 185 / 1024
    square = mask(s)
    ImageDraw.Draw(square).rounded_rectangle(
        (inset * s, inset * s, (1 - inset) * s, (1 - inset) * s), radius=radius * s, fill=255
    )
    shadow(img, square, s, dy=10 / 1024, blur=14 / 1024, alpha=0.45)
    art = blank(s)
    ground(art, s)
    bubbles(art, s, scale=APPLE * (824 / 1024) / BUBBLE)
    art.putalpha(ImageChops.multiply(art.getchannel('A'), square))
    img.alpha_composite(art)


def shaped(img, s):
    # Windows and Linux: icons are shapes on clear, without a plate (Windows 11's own are): the bubble alone, filling
    # the canvas less a little room for its shadow
    bubbles(img, s, scale=0.86 / BUBBLE)


def logo(img, s):
    # In the app (AppLogo): the bubble alone, on clear, so the app bar, splash and rail show it on their own ground;
    # the app icon itself puts it on white
    bubbles(img, s, scale=1.5)


def tight(img):
    """[img] cropped to what it draws, centred on a square canvas (the logo sits beside the wordmark)."""
    box = img.getchannel('A').point(lambda v: 255 if v > 8 else 0).getbbox()
    art = img.crop(box)
    side = max(art.size)
    square = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    square.alpha_composite(art, ((side - art.width) // 2, (side - art.height) // 2))
    return square


# Android's notification icon: Material's 24dp grid, 2dp padding, pure white on clear, a vector so it is sharp at every
# density. The bubble (a rounded body, its tail at the bottom left) with Material's reply arrow cut out of it.
NOTIFICATION_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- Status-bar and notification icon (drawn by tool/make_app_icon.py): the app's chat bubble with a reply arrow cut
     out of it. 24dp, white on clear, as Android requires; Android tints it with the notification colour. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:fillType="evenOdd"
        android:pathData="{path}" />
</vector>
"""


def notification_path():
    """The bubble's outline and the reply arrow's, in one path: with even-odd filling the arrow is a hole."""
    body = ('M6,3H18A4,4 0,0 1,22,7V13A4,4 0,0 1,18,17H10L4.9,20.6C4.2,21.1 3.4,20.6 3.6,19.8L4.3,16.8'
            'C2.9,16.2 2,14.8 2,13V7A4,4 0,0 1,6,3Z')
    # Material's reply arrow (M10,9V5l-7,7 7,7v-4.1c5,0 8.5,1.6 11,5.1 -1,-5 -4,-10 -11,-11z), scaled into the body
    points = [(10, 9), (10, 5), (3, 12), (10, 19), (10, 14.9)]
    curve1 = [(15, 14.9), (18.5, 16.5), (21, 20)]
    curve2 = [(20, 15), (17, 10), (10, 9)]
    k, cx, cy = 0.56, 12, 12.5  # scale, and the arrow's own centre
    tx, ty = 12.2, 10.2  # where that centre goes: the middle of the body

    def t(p):
        return f'{round((p[0] - cx) * k + tx, 3)},{round((p[1] - cy) * k + ty, 3)}'

    arrow = (f'M{t(points[0])}L{t(points[1])}L{t(points[2])}L{t(points[3])}L{t(points[4])}'
             f'C{t(curve1[0])} {t(curve1[1])} {t(curve1[2])}C{t(curve2[0])} {t(curve2[1])} {t(curve2[2])}Z')
    return body + arrow


# Android's dark launcher icon: the same adaptive layers on the charcoal ground (the launcher alias .LauncherDark).
ADAPTIVE_DARK_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- The dark app icon, chosen in Settings → Appearance → App icon (activity-alias .LauncherDark). Written by
     tool/make_app_icon.py: the light icon's layers on a charcoal ground. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background_dark"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
  <monochrome android:drawable="@drawable/ic_launcher_monochrome"/>
</adaptive-icon>
"""

DARK_COLOUR_XML = """<?xml version="1.0" encoding="utf-8"?>
<!-- Written by tool/make_app_icon.py: the dark app icon's ground (DARK_GROUND). -->
<resources>
    <color name="ic_launcher_background_dark">{colour}</color>
</resources>
"""

# iOS: the dark icon as an alternate app icon (one 1024 image; Xcode makes the sizes). Named in the Runner target's
# ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES, and chosen with setAlternateIconName("AppIconDark").
IOS_ALTERNATE_JSON = """{
  "images" : [
    {
      "filename" : "AppIconDark-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""


if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    full = render(full_bleed)
    full.convert('RGB').save(OUT / 'app_icon.png')
    full.convert('RGB').resize((512, 512), Image.LANCZOS).save(OUT / 'play_store_512.png')
    render(foreground).save(OUT / 'app_icon_foreground.png')
    render(monochrome).save(OUT / 'app_icon_monochrome.png')
    render(ios_dark).save(OUT / 'app_icon_ios_dark.png')
    render(ios_tinted).save(OUT / 'app_icon_ios_tinted.png')
    render(macos).save(OUT / 'app_icon_macos.png')
    shape = render(shaped)
    shape.save(OUT / 'app_icon_shaped.png')
    tight(render(logo)).resize((256, 256), Image.LANCZOS).save(OUT / 'app_logo.png')
    # Windows: every size it asks for, in one file (flutter_launcher_icons writes one size only)
    windows = ROOT / 'windows' / 'runner' / 'resources' / 'app_icon.ico'
    shape.save(windows, sizes=[(n, n) for n in (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)])
    # Android's notification icon, as a vector (the per-density PNGs it replaces are removed)
    res = ROOT / 'android' / 'app' / 'src' / 'main' / 'res'
    (res / 'drawable' / 'ic_stat_air_reply.xml').write_text(NOTIFICATION_XML.replace('{path}', notification_path()))
    for old in res.glob('drawable-*/ic_stat_air_reply.png'):
        old.unlink()
    # The dark icon, which people can choose in Settings (Android: a launcher alias; iOS: an alternate icon)
    dark = render(full_bleed_dark).convert('RGB')
    (res / 'mipmap-anydpi-v26' / 'ic_launcher_dark.xml').write_text(ADAPTIVE_DARK_XML)
    (res / 'values' / 'launcher_dark.xml').write_text(DARK_COLOUR_XML.replace('{colour}', '#%02X%02X%02X' % DARK_GROUND))
    alternate = ROOT / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIconDark.appiconset'
    alternate.mkdir(parents=True, exist_ok=True)
    dark.save(alternate / 'AppIconDark-1024.png')
    (alternate / 'Contents.json').write_text(IOS_ALTERNATE_JSON)
    # the two choices as Settings shows them: rounded, as a launcher would
    for name, art in (('light', full.convert('RGB')), ('dark', dark)):
        tile = art.convert('RGBA').resize((192, 192), Image.LANCZOS)
        corners = Image.new('L', (192, 192), 0)
        ImageDraw.Draw(corners).rounded_rectangle((0, 0, 191, 191), radius=43, fill=255)
        tile.putalpha(corners)
        tile.save(OUT / f'app_icon_choice_{name}.png')
    print('Wrote', *sorted(p.name for p in OUT.iterdir()))
