#!/usr/bin/env python3
"""Independent audit of the Hesaplayicilar formulas and the hit-probability model.

Run in a throw-away venv that has py-ballisticcalc==2.2.10, numpy, geopy and pint.
Every check compares the app's formula (re-stated from the Dart source) with a
DIFFERENT implementation: CIPM-2007 air density, geographiclib geodesics, pint
unit factors, the pinned py-ballisticcalc trajectory engine, Monte Carlo.
Tolerances are declared in the table below before any result is looked at.

Prints one "PASS|FAIL name: detail" line per check; exit code 1 on any FAIL.
This script is not part of the production gate and opens nothing.
"""
from __future__ import annotations

import math
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import offline_solver_crosscheck as osc  # noqa: E402  (table loader only)

TOL = {
    "air_density_rel": 0.005,        # Magnus ideal-gas mix vs CIPM-2007
    "density_alt_m": 1.0,            # inverse ISA
    "isa_pressure_hpa": 0.3,
    "haversine_rel": 0.006,          # sphere vs WGS-84 ellipsoid
    "bearing_deg_short": 0.3,
    "unit_factor_rel": 1e-5,
    "velocity_after_mps": 0.15,      # vs py-ballisticcalc RK4
    "bc_roundtrip_rel": 0.02,
    "rayleigh_abs": 0.004,           # closed form vs 2e6-sample Monte Carlo
}

results: list[tuple[bool, str]] = []


def check(name: str, ok: bool, detail: str) -> None:
    results.append((ok, f"{'PASS' if ok else 'FAIL'} {name}: {detail}"))


# ---------------------------------------------------------------- air density
def app_density(t_c, p_hpa, rh):
    tk = t_c + 273.15
    pv = 6.112 * math.exp(17.62 * t_c / (243.12 + t_c)) * 100 * rh / 100
    pt = p_hpa * 100
    return (pt - pv) / (287.05 * tk) + pv / (461.495 * tk)


def cipm_density(t_c, p_hpa, rh):
    t, p, h = t_c + 273.15, p_hpa * 100, rh / 100
    A, B, C, D = 1.2378847e-5, -1.9121316e-2, 33.93711047, -6.3431645e3
    psv = math.exp(A * t * t + B * t + C + D / t)
    f = 1.00062 + 3.14e-8 * p + 5.6e-7 * t_c * t_c
    xv = h * f * psv / p
    a0, a1, a2 = 1.58123e-6, -2.9331e-8, 1.1043e-10
    b0, b1 = 5.707e-6, -2.051e-8
    c0, c1 = 1.9898e-4, -2.376e-6
    d, e = 1.83e-11, -0.765e-8
    z = 1 - (p / t) * (a0 + a1 * t_c + a2 * t_c**2 + (b0 + b1 * t_c) * xv + (c0 + c1 * t_c) * xv**2) \
        + (p / t) ** 2 * (d + e * xv**2)
    ma, mv, r = 28.96546e-3, 18.01528e-3, 8.314472
    return p * ma / (z * r * t) * (1 - xv * (1 - mv / ma))


