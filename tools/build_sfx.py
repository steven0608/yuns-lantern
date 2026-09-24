#!/usr/bin/env python3
"""Synthesizes the placeholder SFX set into assets/audio/sfx/.

Every sound is soft and warm on purpose: there is no buzzer, no harsh
'wrong' tone anywhere (CLAUDE.md: no fail states). Replace with designed
sounds in Phase 4; keep the filenames.
"""
import math, random, struct, wave
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "sfx"
RATE = 22050
rng = random.Random(7)

def env(i, n, attack=0.01, release=0.6):
    t = i / RATE; dur = n / RATE
    a = min(1.0, t / attack) if attack else 1.0
    r = max(0.0, 1 - max(0, t - (dur - dur * release)) / (dur * release))
    return a * r

def tone(freqs, dur, vol=0.35, glide=0.0, noise=0.0, release=0.7):
    n = int(RATE * dur); out = []
    for i in range(n):
        t = i / RATE; s = 0.0
        for f in freqs:
            f2 = f * (1 + glide * t / dur)
            s += math.sin(2 * math.pi * f2 * t) + 0.25 * math.sin(4 * math.pi * f2 * t)
        s /= len(freqs) * 1.25
        if noise: s = s * (1 - noise) + noise * (rng.random() * 2 - 1)
        out.append(s * vol * env(i, n, release=release))
    return out

def seq(parts, gap=0.0):
    out = []
    for p in parts:
        out += p + [0.0] * int(RATE * gap)
    return out

def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))

write("tap", tone([660], 0.09, vol=0.25, glide=0.3))
write("pickup", tone([520], 0.12, vol=0.25, glide=0.5))
write("snap", seq([tone([784], 0.07, vol=0.3), tone([1047], 0.14, vol=0.3)]))
write("soft_return", tone([440], 0.25, vol=0.18, glide=-0.15))       # neutral, never a buzzer
write("sparkle", seq([tone([1319], 0.06, vol=0.15), tone([1568], 0.06, vol=0.13), tone([2093], 0.12, vol=0.1)]))
write("success", seq([tone([523], 0.12), tone([659], 0.12), tone([784], 0.12), tone([1047, 784], 0.5, release=0.8)]))
write("light", seq([tone([392, 587], 0.3, vol=0.25), tone([523, 784], 0.3, vol=0.25), tone([659, 988, 1319], 1.0, vol=0.25, release=0.9)]))
write("splash", tone([180], 0.35, vol=0.3, noise=0.7, glide=-0.4))
write("bubble", seq([tone([300], 0.06, vol=0.2, glide=1.0), tone([420], 0.06, vol=0.2, glide=1.0)], gap=0.03))
write("whoosh", tone([220], 0.3, vol=0.15, noise=0.85, glide=0.8))
print("sfx written:", sorted(p.name for p in OUT.glob("*.wav")))
