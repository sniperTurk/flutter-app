from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT/'lib/services/manual_catalog_store.dart').read_text()
PROFILES = (ROOT/'lib/features/profiles/profiles_screen.dart').read_text()

class ManualCatalogRecoveryRegression(unittest.TestCase):
    def test_missing_primary_falls_back_to_backup(self):
        self.assertIn('return _enqueueMutation(() => _read(repairPrimary: true));', STORE)
        self.assertIn('final recovered = _decodeAndValidate(backup);', STORE)
    def test_backup_snapshot_is_validated(self):
        self.assertIn('final previousSnapshot = jsonEncode(items);', STORE)
        self.assertNotIn('final backupSnapshot = old ?? encoded;', STORE)
    def test_first_write_still_has_backup(self):
        self.assertIn('? encoded\n          : previousSnapshot;', STORE)
    def test_live_profile_editor_uses_manual_store_for_read_and_write(self):
        # The catalog screen was removed; the profile editor is the live
        # writer. Legacy UserCatalogStore records are migrated, never rewritten.
        self.assertIn('final ManualCatalogStore _manualStore = ManualCatalogStore();', PROFILES)
        self.assertIn('await _manualStore.all()', PROFILES)
        self.assertIn('await _manualStore.upsert(entry)', PROFILES)
        self.assertNotIn('UserCatalogStore(', PROFILES)

if __name__ == '__main__': unittest.main()
