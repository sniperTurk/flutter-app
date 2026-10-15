#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-14b, area KUL (turret / zero angle / PCP
zero velocity / cleanup / GA text / rifle "Listede yok").

Independent hand references for test/audit_2026_10_14b/
turret_zero_cleanup_audit_test.dart. Written from published physics, not
from the app's Dart solver and never from another ballistic program:

* Vacuum zero angle: closed form of y(x) = -s + x*tan(a) - g*x^2/(2 v^2
  cos^2 a) = 0 (low root), plain kinematics.
* Point-mass drag zero angle: a = rho/2 * v^2 * Cd_G1(M) * (pi/4) / BC_SI
  (McCoy, Modern Exterior Ballistics, ch. 4; BC_SI = BC lb/in^2 * 703.0696
  kg/m^2), RK4 in time, ICAO Doc 7488/3 dry standard air at the zero
  (15 C, 1013.25 hPa, rho 1.2250 kg/m^3, a 340.294 m/s). The Cd values are
  the BRL G1 table stored in lib/core/standard_drag_tables.dart (public
  BRL data; only the numbers are read, never the app's solver).
* Turret travel bookkeeping (denetim F2): a 0 MOA rail parallel to the
  bore puts the scope's optical centre parallel to the bore; zeroing tilts
  the sight line down by the zero angle, i.e. the turret is dialled UP by
  it. Up left = half - zero + mount, down left = half + zero - mount, and
  their sum can never exceed the whole travel (2 * half).

Standard library only:  python3 -m unittest tools/test_denetim_2026_10_14b_kul.py
"""
from __future__ import annotations

import math
import re
import unittest
from pathlib import Path

from dart_library_source import library_text

ROOT = Path(__file__).resolve().parents[1]
G0 = 9.80665
FOOT_M = 0.3048
LB_IN2 = 0.45359237 / 0.0254**2  # 703.0696 kg/m^2
RHO_ICAO = 1.2250
A_ICAO = 340.294
MOA_MRAD = math.pi / 10.8


def g1_table() -> list[tuple[float, float]]:
    text = (ROOT / "lib/core/standard_drag_tables.dart").read_text(encoding="utf-8")
    block = re.search(r"static final g1 = DragTable\(const \[(.*?)\]\);", text, re.S)
    assert block is not None
    return [(float(a), float(b)) for a, b in
            re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", block.group(1))]


def cd(tab, mach):
    if mach <= tab[0][0]:
        return tab[0][1]
    if mach >= tab[-1][0]:
        return tab[-1][1]
    for (m0, c0), (m1, c1) in zip(tab, tab[1:]):
        if m0 <= mach <= m1:
            return c0 + (c1 - c0) * (mach - m0) / (m1 - m0)
    return tab[-1][1]


def vacuum_zero_angle_mrad(v, zero_m, sight_mm, g=G0):
    x, s = zero_m, sight_mm / 1000
    a = g * x * x / (2 * v * v)
    u = (x - math.sqrt(x * x - 4 * a * (s + a))) / (2 * a)
    return math.atan(u) * 1000


def drag_zero_angle_mrad(v, bc, zero_m, sight_mm, g=G0, dt=2e-5):
    tab = g1_table()
    bc_si = bc * LB_IN2

    def height(angle):
        x, y = 0.0, -sight_mm / 1000
        vx, vy = v * math.cos(angle), v * math.sin(angle)

        def acc(vx_, vy_):
            sp = math.hypot(vx_, vy_)
            k = RHO_ICAO / 2 * cd(tab, sp / A_ICAO) * (math.pi / 4) * sp / bc_si
            return -k * vx_, -k * vy_ - g

        while True:
            px, py = x, y
            ax1, ay1 = acc(vx, vy)
            ax2, ay2 = acc(vx + ax1 * dt / 2, vy + ay1 * dt / 2)
            ax3, ay3 = acc(vx + ax2 * dt / 2, vy + ay2 * dt / 2)
            ax4, ay4 = acc(vx + ax3 * dt, vy + ay3 * dt)
            k1x, k1y = vx, vy
            k2x, k2y = vx + ax1 * dt / 2, vy + ay1 * dt / 2
            k3x, k3y = vx + ax2 * dt / 2, vy + ay2 * dt / 2
            k4x, k4y = vx + ax3 * dt, vy + ay3 * dt
            x += dt / 6 * (k1x + 2 * k2x + 2 * k3x + k4x)
            y += dt / 6 * (k1y + 2 * k2y + 2 * k3y + k4y)
            vx += dt / 6 * (ax1 + 2 * ax2 + 2 * ax3 + ax4)
            vy += dt / 6 * (ay1 + 2 * ay2 + 2 * ay3 + ay4)
            if x >= zero_m:
                f = (zero_m - px) / (x - px)
                return py + (y - py) * f

    lo, hi = 0.0, 0.05
    for _ in range(50):
        mid = (lo + hi) / 2
        if height(mid) < 0:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2 * 1000


def half_clicks(travel_mrad, click, unit_mrad_per):
    return max(1, math.floor(travel_mrad / 2 / unit_mrad_per / click))


def zero_clicks(angle_mrad, click, unit_mrad_per):
    return round(angle_mrad / unit_mrad_per / click)


def mount_clicks(moa, click, unit_mrad_per):
    return math.floor(moa * MOA_MRAD / unit_mrad_per / click + 1e-9)


def app_travel(half, mount, zero):
    """ballistics_screen.dart (denetim F2) as written."""
    up = max(0, min(half + mount - zero, 2 * half))
    down = max(0, half - mount + zero)
    return up, down


class ZeroAngleReference(unittest.TestCase):
    def test_vacuum_308(self):
        # test/denetim_f1_f2_f3_f5_test.dart pins 1.2161 mrad.
        self.assertAlmostEqual(vacuum_zero_angle_mrad(800, 100, 45), 1.2161, places=3)

    def test_vacuum_pcp_25m_60mm(self):
        # Catalog PCP profile of the tests (270 m/s, 25 m, 60 mm, no BC).
        a = vacuum_zero_angle_mrad(270, 25, 60)
        self.assertAlmostEqual(a, 4.0815, places=3)  # (s + gx²/2v²)/x ≈ 4.0816
        self.assertEqual(zero_clicks(a, 0.1, 1.0), 41)

    def test_vacuum_zero_day_velocity(self):
        # Zero angle follows the zero-day velocity, not today's.
        self.assertAlmostEqual(vacuum_zero_angle_mrad(780, 100, 45), 1.2559, places=3)

    def test_drag_308_g1(self):
        a = drag_zero_angle_mrad(800, 0.462, 100, 45)
        self.assertAlmostEqual(a, 1.2601, delta=0.003)
        self.assertEqual(zero_clicks(a, 0.1, 1.0), 13)
        self.assertEqual(zero_clicks(a, 0.25, MOA_MRAD), 17)

    def test_drag_pellet_g1(self):
        # Report table row: PCP pellet 280 m/s, 50 mm, zero 30 m → 3.77 mrad.
        a = drag_zero_angle_mrad(280, 0.031, 30, 50)
        self.assertAlmostEqual(a, 3.77, delta=0.02)

    def test_sign_positive(self):
        # The bore points above the sight line at a normal zero.
        for v, z, s in ((800, 100, 45), (270, 25, 60), (280, 10, 30)):
            self.assertGreater(vacuum_zero_angle_mrad(v, z, s), 0)


class TurretTravel(unittest.TestCase):
    def test_report_table_mrad(self):
        half = half_clicks(26, 0.1, 1.0)
        self.assertEqual(half, 130)
        self.assertEqual(app_travel(half, 0, 13), (117, 143))
        self.assertEqual(app_travel(half, mount_clicks(20, 0.1, 1.0), 13), (175, 85))
        self.assertEqual(app_travel(half, mount_clicks(30, 0.1, 1.0), 13), (204, 56))

    def test_report_table_moa(self):
        half = half_clicks(26, 0.25, MOA_MRAD)
        self.assertEqual(half, 178)
        self.assertEqual(app_travel(half, 0, 17), (161, 195))
        self.assertEqual(app_travel(half, mount_clicks(20, 0.25, MOA_MRAD), 17), (241, 115))
        self.assertEqual(app_travel(half, mount_clicks(30, 0.25, MOA_MRAD), 17), (281, 75))

    def test_kul1_small_travel_scope_overflows(self):
        # KUL-1: Steiner Ranger 4 4-16x56 (7.2 mrad, 0.1 mrad clicks,
        # lib/data/scope_library.dart) on the 25 m / 60 mm PCP: the zero
        # angle (41 clicks) is more than half the travel (36 clicks).
        half = half_clicks(7.2, 0.1, 1.0)
        zero = zero_clicks(vacuum_zero_angle_mrad(270, 25, 60), 0.1, 1.0)
        self.assertEqual((half, zero), (36, 41))
        up, down = app_travel(half, 0, zero)
        self.assertEqual((up, down), (0, 77))
        # The app's down travel is longer than the whole turret.
        self.assertGreater(up + down, 2 * half)


class CleanupEquivalence(unittest.TestCase):
    """#291: the merged formatters have one body each (source guard)."""

    def test_two_decimals_body(self):
        src = library_text(ROOT / "lib/features/ballistics/ballistics_screen.dart")
        m = re.search(r"String _twoDecimals\(double v\) => (.*?);\n", src, re.S)
        self.assertIsNotNone(m)
        body = re.sub(r"\s+", "", m.group(1))
        self.assertEqual(
            body,
            "v==v.roundToDouble()?v.toStringAsFixed(0):double.parse(v.toStringAsFixed(2)).toString()",
        )

    def test_scope_trim_body(self):
        src = library_text(ROOT / "lib/features/ballistics/scope_dial_view.dart")
        m = re.search(r"static String _trim\(double v\) => (.*?);\n", src, re.S)
        self.assertIsNotNone(m)
        body = re.sub(r"\s+", "", m.group(1))
        self.assertEqual(
            body,
            "v==v.roundToDouble()?v.toStringAsFixed(0):v.toStringAsFixed(1).replaceAll('.',',')",
        )

    def test_removed_parameters_have_no_callers(self):
        pattern = re.compile(r"\b(closeLabel|labelTrailing|onUnitTap|showBrand|_windMaxAuto|_autoWindMax)\b")
        hits = []
        for folder in ("lib", "test", "integration_test"):
            base = ROOT / folder
            if not base.exists():
                continue
            for p in base.rglob("*.dart"):
                if "audit_2026_10_14b" in p.parts:
                    continue
                if pattern.search(p.read_text(encoding="utf-8")):
                    hits.append(str(p.relative_to(ROOT)))
        self.assertEqual(hits, [])


class GaText(unittest.TestCase):
    def test_no_ga_drag_model_left_in_user_text(self):
        src = (ROOT / "lib/features/tools/calculators_screen.dart").read_text(encoding="utf-8")
        self.assertNotIn("GA,", src)
        self.assertIn("G1'e göre", src.replace("\\'", "'"))


class RifleListedeYokFlag(unittest.TestCase):
    def test_flag_default_off_item_kept(self):
        src = (ROOT / "lib/features/profiles/profiles_screen.dart").read_text(encoding="utf-8")
        self.assertIn("bool.fromEnvironment(\n    'RIFLE_LISTEDE_YOK',\n  )", src)
        self.assertIn("if (_showRifleListedeYok)", src)
        self.assertIn("Key('rifle-not-listed')", src)


if __name__ == "__main__":
    unittest.main()
