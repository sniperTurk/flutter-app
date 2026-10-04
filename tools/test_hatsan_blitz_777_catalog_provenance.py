from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CATALOG = (ROOT / 'lib/data/catalog_repository.dart').read_text()


class HatsanBlitz777CatalogProvenanceTest(unittest.TestCase):
    def test_blitz_777_specs_and_provenance_are_locked(self):
        match = re.search(r"Rifle\(id:'hatsan-blitz-777-635'.*?\),", CATALOG)
        self.assertIsNotNone(match, 'HATSAN Blitz 777 6.35 catalog record is missing')
        row = match.group(0)
        expected = [
            "brand:'HATSAN'", "model:'Blitz 777'", 'caliberMm:6.35',
            'magazineCapacity:19', 'barrelLengthMm:585', 'airCapacityCc:700',
            'overallLengthMm:905', 'weightKg:4', "sourceName:'HATSAN'",
            "sourceDocument:'HATSAN Blitz 777 official product page, verified 2026-09-27'",
        ]
        for token in expected:
            with self.subTest(token=token):
                self.assertIn(token, row, f'Blitz 777 provenance/spec regression: {token}')
        self.assertEqual(CATALOG.count("id:'hatsan-blitz-777-635'"), 1)


if __name__ == '__main__':
    unittest.main()
