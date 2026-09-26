#!/usr/bin/env python3
"""Tale covers (75) and the page-art template, from content/library.json.

    python design/gen_tale_art.py      # -> design/png/tales/<tale_id>/cover.png and p<N>.png

Covers are generated: a theme-coloured sky and ground, a scene band built from the
tale's own vocabulary, and the bilingual title. They ship as real art.

Page art is a TEMPLATE: each page gets a staged still (sky, ground, the vocab items
the page text mentions, placed on a 3-band layout) so every tale is readable before an
illustrator touches it. The illustrator replaces p<N>.png one file at a time; nothing
else changes. Important content stays inside the central 1194 x 560 band so the iPhone
crop only loses sky and ground (design/HANDOFF.md §1.5).
"""
import json
import os
import re

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PNG = os.path.join(HERE, "png")
OUT = os.path.join(PNG, "tales")
W, H = 1194, 834
SAFE_TOP, SAFE_H = 137, 560          # the band an iPhone crop keeps
FONTS = ("https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600"
         "&family=ZCOOL+KuaiLe&family=Noto+Sans+SC:wght@400;500;700&display=swap")

lib = json.load(open(os.path.join(ROOT, "content", "library.json"), encoding="utf-8"))
vocab = json.load(open(os.path.join(ROOT, "content", "vocab.json"), encoding="utf-8"))["items"]

# theme -> (sky, ground, accent) — warm by day, deep by night, from the app palette
THEME = {
    "numbers": ("#F7D9A8", "#9CC77E", "#D9534A"), "shapes_colors": ("#F5C9A0", "#D9B98C", "#5B9BD5"),
    "sizes": ("#F1E2C6", "#A7B98C", "#C8643B"), "patterns_order": ("#4A4A7A", "#6F8F6A", "#9B76C4"),
    "position": ("#C9D3CB", "#7E9C7A", "#4F8FB0"), "nature": ("#CFE3E8", "#7FB7C9", "#79B45A"),
    "animals": ("#E8E0CE", "#9CC77E", "#9C6B45"), "science": ("#D6E2F0", "#A7B98C", "#4F8FB0"),
    "feelings": ("#F2D0D8", "#8FB9D6", "#EFA0B8"), "routines": ("#FBEFD6", "#D9B98C", "#E8A93C"),
    "festivals": ("#3A3D6B", "#5B6B4E", "#D9534A"), "words": ("#F5DFC0", "#9CC77E", "#9B76C4"),
    "family": ("#FBEFD6", "#9CC77E", "#C8643B"), "music": ("#E4DAEE", "#8DB86B", "#9B76C4"),
    "kindness": ("#F7D9A8", "#8DB86B", "#E8A93C"),
}
NIGHT_THEMES = {"patterns_order", "festivals"}

# words in tale text -> vocab id (plural and inflected forms the pages actually use)
ALIAS = {"apples": "apple", "flowers": "flower", "lanterns": "key_lantern", "lantern": "key_lantern",
         "stars": "star", "cookies": "cookie", "shoes": "shoe", "socks": "sock", "blocks": "block",
         "books": "book", "trees": "tree", "leaves": "leaf", "eyes": "eye", "ears": "ear",
         "dumplings": "dumpling", "mooncakes": "mooncake", "candles": "candle", "bees": "bee",
         "seeds": "flower", "ducks": "duck", "hats": "hat", "boats": "boat", "drums": "drum",
         "snowman": "cloud", "tangyuan": "mooncake", "puppy": "dog", "kitten": "cat", "duckling": "duck",
         "mum": "mom", "mother": "mom", "father": "dad", "grandmother": "grandma", "grandfather": "grandpa"}
ID_BY_WORD = {}
for v in vocab:
    ID_BY_WORD[v["en"].lower()] = v["id"]
    ID_BY_WORD[v["id"].replace("_", " ")] = v["id"]
ID_BY_WORD.update(ALIAS)
# characters that carry a scene even when unnamed
CAST = ["yun", "bear", "duck", "rabbit", "frog", "owl", "mouse", "butterfly", "bee", "cat", "dog", "turtle", "bird", "fish", "panda"]


def items_for(text_en, text_zh=""):
    """vocab ids mentioned on this page, in order, at most 4."""
    words = re.findall(r"[a-z']+", text_en.lower())
    found = []
    for i, w in enumerate(words):
        two = f"{w} {words[i + 1]}" if i + 1 < len(words) else ""
        for key in (two, w):
            if key in ID_BY_WORD and ID_BY_WORD[key] not in found:
                found.append(ID_BY_WORD[key])
                break
    return found[:4]


