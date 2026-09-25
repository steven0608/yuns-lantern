#!/usr/bin/env python3
"""Music loops, stings and the new SFX for Yun's Lantern, synthesized (no samples, no licences).

    python design/audio/gen_audio.py      # needs numpy + ffmpeg on PATH

Writes design/audio/music/*.mp3 (loops at -18 LUFS, stings at -16) and
design/audio/sfx/*.wav (mono 22.05 kHz, like assets/audio/sfx). Everything is
warm and soft: pentatonic or diatonic major, no minor-key tension, no buzzers
(CLAUDE.md: no fail states). Loops are rendered with their reverb tail folded
back onto the start, so they repeat without a seam.
"""
import os
import shutil
import subprocess
import wave

import numpy as np

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
MUSIC, SFX, TMP = (os.path.join(HERE, d) for d in ("music", "sfx", "_tmp"))
for d in (MUSIC, SFX, TMP):
    os.makedirs(d, exist_ok=True)
rng = np.random.default_rng(20260925)

NOTE = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def hz(name):
    """'A4' -> 440.0"""
    n, o = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((NOTE[n] + 12 * (o + 1) - 69) / 12)


def midi(name):
    return NOTE[name[:-1]] + 12 * (int(name[-1]) + 1)


def mhz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


# ---- instruments -----------------------------------------------------------
def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _attack(x, ms=4):
    n = min(len(x), int(SR * ms / 1000))
    x[:n] *= np.linspace(0, 1, n)
    return x


def kalimba(f, dur=1.6, amp=1.0):
    t = _t(dur)
    x = np.zeros_like(t)
    for k, a, dec in ((1, 1.0, 3.2), (2.0, 0.28, 6), (3.01, 0.10, 9), (4.13, 0.05, 13)):
        x += a * np.exp(-dec * t) * np.sin(2 * np.pi * f * k * t)
    return _attack(x * amp * 0.5)


def bell(f, dur=2.4, amp=1.0):
    t = _t(dur)
    x = np.zeros_like(t)
    for k, a, dec in ((1, 1.0, 1.6), (2.0, 0.35, 2.4), (2.76, 0.22, 3.4), (5.4, 0.08, 6), (8.93, 0.03, 9)):
        x += a * np.exp(-dec * t) * np.sin(2 * np.pi * f * k * t)
    return _attack(x * amp * 0.42, 2)


def marimba(f, dur=1.0, amp=1.0):
    t = _t(dur)
    x = (np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * f * 4 * t) * np.exp(-18 * t)) * np.exp(-5.5 * t)
    return _attack(x * amp * 0.55, 3)


def pluck_bass(f, dur=1.0, amp=1.0):
    t = _t(dur)
    x = (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t)) * np.exp(-3.0 * t)
    return _attack(x * amp * 0.6, 8)


def pad(freqs, dur, amp=1.0):
    t = _t(dur)
    x = np.zeros_like(t)
    for f in freqs:
        for cents in (-7, 0, 7):
            fd = f * 2 ** (cents / 1200)
            ph = rng.uniform(0, 2 * np.pi)
            for k in range(1, 6):
                x += (1 / k ** 1.6) * np.sin(2 * np.pi * fd * k * t + ph * k)
    a, r = min(0.7, dur / 3), min(0.9, dur / 3)
    env = np.ones_like(t)
    na, nr = int(SR * a), int(SR * r)
    env[:na] = np.linspace(0, 1, na) ** 1.5
    env[-nr:] *= np.linspace(1, 0, nr) ** 1.5
    x = _lowpass(x * env, 0.08)
    return x * amp * 0.05 / max(1, len(freqs) / 3)


def shaker(amp=1.0):
    t = _t(0.09)
    x = rng.standard_normal(len(t)) * np.exp(-45 * t)
    x = np.diff(x, prepend=0)  # crude high-pass
    return x * amp * 0.05


