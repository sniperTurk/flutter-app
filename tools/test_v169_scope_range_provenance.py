import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOMAIN = ROOT / "lib/models/domain.dart"
CATALOG = ROOT / "lib/data/catalog_repository.dart"

class ScopeRangeProvenanceTests(unittest.TestCase):
    def test_scope_model_can_preserve_strict_lower_bound_semantics(self):
        text = DOMAIN.read_text(encoding="utf-8")
        self.assertIn("elevationRangeIsLowerBound", text)
        self.assertIn("windageRangeIsLowerBound", text)
        self.assertIn("this.elevationRangeIsLowerBound = false", text)
        self.assertIn("this.windageRangeIsLowerBound = false", text)

    def test_scff66_does_not_flatten_manufacturer_greater_than_ranges(self):
        text = CATALOG.read_text(encoding="utf-8")
        record = re.search(r"ScopeOptic\(\s*id:'vector-tauron-gen2-5-30-scff66'.*?\),", text, re.S)
        self.assertIsNotNone(record)
        value = record.group(0)
        self.assertIn("elevationRangeMrad:17.5", value)
        self.assertIn("windageRangeMrad:16", value)
        self.assertIn("elevationRangeIsLowerBound:true", value)
        self.assertIn("windageRangeIsLowerBound:true", value)
        self.assertIn("published as >17.5/>16 MIL", value)

    def test_scff68_existing_lower_bounds_are_also_marked(self):
        text = CATALOG.read_text(encoding="utf-8")
        record = re.search(r"ScopeOptic\(\s*id:'vector-continental-x10-1-10-scff68'.*?\),", text, re.S)
        self.assertIsNotNone(record)
        value = record.group(0)
        self.assertIn("elevationRangeIsLowerBound:true", value)
        self.assertIn("windageRangeIsLowerBound:true", value)
        self.assertIn("ranges published as >30 MIL", value)

if __name__ == "__main__":
    unittest.main()
