# design/

Design canvas: https://claude.ai/artifact/FTrD2dDapcDbEWJ6j5B61F

| Path | What |
|---|---|
| `svg/` | Vector source for every asset (edit via the generator, not by hand) |
| `png/` | Exports for the app; copied into `assets/images/**` by `tools/sync_design_assets.py` |
| `gen_assets.py` | Draws the SVGs from the game's palette (`lib/core/tokens.dart`) and Yun's painter geometry |
| `render.py` | SVG → PNG with headless Chromium (Playwright) |
| `ROADMAP.md` | Design iterations: done and next |
| `HANDOFF.md` | Build order and prompts for the Claude Code session building the app |

Regenerate: `python gen_assets.py && python render.py`, then ask the app session to re-sync.
