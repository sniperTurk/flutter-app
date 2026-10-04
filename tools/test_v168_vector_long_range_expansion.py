import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'lib/data/catalog_repository.dart'


class VectorLongRangeExpansionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = CATALOG.read_text(encoding='utf-8')

    def test_v168_models_are_locked_to_manufacturer_values(self):
        expected = {
            'vector-continental-x6-5-30-vct-scff30': (
                'objectiveDiameterMm:56', 'clickValue:0.1', 'AngularUnit.mrad',
                'tubeDiameterMm:34', 'elevationRangeMrad:30',
                'windageRangeMrad:16', 'lengthMm:393', 'weightG:810',
                "reticle:'VCT-34 FFP'",
            ),
            'vector-tauron-gen2-5-30-scff66': (
                'objectiveDiameterMm:56', 'clickValue:0.1', 'AngularUnit.mrad',
                'tubeDiameterMm:30', 'elevationRangeMrad:17.5',
                'windageRangeMrad:16', 'lengthMm:394.5', 'weightG:924',
                "reticle:'MPX1'", 'elevationRangeIsLowerBound:true',
                'windageRangeIsLowerBound:true',
            ),
        }
        for scope_id, fields in expected.items():
            with self.subTest(scope_id=scope_id):
                match = re.search(r"ScopeOptic\(\s*id:'" + re.escape(scope_id) + r"'.*?\),", self.text, re.S)
                self.assertIsNotNone(match)
                record = match.group(0)
                for field in fields:
                    self.assertIn(field, record)
                self.assertIn("firstFocalPlane:true", record)
                self.assertIn("zeroStop:true", record)
                self.assertIn("sourceName:'Vector Optics'", record)
                self.assertIn('official', record)
                self.assertIn('verified 2026-09-27', record)

    def test_scope_ids_remain_unique(self):
        ids = re.findall(r"ScopeOptic\(\s*id:'([^']+)'", self.text)
        self.assertEqual(len(ids), len(set(ids)))


if __name__ == '__main__':
    unittest.main()
