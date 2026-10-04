"""Fail closed on duplicate or structurally invalid global manufacturer records."""
import csv
import pathlib
import unittest

PATH = pathlib.Path(__file__).resolve().parents[1] / 'data' / 'global_manufacturers.csv'

class GlobalManufacturerRegistryTest(unittest.TestCase):
    def test_registry(self):
        with PATH.open(encoding='utf-8', newline='') as f:
            rows = list(csv.DictReader(f))
        self.assertEqual(len(rows), 26)
        ids = [r['manufacturer_id'] for r in rows]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertTrue(all(r['manufacturer_name'] and r['country'] for r in rows))
        self.assertTrue(all(r['platform'] in {'pcp', 'firearm'} for r in rows))
        self.assertTrue(all(r['verification_status'] in {'manufacturer_verified', 'user_supplied_unverified'} for r in rows))
        self.assertTrue(all(r['source_url'] for r in rows if r['verification_status'] == 'manufacturer_verified'))
        self.assertTrue({'TR', 'US', 'SE', 'CN', 'GB'}.issubset({r['country'] for r in rows}))

if __name__ == '__main__':
    unittest.main()
