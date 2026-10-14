#!/usr/bin/env python3
"""Independent reference for "BC modeli seçimi" (docs/reports/bc_modeli_secim.md,
owner 2026-10-14 11:38: "G değerleri seçildiğinde kesinlikle formüle
eklenmeli, bunun doğruluğunu kontrol et").

The same shot with the same BC is solved once per standard drag law (G1, G2,
G5, G6, G7, G8, GI, GS, RA4) with the world-frame point-mass reference of
tools/formul_denetimi_2026_10_14.py (written from McCoy's equations, not from
the app's Dart code and not from another ballistic program). Each run reads
only the table of its own model, so test/bc_modeli_secim_test.dart catching
a fallback (for example every model silently flown as G1) is what this
checks. Whether the table VALUES equal the BRL originals is a separate
question; see the report.

Standard library only. Run:

    python3 tools/bc_modeli_referans.py           # summary
    python3 tools/bc_modeli_referans.py --dart    # Dart vectors
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

_HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "formul_denetimi_2026_10_14", _HERE / "formul_denetimi_2026_10_14.py")
ref = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = ref
_spec.loader.exec_module(ref)

MODELS = ["g1", "g2", "g5", "g6", "g7", "g8", "gi", "gs", "ra4"]

# (name, Shot kwargs without model, ranges)
CASES = [
    # .25 PCP slug, BC 0.110, 290 m/s, 3 m/s from saat 9 (90 deg).
    ("pcp", dict(v0=290.0, bc=0.110, sight_m=0.050, zero_m=50.0,
                 wind_mps=3.0, wind_deg=90.0), [100.0, 150.0]),
    # .308 class, BC 0.462, 2650 fps, 10 mph from saat 3 (270 deg).
    ("firearm", dict(v0=2650 * ref.FOOT_M, bc=0.462, sight_m=0.0381,
                     zero_m=100.0, wind_mps=10 * ref.MPH_MPS, wind_deg=270.0),
     [300.0, 600.0]),
]


def vectors():
    out = {}
    for name, kw, ranges in CASES:
        for m in MODELS:
            out[(name, m)] = ref.solve(ref.Shot(model=m, **kw), ranges)
    return out


def main(argv):
    vec = vectors()
    if "--dart" in argv:
        for (name, m), pts in vec.items():
            print(f"  ('{name}', BallisticModel.{m}, [")
            for p in pts:
                print(f"    ({p.range_m:.0f}, {p.correction_mrad:.4f}, "
                      f"{p.wind_mrad:.4f}, {p.tof_s:.5f}),")
            print("  ]),")
        return 0
    for (name, m), pts in vec.items():
        for p in pts:
            print(f"{name:8s} {m:4s} {p.range_m:5.0f} m  up {p.correction_mrad:8.4f}"
                  f"  wind {p.wind_mrad:8.4f}  tof {p.tof_s:.5f}  v {p.speed:6.1f}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
