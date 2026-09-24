"""Generate the Yun's Lantern vector asset set (SVG).

Everything is drawn from the game's own sources:
  - lib/core/tokens.dart          (Palette + named colours)
  - lib/core/ui/yun.dart          (_YunPainter geometry, ported 1:1)
  - assets/images/placeholder_art.json (scene sky/ground colours)
  - content/story.json            (8 lights, chapters)
No <style>, no animation, no embedded images: safe to upload as assets.
"""
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")
os.makedirs(OUT, exist_ok=True)

# --- tokens.dart -----------------------------------------------------------
PAPER, PAPER_DEEP, CARD = "#FBF1E1", "#F4E0C2", "#FFF8EC"
INK, INK_SOFT = "#4A3426", "#8A6D58"
RUST, RUST_DEEP, CREAM = "#C8643B", "#9E4726", "#FFE9C9"
LANTERN, LEAF, WATER, WATER_DEEP = "#E8A93C", "#8DB86B", "#7FB7D1", "#4F8FB0"
NIGHT, MIST = "#3A3D6B", "#D9D4CC"
NAMED = {
    "red": "#D9534A", "orange": "#EE9A3E", "yellow": "#F2CC4A", "green": "#79B45A",
    "blue": "#5B9BD5", "purple": "#9B76C4", "pink": "#EFA0B8", "brown": "#9C6B45",
    "white": "#F7F1E6", "black": "#3B3533",
}
SILHOUETTE = "#3E3150"  # item_art.dart
STICK = "#6B4A2B"

# --- yun.dart painter colours ----------------------------------------------
FUR, FUR_DARK, YCREAM, EYE = "#C65F32", "#7A3419", "#FFEBD1", "#3A2418"
BELLY, TEAR, EYE_HI = "#8C3E1E", "#9A4524", "#FFF6E8"


def n(v):
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


def hex_rgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def mix(a, b, t):
    """t=0 -> a, t=1 -> b"""
    ra, rb = hex_rgb(a), hex_rgb(b)
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(ra, rb))


def darken(c, t=0.22):
    return mix(c, "#2A1A10", t)


def svg(w, h, body, vb=None):
    vb = vb or f"0 0 {n(w)} {n(h)}"
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" '
            f'width="{n(w)}" height="{n(h)}">{body}</svg>\n')


def save(name, content):
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as fh:
        fh.write(content)


def circle(cx, cy, r, fill, extra=""):
    return f'<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(r)}" fill="{fill}"{extra}/>'


def ellipse(cx, cy, rx, ry, fill, extra=""):
    return f'<ellipse cx="{n(cx)}" cy="{n(cy)}" rx="{n(rx)}" ry="{n(ry)}" fill="{fill}"{extra}/>'


def rect(x, y, w, h, fill, rx=0, extra=""):
    return f'<rect x="{n(x)}" y="{n(y)}" width="{n(w)}" height="{n(h)}" rx="{n(rx)}" fill="{fill}"{extra}/>'


def sparkle(x, y, r, fill, extra=""):
    k = r * 0.18
    return (f'<path d="M{n(x)} {n(y - r)} Q{n(x + k)} {n(y - k)} {n(x + r)} {n(y)} '
            f'Q{n(x + k)} {n(y + k)} {n(x)} {n(y + r)} Q{n(x - k)} {n(y + k)} {n(x - r)} {n(y)} '
            f'Q{n(x - k)} {n(y - k)} {n(x)} {n(y - r)} Z" fill="{fill}"{extra}/>')


