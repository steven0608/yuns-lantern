#!/usr/bin/env python3
"""Vocabulary item art: one SVG per content/vocab.json id, in design/svg/items/.

Rules (from the app crew, 2026-09-25):
  - Draw each item in its vocab.json `color` and, where honest, its `shape`:
    those attributes drive Match It / Shape Sorter rounds, so the picture must agree.
  - Mirror Match builds pictures from the left half, so boat, leaf, umbrella, kite and
    butterfly are drawn strictly symmetric about x = 100.
  - White items get an outline so they read on the paper background.
All art sits in a 200 x 200 box with ~16 px padding; PNGs are exported at 256 px.
"""
import os

from gen_assets import (CARD, EYE, EYE_HI, INK, NAMED, STICK, apple_g, circle, darken, ellipse, lantern_g, mix,
                        rect, rtri, sparkle, star5, svg)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg", "items")
os.makedirs(OUT, exist_ok=True)

R, O, Y, G, B, P, K, BR, WH, BK = (NAMED[c] for c in ("red", "orange", "yellow", "green", "blue", "purple", "pink",
                                                       "brown", "white", "black"))
OL = ' stroke="#4A3426" stroke-opacity="0.38" stroke-width="4" stroke-linejoin="round"'   # outline for white/light fills
SKIN = "#F3D9B5"
PINK_IN = "#F2A7B4"


def hl(cx, cy, rx, ry, op=0.45):
    return ellipse(cx, cy, rx, ry, CARD, f' fill-opacity="{op}"')


def path(d, fill, extra=""):
    return f'<path d="{d}" fill="{fill}"{extra}/>'


def line(d, color, w, extra=""):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"{extra}/>'


def eyes(x1, x2, y, r=6):
    return "".join(ellipse(x, y, r, r * 1.2, EYE) + circle(x + r * .35, y - r * .45, r * .38, EYE_HI) for x in (x1, x2))


def cheeks(x1, x2, y, r=8):
    return circle(x1, y, r, "#F28A8A", ' fill-opacity="0.35"') + circle(x2, y, r, "#F28A8A", ' fill-opacity="0.35"')


def smile(cx, y, w=10):
    return line(f"M{cx - w} {y} Q{cx} {y + w * .8} {cx + w} {y}", EYE, 3.5)


ITEMS = {}


def item(f):
    ITEMS[f.__name__.rstrip("_")] = f
    return f


# ---- food --------------------------------------------------------------------
@item
def apple():
    return apple_g(15, 12, 1.72)


@item
def banana():
    return (path("M40 58 C44 128 104 170 162 152 C174 148 172 134 160 134 C112 140 72 108 64 58 C62 46 40 46 40 58 Z", Y)
            + line("M52 70 C62 118 104 146 150 142", darken(Y, .15), 4, ' stroke-opacity="0.6"')
            + circle(52, 50, 8, darken(BR, .1)) + circle(166, 144, 5, darken(BR, .1)))


@item
def orange():
    return (circle(100, 108, 66, O) + hl(76, 84, 12, 18)
            + "".join(circle(x, y, 2.5, darken(O, .18), ' fill-opacity="0.5"') for x, y in ((120, 90), (132, 120), (96, 140), (70, 118), (110, 64)))
            + line("M100 44 Q100 36 104 30", STICK, 5) + path("M104 36 Q124 22 136 32 Q122 46 104 36 Z", G))


@item
def grape():
    pts = [(70, 72), (100, 72), (130, 72), (85, 102), (115, 102), (70, 132), (100, 132), (130, 132), (100, 160)]
    pts = [(70, 70), (100, 70), (130, 70), (85, 100), (115, 100), (100, 130), (85, 158), (115, 158)][:6] + [(100, 158)]
    return (line("M100 50 L100 30", STICK, 6) + path("M100 38 Q122 20 138 30 Q120 48 100 38 Z", G)
            + "".join(circle(x, y, 21, P) + hl(x - 7, y - 7, 5, 6) for x, y in pts))


@item
def strawberry():
    seeds = "".join(ellipse(x, y, 2.6, 4, "#FFE9A8") for x, y in
                    ((80, 88), (100, 84), (120, 88), (72, 110), (92, 108), (112, 108), (130, 110), (84, 132), (104, 130), (122, 132), (96, 152)))
    return (path("M100 176 C62 154 36 104 44 76 C54 50 146 50 156 76 C164 104 138 154 100 176 Z", R) + seeds
            + path("M100 70 L78 50 L96 56 L100 38 L104 56 L122 50 Z", G, ' stroke="#79B45A" stroke-width="8" stroke-linejoin="round"')
            + hl(68, 90, 7, 13))


@item
def watermelon():
    stripes = "".join(line(f"M{x} 40 Q{x + (x - 100) * .6} 104 {x} 168", darken(G, .3), 9) for x in (64, 100, 136))
    return circle(100, 104, 70, G) + stripes + hl(64, 70, 10, 16, .35)


@item
def carrot():
    return (path("M100 64 Q88 30 76 26 M100 64 Q100 26 100 18 M100 64 Q112 30 124 26", "none",
                 f' stroke="{G}" stroke-width="10" stroke-linecap="round"')
            + path("M58 66 L142 66 Q146 78 134 90 L108 170 Q100 182 92 170 L66 90 Q54 78 58 66 Z", O)
            + line("M80 96 L94 96 M104 120 L118 120 M86 140 L98 140", darken(O, .2), 4))


