import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
USER = (ROOT / 'lib/services/user_catalog_store.dart').read_text(encoding='utf-8')
MANUAL = (ROOT / 'lib/services/manual_catalog_store.dart').read_text(encoding='utf-8')

class DeepCatalogSnapshotContract(unittest.TestCase):
    def test_user_catalog_snapshot_is_deep_not_shallow(self):
        self.assertIn('static Map<String, dynamic> _snapshotEntry(', USER)
        self.assertIn('jsonDecode(jsonEncode(entry))', USER)
        self.assertIn('final snapshot = _snapshotEntry(entry);', USER)

    def test_manual_catalog_snapshot_is_deep_not_shallow(self):
        self.assertIn('static Map<String, dynamic> _snapshotEntry(', MANUAL)
        self.assertIn('jsonDecode(jsonEncode(entry))', MANUAL)
        self.assertIn('final snapshot = _snapshotEntry(entry);', MANUAL)

if __name__ == '__main__':
    unittest.main()
