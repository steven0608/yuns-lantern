"""Render the SVG assets to PNG (for the Flutter app) and a contact sheet (for review)."""
import os
import sys
from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "svg")
PNG = os.path.join(HERE, "png")
os.makedirs(PNG, exist_ok=True)

# name -> list of (output file, width px). Height follows the SVG's aspect.
JOBS = {
    "app_icon.svg": [("app_icon_1024.png", 1024), ("Icon-512.png", 512), ("Icon-192.png", 192), ("favicon.png", 32)],
    "yun_idle.svg": [("yun_idle.png", 440)], "yun_happy.svg": [("yun_happy.png", 440)],
    "yun_sleepy.svg": [("yun_sleepy.png", 440)],
    "apple.svg": [("items/apple.png", 256)], "bear.svg": [("items/bear.png", 256)],
    "basket.svg": [("items/basket.png", 256)], "light_white.svg": [("items/key_lantern.png", 192)],
}
for f in os.listdir(SRC):
    if f.startswith(("icon_", "light_")):
        JOBS.setdefault(f, []).append((f.replace(".svg", ".png"), 320 if f.startswith("icon_") else 240))
    if f.startswith("scene_") or f in ("map.svg", "home_bg.svg"):
        JOBS.setdefault(f, []).append((f.replace(".svg", ".png"), 2388))


def main(sheet_only=False):
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        if not sheet_only:
            for name, outs in JOBS.items():
                svg = open(os.path.join(SRC, name), encoding="utf-8").read()
                for out, wpx in outs:
                    html = (f"<html><body style='margin:0;background:transparent'>"
                            f"<img id=i src='data:image/svg+xml;charset=utf-8,{svg.replace('#', '%23')}' style='width:{wpx}px;display:block'>"
                            "</body></html>")
                    pg.set_content(html)
                    pg.wait_for_function("document.getElementById('i').complete")
                    el = pg.query_selector("#i")
                    dest = os.path.join(PNG, out)
                    os.makedirs(os.path.dirname(dest), exist_ok=True)
                    el.screenshot(path=dest, omit_background=not out.startswith(("app_icon", "Icon-", "favicon")))
        # contact sheet
        files = sorted(os.listdir(SRC))
        cells = "".join(
            f"<figure style='margin:0;display:flex;flex-direction:column;gap:4px;align-items:center'>"
            f"<img src='file:///{os.path.join(SRC, f).replace(os.sep, '/')}' style='height:{220 if f.startswith(('scene_', 'map', 'home_bg')) else 150}px'>"
            f"<figcaption style='font:12px sans-serif'>{f}</figcaption></figure>" for f in files)
        pg.set_viewport_size({"width": 1800, "height": 800})
        sheet = os.path.join(HERE, "png", "contact.html")
        with open(sheet, "w", encoding="utf-8") as fh:
            fh.write(f"<body style='margin:16px;background:#FBF1E1;display:flex;flex-wrap:wrap;gap:16px'>{cells}</body>")
        pg.goto("file:///" + sheet.replace(os.sep, "/"))
        pg.wait_for_timeout(600)
        pg.screenshot(path=os.path.join(HERE, "png", "contact.png"), full_page=True)
        b.close()


if __name__ == "__main__":
    main(sheet_only="--sheet" in sys.argv)
