#!/usr/bin/env python3
"""Marketing screenshots built from the design assets: design/png/shots/*.png.

These are design mockups for the landing page, matching the canvas boards. The App Store
screenshots and the app preview video must be captured from the real app (Apple's rule).
"""
import os

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
PNG = "."   # the page is written into design/png/, so assets resolve relatively
OUT = os.path.join(HERE, "png", "shots")
os.makedirs(OUT, exist_ok=True)
W, H = 1194, 834
FONTS = ("https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600"
         "&family=ZCOOL+KuaiLe&family=Noto+Sans+SC:wght@400;500&display=swap")

SHADOW = "box-shadow:0 7px 0 rgba(74,52,38,.16)"
BOOK = ('<svg viewBox="0 0 120 92" width="132" height="101" aria-hidden="true">'
        '<path d="M60 18 C44 8 22 8 8 14 V82 C22 76 44 76 60 86 Z" fill="#FFF8EC"></path>'
        '<path d="M60 18 C76 8 98 8 112 14 V82 C98 76 76 76 60 86 Z" fill="#FFF8EC"></path>'
        '<path d="M20 32 H48 M20 44 H44 M20 56 H48 M72 32 H100 M72 44 H96" stroke="#E0CDB0" stroke-width="4" stroke-linecap="round"></path>'
        '<path d="M8 14 V82 C22 76 44 76 60 86 C76 76 98 76 112 82 V14" fill="none" stroke="#9E4726" stroke-width="5" stroke-linejoin="round"></path>'
        '<path d="M60 18 V86" stroke="#9E4726" stroke-width="4"></path>'
        '<path d="M92 50 Q93.5 58 100 60 Q93.5 62 92 70 Q90.5 62 84 60 Q90.5 58 92 50 Z" fill="#E8A93C"></path></svg>')

STOPS = [(150, 700), (330, 592), (520, 668), (660, 495), (470, 385), (640, 262), (860, 330), (1010, 150)]
LIGHTS = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "white"]


def home():
    doors = ""
    for i, (label, bg, inner) in enumerate([
        ("Story", "#3A3D6B", f'<img src="{PNG}/light_white.png" style="width:106px">'),
        ("Play", "#DDEBD2",
         f'<div style="position:relative;width:172px;height:136px">'
         f'<img src="{PNG}/lands/count_feed.png" style="position:absolute;left:0;top:22px;width:88px;transform:rotate(-8deg)">'
         f'<img src="{PNG}/lands/music_echo.png" style="position:absolute;right:0;top:22px;width:88px;transform:rotate(8deg)">'
         f'<img src="{PNG}/lands/sort_bins.png" style="position:absolute;left:42px;top:0;width:92px"></div>'),
        ("Books", "#F6D8C8", BOOK)]):
        doors += (f'<div style="position:absolute;left:{353 + i * 292}px;top:250px;width:220px;height:220px;border-radius:110px;'
                  f'background:{bg};display:flex;align-items:center;justify-content:center;{SHADOW}">{inner}</div>')
    return (f'<img src="{PNG}/home_bg.png" style="position:absolute;inset:0;width:{W}px;height:{H}px">'
            + doors
            + f'<img src="{PNG}/yun_happy.png" style="position:absolute;left:40px;top:420px;width:250px">'
            + '<div style="position:absolute;right:24px;top:24px;height:52px;padding:0 18px 0 14px;border-radius:26px;'
              'background:rgba(255,248,236,.92);box-shadow:inset 0 0 0 1.5px #E0CDB0;display:flex;align-items:center;gap:8px;'
              'font-family:Fredoka,sans-serif;font-weight:500;font-size:16px;color:#4A3426">'
              '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4A3426" stroke-width="2" stroke-linecap="round">'
              '<circle cx="9" cy="8" r="3"></circle><path d="M3.5 19a5.5 5.5 0 0 1 11 0"></path><circle cx="17" cy="9.5" r="2.3"></circle>'
              '<path d="M15.6 14.3A4.5 4.5 0 0 1 21 18.5"></path></svg>For grown-ups</div>')