def yun_named(text):
    return "yun" in text.lower()


def page_html(theme, item_ids, has_yun, night, text_en=None, text_zh=None, cover=False):
    sky, ground, accent = THEME[theme]
    ink = "#FFE9C9" if night else "#4A3426"
    o = [f'<div style="position:absolute;inset:0;background:{sky}"></div>']
    # rolling ground
    o.append(f'<svg width="{W}" height="{H}" style="position:absolute;inset:0">'
             f'<path d="M0 {int(H * .66)} C{int(W * .25)} {int(H * .60)} {int(W * .45)} {int(H * .71)} {int(W * .7)} {int(H * .66)} '
             f'S{int(W * .92)} {int(H * .62)} {W} {int(H * .645)} V{H} H0 Z" fill="{ground}"/>'
             f'<path d="M0 {int(H * .78)} C{int(W * .3)} {int(H * .73)} {int(W * .6)} {int(H * .83)} {W} {int(H * .77)} V{H} H0 Z" '
             f'fill="rgba(0,0,0,.08)"/></svg>')
    if night:
        for x, y, r in ((120, 90, 9), (330, 150, 6), (560, 70, 11), (860, 130, 7), (1060, 90, 9), (700, 210, 5)):
            o.append(f'<svg width="{r * 2.6}" height="{r * 2.6}" viewBox="0 0 24 24" style="position:absolute;left:{x}px;top:{y}px">'
                     f'<path d="M12 0 Q14 10 24 12 Q14 14 12 24 Q10 14 0 12 Q10 10 12 0 Z" fill="#F6E7B8"/></svg>')
    # the cast stands on the ground line, inside the safe band
    n = len(item_ids) + (1 if has_yun else 0)
    if n:
        slot = W / (n + 1)
        i = 0
        if has_yun:
            o.append(f'<img src="../yun_idle.png" style="position:absolute;left:{slot - 120}px;top:{SAFE_TOP + 250}px;width:240px">')
            i = 1
        for k, vid in enumerate(item_ids):
            x = slot * (i + k + 1) - 90
            y = SAFE_TOP + 290 + (18 if k % 2 else 0)
            o.append(f'<img src="../items/{vid}.png" style="position:absolute;left:{x}px;top:{y}px;width:180px">')
    if cover:
        o.append(f'<div style="position:absolute;left:0;right:0;top:{SAFE_TOP + 40}px;text-align:center;padding:0 90px">'
                 f'<div style="font-family:Fredoka,sans-serif;font-weight:600;font-size:62px;line-height:1.1;color:{ink};'
                 f'text-shadow:0 3px 0 rgba(255,248,236,.55)">{text_en}</div>'
                 f'<div style="font-family:\'ZCOOL KuaiLe\',sans-serif;font-size:52px;margin-top:10px;color:{accent};'
                 f'text-shadow:0 3px 0 rgba(255,248,236,.55)">{text_zh}</div></div>')
    return "".join(o)


def main():
    os.makedirs(OUT, exist_ok=True)
    tmp = os.path.join(OUT, "_tale.html")   # lives in png/tales/, so "../items/x.png" resolves
    made = 0
    with sync_playwright() as pw:
        b = pw.chromium.launch()
        pg = b.new_page(viewport={"width": W, "height": H}, device_scale_factor=2)
        for t in lib["tales"]:
            d = os.path.join(OUT, t["id"])
            os.makedirs(d, exist_ok=True)
            night = t["theme"] in NIGHT_THEMES
            jobs = [("cover.png", page_html(t["theme"], items_for(t["synopsis"]["en"]), True, night,
                                            t["title"]["en"], t["title"]["zh"], cover=True))]
            for i, p in enumerate(t["pages"], 1):
                jobs.append((f"p{i}.png", page_html(t["theme"], items_for(p["en"]), yun_named(p["en"]), night)))
            for name, body in jobs:
                with open(tmp, "w", encoding="utf-8") as fh:
                    fh.write(f"<html><head><meta charset='utf-8'><link rel='stylesheet' href='{FONTS}'></head><body style='margin:0'>"
                             f"<div id='s' style='position:relative;width:{W}px;height:{H}px;overflow:hidden'>{body}</div></body></html>")
                pg.goto("file:///" + tmp.replace(os.sep, "/"))
                pg.wait_for_load_state("networkidle")
                pg.evaluate("document.fonts.ready")
                pg.query_selector("#s").screenshot(path=os.path.join(d, name))
                made += 1
        b.close()
    os.remove(tmp)
    print(f"{made} images across {len(lib['tales'])} tales")


if __name__ == "__main__":
    main()
