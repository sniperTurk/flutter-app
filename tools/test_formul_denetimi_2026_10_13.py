"""Regression tests for the 2026-10-13 formula audit
(docs/research/formul_denetimi.md). Standard library only."""
from __future__ import annotations

import math
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import formul_denetimi_2026_10_13 as aud  # noqa: E402
import formula_reference as ref  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DART_TEST = ROOT / "test/formul_denetimi_2026_10_13_test.dart"
STABILITY = ROOT / "lib/core/stability.dart"
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"

_SOLVED = {load.id: aud.solve(load) for load in aud.LOADS}


class IndependentRoutesAgree(unittest.TestCase):
    """The range-stepped RK4 reference and tools/formula_reference.py
    (time-adaptive Dormand-Prince 5(4), different code) give the same
    trajectory for the same model (linear Cd, ICAO dry air)."""

    def test_against_dormand_prince(self):
        for load in aud.LOADS:
            for wind in (0.0, aud.WIND_MPH * aud.MPH_MPS):
                sc = ref.Scenario(load.id, load.model, load.bc, load.grain, load.diameter_in,
                                  load.mv_fps * aud.FOOT_M, load.zero_m, load.sight_mm,
                                  tuple(float(r) for r in load.ranges),
                                  env=ref.Env(15, 1013.25, 0, wind, 90.0))
                pts = ref.solve(sc, interpolation="linear", atmosphere="magnus")
                for p, o in zip(pts, _SOLVED[load.id]):
                    if wind == 0:
                        self.assertAlmostEqual(p.correction_mrad, o.corr_mrad, delta=1e-4)
                        self.assertAlmostEqual(p.velocity_mps, o.v_mps, delta=1e-3)
                        self.assertAlmostEqual(p.tof_s, o.tof_s, delta=1e-6)
                    else:
                        self.assertAlmostEqual(p.wind_mrad, o.drift_mrad, delta=1e-4)

    def test_didion_lag_rule(self):
        # Wind drift of a point mass in a uniform crosswind:
        # D = W (TOF - R / V0) (McCoy 1999, ch. 5, eq. 5.33). Exact for
        # flat fire; the small vertical launch angle costs < 0.5 %.
        w = aud.WIND_MPH * aud.MPH_MPS
        for load in aud.LOADS:
            v0 = load.mv_fps * aud.FOOT_M
            for o in _SOLVED[load.id]:
                lag = w * (o.tof_s - o.range_m / v0) * 100
                self.assertAlmostEqual(o.drift_cm, lag, delta=max(0.005 * lag, 0.01), msg=load.id)

    def test_icao_sea_level(self):
        self.assertAlmostEqual(aud.RHO, 1.2250, delta=5e-5)
        self.assertAlmostEqual(aud.SOUND, 340.29, delta=0.01)


class DartVectorsMatchReference(unittest.TestCase):
    def test_vectors(self):
        text = DART_TEST.read_text(encoding="utf-8")
        rows = re.findall(
            r"\(([\d.]+), (-?[\d.]+), (-?[\d.]+), ([\d.]+), ([\d.]+)\),", text)
        expected = [o for load in aud.LOADS for o in _SOLVED[load.id]]
        self.assertEqual(len(rows), len(expected))
        for row, o in zip(rows, expected):
            r, elev, wind, v, tof = map(float, row)
            self.assertEqual(r, o.range_m)
            self.assertAlmostEqual(elev, o.corr_mrad, delta=1e-5)
            self.assertAlmostEqual(wind, o.drift_mrad, delta=1e-5)
            self.assertAlmostEqual(v, o.v_mps, delta=1e-4)
            self.assertAlmostEqual(tof, o.tof_s, delta=1e-6)


class MillerSubsonic(unittest.TestCase):
    """Courtney & Miller, Precision Shooting Jan 2012 (arXiv:1410.5340):
    below the speed of sound the velocity factor keeps its value there."""

    def test_floor(self):
        clamped = aud.miller_sg(50, 0.25, 10 / 25.4, 17, 985)
        raw = aud.miller_sg(50, 0.25, 10 / 25.4, 17, 985, subsonic_clamp=False)
        self.assertAlmostEqual(clamped, 2.788188, delta=1e-5)
        self.assertAlmostEqual(raw, 2.674167, delta=1e-5)
        sound_fps = aud.SOUND / aud.FOOT_M
        self.assertAlmostEqual(clamped / raw, (sound_fps / 985) ** (1 / 3), delta=1e-12)
        self.assertEqual(aud.miller_sg(50, 0.25, 10 / 25.4, 17, 600), clamped)

    def test_supersonic_matches_existing_reference(self):
        a = aud.miller_sg(175, 0.308, 1.240, 10, 2600, p_hpa=29.92 * 33.8638866667)
        b = ref.miller_sg(175, 0.308, 1.240, 10, 2600, 59, 29.92)
        self.assertAlmostEqual(a, b, delta=1e-4)

    def test_dart_source(self):
        src = re.sub(r"\s+", " ", STABILITY.read_text(encoding="utf-8"))
        self.assertIn("sound.isFinite && sound > velocityMps ? sound : velocityMps", src)
        self.assertIn("math.sqrt(1.4 * 287.05 * (temperatureC + 273.15))", src)
        self.assertIn("arXiv:1410.5340", src)


class SpinDriftWiring(unittest.TestCase):
    def test_pellet_excluded_and_profile_length_used(self):
        src = re.sub(r"\s+", " ", SCREEN.read_text(encoding="utf-8"))
        self.assertIn("if (ammunition?.type == AmmunitionType.pellet) return null;", src)
        self.assertIn("final v = typed ?? ammunition?.lengthMm;", src)
        self.assertNotIn("_parsed(bulletLengthCtl)!", src)


if __name__ == "__main__":
    unittest.main()
