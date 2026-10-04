from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V234(unittest.TestCase):
 def test_pipeline_is_wired_fail_closed(self):
  s=(ROOT/'lib/services/chronograph_capture_controller.dart').read_text()
  self.assertIn('StreamingAudioTransientDetector',s)
  self.assertIn('AcousticChronograph.estimate',s)
  self.assertIn('MeasurementStatus.estimated',s)
  self.assertNotIn('status: MeasurementStatus.valid',s)
 def test_model_has_estimated_status(self):
  self.assertIn('estimated', (ROOT/'lib/models/measurement.dart').read_text())
if __name__=='__main__': unittest.main()
