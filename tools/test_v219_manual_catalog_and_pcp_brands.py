import csv
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class V219Tests(unittest.TestCase):
    def test_pcp_brand_registry(self):
        with (ROOT / 'data/global_pcp_ammunition_brands.csv').open(encoding='utf-8', newline='') as f:
            rows = list(csv.DictReader(f))
        self.assertGreaterEqual(len(rows), 23)
        self.assertEqual(len({r['brand_id'] for r in rows}), len(rows))
        self.assertTrue(all(r['verification_status'] == 'user_supplied_unverified' for r in rows if r['brand_id'] != 'my-bullet'))
    def test_manual_catalog_is_separate_and_persistent(self):
        store = (ROOT / 'lib/services/manual_catalog_store.dart').read_text()
        screen = (ROOT / 'lib/features/catalog/catalog_screen.dart').read_text()
        for value in ('SharedPreferences', 'backupKey', 'upsert(', 'remove(', 'Kullanıcı girdisi'):
            self.assertIn(value, store + screen)
        self.assertIn("e['platform'] == platform.name", screen)
        self.assertIn("_editManual(existing: e)", screen)
        dialog = (ROOT / 'lib/features/catalog/manual_catalog_dialog.dart').read_text()
        self.assertIn("form.currentState!.validate()", dialog)
        self.assertIn("ManualCatalogDialog(", screen)

if __name__ == '__main__': unittest.main()
