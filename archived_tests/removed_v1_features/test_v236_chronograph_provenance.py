from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
class V236ChronographProvenance(unittest.TestCase):
 def test_model_and_codec_persist_source_environment(self):
  model=(ROOT/'lib/models/measurement.dart').read_text()
  codec=(ROOT/'lib/services/measurement_codec.dart').read_text()
  self.assertIn('enum MeasurementSource',model)
  for token in ["'source': value.source.name", "'targetDistanceMeters': value.targetDistanceMeters", "'temperatureC': value.temperatureC"]: self.assertIn(token,codec)
 def test_acoustic_valid_is_fail_closed_and_legacy_is_compatible(self):
  codec=(ROOT/'lib/services/measurement_codec.dart').read_text()
  self.assertGreaterEqual(codec.count('Acoustic microphone readings cannot be valid.'),2)
  self.assertIn('if (value == null) return MeasurementSource.manualReference;',codec)
 def test_capture_stamps_provenance(self):
  src=(ROOT/'lib/services/chronograph_capture_controller.dart').read_text()
  self.assertIn('source: MeasurementSource.acousticMicrophone',src)
  self.assertIn('targetDistanceMeters: distanceMeters',src)
  self.assertIn('temperatureC: temperatureC',src)
if __name__=='__main__': unittest.main()
