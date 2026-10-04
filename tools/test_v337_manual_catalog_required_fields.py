import pathlib, unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
STORE=(ROOT/'lib/services/manual_catalog_store.dart').read_text()
class V337ManualCatalogRequiredFields(unittest.TestCase):
    def test_non_custom_rifle_and_ammo_require_caliber(self):
        self.assertIn("if (kind != 'scope' && kind != 'custom_ammunition' && entry['caliberMm'] == null)", STORE)
    def test_standard_ammunition_requires_grain(self):
        self.assertIn("if (kind == 'ammo' && entry['grain'] == null)", STORE)
if __name__=='__main__': unittest.main()
