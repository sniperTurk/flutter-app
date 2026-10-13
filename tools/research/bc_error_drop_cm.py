"""Drop error (cm) caused by a relative G1 BC error, for the two example loads.

Research only (docs/research/tahmini_bc_hata.md). Uses the repository's
independent reference solver `tools/formula_reference.py` (G1 table from
lib/core/standard_drag_tables.dart, point mass, ICAO atmosphere, 100 m zero).
For each error e the "true" BC is the nominal one and the app's estimate is
BC·(1−e) (under-estimate) or BC·(1+e) (over-estimate); the table gives the
difference of the predicted drop at 100/300/500 m.
Run: python3 -I tools/research/bc_error_drop_cm.py [e1 e2 ...]  (fractions)
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import formula_reference as fr  # noqa: E402

RANGES = (100.0, 200.0, 300.0, 500.0)
LOADS = {
    # .277 130 gr: G1 0.44 is the median of the 29 .277 125–135 gr bullets in
    # lib/data/bullet_library.dart; 45 mm sight height.
    "firearm .277 130 gr G1 0.44, 3000 fps": dict(model="g1", bc=0.44, grain=130.0, caliber_in=0.277,
                                                 mv_mps=3000 * fr.FOOT_M, zero_m=100.0, sight_mm=45.0),
    # 6.35 mm 50 gr slug: SD 0.1143 / i 0.825 = 0.139 → 0.140; 50 mm sight height.
    "PCP 6.35 mm 50 gr slug G1 0.140, 985 fps": dict(model="g1", bc=0.140, grain=50.0, caliber_in=0.25,
                                                    mv_mps=985 * fr.FOOT_M, zero_m=100.0, sight_mm=50.0),
}


def drops_cm(load: dict, bc: float) -> list[float]:
    sc = fr.Scenario("x", **dict(load, bc=bc), ranges=RANGES)
    return [p.correction_mrad * p.range_m / 10.0 for p in fr.solve(sc)]  # mrad·m/10 = cm


def table(errors: list[float]) -> dict:
    out = {}
    for name, load in LOADS.items():
        base = drops_cm(load, load["bc"])
        out[name] = {}
        for e in errors:
            lo = drops_cm(load, load["bc"] * (1 - e))
            hi = drops_cm(load, load["bc"] * (1 + e))
            out[name][e] = [(abs(a - b), abs(c - b)) for a, b, c in zip(lo, base, hi)]
    return out


def main():
    errors = [float(x) for x in sys.argv[1:]] or [0.02, 0.05, 0.08, 0.10, 0.13, 0.16, 0.20, 0.25, 0.30, 0.35, 0.45, 0.80]
    for name, rows in table(errors).items():
        print(f"\n{name}  (|drop change| cm: BC over-estimated … under-estimated)")
        print("  error   " + "  ".join(f"{int(r):>4d} m      " for r in RANGES))
        for e, cells in rows.items():
            print(f"  {e*100:4.0f} %  " + "  ".join(f"{hi:5.1f}–{lo:5.1f}" for lo, hi in cells))


if __name__ == "__main__":
    main()
