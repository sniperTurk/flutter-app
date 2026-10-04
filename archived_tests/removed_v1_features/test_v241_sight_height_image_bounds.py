import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class SightHeightImageBounds(unittest.TestCase):
 def setUp(self): self.src=(ROOT/'lib/features/sight_height/photo_measurement.dart').read_text()
 def test_side_dimensions_are_retained_for_render_geometry(self):
  self.assertIn('_sideWidthPx = width', self.src)
  self.assertIn('_sideHeightPx = height', self.src)
  self.assertIn('Rect _renderedSideRect(BoxConstraints box)', self.src)
  self.assertIn('math.min(box.maxWidth / widthPx, viewportHeight / heightPx)', self.src)
 def test_taps_outside_actual_contained_image_are_rejected(self):
  self.assertIn('!imageRect.contains(d.localPosition)', self.src)
  self.assertIn("Ölçüm noktaları fotoğrafın görünür alanı içinde olmalıdır.", self.src)
 def test_drag_is_clamped_to_actual_image_not_letterbox(self):
  self.assertIn('next.dx.clamp(imageRect.left, imageRect.right)', self.src)
  self.assertIn('next.dy.clamp(imageRect.top, imageRect.bottom)', self.src)
if __name__=='__main__': unittest.main()
