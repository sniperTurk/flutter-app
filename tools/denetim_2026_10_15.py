#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15: hand calculation for PRF-6 (#315).

Independent of the app: uses tools/formula_reference.py (published G7 table,
CIPM-2007 air, world-frame Dormand-Prince integration), never another
ballistic app.

Scenario (the audit's widget test test/audit_2026_10_15/prf6_e2e_test.dart):
.308, 175 gr, 790 m/s, zero 100 m, sight 45 mm, G7 BC 0.243 stored, truing
page default air 15 °C / 1013.25 hPa / 50 %. The shooter observes at 800 m
the correction a G7 BC of 0.225 would need. Truing must give back about
0.225, the stored record must carry it, and Hedef must show about that
observed correction at 800 m.

  python3 tools/denetim_2026_10_15.py   # prints the numbers the test uses
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as fr  # noqa: E402

ENV = fr.Env(15.0, 1013.25, 50.0)
BASE = dict(model="g7", grain=175.0, caliber_in=0.308, mv_mps=790.0,
            zero_m=100.0, sight_mm=45.0, env=ENV)
RANGE_M = 800.0
TRUE_BC = 0.225
BASE_BC = 0.243


def correction(bc: float, r: float = RANGE_M) -> float:
    sc = fr.Scenario("prf6", bc=bc, ranges=(r,), **BASE)
    return fr.solve(sc)[0].correction_mrad


def bc_for(observed_mrad: float, lo: float = 0.1, hi: float = 0.6) -> float:
    """Bisection: the G7 BC whose 800 m correction equals the observation."""
    for _ in range(60):
        mid = (lo + hi) / 2
        # A lower BC drops more: larger correction.
        if correction(mid) > observed_mrad:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def main() -> int:
    base = correction(BASE_BC)
    observed = round(correction(TRUE_BC), 2)
    back = bc_for(observed)
    print(f"base G7 {BASE_BC}: {base:.4f} mrad at {RANGE_M:.0f} m")
    print(f"observed (G7 {TRUE_BC}, 2 decimals): {observed:.2f} mrad")
    print(f"BC that reproduces the observation: {back:.5f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
