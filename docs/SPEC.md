# Yun's Lantern / 小云的灯笼 — Build Specification v2

Bilingual (简体中文 / English) learning app for ages 3–5. App Store Kids Category, 4+, no advertising.

Read alongside `docs/MONETIZATION.md` (revenue plan) and `CLAUDE.md` (hard rules).

---

## 1. What this is

A story-driven collection of 12 mini-games. Yun the red panda must relight the great lantern by collecting eight lights, one per chapter. Each chapter gates three activities drawn from a real preschool math-thinking curriculum.

**Content is data, not code.** All 302 rounds, 8 chapters, 64 vocabulary items and 166 voice lines live in `content/*.json`, generated and verified by `tools/`. Claude Code implements the *engines*; the content already exists and must not be re-invented in Dart.

| File | What it holds |
|---|---|
| `content/vocab.json` | 64 objects with EN/ZH/pinyin + attributes (color, shape, size, category, floats, timeOfDay) |
| `content/phrases.json` | 102 spoken UI/prompt lines, both languages |
| `content/story.json` | 8 chapters, final narrative copy both languages |
| `content/activities.json` | **Generated.** 302 playable rounds across 12 activities |
| `tools/build_content.py` | Regenerates activities.json (deterministic, seed 20260819) |
| `tools/validate_content.py` | **Gate.** Fails CI on incoherent content |
| `tools/build_vo_script.py` | Regenerates the voice-actor script; fails if any line is missing |

Run order: `build_content.py` → `validate_content.py` → `build_vo_script.py`.

---

## 2. Non-negotiable constraints

| Rule | Detail |
|---|---|
| No third-party ads | Zero ad SDKs. Kids Category bans them outright. |
| No third-party analytics | No Firebase, Crashlytics, Sentry, Amplitude, Segment. Apple's first-party App Analytics only (no code needed). |
| No data collection | No accounts, email, name, birthdate, photos, mic, location, contacts, IDFA/IDFV. |
| No network calls | Except StoreKit. Must work fully in airplane mode. |
| No links out | Unless behind the parental gate. |
| No purchase UI for the child | Locked content is invisible to them, not padlocked. |
| No fail states | No X marks, buzzers, red flashes, timers, or score deductions anywhere. |
| Restore Purchases | Required, or Apple rejects. |

---

## 3. Stack

Flutter (stable) + Flame. `flutter_localizations`, `intl`, `flame_audio`, `shared_preferences`, `in_app_purchase` (StoreKit 2 directly — **not** RevenueCat; App Review has flagged it as a third party in kids apps).

Before adding any package, check transitive deps for network or identifier access. Prefer writing 100 lines to adding an unaudited dependency.

---

## 4. Project structure

```
lib/
  core/
    tokens.dart            design constants (§6)
    content/
      content_loader.dart  parses content/*.json at startup, typed models
      models.dart          VocabItem, Round, Activity, Chapter
    audio/
      audio_service.dart   VO + SFX, locale-routed, ducking, interrupt-safe
    locale/locale_controller.dart
    storage/prefs.dart
    progress/progress_service.dart
    iap/purchase_service.dart
  games/
    shared/
      activity_scaffold.dart   standard shell: home button, replay VO, no score
      draggable_item.dart      drag + snap + hit slop + soft return
      drop_target.dart
      celebration.dart
      gentle_hint.dart         idle + miss escalation (§7)
    count_feed/ match_it/ big_and_small/ shape_sorter/ find_the_same/
    where_is_it/ puzzle_pieces/ day_and_night/ float_or_sink/ what_is_it/
    pattern_parade/ mirror_match/
  story/
    map_screen.dart        the 8 chapter map, lights collected
    scene_player.dart      open / beat / close narration beats
  screens/
    home_screen.dart
    parent/parent_gate.dart
    parent/parent_area.dart
assets/
  content/                 the JSON files, bundled
  images/
  audio/sfx/
  audio/vo/en/  audio/vo/zh/    identical trees — enforced by test
```

