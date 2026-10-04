from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
CATALOG = (ROOT / 'lib/data/catalog_repository.dart').read_text(encoding='utf-8')


class HubenK1CatalogProvenanceTests(unittest.TestCase):
    EXPECTED = {
        'huben-k1-55': ('K1', '5.5'),
        'huben-k1-635': ('K1', '6.35'),
        'huben-k1-762': ('K1', '7.62'),
        'huben-k1-special-edition-55': ('K1 Special Edition', '5.5'),
        'huben-k1-special-edition-635': ('K1 Special Edition', '6.35'),
        'huben-k1-special-edition-762': ('K1 Special Edition', '7.62'),
        'huben-k1-lite-55': ('K1 Lite Carbon Fiber', '5.5'),
        'huben-k1-lite-635': ('K1 Lite Carbon Fiber', '6.35'),
        'huben-k1-lite-762': ('K1 Lite Carbon Fiber', '7.62'),
    }

    def _row(self, rifle_id):
        prefix = "    Rifle(id:'" + rifle_id + "'"
        rows = [line for line in CATALOG.splitlines() if line.startswith(prefix)]
        self.assertEqual(len(rows), 1, rifle_id)
        return rows[0]

    def test_verified_k1_variants_exist_once_with_provenance(self):
        for rifle_id, (model, caliber) in self.EXPECTED.items():
            with self.subTest(rifle_id=rifle_id):
                row = self._row(rifle_id)
                self.assertIn("brand:'Huben'", row)
                self.assertIn("model:'%s'" % model, row)
                self.assertIn('platform:WeaponPlatform.pcp', row)
                self.assertIn('caliberMm:%s' % caliber, row)
                self.assertIn("sourceName:'Huben / Wolfiek Group'", row)
                self.assertIn('hubenairguns.shop/collections/', row)
                self.assertIn('verified 2026-10-02', row)
                self.assertEqual(CATALOG.count("id:'" + rifle_id + "'"), 1)

    def test_unverified_numeric_specs_are_not_invented(self):
        fields = ('magazineCapacity:', 'barrelLengthMm:', 'airCapacityCc:',
                  'overallLengthMm:', 'weightKg:', 'plenumCc:')
        for rifle_id in self.EXPECTED:
            row = self._row(rifle_id)
            for field in fields:
                self.assertNotIn(field, row)

    def test_gk1_pistols_are_not_misclassified_as_rifles(self):
        self.assertNotRegex(CATALOG, r"Rifle\(id:'huben-gk1")


if __name__ == '__main__':
    unittest.main()
