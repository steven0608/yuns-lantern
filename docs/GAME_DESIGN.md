# Game Design Brief — for everyone building a mini-game

Read `CLAUDE.md` (hard rules) and `docs/SPEC.md` §5–§7 first. This file
describes how each of the 12 engines should play and the shared toolkit they
are built from. `lib/games/count_feed/count_feed.dart` is the reference
implementation: copy its structure.

## The contract

Each game is one file, `lib/games/<id>/<id>.dart`, exporting a `GameDef`
already imported in `lib/games/registry.dart`. **Never edit registry.dart or
another game's folder.** Games import only `core/` and `games/shared/`.

```dart
final matchItGame = GameDef(
  id: 'match_it',
  build: (rc) => MatchIt(rc: rc),           // one round
  prompt: (r) => [...],                     // VO keys spoken at round start
  shortPrompt: (r) => [...],                // 8s idle nudge (optional)
  background: const [Color(..), Color(..)], // warm 2-stop gradient
);
```

`RoundContext rc` gives: `rc.round` (typed JSON from `content/activities.json`),
`rc.hints` (HintController), `rc.audio`, `rc.content` (vocab lookups:
`rc.content.item(id).color` etc.), `rc.say([...keys])`, `rc.complete()`,
`rc.rng` / `rc.shuffled()` (deterministic per round — use for any layout
shuffle, never `Random()`).

**Only speak VO keys that exist** — the round's own `vo` list, `item.<vocabId>`,
or keys in `content/phrases.json`. Never invent a key; never put words on screen.

## Shared toolkit (`lib/games/shared/`)

| Widget | Use it for |
|---|---|
| `DraggableItem(data:, size:, onTouched: rc.hints.touched, child:)` | anything the child drags |
| `DropTarget(id:, willAccept:, onAccept:, onReject:, pulse:)` | bins, slots, mouths. Call `rc.hints.miss()` in `onReject` |
| `ChoiceCard(id:, correct:, hints:, onCorrect:, hintKey:)` | tap-to-answer. Handles miss/pulse/wobble itself |
| `ItemCard(id:, size:)` | the standard rounded card an item sits on |
| `GentlePulse(active:)` | glow the correct target when `rc.hints.level.value >= 1` |
| `rc.hints.guide = () => HintMove(fromKey, toKey)` | tell the hint hand the correct move (GlobalKeys). Tap games: `HintMove(key)` |
| `rc.hints.succeeded()` | after each correct step (resets escalation) |
| `ItemArt(id, size:, silhouette:)` / `Emoji(glyph)` | placeholder art — never draw item names |
| `Palette`, `k*` tokens in `core/tokens.dart` | colours and sizes. No `Colors.red`, no pure white |

## Non-negotiables in every game

- Tap and drag only. ≥88px visible targets (`ItemCard` ≥ `kMinTouchTarget`),
  ≥64px visible gap between targets (Wrap spacing `kMinTargetGap - kHitSlop`,
  since each target carries 12px slop padding each side).
- ≤ 6 interactive items on screen (`kMaxInteractiveItems`), even if the round
  data lists more — show the first 6 (or refill as items are used).
- No fail states: wrong → soft return + `rc.hints.miss()`. Never red, X, buzz.
- The child always finishes: every round must be completable, and the hint
  hand must be able to demonstrate the next correct move at any moment.
- Layout must work at **iPad 1366×1024 / 1180×820** and **iPhone 844×390**
  landscape (the scaffold gives you the content box; use LayoutBuilder and
  scale sizes from `box.maxHeight`, clamped to ≥ `kMinTouchTarget`).
