#!/usr/bin/env python3
"""
Builds activities.json — the full round data for every mini-game — from vocab.json.

Deterministic: a fixed seed means the same content every build, so QA and golden
tests stay stable. Re-run after editing vocab.json.

Design rules enforced here, not left to the app:
  - Never more than 6 interactive items in a round (kMaxInteractiveItems).
  - Distractors are chosen to be *clearly* different at the easy tier and
    progressively closer at harder tiers.
  - Every round names its required VO keys so the recording script and the
    asset validator can be generated from the same source of truth.
"""

import json
import random
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
SEED = 20260819

rng = random.Random(SEED)

vocab = json.loads((CONTENT / "vocab.json").read_text(encoding="utf-8"))
ITEMS = vocab["items"]
BY_ID = {i["id"]: i for i in ITEMS}

SIZE_ORDER = ["tiny", "small", "medium", "large", "huge"]
COLORS = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "brown", "white", "black"]
SHAPES = ["circle", "square", "triangle", "rectangle", "semicircle"]

def by(**kw):
    out = ITEMS
    for k, v in kw.items():
        if isinstance(v, (list, tuple, set)):
            out = [i for i in out if i.get(k) in v]
        else:
            out = [i for i in out if i.get(k) == v]
    return out

def pick(pool, n, exclude=()):
    pool = [i for i in pool if i["id"] not in exclude]
    return rng.sample(pool, min(n, len(pool)))


# ---------------------------------------------------------------- activities

def build_count_feed():
    """Drag exactly N items to a hungry animal. Tier 1: 1-3 (subitizing).
    Tier 2: 1-5. Tier 3: 1-10."""
    rounds = []
    feeders = ["bear", "rabbit", "duck", "cat", "dog", "panda", "mouse", "turtle"]
    foods = [i["id"] for i in by(category="food")]
    tiers = [("subitize", range(1, 4), 8), ("to_five", range(1, 6), 10), ("to_ten", range(1, 11), 12)]
    for tier_name, span, count in tiers:
        nums = list(span)
        for k in range(count):
            n = nums[k % len(nums)]
            feeder = feeders[k % len(feeders)]
            food = foods[(k * 3) % len(foods)]
            rounds.append({
                "tier": tier_name,
                "target": n,
                "feeder": feeder,
                "item": food,
                "supply": min(n + 3, 10),
                "vo": ["counting.ask", f"number.{n}", f"item.{food}", f"item.{feeder}"],
            })
    return rounds

def build_match_it():
    """Sort items into 3 bins by one attribute. Four attributes keeps this from
    becoming rote: a child who has learned 'sort by color' must re-read the
    prompt when the attribute changes."""
    rounds = []

    def bins_for(attr, keys, per_bin=2):
        bins = []
        for k in keys:
            pool = by(**{attr: k})
            if len(pool) >= per_bin:
                bins.append({"key": k, "items": [i["id"] for i in pick(pool, per_bin)]})
        return bins if len(bins) == len(keys) else None

    color_sets = [("red","yellow","blue"), ("green","orange","purple"),
                  ("blue","pink","brown"), ("yellow","green","red"),
                  ("white","brown","green"), ("orange","blue","white"),
                  ("pink","yellow","purple"), ("red","green","blue")]
    for combo in color_sets:
        b = bins_for("color", combo)
        if b:
            rounds.append({"attribute": "color", "bins": b,
                           "vo": ["matching.color"] + [f"color.{x['key']}" for x in b]})

    cat_sets = [("food","animal","vehicle"), ("toy","clothing","household"),
                ("animal","nature","food"),  ("vehicle","toy","household"),
                ("nature","clothing","animal"), ("food","household","toy"),
                ("animal","vehicle","nature"), ("clothing","food","vehicle")]
    for combo in cat_sets:
        b = bins_for("category", combo)
        if b:
            rounds.append({"attribute": "category", "bins": b,
                           "vo": ["matching.category"] + [f"category.{x['key']}" for x in b]})

    shape_sets = [("circle","square","triangle"), ("circle","rectangle","semicircle"),
                  ("triangle","rectangle","circle"), ("square","triangle","semicircle"),
                  ("rectangle","circle","triangle"), ("semicircle","square","circle")]
    for combo in shape_sets:
        b = bins_for("shape", combo)
        if b:
            rounds.append({"attribute": "shape", "bins": b,
                           "vo": ["matching.shape"] + [f"shape.{x['key']}" for x in b]})

    size_sets = [("tiny","medium","huge"), ("small","medium","large"),
                 ("tiny","small","large"), ("medium","large","huge")]
    for combo in size_sets:
        b = bins_for("size", combo)
        if b:
            rounds.append({"attribute": "size", "bins": b,
                           "vo": ["matching.size"] + [f"size.{x['key']}" for x in b]})
    return rounds

