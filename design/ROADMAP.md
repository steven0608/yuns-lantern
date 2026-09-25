# Design roadmap — Yun's Lantern expansion

Design canvas: https://claude.ai/artifact/FTrD2dDapcDbEWJ6j5B61F
Each iteration: build the next unchecked items → run the validators → review → publish to the canvas → tick here → note what changed in the log.

## Backlog

### Iteration 1: structure ✅
- [x] 15 engines, 75 games, EN + 中文 (`tools/build_expansion.py` → `content/catalog.json`, `docs/CATALOG.md`)
- [x] 75 Lantern Tales outlined: titles, goals, linked games, synopses in EN + 中文 (`content/library.json`, `docs/LIBRARY.md`)
- [x] Tales 1–5 fully written (Numbers)
- [x] `tools/validate_expansion.py` gate
- [x] `docs/EXPANSION.md` handoff spec v3
- [x] Canvas: Game catalog board and Story library board

### Iteration 1b: handoff (moved up, the app is being built now) ✅
- [x] `design/HANDOFF.md`: platforms (GitHub Pages web, iPhone, iPad), responsive rules, phase prompts V2, E1–E5, R, asset contract, definition of done
- [x] Ownership split agreed with the app session (it owns lib/, assets/, CI and git; design owns design/, docs/EXPANSION.md, catalog/library)

### Iteration 2: brand
- [ ] Logo: mark + EN wordmark + 中文 wordmark + lockups (horizontal, stacked, app-icon crop), SVG
- [ ] Name exploration board (keep Yun's Lantern + 3 alternatives, both languages)
- [ ] Landing page design on the canvas (EN + 中文)
- [ ] Landing page source in `landing/` (static, no third-party requests)

### Iteration 3: engine and game art
- [ ] 15 engine (land) icons
- [ ] 63 new game icons (composed from engine + theme art)
- [ ] New IA screens, each at iPad 1194 × 834 **and** iPhone 844 × 390: Home v3 (3 doors), Lands, Land → 5 games, Books shelf, Reader (EN / 中文 / Both)
- [ ] Web-only screens: start screen (tap Yun to begin), portrait "turn your phone" picture, desktop letterbox

### Iteration 4: vocabulary art
- [ ] SVG item art for the 64 vocab items (replaces the emoji placeholders), batch 1 of 2
- [ ] Batch 2 + new expansion vocab (festivals, family, body)

### Iterations 5–7: stories
- [ ] Tales 6–30 written
- [ ] Tales 31–55 written
- [ ] Tales 56–75 written
- [ ] Tale page art template + covers for all 75

### Iteration 8: audio
- [ ] Music loops (lands, map, bedtime), synthesized placeholders, `design/audio/`
- [ ] New SFX (pencil, paint, drum, bell, card_flip, pour) via `tools/build_sfx.py`
- [ ] VO script v3 (games + tales), both languages, for voice actors
- [ ] English placeholder narration for tales 1–5 (debug only; no local Mandarin voice available: needs a voice actor)

### Iteration 9: video
- [ ] Animatic / trailer from canvas assets, `design/video/` (mp4, 1194 × 834 and 1080 × 1920 cut)

### Iteration 10: screens per engine
- [ ] One mock screen per new engine (15 boards)

### Iteration 11: handoff
- [ ] Refresh `design/HANDOFF.md` with everything the later iterations added
- [ ] Full review pass: accessibility, contrast, touch targets, copy, both languages

### Known issues to fix
- [x] `count_feed` supply 7–10: resolved in the widget (shows ≤ 6, refills from supply)
- [ ] Palette `inkSoft` fails 4.5:1 for small text on paper (4.26:1)

## Log
- **Iteration 1b**: HANDOFF.md for the app session (web + iPhone + iPad); ownership split; Pages branch mismatch flagged (workflow triggers on main, repo uses master).
- **Iteration 1**: catalog + library + validators + spec v3; tales 1–5; canvas boards "Game catalog" and "Story library".
