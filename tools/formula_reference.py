#!/usr/bin/env python3
"""Independent reference implementation of SNIPER TÜRK's ballistic formulas.

Formula audit 2026-10-11 (docs/formul-denetimi-2026-10-11.md). Standard
library only, so it runs in the offline Python suite and on CI without pip.

Everything here is written from the PUBLISHED definition of each formula,
not from the Dart source, and deliberately takes a different route wherever
one exists:

* air density: CIPM-2007 (Picard et al., Metrologia 45 (2008) 149) instead
  of the app's Magnus + ideal-gas mix;
* speed of sound: ideal humid air with the mixture's own heat-capacity
  ratio, instead of sqrt(1.4 * p / rho);
* gravity: Somigliana closed form in the a/b form plus the NIMA TR8350.2
  eq. (4-3) free-air series, instead of the k/e² form;
* drag: a = rho * A * i * Cd_G(M) * v² / (2 m) with the form factor
  i = (m/d²)/BC worked out from the bullet's mass and calibre (NIST pound and
  inch), instead of the app's lumped pi/(8*BC_SI);
* drag tables: monotone cubic (Fritsch–Carlson PCHIP) interpolation of the
  BRL samples, instead of the app's linear interpolation ("linear" can be
  selected to isolate the integrator);
* trajectory: integrated in the WORLD frame (forward/up/right, gravity
  vertical, Earth rotation from east-north-up dot products) with an adaptive
  Dormand–Prince 5(4) integrator, then projected onto the canted and
  inclined scope axes. The app integrates in the scope frame with fixed-step
  RK4 and rotates gravity, wind and Earth rotation into it;
* the zero is found by a secant/bisection hybrid on the bore angle.

The G-function Cd samples are standard data (BRL; McCoy, "Modern Exterior
Ballistics", 1999, ch. 4). They are read from lib/core/standard_drag_tables.dart;
the table values themselves are compared with the independent py-ballisticcalc
copy by tools/formula_audit.py (.github/workflows/formula-audit.yml).

Usage:
  python3 tools/formula_reference.py            # print the scenario table
  python3 tools/formula_reference.py --write-dart
      regenerates test/formula_reference_vectors_test.dart's data block.
"""
from __future__ import annotations

import math
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART_TABLES = ROOT / "lib" / "core" / "standard_drag_tables.dart"
DART_VECTORS = ROOT / "test" / "formula_reference_vectors_test.dart"

# --------------------------------------------------------------------- units
# NIST SP 811 (2008) Appendix B / NIST HB 44 Appendix C, exact definitions.
INCH_M = 0.0254
FOOT_M = 0.3048
YARD_M = 0.9144
POUND_KG = 0.45359237
GRAIN_KG = POUND_KG / 7000.0
G_STANDARD = 9.80665                       # CGPM 1901 / ISO 80000-3
MPH_MPS = 1609.344 / 3600.0
KNOT_MPS = 1852.0 / 3600.0
FOOT_POUND_FORCE_J = FOOT_M * POUND_KG * G_STANDARD
# Conventional inch of mercury: 0.0254 m of Hg at 13595.1 kg/m³ under g_n
# (NIST SP 811 B.8 gives 3.386 389 kPa).
INHG_PA = INCH_M * 13595.1 * G_STANDARD
# Angles: true minute of angle, milliradian, "shooter's MOA" (1 in per 100 yd).
MOA_RAD = math.pi / (180.0 * 60.0)
MIL_RAD = 1e-3
SMOA_RAD = INCH_M / (100 * YARD_M)


def fahrenheit_to_celsius(f: float) -> float:
    return (f - 32.0) / 1.8


# ---------------------------------------------------------------- atmosphere
R_UNIVERSAL = 8.314472        # J/(mol K), CIPM-2007 value
M_DRY = 28.96546e-3           # kg/mol, CIPM-2007 (x_CO2 = 0.0004)
M_WATER = 18.01528e-3


