"""Validate the global scope-brand reference registry without claiming unverified model specs."""
import csv
from pathlib import Path
import unittest

PATH = Path(__file__).resolve().parents[1] / 'data' / 'global_scope_brands.csv'


class GlobalScopeBrandsTest(unittest.TestCase):
    def test_registry_integrity(self):
        with PATH.open(encoding='utf-8', newline='') as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(len(rows), 21)
        ids = [row['brand_id'] for row in rows]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(row['brand_name'] and row['headquarters_country'] for row in rows))
        self.assertTrue(all(row['segment_label'] in {'premium', 'upper-mid', 'value-entry', 'asia-production'} for row in rows))
        self.assertTrue(all(row['verification_status'] in {'manufacturer_verified', 'user_supplied_unverified'} for row in rows))
        self.assertTrue(all(row['source_url'] for row in rows if row['verification_status'] == 'manufacturer_verified'))
        self.assertEqual({row['brand_id'] for row in rows if row['verification_status'] == 'manufacturer_verified'}, {'swarovski-optik', 'march', 'eotech'})


if __name__ == '__main__':
    unittest.main()
