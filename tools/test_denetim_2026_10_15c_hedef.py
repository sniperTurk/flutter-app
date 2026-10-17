"""Audit 2026-10-15c (Hedef result row #330, side turret 66 x 180 #332,
arrow areas #349, KUL-1 travel #337, click sound #352, HDF-1 removal #357,
Pro row layout #358): the hand values in the Dart audit test come from the
independent reference solver, every exact click count used there is clear
of a rounding edge, and the code still follows the rules the hand
calculation assumes."""
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15c_hedef as d  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "test" / "audit_2026_10_15c" / "hedef_audit_test.dart"
BALLISTICS = ROOT / "lib" / "features" / "ballistics"

_CONST = re.compile(r"^const (_[A-Za-z0-9]+) = (-?[0-9.]+);", re.M)

# Dart constant name for each printed hand value.
_NAMES = {
    "up_mrad_450": "_up450",
    "up_moa_450": "_upMoa450",
    "up_mrad_620": "_up620",
    "up_moa_620": "_upMoa620",
    "right_mrad_620": "_right620",
    "right_moa_620": "_rightMoa620",
    "up_mrad_800yd": "_up800yd",
    "right_mrad_800yd": "_right800yd",
    "zero_angle_mrad": "_zeroAngle",
}


def _dart_consts() -> dict[str, float]:
    return {m.group(1): float(m.group(2))
            for m in _CONST.finditer(DART.read_text(encoding="utf-8"))}


def _read(name: str) -> str:
    return (BALLISTICS / name).read_text(encoding="utf-8")


