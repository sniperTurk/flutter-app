from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT/'lib/services/manual_catalog_store.dart').read_text()
SCREEN = (ROOT/'lib/features/catalog/catalog_screen.dart').read_text()
DIALOG = (ROOT/'lib/features/catalog/manual_catalog_dialog.dart').read_text()

class ManualCatalogRecoveryRegression(unittest.TestCase):
    def test_missing_primary_falls_back_to_backup(self):
        self.assertIn('return _enqueueMutation(() => _read(repairPrimary: true));', STORE)
        self.assertIn('final recovered = _decodeAndValidate(backup);', STORE)
    def test_backup_snapshot_is_validated(self):
        self.assertIn('final previousSnapshot = jsonEncode(items);', STORE)
        self.assertNotIn('final backupSnapshot = old ?? encoded;', STORE)
    def test_first_write_still_has_backup(self):
        self.assertIn('? encoded\n          : previousSnapshot;', STORE)
    def test_live_catalog_uses_manual_store_for_read_and_write(self):
        self.assertIn('final _manualStore = ManualCatalogStore();', SCREEN)
        self.assertIn('await _manualStore.all()', SCREEN)
        self.assertIn('await _manualStore.upsert(entry)', SCREEN)
        self.assertNotIn('UserCatalogStore(', SCREEN)
    def test_live_dialog_is_wired_to_manual_store_only(self):
        # The former unused UserCatalogStore dialog was replaced by the live
        # manual-catalog dialog; legacy records are migrated, never rewritten.
        self.assertIn('ManualCatalogDialog(', SCREEN)
        self.assertIn('onSave: (entry) async => await _manualStore.upsert(entry)', SCREEN)
        self.assertNotIn('UserCatalogStore', DIALOG)

if __name__ == '__main__': unittest.main()
