import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]

class SightHeightEvidenceGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.screen = (ROOT / 'lib/features/sight_height/sight_height_screen.dart').read_text()

    def test_valid_save_requires_both_photo_paths(self):
        self.assertIn('final hasPhotoEvidence = frontPhotoPath != null', self.screen)
        self.assertIn("sidePhotoPath != null && sidePhotoPath!.trim().isNotEmpty", self.screen)
        self.assertIn('!userConfirmed || !hasPhotoEvidence', self.screen)

    def test_missing_photo_evidence_has_explicit_user_message(self):
        self.assertIn('Doğrulanmış kayıt için kalıcı ön ve yan fotoğraf kanıtı gerekir.', self.screen)

    def test_evidence_paths_are_still_persisted_with_measurement(self):
        self.assertIn('frontPhotoPath: frontPhotoPath', self.screen)
        self.assertIn('sidePhotoPath: sidePhotoPath', self.screen)

if __name__ == '__main__':
    unittest.main()
