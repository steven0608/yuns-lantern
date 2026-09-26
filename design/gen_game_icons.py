#!/usr/bin/env python3
"""Game icons for the 58 catalog games that had none, composed from the item art.

Each game icon sits on its land's tile tint (so a land reads as one family) and shows
what the game is about. Output: design/svg/icon_<game_id>.svg (160 x 160), exported to
design/png/games/<game_id>.png by render.py together with the 17 hand-drawn icons.
"""
import math
import os

from gen_assets import (CARD, INK, LANTERN, NAMED, NIGHT, RUST_DEEP, STICK, WATER, WATER_DEEP, circle, ellipse, lantern_g,
                        mix, rect, rtri, sparkle, svg, tile)
from gen_items import ITEMS

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "svg")
R, O, Y, G, B, P, K, BR = (NAMED[c] for c in ("red", "orange", "yellow", "green", "blue", "purple", "pink", "brown"))

# land (engine) tile tints, matching the land icons
TINT = {
    "count_feed": (R, .72), "sort_bins": (Y, .72), "find_same": (O, .72), "silhouette": (K, .72),
    "order_line": (LANTERN, .68), "pattern": (WATER, .66), "jigsaw": (BR, .75), "position": ("#D9D4CC", .45),
    "mirror": (P, .72), "try_see": (G, .72), "listen_find": (WATER, .66), "trace": (LANTERN, .68),
    "color_fill": (K, .72), "music_echo": (P, .72), "memory_pairs": (G, .72),
}


def it(item_id, x, y, size, rot=0, extra=""):
    """Place a 200-box item drawing with its top-left at (x, y), `size` px wide."""
    r = f" rotate({rot} 100 100)" if rot else ""
    return f'<g transform="translate({x} {y}) scale({size / 200:.4f}){r}"{extra}>{ITEMS[item_id]()}</g>'


def ln(d, color, w, extra=""):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"{extra}/>'


def dots(n, y, color=RUST_DEEP, r=7, gap=22, cx=80):
    x0 = cx - (n - 1) * gap / 2
    return "".join(circle(x0 + i * gap, y, r, color) for i in range(n))


def card(x, y, w, h, rot=0, fill=CARD):
    return (f'<g transform="rotate({rot} {x + w / 2} {y + h / 2})">'
            + rect(x, y, w, h, fill, 12, ' stroke="#EAD9BF" stroke-width="3"') + "</g>")


def speaker(x, y, s=1.0, color=WATER_DEEP):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            + f'<path d="M0 10 H10 L22 0 V36 L10 26 H0 Z" fill="{color}"/>'
            + ln("M30 8 Q40 18 30 28 M38 2 Q54 18 38 34", color, 5) + "</g>")


NOTE = lambda x, y, c=INK: (ellipse(x, y, 7, 5.5, c, f' transform="rotate(-20 {x} {y})"')  # noqa: E731
                           + ln(f"M{x + 6} {y - 2} V{y - 26} L{x + 16} {y - 20}", c, 3.5))

