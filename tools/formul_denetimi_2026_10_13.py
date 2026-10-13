#!/usr/bin/env python3
"""Independent point-mass reference for the 2026-10-13 formula audit
(docs/research/formul_denetimi.md).

Written from the textbook equations, not from the app's Dart code:

* Point-mass equations of motion: McCoy, R. L., *Modern Exterior
  Ballistics*, Schiffer 1999, ch. 5 (drag along the air-relative velocity,
  gravity, flat non-rotating Earth for these level shots).
* Drag: a = (rho / 2) * v^2 * Cd_G(M) * i * A / m with the form factor
  i = SD / BC (McCoy ch. 4, eq. 4.6 ff.), SD = m / d^2 in lb/in^2. The
  standard G1/G7 Cd(M) values are read from the repository's
  lib/core/standard_drag_tables.dart (BRL tables; linear between points,
  which is how that table is defined in the app).
* Atmosphere: ICAO standard atmosphere at sea level (ICAO Doc 7488/3):
  15 degC, 1013.25 hPa, dry air, R = 287.05 J/(kg K), gamma = 1.4.
* Integration: classical RK4 with the RANGE x as the independent variable
  (dt/dx = 1/vx), step 0.02 m, so every requested range is hit exactly
  (the app integrates in time with a 0.5 ms step and interpolates).
* Zero: secant iteration on the launch angle (the app bisects).

Standard library only. Run:

    python3 tools/formul_denetimi_2026_10_13.py          # table
    python3 tools/formul_denetimi_2026_10_13.py --dart   # Dart vectors
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "lib/core/standard_drag_tables.dart"

# NIST SP 811 (2008) Appendix B.
GRAIN_KG = 64.79891e-6
INCH_M = 0.0254
FOOT_M = 0.3048
POUND_KG = 0.45359237
MPH_MPS = 0.44704
G0 = 9.80665

# ICAO Doc 7488/3 sea level, dry air.
T_K = 288.15
P_PA = 101325.0
R_DRY = 287.05
GAMMA = 1.4
RHO = P_PA / (R_DRY * T_K)
SOUND = math.sqrt(GAMMA * R_DRY * T_K)


def load_table(name: str) -> list[tuple[float, float]]:
    text = TABLES.read_text(encoding="utf-8")
    block = re.search(rf"static final {name} = DragTable\(const \[(.*?)\]\);", text, re.S)
    if block is None:
        raise ValueError(f"table {name} not found")
    return [(float(a), float(b)) for a, b in re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", block.group(1))]


class Cd:
    def __init__(self, pts: list[tuple[float, float]]):
        self.m = [p[0] for p in pts]
        self.c = [p[1] for p in pts]

    def __call__(self, mach: float) -> float:
        m, c = self.m, self.c
        if mach <= m[0]:
            return c[0]
        if mach >= m[-1]:
            return c[-1]
        lo, hi = 0, len(m) - 1
        while hi - lo > 1:
            mid = (lo + hi) // 2
            if m[mid] <= mach:
                lo = mid
            else:
                hi = mid
        f = (mach - m[lo]) / (m[hi] - m[lo])
        return c[lo] + (c[hi] - c[lo]) * f


@dataclass(frozen=True)
class Load:
    id: str
    model: str
    bc: float
    grain: float
    diameter_in: float
    mv_fps: float
    zero_m: float
    sight_mm: float
    ranges: tuple[float, ...]


LOADS = (
    Load("r308_168_g1", "g1", 0.462, 168, 0.308, 2650, 100, 38.1, (100, 300, 500)),
    Load("cm65_140_g7", "g7", 0.315, 140, 0.264, 2710, 100, 38.1, (100, 300, 500)),
    Load("pcp635_50_slug_g1", "g1", 0.139, 50, 0.250, 985, 50, 50, (50, 100, 200, 300)),
    Load("pcp22_18_pellet_g1", "g1", 0.030, 18, 0.2165, 900, 30, 50, (50, 100, 200, 300)),
)

WIND_MPH = 10.0  # full value, from the left (9 o'clock): drift to the right


@dataclass
class Out:
    range_m: float
    drop_cm: float       # below the line of sight, + = low
    corr_mrad: float     # elevation to dial, + = up
    drift_cm: float      # + = to the right (10 mph from the left)
    drift_mrad: float    # windage to dial, + = right (app's windMrad sign)
    v_mps: float
    tof_s: float


def _k(load: Load) -> float:
    m = load.grain * GRAIN_KG
    d = load.diameter_in * INCH_M
    sd = m / (d * d)                                   # kg/m^2
    bc = load.bc * POUND_KG / (INCH_M * INCH_M)        # kg/m^2
    i = sd / bc
    return RHO * (math.pi * d * d / 4) * i / (2 * m)   # times Cd * v^2


def _deriv(s, k, cd, wind_z):
    # s = (t, y, z, vx, vy, vz); derivative with respect to x.
    t, y, z, vx, vy, vz = s
    rx, ry, rz = vx, vy, vz - wind_z
    v = math.sqrt(rx * rx + ry * ry + rz * rz)
    a = -k * cd(v / SOUND) * v
    inv = 1.0 / vx
    return (inv, vy * inv, vz * inv, a * rx * inv, (a * ry - G0) * inv, a * rz * inv)


def _fly(load: Load, angle: float, targets, cd: Cd, wind_z=0.0, h=0.02):
    v0 = load.mv_fps * FOOT_M
    s = (0.0, -load.sight_mm / 1000, 0.0, v0 * math.cos(angle), v0 * math.sin(angle), 0.0)
    k = _k(load)
    x = 0.0
    out = []
    for target in sorted(targets):
        while x < target - 1e-12:
            step = min(h, target - x)
            k1 = _deriv(s, k, cd, wind_z)
            k2 = _deriv(tuple(a + step / 2 * b for a, b in zip(s, k1)), k, cd, wind_z)
            k3 = _deriv(tuple(a + step / 2 * b for a, b in zip(s, k2)), k, cd, wind_z)
            k4 = _deriv(tuple(a + step * b for a, b in zip(s, k3)), k, cd, wind_z)
            s = tuple(a + step / 6 * (b + 2 * c + 2 * d + e)
                      for a, b, c, d, e in zip(s, k1, k2, k3, k4))
            x += step
            if s[3] <= 0:
                raise RuntimeError("projectile stopped")
        out.append((target, s))
    return out


def zero_angle(load: Load, cd: Cd) -> float:
    def y_at(a):
        return _fly(load, a, [load.zero_m], cd)[0][1][1]

    a0, a1 = 0.0, 0.01
    y0, y1 = y_at(a0), y_at(a1)
    for _ in range(50):
        a2 = a1 - y1 * (a1 - a0) / (y1 - y0)
        a0, y0, a1, y1 = a1, y1, a2, y_at(a2)
        if abs(y1) < 1e-12:
            break
    return a1


def solve(load: Load) -> list[Out]:
    cd = Cd(load_table(load.model))
    angle = zero_angle(load, cd)
    calm = _fly(load, angle, load.ranges, cd)
    windy = _fly(load, angle, load.ranges, cd, wind_z=WIND_MPH * MPH_MPS)
    res = []
    for (r, s), (_, w) in zip(calm, windy):
        t, y, _, vx, vy, vz = s
        z = w[2]
        res.append(Out(r, -y * 100, math.atan2(-y, r) * 1000, z * 100,
                       math.atan2(-z, r) * 1000, math.sqrt(vx * vx + vy * vy + vz * vz), t))
    return res


# ------------------------------------------------- Miller (Courtney & Miller)
def miller_sg(grain, diameter_in, length_in, twist_in, v_fps, t_c=15.0, p_hpa=1013.25,
              subsonic_clamp=True):
    """Miller, "A New Rule for Estimating Rifling Twist", Precision Shooting,
    March 2005: Sg = 30 m / (t^2 d^3 l (1 + l^2)) * (v/2800)^(1/3) *
    (T+460)/519 * 29.92/P. Courtney & Miller, "A Stability Formula for
    Plastic-Tipped Bullets: Part 1", Precision Shooting, Jan 2012
    (arXiv:1410.5340): below the speed of sound the velocity factor keeps
    its value at the speed of sound."""
    t = twist_in / diameter_in
    l = length_in / diameter_in
    if subsonic_clamp:
        sound_fps = math.sqrt(GAMMA * R_DRY * (t_c + 273.15)) / FOOT_M
        v_fps = max(v_fps, sound_fps)
    t_f = t_c * 9 / 5 + 32
    p_inhg = p_hpa / 33.8638866667
    return (30 * grain / (t * t * diameter_in ** 3 * l * (1 + l * l))
            * (v_fps / 2800) ** (1 / 3) * (t_f + 460) / 519 * 29.92 / p_inhg)


def main(argv: list[str]) -> int:
    if "--dart" in argv:
        for load in LOADS:
            print(f"  // {load.id}")
            for o in solve(load):
                print(f"  ({o.range_m:.0f}, {o.corr_mrad:.5f}, {o.drift_mrad:.5f}, "
                      f"{o.v_mps:.4f}, {o.tof_s:.6f}),")
        return 0
    print(f"ICAO: rho={RHO:.5f} kg/m3, c={SOUND:.3f} m/s")
    for load in LOADS:
        print(f"\n{load.id}: {load.model.upper()} {load.bc} {load.grain} gr {load.mv_fps} fps, "
              f"zero {load.zero_m} m, sight {load.sight_mm} mm")
        print(" range  drop_cm  corr_mrad  drift_cm  drift_mrad  v_mps  v_fps  tof_s")
        for o in solve(load):
            print(f" {o.range_m:5.0f} {o.drop_cm:8.2f} {o.corr_mrad:10.4f} {o.drift_cm:9.2f} "
                  f"{o.drift_mrad:10.4f} {o.v_mps:7.2f} {o.v_mps / FOOT_M:6.0f} {o.tof_s:7.4f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
