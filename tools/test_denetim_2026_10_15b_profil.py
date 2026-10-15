"""Tests for tools/denetim_2026_10_15b_profil.py (pre-TestFlight audit
2026-10-15b, PROFIL SPLIT #318 + TÜR ZORUNLU #323).

Hand calculations from definitions (1 ft = 0.3048 m, 1 yd = 0.9144 m,
1 MOA = pi/10800 rad, 1 SMOA = 1 in / 100 yd) and source scans of the whole
profiles_screen.dart library (main file + part files). No Flutter needed.

Run: python3 -m unittest tools/test_denetim_2026_10_15b_profil.py
"""
from __future__ import annotations

import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import denetim_2026_10_15b_profil as d  # noqa: E402


class HandCalculation(unittest.TestCase):
    def test_angle_units_from_definitions(self):
        # 1 MOA = 1/60 degree; 1 SMOA = 1 in at 100 yd.
        self.assertAlmostEqual(d.RAD_PER_MOA / d.RAD_PER_MRAD,
                               math.pi / 10.8, places=15)
        self.assertAlmostEqual(d.RAD_PER_SMOA / d.RAD_PER_MRAD,
                               1000 / 3600, places=15)

    def test_turret_travel_round_trip_used_by_the_dart_test(self):
        # 400 clicks of 1/4 MOA = 100 MOA; 480 clicks of 1/4 SMOA = 120 SMOA.
        moa = d.clicks_to_mrad(400, 0.25, 'moa')
        smoa = d.clicks_to_mrad(480, 0.25, 'smoa')
        self.assertAlmostEqual(moa, 29.08882086657216, places=12)
        self.assertAlmostEqual(smoa, 33.333333333333336, places=12)
        self.assertEqual(d.travel_clicks(moa, 0.25, 'moa'), 400)
        self.assertEqual(d.travel_clicks(smoa, 0.25, 'smoa'), 480)

    def test_velocity_display_round_trip_within_tolerance(self):
        worst = 0.0
        mps = 100.0
        while mps <= 1500.0:
            worst = max(worst, abs(d.velocity_round_trip(mps) - mps))
            mps += 0.37
        self.assertLessEqual(worst, d.VELOCITY_TOL_MPS + 1e-12)
        # The Dart tolerance (0.02 m/s) covers it.
        self.assertLess(d.VELOCITY_TOL_MPS, 0.02)
        # 2700 fps profile: exact.
        self.assertAlmostEqual(d.velocity_round_trip(822.96), 822.96,
                               places=9)
        self.assertAlmostEqual(d.fps_to_mps(2650), 807.72, places=9)

    def test_zero_and_band_display_round_trip_within_tolerance(self):
        for m in (25.0, 91.44, 100.0, 274.32, 300.0, 457.2):
            self.assertLessEqual(abs(d.zero_round_trip_yd(m) - m),
                                 d.ZERO_TOL_M + 1e-12)
        self.assertLess(d.ZERO_TOL_M, 0.05)
        self.assertAlmostEqual(100 * d.M_PER_YD, 91.44, places=12)
        for v in (700.0, 500.0, 853.4, 241.0):
            self.assertLessEqual(abs(d.band_round_trip(v) - v),
                                 d.BAND_TOL_MPS + 1e-12)
        self.assertLess(d.BAND_TOL_MPS, 0.2)
        # The fields the Dart test reads: 700 m/s -> 2297 fps, 500 -> 1640.
        self.assertEqual(round(d.mps_to_fps(700)), 2297)
        self.assertEqual(round(d.mps_to_fps(500)), 1640)

    def test_prf7_size(self):
        e = d.prf7_effect(100, 2650, 45, 600)
        self.assertEqual(e['shown_yd'], 109.4)
        self.assertAlmostEqual(e['intended_m'], 91.44, places=9)
        self.assertAlmostEqual(e['stored_m'], 100.035, places=3)
        # Small at a short zero, about 0.18 mrad (14 cm at 800 m) at 300.
        self.assertLess(abs(e['angle_error_mrad']), 0.05)
        far = d.prf7_effect(300, 2650, 45, 800)
        self.assertGreater(far['angle_error_mrad'], 0.15)
        self.assertGreater(far['offset_mm_at_range'], 100)


class EditorSource(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.src = d.editor_source()

    def test_reads_every_part_file(self):
        for marker in ('extension _RifleSection', 'extension _ScopeSection',
                       'extension _AmmoSection', 'extension _AmmoExtraSection',
                       'class _ProfileDialogState'):
            self.assertIn(marker, self.src)

    def test_every_value_box_has_info(self):
        # CLAUDE.md: every typed or picked value gets an ⓘ; identity boxes
        # (Marka, Model, Dürbün markası, Profil adı) may skip it.
        self.assertGreater(len(d._FIELD.findall(self.src)), 30)
        self.assertEqual(d.fields_without_info(self.src), [])

    def test_info_scan_finds_a_missing_info(self):
        fake = ("MenzilInput(key: const Key('x'), label: 'Yiv oranı', "
                "controller: c)\nMenzilSelect<int>(label: 'Marka', items: [])")
        self.assertEqual(d.fields_without_info(fake),
                         [('MenzilInput', 'Yiv oranı')])

    def test_every_controller_is_read_on_save(self):
        self.assertEqual(d.controllers_not_saved(self.src), [])

    def test_tur_blocks_only_a_new_profile(self):
        self.assertTrue(d.tur_blocks_only_new_profile(self.src))

    def test_bc_plausibility_bands_unchanged_since_previous_testflight(self):
        # Same G1 / G7 / slug / pellet bands as main ea9c9e8.
        for band in ('(WeaponPlatform.firearm, _, BallisticModel.g1) => '
                     '(0.32, 4.6)',
                     '(WeaponPlatform.firearm, _, BallisticModel.g7) => '
                     '(0.63, 1.8)'):
            self.assertIn(band, self.src)


if __name__ == '__main__':
    unittest.main()
