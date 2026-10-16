#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15c: hand calculation for the Hedef result
row and the turrets (PRs #330, #332, #337, #349, #352, #357, #358).

Independent of the app: the trajectory comes from tools/formula_reference.py
(our own solver: published G7 table, CIPM-2007 air, world-frame
Dormand-Prince). Units only from their definitions: 1 MOA = pi/10800 rad,
1 mrad = 1/1000 rad, 1 yd = 0.9144 m. No other ballistic app is used.

What the Hedef result row ("Üst kule" / "Yan kule", PR #330) must show for a
required correction c (in the profile's turret unit) and a click value k:

  clicks = nearest whole click, half away from zero  (a turret is dialled
           to the nearest click; Dart's int round() does the same),
  detail = |c| with one decimal and a Turkish comma, then the unit label
           and "yukarı"/"aşağı" (elevation) or "sağ"/"sol" (windage),
  direction: + up / + right (dial UP / dial RIGHT).

Scenario (test/audit_2026_10_15c/hedef_audit_test.dart), same load as the
2026-10-15b audit: .308, 175 gr, G7 BC 0.243, 790 m/s, sight 45 mm, saved
Hava Durumu 15 °C / 1013.25 hPa / 50 %, wind 4 m/s from 9 o'clock (app
90° = from the LEFT, so the bullet drifts right and the turret goes LEFT).
Spin drift, aerodynamic jump, zero offset and Coriolis are off.

  * metric, zero 100 m, Gazi 6-36 (0.1 mrad), MRAD and MOA profiles: 620 m;
  * yard, zero 100 yd, Gazi 6-36 MRAD profile: 800 yd (731.52 m);
  * metric, zero 100 m, a 1/8 MOA scope with 13.09 mrad travel (both
    turrets), MOA profile: 450 m (inside the travel) and 620 m (beyond it).

  python3 tools/denetim_2026_10_15c_hedef.py   # prints every number used
"""
from __future__ import annotations

import math
import sys
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as fr  # noqa: E402

YARD_M = 0.9144
MOA_PER_MRAD = 10800.0 / math.pi / 1000.0  # 1 MOA = π/10800 rad
# Same tolerance as test/formula_reference_vectors_test.dart: modelling
# spread between two independent solvers.
TOLERANCE_MRAD = 0.03

ENV = fr.Env(15.0, 1013.25, 50.0, wind_mps=4.0, wind_deg=90.0)
LOAD = dict(model="g7", bc=0.243, grain=175.0, caliber_in=0.308,
            mv_mps=790.0, sight_mm=45.0, env=ENV)

METRIC_RANGES_M = (100.0, 450.0, 620.0)
YARD_RANGE_YD = 800.0
EIGHTH_MOA_TRAVEL_MRAD = 13.09


# ------------------------------------------------------------ the rules

def clicks(angle: float, click: float) -> int:
    """Nearest whole click, half away from zero."""
    v = angle / click
    return int(math.floor(abs(v) + 0.5)) * (1 if v >= 0 else -1)


def click_margin(angle: float, click: float) -> float:
    """Distance (in the angle's unit) of [angle] from a half-click edge."""
    v = abs(angle) / click
    return abs((v - math.floor(v)) - 0.5) * click


def fixed1(v: float) -> str:
    """|v| with one decimal and a comma; ties up, on the exact binary value
    (what Dart's toStringAsFixed(1) prints)."""
    d = Decimal(abs(v)).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP)
    return f"{d}".replace(".", ",")


def row(required_up: float, required_right: float, click: float,
        unit: str, wind_calm: bool) -> tuple[list[str], list[str]]:
    """Texts of the two result columns, from the rules above (the app's
    current rule for the direction word: none when the angle prints 0,0;
    "rüzgâr yok" for a zero side turret without wind)."""
    def detail(a: float, pos: str, neg: str) -> str:
        s = fixed1(a)
        return f"{s} {unit}" if s == "0,0" else f"{s} {unit} {pos if a > 0 else neg}"

    up = clicks(required_up, click)
    right = clicks(required_right, click)
    return (
        ["Üst kule", f"{abs(up)} klik", detail(required_up, "yukarı", "aşağı")],
        ["Yan kule", f"{abs(right)} klik",
         "rüzgâr yok" if right == 0 and wind_calm
         else detail(required_right, "sağ", "sol")],
    )


def direction_consistent(angle: float, click: float) -> bool:
    """HDF-3 rule: a column that shows a non-zero click count names the
    direction, and a column that shows 0 klik names none."""
    n = clicks(angle, click)
    has_word = fixed1(angle) != "0,0"
    return (n != 0) == has_word


# ------------------------------------------------------------ trajectories

def solve_metric() -> dict[float, fr.Point]:
    sc = fr.Scenario("c_metric", ranges=METRIC_RANGES_M, zero_m=100.0, **LOAD)
    return {p.range_m: p for p in fr.solve(sc)}


def solve_yard() -> fr.Point:
    sc = fr.Scenario("c_yard", ranges=(YARD_RANGE_YD * YARD_M,),
                     zero_m=100.0 * YARD_M, **LOAD)
    (p,) = fr.solve(sc)
    return p


def zero_angle_mrad() -> float:
    """Bore angle above the sight line at the 100 m zero (ICAO air, as the
    app zeroes)."""
    sc = fr.Scenario("c_zero", ranges=(100.0,), zero_m=100.0, **LOAD)
    cd = fr.Pchip(fr.load_table("g7"))
    return fr.zero_angle(sc, cd, "cipm") * 1000.0


def eighth_moa_travel() -> dict[str, float]:
    """1/8 MOA scope, 13.09 mrad total travel: half travel and the zero
    angle in clicks, UP travel left after zeroing (denetim F2 / KUL-1)."""
    click = 0.125
    half = math.floor(EIGHTH_MOA_TRAVEL_MRAD / 2 * MOA_PER_MRAD / click)
    zero = clicks(zero_angle_mrad() * MOA_PER_MRAD, click)
    return {
        "half": half,
        "zero": zero,
        "up": max(0, min(half - zero, 2 * half)),
        "down": max(0, min(half + zero, 2 * half)),
    }


def values() -> list[tuple[str, float]]:
    pts = solve_metric()
    out: list[tuple[str, float]] = []
    for r in METRIC_RANGES_M:
        p = pts[r]
        tag = f"{r:.0f}"
        out += [
            (f"up_mrad_{tag}", p.correction_mrad),
            (f"up_moa_{tag}", p.correction_mrad * MOA_PER_MRAD),
            (f"right_mrad_{tag}", p.wind_mrad),
            (f"right_moa_{tag}", p.wind_mrad * MOA_PER_MRAD),
        ]
    y = solve_yard()
    out += [("up_mrad_800yd", y.correction_mrad),
            ("right_mrad_800yd", y.wind_mrad),
            ("zero_angle_mrad", zero_angle_mrad())]
    return out


def main() -> int:
    for name, v in values():
        print(f"{name} = {v:.4f}")
    pts = solve_metric()
    p = pts[620.0]
    print("620 m MRAD row:", row(p.correction_mrad, p.wind_mrad, 0.1, "MRAD", False))
    moa = (p.correction_mrad * MOA_PER_MRAD, p.wind_mrad * MOA_PER_MRAD)
    print("620 m MOA row:", row(*moa, 0.25, "MOA", False))
    y = solve_yard()
    print("800 yd MRAD row:", row(y.correction_mrad, y.wind_mrad, 0.1, "MRAD", False))
    t = eighth_moa_travel()
    print("1/8 MOA travel:", t)
    for r in (450.0, 620.0):
        need = pts[r].correction_mrad * MOA_PER_MRAD / 0.125
        print(f"1/8 MOA {r:.0f} m: need {need:.2f} clicks "
              f"({'inside' if need <= t['up'] else 'BEYOND'} {t['up']} up)")
    for a, k, u in ((0.03, 0.05, "MRAD"), (0.1, 0.25, "MOA"), (0.055, 0.125, "MOA")):
        print(f"HDF-3 {a} {u} @ {k}:", row(a, 0.0, k, u, True)[0],
              "consistent" if direction_consistent(a, k) else "INCONSISTENT")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
