from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / "lib/services/user_catalog_store.dart").read_text(encoding="utf-8")

class UserCatalogAtomicCommitRegression(unittest.TestCase):
    def test_save_and_remove_share_fail_closed_commit_helper(self):
        self.assertIn("await _commit(prefs, encoded, operationError: 'Kişisel katalog kaydedilemedi');", STORE)
        self.assertIn("await _commit(prefs, encoded, operationError: 'Kişisel katalog silinemedi');", STORE)

    def test_backup_is_written_before_primary(self):
        helper = STORE[STORE.index("static Future<void> _commit"):STORE.index("static void validate")]
        self.assertLess(helper.index("prefs.setString(backupKey, encoded)"), helper.index("prefs.setString(key, encoded)"))

    def test_primary_failure_restores_previous_backup(self):
        helper = STORE[STORE.index("static Future<void> _commit"):STORE.index("static void validate")]
        self.assertIn("previousBackup", helper)
        self.assertIn("await prefs.remove(backupKey)", helper)
        self.assertIn("await prefs.setString(backupKey, previousBackup)", helper)

if __name__ == "__main__":
    unittest.main()