@item
def corn():
    kernels = "".join(circle(x, y, 6, darken(Y, .1)) for x in (86, 100, 114) for y in range(52, 162, 14))
    return (ellipse(100, 106, 34, 70, Y) + kernels
            + path("M100 176 C60 160 50 110 62 70 C70 110 84 140 100 150 Z", G)
            + path("M100 176 C140 160 150 110 138 70 C130 110 116 140 100 150 Z", darken(G, .12)))


@item
def mushroom():
    return (rect(78, 100, 44, 62, SKIN, 18) + path("M34 112 A66 66 0 0 1 166 112 Q100 124 34 112 Z", BR)
            + circle(76, 80, 9, "#F3E3C8") + circle(116, 70, 11, "#F3E3C8") + circle(138, 96, 7, "#F3E3C8")
            + hl(60, 84, 6, 10, .3))


@item
def egg():
    return ellipse(100, 108, 54, 70, WH, OL) + hl(80, 82, 9, 16, .8)


@item
def bread():
    return (ellipse(100, 82, 64, 30, BR) + rect(36, 80, 128, 82, BR, 20)
            + line("M70 70 Q78 62 86 70 M96 66 Q104 58 112 66 M122 70 Q130 62 138 70", mix(BR, CARD, .5), 5)
            + hl(60, 110, 8, 20, .25))


@item
def cookie():
    chips = "".join(ellipse(x, y, 7, 6, darken(BR, .45)) for x, y in ((78, 80), (118, 72), (132, 112), (96, 124), (68, 118), (108, 150)))
    return circle(100, 104, 68, BR) + circle(100, 104, 58, mix(BR, SKIN, .35)) + chips


# ---- animals -----------------------------------------------------------------
def critter(body, head_y, head_r, ears, face_extra="", belly=None):
    """Front-facing sitting animal: body, head, ears, face."""
    o = [ellipse(100, 150, 50, 38, body)]
    if belly:
        o.append(ellipse(100, 156, 28, 24, belly))
    o.append(ears)
    o.append(circle(100, head_y, head_r, body))
    o.append(face_extra)
    return "".join(o)


@item
def cat():
    ears = rtri((62, 30), (86, 58), (56, 70), O, 10) + rtri((138, 30), (144, 70), (114, 58), O, 10)
    face = (eyes(84, 116, 82) + ellipse(100, 98, 5, 4, "#E88A8A") + smile(100, 103, 7) + cheeks(72, 128, 100)
            + line("M60 96 L40 92 M60 102 L40 106 M140 96 L160 92 M140 102 L160 106", darken(O, .35), 2.5)
            + line("M88 50 L90 60 M100 48 L100 58 M112 50 L110 60", darken(O, .22), 5))
    tail = line("M146 160 C176 158 180 126 160 118", O, 14)
    return tail + critter(O, 84, 44, ears, face, belly="#FBE0C0")


@item
def dog():
    ears = ellipse(56, 92, 16, 34, darken(BR, .3), ' transform="rotate(12 56 92)"') + ellipse(144, 92, 16, 34, darken(BR, .3), ' transform="rotate(-12 144 92)"')
    face = (ellipse(100, 104, 26, 20, SKIN) + eyes(84, 116, 80) + ellipse(100, 96, 9, 7, EYE)
            + path("M94 114 Q100 132 106 114 Z", "#E88A8A") + cheeks(70, 130, 104))
    return critter(BR, 86, 46, "", face, belly=SKIN) + ears


@item
def rabbit():
    ears = (ellipse(80, 48, 15, 40, WH, OL) + ellipse(80, 50, 7, 28, PINK_IN)
            + ellipse(120, 48, 15, 40, WH, OL) + ellipse(120, 50, 7, 28, PINK_IN))
    face = eyes(86, 114, 104) + ellipse(100, 118, 5, 4, "#E88A8A") + smile(100, 122, 6) + cheeks(76, 124, 122)
    return (ellipse(100, 158, 46, 32, WH, OL) + ears + circle(100, 110, 40, WH, OL) + face)


@item
def bird():
    return (path("M40 104 L16 88 L20 116 Z", darken(B, .2)) + ellipse(100, 110, 60, 48, B) + ellipse(108, 126, 40, 28, mix(B, CARD, .55))
            + ellipse(84, 110, 30, 20, darken(B, .18), ' transform="rotate(-18 84 110)"')
            + eyes(132, 132, 92, 6) + path("M156 100 L178 106 L156 114 Z", O)
            + line("M92 156 L88 172 M112 156 L116 172", O, 5))


@item
def fish():
    return (path("M140 100 L180 70 Q170 100 180 130 Z", darken(O, .12)) + ellipse(96, 100, 60, 40, O)
            + path("M84 62 Q100 40 118 62 Z", darken(O, .12)) + path("M90 138 Q100 156 112 138 Z", darken(O, .12))
            + line("M78 70 Q88 100 78 130 M104 64 Q114 100 104 136", CARD, 5, ' stroke-opacity="0.55"')
            + eyes(60, 60, 92, 7) + smile(46, 110, 5))


@item
def duck():
    return (ellipse(96, 132, 64, 40, Y) + circle(132, 76, 32, Y) + ellipse(162, 84, 18, 9, O)
            + eyes(140, 140, 70, 6) + path("M60 124 Q84 150 110 126", darken(Y, .18), ' stroke="#D9A92E" stroke-width="7" stroke-linecap="round" fill-opacity="0"')
            + path("M30 120 L46 110 L44 132 Z", darken(Y, .12)))


