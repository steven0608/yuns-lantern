#!/usr/bin/env python3
"""Render trailer.html to MP4 (1920x1080, 30 fps) with the home theme underneath.

    python design/video/render_video.py      # needs playwright (chromium) + ffmpeg

This is a design-stage animatic for the landing page and pitching. The App Store
app preview must be captured from the real app (Apple's rule).
"""
import os
import shutil
import subprocess

from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = os.path.join(HERE, "_frames")
FPS, DUR = 30, 30.0


def main():
    shutil.rmtree(FRAMES, ignore_errors=True)
    os.makedirs(FRAMES)
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page(viewport={"width": 1920, "height": 1080})
        pg.goto("file:///" + os.path.join(HERE, "trailer.html").replace(os.sep, "/"))
        pg.wait_for_load_state("networkidle")
        pg.evaluate("document.fonts.ready")
        stage = pg.query_selector("#stage")
        for i in range(int(FPS * DUR)):
            pg.evaluate(f"window.render({i / FPS})")
            stage.screenshot(path=os.path.join(FRAMES, f"{i:05d}.jpg"), type="jpeg", quality=92)
        b.close()
    music = os.path.join(HERE, "..", "audio", "music", "home.mp3")
    out = os.path.join(HERE, "yuns_lantern_trailer.mp4")
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", os.path.join(FRAMES, "%05d.jpg"),
        "-stream_loop", "-1", "-i", music, "-t", str(DUR),
        "-af", f"afade=t=in:d=1,afade=t=out:st={DUR - 2}:d=2",
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "20", "-preset", "slow", "-movflags", "+faststart",
        "-c:a", "aac", "-b:a", "160k", out], check=True)
    # square-ish 1080x1350 cut for social posts, centre-cropped
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", out, "-vf", "crop=864:1080,scale=1080:1350",
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "21", "-c:a", "copy",
                    os.path.join(HERE, "yuns_lantern_trailer_4x5.mp4")], check=True)
    shutil.rmtree(FRAMES, ignore_errors=True)
    print(out)


if __name__ == "__main__":
    main()
