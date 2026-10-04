#!/usr/bin/env python3
"""Generate independent G1/G7 reference vectors with py-ballisticcalc.

This helper intentionally lives outside the Dart solver. It refuses to emit a
fixture when the pinned independent dependency is absent or has the wrong
version, so an unavailable validator can never be mistaken for a pass.
"""
from __future__ import annotations
import importlib.metadata
import json
import os
import sys
import tempfile
from pathlib import Path

from validate_py_ballisticcalc_fixture import FROZEN_ATMOSPHERES, FROZEN_CASES, validate

PIN = "2.2.10"
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "validation" / "py_ballisticcalc_vectors.json"
ACCEPTANCE = ROOT / "validation" / "acceptance.json"


def fail(message: str) -> "NoReturn":
    print(f"reference-vector generation FAILED: {message}", file=sys.stderr)
    raise SystemExit(2)


def load_acceptance() -> dict:
    try:
        data = json.loads(ACCEPTANCE.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"could not read acceptance policy: {exc}")
    ref = data.get("reference", {})
    if ref.get("package") != "py-ballisticcalc" or ref.get("version") != PIN:
        fail("acceptance policy does not match the pinned independent validator")
    dependencies = ref.get("dependencies")
    if not isinstance(dependencies, dict) or not dependencies:
        fail("acceptance policy is missing pinned validator dependencies")
    for name, spec in dependencies.items():
        if not isinstance(name, str) or not isinstance(spec, dict):
            fail("validator dependency locks are invalid")
        expected_version = spec.get("version")
        expected_hash = spec.get("wheel_sha256")
        if (not isinstance(expected_version, str) or not expected_version or
                not isinstance(expected_hash, str) or len(expected_hash) != 64 or
                any(c not in "0123456789abcdef" for c in expected_hash)):
            fail(f"validator dependency lock for {name} is incomplete")
        try:
            actual_version = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            fail(f"pinned validator dependency {name} is not installed")
        if actual_version != expected_version:
            fail(
                f"validator dependency drift for {name}: "
                f"expected {expected_version}, got {actual_version}"
            )
    requirements = data.get("requirements", {})
    if requirements.get("require_model_atmosphere_cross_product") is not True:
        fail("acceptance policy must require every model-atmosphere validation pair")
    tolerances = data.get("tolerances", {})
    required = {"height_m_absolute", "velocity_mps_absolute", "time_s_absolute"}
    if set(tolerances) != required or any(not isinstance(v, (int, float)) or v <= 0 for v in tolerances.values()):
        fail("acceptance tolerances are missing or invalid")
    return data


def verify_bootstrap_receipt(acceptance: dict) -> None:
    expected_venv = (ROOT / ".validator_venv").resolve()
    actual_prefix = Path(sys.prefix).resolve()
    if actual_prefix != expected_venv:
        fail(f"reference generation must run with {expected_venv} Python; got {actual_prefix}")
    receipt_path = expected_venv / "sniper_turk_validator_receipt.json"
    try:
        receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"hash-verified bootstrap receipt is missing or unreadable: {exc}")
    ref = acceptance["reference"]
    expected = {
        "schema": 1,
        "package": ref["package"],
        "version": ref["version"],
        "wheel_sha256": ref["wheel_sha256"],
        "dependencies": ref["dependencies"],
    }
    if receipt != expected:
        fail("bootstrap receipt does not exactly match acceptance policy")


