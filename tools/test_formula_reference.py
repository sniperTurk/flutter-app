"""Checks for the independent formula reference (formula audit 2026-10-11).

* the reference itself reproduces published anchor values and analytic limits;
* the reference vectors embedded in test/formula_reference_vectors_test.dart
  are exactly what tools/formula_reference.py produces (no hand edits);
* formulas that live in UI state (Miller, Litz spin drift and aerodynamic
  jump) keep the published coefficients;
* the group-size statistics (extreme spread of N shots) match a Monte Carlo.
Standard library only.
"""
from __future__ import annotations

import math
import random
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as ref  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SCREEN = ROOT / "lib/features/ballistics/ballistics_screen.dart"
HIT_PROB = ROOT / "lib/tools/domain/hit_probability.dart"
WEZ = ROOT / "lib/core/wez.dart"


class PublishedAnchors(unittest.TestCase):
    def test_icao_standard_atmosphere_table(self):
        # ICAO Doc 7488/3, Table 1 (hPa), tabulated by GEOMETRIC height h;
        # the formula takes geopotential H = r0 h / (r0 + h), r0 = 6356766 m.
        for h, p in {0: 1013.25, 1000: 898.76, 2000: 795.01, 3000: 701.21, 5000: 540.48}.items():
            geo = 6356766 * h / (6356766 + h)
            self.assertAlmostEqual(ref.isa_pressure_pa(geo) / 100, p, delta=0.02, msg=h)
        self.assertAlmostEqual(ref.isa_density(0), 1.2250, delta=1e-4)
        self.assertAlmostEqual(ref.density_altitude_m(ref.isa_density(2500)), 2500, delta=0.01)

    def test_speed_of_sound_sea_level(self):
        # ISA a0 = 340.294 m/s (dry air, 15 °C).
        self.assertAlmostEqual(ref.speed_of_sound(15, 101325, 0), 340.294, delta=0.1)

    def test_cipm_density_close_to_isa(self):
        # Real dry air at ISA sea level is within 0.1 % of 1.225 kg/m³.
        self.assertAlmostEqual(ref.cipm2007_density(15, 101325, 0), 1.225, delta=0.0013)

    def test_wgs84_normal_gravity(self):
        self.assertAlmostEqual(ref.gravity(0), 9.7803253359, places=9)
        self.assertAlmostEqual(ref.gravity(90), 9.8321849378, places=9)
        # International Gravity Formula 1980 series at 45°.
        igf45 = 9.780327 * (1 + 0.0053024 * 0.5 - 0.0000058 * 1.0)
        self.assertAlmostEqual(ref.gravity(45), igf45, delta=1e-5)
        # Free-air gradient ~0.3086 mGal/m.
        self.assertAlmostEqual((ref.gravity(39) - ref.gravity(39, 1000)) / 1000, 3.086e-6, delta=3e-9)

    def test_buck_dew_point(self):
        # Saturated air: dew point = air temperature.
        self.assertAlmostEqual(ref.dew_point_c(25, 100), 25, delta=1e-6)
        # Psychrometric chart: 20 °C / 50 % -> 9.3 °C.
        self.assertAlmostEqual(ref.dew_point_c(20, 50), 9.3, delta=0.1)

    def test_nist_units(self):
        self.assertAlmostEqual(ref.INHG_PA, 3386.389, delta=0.001)
        self.assertAlmostEqual(ref.FOOT_POUND_FORCE_J, 1.3558179483314004, places=12)
        self.assertAlmostEqual(ref.MOA_RAD * 1000, 0.2908882086657216, places=12)
        self.assertAlmostEqual(ref.SMOA_RAD, 1 / 3600, places=15)
        self.assertAlmostEqual(math.tan(ref.MOA_RAD) * 100 * ref.YARD_M / ref.INCH_M, 1.0472, delta=1e-4)