def cipm2007_density(t_c: float, p_pa: float, rh_percent: float) -> float:
    """Moist-air density, CIPM-2007 equation (Picard et al. 2008, eq. 1)."""
    t = t_c + 273.15
    h = rh_percent / 100.0
    A, B, C, D = 1.2378847e-5, -1.9121316e-2, 33.93711047, -6.3431645e3
    psv = math.exp(A * t * t + B * t + C + D / t)
    f = 1.00062 + 3.14e-8 * p_pa + 5.6e-7 * t_c * t_c
    xv = h * f * psv / p_pa
    a0, a1, a2 = 1.58123e-6, -2.9331e-8, 1.1043e-10
    b0, b1 = 5.707e-6, -2.051e-8
    c0, c1 = 1.9898e-4, -2.376e-6
    d, e = 1.83e-11, -0.765e-8
    z = (1 - (p_pa / t) * (a0 + a1 * t_c + a2 * t_c * t_c + (b0 + b1 * t_c) * xv
                           + (c0 + c1 * t_c) * xv * xv)
         + (p_pa / t) ** 2 * (d + e * xv * xv))
    return p_pa * M_DRY / (z * R_UNIVERSAL * t) * (1 - xv * (1 - M_WATER / M_DRY))


def water_mole_fraction(t_c: float, p_pa: float, rh_percent: float) -> float:
    t = t_c + 273.15
    psv = math.exp(1.2378847e-5 * t * t - 1.9121316e-2 * t + 33.93711047 - 6.3431645e3 / t)
    f = 1.00062 + 3.14e-8 * p_pa + 5.6e-7 * t_c * t_c
    return rh_percent / 100.0 * f * psv / p_pa


def speed_of_sound(t_c: float, p_pa: float, rh_percent: float) -> float:
    """Ideal humid air: c = sqrt(gamma_mix R T / M_mix).

    Molar isobaric heat capacities at ~300 K: dry air 29.12, water vapour
    33.58 J/(mol K) (NIST Chemistry WebBook). Real-gas terms (Cramer 1993)
    change c by < 0.05 % in the shooting range of conditions.
    """
    xv = water_mole_fraction(t_c, p_pa, rh_percent)
    cp = (1 - xv) * 29.12 + xv * 33.58
    gamma = cp / (cp - R_UNIVERSAL)
    m = (1 - xv) * M_DRY + xv * M_WATER
    return math.sqrt(gamma * R_UNIVERSAL * (t_c + 273.15) / m)


def isa_pressure_pa(h_m: float) -> float:
    """ICAO Doc 7488/3 troposphere: p = p0 (T/T0)^(g0 M / (R* L))."""
    t0, l, p0 = 288.15, 0.0065, 101325.0
    r_star, m = 8.31432, 0.0289644      # ICAO 1993 constants
    return p0 * ((t0 - l * h_m) / t0) ** (G_STANDARD * m / (r_star * l))


def isa_density(h_m: float) -> float:
    t0, l = 288.15, 0.0065
    t = t0 - l * h_m
    return isa_pressure_pa(h_m) * 0.0289644 / (8.31432 * t)


def density_altitude_m(rho: float) -> float:
    """Height whose ISA density is rho (bisection, no closed form used)."""
    lo, hi = -2000.0, 11000.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if isa_density(mid) > rho:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def station_from_msl_pa(p_msl_pa: float, h_m: float, t_station_c: float) -> float:
    """Hypsometric equation with the mean virtual-less column temperature
    (WMO-No. 8, 2018, Annex 3.A / Smithsonian Meteorological Tables)."""
    t_mean = t_station_c + 273.15 + 0.0065 * h_m / 2
    return p_msl_pa * math.exp(-G_STANDARD * h_m / (287.05 * t_mean))


def buck_saturation_hpa(t_c: float) -> float:
    """Buck (1981, J. Appl. Meteor. 20, 1527), 1996 revision, over water."""
    return 6.1121 * math.exp((18.678 - t_c / 234.5) * (t_c / (257.14 + t_c)))


