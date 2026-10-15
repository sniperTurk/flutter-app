"""Audit 2026-10-15b (PR #317, Hedef / Hava / Pro split into part files):
the hand values in the Dart audit test come from the independent reference
solver, every click count used there is clear of a rounding edge, and the
split kept the state, solve and auto-dial in the library's main files."""
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15b_hedef as d  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "test" / "audit_2026_10_15b" / "hedef_split_audit_test.dart"
BALLISTICS = ROOT / "lib" / "features" / "ballistics"

_CONST = re.compile(r"^const (_[A-Za-z0-9]+) = (-?[0-9.]+);", re.M)

# Dart constant name for each printed hand value.
_NAMES = {
    "up_mrad_100": "_up100",
    "right_mrad_100": "_right100",
    "up_mrad_350": "_up350",
    "up_moa_350": "_upMoa350",
    "right_mrad_350": "_right350",
    "tof_s_350": "_tof350",
    "v_mps_350": "_v350",
    "up_mrad_620": "_up620",
    "up_moa_620": "_upMoa620",
    "right_mrad_620": "_right620",
    "tof_s_620": "_tof620",
    "v_mps_620": "_v620",
}


def _dart_consts() -> dict[str, float]:
    return {m.group(1): float(m.group(2))
            for m in _CONST.finditer(DART.read_text(encoding="utf-8"))}


def _strip_comments(src: str) -> str:
    return "\n".join(line.split("//", 1)[0] for line in src.splitlines())


