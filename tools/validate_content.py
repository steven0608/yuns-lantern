#!/usr/bin/env python3
"""
Validates generated content. Exits non-zero on any failure so it can gate CI.

This is the guard against shipping something that looks finished but isn't:
dangling item references, rounds that are unsolvable, ordering puzzles whose
"correct" order is wrong, distractor sets that accidentally contain the answer.
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

vocab = json.loads((CONTENT / "vocab.json").read_text(encoding="utf-8"))
acts = json.loads((CONTENT / "activities.json").read_text(encoding="utf-8"))
story = json.loads((CONTENT / "story.json").read_text(encoding="utf-8"))

BY_ID = {i["id"]: i for i in vocab["items"]}
SIZE_ORDER = ["tiny", "small", "medium", "large", "huge"]
MAX_INTERACTIVE = 6
# Mirrors lib/games/where_is_it/: the relations the engine stages and the
# vessels it can draw. Content outside these sets renders an unanswerable room.
RELATIONS = {"up", "down", "inside", "outside", "front", "behind"}
VESSELS = {"box", "basket", "cup", "bowl"}
# Mirrors lib/games/what_is_it/: silhouette panel or clearing mist.
MYSTERY_TIERS = {"silhouette", "reveal"}

errors, warnings = [], []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def check_ids(where, ids):
    for i in ids:
        if i not in BY_ID:
            err(f"{where}: unknown item id '{i}'")


# ---------------------------------------------------------------- vocab
seen = set()
for it in vocab["items"]:
    if it["id"] in seen:
        err(f"vocab: duplicate id '{it['id']}'")
    seen.add(it["id"])
    for field in ("en", "zh", "pinyin", "category", "shape", "size"):
        if not it.get(field):
            err(f"vocab[{it['id']}]: missing '{field}'")
    # color may be null: the item is then kept out of colour rounds (e.g. a
    # rainbow is every colour; an elephant isn't any palette colour).
    if "color" not in it:
        err(f"vocab[{it['id']}]: missing 'color' (use null to exclude from colour rounds)")
    if it["size"] not in SIZE_ORDER:
        err(f"vocab[{it['id']}]: bad size '{it['size']}'")

# ---------------------------------------------------------------- activities
act_by_id = {a["id"]: a for a in acts["activities"]}

# A v2 activity is its own engine; a v3 game names the engine that plays it.
# Everything below is checked per ENGINE, so every game on an engine gets the
# same scrutiny as the original twelve — that is the whole point of E2.
V2_ENGINES = {a["id"] for a in acts["activities"]
              if a.get("engine", a["id"]) == a["id"]}

for a in acts["activities"]:
    engine = a.get("engine", a["id"])
    if engine not in act_by_id:
        err(f"{a['id']}: engine '{engine}' is not an activity in this file")
    elif engine not in V2_ENGINES:
        err(f"{a['id']}: engine '{engine}' is itself a v3 game, not an engine")

for a in acts["activities"]:
    # `aid` drives the per-engine checks; messages still name the real game.
    aid = a.get("engine", a["id"])
    name = a["id"]
    if a["roundCount"] == 0:
        err(f"{name}: no rounds")
    if a["roundCount"] < 10:
        warn(f"{name}: only {a['roundCount']} rounds — thin for repeat play")
    if a["roundCount"] != len(a["rounds"]):
        err(f"{name}: roundCount {a['roundCount']} != actual {len(a['rounds'])}")

    for n, r in enumerate(a["rounds"]):
        tag = f"{name}[{n}]"
        # A round may override the engine's spoken prompt; those keys must be
        # declared in `vo` too, or the VO script never asks for them.
        for field in ("prompt", "shortPrompt"):
            for k in r.get(field, []):
                if k not in r.get("vo", []):
                    err(f"{tag}: {field} key '{k}' is not listed in vo")

        if aid == "count_feed":
            check_ids(tag, [r["feeder"], r["item"]])
            if not (1 <= r["target"] <= 10):
                err(f"{tag}: target {r['target']} out of range")
            if r["supply"] < r["target"]:
                err(f"{tag}: supply {r['supply']} < target {r['target']}")
            if not BY_ID[r["item"]].get("countable"):
                err(f"{tag}: item '{r['item']}' is not countable")

        elif aid == "match_it":
            attr = r["attribute"]
            total = sum(len(b["items"]) for b in r["bins"])
            if total > MAX_INTERACTIVE:
                err(f"{tag}: {total} draggable items exceeds {MAX_INTERACTIVE}")
            keys = [b["key"] for b in r["bins"]]
            if len(set(keys)) != len(keys):
                err(f"{tag}: duplicate bin keys {keys}")
            for b in r["bins"]:
                check_ids(tag, b["items"])
                for i in b["items"]:
                    if BY_ID[i].get(attr) != b["key"]:
                        err(f"{tag}: '{i}' has {attr}={BY_ID[i].get(attr)} "
                            f"but sits in bin '{b['key']}'")
            allitems = [i for b in r["bins"] for i in b["items"]]
            if len(set(allitems)) != len(allitems):
                err(f"{tag}: same item appears in two bins")

        elif aid == "big_and_small":
            trio = r["orderedSmallToLarge"]
            check_ids(tag, trio)
            if len(set(trio)) != 3:
                err(f"{tag}: repeated item in ordering trio")
            dim = r.get("dimension", "size")
            if dim == "size":
                # The stated order must really be the vocab order, and all
                # three sizes must differ or the puzzle has two answers.
                sizes = [SIZE_ORDER.index(BY_ID[i]["size"]) for i in trio]
                if sizes != sorted(sizes):
                    err(f"{tag}: order is wrong — {list(zip(trio, sizes))}")
                if len(set(sizes)) != 3:
                    err(f"{tag}: sizes not distinct, puzzle is ambiguous — {trio}")
            elif dim == "sequence":
                # A curated first/next/last order (e.g. a morning routine);
                # no vocab attribute ranks it, so only the ids are checked.
                pass
            else:
                err(f"{tag}: unknown ordering dimension '{dim}'")

        elif aid == "shape_sorter":
            if len(r["shapes"]) > MAX_INTERACTIVE:
                err(f"{tag}: too many shapes")
            for shape, ex in r["examples"].items():
                check_ids(tag, ex)
                for i in ex:
                    if BY_ID[i]["shape"] != shape:
                        err(f"{tag}: '{i}' is {BY_ID[i]['shape']}, filed under {shape}")

        elif aid == "find_the_same":
            check_ids(tag, [r["reference"]] + r["distractors"])
            if r["reference"] in r["distractors"]:
                err(f"{tag}: answer appears among distractors")
            if len(set(r["distractors"])) != len(r["distractors"]):
                err(f"{tag}: duplicate distractors")

        elif aid == "where_is_it":
            check_ids(tag, [r["actor"]])
            if r["target"] not in r["pair"]:
                err(f"{tag}: target '{r['target']}' not in pair {r['pair']}")
            if len(set(r["pair"])) != 2:
                err(f"{tag}: the two rooms show the same relation {r['pair']}")
            for rel in r["pair"]:
                # Only these six are staged by the engine; anything else
                # falls back to two identical rooms, which has no answer.
                if rel not in RELATIONS:
                    err(f"{tag}: relation '{rel}' is not one the engine can stage")
            if r["container"] not in VESSELS:
                err(f"{tag}: container '{r['container']}' has no vessel art")

        elif aid == "day_and_night":
            check_ids(tag, r["day"] + r["night"] + r.get("either", []))
            overlap = set(r["day"]) & set(r["night"])
            if overlap:
                err(f"{tag}: items in both bins {overlap}")
            if len(r["day"]) + len(r["night"]) + len(r.get("either", [])) > MAX_INTERACTIVE:
                err(f"{tag}: too many cards")
            for i in r["day"]:
                if BY_ID[i]["timeOfDay"] != "day":
                    err(f"{tag}: '{i}' is not a day item")
            for i in r["night"]:
                if BY_ID[i]["timeOfDay"] != "night":
                    err(f"{tag}: '{i}' is not a night item")

        elif aid == "float_or_sink":
            check_ids(tag, r["floats"] + r["sinks"])
            if len(r["floats"]) + len(r["sinks"]) > MAX_INTERACTIVE:
                err(f"{tag}: too many items")
            if set(r["floats"]) & set(r["sinks"]):
                err(f"{tag}: item both floats and sinks")
            for i in r["floats"]:
                if BY_ID[i].get("floats") is not True:
                    err(f"{tag}: '{i}' does not float")
            for i in r["sinks"]:
                if BY_ID[i].get("floats") is not False:
                    err(f"{tag}: '{i}' does not sink")

        elif aid == "what_is_it":
            check_ids(tag, [r["answer"]] + r["distractors"])
            if r["answer"] in r["distractors"]:
                err(f"{tag}: answer among distractors")
            if len(set(r["distractors"])) != len(r["distractors"]):
                err(f"{tag}: duplicate distractors")
            if r["tier"] not in MYSTERY_TIERS:
                err(f"{tag}: unknown tier '{r['tier']}'")
            # The prompt must never give the answer away.
            if f"item.{r['answer']}" in r.get("prompt", []):
                err(f"{tag}: the prompt names the answer")

        elif aid == "pattern_parade":
            check_ids(tag, r["sequence"] + r["choices"] + [r["answer"]])
            if r["answer"] not in r["choices"]:
                err(f"{tag}: answer not offered as a choice")
            if len(set(r["choices"])) != len(r["choices"]):
                err(f"{tag}: duplicate choices")
            # independently re-derive the answer from the rendered sequence
            seq = r["sequence"]
            n = len(seq)
            period = next(p for p in range(1, n + 1)
                          if all(seq[i] == seq[i % p] for i in range(n)))
            expected = seq[n % period]
            if expected != r["answer"]:
                err(f"{tag}: answer '{r['answer']}' but sequence implies '{expected}'")

        elif aid == "mirror_match":
            check_ids(tag, [r["subject"]])

# ---------------------------------------------------------------- story
for ch in story["chapters"]:
    for f in ("open", "beat", "close"):
        for lang in ("en", "zh"):
            if not ch[f].get(lang):
                err(f"story ch{ch['number']}: missing {f}.{lang}")
    for a in ch["activities"]:
        if a not in act_by_id:
            err(f"story ch{ch['number']}: references unknown activity '{a}'")
    if len(ch["activities"]) != 3:
        warn(f"story ch{ch['number']}: {len(ch['activities'])} activities (expected 3)")

if len(story["chapters"]) != len(story["lightColors"]):
    err("story: chapter count does not match lightColors count")

used_colors = [c["lightColor"] for c in story["chapters"]]
if len(set(used_colors)) != len(used_colors):
    err("story: duplicate light colors")

# ---------------------------------------------------------------- free tier
free_acts = [a for a in acts["activities"] if a["free"]]
free_rounds = sum(a["roundCount"] for a in free_acts)
free_chapters = [c for c in story["chapters"] if c["free"]]
if free_rounds < 60:
    warn(f"free tier has only {free_rounds} rounds — too thin to demonstrate value")
if not free_chapters:
    err("free tier includes no story chapters")

# every story chapter's activities must be unlocked at that chapter's tier
for ch in story["chapters"]:
    if ch["free"]:
        for a in ch["activities"]:
            if not act_by_id[a]["free"]:
                err(f"story ch{ch['number']} is free but requires paid activity '{a}'")

# ---------------------------------------------------------------- report
total = sum(a["roundCount"] for a in acts["activities"])
print(f"vocab items      : {len(vocab['items'])}")
print(f"activities       : {len(acts['activities'])}")
print(f"total rounds     : {total}")
print(f"story chapters   : {len(story['chapters'])}")
print(f"free rounds      : {free_rounds} across {len(free_acts)} activities, "
      f"{len(free_chapters)} chapters")
print(f"distinct VO keys : {len(acts['voKeys'])}")
print()

for w in warnings:
    print(f"WARN  {w}")
for e in errors:
    print(f"ERROR {e}")

print()
if errors:
    print(f"FAILED — {len(errors)} error(s), {len(warnings)} warning(s)")
    sys.exit(1)
print(f"PASSED — 0 errors, {len(warnings)} warning(s)")
