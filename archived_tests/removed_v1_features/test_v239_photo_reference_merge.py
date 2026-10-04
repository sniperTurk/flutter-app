import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
class PhotoReferenceMerge(unittest.TestCase):
 def test_reference_pixels_wired_from_photo_to_calibration(self):
  photo=(ROOT/'lib/features/sight_height/photo_measurement.dart').read_text()
  screen=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
  self.assertIn('onReferencePixels(reference)',photo)
  self.assertIn('referencePx.text = px.toStringAsFixed(3)',screen)
  self.assertIn('onReferencePixels:',screen)
 def test_only_physical_outer_diameter_prefilled(self):
  screen=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
  self.assertIn('scope?.objectiveOuterDiameterMm',screen)
  self.assertNotIn('scope?.objectiveDiameterMm',screen)
  self.assertIn('UserCatalogStore.scope(entry)',screen)
 def test_photo_is_not_claimed_validated(self):
  screen=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
  self.assertIn('henüz doğrulanmadı',screen)
  self.assertNotIn('Kamera/Qwen',screen)
if __name__=='__main__': unittest.main()
