#!/usr/bin/env python3
"""
Copies the design canvas exports (design/png, made by design/gen_assets.py +
design/render.py from the "Yun's Lantern Design" canvas) into the app, builds
the iOS / web app icons, and rewrites the pubspec asset list.

Flutter asset folders are NOT recursive, so every folder holding assets (e.g.
each assets/audio/vo/<lang>/<group>/) must be listed. This script is the one
place that list is generated; re-run it after adding audio or art.

    python tools/sync_design_assets.py
"""
import json
import re
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PNG = ROOT / "design" / "png"
IMG = ROOT / "assets" / "images"


def copy_art():
    groups = {
        "tiles": lambda n: n.startswith("icon_"),      # home screen activity tiles
        "lights": lambda n: n.startswith("light_"),    # story lanterns, one per chapter
        "scenes": lambda n: n.startswith("scene_"),    # chapter illustrations
        "ui": lambda n: n in ("home_bg.png", "map.png", "map_phone.png", "yun_idle.png", "yun_happy.png", "yun_sleepy.png"),
    }
    for folder, match in groups.items():
        (IMG / folder).mkdir(parents=True, exist_ok=True)
        for f in sorted(PNG.glob("*.png")):
            if match(f.name):
                shutil.copy2(f, IMG / folder / f.name.split("_", 1)[1] if folder != "ui" else IMG / folder / f.name)
    # Props that aren't vocabulary (Where Is It? containers).
    (IMG / "items").mkdir(exist_ok=True)
    shutil.copy2(PNG / "items" / "basket.png", IMG / "items" / "basket.png")


def copy_audio():
    """design/audio (music loops, stings, new SFX) -> assets/audio."""
    src = ROOT / "design" / "audio"
    for sub in ("music", "sfx"):
        if (src / sub).exists():
            (ROOT / "assets" / "audio" / sub).mkdir(parents=True, exist_ok=True)
            for f in (src / sub).iterdir():
                if f.suffix in (".mp3", ".wav"):
                    shutil.copy2(f, ROOT / "assets" / "audio" / sub / f.name)


def app_icons():
    master = Image.open(PNG / "app_icon_1024.png").convert("RGB")  # iOS icons must be opaque
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for img in json.loads((ios / "Contents.json").read_text())["images"]:
        px = round(float(img["size"].split("x")[0]) * int(img["scale"][0]))
        master.resize((px, px), Image.LANCZOS).save(ios / img["filename"])
    web = ROOT / "web"
    for name, px in [("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512),
                     ("icons/Icon-maskable-192.png", 192), ("icons/Icon-maskable-512.png", 512),
                     ("favicon.png", 32)]:
        master.resize((px, px), Image.LANCZOS).save(web / name)


def pubspec_assets():
    dirs = ["content/"]
    for base in ["assets/images", "assets/audio/sfx", "assets/audio/music", "assets/audio/vo", "assets/fonts"]:
        root = ROOT / base
        if not root.exists():
            continue
        for d in sorted([root, *[p for p in root.rglob("*") if p.is_dir()]]):
            if any(f.is_file() and not f.name.startswith(".") and f.suffix not in (".txt",) for f in d.iterdir()):
                dirs.append(d.relative_to(ROOT).as_posix() + "/")
    dirs = [d for d in dirs if not d.startswith("assets/fonts")]  # fonts are declared under `fonts:`
    block = "  assets:\n" + "".join(f"    - {d}\n" for d in dirs)
    spec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    spec = re.sub(r"  assets:\n(    - .*\n)+", block, spec)
    (ROOT / "pubspec.yaml").write_text(spec, encoding="utf-8")
    print(f"pubspec: {len(dirs)} asset folders")


if __name__ == "__main__":
    copy_art()
    copy_audio()
    app_icons()
    pubspec_assets()