@item
def bear():
    ears = circle(58, 52, 22, BR) + circle(58, 52, 11, "#D9A77A") + circle(142, 52, 22, BR) + circle(142, 52, 11, "#D9A77A")
    face = (ellipse(100, 104, 26, 19, SKIN) + ellipse(100, 96, 10, 7, EYE) + smile(100, 106, 7) + eyes(80, 120, 80) + cheeks(64, 136, 104))
    return (ellipse(100, 158, 54, 36, BR) + ellipse(100, 162, 30, 24, "#C49A70")
            + ellipse(62, 150, 14, 20, darken(BR, .3)) + ellipse(138, 150, 14, 20, darken(BR, .3))
            + ears + ellipse(100, 88, 54, 46, BR) + face)


@item
def elephant():
    ele = "#9AA6BD"   # blue-grey: vocab says blue; proposed to set color null (elephants are grey)
    return (rect(64, 130, 22, 40, darken(ele, .1), 10) + rect(126, 130, 22, 40, darken(ele, .1), 10)
            + ellipse(112, 118, 60, 44, ele) + line("M168 108 Q182 118 176 134", ele, 7)
            + circle(66, 90, 40, ele) + ellipse(88, 88, 28, 36, mix(ele, PINK_IN, .35))
            + line("M40 104 C28 130 40 158 56 150", ele, 18) + eyes(54, 54, 80, 6) + cheeks(40, 40, 98, 7))


@item
def mouse():
    return (line("M150 140 C182 140 186 108 168 104", "#D9A77A", 5)
            + ellipse(112, 130, 52, 38, BR) + circle(66, 68, 22, BR) + circle(66, 68, 12, PINK_IN)
            + circle(116, 64, 22, BR) + circle(116, 64, 12, PINK_IN)
            + ellipse(84, 104, 40, 34, BR) + eyes(74, 100, 96, 5) + circle(52, 110, 6, "#E88A8A"))


@item
def owl():
    return (rtri((58, 36), (78, 60), (54, 66), darken(BR, .15), 8) + rtri((142, 36), (146, 66), (122, 60), darken(BR, .15), 8)
            + ellipse(100, 112, 58, 66, BR) + ellipse(100, 132, 36, 40, "#D9B48A")
            + ellipse(52, 118, 14, 36, darken(BR, .2)) + ellipse(148, 118, 14, 36, darken(BR, .2))
            + circle(78, 82, 22, CARD) + circle(122, 82, 22, CARD) + circle(80, 84, 10, EYE) + circle(120, 84, 10, EYE)
            + circle(83, 80, 3.5, EYE_HI) + circle(123, 80, 3.5, EYE_HI) + path("M92 100 L108 100 L100 114 Z", O))


@item
def frog():
    return (ellipse(100, 130, 66, 44, G) + ellipse(100, 142, 40, 26, mix(G, CARD, .5))
            + circle(70, 84, 22, G) + circle(130, 84, 22, G) + circle(70, 82, 13, CARD) + circle(130, 82, 13, CARD)
            + circle(72, 84, 7, EYE) + circle(128, 84, 7, EYE) + smile(100, 116, 16) + cheeks(66, 134, 120)
            + ellipse(52, 168, 22, 9, darken(G, .15)) + ellipse(148, 168, 22, 9, darken(G, .15)))


@item
def turtle():
    shell = path("M36 132 A64 64 0 0 1 164 132 Z", G)
    plates = line("M68 132 L80 96 L120 96 L132 132 M80 96 L92 76 M120 96 L108 76", darken(G, .3), 5)
    return (ellipse(56, 142, 14, 10, mix(G, Y, .4)) + ellipse(144, 142, 14, 10, mix(G, Y, .4))
            + circle(168, 116, 18, mix(G, Y, .4)) + eyes(174, 174, 110, 4) + shell + plates
            + rect(30, 128, 140, 12, darken(G, .25), 6))


@item
def butterfly():  # symmetric about x = 100 (Mirror Match)
    w = ""
    for s in (-1, 1):
        w += ellipse(100 + s * 40, 76, 38, 32, P) + ellipse(100 + s * 34, 130, 26, 24, mix(P, K, .35))
        w += circle(100 + s * 46, 72, 11, CARD, ' fill-opacity="0.8"') + circle(100 + s * 34, 132, 7, CARD, ' fill-opacity="0.7"')
    return (w + ellipse(100, 104, 8, 44, INK)
            + line("M96 64 Q88 42 76 36 M104 64 Q112 42 124 36", INK, 4) + circle(76, 36, 5, INK) + circle(124, 36, 5, INK))


@item
def bee():
    clip = '<clipPath id="beebody"><ellipse cx="96" cy="112" rx="54" ry="40"/></clipPath>'
    stripes = f'<g clip-path="url(#beebody)">{rect(78, 60, 16, 110, BK)}{rect(110, 60, 16, 110, BK)}</g>'
    return (f"<defs>{clip}</defs>"
            + ellipse(84, 70, 22, 32, CARD, ' fill-opacity="0.85" transform="rotate(-20 84 70)"')
            + ellipse(112, 68, 22, 32, CARD, ' fill-opacity="0.85" transform="rotate(20 112 68)"')
            + ellipse(96, 112, 54, 40, Y) + stripes + path("M40 112 L26 106 L28 120 Z", BK)
            + circle(148, 108, 20, BK) + circle(154, 102, 5, EYE_HI) + line("M150 90 Q156 72 168 68", BK, 3.5))


