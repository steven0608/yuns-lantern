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
- [x] Logo: lantern mark with Yun's face + EN/中文 wordmarks + lockups (horizontal, stacked, mark, night, favicon) → `design/gen_logo.py`, `design/render_brand.py`
- [x] Name: kept Yun's Lantern / 小云的灯笼 (works in both languages, ties to the Lantern Festival, already in the content) — no alternatives board needed
- [x] Landing page design on the canvas (EN + 中文 + phone)
- [x] Landing page source in `landing/` (`design/build_landing.py`; verified zero third-party requests at 1280 and 390 wide)
- [x] Marketing screenshots `design/png/shots/` (`design/gen_shots.py`)

### Iteration 2b: phone layouts (requested by the app session) ✅
- [x] `design/png/map_phone.png`: 844 × 390 map whose path winds as a 2 × 4 snake (88 pt stops, ≥ 64 pt gaps) + Map (iPhone) board
- [x] Adopt app-side map changes on the Map board: stop 4 → (660,495), last lantern 1.2×

### Iteration 3: engine and game art
- [x] 15 engine (land) icons → design/png/lands/<engine>.png (5 new: listen, trace, color, music, memory)
- [x] Game icons for all 75 catalog games → design/png/games/<game_id>.png (`design/gen_game_icons.py`, composed from the item art on each land's tint)
- [x] New IA screens, each at iPad 1194 × 834 **and** iPhone 844 × 390: Home v3 (3 doors), Lands, Land → 5 games, Books shelf, Reader (EN / 中文 / Both)
- [x] Web-only screens: start screen (tap Yun to begin), portrait "turn your phone" picture (desktop letterbox is built in the app)

### Iteration 4: vocabulary art
- [x] SVG item art for all vocab items, drawn in their vocab.json colour/shape (`design/gen_items.py`); Mirror Match items pixel-checked symmetric
- [x] Refresh the Land boards once game icons exist
- [x] Batch 2 + new expansion vocab (feelings, festivals, family, body, gift, window, candle, cake): 91 items total
- [x] Canvas board "Vocabulary items · 91"

### Iterations 5–7: stories
- [x] Tales 6–30 written
- [ ] Tales 31–55 written
- [ ] Tales 56–75 written
- [ ] Tale page art template + covers for all 75

### Iteration 8: audio
- [x] Music: 5 seamless loops (home, story_map, lands, reader, bedtime) + 2 stings (celebrate, light_found), −18/−16 LUFS, `design/audio/gen_audio.py`
- [x] New SFX (pencil, paint, drum, bell, card_flip, pour), `design/audio/sfx/`
- [ ] VO script v3 (games + tales), both languages, for voice actors
- [ ] English placeholder narration for tales 1–5 (debug only; no local Mandarin voice available: needs a voice actor)

### Iteration 9: video
- [x] 30 s bilingual trailer animatic, 1920 × 1080 + 4:5 cut, `design/video/render_video.py`
- [ ] Trailer v2 once Home v3, Books and vocab art exist (show the real 3-door home and a Reader page); fix the subtitle overlapping a hill lantern on the end card

### Iteration 10: screens per engine
- [ ] One mock screen per new engine (15 boards)

### Iteration 11: handoff
- [ ] Refresh `design/HANDOFF.md` with everything the later iterations added
- [ ] Full review pass: accessibility, contrast, touch targets, copy, both languages

### Known issues to fix
- [x] `count_feed` supply 7–10: resolved in the widget (shows ≤ 6, refills from supply)
- [ ] Palette `inkSoft` fails 4.5:1 for small text on paper (4.26:1)

## Log
- **Iteration 6**: logo + lockups, marketing screenshots, bilingual landing page in `landing/` (zero external requests), "Logo & lockups" and "Landing page" boards.
- **Iteration 5**: 58 new game icons (75 total) + "Game icons · 75" board; Sort It land boards use real icons; US-only + all-free decisions written into HANDOFF/EXPANSION/MONETIZATION.
- **Iteration 4**: 91 vocab items drawn (all vocab.json ids incl. 27 E2 additions), symmetric Mirror Match items verified, bear feeder moved to characters/bear_basket.png; peer notified.
- **Iteration 3**: 13 v3 screen boards (iPad + iPhone), 5 new engine icons, 15 land icons, tales 6–30 written (30/75); vocab attribute fixes proposed to the app session.
- **Iteration 2b**: phone map (map_phone.png @3x + map_phone_stops.json, gap-checked), Map (iPhone) board, iPad map stop 4 / 1.2× lantern; peer notified.
- **Iteration 2 (audio + video)**: music loops, stings, 6 new SFX; 30 s trailer animatic; Catalog + Library boards published; peer notified to sync.
- **Iteration 1b**: HANDOFF.md for the app session (web + iPhone + iPad); ownership split; Pages branch mismatch flagged (workflow triggers on main, repo uses master).
- **Iteration 1**: catalog + library + validators + spec v3; tales 1–5; canvas boards "Game catalog" and "Story library".
