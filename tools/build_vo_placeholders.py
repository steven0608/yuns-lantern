#!/usr/bin/env python3
"""
Generates PLACEHOLDER voice-over for every VO key (phrases, items, story),
in both languages, so the app can be played and tested with sound before the
Phase 4 recordings exist.

DO NOT SHIP THESE. SPEC §12 Phase 4: native speakers for every file. A
three-year-old learns Mandarin tone from whatever she hears, and synthetic
tone contours are the one thing this app must not teach wrong.

Network is used at BUILD time only (edge-tts). The app ships the mp3 files and
runs fully offline, which is what CLAUDE.md's no-network rule requires.
Existing files are kept unless --force, so real recordings dropped into
assets/audio/vo/ are never overwritten.

    pip install edge-tts
    python tools/build_vo_placeholders.py [--force] [--only story.]
"""
import asyncio
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
VO = ROOT / "assets" / "audio" / "vo"

# Same voices as the first placeholder batch, so the set sounds consistent.
VOICES = {"en": "en-US-AnaNeural", "zh": "zh-CN-XiaoyiNeural"}
RATE = {"en": "-15%", "zh": "-20%"}  # preschoolers need processing time


def collect():
    load = lambda n: json.loads((CONTENT / n).read_text(encoding="utf-8"))
    lines = {k: v for k, v in load("phrases.json")["phrases"].items()}
    for it in load("vocab.json")["items"]:
        lines["item." + it["id"]] = it
    for ch in load("story.json")["chapters"]:
        for part in ("open", "beat", "close"):
            lines[f"story.{ch['id']}.{part}"] = ch[part]
    # Lantern Tales narration: tales.<tale_id>.p<N> (docs/EXPANSION.md §5).
    library = CONTENT / "library.json"
    if library.exists():
        for tale in json.loads(library.read_text(encoding="utf-8"))["tales"]:
            if tale.get("status") != "written":
                continue
            for n, page in enumerate(tale["pages"], 1):
                lines[f"tales.{tale['id']}.p{n}"] = page
    return {k: {"en": v["en"], "zh": v["zh"]} for k, v in lines.items()}


async def main(force=False, only=None):
    import edge_tts

    made = kept = 0
    for key, copy in sorted(collect().items()):
        if only and not key.startswith(only):
            continue
        for lang in ("en", "zh"):
            out = VO / lang / (key.replace(".", "/") + ".mp3")
            if out.exists() and out.stat().st_size and not force:
                kept += 1
                continue
            out.parent.mkdir(parents=True, exist_ok=True)
            await edge_tts.Communicate(copy[lang], VOICES[lang], rate=RATE[lang]).save(str(out))
            made += 1
    print(f"generated {made}, kept {kept} existing")
    (VO / "PLACEHOLDER.txt").write_text(
        "Every mp3 under this folder is machine TTS (tools/build_vo_placeholders.py).\n"
        "Replace with native-speaker recordings before shipping - see docs/VO_SCRIPT.md.\n",
        encoding="utf-8")


if __name__ == "__main__":
    only = sys.argv[sys.argv.index("--only") + 1] if "--only" in sys.argv else None
    asyncio.run(main(force="--force" in sys.argv, only=only))