def audit_air():
    worst = 0.0
    arg = None
    for t in range(-20, 41, 5):
        for p in range(700, 1051, 50):
            for rh in (0, 25, 50, 75, 100):
                if 6.112 * math.exp(17.62 * t / (243.12 + t)) * rh / 100 >= p:
                    continue
                a, b = app_density(t, p, rh), cipm_density(t, p, rh)
                rel = abs(a - b) / b
                if rel > worst:
                    worst, arg = rel, (t, p, rh)
    check("air_density_vs_CIPM2007", worst <= TOL["air_density_rel"],
          f"max rel diff {worst:.5f} at T/P/RH={arg} (tol {TOL['air_density_rel']})")

    # dew point: Magnus psat at Td must equal the actual vapour pressure
    worst = 0.0
    for t in range(-10, 41, 5):
        for rh in (10, 30, 50, 70, 90, 100):
            a, b = 17.62, 243.12
            g = math.log(rh / 100) + a * t / (b + t)
            td = b * g / (a - g)
            pv = 6.112 * math.exp(a * t / (b + t)) * rh / 100
            ps_td = 6.112 * math.exp(a * td / (b + td))
            worst = max(worst, abs(ps_td - pv) / pv)
            if rh >= 50:  # Lawrence approximation, valid for RH >= 50 %
                lawrence = t - (100 - rh) / 5
                if abs(td - lawrence) > 1.0:
                    check("dew_point_vs_Lawrence", False, f"T={t} RH={rh} td={td:.2f} approx={lawrence:.2f}")
    check("dew_point_inverse_consistency", worst < 1e-9, f"max rel {worst:.2e}")

    # density altitude: ISA troposphere density -> altitude round trip
    worst = 0.0
    for h in range(0, 11001, 500):
        rho = 1.225 * (1 - 2.25577e-5 * h) ** 4.25588
        da = 44330.77 * (1 - (rho / 1.225) ** 0.234969)
        worst = max(worst, abs(da - h))
    check("density_altitude_ISA_roundtrip", worst <= TOL["density_alt_m"], f"max |dh| {worst:.3f} m")

    # station pressure vs ISA table values (ICAO Doc 7488)
    table = {0: 1013.25, 1000: 898.76, 2000: 795.01, 3000: 701.21, 5000: 540.48}
    worst = max(abs(1013.25 * (1 - 2.25577e-5 * h) ** 5.25588 - p) for h, p in table.items())
    check("station_pressure_vs_ISA_table", worst <= TOL["isa_pressure_hpa"], f"max |dp| {worst:.3f} hPa")

    # speed of sound, dry air, vs textbook 331.3*sqrt(T/273.15)
    worst = 0.0
    for t in range(-20, 41, 10):
        rho = app_density(t, 1013.25, 0)
        c = math.sqrt(1.4 * 101325 / rho)
        worst = max(worst, abs(c - 331.3 * math.sqrt((t + 273.15) / 273.15)))
    check("speed_of_sound_dry", worst < 0.5, f"max |dc| {worst:.3f} m/s")


# ---------------------------------------------------------------- geodesy
def haversine(lat1, lon1, lat2, lon2):
    R = 6371008.8
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * R * math.asin(min(1, math.sqrt(a)))


def bearing(lat1, lon1, lat2, lon2):
    p1, p2, dl = math.radians(lat1), math.radians(lat2), math.radians(lon2 - lon1)
    y = math.sin(dl) * math.cos(p2)
    x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(y, x)) + 360) % 360


def audit_geo():
    from geographiclib.geodesic import Geodesic
    rnd = random.Random(7)
    worst_rel = worst_brg = 0.0
    n = 0
    for _ in range(4000):
        lat, lon = rnd.uniform(35, 42), rnd.uniform(26, 45)  # Turkey
        dist = rnd.choice([200, 800, 2500, 20_000, 120_000, 600_000])
        az = rnd.uniform(0, 360)
        g = Geodesic.WGS84.Direct(lat, lon, az, dist)
        lat2, lon2 = g["lat2"], g["lon2"]
        true = Geodesic.WGS84.Inverse(lat, lon, lat2, lon2)
        s_true, a_true = true["s12"], true["azi1"] % 360
        s_app = haversine(lat, lon, lat2, lon2)
        worst_rel = max(worst_rel, abs(s_app - s_true) / s_true)
        if dist <= 120_000:
            d = abs((bearing(lat, lon, lat2, lon2) - a_true + 180) % 360 - 180)
            worst_brg = max(worst_brg, d)
        n += 1
    check("haversine_vs_WGS84_geodesic", worst_rel <= TOL["haversine_rel"],
          f"{n} pairs in Turkey, 0.2-600 km: max rel {worst_rel:.5f} (sphere, no ellipsoid)")
    check("bearing_vs_WGS84_azimuth", worst_brg <= TOL["bearing_deg_short"],
          f"pairs up to 120 km: max |d azimuth| {worst_brg:.4f} deg")


# ---------------------------------------------------------------- converters
def parse_converters():
    text = (ROOT / "lib/tools/domain/field_calc.dart").read_text(encoding="utf-8")
    out = {}
    for name in ("angle", "speed", "weight", "pressure", "length", "torque"):
        block = re.search(rf"static const {name} = ConvCategory\([^\[]*\[(.*?)\]\);", text, re.S).group(1)
        items = []
        for label, expr in re.findall(r"ConvUnit\('([^']+)',\s*([^\n]+?)\),?\n", block):
            expr = expr.strip().rstrip(",").rstrip(")")
            expr = expr.replace("FieldCalc.radPerMoa", "(math.pi/10800)").replace("FieldCalc.radPerMil", "0.001")
            expr = expr.replace("math.pi", "3.141592653589793")
            items.append((label, eval(expr, {"__builtins__": {}})))
        out[name] = items
    return out