---

## 5. The 12 activities

| id | EN / 中文 | Skill | Age | Rounds | Free |
|---|---|---|---|---|---|
| `count_feed` | Count and Feed / 数一数 | counting, 1:1 correspondence | 3+ | 30 | ✅ |
| `match_it` | Match It / 配对 | classification (color/shape/size/category) | 3+ | 23 | ✅ |
| `shape_sorter` | Shape Sorter / 形状 | shape recognition | 3+ | 24 | ✅ |
| `find_the_same` | Find the Same / 找相同 | visual discrimination | 3+ | 30 | ✅ |
| `float_or_sink` | Float or Sink / 沉与浮 | science, open-ended | 3+ | 12 | ✅ |
| `what_is_it` | What Is It? / 猜一猜 | silhouette recognition | 3+ | 24 | ✅ |
| `big_and_small` | Big and Small / 比大小 | size ordering | 3+ | 15 | — |
| `where_is_it` | Where Is It? / 在哪里 | spatial position | 3+ | 18 | — |
| `puzzle_pieces` | Puzzle Pieces / 拼图 | part–whole | 3+ | 16 | — |
| `day_and_night` | Day and Night / 白天黑夜 | time concepts | 4+ | 14 | — |
| `pattern_parade` | Pattern Parade / 排排队 | AB/AAB/ABB/ABC patterns | 4+ | 80 | — |
| `mirror_match` | Mirror Match / 照镜子 | symmetry | 4+ | 16 | — |

**302 rounds total; 143 free.** Round schemas are in `activities.json`; each round carries the exact `vo` keys it needs.

`minAge` gates visibility: the parent sets the child's age once, and 4+ activities stay hidden until then. This is not a lock — it is the difference between an app that fits a 3-year-old and one that frustrates her.

---

## 6. Design tokens

```dart
const double kMinTouchTarget = 88.0;   // ~2cm on iPad — NNG minimum for young children
const double kHitSlop        = 24.0;
const double kMinTargetGap   = 64.0;
const int    kMaxInteractiveItems = 6; // enforced in validate_content.py

const Duration kIdleHintDelay     = Duration(seconds: 8);
const Duration kIdleHintRepeat    = Duration(seconds: 12);
const Duration kCelebrationLength = Duration(milliseconds: 1800);
const Duration kStandardEase      = Duration(milliseconds: 260);
const Curve    kStandardCurve     = Curves.easeOutCubic;
```

Warm, medium-saturation palette. No pure-white backgrounds. Never encode meaning in colour alone.

---

## 7. Interaction rules (every activity)

1. **Tap and drag only.** No pinch, rotate, double-tap, long-press, multi-finger.
2. **Generous snapping.** Drop within radius → snaps. Drop in empty space → soft float home, no penalty sound.
3. **Miss escalation:** 1st miss, item returns, neutral sound. 2nd, correct target pulses. 3rd, a hand animates the correct move. The child always succeeds. Draw feedback lines from `feedback.retry*` and `feedback.hint*`, rotating so nothing repeats twice running.
4. **Idle:** 8s → replay shortened prompt. 20s → demonstrate.
5. **Every touch responds** — scale-bump + soft sound, even on décor.
6. **Completion:** celebration ~1.8s, rotate `feedback.success1-4`, then replay-or-home. Never auto-advance.
7. **Home button** top-left, ≥88pt. No hamburger, no tabs, no text buttons in child UI.

---

## 8. Story mode

`content/story.json` holds final copy. Each chapter: `open` beat → 3 activities → `beat` narration midway → `close` beat → one coloured light lands on the map.

