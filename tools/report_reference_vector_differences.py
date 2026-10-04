#!/usr/bin/env python3
"""Diagnostic-only comparison of a py-ballisticcalc fixture against the Python
port of SNIPER TÜRK's no-wind solver.

This tool NEVER opens the production gate and is NOT the official Dart
acceptance comparator. It exists so an incoming independent fixture can be
triaged per case/range before Flutter/Dart is available.
"""
from __future__ import annotations
import json, math, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import offline_solver_crosscheck as osc  # noqa: E402
from validate_py_ballisticcalc_fixture import validate  # noqa: E402

DEFAULT_FIXTURE = ROOT / "validation" / "py_ballisticcalc_vectors.json"
POLICY = ROOT / "validation" / "acceptance.json"


def fail(msg: str) -> "NoReturn":
    print(f"reference difference report FAILED: {msg}", file=sys.stderr)
    raise SystemExit(2)


def main() -> None:
    fixture = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else DEFAULT_FIXTURE
    if len(sys.argv) > 2:
        fail("usage: report_reference_vector_differences.py [FIXTURE.json]")
    errors = validate(fixture, POLICY)
    if errors:
        fail("fixture contract rejected: " + "; ".join(errors))
    data = json.loads(fixture.read_text(encoding="utf-8"))
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    tol = policy["tolerances"]
    tables = osc.load_tables()
    failures = 0
    compared = 0
    worst = {"h": 0.0, "v": 0.0, "t": 0.0}
    print("DIAGNOSTIC ONLY — Python solver port; official Dart acceptance still required")
    for case in data["cases"]:
        atmosphere = data["atmospheres"][case["atmosphere"]]
        air = osc.Air(atmosphere["temperature_c"], atmosphere["pressure_hpa"], atmosphere["humidity_percent"])
        model = case["model"].lower()
        f = osc.make_accel(tables[model], case["bc"], air)
        refs = case["points"]
        ranges = [float(p["range_m"]) for p in refs]
        _, actual = osc.dart_style(f, case["mv"], case["sight_mm"] / 1000.0, case["zero"], ranges, 0.0005)
        print(f"\n{case['id']} ({case['model']}, {case['atmosphere']})")
        print("range_m,dh_m,dv_mps,dt_s,status")
        for r, ref, got in zip(ranges, refs, actual):
            # Dart solver stores positive drop = -trajectory height.
            dh = abs(got["drop"] + float(ref["height_m"]))
            dv = abs(got["v"] - float(ref["velocity_mps"]))
            dt = abs(got["t"] - float(ref["time_s"]))
            bad = dh > tol["height_m_absolute"] or dv > tol["velocity_mps_absolute"] or dt > tol["time_s_absolute"]
            failures += int(bad); compared += 1
            worst["h"] = max(worst["h"], dh); worst["v"] = max(worst["v"], dv); worst["t"] = max(worst["t"], dt)
            print(f"{r:.3f},{dh:.9g},{dv:.9g},{dt:.9g},{'FAIL' if bad else 'PASS'}")
    print(f"\nsummary: {compared} points, {failures} outside frozen tolerances; "
          f"worst dh={worst['h']:.9g}m dv={worst['v']:.9g}m/s dt={worst['t']:.9g}s")
    print("gate action: NONE (diagnostic tool cannot open or modify the production gate)")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
