#!/usr/bin/env python3
"""Logo: the lantern mark, plus lockups. Output: design/svg/brand/*.svg -> design/png/brand/.

The mark is Yun's paper lantern with a small lit window in the shape of a red panda's
face — the story in one shape. It survives at 24 px (the mark alone), so it works as a
favicon, a store badge and the top-left of the landing page.

Wordmarks are set in the app's own bundled faces (Fredoka for English, ZCOOL KuaiLe for
中文) and rendered to outlines by render.py, so nothing depends on a font at use time.
"""
import os

from gen_assets import CARD, INK, LANTERN, NAMED, RUST, RUST_DEEP, STICK, circle, darken, ellipse, mix, rect, sparkle, svg

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg", "brand")
os.makedirs(OUT, exist_ok=True)

FUR, FUR_DARK, YCREAM, EYE = "#C65F32", "#7A3419", "#FFEBD1", "#3A2418"
NIGHT = "#3A3D6B"


def panda_face(cx, cy, r, fur=FUR, cream=YCREAM, eye=EYE):
    """Yun's face, simplified to read at small sizes."""
    o = []
    for dx in (-1, 1):
        o.append(circle(cx + dx * r * 0.82, cy - r * 0.52, r * 0.42, fur))
        o.append(circle(cx + dx * r * 0.82, cy - r * 0.52, r * 0.2, cream))
    o.append(ellipse(cx, cy, r * 1.02, r * 0.86, fur))
    o.append(ellipse(cx, cy + r * 0.3, r * 0.44, r * 0.32, cream))
    for dx in (-1, 1):
        o.append(ellipse(cx + dx * r * 0.62, cy + r * 0.22, r * 0.24, r * 0.24, cream))
        o.append(ellipse(cx + dx * r * 0.36, cy + r * 0.2, r * 0.1, r * 0.2, "#9A4524"))
        o.append(circle(cx + dx * r * 0.36, cy - r * 0.16, r * 0.15, eye))
    o.append(ellipse(cx, cy + r * 0.22, r * 0.13, r * 0.09, eye))
    return "".join(o)


def mark(size=200, night=False):
    """The lantern with Yun's face glowing inside it."""
    s = size / 200
    body = LANTERN
    cap = STICK if not night else "#8A6A44"
    o = [f'<g transform="scale({s:.4f})">']
    if night:
        for r, t in ((96, .10), (80, .16), (64, .26)):
            o.append(circle(100, 108, r, mix(NIGHT, LANTERN, t)))
    # hanger + cap
    o.append(f'<path d="M100 8 V26" fill="none" stroke="{cap}" stroke-width="7" stroke-linecap="round"/>')
    o.append(rect(66, 22, 68, 18, cap, 7))
    # paper body
    o.append(rect(34, 36, 132, 144, body, 56))
    o.append(rect(34, 36, 132, 144, "none", 56, f' stroke="{darken(body, .22)}" stroke-width="4"'))
    # the lit window: a rounded arch holding Yun's face
    o.append(rect(56, 58, 88, 100, CARD, 40))
    o.append(panda_face(100, 108, 30))
    # ribs left and right of the window
    o.append(f'<path d="M46 64 Q38 108 46 152 M154 64 Q162 108 154 152" fill="none" stroke="{darken(body, .28)}" stroke-width="5" stroke-linecap="round"/>')
    o.append(rect(66, 172, 68, 18, cap, 7))
    o.append(rect(90, 188, 20, 12, RUST_DEEP, 5))
    o.append("</g>")
    return "".join(o)


FRED = "Fredoka, 'Noto Sans SC', sans-serif"
ZCOOL = "'ZCOOL KuaiLe', 'Noto Sans SC', sans-serif"


def text(x, y, s, size, fill, family=FRED, weight=600, anchor="start"):
    return (f'<text x="{x}" y="{y}" font-family="{family}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}" text-anchor="{anchor}">{s}</text>')


def horizontal(night=False):
    ink = CARD if night else INK
    sub = "#D9D4CC" if night else "#75594A"
    zh = LANTERN if night else RUST_DEEP
    bg = rect(0, 0, 900, 260, NIGHT) if night else ""
    return svg(900, 260, bg + f'<g transform="translate(30 30)">{mark(200, night)}</g>'
               + text(272, 118, "Yun's Lantern", 76, ink)
               + text(276, 186, "小云的灯笼", 60, zh, ZCOOL, 400)
               + text(278, 228, "Mandarin and English for ages 3–5", 24, sub, FRED, 500))


def stacked(night=False):
    ink = CARD if night else INK
    zh = LANTERN if night else RUST_DEEP
    bg = rect(0, 0, 520, 560, NIGHT) if night else ""
    return svg(520, 560, bg + f'<g transform="translate(160 26)">{mark(200, night)}</g>'
               + text(260, 320, "Yun's Lantern", 62, ink, FRED, 600, "middle")
               + text(260, 392, "小云的灯笼", 56, zh, ZCOOL, 400, "middle")
               + text(260, 444, "Mandarin and English for ages 3–5", 22, "#D9D4CC" if night else "#75594A", FRED, 500, "middle"))


def mark_only(night=False):
    bg = rect(0, 0, 240, 240, NIGHT, 54) if night else ""
    return svg(240, 240, bg + f'<g transform="translate(20 20)">{mark(200, night)}</g>')


def favicon():
    """Simplified for 32 px and below: no window arch, no ribs."""
    o = [rect(2, 8, 60, 52, LANTERN, 22), rect(14, 2, 36, 10, STICK, 5), rect(14, 56, 36, 10, STICK, 5),
         rect(22, 16, 20, 36, CARD, 10)]
    o.append(panda_face(32, 34, 11))
    return svg(64, 68, "".join(o))


def wordmark_en():
    return svg(700, 130, text(10, 96, "Yun's Lantern", 88, INK))


def wordmark_zh():
    return svg(560, 140, text(10, 104, "小云的灯笼", 96, RUST_DEEP, ZCOOL, 400))


def main():
    files = {
        "logo_horizontal.svg": horizontal(), "logo_horizontal_night.svg": horizontal(True),
        "logo_stacked.svg": stacked(), "logo_stacked_night.svg": stacked(True),
        "logo_mark.svg": mark_only(), "logo_mark_night.svg": mark_only(True),
        "wordmark_en.svg": wordmark_en(), "wordmark_zh.svg": wordmark_zh(), "favicon_mark.svg": favicon(),
    }
    for name, body in files.items():
        with open(os.path.join(OUT, name), "w", encoding="utf-8") as fh:
            fh.write(body)
    print(len(files), "brand files")


if __name__ == "__main__":
    main()
