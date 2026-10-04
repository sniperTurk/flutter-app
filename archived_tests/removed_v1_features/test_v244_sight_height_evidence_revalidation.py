import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STORE = (ROOT/'lib/services/sight_height_photo_store.dart').read_text()
SCREEN = (ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()

class V244SightHeightEvidenceRevalidationTest(unittest.TestCase):
    def test_store_rejects_non_owned_or_missing_evidence(self):
        self.assertIn('Future<bool> verifyEvidence(String? path, {required bool side})', STORE)
        self.assertIn("if (!path.startsWith(prefix)) return false;", STORE)
        self.assertIn("if (!await file.exists()) return false;", STORE)
        self.assertIn('SightHeightPhotoRules.validate(size, side: side);', STORE)

    def test_save_boundary_revalidates_both_photos(self):
        self.assertIn('photoStore.verifyEvidence(frontPhotoPath, side: false)', SCREEN)
        self.assertIn('photoStore.verifyEvidence(sidePhotoPath, side: true)', SCREEN)
        self.assertIn('Fotoğraf kanıtı artık geçerli değil.', SCREEN)

    def test_revalidation_precedes_measurement_persistence(self):
        verify = SCREEN.index('photoStore.verifyEvidence(frontPhotoPath, side: false)')
        save = SCREEN.index('store.saveSightHeightMeasurement')
        self.assertLess(verify, save)

if __name__ == '__main__':
    unittest.main()