def build_big_and_small():
    """Order 3 items by real-world size, length, or height."""
    rounds = []
    tiny = by(size="tiny"); small = by(size="small")
    med = by(size="medium"); large = by(size="large"); huge = by(size="huge")
    triples = [(tiny, small, medium_or(med)), (small, med, large),
               (med, large, huge), (tiny, med, huge), (small, large, huge)]
    for a, b, c in triples:
        for _ in range(3):
            trio = [pick(a,1)[0]["id"], pick(b,1)[0]["id"], pick(c,1)[0]["id"]]
            if len(set(trio)) == 3:
                rounds.append({"dimension": "size", "orderedSmallToLarge": trio,
                               "vo": ["comparing.order_small_big"] + [f"item.{t}" for t in trio]})
    return rounds

def medium_or(m):
    return m if m else by(size="medium")

def build_shape_sorter():
    """Drag falling shapes into matching holes. Shapes auto-orient on approach --
    a 3-year-old cannot rotate a piece, so we never ask them to."""
    rounds = []
    sets = [["circle","square","triangle"],
            ["circle","triangle","rectangle"],
            ["square","rectangle","semicircle"],
            ["circle","square","semicircle"],
            ["triangle","rectangle","semicircle"],
            ["circle","square","triangle","rectangle"],
            ["circle","triangle","rectangle","semicircle"],
            ["circle","square","triangle","rectangle","semicircle"]]
    for variant in range(3):
        for s_ in sets:
            examples = {}
            ok = True
            for shape in s_:
                pool = by(shape=shape)
                if not pool:
                    ok = False
                    break
                examples[shape] = [i["id"] for i in pick(pool, min(2, len(pool)))]
            if ok:
                rounds.append({"shapes": s_, "variant": variant, "examples": examples,
                               "vo": [f"shape.{x}" for x in s_] + ["shapes.intro"]})
    return rounds

def build_find_the_same():
    """One reference, 4 candidates, one identical. Difficulty = how close distractors are."""
    rounds = []
    for tier, same_attrs in [("easy", []), ("medium", ["category"]), ("hard", ["category","color"])]:
        for _ in range(10):
            ref = rng.choice(ITEMS)
            pool = ITEMS
            for a in same_attrs:
                pool = [i for i in pool if i.get(a) == ref.get(a)]
            distractors = pick(pool, 3, exclude={ref["id"]})
            if len(distractors) < 3:
                distractors = pick(ITEMS, 3, exclude={ref["id"]})
            rounds.append({"tier": tier, "reference": ref["id"],
                           "distractors": [d["id"] for d in distractors],
                           "vo": ["spotsame.intro", f"item.{ref['id']}"]})
    return rounds

def build_where_is_it():
    """Voice asks for a position; child taps the right one."""
    rounds = []
    pairs = [("up","down"), ("inside","outside"), ("front","behind")]
    actors = ["cat","frog","owl","mouse","bird","rabbit","fish","butterfly"]
    containers = ["box","basket","cup","bowl"]
    for a, b in pairs:
        for k in range(6):
            actor = actors[k % len(actors)]
            rounds.append({"pair": [a, b], "target": a if k % 2 == 0 else b,
                           "actor": actor, "container": containers[k % len(containers)],
                           "vo": [f"position.{a}", f"position.{b}", f"item.{actor}", "position.ask"]})
    return rounds

def build_puzzle_pieces():
    rounds = []
    scenes = ["orchard","shapevillage","rainbowriver","bigmountain",
              "mistyforest","starrymeadow","mirrorlake","lighthouse"]
    for tier, pieces in [("missing", 1), ("four", 4)]:
        for s in scenes:
            rounds.append({"tier": tier, "scene": s, "pieces": pieces,
                           "candidates": 3 if tier == "missing" else 0,
                           "vo": ["puzzle.intro"]})
    return rounds

