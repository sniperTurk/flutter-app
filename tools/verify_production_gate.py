#!/usr/bin/env python3
"""Fail closed if unvalidated G1/G7 DOPE becomes reachable from BallisticEngine.

The gate is deliberately structural: it parses the acceptance policy as JSON
instead of grepping its formatting, and verifies that production code still
contains the explicit rejection path and has no dependency on the experimental
solver.  Malformed/missing policy is a hard failure.
"""
from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "lib/core/ballistic_engine.dart"
ACCEPTANCE = ROOT / "validation/acceptance.json"


def verify() -> list[str]:
    errors: list[str] = []
    try:
        source = ENGINE.read_text(encoding="utf-8")
    except OSError as exc:
        return [f"could not read {ENGINE.relative_to(ROOT)}: {exc}"]
    try:
        policy = json.loads(ACCEPTANCE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"could not parse {ACCEPTANCE.relative_to(ROOT)}: {exc}"]

    requirements = policy.get("requirements")
    if not isinstance(requirements, dict):
        errors.append("acceptance policy requirements object is missing")
        gate_required = None
    else:
        gate_required = requirements.get("production_gate_must_remain_closed_until_comparison_passes")
    if gate_required is not True:
        errors.append("acceptance policy does not explicitly require the production gate to remain closed")

    models = requirements.get("models") if isinstance(requirements, dict) else None
    if not isinstance(models, list) or set(models) != {"G1", "G7"}:
        errors.append("acceptance policy must require exactly G1 and G7 validation")

    cross_product = requirements.get("require_model_atmosphere_cross_product") if isinstance(requirements, dict) else None
    if cross_product is not True:
        errors.append("acceptance policy must require every model-atmosphere validation pair")

    required_markers = [
        "if (input.ballisticModel != null || input.ballisticCoefficient != null)",
        "throw UnsupportedError('G1/G7 drag solver is not validated yet; aerodynamic DOPE is unavailable.');",
    ]
    for marker in required_markers:
        if marker not in source:
            errors.append(f"missing fail-closed marker in {ENGINE.relative_to(ROOT)}: {marker}")

    if "aerodynamic_trajectory_solver.dart" in source or "AerodynamicTrajectorySolver" in source:
        errors.append("BallisticEngine directly references the experimental aerodynamic solver while gate policy is closed")
    return errors


def main() -> int:
    errors = verify()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Production G1/G7 gate: CLOSED (fail-closed contract verified)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
