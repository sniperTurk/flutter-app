import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TelsonStagingTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((ROOT/'catalog_sources/telson_optics_2026.json').read_text())

    def test_five_distinct_official_models(self):
        names = [p['model'] for p in self.data['products']]
        self.assertEqual(len(names), 5)
        self.assertEqual(len(set(names)), 5)

    def test_staging_does_not_claim_production_import(self):
        self.assertIn('pending', self.data['import_status'])
        self.assertIn('No production ScopeOptic', self.data['note'])

    def test_magnification_and_objective_are_valid(self):
        for p in self.data['products']:
            self.assertLess(p['min_magnification'], p['max_magnification'])
            self.assertGreater(p['objective_mm'], 0)

if __name__ == '__main__': unittest.main()
