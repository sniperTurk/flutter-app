import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPO = (ROOT / 'lib/data/catalog_repository.dart').read_text()
INTEGRITY = (ROOT / 'lib/data/catalog_integrity.dart').read_text()
SCREEN = (ROOT / 'lib/features/catalog/catalog_screen.dart').read_text()
DART_TEST = (ROOT / 'test/catalog_integrity_test.dart').read_text()

class V153CatalogCompletenessTest(unittest.TestCase):
    def test_all_non_manual_bundled_records_have_provenance(self):
        for kind in ('Rifle', 'Ammunition', 'ScopeOptic'):
            for body in re.findall(rf'\\b{kind}\\((.*?)\\),\\n', REPO, re.S):
                brand = re.search(r"brand:'([^']+)'", body)
                if brand and brand.group(1) != 'Manuel':
                    self.assertIn('sourceName:', body, body[:160])
                    self.assertIn('sourceDocument:', body, body[:160])

    def test_integrity_layer_enforces_provenance_not_only_fixture_text(self):
        self.assertGreaterEqual(INTEGRITY.count('non-manual catalog records require provenance'), 3)
        self.assertIn("brand != 'Manuel'", INTEGRITY)
        self.assertIn('non-manual branded catalog records cannot silently lose provenance', DART_TEST)
        self.assertIn('manual templates remain intentionally usable without fake provenance', DART_TEST)

    def test_user_reported_gmaz_is_not_misrepresented_as_verified_manufacturer_data(self):
        line = next(x for x in REPO.splitlines() if "id:'gmaz-51'" in x)
        self.assertIn("sourceName:'Kullanıcı girdisi'", line)
        self.assertIn('kamuya açık üretici teknik föyü doğrulanamadı', line)
        self.assertNotIn('ballisticCoefficient:', line)
        self.assertIn("ammunition.sourceName == 'Kullanıcı girdisi'", SCREEN)
        self.assertIn("'Doğrulama: kullanıcı girdisi'", SCREEN)

    def test_jsb_45_55_records_are_present_without_invented_bc(self):
        expected = {
            'jsb-exact-177-8_44': ('4.52', '8.44'),
            'jsb-exact-heavy-177-10_34': ('4.52', '10.34'),
            'jsb-exact-jumbo-22-15_89': ('5.52', '15.89'),
            'jsb-exact-jumbo-heavy-22-18_13': ('5.52', '18.13'),
        }
        for record_id, (caliber, grain) in expected.items():
            line = next(x for x in REPO.splitlines() if f"id:'{record_id}'" in x)
            self.assertIn(f'caliberMm:{caliber}', line)
            self.assertIn(f'grain:{grain}', line)
            self.assertIn("sourceName:'JSB Match Diabolo'", line)
            self.assertNotIn('ballisticCoefficient:', line)
        self.assertIn('JSB 4.5 and 5.5 manufacturer records keep exact verified weights', DART_TEST)

if __name__ == '__main__':
    unittest.main()