def dew_point_c(t_c: float, rh_percent: float) -> float:
    """Temperature at which Buck's saturation pressure equals the vapour
    pressure (numerical inversion)."""
    e = buck_saturation_hpa(t_c) * rh_percent / 100
    lo, hi = -80.0, t_c
    for _ in range(200):
        mid = (lo + hi) / 2
        if buck_saturation_hpa(mid) < e:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


# ------------------------------------------------------------------- gravity
WGS84_A = 6378137.0
WGS84_B = 6356752.3142
WGS84_F = 1 / 298.257223563
WGS84_GE = 9.7803253359
WGS84_GP = 9.8321849378
WGS84_M = 0.00344978650684   # ω² a² b / GM


def gravity(lat_deg: float, h_m: float = 0.0) -> float:
    """Somigliana (NIMA TR8350.2 eq. 4-1, a/b form) + free-air eq. 4-3."""
    phi = math.radians(lat_deg)
    c2, s2 = math.cos(phi) ** 2, math.sin(phi) ** 2
    g0 = (WGS84_A * WGS84_GE * c2 + WGS84_B * WGS84_GP * s2) / math.sqrt(
        WGS84_A ** 2 * c2 + WGS84_B ** 2 * s2)
    return g0 * (1 - 2 / WGS84_A * (1 + WGS84_F + WGS84_M - 2 * WGS84_F * s2) * h_m
                 + 3 / WGS84_A ** 2 * h_m * h_m)


EARTH_OMEGA = 7.292115e-5  # rad/s, WGS-84 / IERS


# ---------------------------------------------------------------- drag table
def load_table(name: str) -> list[tuple[float, float]]:
    text = DART_TABLES.read_text(encoding="utf-8")
    block = re.search(rf"static final {name} = DragTable\(const \[(.*?)\]\);", text, re.S)
    if not block:
        raise SystemExit(f"{name} table missing in {DART_TABLES}")
    return [(float(m), float(c)) for m, c in
            re.findall(r"DragSample\(([\d.]+),\s*([\d.]+)\)", block.group(1))]


class Pchip:
    """Fritsch–Carlson monotone cubic interpolation (SIAM J. Numer. Anal.
    17 (1980) 238), clamped to the end values outside the table."""

    def __init__(self, pts: list[tuple[float, float]], linear: bool = False):
        self.x = [p[0] for p in pts]
        self.y = [p[1] for p in pts]
        self.linear = linear
        n = len(pts)
        h = [self.x[i + 1] - self.x[i] for i in range(n - 1)]
        d = [(self.y[i + 1] - self.y[i]) / h[i] for i in range(n - 1)]
        m = [0.0] * n
        m[0], m[-1] = d[0], d[-1]
        for i in range(1, n - 1):
            if d[i - 1] * d[i] <= 0:
                m[i] = 0.0
            else:
                w1, w2 = 2 * h[i] + h[i - 1], h[i] + 2 * h[i - 1]
                m[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i])
        self.h, self.d, self.m = h, d, m

    def __call__(self, xq: float) -> float:
        x, y = self.x, self.y
        if xq <= x[0]:
            return y[0]
        if xq >= x[-1]:
            return y[-1]
        lo, hi = 0, len(x) - 1
        while hi - lo > 1:
            mid = (lo + hi) // 2
            if x[mid] <= xq:
                lo = mid
            else:
                hi = mid
        t = (xq - x[lo]) / self.h[lo]
        if self.linear:
            return y[lo] + (y[hi] - y[lo]) * t
        h00 = (1 + 2 * t) * (1 - t) ** 2
        h10 = t * (1 - t) ** 2
        h01 = t * t * (3 - 2 * t)
        h11 = t * t * (t - 1)
        return (h00 * y[lo] + h10 * self.h[lo] * self.m[lo]
                + h01 * y[hi] + h11 * self.h[lo] * self.m[hi])


# ----------------------------------------------------------------- scenarios
@dataclass(frozen=True)
class Env:
    t_c: float = 15.0
    p_hpa: float = 1013.25
    rh: float = 0.0
    wind_mps: float = 0.0
    wind_deg: float = 90.0   # app convention: 0 headwind, 90 from the left


