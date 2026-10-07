#!/usr/bin/env python3
"""Fail the build if G1/G7 DOPE is reachable without its validation evidence.

Opening the G1/G7 production gate is allowed only while all of these hold, and
the check is deliberately structural (policy parsed as JSON, formatting
independent):

* ``BallisticEngine.solve`` routes aerodynamic requests (ballistic coefficient
  or drag law present) to ``AerodynamicTrajectorySolver`` and never to the
  vacuum solver;
* the frozen acceptance policy still requires G1 and G7, the model x
  atmosphere cross product, and records that the gate depends on the
  comparison passing;
* the iOS CI workflow still runs the independent reference comparison
  (no-wind and wind) before anything is built.

Removing the comparison from CI, or letting the engine fall back to vacuum for
an aerodynamic request, fails this check. Malformed/missing policy is a hard
failure.
"""
from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "lib/core/ballistic_engine.dart"
ACCEPTANCE = ROOT / "validation/acceptance.json"
WORKFLOW = ROOT / ".github/workflows/ios-ci.yml"

REQUIRED_WORKFLOW_STEPS = (
    "tools/generate_reference_vectors.py",
    "dart run tools/compare_reference_vectors.dart",
    "tools/generate_wind_reference_vectors.py",
    "dart run tools/compare_wind_reference_vectors.dart",
)


def _squash(text: str) -> str:
    # Format-independent: dart format may wrap lines or add trailing commas.
    return "".join(text.split()).replace(",)", ")")


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
        "return const AerodynamicTrajectorySolver().solve(input);",
        "return solveVacuum(input);",
    ]
    squashed = _squash(source)
    for marker in required_markers:
        if _squash(marker) not in squashed:
            errors.append(f"missing routing marker in {ENGINE.relative_to(ROOT)}: {marker}")
    # The aerodynamic branch must come first: vacuum is only the no-BC path.
    aero = squashed.find(_squash("return const AerodynamicTrajectorySolver().solve(input);"))
    vac = squashed.find(_squash("return solveVacuum(input);"))
    if aero != -1 and vac != -1 and aero > vac:
        errors.append("aerodynamic routing must precede the vacuum fallback in BallisticEngine.solve")
    if "UnsupportedError('G1/G7 drag solver is not validated yet" in source:
        errors.append("the closed-gate rejection is still present in BallisticEngine")
    if "aerodynamic_trajectory_solver.dart" not in source:
        errors.append("BallisticEngine does not import the aerodynamic solver")

    try:
        workflow = WORKFLOW.read_text(encoding="utf-8")
    except OSError as exc:
        errors.append(f"could not read {WORKFLOW.relative_to(ROOT)}: {exc}")
        workflow = ""
    for step in REQUIRED_WORKFLOW_STEPS:
        if step not in workflow:
            errors.append(f"CI no longer runs the reference validation step: {step}")
    return errors


def main() -> int:
    errors = verify()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Production G1/G7 gate: OPEN only with CI reference comparison wired (contract verified)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
