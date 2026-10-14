"""Self-checks of the 2026-10-14 audit reference (formul_denetimi_2026_10_14)."""
import math
import unittest

import formul_denetimi_2026_10_14 as ref
import formul_denetimi_2026_10_13 as prev


class AtmosphereTests(unittest.TestCase):
    def test_icao_station_pressure(self):
        # ICAO Doc 7488/3 table: 1000 m 898.76 hPa, 2000 m 795.01 hPa.
        self.assertAlmostEqual(ref.isa_station_pressure_hpa(1000), 898.76, delta=0.05)
        self.assertAlmostEqual(ref.isa_station_pressure_hpa(2000), 795.01, delta=0.1)

    def test_cipm2007_reference_point(self):
        # Picard et al. 2008: dry-ish lab air 20 C, 101325 Pa, 50 % RH ~ 1.1992.
        self.assertAlmostEqual(ref.cipm2007_density(20, 1013.25, 50), 1.1992, delta=0.0005)
        # Dry ICAO sea level: 1.2255 (CIPM) vs 1.2250 (ideal gas).
        self.assertAlmostEqual(ref.cipm2007_density(15, 1013.25, 0), 1.2255, delta=0.0003)

    def test_speed_of_sound(self):
        self.assertAlmostEqual(ref.dry_sound(15), 340.294, delta=0.001)


class StabilityTests(unittest.TestCase):
    def test_miller_matches_previous_audit(self):
        self.assertAlmostEqual(
            ref.miller_sg(50, 6.35, 16, 10, 300, 15, 1013.25), 3.1476, delta=0.0005)

    def test_litz(self):
        self.assertAlmostEqual(ref.litz_spin_drift_m(2.5, 1.0), 1.25 * 3.7 * 0.0254, places=12)
        self.assertAlmostEqual(ref.litz_jump_moa_per_mph(2.0, 4.0), 0.0424, places=12)


class SolverTests(unittest.TestCase):
    def test_world_frame_level_matches_range_stepped_reference(self):
        # Two independent integrators (time-stepped world frame vs the
        # 2026-10-13 range-stepped one) agree on the .308 load.
        pts = ref.solve(ref.Shot(**ref.R308), [300, 500])
        load = next(l for l in prev.LOADS if l.id == "r308_168_g1")
        other = {o.range_m: o for o in prev.solve(load)}
        for p in pts:
            self.assertAlmostEqual(p.correction_mrad, other[p.range_m].corr_mrad, delta=0.002)

    def test_zero_is_on_the_sight_line(self):
        p = ref.solve(ref.Shot(**ref.PELLET), [30])[0]
        self.assertLess(abs(p.correction_mrad), 1e-6)

    def test_findings_have_field_size(self):
        alt = ref.finding_altitude()["308"]["rows"]
        self.assertGreater(alt[-1][3], 50)  # cm at 800 m
        mixed = ref.finding_pcp_mixed_velocity()["rows"]
        self.assertGreater(abs(mixed[0][1]), 0.1)  # off zero at the zero range
        self.assertGreater(ref.finding_turret_zero_angle()["pellet"]["zero_angle_mrad"], 3)


if __name__ == "__main__":
    unittest.main()
