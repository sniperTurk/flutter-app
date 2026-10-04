from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CATALOG = (ROOT / 'lib/data/catalog_repository.dart').read_text()


class HatsanHerculesBully777CatalogProvenanceTest(unittest.TestCase):
    def test_hercules_bully_777_specs_and_provenance_are_locked(self):
        match = re.search(r"Rifle\(id:'hatsan-hercules-bully-777-635'.*?\),", CATALOG)
        self.assertIsNotNone(match, 'HATSAN Hercules Bully 777 6.35 catalog record is missing')
        row = match.group(0)
        expected = [
            "brand:'HATSAN'", "model:'Hercules Bully 777'", 'caliberMm:6.35',
            'magazineCapacity:13', 'barrelLengthMm:760', 'airCapacityCc:700',
            'overallLengthMm:1080', 'weightKg:5.3', "sourceName:'HATSAN'",
            "sourceDocument:'HATSAN Hercules Bully 777 official product page, verified 2026-09-27'",
        ]
        for token in expected:
            with self.subTest(token=token):
                self.assertIn(token, row, f'Hercules Bully 777 provenance/spec regression: {token}')
        self.assertEqual(CATALOG.count("id:'hatsan-hercules-bully-777-635'"), 1)


if __name__ == '__main__':
    unittest.main()