def audit_units():
    import pint
    ureg = pint.UnitRegistry()
    Q = ureg.Quantity
    pu = {
        "angle": {"Derece": "degree", "Radyan": "radian", "MOA": "arcminute", "MIL": "milliradian",
                  "NATO": None, "SMOA": None, "cm/100": None},
        "speed": {"m/s": "m/s", "fps": "ft/s", "km/sa": "km/h", "mph": "mph", "knot": "knot"},
        "weight": {"grain": "grain", "gram": "g", "miligram": "mg", "kilogram": "kg", "ons": "ounce", "libre": "pound"},
        "pressure": {"bar": "bar", "psi": "psi", "hPa": "hPa", "kPa": "kPa", "MPa": "MPa", "atm": "atm",
                     "mmHg": "mmHg", "inHg": "inch_Hg", "kgf/cm": "kilogram_force/cm**2"},
        "length": {"milimetre": "mm", "santimetre": "cm", "metre": "m", "kilometre": "km", "inç": "inch",
                   "fit": "foot", "yarda": "yard", "mil (mi)": "mile"},
        "torque": {"N·m": "N*m", "N·cm": "N*cm", "lbf·ft": "pound_force*foot", "lbf·in": "pound_force*inch",
                   "ozf·in": "ounce_force*inch", "kgf·m": "kilogram_force*m"},
    }
    base = {"angle": "radian", "speed": "m/s", "weight": "g", "pressure": "Pa", "length": "m", "torque": "N*m"}
    special = {"NATO": 2 * math.pi / 6400, "SMOA": 1 / 3600, "cm/100": 1e-4}
    cats = parse_converters()
    for cat, items in cats.items():
        worst, who = 0.0, None
        unmapped = []
        for label, factor in items:
            key = next((k for k in pu[cat] if label.startswith(k)), None)
            if key is None:
                unmapped.append(label)
                continue
            if cat == "angle" and key in special:
                ref = special[key]
            else:
                ref = Q(1, pu[cat][key]).to(base[cat]).magnitude
            rel = abs(factor - ref) / abs(ref)
            if rel > worst:
                worst, who = rel, label
        check(f"converter_{cat}_vs_pint", worst <= TOL["unit_factor_rel"] and not unmapped,
              f"{len(items)} units, max rel {worst:.2e} ({who}); unmapped={unmapped}")
    # angular definitions
    moa_cm_100yd = math.tan(math.pi / 10800) * 3600 * 2.54
    check("moa_definition", abs(moa_cm_100yd - 2.6597) < 0.002, f"1 MOA at 100 yd = {moa_cm_100yd:.4f} cm (=1.0472 in)")
    check("mil_definition", abs(math.tan(0.001) * 100 * 100 - 10.0) < 1e-3, "1 MIL at 100 m = 10.000 cm")


# ---------------------------------------------------------------- BC / drag
def mirror_velocity_after(table, bc, v1, dist, t_c, p_hpa, rh, step=0.5):
    air = osc.Air(t_c, p_hpa, rh)
    bc_si = bc * osc.LB_IN2_TO_KG_M2

    def f(v):
        if v <= 1:
            return 0.0
        cd = osc.cd_at(table, v / air.sound)
        return -(0.5 * air.rho * cd * (math.pi / 4) * v * v / bc_si) / v

    v, x = v1, 0.0
    while x < dist:
        h = min(step, dist - x)
        k1 = f(v); k2 = f(v + h / 2 * k1); k3 = f(v + h / 2 * k2); k4 = f(v + h * k3)
        v += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
        x += h
    return v


