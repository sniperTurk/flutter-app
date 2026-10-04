from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / 'lib/services/manual_catalog_store.dart').read_text(encoding='utf-8')

class V340ManualCatalogRecoveryRepair(unittest.TestCase):
    def test_public_recovery_repairs_primary_inside_serialized_mutation_queue(self):
        self.assertIn('return _enqueueMutation(() => _read(repairPrimary: true));', STORE)
        self.assertIn("if (repairPrimary && !await prefs.setString(key, backup))", STORE)

    def test_mutation_reads_privately_to_avoid_recursive_queue_deadlock(self):
        self.assertIn('final items = await _read();', STORE)
        self.assertNotIn('final items = await all();', STORE)

if __name__ == '__main__':
    unittest.main()