# ===========================================================================
# Yun — a 1:1 port of _YunPainter (lib/core/ui/yun.dart)
# ===========================================================================
def yun_g(mood="idle", lantern=LANTERN, w=200.0, ox=0.0, oy=0.0, sway=None):
    if sway is None:
        sway = {"idle": 0.06, "happy": -0.06, "sleepy": 0.0}[mood]
    s = lambda v: v * w  # noqa: E731
    o = [f'<g transform="translate({n(ox)} {n(oy)})">']
    # tail, striped
    o.append(f'<path d="M{n(s(.62))} {n(s(.92))} Q{n(s(1.02))} {n(s(.95))} {n(s(.92))} {n(s(.62))} '
             f'Q{n(s(.88))} {n(s(.82))} {n(s(.60))} {n(s(.82))} Z" fill="{FUR}"/>')
    o.append(circle(s(.90), s(.75), s(.04), FUR_DARK))
    o.append(circle(s(.80), s(.88), s(.04), FUR_DARK))
    # body + belly + feet
    o.append(ellipse(s(.5), s(.86), s(.28), s(.21), FUR))
    o.append(ellipse(s(.5), s(.90), s(.15), s(.13), BELLY))
    o.append(ellipse(s(.38), s(1.05), s(.08), s(.045), FUR_DARK))
    o.append(ellipse(s(.62), s(1.05), s(.08), s(.045), FUR_DARK))
    # lantern on a stick
    o.append(f'<g transform="translate({n(s(.20))} {n(s(.62))}) rotate({n(math.degrees(sway))})">')
    o.append(f'<line x1="0" y1="0" x2="{n(s(-.10))}" y2="{n(s(-.22))}" stroke="{STICK}" '
             f'stroke-width="{n(s(.025))}" stroke-linecap="round"/>')
    o.append(f'<line x1="{n(s(-.10))}" y1="{n(s(-.22))}" x2="{n(s(-.10))}" y2="{n(s(-.12))}" '
             f'stroke="{STICK}" stroke-width="{n(s(.01))}" stroke-linecap="round"/>')
    o.append(ellipse(s(-.10), s(-.02), s(.135), s(.15), lantern, ' fill-opacity="0.25"'))
    o.append(rect(s(-.185), s(-.12), s(.17), s(.2), lantern, s(.07)))
    o.append(f'<line x1="{n(s(-.10))}" y1="{n(s(-.12))}" x2="{n(s(-.10))}" y2="{n(s(.08))}" '
             f'stroke="#000000" stroke-opacity="0.33" stroke-width="{n(s(.008))}"/>')
    o.append(rect(s(-.15), s(-.1325), s(.1), s(.025), STICK))
    o.append(rect(s(-.15), s(.0675), s(.1), s(.025), STICK))
    o.append("</g>")
    o.append(circle(s(.22), s(.64), s(.06), FUR_DARK))  # paw on the stick
    # ears
    for dx in (-1, 1):
        o.append(f'<path d="M{n(s(.5 + dx * .34))} {n(s(.14))} Q{n(s(.5 + dx * .38))} {n(s(.02))} '
                 f'{n(s(.5 + dx * .20))} {n(s(.12))} Q{n(s(.5 + dx * .25))} {n(s(.30))} '
                 f'{n(s(.5 + dx * .34))} {n(s(.14))} Z" fill="{FUR}"/>')
        o.append(circle(s(.5 + dx * .30), s(.13), s(.05), YCREAM))
    # head + cream markings + tear marks
    o.append(ellipse(s(.5), s(.40), s(.39), s(.30), FUR))
    for cx, cy, rx, ry in [(.5, .52, .18, .13), (.32, .30, .07, .04), (.68, .30, .07, .04),
                           (.22, .50, .08, .08), (.78, .50, .08, .08)]:
        o.append(ellipse(s(cx), s(cy), s(rx), s(ry), YCREAM))
    o.append(ellipse(s(.36), s(.50), s(.035), s(.07), TEAR))
    o.append(ellipse(s(.64), s(.50), s(.035), s(.07), TEAR))
    # eyes
    ey = .40
    if mood == "sleepy":
        a = .2
        for x in (.36, .64):
            x1, y1 = x + .045 * math.cos(a), ey + .03 * math.sin(a)
            x2 = x - .045 * math.cos(a)
            o.append(f'<path d="M{n(s(x1))} {n(s(y1))} A{n(s(.045))} {n(s(.03))} 0 0 1 {n(s(x2))} {n(s(y1))}" '
                     f'fill="none" stroke="{EYE}" stroke-width="{n(s(.022))}" stroke-linecap="round"/>')
    else:
        for x in (.36, .64):
            o.append(ellipse(s(x), s(ey), s(.0425), s(.04 if mood == "happy" else .05), EYE))
            o.append(circle(s(x + .015), s(ey - .02), s(.015), EYE_HI))
    # cheeks, nose, mouth
    o.append(circle(s(.27), s(.55), s(.04), "#F28A8A", ' fill-opacity="0.33"'))
    o.append(circle(s(.73), s(.55), s(.04), "#F28A8A", ' fill-opacity="0.33"'))
    o.append(ellipse(s(.5), s(.49), s(.04), s(.0275), EYE))
    mh = .04 if mood == "happy" else .025
    for cx in (.46, .54):
        o.append(f'<path d="M{n(s(cx + .04))} {n(s(.535))} A{n(s(.04))} {n(s(mh))} 0 0 1 {n(s(cx - .04))} {n(s(.535))}" '
                 f'fill="none" stroke="{EYE}" stroke-width="{n(s(.015))}" stroke-linecap="round"/>')
    if mood == "sleepy":  # the painter's "z z", drawn as strokes so it needs no font
        for zx, zy, zs in ((.80, .04, .06), (.89, .0, .045)):
            o.append(f'<path d="M{n(s(zx))} {n(s(zy))} H{n(s(zx + zs))} L{n(s(zx))} {n(s(zy + zs))} H{n(s(zx + zs))}" '
                     f'fill="none" stroke="{INK_SOFT}" stroke-width="{n(s(.02))}" stroke-linecap="round" stroke-linejoin="round"/>')
    o.append("</g>")
    return "".join(o)


def yun_svg(mood, lantern=LANTERN, w=200):
    # padded so the lantern glow (x<0) and feet (y>1.05w) are not clipped
    vb = f"{n(-.07 * w)} {n(-.03 * w)} {n(1.11 * w)} {n(1.14 * w)}"
    return svg(1.11 * w, 1.14 * w, yun_g(mood, lantern, w), vb)


# ===========================================================================
# Lanterns (story lights): lit / unlit / misty
# ===========================================================================
def lantern_g(color, state="lit", x=0.0, y=0.0, sc=1.0):
    """Drawn in a 120x160 box; `state` = lit | unlit | misty."""
    o = [f'<g transform="translate({n(x)} {n(y)}) scale({n(sc)})">']
    if state == "misty":
        body, cap, tassel = MIST, "#B9B0A6", "#C9C2B8"
    elif state == "unlit":
        body, cap, tassel = mix(color, "#B8AA98", .62), "#8C7A66", mix(color, "#A89A88", .7)
    else:
        body, cap, tassel = color, STICK, darken(color, .18)
    if state == "lit":
        glow = "#FFE9A8" if color.upper() == NAMED["white"].upper() else color
        o.append(circle(60, 84, 62, glow, ' fill-opacity="0.16"'))
        o.append(circle(60, 84, 46, glow, ' fill-opacity="0.26"'))
    o.append(f'<line x1="60" y1="6" x2="60" y2="30" stroke="{cap}" stroke-width="4" stroke-linecap="round"/>')
    o.append(rect(38, 26, 44, 14, cap, 5))
    light_body = color.upper() in (NAMED["white"].upper(), NAMED["yellow"].upper())
    stroke = f' stroke="{INK}" stroke-opacity="0.28" stroke-width="2.5"' if (light_body and state == "lit") else ""
    o.append(rect(20, 36, 80, 94, body, 36, stroke))
    o.append('<path d="M60 38 V128 M40 40 Q24 83 40 126 M80 40 Q96 83 80 126" fill="none" '
             'stroke="#000000" stroke-opacity="0.16" stroke-width="2.5"/>')
    if state == "lit":
        o.append(ellipse(42, 64, 7, 15, CARD, ' fill-opacity="0.45"'))
    o.append(rect(38, 124, 44, 12, cap, 5))
    o.append(rect(54, 136, 12, 20, tassel, 5))
    if state == "misty":
        o.append(rect(2, 66, 116, 24, "#F3F0EB", 12, ' fill-opacity="0.9"'))
        o.append(rect(12, 102, 96, 20, "#F3F0EB", 10, ' fill-opacity="0.75"'))
        o.append(rect(28, 44, 70, 14, "#F3F0EB", 7, ' fill-opacity="0.6"'))
    o.append("</g>")
    return "".join(o)