def game_map():
    o = [f'<img src="{PNG}/map.png" style="position:absolute;inset:0;width:{W}px;height:{H}px">']
    for i, (x, y) in enumerate(STOPS):
        big = i == 7
        d = 124 if big else 104
        lw = 80 if big else 66
        if i < 3:                                   # found
            src, extra = f"{PNG}/light_{LIGHTS[i]}.png", ""
        elif i == 3:                                # current
            src = f"{PNG}/light_unlit.png"
            extra = "background:rgba(255,248,236,.92);box-shadow:0 0 0 8px rgba(232,169,60,.38),0 0 0 20px rgba(232,169,60,.16);"
        else:                                       # not reached: misty
            src, extra = f"{PNG}/light_misty.png", "opacity:.9;"
        o.append(f'<div style="position:absolute;left:{x - d // 2}px;top:{y - d // 2}px;width:{d}px;height:{d}px;border-radius:{d // 2}px;'
                 f'{extra}display:flex;align-items:center;justify-content:center"><img src="{src}" style="width:{lw}px"></div>')
    o.append(f'<img src="{PNG}/yun_idle.png" style="position:absolute;left:{STOPS[3][0] + 50}px;top:{STOPS[3][1] - 96}px;width:110px">')
    o.append('<div style="position:absolute;left:24px;top:24px;width:88px;height:88px;border-radius:44px;background:#FFF8EC;'
             f'{SHADOW};display:flex;align-items:center;justify-content:center">'
             '<svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#4A3426" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">'
             '<path d="M4 11.5 12 5l8 6.5"></path><path d="M6.5 10v8.5a1 1 0 0 0 1 1H10v-5h4v5h2.5a1 1 0 0 0 1-1V10"></path></svg></div>')
    return "".join(o)


def reader():
    return (f'<img src="{PNG}/scene_orchard.png" style="position:absolute;inset:0;width:{W}px;height:{H}px">'
            f'<img src="{PNG}/characters/bear_basket.png" style="position:absolute;left:620px;top:250px;width:380px">'
            + "".join(f'<img src="{PNG}/items/apple.png" style="position:absolute;left:{710 + i * 42}px;top:494px;width:44px">' for i in range(3))
            + '<div style="position:absolute;left:0;right:0;bottom:0;height:150px;padding:24px 124px;background:rgba(255,248,236,.94);'
              'display:flex;flex-direction:column;justify-content:center;gap:8px">'
              '<p style="margin:0;font-family:Fredoka,sans-serif;font-weight:500;font-size:30px;color:#4A3426">Two apples, three apples. Bear counts each one.</p>'
              '<p style="margin:0;font-size:28px;color:#9E4726">两个苹果，三个苹果。小熊一个一个地数。</p></div>')


SHOTS = {"home": home, "map": game_map, "reader": reader}


def main():
    tmp = os.path.join(HERE, "png", "_shot.html")
    with sync_playwright() as pw:
        b = pw.chromium.launch()
        pg = b.new_page(viewport={"width": W, "height": H}, device_scale_factor=2)
        for name, fn in SHOTS.items():
            # written into design/png/ so the file:// page can load the art next to it
            with open(tmp, "w", encoding="utf-8") as fh:
                fh.write(f"<html><head><meta charset='utf-8'><link rel='stylesheet' href='{FONTS}'></head>"
                         f"<body style='margin:0'><div id='s' style='position:relative;width:{W}px;height:{H}px;overflow:hidden;"
                         f"background:#FBF1E1;font-family:\"Noto Sans SC\",sans-serif'>{fn()}</div></body></html>")
            pg.goto("file:///" + tmp.replace(os.sep, "/"))
            pg.wait_for_load_state("networkidle")
            pg.evaluate("document.fonts.ready")
            pg.wait_for_timeout(300)
            assert pg.evaluate("[...document.images].every(i => i.complete && i.naturalWidth > 0)"), f"{name}: an image failed to load"
            pg.query_selector("#s").screenshot(path=os.path.join(OUT, f"{name}.png"))
        b.close()
    os.remove(tmp)
    print(sorted(os.listdir(OUT)))


if __name__ == "__main__":
    main()