def _lowpass(x, a):
    """one-pole low-pass, a in (0,1]; smaller = darker"""
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):  # fine for these lengths
        acc += a * (v - acc)
        y[i] = acc
    return y


def lowpass_fast(x, a):
    # vectorised via scipy-free IIR approximation: repeated moving average
    k = max(1, int(1 / a))
    ker = np.ones(k) / k
    return np.convolve(np.convolve(x, ker, "same"), ker, "same")


_lowpass = lowpass_fast  # noqa: F811  (keeps the pure version above for reference)


# ---- mixing ----------------------------------------------------------------
class Track:
    def __init__(self, seconds):
        self.L = np.zeros(int(SR * seconds) + SR * 4)
        self.R = np.zeros_like(self.L)

    def add(self, x, at, pan=0.0):
        i = int(at * SR)
        j = min(len(self.L), i + len(x))
        gl, gr = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        self.L[i:j] += x[: j - i] * gl
        self.R[i:j] += x[: j - i] * gr


def reverb(L, R, seconds=2.2, wet=0.28):
    n = int(SR * seconds)
    t = np.arange(n) / SR
    out = []
    for ch, seed in ((L, 1), (R, 2)):
        g = np.random.default_rng(seed)
        ir = g.standard_normal(n) * np.exp(-t / (seconds / 4.5))
        ir[: int(SR * 0.018)] = 0
        ir = lowpass_fast(ir, 0.25)
        ir /= np.sqrt(np.sum(ir ** 2))
        size = 1 << int(np.ceil(np.log2(len(ch) + n)))
        wetsig = np.fft.irfft(np.fft.rfft(ch, size) * np.fft.rfft(ir, size), size)[: len(ch)]
        out.append(ch * (1 - wet) + wetsig * wet * 1.6)
    return out


def finish_loop(tr, loop_s):
    L, R = reverb(tr.L, tr.R)
    n = int(loop_s * SR)
    tail = len(L) - n
    L[:tail] += L[n:]
    R[:tail] += R[n:]
    return np.stack([L[:n], R[:n]], 1)


def finish_sting(tr, total_s):
    L, R = reverb(tr.L, tr.R, 2.6, 0.32)
    n = int(total_s * SR)
    st = np.stack([L[:n], R[:n]], 1)
    fade = int(SR * 0.4)
    st[-fade:] *= np.linspace(1, 0, fade)[:, None]
    return st


def write_wav(path, data, rate=SR):
    data = data / max(1e-9, np.max(np.abs(data))) * 0.89
    pcm = (data * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(1 if data.ndim == 1 else data.shape[1])
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def to_mp3(name, data, lufs=-18):
    raw = os.path.join(TMP, name + ".wav")
    write_wav(raw, data)
    out = os.path.join(MUSIC, name + ".mp3")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-af",
                    f"loudnorm=I={lufs}:TP=-1.5:LRA=11", "-ar", "44100", "-b:a", "160k", out], check=True)
    return out


# ---- composition helpers ---------------------------------------------------
CHORDS = {  # root + triad, as midi offsets from C4 space
    "C": ("C3", [0, 4, 7]), "Am": ("A2", [0, 3, 7]), "F": ("F2", [0, 4, 7]), "G": ("G2", [0, 4, 7]),
    "Em": ("E3", [0, 3, 7]), "Dm": ("D3", [0, 3, 7]), "Bb": ("A#2", [0, 4, 7]), "D": ("D3", [0, 4, 7]),
    "Bm": ("B2", [0, 3, 7]),
}


def chord_freqs(name, octave_shift=12):
    root, iv = CHORDS[name]
    return [mhz(midi(root) + octave_shift + i) for i in iv]


def play_melody(tr, notes, beat, inst, amp=1.0, pan=0.0, start=0.0, octave=0):
    t = start
    for n, b in notes:
        if n:
            tr.add(inst(mhz(midi(n) + octave), max(1.2, b * beat * 1.6), amp), t, pan)
        t += b * beat
    return t


