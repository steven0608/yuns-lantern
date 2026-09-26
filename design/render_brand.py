#!/usr/bin/env python3
"""Render design/svg/brand/*.svg to design/png/brand/*.png.

Separate from render.py because the wordmarks use <text>: the SVG is inlined into a
page that loads the fonts, so the type renders. The published PNGs are what the app,
the landing page and the store use, so nothing depends on a font at use time.
"""
import os
import re

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
SRC, OUT = os.path.join(HERE, "svg", "brand"), os.path.join(HERE, "png", "brand")
os.makedirs(OUT, exist_ok=True)
FONTS = ("https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600"
         "&family=ZCOOL+KuaiLe&family=Noto+Sans+SC:wght@400;500&display=swap")
# export scale per file (mark and favicon need to survive being shrunk)
SCALE = {"logo_horizontal": 2, "logo_horizontal_night": 2, "logo_stacked": 2, "logo_stacked_night": 2,
         "logo_mark": 4, "logo_mark_night": 4, "wordmark_en": 2, "wordmark_zh": 2, "favicon_mark": 8}
# logo_mark_night has rounded corners, so it stays transparent outside them
OPAQUE = {"logo_horizontal_night", "logo_stacked_night"}


def main():
    with sync_playwright() as pw:
        b = pw.chromium.launch()
        pg = b.new_page(viewport={"width": 2400, "height": 1400})
        for f in sorted(os.listdir(SRC)):
            name = f[:-4]
            s = open(os.path.join(SRC, f), encoding="utf-8").read()
            w = float(re.search(r'width="([\d.]+)"', s).group(1))
            h = float(re.search(r'height="([\d.]+)"', s).group(1))
            k = SCALE[name]
            svg = s.replace("<svg ", f'<svg style="width:{w * k}px;height:{h * k}px;display:block" ', 1)
            pg.set_content(f"<html><head><link rel='stylesheet' href='{FONTS}'></head>"
                           f"<body style='margin:0;background:transparent'>"
                           f"<div id='w' style='width:{w * k}px;height:{h * k}px'>{svg}</div></body></html>")
            pg.wait_for_load_state("networkidle")
            pg.evaluate("document.fonts.ready")
            pg.wait_for_timeout(250)
            pg.query_selector("#w").screenshot(path=os.path.join(OUT, name + ".png"),
                                               omit_background=name not in OPAQUE)
        b.close()
    print(len(os.listdir(OUT)), "brand PNGs")


if __name__ == "__main__":
    main()
