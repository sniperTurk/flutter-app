import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
PHOTO = (ROOT / "lib/features/sight_height/photo_measurement.dart").read_text()
STORE = (ROOT / "lib/services/sight_height_photo_store.dart").read_text()

class SightHeightPhotoReplacementCleanup(unittest.TestCase):
    def test_old_evidence_is_deleted_only_after_new_photo_is_persisted(self):
        persisted = PHOTO.index("final persistedPath = await _photoStore.persist(")
        capture_old = PHOTO.index("final replacedPath = front ? _front?.path : _side?.path;")
        delete_old = PHOTO.index("await _photoStore.delete(replacedPath);")
        self.assertLess(persisted, capture_old)
        self.assertLess(capture_old, delete_old)

    def test_front_and_side_replacements_share_cleanup_path(self):
        self.assertIn("final replacedPath = front ? _front?.path : _side?.path;", PHOTO)
        self.assertIn("replacedPath != null && replacedPath != persistedPath", PHOTO)

    def test_store_delete_is_scoped_to_app_owned_sight_height_directory(self):
        self.assertIn("if (!path.startsWith('${dir.path}${Platform.pathSeparator}')) return;", STORE)

if __name__ == "__main__":
    unittest.main()
