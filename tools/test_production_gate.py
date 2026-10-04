#!/usr/bin/env python3
"""Regression tests for the production G1/G7 fail-closed verifier."""
from __future__ import annotations
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock
import verify_production_gate as gate

ENGINE = """if (input.ballisticModel != null || input.ballisticCoefficient != null) {\n  throw UnsupportedError('G1/G7 drag solver is not validated yet; aerodynamic DOPE is unavailable.');\n}\n"""
POLICY = {"requirements": {"models": ["G1", "G7"], "production_gate_must_remain_closed_until_comparison_passes": True, "require_model_atmosphere_cross_product": True}}

class ProductionGateTests(unittest.TestCase):
    def _run(self, engine=ENGINE, policy=POLICY):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td); (root / "lib/core").mkdir(parents=True); (root / "validation").mkdir()
            engine_path = root / "lib/core/ballistic_engine.dart"; policy_path = root / "validation/acceptance.json"
            engine_path.write_text(engine, encoding="utf-8")
            if isinstance(policy, str): policy_path.write_text(policy, encoding="utf-8")
            else: policy_path.write_text(json.dumps(policy), encoding="utf-8")
            with mock.patch.object(gate, "ROOT", root), mock.patch.object(gate, "ENGINE", engine_path), mock.patch.object(gate, "ACCEPTANCE", policy_path):
                return gate.verify()

    def test_valid_closed_gate_passes(self): self.assertEqual(self._run(), [])
    def test_policy_formatting_does_not_matter(self):
        p = json.dumps(POLICY, indent=4, sort_keys=True)
        self.assertEqual(self._run(policy=p), [])
    def test_malformed_policy_fails_closed(self): self.assertTrue(self._run(policy="{bad json"))
    def test_false_gate_policy_fails(self):
        p = json.loads(json.dumps(POLICY)); p["requirements"]["production_gate_must_remain_closed_until_comparison_passes"] = False
        self.assertTrue(self._run(policy=p))
    def test_missing_cross_product_policy_fails(self):
        p = json.loads(json.dumps(POLICY)); p["requirements"].pop("require_model_atmosphere_cross_product")
        self.assertTrue(self._run(policy=p))
    def test_experimental_solver_import_fails(self): self.assertTrue(self._run(engine=ENGINE + "import 'aerodynamic_trajectory_solver.dart';\n"))
    def test_missing_rejection_path_fails(self): self.assertTrue(self._run(engine="void solve() {}\n"))

if __name__ == "__main__": unittest.main()