class HandValues(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.v = dict(d.values())
        cls.pts = d.solve_metric()
        cls.yard = d.solve_yard()

    def test_dart_constants_match_the_reference(self):
        consts = _dart_consts()
        for name, dart in _NAMES.items():
            with self.subTest(value=name):
                self.assertIn(dart, consts)
                self.assertAlmostEqual(consts[dart], self.v[name], delta=5e-5)

    def test_tolerance_and_moa_factor(self):
        consts = _dart_consts()
        self.assertEqual(consts["_tol"], d.TOLERANCE_MRAD)
        self.assertAlmostEqual(consts["_moaPerMrad"], d.MOA_PER_MRAD, places=12)
        # 1 MOA = π/10800 rad, 1 yd = 0.9144 m (definitions).
        self.assertAlmostEqual(d.MOA_PER_MRAD, 3.437746770784939, places=12)
        self.assertAlmostEqual(800 * d.YARD_M, 731.52, places=9)

    def test_mrad_620_row(self):
        # "620 m → 5,89 mrad up = 59 U; 1,61 mrad left = 16 L".
        p = self.pts[620.0]
        up, right = d.row(p.correction_mrad, p.wind_mrad, 0.1, "MRAD", False)
        self.assertEqual(up, ["Üst kule", "59 klik", "5,9 MRAD yukarı"])
        self.assertEqual(right, ["Yan kule", "16 klik", "1,6 MRAD sol"])
        for a in (p.correction_mrad, p.wind_mrad):
            self.assertGreater(d.click_margin(a, 0.1), d.TOLERANCE_MRAD)

    def test_moa_620_row(self):
        p = self.pts[620.0]
        up = p.correction_mrad * d.MOA_PER_MRAD
        self.assertEqual(d.clicks(up, 0.25), 81)
        # 81 is safe; the side clicks and the one-decimal texts are near an
        # edge, so the Dart test derives them from the app's own angle.
        self.assertGreater(d.click_margin(up, 0.25) / d.MOA_PER_MRAD,
                           d.TOLERANCE_MRAD)

    def test_yard_800_row(self):
        y = self.yard
        self.assertAlmostEqual(y.range_m, 731.52, places=6)
        up, right = d.row(y.correction_mrad, y.wind_mrad, 0.1, "MRAD", False)
        self.assertEqual(up, ["Üst kule", "79 klik", "7,9 MRAD yukarı"])
        self.assertEqual(right, ["Yan kule", "20 klik", "2,0 MRAD sol"])
        for a in (y.correction_mrad, y.wind_mrad):
            self.assertGreater(d.click_margin(a, 0.1), d.TOLERANCE_MRAD)

    def test_wind_from_the_left_needs_left(self):
        for r in (450.0, 620.0):
            self.assertLess(self.pts[r].wind_mrad, 0)
        self.assertLess(self.yard.wind_mrad, 0)

    def test_eighth_moa_travel(self):
        t = d.eighth_moa_travel()
        self.assertEqual(t["half"], 180)
        self.assertEqual(t["zero"], 35)
        self.assertEqual(t["up"], 145)
        self.assertEqual(t["down"], 215)
        self.assertLessEqual(t["up"] + t["down"], 2 * t["half"] + 2 * t["zero"])
        # 450 m inside the UP travel, 620 m beyond it (HDF-4 scenario), by
        # far more than any solver spread (0,03 mrad = 0,8 click of 1/8 MOA).
        need450 = self.pts[450.0].correction_mrad * d.MOA_PER_MRAD / 0.125
        need620 = self.pts[620.0].correction_mrad * d.MOA_PER_MRAD / 0.125
        self.assertLess(need450 + 5, t["up"])
        self.assertGreater(need620 - 5, t["up"])

    def test_zero_angle(self):
        # Sight 45 mm + drop over 100 m: (0,045 + ~0,083) / 100 m.
        self.assertAlmostEqual(self.v["zero_angle_mrad"], 1.279, delta=0.002)

    def test_fixed1_matches_dart_rounding(self):
        self.assertEqual(d.fixed1(0.05), "0,1")   # 0.05 is just above 0.05
        self.assertEqual(d.fixed1(0.25), "0,3")   # exact tie: up
        self.assertEqual(d.fixed1(-5.8948), "5,9")
        self.assertEqual(d.fixed1(0.0), "0,0")

    def test_hdf3_direction_word_vs_click_count(self):
        # Consistent on a 0,1 mrad turret: the one-decimal print and the
        # click count share their rounding edges.
        for a in (0.04, 0.05, 0.06, -0.06, 5.8948, -1.608):
            with self.subTest(angle=a):
                self.assertTrue(d.direction_consistent(a, 0.1))
        # HDF-3: 0,05 mrad, ¼ MOA and 1/8 MOA turrets.
        self.assertEqual(d.row(0.03, 0, 0.05, "MRAD", True)[0],
                         ["Üst kule", "1 klik", "0,0 MRAD"])
        self.assertEqual(d.row(0.1, 0, 0.25, "MOA", True)[0],
                         ["Üst kule", "0 klik", "0,1 MOA yukarı"])
        for a, k in ((0.03, 0.05), (0.1, 0.25), (0.055, 0.125)):
            with self.subTest(angle=a, click=k):
                self.assertFalse(d.direction_consistent(a, k))


class CodeFollowsTheRules(unittest.TestCase):
    """The rules the hand calculation assumes, as they stand on main."""

    def test_result_row_uses_the_dial_numbers(self):
        hedef = _read("hedef_view.dart")
        self.assertIn("requiredUp: dial.requiredUp!,", hedef)
        self.assertIn("requiredRight: dial.requiredRight,", hedef)
        self.assertIn("clickValue: dial.clickValue,", hedef)
        self.assertIn("unit: dial.unit,", hedef)
        # Built once per frame (watch publish and auto-dial run once).
        self.assertEqual(hedef.count("_scopeDial(shot)"), 2)  # doc + call
        self.assertIn("final dial = _scopeDial(shot);", hedef)
        results = _read("scope_results.dart")
        self.assertIn("ScopeDialMath.clicksFor(requiredUp, clickValue)", results)
        self.assertIn("ScopeDialMath.clicksFor(requiredRight, clickValue)", results)
        self.assertIn("v.abs().toStringAsFixed(1).replaceAll('.', ',')", results)
        core = (ROOT / "lib" / "core" / "scope_dial.dart").read_text(encoding="utf-8")
        self.assertIn("return (correction / clickValue).round();", core)

    def test_row_is_not_clamped_to_the_travel(self):
        # HDF-4: the row shows the unclamped need; "Kuleleri kur" and the
        # Pro auto-dial clamp to the travel.
        results = _read("scope_results.dart")
        self.assertNotIn("maxElevationClicks", results.split("class TurretSolutionRow")[1])
        turrets = _read("scope_turrets.dart")
        self.assertRegex(turrets, r"rawElev\s*\?\.clamp\(-_downClicks, maxElevationClicks\)")

    def test_kul1_travel_formula(self):
        main = _read("ballistics_screen.dart")
        self.assertIn("math.max(0, math.min(halfUp + mountClicks - zeroClicks, 2 * halfUp))", main)
        self.assertIn("math.max(0, math.min(halfUp - mountClicks + zeroClicks, 2 * halfUp))", main)
        self.assertIn("return math.max(1, (inUnit / clickValue).floor());", main)
        self.assertIn("return (unit.fromMrad(mrad) / click).round();", main)

    def test_side_turret_geometry(self):
        # 66 × 180 pt box, 74 pt column, 30 pt arrows 28 pt from the box:
        # the box is centred, so its zero sits on the reticle's line.
        t = _read("scope_turrets.dart")
        for needle in ("sideColumnWidth = 74", "sideBoxWidth = 66",
                       "sideBoxHeight = 180", "sideArrowHeight = 30",
                       "sideArrowGap = 28", "static const double minTap = 44;"):
            self.assertIn(needle, t)
        column = 180 + 2 * (30 + 28)
        self.assertEqual(column, 296)
        self.assertEqual((column - 180) / 2, 30 + 28)
        # 44 pt fits in arrow + gap while 58·k ≥ 44, i.e. reticle ≥ 254 pt.
        self.assertGreaterEqual(58 * 254 / 334, 44)
        self.assertLess(58 * 253 / 334, 44)

    def test_click_sound_is_silent_by_default_and_after_the_value(self):
        src = (ROOT / "lib" / "services" / "turret_click_sound.dart").read_text(encoding="utf-8")
        self.assertIn("static TurretClickSound instance = const SilentTurretClickSound();", src)
        # Audio failures are swallowed.
        self.assertEqual(src.count("} catch (e) {"), 2)
        t = _read("scope_turrets.dart")
        body = t.split("void _set(int value) {", 1)[1].split("\n  }\n", 1)[0]
        # Same clamp as before #352; the value handed on does not depend on
        # the sound.
        self.assertIn("-(widget.maxNegativeClicks ?? widget.maxClicks),", body)
        self.assertIn("widget.onChanged(v);", body)
        self.assertNotIn("click()", body.split("widget.onChanged(v);")[1])

    def test_hdf1_removed_everywhere_and_unskipped(self):
        for base in ("lib", "tools", ".github"):
            for p in (ROOT / base).rglob("*"):
                if not p.is_file() or p.suffix not in (".dart", ".yml", ".yaml", ".sh"):
                    continue
                with self.subTest(path=str(p.relative_to(ROOT))):
                    self.assertNotIn("WIND_GUIDE_LINK", p.read_text(encoding="utf-8"))
        # The HDF-1 / FLG-1 tests run (no skip left behind).
        for name in ("test_denetim_2026_10_15b_hedef.py",
                     "test_denetim_2026_10_15b_guvenlik.py"):
            src = (ROOT / "tools" / name).read_text(encoding="utf-8")
            for m in re.finditer(r"@unittest\.skip\((.*)", src):
                with self.subTest(file=name):
                    self.assertNotRegex(m.group(1), r"HDF-1|FLG-1|WIND_GUIDE")
        dart = (ROOT / "test" / "audit_2026_10_15b" / "hedef_split_audit_test.dart").read_text(encoding="utf-8")
        self.assertNotRegex(dart, r"skip:[^\n]*HDF-1")
        self.assertNotRegex(dart, r"//\s*HDF-1:[^\n]*\n[^\n]*skip")

    def test_pro_row_layout_keeps_the_range_box(self):
        pro = _read("pro_ayarlar_view.dart")
        self.assertIn("key: const Key('pro-shot-range'),", pro)
        self.assertIn("controller: proRangeCtl,", pro)
        self.assertIn("ProRowHeader(", pro)


if __name__ == "__main__":
    unittest.main()
