#!/usr/bin/env python3
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
CI = ROOT / ".github" / "workflows" / "ios-ci.yml"
GEN = ROOT / "tools" / "generate_reference_vectors.py"

class ReferenceGeneratorVenvCIContract(unittest.TestCase):
    def test_ci_runs_generator_with_bootstrapped_validator_interpreter(self):
        text = CI.read_text(encoding="utf-8")
        self.assertIn("python3 tools/bootstrap_reference_validator.py", text)
        self.assertIn(".validator_venv/bin/python tools/generate_reference_vectors.py", text)
        self.assertNotIn("\n          python3 tools/generate_reference_vectors.py", text)

    def test_generator_requires_bootstrapped_validator_interpreter(self):
        text = GEN.read_text(encoding="utf-8")
        self.assertIn("actual_prefix = Path(sys.prefix).resolve()", text)
        self.assertIn("if actual_prefix != expected_venv", text)
        self.assertIn("verify_bootstrap_receipt(acceptance)", text)

if __name__ == "__main__":
    unittest.main()