# ===========================================================================
# Items used by the Count & Feed mock (vocab ids: apple, bear, basket)
# ===========================================================================
def apple_g(x=0, y=0, sc=1.0):
    return (f'<g transform="translate({n(x)} {n(y)}) scale({n(sc)})">'
            f'<path d="M50 30 C30 16 6 28 10 55 C14 82 34 96 50 89 C66 96 86 82 90 55 C94 28 70 16 50 30 Z" fill="{NAMED["red"]}"/>'
            f'<path d="M50 30 C44 26 38 25 33 26" fill="none" stroke="{darken(NAMED["red"], .25)}" stroke-width="3" stroke-linecap="round" stroke-opacity="0.5"/>'
            + ellipse(31, 50, 7, 12, CARD, ' fill-opacity="0.45"') +
            f'<path d="M50 30 Q50 18 56 9" fill="none" stroke="{STICK}" stroke-width="5" stroke-linecap="round"/>'
            f'<path d="M55 20 Q70 6 83 14 Q70 28 55 20 Z" fill="{NAMED["green"]}"/>'
            '</g>')


def basket_g(x=0, y=0, sc=1.0, handle=True):
    body, rim, weave = "#C9965A", "#B07A40", "#A26E38"
    o = [f'<g transform="translate({n(x)} {n(y)}) scale({n(sc)})">']
    if handle:
        o.append(f'<path d="M22 44 Q70 -18 118 44" fill="none" stroke="{rim}" stroke-width="10" stroke-linecap="round"/>')
    o.append(f'<path d="M8 44 H132 L124 96 Q121 110 106 110 H34 Q19 110 16 96 Z" fill="{body}"/>')
    o.append(f'<path d="M16 64 H124 M19 84 H121" stroke="{weave}" stroke-width="4" stroke-linecap="round"/>')
    o.append(f'<path d="M44 48 L48 106 M70 48 V108 M96 48 L92 106" stroke="{weave}" stroke-width="4" stroke-linecap="round" stroke-opacity="0.7"/>')
    o.append(rect(2, 36, 136, 18, rim, 9))
    o.append("</g>")
    return "".join(o)


def bear_g(x=0, y=0, sc=1.0):
    fur, dark, muzzle, inner = NAMED["brown"], "#6E4A2F", "#F3D9B5", "#D9A77A"
    o = [f'<g transform="translate({n(x)} {n(y)}) scale({n(sc)})">']
    o.append(ellipse(120, 194, 84, 64, fur))                       # body
    o.append(ellipse(82, 250, 28, 13, dark))                        # feet
    o.append(ellipse(158, 250, 28, 13, dark))
    o.append(circle(58, 46, 26, fur) + circle(58, 46, 13, inner))   # ears
    o.append(circle(182, 46, 26, fur) + circle(182, 46, 13, inner))
    o.append(ellipse(120, 100, 76, 64, fur))                        # head
    o.append(ellipse(120, 124, 32, 23, muzzle))
    o.append(ellipse(120, 111, 12, 8.5, EYE))                       # nose
    for cx in (112, 128):
        o.append(f'<path d="M{cx + 8} 128 A8 5 0 0 1 {cx - 8} 128" fill="none" stroke="{EYE}" stroke-width="3" stroke-linecap="round"/>')
    for cx in (93, 147):
        o.append(ellipse(cx, 90, 7.5, 9.5, EYE) + circle(cx + 3, 86, 3, EYE_HI))
    o.append(circle(76, 118, 9, "#F28A8A", ' fill-opacity="0.35"'))
    o.append(circle(164, 118, 9, "#F28A8A", ' fill-opacity="0.35"'))
    o.append(basket_g(50, 146, 1.0, handle=False))                 # basket held at the belly
    o.append(ellipse(56, 188, 17, 15, dark))                        # paws on the rim
    o.append(ellipse(184, 188, 17, 15, dark))
    o.append("</g>")
    return "".join(o)


# ===========================================================================
# Activity icons (12), 160x160 rounded tiles
# ===========================================================================
TILE_R = 44


def tile(color, t=.72):
    return rect(0, 0, 160, 160, mix(color, CARD, t), TILE_R)


def star5(cx, cy, R, r, fill, extra=""):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rad = R if i % 2 == 0 else r
        pts.append(f"{n(cx + rad * math.cos(a))} {n(cy + rad * math.sin(a))}")
    return (f'<path d="M{" L".join(pts)} Z" fill="{fill}" stroke="{fill}" '
            f'stroke-width="{n(R * .28)}" stroke-linejoin="round"{extra}/>')


