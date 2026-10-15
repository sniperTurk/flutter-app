#!/usr/bin/env python3
"""Recolour the app icon's black background to the app background #0B1620.

Usage: recolor_icon_bg.py INPUT.png OUTPUT.png

Method (owner preview, 2026-10-15):
  w = clip(1 - max(R,G,B)/70, 0, 1)
  w = 0 for red pixels (R > G+40 and R > B+40)
  out = clip(in + w * (11, 22, 32), 0, 255)

Pure black becomes #0B1620, anti-aliased edges blend smoothly, pixels whose
max channel is >= 70 (white reticle, silver bullet, red trajectory) are left
unchanged. Output is RGB (no alpha), same size as the input. No network.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

BG = np.array([11, 22, 32], dtype=np.float64)  # #0B1620
LIMIT = 70.0


def recolor(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    w = np.clip(1.0 - a.max(axis=-1) / LIMIT, 0.0, 1.0)
    w[(r > g + 40) & (r > b + 40)] = 0.0
    out = np.clip(a + w[..., None] * BG, 0, 255)
    return np.rint(out).astype(np.uint8)


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: recolor_icon_bg.py INPUT.png OUTPUT.png", file=sys.stderr)
        return 2
    from PIL import Image  # only needed for file I/O

    src, dst = Path(argv[1]), Path(argv[2])
    with Image.open(src) as im:
        if im.mode != "RGB":
            print(f"input must be RGB without alpha, got {im.mode}", file=sys.stderr)
            return 1
        rgb = np.array(im)
    Image.fromarray(recolor(rgb), "RGB").save(dst, format="PNG", optimize=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