def auto_melody(chords, scale, seed, bars_per_phrase=4, beats=4):
    """Stepwise pentatonic line: chord tones on strong beats, long notes at phrase ends."""
    g = np.random.default_rng(seed)
    pats = [[1, 1, 1, 1], [1, 1, 2], [2, 1, 1], [1, 0.5, 0.5, 2], [3, 1], [1.5, 0.5, 2]]
    if beats == 3:
        pats = [[1, 1, 1], [2, 1], [1, 2], [1.5, 0.5, 1]]
    notes, cur = [], scale.index(min(scale, key=lambda m: abs(m - 67)))
    for bi, ch in enumerate(chords):
        root, iv = CHORDS[ch]
        tones = {(midi(root) + i) % 12 for i in iv}
        end = (bi + 1) % bars_per_phrase == 0
        pat = [beats] if end and bi == len(chords) - 1 else ([2, 2] if beats == 4 else [3]) if end else pats[g.integers(len(pats))]
        for k, d in enumerate(pat):
            if k == 0 or end:
                cands = [i for i in range(len(scale)) if scale[i] % 12 in tones and abs(i - cur) <= 3]
                cur = min(cands, key=lambda i: abs(i - cur) + g.random()) if cands else cur
            else:
                cur = int(np.clip(cur + g.choice([-2, -1, -1, 1, 1, 2]), 0, len(scale) - 1))
            if end and bi == len(chords) - 1:
                cur = min((i for i in range(len(scale)) if scale[i] % 12 == midi(root) % 12), key=lambda i: abs(i - cur))
            notes.append((scale[cur], d))
    return notes


def play_midi(tr, notes, beat, inst, amp=1.0, pan=0.0, start=0.0):
    t = start
    for m, b in notes:
        if m is not None:
            tr.add(inst(mhz(m), max(1.0, b * beat * 1.6), amp), t, pan)
        t += b * beat


def pent(root_name, lo=60, hi=84):
    r = NOTE[root_name]
    return [m for m in range(lo, hi + 1) if (m - r) % 12 in (0, 2, 4, 7, 9)]


def backing(tr, chords, beat, beats=4, arp=True, bass=True, pad_amp=1.0, arp_inst=kalimba, arp_amp=0.22, shake=False):
    for bi, ch in enumerate(chords):
        t0 = bi * beats * beat
        fr = chord_freqs(ch)
        tr.add(pad(fr, beats * beat + 0.8, pad_amp), t0, 0.0)
        if bass:
            root = mhz(midi(CHORDS[ch][0]))
            tr.add(pluck_bass(root, beats * beat * 0.9, 0.8), t0, -0.1)
            if beats == 4:
                tr.add(pluck_bass(root * 1.5, beat * 1.6, 0.45), t0 + 2 * beat, -0.1)
        if arp:
            seq = [0, 1, 2, 1] * beats
            for k in range(beats * 2):
                tr.add(arp_inst(fr[seq[k]] * 2, 0.9, arp_amp), t0 + k * beat / 2, 0.35 if k % 2 else -0.35)
        if shake:
            for k in range(beats):
                tr.add(shaker(1.0), t0 + k * beat + beat / 2, 0.5)


# ---- the pieces ------------------------------------------------------------
def home():
    bpm = 96
    beat = 60 / bpm
    chords = "C Am F G C Am F G F G Em Am F G C C".split()
    q, h, hd, w = 1, 2, 3, 4
    mel = [("E4", q), ("G4", q), ("A4", q), ("G4", q), ("E4", q), ("D4", q), ("C4", h),
           ("C4", q), ("D4", q), ("E4", q), ("G4", q), ("D4", hd), (None, q),
           ("E4", q), ("G4", q), ("C5", q), ("A4", q), ("G4", q), ("E4", q), ("D4", h),
           ("C4", q), ("D4", q), ("E4", q), ("D4", q), ("C4", hd), (None, q),
           ("A4", q), ("G4", q), ("A4", q), ("C5", q), ("D5", h), ("G4", h),
           ("E4", q), ("G4", q), ("E4", q), ("D4", q), ("C4", q), ("E4", q), ("A4", h),
           ("A4", q), ("G4", q), ("E4", q), ("D4", q), ("D4", q), ("E4", q), ("G4", h),
           ("E4", q), ("D4", q), ("C4", h), (None, w)]
    total = len(chords) * 4 * beat
    tr = Track(total)
    backing(tr, chords, beat, arp_amp=0.18)
    play_melody(tr, mel, beat, kalimba, 1.0, 0.1, octave=12)
    return finish_loop(tr, total)


