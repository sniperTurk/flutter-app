#!/usr/bin/env python3
"""Regression contract for cwd-independent G1/G7 reference comparison."""
from __future__ import annotations
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "compare_reference_vectors.dart"

class ReferenceComparatorPathTest(unittest.TestCase):
    def test_validation_inputs_are_resolved_from_script_location(self) -> None:
        text = SOURCE.read_text(encoding="utf-8")
        self.assertIn("File.fromUri(Platform.script).absolute", text)
        self.assertIn("final root = toolFile.parent.parent;", text)
        self.assertIn("File('${root.path}/validation/acceptance.json')", text)
        self.assertIn("File('${root.path}/validation/py_ballisticcalc_vectors.json')", text)
        self.assertNotIn("File('validation/acceptance.json')", text)
        self.assertNotIn("File('validation/py_ballisticcalc_vectors.json')", text)

if __name__ == "__main__":
    unittest.main()