@item
def panda():
    return (ellipse(100, 160, 54, 34, WH, OL) + ellipse(56, 154, 16, 22, BK) + ellipse(144, 154, 16, 22, BK)
            + circle(60, 54, 20, BK) + circle(140, 54, 20, BK) + ellipse(100, 94, 56, 48, WH, OL)
            + ellipse(80, 92, 13, 17, BK, ' transform="rotate(-20 80 92)"') + ellipse(120, 92, 13, 17, BK, ' transform="rotate(20 120 92)"')
            + circle(82, 90, 5, EYE_HI) + circle(118, 90, 5, EYE_HI) + ellipse(100, 110, 8, 6, BK) + smile(100, 116, 6))


# ---- vehicles ----------------------------------------------------------------
def wheel(x, y, r=17):
    return circle(x, y, r, BK) + circle(x, y, r * .45, "#B8B0A6")


@item
def car():
    return (path("M62 88 Q70 58 92 58 H124 Q140 58 148 88 Z", R) + rect(26, 84, 148, 56, R, 20)
            + path("M76 86 Q82 66 96 66 H104 V86 Z", "#CFE6F2") + path("M112 66 H122 Q134 66 138 86 H112 Z", "#CFE6F2")
            + wheel(62, 142) + wheel(138, 142) + circle(166, 104, 6, "#FFE9A8") + hl(50, 100, 14, 5, .35))


@item
def bus():
    wins = "".join(rect(x, 62, 26, 28, "#CFE6F2", 6) for x in (34, 68, 102))
    return (rect(22, 48, 156, 100, Y, 20) + wins + rect(138, 62, 28, 60, "#CFE6F2", 6)
            + rect(22, 104, 110, 10, darken(Y, .15)) + wheel(56, 150) + wheel(144, 150) + circle(170, 134, 5, O))


@item
def boat():  # symmetric about x = 100 (Mirror Match)
    return (line("M100 28 L100 128", STICK, 5)
            + path("M100 34 L150 118 L50 118 Z", WH, OL)
            + path("M36 128 H164 L142 160 Q100 170 58 160 Z", WH, OL)
            + rect(46, 136, 108, 8, R, 4))


@item
def train():
    return (rect(24, 86, 98, 56, G, 14) + rect(112, 50, 60, 92, darken(G, .12), 12) + rect(124, 62, 36, 30, "#CFE6F2", 6)
            + rect(40, 58, 20, 30, darken(G, .3), 6) + ellipse(50, 52, 16, 8, "#E8E2D8")
            + wheel(52, 148, 16) + wheel(92, 148, 16) + wheel(142, 148, 16) + rect(20, 132, 160, 8, darken(G, .35), 4))


@item
def plane():
    return (path("M78 100 L40 150 H62 L108 104 Z", WH, OL) + path("M78 96 L50 50 H70 L110 92 Z", WH, OL)
            + rect(24, 82, 160, 34, WH, 17) + rect(24, 82, 160, 34, "none", 17, OL)
            + path("M36 84 L22 52 H40 L60 84 Z", WH, OL) + "".join(circle(x, 96, 5, B) for x in (90, 110, 130, 150))
            + path("M166 86 Q182 99 166 112 Z", B))


@item
def bike():
    return (circle(52, 132, 34, "none", f' stroke="{INK}" stroke-width="7"') + circle(148, 132, 34, "none", f' stroke="{INK}" stroke-width="7"')
            + line("M52 132 L84 86 L128 86 L148 132 M84 86 L100 132 L128 86 M100 132 L52 132", B, 8)
            + line("M76 72 L94 72 M122 64 L138 60 M128 86 L124 64", INK, 7) + circle(100, 132, 7, INK))


# ---- toys --------------------------------------------------------------------
@item
def ball():
    return (circle(100, 100, 68, R) + line("M44 78 Q100 110 156 78", "#FFE9C9", 7) + line("M44 122 Q100 90 156 122", "#FFE9C9", 7, ' stroke-opacity="0.6"')
            + hl(74, 64, 12, 16))


@item
def block():  # the only "square" item: a face-on wooden block, not an ice cube
    return (rect(34, 34, 132, 132, darken(B, .18), 22) + rect(34, 34, 124, 124, B, 20)
            + rect(52, 52, 88, 88, mix(B, CARD, .25), 14) + sparkle(96, 96, 28, CARD, ' fill-opacity="0.9"'))


@item
def teddy():
    return bear() + path("M84 130 L100 138 L116 130 L116 146 L100 138 L84 146 Z", R) + circle(100, 138, 5, darken(R, .2))


@item
def drum():
    return (rect(36, 76, 128, 84, R, 16) + ellipse(100, 160, 64, 14, darken(R, .25)) + ellipse(100, 76, 64, 22, SKIN)
            + line("M42 96 L70 150 L100 96 L130 150 L158 96", CARD, 5)
            + line("M74 66 L50 26 M126 66 L150 26", STICK, 7) + circle(50, 26, 8, SKIN) + circle(150, 26, 8, SKIN))


@item
def kite():  # symmetric about x = 100 (Mirror Match); triangle per vocab
    bows = "".join(path(f"M92 {y} L100 {y + 6} L108 {y} L108 {y + 12} L100 {y + 6} L92 {y + 12} Z", P) for y in (150, 172))
    return (path("M100 24 L160 130 H40 Z", K, ' stroke="#EFA0B8" stroke-width="10" stroke-linejoin="round"')
            + line("M100 28 V128 M52 124 L148 124", darken(K, .25), 4) + path("M100 24 L130 78 H70 Z", mix(K, CARD, .35))
            + line("M100 130 V186", INK, 3, ' stroke-opacity="0.6"') + bows)


