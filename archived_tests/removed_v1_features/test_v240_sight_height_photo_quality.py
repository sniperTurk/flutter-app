import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class SightHeightPhotoQuality(unittest.TestCase):
 def setUp(self): self.src=(ROOT/'lib/features/sight_height/photo_measurement.dart').read_text()
 def test_rejects_low_resolution_and_portrait_side_photo(self):
  self.assertIn('_minLongSidePx = 1000',self.src)
  self.assertIn("'low_resolution'",self.src)
  self.assertIn("'side_not_landscape'",self.src)
  self.assertIn('width <= height',self.src)
 def test_corrupt_photo_fails_closed(self):
  self.assertIn('instantiateImageCodec',self.src)
  self.assertIn("'corrupt_photo'",self.src)
 def test_points_are_draggable_and_recompute_measurement(self):
  self.assertIn('onPanUpdate:',self.src)
  self.assertIn('_movePoint(',self.src)
  self.assertIn('_emitMeasurement();',self.src)
  self.assertIn('next.dx.clamp',self.src)
if __name__=='__main__': unittest.main()
