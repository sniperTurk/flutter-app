from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
STORE=(ROOT/'lib/services/manual_catalog_store.dart').read_text(encoding='utf-8')
class ManualCatalogRollbackRegression(unittest.TestCase):
    def test_primary_failure_restores_previous_backup(self):
        mutate=STORE[STORE.index('Future<void> _mutate'):]
        self.assertIn('final previousBackup = prefs.getString(backupKey);', mutate)
        self.assertIn('await prefs.remove(backupKey)', mutate)
        self.assertIn('await prefs.setString(backupKey, previousBackup)', mutate)
        self.assertIn('Manual catalog write failed and backup rollback failed', mutate)
if __name__=='__main__': unittest.main()
