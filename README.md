# Yun's Lantern / 小云的灯笼

Bilingual (简体中文 / English) learning app for ages 3–5. Kids Category, no advertising.

## Read in this order

1. `docs/SPEC.md` — what to build
2. `docs/MONETIZATION.md` — how it makes money
3. `CLAUDE.md` — rules Claude Code must never break
4. `docs/VO_SCRIPT.md` — hand this to your voice actors

## Content pipeline

All game content is data. Never hardcode a round in Dart.

```bash
python3 tools/build_content.py     # vocab.json -> activities.json (302 rounds)
python3 tools/validate_content.py  # fails CI on incoherent content
python3 tools/build_vo_script.py   # -> docs/VO_SCRIPT.md, fails on missing copy
python3 tools/revenue_model.py     # scenario modelling
```

Run all three build steps after any content edit. `validate_content.py` must exit 0.

## What exists

| | |
|---|---|
| Vocabulary | 64 objects, EN + 中文 + pinyin, with attributes |
| Activities | 12 mini-games, **302 playable rounds** |
| Story | 8 chapters, final bilingual copy |
| Voice lines | 166 per language = **332 audio files** |
| Free tier | 6 activities (143 rounds) + chapters 1–2 |

## Getting started with Claude Code

Point it at `CLAUDE.md` and `docs/SPEC.md`, then build Phase 1 only:
the content loader, audio service, and the five shared components in
`games/shared/`. Those determine the quality of all twelve games — get
them right before generating any activity code.
