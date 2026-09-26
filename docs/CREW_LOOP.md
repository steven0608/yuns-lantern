# Crew loop — how the app keeps getting built

The app session runs this loop until the backlog is empty. Each iteration:

1. **Collect.** Merge any finished crew branch (worktree agent) into `master` — cherry-pick if its base predates a history rewrite. Re-run `python tools/sync_design_assets.py` if the design session announced new exports.
2. **Gate.** `python tools/build_content.py && python tools/validate_content.py && python tools/build_vo_script.py && python tools/validate_expansion.py && flutter analyze && flutter test`. Anything red is fixed before new work starts.
3. **Look.** Build the web app and review the changed screens at 1194×834 and 844×390 in the browser (screenshots), both languages. File what looks wrong as backlog items.
4. **Ship.** Commit, push `master` (CI → Pages + iOS build). Tick the backlog.
5. **Dispatch.** Start the next unchecked backlog item as **one** worktree agent (one at a time: parallel agents exhaust the usage limit and lose work). Agents commit after every working step.
6. **Sync.** Message the design session ("Game folder artifact and asset") about anything that touches its files (design/**, catalog, library) or needs art.

Hard rules for every item: `CLAUDE.md`. Build order: `design/HANDOFF.md` §2. Per-game contract: `docs/GAME_DESIGN.md`.

## Backlog

### V2 — ship the 12 games
- [x] 11 engines merged (count_feed, float_or_sink, what_is_it, big_and_small, pattern_parade, mirror_match, where_is_it, puzzle_pieces, match_it, shape_sorter, find_the_same)
- [x] day_and_night (12/12 v2 engines built)
- [x] DraggableItem follows global finger position (crew recommendation)
- [x] Vocab art matches vocab colour/shape (91 drawings synced; ItemArt prefers them)
- [ ] Every engine: content insets keep 64 px from the home/replay buttons (games_test with `checkGaps: true`)
- [ ] Golden tests per activity at 844×390 and 1194×834, en + zh (HANDOFF V2)
- [ ] Web offline after first visit (service worker caching the app shell + free tier)

### E1 — framework ✅ (Home v3, Lands, Books, reader EN/中文/Both, music)
- [ ] Swap in the design session's Home v3 / Lands / Books / Reader boards when they land
- [x] Land icons from `design/png/lands/<engine>.png` via sync

### E2 — more games on existing engines (data only: rounds + prompts + VO)
Rounds may carry `prompt` / `shortPrompt` VO keys that override the engine default, so a new game needs no Dart.
- [ ] `tools/build_content.py`: a V3 game table (id → engine, from `content/catalog.json`) and builders; `activities.json` entries get `engine`; `validate_content.py` validates by engine
- [ ] count_feed engine: birthday_candles, share_cookies, garden_seeds, bus_stop
- [ ] match_it (sort) engine: tidy_up, weather_wardrobe
- [ ] find_the_same engine: feelings_faces, sock_pairs, spot_the_lantern
- [ ] what_is_it engine: peekaboo_animals, zoom_out, shadow_puppets, who_made_tracks
- [ ] big_and_small (order) engine: ladder_up, stacking_cups, growing_up, morning_routine
- [ ] pattern_parade engine: bead_necklace, lantern_string, flower_path
- [ ] where_is_it engine: hide_seek, owl_tree_house, set_table
- [ ] float_or_sink (try-see) engine: melt_or_not, plant_grows
- [ ] New vocab (festivals, family, body, feelings) with placeholder art; phrases for every new prompt; `tools/build_vo_placeholders.py` for all new keys

### E3 — new engines
- [ ] listen_find (hear a word, tap its picture): first_words, color_words, body_parts, numbers_out_loud, tone_hills
- [ ] memory_pairs (flip 4–6 cards): memory_pairs, word_pairs, festival_pairs, animal_families, shape_pairs
- [ ] trace (drag along a dotted path, generous tolerance): lines_curves, shape_tracing, number_tracing, first_characters, letter_friends
- [ ] color_fill (open-ended painting): color_me, lantern_painter, night_sky, rainbow_mixing, color_by_number
- [ ] music_echo (tap it back; any sequence is praised): echo_drums, animal_choir, rhyme_time, fast_slow, high_low

### E4 — Lantern Tales
- [x] Reader + narration for written tales (5)
- [x] Narration placeholders regenerated whenever the design session writes more tales (30 tales)
- [ ] Tale page art wired as it lands (`design/png/tales/<tale_id>/p<N>.png`)

### E5 / R — launch
- [x] iOS signing via App Store Connect API key + TestFlight upload (`docs/TESTFLIGHT.md`; Steven adds the 4 secrets)
- [x] US App Store only; everything free for testing (`YL_ALL_FREE`)
- [x] Landing page (EN + 中文) at the Pages root, app at `/play/`; CI fails on any third-party URL in landing/
- [x] Logo + lantern-mark favicon and apple-touch-icon
- [ ] StoreKit product + TestFlight signing secrets (Steven: Apple Developer account)
- [ ] Release build fails while `assets/audio/vo/PLACEHOLDER.txt` exists (native-speaker VO required)