class ReferenceSolver(unittest.TestCase):
    def test_vacuum_limit_matches_closed_form(self):
        # A huge BC removes drag: the shot must follow the parabola exactly.
        sc = ref.Scenario("vac", model="g1", bc=1e7, grain=175, caliber_in=0.308, mv_mps=800.0,
                          zero_m=100.0, sight_mm=45.0, ranges=(50.0, 300.0, 600.0))
        pts = ref.solve(sc)
        g, v, h, x0 = ref.G_STANDARD, 800.0, 0.045, 100.0
        # Zero angle from y(x0) = 0: tan a = (h + g x0²/(2v²cos²a)) / x0, iterated.
        a = 0.0
        for _ in range(50):
            a = math.atan((h + g * x0 * x0 / (2 * v * v * math.cos(a) ** 2)) / x0)
        for p in pts:
            y = -h + p.range_m * math.tan(a) - g * p.range_m ** 2 / (2 * v * v * math.cos(a) ** 2)
            self.assertAlmostEqual(p.correction_mrad, math.atan2(-y, p.range_m) * 1000, delta=1e-5)
            self.assertAlmostEqual(p.tof_s, p.range_m / (v * math.cos(a)), delta=1e-7)

    def test_constant_cd_no_gravity_is_exponential(self):
        cd = ref.Pchip([(0.0, 0.3), (5.0, 0.3)])
        m = ref._Model(rho=1.2, sound=340.0, k=0.002, cd=cd, g=0.0, wind=(0, 0, 0), omega=(0, 0, 0))
        (_t, s), = ref._fly(m, [0, 0, 0, 800.0, 0, 0], (1, 0, 0), [500.0])
        self.assertAlmostEqual(s[3], 800.0 * math.exp(-0.002 * 0.3 * 500), delta=1e-6)

    def test_pchip_is_monotone_and_hits_samples(self):
        table = ref.load_table("g7")
        p = ref.Pchip(table)
        for m, c in table:
            self.assertAlmostEqual(p(m), c, places=12)
        for (m0, c0), (m1, c1) in zip(table, table[1:]):
            mid = p((m0 + m1) / 2)
            self.assertGreaterEqual(mid, min(c0, c1) - 1e-12)
            self.assertLessEqual(mid, max(c0, c1) + 1e-12)

    def test_coriolis_matches_the_flat_earth_approximation(self):
        # Without drag the first-order deflections are exact:
        #   horizontal Z = Ω sinλ X t (right in the north),
        #   vertical (Eötvös) Y = Ω cosλ sinA X t (up when shooting east)
        # (McCoy 1999, ch. 10; Litz 2009, ch. 12). With drag the
        # Coriolis-induced sideways velocity is damped like any other
        # air-relative velocity, so the drag result is a bit smaller.
        lat = 39.0
        for bc, low, high in ((1e7, 0.98, 1.02), (0.243, 0.75, 1.0)):
            base = dict(ref.R308, ranges=(1000.0,))
            base["bc"] = bc
            off = ref.solve(ref.Scenario("a", **base))[0]
            for az, axis in ((0.0, "z"), (90.0, "y")):
                on = ref.solve(ref.Scenario("b", **base, lat_deg=lat, az_deg=az))[0]
                x, t = 1000.0, on.tof_s
                if axis == "z":
                    moved = -(on.wind_mrad - off.wind_mrad) / 1000 * x       # + = right
                    expect = ref.EARTH_OMEGA * math.sin(math.radians(lat)) * x * t
                else:
                    moved = -(on.correction_mrad - off.correction_mrad) / 1000 * x   # + = up
                    expect = ref.EARTH_OMEGA * math.cos(math.radians(lat)) * x * t
                ratio = moved / expect
                self.assertTrue(low <= ratio <= high, f"bc={bc} az={az}: ratio {ratio:.4f}")