ICAO = Env()


@dataclass(frozen=True)
class Scenario:
    id: str
    model: str
    bc: float
    grain: float
    caliber_in: float
    mv_mps: float
    zero_m: float
    sight_mm: float
    ranges: tuple[float, ...]
    env: Env = ICAO
    incline_deg: float = 0.0
    cant_deg: float = 0.0
    lat_deg: float | None = None
    az_deg: float | None = None
    g: float = G_STANDARD


# Generic loads typical of the classes the owner asked for. BCs are the
# usual published order of magnitude for each class (not copied from any
# app's output); what matters is that both solvers get identical inputs.
PCP22 = dict(model="g1", bc=0.035, grain=18.13, caliber_in=0.217, mv_mps=270.0,
             zero_m=30.0, sight_mm=50.0)
PCP_RANGES = (15.0, 20.0, 30.0, 50.0, 75.0, 100.0)
R308 = dict(model="g7", bc=0.243, grain=175.0, caliber_in=0.308, mv_mps=2600 * FOOT_M,
            zero_m=100.0, sight_mm=45.0)
R308_RANGES = tuple(float(r) for r in range(100, 1001, 100))
CM65 = dict(model="g7", bc=0.315, grain=140.0, caliber_in=0.264, mv_mps=2710 * FOOT_M,
            zero_m=100.0, sight_mm=40.0)

SCENARIOS: tuple[Scenario, ...] = (
    Scenario("pcp22_mild", **PCP22, ranges=PCP_RANGES, env=Env(20, 1000, 50)),
    Scenario("pcp22_cold", **PCP22, ranges=PCP_RANGES, env=Env(-10, 1020, 80)),
    Scenario("pcp22_hot_wind3", **PCP22, ranges=PCP_RANGES,
             env=Env(40, 990, 30, wind_mps=4.0, wind_deg=270.0)),
    Scenario("pcp22_down30", **PCP22, ranges=(30.0, 50.0, 75.0), env=Env(20, 1000, 50),
             incline_deg=-30.0),
    Scenario("r308_icao", **R308, ranges=R308_RANGES),
    Scenario("r308_hot_high", **R308, ranges=R308_RANGES, env=Env(40, 800, 20)),
    Scenario("r308_cold", **R308, ranges=R308_RANGES, env=Env(-10, 1030, 60)),
    Scenario("r308_wind10_coriolis_east", **R308, ranges=(300.0, 600.0, 1000.0),
             env=Env(15, 1013.25, 50, wind_mps=10.0, wind_deg=90.0),
             lat_deg=39.0, az_deg=90.0, g=gravity(39.0)),
    Scenario("r308_up30", **R308, ranges=(300.0, 600.0), incline_deg=30.0),
    Scenario("r308_down45", **R308, ranges=(300.0, 600.0), incline_deg=-45.0),
    Scenario("r308_up60", **R308, ranges=(200.0, 400.0), incline_deg=60.0),
    Scenario("r308_cant5", **R308, ranges=(300.0, 600.0, 1000.0), cant_deg=5.0),
    Scenario("r308_coriolis_south_north", **R308, ranges=(600.0, 1000.0),
             lat_deg=-35.0, az_deg=0.0),
    Scenario("cm65_wind5_2oclock", **CM65, ranges=R308_RANGES,
             env=Env(15, 1013.25, 40, wind_mps=5.0, wind_deg=300.0)),
    Scenario("cm65_altitude3000", **CM65, ranges=R308_RANGES, env=Env(0, 700, 30)),
)


# ---------------------------------------------------------------- trajectory
@dataclass
class Point:
    range_m: float
    correction_mrad: float
    wind_mrad: float
    velocity_mps: float
    tof_s: float
    energy_j: float


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


