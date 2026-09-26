# Yun's Lantern / 小云的灯笼 — Expansion Spec v3

From 12 activities and 8 chapters to **75 games** and **75 learning stories**, one bilingual app on three targets: **web (GitHub Pages)**, **iPhone** and **iPad**. Build order and per-phase prompts: `design/HANDOFF.md`.

Read with `docs/SPEC.md` (v2, still authoritative for everything not changed here), `CLAUDE.md` (hard rules, unchanged and binding on every new game) and `docs/MONETIZATION.md`.

| Doc / file | What it holds |
|---|---|
| `content/catalog.json` → `docs/CATALOG.md` | 15 engines × 5 games = 75 games, EN + 中文, age, free tier, planned rounds |
| `content/library.json` → `docs/LIBRARY.md` | 15 themes × 5 tales = 75 Lantern Tales, EN + 中文 titles, goals, synopses, page text |
| `tools/build_expansion.py` | Source of truth for both JSON files. Edit here, never the JSON |
| `tools/validate_expansion.py` | Gate: counts, links, both languages, page limits, no fail-state words |
| `design/` | Vector asset set (SVG + PNG) and its generator; design canvas link in `design/README.md` |
| `design/ROADMAP.md` | What is done and what is next, by iteration |

Run order after any content edit:

```bash
python3 tools/build_content.py && python3 tools/validate_content.py && python3 tools/build_vo_script.py
python3 tools/build_expansion.py && python3 tools/validate_expansion.py
```

---

## 1. Decisions

| Question | Decision | Why |
|---|---|---|
| Two apps (Chinese, English)? | **One app, both languages.** Parent picks the language; default follows the device. **US App Store only** (Steven, 2026-09-25), with an English listing and a 简体中文 localization. | One codebase, one purchase, Family Sharing works, and bilingual families switch freely. Already how v2 works (§9 of SPEC). |
| A third language mode? | **Add "Both" (双语) for stories:** each page is read in the child's main language, then the other. | This is the Mandarin-learning pitch in MONETIZATION.md. |
| 75 separate mini-games? | **75 games on 15 engines.** Each engine is one Flutter widget tree driven by data. A game is an engine + a content set + art. | 15 well-tested engines beat 75 one-offs for one maintainer. Adding a game is data, not code (CLAUDE.md: content is data). |
| How does a 3-year-old find 75 games? | **Never show more than 6 at once** (§4). | Choice overload; the 6-item rule applies to menus too. |
| Free tier | **12 games + story chapters 1–2 + 5 tales** (was 6 games) at App Store release. **Until then everything is free** on web and TestFlight (`YL_ALL_FREE=true`, Steven 2026-09-25). | Parents see the breadth before paying; testers see everything. Revisit with MONETIZATION.md. |
| Name | **Keep Yun's Lantern / 小云的灯笼.** | Works in both languages, ties to the Lantern Festival, already in the content. Alternatives on the design canvas. |

## 2. What stays the same

Everything in CLAUDE.md. For the new engines specifically:

- **Tap and drag only.** Trace It is a drag along a path. Music is tapping. No engine may use the microphone, camera or speech recognition, even for "say the word" games. Listening games play audio; the child taps.
- **No fail states.** `try_see` has no wrong guess: both choices lead to watching what happens. `color_fill` and `night_sky` have no right answer. `music_echo` praises any tap sequence and replays the pattern as the hint.
- **Max 6 interactive items** on screen, including menus. (`count_feed` rounds with `supply` above 6 are fine: the widget shows at most 6 and refills from the supply.)
- Audio carries every instruction; text is for parents.

## 3. The 15 engines

Each engine is one folder in `lib/games/<engine>/`, depends only on `core/` and `games/shared/`, and reads its rounds from content. Build them in this order (shared machinery first):

| Order | Engine | What the child does | Reuses | Hint escalation (miss 2 → pulse, miss 3 → hand) |
|---|---|---|---|---|
| 1 | `count_feed` | drag N items to a character | exists | pulse the feeder, hand drags one |
| 2 | `sort_bins` | drag into 2–3 bins | DropTarget | pulse the right bin |
| 3 | `find_same` | tap the match | TouchTarget | pulse the match |
| 4 | `silhouette` | tap the object that fits a shadow | find_same | reveal colour gradually |
| 5 | `order_line` | drag 3–5 into slots | DropTarget | pulse next slot, ghost the item |
| 6 | `pattern` | tap or drag what comes next | order_line | replay the pattern aloud |
| 7 | `jigsaw` | drag pieces into slots | DropTarget | outline the slot |
| 8 | `position` | tap or drag to a spoken place | find_same | pulse the place |
| 9 | `mirror` | tap cells or drag parts | jigsaw | flash the mirrored cell |
| 10 | `try_see` | choose a guess, watch the result | new | none needed: every choice is fine |
| 11 | `listen_find` | hear a word, tap the picture | find_same | replay word, then pulse |
| 12 | `memory_pairs` | flip 4–6 cards | find_same | briefly peek both cards |
| 13 | `trace` | drag along a dotted path | new | the dot leads; a hand traces |
| 14 | `color_fill` | pick a colour, tap a region | new | none: open-ended |
| 15 | `music_echo` | tap the pattern back | new | pattern plays again, slower |

**Build status** lives in `catalog.json` as `status`: `built` (rounds exist in `activities.json`) or `planned`. As of 2026-09-26: **34 built, 681 rounds**. `validate_expansion.py` checks both directions, so a game cannot be marked built without content, or hold content while marked planned.