def mirror_solve_bc(table, v1, v2, dist, t_c, p_hpa, rh):
    lo, hi = 0.005, 3.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if mirror_velocity_after(table, mid, v1, dist, t_c, p_hpa, rh) < v2:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def audit_bc():
    from py_ballisticcalc import (Ammo, Atmo, Calculator, Distance, DragModel, Shot, TableG1, TableG7,
                                  Velocity, Weapon)
    tables = osc.load_tables()
    cases = [
        ("g1", TableG1, 0.030, 280.0, [10, 30, 50, 100]),
        ("g1", TableG1, 0.120, 270.0, [25, 50, 100, 200]),
        ("g1", TableG1, 0.025, 240.0, [10, 30, 60]),
        ("g7", TableG7, 0.150, 280.0, [30, 100, 200]),
        ("g7", TableG7, 0.243, 800.0, [100, 500, 1000]),
    ]
    worst_v = worst_bc = 0.0
    detail = []
    for name, ptable, bc, mv, ranges in cases:
        dm = DragModel(bc, ptable, weight=15.9)
        shot = Shot(weapon=Weapon(sight_height=Distance.Millimeter(50)), ammo=Ammo(dm, mv=Velocity.MPS(mv)),
                    atmo=Atmo.icao())
        hit = Calculator(engine="rk4_engine").fire(shot, trajectory_range=Distance.Meter(max(ranges) + 1),
                                                  trajectory_step=Distance.Meter(1))
        for r in ranges:
            v_py = hit.get_at("distance", Distance.Meter(r)).velocity >> Velocity.MPS
            v_me = mirror_velocity_after(tables[name], bc, mv, r, 15.0, 1013.25, 0.0)
            dv = abs(v_py - v_me)
            worst_v = max(worst_v, dv)
            if v_me < mv - 2.0:  # BC is only recoverable when the velocity loss is measurable
                bc_back = mirror_solve_bc(tables[name], mv, v_py, r, 15.0, 1013.25, 0.0)
                rel = abs(bc_back - bc) / bc
                worst_bc = max(worst_bc, rel)
                detail.append(f"{name} bc={bc} r={r}: dv={dv:.3f} bc_back={bc_back:.4f}")
    check("velocity_after_vs_py_ballisticcalc", worst_v <= TOL["velocity_after_mps"],
          f"{len(cases)} loads, max |dv| {worst_v:.3f} m/s (tol {TOL['velocity_after_mps']})")
    check("bc_from_two_velocities_vs_py_ballisticcalc", worst_bc <= TOL["bc_roundtrip_rel"],
          f"max rel BC error {worst_bc:.4f} using py velocities as the 'measured' V2; " + "; ".join(detail[:4]))


# ---------------------------------------------------------------- statistics
def audit_hit_probability():
    import numpy as np
    rng = np.random.default_rng(1)
    worst = 0.0
    for group_moa, target_cm, rng_m in [(1.0, 10, 100), (0.5, 2.5, 50), (2.0, 15, 200), (1.5, 4, 80)]:
        sigma = math.radians(group_moa / 2 / 60) * rng_m          # 1-sigma radial = group radius (app assumption)
        r_t = target_cm / 100 / 2
        closed = 1 - math.exp(-r_t * r_t / (2 * sigma * sigma))
        xy = rng.normal(0, sigma, size=(2_000_000, 2))
        mc = float(np.mean(np.hypot(xy[:, 0], xy[:, 1]) <= r_t))
        worst = max(worst, abs(closed - mc))
    check("hit_probability_closed_form_vs_monte_carlo", worst <= TOL["rayleigh_abs"], f"max |dP| {worst:.5f}")
    # what a measured N-shot group diameter really means for sigma (model note, not a pass/fail)
    notes = []
    for n in (3, 5, 10):
        xy = rng.normal(0, 1.0, size=(20000, n, 2))
        d = xy[:, :, None, :] - xy[:, None, :, :]
        es = np.sqrt((d ** 2).sum(-1)).max(axis=(1, 2)).mean()
        notes.append(f"N={n}: mean group diameter = {es:.2f} sigma_axis")
    results.append((True, "INFO group_diameter_vs_sigma: " + "; ".join(notes) +
                    " (app uses diameter = 2 sigma, so it assumes an N~10+ group; smaller groups make the app conservative)"))


def audit_chrono():
    import statistics
    v = [270.1, 271.4, 269.8, 270.9, 272.0, 270.3]
    sd = statistics.stdev(v)
    results.append((True, f"INFO chronograph sample SD (n-1) for {v}: {sd:.4f} m/s, ES {max(v)-min(v):.2f}"))


def main() -> int:
    for fn in (audit_air, audit_geo, audit_units, audit_bc, audit_hit_probability, audit_chrono):
        try:
            fn()
        except Exception as exc:  # a crashed audit must be visible, never a silent pass
            results.append((False, f"FAIL {fn.__name__}: crashed: {type(exc).__name__}: {exc}"))
    for _, line in results:
        print(line)
    return 0 if all(ok for ok, _ in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