@dataclass
class _Model:
    rho: float
    sound: float
    k: float               # rho * A * i / (2 m) without Cd
    cd: Pchip
    g: float
    wind: tuple[float, float, float]
    omega: tuple[float, float, float]

    def deriv(self, s):
        x, y, z, vx, vy, vz = s
        rx, ry, rz = vx - self.wind[0], vy - self.wind[1], vz - self.wind[2]
        vr = math.sqrt(rx * rx + ry * ry + rz * rz)
        a = -self.k * self.cd(vr / self.sound) * vr
        cor = _cross(self.omega, (vx, vy, vz))
        return (vx, vy, vz,
                a * rx - 2 * cor[0],
                a * ry - self.g - 2 * cor[1],
                a * rz - 2 * cor[2])


def _model(sc: Scenario, env: Env, cd: Pchip, coriolis: bool, atmosphere: str) -> _Model:
    p_pa = env.p_hpa * 100
    if atmosphere == "cipm":
        rho = cipm2007_density(env.t_c, p_pa, env.rh)
        sound = speed_of_sound(env.t_c, p_pa, env.rh)
    else:  # "magnus": the app's model, to isolate the integrator
        tk = env.t_c + 273.15
        pv = 6.112 * math.exp(17.62 * env.t_c / (243.12 + env.t_c)) * env.rh
        rho = (p_pa - pv) / (287.05 * tk) + pv / (461.495 * tk)
        sound = math.sqrt(1.4 * p_pa / rho)
    m = sc.grain * GRAIN_KG
    d = sc.caliber_in * INCH_M
    sd_kg_m2 = m / (d * d)
    bc_kg_m2 = sc.bc * POUND_KG / (INCH_M * INCH_M)
    form_factor = sd_kg_m2 / bc_kg_m2
    area = math.pi * d * d / 4
    k = rho * area * form_factor / (2 * m)
    d_rad = math.radians(env.wind_deg)
    # 0° = headwind: the air moves toward the shooter; 90° = from the left:
    # the air moves to the right.
    wind = (-env.wind_mps * math.cos(d_rad), 0.0, env.wind_mps * math.sin(d_rad))
    omega = (0.0, 0.0, 0.0)
    if coriolis and sc.lat_deg is not None and sc.az_deg is not None:
        lat, az = math.radians(sc.lat_deg), math.radians(sc.az_deg)
        # East-north-up components of Earth's rotation and of the local axes.
        om_enu = (0.0, EARTH_OMEGA * math.cos(lat), EARTH_OMEGA * math.sin(lat))
        fwd = (math.sin(az), math.cos(az), 0.0)
        up = (0.0, 0.0, 1.0)
        right = _cross(fwd, up)          # forward × up = right (east for north)
        omega = (_dot(om_enu, fwd), _dot(om_enu, up), _dot(om_enu, right))
    return _Model(rho, sound, k, cd, sc.g, wind, omega)


# Dormand–Prince 5(4) tableau (Dormand & Prince, J. Comp. Appl. Math. 6 (1980) 19).
_C = (0, 1 / 5, 3 / 10, 4 / 5, 8 / 9, 1, 1)
_A = ((), (1 / 5,), (3 / 40, 9 / 40), (44 / 45, -56 / 15, 32 / 9),
      (19372 / 6561, -25360 / 2187, 64448 / 6561, -212 / 729),
      (9017 / 3168, -355 / 33, 46732 / 5247, 49 / 176, -5103 / 18656),
      (35 / 384, 0, 500 / 1113, 125 / 192, -2187 / 6784, 11 / 84))
_B5 = (35 / 384, 0, 500 / 1113, 125 / 192, -2187 / 6784, 11 / 84, 0)
_B4 = (5179 / 57600, 0, 7571 / 16695, 393 / 640, -92097 / 339200, 187 / 2100, 1 / 40)


def _dp_step(f, s, h):
    ks = []
    for i in range(7):
        si = list(s)
        for j, a in enumerate(_A[i]):
            if a:
                kj = ks[j]
                for n in range(6):
                    si[n] += h * a * kj[n]
        ks.append(f(si))
    y5 = [s[n] + h * sum(_B5[i] * ks[i][n] for i in range(7)) for n in range(6)]
    y4 = [s[n] + h * sum(_B4[i] * ks[i][n] for i in range(7)) for n in range(6)]
    return y5, y4, ks[0], ks[6]