class GeneratedVectors(unittest.TestCase):
    def test_dart_block_is_current(self):
        text = ref.DART_VECTORS.read_text(encoding="utf-8")
        block = ref.GENERATED_RE.search(text)
        self.assertIsNotNone(block, "generated block missing")
        # Numbers are compared with a tolerance: the adaptive integrator
        # turns a one-ulp libm difference (macOS vs glibc) into ~1e-7.
        num = re.compile(r"-?\d+(?:\.\d+)?(?:e[-+]?\d+)?")
        want = ref.dart_block()
        self.assertEqual(num.sub("#", block.group(0)), num.sub("#", want),
                         "structure changed: run python3 tools/formula_reference.py --write-dart")
        for a, b in zip(num.findall(block.group(0)), num.findall(want)):
            x, y = float(a), float(b)
            self.assertLessEqual(abs(x - y), 1e-6 * max(1.0, abs(y)),
                                 f"{a} vs {b}: run python3 tools/formula_reference.py --write-dart")


class SpinDriftSourceContract(unittest.TestCase):
    """Miller, Litz spin drift and aerodynamic jump are computed in the shot
    screen's state; their published coefficients must stay exactly as cited."""

    @classmethod
    def setUpClass(cls):
        cls.src = re.sub(r"\s+", " ", SCREEN.read_text(encoding="utf-8"))

    def test_miller(self):
        for piece in [
            "30 * basis.grain / (tCal * tCal * dIn * dIn * dIn * lCal * (1 + lCal * lCal))",
            "math.pow(vFps / 2800, 1 / 3)",
            "((tF + 460) / 519)",
            "(29.92 / pInHg)",
            "basis.environment.temperatureC * 9 / 5 + 32",
        ]:
            self.assertIn(piece, self.src)
        # 1 hPa in inHg (NIST: 1 inHg = 33.8638866667 hPa).
        self.assertIn(f"basis.environment.pressureHpa * {1 / 33.8638866667:.13f}", self.src)

    def test_litz_spin_drift_and_jump(self):
        self.assertIn("1.25 * (st.sg + 1.2) * math.pow(shot.timeOfFlightS, 1.83)", self.src)
        self.assertIn("0.01 * st.sg - 0.0024 * st.lCal + 0.032", self.src)

    def test_reference_values_for_the_report(self):
        # .308 175 gr, 1.240 in, 1:10 twist, 2600 fps, 59 °F, 29.92 inHg.
        sg = ref.miller_sg(175, 0.308, 1.240, 10, 2600, 59, 29.92)
        self.assertAlmostEqual(sg, 2.40, delta=0.01)
        drift_cm = ref.litz_spin_drift_in(sg, 2.057) * 2.54   # 1000 m flight time
        self.assertAlmostEqual(drift_cm, 42.8, delta=0.2)


class GroupStatistics(unittest.TestCase):
    def test_extreme_spread_factors(self):
        text = HIT_PROB.read_text(encoding="utf-8")
        table = {int(n): float(k) for n, k in re.findall(r"(\d+): ([\d.]+),", text)}
        self.assertEqual(sorted(table), list(range(2, 11)))
        self.assertIn("/ 3.067", WEZ.read_text(encoding="utf-8"))
        self.assertAlmostEqual(table[2], math.sqrt(math.pi), delta=5e-4)
        rnd = random.Random(20261011)
        for n in (3, 5, 10):
            total, groups = 0.0, 20000
            for _ in range(groups):
                pts = [(rnd.gauss(0, 1), rnd.gauss(0, 1)) for _ in range(n)]
                total += max(math.dist(a, b) for i, a in enumerate(pts) for b in pts[i + 1:])
            mc = total / groups
            self.assertAlmostEqual(table[n], mc, delta=0.012 * mc, msg=n)

    def test_rayleigh_hit_probability(self):
        rnd = random.Random(7)
        sigma, radius, n = 1.0, 1.3, 200000
        hits = sum(1 for _ in range(n) if math.hypot(rnd.gauss(0, sigma), rnd.gauss(0, sigma)) <= radius)
        self.assertAlmostEqual(hits / n, 1 - math.exp(-radius ** 2 / (2 * sigma ** 2)), delta=0.004)


if __name__ == "__main__":
    unittest.main()
