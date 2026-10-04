import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'lib/data/catalog_repository.dart'

class VectorForesterParagonExpansionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = CATALOG.read_text(encoding='utf-8')

    def test_new_models_and_official_provenance(self):
        expected = {
            'vector-forester-2-10-scom02': ('objectiveDiameterMm:40', 'clickValue:0.25', 'AngularUnit.moa', 'weightG:500'),
            'vector-forester-3-15-scom16': ('objectiveDiameterMm:50', 'clickValue:0.25', 'AngularUnit.moa', 'weightG:575'),
            'vector-forester-jr-3-9-scom35': ('objectiveDiameterMm:40', 'clickValue:0.25', 'AngularUnit.moa', 'weightG:430'),
            'vector-paragon-gen2-3-15-scom25': ('objectiveDiameterMm:50', 'clickValue:0.1', 'AngularUnit.mrad', 'elevationRangeMrad:26'),
            'vector-paragon-gen2-6-30-scol27': ('objectiveDiameterMm:56', 'clickValue:0.1', 'AngularUnit.mrad', 'elevationRangeMrad:17.5'),
        }
        for scope_id, fields in expected.items():
            with self.subTest(scope_id=scope_id):
                m = re.search(r"ScopeOptic\(id:'" + re.escape(scope_id) + r"'.*?\),", self.text, re.S)
                self.assertIsNotNone(m)
                record = m.group(0)
                for field in fields:
                    self.assertIn(field, record)
                self.assertIn("sourceName:'Vector Optics'", record)
                self.assertIn('official', record)
                self.assertIn('verified 2026-09-27', record)

    def test_scope_ids_are_unique(self):
        ids = re.findall(r"ScopeOptic\(\s*id:'([^']+)'", self.text)
        self.assertEqual(len(ids), len(set(ids)))

if __name__ == '__main__':
    unittest.main()