def build_day_and_night():
    rounds = []
    day = [i["id"] for i in by(timeOfDay="day")]
    night = [i["id"] for i in by(timeOfDay="night")]
    both = [i["id"] for i in by(timeOfDay="both")]
    for k in range(14):
        d = [day[(k * 2 + j) % len(day)] for j in range(3)]
        n = [night[(k + j) % len(night)] for j in range(2)]
        r = {"day": list(dict.fromkeys(d)), "night": list(dict.fromkeys(n)),
             "vo": ["daynight.intro", "item.sun", "item.moon"]}
        # later rounds introduce an "either" item, which has no wrong bin
        if k >= 8 and both:
            r["either"] = [both[k % len(both)]]
        r["vo"] += [f"item.{x}" for x in r["day"] + r["night"] + r.get("either", [])]
        rounds.append(r)
    return rounds

def build_float_or_sink():
    """Open-ended sandbox. No wrong answers, no scoring -- the child drops any
    object and learns what actually happens. Endlessly replayable on purpose.
    3 floaters + 3 sinkers per round (kMaxInteractiveItems); each round's set
    is new, so rounds never repeat."""
    floats = [i["id"] for i in ITEMS if i.get("floats") is True]
    sinks = [i["id"] for i in ITEMS if i.get("floats") is False]
    rounds, seen = [], set()
    while len(rounds) < 12:
        f = sorted(rng.sample(floats, 3))
        s_ = sorted(rng.sample(sinks, 3))
        if (tuple(f), tuple(s_)) in seen:
            continue
        seen.add((tuple(f), tuple(s_)))
        rounds.append({"floats": f, "sinks": s_,
                       "vo": ["floatsink.floats", "floatsink.sinks", "floatsink.intro"] +
                             [f"item.{x}" for x in f + s_]})
    return rounds

def build_what_is_it():
    """Silhouette or slow reveal, 3 candidates."""
    rounds = []
    distinctive = [i for i in ITEMS if i["shape"] == "irregular" or i["category"] in ("animal","vehicle")]
    for tier in ["silhouette", "reveal"]:
        for k in range(12):
            ans = distinctive[k % len(distinctive)]
            others = pick(distinctive, 2, exclude={ans["id"]})
            rounds.append({"tier": tier, "answer": ans["id"],
                           "distractors": [o["id"] for o in others],
                           "vo": ["whatisit.intro", f"item.{ans['id']}"]})
    return rounds

def smallest_period(core):
    """Smallest p such that core is a prefix of (core[:p] repeated). This is the
    real repeating unit — counting distinct letters is NOT the same thing
    (AAB has 2 distinct letters but a period of 3)."""
    n = len(core)
    for p in range(1, n + 1):
        if all(core[i] == core[i % p] for i in range(n)):
            return p
    return n

def seq_next(seq):
    """The letter that continues the pattern after the '?'."""
    core = seq.rstrip("?")
    if not core:
        return "A"
    p = smallest_period(core)
    return core[len(core) % p]

def build_pattern_parade():
    """AB, AAB, ABB, ABC patterns plus mid-sequence variants. Age 4+.
    Mid-sequence variants (ABABA?) matter: they stop the child from learning
    'the answer is always the first one'."""
    rounds = []
    templates = [
        ("AB",  "ABAB?"),   ("AB",  "ABABA?"),
        ("AAB", "AABAAB?"), ("AAB", "AABAA?"),
        ("ABB", "ABBABB?"), ("ABB", "ABBAB?"),
        ("ABC", "ABCABC?"), ("ABC", "ABCAB?"),
    ]
    palettes = [("apple","banana","grape"), ("cat","dog","bird"),
                ("ball","block","balloon"), ("star","moon","cloud"),
                ("flower","leaf","shell"), ("car","boat","train"),
                ("hat","shoe","sock"),     ("cup","bowl","spoon"),
                ("duck","frog","fish"),    ("sun","cloud","star")]
    for name, seq in templates:
        for p in palettes:
            mapping = {"A": p[0], "B": p[1], "C": p[2]}
            core = seq.rstrip("?")
            body = [mapping[c] for c in core]
            answer = mapping[seq_next(seq)]
            # three distinct choices, answer always included, order shuffled
            choices = list(dict.fromkeys([answer, mapping["A"], mapping["B"], mapping["C"]]))[:3]
            while len(choices) < 3:
                extra = rng.choice(ITEMS)["id"]
                if extra not in choices:
                    choices.append(extra)
            rng.shuffle(choices)
            rounds.append({"pattern": name, "template": seq, "sequence": body,
                           "answer": answer, "choices": choices,
                           "vo": ["pattern.intro", "pattern.whatnext"]})
    return rounds

