#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15b: hand calculation for the Hedef split
(PR #317, commit cb9ffee).

Independent of the app: uses tools/formula_reference.py (published G7
table, CIPM-2007 air, world-frame Dormand-Prince integration). No other
ballistic app is used.

Scenario (test/audit_2026_10_15b/hedef_split_audit_test.dart):
.308, 175 gr, G7 BC 0.243, 790 m/s, zero 100 m, sight 45 mm, Gazi Sniper
6-36x56 (0.1 mrad clicks), saved Hava Durumu 15 °C / 1013.25 hPa / 50 %,
wind 4 m/s from 9 o'clock (app 90° = from the left). Spin drift and
aerodynamic jump stay off (no Mermi uzunluğu), no zero offset, no Coriolis.

  python3 tools/denetim_2026_10_15b_hedef.py   # prints the numbers the test uses
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as fr  # noqa: E402

ENV = fr.Env(15.0, 1013.25, 50.0, wind_mps=4.0, wind_deg=90.0)
BASE = dict(model="g7", bc=0.243, grain=175.0, caliber_in=0.308, mv_mps=790.0,
            zero_m=100.0, sight_mm=45.0, env=ENV)
RANGES_M = (100.0, 350.0, 620.0)
CLICK_MRAD = 0.1
# Same tolerance as test/formula_reference_vectors_test.dart (modelling
# spread between two independent solvers, well below one 0.1 mrad click).
TOLERANCE_MRAD = 0.03
MOA_PER_MRAD = 10800.0 / math.pi / 1000.0  # 1 MOA = π/(180·60) rad


def solve() -> dict[float, fr.Point]:
    sc = fr.Scenario("hdf", ranges=RANGES_M, **BASE)
    return {p.range_m: p for p in fr.solve(sc)}


def clicks(mrad: float) -> int:
    """Nearest click, as a turret is dialled (half away from zero)."""
    v = mrad / CLICK_MRAD
    return int(math.floor(abs(v) + 0.5)) * (1 if v >= 0 else -1)


def click_margin_mrad(mrad: float) -> float:
    """Distance of [mrad] from the nearest half-click rounding edge."""
    v = mrad / CLICK_MRAD
    return abs(abs(v - math.floor(v)) - 0.5) * CLICK_MRAD


def rows() -> list[tuple[str, float]]:
    pts = solve()
    out = []
    for r in RANGES_M:
        p = pts[r]
        tag = f"{r:.0f}"
        out += [
            (f"up_mrad_{tag}", p.correction_mrad),
            (f"up_moa_{tag}", p.correction_mrad * MOA_PER_MRAD),
            (f"right_mrad_{tag}", p.wind_mrad),
            (f"tof_s_{tag}", p.tof_s),
            (f"v_mps_{tag}", p.velocity_mps),
        ]
    return out


def main() -> int:
    pts = solve()
    for name, value in rows():
        print(f"{name} = {value:.4f}")
    for r in RANGES_M:
        p = pts[r]
        print(f"{r:.0f} m: {clicks(p.correction_mrad)} clicks U "
              f"(edge {click_margin_mrad(p.correction_mrad):.3f} mrad), "
              f"{clicks(p.wind_mrad)} clicks R "
              f"(edge {click_margin_mrad(p.wind_mrad):.3f} mrad)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