def lullaby():
    bpm = 66
    beat = 60 / bpm
    chords = "G Em C D G Em Am G C G Am D G Em C G".split()
    q, h, hd = 1, 2, 3
    mel = [("B4", h), ("D5", q), ("E5", h), ("D5", q), ("C5", q), ("B4", q), ("A4", q), ("A4", hd),
           ("B4", h), ("D5", q), ("G5", h), ("E5", q), ("C5", q), ("B4", q), ("A4", q), ("G4", hd),
           ("E5", h), ("E5", q), ("D5", h), ("B4", q), ("C5", q), ("B4", q), ("A4", q), ("A4", q), ("D5", h),
           ("B4", h), ("G4", q), ("E4", h), ("G4", q), ("A4", q), ("B4", q), ("A4", q), ("G4", hd)]
    total = len(chords) * 3 * beat
    tr = Track(total)
    backing(tr, chords, beat, beats=3, arp=True, bass=True, pad_amp=0.9, arp_inst=kalimba, arp_amp=0.08)
    play_melody(tr, mel, beat, bell, 0.9, 0.0)
    return finish_loop(tr, total)


def journey():  # story map
    bpm = 88
    beat = 60 / bpm
    chords = "F Dm Bb C F Dm Bb C Dm Bb F C Dm Bb C F".split()
    total = len(chords) * 4 * beat
    tr = Track(total)
    backing(tr, chords, beat, arp_inst=marimba, arp_amp=0.22)
    play_midi(tr, auto_melody(chords, pent("F", 62, 84), 11), beat, kalimba, 0.95, -0.1)
    return finish_loop(tr, total)


def lands():  # Play: lands and game menus, a little bouncier
    bpm = 108
    beat = 60 / bpm
    chords = "G Em C D G Em C D C D Bm Em C D G G".split()
    total = len(chords) * 4 * beat
    tr = Track(total)
    backing(tr, chords, beat, arp_inst=marimba, arp_amp=0.24, shake=True)
    play_midi(tr, auto_melody(chords, pent("G", 62, 86), 23), beat, marimba, 1.0, 0.15)
    return finish_loop(tr, total)


def reader():  # under story narration: sparse and low
    bpm = 70
    beat = 60 / bpm
    chords = "D Bm G D D Bm G D".split()
    total = len(chords) * 4 * beat
    tr = Track(total)
    backing(tr, chords, beat, arp=False, bass=False, pad_amp=0.8)
    notes = auto_melody(chords, pent("D", 66, 86), 5)
    sparse = [(m if i % 3 == 0 else None, d) for i, (m, d) in enumerate(notes)]
    play_midi(tr, sparse, beat, bell, 0.45, 0.2)
    return finish_loop(tr, total)


def celebrate():
    tr = Track(3)
    for i, n in enumerate(("C5", "E5", "G5", "C6", "E6")):
        tr.add(bell(hz(n), 2.0, 0.8), i * 0.09, -0.4 + i * 0.2)
    tr.add(pad(chord_freqs("C", 24), 2.2, 1.6), 0.0)
    for i in range(7):
        tr.add(kalimba(hz("G6") * 2 ** (rng.integers(0, 5) * 2 / 12), 0.6, 0.25), 0.5 + i * 0.1, rng.uniform(-0.8, 0.8))
    return finish_sting(tr, 2.6)