def build_mirror_match():
    """Complete the symmetrical half. Age 4+."""
    rounds = []
    subjects = ["butterfly","tree","flower","kite","star","leaf","boat","umbrella"]
    for tier, cells in [("simple", 4), ("detailed", 6)]:
        for s in subjects:
            rounds.append({"tier": tier, "subject": s, "cells": cells,
                           "vo": ["mirror.intro", f"item.{s}"]})
    return rounds


# ------------------------------------------------------------- v3 games (E2)
#
# More games on the twelve engines that already exist, as DATA ONLY: an
# activity names the `engine` whose widget plays it and carries its own rounds.
# A round may carry `prompt` / `shortPrompt` VO keys, which the scaffold speaks
# instead of the engine's default line — that is how one engine hosts games
# with different voices without a line of Dart.
#
# Every v3 builder owns a private Random seeded from SEED, so adding, removing
# or reordering a game can never shift another game's rounds (the v2 twelve
# share the module-level `rng` and must stay byte-identical).

def r_for(tag):
    """A private, stable RNG per game: order-independent determinism."""
    return random.Random(SEED + sum((i + 1) * ord(c) for i, c in enumerate(tag)))

def rpick(r, pool, n, exclude=()):
    pool = [i for i in pool if i["id"] not in exclude]
    return r.sample(pool, min(n, len(pool)))

def ids(pool):
    return [i["id"] for i in pool]


# --- count_feed engine -------------------------------------------------------

def _counting_rounds(feeders, items, prompt_key, extra_vo=()):
    """Twenty rounds of 'give exactly N': ten to five, then ten to ten.
    `feeders` and `items` cycle independently so no two rounds look alike."""
    rounds = []
    for k in range(20):
        n = (k % 5) + 1 if k < 10 else (k - 9)
        feeder = feeders[k % len(feeders)]
        item = items[k % len(items)]
        rounds.append({
            "tier": "to_five" if k < 10 else "to_ten",
            "target": n,
            "feeder": feeder,
            "item": item,
            "supply": min(n + 3, 10),
            "prompt": [f"item.{feeder}", prompt_key, f"number.{n}"],
            "vo": [prompt_key, f"number.{n}", f"item.{item}", f"item.{feeder}",
                   *extra_vo],
        })
    return rounds

def build_birthday_candles():
    """Candles onto a birthday cake. The plate's N empty spots are the holes
    in the icing, so the count stays visible without a numeral."""
    return _counting_rounds(["cake"], ["candle"], "game.candles")

def build_share_cookies():
    """One friend, N cookies: one-to-one correspondence, counted aloud."""
    friends = ["bear", "rabbit", "panda", "dog", "cat", "duck", "mouse", "turtle"]
    return _counting_rounds(friends, ["cookie"], "game.cookies")

def build_garden_seeds():
    """Plant this many in the garden bed. Only countable garden things."""
    grown = ["flower", "leaf", "apple", "corn", "strawberry", "mushroom"]
    return _counting_rounds(["tree"], grown, "game.seeds")

def build_bus_stop():
    """Riders onto the bus, one per seat."""
    riders = ["rabbit", "cat", "dog", "duck", "mouse", "bear", "panda", "frog"]
    return _counting_rounds(["bus"], riders, "game.bus")


# --- match_it (sort) engine --------------------------------------------------

def _bins_for(r, attr, keys, per_bin=2):
    """One bin per key, `per_bin` items each — never more than
    kMaxInteractiveItems in total. Returns None if the vocab can't fill it."""
    bins = []
    for k in keys:
        pool = [i for i in ITEMS if i.get(attr) == k]
        if len(pool) < per_bin:
            return None
        bins.append({"key": k, "items": sorted(i["id"] for i in r.sample(pool, per_bin))})
    return bins

