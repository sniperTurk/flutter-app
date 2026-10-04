#!/usr/bin/env python3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class ScopeLowerBoundIntegrityContractTest(unittest.TestCase):
    def test_integrity_rejects_orphan_lower_bound_flags(self):
        text = (ROOT / "lib/data/catalog_integrity.dart").read_text(encoding="utf-8")
        self.assertIn("elevationRangeIsLowerBound && s.elevationRangeMrad == null", text)
        self.assertIn("windageRangeIsLowerBound && s.windageRangeMrad == null", text)
        self.assertIn("elevationRangeIsLowerBound requires elevationRangeMrad", text)
        self.assertIn("windageRangeIsLowerBound requires windageRangeMrad", text)

    def test_dart_regression_covers_invalid_and_valid_semantics(self):
        text = (ROOT / "test/catalog_integrity_test.dart").read_text(encoding="utf-8")
        self.assertIn("scope lower-bound provenance cannot exist without a published range", text)
        self.assertIn("scope lower-bound provenance is valid when the published ranges exist", text)
        self.assertIn("elevationRangeIsLowerBound: true", text)
        self.assertIn("windageRangeIsLowerBound: true", text)

if __name__ == "__main__":
    unittest.main()
