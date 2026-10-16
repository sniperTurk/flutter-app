#!/usr/bin/env python3
"""Pre-TestFlight audit 2026-10-15c, "diğer" part: the non-design PRs merged
into main after 4c51b77 (#334/#340, #335, #336, #338, #342, #345, #353,
#355, #356, #357 and #228).

Hand calculations for test/audit_2026_10_15c/diger_audit_test.dart and
tools/test_denetim_2026_10_15c_diger.py. References, never another
ballistic app:

* unit definitions (1 ft = 0.3048 m, 1 gr = 64.79891 mg);
* ICAO standard atmosphere, P = 1013.25 * (1 - 2.25577e-5 h)^5.25588 hPa;
* the powder-temperature rule the app documents, v = v0 * (1 + k/100 *
  (T - T0) / 15) (lib/core/powder_temperature.dart), evaluated by hand;
* tools/formula_reference.py: the repository's own independent point-mass
  solver (published G1 table, CIPM air), used for KUL-10;
* manufacturer data already cited in the repository
  (data/bc_gelistirme/bc_less_mapping.csv, lib/data/factory_ammo_library.dart
  source URLs).

Run: python3 tools/denetim_2026_10_15c_diger.py
"""
from __future__ import annotations

import csv
import math
import sys
from decimal import ROUND_HALF_EVEN, Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import formula_reference as fr  # noqa: E402

FT_M = 0.3048


# ---------------------------------------------------------------- RUZ (#335)
GUST = 1.5


def dart_fixed1(x: float) -> str:
    """Dart toStringAsFixed(1) of a double (exact binary value)."""
    return str(Decimal(x).quantize(Decimal("0.1"), rounding=ROUND_HALF_EVEN))


def wind_text_changed(before: str, after: str) -> bool:
    """Mirror of _BallisticsScreenState._windTextChanged (#335): numbers,
    "," or ".", a change only beyond the fill's 0.05 rounding."""
    def n(t: str):
        try:
            return float(t.strip().replace(",", "."))
        except ValueError:
            return None
    a, b = n(before), n(after)
    if a is None or b is None:
        return (a is None) != (b is None)
    return abs(a - b) > 0.05 + 1e-9


# ---------------------------------------------------- powder temperature (#355)
def powder_factor(k, t0, today):
    if k is None or t0 is None:
        return 1.0
    if abs(k) > 10 or t0 < -50 or t0 > 60:
        return 1.0
    f = 1 + k / 100 * (today - t0) / 15
    return f if f > 0 else 1.0


def effective_temp(air_c: float, ammo_c):
    """Empty (None) or outside -50..60 °C: the air temperature."""
    if ammo_c is None or not math.isfinite(ammo_c) or ammo_c < -50 or ammo_c > 60:
        return air_c
    return ammo_c


def hedef_fps(v0_fps, k, t0, air_c=None, ammo_c=None):
    """Velocity Hedef shoots with; an empty Sıcaklık is 15 °C (ICAO)."""
    air = 15.0 if air_c is None else air_c
    return v0_fps * powder_factor(k, t0, effective_temp(air, ammo_c))


# ------------------------------------------------------------ İrtifa (#356)
def isa_pressure_hpa(h_m: float) -> float:
    return 1013.25 * (1 - 2.25577e-5 * h_m) ** 5.25588


def legacy_altitude_shown(weather: dict, altitude_source=None):
    """Which saved value the one İrtifa box shows (#356 load rule)."""
    new_format = altitude_source is not None
    from_map_key = new_format or weather.get("mapAltitude") is not None
    return weather.get("mapAltitude") if from_map_key else weather.get("altitude")


# --------------------------------------------------------------- KUL-10 (#338)
ENV = fr.Env(15.0, 1013.25, 50.0)  # Hız Doğrulama default air


def correction(v_mps: float, bc: float, range_m: float, *, grain=18.0,
               cal_in=5.5 / 25.4, zero_m=30.0, sight_mm=50.0) -> float:
    sc = fr.Scenario("k10", "g1", bc, grain, cal_in, v_mps, zero_m, sight_mm,
                     (range_m,), env=ENV)
    return fr.solve(sc)[0].correction_mrad


def trued_bc(observed_mrad: float, v_mps: float, range_m: float, **kw) -> float:
    """BC that makes the solver at [v_mps] give [observed_mrad] (bisection;
    a higher BC drops less)."""
    lo, hi = 0.005, 0.5
    for _ in range(60):
        mid = (lo + hi) / 2
        if correction(v_mps, mid, range_m, **kw) > observed_mrad:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def kul10_example():
    """Regulator-less PCP, table 120 bar 255 m/s / 200 bar 270 m/s, Tüp
    basıncı 120 bar, Profil Namlu çıkış hızı 270 m/s, 18 gr pellet G1 0.031,
    zero 30 m, sight 50 mm. Hedef zeroes and shoots with the table velocity
    255 m/s (Denetim F3). The shooter's true observation at 100 m is the
    255 m/s shot; Hız Doğrulama solves BC with the profile 270 m/s."""
    true_bc, v_table, v_profile = 0.031, 255.0, 270.0
    observed = correction(v_table, true_bc, 100.0)
    bc_app = trued_bc(observed, v_profile, 100.0)
    rows = []
    for r in (50.0, 75.0, 100.0):
        rows.append((r, correction(v_table, true_bc, r),
                     correction(v_table, bc_app, r)))
    return observed, bc_app, rows


# ---------------------------------------------------------- MUH (#345) data
def mapping_row(row_id: str) -> dict:
    path = ROOT / "data" / "bc_gelistirme" / "bc_less_mapping.csv"
    with path.open(encoding="utf-8") as fh:
        for row in csv.reader(fh):
            if row and row[0] == row_id:
                return {"id": row[0], "brand": row[1], "name": row[2],
                        "url": row[11], "table": row[13]}
    raise KeyError(row_id)


def main() -> int:
    print("RUZ: 5.0 x 1.5 =", dart_fixed1(5.0 * GUST),
          "| '5' vs '5.0' changed:", wind_text_changed("5", "5.0"),
          "| '5.0' vs '0.0' changed:", wind_text_changed("5.0", "0.0"))
    print("Powder 2650 fps, k 1.5 %/15 °C, T0 21 °C:",
          "air 5 °C, ammo empty -> %.2f fps;" % hedef_fps(2650, 1.5, 21, 5),
          "ammo 30 °C -> %.2f fps;" % hedef_fps(2650, 1.5, 21, 5, 30),
          "both empty -> %.2f fps" % hedef_fps(2650, 1.5, 21))
    print("ISA 1500 m: %.2f hPa" % isa_pressure_hpa(1500))
    obs, bc, rows = kul10_example()
    print("KUL-10: observed 100 m %.4f mrad, trued BC %.4f (%.1f %%)" %
          (obs, bc, (bc / 0.031 - 1) * 100))
    for r, good, app in rows:
        print("   %3.0f m: true %.3f mrad, Hedef after truing %.3f (+%.3f)" %
              (r, good, app, app - good))
    fa007 = mapping_row("FA007")
    print("MUH-2 FA007 maker page:", fa007["table"], fa007["url"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
