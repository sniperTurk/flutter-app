import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class V194DopeRangeLimitContractTest(unittest.TestCase):
    def test_dope_parser_uses_central_production_limit(self):
        text = (ROOT / "lib/core/dope_ranges.dart").read_text()
        self.assertIn("import 'production_limits.dart';", text)
        self.assertIn("double maxRangeM = ProductionLimits.maxRangeM", text)
        self.assertNotIn("maxRangeM = 2000", text)

    def test_ui_converts_canonical_limit_for_imperial_display(self):
        text = (ROOT / "lib/features/ballistics/ballistics_screen.dart").read_text()
        self.assertIn("UnitSystem.metersToYards(ProductionLimits.maxRangeM)", text)
        self.assertIn("maxRangeM: displayMaxRange", text)

    def test_dart_regression_covers_3000m_boundary(self):
        text = (ROOT / "test/dope_ranges_test.dart").read_text()
        self.assertIn("DopeRanges.parse('3000')", text)
        self.assertIn("DopeRanges.parse('3000.1')", text)

if __name__ == '__main__':
    unittest.main()
