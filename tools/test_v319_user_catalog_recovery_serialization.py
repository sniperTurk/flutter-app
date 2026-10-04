from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT / 'lib/services/user_catalog_store.dart').read_text(encoding='utf-8')

class UserCatalogRecoverySerializationRegression(unittest.TestCase):
    def test_recovery_is_serialized_with_save_and_remove(self):
        self.assertIn('Future<List<Map<String, dynamic>>> _read({bool repairPrimary = false})', STORE)
        self.assertIn('return _enqueueMutation(() => _read(repairPrimary: true));', STORE)
        self.assertIn('final items = await _read();', STORE)

    def test_recovery_rechecks_storage_inside_mutation_queue(self):
        all_body = STORE[STORE.index('Future<List<Map<String, dynamic>>> all()'):STORE.index('Future<void> save(')]
        self.assertNotIn('prefs.setString(key, backup)', all_body)
        self.assertIn('_enqueueMutation', all_body)

if __name__ == '__main__':
    unittest.main()