def main() -> None:
    acceptance = load_acceptance()
    verify_bootstrap_receipt(acceptance)
    try:
        version = importlib.metadata.version("py-ballisticcalc")
    except importlib.metadata.PackageNotFoundError:
        fail(f"py-ballisticcalc=={PIN} is required; no fixture was written")
    if version != PIN:
        fail(f"expected py-ballisticcalc=={PIN}, found {version}; no fixture was written")

    # Import only after the version gate so dependency failures are explicit.
    try:
        from py_ballisticcalc import (  # type: ignore
            Ammo, Atmo, Calculator, Distance, DragModel, Shot,
            Pressure, TableG1, TableG7, Temperature, Velocity, Weapon,
        )
    except Exception as exc:
        fail(f"pinned package API could not be imported: {exc}")

    # Keep the initial acceptance set intentionally simple and no-wind. Wind
    # convention equivalence must be established separately before wind vectors
    # become an activation criterion.
    # Acceptance inputs are sourced from the canonical validator contract so
    # generator and validator cannot silently drift between CI runs.
    cases = [
        {"id": case_id, **{k: v for k, v in spec.items() if k != "ranges"}}
        for case_id, spec in FROZEN_CASES.items()
    ]
    ranges_by_case = {case_id: list(spec["ranges"]) for case_id, spec in FROZEN_CASES.items()}
    output = {
        "schema": 1,
        "generator": "py-ballisticcalc",
        "version": version,
        "engine": "rk4_engine",
        "acceptance": acceptance,
        "atmospheres": {name: dict(values) for name, values in FROZEN_ATMOSPHERES.items()},
        "cases": [],
    }

    for c in cases:
        table = TableG1 if c["model"] == "G1" else TableG7
        ranges = ranges_by_case[c["id"]]
        # py-ballisticcalc attaches projectile weight to DragModel, not Ammo.
        # Supplying it here also keeps the independent reference's projectile
        # metadata aligned with the SNIPER TÜRK input vector.
        dm = DragModel(c["bc"], table, weight=c["grain"])
        ammo = Ammo(dm, mv=Velocity.MPS(c["mv"]))
        weapon = Weapon(sight_height=Distance.Millimeter(c["sight_mm"]))
        if c["atmosphere"] == "icao":
            atmosphere = Atmo.icao()
        else:
            # Explicit non-standard condition; values are frozen before reference output.
            frozen_atmo = FROZEN_ATMOSPHERES[c["atmosphere"]]
            atmosphere = Atmo(
                altitude=Distance.Meter(frozen_atmo["altitude_m"]),
                pressure=Pressure.HPa(frozen_atmo["pressure_hpa"]),
                temperature=Temperature.Celsius(frozen_atmo["temperature_c"]),
                humidity=frozen_atmo["humidity_percent"],
            )
        shot = Shot(weapon=weapon, ammo=ammo, atmo=atmosphere)
        # Pin the engine explicitly. Relying on the package default would make
        # reference vectors vulnerable to a future default-engine change even
        # when the package/API remains otherwise compatible.
        calc = Calculator(engine="rk4_engine")
        # set_weapon_zero accepts the configured Shot and target distance and
        # mutates the weapon's zero elevation.  Passing Weapon/Ammo separately
        # is not the py-ballisticcalc 2.2.x API.
        calc.set_weapon_zero(shot, Distance.Meter(c["zero"]))
        hit = calc.fire(
            shot,
            trajectory_range=Distance.Meter(max(ranges)),
            trajectory_step=Distance.Meter(1),
        )
        points = []
        for r in ranges:
            p = hit.get_at(Distance.Meter(r))
            points.append({
                "range_m": r,
                "height_m": p.height >> Distance.Meter,
                "velocity_mps": p.velocity >> Velocity.MPS,
                "time_s": p.time,
            })
        output["cases"].append({**c, "points": points})

    # Publish the independently generated fixture transactionally. A failed or
    # malformed generation must never truncate/replace the last known-good
    # fixture that a developer may be inspecting locally. JSON's default NaN
    # extension is disabled because the acceptance contract requires finite
    # numeric values. Validate the complete temporary file with the canonical
    # validator before the atomic replace.
    OUT.parent.mkdir(parents=True, exist_ok=True)
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=OUT.parent,
            prefix=f".{OUT.name}.", suffix=".tmp", delete=False,
        ) as temp:
            temp_path = Path(temp.name)
            json.dump(output, temp, indent=2, sort_keys=True, allow_nan=False)
            temp.write("\n")
            temp.flush()
            os.fsync(temp.fileno())
        errors = validate(temp_path)
        if errors:
            fail("generated fixture failed canonical validation: " + "; ".join(errors))
        os.replace(temp_path, OUT)
        temp_path = None
    except (OSError, ValueError) as exc:
        fail(f"could not publish validated reference fixture: {exc}")
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)
    print(f"wrote validated fixture {OUT}")


if __name__ == "__main__":
    main()
