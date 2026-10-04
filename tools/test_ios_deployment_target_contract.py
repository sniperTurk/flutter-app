#!/usr/bin/env python3
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class IosDeploymentTargetContractTest(unittest.TestCase):
    def test_preflight_requires_ios_15(self):
        text = (ROOT / "tools/app_store_preflight.py").read_text(encoding="utf-8")
        self.assertIn("EXPECTED_MIN_IOS = (15, 0)", text)
        self.assertIn("deployment target must be at least 15.0", text)

    def test_scaffold_contract_requires_ios_15(self):
        text = (ROOT / "tools/bootstrap_ios_scaffold.sh").read_text(encoding="utf-8")
        self.assertIn("< (15, 0)", text)
        self.assertNotIn("< (13, 0)", text)

if __name__ == "__main__":
    unittest.main()
