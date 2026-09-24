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
    object and learns what actually happens. Endlessly replayable on purpose."""
    floats = [i["id"] for i in ITEMS if i.get("floats") is True]
    sinks = [i["id"] for i in ITEMS if i.get("floats") is False]
    rounds = []
    for k in range(12):
        f = list(dict.fromkeys([floats[(k * 3 + j) % len(floats)] for j in range(4)]))
        s_ = list(dict.fromkeys([sinks[(k * 2 + j) % len(sinks)] for j in range(4)]))
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
    for aid, name, skill, min_age, builder in ACTIVITIES:
        rounds = builder()
        for r in rounds:
            all_vo.update(r.get("vo", []))
        out["activities"].append({
            "id": aid, "name": name, "skill": skill, "minAge": min_age,
            "free": aid in FREE_ACTIVITIES,
            "roundCount": len(rounds), "rounds": rounds,
        })
    # every item name is spoken somewhere
    for i in ITEMS:
        all_vo.add(f"item.{i['id']}")
    out["voKeys"] = sorted(all_vo)
    (CONTENT / "activities.json").write_text(
        json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"activities: {len(out['activities'])}")
    total = sum(a["roundCount"] for a in out["activities"])
    for a in out["activities"]:
        print(f"  {a['id']:16s} {a['roundCount']:4d} rounds  age {a['minAge']}+  "
              f"{'FREE' if a['free'] else 'paid'}")
    print(f"total rounds: {total}")
    print(f"distinct VO keys: {len(out['voKeys'])}")


if __name__ == "__main__":
    main()