ICONS = {
    # ---- Count and Feed land --------------------------------------------------
    "birthday_candles": lambda: it("cake", 16, 30, 128) + dots(3, 146),
    "bus_stop": lambda: it("bus", 14, 18, 132) + dots(4, 144, r=6, gap=20),
    "share_cookies": lambda: it("cookie", 12, 24, 62) + it("cookie", 50, 58, 62) + it("cookie", 88, 24, 62) + dots(3, 144),
    "garden_seeds": lambda: (rect(18, 110, 124, 30, "#9C6B45", 14) + it("flower", 18, 32, 70) + it("flower", 72, 44, 60)
                             + "".join(circle(x, 124, 6, "#6E4A2F") for x in (40, 80, 120))),
    # ---- Sort It land -------------------------------------------------------------
    "tidy_up": lambda: (rect(22, 94, 116, 50, "#B5835A", 12) + rect(18, 86, 124, 16, "#8C6240", 8)
                        + it("teddy", 22, 20, 74) + it("block", 90, 44, 50) + it("ball", 64, 56, 40)),
    "weather_wardrobe": lambda: it("umbrella", 4, 12, 90) + it("sun", 78, 8, 70) + it("hat", 70, 84, 76),
    # ---- Find the Same land -----------------------------------------------------
    "odd_one_out": lambda: it("apple", 8, 24, 62) + it("apple", 90, 24, 62) + it("apple", 8, 86, 62) + it("orange", 90, 86, 62, extra=' opacity="1"')
                          + circle(121, 117, 34, "none", ' stroke="#9E4726" stroke-width="5" stroke-dasharray="6 6"'),
    "feelings_faces": lambda: it("happy", 10, 30, 80) + it("sad", 72, 50, 80),
    "sock_pairs": lambda: it("sock", 8, 20, 96, -10) + it("sock", 58, 34, 96, 10),
    "spot_the_lantern": lambda: lantern_g(R, "lit", 10, 20, .62) + lantern_g(R, "lit", 76, 20, .62) + sparkle(80, 138, 10, RUST_DEEP),
    # ---- What Is It? land -------------------------------------------------------
    "peekaboo_animals": lambda: (it("rabbit", 36, 10, 88) + ellipse(80, 118, 66, 40, G) + ellipse(42, 108, 30, 26, mix(G, "#2A1A10", .12))
                                 + ellipse(118, 108, 30, 26, mix(G, "#2A1A10", .12))),
    "who_made_tracks": lambda: ("".join(ellipse(x, y, 9, 11, "#6E4A2F") + "".join(circle(x + dx, y - 14, 4, "#6E4A2F") for dx in (-8, 0, 8))
                                        for x, y in ((40, 130), (70, 104), (100, 128), (130, 102))) + it("bear", 70, 8, 72)),
    "zoom_out": lambda: (it("strawberry", 20, 20, 88) + circle(64, 64, 42, "none", f' stroke="{INK}" stroke-width="9"')
                         + ln("M94 94 L132 132", INK, 16)),
    "shadow_puppets": lambda: (rect(0, 0, 160, 160, NIGHT, 44) + f'<path d="M20 20 L150 60 L150 140 L20 150 Z" fill="#FFE9A8" fill-opacity="0.25"/>'
                               + it("hand", 20, 40, 70, extra=' opacity="0.95"')
                               + f'<g opacity="0.9">{rtri((110, 56), (130, 80), (100, 80), "#1F2033", 8)}{ellipse(116, 104, 26, 22, "#1F2033")}</g>'),
    # ---- Line Up land -------------------------------------------------------------
    "ladder_up": lambda: (ln("M50 146 L62 22 M110 146 L98 22", "#9C6B45", 9)
                          + "".join(ln(f"M{54 + (146 - y) * .09:.1f} {y} H{106 - (146 - y) * .09:.1f}", "#9C6B45", 7) for y in (124, 96, 68, 40))),
    "morning_routine": lambda: (it("sun", 4, 24, 52) + it("toothbrush", 54, 26, 52) + it("shoe", 104, 26, 52)
                                + dots(3, 118, r=10, gap=50)),
    "growing_up": lambda: (rect(10, 128, 140, 12, "#9C6B45", 6) + circle(30, 120, 8, "#6E4A2F")
                           + ln("M80 128 V96", G, 6) + ellipse(72, 98, 10, 6, G) + ellipse(88, 94, 10, 6, G)
                           + it("flower", 104, 32, 60) + ln("M44 110 L58 110 M96 110 L106 110", RUST_DEEP, 4, ' stroke-dasharray="2 6"')),
    "stacking_cups": lambda: "".join(f'<path d="M{80 - w} {y} H{80 + w} L{80 + w - 8} {y + 30} H{80 - w + 8} Z" fill="{c}"/>'
                                     for w, y, c in ((56, 112, R), (44, 80, O), (32, 48, Y), (20, 20, G))),
    # ---- Pattern Parade land --------------------------------------------------------
    "bead_necklace": lambda: (ln("M14 60 Q80 150 146 60", INK, 3, ' stroke-opacity="0.5"')
                              + "".join(circle(14 + i * 22, 60 + 90 * math.sin(math.pi * i / 6) * .55, 12, (R, B)[i % 2]) for i in range(6))
                              + circle(146, 60, 12, "none", ' stroke="#4F8FB0" stroke-width="4" stroke-dasharray="5 4"')),
    "lantern_string": lambda: (ln("M8 30 Q80 56 152 30", INK, 3, ' stroke-opacity="0.5"')
                               + lantern_g(R, "lit", 6, 30, .34) + lantern_g(Y, "lit", 44, 38, .34) + lantern_g(R, "lit", 82, 38, .34)
                               + f'<g transform="translate(120 30) scale(.34)"><rect x="20" y="36" width="80" height="94" rx="36" fill="none" stroke="#4F8FB0" stroke-width="10" stroke-dasharray="14 10"/></g>'),
    "clap_stomp": lambda: it("hand", 4, 30, 60) + it("foot", 50, 62, 56) + it("hand", 98, 30, 60) + ln("M22 146 H138", WATER_DEEP, 4, ' stroke-dasharray="4 10"'),
    "flower_path": lambda: "".join(rect(8 + i * 38, 104, 34, 34, (mix(Y, CARD, .4), mix(K, CARD, .4))[i % 2], 8) for i in range(4))
                          + it("flower", 4, 40, 50) + it("flower", 60, 30, 56) + it("flower", 112, 18, 44),
    # ---- Puzzle Pieces land ------------------------------------------------------
    "build_snowman": lambda: (circle(80, 120, 34, CARD, ' stroke="#4A3426" stroke-opacity="0.35" stroke-width="4"')
                              + circle(80, 72, 24, CARD, ' stroke="#4A3426" stroke-opacity="0.35" stroke-width="4"')
                              + circle(80, 34, 16, "none", ' stroke="#9E4726" stroke-width="4" stroke-dasharray="5 5"')
                              + f'<path d="M80 72 L102 76 L80 80 Z" fill="{O}"/>' + circle(72, 66, 3, INK) + circle(88, 66, 3, INK)),
    "tangram": lambda: (rtri((20, 130), (80, 70), (80, 130), R, 4) + rtri((80, 70), (140, 130), (80, 130), B, 4)
                        + rtri((40, 70), (60, 40), (80, 70), Y, 4) + rtri((80, 70), (100, 40), (120, 70), G, 4)
                        + rect(62, 46, 36, 24, "none", 4, ' stroke="#9E4726" stroke-width="3" stroke-dasharray="5 4" transform="rotate(45 80 58)"')),
    "fix_bridge": lambda: (rect(0, 110, 160, 50, WATER, 0) + rect(6, 84, 44, 16, "#9C6B45", 5) + rect(110, 84, 44, 16, "#9C6B45", 5)
                           + rect(54, 84, 52, 16, "none", 5, ' stroke="#9E4726" stroke-width="4" stroke-dasharray="6 5"')
                           + rect(52, 40, 56, 16, "#C49A70", 5, ' transform="rotate(-8 80 48)"')),
    "dragon_boat": lambda: it("dragon_boat", 0, 22, 160),
    # ---- Where Is It? land --------------------------------------------------------
    "hide_seek": lambda: it("tree", 20, 6, 110) + it("frog", 90, 88, 56),
    "set_table": lambda: rect(10, 100, 140, 14, "#B5835A", 7) + it("bowl", 42, 34, 76) + it("spoon", 104, 54, 50, -60) + it("cup", 2, 50, 48),
    "owl_tree_house": lambda: (rect(70, 20, 20, 130, "#9C6B45", 8) + "".join(rect(46, y, 68, 10, "#8C6240", 5) for y in (48, 92, 136))
                               + it("owl", 58, 2, 46) + it("bird", 96, 58, 38) + it("frog", 20, 100, 40)),
    "park_map": lambda: (ln("M24 136 C24 90 70 110 80 76 S130 60 136 26", "#EAD3AE", 18) + ln("M24 136 C24 90 70 110 80 76 S130 60 136 26", RUST_DEEP, 5, ' stroke-dasharray="1 12"')
                         + f'<path d="M126 20 L148 24 L134 42 Z" fill="{RUST_DEEP}"/>' + it("tree", 94, 84, 50) + it("flower", 10, 20, 44)),
    # ---- Mirror Match land --------------------------------------------------------
    "butterfly_wings": lambda: (it("butterfly", 0, 0, 160)
                                + rect(82, 16, 70, 128, mix(P, CARD, .72), 0) + ln("M80 12 V148", INK, 3, ' stroke-opacity="0.45" stroke-dasharray="6 6"')
                                + f'<path d="M84 60 Q128 30 138 70 Q130 96 84 90 Z" fill="none" stroke="#9B76C4" stroke-width="4" stroke-dasharray="6 5"/>'),
    "paper_cutting": lambda: (rect(18, 18, 124, 124, R, 12) + "".join(
        f'<ellipse cx="80" cy="{80 - 30}" rx="12" ry="26" fill="{mix(R, CARD, .9)}" transform="rotate({a} 80 80)"/>' for a in range(0, 360, 45))
        + circle(80, 80, 14, R) + ln("M80 14 V146", INK, 3, ' stroke-opacity="0.35" stroke-dasharray="6 6"')),
    "face_builder": lambda: (circle(80, 84, 58, "#F9DDB8") + circle(60, 76, 8, INK) + circle(100, 76, 8, "none", ' stroke="#4A3426" stroke-width="3" stroke-dasharray="4 4"')
                             + ln("M62 106 Q80 120 98 106", INK, 4) + ln("M80 20 V150", INK, 3, ' stroke-opacity="0.35" stroke-dasharray="6 6"')),
    "reflection_lake": lambda: (rect(0, 84, 160, 76, WATER, 0) + it("tree", 40, 4, 80)
                                + f'<g opacity="0.45" transform="translate(0 168) scale(1 -1)">{it("tree", 40, 4, 80)}</g>'),
    # ---- Try It and See land --------------------------------------------------------
    "melt_or_not": lambda: (it("sun", 86, 4, 70) + rect(24, 62, 56, 56, "#CFE6F2", 12, ' stroke="#7FB7D1" stroke-width="4"')
                            + ellipse(52, 136, 40, 10, "#9FC4DC") + circle(46, 124, 5, "#9FC4DC")),
    "plant_grows": lambda: (f'<path d="M44 104 H116 L106 146 H54 Z" fill="{R}"/>' + ln("M80 104 V56", G, 7)
                            + ellipse(64, 66, 16, 9, G, ' transform="rotate(-25 64 66)"') + ellipse(96, 60, 16, 9, G, ' transform="rotate(25 96 60)"')
                            + f'<path d="M124 22 C132 36 136 42 130 50 C126 54 118 52 118 44 C118 38 122 30 124 22 Z" fill="{B}"/>' + it("sun", 4, 4, 46)),
    "magnet_magic": lambda: (f'<path d="M40 30 V86 A40 40 0 0 0 120 86 V30" fill="none" stroke="{R}" stroke-width="26"/>'
                             + rect(27, 22, 26, 18, "#D9D4CC") + rect(107, 22, 26, 18, "#D9D4CC") + it("key", 46, 110, 68)
                             + ln("M60 130 L66 118 M100 130 L94 118", RUST_DEEP, 3)),
    "light_shadow": lambda: (it("lamp", 4, 6, 70) + circle(116, 66, 16, O) + rect(106, 80, 20, 40, O, 8)
                             + ellipse(128, 138, 30, 8, "#6E6259", ' fill-opacity="0.6"')),
    # ---- Listen and Find land -----------------------------------------------------
    "color_words": lambda: speaker(12, 18, 1.2) + circle(46, 118, 20, R) + circle(92, 118, 20, Y) + circle(138, 118, 20, B) + circle(92, 60, 20, G),
    "tone_hills": lambda: (ln("M14 60 H46", WATER_DEEP, 9) + ln("M54 76 L84 44", WATER_DEEP, 9) + ln("M92 50 Q104 84 118 50", WATER_DEEP, 9)
                           + ln("M124 44 L150 76", WATER_DEEP, 9) + speaker(58, 104, 1.1)),
    "body_parts": lambda: it("eye", 6, 20, 80) + it("ear", 84, 16, 70) + it("hand", 40, 84, 70),
    "numbers_out_loud": lambda: speaker(12, 20, 1.2) + "".join(circle(x, y, 13, R) for x, y in ((92, 40), (124, 40), (108, 70))) + dots(3, 128, WATER_DEEP, 10, 30),
    # ---- Trace It land --------------------------------------------------------------
    "shape_tracing": lambda: (circle(56, 60, 34, "none", f' stroke="{RUST_DEEP}" stroke-width="7" stroke-dasharray="1 14" stroke-linecap="round"')
                              + f'<path d="M110 40 L144 110 H76 Z" fill="none" stroke="{RUST_DEEP}" stroke-width="7" stroke-dasharray="1 14" stroke-linecap="round" stroke-linejoin="round"/>'
                              + circle(56, 26, 8, RUST_DEEP)),
    "number_tracing": lambda: (ln("M52 44 Q80 20 102 40 Q112 60 90 80 Q108 90 104 112 Q92 140 52 124", RUST_DEEP, 9, ' stroke-dasharray="1 16"')
                               + circle(52, 44, 9, RUST_DEEP)),
    "first_characters": lambda: (ln("M86 28 Q84 90 30 136", RUST_DEEP, 10, ' stroke-dasharray="1 16"') + ln("M84 74 Q104 112 136 136", RUST_DEEP, 10, ' stroke-dasharray="1 16"')
                                 + circle(86, 28, 9, RUST_DEEP) + rect(12, 12, 136, 136, "none", 16, ' stroke="#C9B79E" stroke-width="3" stroke-dasharray="8 8"')),
    "letter_friends": lambda: (ln("M36 136 L80 26 L124 136 M54 96 H106", RUST_DEEP, 9, ' stroke-dasharray="1 16"') + circle(36, 136, 9, RUST_DEEP)),
    # ---- Color Me land ------------------------------------------------------------
    "rainbow_mixing": lambda: (circle(52, 62, 32, Y, ' fill-opacity="0.9"') + circle(100, 62, 32, B, ' fill-opacity="0.9"')
                               + f'<path d="M76 40 Q92 62 76 84 Q60 62 76 40 Z" fill="{G}"/>' + circle(76, 126, 22, G) + ln("M76 96 V100", INK, 4)),
    "color_by_number": lambda: (rect(16, 16, 128, 128, CARD, 14, ' stroke="#EAD9BF" stroke-width="3"') + f'<path d="M16 80 Q80 50 144 80 V130 Q144 144 130 144 H30 Q16 144 16 130 Z" fill="{G}"/>'
                                + circle(110, 50, 18, Y) + dots(1, 50, INK, 4, 0, 110) + dots(2, 116, INK, 4, 12, 60) + circle(46, 46, 16, "none", ' stroke="#C9B79E" stroke-width="3" stroke-dasharray="4 4"')),
    "lantern_painter": lambda: (lantern_g(R, "lit", 12, 14, .82) + sparkle(56, 90, 10, Y) + sparkle(74, 70, 6, Y)
                                + f'<g transform="rotate(35 128 70)">{rect(122, 30, 12, 70, STICK, 5)}{rect(120, 94, 16, 20, "#D9D4CC", 4)}'
                                + f'<path d="M120 112 H136 L130 136 Q128 140 126 136 Z" fill="{B}"/></g>'),
    "night_sky": lambda: (rect(0, 0, 160, 160, NIGHT, 44) + ln("M34 110 L66 62 L108 78 L130 36", "#F6E7B8", 3, ' stroke-opacity="0.7"')
                          + "".join(sparkle(x, y, r, "#F6E7B8") for x, y, r in ((34, 110, 12), (66, 62, 14), (108, 78, 11), (130, 36, 13), (40, 36, 6), (120, 126, 7)))),
    # ---- Echo Music land --------------------------------------------------------------
    "animal_choir": lambda: it("bird", 4, 44, 72) + it("frog", 80, 70, 72) + NOTE(72, 40) + NOTE(126, 52),
    "fast_slow": lambda: it("rabbit", 4, 4, 76) + it("turtle", 72, 70, 84) + ln("M88 30 H140 M100 44 H150", INK, 4, ' stroke-opacity="0.45"'),
    "rhyme_time": lambda: it("star", 34, 30, 92) + NOTE(30, 50) + NOTE(132, 58) + NOTE(118, 132),
    "high_low": lambda: it("bird", 88, 4, 64) + it("bear", 6, 76, 76) + NOTE(60, 40, WATER_DEEP) + NOTE(110, 126, RUST_DEEP),
    # ---- Memory Pairs land ------------------------------------------------------------
    "word_pairs": lambda: card(14, 28, 62, 96, -8) + it("apple", 18, 50, 54) + card(84, 28, 62, 96, 8) + it("apple", 88, 50, 54) + speaker(100, 124, .6),
    "festival_pairs": lambda: card(14, 28, 62, 96, -8) + it("mooncake", 16, 48, 58) + card(84, 28, 62, 96, 8) + it("dumpling", 86, 48, 58),
    "animal_families": lambda: it("duck", 0, 22, 104) + it("duck", 96, 80, 58),
    "shape_pairs": lambda: (card(14, 28, 62, 96, -8) + circle(45, 76, 20, "none", f' stroke="{B}" stroke-width="7"')
                            + card(84, 28, 62, 96, 8) + it("ball", 90, 50, 50)),
}

GAME_ENGINE = {}


def main():
    import json
    cat = json.load(open(os.path.join(os.path.dirname(OUT), "..", "content", "catalog.json"), encoding="utf-8"))
    for g in cat["games"]:
        GAME_ENGINE[g["id"]] = g["engine"]
    missing = [g["id"] for g in cat["games"] if g["id"] not in ICONS and not os.path.exists(os.path.join(OUT, f"icon_{g['id']}.svg"))]
    if missing:
        raise SystemExit(f"no icon for: {missing}")
    for gid, fn in ICONS.items():
        c, t = TINT[GAME_ENGINE[gid]]
        body = fn()
        bg = "" if body.startswith(rect(0, 0, 160, 160, NIGHT, 44)) else tile(c, t)
        with open(os.path.join(OUT, f"icon_{gid}.svg"), "w", encoding="utf-8") as fh:
            fh.write(svg(160, 160, bg + body))
    print(len(ICONS), "game icons")


if __name__ == "__main__":
    main()
