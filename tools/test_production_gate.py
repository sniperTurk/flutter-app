#!/usr/bin/env python3
"""Regression tests for the production G1/G7 gate verifier.

The gate is open only while the engine routes aerodynamic requests to the
validated solver AND CI still runs the independent reference comparison.
"""
from __future__ import annotations
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock
import verify_production_gate as gate

ENGINE = """import 'aerodynamic_trajectory_solver.dart';
List solve(input) {
  if (input.ballisticModel != null || input.ballisticCoefficient != null) {
    return const AerodynamicTrajectorySolver().solve(input);
  }
  return solveVacuum(input);
}
"""
WORKFLOW = "\n".join(gate.REQUIRED_WORKFLOW_STEPS) + "\n"
POLICY = {"requirements": {"models": ["G1", "G7"], "production_gate_must_remain_closed_until_comparison_passes": True, "require_model_atmosphere_cross_product": True}}


class ProductionGateTests(unittest.TestCase):
    def _run(self, engine=ENGINE, policy=POLICY, workflow=WORKFLOW):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "lib/core").mkdir(parents=True)
            (root / "validation").mkdir()
            (root / ".github/workflows").mkdir(parents=True)
            engine_path = root / "lib/core/ballistic_engine.dart"
            policy_path = root / "validation/acceptance.json"
            workflow_path = root / ".github/workflows/ios-ci.yml"
            engine_path.write_text(engine, encoding="utf-8")
            workflow_path.write_text(workflow, encoding="utf-8")
            if isinstance(policy, str):
                policy_path.write_text(policy, encoding="utf-8")
            else:
                policy_path.write_text(json.dumps(policy), encoding="utf-8")
            with mock.patch.object(gate, "ROOT", root), mock.patch.object(gate, "ENGINE", engine_path), \
                    mock.patch.object(gate, "ACCEPTANCE", policy_path), mock.patch.object(gate, "WORKFLOW", workflow_path):
                return gate.verify()

    def test_valid_open_gate_with_ci_comparison_passes(self):
        self.assertEqual(self._run(), [])

    def test_formatting_does_not_matter(self):
        engine = ENGINE.replace("solve(input);\n  }", "solve(\n      input,\n    );\n  }")
        self.assertEqual(self._run(engine=engine), [])
        self.assertEqual(self._run(policy=json.dumps(POLICY, indent=4, sort_keys=True)), [])

    def test_malformed_policy_fails_closed(self):
        self.assertTrue(self._run(policy="{bad json"))

    def test_false_gate_policy_fails(self):
        p = json.loads(json.dumps(POLICY))
        p["requirements"]["production_gate_must_remain_closed_until_comparison_passes"] = False
        self.assertTrue(self._run(policy=p))

    def test_missing_cross_product_policy_fails(self):
        p = json.loads(json.dumps(POLICY))
        p["requirements"].pop("require_model_atmosphere_cross_product")
        self.assertTrue(self._run(policy=p))

    def test_engine_falling_back_to_vacuum_for_drag_fails(self):
        engine = ENGINE.replace("return const AerodynamicTrajectorySolver().solve(input);", "return solveVacuum(input);")
        self.assertTrue(self._run(engine=engine))

    def test_vacuum_before_aerodynamic_fails(self):
        engine = """import 'aerodynamic_trajectory_solver.dart';
List solve(input) {
  return solveVacuum(input);
  if (input.ballisticModel != null || input.ballisticCoefficient != null) {
    return const AerodynamicTrajectorySolver().solve(input);
  }
}
"""
        self.assertTrue(self._run(engine=engine))

    def test_old_closed_gate_rejection_is_reported(self):
        engine = ENGINE + "throw UnsupportedError('G1/G7 drag solver is not validated yet; aerodynamic DOPE is unavailable.');\n"
        self.assertTrue(self._run(engine=engine))

    def test_removing_a_ci_comparison_step_fails(self):
        for step in gate.REQUIRED_WORKFLOW_STEPS:
            with self.subTest(step=step):
                self.assertTrue(self._run(workflow=WORKFLOW.replace(step, "")))

    def test_missing_workflow_fails(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "lib/core").mkdir(parents=True)
            (root / "validation").mkdir()
            (root / "lib/core/ballistic_engine.dart").write_text(ENGINE, encoding="utf-8")
            (root / "validation/acceptance.json").write_text(json.dumps(POLICY), encoding="utf-8")
            with mock.patch.object(gate, "ROOT", root), \
                    mock.patch.object(gate, "ENGINE", root / "lib/core/ballistic_engine.dart"), \
                    mock.patch.object(gate, "ACCEPTANCE", root / "validation/acceptance.json"), \
                    mock.patch.object(gate, "WORKFLOW", root / "missing.yml"):
                self.assertTrue(gate.verify())


if __name__ == "__main__":
    unittest.main()
