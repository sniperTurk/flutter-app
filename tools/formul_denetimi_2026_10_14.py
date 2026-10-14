#!/usr/bin/env python3
"""Independent reference for the 2026-10-14 formula audit
(docs/reports/formul_denetimi_2026_10_14.md).

Written from published equations, NOT from the app's Dart code, and never
from another ballistic program:

* Point-mass motion in a WORLD frame (east, north, up), McCoy, *Modern
  Exterior Ballistics* (1999), ch. 5: drag along the air-relative velocity,
  gravity straight down, Coriolis a = -2 Omega x v (McCoy ch. 5 / ch. 9,
  Omega = omega (0, cos lat, sin lat) in ENU). The app works in the scope
  frame instead; agreement of the two frames checks its rotations
  (incline, cant, wind, Coriolis).
* Drag: a = rho/2 * v^2 * Cd_G(M) * (pi/4) / BC_SI with BC_SI = BC(lb/in^2)
  * 703.0696 kg/m^2 (McCoy ch. 4, form factor i = SD / BC). Cd_G(M) is the
  BRL table stored in lib/core/standard_drag_tables.dart, linear between
  points (that is how the table is defined; the values themselves were
  spot-checked against the BRL landmarks G1(M1.0)=0.4805, G1 max 0.6625 at
  M1.40, G7(M1.0)=0.3803, G7 max 0.4043 at M1.05).
* Atmosphere: ICAO Doc 7488/3 standard atmosphere (station pressure from
  altitude, a0 = 340.294 m/s); moist-air density from the CIPM-2007
  equation (Picard et al., Metrologia 45 (2008) 149) with enhancement
  factor and compressibility, x_CO2 = 0.0004.
* Stability: Miller, "A New Rule for Estimating Rifling Twist", Precision
  Shooting, March 2005; subsonic floor from Courtney & Miller 2012
  (arXiv:1410.5340). Spin drift and aerodynamic jump: Litz, *Applied
  Ballistics for Long-Range Shooting*, 2nd ed. (SD = 1.25 (Sg+1.2) TOF^1.83
  in; Y = 0.01 Sg - 0.0024 L + 0.032 MOA per mph).
* Integration: classical RK4 in time, dt = 0.05 ms (10x finer than the app),
  cubic Hermite interpolation at the range plane. Zero: secant on the launch
  angle (the app bisects).

Standard library only. Run:

    python3 tools/formul_denetimi_2026_10_14.py           # summary table
    python3 tools/formul_denetimi_2026_10_14.py --dart    # Dart vectors
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "lib/core/standard_drag_tables.dart"

# NIST SP 811 (2008) Appendix B.
GRAIN_KG = 64.79891e-6
INCH_M = 0.0254
FOOT_M = 0.3048
MPH_MPS = 0.44704
LB_PER_IN2_TO_KG_PER_M2 = 0.45359237 / INCH_M**2
G0 = 9.80665
OMEGA_EARTH = 7.2921159e-5  # IERS, rad/s

# ICAO Doc 7488/3.
ICAO_T0 = 288.15
ICAO_P0 = 1013.25
ICAO_LAPSE = 0.0065
ICAO_R = 287.05287
ICAO_A0 = 340.294
R_DRY = 287.05


# --------------------------------------------------------------------------
# Atmosphere
# --------------------------------------------------------------------------

def isa_station_pressure_hpa(altitude_m: float) -> float:
    """ICAO standard-atmosphere pressure at [altitude_m] (troposphere)."""
    t = ICAO_T0 - ICAO_LAPSE * altitude_m
    return ICAO_P0 * (t / ICAO_T0) ** (G0 / (ICAO_R * ICAO_LAPSE))


def cipm2007_density(t_c: float, p_hpa: float, rh_pct: float, x_co2: float = 0.0004) -> float:
    """CIPM-2007 moist-air density, kg/m^3 (Picard et al. 2008)."""
    t = t_c + 273.15
    p = p_hpa * 100.0
    # Saturation vapour pressure (Davis 1992 / CIPM-81/91).
    a, b, c, d = 1.2378847e-5, -1.9121316e-2, 33.93711047, -6.3431645e3
    psv = math.exp(a * t * t + b * t + c + d / t)
    # Enhancement factor.
    alpha, beta, gamma = 1.00062, 3.14e-8, 5.6e-7
    f = alpha + beta * p + gamma * t_c * t_c
    xv = rh_pct / 100.0 * f * psv / p
    # Compressibility.
    a0, a1, a2 = 1.58123e-6, -2.9331e-8, 1.1043e-10
    b0, b1 = 5.707e-6, -2.051e-8
    c0, c1 = 1.9898e-4, -2.376e-6
    d_, e_ = 1.83e-11, -0.765e-8
    z = (1 - p / t * (a0 + a1 * t_c + a2 * t_c**2 + (b0 + b1 * t_c) * xv
                      + (c0 + c1 * t_c) * xv**2)
         + (p / t) ** 2 * (d_ + e_ * xv**2))
    ma = (28.96546 + 12.011 * (x_co2 - 0.0004)) * 1e-3
    mv = 18.01528e-3
    r = 8.314472
    return p * ma / (z * r * t) * (1 - xv * (1 - mv / ma))


def ideal_dry_density(t_c: float, p_hpa: float) -> float:
    return p_hpa * 100.0 / (R_DRY * (t_c + 273.15))


def dry_sound(t_c: float) -> float:
    """Speed of sound in dry air, ICAO constants (340.294 m/s at 15 C)."""
    return math.sqrt(1.4 * ICAO_R * (t_c + 273.15))


@dataclass(frozen=True)
class Air:
    rho: float
    sound: float

    @staticmethod
    def dry(t_c: float = 15.0, p_hpa: float = ICAO_P0) -> "Air":
        # Dry ideal gas with the app's R = 287.05 so the solver comparison
        # isolates the dynamics (CIPM vs ideal gas is checked separately).
        return Air(ideal_dry_density(t_c, p_hpa), math.sqrt(1.4 * R_DRY * (t_c + 273.15)))


ICAO_AIR = Air.dry()


# --------------------------------------------------------------------------
# Drag
# --------------------------------------------------------------------------

def load_table(name: str) -> list[tuple[float, float]]:
    text = TABLES.read_text(encoding="utf-8")
    block = re.search(rf"static final {name} = DragTable\(const \[(.*?)\]\);", text, re.S)
    if block is None:
        raise ValueError(f"table {name} not found")
    return [(float(a), float(b)) for a, b in
            re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", block.group(1))]


_TABLE_CACHE: dict[str, list[tuple[float, float]]] = {}


def table(name: str) -> list[tuple[float, float]]:
    if name not in _TABLE_CACHE:
        _TABLE_CACHE[name] = load_table(name)
    return _TABLE_CACHE[name]


def cd_at(tab: list[tuple[float, float]], mach: float) -> float:
    if mach <= tab[0][0]:
        return tab[0][1]
    if mach >= tab[-1][0]:
        return tab[-1][1]
    lo, hi = 0, len(tab) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if tab[mid][0] <= mach:
            lo = mid
        else:
            hi = mid
    (m0, c0), (m1, c1) = tab[lo], tab[hi]
    return c0 + (c1 - c0) * (mach - m0) / (m1 - m0)


def drag_decel(speed: float, bc: float, tab, air: Air) -> float:
    bc_si = bc * LB_PER_IN2_TO_KG_PER_M2
    return 0.5 * air.rho * cd_at(tab, speed / air.sound) * (math.pi / 4) * speed * speed / bc_si


# --------------------------------------------------------------------------
# World-frame point-mass solver
# --------------------------------------------------------------------------

def _add(a, b):
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])


def _scale(a, k):
    return (a[0] * k, a[1] * k, a[2] * k)


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


@dataclass
class Shot:
    v0: float                      # m/s today
    bc: float
    model: str                     # 'g1' / 'g7'
    sight_m: float
    zero_m: float
    zero_v: float | None = None    # zero-day velocity (None = v0)
    air: Air = ICAO_AIR
    zero_air: Air = ICAO_AIR
    incline_deg: float = 0.0
    cant_deg: float = 0.0
    lat_deg: float | None = None
    az_deg: float | None = None
    wind_mps: float = 0.0
    wind_deg: float = 90.0         # app convention: 0 head, 90 from LEFT, 270 from right
    g: float = G0
    dt: float = 5e-5


@dataclass
class Point:
    range_m: float
    correction_mrad: float  # + = dial up (impact below LOS)
    wind_mrad: float        # + = dial right (impact left of LOS)
    tof_s: float
    speed: float


def _frame(shot: Shot, level: bool = False):
    az = math.radians(shot.az_deg or 0.0)
    h = (math.sin(az), math.cos(az), 0.0)     # horizontal forward
    r = (math.cos(az), -math.sin(az), 0.0)    # horizontal right
    u = (0.0, 0.0, 1.0)
    th = 0.0 if level else math.radians(shot.incline_deg)
    ph = 0.0 if level else math.radians(shot.cant_deg)
    los = _add(_scale(h, math.cos(th)), _scale(u, math.sin(th)))
    up0 = _add(_scale(h, -math.sin(th)), _scale(u, math.cos(th)))
    # Cant: positive = clockwise as the shooter sees it (top to the right).
    up = _add(_scale(up0, math.cos(ph)), _scale(r, math.sin(ph)))
    right = _add(_scale(r, math.cos(ph)), _scale(up0, -math.sin(ph)))
    return h, r, los, up, right


def _trajectory(shot: Shot, angle: float, ranges: list[float], *, zero: bool) -> list[Point]:
    h, r, los, up, right = _frame(shot, level=zero)
    v = shot.zero_v if (zero and shot.zero_v) else shot.v0
    air = shot.zero_air if zero else shot.air
    tab = table(shot.model)
    if zero or shot.lat_deg is None:
        omega = (0.0, 0.0, 0.0)
    else:
        lat = math.radians(shot.lat_deg)
        omega = (0.0, OMEGA_EARTH * math.cos(lat), OMEGA_EARTH * math.sin(lat))
    w = 0.0 if zero else shot.wind_mps
    d = math.radians(shot.wind_deg)
    wind = _add(_scale(h, -w * math.cos(d)), _scale(r, w * math.sin(d)))
    gvec = (0.0, 0.0, -shot.g)

    def acc(vel):
        rel = (vel[0] - wind[0], vel[1] - wind[1], vel[2] - wind[2])
        sp = math.sqrt(_dot(rel, rel))
        a = _scale(rel, -drag_decel(sp, shot.bc, tab, air) / sp) if sp > 0 else (0.0, 0.0, 0.0)
        a = _add(a, gvec)
        return _add(a, _scale(_cross(omega, vel), -2.0))

    pos = _scale(up, -shot.sight_m)
    vel = _add(_scale(los, v * math.cos(angle)), _scale(up, v * math.sin(angle)))
    t = 0.0
    out: list[Point] = []
    targets = sorted(ranges)
    i = 0
    dt = shot.dt
    while i < len(targets):
        k1v, k1x = acc(vel), vel
        k2v = acc(_add(vel, _scale(k1v, dt / 2)))
        k2x = _add(vel, _scale(k1v, dt / 2))
        k3v = acc(_add(vel, _scale(k2v, dt / 2)))
        k3x = _add(vel, _scale(k2v, dt / 2))
        k4v = acc(_add(vel, _scale(k3v, dt)))
        k4x = _add(vel, _scale(k3v, dt))
        npos = _add(pos, _scale(_add(_add(k1x, _scale(k2x, 2)), _add(_scale(k3x, 2), k4x)), dt / 6))
        nvel = _add(vel, _scale(_add(_add(k1v, _scale(k2v, 2)), _add(_scale(k3v, 2), k4v)), dt / 6))
        while i < len(targets) and _dot(npos, los) >= targets[i]:
            rng = targets[i]
            # Cubic Hermite on the along-LOS coordinate, solved by Newton.
            a0, a1 = _dot(pos, los), _dot(npos, los)
            s0, s1 = _dot(vel, los) * dt, _dot(nvel, los) * dt
            tau = (rng - a0) / (a1 - a0)
            for _ in range(20):
                h00 = 2 * tau**3 - 3 * tau**2 + 1
                h10 = tau**3 - 2 * tau**2 + tau
                h01 = -2 * tau**3 + 3 * tau**2
                h11 = tau**3 - tau**2
                val = h00 * a0 + h10 * s0 + h01 * a1 + h11 * s1 - rng
                der = ((6 * tau**2 - 6 * tau) * a0 + (3 * tau**2 - 4 * tau + 1) * s0
                       + (-6 * tau**2 + 6 * tau) * a1 + (3 * tau**2 - 2 * tau) * s1)
                tau -= val / der
            h00 = 2 * tau**3 - 3 * tau**2 + 1
            h10 = tau**3 - 2 * tau**2 + tau
            h01 = -2 * tau**3 + 3 * tau**2
            h11 = tau**3 - tau**2

            def herm(p0, p1, v0_, v1_):
                return h00 * p0 + h10 * v0_ * dt + h01 * p1 + h11 * v1_ * dt

            y = herm(_dot(pos, up), _dot(npos, up), _dot(vel, up), _dot(nvel, up))
            z = herm(_dot(pos, right), _dot(npos, right), _dot(vel, right), _dot(nvel, right))
            sp = [vel[j] + (nvel[j] - vel[j]) * tau for j in range(3)]
            out.append(Point(rng, math.atan2(-y, rng) * 1000, math.atan2(-z, rng) * 1000,
                             t + tau * dt, math.sqrt(sum(c * c for c in sp))))
            i += 1
        pos, vel, t = npos, nvel, t + dt
        if t > 60 or _dot(vel, los) <= 0:
            raise RuntimeError("projectile did not reach the range")
    order = {p.range_m: p for p in out}
    return [order[x] for x in ranges]


def zero_angle(shot: Shot) -> float:
    """Launch angle above the sight line (rad), level, calm, zero air."""
    def height(a):
        p = _trajectory(shot, a, [shot.zero_m], zero=True)[0]
        return -p.correction_mrad  # sign only matters
    a0, a1 = 0.0, 0.01
    f0, f1 = height(a0), height(a1)
    for _ in range(40):
        a2 = a1 - f1 * (a1 - a0) / (f1 - f0)
        a0, f0, a1, f1 = a1, f1, a2, height(a2)
        if abs(f1) < 1e-9:
            break
    return a1


def solve(shot: Shot, ranges: list[float]) -> list[Point]:
    return _trajectory(shot, zero_angle(shot), ranges, zero=False)


# --------------------------------------------------------------------------
# Stability, spin drift, jump, estimated BC
# --------------------------------------------------------------------------

def miller_sg(grain, cal_mm, twist_in, length_mm, v_mps, t_c, p_hpa) -> float:
    d = cal_mm / 25.4
    t = twist_in / d
    l = length_mm / 25.4 / d
    v = max(v_mps, math.sqrt(1.4 * R_DRY * (t_c + 273.15)))  # Courtney & Miller 2012
    fv = (v / FOOT_M / 2800.0) ** (1.0 / 3.0)
    ft = (t_c * 9 / 5 + 32 + 460) / 519.0
    fp = 29.92 / (p_hpa / 33.8638866667)
    return 30.0 * grain / (t * t * d**3 * l * (1 + l * l)) * fv * ft * fp


def litz_spin_drift_m(sg: float, tof: float) -> float:
    return 1.25 * (sg + 1.2) * tof**1.83 * INCH_M


def litz_jump_moa_per_mph(sg: float, l_cal: float) -> float:
    return 0.01 * sg - 0.0024 * l_cal + 0.032


def estimated_g1(grain: float, cal_mm: float, form: float) -> float:
    d = cal_mm / 25.4
    return round(grain / (7000 * d * d) / form, 3)


# --------------------------------------------------------------------------
# Scenarios
# --------------------------------------------------------------------------

def mrad_to_cm(mrad: float, range_m: float) -> float:
    return math.tan(mrad / 1000) * range_m * 100


R308 = dict(v0=2650 * FOOT_M, bc=0.462, model="g1", sight_m=0.0381, zero_m=100.0)
PELLET = dict(v0=280.0, bc=0.031, model="g1", sight_m=0.050, zero_m=30.0)
SLUG = dict(v0=290.0, bc=0.110, model="g1", sight_m=0.050, zero_m=50.0)
G7_65 = dict(v0=2700 * FOOT_M, bc=0.315, model="g7", sight_m=0.040, zero_m=100.0)


def vectors() -> dict[str, list[Point]]:
    return {
        "308_level": solve(Shot(**R308), [100, 300, 500, 800]),
        "308_wind3": solve(Shot(**R308, wind_mps=10 * MPH_MPS, wind_deg=270), [300, 500]),
        "308_incline30": solve(Shot(**R308, incline_deg=30), [300, 500]),
        "308_cant5": solve(Shot(**R308, cant_deg=5), [300, 500]),
        "308_coriolis_e": solve(Shot(**R308, lat_deg=40, az_deg=90), [800]),
        "308_coriolis_n": solve(Shot(**R308, lat_deg=40, az_deg=0), [800]),
        "65_g7": solve(Shot(**G7_65), [300, 600]),
        "pellet_level": solve(Shot(**PELLET), [10, 30, 50, 100]),
        "pellet_wind9": solve(Shot(**PELLET, wind_mps=3.0, wind_deg=90), [50, 100]),
        "slug_level": solve(Shot(**SLUG), [100, 150]),
    }


def finding_altitude() -> dict:
    """F1: empty pressure + typed altitude -> app uses 1013.25 hPa."""
    rows = {}
    for name, base, alt, ranges in (("308", R308, 1500.0, [300, 500, 800]),
                                    ("pellet", PELLET, 1000.0, [50, 100])):
        p = isa_station_pressure_hpa(alt)
        app = solve(Shot(**base, air=Air.dry(15, ICAO_P0)), ranges)
        true = solve(Shot(**base, air=Air.dry(15, p)), ranges)
        rows[name] = dict(altitude_m=alt, isa_hpa=p, rows=[
            (a.range_m, a.correction_mrad, b.correction_mrad,
             mrad_to_cm(a.correction_mrad - b.correction_mrad, a.range_m))
            for a, b in zip(app, true)])
    return rows


def finding_pcp_mixed_velocity() -> dict:
    """F2: unregulated PCP, table velocity at the Profil tube pressure
    differs from the profile velocity: zero at one, shot at the other."""
    base = dict(PELLET)
    base.pop("v0")
    ranges = [30, 50, 100]
    mixed = solve(Shot(**base, v0=255.0, zero_v=270.0), ranges)
    same = solve(Shot(**base, v0=255.0), ranges)
    return dict(rows=[(a.range_m, a.correction_mrad, b.correction_mrad,
                       mrad_to_cm(a.correction_mrad - b.correction_mrad, a.range_m))
                      for a, b in zip(mixed, same)])


def finding_turret_zero_angle() -> dict:
    """F3: the zero's own launch angle (bore above the sight line) that a
    0 MOA mount uses from the UP travel."""
    out = {}
    for name, base in (("308", R308), ("pellet", PELLET), ("slug", SLUG)):
        a = zero_angle(Shot(**base)) * 1000
        out[name] = dict(zero_angle_mrad=a, clicks_01mrad=a / 0.1,
                         clicks_quarter_moa=a / (math.pi / 10.8) / 0.25)
    return out


def main(argv: list[str]) -> int:
    vec = vectors()
    if "--dart" in argv:
        for k, pts in vec.items():
            print(f"  // {k}")
            for p in pts:
                print(f"  ({p.range_m:.0f}, {p.correction_mrad:.4f}, {p.wind_mrad:.4f}, {p.tof_s:.5f}),")
        return 0
    for k, pts in vec.items():
        print(k)
        for p in pts:
            print(f"   {p.range_m:6.0f} m  up {p.correction_mrad:9.4f} mrad  wind {p.wind_mrad:8.4f}"
                  f"  tof {p.tof_s:.5f}  v {p.speed:.1f}")
    print("F1 altitude ignored when pressure is empty:", finding_altitude())
    print("F2 PCP mixed velocity:", finding_pcp_mixed_velocity())
    print("F3 zero launch angle:", finding_turret_zero_angle())
    print("CIPM-2007 15C 1013.25 50%:", cipm2007_density(15, 1013.25, 50))
    print("ISA 1000 m:", isa_station_pressure_hpa(1000), " 1500 m:", isa_station_pressure_hpa(1500))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
