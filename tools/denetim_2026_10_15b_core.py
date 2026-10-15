#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15b, PR #324 (formulas moved into lib/core).

Hand-calculated reference values for
test/audit_2026_10_15b/core_formulas_audit_test.dart. Every number is built
from definitions only, not from the app's own constants:

* 1 in = 25.4 mm, 1 ft = 0.3048 m, 1 mph = 0.44704 m/s (exact, 1959 yard
  and pound agreement), 1 gr = 64.79891 mg (exact).
* 1 MOA = pi / (180 * 60) rad, 1 mrad = 0.001 rad.
* 1 inHg = 3386.389 Pa (conventional mercury column, 13.5951 g/cm3,
  g_n = 9.80665 m/s2); 1 hPa = 100 Pa.
* Speed of sound in dry air: sqrt(gamma * R * T), gamma = 1.4,
  R = 287.05 J/(kg K) (ICAO standard atmosphere constants).
* Miller twist rule with velocity, temperature and pressure corrections
  (D. Miller, "A New Rule for Estimating Rifling Twist", Precision
  Shooting, March 2005).
* Litz spin drift 1.25 (Sg + 1.2) t^1.83 in and aerodynamic jump
  0.01 Sg - 0.0024 l + 0.032 MOA/mph (B. Litz, book formulas).

No value comes from another ballistic app.
Run: python3 tools/denetim_2026_10_15b_core.py
"""
import math

MM_PER_IN = 25.4
M_PER_FT = 0.3048
MPS_PER_MPH = 0.44704
KG_PER_GR = 64.79891e-6
PA_PER_INHG = 13.5951 * 1000 * 9.80665 * 0.0254  # 3386.38864...
RAD_PER_MOA = math.pi / (180 * 60)
RAD_PER_MRAD = 0.001


def mrad_of(size_m: float, range_m: float) -> float:
    return math.atan(size_m / range_m) / RAD_PER_MRAD


def miller_sg(grain, caliber_mm, twist_in, length_mm, v_mps, temp_c, p_hpa):
    d = caliber_mm / MM_PER_IN
    t = twist_in / d
    l = (length_mm / MM_PER_IN) / d
    sound = math.sqrt(1.4 * 287.05 * (temp_c + 273.15))
    v = max(v_mps, sound)  # Courtney & Miller: subsonic uses Mach 1 factor.
    v_fps = v / M_PER_FT
    temp_f = temp_c * 9 / 5 + 32
    p_inhg = p_hpa * 100 / PA_PER_INHG
    return (30 * grain / (t * t * d ** 3 * l * (1 + l * l))
            * (v_fps / 2800) ** (1 / 3)
            * ((temp_f + 460) / (59 + 460))
            * (29.92 / p_inhg))


def spin_drift_mrad(sg, tof_s, range_m, right=True):
    drift_in = 1.25 * (sg + 1.2) * tof_s ** 1.83
    drift_m = drift_in * MM_PER_IN / 1000 * (1 if right else -1)
    return mrad_of(drift_m, range_m)


def aero_jump_mrad(sg, l_cal, wind_mps, dir_deg, right=True):
    from_right_mph = -(wind_mps / MPS_PER_MPH) * math.sin(math.radians(dir_deg))
    moa = (0.01 * sg - 0.0024 * l_cal + 0.032) * from_right_mph
    moa *= 1 if right else -1
    return moa * RAD_PER_MOA / RAD_PER_MRAD


def zero_offset_mrad(typed, zero_m, metric):
    if zero_m is None or zero_m <= 0 or typed is None or abs(typed) > 100:
        return 0.0
    m = typed / 100 if metric else typed * MM_PER_IN / 1000
    return mrad_of(m, zero_m)


def lead_mrad(speed_mps, tof_s, range_m):
    return mrad_of(speed_mps * tof_s, range_m)


def sectional_density(grain, caliber_mm):
    d = caliber_mm / MM_PER_IN
    return grain / 7000 / (d * d)


def grain_for_sd(sd, caliber_mm):
    d = caliber_mm / MM_PER_IN
    return sd * 7000 * d * d


def energy_j(grain, v_mps):
    return 0.5 * grain * KG_PER_GR * v_mps ** 2


def velocity_for_energy_fps(grain, joules):
    return math.sqrt(2 * joules / (grain * KG_PER_GR)) / M_PER_FT


def stadia_distance_m(size, metric_cm, reading, mil):
    size_m = size / 100 if metric_cm else size * MM_PER_IN / 1000
    rad = reading * (RAD_PER_MRAD if mil else RAD_PER_MOA)
    return size_m / math.tan(rad)


def low_pass(x, target, dt, tau):
    return x + (target - x) * (1 - math.exp(-dt / tau))


def mount_cant_clicks(cant_moa, click, unit):
    # unit: 'mrad' or 'moa' (true MOA)
    rad = cant_moa * RAD_PER_MOA
    angle = rad / RAD_PER_MRAD if unit == "mrad" else rad / RAD_PER_MOA
    return math.floor(angle / click + 1e-9)


def rows():
    return [
        ("millerSg 168gr .300 12in 1.2in 2800fps 15C 1013.25hPa",
         miller_sg(168, 7.62, 12, 30.48, 2800 * M_PER_FT, 15, 1013.25)),
        ("millerSg 168gr .300 10in 1.2in 2800fps 15C 1013.25hPa",
         miller_sg(168, 7.62, 10, 30.48, 2800 * M_PER_FT, 15, 1013.25)),
        ("millerSg subsonic 300 m/s 15C (floor = sound)",
         miller_sg(168, 7.62, 12, 30.48, 300, 15, 1013.25)),
        ("spinDriftMrad sg1.8 t1.2 800m", spin_drift_mrad(1.8, 1.2, 800)),
        ("aeroJumpMrad sg1.8 l4 4m/s 270deg",
         aero_jump_mrad(1.8, 4.0, 4.0, 270)),
        ("zeroOffsetMrad 2in 100m", zero_offset_mrad(2, 100, False)),
        ("zeroOffsetMrad 2cm 100m", zero_offset_mrad(2, 100, True)),
        ("leadMrad 1.5m/s 0.9s 600m", lead_mrad(1.5, 0.9, 600)),
        ("SD 77gr 5.69mm", sectional_density(77, 5.69)),
        ("BC window low 7.62", grain_for_sd(0.08, 7.62)),
        ("BC window high 7.62", grain_for_sd(0.45, 7.62)),
        ("energy 168gr 2650fps", energy_j(168, 2650 * M_PER_FT)),
        ("need fps 168gr 3000J", velocity_for_energy_fps(168, 3000)),
        ("stadia 18in 2mil", stadia_distance_m(18, False, 2, True)),
        ("stadia 45cm 5moa", stadia_distance_m(45, True, 5, False)),
        ("density altitude 1000 m in ft", 1000 / M_PER_FT),
        ("low pass 0->10 dt=1/60 tau=0.12", low_pass(0, 10, 1 / 60, 0.12)),
        ("mount cant 20 MOA, 0.1 mrad", mount_cant_clicks(20, 0.1, "mrad")),
        ("mount cant 20 MOA, 1/4 MOA", mount_cant_clicks(20, 0.25, "moa")),
    ]


def main() -> None:
    for name, value in rows():
        print(f"{name:55s} {value!r}")


if __name__ == "__main__":
    main()