def _hermite(s0, f0, s1, f1, h, t):
    """Cubic Hermite state at fraction t of a step of length h."""
    h00 = 2 * t ** 3 - 3 * t ** 2 + 1
    h10 = t ** 3 - 2 * t ** 2 + t
    h01 = -2 * t ** 3 + 3 * t ** 2
    h11 = t ** 3 - t ** 2
    return [h00 * s0[n] + h10 * h * f0[n] + h01 * s1[n] + h11 * h * f1[n] for n in range(6)]


def _fly(model: _Model, s0, axis, targets, rtol=1e-10, atol=1e-10, t_max=60.0):
    """Integrate until the state's projection on `axis` passes every target.
    Returns [(time, state)] at each target (sorted ascending)."""
    out = []
    targets = sorted(targets)
    s, t, h = list(s0), 0.0, 1e-4
    f0 = model.deriv(s)
    i = 0
    while i < len(targets):
        if t > t_max:
            raise RuntimeError("did not reach range")
        y5, y4, _k1, k7 = _dp_step(model.deriv, s, h)
        err = max(abs(a - b) / (atol + rtol * max(abs(a), abs(c)))
                  for a, b, c in zip(y5, y4, s))
        if err > 1:
            h *= max(0.2, 0.9 * err ** -0.2)
            continue
        while i < len(targets) and _dot(y5[:3], axis) >= targets[i]:
            lo, hi = 0.0, 1.0
            for _ in range(80):
                mid = (lo + hi) / 2
                if _dot(_hermite(s, f0, y5, k7, h, mid)[:3], axis) < targets[i]:
                    lo = mid
                else:
                    hi = mid
            tau = (lo + hi) / 2
            out.append((t + tau * h, _hermite(s, f0, y5, k7, h, tau)))
            i += 1
        s, t, f0 = y5, t + h, k7
        if s[3] <= 0:
            raise RuntimeError("projectile stopped")
        h *= min(5.0, 0.9 * max(err, 1e-12) ** -0.2)
        h = min(h, 0.01)
    return out


def _axes(incline_deg: float, cant_deg: float):
    th, ph = math.radians(incline_deg), math.radians(cant_deg)
    los = (math.cos(th), math.sin(th), 0.0)
    up0 = (-math.sin(th), math.cos(th), 0.0)
    right0 = (0.0, 0.0, 1.0)
    # Clockwise roll as seen by the shooter: the scope's top goes right.
    up = tuple(math.cos(ph) * u + math.sin(ph) * r for u, r in zip(up0, right0))
    right = tuple(math.cos(ph) * r - math.sin(ph) * u for u, r in zip(up0, right0))
    return los, up, right


def _launch(sc: Scenario, alpha: float, axes):
    los, up, _right = axes
    h = sc.sight_mm / 1000
    pos = tuple(-h * u for u in up)
    vel = tuple(sc.mv_mps * (math.cos(alpha) * l + math.sin(alpha) * u) for l, u in zip(los, up))
    return list(pos) + list(vel)


def zero_angle(sc: Scenario, cd: Pchip, atmosphere: str) -> float:
    """Bore angle above the sight line that zeroes at sc.zero_m, level, no
    wind, no Coriolis, ICAO air (the app's zeroing assumption)."""
    zsc = Scenario(**{**sc.__dict__, "lat_deg": None, "az_deg": None})
    model = _model(zsc, ICAO, cd, False, atmosphere)
    axes = _axes(0.0, 0.0)

    def height(alpha):
        (_t, s), = _fly(model, _launch(sc, alpha, axes), axes[0], [sc.zero_m])
        return _dot(s[:3], axes[1])

    a, b = 0.0, 0.05
    fa, fb = height(a), height(b)
    for _ in range(100):
        c = b - fb * (b - a) / (fb - fa)
        fc = height(c)
        if abs(fc) < 1e-12:
            return c
        a, fa, b, fb = b, fb, c, fc
    return b