class HandValues(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rows = dict(d.rows())
        cls.pts = d.solve()

    def test_dart_constants_match_the_reference(self):
        consts = _dart_consts()
        for name, dart in _NAMES.items():
            with self.subTest(value=name):
                self.assertIn(dart, consts)
                self.assertAlmostEqual(consts[dart], self.rows[name], delta=5e-5)

    def test_tolerance_and_moa_factor(self):
        consts = _dart_consts()
        self.assertEqual(consts["_tol"], d.TOLERANCE_MRAD)
        self.assertAlmostEqual(consts["_moaPerMrad"], d.MOA_PER_MRAD, places=12)

    def test_clicks_used_in_the_dart_test(self):
        expected = {100.0: (0, -2), 350.0: (22, -8), 620.0: (59, -16)}
        for r, (up, right) in expected.items():
            p = self.pts[r]
            with self.subTest(range_m=r):
                self.assertEqual(d.clicks(p.correction_mrad), up)
                self.assertEqual(d.clicks(p.wind_mrad), right)

    def test_click_counts_clear_of_rounding_edges(self):
        # A solver within the tolerance still dials the same click.
        for r, p in self.pts.items():
            for v in (p.correction_mrad, p.wind_mrad):
                with self.subTest(range_m=r, mrad=v):
                    self.assertGreater(d.click_margin_mrad(v), d.TOLERANCE_MRAD)

    def test_moa_profile_elevation_clicks(self):
        # MOA profile on a 0,1 mrad scope: standard ¼ MOA click (app rule).
        moa = self.pts[620.0].correction_mrad * d.MOA_PER_MRAD
        self.assertEqual(round(moa / 0.25), 81)
        edge = abs(abs(moa / 0.25 - 81) - 0.5) * 0.25 / d.MOA_PER_MRAD
        self.assertGreater(edge, d.TOLERANCE_MRAD)

    def test_wind_from_the_left_needs_left_correction(self):
        for r, p in self.pts.items():
            with self.subTest(range_m=r):
                self.assertLess(p.wind_mrad, 0)


class SplitStructure(unittest.TestCase):
    """The split moved code into part files; behaviour stays in one place."""

    def _read(self, name: str) -> str:
        return (BALLISTICS / name).read_text(encoding="utf-8")

    def test_part_files_declared(self):
        main = self._read("ballistics_screen.dart")
        for part in ("ballistics_shared_rows.dart", "hava_durumu_view.dart",
                     "hedef_view.dart", "pro_ayarlar_view.dart"):
            with self.subTest(part=part):
                self.assertIn(f"part '{part}';", main)
                self.assertTrue(self._read(part).startswith(
                    "part of 'ballistics_screen.dart';"))
        scope = self._read("scope_dial_view.dart")
        for part in ("scope_reticle.dart", "scope_results.dart",
                     "scope_turrets.dart", "scope_workings.dart"):
            with self.subTest(part=part):
                self.assertIn(f"part '{part}';", scope)
                self.assertTrue(self._read(part).startswith(
                    "part of 'scope_dial_view.dart';"))

    def test_view_parts_hold_no_state_and_no_store(self):
        # Extensions cannot declare instance fields; persistence stays in
        # ballistics_screen.dart (same keys as before the split).
        for part in ("ballistics_shared_rows.dart", "hava_durumu_view.dart",
                     "hedef_view.dart", "pro_ayarlar_view.dart"):
            src = _strip_comments(self._read(part))
            with self.subTest(part=part):
                self.assertNotRegex(src, r"\bShotSettingsStore\b")
                self.assertNotRegex(src, r"\bSettingsStore\b")
                self.assertNotRegex(src, r"\bSharedPreferences\b")
                self.assertNotRegex(src, r"\bsetState\(")

    def test_solve_and_auto_dial_stay_in_the_main_file(self):
        main = self._read("ballistics_screen.dart")
        for needle in ("bool _autoDialArmed = false;",
                       "Widget _scopeDial(TrajectoryPoint? shot)",
                       "_windageRevealToken++",
                       "void _saveShotSettings()",
                       "void _putWeatherSi(ShotSettings s)"):
            with self.subTest(needle=needle):
                self.assertIn(needle, main)

    def test_auto_dial_and_button_clamp_alike(self):
        # Auto-dial (Pro distance) and "Kuleleri kur" dial the same clicks:
        # nearest click, inside the same up / down / windage travel.
        main = self._read("ballistics_screen.dart")
        self.assertIn("maxElevationClicks: upClicks,", main)
        self.assertIn("maxElevationDownClicks: downClicks,", main)
        self.assertIn("maxWindageClicks: maxWindage,", main)
        self.assertRegex(main, r"within\(\s*ScopeDialMath\.clicksFor\(requiredUp, click\),"
                               r"\s*-downClicks,\s*upClicks,\s*\)")
        turrets = self._read("scope_turrets.dart")
        self.assertRegex(turrets, r"rawElev\s*\?\.clamp\(-_downClicks, maxElevationClicks\)")
        self.assertRegex(turrets, r"rawWind\s*\.clamp\(-maxWindageClicks, maxWindageClicks\)")

    def test_workings_panel_closed_by_default_and_lines_unchanged(self):
        src = self._read("scope_workings.dart")
        self.assertIn("bool _open = false;", src)
        self.assertIn("return _WorkingsPanel(key: ScopeDialKeys.workings, lines: lines);", src)
        # The panel only shows the lines it was given.
        self.assertIn("for (final l in widget.lines)", src)

    def test_wind_guide_flag_defaults_off(self):
        main = self._read("ballistics_screen.dart")
        m = re.search(r"_showWindGuideLink\s*=\s*bool\.fromEnvironment\(([^)]*)\)", main)
        self.assertIsNotNone(m)
        self.assertNotIn("defaultValue", m.group(1))

    @unittest.skip("HDF-1 (low): WIND_GUIDE_LINK keeps the removed Rüzgâr link "
                   "behind a flag; CLAUDE.md 2026-10-15 says delete (= FLG-1)")
    def test_removed_wind_guide_link_is_deleted(self):
        src = self._read("ballistics_screen.dart") + self._read("hava_durumu_view.dart")
        self.assertNotIn("WIND_GUIDE_LINK", src)
        self.assertNotIn("WindGuideLink(", src)


if __name__ == "__main__":
    unittest.main()
