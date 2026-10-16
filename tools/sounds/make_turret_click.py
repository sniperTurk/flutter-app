#!/usr/bin/env python3
"""Generate the turret click sound: assets/sounds/turret_click.wav.

Owner, 2026-10-15 23:30: "Dürbün kulelerini çevirme klik sesi ekleyelim."
The sound is our own: it is synthesised here, nothing is downloaded or
copied. A crisp metallic detent click:

* a short noise burst (the detent snapping in) with a fast exponential
  decay, high-passed so it is bright rather than thumpy;
* a brief high resonance (the turret's metal ringing), two partials;
* a little low body so it does not sound like a tick of a watch.

Deterministic: fixed seed, numpy's frozen legacy RandomState stream and
16-bit rounding, so running the script again gives the same bytes
(tools/test_turret_click_sound.py checks this). Mono, 44.1 kHz, 32 ms,
peak at -6 dBFS (moderate; the app also plays it at reduced volume).

Usage: python3 tools/sounds/make_turret_click.py [--out PATH]
"""
from __future__ import annotations

import argparse
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = ROOT / "assets" / "sounds" / "turret_click.wav"

RATE = 44100
DURATION_S = 0.032
SEED = 20261015
PEAK = 0.5  # -6 dBFS


def synthesize() -> np.ndarray:
    """The click as float samples in [-PEAK, PEAK]."""
    n = int(round(RATE * DURATION_S))
    t = np.arange(n, dtype=np.float64) / RATE
    rng = np.random.RandomState(SEED)

    # Detent snap: white noise, first difference (a simple high-pass),
    # 0.3 ms attack and a 2.2 ms exponential decay.
    noise = rng.standard_normal(n + 1)
    noise = np.diff(noise)
    attack = np.minimum(1.0, t / 0.0003)
    snap = noise * attack * np.exp(-t / 0.0022)

    # Metal ring: two high partials, decaying fast.
    ring = 0.55 * np.sin(2 * np.pi * 3150.0 * t) * np.exp(-t / 0.0060)
    ring += 0.30 * np.sin(2 * np.pi * 5870.0 * t) * np.exp(-t / 0.0035)

    # Low body of the turret cap.
    body = 0.35 * np.sin(2 * np.pi * 1180.0 * t) * np.exp(-t / 0.0040)

    x = 0.9 * snap / np.max(np.abs(snap)) + (ring + body) * attack

    # Last 3 ms fade to silence so the file never ends on a step.
    fade_n = int(round(RATE * 0.003))
    x[-fade_n:] *= np.linspace(1.0, 0.0, fade_n)
    x[-1] = 0.0

    return PEAK * x / np.max(np.abs(x))


def to_pcm16(x: np.ndarray) -> bytes:
    pcm = np.clip(np.round(x * 32767.0), -32768, 32767).astype("<i2")
    return pcm.tobytes()


def write(out: Path) -> Path:
    out.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(out), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(to_pcm16(synthesize()))
    return out


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = p.parse_args()
    print(write(args.out))


if __name__ == "__main__":
    main()
