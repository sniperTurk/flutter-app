#!/usr/bin/env python3
"""Generate the separate wind acceptance vectors with py-ballisticcalc.

Inputs, conventions and tolerances come from validation/wind_acceptance.json,
which was frozen before any wind output existed. Must run inside the
hash-verified validator venv created by bootstrap_reference_validator.py.
"""
from __future__ import annotations

import importlib.metadata
import json
import os
import sys
import tempfile
from pathlib import Path

from generate_reference_vectors import PIN, fail, load_acceptance, verify_bootstrap_receipt

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "validation" / "wind_acceptance.json"
OUT = ROOT / "validation" / "py_ballisticcalc_wind_vectors.json"


def load_wind_policy() -> dict:
    try:
        policy = json.loads(POLICY.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"could not read wind acceptance policy: {exc}")
    ref = policy.get("reference", {})
    if ref.get("package") != "py-ballisticcalc" or ref.get("version") != PIN:
        fail("wind acceptance policy does not match the pinned validator")
    if ref.get("engine") != "rk4_engine":
        fail("wind acceptance policy must pin rk4_engine")
    cases = policy.get("cases")
    if not isinstance(cases, list) or len(cases) < 4:
        fail("wind acceptance policy must declare at least four cases")
    return policy


def main() -> None:
    acceptance = load_acceptance()
    verify_bootstrap_receipt(acceptance)
    policy = load_wind_policy()
    version = importlib.metadata.version("py-ballisticcalc")
    if version != PIN:
        fail(f"expected py-ballisticcalc=={PIN}, found {version}")
    try:
        from py_ballisticcalc import (  # type: ignore
            Ammo, Angular, Atmo, Calculator, Distance, DragModel, Pressure, Shot,
            TableG1, TableG7, Temperature, Velocity, Weapon, Wind,
        )
    except Exception as exc:
        fail(f"pinned package API could not be imported: {exc}")

    output = {
        "schema": 1,
        "generator": "py-ballisticcalc",
        "version": version,
        "engine": "rk4_engine",
        "policy": policy,
        "cases": [],
    }
    for c in policy["cases"]:
        table = TableG1 if c["model"] == "G1" else TableG7
        atmo_def = policy["atmospheres"][c["atmosphere"]]
        if c["atmosphere"] == "icao":
            atmosphere = Atmo.icao()
        else:
            atmosphere = Atmo(
                altitude=Distance.Meter(atmo_def["altitude_m"]),
                pressure=Pressure.hPa(atmo_def["pressure_hpa"]),
                temperature=Temperature.Celsius(atmo_def["temperature_c"]),
                humidity=atmo_def["humidity_percent"],
            )
        dm = DragModel(c["bc"], table, weight=c["grain"])
        ammo = Ammo(dm, mv=Velocity.MPS(c["mv"]))
        # twist = 0 disables the Litz spin-drift term, so windage is wind only.
        weapon = Weapon(sight_height=Distance.Millimeter(c["sight_mm"]), twist=0)
        calc = Calculator(engine="rk4_engine")
        # Zero in still air (same as SNIPER TÜRK's separate zero environment).
        calc.set_weapon_zero(Shot(weapon=weapon, ammo=ammo, atmo=atmosphere), Distance.Meter(c["zero"]))
        direction_from = (180.0 - c["wind_direction_deg"]) % 360.0
        wind = Wind(velocity=Velocity.MPS(c["wind_mps"]), direction_from=Angular.Degree(direction_from))
        shot = Shot(weapon=weapon, ammo=ammo, atmo=atmosphere, winds=[wind])
        hit = calc.fire(shot, trajectory_range=Distance.Meter(max(c["ranges"])), trajectory_step=Distance.Meter(1))
        points = []
        for r in c["ranges"]:
            p = hit.get_at("distance", Distance.Meter(r))
            points.append({
                "range_m": r,
                "windage_m": p.windage >> Distance.Meter,
                "height_m": p.height >> Distance.Meter,
                "velocity_mps": p.velocity >> Velocity.MPS,
                "time_s": p.time,
            })
        output["cases"].append({"id": c["id"], "py_direction_from_deg": direction_from, "points": points})

    OUT.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=OUT.parent, prefix=f".{OUT.name}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, sort_keys=True, allow_nan=False)
            f.write("\n")
        os.replace(tmp, OUT)
    except (OSError, ValueError) as exc:
        Path(tmp).unlink(missing_ok=True)
        fail(f"could not write wind fixture: {exc}")
    print(f"wrote wind fixture {OUT}")


if __name__ == "__main__":
    main()
