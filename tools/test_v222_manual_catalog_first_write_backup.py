from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SRC = (ROOT / "lib/services/manual_catalog_store.dart").read_text(encoding="utf-8")

class ManualCatalogFirstWriteBackupTest(unittest.TestCase):
    def test_first_write_creates_recovery_snapshot(self):
        self.assertIn("final encoded = jsonEncode(items);", SRC)
        self.assertIn("final backupSnapshot = old == null && prefs.getString(backupKey) == null", SRC)
        self.assertIn("prefs.setString(backupKey, backupSnapshot)", SRC)
        self.assertLess(SRC.index("prefs.setString(backupKey, backupSnapshot)"), SRC.index("prefs.setString(key, encoded)"))

if __name__ == "__main__":
    unittest.main()