@item
def balloon():
    return (line("M100 150 Q88 166 100 178 Q112 190 100 196", INK, 3, ' stroke-opacity="0.6"')
            + path("M92 150 L108 150 L100 140 Z", darken(K, .2)) + ellipse(100, 84, 58, 66, K) + hl(78, 60, 10, 18, .6))


# ---- nature ------------------------------------------------------------------
@item
def sun():
    rays = "".join(f'<rect x="94" y="14" width="12" height="30" rx="6" fill="{O}" transform="rotate({a} 100 100)"/>' for a in range(0, 360, 45))
    return rays + circle(100, 100, 50, Y) + hl(82, 80, 10, 14, .5)


@item
def moon():  # a half moon: the "semicircle" in vocab
    craters = circle(118, 70, 10, "#E6DED2") + circle(130, 118, 14, "#E6DED2") + circle(108, 146, 7, "#E6DED2")
    return path("M96 28 A72 72 0 0 1 96 172 Z", WH, OL) + craters


@item
def star():
    return star5(100, 106, 72, 32, Y) + hl(84, 84, 8, 12, .5)


@item
def cloud():
    circs = [(66, 112, 36), (104, 92, 46), (140, 110, 34), (100, 126, 34)]
    return ("".join(circle(x, y, r + 4, "#CBBFB2") for x, y, r in circs)
            + rect(42, 110, 124, 40, "#CBBFB2", 20)
            + "".join(circle(x, y, r, WH) for x, y, r in circs) + rect(46, 112, 116, 34, WH, 17))


@item
def tree():  # triangle per vocab: a pine
    return (rect(90, 150, 20, 34, BR, 6) + rtri((100, 20), (150, 92), (50, 92), darken(G, .1), 14)
            + rtri((100, 50), (162, 130), (38, 130), G, 14) + rtri((100, 84), (172, 158), (28, 158), mix(G, Y, .15), 14))


@item
def flower():
    petals = "".join(circle(100 + 34 * __import__("math").cos(i * 1.0472), 80 + 34 * __import__("math").sin(i * 1.0472), 24, K) for i in range(6))
    return (line("M100 110 V188", G, 8) + path("M100 160 Q128 136 148 150 Q126 172 100 160 Z", G)
            + petals + circle(100, 80, 20, Y))


@item
def leaf():  # symmetric about x = 100 (Mirror Match)
    veins = line("M100 176 V40 M100 80 L76 64 M100 80 L124 64 M100 110 L70 92 M100 110 L130 92 M100 140 L76 124 M100 140 L124 124", darken(G, .3), 4)
    return path("M100 24 C152 58 152 138 100 176 C48 138 48 58 100 24 Z", G) + veins + line("M100 176 V190", darken(G, .3), 6)


@item
def rock():
    stone = mix(BR, "#8A8078", .45)
    return path("M34 148 C24 116 50 72 88 64 C122 56 162 78 170 116 C176 146 150 162 104 164 C68 166 40 162 34 148 Z", stone) + hl(80, 90, 18, 9, .3)


@item
def shell():  # semicircle scallop
    ribs = "".join(line(f"M100 150 L{100 + 66 * __import__('math').cos(a)} {150 - 66 * __import__('math').sin(a)}", darken(K, .2), 4)
                   for a in [i * 3.1416 / 8 for i in range(1, 8)])
    return (path("M34 150 A66 66 0 0 1 166 150 Z", K) + ribs + rect(82, 146, 36, 22, darken(K, .12), 8))


@item
def rainbow():
    arcs = "".join(f'<path d="M{100 - r} 150 A{r} {r} 0 0 1 {100 + r} 150" fill="none" stroke="{NAMED[c]}" stroke-width="14"/>'
                   for c, r in zip(("red", "orange", "yellow", "green", "blue", "purple"), (82, 68, 54, 40, 26, 12)))
    return arcs + "".join(circle(x, 154, 16, WH) + circle(x + 18 * s, 158, 12, WH) for x, s in ((20, 1), (180, -1)))


# ---- clothing ----------------------------------------------------------------
@item
def hat():  # semicircle dome
    return (ellipse(100, 140, 82, 18, darken(R, .2)) + path("M40 138 A60 60 0 0 1 160 138 Z", R)
            + rect(40, 120, 120, 16, "#FFE9C9") + hl(76, 96, 8, 14, .4))


@item
def shoe():
    return (path("M26 118 C26 90 50 80 66 84 C80 88 88 104 110 106 L160 112 C176 114 180 134 170 142 H26 Z", B)
            + rect(22, 136, 156, 20, CARD, 10) + line("M70 94 L84 104 M80 88 L94 100 M90 84 L104 96", CARD, 4))


@item
def sock():
    return (path("M64 22 H116 V112 C116 132 130 136 150 140 C174 144 176 176 150 180 H90 C68 180 64 162 64 140 Z", G)
            + rect(60, 18, 60, 30, mix(G, CARD, .45), 8) + line("M60 34 H120", darken(G, .2), 5)
            + path("M130 138 C156 138 172 150 164 172 C150 178 136 170 132 158 Z", darken(G, .2)))


@item
def scarf():
    fringe = "".join(line(f"M{x} 128 V148", darken(P, .2), 4) for x in range(132, 174, 8))
    return (path("M30 70 C70 56 120 84 170 70 L170 128 C120 142 70 114 30 128 Z", P)
            + line("M30 90 C70 76 120 104 170 90 M30 110 C70 96 120 124 170 110", mix(P, CARD, .4), 5)
            + fringe + "".join(line(f"M{x} 128 V148", darken(P, .2), 4) for x in range(34, 72, 8)))