def _sorting_rounds(tag, attr, key_sets, prompt_key, repeats):
    r = r_for(tag)
    rounds = []
    for _ in range(repeats):
        for keys in key_sets:
            b = _bins_for(r, attr, keys)
            if b is None:
                continue
            rounds.append({
                "attribute": attr, "bins": b,
                "prompt": [prompt_key],
                # the tub's spoken name is read from vo by the engine
                "vo": [prompt_key] + [f"{attr}.{x['key']}" for x in b],
            })
    return rounds

def build_tidy_up():
    """Everything in the room goes somewhere: toys, clothes, dishes, food."""
    key_sets = [("toy", "clothing", "household"),
                ("toy", "food", "household"),
                ("clothing", "household", "food"),
                ("toy", "clothing", "food")]
    return _sorting_rounds("tidy_up", "category", key_sets, "game.tidy", 4)

def build_weather_wardrobe():
    """Sunny, rainy, windy: what each kind of day needs. Driven by the
    `weather` attribute in vocab.json — never guessed here."""
    return _sorting_rounds("weather_wardrobe", "weather",
                           [("sunny", "rainy", "windy")], "game.weather", 16)


# --- find_the_same engine ----------------------------------------------------

def _same_rounds(tag, pool_ids, prompt_key, count=20):
    """One reference, three distractors from the same themed pool. The
    reference is never among the distractors (the validator re-checks)."""
    r = r_for(tag)
    pool = [BY_ID[i] for i in pool_ids]
    rounds = []
    for k in range(count):
        ref = pool[k % len(pool)]
        distractors = rpick(r, pool, 3, exclude={ref["id"]})
        rounds.append({
            "tier": "easy" if k < count // 2 else "hard",
            "reference": ref["id"],
            "distractors": sorted(d["id"] for d in distractors),
            "prompt": [prompt_key],
            "vo": [prompt_key, f"item.{ref['id']}"],
        })
    return rounds

def build_feelings_faces():
    """Six feelings, matched face to face — the first emotional vocabulary."""
    return _same_rounds("feelings_faces", ids(by(category="feeling")),
                        "game.feelings")

def build_sock_pairs():
    """Things we wear, matched into pairs."""
    return _same_rounds("sock_pairs", ids(by(category="clothing")), "game.socks")

def build_spot_the_lantern():
    """Festival things: find the twin among lanterns, candles and gifts."""
    festival = ["key_lantern", "candle", "red_envelope", "mooncake", "dumpling",
                "dragon_boat", "cake", "gift", "balloon", "moon"]
    return _same_rounds("spot_the_lantern", festival, "game.lantern")


# --- what_is_it (silhouette) engine ------------------------------------------

def _mystery_rounds(tag, pool_ids, tier, prompt_key, count=16):
    """A shape to guess and two other candidates. The prompt never names the
    answer — that's the whole game."""
    r = r_for(tag)
    pool = [BY_ID[i] for i in pool_ids]
    order = list(range(len(pool)))
    r.shuffle(order)
    rounds = []
    for k in range(count):
        ans = pool[order[k % len(order)]]
        others = rpick(r, pool, 2, exclude={ans["id"]})
        rounds.append({
            "tier": tier,
            "answer": ans["id"],
            "distractors": sorted(o["id"] for o in others),
            "prompt": [prompt_key],
            "vo": [prompt_key, f"item.{ans['id']}"],
        })
    return rounds

def build_peekaboo_animals():
    """An animal peeks out as a silhouette; who is it?"""
    return _mystery_rounds("peekaboo_animals", ids(by(category="animal")),
                           "silhouette", "game.peekaboo")

def build_shadow_puppets():
    """The same silhouette panel, told as a shadow play on the wall."""
    return _mystery_rounds("shadow_puppets", ids(by(category="animal")),
                           "silhouette", "game.shadow")

def build_zoom_out():
    """Misted over, clearing slowly — a close-up pulling back."""
    pool = ids(by(category=("food", "household", "toy", "nature", "clothing")))
    return _mystery_rounds("zoom_out", pool, "reveal", "game.zoom")


# --- big_and_small (order_line) engine ---------------------------------------

