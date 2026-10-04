from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / "lib/services/manual_catalog_store.dart").read_text(encoding="utf-8")
DIALOG = (ROOT / "lib/features/catalog/manual_catalog_dialog.dart").read_text(encoding="utf-8")

class ManualCatalogIntegrityRegression(unittest.TestCase):
    def test_store_validates_loaded_and_new_entries(self):
        self.assertIn("_validateEntry(item);", STORE)
        self.assertIn("_validateEntry(entry);", STORE)
        self.assertIn("Invalid ammunition type for platform", STORE)
        self.assertIn("(platform == 'firearm' && ammoType != 'bullet')", STORE)
        self.assertIn("(platform == 'pcp' && ammoType == 'bullet')", STORE)

    def test_legacy_dialog_rebuilds_ammo_dropdown_on_platform_change(self):
        self.assertIn("key: ValueKey('legacy-ammo-type-$platform')", DIALOG)

if __name__ == '__main__':
    unittest.main()
