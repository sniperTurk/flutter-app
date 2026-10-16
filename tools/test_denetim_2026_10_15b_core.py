"""Audit 2026-10-15b (PR #324, formulas moved into lib/core): the hand values
in the Dart audit test are reproduced from definitions, and no inline copy
of a moved formula is left in the screens (a second copy could drift)."""
import math
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15b_core as d  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "test" / "audit_2026_10_15b" / "core_formulas_audit_test.dart"
FEATURES = ROOT / "lib" / "features"


class HandValues(unittest.TestCase):
    def test_definitions(self):
        self.assertAlmostEqual(d.PA_PER_INHG, 3386.389, delta=0.001)
        self.assertAlmostEqual(d.RAD_PER_MOA * 1000, math.pi / 10.8, places=15)
        self.assertEqual(d.KG_PER_GR, 0.06479891e-3)

    def test_miller_textbook_case(self):
        # 168 gr, d = 0,3 in, t = 40 cal, l = 4 cal at standard conditions:
        # 30·168 / (1600·0,027·4·17) = 1,71569 before the pressure factor.
        base = 30 * 168 / (40 ** 2 * 0.3 ** 3 * 4 * (1 + 16))
        sg = d.miller_sg(168, 7.62, 12, 30.48, 2800 * d.M_PER_FT, 15, 1013.25)
        self.assertAlmostEqual(sg / base, 29.92 / (101325 / d.PA_PER_INHG), places=12)

    def test_subsonic_floor(self):
        low = d.miller_sg(168, 7.62, 12, 30.48, 300, 15, 1013.25)
        at_sound = d.miller_sg(168, 7.62, 12, 30.48, 340.294, 15, 1013.25)
        self.assertAlmostEqual(low, at_sound, places=5)

    def test_values_in_the_dart_test(self):
        src = DART.read_text(encoding="utf-8")
        for name, value in d.rows():
            if isinstance(value, int):
                continue
            # Every float hand value printed by the module must appear in the
            # Dart test (closeTo literal), to the digits printed there.
            shown = [float(x) for x in re.findall(r"closeTo\(([0-9.]+),", src)]
            self.assertTrue(
                any(abs(s - value) <= 1e-9 * max(1.0, abs(value)) for s in shown),
                f"{name} = {value!r} missing from the Dart test",
            )

    def test_click_counts(self):
        self.assertEqual(d.mount_cant_clicks(20, 0.1, "mrad"), 58)
        self.assertEqual(d.mount_cant_clicks(20, 0.25, "moa"), 80)
        self.assertEqual(d.mount_cant_clicks(60, 0.25, "moa"), 240)
        self.assertEqual(d.mount_cant_clicks(30, 0.1, "mrad"), 87)


class NoLeftoverInlineCopy(unittest.TestCase):
    """The expressions #324 moved into lib/core must not reappear in a
    screen (they would be a second, independently edited copy)."""

    PATTERNS = {
        "spin drift fit": re.compile(r"1\.25\s*\*\s*\("),
        "aero jump fit": re.compile(r"0\.0024\s*\*"),
        "low-pass factor": re.compile(r"1\s*-\s*math\.exp\(\s*-\s*dt"),
        "sectional density": re.compile(r"7000\s*\*\s*dIn"),
        "zero offset copy": re.compile(r"math\.atan\(\s*m\s*/\s*z"),
        "display inch factor": re.compile(r"39\.3700787"),
        "fps factor": re.compile(r"\b0\.3048\b"),
    }

    def test_no_copy_in_features(self):
        hits = []
        for p in sorted(FEATURES.rglob("*.dart")):
            for no, line in enumerate(p.read_text(encoding="utf-8").splitlines(), 1):
                code = line.split("//", 1)[0]
                for name, pat in self.PATTERNS.items():
                    if pat.search(code):
                        hits.append(f"{p.relative_to(ROOT)}:{no} {name}")
        self.assertEqual(hits, [])


if __name__ == "__main__":
    unittest.main()
