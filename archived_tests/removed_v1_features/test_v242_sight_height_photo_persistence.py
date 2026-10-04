import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class V242SightHeightPhotoPersistenceTest(unittest.TestCase):
    def test_photo_store_is_app_owned_and_dependency_declared(self):
        service = (ROOT/'lib/services/sight_height_photo_store.dart').read_text()
        pubspec = (ROOT/'pubspec.yaml').read_text()
        self.assertIn('getApplicationDocumentsDirectory', service)
        self.assertIn("folderName = 'sight_height'", service)
        self.assertIn('path_provider:', pubspec)

    def test_picker_persists_before_exposing_path(self):
        src = (ROOT/'lib/features/sight_height/photo_measurement.dart').read_text()
        self.assertIn('await _photoStore.persist(', src)
        self.assertIn('widget.onFrontPhotoPath(persistedPath)', src)
        self.assertIn('widget.onSidePhotoPath(persistedPath)', src)
        self.assertIn('XFile(persistedPath)', src)

    def test_measurement_codec_preserves_photo_provenance_backwards_compatibly(self):
        model = (ROOT/'lib/models/measurement.dart').read_text()
        codec = (ROOT/'lib/services/measurement_codec.dart').read_text()
        screen = (ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
        self.assertIn('frontPhotoPath', model)
        self.assertIn('sidePhotoPath', model)
        self.assertIn("'frontPhotoPath': value.frontPhotoPath", codec)
        self.assertIn("_nullableString(json['frontPhotoPath']", codec)
        self.assertIn('frontPhotoPath: frontPhotoPath', screen)
        self.assertIn('sidePhotoPath: sidePhotoPath', screen)

if __name__ == '__main__': unittest.main()