- Narration is **audio-first with an illustrated still**. No animated cutscene — you cannot afford one and a 3-year-old doesn't need it. A gentle parallax pan over a good illustration is enough.
- Every beat is skippable by tapping. Never trap a child in narration.
- The map screen shows 8 lanterns; collected ones glow. Uncollected paid chapters are shown as **misty and unreachable, never padlocked** — mystery, not a sales pitch.
- Chapters 1–2 free. Progress persists locally.

---

## 9. Localization

- Zero hardcoded user-facing strings. Everything through ARB or `content/*.json`.
- Locale order: parent override → device locale → `en`.
- **Audio is a localized asset.** `AudioService.playVO('counting.ask')` → `assets/audio/vo/{locale}/counting/ask.mp3`. A test asserts `en/` and `zh/` trees are byte-identical in structure. 166 lines × 2 = **332 files**.
- Bundle Noto Sans SC (OFL). Do not rely on system CJK fallback.
- Child-facing instruction is **audio only**. Text exists for the parent.

---

## 10. Parental gate

Randomly generated two-digit arithmetic problem **written out in words** ("Enter the result of four times seven") with a numeric keypad. Words are the barrier — a pre-reader cannot parse them.

Randomize every time. On failure, return silently to the child home. No lockout, no retry counter.

This is Apple's gate, **not** COPPA verifiable parental consent. Since the app collects nothing, VPC is not triggered.

---

## 11. Parent area (behind gate)

Language toggle · VO and SFX volume · child's age (drives `minAge` gating) · activity visibility · break reminder (10/15/20 min/off — suggests, never locks mid-activity) · **purchase + restore** · progress ("played Count and Feed 12 times" — no scores, no percentiles, no "behind schedule") · privacy policy · credits.

---

## 12. Build phases

**Phase 1 — Foundations (2 weeks).** Content loader parsing all four JSON files into typed models. `AudioService` with locale routing. The five shared components. Home screen. Parental gate. *Accept when:* one activity plays end-to-end in both languages, driven entirely by `activities.json`, with no hardcoded round data.

**Phase 2 — The six free activities (5 weeks).** `count_feed`, `match_it`, `shape_sorter`, `find_the_same`, `float_or_sink`, `what_is_it`. Story chapters 1–2. Progress persistence. *Accept when:* your daughter plays all six unassisted after one demonstration and never encounters text she must read.

**Phase 3 — Paid content (5 weeks).** Remaining six activities. Chapters 3–8. Age gating. Parent area complete.

**Phase 4 — Real assets (8+ weeks, mostly not code).** Final illustration set. **Native-speaker voice-over for all 332 files** — do not ship machine TTS for Mandarin; your daughter is learning tones from it. Accessibility pass.

**Phase 5 — Launch.** StoreKit unlock + restore. Privacy policy. Age questionnaire (4+). Kids Category, 5-&-under band. Bilingual listing led by *Mandarin learning* (see MONETIZATION.md). TestFlight with 3–5 families.

---

## 13. Testing with a 3-year-old

She cannot give verbal feedback. Observe instead:

- Hand her the device with **no instruction**. Where she taps first is your real affordance test.
- Count mis-taps near targets. Frequent → targets too small or too close.
- When she puts it down is your true session length. Design to it, don't fight it.
- Does she succeed without you? Where she looks up at you is either a defect or an intended co-play moment — decide which.
- **Spontaneous return next day is the strongest signal there is.**

Test with 2–3 other preschoolers before launch. She is biased toward loving anything you made.

---

## 14. Known risks

- **Art and audio cost more than code.** 332 voice files and a consistent illustration set are the real budget. Everything else is a weekend.
- **Kids Category discovery is hard** and you cannot advertise inside kids apps. Hence the school channel.
- **Don't enable the subscription** until you've shipped three monthly chapters on time. Taking recurring money for static content generates refunds and 1-star reviews.
- **Regulatory drift.** Re-check Apple's App Review Guidelines and FTC COPPA guidance before submitting rather than trusting this document; COPPA's amended rule had an April 2026 full-compliance deadline and Apple revised age ratings in 2025.