Three catalog games are blocked on engine work, not content, and stay `planned` until E3:

| Game | Engine | What the engine needs |
|---|---|---|
| `melt_or_not` | `try_see` | staging other than a water tank (sun, warmth) |
| `plant_grows` | `try_see` | a result that plays over time, not an instant outcome |
| `who_made_tracks` | `silhouette` | a panel that shows a *trace* of the answer (footprints), not the answer's own outline |

Round schemas: add one per engine to `content/activities.json` via `tools/build_content.py`, following the existing 12. Each round lists its `vo` keys, as now.

## 4. Finding things (information architecture)

```
Home ──┬── Story (map: 8 chapters)           existing
       ├── Play  (Lantern Lands: 15 lands)   new: one land per engine
       │     └── a land shows its 5 games (≤ 6 targets)
       └── Books (Lantern Tales: 75 stories) new: a shelf per theme, 5 books each
```

- Home keeps **3 big doors** (Story, Play, Books), not a grid of 75.
- **Play** shows lands as big icons you drag sideways, with arrow buttons as well (drag alone is hard to discover). Each land opens to its 5 games. Age gating hides 4+ and 5+ games until the parent sets the age.
- **Books** shows theme shelves the same way; a book opens to its cover, then pages.
- Locked (unpaid) lands and books are **not shown to the child** (CLAUDE.md). Parents see everything in the parent area.
- Each tale ends with a "play" button to its linked game (`game` in library.json). This is how stories and games teach together.

## 5. Lantern Tales (stories)

- 6–8 pages. Each page is one illustrated still (gentle pan) + one or two sentences, ≤ 22 English words / ≤ 36 汉字 (enforced).
- **Read to me** (default): narration plays, the child taps to turn the page. No auto-advance (CLAUDE.md).
- **Language**: follows the app language, or "Both" (§1).
- Tap any character or object on a page for a small reaction + its word (vocab.json), in the current language.
- Text shows under the picture for parents; words highlight as they are read.
- Page text: `library.json → tales[].pages[] = {en, zh}`. Page art: `assets/images/tales/<tale_id>/p<N>.png`, 1194 × 834 (iPad landscape), same art style as `design/svg`.

## 6. Audio

| Set | Files (per language) | Source |
|---|---|---|
| Existing VO | 166 | `docs/VO_SCRIPT.md` |
| Game prompts, 63 new games × ~3 lines | ~190 | added to phrases.json by the build |
| Tale narration, 75 tales × ~6.5 pages | ~490 | library.json |
| New vocabulary (festivals, body, family, tones) | ~80 | vocab.json additions |
| **Total** | **~926 × 2 languages ≈ 1,850 files** | |

- Layout unchanged: `assets/audio/vo/{en,zh}/<group>/<key>.mp3`, identical trees (parity test).
- **Native-speaker Mandarin is required for release** (SPEC §12). Placeholder machine voices are allowed in debug builds only and must never ship; mark them with `assets/audio/vo/_PLACEHOLDER` and fail the release build if it exists.
- Music: one calm loop per land + story map + bedtime. Instrumental, no lyrics, −18 LUFS, ducked under VO. Nursery rhymes in Rhyme Time use public-domain melodies only (e.g. Twinkle Twinkle, 两只老虎).
- SFX: `tools/build_sfx.py` (soft, no buzzers). New engines add: `pencil` (trace), `paint`, `drum`, `bell`, `card_flip`, `pour`.

## 7. Video

- **App Store app preview** (15–30 s, iPad 1194 × 834 @2x, silent-safe captions): Home → a tale page → Count and Feed → map light collected. Capture from the real app (Apple requires real footage), then add titles.
- Design-stage animatic from the canvas assets: `design/video/` (built by the design loop, see ROADMAP), for pitch and landing page only.

## 8. Landing page

One static page, both languages (`/` English, `/zh/` 简体中文), no cookies, no analytics, no third-party scripts (same rule as the app). Sections: hero with Yun + App Store badge, "Mandarin for young children" pitch, what's inside (games, tales, story), for parents (privacy: collects nothing), pricing (one purchase), FAQ, footer with privacy policy. Design on the canvas; source in `landing/` (produced by the design loop).

## 9. Build phases for Claude Code

Keep SPEC.md phases 1–5 for the first release. The expansion ships as updates:

| Phase | Scope | Accept when |
|---|---|---|
| E1 | Engine framework: engine registry reads `catalog.json`; Play → Lands → games; Books shelf reading `library.json`; "Both" language mode | A land and a tale work end to end in both languages, driven only by JSON |
| E2 | Engines 2–9 (reuse-heavy), their 40 games' rounds in content | Validators pass; golden tests per engine in both locales |
| E3 | Engines 10–15 (new interactions: trace, fill, music, memory, try-see, listen) | Touch-target test and no-fail tests pass for each |
| E4 | All 75 tales: page art + narration | Every tale readable in EN, ZH and Both |
| E5 | Landing page, store listings, app preview video | Page has no third-party requests (checked in CI) |

Prompts for each phase: `design/HANDOFF.md` (produced by the design loop).

## 10. Platforms

One Flutter codebase: web (GitHub Pages, free tier, offline after first load), iPhone and iPad (landscape, Kids Category). Responsive rules, web specifics and per-platform acceptance checks are in `design/HANDOFF.md` §1. Touch targets never shrink on iPhone; layouts drop to two rows instead.