def solve(sc: Scenario, interpolation: str = "pchip", atmosphere: str = "cipm") -> list[Point]:
    cd = Pchip(load_table(sc.model), linear=(interpolation == "linear"))
    alpha = zero_angle(sc, cd, atmosphere)
    axes = _axes(sc.incline_deg, sc.cant_deg)
    model = _model(sc, sc.env, cd, True, atmosphere)
    hits = _fly(model, _launch(sc, alpha, axes), axes[0], list(sc.ranges))
    m = sc.grain * GRAIN_KG
    out = []
    for r, (t, s) in zip(sorted(sc.ranges), hits):
        y = _dot(s[:3], axes[1])
        z = _dot(s[:3], axes[2])
        v = math.sqrt(s[3] ** 2 + s[4] ** 2 + s[5] ** 2)
        out.append(Point(r, math.atan2(-y, r) * 1000, math.atan2(-z, r) * 1000, v, t,
                         0.5 * m * v * v))
    return out


# -------------------------------------------------------- spin / stability
def miller_sg(grain, diameter_in, length_in, twist_in, v_fps, t_f, p_inhg):
    """Miller (2005), "A New Rule for Estimating Rifling Twist", Precision
    Shooting, March 2005: Sg = 30 m / (t² d³ l (1 + l²)), t and l in
    calibres, with fv = (v/2800)^(1/3) and the atmosphere correction
    (T+460)/(59+460) * 29.92/P (Litz, Applied Ballistics, 2nd ed., ch. 10)."""
    t = twist_in / diameter_in
    l = length_in / diameter_in
    sg = 30 * grain / (t ** 2 * diameter_in ** 3 * l * (1 + l * l))
    return sg * (v_fps / 2800) ** (1 / 3) * (t_f + 460) / 519 * 29.92 / p_inhg


def litz_spin_drift_in(sg: float, tof_s: float) -> float:
    """Litz, Applied Ballistics for Long Range Shooting (2009), eq. 10.1:
    SD = 1.25 (Sg + 1.2) TOF^1.83 inches."""
    return 1.25 * (sg + 1.2) * tof_s ** 1.83


def litz_aero_jump_moa_per_mph(sg: float, length_cal: float) -> float:
    """Litz (2009) ch. 10: vertical jump per mph of crosswind,
    Y = 0.01 Sg − 0.0024 L + 0.032 MOA/mph (L in calibres)."""
    return 0.01 * sg - 0.0024 * length_cal + 0.032


# ------------------------------------------------------------- Dart output
def _fmt(v: float) -> str:
    return repr(round(v, 9))


