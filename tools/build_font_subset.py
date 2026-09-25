#!/usr/bin/env python3
"""
Builds assets/fonts/NotoSansSC-subset.ttf: Noto Sans SC (OFL) cut down to the
characters this app can actually display — every Chinese string in
lib/l10n/*.arb and content/*.json, plus Latin and punctuation.

Why: CLAUDE.md requires bundling Noto Sans SC rather than trusting system CJK
fallback, but the full font is ~17 MB — too heavy for the web build and
wasteful on iOS. The subset is a few hundred KB. RE-RUN after any text change
(a character missing from the subset falls back to the system font).

The full font is fetched once at build time into build/fonts/ (git-ignored);
the app itself never touches the network.

    pip install fonttools
    python tools/build_font_subset.py
"""
import json
import urllib.request
from pathlib import Path

from fontTools import subset

ROOT = Path(__file__).resolve().parent.parent
FULL = ROOT / "build" / "fonts" / "NotoSansSC.ttf"
URL = "https://github.com/google/fonts/raw/main/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf"
OUT = ROOT / "assets" / "fonts" / "NotoSansSC-subset.ttf"


def strings(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for v in node.values():
            yield from strings(v)
    elif isinstance(node, list):
        for v in node:
            yield from strings(v)


def main():
    if not FULL.exists():
        FULL.parent.mkdir(parents=True, exist_ok=True)
        urllib.request.urlretrieve(URL, FULL)
    chars = set(chr(c) for c in range(0x20, 0x7F))
    chars |= set("·—–…“”‘’、。，：；！？（）《》【】「」 ０１２３４５６７８９")
    sources = list((ROOT / "lib" / "l10n").glob("*.arb")) + list((ROOT / "content").glob("*.json"))
    for f in sources:
        for s in strings(json.loads(f.read_text(encoding="utf-8"))):
            chars |= set(s)
    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    font = subset.load_font(str(FULL), opts)
    sub = subset.Subsetter(opts)
    sub.populate(text="".join(sorted(chars)))
    sub.subset(font)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(OUT), opts)
    cjk = sum(1 for c in chars if "一" <= c <= "鿿")
    print(f"{OUT.name}: {cjk} CJK chars, {OUT.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
