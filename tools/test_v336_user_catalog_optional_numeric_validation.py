#!/usr/bin/env python3
"""Regression contract for optional user-rifle numeric fields."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class UserCatalogOptionalNumericValidationTest(unittest.TestCase):
    def test_optional_rifle_numeric_fields_are_validated_before_domain_cast(self) -> None:
        text = (ROOT / "lib/services/user_catalog_store.dart").read_text(encoding="utf-8")
        self.assertIn("'barrelLengthMm', 'airCapacityCc'", text)
        self.assertIn("value is! num || !value.isFinite || value <= 0", text)

    def test_dart_regressions_cover_corrupt_optional_numeric_values(self) -> None:
        text = (ROOT / "test/user_catalog_store_test.dart").read_text(encoding="utf-8")
        self.assertIn("invalid optional rifle numeric fields fail closed", text)
        self.assertIn("'barrelLengthMm': '800'", text)
        self.assertIn("'airCapacityCc': -1", text)


if __name__ == "__main__":
    unittest.main()
