"""Tests for the app icon background recolour (#0B1620, owner 2026-10-15).

Pure stdlib PNG decoding, so CI needs no Pillow.
"""
from __future__ import annotations

import struct
import sys
import unittest
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON = ROOT / "branding" / "ios" / "AppIcon-1024.png"
sys.path.insert(0, str(ROOT / "tools" / "branding"))

# (y, x) -> RGB sampled from the icon before the recolour (main @ 9104632).
OLD_UNCHANGED = {
    (100, 520): (243, 241, 242),  # white reticle, top bar
    (55, 498): (221, 221, 221),  # reticle anti-aliased edge
    (388, 628): (245, 15, 20),  # red trajectory dot
    (512, 512): (75, 74, 73),  # centre, max channel >= 70
}
OLD_CORNER = (6, 6, 7)
TARGET = (11, 22, 32)  # #0B1620


def _decode_rgb(path: Path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    pos, idat, ihdr = 8, b"", None
    while pos < len(data):
        (n,) = struct.unpack(">I", data[pos:pos + 4])
        kind = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + n]
        if kind == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif kind == b"IDAT":
            idat += body
        pos += 12 + n
    w, h, depth, colour, _, _, interlace = ihdr
    assert (depth, colour, interlace) == (8, 2, 0), ihdr
    raw, bpp, stride = zlib.decompress(idat), 3, w * 3
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        f, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1:
                line[x] = (line[x] + a) & 255
            elif f == 2:
                line[x] = (line[x] + b) & 255
            elif f == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pr) & 255
        rows.append(bytes(line))
        prev = line
    return w, h, colour, rows


class CommittedIconTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.w, cls.h, cls.colour, cls.rows = _decode_rgb(ICON)

    def px(self, y, x):
        return tuple(self.rows[y][x * 3:x * 3 + 3])

    def test_size_and_mode(self):
        self.assertEqual((1024, 1024), (self.w, self.h))
        self.assertEqual(2, self.colour)  # RGB, no alpha

    def test_corners_are_recoloured_by_the_method(self):
        # The old corner was (6, 6, 7), not pure black, so the method gives
        # (16, 26, 36): w = 1 - 7/70 = 0.9 -> 6 + 0.9 * (11, 22, 32).
        expected = tuple(round(o + 0.9 * t) for o, t in zip(OLD_CORNER, TARGET))
        for y, x in [(0, 0), (0, 1023), (1023, 0), (1023, 1023)]:
            for got, want in zip(self.px(y, x), expected):
                self.assertLessEqual(abs(got - want), 1, (y, x))
            # Tinted towards #0B1620: blue > green > red.
            r, g, b = self.px(y, x)
            self.assertTrue(b > g > r, (y, x))

    def test_reticle_red_and_bright_pixels_unchanged(self):
        for (y, x), old in OLD_UNCHANGED.items():
            self.assertEqual(old, self.px(y, x), (y, x))


class RecolorMethodTests(unittest.TestCase):
    def setUp(self):
        try:
            import numpy as np
        except ImportError:  # pragma: no cover
            self.skipTest("numpy not installed")
        import recolor_icon_bg as rc

        self.np, self.rc = np, rc

    def run_px(self, *pixels):
        a = self.np.array([list(pixels)], dtype=self.np.uint8)
        return [tuple(int(v) for v in p) for p in self.rc.recolor(a)[0]]

    def test_pure_black_becomes_app_background(self):
        self.assertEqual([TARGET], self.run_px((0, 0, 0)))

    def test_bright_and_red_unchanged(self):
        px = [(70, 70, 70), (255, 255, 255), (180, 180, 185), (60, 5, 5), (245, 15, 20)]
        self.assertEqual(px, self.run_px(*px))

    def test_edge_blends(self):
        (got,) = self.run_px((35, 35, 35))  # w = 0.5
        self.assertEqual((40, 46, 51), got)


if __name__ == "__main__":
    unittest.main()