def dart_block() -> str:
    lines = ["// BEGIN GENERATED (python3 tools/formula_reference.py --write-dart)"]
    lines.append("const referenceScenarios = <RefScenario>[")
    for sc in SCENARIOS:
        ref = solve(sc, "pchip", "cipm")
        same = solve(sc, "linear", "magnus")
        e = sc.env
        lines.append("  RefScenario(")
        lines.append(f"    id: '{sc.id}', model: BallisticModel.{sc.model}, bc: {_fmt(sc.bc)},")
        lines.append(f"    grain: {_fmt(sc.grain)}, mvMps: {_fmt(sc.mv_mps)}, zeroM: {_fmt(sc.zero_m)},")
        lines.append(f"    sightMm: {_fmt(sc.sight_mm)}, g: {_fmt(sc.g)},")
        lines.append(f"    env: EnvironmentData(temperatureC: {_fmt(e.t_c)}, pressureHpa: {_fmt(e.p_hpa)}, "
                     f"humidityPercent: {_fmt(e.rh)}, windMps: {_fmt(e.wind_mps)}, "
                     f"windDirectionDeg: {_fmt(e.wind_deg)}),")
        lines.append(f"    inclineDeg: {_fmt(sc.incline_deg)}, cantDeg: {_fmt(sc.cant_deg)},")
        lines.append(f"    latitudeDeg: {'null' if sc.lat_deg is None else _fmt(sc.lat_deg)}, "
                     f"azimuthDeg: {'null' if sc.az_deg is None else _fmt(sc.az_deg)},")
        lines.append("    points: [")
        for p, q in zip(ref, same):
            lines.append(f"      RefPoint({_fmt(p.range_m)}, {_fmt(p.correction_mrad)}, {_fmt(p.wind_mrad)}, "
                         f"{_fmt(p.velocity_mps)}, {_fmt(p.tof_s)}, {_fmt(p.energy_j)}, "
                         f"{_fmt(q.correction_mrad)}, {_fmt(q.wind_mrad)}, {_fmt(q.velocity_mps)}, "
                         f"{_fmt(q.tof_s)}),")
        lines.append("    ],")
        lines.append("  ),")
    lines.append("];")
    lines.append("")
    lines.append("/// (°C, hPa, %RH, CIPM-2007 kg/m³, speed of sound m/s, Buck dew point °C)")
    lines.append("const referenceAir = <List<double>>[")
    for t, p, rh in AIR_POINTS:
        lines.append(f"  [{_fmt(t)}, {_fmt(p)}, {_fmt(rh)}, {_fmt(cipm2007_density(t, p * 100, rh))}, "
                     f"{_fmt(speed_of_sound(t, p * 100, rh))}, {_fmt(dew_point_c(t, rh) if rh > 0 else -999)}],")
    lines.append("];")
    lines.append("")
    lines.append("/// (latitude °, height m, WGS-84 normal gravity m/s²)")
    lines.append("const referenceGravity = <List<double>>[")
    for lat, h in GRAVITY_POINTS:
        lines.append(f"  [{_fmt(lat)}, {_fmt(h)}, {_fmt(gravity(lat, h))}],")
    lines.append("];")
    lines.append("")
    lines.append("/// (height m, ICAO station pressure hPa from 1013.25, ISA density kg/m³,")
    lines.append("///  hypsometric station hPa from 1013.25 at 30 °C station temperature)")
    lines.append("const referenceIsa = <List<double>>[")
    for h in ISA_HEIGHTS:
        lines.append(f"  [{_fmt(h)}, {_fmt(isa_pressure_pa(h) / 100)}, {_fmt(isa_density(h))}, "
                     f"{_fmt(station_from_msl_pa(101325.0, h, 30.0) / 100)}],")
    lines.append("];")
    lines.append("// END GENERATED")
    return "\n".join(lines)


AIR_POINTS = [(-20, 1030, 50), (-10, 1020, 80), (0, 700, 30), (15, 1013.25, 0), (15, 1013.25, 100),
              (20, 1000, 50), (30, 900, 70), (40, 990, 30), (40, 800, 100), (50, 1013.25, 90)]
GRAVITY_POINTS = [(0, 0), (36, 0), (39, 0), (39.9, 900), (42, 2000), (45, 0), (60, 3000), (90, 0), (-35, 500)]
ISA_HEIGHTS = [0, 500, 1000, 2000, 3000, 5000]


GENERATED_RE = re.compile(r"// BEGIN GENERATED.*?// END GENERATED", re.S)


def write_dart() -> None:
    text = DART_VECTORS.read_text(encoding="utf-8")
    if not GENERATED_RE.search(text):
        raise SystemExit(f"no generated block in {DART_VECTORS}")
    DART_VECTORS.write_text(GENERATED_RE.sub(lambda _m: dart_block(), text), encoding="utf-8")


def main(argv: list[str]) -> int:
    if "--write-dart" in argv:
        write_dart()
        return 0
    for sc in SCENARIOS:
        ref = solve(sc)
        same = solve(sc, "linear", "magnus")
        print(sc.id)
        for p, q in zip(ref, same):
            print(f"  {p.range_m:6.0f} m  up {p.correction_mrad:8.3f} mrad (app-model {q.correction_mrad:8.3f})"
                  f"  wind {p.wind_mrad:7.3f}  v {p.velocity_mps:7.1f}  t {p.tof_s:6.3f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
