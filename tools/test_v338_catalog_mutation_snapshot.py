import pathlib, unittest
ROOT = pathlib.Path(__file__).resolve().parents[1]
USER = (ROOT/'lib/services/user_catalog_store.dart').read_text()
MANUAL = (ROOT/'lib/services/manual_catalog_store.dart').read_text()

class V338CatalogMutationSnapshot(unittest.TestCase):
    def test_user_catalog_snapshots_caller_map_before_async_queue(self):
        self.assertIn("final snapshot = _snapshotEntry(entry);", USER)
        self.assertIn("validate(snapshot);", USER)
        self.assertIn("item['id'] == snapshot['id']", USER)
        self.assertIn("items.add(snapshot);", USER)

    def test_manual_catalog_snapshots_caller_map_before_async_queue(self):
        self.assertIn("final snapshot = _snapshotEntry(entry);", MANUAL)
        self.assertIn("_validateEntry(snapshot);", MANUAL)
        self.assertIn("e['id'] == snapshot['id']", MANUAL)
        self.assertIn("items.add(snapshot);", MANUAL)

if __name__ == '__main__': unittest.main()