- Completion: when solved, speak any closing line then call `rc.complete()`
  exactly once (the scaffold celebrates; don't build your own).

## Per-game design

### match_it — Match It / 配对
Round: `attribute` (color|category|shape|size), `bins[{key, items[]}]` (3 bins × 2).
Three bins across the bottom, six item cards scattered above (shuffled). Bin
face shows the key visually, never as text: colour → a soft swatch + a blob of
that colour; shape → the outline shape drawn with CustomPaint; category → the
category emoji from `content.art.categories`; size → a nested-squares glyph
scaled small/medium/big. Drag item → correct bin accepts (item joins a little
pile inside the bin); wrong bin rejects. Prompt: `vo` as given. On accept say
`item.<id>`.

### big_and_small — Big and Small / 比大小
Round: `orderedSmallToLarge` (3 ids). Three steps of a ladder/staircase,
visibly short → tall, left to right. Items (shuffled) in a tray; drag each to
its step. Items render at the same size in the tray (the knowledge is
real-world size); once placed, scale them 0.8/1.0/1.2 to reinforce.
Prompt: `comparing.order_small_big`. Hint: next unplaced smallest item → its step.

### shape_sorter — Shape Sorter / 形状
Round: `shapes` (3–5), `examples{shape: [ids]}`, `variant`. A board of holes
(CustomPaint outlines: circle, square, triangle, rectangle, semicircle) and
matching coloured shape pieces to drag in. Pieces never need rotating — draw
them already oriented. On accept: `shape.<x>`, and an example item from
`examples[x]` pops out of the hole briefly. `variant` picks colour set / layout.

### find_the_same — Find the Same / 找相同
Round: `reference`, `distractors[3]`. Reference card large on the left in a
frame; four `ChoiceCard`s (reference + distractors, shuffled) on the right.
Prompt `spotsame.intro`; correct → `item.<ref>` then complete.

### where_is_it — Where Is It? / 在哪里
Round: `pair` [a,b], `target`, `actor`, `container`. Two scene cards side by
side: in each, the container (placeholder art `box`/`basket` exist in
`content.art.items`; `cup`/`bowl` are vocab) with the actor positioned
according to one of the pair — up high/down low, inside/outside,
in front/behind (behind = partly occluded by the container, smaller, dimmer).
Child taps the scene matching `target`. Prompt: `item.<actor>`,
`position.<target>`. Correct → `position.<target>`.

### puzzle_pieces — Puzzle Pieces / 拼图
Round: `tier` (missing|four), `scene` (a chapter id; art in
`content.art.scenes`), `pieces`, `candidates`. Render the scene with
`SceneStill` (`lib/core/ui/scene_still.dart`) inside a 2×2 grid. **missing**: one quadrant
empty, 3 candidate pieces (the right one + quadrants of two *other* scenes)
to drag in. **four**: all four quadrants shuffled in a tray, drag each into
the frame. Clip each quadrant with ClipRect + OverflowBox/Align.

### day_and_night — Day and Night / 白天黑夜
Round: `day[]`, `night[]`, optional `either[]`. Split scene: sunny half
(left) and starry half (right), each a big drop zone. Drag cards to a side.
`either` items are accepted by both sides and trigger `daynight.either`.
Prompt: `daynight.intro`; on accept say `item.<id>`.

### float_or_sink — Float or Sink / 沉与浮
Round: `floats[]`, `sinks[]` (up to 8 total — **show at most 6**: take up to 3
of each). An open-ended sandbox: a big water tank; drag any item in. It
bobs at the surface (`floatsink.floats`) or drifts to the bottom
(`floatsink.sinks`) with splash/bubble SFX, then stays there. **There are no
wrong answers** — never call `miss()`. Round completes when every item is in
the water. Prompt: `floatsink.intro`. Idle demo: any remaining item → water.

### what_is_it — What Is It? / 猜一猜
Round: `tier` (silhouette|reveal), `answer`, `distractors[2]`. Big mystery
panel: **silhouette** shows `ItemArt(answer, silhouette: true)`;
**reveal** shows the item under a soft blur/mask that clears over ~10s. Three
`ChoiceCard`s below. Correct → the panel flips to full colour, say
`item.<answer>`, then complete. Prompt `whatisit.intro`.

### pattern_parade — Pattern Parade / 排排队 (4+)
Round: `sequence[]`, `answer`, `choices[3]`. A parade line of item cards
(slight bounce, marching feel) ending in a dashed empty slot. Three choices
below; drag (or tap) the right one into the slot. Prompt `pattern.intro`,
`pattern.whatnext`. On success the whole line hops in sequence.

### mirror_match — Mirror Match / 照镜子 (4+)
Round: `tier` (simple|detailed), `subject`, `cells` (4|6). A mirror line
down the middle. The subject is cut into a grid of `cells` (2 cols × 2 rows,
or 2 × 3). The left column is shown; the right column's slots are empty. The
right pieces are the left pieces **flipped horizontally** (Transform scale
x=-1) — true symmetry. They sit shuffled in a tray; drag each into its row.
Prompt: `mirror.intro`, `item.<subject>`; on completion say `item.<subject>`.

## UX quality bar

Warm, soft, tactile. Everything springs slightly when touched; items cast
soft shadows; placed items settle with a tiny bounce. Generous whitespace.
Use `Palette` colours; each game has its own 2-stop background gradient so
games feel distinct. Nothing flashes, nothing is sudden, nothing is red.
