#!/usr/bin/env python3
"""Gate for the v3 expansion content (content/catalog.json, content/library.json).

Exits non-zero on anything that would break the app or the house rules:
counts, unique ids, both languages present, links that resolve, age range,
page limits, and copy that implies a fail state (CLAUDE.md: no fail states).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CJK = re.compile(r"[一-鿿]")
# Scolding or fail-state words must never reach a child (CLAUDE.md "No fail states").
BANNED_EN = re.compile(r"\b(wrong|fail(ed|ure)?|incorrect|bad|lose|lost a life|try harder|game over)\b", re.I)
BANNED_ZH = ("错", "不对", "失败", "输了", "笨")
MAX_PAGES, MIN_PAGES = 8, 6
MAX_EN_WORDS, MAX_ZH_CHARS = 22, 36  # one or two short sentences, under ~6 s spoken

errors = []


def err(msg):
    errors.append(msg)


def check_text(tag, en, zh):
    if not en or not en.strip():
        err(f"{tag}: missing English")
    if not zh or not CJK.search(zh):
        err(f"{tag}: missing Chinese")
    if BANNED_EN.search(en or ""):
        err(f"{tag}: fail-state word in English copy: {en!r}")
    for w in BANNED_ZH:
        if w in (zh or ""):
            err(f"{tag}: fail-state word {w!r} in Chinese copy: {zh!r}")


def main():
    cat = json.loads((ROOT / "content" / "catalog.json").read_text(encoding="utf-8"))
    lib = json.loads((ROOT / "content" / "library.json").read_text(encoding="utf-8"))
    acts = json.loads((ROOT / "content" / "activities.json").read_text(encoding="utf-8"))

    engines = {e["id"] for e in cat["engines"]}
    if len(engines) != 15:
        err(f"expected 15 engines, got {len(engines)}")
    games = cat["games"]
    ids = [g["id"] for g in games]
    if len(games) != 75:
        err(f"expected 75 games, got {len(games)}")
    if len(set(ids)) != len(ids):
        err("duplicate game ids")
    for e in engines:
        n = sum(1 for g in games if g["engine"] == e)
        if n != 5:
            err(f"engine {e}: {n} games, expected 5")
    for g in games:
        tag = f"game {g['id']}"
        if g["engine"] not in engines:
            err(f"{tag}: unknown engine {g['engine']}")
        if g["minAge"] not in (3, 4, 5):
            err(f"{tag}: minAge {g['minAge']} outside 3–5")
        if not re.fullmatch(r"[a-z][a-z0-9_]*", g["id"]):
            err(f"{tag}: id must be snake_case")
        check_text(tag, g["name"]["en"], g["name"]["zh"])
        if BANNED_EN.search(g["goal"]):
            err(f"{tag}: fail-state word in goal")
    # the original 12 must stay consistent with activities.json
    for a in acts["activities"]:
        match = [g for g in games if g["id"] == a["id"]]
        if not match:
            err(f"activity {a['id']} missing from catalog")
            continue
        g = match[0]
        if g["name"]["en"] != a["name"]["en"] or g["name"]["zh"] != a["name"]["zh"]:
            err(f"{a['id']}: catalog name differs from activities.json")
        if g["free"] != a["free"] or g["minAge"] != a["minAge"] or g["rounds"] != a["roundCount"]:
            err(f"{a['id']}: catalog free/minAge/rounds differ from activities.json")

    themes = {t["id"] for t in lib["themes"]}
    tales = lib["tales"]
    if len(themes) != 15:
        err(f"expected 15 themes, got {len(themes)}")
    if len(tales) != 75:
        err(f"expected 75 tales, got {len(tales)}")
    if len({t["id"] for t in tales}) != len(tales):
        err("duplicate tale ids")
    for t in tales:
        tag = f"tale {t['id']}"
        if t["theme"] not in themes:
            err(f"{tag}: unknown theme")
        if t["game"] not in ids:
            err(f"{tag}: links to unknown game {t['game']}")
        check_text(f"{tag} title", t["title"]["en"], t["title"]["zh"])
        check_text(f"{tag} synopsis", t["synopsis"]["en"], t["synopsis"]["zh"])
        pages = t["pages"]
        if pages and not (MIN_PAGES <= len(pages) <= MAX_PAGES):
            err(f"{tag}: {len(pages)} pages, expected {MIN_PAGES}–{MAX_PAGES}")
        for i, p in enumerate(pages, 1):
            check_text(f"{tag} p{i}", p["en"], p["zh"])
            if len(p["en"].split()) > MAX_EN_WORDS:
                err(f"{tag} p{i}: {len(p['en'].split())} English words, max {MAX_EN_WORDS}")
            if len(CJK.findall(p["zh"])) > MAX_ZH_CHARS:
                err(f"{tag} p{i}: {len(CJK.findall(p['zh']))} Chinese characters, max {MAX_ZH_CHARS}")
    for t in themes:
        n = sum(1 for s in tales if s["theme"] == t)
        if n != 5:
            err(f"theme {t}: {n} tales, expected 5")

    written = sum(1 for t in tales if t["pages"])
    if errors:
        print(f"FAIL: {len(errors)} problem(s)")
        for e in errors:
            print("  -", e)
        sys.exit(1)
    print(f"OK: 15 engines, 75 games ({sum(g['free'] for g in games)} free), 75 tales ({written} written)")


if __name__ == "__main__":
    main()
