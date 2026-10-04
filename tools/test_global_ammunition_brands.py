"""Validate user-supplied ammunition brand registry without promoting it to ballistic data."""
import csv
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'data' / 'global_ammunition_brands.csv'


class GlobalAmmunitionBrandsTest(unittest.TestCase):
    def test_registry_integrity(self):
        with PATH.open(encoding='utf-8', newline='') as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(len(rows), 28)
        ids = [row['brand_id'] for row in rows]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(row['brand_name'] and row['headquarters_country'] for row in rows))
        self.assertTrue(all(row['verification_status'] == 'user_supplied_unverified' for row in rows))
        self.assertTrue(all(row['category'] in {
            'finished_ammunition', 'projectiles', 'projectiles_and_ammunition',
            'projectiles_cases_ammunition', 'propellant_and_ammunition'
        } for row in rows))

    def test_registry_does_not_change_live_catalog(self):
        source = (ROOT / 'lib' / 'data' / 'catalog_repository.dart').read_text(encoding='utf-8')
        self.assertNotIn('global_ammunition_brands.csv', source)


if __name__ == '__main__':
    unittest.main()