def light_found():  # a story light lands on the map
    tr = Track(5)
    for i, n in enumerate(("G6", "E6", "D6", "C6", "A5", "G5")):
        tr.add(bell(hz(n), 2.5, 0.6), i * 0.12, 0.6 - i * 0.24)
    tr.add(pad(chord_freqs("C", 12) + chord_freqs("G", 24)[1:2], 3.4, 2.0), 0.7)
    tr.add(bell(hz("C5"), 3.0, 0.9), 0.8, 0.0)
    tr.add(bell(hz("G5"), 3.0, 0.6), 0.8, 0.0)
    return finish_sting(tr, 4.2)


# ---- SFX (mono, 22.05 kHz like the existing set) ---------------------------
SR_SFX = 22050


def _rs(x):  # 44.1k -> 22.05k
    return x[::2]


def sfx():
    t = lambda d: np.arange(int(SR * d)) / SR  # noqa: E731
    out = {}
    # pencil: soft grainy scratch, two strokes
    x = np.zeros(int(SR * 0.5))
    for s0 in (0.0, 0.22):
        n = rng.standard_normal(int(SR * 0.2)) * np.sin(np.linspace(0, np.pi, int(SR * 0.2)))
        n = np.diff(lowpass_fast(n, 0.35), prepend=0) * 3
        x[int(s0 * SR): int(s0 * SR) + len(n)] += n
    out["pencil"] = x
    # paint: wet swish (noise sweep, low-passed)
    tt = t(0.45)
    n = rng.standard_normal(len(tt)) * np.sin(np.pi * tt / 0.45) ** 2
    out["paint"] = lowpass_fast(n, 0.12) * (1 + 0.5 * np.sin(2 * np.pi * 9 * tt))
    # drum: soft tom, pitch drops
    tt = t(0.5)
    f = 150 * np.exp(-tt * 5) + 85
    out["drum"] = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * 9) + 0.15 * rng.standard_normal(len(tt)) * np.exp(-tt * 60)
    # bell: small hand bell
    out["bell"] = bell(hz("E6"), 1.2, 1.0)
    # card_flip: paper flick
    tt = t(0.18)
    n = rng.standard_normal(len(tt)) * np.exp(-tt * 40)
    out["card_flip"] = np.diff(n, prepend=0) * 0.6 + 0.4 * np.sin(2 * np.pi * (500 + 1800 * tt) * tt) * np.exp(-tt * 30)
    # pour: gentle bubbles rising
    x = np.zeros(int(SR * 0.9))
    for k in range(9):
        f0 = rng.uniform(380, 900)
        d = rng.uniform(0.05, 0.09)
        tb = t(d)
        b = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 1.2 * tb / d)) / SR) * np.sin(np.pi * tb / d)
        i = int(rng.uniform(0, 0.8) * SR)
        x[i:i + len(b)] += b[: len(x) - i]
    out["pour"] = x
    for name, x in out.items():
        fade = int(SR * 0.01)
        x[-fade:] *= np.linspace(1, 0, fade)
        write_wav(os.path.join(SFX, name + ".wav"), _rs(x) * 0.7, SR_SFX)
    return list(out)


def main():
    if not shutil.which("ffmpeg"):
        raise SystemExit("ffmpeg not on PATH")
    loops = {"home": home, "story_map": journey, "lands": lands, "reader": reader, "bedtime": lullaby}
    for name, fn in loops.items():
        data = fn()
        to_mp3(name, data, -18)
        print(f"music/{name}.mp3  {len(data) / SR:.1f}s loop")
    for name, fn in {"celebrate": celebrate, "light_found": light_found}.items():
        data = fn()
        to_mp3(name, data, -16)
        print(f"music/{name}.mp3  {len(data) / SR:.1f}s sting")
    print("sfx:", ", ".join(sfx()))
    shutil.rmtree(TMP, ignore_errors=True)


if __name__ == "__main__":
    main()