@item
def umbrella():  # symmetric about x = 100 (Mirror Match); straight handle, no J hook
    return (line("M100 110 V176", STICK, 7) + circle(100, 178, 8, STICK)
            + path("M26 112 A74 74 0 0 1 174 112 Q155 98 137 112 Q118 98 100 112 Q82 98 63 112 Q45 98 26 112 Z", B)
            + line("M100 38 Q84 70 63 112 M100 38 Q116 70 137 112", darken(B, .22), 4) + circle(100, 36, 6, darken(B, .25)))


# ---- household ---------------------------------------------------------------
@item
def cup():
    return (path("M150 84 C182 84 182 128 146 128", "none", ' stroke="#4A3426" stroke-opacity="0.38" stroke-width="16" stroke-linecap="round"')
            + path("M150 84 C178 84 178 128 146 128", "none", f' stroke="{WH}" stroke-width="9" stroke-linecap="round"')
            + path("M40 64 H160 C160 128 136 162 100 162 C64 162 40 128 40 64 Z", WH, OL)
            + ellipse(100, 64, 60, 12, mix(WH, "#C9B79E", .4), OL) + rect(58, 96, 84, 8, B, 4))


@item
def spoon():  # a Chinese soup spoon, white
    return (path("M36 108 C36 80 62 70 88 76 L164 98 C178 102 178 118 164 120 L90 132 C62 138 36 132 36 108 Z", WH, OL)
            + ellipse(66, 106, 22, 16, mix(WH, "#C9B79E", .5)) + rect(120, 104, 30, 6, B, 3))


@item
def bowl():  # semicircle
    return (rect(78, 150, 44, 14, WH, 6) + rect(78, 150, 44, 14, "none", 6, OL)
            + path("M30 84 H170 A70 70 0 0 1 30 84 Z", WH, OL) + rect(44, 104, 112, 10, B, 5)
            + ellipse(100, 84, 70, 12, mix(WH, "#C9B79E", .45), OL))


@item
def key():
    return (circle(60, 100, 34, Y) + circle(60, 100, 14, CARD) + rect(88, 90, 86, 20, Y, 8)
            + rect(140, 108, 14, 24, Y, 4) + rect(162, 108, 12, 18, Y, 4) + hl(46, 80, 6, 9, .5))


@item
def book():
    return (rect(38, 30, 124, 144, CARD, 12, OL) + rect(30, 26, 124, 144, B, 14) + rect(30, 26, 18, 144, darken(B, .2), 8)
            + rect(66, 58, 70, 12, mix(B, CARD, .5), 6) + rect(66, 80, 50, 10, mix(B, CARD, .5), 5))


@item
def lamp():  # triangle shade per vocab
    return (circle(100, 96, 70, Y, ' fill-opacity="0.18"') + rect(92, 112, 16, 50, STICK, 6) + ellipse(100, 170, 44, 12, STICK)
            + rtri((100, 30), (148, 116), (52, 116), Y, 12) + hl(84, 80, 6, 18, .35))


@item
def clock():
    ticks = "".join(f'<rect x="97" y="42" width="6" height="12" rx="3" fill="{INK}" fill-opacity="0.5" transform="rotate({a} 100 104)"/>'
                    for a in range(0, 360, 90))
    return (circle(100, 104, 70, WH, OL) + ticks + line("M100 104 L100 66 M100 104 L128 118", INK, 7) + circle(100, 104, 7, R))


@item
def pillow():
    return (path("M28 60 Q40 50 100 56 Q160 50 172 60 Q180 100 172 140 Q160 152 100 146 Q40 152 28 140 Q20 100 28 60 Z", K)
            + line("M50 80 Q100 70 150 80", mix(K, CARD, .45), 5))


@item
def toothbrush():
    bristles = "".join(rect(x, 70, 7, 24, CARD, 3, ' stroke="#4A3426" stroke-opacity="0.3" stroke-width="2"') for x in range(126, 174, 10))
    return (rect(18, 94, 160, 22, G, 11) + rect(118, 88, 60, 12, G, 6) + bristles + hl(50, 100, 22, 4, .5))


@item
def key_lantern():
    return lantern_g(O, "lit", 34, 14, 1.1)


# ---- v3 additions (E2 vocab, added to vocab.json by the app session) -----------
SKIN_T = "#F1C6A0"
FACE = "#F9DDB8"
HAIR, GREY_HAIR = "#3B3533", "#C9C4BE"


@item
def gift():  # square
    return (rect(36, 44, 128, 128, R, 14) + rect(90, 44, 20, 128, "#FFE9A8") + rect(36, 98, 128, 20, "#FFE9A8")
            + path("M100 44 C80 14 52 20 64 40 C70 48 90 46 100 44 Z", "#FFE9A8") + path("M100 44 C120 14 148 20 136 40 C130 48 110 46 100 44 Z", "#FFE9A8")
            + hl(56, 64, 8, 12, .35))


@item
def window():  # square
    return (rect(30, 30, 140, 140, STICK, 12) + rect(42, 42, 116, 116, B, 6)
            + rect(94, 42, 12, 116, STICK) + rect(42, 94, 116, 12, STICK)
            + path("M52 52 L80 52 L52 80 Z", CARD, ' fill-opacity="0.5"') + path("M116 116 L134 116 L116 134 Z", CARD, ' fill-opacity="0.35"'))