def _size_order_rounds(tag, pool_ids, prompt_key, count=12):
    """Trios genuinely ordered by the vocab `size` attribute, all three sizes
    distinct so the puzzle has exactly one answer."""
    r = r_for(tag)
    pool = [BY_ID[i] for i in pool_ids]
    buckets = {s: [i for i in pool if i["size"] == s] for s in SIZE_ORDER}
    ladders = [(a, b, c) for ai, a in enumerate(SIZE_ORDER)
               for bi, b in enumerate(SIZE_ORDER) if bi > ai
               for ci, c in enumerate(SIZE_ORDER) if ci > bi
               if buckets[a] and buckets[b] and buckets[c]]
    rounds = []
    for k in range(count):
        a, b, c = ladders[k % len(ladders)]
        trio = [r.choice(buckets[a])["id"], r.choice(buckets[b])["id"],
                r.choice(buckets[c])["id"]]
        rounds.append({
            "dimension": "size", "orderedSmallToLarge": trio,
            "prompt": [prompt_key],
            "vo": [prompt_key] + [f"item.{t}" for t in trio],
        })
    return rounds

def build_ladder_up():
    """Short to tall, with things you look up at outdoors."""
    pool = ids(by(category=("nature", "vehicle", "animal")))
    return _size_order_rounds("ladder_up", pool, "game.ladder")

def build_stacking_cups():
    """Nesting things from the kitchen shelf, smallest first."""
    pool = ids(by(category=("household", "food", "toy")))
    return _size_order_rounds("stacking_cups", pool, "game.stack")

def build_growing_up():
    """Baby, big sister, grown-up: the family ordered by how big they are.
    Genuinely a size ordering, and the first 'I am growing' idea."""
    return _size_order_rounds("growing_up", ids(by(category="family")),
                              "game.growing")

# What happens first, next and last in a morning. Ordered by the sequence the
# curator wrote here, not by a vocab attribute — the validator checks the
# dimension and only enforces vocab size when `dimension` is "size".
MORNING_SEQUENCES = [
    ["pillow", "toothbrush", "shoe"],
    ["eye", "toothbrush", "hat"],
    ["pillow", "bowl", "book"],
    ["toothbrush", "bowl", "shoe"],
    ["pillow", "cup", "hat"],
    ["eye", "bowl", "shoe"],
    ["pillow", "toothbrush", "book"],
    ["bowl", "toothbrush", "shoe"],
    ["pillow", "hand", "toothbrush"],
    ["eye", "hand", "bowl"],
    ["pillow", "shoe", "bike"],
    ["bowl", "hat", "bus"],
]

def build_morning_routine():
    return [{"dimension": "sequence", "orderedSmallToLarge": trio,
             "prompt": ["game.routine"],
             "vo": ["game.routine"] + [f"item.{t}" for t in trio]}
            for trio in MORNING_SEQUENCES]


# --- pattern_parade engine ---------------------------------------------------

def _pattern_rounds(tag, templates, palettes, prompt_key):
    r = r_for(tag)
    rounds = []
    for name, seq in templates:
        for p in palettes:
            mapping = {"A": p[0], "B": p[1], "C": p[2]}
            core = seq.rstrip("?")
            body = [mapping[c] for c in core]
            answer = mapping[seq_next(seq)]
            choices = list(dict.fromkeys([answer, mapping["A"], mapping["B"],
                                          mapping["C"]]))[:3]
            while len(choices) < 3:
                extra = r.choice(ITEMS)["id"]
                if extra not in choices:
                    choices.append(extra)
            r.shuffle(choices)
            rounds.append({"pattern": name, "template": seq, "sequence": body,
                           "answer": answer, "choices": choices,
                           "prompt": [prompt_key, "pattern.whatnext"],
                           "vo": [prompt_key, "pattern.whatnext"]})
    return rounds

SIMPLE_TEMPLATES = [
    ("AB",  "ABAB?"),   ("AB",  "ABABA?"),
    ("AAB", "AABAAB?"), ("AAB", "AABAA?"),
    ("ABB", "ABBABB?"), ("ABB", "ABBAB?"),
    ("ABC", "ABCABC?"), ("ABC", "ABCAB?"),
]

