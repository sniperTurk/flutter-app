from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / "lib/services/profile_store.dart").read_text(encoding="utf-8")
DART_TEST = (ROOT / "test/profile_store_test.dart").read_text(encoding="utf-8")

class ProfileStoreRecoveryRegression(unittest.TestCase):
    def test_missing_primary_is_not_treated_as_valid_empty_when_backup_exists(self):
        self.assertIn("if (primaryRaw == null && backupRaw == null) return const [];", STORE)
        self.assertIn("return _enqueueMutation(() => _read(repairPrimary: true));", STORE)
        self.assertIn("missing primary recovers surviving profile backup and self-heals", DART_TEST)

    def test_first_write_creates_backup_before_primary(self):
        backup_write = STORE.index("prefs.setString(_backupKey, backupPayload)")
        primary_write = STORE.index("prefs.setString(_key, payload)")
        self.assertLess(backup_write, primary_write)
        self.assertIn("first profile write creates a recoverable backup", DART_TEST)

    def test_corrupt_primary_without_backup_fails_closed(self):
        self.assertIn("if (backupRaw == null)", STORE)
        self.assertIn("Profile storage is corrupt and backup is missing", STORE)
        self.assertIn("if (raw.isEmpty) return null;", STORE)
        self.assertIn("corrupt primary without backup fails closed", DART_TEST)
        self.assertIn("empty persisted primary is corruption", DART_TEST)

    def test_failed_first_primary_write_rolls_back_uncommitted_backup(self):
        self.assertIn("await prefs.remove(_backupKey)", STORE)
        self.assertIn("Profile write failed and backup rollback failed", STORE)

if __name__ == "__main__":
    unittest.main()