def face(extra):
    return circle(100, 104, 72, FACE, OL) + extra


@item
def happy():
    return face(line("M68 92 Q78 80 88 92 M112 92 Q122 80 132 92", EYE, 6) + path("M68 116 Q100 158 132 116 Z", "#C8643B")
                + path("M84 132 Q100 146 116 132 Q100 138 84 132 Z", "#F28A8A") + cheeks(60, 140, 118, 11))


@item
def sad():
    return face(eyes(80, 120, 96, 7) + line("M72 80 L88 74 M128 80 L112 74", EYE, 4)
                + line("M78 140 Q100 122 122 140", EYE, 5) + path("M128 108 Q138 126 128 132 Q118 126 128 108 Z", B))


@item
def angry():
    return face(eyes(80, 120, 100, 7) + line("M66 80 L92 90 M134 80 L108 90", EYE, 6)
                + line("M80 138 Q100 128 120 138", EYE, 5) + cheeks(60, 140, 122, 13).replace('0.35', '0.55'))


@item
def scared():
    return face(circle(80, 96, 13, CARD) + circle(120, 96, 13, CARD) + circle(80, 97, 5, EYE) + circle(120, 97, 5, EYE)
                + line("M68 72 L90 78 M132 72 L110 78", EYE, 4)
                + line("M76 136 Q84 128 92 136 Q100 144 108 136 Q116 128 124 136", EYE, 5))


@item
def surprised():
    return face(circle(80, 92, 12, CARD) + circle(120, 92, 12, CARD) + circle(80, 92, 6, EYE) + circle(120, 92, 6, EYE)
                + line("M68 68 Q80 60 92 68 M108 68 Q120 60 132 68", EYE, 4) + ellipse(100, 136, 14, 18, "#C8643B"))


@item
def sleepy():
    return face(line("M68 98 Q80 108 92 98 M108 98 Q120 108 132 98", EYE, 6) + ellipse(100, 134, 10, 7, "#C8643B")
                + line("M142 40 H160 L142 58 H160 M164 18 H176 L164 30 H176", "#75594A", 5) + cheeks(62, 138, 118, 10))


@item
def mooncake():
    petals = "".join(circle(100 + 60 * __import__("math").cos(a / 8 * 6.2832), 104 + 60 * __import__("math").sin(a / 8 * 6.2832), 18, "#C98B4E") for a in range(8))
    return (petals + circle(100, 104, 62, "#D69A5A") + circle(100, 104, 42, "none", ' stroke="#A86B34" stroke-width="5"')
            + sparkle(100, 104, 22, "#A86B34") + hl(76, 78, 10, 7, .3))


@item
def dumpling():  # semicircle, white
    pleats = line("M56 96 Q64 84 72 92 M78 86 Q86 74 94 84 M100 82 Q108 70 116 82 M122 86 Q130 76 138 90", "#4A3426", 3.5, ' stroke-opacity="0.35"')
    return path("M28 128 C28 60 172 60 172 128 Q100 148 28 128 Z", WH, OL) + pleats + hl(64, 112, 14, 6, .6)


@item
def red_envelope():  # rectangle
    return (rect(50, 22, 100, 156, R, 12) + path("M50 34 L100 78 L150 34", darken(R, .22), ' stroke="#9E3B33" stroke-width="5" fill-opacity="0"')
            + circle(100, 82, 18, "#F2CC4A") + rect(92, 76, 16, 12, "#E8A93C", 3) + rect(66, 120, 68, 8, "#F2CC4A", 4))


@item
def dragon_boat():
    scales = "".join(path(f"M{x} 124 Q{x + 9} 114 {x + 18} 124", "none", f' stroke="{darken(G, .3)}" stroke-width="4"') for x in range(44, 150, 18))
    return (path("M22 118 H160 C170 142 150 158 120 158 H60 C36 158 24 142 22 118 Z", G) + scales
            + rect(30, 112, 132, 10, darken(G, .3), 5)
            + path("M150 118 C152 86 166 70 184 74 C190 88 180 102 168 104 L166 118 Z", G) + circle(174, 84, 4, EYE)
            + path("M154 88 L140 70 L160 80 L150 60 L166 76 Z", O) + path("M24 118 C10 104 16 86 30 88 C24 98 30 108 36 116 Z", O)
            + ellipse(96, 104, 16, 12, R) + ellipse(96, 98, 16, 5, SKIN))


@item
def candle():  # rectangle, yellow
    return (ellipse(100, 44, 22, 34, "#F2CC4A", ' fill-opacity="0.25"') + path("M100 20 C112 36 110 52 100 58 C90 52 88 36 100 20 Z", O)
            + path("M100 34 C106 42 105 50 100 54 C95 50 94 42 100 34 Z", "#FFE9A8") + line("M100 58 V68", INK, 3)
            + rect(78, 68, 44, 112, Y, 10) + path("M78 84 Q90 98 96 84 Q104 104 110 84 Q116 96 122 84 V78 H78 Z", mix(Y, CARD, .45)))


@item
def cake():  # circle-ish round cake, pink
    return (ellipse(100, 156, 72, 18, darken(K, .2)) + rect(28, 92, 144, 64, K) + ellipse(100, 92, 72, 20, mix(K, CARD, .55))
            + path("M28 92 Q40 116 52 96 Q64 120 76 98 Q88 122 100 98 Q112 122 124 98 Q136 120 148 96 Q160 116 172 92 Z", mix(K, CARD, .55))
            + "".join(circle(x, 84, 9, R) for x in (70, 100, 130)) + "".join(line(f"M{x} 70 V58", "#F2CC4A", 6) for x in (86, 114)))


