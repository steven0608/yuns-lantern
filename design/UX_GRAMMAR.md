# Visual grammar — "what do I do here?" with no text and no sound

Written 2026-09-26, after Steven played the app and said some games were not clear.

A three-year-old cannot read, may have the sound off, and will not wait. The screen alone
must answer three questions in the first second:

1. **What can I touch?**
2. **Where does it go?**
3. **Which one is being asked about?**

This file is the answer, and it is the same in all 15 engines. One grammar learned once in
Count and Feed transfers to Mirror Match. Build against this; where an engine can't follow
it, that's a bug in the engine, not an exception to the grammar.

---

## 1. The four roles

Everything on screen is exactly one of these. If a thing's role is unclear to *you*, it is
invisible to a child.

| Role | Means | Marks |
|---|---|---|
| **Take** | you can pick this up or tap it | full colour · **drop shadow** (it sits above the scene) · gentle idle bob · scales to 1.08 on touch |
| **Hold** | it goes here | **recessed**: inset shadow, no drop shadow · dashed outline · **ghost of what belongs** at 18% |
| **Ask** | this is the one the question is about | **cream halo**: two soft rings behind it · sits alone at top centre · never has a dashed outline |
| **Scene** | decoration, not interactive | no shadow of any kind · 88% opacity · slightly desaturated · never dashed, never haloed |

### The physical rule that carries it

> **A shadow means you can lift it. A hole means something goes in it.**

Drop shadow (light from above, object raised) versus inset shadow (object sunk into the
surface). This is the one metaphor a child reads with no instruction, so nothing else may
use those two shadows. Décor gets no shadow at all.

### Exact values

```dart
// Take
boxShadow: [BoxShadow(color: Color(0x294A3426), blurRadius: 0, offset: Offset(0, 7))]
idleBob:   translateY -4 px, 2.4 s, ease-in-out, staggered 120 ms per item
onTouch:   scale 1.08, 120 ms, plus the item's sound

// Hold (empty)
decoration: inset 0 3 px 0 rgba(74,52,38,.20)
border:     3 px dashed Palette.rustDeep @ 45 %
ghost:      the item that belongs, 18 % opacity, same size and rotation as it will land
// Hold (filled): ghost and dash disappear; the landed item keeps a small drop shadow

// Ask
halo:       0 0 0 10 px rgba(232,169,60,.34), 0 0 0 24 px rgba(232,169,60,.14)
scale:      1.06 relative to the choices below it

// Scene
opacity: .88, saturation .9, no shadow
```

**The dashed outline always means "something goes here".** It never means an error, and
there is no other use of dashes anywhere in the app. (This is already how the game icons
read, so the icon and the screen agree.)

---

## 2. The tray

The row of takeable items along the bottom. It must read as *these are mine to move*,
which a bare row of floating pictures does not.

- Give it a **shelf**: a 12 px rounded bar in `#B5835A` under the row, with an 8 px darker
  edge, running to within 24 pt of both safe edges. Things rest **on** it.
- Items sit **on top of** the shelf with their drop shadow falling onto it.
- The shelf is the only horizontal line in the lower third, so it reads as a surface.
- When an item leaves the tray, the gap stays open (no reflow). Reflowing loses a
  three-year-old's place.
- At most 6 items, per CLAUDE.md. If a round has more, the tray refills as items leave —
  which is already what Count and Feed does.

---

## 3. The first second

Order of attention: **Ask → Hold → Take**. Build the layout so the eye lands in that order
without any motion:

1. **Ask** at top centre, alone, largest, haloed.
2. **Hold** in the middle band, empty and ghosted, aligned to the centre line.
3. **Take** on the tray at the bottom, in full colour.

Then, and only then, the entry choreography (it runs once per round, ~1.4 s total):

| At | What happens |
|---|---|
| 0 ms | Everything is on screen already. Nothing fades in. |
| 0 ms | The **Ask** halo pulses once. |
| 300 ms | The **Hold** ghost fades 0 → 18 %, one after another, 80 ms apart. |
| 700 ms | The **tray** items bob once, left to right, 60 ms apart. |
| 1400 ms | The spoken prompt starts. Sound arrives **after** the eye has been led, not instead of it. |

**First ever play of an engine** (already implemented): after the choreography, the hand
silently demonstrates one complete move, then puts the item back. It does this once per
engine, not once per game — the grammar is what's being taught, not the content.

---

## 4. Per-engine first moment

What the child sees in the first second, and which role each element takes.

| Engine | Ask (top centre) | Hold (middle) | Take (tray) |
|---|---|---|---|
| `count_feed` | the feeder, haloed, mouth open | the plate: N ghost slots | the food on the shelf |
| `sort_bins` | — (the bins carry the question) | 2–3 bins, each with a ghost of its own kind inside | the mixed items |
| `find_same` | the reference item, haloed, alone | — | the choices, all equal, on the shelf |
| `silhouette` | the dark shape, haloed | — | the picture choices |
| `order_line` | — | the row of ghost slots, small → large left to right | the items, deliberately out of order |
| `pattern` | the sequence so far, laid along the top | the one empty slot at the end of the sequence, dashed | the candidate items |
| `jigsaw` | the finished picture, faint, behind the board | the piece-shaped holes | the loose pieces |
| `position` | the container with the actor beside it | the target place, ghosted (in / on / under) | the actor to move |
| `mirror` | the left half, haloed | the mirrored cells, dashed, on the right of the axis | the parts, or tap-to-fill cells |
| `try_see` | the object, haloed, held above the water | the two guess pads, each with a ghost arrow (up / down) | — (tap only) |
| `listen_find` | the speaker mark, pulsing once | — | the picture choices |
| `trace` | the start dot, haloed, larger | the dotted path ahead | — (finger only) |
| `color_fill` | — | the outline regions, each a faint ghost of any colour | the paint pots |
| `music_echo` | the pattern replays, each pad lighting in turn | — | the pads, drop-shadowed |
| `memory_pairs` | — | the card backs, all identical, evenly spaced | — (the cards are both Take and Hold) |

Two engines have no Ask, which is correct: in `sort_bins`, `order_line`, `color_fill` and
`memory_pairs` the question *is* the board. Never invent a haloed element to fill the slot.

---

## 5. What this replaces

- **Do not** rely on the spoken prompt to establish the task. It arrives at 1400 ms, and
  it may never arrive at all (sound off, headphones out, second language).
- **Do not** use colour alone to mark a role. Every mark above is a shape or a shadow;
  colour only reinforces it. (Palette note: `inkSoft` fails 4.5:1 on paper for small text —
  use `#6E5443` or darker for anything under 24 px.)
- **Do not** add text labels to child-facing screens, including "tap here". The grammar
  replaces them.
- **Do not** animate anything continuously except the 2.4 s idle bob. Constant motion
  competes with the escalating hint and exhausts the child.

## 6. How to check a screen

Show it to an adult who has never seen the app, with the sound off, for **three seconds**,
then take it away and ask: *what were you supposed to do?* If they can't say, a
three-year-old can't either. This is the test in `docs/UX_REVIEW.md`; run it per engine at
both iPad and iPhone sizes.