def rtri(p1, p2, p3, fill, rr=12):
    return (f'<path d="M{n(p1[0])} {n(p1[1])} L{n(p2[0])} {n(p2[1])} L{n(p3[0])} {n(p3[1])} Z" '
            f'fill="{fill}" stroke="{fill}" stroke-width="{rr}" stroke-linejoin="round"/>')


def hi(cx, cy, rx, ry):
    return ellipse(cx, cy, rx, ry, CARD, ' fill-opacity="0.45"')


def bin_path(x0, y0, w, h, color):
    return (f'<path d="M{n(x0)} {n(y0)} H{n(x0 + w)} L{n(x0 + w - 6)} {n(y0 + h - 10)} '
            f'Q{n(x0 + w - 8)} {n(y0 + h)} {n(x0 + w - 18)} {n(y0 + h)} H{n(x0 + 18)} '
            f'Q{n(x0 + 8)} {n(y0 + h)} {n(x0 + 6)} {n(y0 + h - 10)} Z" fill="{color}"/>'
            + rect(x0 - 4, y0 - 8, w + 8, 14, darken(color, .18), 7))


def icon_body(aid):
    R, O, Y, G, B, P, K, BR = (NAMED[c] for c in ("red", "orange", "yellow", "green", "blue", "purple", "pink", "brown"))
    if aid == "count_feed":
        return (tile(R) + apple_g(33, 14, .94)
                + "".join(circle(x, 136, 9, RUST_DEEP) for x in (54, 80, 106)))
    if aid == "match_it":
        return (tile(Y) + bin_path(18, 98, 56, 42, R) + bin_path(86, 98, 56, 42, B)
                + circle(46, 62, 17, R) + hi(40, 56, 4, 6)
                + rect(96, 42, 36, 36, B, 8) + hi(104, 52, 4, 6))
    if aid == "shape_sorter":
        return (tile(B) + circle(50, 56, 24, O) + rect(88, 32, 46, 46, R, 9)
                + rtri((80, 96), (112, 134), (48, 134), G))
    if aid == "find_the_same":
        return (tile(O)
                + f'<line x1="98" y1="98" x2="130" y2="130" stroke="{INK}" stroke-width="16" stroke-linecap="round"/>'
                + circle(70, 70, 38, CARD, f' stroke="{INK}" stroke-width="10"')
                + star5(70, 72, 20, 9, Y, f'') + star5(128, 36, 11, 5, Y))
    if aid == "float_or_sink":
        return (tile(G) + circle(60, 70, 17, Y) + hi(54, 64, 4, 5)
                + f'<path d="M18 80 Q33 68 49 80 T80 80 T111 80 T142 80 V124 Q142 140 126 140 H34 Q18 140 18 124 Z" fill="{WATER}"/>'
                + f'<path d="M18 80 Q33 68 49 80 T80 80 T111 80 T142 80" fill="none" stroke="{WATER_DEEP}" stroke-width="4" stroke-linecap="round"/>'
                + ellipse(106, 126, 19, 11, "#7F766F")
                + circle(96, 104, 4, "none", f' stroke="{CARD}" stroke-width="2.5"')
                + circle(108, 94, 2.5, "none", f' stroke="{CARD}" stroke-width="2"'))
    if aid == "what_is_it":
        return (tile(K)
                + f'<ellipse cx="63" cy="54" rx="12" ry="32" fill="{SILHOUETTE}" transform="rotate(-12 63 54)"/>'
                + f'<ellipse cx="97" cy="54" rx="12" ry="32" fill="{SILHOUETTE}" transform="rotate(12 97 54)"/>'
                + ellipse(80, 104, 38, 32, SILHOUETTE)
                + sparkle(130, 36, 11, P) + sparkle(30, 126, 8, P))
    if aid == "big_and_small":
        return (tile(LANTERN, .68) + rect(28, 100, 28, 36, "#E09560", 8)
                + rect(66, 70, 28, 66, RUST, 8) + rect(104, 36, 28, 100, RUST_DEEP, 8))
    if aid == "where_is_it":
        return (tile(MIST, .45) + circle(80, 38, 17, R) + hi(74, 32, 4, 6)
                + f'<path d="M36 82 L18 68 Q16 64 21 62 L48 60 L62 82 Z" fill="#B5835A"/>'
                + f'<path d="M124 82 L142 68 Q144 64 139 62 L112 60 L98 82 Z" fill="#B5835A"/>'
                + rect(36, 80, 88, 60, BR, 10) + rect(44, 78, 72, 9, "#6E4A2F", 4.5))
    if aid == "puzzle_pieces":
        return (tile(BR, .75)
                + rect(28, 28, 50, 50, G, 8) + circle(78, 53, 9, G)
                + rect(82, 28, 50, 50, B, 8) + circle(107, 78, 9, B)
                + rect(28, 82, 50, 50, O, 8)
                + rect(82, 82, 50, 50, "none", 8, f' stroke="{RUST_DEEP}" stroke-width="4" stroke-dasharray="8 7"')
                + f'<g transform="rotate(14 116 112)">{rect(96, 92, 44, 44, R, 8)}{circle(96, 114, 8, mix(CARD, R, .0))}</g>')
    if aid == "day_and_night":
        rays = "".join(circle(46 + 31 * math.cos(i * math.pi / 4), 80 + 31 * math.sin(i * math.pi / 4), 4.5, O)
                       for i in range(8))
        return (f'<path d="M44 0 H80 V160 H44 A44 44 0 0 1 0 116 V44 A44 44 0 0 1 44 0 Z" fill="{mix(Y, CARD, .7)}"/>'
                f'<path d="M80 0 H116 A44 44 0 0 1 160 44 V116 A44 44 0 0 1 116 160 H80 Z" fill="{NIGHT}"/>'
                + rays + circle(46, 80, 20, Y)
                + circle(114, 74, 21, "#F6E7B8") + circle(125, 66, 19, NIGHT)
                + sparkle(134, 116, 9, "#F6E7B8") + sparkle(100, 124, 5, "#F6E7B8"))
    if aid == "pattern_parade":
        return (tile(WATER, .66) + circle(31, 80, 15, R) + rect(49, 65, 30, 30, B, 6)
                + circle(97, 80, 15, R)
                + rect(114, 65, 30, 30, "none", 6, f' stroke="{WATER_DEEP}" stroke-width="4" stroke-dasharray="6 5"')
                + "".join(circle(x, 118, 4, WATER_DEEP) for x in (31, 64, 97, 129)))
    if aid == "mirror_match":
        return (tile(P)
                + f'<line x1="80" y1="18" x2="80" y2="144" stroke="{INK}" stroke-opacity="0.45" stroke-width="3" stroke-dasharray="6 6" stroke-linecap="round"/>'
                + ellipse(54, 64, 27, 23, P) + ellipse(106, 64, 27, 23, P)
                + ellipse(58, 102, 18, 16, K) + ellipse(102, 102, 18, 16, K)
                + circle(50, 62, 7, CARD) + circle(110, 62, 7, CARD)
                + ellipse(80, 82, 5.5, 31, INK)
                + f'<path d="M77 54 Q70 38 62 34 M83 54 Q90 38 98 34" fill="none" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    raise KeyError(aid)


ACTIVITIES = ["count_feed", "match_it", "shape_sorter", "find_the_same", "float_or_sink", "what_is_it",
              "big_and_small", "where_is_it", "puzzle_pieces", "day_and_night", "pattern_parade", "mirror_match"]

# ===========================================================================
# Scenes (8 chapters), 1194x834 = iPad 11" landscape, from placeholder_art.json
# ===========================================================================
W, H = 1194, 834
SCENES = {
    "orchard": ("#F7D9A8", "#9CC77E"), "shapevillage": ("#F5C9A0", "#D9B98C"),
    "rainbowriver": ("#CFE3E8", "#7FB7C9"), "bigmountain": ("#D6E2F0", "#A7B98C"),
    "mistyforest": ("#C9D3CB", "#7E9C7A"), "starrymeadow": ("#4A4A7A", "#6F8F6A"),
    "mirrorlake": ("#F2D0D8", "#8FB9D6"), "lighthouse": ("#2F3558", "#5B6B4E"),
}


def far_hills(color, y=.60):
    return (f'<path d="M0 {n(H * y)} C{n(W * .18)} {n(H * (y - .10))} {n(W * .32)} {n(H * (y - .06))} '
            f'{n(W * .5)} {n(H * (y - .02))} S{n(W * .82)} {n(H * (y - .12))} {n(W)} {n(H * (y - .04))} '
            f'V{H} H0 Z" fill="{color}"/>')


def near_ground(color, y=.74):
    return (f'<path d="M0 {n(H * y)} C{n(W * .25)} {n(H * (y - .06))} {n(W * .45)} {n(H * (y + .05))} '
            f'{n(W * .7)} {n(H * y)} S{n(W * .92)} {n(H * (y - .04))} {n(W)} {n(H * (y - .01))} '
            f'V{H} H0 Z" fill="{color}"/>')


def apple_tree(x, base, s, canopy=NAMED["green"], apples=True):
    o = [rect(x - 13 * s, base - 120 * s, 26 * s, 122 * s, NAMED["brown"], 10 * s)]
    back = darken(canopy, .12)
    o.append(circle(x - 52 * s, base - 128 * s, 52 * s, back))
    o.append(circle(x + 54 * s, base - 124 * s, 54 * s, back))
    o.append(circle(x, base - 166 * s, 74 * s, canopy))
    o.append(circle(x - 40 * s, base - 150 * s, 44 * s, canopy))
    o.append(circle(x + 42 * s, base - 146 * s, 46 * s, canopy))
    if apples:
        for dx, dy in ((-40, -140), (22, -196), (48, -132), (-8, -118), (-58, -186), (70, -176)):
            o.append(circle(x + dx * s, base + dy * s, 10 * s, NAMED["red"]))
    return "".join(o)


def cloud(x, y, s, fill=CARD, op=0.9):
    e = f' fill-opacity="{op}"'
    return (circle(x, y, 34 * s, fill, e) + circle(x + 40 * s, y - 14 * s, 42 * s, fill, e)
            + circle(x + 84 * s, y, 32 * s, fill, e) + rect(x - 10 * s, y, 110 * s, 34 * s, fill, 17 * s, e))


def gumdrop(x, base, w, h, fill):
    return (f'<path d="M{n(x - w)} {n(base)} C{n(x - w)} {n(base - h * .45)} {n(x - w * .22)} {n(base - h)} {n(x)} {n(base - h)} '
            f'C{n(x + w * .22)} {n(base - h)} {n(x + w)} {n(base - h * .45)} {n(x + w)} {n(base)} Z" fill="{fill}"/>')


def house(x, base, kind, wall, roof, s=1.0):
    o = []
    if kind == "square":
        o.append(rect(x - 60 * s, base - 110 * s, 120 * s, 110 * s, wall, 10 * s))
        o.append(rtri((x, base - 190 * s), (x + 76 * s, base - 110 * s), (x - 76 * s, base - 110 * s), roof, 16 * s))
    elif kind == "round":
        o.append(rect(x - 58 * s, base - 96 * s, 116 * s, 96 * s, wall, 10 * s))
        o.append(f'<path d="M{n(x - 70 * s)} {n(base - 92 * s)} A{n(70 * s)} {n(70 * s)} 0 0 1 {n(x + 70 * s)} {n(base - 92 * s)} Z" fill="{roof}"/>')
    elif kind == "tall":
        o.append(rect(x - 46 * s, base - 170 * s, 92 * s, 170 * s, wall, 10 * s))
        o.append(rect(x - 58 * s, base - 196 * s, 116 * s, 34 * s, roof, 12 * s))
    elif kind == "roofless":
        o.append(rect(x - 64 * s, base - 104 * s, 128 * s, 104 * s, wall, 10 * s))
    # door + window
    o.append(rect(x - 16 * s, base - 56 * s, 32 * s, 56 * s, darken(wall, .45), 16 * s))
    if kind in ("square", "tall", "roofless"):
        o.append(rect(x + 22 * s, base - (140 if kind == "tall" else 90) * s, 26 * s, 24 * s, "#F2CC4A", 6 * s))
    return "".join(o)


def flower(x, y, color, lit=True, s=1.0):
    o = [f'<line x1="{n(x)}" y1="{n(y)}" x2="{n(x)}" y2="{n(y + 60 * s)}" stroke="#4E6B48" stroke-width="{n(6 * s)}" stroke-linecap="round"/>']
    if lit:
        o.append(circle(x, y, 40 * s, color, ' fill-opacity="0.22"'))
    pc = color if lit else "#5E5E73"
    for i in range(5):
        a = -math.pi / 2 + i * 2 * math.pi / 5
        o.append(circle(x + 15 * s * math.cos(a), y + 15 * s * math.sin(a), 11 * s, pc))
    o.append(circle(x, y, 9 * s, "#F6E7B8" if lit else "#77778A"))
    return "".join(o)


def duck(x, y, s=1.0):
    return (ellipse(x, y, 40 * s, 24 * s, NAMED["yellow"]) + circle(x + 30 * s, y - 28 * s, 20 * s, NAMED["yellow"])
            + ellipse(x + 52 * s, y - 24 * s, 12 * s, 6 * s, NAMED["orange"]) + circle(x + 36 * s, y - 32 * s, 3.5 * s, EYE)
            + f'<path d="M{n(x - 20 * s)} {n(y - 6 * s)} Q{n(x)} {n(y + 6 * s)} {n(x + 14 * s)} {n(y - 8 * s)}" fill="none" stroke="#D9A92E" stroke-width="{n(5 * s)}" stroke-linecap="round"/>')


def butterfly(x, y, s, a=1.0):
    P, K = NAMED["purple"], NAMED["pink"]
    op = f' fill-opacity="{a}"'
    return (ellipse(x - 26 * s, y - 16 * s, 27 * s, 23 * s, P, op) + ellipse(x + 26 * s, y - 16 * s, 27 * s, 23 * s, P, op)
            + ellipse(x - 22 * s, y + 22 * s, 18 * s, 16 * s, K, op) + ellipse(x + 22 * s, y + 22 * s, 18 * s, 16 * s, K, op)
            + ellipse(x, y, 5 * s, 30 * s, INK, op))


def moon(x, y, r, sky):
    return circle(x, y, r, "#F6E7B8") + circle(x + r * .5, y - r * .38, r * .88, sky)


STARS = [(80, 70, 10), (210, 150, 7), (330, 60, 12), (470, 120, 6), (560, 50, 9), (700, 110, 7),
         (820, 60, 11), (1080, 90, 8), (150, 250, 6), (400, 230, 8), (1120, 250, 7), (620, 210, 6)]


def scene_body(sid):
    sky, ground = SCENES[sid]
    o = [rect(0, 0, W, H, sky)]
    far = mix(ground, sky, .45)
    if sid == "orchard":
        o += [circle(960, 150, 64, NAMED["yellow"], ' fill-opacity="0.75"'), cloud(180, 150, 1.0), cloud(640, 110, .8),
              far_hills(far), apple_tree(360, 560, .62, mix(NAMED["green"], sky, .25)),
              apple_tree(840, 548, .56, mix(NAMED["green"], sky, .25)),
              near_ground(ground), apple_tree(150, 700, 1.25), apple_tree(1060, 690, 1.35)]
    elif sid == "shapevillage":
        o += [cloud(140, 140, .9), far_hills(far),
              f'<g transform="rotate(-18 610 190)">{rtri((610, 130), (680, 210), (540, 210), NAMED["red"], 14)}</g>',
              f'<g transform="rotate(14 760 270)">{rtri((760, 220), (816, 290), (704, 290), NAMED["orange"], 12)}</g>',
              f'<path d="M430 170 Q480 150 520 170 M450 206 Q500 186 540 206" fill="none" stroke="{CARD}" stroke-width="8" stroke-linecap="round"/>',
              near_ground(ground),
              house(170, 690, "square", "#FFF1DE", NAMED["blue"], 1.1), house(420, 660, "round", "#FFE3C8", NAMED["green"], 1.0),
              house(770, 676, "roofless", "#FFF1DE", "", 1.05), house(1030, 690, "tall", "#FFE3C8", NAMED["purple"], 1.0)]
    elif sid == "rainbowriver":
        arcs = "".join(f'<path d="M{n(600 - r)} 600 A{r} {r} 0 0 1 {n(600 + r)} 600" fill="none" stroke="{NAMED[c]}" stroke-width="26" stroke-opacity="0.85"/>'
                       for c, r in zip(("red", "orange", "yellow", "green", "blue", "purple"), (420, 394, 368, 342, 316, 290)))
        o += [cloud(120, 130, .9), cloud(900, 100, .8), arcs, far_hills(mix(NAMED["green"], sky, .45), .64),
              near_ground(mix(NAMED["green"], sky, .15), .70),
              f'<path d="M-20 834 C200 780 260 700 520 690 S900 640 1214 560 V834 Z" fill="{ground}"/>',
              f'<path d="M140 800 Q220 770 300 790 M620 700 Q700 680 780 694 M900 650 Q960 636 1020 646" fill="none" stroke="{CARD}" stroke-opacity="0.7" stroke-width="7" stroke-linecap="round"/>',
              duck(660, 760, 1.2)]
    elif sid == "bigmountain":
        o += [cloud(120, 160, .9), cloud(930, 120, 1.0),
              gumdrop(250, 700, 230, 360, "#B4BFD6"), gumdrop(980, 700, 240, 330, "#B4BFD6"),
              gumdrop(620, 720, 320, 560, "#98A5C2"),
              f'<path d="M532 280 C560 214 590 176 620 176 C650 176 680 214 708 280 Q690 300 670 282 Q646 304 622 282 Q596 304 572 282 Q552 300 532 280 Z" fill="#F7F1E6"/>',
              near_ground(ground),
              f'<g stroke="{NAMED["brown"]}" stroke-width="12" stroke-linecap="round"><line x1="860" y1="770" x2="930" y2="520"/><line x1="930" y1="770" x2="1000" y2="520"/></g>',
              "".join(f'<line x1="{n(860 + 70 * (770 - y) / 250)}" y1="{y}" x2="{n(930 + 70 * (770 - y) / 250)}" y2="{y}" stroke="{NAMED["brown"]}" stroke-width="10" stroke-linecap="round"/>'
                      for y in (730, 680, 630, 580))]
    elif sid == "mistyforest":
        o += [far_hills(far),
              "".join(gumdrop(x, 560, 46, 190, "#9DB39A") for x in (80, 230, 380, 520, 690, 850, 1010, 1150)),
              rect(-40, 440, 1300, 60, "#F3F0EB", 30, ' fill-opacity="0.55"'),
              near_ground(ground),
              "".join(gumdrop(x, h0, 70, hh, "#5E7F5C") for x, h0, hh in ((140, 720, 330), (330, 700, 300), (880, 700, 320), (1080, 730, 340))),
              ellipse(330, 520, 26, 32, NAMED["brown"]) + circle(320, 512, 10, "#FFF1DE") + circle(342, 512, 10, "#FFF1DE")
              + circle(320, 512, 4.5, EYE) + circle(342, 512, 4.5, EYE),
              ellipse(640, 760, 44, 28, NAMED["green"]) + circle(622, 736, 12, NAMED["green"]) + circle(658, 736, 12, NAMED["green"])
              + circle(622, 736, 5, EYE) + circle(658, 736, 5, EYE),
              rect(-60, 600, 700, 70, "#F3F0EB", 35, ' fill-opacity="0.6"'),
              rect(560, 660, 760, 60, "#F3F0EB", 30, ' fill-opacity="0.5"')]
    elif sid == "starrymeadow":
        o += ["".join(sparkle(x, y, r, "#F6E7B8") for x, y, r in STARS), moon(990, 150, 58, sky),
              far_hills(mix(ground, sky, .55), .66), near_ground(ground, .76),
              "".join(flower(140 + i * 150, 640 + (i % 2) * 24, NAMED["red"] if i % 2 == 0 else NAMED["blue"], lit=i < 5)
                      for i in range(7))]
    elif sid == "mirrorlake":
        o += [cloud(150, 130, .8), far_hills(mix(NAMED["green"], sky, .5), .56),
              rect(0, 470, W, H - 470, ground),
              f'<g transform="translate(0 940) scale(1 -1)" opacity="0.35">{far_hills(mix(NAMED["green"], sky, .5), .56)}</g>',
              rect(0, 470, W, 8, CARD, 0, ' fill-opacity="0.5"'),
              butterfly(600, 300, 1.8), butterfly(600, 640, 1.8, .35),
              f'<path d="M60 560 Q200 540 340 556 M820 600 Q960 584 1120 600" fill="none" stroke="{CARD}" stroke-opacity="0.6" stroke-width="6" stroke-linecap="round"/>']
    elif sid == "lighthouse":
        lights = ("red", "orange", "yellow", "green", "blue", "purple", "pink")
        path_pts = [(170, 780), (300, 720), (420, 690), (520, 610), (600, 560), (660, 480), (720, 420)]
        o += ["".join(sparkle(x, y, r, "#F6E7B8") for x, y, r in STARS),
              far_hills(mix(ground, sky, .5), .70),
              f'<path d="M0 834 C220 760 480 640 640 420 C700 330 820 330 880 420 C980 560 1100 640 1194 700 V834 Z" fill="{ground}"/>',
              circle(760, 250, 190, "#FFE9A8", ' fill-opacity="0.12"'),
              lantern_g(NAMED["white"], "lit", 680, 150, 1.35),
              "".join(lantern_g(NAMED[c], "lit", x - 18, y - 60, .3) for c, (x, y) in zip(lights, path_pts))]
    return "".join(o)


# ===========================================================================
# Story map, home background, app icon
# ===========================================================================
MAP_STOPS = [(150, 700), (330, 592), (520, 668), (660, 505), (470, 385), (640, 262), (860, 330), (1010, 168)]


def catmull(points):
    d = f"M{points[0][0]} {points[0][1]}"
    for i in range(len(points) - 1):
        p0 = points[max(i - 1, 0)]
        p1, p2 = points[i], points[i + 1]
        p3 = points[min(i + 2, len(points) - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{n(c1[0])} {n(c1[1])} {n(c2[0])} {n(c2[1])} {p2[0]} {p2[1]}"
    return d


def map_body():
    o = [rect(0, 0, W, H, "#F8EAD3")]
    o.append(cloud(110, 110, .8, CARD, .8) + cloud(560, 80, .7, CARD, .8))
    # Lantern Hill, the goal — dark until the end
    o.append(f'<path d="M760 834 C820 520 920 250 1010 214 C1100 250 1170 420 1194 520 V834 Z" fill="#E3CCA6"/>')
    o.append(far_hills("#EEDCBD", .52))
    o.append(f'<path d="M0 520 C200 470 360 520 560 500 S900 420 1194 470 V834 H0 Z" fill="#E6D2AE"/>')
    o.append(f'<path d="M0 640 C240 600 420 660 640 620 S1000 560 1194 600 V834 H0 Z" fill="#DCC69E"/>')
    # region vignettes
    o.append(apple_tree(70, 690, .42) + apple_tree(245, 690, .36))                                   # 1 orchard
    o.append(house(410, 560, "square", "#FFF1DE", NAMED["blue"], .38) + house(455, 566, "round", "#FFE3C8", NAMED["green"], .34))  # 2
    o.append(f'<path d="M430 834 C470 760 560 740 590 700 S640 640 700 620" fill="none" stroke="{WATER}" stroke-width="30" stroke-linecap="round"/>')  # 3 river
    o.append(gumdrop(760, 520, 110, 190, "#A9B3CB") + gumdrop(700, 520, 70, 120, "#BCC5D8"))        # 4 mountain
    o.append("".join(gumdrop(x, 380, 22, 84, "#7E9C7A") for x in (380, 410, 545, 575)))             # 5 forest
    o.append("".join(sparkle(x, y, r, NAMED["purple"]) for x, y, r in ((560, 212, 9), (705, 206, 11), (590, 290, 6))))  # 6
    o.append(ellipse(940, 392, 78, 24, "#9FC4DC"))                                                    # 7 lake
    # the path
    d = catmull(MAP_STOPS)
    o.append(f'<path d="{d}" fill="none" stroke="#EAD3AE" stroke-width="36" stroke-linecap="round" stroke-linejoin="round"/>')
    o.append(f'<path d="{d}" fill="none" stroke="{RUST}" stroke-width="10" stroke-linecap="round" stroke-dasharray="1 24"/>')
    # the big lantern itself is the chapter-8 stop, drawn by the screen so it can light up
    return "".join(o)


def home_body():
    o = [rect(0, 0, W, H, PAPER)]
    o.append(cloud(420, 120, .8, CARD, .9) + cloud(900, 90, .6, CARD, .9))
    o.append(f'<path d="M820 834 C880 560 960 330 1040 300 C1120 330 1170 450 1194 520 V834 Z" fill="#EFDDBF"/>')
    o.append(lantern_g(LANTERN, "unlit", 1010, 208, .55))
    o.append(far_hills("#F1E2C6", .66))
    o.append(near_ground(mix(LEAF, PAPER, .55), .80))
    o.append(f'<path d="M-20 834 C-20 700 120 640 260 640 C400 640 520 720 540 834 Z" fill="{mix(LEAF, PAPER, .3)}"/>')
    return "".join(o)


def app_icon_body(S=1024):
    o = [rect(0, 0, S, S, NIGHT)]
    for x, y, r in ((130, 150, 26), (300, 90, 14), (840, 130, 30), (920, 330, 16), (700, 70, 12), (90, 420, 12)):
        o.append(sparkle(x, y, r, "#F6E7B8"))
    o.append(f'<path d="M0 {S * .80} C{S * .3} {S * .74} {S * .7} {S * .84} {S} {S * .78} V{S} H0 Z" fill="#30335C"/>')
    w, ox, oy = 700, 234, 262
    lx, ly = ox + .10 * w, oy + .60 * w   # Yun's lantern, for the halo
    # flat warm rings (a translucent gold over indigo reads grey, so mix solid steps)
    for r, t in ((330, .10), (240, .20), (160, .34), (100, .52)):
        o.append(circle(lx, ly, r, mix(NIGHT, LANTERN, t)))
    o.append(yun_g("happy", LANTERN, w, ox, oy, sway=-0.06))
    return "".join(o)


# ===========================================================================
def main():
    for mood in ("idle", "happy", "sleepy"):
        save(f"yun_{mood}.svg", yun_svg(mood))
    for c in ("red", "orange", "yellow", "green", "blue", "purple", "pink", "white"):
        save(f"light_{c}.svg", svg(120, 160, lantern_g(NAMED[c], "lit")))
    save("light_unlit.svg", svg(120, 160, lantern_g(LANTERN, "unlit")))
    save("light_misty.svg", svg(120, 160, lantern_g(LANTERN, "misty")))
    for aid in ACTIVITIES:
        save(f"icon_{aid}.svg", svg(160, 160, icon_body(aid)))
    for sid in SCENES:
        save(f"scene_{sid}.svg", svg(W, H, scene_body(sid)))
    save("apple.svg", svg(100, 100, apple_g()))
    save("basket.svg", svg(140, 112, basket_g(0, 0, 1.0), "0 -10 140 122"))
    save("bear.svg", svg(240, 266, bear_g()))
    save("map.svg", svg(W, H, map_body()))
    save("home_bg.svg", svg(W, H, home_body()))
    save("app_icon.svg", svg(1024, 1024, app_icon_body()))
    print("\n".join(sorted(os.listdir(OUT))))


if __name__ == "__main__":
    main()