def build_bead_necklace():
    """Threading beads: the gentlest pattern game, one bead at a time."""
    palettes = [("apple", "grape", "orange"), ("ball", "balloon", "block"),
                ("shell", "flower", "leaf")]
    return _pattern_rounds("bead_necklace", SIMPLE_TEMPLATES, palettes,
                           "game.beads")

def build_lantern_string():
    """Festival lanterns strung along a wire."""
    palettes = [("key_lantern", "candle", "star"),
                ("red_envelope", "mooncake", "dumpling"),
                ("gift", "cake", "balloon")]
    return _pattern_rounds("lantern_string", SIMPLE_TEMPLATES, palettes,
                           "game.lanterns_next")

def build_flower_path():
    """Age 5: longer repeating units (AABB, ABCB) along a garden path."""
    templates = [("ABC", "ABCABC?"), ("ABC", "ABCAB?"), ("ABC", "ABCA?"),
                 ("AABB", "AABBAABB?"), ("AABB", "AABBAA?"),
                 ("ABCB", "ABCBABCB?")]
    palettes = [("flower", "leaf", "shell"), ("flower", "tree", "rock"),
                ("flower", "butterfly", "bee"), ("flower", "mushroom", "star")]
    return _pattern_rounds("flower_path", templates, palettes,
                           "game.flowers_next")


# --- where_is_it (position) engine -------------------------------------------

def _position_rounds(tag, pairs, actors, containers, prompt_key, count=12):
    """Two rooms, the same actor and vessel in each, arranged by the two
    words of `pair`. Only the six relations the engine can stage."""
    rounds = []
    for k in range(count):
        a, b = pairs[k % len(pairs)]
        target = a if k % 2 == 0 else b
        actor = actors[k % len(actors)]
        rounds.append({
            "pair": [a, b], "target": target,
            "actor": actor, "container": containers[k % len(containers)],
            "prompt": [prompt_key, f"item.{actor}", f"position.{target}"],
            "vo": [prompt_key, f"position.{a}", f"position.{b}",
                   f"item.{actor}", "position.ask"],
        })
    return rounds

def build_hide_seek():
    """Someone is hiding. Listen to where, then tap that room."""
    return _position_rounds("hide_seek", [("inside", "outside"), ("front", "behind")],
                            ["cat", "mouse", "rabbit", "frog", "bird", "owl"],
                            ["box", "basket", "bowl", "cup"], "game.hide")

def build_owl_tree_house():
    """Up in the branches or down by the roots."""
    return _position_rounds("owl_tree_house", [("up", "down")],
                            ["owl", "bird", "mouse", "cat"],
                            ["basket", "box"], "game.treehouse")

def build_set_table():
    """On the table, in the bowl, beside it: laying a place for dinner."""
    return _position_rounds("set_table", [("inside", "outside"), ("up", "down")],
                            ["spoon", "egg", "apple", "cookie", "strawberry", "grape"],
                            ["bowl", "cup", "basket"], "game.table")


# id -> (engine, skill, builder). Names, ages and tier come from
# content/catalog.json, which is the single source of truth for the 75 games.
V3_GAMES = [
    ("birthday_candles", "count_feed",     "counting",       build_birthday_candles),
    ("share_cookies",    "count_feed",     "counting",       build_share_cookies),
    ("garden_seeds",     "count_feed",     "counting",       build_garden_seeds),
    ("bus_stop",         "count_feed",     "counting",       build_bus_stop),
    ("tidy_up",          "match_it",       "classification", build_tidy_up),
    ("weather_wardrobe", "match_it",       "classification", build_weather_wardrobe),
    ("feelings_faces",   "find_the_same",  "discrimination", build_feelings_faces),
    ("sock_pairs",       "find_the_same",  "discrimination", build_sock_pairs),
    ("spot_the_lantern", "find_the_same",  "discrimination", build_spot_the_lantern),
    ("peekaboo_animals", "what_is_it",     "recognition",    build_peekaboo_animals),
    ("shadow_puppets",   "what_is_it",     "recognition",    build_shadow_puppets),
    ("zoom_out",         "what_is_it",     "recognition",    build_zoom_out),
    ("ladder_up",        "big_and_small",  "comparison",     build_ladder_up),
    ("stacking_cups",    "big_and_small",  "comparison",     build_stacking_cups),
    ("growing_up",       "big_and_small",  "comparison",     build_growing_up),
    ("morning_routine",  "big_and_small",  "comparison",     build_morning_routine),
    ("bead_necklace",    "pattern_parade", "patterns",       build_bead_necklace),
    ("lantern_string",   "pattern_parade", "patterns",       build_lantern_string),
    ("flower_path",      "pattern_parade", "patterns",       build_flower_path),
    ("hide_seek",        "where_is_it",    "position",       build_hide_seek),
    ("owl_tree_house",   "where_is_it",    "position",       build_owl_tree_house),
    ("set_table",        "where_is_it",    "position",       build_set_table),
]


