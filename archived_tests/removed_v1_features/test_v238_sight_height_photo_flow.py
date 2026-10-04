import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class V238SightHeightPhotoFlow(unittest.TestCase):
 def test_dependency_and_permissions(self):
  self.assertIn('image_picker:',(ROOT/'pubspec.yaml').read_text())
  s=(ROOT/'tools/configure_ios_info_plist.py').read_text()
  self.assertIn('NSCameraUsageDescription',s); self.assertIn('NSPhotoLibraryUsageDescription',s)
 def test_user_controlled_photo_measurement_is_wired(self):
  s=(ROOT/'lib/features/sight_height/sight_height_screen.dart').read_text()
  self.assertIn('SightHeightPhotoMeasurement',s); self.assertIn('onMeasuredPixels',s)
  p=(ROOT/'lib/features/sight_height/photo_measurement.dart').read_text()
  self.assertIn('ImageSource.camera',p); self.assertIn('ImageSource.gallery',p)
  self.assertIn('SightHeightGeometry.pixelDistance',p)
  self.assertNotIn('Qwen',p)
if __name__=='__main__': unittest.main()