def person(hair_back, hair_front, top, extra="", head_r=44, skin=SKIN_T, cy=88):
    return (path("M40 190 C40 150 64 136 100 136 C136 136 160 150 160 190 Z", top) + hair_back
            + circle(100, cy, head_r, skin) + hair_front
            + eyes(84, 116, cy + 4, 5.5) + smile(100, cy + 22, 9) + cheeks(72, 128, cy + 18, 8) + extra)


@item
def mom():
    return person(path("M52 90 C52 40 148 40 148 90 L152 150 H48 Z", HAIR),
                  path("M58 84 C60 50 140 50 142 84 C120 64 84 62 58 84 Z", HAIR), K)


@item
def dad():
    return person("", path("M58 80 C58 40 142 40 142 80 C130 60 70 60 58 80 Z", HAIR), B)


def glasses(cy):
    return circle(84, cy + 4, 12, "none", f' stroke="{INK}" stroke-width="3.5"') + circle(116, cy + 4, 12, "none", f' stroke="{INK}" stroke-width="3.5"') + line(f"M96 {cy + 4} H104", INK, 3.5)


@item
def grandma():
    return person(circle(100, 38, 22, GREY_HAIR), path("M56 84 C58 46 142 46 144 84 C124 66 76 66 56 84 Z", GREY_HAIR), P, glasses(88))


@item
def grandpa():
    return person("", path("M58 72 C62 50 80 44 88 50 M112 50 C120 44 138 50 142 72", "none", f' stroke="{GREY_HAIR}" stroke-width="12" stroke-linecap="round"'),
                  G, glasses(88) + line("M84 124 Q100 118 116 124", GREY_HAIR, 6))


@item
def baby():
    return (path("M56 190 C56 158 74 148 100 148 C126 148 144 158 144 190 Z", Y) + circle(100, 104, 50, SKIN_T)
            + line("M100 56 Q108 44 98 40", HAIR, 5) + eyes(84, 116, 104, 5) + smile(100, 124, 7) + cheeks(70, 130, 120, 9))


@item
def sister():
    return person(circle(48, 96, 16, HAIR) + circle(152, 96, 16, HAIR) + line("M54 90 L60 92 M146 90 L140 92", R, 6),
                  path("M58 84 C58 48 142 48 142 84 C122 62 78 62 58 84 Z", HAIR), O, head_r=40)


@item
def brother():
    return person("", path("M60 80 L66 52 L80 64 L90 44 L100 60 L110 44 L120 64 L134 52 L140 80 C120 66 80 66 60 80 Z", HAIR), R, head_r=40)


@item
def hand():
    fingers = "".join(rect(x, y, 22, 64, SKIN_T, 11) for x, y in ((56, 40), (82, 28), (108, 32), (134, 50)))
    return (fingers + rect(52, 82, 106, 86, SKIN_T, 34)
            + f'<rect x="26" y="96" width="22" height="58" rx="11" fill="{SKIN_T}" transform="rotate(-38 37 125)"/>'
            + line("M84 124 Q104 132 124 124", darken(SKIN_T, .15), 4))


@item
def foot():
    toes = "".join(circle(x, y, r, SKIN_T) for x, y, r in ((70, 46, 13), (94, 40, 11), (114, 42, 10), (132, 48, 9), (146, 58, 8)))
    return toes + path("M58 68 C74 56 150 58 152 84 C154 118 136 128 130 150 C124 176 72 180 64 150 C58 124 44 90 58 68 Z", SKIN_T)


@item
def eye():
    return (path("M24 100 C60 50 140 50 176 100 C140 150 60 150 24 100 Z", CARD, OL) + circle(100, 100, 32, "#8C5A3A")
            + circle(100, 100, 15, EYE) + circle(110, 90, 7, EYE_HI)
            + line("M52 72 L44 60 M76 58 L72 44 M100 54 V40 M124 58 L128 44 M148 72 L156 60", EYE, 4))


@item
def ear():
    return (path("M76 40 C130 20 168 70 146 118 C136 140 118 146 112 164 C106 184 76 184 72 164", SKIN_T,
                 f' stroke="{darken(SKIN_T, .12)}" stroke-width="4"')
            + line("M96 72 C124 60 140 90 124 112 C114 124 104 120 104 136", darken(SKIN_T, .2), 7))


@item
def nose():
    return (circle(100, 106, 70, FACE, OL) + path("M100 56 C96 90 76 110 78 126 C80 140 92 142 100 138 C108 142 120 140 122 126 C124 110 104 90 100 56 Z", darken(FACE, .08))
            + ellipse(88, 130, 7, 5, darken(FACE, .3)) + ellipse(112, 130, 7, 5, darken(FACE, .3)))


@item
def mouth():
    return (path("M30 96 C60 80 80 92 100 88 C120 92 140 80 170 96 C150 150 50 150 30 96 Z", "#D9534A")
            + path("M42 100 C70 96 130 96 158 100 C150 112 50 112 42 100 Z", CARD) + path("M70 132 Q100 118 130 132 Q100 146 70 132 Z", "#F28A8A"))


def main():
    for name, fn in ITEMS.items():
        with open(os.path.join(OUT, f"{name}.svg"), "w", encoding="utf-8") as fh:
            fh.write(svg(200, 200, fn()))
    print(len(ITEMS), "items")


if __name__ == "__main__":
    main()