ACTIVITIES = [
    ("count_feed",     {"en":"Count and Feed","zh":"数一数"},      "counting",       3, build_count_feed),
    ("match_it",       {"en":"Match It","zh":"配对"},              "classification", 3, build_match_it),
    ("big_and_small",  {"en":"Big and Small","zh":"比大小"},        "comparison",     3, build_big_and_small),
    ("shape_sorter",   {"en":"Shape Sorter","zh":"形状"},          "shapes",         3, build_shape_sorter),
    ("find_the_same",  {"en":"Find the Same","zh":"找相同"},        "discrimination", 3, build_find_the_same),
    ("where_is_it",    {"en":"Where Is It?","zh":"在哪里"},         "position",       3, build_where_is_it),
    ("puzzle_pieces",  {"en":"Puzzle Pieces","zh":"拼图"},          "part_whole",     3, build_puzzle_pieces),
    ("day_and_night",  {"en":"Day and Night","zh":"白天黑夜"},      "time",           4, build_day_and_night),
    ("float_or_sink",  {"en":"Float or Sink","zh":"沉与浮"},        "science",        3, build_float_or_sink),
    ("what_is_it",     {"en":"What Is It?","zh":"猜一猜"},          "recognition",    3, build_what_is_it),
    ("pattern_parade", {"en":"Pattern Parade","zh":"排排队"},       "patterns",       4, build_pattern_parade),
    ("mirror_match",   {"en":"Mirror Match","zh":"照镜子"},         "symmetry",       4, build_mirror_match),
]

FREE_ACTIVITIES = {"count_feed", "match_it", "float_or_sink", "what_is_it",
                   "shape_sorter", "find_the_same"}


def main():
    out = {"_comment": "GENERATED by tools/build_content.py — do not hand-edit. "
                       "Edit vocab.json or the builders and re-run.",
           "seed": SEED, "activities": []}
    all_vo = set()

    def emit(aid, engine, name, skill, min_age, free, rounds):
        for r in rounds:
            all_vo.update(r.get("vo", []))
        out["activities"].append({
            "id": aid, "engine": engine, "name": name, "skill": skill,
            "minAge": min_age, "free": free,
            "roundCount": len(rounds), "rounds": rounds,
        })

    # The twelve v2 activities: each one is its own engine.
    for aid, name, skill, min_age, builder in ACTIVITIES:
        emit(aid, aid, name, skill, min_age, aid in FREE_ACTIVITIES, builder())

    # v3 games: more content on those same engines. Name, age and tier are
    # read from catalog.json so the two files can never disagree.
    catalog = json.loads((CONTENT / "catalog.json").read_text(encoding="utf-8"))
    cat_by_id = {g["id"]: g for g in catalog["games"]}
    for gid, engine, skill, builder in V3_GAMES:
        g = cat_by_id[gid]
        emit(gid, engine, g["name"], skill, g["minAge"], g["free"], builder())

    # every item name is spoken somewhere
    for i in ITEMS:
        all_vo.add(f"item.{i['id']}")
    out["voKeys"] = sorted(all_vo)
    (CONTENT / "activities.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"activities: {len(out['activities'])}")
    total = sum(a["roundCount"] for a in out["activities"])
    for a in out["activities"]:
        print(f"  {a['id']:18s} {a['roundCount']:4d} rounds  age {a['minAge']}+  "
              f"{'FREE' if a['free'] else 'paid'}  on {a['engine']}")
    print(f"total rounds: {total}")
    print(f"distinct VO keys: {len(out['voKeys'])}")


if __name__ == "__main__":
    main()
