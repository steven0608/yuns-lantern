#!/usr/bin/env python3
"""
Generates docs/VO_SCRIPT.md — the recording script handed to the two voice actors —
and cross-checks that every VO key referenced by generated content actually has
copy written for it. A missing line here is a silent activity in the shipped app,
which is the single worst failure mode for a pre-reader.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
DOCS = ROOT / "docs"
DOCS.mkdir(exist_ok=True)

vocab = json.loads((CONTENT / "vocab.json").read_text(encoding="utf-8"))
phrases = json.loads((CONTENT / "phrases.json").read_text(encoding="utf-8"))["phrases"]
acts = json.loads((CONTENT / "activities.json").read_text(encoding="utf-8"))
story = json.loads((CONTENT / "story.json").read_text(encoding="utf-8"))

# Build the full key -> copy table
lines = {}
for it in vocab["items"]:
    lines[f"item.{it['id']}"] = {"en": it["en"], "zh": it["zh"], "pinyin": it["pinyin"]}
lines.update(phrases)

for ch in story["chapters"]:
    for part in ("open", "beat", "close"):
        lines[f"story.{ch['id']}.{part}"] = {
            "en": ch[part]["en"], "zh": ch[part]["zh"], "pinyin": ""
        }

# Cross-check
referenced = set(acts["voKeys"])
missing = sorted(referenced - set(lines))
unused = sorted(set(lines) - referenced - {k for k in lines if k.startswith("story.")
                                            or k.startswith("ui.")
                                            or k.startswith("feedback.")})

if missing:
    print("MISSING COPY for keys referenced by content:")
    for m in missing:
        print(f"  {m}")
    sys.exit(1)

# Group for the script
groups = {}
for k in sorted(lines):
    groups.setdefault(k.split(".")[0], []).append(k)

GROUP_TITLES = {
    "item": "Object names (spoken whenever an object is named or celebrated)",
    "number": "Numbers — record each in isolation, clearly, with a short pause",
    "color": "Colors", "shape": "Shapes", "size": "Sizes",
    "category": "Category names", "position": "Position words",
    "matching": "Prompts — Match It", "counting": "Prompts — Count and Feed",
    "comparing": "Prompts — Big and Small", "shapes": "Prompts — Shape Sorter",
    "spotsame": "Prompts — Find the Same", "puzzle": "Prompts — Puzzle Pieces",
    "daynight": "Prompts — Day and Night", "floatsink": "Prompts — Float or Sink",
    "whatisit": "Prompts — What Is It?", "pattern": "Prompts — Pattern Parade",
    "mirror": "Prompts — Mirror Match",
    "feedback": "Feedback lines (recorded with genuine warmth, never sing-song)",
    "ui": "Interface lines", "story": "Story mode narration",
}

out = []
out.append("# Voice-Over Recording Script\n")
out.append("**GENERATED — do not hand-edit. Edit `content/phrases.json`, "
           "`content/vocab.json`, or `content/story.json` and re-run "
           "`tools/build_vo_script.py`.**\n")
out.append(f"Total lines to record per language: **{len(lines)}** "
           f"(×2 languages = **{len(lines)*2}** files)\n")
out.append("""
## Direction for both voice actors

- **Warm, unhurried, and real.** Speak the way you would to one child sitting
  next to you — not to an audience, not to a camera. No sing-song "kids TV" voice.
- **Slow, but not slowed down.** Natural pace with clear articulation. Leave the
  final consonant/tone intact rather than trimming it.
- **No rising "quiz" inflection** on prompts. A question should sound curious,
  not testing.
- **Feedback lines must sound genuinely pleased**, not performed. These play
  hundreds of times; anything theatrical becomes grating by the third day.
- **Never sound disappointed.** There are no failure lines in this app by design.
  The "retry" lines are encouraging redirections, not corrections.

### Mandarin specifics
- Standard Mandarin (普通话), Beijing-neutral, no regional colouring.
- **Tones must be fully realised**, including neutral tones (轻声) — a child is
  learning pronunciation from this audio and will copy exactly what they hear.
- Observe 儿化 only where written. Do not add it.
- Numbers 一 through 十 are recorded in isolation and must be usable in any
  counting position, so keep 一 as first tone (yī), not the sandhi variant.

### English specifics
- Neutral North American or neutral British — pick one and stay consistent
  across every file.
- Fully articulate final consonants ("eight", not "eigh").

### Technical
- 48 kHz, 24-bit WAV masters; deliver mono. App bundles 128 kbps mono MP3.
- Silence trimmed to 80–120 ms head, 150–250 ms tail.
- Peak −3 dBFS, loudness normalised to −16 LUFS integrated.
- One file per line, named exactly as the **Key** column with dots replaced by
  slashes: `counting.ask` → `assets/audio/vo/en/counting/ask.mp3`.
- **File trees for `en/` and `zh/` must be identical.** The build fails otherwise.
""")

for g in ["story", "ui", "feedback", "number", "color", "shape", "size",
          "category", "position", "matching", "counting", "comparing", "shapes",
          "spotsame", "puzzle", "daynight", "floatsink", "whatisit", "pattern",
          "mirror", "item"]:
    if g not in groups:
        continue
    out.append(f"\n## {GROUP_TITLES.get(g, g)}\n")
    out.append(f"*{len(groups[g])} lines*\n")
    out.append("| Key | English | 中文 | Pinyin |")
    out.append("|---|---|---|---|")
    for k in groups[g]:
        v = lines[k]
        out.append(f"| `{k}` | {v['en']} | {v['zh']} | {v.get('pinyin','')} |")

(DOCS / "VO_SCRIPT.md").write_text("\n".join(out) + "\n", encoding="utf-8")

print(f"lines per language : {len(lines)}")
print(f"total audio files  : {len(lines)*2}")
print(f"referenced by content: {len(referenced)}  (all have copy)")
if unused:
    print(f"defined but not yet referenced by any round: {len(unused)}")
    for u in unused[:10]:
        print(f"  {u}")
print("\nwrote docs/VO_SCRIPT.md")
